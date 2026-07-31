import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/two_pass_correction_pipeline.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_original_range_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

void main() {
  group('runTwoPassCorrectionPipeline', () {
    test(
      'does not call the naturalness fallback when the parallel merge is '
      'already clean (no naturalness issue at all)',
      () async {
        const text = 'Vi mucho trafico ayer.';
        final traficoIndex = text.indexOf('trafico');

        final client = _RoutingHttpClient(
          repliesBySystemPrompt: {
            stage1DetectionDialectSpanish: _arrayEnvelope(['"trafico"']),
            stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
            stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
            stage2CategorizationSpanish: _arrayEnvelope([
              '{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
                  '"occurrence": 1, "category": "Spelling", "verdict": "error"}',
            ]),
            stage3FeedbackSpanish: _arrayEnvelope([
              '{"start_index": $traficoIndex, "short_explanation": '
                  '"Trafico needs an accent on the a: tráfico."}',
            ]),
          },
          naturalnessRepliesByUserText: {
            buildNaturalnessUserContent(text): _naturalnessEnvelope(
              '{"has_naturalness_issue": false, "issues": []}',
            ),
          },
        );

        final result = await runTwoPassCorrectionPipeline(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          submittedText: text,
        );

        // One unified CorrectionResponse — the same shape correctText()
        // returns for every other path — with just the first-pass fix,
        // since the naturalness pass found nothing to flag.
        expect(result.correctedText, 'Vi mucho tráfico ayer.');
        expect(result.corrections, hasLength(1));
        expect(result.corrections.single.category, ErrorCategory.spelling);
        expect(result.corrections.single.correctedPhrase, 'tráfico');
        // Exactly one naturalness call — the fallback was never triggered.
        expect(client.naturalnessCallCount, 1);
      },
    );

    test(
      'falls back to a sequential naturalness rerun when the first pass '
      'changes the exact wording the parallel naturalness pass flagged',
      () async {
        const originalText = 'Ayer iso una desicion importante.';
        final isoIndex = resolveOccurrenceCorrections(originalText, [
          const OccurrenceCorrection(originalPhrase: 'iso', occurrence: 1),
        ]).single.startIndex!;
        final desicionIndex = resolveOccurrenceCorrections(originalText, [
          const OccurrenceCorrection(
            originalPhrase: 'desicion',
            occurrence: 1,
          ),
        ]).single.startIndex!;
        const firstPassCorrectedText =
            'Ayer hizo una decisión importante.';

        final client = _RoutingHttpClient(
          repliesBySystemPrompt: {
            stage1DetectionDialectSpanish: _arrayEnvelope([
              '"iso"',
              '"desicion"',
            ]),
            stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
            stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
            stage2CategorizationSpanish: _arrayEnvelope([
              '{"original_phrase": "iso", "corrected_phrase": "hizo", '
                  '"occurrence": 1, "category": "Spelling", "verdict": "error"}',
              '{"original_phrase": "desicion", "corrected_phrase": '
                  '"decisión", "occurrence": 1, "category": "Spelling", '
                  '"verdict": "error"}',
            ]),
            stage3FeedbackSpanish: _arrayEnvelope([
              '{"start_index": $isoIndex, "short_explanation": '
                  '"Iso should be hizo."}',
              '{"start_index": $desicionIndex, "short_explanation": '
                  '"Desicion is missing its accent: decisión."}',
            ]),
          },
          naturalnessRepliesByUserText: {
            // Parallel call: reviews the raw, uncorrected originalText —
            // its flagged span still carries the typos the first pass will
            // fix, so it can never match firstPassCorrectedText.
            buildNaturalnessUserContent(originalText): _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
                  '{"span": "iso una desicion", '
                  '"natural_replacement": "tomó una decisión", '
                  '"explanation": "Hacer una decisión is a calque."}'
                  ']}',
            ),
            // Fallback call: reviews the first pass's own corrected text,
            // so its span matches exactly.
            buildNaturalnessUserContent(firstPassCorrectedText):
                _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
                  '{"span": "hizo una decisión", '
                  '"natural_replacement": "tomó una decisión", '
                  '"explanation": "Hacer una decisión is a calque."}'
                  ']}',
            ),
          },
        );

        final result = await runTwoPassCorrectionPipeline(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          submittedText: originalText,
        );

        expect(
          result.correctedText,
          'Ayer tomó una decisión importante.',
        );
        // Both first-pass fixes plus the (fallback-resolved) naturalness
        // edit, all in one unified corrections list.
        expect(result.corrections, hasLength(3));
        expect(
          result.corrections.where(
            (item) => item.category == ErrorCategory.spelling,
          ),
          hasLength(2),
        );
        final naturalnessItem = result.corrections.firstWhere(
          (item) => item.category == ErrorCategory.naturalLanguage,
        );
        expect(naturalnessItem.correctedPhrase, 'tomó una decisión');
        // The parallel call, then the sequential fallback.
        expect(client.naturalnessCallCount, 2);
      },
    );

    test(
      'falls back to a sequential naturalness rerun when the parallel '
      'naturalness pass flags an ambiguous span (occurs more than once)',
      () async {
        // "tráfico" occurs twice in both originalText and
        // firstPassCorrectedText — the ambiguity is untouched by the first
        // pass, which only fixes the unrelated "iso" -> "hizo". That
        // unrelated fix is what makes firstPassCorrectedText differ from
        // originalText, so the parallel and fallback naturalness calls
        // have distinct user text (otherwise they'd be indistinguishable
        // to this fake, since it routes the naturalness prompt by exact
        // user text).
        const originalText = 'Vi mucho tráfico, y luego iso más tráfico.';
        const firstPassCorrectedText =
            'Vi mucho tráfico, y luego hizo más tráfico.';
        final isoIndex = resolveOccurrenceCorrections(originalText, [
          const OccurrenceCorrection(originalPhrase: 'iso', occurrence: 1),
        ]).single.startIndex!;

        final client = _RoutingHttpClient(
          repliesBySystemPrompt: {
            stage1DetectionDialectSpanish: _arrayEnvelope(['"iso"']),
            stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
            stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
            stage2CategorizationSpanish: _arrayEnvelope([
              '{"original_phrase": "iso", "corrected_phrase": "hizo", '
                  '"occurrence": 1, "category": "Grammar", "verdict": "error"}',
            ]),
            stage3FeedbackSpanish: _arrayEnvelope([
              '{"start_index": $isoIndex, "short_explanation": '
                  '"Iso should be hizo."}',
            ]),
          },
          naturalnessRepliesByUserText: {
            // Parallel call: flags "tráfico", which occurs twice in
            // originalText — ambiguousSpan, not spanNotFound.
            buildNaturalnessUserContent(originalText): _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
                  '{"span": "tráfico", '
                  '"natural_replacement": "tránsito", '
                  '"explanation": "Tráfico as traffic is an anglicism."}'
                  ']}',
            ),
            // Fallback call: reviews firstPassCorrectedText and this time
            // flags a more specific, unambiguous span.
            buildNaturalnessUserContent(firstPassCorrectedText):
                _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
                  '{"span": "más tráfico", '
                  '"natural_replacement": "más tránsito", '
                  '"explanation": "Tráfico as traffic is an anglicism."}'
                  ']}',
            ),
          },
        );

        final result = await runTwoPassCorrectionPipeline(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          submittedText: originalText,
        );

        expect(
          result.correctedText,
          'Vi mucho tráfico, y luego hizo más tránsito.',
        );
        expect(result.corrections, hasLength(2));
        final naturalnessItem = result.corrections.firstWhere(
          (item) => item.category == ErrorCategory.naturalLanguage,
        );
        expect(naturalnessItem.correctedPhrase, 'más tránsito');
        expect(client.naturalnessCallCount, 2);
      },
    );

    test(
      'never applies an edit that is still unsafe after the fallback '
      'rerun — a rerun earns another chance to become safe, not a bypass '
      'of safety itself (issue #37)',
      () async {
        // Same setup as the ambiguous-span fallback test above, except
        // the fallback call's own reply is STILL ambiguous ("tráfico"
        // again, not narrowed to "más tráfico"). The fallback must still
        // be attempted, but its edit must still not be applied.
        const originalText = 'Vi mucho tráfico, y luego iso más tráfico.';
        const firstPassCorrectedText =
            'Vi mucho tráfico, y luego hizo más tráfico.';
        final isoIndex = resolveOccurrenceCorrections(originalText, [
          const OccurrenceCorrection(originalPhrase: 'iso', occurrence: 1),
        ]).single.startIndex!;

        final client = _RoutingHttpClient(
          repliesBySystemPrompt: {
            stage1DetectionDialectSpanish: _arrayEnvelope(['"iso"']),
            stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
            stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
            stage2CategorizationSpanish: _arrayEnvelope([
              '{"original_phrase": "iso", "corrected_phrase": "hizo", '
                  '"occurrence": 1, "category": "Grammar", "verdict": "error"}',
            ]),
            stage3FeedbackSpanish: _arrayEnvelope([
              '{"start_index": $isoIndex, "short_explanation": '
                  '"Iso should be hizo."}',
            ]),
          },
          naturalnessRepliesByUserText: {
            buildNaturalnessUserContent(originalText): _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
                  '{"span": "tráfico", '
                  '"natural_replacement": "tránsito", '
                  '"explanation": "Tráfico as traffic is an anglicism."}'
                  ']}',
            ),
            // Fallback call: still flags the bare, still-ambiguous
            // "tráfico" — the model didn't narrow it down this time.
            buildNaturalnessUserContent(firstPassCorrectedText):
                _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
                  '{"span": "tráfico", '
                  '"natural_replacement": "tránsito", '
                  '"explanation": "Tráfico as traffic is an anglicism."}'
                  ']}',
            ),
          },
        );

        final result = await runTwoPassCorrectionPipeline(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          submittedText: originalText,
        );

        // The fallback was attempted...
        expect(client.naturalnessCallCount, 2);
        // ...but since it was STILL unsafe, the base is untouched: the
        // final text is exactly the first pass's own output, nothing more,
        // and the unified response has no naturalness-derived correction
        // at all — only the first pass's own "iso" -> "hizo" fix.
        expect(result.correctedText, firstPassCorrectedText);
        expect(result.corrections, hasLength(1));
        expect(result.corrections.single.category, ErrorCategory.grammar);
      },
    );
  });
}

