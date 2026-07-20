import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';

void main() {
  test('sends the model, system/user messages, and auth header', () async {
    final client = _CapturingHttpClient(
      _chatCompletionsEnvelope('¡Hola!'),
    );

    await OpenAiChatCompletionsClient(
      apiKey: 'test-key',
      httpClient: client,
    ).complete(
      model: 'gpt-5.5',
      systemPrompt: 'You are a Spanish tutor.',
      userText: 'Como estas?',
    );

    final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
    final messages = sent['messages'] as List;

    expect(sent['model'], 'gpt-5.5');
    expect(messages[0], {
      'role': 'system',
      'content': 'You are a Spanish tutor.',
    });
    expect(messages[1], {'role': 'user', 'content': 'Como estas?'});
    expect(
      client.lastRequest!.headers.value(HttpHeaders.authorizationHeader),
      'Bearer test-key',
    );
  });

  test('returns the trimmed assistant reply text', () async {
    final client = _CapturingHttpClient(
      _chatCompletionsEnvelope('  ¡Hola! ¿Qué tal?  '),
    );

    final reply = await OpenAiChatCompletionsClient(
      apiKey: 'test-key',
      httpClient: client,
    ).complete(model: 'gpt-5.5', systemPrompt: 'sys', userText: 'user');

    expect(reply, '¡Hola! ¿Qué tal?');
  });

  test('throws on a non-2xx HTTP status', () async {
    final client = _CapturingHttpClient('upstream error', statusCode: 500);

    await expectLater(
      () => OpenAiChatCompletionsClient(
        apiKey: 'test-key',
        httpClient: client,
      ).complete(model: 'gpt-5.5', systemPrompt: 'sys', userText: 'user'),
      throwsA(isA<ChatCompletionsException>()),
    );
  });

  test('throws when the response root is not a JSON object', () async {
    final client = _CapturingHttpClient(jsonEncode([1, 2, 3]));

    await expectLater(
      () => OpenAiChatCompletionsClient(
        apiKey: 'test-key',
        httpClient: client,
      ).complete(model: 'gpt-5.5', systemPrompt: 'sys', userText: 'user'),
      throwsA(isA<ChatCompletionsException>()),
    );
  });

  test('throws when choices is missing or empty', () async {
    final client = _CapturingHttpClient(jsonEncode({'choices': <Object?>[]}));

    await expectLater(
      () => OpenAiChatCompletionsClient(
        apiKey: 'test-key',
        httpClient: client,
      ).complete(model: 'gpt-5.5', systemPrompt: 'sys', userText: 'user'),
      throwsA(isA<ChatCompletionsException>()),
    );
  });

  test('throws when the first choice has no message', () async {
    final client = _CapturingHttpClient(
      jsonEncode({
        'choices': [
          {'index': 0},
        ],
      }),
    );

    await expectLater(
      () => OpenAiChatCompletionsClient(
        apiKey: 'test-key',
        httpClient: client,
      ).complete(model: 'gpt-5.5', systemPrompt: 'sys', userText: 'user'),
      throwsA(isA<ChatCompletionsException>()),
    );
  });

  test('throws when the message content is missing or empty', () async {
    final client = _CapturingHttpClient(
      jsonEncode({
        'choices': [
          {
            'message': {'content': '   '},
          },
        ],
      }),
    );

    await expectLater(
      () => OpenAiChatCompletionsClient(
        apiKey: 'test-key',
        httpClient: client,
      ).complete(model: 'gpt-5.5', systemPrompt: 'sys', userText: 'user'),
      throwsA(isA<ChatCompletionsException>()),
    );
  });

  group('ChatCompletionsException.kind classification', () {
    Future<ChatCompletionsException> completeAndCaptureException(
      HttpClient client,
    ) async {
      try {
        await OpenAiChatCompletionsClient(
          apiKey: 'test-key',
          httpClient: client,
        ).complete(model: 'gpt-5.5', systemPrompt: 'sys', userText: 'user');
      } on ChatCompletionsException catch (error) {
        return error;
      }
      fail('Expected a ChatCompletionsException to be thrown.');
    }

    test('a SocketException classifies as connectivity', () async {
      final client = _ThrowingHttpClient(
        const SocketException('Failed host lookup'),
      );

      final error = await completeAndCaptureException(client);

      expect(error.kind, ChatCompletionsFailureKind.connectivity);
    });

    test(
      'a TimeoutException classifies as serviceFailure, not connectivity — '
      'matching the legacy /v1/responses path, which treats a timeout as '
      'apiFailure rather than networkUnavailable',
      () async {
        final client = _ThrowingHttpClient(
          TimeoutException('timed out'),
        );

        final error = await completeAndCaptureException(client);

        expect(error.kind, ChatCompletionsFailureKind.serviceFailure);
      },
    );

    test('a non-2xx HTTP status classifies as serviceFailure', () async {
      final client = _CapturingHttpClient('upstream error', statusCode: 500);

      final error = await completeAndCaptureException(client);

      expect(error.kind, ChatCompletionsFailureKind.serviceFailure);
    });

    test('malformed JSON classifies as serviceFailure', () async {
      final client = _CapturingHttpClient(jsonEncode([1, 2, 3]));

      final error = await completeAndCaptureException(client);

      expect(error.kind, ChatCompletionsFailureKind.serviceFailure);
    });
  });
}

/// Wraps [content] in a minimal `/v1/chat/completions` response envelope.
String _chatCompletionsEnvelope(String content) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': content},
    },
  ],
});

// ── Minimal dart:io HttpClient fake that captures the outgoing request and
// returns a configurable status code ──
//
// Same hand-rolled fake approach as
// test/features/corrections/data/open_ai_correction_service_test.dart,
// extended with a configurable status code so non-2xx handling can be
// exercised without a real HTTP dependency.

class _CapturingHttpClient implements HttpClient {
  _CapturingHttpClient(this._replyBody, {this.statusCode = 200});

  final String _replyBody;
  final int statusCode;
  _CapturingRequest? lastRequest;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final request = _CapturingRequest(
      replyBody: _replyBody,
      statusCode: statusCode,
    );
    lastRequest = request;
    return request;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _CapturingRequest implements HttpClientRequest {
  _CapturingRequest({required this.replyBody, required this.statusCode});

  final String replyBody;
  final int statusCode;
  final BytesBuilder _bytes = BytesBuilder();

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) => _bytes.add(data);

  String get bodyAsString => utf8.decode(_bytes.toBytes());

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(
      responseBody: replyBody,
      statusCode: statusCode,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, String> _values = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name.toLowerCase()] = value.toString();
  }

  @override
  String? value(String name) => _values[name.toLowerCase()];

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({
    required String responseBody,
    required this.statusCode,
  }) : _body = responseBody;

  final String _body;

  @override
  final int statusCode;

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

/// Minimal fake that throws [exception] as soon as a request is opened —
/// simulating a failure that happens before any response is received at
/// all (a `SocketException` or `TimeoutException`), rather than a bad
/// response arriving.
class _ThrowingHttpClient implements HttpClient {
  _ThrowingHttpClient(this.exception);

  final Object exception;

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    throw exception;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
