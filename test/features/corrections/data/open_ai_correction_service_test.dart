import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/prompt_builder.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service_exception.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

void main() {
  OpenAiCorrectionService serviceWith(HttpClient client) =>
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
      expect(
        userMessage['content'],
        contains('expectedAnswer: "Fui al mercado ayer"'),
      );
      expect(userMessage['content'], contains('targetCategory: Grammar'));
      expect(
        userMessage['content'],
        contains('attempt: "Voy al mercado ayer"'),
      );
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
    test(
      'still parses a well-formed anchored correction response '
      '(Portuguese — the language still on the legacy single-call path)',
      () async {
        const submitted = 'Ontem eu fui ao mercado.';
        final client = _CapturingHttpClient(
          _responsesEnvelope(
            jsonEncode({
              'original_text': submitted,
              'corrected_text': submitted,
              'corrections': <Object?>[],
            }),
          ),
        );

        final result = await serviceWith(
          client,
        ).correctText(submitted, Language.portuguese);

        expect(result.originalText, submitted);
        expect(result.correctedText, submitted);
        expect(result.corrections, isEmpty);

        final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
        final input = sent['input'] as List;
        expect(
          (input[0] as Map)['content'],
          PromptBuilder.correctionSystemPrompt(Language.portuguese),
        );
        expect(
          (input[1] as Map)['content'],
          PromptBuilder.correctionUserContent(Language.portuguese, submitted),
        );
      },
    );
  });

  group('correctText Spanish staged pipeline', () {
    test(
      'Spanish routes through the real staged pipeline '
      '(network layer faked, same pattern as the pipeline\'s own tests)',
      () async {
        const submitted = 'Vi mucho trafico ayer.';
        final client = _RoutingHttpClient({
          stage1DetectionDialectSpanish: _arrayEnvelope(['"trafico"']),
          stage1RedundancyDetectionSpanish: _arrayEnvelope(const []),
          stage1ReflexiveDetectionSpanish: _arrayEnvelope(const []),
          stage2CategorizationSpanish: _arrayEnvelope([
            '{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
                '"occurrence": 1, "category": "Spelling", "verdict": "error"}',
          ]),
          stage3FeedbackSpanish: _arrayEnvelope([
            '{"start_index": 9, "short_explanation": '
                '"Trafico needs an accent on the a: tráfico."}',
          ]),
        });

        final result = await serviceWith(
          client,
        ).correctText(submitted, Language.spanish);

        expect(result.correctedText, 'Vi mucho tráfico ayer.');
        expect(result.corrections, hasLength(1));
        expect(result.corrections.single.originalPhrase, 'trafico');
        expect(result.corrections.single.category, ErrorCategory.spelling);

        // Every call went to the staged pipeline's endpoint — the legacy
        // path's /v1/responses was never hit.
        expect(client.requestedUris, isNotEmpty);
        expect(
          client.requestedUris.every(
            (uri) => uri.path == '/v1/chat/completions',
          ),
          isTrue,
        );
      },
    );

    test('Portuguese still uses the existing single-call path — there is no '
        'staged Portuguese pipeline', () async {
      const submitted = 'Oi, tudo bem?';
      final client = _CapturingHttpClient(
        _responsesEnvelope(
          jsonEncode({
            'original_text': submitted,
            'corrected_text': submitted,
            'corrections': <Object?>[],
          }),
        ),
      );

      final result = await serviceWith(
        client,
      ).correctText(submitted, Language.portuguese);

      expect(result.originalText, submitted);

      expect(client.requestedUris, hasLength(1));
      expect(client.requestedUris.single.path, '/v1/responses');

      final sent = jsonDecode(client.lastRequest!.bodyAsString) as Map;
      final input = sent['input'] as List;
      expect(
        (input[0] as Map)['content'],
        PromptBuilder.correctionSystemPrompt(Language.portuguese),
      );
    });
  });

  group('correctText failure classification parity (Spanish staged vs '
      'Portuguese legacy)', () {
    test('a SocketException classifies as networkUnavailable on BOTH paths, '
        'for the same underlying fault', () async {
      const fault = SocketException('Failed host lookup');

      Object? stagedError;
      try {
        await serviceWith(
          _ThrowingHttpClient(fault),
        ).correctText('Vi mucho trafico ayer.', Language.spanish);
      } catch (error) {
        stagedError = error;
      }

      Object? legacyError;
      try {
        await serviceWith(
          _ThrowingHttpClient(fault),
        ).correctText('Oi, tudo bem?', Language.portuguese);
      } catch (error) {
        legacyError = error;
      }

      expect(stagedError, isA<CorrectionServiceException>());
      expect(
        (stagedError as CorrectionServiceException).reason,
        CorrectionFailureReason.networkUnavailable,
      );

      expect(legacyError, isA<CorrectionServiceException>());
      expect(
        (legacyError as CorrectionServiceException).reason,
        CorrectionFailureReason.networkUnavailable,
      );
    });

    test('on the staged Spanish path, a TimeoutException classifies as '
        'apiFailure, not networkUnavailable — matching the legacy path\'s own '
        'treatment of a timeout as apiFailure', () async {
      final client = _ThrowingHttpClient(TimeoutException('timed out'));

      Object? caught;
      try {
        await serviceWith(
          client,
        ).correctText('Vi mucho trafico ayer.', Language.spanish);
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<CorrectionServiceException>());
      expect(
        (caught as CorrectionServiceException).reason,
        CorrectionFailureReason.apiFailure,
      );
    });

    test('on the staged Spanish path, a bad response (malformed JSON body) '
        'classifies as apiFailure, not networkUnavailable — the two failure '
        'kinds do not collapse into the same reason', () async {
      // A JSON array instead of an object — decodes fine but fails the
      // "root is an object" check, the same "API responded, just not
      // usably" case a non-2xx status represents.
      final client = _CapturingHttpClient(jsonEncode([1, 2, 3]));

      Object? caught;
      try {
        await serviceWith(
          client,
        ).correctText('Vi mucho trafico ayer.', Language.spanish);
      } catch (error) {
        caught = error;
      }

      expect(caught, isA<CorrectionServiceException>());
      expect(
        (caught as CorrectionServiceException).reason,
        CorrectionFailureReason.apiFailure,
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

  /// Every URL a request was opened against, in call order — used to prove
  /// which endpoint(s) a `correctText` call actually hit (the legacy path
  /// calls `/v1/responses` exactly once; the staged pipeline calls
  /// `/v1/chat/completions`, potentially several times).
  final List<Uri> requestedUris = [];

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    requestedUris.add(url);
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

/// Wraps a hand-written list of already-JSON-encoded array element strings
/// in a `/v1/chat/completions` reply envelope — same helper as
/// `staged_correction_pipeline_test.dart`, e.g. `_arrayEnvelope(['"trafico"'])`
/// -> a reply whose content is `["trafico"]`.
String _arrayEnvelope(List<String> elements) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': '[${elements.join(', ')}]'},
    },
  ],
});

// ── Minimal dart:io HttpClient fake that routes a reply by the outgoing
// request's system prompt, and records every requested URI ──
//
// Same fake as `staged_correction_pipeline_test.dart`'s `_RoutingHttpClient`,
// extended here to also track `requestedUris` so a test can prove every
// call went to `/v1/chat/completions` and never to the legacy
// `/v1/responses` endpoint.

class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient(this._repliesBySystemPrompt);

  final Map<String, String> _repliesBySystemPrompt;
  final List<Uri> requestedUris = [];

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    requestedUris.add(url);
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

/// Minimal fake that throws [exception] as soon as a request is opened —
/// simulating a failure that happens before any response is received at
/// all (a `SocketException` or `TimeoutException`), same fake as
/// `openai_chat_completions_client_test.dart`'s `_ThrowingHttpClient`.
/// Works for both the legacy path (`/v1/responses`, single call) and the
/// staged path (`/v1/chat/completions`, first call fails the same way)
/// since the fault happens at `postUrl`, before either path's endpoint
/// even matters.
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
