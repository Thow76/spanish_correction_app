// Stage 1C dedicated reflexive-insertion pass harness.
//
// Tests `stage1ReflexiveDetectionSpanish`
// (lib/core/services/prompts/correction_prompt.dart) — a standalone
// detection pass whose only job is a missing obligatory reflexive pronoun
// (se, me, te, nos, os) on a verb that requires it in the specific sentence
// it appears in. Built on the same fix pattern as
// `stage1RedundancyDetectionSpanish`: a dedicated single-purpose pass rather
// than folding span-width guidance into the shared general detection
// prompt — an earlier attempt to do the latter directly
// (`stage1DetectionCleanSpanSpanish`, retired) caused a regression on
// ES-4-calque.
//
// Two groups:
//   - Positive (should flag, with a clean single-verb span): "Levantó" and
//     "Atrevió" — both incomplete/ungrammatical as written without the
//     reflexive.
//   - Restraint (must NOT flag): three cases — a verb that is already
//     complete and correct without a reflexive ("Decidí el color del
//     coche"), the same verb already correctly reflexive with a different
//     complement ("Me decidí por el azul"), and a verb that is simply
//     non-reflexive and correct as-is ("Paré el coche en la esquina").
//
// STANDALONE, like every other harness in this repo: helper functions are
// copied by value from the other Stage 1 harnesses, not imported. Direct
// `/v1/chat/completions` call, env-only OPENAI_API_KEY, GPT-5.5 default.
//
// This step is fixture-only: it validates the case list and prompt text
// against expectations, and exercises the report builder against synthetic
// data. It does NOT make any live model call in this step — that is a
// separate, later, deliberate step. The `live` test at the bottom mirrors
// the other Stage 1 harnesses' shape for when that step happens, but is
// tagged `live` and skipped by default.
//
// Does NOT touch `correctText()`, `stage1DetectionDialectSpanish`,
// `stage1RedundancyDetectionSpanish`, or any live path.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage1_reflexive_detection_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/stage1_reflexive_detection_harness.dart --timeout none
//
// Writes a report to docs/stage1_reflexive_detection_harness.md (override
// with --dart-define=REFLEXIVE_PASS_OUTPUT=...). Override run count per case
// with --dart-define=REFLEXIVE_PASS_RUNS_PER_CASE=... (default 10). Override
// the model with --dart-define=REFLEXIVE_PASS_MODEL=... (default 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'REFLEXIVE_PASS_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'REFLEXIVE_PASS_OUTPUT',
  defaultValue: 'docs/stage1_reflexive_detection_harness.md',
);

/// Model used for the live run. Override with
/// `--dart-define=REFLEXIVE_PASS_MODEL=...` (default 'gpt-5.5').
const String reflexivePassModel = String.fromEnvironment(
  'REFLEXIVE_PASS_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'REFLEXIVE_PASS_CALL_DELAY_MS',
  defaultValue: 750,
);

/// Which group a case belongs to, so the report can print them under
/// separate headings and score them differently.
enum _CaseGroup { positive, restraint }

String _groupHeading(_CaseGroup group) => switch (group) {
  _CaseGroup.positive => 'Positive cases (should flag, clean single-verb span)',
  _CaseGroup.restraint => 'Restraint cases (must NOT flag)',
};

/// One test case for the dedicated reflexive-insertion pass. [verb] is only
/// set for positive cases — the bare verb form checked for overlap against
/// the returned flagged phrases, not a specific occurrence.
class _Case {
  const _Case({
    required this.id,
    required this.group,
    required this.text,
    required this.note,
    this.verb,
  });

  final String id;
  final _CaseGroup group;
  final String text;
  final String note;
  final String? verb;

  bool get isPositive => group == _CaseGroup.positive;
}

