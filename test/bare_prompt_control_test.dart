// Bare-prompt control test.
//
// Isolates whether specific phrases (particularly Portuguese "ligaram de
// volta", caught 0/10 by the in-app harness) fail because of genuine LLM
// softness, or because the app's 5-category JSON schema suppresses
// detection under uncertainty. Calls the OpenAI chat completions endpoint
// directly with a bare, minimal proofreading instruction — no JSON schema,
// no category system.
//
// STANDALONE — must NOT import PromptBuilder, CorrectionService,
// OpenAiCorrectionService, AppConfig, or any other `lib/` code, so results
// can't be contaminated by app-specific prompt engineering. Verify with:
//   grep -n "^import" test/bare_prompt_control_test.dart
// (only `dart:*` and `package:flutter_test`/`package:test` imports allowed).
//
// This deliberately targets the classic chat completions endpoint
// (/v1/chat/completions, `choices[0].message.content`), not the Responses
// API endpoint (/v1/responses, `output_text`) that
// OpenAiCorrectionService uses — a different response shape is part of the
// decoupling, not an oversight.
//
// Step 1 (done): scaffold — system prompt constant, phrase fixtures,
// run-count/delay/output constants, and a shape-check test.
//
// Post-Step-5 expansion (full battery): the phrase fixture list was
// expanded from the original 5 (PT-1, PT-2, PT-3, PT-4, ES-2) to the full
// 12-phrase battery — ES-1..ES-6, PT-1..PT-6 — matching
// correction_consistency_harness.dart's fixture list exactly (same ids,
// same verbatim text, same order), so the bare-prompt control covers every
// case the schema-based harness does. Text for all 12 was copied verbatim
// from that file, not retyped, to guarantee identical wording.
// Step 2 (done): request-body builder (buildChatCompletionsBody), pure —
// returns the raw JSON-able map for a chat completions call, with no
// `response_format`/schema key anywhere.
// Step 3 (done): response parser (extractReplyText), pure — pulls
// `choices[0].message.content` out of a decoded chat completions body,
// throwing a clear FormatException on any unexpected shape rather than
// returning a blank string.
// Step 4 (done): markdown report writer (_buildReport), pure — takes
// already-collected raw replies (each already either a reply string or a
// pre-formatted "ERROR — ..." string) and returns the report. No
// scoring/aggregation — this is for manual read-through, per the
// decomposition. Golden-tested against a captured fixture string.
// Step 5 (done): live-call wiring. The final `test(...)` in main() below,
// tagged 'live', builds its own HttpClient and POSTs directly to
// https://api.openai.com/v1/chat/completions — no OpenAiCorrectionService,
// no AppConfig. Auth reads OPENAI_API_KEY from Platform.environment ONLY
// (no hardcoded fallback, unlike AppConfig); fails cleanly via fail(...)
// if unset.
//
// Category-tag variant (this addition): tests whether a soft, non-enforced
// category ask degrades detection reliability versus the plain-proofreader
// baseline. `systemPrompt` now appends a second paragraph asking for a
// best-guess category tag after each explanation, explicitly told not to
// gate or change the underlying evaluation — unlike the app's schema,
// there is no enforcement, no fixed category enum, and omitting the tag
// entirely is not an error. Everything else (12-phrase battery, 10 runs,
// gpt-5.5 default, 'live' tag) is unchanged from the baseline. Output goes
// to a distinctly-named file (see outputPath below) so the original
// baseline report is never overwritten and both are diffable side by
// side. Not run as part of this change.
//
// Run only the offline tests (Steps 1-4), skipping the live call entirely:
//   flutter test test/bare_prompt_control_test.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/bare_prompt_control_test.dart --timeout none
//
// Writes a report to docs/bare_prompt_control_test_with_category.md
// (override with --dart-define=BARE_CONTROL_OUTPUT=...) — the original
// bare (no-category) baseline remains at docs/bare_prompt_control_test.md,
// untouched.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String systemPrompt =
    'You are a proofreader. Read the following text and identify any '
    'language errors — grammar, spelling, or unnatural/non-native '
    "phrasing. Do not rewrite for style, elegance, or polish beyond fixing "
    "actual errors. For each error, quote the exact problematic phrase and "
    "briefly explain what's wrong. If there are no errors, say so.\n\n"
    'After each explanation, add a rough category tag: Grammar, Spelling, '
    'Word Choice, Natural Language, or Other. This is just a best-guess '
    "label — don't overthink it, and don't let it change how you evaluate "
    'the error itself.';

