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

  // A fake scripted to return the same bad body on both attempts. Since the
  // service retries schema/validation failures once, a payload that must be
  // rejected has to fail on both calls for the exception to surface (a single
  // reply would let the retry exhaust the queue and throw StateError).
  _FakeHttpClient failsTwice(String body) =>
      _FakeHttpClient([_Reply.body(body), _Reply.body(body)]);

  // 'Voy al banco el viernes.' mechanically chunks to exactly these 3 chunks
  // (chunkSentence: 'Voy' | 'al banco' | 'el viernes' — verified in
  // test/core/text/phrase_chunker_test.dart). Every helper/body below that
  // targets this sentence must supply exactly 3 question entries, one per
  // chunk, in order.
  Future<List<dynamic>> fetch(WalkthroughService service) => service.fetchQuestions(
    targetSentence: 'Voy al banco el viernes.',
    userAttempt: 'Voy a el banco en viernes.',
    englishSource: "I'm going to the bank on Friday.",
    corrections: const [],
    language: Language.spanish,
  );

  // For single-chunk cases, [targetSentence] should be a bare word or a
  // function-word + noun pair so chunkSentence collapses it to exactly one
  // chunk — the service now derives correctTranslation/chunkPosition from the
  // chunker, not from the response body, so the question array length must
  // match the chunker's output length.
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

    test(
      'correctTranslation/chunkPosition come from the mechanical chunker, '
      'not from the response body — an extra correct_translation/chunk_position '
      'field in the JSON is ignored',
      () async {
        final body = _envelope([
          {
            'english_stem': "I'm going",
            'distractors': ['Va', 'Vamos'],
            // Smuggled fields the parser no longer reads.
            'correct_translation': 'IGNORE ME',
            'chunk_position': 99,
          },
        ]);

        final questions = await fetchTarget(
          serviceWith(_FakeHttpClient.single(body)),
          'Voy',
        );

        expect(questions, hasLength(1));
        expect(questions[0].correctTranslation, 'Voy');
        expect(questions[0].chunkPosition, 0);
      },
    );
  });

  // ── Fake-harness capability proofs ──────────────────────────────────────────

  group('fake harness — capability 1: arbitrary per-test body', () {
    test('an arbitrary body flows through to the parsed result verbatim', () async {
      final body = _envelope([
        _question(distractors: ['marker-one', 'marker-two']),
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
        _Reply.body(_envelope([_question(distractors: ['Va', 'Vamos'])])),
        _Reply.body(_envelope([_question(distractors: ['Quiere', 'Quieren'])])),
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

    test(
      'a question with three distractors -> WalkthroughSchemaException',
      () async {
        // Single-chunk target so the entry count matches the chunker's
        // output (1) and the only violation is the distractor count.
        final body = _envelope([
          _question(distractors: ['Va', 'Vamos', 'Van']),
        ]);
        final service = serviceWith(failsTwice(body));

        await expectLater(
          fetchTarget(service, 'Voy'),
          throwsA(isA<WalkthroughSchemaException>()),
        );
      },
    );

    test(
      'a question array shorter than the chunk count -> WalkthroughSchemaException',
      () async {
        // Target chunks to 3 ('Voy' | 'al banco' | 'el viernes') but only 1
        // question is supplied.
        final body = _envelope([_question(distractors: ['Va', 'Vamos'])]);
        final service = serviceWith(failsTwice(body));

        await expectLater(
          fetch(service),
          throwsA(isA<WalkthroughSchemaException>()),
        );
      },
    );
  });

  // ── Semantic validation: distractor distinctness + cross-language disallowlist ──

  group('validation — distinctness', () {
    test('distractor equals the chunk text -> rejected', () async {
      final body = _envelope([_question(distractors: ['Voy', 'Vamos'])]);

      await expectLater(
        fetchTarget(serviceWith(failsTwice(body)), 'Voy'),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('two identical distractors -> rejected', () async {
      final body = _envelope([_question(distractors: ['Va', 'Va'])]);

      await expectLater(
        fetchTarget(serviceWith(failsTwice(body)), 'Voy'),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('distractor differing only by whitespace from the chunk -> rejected', () async {
      // " la  casa" normalises to "la casa" and so collides with the chunk
      // text ('la' binds forward to 'casa' -> one chunk 'la casa').
      final body = _envelope([
        _question(distractors: [' la  casa', 'una casa']),
      ]);

      await expectLater(
        fetchTarget(serviceWith(failsTwice(body)), 'la casa'),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });
  });

  group('validation — cross-language disallowlist', () {
    test('a distractor exactly "Domani" -> rejected', () async {
      final body = _envelope([_question(distractors: ['Domani', 'amanhá'])]);

      await expectLater(
        fetchTarget(serviceWith(failsTwice(body)), 'amanhã'),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('case/whitespace variant " tomorrow " -> still rejected', () async {
      final body = _envelope([
        _question(distractors: [' tomorrow ', 'amanhá']),
      ]);

      await expectLater(
        fetchTarget(serviceWith(failsTwice(body)), 'amanhã'),
        throwsA(isA<WalkthroughValidationException>()),
      );
    });

    test('listed word as a substring inside a longer phrase -> NOT rejected', () async {
      // "hoy" appears inside a longer legitimate phrase; whole-value matching
      // must not reject it.
      final body = _envelope([
        _question(distractors: ['hoy de manhã', 'ontem']),
      ]);

      final questions = await fetchTarget(
        serviceWith(_FakeHttpClient.single(body)),
        'manhã',
      );

      expect(questions, hasLength(1));
      expect(questions[0].distractors.first, 'hoy de manhã');
    });
  });

  group('validation — clean response', () {
    test('distinct distractors -> passes, chunk positions are contiguous', () async {
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

  // ── Single retry on schema / validation failure ─────────────────────────────

  group('retry', () {
    test('validation failure then clean -> succeeds, callCount == 2', () async {
      final client = _FakeHttpClient([
        _Reply.body(_envelope([_question(distractors: ['Va', 'Va'])])),
        _Reply.body(_envelope([_question(distractors: ['Va', 'Vamos'])])),
      ]);

      final questions = await fetchTarget(serviceWith(client), 'Voy');

      expect(questions, hasLength(1));
      expect(client.callCount, 2);
    });

    test('schema failure then clean -> succeeds, callCount == 2', () async {
      final client = _FakeHttpClient([
        _Reply.body(_envelope([_question(distractors: ['Va', 'Vamos', 'Van'])])),
        _Reply.body(_envelope([_question(distractors: ['Va', 'Vamos'])])),
      ]);

      final questions = await fetchTarget(serviceWith(client), 'Voy');

      expect(questions, hasLength(1));
      expect(client.callCount, 2);
    });

    test('both calls fail validation -> throws, callCount == 2 (no loop)', () async {
      final client = _FakeHttpClient([
        _Reply.body(_envelope([_question(distractors: ['Va', 'Va'])])),
        _Reply.body(_envelope([_question(distractors: ['Va', 'Va'])])),
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

      final questions = await fetch(serviceWith(client));

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
      // The once-more retry only fires for schema/validation failures, so an
      // API failure makes a single call (a retry would exhaust the queue).
      expect(client.callCount, 1);
    });
  });

  group('empty target sentence', () {
    test('no chunks can be derived -> WalkthroughSchemaException, no API call', () async {
      final client = _FakeHttpClient([]);

      await expectLater(
        fetchTarget(serviceWith(client), '   '),
        throwsA(isA<WalkthroughSchemaException>()),
      );
      expect(client.callCount, 0);
    });
  });
}

// ── Walkthrough payload builders ────────────────────────────────────────────

/// Wraps walkthrough [questions] in the OpenAI `/v1/responses` `output_text`
/// envelope the service reads.
String _envelope(List<Map<String, Object?>> questions) {
  final walkthroughJson = jsonEncode({'questions': questions});
  return jsonEncode({'output_text': walkthroughJson});
}

/// Builds a single `{english_stem, distractors}` question map — the only
/// fields the model supplies now that chunk text/position come from
/// chunkSentence rather than the response.
Map<String, Object?> _question({
  String englishStem = "I'm going",
  List<String> distractors = const ['Va', 'Vamos'],
}) => {'english_stem': englishStem, 'distractors': distractors};

/// Three questions matching the 3 chunks 'Voy al banco el viernes.'
/// mechanically produces ('Voy' | 'al banco' | 'el viernes').
const List<Map<String, Object?>> _threeQuestions = [
  {
    'english_stem': "I'm going",
    'distractors': ['Va', 'Vamos'],
  },
  {
    'english_stem': 'to the bank',
    'distractors': ['a el banco', 'en el banco'],
  },
  {
    'english_stem': 'on Friday',
    'distractors': ['en viernes', 'el viernos'],
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
