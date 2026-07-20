// Stage 1B dedicated redundancy pass harness.
//
// Tests `stage1RedundancyDetectionSpanish`
// (lib/core/services/prompts/correction_prompt.dart) — a standalone
// detection pass whose only job is unnecessary repeated subject pronouns
// and unnecessary emphatic pronoun phrases. Run independently from
// `stage1DetectionDialectSpanish`, never merged into it: an earlier attempt
// to fold span-cleanliness guidance directly into the main detection prompt
// (`stage1DetectionCleanSpanSpanish`, retired) caused a regression on
// ES-4-calque, so this narrower pattern gets its own dedicated pass instead
// of leaking specificity into swap-type detection.
//
// Two groups:
//   - Positive (should flag, with a clean single word/short-phrase span):
//     ES-6 "yo", ellos-redundant, ST-R2 "nosotros", ST-R1 "a mí" — text/ids
//     copied verbatim from
//     test/stage1_redundancy_model_comparison_harness.dart. ST-R1 is THE
//     hardest case (0% flag rate under every prior variant tried) — the key
//     result this harness is built to surface. Scored on flag rate AND
//     span-bucket classification (word/phrase/clause, same `_bucketFor`
//     logic as the redundancy comparison harness) — since the whole point
//     of a dedicated pass is clean spans by construction, a clause-level
//     flag here is a real failure, not just noise.
//   - Restraint (must NOT flag): three cases, deliberately NOT reusing the
//     prompt's own worked example ("A mí me gusta el fútbol, pero a ella le
//     gusta el tenis") so this tests generalization of the restraint
//     instruction, not memorization of one example. Covers genuine
//     contrast (different verb/people), a single one-off emphatic pronoun
//     with no repetition or contrast, and a clean sentence with no pronoun
//     issue at all.
//
// STANDALONE, like every other harness in this repo: helper functions are
// copied by value from the other Stage 1 harnesses, not imported. Direct
// `/v1/chat/completions` call, env-only OPENAI_API_KEY, GPT-5.5 default.
//
// Does NOT touch `correctText()`, `stage1DetectionDialectSpanish`, or any
// live path.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage1_redundancy_pass_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/stage1_redundancy_pass_harness.dart --timeout none
//
// Writes a report to docs/stage1_redundancy_pass_harness.md (override with
// --dart-define=REDUNDANCY_PASS_OUTPUT=...). Override run count per case
// with --dart-define=REDUNDANCY_PASS_RUNS_PER_CASE=... (default 10).
// Override the model with --dart-define=REDUNDANCY_PASS_MODEL=... (default
// 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'REDUNDANCY_PASS_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'REDUNDANCY_PASS_OUTPUT',
  defaultValue: 'docs/stage1_redundancy_pass_harness.md',
);

/// Model used for the live run. Override with
/// `--dart-define=REDUNDANCY_PASS_MODEL=...` (default 'gpt-5.5').
const String redundancyPassModel = String.fromEnvironment(
  'REDUNDANCY_PASS_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'REDUNDANCY_PASS_CALL_DELAY_MS',
  defaultValue: 750,
);

/// Which group a case belongs to, so the report can print them under
/// separate headings and score them differently.
enum _CaseGroup { positive, restraint }

String _groupHeading(_CaseGroup group) => switch (group) {
  _CaseGroup.positive => 'Positive cases (should flag, clean word/short-phrase span)',
  _CaseGroup.restraint => 'Restraint cases (must NOT flag)',
};

/// One test case for the dedicated redundancy pass. [pronoun] is only set
/// for positive cases — the bare redundant word/phrase checked for overlap
/// against the returned flagged phrases, not a specific occurrence.
class _Case {
  const _Case({
    required this.id,
    required this.group,
    required this.text,
    required this.note,
    this.pronoun,
  });

  final String id;
  final _CaseGroup group;
  final String text;
  final String note;
  final String? pronoun;