const int runsPerPhrase = 10;

/// A fresh literal, not imported from correction_consistency_harness.dart —
/// this file must stay fully standalone. Same starting value (750ms) that
/// proved necessary there, reused by value, not by reference.
const int callDelayMs = 750;

const String outputPath = String.fromEnvironment(
  'BARE_CONTROL_OUTPUT',
  defaultValue: 'docs/bare_prompt_control_test_with_category.md',
);

/// One phrase to run through the bare prompt. No expected-target/category
/// modeling here — unlike the schema-based harness, this script does no
/// scoring; the 10 raw replies per phrase are for manual read-through.
class _Phrase {
  const _Phrase({required this.id, required this.text});

  final String id;
  final String text;
}

const List<_Phrase> _phrases = [
  // ── Spanish ──────────────────────────────────────────────────────────────
  _Phrase(
    id: 'ES-1-repeated-word',
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
  ),
  _Phrase(
    id: 'ES-2-single-char',
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
  ),
  _Phrase(
    id: 'ES-3-multi-correction',
    text:
        'Ayer había mucho trafico y mis amigos llamaron para atrás para '
        'confirmar la cena.',
  ),
  _Phrase(
    id: 'ES-4-calque',
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche.',
  ),
  _Phrase(
    id: 'ES-5-accents',
    text:
        'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
  ),
  _Phrase(
    id: 'ES-6-redundant-pronoun',
    text: 'Yo fui a casa, yo estudié, y yo hice la cena.',
  ),

  // ── Portuguese ───────────────────────────────────────────────────────────
  _Phrase(
    id: 'PT-1-repeated-word',
    text:
        'Ontem fui ao supermercado para comprar pão e depois voltei para '
        'casa para preparar o jantar, mas esqueci para pegar o leite.',
  ),
  _Phrase(
    id: 'PT-2-single-char',
    text: 'Eu gosto de ir a praia nos fins de semana com a minha família.',
  ),
  _Phrase(
    id: 'PT-3-multi-correction',
    text:
        'Ontem tinha muito transito no caminho para o trabalho e meus '
        'amigos ligaram de volta para confirmar o jantar.',
  ),
  _Phrase(
    id: 'PT-4-calque',
    text:
        'Posso ter uma cerveja? Quero passar um bom tempo com meus amigos '
        'essa noite.',
  ),
  _Phrase(
    id: 'PT-5-accents',
    text:
        'Morei em Sao Paulo por tres anos mas agora vivo em Curitiba e '
        'meu aniversario é em julho.',
  ),
  _Phrase(
    id: 'PT-6-redundant-pronoun',
    text: 'Eu fui para casa, eu estudei, e eu fiz o jantar.',
  ),
];

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call: `model` plus a two-message `messages` array (system, then user).
///
/// Deliberately no `response_format` (or any other schema/JSON-mode key) —
/// this is the bare-prompt control, so the request must carry nothing that
/// nudges the model toward the app's category system. Free-text output only.
Map<String, Object?> buildChatCompletionsBody({
  required String model,
  required String systemPrompt,
  required String userText,
}) {
  return {
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userText},
    ],
  };
}

/// Extracts the assistant's reply text from a decoded chat completions
/// response body: `choices[0].message.content`, trimmed.
///
/// Throws a [FormatException] with a specific, readable message on any
/// unexpected shape (missing/empty `choices`, non-object choice/message, or
/// missing/non-string/empty `content`) rather than returning an empty
/// string silently — a malformed response must show up as a visible error
/// in the report, not a blank reply that looks like "no errors found."
String extractReplyText(Map<String, Object?> decodedBody) {
  final choices = decodedBody['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException(
      'Chat completions response has no choices.',
    );
  }

  final firstChoice = choices.first;
  if (firstChoice is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice is not an object.');
  }

  final message = firstChoice['message'];
  if (message is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice has no message.');
  }

  final content = message['content'];
  if (content is! String || content.trim().isEmpty) {
    throw const FormatException('Chat completions message has no content.');
  }

  return content.trim();
}

