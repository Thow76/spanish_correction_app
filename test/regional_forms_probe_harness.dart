// Regional forms probe (test program only; 21 Nov 2026, at Andrew's request).
//
// One question per sentence, on its own, with no correcting and no scoring:
// are there any regional forms in this text, and if so which, used where and
// not used where? It does not touch the two-step check, its prompts or the
// app. Its only job is to measure whether the model can recognise regional
// forms, and how consistently, so that a regional-note feature (decision C4,
// after the first build) can be designed on evidence.
//
// The report, per sentence: how many of the runs returned a note, and what
// the model said. The five "Valid Regional / Should Not Flag" sentences are
// the ones it should notice; every other sentence is a check that it does
// not invent regional forms where there are none.
//
// Run offline (no API calls):
//   flutter test test/regional_forms_probe_harness.dart --exclude-tags live
//
// Run live deliberately (one call per run; all 84 sentences five times each
// is 420 calls). The key comes from OPENAI_API_KEY in your terminal or,
// failing that, the .env file in the project folder:
//   REGIONAL_LIVE=true \
//   REGIONAL_FIXTURE_SET=all \
//   REGIONAL_RUNS_PER_FIXTURE=5 \
//   REGIONAL_OUTPUT=docs/regional_forms_probe_all_5x.md \
//   flutter test test/regional_forms_probe_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - REGIONAL_MODEL: defaults to gpt-6-sol.
// - REGIONAL_FIXTURE_SET: "all" (default), "regional" (only the five
//   regional control sentences), "errors", "single" (with
//   REGIONAL_FIXTURE_ID) or "language_point" (with REGIONAL_LANGUAGE_POINT).
// - REGIONAL_RUNS_PER_FIXTURE: defaults to 1.
// - REGIONAL_CALL_DELAY_MS: pause between runs, defaults to 750.
// - REGIONAL_OUTPUT: report path, defaults to docs/regional_forms_probe.md.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';

import 'shared/openai_key.dart';
import 'two_pass_integration_harness.dart'
    show CallStats, TwoPassFixture, allTwoPassFixtures, statsFor;
import 'two_pass_linear_prompt_comparison_harness.dart' show linearFixturesFor;

// ---------------------------------------------------------------------------
// The question
// ---------------------------------------------------------------------------

const String defaultRegionalModel = 'gpt-6-sol';
const String defaultRegionalOutputPath = 'docs/regional_forms_probe.md';

/// The language point of the five sentences the model should notice.
const String regionalLanguagePoint = 'Valid Regional / Should Not Flag';

/// The whole prompt. Its only job is to find regional forms.
const String regionalFormsPrompt =
    'You are a Spanish tutor with a good knowledge of how Spanish differs '
    'between countries and regions.\n'
    '\n'
    'Read the learner\'s text and report every regional form in it: any '
    'word, phrase, verb form, pronoun or construction that is standard in '
    'some Spanish-speaking regions but not in others, or that would sound '
    'unusual, be misunderstood, or cause offence in some regions.\n'
    '\n'
    'Do not correct anything. Do not comment on spelling, grammar, '
    'punctuation or style. Do not report forms that are standard across '
    'the Spanish-speaking world. If the text has no regional form, return '
    'an empty list.\n'
    '\n'
    'Return a JSON object with one field, "items": a list. Each item has '
    'exactly four fields:\n'
    '- "written": the words exactly as the learner wrote them, copied '
    'character for character from the text.\n'
    '- "used_in": where the form is standard or common.\n'
    '- "not_used_in": where it is not used, or where it means something '
    'else.\n'
    '- "reason": one short plain-English sentence for a learner of '
    'Spanish, saying what the form is and why it is regional.\n'
    '\n'
    'Return JSON only, with no Markdown and no commentary.';

String buildRegionalUserContent(String text) => 'Text to review:\n$text';