const List<_Case> _cases = [
  // ── Positive: should flag, with a clean single-verb span. ─────────────
  _Case(
    id: 'reflexive-levanto',
    group: _CaseGroup.positive,
    text: 'Levantó temprano y desayunó con calma.',
    verb: 'Levantó',
    note:
        '"Levantó temprano" has no valid object and leaves the clause '
        'hanging without the reflexive — needs "Se levantó" to be complete.',
  ),
  _Case(
    id: 'reflexive-atrevio',
    group: _CaseGroup.positive,
    text: 'Atrevió a preguntarle directamente.',
    verb: 'Atrevió',
    note:
        '"Atrever" is inherently reflexive (atreverse a) — the sentence is '
        'ungrammatical without "Se atrevió".',
  ),

  // ── Restraint: must NOT flag. ──────────────────────────────────────────
  _Case(
    id: 'restraint-decidio-coche',
    group: _CaseGroup.restraint,
    text: 'Decidí el color del coche.',
    note:
        'Already a complete, correct sentence as written — "decidir" with '
        'a direct object needs no reflexive here, even though "decidirse" '
        'exists with a different meaning in other sentences.',
  ),
  _Case(
    id: 'restraint-me-decidi-azul',
    group: _CaseGroup.restraint,
    text: 'Me decidí por el azul.',
    note:
        'Same verb as restraint-decidio-coche, already correctly reflexive '
        'with a different complement — must not be flagged as missing '
        'anything.',
  ),
  _Case(
    id: 'restraint-paro-coche',
    group: _CaseGroup.restraint,
    text: 'Paré el coche en la esquina.',
    note: 'Non-reflexive "parar" (to stop something) — correct as-is, no reflexive needed.',
  ),
];

/// Span-width bucket for a flagged phrase, by word count — same
/// word/phrase/clause split
/// stage1_redundancy_model_comparison_harness.dart's `_bucketFor` uses,
/// reimplemented locally since that file isn't imported (this harness stays
/// standalone).
enum _SpanBucket { word, phrase, clause }

_SpanBucket _bucketFor(String span) {
  final wordCount = span
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .length;
  if (wordCount <= 1) {
    return _SpanBucket.word;
  }
  if (wordCount <= 4) {
    return _SpanBucket.phrase;
  }
  return _SpanBucket.clause;
}

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Copied by value from the other
/// harnesses' `_normalizeForMatch`.
String _normalizeForMatch(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâã]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöôõ]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c');
}

/// Case/diacritic-insensitive containment check in either direction. Copied
/// by value from the other harnesses' `_normalizedOverlap`.
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// The flagged phrases from one run that actually overlap [verb].
List<String> _overlappingSpans(List<String> flaggedPhrases, String verb) {
  return flaggedPhrases.where((phrase) => _normalizedOverlap(phrase, verb)).toList();
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. Copied by value from the other harnesses'
/// `buildChatCompletionsBody`.
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
/// response body: `choices[0].message.content`, trimmed. Copied by value
/// from the other harnesses' `extractReplyText`.
String extractReplyText(Map<String, Object?> decodedBody) {
  final choices = decodedBody['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException('Chat completions response has no choices.');
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

/// Parses a Stage 1 reply into the list of quoted phrases it flagged.
/// Copied by value from the other harnesses' `parseDetectionArray`.
List<String> parseDetectionArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 1 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('Stage 1 reply array did not decode to a List.');
  }

  return decoded.map((element) {
    if (element is! String) {
      throw FormatException('Stage 1 reply array contained a non-string element: $element');
    }
    return element;
  }).toList();
}

/// One run's outcome for one case. A transient API failure is recorded via
/// [error] rather than dropped, same as the other harnesses' `_RunRecord`.
class _RunRecord {
  const _RunRecord({
    required this.caseId,
    required this.runIndex,
    this.flaggedPhrases = const [],
    this.error,
  });

  final String caseId;
  final int runIndex;
  final List<String> flaggedPhrases;
  final Object? error;

  bool get isError => error != null;
}

_RunRecord _buildRunRecord({
  required String caseId,
  required int runIndex,
  required List<String> flaggedPhrases,
}) {
  return _RunRecord(caseId: caseId, runIndex: runIndex, flaggedPhrases: flaggedPhrases);
}

_RunRecord _errorRunRecord({
  required String caseId,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(caseId: caseId, runIndex: runIndex, error: error);
}

/// Aggregated results for one case across all its runs. For positive
/// cases, [flaggedCount]/[overlappingSpanDistribution]/
/// [spanBucketDistribution] are populated against [_Case.verb]. For
/// restraint cases, [cleanCount] is populated instead (any non-empty
/// flaggedPhrases counts as a restraint failure — the prompt is scoped to
/// this one pattern only, so any flag it returns is a reflexive-insertion
/// flag by construction).
class _CaseAggregate {
  const _CaseAggregate({
    required this.caseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.consideredRuns,
    required this.flaggedCount,
    required this.overlappingSpanDistribution,
    required this.spanBucketDistribution,
    required this.cleanCount,
  });

  final String caseId;
  final int totalRuns;
  final int errorRuns;
  final int consideredRuns;
  final int flaggedCount;
  final Map<String, int> overlappingSpanDistribution;
  final Map<String, int> spanBucketDistribution;
  final int cleanCount;
}

_CaseAggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();

  if (testCase.isPositive) {
    var flaggedCount = 0;
    final overlapDist = <String, int>{};
    final bucketDist = <String, int>{};

    for (final record in okRecords) {
      final overlapping = _overlappingSpans(record.flaggedPhrases, testCase.verb!);
      if (overlapping.isNotEmpty) {
        flaggedCount++;
      }
      for (final span in overlapping) {
        overlapDist[span] = (overlapDist[span] ?? 0) + 1;
        final bucketKey = _bucketFor(span).name;
        bucketDist[bucketKey] = (bucketDist[bucketKey] ?? 0) + 1;
      }
    }

    return _CaseAggregate(
      caseId: testCase.id,
      totalRuns: records.length,
      errorRuns: records.length - okRecords.length,
      consideredRuns: okRecords.length,
      flaggedCount: flaggedCount,
      overlappingSpanDistribution: overlapDist,
      spanBucketDistribution: bucketDist,
      cleanCount: 0,
    );
  }

  final cleanCount = okRecords.where((r) => r.flaggedPhrases.isEmpty).length;
  return _CaseAggregate(
    caseId: testCase.id,
    totalRuns: records.length,
    errorRuns: records.length - okRecords.length,
    consideredRuns: okRecords.length,
    flaggedCount: 0,
    overlappingSpanDistribution: const {},
    spanBucketDistribution: const {},
    cleanCount: cleanCount,
  );
}

String _percentLabel(int count, int total) {
  if (total == 0) {
    return '0.0% (0/0)';
  }
  final pct = (count / total * 100).toStringAsFixed(1);
  return '$pct% ($count/$total)';
}

String _describeDistribution(Map<String, int> counts) {
  if (counts.isEmpty) {
    return '(none)';
  }
  final entries = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '"${e.key}": ${e.value}').join(', ');
}

