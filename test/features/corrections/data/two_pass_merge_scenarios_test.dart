// Issue #38: proves the two-pass merge behavior against a fixed matrix of
// deterministic scenarios, with no live OpenAI API access — every scenario
// here either drives the real staged pipeline against a fake HTTP client
// (same fake-client pattern as staged_correction_pipeline_test.dart) or
// calls the merge/mapper domain functions directly against hand-built
// inputs. Each test below corresponds to exactly one bullet in the issue's
// "Test cases" list.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/staged_correction_pipeline.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_original_range_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_issue.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

void main() {
  test('grammar-only correction: no naturalness issue at all', () async {
    const submittedText = 'Vi mucho trafico ayer.';
    final traficoIndex = submittedText.indexOf('trafico');

    final firstPassResponse = await runStagedCorrectionPipeline(
      client: OpenAiChatCompletionsClient(
        apiKey: 'test-key',
        httpClient: _RoutingHttpClient({
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
        }),
      ),
      model: 'gpt-5.5',
      submittedText: submittedText,
    );

    final merge = mergeNaturalnessReview(
      originalText: submittedText,
      firstPassCorrectedText: firstPassResponse.correctedText,
      naturalnessReview: const NaturalnessReview(
        hasNaturalnessIssue: false,
        issues: [],
      ),
    );
    final result = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: merge,
    );

    expect(result.correctedText, 'Vi mucho tráfico ayer.');
    expect(result.corrections, hasLength(1));
    expect(result.corrections.single.category, ErrorCategory.spelling);
    expect(result.corrections.single.correctedPhrase, 'tráfico');
  });

  test(
    'naturalness-only correction: the first pass flags nothing at all',
    () async {
      const submittedText = 'Voy a hacer una decisión importante.';

      final firstPassResponse = await runStagedCorrectionPipeline(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: _RoutingHttpClient({
            stage1DetectionDialectSpanish: _arrayEnvelope(const []),
            stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
            stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
          }),
        ),
        model: 'gpt-5.5',
        submittedText: submittedText,
      );
      expect(firstPassResponse.correctedText, submittedText);
      expect(firstPassResponse.corrections, isEmpty);

      const issue = NaturalnessIssue(
        span: 'hacer una decisión',
        naturalReplacement: 'tomar una decisión',
        explanation: 'Wrong collocation for "decisión".',
      );
      final merge = mergeNaturalnessReview(
        originalText: submittedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );
      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );

      expect(result.correctedText, 'Voy a tomar una decisión importante.');
      expect(result.corrections, hasLength(1));
      expect(result.corrections.single.category, ErrorCategory.naturalLanguage);
      expect(result.corrections.single.correctedPhrase, 'tomar una decisión');
    },
  );

  test(
    'grammar and naturalness corrections in different (non-overlapping) '
    'spans',
    () async {
      const submittedText =
          'El profesor dijo que devia estudiar más, y ella hizo una '
          'decisión importante.';
      final deviaIndex = submittedText.indexOf('devia');

      final firstPassResponse = await runStagedCorrectionPipeline(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: _RoutingHttpClient({
            stage1DetectionDialectSpanish: _arrayEnvelope(['"devia"']),
            stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
            stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
            stage2CategorizationSpanish: _arrayEnvelope([
              '{"original_phrase": "devia", "corrected_phrase": "debía", '
                  '"occurrence": 1, "category": "Spelling", "verdict": "error"}',
            ]),
            stage3FeedbackSpanish: _arrayEnvelope([
              '{"start_index": $deviaIndex, "short_explanation": '
                  '"Devia is missing its accent: debía."}',
            ]),
          }),
        ),
        model: 'gpt-5.5',
        submittedText: submittedText,
      );

      const issue = NaturalnessIssue(
        span: 'hizo una decisión',
        naturalReplacement: 'tomó una decisión',
        explanation: '"Hacer una decisión" is a calque.',
      );
      final merge = mergeNaturalnessReview(
        originalText: submittedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );
      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );

      expect(
        result.correctedText,
        'El profesor dijo que debía estudiar más, y ella tomó una '
        'decisión importante.',
      );
      expect(result.corrections, hasLength(2));
      expect(
        result.corrections.any(
          (item) =>
              item.correctedPhrase == 'debía' &&
              item.category == ErrorCategory.spelling,
        ),
        isTrue,
      );
      expect(
        result.corrections.any(
          (item) =>
              item.correctedPhrase == 'tomó una decisión' &&
              item.category == ErrorCategory.naturalLanguage,
        ),
        isTrue,
      );
    },
  );

  test(
    'pronoun deletion (empty corrected_phrase, whitespace-absorbing) plus '
    'a naturalness edit later in the text',
    () async {
      const submittedText =
          'Yo fui a casa, y yo hice una decisión importante.';
      // Case-sensitive match: "Yo" (capitalized, sentence-initial) is a
      // different string from "yo", so the lowercase "yo" after the comma
      // is occurrence 1 of "yo", not occurrence 2.
      final resolvedDeletion = resolveOccurrenceCorrections(submittedText, [
        const OccurrenceCorrection(originalPhrase: 'yo', occurrence: 1),
      ]).single;

      final firstPassResponse = await runStagedCorrectionPipeline(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: _RoutingHttpClient({
            stage1DetectionDialectSpanish: _arrayEnvelope(const []),
            stage1RedundancyDetectionSpanish: _arrayEnvelope(['"yo"']),
            stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
            stage2CategorizationSpanish: _arrayEnvelope([
              '{"original_phrase": "yo", "corrected_phrase": "", '
                  '"occurrence": 1, "category": "Grammar", "verdict": "error"}',
            ]),
            stage3FeedbackSpanish: _arrayEnvelope([
              '{"start_index": ${resolvedDeletion.startIndex}, '
                  '"short_explanation": "Redundant subject pronoun."}',
            ]),
          }),
        ),
        model: 'gpt-5.5',
        submittedText: submittedText,
      );
      // Confirms the fixture is genuinely a pronoun deletion (empty
      // correctedPhrase) before layering naturalness on top of it.
      expect(firstPassResponse.corrections.single.correctedPhrase, isEmpty);
      expect(
        firstPassResponse.correctedText,
        'Yo fui a casa, y hice una decisión importante.',
      );

      const issue = NaturalnessIssue(
        span: 'hice una decisión',
        naturalReplacement: 'tomé una decisión',
        explanation: 'Wrong collocation for "decisión".',
      );
      final merge = mergeNaturalnessReview(
        originalText: submittedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );
      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );

      expect(
        result.correctedText,
        'Yo fui a casa, y tomé una decisión importante.',
      );
      expect(result.corrections, hasLength(2));
      final deletionItem = result.corrections.firstWhere(
        (item) => item.originalPhrase == 'yo',
      );
      expect(deletionItem.correctedPhrase, isEmpty);
      final naturalnessItem = result.corrections.firstWhere(
        (item) => item.category == ErrorCategory.naturalLanguage,
      );
      expect(naturalnessItem.correctedPhrase, 'tomé una decisión');
    },
  );

  test(
    'missing naturalness span after the first pass changed that exact '
    'wording',
    () {
      const originalText = 'Ayer iso una decisión importante.';
      const firstPassCorrectedText = 'Ayer hizo una decisión importante.';

      final firstPassResponse = CorrectionResponse(
        originalText: originalText,
        correctedText: firstPassCorrectedText,
        corrections: const [],
      );

      // Span reflects the pre-first-pass (typo'd) wording — the parallel
      // naturalness pass reviewed originalText, which still had "iso", not
      // "hizo". That exact substring no longer exists in
      // firstPassCorrectedText at all.
      const issue = NaturalnessIssue(
        span: 'iso una decisión',
        naturalReplacement: 'tomó una decisión',
        explanation: '"Hacer una decisión" is a calque.',
      );
      final merge = mergeNaturalnessReview(
        originalText: originalText,
        firstPassCorrectedText: firstPassCorrectedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );

      expect(merge.appliedEdits, isEmpty);
      expect(merge.skippedEdits, hasLength(1));
      expect(
        merge.skippedEdits.single.reason,
        NaturalnessMergeSkipReason.spanNotFound,
      );
      // The merge still returns the unmodified first-pass text — a
      // conflict never means losing the safe first-pass corrections.
      expect(merge.finalCorrectedText, firstPassCorrectedText);

      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );
      expect(result.corrections, isEmpty);
      expect(result.correctedText, firstPassCorrectedText);
    },
  );

  test('overlapping naturalness edits: only the leftmost is applied', () {
    const firstPassCorrectedText = 'Voy a hacer una decisión importante hoy.';

    const issueEarly = NaturalnessIssue(
      span: 'hacer una decisión',
      naturalReplacement: 'tomar una decisión',
      explanation: 'Wrong collocation for "decisión".',
    );
    const issueLate = NaturalnessIssue(
      span: 'una decisión importante',
      naturalReplacement: 'una decisión clave',
      explanation: 'Overlaps the other candidate.',
    );

    final merge = mergeNaturalnessReview(
      originalText: 'placeholder',
      firstPassCorrectedText: firstPassCorrectedText,
      naturalnessReview: const NaturalnessReview(
        hasNaturalnessIssue: true,
        issues: [issueEarly, issueLate],
      ),
    );

    expect(
      merge.finalCorrectedText,
      'Voy a tomar una decisión importante hoy.',
    );
    expect(merge.appliedEdits, hasLength(1));
    expect(merge.appliedEdits.single.issue, same(issueEarly));
    expect(merge.skippedEdits, hasLength(1));
    expect(merge.skippedEdits.single.issue, same(issueLate));
    expect(
      merge.skippedEdits.single.reason,
      NaturalnessMergeSkipReason.overlapsAnotherEdit,
    );
  });

  test('no naturalness issue: the first-pass text passes through unchanged', () {
    const firstPassCorrectedText = 'Todo está muy bien.';

    final merge = mergeNaturalnessReview(
      originalText: firstPassCorrectedText,
      firstPassCorrectedText: firstPassCorrectedText,
      naturalnessReview: const NaturalnessReview(
        hasNaturalnessIssue: false,
        issues: [],
      ),
    );

    expect(merge.finalCorrectedText, firstPassCorrectedText);
    expect(merge.appliedEdits, isEmpty);
    expect(merge.skippedEdits, isEmpty);
  });

  group('malformed naturalness response', () {
    test('throws when has_naturalness_issue is missing', () {
      expect(
        () => NaturalnessReview.fromJson({
          'issues': [],
        }),
        throwsFormatException,
      );
    });

    test('throws when an issue is missing a required field', () {
      expect(
        () => NaturalnessReview.fromJson({
          'has_naturalness_issue': true,
          'issues': [
            {'span': 'x'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}

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
// request's system prompt — same hand-rolled approach as
// staged_correction_pipeline_test.dart.

class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient(this._repliesBySystemPrompt);

  final Map<String, String> _repliesBySystemPrompt;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _RoutingRequest(repliesBySystemPrompt: _repliesBySystemPrompt);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _RoutingRequest implements HttpClientRequest {
  _RoutingRequest({required this.repliesBySystemPrompt});

  final Map<String, String> repliesBySystemPrompt;
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
