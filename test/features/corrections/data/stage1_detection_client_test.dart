import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/stage1_detection_client.dart';

void main() {
  group('parseStage1DetectionArray', () {
    test('parses a populated array of quoted phrases', () {
      final result = parseStage1DetectionArray(
        '["volví para casa", "trafico"]',
      );

      expect(result, ['volví para casa', 'trafico']);
    });

    test('parses an empty array', () {
      expect(parseStage1DetectionArray('[]'), isEmpty);
    });

    test('tolerates Markdown fences and trailing commentary', () {
      final result = parseStage1DetectionArray(
        '```json\n["trafico"]\n```\nThat is the only issue.',
      );

      expect(result, ['trafico']);
    });

    test('throws when no array is present', () {
      expect(
        () => parseStage1DetectionArray('none'),
        throwsFormatException,
      );
    });

    test('throws when an element is not a string', () {
      expect(
        () => parseStage1DetectionArray('["trafico", 5]'),
        throwsFormatException,
      );
    });
  });

  group('mergeStage1FlaggedPhrases', () {
    test('concatenates Stage 1 before Stage 1B, order preserved', () {
      final merged = mergeStage1FlaggedPhrases(
        stage1DetectionFlagged: ['trafico', 'volví para casa'],
        stage1RedundancyFlagged: ['yo', 'a mí'],
      );

      expect(merged, ['trafico', 'volví para casa', 'yo', 'a mí']);
    });

    test('leaves duplicates between the two lists untouched', () {
      final merged = mergeStage1FlaggedPhrases(
        stage1DetectionFlagged: ['yo'],
        stage1RedundancyFlagged: ['yo'],
      );

      expect(merged, ['yo', 'yo']);
    });

    test('handles either list being empty', () {
      expect(
        mergeStage1FlaggedPhrases(
          stage1DetectionFlagged: const [],
          stage1RedundancyFlagged: ['yo'],
        ),
        ['yo'],
      );
      expect(
        mergeStage1FlaggedPhrases(
          stage1DetectionFlagged: ['trafico'],
          stage1RedundancyFlagged: const [],
        ),
        ['trafico'],
      );
    });
  });

  group('callStage1Detection', () {
    test('sends the given system prompt and submitted text, and parses the '
        'reply', () async {
      final client = _RoutingHttpClient({
        stage1DetectionDialectSpanish: _detectionEnvelope(['trafico']),
      });

      final result = await callStage1Detection(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        systemPrompt: stage1DetectionDialectSpanish,
        submittedText: 'Vi mucho trafico ayer.',
      );

      expect(result, ['trafico']);
      final sent = jsonDecode(client.lastRequestBody!) as Map;
      final messages = sent['messages'] as List;
      expect(messages[0], {
        'role': 'system',
        'content': stage1DetectionDialectSpanish,
      });
      expect(messages[1], {
        'role': 'user',
        'content': 'Vi mucho trafico ayer.',
      });
    });
  });

  group('callStage1AndMergeFlaggedPhrases', () {
    test('calls Stage 1 and Stage 1B and merges their flagged phrases', () async {
      final client = _RoutingHttpClient({
        stage1DetectionDialectSpanish: _detectionEnvelope(['trafico']),
        stage1RedundancyDetectionSpanish: _detectionEnvelope(['yo', 'a mí']),
      });

      final result = await callStage1AndMergeFlaggedPhrases(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        submittedText: 'Yo vi mucho trafico, a mí me pareció mucho.',
      );

      expect(result, ['trafico', 'yo', 'a mí']);
    });

    test('handles Stage 1 flagging nothing but Stage 1B flagging something', () async {
      final client = _RoutingHttpClient({
        stage1DetectionDialectSpanish: _detectionEnvelope(const []),
        stage1RedundancyDetectionSpanish: _detectionEnvelope(['yo']),
      });

      final result = await callStage1AndMergeFlaggedPhrases(
        client: OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ),
        model: 'gpt-5.5',
        submittedText: 'Yo fui a la tienda.',
      );

      expect(result, ['yo']);
    });
  });
}

/// Wraps [phrases] in a minimal `/v1/chat/completions` reply envelope whose
/// content is the JSON array Stage 1 is expected to return.
String _detectionEnvelope(List<String> phrases) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': jsonEncode(phrases)},
    },
  ],
});

// ── Minimal dart:io HttpClient fake that routes a reply by the outgoing
// request's system prompt ──
//
// Stage 1 and Stage 1B are called concurrently with different system
// prompts but the same transport; routing by system-prompt content (read
// back from the request body at close() time, once all bytes have been
// written) rather than by call order keeps this test independent of
// whichever call happens to reach the fake first.

class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient(this._repliesBySystemPrompt);

  final Map<String, String> _repliesBySystemPrompt;
  String? lastRequestBody;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _RoutingRequest(
      repliesBySystemPrompt: _repliesBySystemPrompt,
      onBodyCaptured: (body) => lastRequestBody = body,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _RoutingRequest implements HttpClientRequest {
  _RoutingRequest({
    required this.repliesBySystemPrompt,
    required this.onBodyCaptured,
  });

  final Map<String, String> repliesBySystemPrompt;
  final void Function(String body) onBodyCaptured;
  final BytesBuilder _bytes = BytesBuilder();

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) => _bytes.add(data);

  @override
  Future<HttpClientResponse> close() async {
    final body = utf8.decode(_bytes.toBytes());
    onBodyCaptured(body);

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