  bool get isPositive => group == _CaseGroup.positive;
}

const List<_Case> _cases = [
  // ── Positive: should flag, with a clean word/short-phrase span. Text/ids
  // copied verbatim from
  // test/stage1_redundancy_model_comparison_harness.dart. ──────────────
  _Case(
    id: 'ES-6-redundant-yo',
    group: _CaseGroup.positive,
    text: 'Yo fui a casa, yo estudié, y yo hice la cena.',
    pronoun: 'yo',
    note:
        'Text/id copied verbatim from '
        'test/stage1_redundancy_model_comparison_harness.dart. Spanish is '
        'pro-drop; repeating "yo" before every verb is grammatical but '
        'unnatural.',
  ),
  _Case(
    id: 'ellos-redundant',
    group: _CaseGroup.positive,
    text:
        'Ellos trabajan mucho, ellos estudian por la noche y ellos nunca '
        'descansan.',
    pronoun: 'ellos',
    note:
        'Text/id copied verbatim from '
        'test/stage1_redundancy_model_comparison_harness.dart. Third-person '
        'plural.',
  ),
  _Case(
    id: 'ST-R2-redundant-nosotros',
    group: _CaseGroup.positive,
    text:
        'Nosotros vamos al cine, nosotros comemos palomitas y nosotros '
        'volvemos a casa.',
    pronoun: 'nosotros',
    note:
        'Text/id copied verbatim from '
        'test/stage1_redundancy_model_comparison_harness.dart. Same class '
        'as ES-6, plural subject.',
  ),
  _Case(
    id: 'ST-R1-redundant-a-mi',
    group: _CaseGroup.positive,
    text:
        'Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a '
        'mí.',
    pronoun: 'a mí',
    note:
        'Text/id copied verbatim from '
        'test/stage1_redundancy_model_comparison_harness.dart. THE HARDEST '
        'case — 0% flag rate under every prior variant tried (base '
        'detection, dialect variant, clean-span variant). Key result: does '
        'a dedicated pass do any better than a shared one?',
  ),

  // ── Restraint: must NOT flag. Deliberately different content from the
  // prompt's own worked example ("A mí me gusta el fútbol, pero a ella le
  // gusta el tenis") so this tests generalization, not memorization. ────
  _Case(
    id: 'restraint-contrast',
    group: _CaseGroup.restraint,
    text: 'A mí me encanta la playa, pero a él le encanta la montaña.',
    note:
        'Genuine contrast between two different people, different verb '
        '("encantar") and people than the prompt\'s own worked example — '
        'tests generalization of the contrast exception, not memorization.',
  ),
  _Case(
    id: 'restraint-single-emphatic',
    group: _CaseGroup.restraint,
    text: 'A mí me encantó muchísimo la película.',
    note:
        'A single emphatic pronoun with no repetition and no contrast — '
        'tests whether the restraint instruction holds for ordinary one-off '
        'emphasis, not just the contrast case explicitly named in the '
        'prompt.',
  ),
  _Case(
    id: 'restraint-no-pronoun-issue',
    group: _CaseGroup.restraint,
    text: 'Compré pan y leche en el supermercado esta mañana.',
    note:
        'No pronoun at all — basic no-over-trigger sanity check that this '
        'narrowly-scoped pass does not invent a problem where none exists.',
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

/// The flagged phrases from one run that actually overlap [pronoun].
List<String> _overlappingSpans(List<String> flaggedPhrases, String pronoun) {
  return flaggedPhrases.where((phrase) => _normalizedOverlap(phrase, pronoun)).toList();
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
/// [spanBucketDistribution] are populated against [_Case.pronoun]. For
/// restraint cases, [cleanCount] is populated instead (any non-empty
/// flaggedPhrases counts as a restraint failure — the prompt is scoped to
/// this one pattern only, so any flag it returns is a pronoun/emphatic-
/// phrase flag by construction).
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
      final overlapping = _overlappingSpans(record.flaggedPhrases, testCase.pronoun!);
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
    ..writeln('# Stage 1B Dedicated Redundancy Pass Harness')
    ..writeln()
    ..writeln(
      'Tests `stage1RedundancyDetectionSpanish` — a standalone detection '
      'pass for unnecessary repeated/emphatic pronouns, run independently '
      'from `stage1DetectionDialectSpanish` and never merged into it.',
    )
    ..writeln()
    ..writeln('Model: `$model`  ')
    ..writeln('Prompt: `stage1RedundancyDetectionSpanish`  ');
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
      if (testCase.pronoun != null) {
        report.writeln('- Redundant pronoun: `${testCase.pronoun}`');
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

Future<List<String>> _callStage1RedundancyDetection({
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
          systemPrompt: stage1RedundancyDetectionSpanish,
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
  test('redundancy pass harness case fixtures are well-formed', () {
    expect(_cases.length, 7, reason: '4 positive + 3 restraint.');

    final positive = _cases.where((c) => c.group == _CaseGroup.positive);
    final restraint = _cases.where((c) => c.group == _CaseGroup.restraint);
    expect(positive.length, 4);
    expect(restraint.length, 3);

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in positive) {
      expect(testCase.pronoun, isNotNull, reason: testCase.id);
      expect(
        testCase.text.toLowerCase().contains(testCase.pronoun!.toLowerCase()),
        isTrue,
        reason: '${testCase.id}: pronoun "${testCase.pronoun}" not found in text.',
      );
    }

    for (final testCase in restraint) {
      expect(testCase.pronoun, isNull, reason: testCase.id);
    }

    // Text/ids copied verbatim from
    // stage1_redundancy_model_comparison_harness.dart — guard against
    // retyping drift.
    final textsById = {for (final c in _cases) c.id: c.text};
    expect(textsById['ES-6-redundant-yo'], 'Yo fui a casa, yo estudié, y yo hice la cena.');
    expect(
      textsById['ellos-redundant'],
      'Ellos trabajan mucho, ellos estudian por la noche y ellos nunca '
      'descansan.',
    );
    expect(
      textsById['ST-R2-redundant-nosotros'],
      'Nosotros vamos al cine, nosotros comemos palomitas y nosotros '
      'volvemos a casa.',
    );
    expect(
      textsById['ST-R1-redundant-a-mi'],
      'Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a '
      'mí.',
    );

    // Restraint cases must not reuse the prompt's own worked example.
    const promptExample = 'A mí me gusta el fútbol, pero a ella le gusta el tenis';
    for (final testCase in restraint) {
      expect(
        testCase.text,
        isNot(equals(promptExample)),
        reason: '${testCase.id}: must not reuse the prompt\'s worked example verbatim.',
      );
    }
  });

  test('runsPerCase defaults to 10', () {
    expect(runsPerCase, 10);
  });

  test('redundancyPassModel defaults to gpt-5.5', () {
    expect(redundancyPassModel, 'gpt-5.5');
  });

  test(
    'stage1RedundancyDetectionSpanish is a standalone prompt, distinct from '
    'stage1DetectionDialectSpanish, with the same JSON-array output shape',
    () {
      expect(stage1RedundancyDetectionSpanish, isNot(equals(stage1DetectionDialectSpanish)));
      expect(stage1RedundancyDetectionSpanish, contains('unnecessary repeated subject pronouns'));
      expect(stage1RedundancyDetectionSpanish, contains('pro-drop'));
      expect(
        stage1RedundancyDetectionSpanish,
        contains('Do not flag a pronoun used once for legitimate emphasis or contrast'),
      );
      expect(
        stage1RedundancyDetectionSpanish,
        contains('never the surrounding clause or sentence'),
      );
      expect(stage1RedundancyDetectionSpanish, contains('If there is nothing to flag, return none.'));

      // Same JSON-array-of-quoted-phrases output shape as
      // stage1DetectionDialectSpanish — same closing instruction sentence
      // fragment shared across every Stage 1 prompt in this file.
      const sharedOutputInstruction =
          'Return an empty array [] when nothing is wrong. Do not include '
          'indices, categories, corrected text, explanations, Markdown, or '
          'code fences — quoted phrases only.';
      expect(stage1RedundancyDetectionSpanish, contains(sharedOutputInstruction));
      expect(stage1DetectionDialectSpanish, contains(sharedOutputInstruction));
    },
  );

  test('stage1RedundancyDetectionSpanish does not mention dialect or calques', () {
    final lower = stage1RedundancyDetectionSpanish.toLowerCase();
    expect(lower, isNot(contains('dialect')));
    expect(lower, isNot(contains('calque')));
  });

  group('_bucketFor', () {
    test('single word is bucketed as word', () {
      expect(_bucketFor('yo'), _SpanBucket.word);
    });

    test('two words ("a mí") is bucketed as phrase, not word', () {
      expect(_bucketFor('a mí'), _SpanBucket.phrase);
    });

    test('four words is bucketed as phrase (upper boundary)', () {
      expect(_bucketFor('nosotros comemos palomitas hoy'), _SpanBucket.phrase);
    });

    test('five or more words is bucketed as clause', () {
      expect(_bucketFor('Yo fui a casa, yo estudié, y yo hice la cena.'), _SpanBucket.clause);
    });
  });

  group('_overlappingSpans', () {
    test('returns every flagged phrase overlapping the pronoun', () {
      final spans = _overlappingSpans([
        'yo estudié',
        'yo hice la cena',
        'unrelated phrase',
      ], 'yo');
      expect(spans, ['yo estudié', 'yo hice la cena']);
    });

    test('is case/diacritic-insensitive', () {
      expect(_overlappingSpans(['A MÍ'], 'a mí'), ['A MÍ']);
    });

    test('returns empty when nothing overlaps', () {
      expect(_overlappingSpans(['otono'], 'yo'), isEmpty);
    });
  });

  group('parseDetectionArray', () {
    test('parses a populated array', () {
      expect(parseDetectionArray('["yo"]'), ['yo']);
    });

    test('parses an empty array', () {
      expect(parseDetectionArray('[]'), isEmpty);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      expect(parseDetectionArray('```json\n["a mí"]\n```'), ['a mí']);
    });

    test('throws when no array is present', () {
      expect(() => parseDetectionArray('nothing here'), throwsFormatException);
    });

    test('throws when the array contains a non-string element', () {
      expect(() => parseDetectionArray('["yo", 42]'), throwsFormatException);
    });
  });

  group('_buildRunRecord / _errorRunRecord', () {
    test('builds a plain run record with flaggedPhrases', () {
      final record = _buildRunRecord(
        caseId: 'ES-6-redundant-yo',
        runIndex: 1,
        flaggedPhrases: ['yo'],
      );
      expect(record.isError, isFalse);
      expect(record.flaggedPhrases, ['yo']);
    });

    test('_errorRunRecord carries the error and no data', () {
      final record = _errorRunRecord(
        caseId: 'ES-6-redundant-yo',
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
      final testCase = _cases.firstWhere((c) => c.id == 'ES-6-redundant-yo');

      final records = [
        _buildRunRecord(caseId: testCase.id, runIndex: 1, flaggedPhrases: ['yo']),
        _buildRunRecord(caseId: testCase.id, runIndex: 2, flaggedPhrases: []),
        _errorRunRecord(caseId: testCase.id, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.consideredRuns, 2);
      expect(aggregate.flaggedCount, 1);
      expect(aggregate.overlappingSpanDistribution, {'yo': 1});
      expect(aggregate.spanBucketDistribution, {'word': 1});
    });

    test('a whole-clause flag is tallied under clause, not word/phrase', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-6-redundant-yo');
      final records = [
        _buildRunRecord(
          caseId: testCase.id,
          runIndex: 1,
          flaggedPhrases: ['Yo fui a casa, yo estudié, y yo hice la cena.'],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.flaggedCount, 1);
      expect(aggregate.spanBucketDistribution, {'clause': 1});
    });
  });

  group('_aggregateCase (restraint)', () {
    test('cleanCount reflects runs with zero flagged phrases', () {
      final testCase = _cases.firstWhere((c) => c.id == 'restraint-contrast');

      final records = [
        _buildRunRecord(caseId: testCase.id, runIndex: 1, flaggedPhrases: []),
        _buildRunRecord(caseId: testCase.id, runIndex: 2, flaggedPhrases: ['a mí']),
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
      final testCase = _cases.firstWhere((c) => c.id == 'restraint-contrast');
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
            text: 'Yo fui, yo comí.',
            pronoun: 'yo',
            note: 'Synthetic positive case for report golden test.',
          ),
          _Case(
            id: 'TEST-2-restraint',
            group: _CaseGroup.restraint,
            text: 'Frase de prueba sin pronombre redundante.',
            note: 'Synthetic restraint case for report golden test.',
          ),
        ],
        recordsByCaseId: {
          'TEST-1-positive': [
            _buildRunRecord(caseId: 'TEST-1-positive', runIndex: 1, flaggedPhrases: ['yo']),
            _errorRunRecord(
              caseId: 'TEST-1-positive',
              runIndex: 2,
              error: StateError('Stage 1 redundancy call timed out'),
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
    'stage1 redundancy pass harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the Stage 1B redundancy pass harness. '
          'This script does NOT fall back to any hardcoded/default key — '
          'no AppConfig involved, by design (see the file header).',
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
              final flaggedPhrases = await _callStage1RedundancyDetection(
                httpClient: httpClient,
                apiKey: apiKey,
                model: redundancyPassModel,
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
        model: redundancyPassModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath (model: $redundancyPassModel)');
    },
    timeout: const Timeout(Duration(minutes: 20)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Stage 1B Dedicated Redundancy Pass Harness\n\nTests `stage1RedundancyDetectionSpanish` — a standalone detection pass for unnecessary repeated/emphatic pronouns, run independently from `stage1DetectionDialectSpanish` and never merged into it.\n\nModel: `test-model`  \nPrompt: `stage1RedundancyDetectionSpanish`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## Positive cases (should flag, clean word/short-phrase span)\n\n### TEST-1-positive\n\n- Text: `Yo fui, yo comí.`\n- Redundant pronoun: `yo`\n- Note: Synthetic positive case for report golden test.\n\n#### Summary (2 runs, 1 error(s))\n\n- Flag rate: 100.0% (1/1)\n- Span-bucket distribution (word/phrase/clause, among flagged spans): \"word\": 1\n- Exact flagged-span distribution: \"yo\": 1\n\n#### Run detail\n\n- Run 1: flagged: \"yo\"\n- Run 2: ERROR — Bad state: Stage 1 redundancy call timed out\n\n## Restraint cases (must NOT flag)\n\n### TEST-2-restraint\n\n- Text: `Frase de prueba sin pronombre redundante.`\n- Note: Synthetic restraint case for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Stayed clean: 100.0% (2/2)\n\n#### Run detail\n\n- Run 1: flagged: (no phrases flagged)\n- Run 2: flagged: (no phrases flagged)\n\n---\n\n## Overall summary\n\n| Case | Runs | Errors | Headline rate | Span-bucket distribution |\n| --- | --- | --- | --- | --- |\n| TEST-1-positive | 2 | 1 | 100.0% (1/1) | \"word\": 1 |\n| TEST-2-restraint | 2 | 0 | 100.0% (2/2) (clean) | — |\n"';