/// Builds the full markdown report: a header block (model, generated-at,
/// run count, the system prompt used), then one section per phrase listing
/// every run's reply verbatim, in order.
///
/// Pure — takes already-collected [repliesByPhraseId] rather than making
/// any calls itself, so it's golden-testable with no network. Each entry in
/// a phrase's reply list is printed as-is: either the model's raw reply
/// text, or a pre-formatted `ERROR — ...` string built by the caller when a
/// run failed. There is deliberately no scoring/aggregation here — this
/// report is for manual read-through, not automated pass/fail.
String _buildReport({
  required String model,
  required int runsPerPhrase,
  required DateTime generatedAt,
  required List<_Phrase> phrases,
  required Map<String, List<String>> repliesByPhraseId,
}) {
  final report = StringBuffer()
    ..writeln('# Bare Prompt Control Test')
    ..writeln()
    ..writeln('Model: `$model`  ')
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per phrase: $runsPerPhrase')
    ..writeln()
    ..writeln('System prompt:')
    ..writeln()
    ..writeln('> $systemPrompt')
    ..writeln();

  for (final phrase in phrases) {
    final replies = repliesByPhraseId[phrase.id] ?? const <String>[];

    report
      ..writeln('## ${phrase.id}')
      ..writeln()
      ..writeln('- Text: `${phrase.text}`')
      ..writeln();

    for (var i = 0; i < replies.length; i++) {
      report
        ..writeln('### Run ${i + 1}/$runsPerPhrase')
        ..writeln()
        ..writeln(replies[i])
        ..writeln();
    }
  }

  return report.toString();
}

