import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/prompt_builder.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

void main() {
  OpenAiCorrectionService serviceWith(_CapturingHttpClient client) =>
      OpenAiCorrectionService(
        apiKey: 'test-key',
        model: 'gpt-5.5',
        httpClient: client,
      );

  group('gradeRetranslation', () {
    test('sends the grading system prompt and grading user content', () async {
      final client = _CapturingHttpClient(
        _responsesEnvelope(
          jsonEncode({
            'is_related': true,
            'corrected_text': 'Fui al mercado ayer.',
            'corrections': <Object?>[],
          }),
        ),
      );

      await serviceWith(client).gradeRetranslation(
        attempt: 'Voy al mercado ayer',
        expectedAnswer: 'Fui al mercado ayer',
        targetCategory: ErrorCategory.grammar,
        language: Language.spanish,
      );

      final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
      final input = sent['input'] as List;
      final systemMessage = input[0] as Map;
      final userMessage = input[1] as Map;

      expect(
        systemMessage['content'],
        PromptBuilder.gradingSystemPrompt(Language.spanish),
      );
      expect(userMessage['content'], contains('expectedAnswer: "Fui al mercado ayer"'));
      expect(userMessage['content'], contains('targetCategory: Grammar'));
      expect(userMessage['content'], contains('attempt: "Voy al mercado ayer"'));
    });

    test('sends the Portuguese grading system prompt for Portuguese', () async {
      final client = _CapturingHttpClient(
        _responsesEnvelope(
          jsonEncode({
            'is_related': true,
            'corrected_text': 'x',
            'corrections': <Object?>[],
          }),
        ),
      );

      await serviceWith(client).gradeRetranslation(
        attempt: 'a',
        expectedAnswer: 'b',
        targetCategory: ErrorCategory.other,
        language: Language.portuguese,
      );

      final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
      final input = sent['input'] as List;
      final systemMessage = input[0] as Map;

      expect(
        systemMessage['content'],
        PromptBuilder.gradingSystemPrompt(Language.portuguese),
      );
    });

    test('parses an is_related: true API response end-to-end', () async {
      final client = _CapturingHttpClient(
        _responsesEnvelope(
          jsonEncode({
            'is_related': true,
            'corrected_text': 'Fui al mercado ayer.',
            'corrections': [
              {
                'original_phrase': 'Voy',
                'corrected_phrase': 'Fui',
                'category': 'Grammar',
                'short_explanation': 'Use the preterite.',
              },
            ],
          }),
        ),
      );

      final result = await serviceWith(client).gradeRetranslation(
        attempt: 'Voy al mercado ayer',
        expectedAnswer: 'Fui al mercado ayer',
        targetCategory: ErrorCategory.grammar,
        language: Language.spanish,
      );

      expect(result.isRelated, isTrue);
      expect(result.correctedText, 'Fui al mercado ayer.');
      expect(result.corrections, hasLength(1));
      expect(result.corrections.single.originalPhrase, 'Voy');
    });

    test('parses an is_related: false API response end-to-end', () async {
      final client = _CapturingHttpClient(
        _responsesEnvelope(
          jsonEncode({
            'is_related': false,
            'corrected_text': 'Tomé el autobús a casa.',
            'corrections': <Object?>[],
          }),
        ),
      );

      final result = await serviceWith(client).gradeRetranslation(
        attempt: 'Tomé el autobús a casa',
        expectedAnswer: 'Fui al mercado ayer',
        targetCategory: ErrorCategory.grammar,
        language: Language.spanish,
      );

      expect(result.isRelated, isFalse);
      expect(result.corrections, isEmpty);
    });
  });

  group('correctText regression (unaffected by grading feature)', () {
    test('still parses a well-formed anchored correction response', () async {
      const submitted = 'Ayer yo fue al mercado.';
      final client = _CapturingHttpClient(
        _responsesEnvelope(
          jsonEncode({
            'original_text': submitted,
            'corrected_text': submitted,
            'corrections': <Object?>[],
          }),
        ),
      );

      final result = await serviceWith(client).correctText(
        submitted,
        Language.spanish,
      );

      expect(result.originalText, submitted);
      expect(result.correctedText, submitted);
      expect(result.corrections, isEmpty);

      final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
      final input = sent['input'] as List;
      expect(
        (input[0] as Map)['content'],
        PromptBuilder.correctionSystemPrompt(Language.spanish),
      );
      expect(
        (input[1] as Map)['content'],
        PromptBuilder.correctionUserContent(Language.spanish, submitted),
      );
    });
  });
}

/// Wraps [outputText] in the OpenAI `/v1/responses` `output_text` envelope.
String _responsesEnvelope(String outputText) =>
    jsonEncode({'output_text': outputText});

// ── Minimal dart:io HttpClient fake that captures the outgoing request body ──
//
// There is no HTTP-mocking dependency in the project; the same hand-rolled
// fake approach used for WalkthroughService's injectable HttpClient seam
// (test/services/walkthrough_service_test.dart) is used here, extended to
// capture the bytes written to the request so tests can assert on the
// outgoing prompt/content, not just the parsed response.

class _CapturingHttpClient implements HttpClient {
  _CapturingHttpClient(this._replyBody);

  final String _replyBody;
  _CapturingRequest? lastRequest;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final request = _CapturingRequest(replyBody: _replyBody);
    lastRequest = request;
    return request;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _CapturingRequest implements HttpClientRequest {
  _CapturingRequest({required this.replyBody});

  final String replyBody;
  final BytesBuilder _bytes = BytesBuilder();

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) => _bytes.add(data);

  String get bodyAsString => utf8.decode(_bytes.toBytes());

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(responseBody: replyBody);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
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
