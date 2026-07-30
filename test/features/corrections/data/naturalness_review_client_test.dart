import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';

import '../../../naturalness_model_comparison_harness.dart' as harness;

void main() {
  test(
    'naturalnessReviewSpanish is unchanged from the harness-validated prompt',
    () {
      // Issue #31's scope is explicitly to use the existing naturalness
      // prompt unchanged — this pins the production copy to the harness's
      // own (already model-validated) v3 wording character-for-character,
      // same precedent as the automated diff test described for
      // stage1DetectionDialectSpanish in correction_prompt.dart.
      expect(naturalnessReviewSpanish, harness.naturalnessSystemPrompt);
    },
  );

  group('buildNaturalnessUserContent', () {
    test('includes the review instruction and the text', () {
      final content = buildNaturalnessUserContent(
        'Ayer llamé para atrás a mi amigo.',
      );

      expect(content, contains('Review this Spanish text for naturalness only.'));
      expect(content, contains('Ayer llamé para atrás a mi amigo.'));
    });
  });

  group('parseNaturalnessReviewResponse', () {
    test('parses a valid no-issue reply', () {
      final review = parseNaturalnessReviewResponse(
        '{"has_naturalness_issue": false, "issues": []}',
      );

      expect(review.hasNaturalnessIssue, isFalse);
      expect(review.issues, isEmpty);
    });

    test('parses a valid reply with issues', () {
      final review = parseNaturalnessReviewResponse(
        '{"has_naturalness_issue": true, "issues": ['
        '{"span": "llamo para atrás", '
        '"natural_replacement": "te devuelvo la llamada", '
        '"explanation": "Calque of \\"call back\\"."}'
        ']}',
      );

      expect(review.hasNaturalnessIssue, isTrue);
      expect(review.issues.single.span, 'llamo para atrás');
    });

    test('tolerates Markdown fences and trailing commentary', () {
      final review = parseNaturalnessReviewResponse(
        '```json\n{"has_naturalness_issue": false, "issues": []}\n```\n'
        'That is the only issue.',
      );

      expect(review.hasNaturalnessIssue, isFalse);
    });

    test('throws when no JSON object is present', () {
      expect(
        () => parseNaturalnessReviewResponse('none'),
        throwsFormatException,
      );
    });

    test('throws when the contract is malformed', () {
      expect(
        () => parseNaturalnessReviewResponse('{"has_naturalness_issue": true}'),
        throwsFormatException,
      );
    });
  });

  group('callNaturalnessReview', () {
    test(
      'sends the naturalness system prompt and built user content, and '
      'parses the reply',
      () async {
        final client = _CapturingHttpClient(
          _naturalnessEnvelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "llamo para atrás", '
            '"natural_replacement": "te devuelvo la llamada", '
            '"explanation": "Calque of call back."}'
            ']}',
          ),
        );

        final result = await callNaturalnessReview(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: 'gpt-5.1',
          text: 'Ayer llamé para atrás a mi amigo.',
        );

        expect(result.hasNaturalnessIssue, isTrue);
        expect(result.issues.single.span, 'llamo para atrás');

        final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
        final messages = sent['messages'] as List;
        expect(messages[0], {
          'role': 'system',
          'content': naturalnessReviewSpanish,
        });
        expect(
          messages[1]['content'],
          buildNaturalnessUserContent('Ayer llamé para atrás a mi amigo.'),
        );
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