/// Model used for the live call, matching the existing schema-based
/// harness for a fair comparison. Override with
/// `--dart-define=BARE_PROMPT_MODEL=...` to compare a different model
/// without editing this file — same override pattern as [outputPath].
const String liveModel = String.fromEnvironment(
  'BARE_PROMPT_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Makes one live chat completions call and returns the extracted reply
/// text, or throws with a specific message on any failure (non-2xx HTTP
/// status, malformed JSON, or unexpected response shape via
/// [extractReplyText]). Raw dart:io HttpClient — no OpenAiCorrectionService.
Future<String> _callChatCompletions({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required String userText,
}) async {
  final request = await httpClient
      .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
      .timeout(const Duration(seconds: 10));

  request.headers
    ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
    ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

  request.add(
    utf8.encode(
      jsonEncode(
        buildChatCompletionsBody(
          model: model,
          systemPrompt: systemPrompt,
          userText: userText,
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Chat completions call failed with HTTP ${response.statusCode}: $body',
    );
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'Chat completions response root is not an object.',
    );
  }

  return extractReplyText(decoded);
}

void main() {
  test('bare prompt control test fixtures are well-formed', () {
    expect(
      systemPrompt,
      "You are a proofreader. Read the following text and identify any "
      "language errors — grammar, spelling, or unnatural/non-native "
      "phrasing. Do not rewrite for style, elegance, or polish beyond "
      "fixing actual errors. For each error, quote the exact problematic "
      "phrase and briefly explain what's wrong. If there are no errors, "
      "say so.\n\n"
      "After each explanation, add a rough category tag: Grammar, "
      "Spelling, Word Choice, Natural Language, or Other. This is just a "
      "best-guess label — don't overthink it, and don't let it change how "
      "you evaluate the error itself.",
    );

    expect(
      _phrases.length,
      12,
      reason: 'ES-1..ES-6 + PT-1..PT-6, matching '
          'correction_consistency_harness.dart\'s full battery.',
    );

    final ids = _phrases.map((p) => p.id).toSet();
    expect(ids.length, _phrases.length, reason: 'Phrase ids must be unique.');
    expect(ids, contains('ES-1-repeated-word'));
    expect(ids, contains('ES-2-single-char'));
    expect(ids, contains('ES-3-multi-correction'));
    expect(ids, contains('ES-4-calque'));
    expect(ids, contains('ES-5-accents'));
    expect(ids, contains('ES-6-redundant-pronoun'));
    expect(ids, contains('PT-1-repeated-word'));
    expect(ids, contains('PT-2-single-char'));
    expect(ids, contains('PT-3-multi-correction'));
    expect(ids, contains('PT-4-calque'));
    expect(ids, contains('PT-5-accents'));
    expect(ids, contains('PT-6-redundant-pronoun'));

    // Order matches the requested battery order exactly: ES-1..ES-6, then
    // PT-1..PT-6.
    expect(_phrases.map((p) => p.id).toList(), [
      'ES-1-repeated-word',
      'ES-2-single-char',
      'ES-3-multi-correction',
      'ES-4-calque',
      'ES-5-accents',
      'ES-6-redundant-pronoun',
      'PT-1-repeated-word',
      'PT-2-single-char',
      'PT-3-multi-correction',
      'PT-4-calque',
      'PT-5-accents',
      'PT-6-redundant-pronoun',
    ]);

    for (final phrase in _phrases) {
      expect(phrase.text.trim(), isNotEmpty, reason: phrase.id);
    }

    // Verbatim match against the existing harness's fixture texts (copied by
    // reference to this conversation, not by importing the other file), so
    // this control test compares against the exact same wording the
    // schema-based harness saw.
    final textsById = {for (final p in _phrases) p.id: p.text};
    expect(
      textsById['ES-1-repeated-word'],
      'Ayer fui al supermercado para comprar pan y después volví para casa '
      'para preparar la cena.',
    );
    expect(
      textsById['ES-2-single-char'],
      'Cuando termino el trabajo, voy para casa en autobús.',
    );
    expect(
      textsById['ES-3-multi-correction'],
      'Ayer había mucho trafico y mis amigos llamaron para atrás para '
      'confirmar la cena.',
    );
    expect(
      textsById['ES-4-calque'],
      '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
      'amigos esta noche.',
    );
    expect(
      textsById['ES-5-accents'],
      'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
    );
    expect(
      textsById['ES-6-redundant-pronoun'],
      'Yo fui a casa, yo estudié, y yo hice la cena.',
    );
    expect(
      textsById['PT-1-repeated-word'],
      'Ontem fui ao supermercado para comprar pão e depois voltei para '
      'casa para preparar o jantar, mas esqueci para pegar o leite.',
    );
    expect(
      textsById['PT-2-single-char'],
      'Eu gosto de ir a praia nos fins de semana com a minha família.',
    );
    expect(
      textsById['PT-3-multi-correction'],
      'Ontem tinha muito transito no caminho para o trabalho e meus '
      'amigos ligaram de volta para confirmar o jantar.',
    );
    expect(textsById['PT-3-multi-correction'], contains('ligaram de volta'));
    expect(
      textsById['PT-4-calque'],
      'Posso ter uma cerveja? Quero passar um bom tempo com meus amigos '
      'essa noite.',
    );
    expect(
      textsById['PT-5-accents'],
      'Morei em Sao Paulo por tres anos mas agora vivo em Curitiba e '
      'meu aniversario é em julho.',
    );
    expect(
      textsById['PT-6-redundant-pronoun'],
      'Eu fui para casa, eu estudei, e eu fiz o jantar.',
    );
  });

  group('buildChatCompletionsBody', () {
    test('has exactly model + messages, no schema/response_format key', () {
      final body = buildChatCompletionsBody(
        model: 'gpt-5.5',
        systemPrompt: 'sys',
        userText: 'user',
      );

      expect(body.keys.toSet(), {'model', 'messages'});
      expect(body['model'], 'gpt-5.5');
      expect(body.containsKey('response_format'), isFalse);
      expect(body.containsKey('text'), isFalse);
    });

    test('messages is [system, user] in that order with the right content', () {
      final body = buildChatCompletionsBody(
        model: 'gpt-5.5',
        systemPrompt: 'You are a proofreader.',
        userText: 'Review this text.',
      );

      final messages = body['messages'] as List<Object?>;
      expect(messages, hasLength(2));
      expect(messages[0], {'role': 'system', 'content': 'You are a proofreader.'});
      expect(messages[1], {'role': 'user', 'content': 'Review this text.'});
    });

    test('carries the real system prompt and phrase text unmodified', () {
      final body = buildChatCompletionsBody(
        model: 'gpt-5.5',
        systemPrompt: systemPrompt,
        userText: _phrases.first.text,
      );

      final messages = body['messages'] as List<Object?>;
      final system = messages[0] as Map<String, Object?>;
      final user = messages[1] as Map<String, Object?>;

      expect(system['content'], systemPrompt);
      expect(user['content'], _phrases.first.text);
    });
  });

  group('extractReplyText', () {
    test('extracts and trims choices[0].message.content', () {
      final body = {
        'choices': [
          {
            'message': {'role': 'assistant', 'content': '  No errors found.  '},
          },
        ],
      };
      expect(extractReplyText(body), 'No errors found.');
    });

    test('throws when choices is missing', () {
      expect(() => extractReplyText({}), throwsFormatException);
    });

    test('throws when choices is an empty list', () {
      expect(
        () => extractReplyText({'choices': []}),
        throwsFormatException,
      );
    });

    test('throws when the first choice is not an object', () {
      expect(
        () => extractReplyText({'choices': ['not an object']}),
        throwsFormatException,
      );
    });

    test('throws when message is missing from the choice', () {
      expect(
        () => extractReplyText({
          'choices': [<String, Object?>{}],
        }),
        throwsFormatException,
      );
    });

    test('throws when content is missing from the message', () {
      expect(
        () => extractReplyText({
          'choices': [
            {'message': <String, Object?>{}},
          ],
        }),
        throwsFormatException,
      );
    });

    test('throws when content is present but blank', () {
      expect(
        () => extractReplyText({
          'choices': [
            {'message': {'content': '   '}},
          ],
        }),
        throwsFormatException,
      );
    });

    test('throws when content is not a string', () {
      expect(
        () => extractReplyText({
          'choices': [
            {'message': {'content': 42}},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header + system prompt, per-phrase run-by-run replies)',
    () {
      final report = _buildReport(
        model: 'gpt-5.5',
        runsPerPhrase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        phrases: const [
          _Phrase(id: 'TEST-1', text: 'Texto de exemplo um.'),
          _Phrase(id: 'TEST-2', text: 'Texto de exemplo dois.'),
        ],
        repliesByPhraseId: {
          'TEST-1': [
            'No errors found.',
            '"exemplo" is fine, but the sentence reads as slightly stiff phrasing.',
          ],
          'TEST-2': ['ERROR — Chat completions response has no choices.'],
        },
      );

      // Captured verbatim from _buildReport's own output for this exact
      // input (see the Step 4 commit) — a byte-for-byte format regression
      // test, same approach as correction_consistency_harness.dart's
      // _buildReport golden test.
      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'bare prompt control (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the bare prompt control test. This '
          'script does NOT fall back to any hardcoded/default key — '
          'unlike AppConfig, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final repliesByPhraseId = <String, List<String>>{};

      try {
        for (final phrase in _phrases) {
          final replies = <String>[];
          // ignore: avoid_print
          print('=== ${phrase.id} ===');

          for (var run = 1; run <= runsPerPhrase; run++) {
            String reply;
            try {
              reply = await _callChatCompletions(
                httpClient: httpClient,
                apiKey: apiKey,
                model: liveModel,
                userText: phrase.text,
              );
            } catch (error) {
              reply = 'ERROR — $error';
            }
            replies.add(reply);
            // ignore: avoid_print
            print('[run $run] $reply');
            await Future<void>.delayed(
              const Duration(milliseconds: callDelayMs),
            );
          }

          repliesByPhraseId[phrase.id] = replies;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: liveModel,
        runsPerPhrase: runsPerPhrase,
        generatedAt: DateTime.now(),
        phrases: _phrases,
        repliesByPhraseId: repliesByPhraseId,
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 30)),
    tags: ['live'],
  );
}

const String _expectedReportGolden = r'''"# Bare Prompt Control Test\n\nModel: `gpt-5.5`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per phrase: 2\n\nSystem prompt:\n\n> You are a proofreader. Read the following text and identify any language errors — grammar, spelling, or unnatural/non-native phrasing. Do not rewrite for style, elegance, or polish beyond fixing actual errors. For each error, quote the exact problematic phrase and briefly explain what's wrong. If there are no errors, say so.\n\nAfter each explanation, add a rough category tag: Grammar, Spelling, Word Choice, Natural Language, or Other. This is just a best-guess label — don't overthink it, and don't let it change how you evaluate the error itself.\n\n## TEST-1\n\n- Text: `Texto de exemplo um.`\n\n### Run 1/2\n\nNo errors found.\n\n### Run 2/2\n\n\"exemplo\" is fine, but the sentence reads as slightly stiff phrasing.\n\n## TEST-2\n\n- Text: `Texto de exemplo dois.`\n\n### Run 1/2\n\nERROR — Chat completions response has no choices.\n\n"''';
