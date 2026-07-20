import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/stage2_categorization_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  group('buildStage2UserContent', () {
    test('includes the full text and the flagged phrases as a JSON array', () {
      final content = buildStage2UserContent(
        fullText: 'Vi mucho trafico ayer.',
        flaggedPhrases: ['trafico', 'yo'],
      );

      expect(content, contains('Vi mucho trafico ayer.'));
      expect(content, contains(jsonEncode(['trafico', 'yo'])));
    });

    test('encodes an empty flagged-phrase list as []', () {
      final content = buildStage2UserContent(
        fullText: 'Todo está bien.',
        flaggedPhrases: const [],
      );

      expect(content, contains('[]'));
    });
  });

  group('parseStage2CategorizationArray', () {
    test('parses a populated array', () {
      final results = parseStage2CategorizationArray(
        '[{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
        '"occurrence": 1, "category": "Spelling", "verdict": "error"}]',
      );

      expect(results, hasLength(1));
      expect(results.single.originalPhrase, 'trafico');
      expect(results.single.correctedPhrase, 'tráfico');
      expect(results.single.occurrence, 1);
      expect(results.single.category, 'Spelling');
      expect(results.single.verdict, StagedCorrectionVerdict.error);
    });

    test('parses a null category for not_an_error', () {
      final results = parseStage2CategorizationArray(
        '[{"original_phrase": "coche", "corrected_phrase": "coche", '
        '"occurrence": 1, "category": null, "verdict": "not_an_error"}]',
      );

      expect(results.single.category, isNull);
      expect(results.single.verdict, StagedCorrectionVerdict.notAnError);
    });

    test('parses an empty array', () {
      expect(parseStage2CategorizationArray('[]'), isEmpty);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = parseStage2CategorizationArray(
        '```json\n[{"original_phrase": "trafico", "corrected_phrase": '
        '"tráfico", "occurrence": 1, "category": "Spelling", "verdict": '
        '"error"}]\n```',
      );
      expect(results, hasLength(1));
    });

    test('throws when no array is present', () {
      expect(
        () => parseStage2CategorizationArray('No errors found.'),
        throwsFormatException,
      );
    });

    test('throws when an element is missing original_phrase', () {
      expect(
        () => parseStage2CategorizationArray(
          '[{"corrected_phrase": "x", "occurrence": 1, "category": "Other", '
          '"verdict": "error"}]',
        ),
        throwsFormatException,
      );
    });

    test('throws when occurrence is not an integer', () {
      expect(
        () => parseStage2CategorizationArray(
          '[{"original_phrase": "x", "corrected_phrase": "y", '
          '"occurrence": "first", "category": "Other", "verdict": "error"}]',
        ),
        throwsFormatException,
      );
    });

    test('throws on an unrecognized verdict', () {
      expect(
        () => parseStage2CategorizationArray(
          '[{"original_phrase": "x", "corrected_phrase": "y", '
          '"occurrence": 1, "category": "Other", "verdict": "maybe"}]',
        ),
        throwsFormatException,
      );
    });
  });

  group('callStage2Categorization', () {
    test('sends the Stage 2 system prompt and the built user content, and '
        'parses the reply', () async {
      final client = _CapturingHttpClient(
        _categorizationEnvelope(
          '[{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
          '"occurrence": 1, "category": "Spelling", "verdict": "error"}]',
        ),
      );

      final result = await callStage2Categorization(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        fullText: 'Vi mucho trafico ayer.',
        flaggedPhrases: const ['trafico'],
      );

      expect(result, hasLength(1));
      expect(result.single.originalPhrase, 'trafico');
      expect(result.single.verdict, StagedCorrectionVerdict.error);

      final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
      final messages = sent['messages'] as List;
      expect(messages[0], {
        'role': 'system',
        'content': stage2CategorizationSpanish,
      });
      expect(
        messages[1]['content'],
        buildStage2UserContent(
          fullText: 'Vi mucho trafico ayer.',
          flaggedPhrases: const ['trafico'],
        ),
      );
    });
  });
}

/// Wraps [replyContent] (the JSON-array-shaped Stage 2 reply text) in a
/// minimal `/v1/chat/completions` response envelope.
String _categorizationEnvelope(String replyContent) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': replyContent},
    },
  ],
});

// ── Minimal dart:io HttpClient fake that captures the outgoing request body
// — same hand-rolled approach as the other stage client tests.

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
