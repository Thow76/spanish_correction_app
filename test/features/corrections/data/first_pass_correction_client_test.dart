import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';

void main() {
  group('parseFirstPassCorrectionResponse', () {
    test('parses a valid reply', () {
      final correctedText = parseFirstPassCorrectionResponse(
        '{"corrected_text": "Los niños comen muchas manzanas."}',
      );

      expect(correctedText, 'Los niños comen muchas manzanas.');
    });

    test('tolerates Markdown fences and trailing commentary', () {
      final correctedText = parseFirstPassCorrectionResponse(
        '```json\n{"corrected_text": "Hola."}\n```\nThat is the fix.',
      );

      expect(correctedText, 'Hola.');
    });

    test('throws when no JSON object is present', () {
      expect(
        () => parseFirstPassCorrectionResponse('none'),
        throwsFormatException,
      );
    });

    test('throws when the reply does not decode to an object', () {
      expect(
        () => parseFirstPassCorrectionResponse('[1, 2, 3]'),
        throwsFormatException,
      );
    });

    test('throws when corrected_text is missing', () {
      expect(
        () => parseFirstPassCorrectionResponse('{"other_field": "x"}'),
        throwsFormatException,
      );
    });

    test('throws when corrected_text is not a string', () {
      expect(
        () => parseFirstPassCorrectionResponse('{"corrected_text": 5}'),
        throwsFormatException,
      );
    });
  });

  group('callFirstPassCorrection', () {
    test(
      'sends the first-pass system prompt, built user content, and '
      'response_format, and returns a CorrectionResponse with no '
      'corrections',
      () async {
        final client = _CapturingHttpClient(
          _firstPassEnvelope(
            '{"corrected_text": "Los niños comen muchas manzanas."}',
          ),
        );

        final result = await callFirstPassCorrection(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: 'gpt-4.1',
          submittedText: 'Los niño come muchas manzana.',
        );

        expect(result.originalText, 'Los niño come muchas manzana.');
        expect(result.correctedText, 'Los niños comen muchas manzanas.');
        expect(result.corrections, isEmpty);

        final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
        final messages = sent['messages'] as List;
        expect(messages[0], {
          'role': 'system',
          'content': firstPassCorrectionSpanish,
        });
        expect(
          messages[1]['content'],
          buildFirstPassCorrectionUserContent('Los niño come muchas manzana.'),
        );
        expect(sent['response_format'], firstPassCorrectionResponseFormat);
      },
    );
  });
}

/// Wraps [replyContent] (the JSON-object-shaped first-pass reply text) in
/// a minimal `/v1/chat/completions` response envelope.
String _firstPassEnvelope(String replyContent) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': replyContent},
    },
  ],
});

// ── Minimal dart:io HttpClient fake that captures the outgoing request
// body — same hand-rolled approach as the other stage client tests.

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