String _describeError(Object error) => error.toString();

String _describeRun(_RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }

  final flagged = record.flaggedPhrases.isEmpty
      ? '(no phrases flagged)'
      : record.flaggedPhrases.map((f) => '"$f"').join('; ');

  return '- $prefix: flagged: $flagged';
}

/// Builds the full markdown report: a header block, then each group as its
/// own section (positive cases with flag rate + span-bucket distribution,
/// restraint cases with stayed-clean rate), then an overall-summary table.
///
/// Pure — takes already-collected [recordsByCaseId] rather than making any
/// calls itself, golden-testable against synthetic data with no live API
/// involved, same approach as the other harnesses' `_buildReport`.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Stage 1C Dedicated Reflexive-Insertion Pass Harness')
    ..writeln()
    ..writeln(
      'Tests `stage1ReflexiveDetectionSpanish` — a standalone detection '
      'pass for missing obligatory reflexive pronouns, run independently '
      'from the shared general detection prompt.',
    )
    ..writeln()
    ..writeln('Model: `$model`  ')
    ..writeln('Prompt: `stage1ReflexiveDetectionSpanish`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per case: $runsPerCase')
    ..writeln();

  final summaryRows = <String>[];

  for (final group in _CaseGroup.values) {
    final groupCases = cases.where((c) => c.group == group).toList();
    if (groupCases.isEmpty) {
      continue;
    }

    report
      ..writeln('## ${_groupHeading(group)}')
      ..writeln();

    for (final testCase in groupCases) {
      final records = recordsByCaseId[testCase.id] ?? const <_RunRecord>[];
      final aggregate = _aggregateCase(testCase, records);

      report
        ..writeln('### ${testCase.id}')
        ..writeln()
        ..writeln('- Text: `${testCase.text}`');
      if (testCase.verb != null) {
        report.writeln('- Target verb: `${testCase.verb}`');
      }
      report
        ..writeln('- Note: ${testCase.note}')
        ..writeln()
        ..writeln('#### Summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))')
        ..writeln();

      if (testCase.isPositive) {
        final flagRateLabel = _percentLabel(aggregate.flaggedCount, aggregate.consideredRuns);
        report
          ..writeln('- Flag rate: $flagRateLabel')
          ..writeln(
            '- Span-bucket distribution (word/phrase/clause, among flagged spans): '
            '${_describeDistribution(aggregate.spanBucketDistribution)}',
          )
          ..writeln(
            '- Exact flagged-span distribution: '
            '${_describeDistribution(aggregate.overlappingSpanDistribution)}',
          );
        summaryRows.add(
          '| ${testCase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
          '$flagRateLabel | ${_describeDistribution(aggregate.spanBucketDistribution)} |',
        );
      } else {
        final cleanLabel = _percentLabel(aggregate.cleanCount, aggregate.consideredRuns);
        report.writeln('- Stayed clean: $cleanLabel');
        summaryRows.add(
          '| ${testCase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
          '$cleanLabel (clean) | — |',
        );
      }

      report
        ..writeln()
        ..writeln('#### Run detail')
        ..writeln();

      for (final record in records) {
        report.writeln(_describeRun(record));
      }
      report.writeln();
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Case | Runs | Errors | Headline rate | Span-bucket distribution |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final row in summaryRows) {
    report.writeln(row);
  }

  return report.toString();
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

Future<List<String>> _callStage1ReflexiveDetection({
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
          systemPrompt: stage1ReflexiveDetectionSpanish,
          userText: userText,
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Chat completions call failed with HTTP ${response.statusCode}: $body');
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Chat completions response root is not an object.');
  }

  return parseDetectionArray(extractReplyText(decoded));
}

void main() {
  test('reflexive detection harness case fixtures are well-formed', () {
    expect(_cases.length, 5, reason: '2 positive + 3 restraint.');

    final positive = _cases.where((c) => c.group == _CaseGroup.positive);
    final restraint = _cases.where((c) => c.group == _CaseGroup.restraint);
    expect(positive.length, 2);
    expect(restraint.length, 3);

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in positive) {
      expect(testCase.verb, isNotNull, reason: testCase.id);
      expect(
        testCase.text.contains(testCase.verb!),
        isTrue,
        reason: '${testCase.id}: verb "${testCase.verb}" not found in text.',
      );
    }

    for (final testCase in restraint) {
      expect(testCase.verb, isNull, reason: testCase.id);
    }

    final textsById = {for (final c in _cases) c.id: c.text};
    expect(textsById['reflexive-levanto'], 'Levantó temprano y desayunó con calma.');
    expect(textsById['reflexive-atrevio'], 'Atrevió a preguntarle directamente.');
    expect(textsById['restraint-decidio-coche'], 'Decidí el color del coche.');
    expect(textsById['restraint-me-decidi-azul'], 'Me decidí por el azul.');
    expect(textsById['restraint-paro-coche'], 'Paré el coche en la esquina.');
  });

  test('runsPerCase defaults to 10', () {
    expect(runsPerCase, 10);
  });

  test('reflexivePassModel defaults to gpt-5.5', () {
    expect(reflexivePassModel, 'gpt-5.5');
  });

  test(
    'stage1ReflexiveDetectionSpanish is a standalone prompt, distinct from '
    'stage1DetectionDialectSpanish and stage1RedundancyDetectionSpanish, with '
    'the same JSON-array output shape',
    () {
      expect(
        stage1ReflexiveDetectionSpanish,
        isNot(equals(stage1DetectionDialectSpanish)),
      );
      expect(
        stage1ReflexiveDetectionSpanish,
        isNot(equals(stage1RedundancyDetectionSpanish)),
      );
      expect(
        stage1ReflexiveDetectionSpanish,
        contains('missing obligatory reflexive pronoun'),
      );
      expect(stage1ReflexiveDetectionSpanish, contains('se, me, te, nos, os'));
      expect(
        stage1ReflexiveDetectionSpanish,
        contains('Judge only the sentence as written'),
      );
      expect(
        stage1ReflexiveDetectionSpanish,
        contains('never the surrounding clause or sentence'),
      );
      expect(
        stage1ReflexiveDetectionSpanish,
        contains('If there is nothing to flag, return none.'),
      );

      // Same JSON-array-of-quoted-phrases output shape as the other Stage 1
      // prompts — same closing instruction sentence fragment shared across
      // every Stage 1 prompt in this file.
      const sharedOutputInstruction =
          'Return an empty array [] when nothing is wrong. Do not include '
          'indices, categories, corrected text, explanations, Markdown, or '
          'code fences — quoted phrases only.';
      expect(stage1ReflexiveDetectionSpanish, contains(sharedOutputInstruction));
      expect(stage1RedundancyDetectionSpanish, contains(sharedOutputInstruction));
    },
  );

  test('stage1ReflexiveDetectionSpanish does not mention dialect or calques', () {
    final lower = stage1ReflexiveDetectionSpanish.toLowerCase();
    expect(lower, isNot(contains('dialect')));
    expect(lower, isNot(contains('calque')));
  });

  group('_bucketFor', () {
    test('single word is bucketed as word', () {
      expect(_bucketFor('Levantó'), _SpanBucket.word);
    });

    test('two words is bucketed as phrase, not word', () {
      expect(_bucketFor('Se levantó'), _SpanBucket.phrase);
    });

    test('four words is bucketed as phrase (upper boundary)', () {
      expect(_bucketFor('Levantó temprano y desayunó'), _SpanBucket.phrase);
    });

    test('five or more words is bucketed as clause', () {
      expect(_bucketFor('Levantó temprano y desayunó con calma.'), _SpanBucket.clause);
    });
  });

  group('_overlappingSpans', () {
    test('returns every flagged phrase overlapping the verb', () {
      final spans = _overlappingSpans([
        'Levantó temprano',
        'Levantó',
        'unrelated phrase',
      ], 'Levantó');
      expect(spans, ['Levantó temprano', 'Levantó']);
    });

    test('is case/diacritic-insensitive', () {
      expect(_overlappingSpans(['LEVANTO'], 'Levantó'), ['LEVANTO']);
    });

    test('returns empty when nothing overlaps', () {
      expect(_overlappingSpans(['otono'], 'Levantó'), isEmpty);
    });
  });

  group('parseDetectionArray', () {
    test('parses a populated array', () {
      expect(parseDetectionArray('["Levantó"]'), ['Levantó']);
    });

    test('parses an empty array', () {
      expect(parseDetectionArray('[]'), isEmpty);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      expect(parseDetectionArray('```json\n["Atrevió"]\n```'), ['Atrevió']);
    });

    test('throws when no array is present', () {
      expect(() => parseDetectionArray('nothing here'), throwsFormatException);
    });

    test('throws when the array contains a non-string element', () {
      expect(() => parseDetectionArray('["Levantó", 42]'), throwsFormatException);
    });
  });

  group('_buildRunRecord / _errorRunRecord', () {
    test('builds a plain run record with flaggedPhrases', () {
      final record = _buildRunRecord(
        caseId: 'reflexive-levanto',
        runIndex: 1,
        flaggedPhrases: ['Levantó'],
      );
      expect(record.isError, isFalse);
      expect(record.flaggedPhrases, ['Levantó']);
    });

    test('_errorRunRecord carries the error and no data', () {
      final record = _errorRunRecord(
        caseId: 'reflexive-levanto',
        runIndex: 2,
        error: StateError('timed out'),
      );
      expect(record.isError, isTrue);
      expect(record.error, isA<StateError>());
      expect(record.flaggedPhrases, isEmpty);
    });
  });

  group('_aggregateCase (positive)', () {
    test('flag rate and distributions computed over non-error runs only', () {
      final testCase = _cases.firstWhere((c) => c.id == 'reflexive-levanto');

      final records = [
        _buildRunRecord(caseId: testCase.id, runIndex: 1, flaggedPhrases: ['Levantó']),
        _buildRunRecord(caseId: testCase.id, runIndex: 2, flaggedPhrases: []),
        _errorRunRecord(caseId: testCase.id, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.consideredRuns, 2);
      expect(aggregate.flaggedCount, 1);
      expect(aggregate.overlappingSpanDistribution, {'Levantó': 1});
      expect(aggregate.spanBucketDistribution, {'word': 1});
    });

    test('a whole-clause flag is tallied under clause, not word/phrase', () {
      final testCase = _cases.firstWhere((c) => c.id == 'reflexive-levanto');
      final records = [
        _buildRunRecord(
          caseId: testCase.id,
          runIndex: 1,
          flaggedPhrases: ['Levantó temprano y desayunó con calma.'],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.flaggedCount, 1);
      expect(aggregate.spanBucketDistribution, {'clause': 1});
    });
  });

  group('_aggregateCase (restraint)', () {
    test('cleanCount reflects runs with zero flagged phrases', () {
      final testCase = _cases.firstWhere((c) => c.id == 'restraint-decidio-coche');

      final records = [
        _buildRunRecord(caseId: testCase.id, runIndex: 1, flaggedPhrases: []),
        _buildRunRecord(caseId: testCase.id, runIndex: 2, flaggedPhrases: ['Decidí']),
        _errorRunRecord(caseId: testCase.id, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.consideredRuns, 2);
      expect(aggregate.cleanCount, 1);
      expect(aggregate.flaggedCount, 0);
    });

    test('all runs erroring yields zeroed aggregates, not a crash', () {
      final testCase = _cases.firstWhere((c) => c.id == 'restraint-decidio-coche');
      final records = [
        _errorRunRecord(caseId: testCase.id, runIndex: 1, error: StateError('a')),
        _errorRunRecord(caseId: testCase.id, runIndex: 2, error: StateError('b')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 2);
      expect(aggregate.errorRuns, 2);
      expect(aggregate.consideredRuns, 0);
      expect(aggregate.cleanCount, 0);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, grouped sections, per-case summary + run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: const [
          _Case(
            id: 'TEST-1-positive',
            group: _CaseGroup.positive,
            text: 'Levantó temprano.',
            verb: 'Levantó',
            note: 'Synthetic positive case for report golden test.',
          ),
          _Case(
            id: 'TEST-2-restraint',
            group: _CaseGroup.restraint,
            text: 'Decidí el color del coche.',
            note: 'Synthetic restraint case for report golden test.',
          ),
        ],
        recordsByCaseId: {
          'TEST-1-positive': [
            _buildRunRecord(caseId: 'TEST-1-positive', runIndex: 1, flaggedPhrases: ['Levantó']),
            _errorRunRecord(
              caseId: 'TEST-1-positive',
              runIndex: 2,
              error: StateError('Stage 1 reflexive call timed out'),
            ),
          ],
          'TEST-2-restraint': [
            _buildRunRecord(caseId: 'TEST-2-restraint', runIndex: 1, flaggedPhrases: []),
            _buildRunRecord(caseId: 'TEST-2-restraint', runIndex: 2, flaggedPhrases: []),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'stage1 reflexive detection harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the Stage 1C reflexive detection '
          'harness. This script does NOT fall back to any hardcoded/default '
          'key — no AppConfig involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final recordsByCaseId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in _cases) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (var run = 1; run <= runsPerCase; run++) {
            _RunRecord record;
            try {
              final flaggedPhrases = await _callStage1ReflexiveDetection(
                httpClient: httpClient,
                apiKey: apiKey,
                model: reflexivePassModel,
                userText: testCase.text,
              );
              record = _buildRunRecord(
                caseId: testCase.id,
                runIndex: run,
                flaggedPhrases: flaggedPhrases,
              );
            } catch (error) {
              record = _errorRunRecord(caseId: testCase.id, runIndex: run, error: error);
            }
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(record));
            await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
          }

          recordsByCaseId[testCase.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: reflexivePassModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath (model: $reflexivePassModel)');
    },
    timeout: const Timeout(Duration(minutes: 20)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Stage 1C Dedicated Reflexive-Insertion Pass Harness\n\nTests `stage1ReflexiveDetectionSpanish` — a standalone detection pass for missing obligatory reflexive pronouns, run independently from the shared general detection prompt.\n\nModel: `test-model`  \nPrompt: `stage1ReflexiveDetectionSpanish`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## Positive cases (should flag, clean single-verb span)\n\n### TEST-1-positive\n\n- Text: `Levantó temprano.`\n- Target verb: `Levantó`\n- Note: Synthetic positive case for report golden test.\n\n#### Summary (2 runs, 1 error(s))\n\n- Flag rate: 100.0% (1/1)\n- Span-bucket distribution (word/phrase/clause, among flagged spans): \"word\": 1\n- Exact flagged-span distribution: \"Levantó\": 1\n\n#### Run detail\n\n- Run 1: flagged: \"Levantó\"\n- Run 2: ERROR — Bad state: Stage 1 reflexive call timed out\n\n## Restraint cases (must NOT flag)\n\n### TEST-2-restraint\n\n- Text: `Decidí el color del coche.`\n- Note: Synthetic restraint case for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Stayed clean: 100.0% (2/2)\n\n#### Run detail\n\n- Run 1: flagged: (no phrases flagged)\n- Run 2: flagged: (no phrases flagged)\n\n---\n\n## Overall summary\n\n| Case | Runs | Errors | Headline rate | Span-bucket distribution |\n| --- | --- | --- | --- | --- |\n| TEST-1-positive | 2 | 1 | 100.0% (1/1) | \"word\": 1 |\n| TEST-2-restraint | 2 | 0 | 100.0% (2/2) (clean) | — |\n"';