/// Wraps [replyContent] (the JSON-object-shaped naturalness reply text) in
/// a minimal `/v1/chat/completions` response envelope.
String _naturalnessEnvelope(String replyContent) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': replyContent},
    },
  ],
});

/// Wraps a hand-written list of already-JSON-encoded array element strings
/// in a `/v1/chat/completions` reply envelope, e.g.
/// `_arrayEnvelope(['"trafico"'])` -> a reply whose content is `["trafico"]`.
String _arrayEnvelope(List<String> elements) => jsonEncode({
  'choices': [
    {
      'message': {
        'role': 'assistant',
        'content': '[${elements.join(', ')}]',
      },
    },
  ],
});

// ── Minimal dart:io HttpClient fake that routes a reply by the outgoing
// request's system prompt — except for the naturalness system prompt,
// which this pipeline can call twice (parallel, then fallback) with the
// exact same system prompt but different user text, so that one is routed
// by user text instead.

class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient({
    required this.repliesBySystemPrompt,
    required this.naturalnessRepliesByUserText,
  });

  final Map<String, String> repliesBySystemPrompt;
  final Map<String, String> naturalnessRepliesByUserText;
  int naturalnessCallCount = 0;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _RoutingRequest(
      repliesBySystemPrompt: repliesBySystemPrompt,
      naturalnessRepliesByUserText: naturalnessRepliesByUserText,
      onNaturalnessCall: () => naturalnessCallCount++,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _RoutingRequest implements HttpClientRequest {
  _RoutingRequest({
    required this.repliesBySystemPrompt,
    required this.naturalnessRepliesByUserText,
    required this.onNaturalnessCall,
  });

  final Map<String, String> repliesBySystemPrompt;
  final Map<String, String> naturalnessRepliesByUserText;
  final void Function() onNaturalnessCall;
  final BytesBuilder _bytes = BytesBuilder();

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) => _bytes.add(data);

  @override
  Future<HttpClientResponse> close() async {
    final body = utf8.decode(_bytes.toBytes());
    final sent = jsonDecode(body) as Map<String, Object?>;
    final messages = sent['messages'] as List;
    final systemPrompt = (messages[0] as Map)['content'] as String;

    if (systemPrompt == naturalnessReviewSpanish) {
      onNaturalnessCall();
      final userText = (messages[1] as Map)['content'] as String;
      final reply = naturalnessRepliesByUserText[userText];
      if (reply == null) {
        throw StateError(
          'No fake naturalness reply registered for user text: $userText',
        );
      }
      return _FakeHttpClientResponse(responseBody: reply);
    }

    final reply = repliesBySystemPrompt[systemPrompt];
    if (reply == null) {
      throw StateError(
        'No fake reply registered for system prompt: $systemPrompt',
      );
    }
    return _FakeHttpClientResponse(responseBody: reply);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({required String responseBody})
    : _body = responseBody;

  final String _body;

  @override
  final int statusCode = 200;

  late final Stream<List<int>> _inner = Stream.fromIterable([
    utf8.encode(_body),
  ]);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _inner.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
