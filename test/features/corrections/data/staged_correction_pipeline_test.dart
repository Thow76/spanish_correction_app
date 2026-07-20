import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/staged_correction_pipeline.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

const _submittedText = 'Vi mucho trafico ayer.';

void main() {
  test(
    'runs Stage 1 -> Stage 1B -> Stage 2 -> position/insertion/dedup -> '
    'verdict split -> Stage 3 end to end and assembles a correct '
    'CorrectionResponse, via the real pipeline function with only the '
    'network layer faked',
    () async {
      final client = _RoutingHttpClient({
        stage1DetectionDialectSpanish: _arrayEnvelope(['"trafico"']),
        stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
        stage2CategorizationSpanish: _arrayEnvelope([
          '{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
              '"occurrence": 1, "category": "Spelling", "verdict": "error"}',
        ]),
        stage3FeedbackSpanish: _arrayEnvelope([
          '{"start_index": 9, "short_explanation": '
              '"Trafico needs an accent on the a: tráfico."}',
        ]),
      });

      final response = await runStagedCorrectionPipeline(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        submittedText: _submittedText,
      );

      expect(response.originalText, _submittedText);
      expect(response.correctedText, 'Vi mucho tráfico ayer.');
      expect(response.hasCorrections, isTrue);
      expect(response.notes, isEmpty);

      expect(response.corrections, hasLength(1));
      final correction = response.corrections.single;
      expect(correction.originalPhrase, 'trafico');
      expect(correction.correctedPhrase, 'tráfico');
      expect(correction.category, ErrorCategory.spelling);
      expect(
        correction.shortExplanation,
        'Trafico needs an accent on the a: tráfico.',
      );
      expect(correction.startIndex, 9);
      expect(correction.endIndex, 16);
      expect(correction.correctedStartIndex, 9);
      expect(correction.correctedEndIndex, 16);
    },
  );

  test(
    'returns an unchanged, no-corrections response when Stage 1 and Stage '
    '1B both flag nothing, without calling Stage 2 or Stage 3',
    () async {
      const cleanText = 'Todo está bien.';
      final client = _RoutingHttpClient({
        stage1DetectionDialectSpanish: _arrayEnvelope(const []),
        stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
      });

      final response = await runStagedCorrectionPipeline(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        submittedText: cleanText,
      );

      expect(response.originalText, cleanText);
      expect(response.correctedText, cleanText);
      expect(response.hasCorrections, isFalse);
      expect(response.notes, isEmpty);
      expect(response.corrections, isEmpty);
    },
  );

  test(
    'returns a no-corrections response without calling Stage 3, when Stage '
    '2 categorizes every flagged phrase as not_an_error',
    () async {
      const text = 'Vi el coche ayer.';
      final client = _RoutingHttpClient({
        stage1DetectionDialectSpanish: _arrayEnvelope(['"coche"']),
        stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
        stage2CategorizationSpanish: _arrayEnvelope([
          '{"original_phrase": "coche", "corrected_phrase": "coche", '
              '"occurrence": 1, "category": null, "verdict": "not_an_error"}',
        ]),
      });

      final response = await runStagedCorrectionPipeline(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        submittedText: text,
      );

      expect(response.originalText, text);
      expect(response.correctedText, text);
      expect(response.hasCorrections, isFalse);
      expect(response.notes, isEmpty);
      expect(response.corrections, isEmpty);
    },
  );

  test(
    'routes error, dialectal, and not_an_error verdicts from one Stage 2 '
    'response to their correct final destinations, through the real '
    'assembled pipeline end to end — the invariant step 7\'s unit test '
    'already proves, exercised here at the integration level instead of '
    'via a hand-called splitter',
    () async {
      const combinedText =
          'Vi mucho trafico y el autobús pasó. Tengo un coche.';
      final traficoIndex = combinedText.indexOf('trafico');
      final autobusIndex = combinedText.indexOf('autobús');

      final client = _RoutingHttpClient({
        stage1DetectionDialectSpanish: _arrayEnvelope([
          '"trafico"',
          '"autobús"',
          '"coche"',
        ]),
        stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
        stage2CategorizationSpanish: _arrayEnvelope([
          '{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
              '"occurrence": 1, "category": "Spelling", "verdict": "error"}',
          '{"original_phrase": "autobús", "corrected_phrase": "autobús", '
              '"occurrence": 1, "category": "Other", "verdict": "dialectal"}',
          '{"original_phrase": "coche", "corrected_phrase": "coche", '
              '"occurrence": 1, "category": null, "verdict": "not_an_error"}',
        ]),
        stage3FeedbackSpanish: _arrayEnvelope([
          '{"start_index": $traficoIndex, "short_explanation": '
              '"Trafico needs an accent on the a: tráfico."}',
          '{"start_index": $autobusIndex, "short_explanation": '
              '"Standard in Spain; called camión or guagua in parts of '
              'Latin America."}',
        ]),
      });

      final response = await runStagedCorrectionPipeline(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        submittedText: combinedText,
      );

      // Exactly the expected counts — nothing extra leaked through from the
      // not_an_error verdict, or from any mis-routing between corrections
      // and notes.
      expect(response.corrections, hasLength(1));
      expect(response.notes, hasLength(1));

      // error -> a real correction, positioned correctly, with its Stage 3
      // explanation attached.
      final correction = response.corrections.single;
      expect(correction.originalPhrase, 'trafico');
      expect(correction.correctedPhrase, 'tráfico');
      expect(correction.category, ErrorCategory.spelling);
      expect(
        correction.shortExplanation,
        'Trafico needs an accent on the a: tráfico.',
      );
      expect(correction.startIndex, traficoIndex);
      expect(correction.endIndex, traficoIndex + 'trafico'.length);

      // dialectal -> a note, never a correction, with its Stage 3
      // explanation as note text.
      final note = response.notes.single;
      expect(note.phrase, 'autobús');
      expect(
        note.note,
        'Standard in Spain; called camión or guagua in parts of Latin '
        'America.',
      );

      // not_an_error ("coche") must not appear anywhere in the final
      // result — not as a correction, not as a note.
      expect(
        response.corrections.any((item) => item.originalPhrase == 'coche'),
        isFalse,
      );
      expect(
        response.notes.any((n) => n.phrase == 'coche'),
        isFalse,
      );

      // correctedText reflects only the error correction — dialectal and
      // not_an_error never touch the text.
      expect(
        response.correctedText,
        'Vi mucho tráfico y el autobús pasó. Tengo un coche.',
      );
      expect(response.hasCorrections, isTrue);
    },
  );
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
// request's system prompt ──
//
// The pipeline makes up to four calls (Stage 1 and Stage 1B concurrently,
// then Stage 2, then Stage 3), each with a different, known system prompt.
// Routing by system-prompt content (read back from the request body at
// close() time) rather than by call order or call count keeps this fake
// correct regardless of which order calls actually complete in.

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
  _FakeHttpClientResponse({required String responseBody}) : _body = responseBody;

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