/// The reply shape, enforced by the service.
const Map<String, Object?> regionalResponseFormat = {
  'type': 'json_schema',
  'json_schema': {
    'name': 'regional_forms_response',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['items'],
      'properties': {
        'items': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['written', 'used_in', 'not_used_in', 'reason'],
            'properties': {
              'written': {'type': 'string'},
              'used_in': {'type': 'string'},
              'not_used_in': {'type': 'string'},
              'reason': {'type': 'string'},
            },
          },
        },
      },
    },
  },
};

// ---------------------------------------------------------------------------
// Replies
// ---------------------------------------------------------------------------

/// One regional form as the model reports it.
class RegionalNote {
  const RegionalNote({
    required this.written,
    required this.usedIn,
    required this.notUsedIn,
    required this.reason,
  });

  final String written;
  final String usedIn;
  final String notUsedIn;
  final String reason;

  String get summary => '$written: used in $usedIn; not in $notUsedIn. $reason';
}

/// Parses a reply. Tolerates Markdown fences or commentary around the JSON
/// object; throws [FormatException] when there is no object or no "items"
/// list; skips an item with a missing or non-string field.
List<RegionalNote> parseRegionalReply(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end <= start) {
    throw const FormatException('No JSON object found in the reply.');
  }
  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Reply JSON is not an object.');
  }
  final items = decoded['items'];
  if (items is! List) {
    throw const FormatException('Reply has no "items" list.');
  }
  final notes = <RegionalNote>[];
  for (final raw in items) {
    if (raw is! Map<String, Object?>) continue;
    final written = raw['written'];
    final usedIn = raw['used_in'];
    final notUsedIn = raw['not_used_in'];
    final reason = raw['reason'];
    if (written is! String ||
        usedIn is! String ||
        notUsedIn is! String ||
        reason is! String) {
      continue;
    }
    notes.add(
      RegionalNote(
        written: written,
        usedIn: usedIn,
        notUsedIn: notUsedIn,
        reason: reason,
      ),
    );
  }
  return notes;
}

// ---------------------------------------------------------------------------
// One run
// ---------------------------------------------------------------------------

class RegionalResult {
  const RegionalResult({
    required this.fixture,
    required this.runIndex,
    required this.notes,
    required this.stats,
    this.error,
  });

  final TwoPassFixture fixture;
  final int runIndex;
  final List<RegionalNote> notes;
  final CallStats stats;

  /// The service's failure message when every retry failed; null otherwise.
  final String? error;

  bool get noted => notes.isNotEmpty;

  /// True for one of the five sentences the model should notice.
  bool get isRegionalControl => fixture.languagePoint == regionalLanguagePoint;
}

/// How many times one call is attempted before the run is given up: the
/// first try plus [regionalCallRetries] more, with a pause of 2, 4 and 8
/// seconds between tries.
const int regionalCallRetries = 3;

Future<T> _withRetries<T>(Future<T> Function() call) async {
  var attempt = 0;
  while (true) {
    try {
      return await call();
    } on ChatCompletionsException {
      if (attempt >= regionalCallRetries) rethrow;
      attempt += 1;
      await Future<void>.delayed(Duration(seconds: 1 << attempt));
    }
  }
}

