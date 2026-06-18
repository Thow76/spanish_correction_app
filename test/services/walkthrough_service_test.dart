import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/models/walkthrough_exceptions.dart';
import 'package:spanish_correction_app/core/services/walkthrough_service.dart';

void main() {
  WalkthroughService serviceWith(_FakeHttpClient client) => WalkthroughService(
    apiKey: 'test-key',
    model: 'gpt-5.5',
    httpClient: client,
  );

  // A fake scripted to return the same bad body on both attempts. Since 5d
  // retries schema/validation failures once, a payload that must be rejected
  // has to fail on both calls for the exception to surface (a single reply
  // would let the retry exhaust the queue and throw StateError).
  _FakeHttpClient failsTwice(String body) =>
      _FakeHttpClient([_Reply.body(body), _Reply.body(body)]);

  Future<List<dynamic>> fetch(WalkthroughService service) => service.fetchQuestions(
    targetSentence: 'Voy al banco el viernes.',
    userAttempt: 'Voy a el banco en viernes.',
    englishSource: "I'm going to the bank on Friday.",
    corrections: const [],
    language: Language.spanish,
  );

  // For reconstruction tests, the targetSentence input is what matters — the
  // service compares chunks against this parameter, not the model's echoed
  // target_sentence field.
  Future<List<dynamic>> fetchTarget(
    WalkthroughService service,
    String targetSentence,
  ) => service.fetchQuestions(
    targetSentence: targetSentence,
    userAttempt: '',
    englishSource: '',
    corrections: const [],
    language: Language.spanish,
  );

  group('WalkthroughService.fetchQuestions', () {
    test('parses a well-formed envelope into WalkthroughQuestions', () async {
      final service = serviceWith(
        _FakeHttpClient.single(_envelope(_threeQuestions)),
      );

      final questions = await fetch(service);

      expect(questions, hasLength(3));

      expect(questions[0].englishStem, "I'm going");
      expect(questions[0].correctTranslation, 'Voy');
      expect(questions[0].distractors.first, 'Va');
      expect(questions[0].distractors.second, 'Vamos');
      expect(questions[0].chunkPosition, 0);

      expect(questions[1].correctTranslation, 'al banco');
      expect(questions[1].chunkPosition, 1);

      expect(questions[2].correctTranslation, 'el viernes');
      expect(questions[2].distractors.first, 'en viernes');
      expect(questions[2].chunkPosition, 2);
    });
  });

  // ── Fake-harness capability proofs ──────────────────────────────────────────
  //
  // These prove the HttpClient fake is fit to support the upcoming validation
  // (5b) and retry (5c) passes. They assert only transport/parse behaviour that
  // exists today — no semantic validation logic is added.

  group('fake harness — capability 1: arbitrary per-test body', () {
    test('an arbitrary body flows through to the parsed result verbatim', () async {
      // Distinct, contiguous payload (so 5b validation passes) with marker
      // distractors, proving the fake delivers an arbitrary body and the
      // service surfaces its contents unchanged.
      final body = _envelope([
        {
          'english_stem': "I'm going",
          'correct_translation': 'Voy',
          'distractors': ['marker-one', 'marker-two'],
          'chunk_position': 0,
        },
      ]);

      final questions = await fetchTarget(
        serviceWith(_FakeHttpClient.single(body)),
        'Voy',
      );

      expect(questions, hasLength(1));
      expect(questions[0].distractors.first, 'marker-one');
      expect(questions[0].distractors.second, 'marker-two');
    });
  });

  group('fake harness — capability 2: different responses per call', () {
    test('successive calls see successive responses in order', () async {
      final client = _FakeHttpClient([
        _Reply.body(_envelope(_oneQuestion('Voy'))),
        _Reply.body(_envelope(_oneQuestion('Quiero'))),
      ]);
      final service = serviceWith(client);

      final first = await fetchTarget(service, 'Voy');
      final second = await fetchTarget(service, 'Quiero');

      expect(first[0].correctTranslation, 'Voy');
      expect(second[0].correctTranslation, 'Quiero');
      expect(client.callCount, 2);
    });
  });

  group('fake harness — capability 3: transport / error paths', () {
    test('non-2xx status -> WalkthroughApiException', () async {
      final service = serviceWith(
        _FakeHttpClient([_Reply.body('upstream error', statusCode: 500)]),
      );

      await expectLater(
        fetch(service),
        throwsA(isA<WalkthroughApiException>()),
      );
    });

    test('a timeout -> WalkthroughApiException', () async {
      final service = serviceWith(
        _FakeHttpClient([_Reply.error(TimeoutException('slow'))]),
      );

      await expectLater(
        fetch(service),
        throwsA(isA<WalkthroughApiException>()),
      );
    });

    test('malformed OpenAI envelope -> WalkthroughApiException', () async {
      // Valid JSON object, but lacks output_text / output: an OpenAI-envelope
      // (transport) failure, not a walkthrough-content failure.
      final service = serviceWith(
        _FakeHttpClient.single('{"unexpected":"shape"}'),
      );

      await expectLater(
        fetch(service),
        throwsA(isA<WalkthroughApiException>()),
      );
    });

    test('malformed walkthrough content -> WalkthroughSchemaException', () async {
      // A valid OpenAI envelope wrapping a question with three distractors:
      // the content schema boundary, surfaced by the model at parse time.
      final body = _envelope([
        {
          'english_stem': "I'm going",
          'correct_translation': 'Voy',
          'distractors': ['Va', 'Vamos', 'Van'],
          'chunk_position': 0,
        },
      ]);
      final service = serviceWith(failsTwice(body));

      await expectLater(
        fetch(service),
        throwsA(isA<WalkthroughSchemaException>()),
      );
    });
  });

  // ── Pass 5b: distinctness + contiguity validation ───────────────────────────

  group('validation — distinctness', () {
    test('distractor equals correct_translation -> rejected', () async {
      final body = _envelope([
        _question('Voy', distractors: ['Voy', 'Vamos']),
      ]);

      await expectLater(
        fetch(serviceWith(failsTwice(body))),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('two identical distractors -> rejected', () async {
      final body = _envelope([
        _question('Voy', distractors: ['Va', 'Va']),
      ]);

      await expectLater(
        fetch(serviceWith(failsTwice(body))),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('distractor differing only by whitespace from correct -> rejected', () async {
      // " la  casa" normalises to "la casa" and so collides with the correct
      // answer after whitespace normalisation.
      final body = _envelope([
        _question('la casa', distractors: [' la  casa', 'una casa']),
      ]);

      await expectLater(
        fetch(serviceWith(failsTwice(body))),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });
  });

  group('validation — contiguity', () {
    test('chunk positions with a gap (0, 1, 3) -> rejected', () async {
      final body = _envelope([
        _question('Voy', position: 0),
        _question('al banco', position: 1),
        _question('el viernes', position: 3),
      ]);

      await expectLater(
        fetch(serviceWith(failsTwice(body))),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('chunk positions with a duplicate (0, 1, 1) -> rejected', () async {
      final body = _envelope([
        _question('Voy', position: 0),
        _question('al banco', position: 1),
        _question('el viernes', position: 1),
      ]);

      await expectLater(
        fetch(serviceWith(failsTwice(body))),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });
  });

  group('validation — cross-language disallowlist', () {
    test('a distractor exactly "Domani" -> rejected', () async {
      final body = _envelope([
        _question('amanhã', distractors: ['Domani', 'amanhá']),
      ]);

      await expectLater(
        fetch(serviceWith(failsTwice(body))),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('case/whitespace variant " tomorrow " -> still rejected', () async {
      final body = _envelope([
        _question('amanhã', distractors: [' tomorrow ', 'amanhá']),
      ]);

      await expectLater(
        fetch(serviceWith(failsTwice(body))),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('listed word as a substring inside a longer phrase -> NOT rejected', () async {
      // "hoy" appears inside a longer legitimate phrase; whole-value matching
      // must not reject it.
      final body = _envelope([
        _question('hoje de manhã', distractors: ['hoy de manhã', 'ontem']),
      ]);

      final questions = await fetchTarget(
        serviceWith(_FakeHttpClient.single(body)),
        'hoje de manhã',
      );

      expect(questions, hasLength(1));
      expect(questions[0].distractors.first, 'hoy de manhã');
    });
  });

  group('validation — reconstruction', () {
    test('chunks that concatenate exactly to the target -> passes', () async {
      final body = _envelope([
        _question('Voy', position: 0, distractors: ['Va', 'Vamos']),
        _question('al banco', position: 1, distractors: ['a el banco', 'en el banco']),
        _question('el viernes', position: 2, distractors: ['en viernes', 'el viernos']),
      ]);

      final questions = await fetchTarget(
        serviceWith(_FakeHttpClient.single(body)),
        'Voy al banco el viernes',
      );

      expect(questions, hasLength(3));
    });

    test('response dropped the trailing "." -> still passes', () async {
      // The core ~22% case: chunks reconstruct "Voy al banco el viernes" while
      // the target input carries the trailing period.
      final body = _envelope([
        _question('Voy', position: 0, distractors: ['Va', 'Vamos']),
        _question('al banco', position: 1, distractors: ['a el banco', 'en el banco']),
        _question('el viernes', position: 2, distractors: ['en viernes', 'el viernos']),
      ]);

      final questions = await fetchTarget(
        serviceWith(_FakeHttpClient.single(body)),
        'Voy al banco el viernes.',
      );

      expect(questions, hasLength(3));
    });

    test('chunks that do not cover the target -> rejected', () async {
      // Last chunk is the wrong word ("el sábado" vs "el viernes").
      final body = _envelope([
        _question('Voy', position: 0, distractors: ['Va', 'Vamos']),
        _question('al banco', position: 1, distractors: ['a el banco', 'en el banco']),
        _question('el sábado', position: 2, distractors: ['en sábado', 'el sabado']),
      ]);

      await expectLater(
        fetchTarget(
          serviceWith(failsTwice(body)),
          'Voy al banco el viernes.',
        ),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('Spanish leading ¿ and trailing ? omitted by chunks -> passes', () async {
      final body = _envelope([
        _question('Cómo', position: 0, distractors: ['Como', 'Cuándo']),
        _question('estás', position: 1, distractors: ['está', 'estáis']),
      ]);

      final questions = await fetchTarget(
        serviceWith(_FakeHttpClient.single(body)),
        '¿Cómo estás?',
      );

      expect(questions, hasLength(2));
    });

    test('internal comma present in both chunks and target -> passes', () async {
      // The comma is internal, not a trailing/leading sentence mark, so it must
      // survive normalisation on both sides.
      final body = _envelope([
        _question('Sí,', position: 0, distractors: ['Si', 'No,']),
        _question('claro', position: 1, distractors: ['claroo', 'clara']),
      ]);

      final questions = await fetchTarget(
        serviceWith(_FakeHttpClient.single(body)),
        'Sí, claro.',
      );

      expect(questions, hasLength(2));
    });
  });

  group('validation — clean response', () {
    test('distinct distractors + contiguous positions -> passes', () async {
      final questions = await fetch(
        serviceWith(_FakeHttpClient.single(_envelope(_threeQuestions))),
      );

      expect(questions, hasLength(3));
      expect(
        [for (final q in questions) q.chunkPosition],
        [0, 1, 2],
      );
    });
  });

  // ── Pass 5d: single retry on schema / validation failure ────────────────────

  group('retry', () {
    test('validation failure then clean -> succeeds, callCount == 2', () async {
      final client = _FakeHttpClient([
        _Reply.body(_envelope([_question('Voy', distractors: ['Va', 'Va'])])),
        _Reply.body(_envelope(_threeQuestions)),
      ]);

      final questions = await fetchTarget(
        serviceWith(client),
        'Voy al banco el viernes.',
      );

      expect(questions, hasLength(3));
      expect(client.callCount, 2);
    });

    test('schema failure then clean -> succeeds, callCount == 2', () async {
      final client = _FakeHttpClient([
        _Reply.body(
          _envelope([_question('Voy', distractors: ['Va', 'Vamos', 'Van'])]),
        ),
        _Reply.body(_envelope(_threeQuestions)),
      ]);

      final questions = await fetchTarget(
        serviceWith(client),
        'Voy al banco el viernes.',
      );

      expect(questions, hasLength(3));
      expect(client.callCount, 2);
    });

    test('both calls fail validation -> throws, callCount == 2 (no loop)', () async {
      final client = _FakeHttpClient([
        _Reply.body(_envelope([_question('Voy', distractors: ['Va', 'Va'])])),
        _Reply.body(_envelope([_question('Voy', distractors: ['Va', 'Va'])])),
      ]);
      final service = serviceWith(client);

      await expectLater(
        fetchTarget(service, 'Voy'),
        throwsA(isA<WalkthroughValidationException>()),
      );
      // Exactly two calls: stops after one retry rather than looping. A third
      // call would exhaust the reply queue and throw StateError instead.
      expect(client.callCount, 2);
    });

    test('first call already clean -> succeeds, callCount == 1', () async {
      final client = _FakeHttpClient([_Reply.body(_envelope(_threeQuestions))]);

      final questions = await fetchTarget(
        serviceWith(client),
        'Voy al banco el viernes.',
      );

      expect(questions, hasLength(3));
      expect(client.callCount, 1);
    });

    test('WalkthroughApiException is not retried -> callCount == 1', () async {
      final client = _FakeHttpClient([_Reply.body('error', statusCode: 500)]);
      final service = serviceWith(client);

      await expectLater(
        fetch(service),
        throwsA(isA<WalkthroughApiException>()),
      );
      // The new once-more retry only fires for schema/validation failures, so
      // an API failure makes a single call (a retry would exhaust the queue).
      expect(client.callCount, 1);
    });
  });
}

// ── Walkthrough payload builders ────────────────────────────────────────────

/// Wraps walkthrough [questions] in the OpenAI `/v1/responses` `output_text`
/// envelope the service reads.
String _envelope(List<Map<String, Object?>> questions) {
  final walkthroughJson = jsonEncode({
    'target_sentence': 'Voy al banco el viernes.',
    'questions': questions,
  });
  return jsonEncode({'output_text': walkthroughJson});
}

/// Builds a single question map with overridable distractors and position.
Map<String, Object?> _question(
  String correctTranslation, {
  List<String> distractors = const ['Va', 'Vamos'],
  int position = 0,
}) => {
  'english_stem': "I'm going",
  'correct_translation': correctTranslation,
  'distractors': distractors,
  'chunk_position': position,
};

List<Map<String, Object?>> _oneQuestion(String correctTranslation) => [
  {
    'english_stem': "I'm going",
    'correct_translation': correctTranslation,
    'distractors': ['Va', 'Vamos'],
    'chunk_position': 0,
  },
];

const List<Map<String, Object?>> _threeQuestions = [
  {
    'english_stem': "I'm going",
    'correct_translation': 'Voy',
    'distractors': ['Va', 'Vamos'],
    'chunk_position': 0,
  },
  {
    'english_stem': 'to the bank',
    'correct_translation': 'al banco',
    'distractors': ['a el banco', 'en el banco'],
    'chunk_position': 1,
  },
  {
    'english_stem': 'on Friday',
    'correct_translation': 'el viernes',
    'distractors': ['en viernes', 'el viernos'],
    'chunk_position': 2,
  },
];

// ── Minimal dart:io HttpClient fakes ────────────────────────────────────────
//
// There is no HTTP-mocking dependency in the project and no existing service
// test to mirror, so the injectable HttpClient seam (the same one
// OpenAiCorrectionService exposes) is satisfied with hand-rolled fakes. Each
// fake implements only the members the service touches and routes the rest
// through noSuchMethod.
//
// The fake is a per-call reply queue: each fetchQuestions makes exactly one
// postUrl call, which consumes the next [_Reply]. A reply either yields a body
// + status code or throws an error (e.g. TimeoutException) from close(), so
// tests can sequence successes/failures and exercise both exception boundaries.

/// One scripted outcome for a single API call: either a response (body +
/// status) or an error thrown from the request's close().
class _Reply {
  const _Reply.body(this.body, {this.statusCode = 200}) : error = null;
  const _Reply.error(this.error)
    : body = null,
      statusCode = 0;

  final String? body;
  final int statusCode;
  final Object? error;
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this._replies);

  _FakeHttpClient.single(String body, {int statusCode = 200})
    : _replies = [_Reply.body(body, statusCode: statusCode)];

  final List<_Reply> _replies;
  int _callCount = 0;

  int get callCount => _callCount;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    if (_callCount >= _replies.length) {
      throw StateError(
        'Fake HttpClient received call ${_callCount + 1} but only '
        '${_replies.length} reply(ies) were scripted.',
      );
    }
    final reply = _replies[_callCount];
    _callCount++;
    return _FakeHttpClientRequest(reply);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this._reply);

  final _Reply _reply;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async {
    final error = _reply.error;
    if (error != null) {
      throw error;
    }
    return _FakeHttpClientResponse(
      responseBody: _reply.body!,
      statusCode: _reply.statusCode,
    );
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
  _FakeHttpClientResponse({required String responseBody, required this.statusCode})
    : _body = responseBody;

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