/// Asks the one question about [fixture]'s sentence.
Future<RegionalResult> runRegionalProbe({
  required String apiKey,
  required HttpClient httpClient,
  required String model,
  required TwoPassFixture fixture,
  int runIndex = 1,
}) async {
  final usage = <ChatCompletionsUsage>[];
  final client = OpenAiChatCompletionsClient(
    apiKey: apiKey,
    httpClient: httpClient,
    onUsage: usage.add,
  );
  final stopwatch = Stopwatch()..start();
  try {
    final reply = await _withRetries(
      () => client.complete(
        model: model,
        systemPrompt: regionalFormsPrompt,
        userText: buildRegionalUserContent(fixture.text),
        stageLabel: 'regional_forms_probe',
        responseFormat: regionalResponseFormat,
      ),
    );
    stopwatch.stop();
    return RegionalResult(
      fixture: fixture,
      runIndex: runIndex,
      notes: parseRegionalReply(reply),
      stats: statsFor(usage, wallClockMs: stopwatch.elapsedMilliseconds),
    );
  } on ChatCompletionsException catch (e) {
    stopwatch.stop();
    return RegionalResult(
      fixture: fixture,
      runIndex: runIndex,
      notes: const [],
      stats: statsFor(usage, wallClockMs: stopwatch.elapsedMilliseconds),
      error: e.message.split('\n').first,
    );
  } on FormatException catch (e) {
    stopwatch.stop();
    return RegionalResult(
      fixture: fixture,
      runIndex: runIndex,
      notes: const [],
      stats: statsFor(usage, wallClockMs: stopwatch.elapsedMilliseconds),
      error: e.message,
    );
  }
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

String _percent(int part, int whole) =>
    whole == 0 ? 'n/a' : '${(part * 100 / whole).toStringAsFixed(1)} per cent';

String _cost(double? usd) =>
    usd == null ? 'unknown' : '\$${usd.toStringAsFixed(6)}';

String _notes(List<RegionalNote> notes) =>
    notes.isEmpty ? '(none)' : notes.map((n) => n.summary).join('<br>');

/// Builds the markdown report. Measures only; it passes no judgement.
String buildRegionalReport({
  required String model,
  required List<RegionalResult> results,
  required DateTime generatedAt,
}) {
  final b = StringBuffer()
    ..writeln('# Regional forms probe')
    ..writeln()
    ..writeln(
      'One call per run on `$model`, asking only: are there any regional '
      'forms in this text, and if so which, used where and not used where? '
      'Nothing is corrected and nothing is scored. This report measures '
      'what the model notices, and how consistently; it does not gate.',
    )
    ..writeln()
    ..writeln('- Total runs: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln();

  final controls = results.where((r) => r.isRegionalControl).toList();
  final others = results.where((r) => !r.isRegionalControl).toList();
  final controlsNoted = controls.where((r) => r.noted).length;
  final othersNoted = others.where((r) => r.noted).length;
  final errors = results.where((r) => r.error != null).length;
  b
    ..writeln('## Summary')
    ..writeln()
    ..writeln(
      '**Regional sentences noted: $controlsNoted of ${controls.length} '
      'runs (${_percent(controlsNoted, controls.length)}).**',
    )
    ..writeln()
    ..writeln(
      '- Other sentences given a regional note: `$othersNoted` of '
      '`${others.length}` runs',
    )
    ..writeln(
      '- Runs that failed (service error or unreadable reply): '
      '`$errors`',
    )
    ..writeln();

  // Per sentence.
  b
    ..writeln('## Per sentence')
    ..writeln()
    ..writeln(
      '| Sentence | Language point | Runs with a note | Runs | '
      'What the model said |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');
  final seen = <String>{};
  for (final r in results) {
    if (!seen.add(r.fixture.id)) continue;
    final rows = results.where((x) => x.fixture.id == r.fixture.id);
    final noted = rows.where((x) => x.noted).length;
    final said = <String>{};
    for (final x in rows) {
      for (final note in x.notes) {
        said.add(note.summary);
      }
    }
    b.writeln(
      '| `${r.fixture.text}` | ${r.fixture.languagePoint} | $noted | '
      '${rows.length} | ${said.isEmpty ? '(none)' : said.join('<br>')} |',
    );
  }
  b.writeln();

  // Speed and cost.
  final total = results.fold<CallStats>(CallStats.zero, (a, r) => a + r.stats);
  final n = results.isEmpty ? 1 : results.length;
  b
    ..writeln('## Speed and cost per call')
    ..writeln()
    ..writeln('| Model | Average time (ms) | Average cost | Total cost |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln(
      '| `$model` | ${(total.wallClockMs / n).round()} | '
      '${_cost(total.costUsd == null ? null : total.costUsd! / n)} | '
      '${_cost(total.costUsd)} |',
    )
    ..writeln();

  // Every run.
  b
    ..writeln('## Every run')
    ..writeln()
    ..writeln('| Sentence | Run | Original | Regional forms reported |')
    ..writeln('| --- | --- | --- | --- |');
  for (final r in results) {
    b.writeln(
      '| ${r.fixture.id} | ${r.runIndex} | `${r.fixture.text}` | '
      '${r.error == null ? _notes(r.notes) : 'ERROR: ${r.error}'} |',
    );
  }
  return b.toString();
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

String _setting(Map<String, String> env, String key, String fallback) {
  final value = env[key]?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

bool regionalLiveOptIn(Map<String, String> env) =>
    env['REGIONAL_LIVE']?.trim().toLowerCase() == 'true';

int regionalRunsPerFixtureFrom(Map<String, String> env) {
  final runs = int.tryParse(env['REGIONAL_RUNS_PER_FIXTURE']?.trim() ?? '');
  if (runs == null) return 1;
  if (runs < 1) {
    throw ArgumentError('REGIONAL_RUNS_PER_FIXTURE must be >= 1 (was $runs).');
  }
  return runs;
}

/// The five regional control sentences. `REGIONAL_FIXTURE_SET=regional`.
List<TwoPassFixture> get regionalControlFixtures => allTwoPassFixtures
    .where((f) => f.languagePoint == regionalLanguagePoint)
    .toList();

List<TwoPassFixture> regionalFixturesFrom(Map<String, String> env) {
  final set = _setting(env, 'REGIONAL_FIXTURE_SET', 'all');
  if (set == 'regional') return regionalControlFixtures;
  return linearFixturesFor(
    set,
    fixtureId: env['REGIONAL_FIXTURE_ID']?.trim(),
    languagePoint: env['REGIONAL_LANGUAGE_POINT']?.trim(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('the prompt', () {
    test('asks only for regional forms, never for corrections', () {
      expect(regionalFormsPrompt, contains('report every regional form'));
      expect(regionalFormsPrompt, contains('Do not correct anything'));
      expect(regionalFormsPrompt, contains('return an empty list'));
      for (final field in ['written', 'used_in', 'not_used_in', 'reason']) {
        expect(regionalFormsPrompt, contains('"$field"'));
      }
    });

    test('does not quote the test sentences', () {
      // Four consecutive words of a test sentence in the prompt would be
      // telling the model the answer.
      String normalise(String text) => text
          .toLowerCase()
          .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final prompt = normalise(regionalFormsPrompt);
      for (final fixture in allTwoPassFixtures) {
        final words = normalise(fixture.text).split(' ');
        for (var i = 0; i + 4 <= words.length; i++) {
          final run = words.sublist(i, i + 4).join(' ');
          expect(
            prompt,
            isNot(contains(run)),
            reason: 'prompt quotes "$run" from ${fixture.id}',
          );
        }
      }
    });
  });

  group('parseRegionalReply', () {
    test('reads the four parts of each note', () {
      final notes = parseRegionalReply(
        '{"items": [{"written": "Vos tenés", "used_in": "Argentina and '
        'Uruguay", "not_used_in": "Spain", "reason": "Voseo."}]}',
      );
      expect(notes, hasLength(1));
      expect(notes.single.written, 'Vos tenés');
      expect(notes.single.usedIn, 'Argentina and Uruguay');
      expect(notes.single.notUsedIn, 'Spain');
      expect(notes.single.reason, 'Voseo.');
      expect(
        notes.single.summary,
        'Vos tenés: used in Argentina and Uruguay; not in Spain. Voseo.',
      );
    });

    test('an empty list means no regional form', () {
      expect(parseRegionalReply('{"items": []}'), isEmpty);
    });

    test('tolerates fences and skips an item with a missing field', () {
      final notes = parseRegionalReply(
        '```json\n{"items": [{"written": "x", "used_in": "y"}, '
        '{"written": "a", "used_in": "b", "not_used_in": "c", '
        '"reason": "d"}]}\n```',
      );
      expect(notes, hasLength(1));
      expect(notes.single.written, 'a');
    });

    test('throws when there is no object or no items list', () {
      expect(() => parseRegionalReply('nothing'), throwsFormatException);
      expect(() => parseRegionalReply('{"x": 1}'), throwsFormatException);
    });
  });

  group('settings', () {
    test('is off unless REGIONAL_LIVE=true', () {
      expect(regionalLiveOptIn({}), isFalse);
      expect(regionalLiveOptIn({'REGIONAL_LIVE': 'true'}), isTrue);
    });

    test('the regional set is the five control sentences', () {
      final set = regionalFixturesFrom({'REGIONAL_FIXTURE_SET': 'regional'});
      expect(set, hasLength(5));
      expect(
        set.every((f) => f.languagePoint == regionalLanguagePoint),
        isTrue,
      );
    });

    test('the default set is every sentence', () {
      expect(regionalFixturesFrom({}), hasLength(allTwoPassFixtures.length));
    });
  });

  group('the report', () {
    test('separates the regional sentences from the rest', () {
      final control = regionalControlFixtures.first;
      final other = allTwoPassFixtures.firstWhere(
        (f) => f.languagePoint != regionalLanguagePoint,
      );
      final results = [
        RegionalResult(
          fixture: control,
          runIndex: 1,
          notes: const [
            RegionalNote(
              written: 'Vos tenés',
              usedIn: 'Argentina',
              notUsedIn: 'Spain',
              reason: 'Voseo.',
            ),
          ],
          stats: CallStats.zero,
        ),
        RegionalResult(
          fixture: control,
          runIndex: 2,
          notes: const [],
          stats: CallStats.zero,
        ),
        RegionalResult(
          fixture: other,
          runIndex: 1,
          notes: const [],
          stats: CallStats.zero,
        ),
      ];
      final report = buildRegionalReport(
        model: 'm',
        results: results,
        generatedAt: DateTime(2026),
      );
      expect(report, contains('Regional sentences noted: 1 of 2 runs'));
      expect(
        report,
        contains('Other sentences given a regional note: `0` of `1`'),
      );
      expect(
        report,
        contains('Vos tenés: used in Argentina; not in Spain. Voseo.'),
      );
      expect(report, contains('## Every run'));
    });
  });

  test(
    'regional forms probe against the test sentences',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!regionalLiveOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live regional probe. Set REGIONAL_LIVE=true to opt in.',
        );
        return;
      }

      final apiKey = openAiApiKeyFor(environment);
      if (apiKey.isEmpty) {
        fail(noApiKeyMessage);
      }

      final model = _setting(
        environment,
        'REGIONAL_MODEL',
        defaultRegionalModel,
      );
      final outputPath = _setting(
        environment,
        'REGIONAL_OUTPUT',
        defaultRegionalOutputPath,
      );
      final delayMs =
          int.tryParse(environment['REGIONAL_CALL_DELAY_MS']?.trim() ?? '') ??
          750;
      final fixtures = regionalFixturesFrom(environment);
      final runsPerFixture = regionalRunsPerFixtureFrom(environment);
      final httpClient = HttpClient();

      final results = <RegionalResult>[];
      for (final fixture in fixtures) {
        for (var run = 1; run <= runsPerFixture; run++) {
          final result = await runRegionalProbe(
            apiKey: apiKey,
            httpClient: httpClient,
            model: model,
            fixture: fixture,
            runIndex: run,
          );
          results.add(result);
          // ignore: avoid_print
          print(
            '=== ${fixture.id} (run $run/$runsPerFixture) === '
            '${result.error ?? _notes(result.notes)}',
          );
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }
      }

      final report = buildRegionalReport(
        model: model,
        results: results,
        generatedAt: DateTime.now(),
      );
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote regional forms probe report to $outputPath');
    },
  );
}
