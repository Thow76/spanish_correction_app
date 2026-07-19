// Stage 1 redundancy model-comparison harness.
//
// Focused, single-purpose harness: tests `stage1DetectionDialectSpanish`
// (the adopted Stage 1 detection variant) against redundant-pronoun cases
// ONLY, parameterized by model so the exact same harness can be pointed at
// GPT-5.6-sol and GPT-5.5 for a direct before/after comparison. Redundancy
// (redundant subject/emphatic pronouns — "yo", "nosotros", "a mí", "ellos")
// is a Stage 1 DETECTION problem: the model under-flags it, or flags it
// with a messy whole-sentence/fragment span instead of a clean one. This is
// Stage 1 only — no Stage 2 categorization, no chaining — since the
// question here is purely "does detection improve," not how a flagged
// phrase gets categorized or explained downstream.
//
// Model IDs (verified against OpenAI's API, released 2026-07-09): GPT-5.6
// is a three-model family on /v1/chat/completions — gpt-5.6-sol (flagship
// reasoning; gpt-5.6 aliases to this), gpt-5.6-terra (balanced,
// ~5.5-level), gpt-5.6-luna (fast/cheap). Redundancy is a subtle judgment
// task, so the comparison is specifically gpt-5.6-sol vs. the current
// gpt-5.5 baseline — not the other two family members.
//
// STANDALONE, like every other harness in this repo: helper functions
// (`_normalizeForMatch`/`_normalizedOverlap`/`buildChatCompletionsBody`/
// `extractReplyText`/`parseDetectionArray`) are copied by value from
// test/stage1_detection_harness.dart, not imported. Direct
// `/v1/chat/completions` call, env-only OPENAI_API_KEY, no AppConfig.
//
// Battery (redundancy cases only — NOT the full Stage 1 battery):
//   - ES-6: redundant "yo" (text/id copied verbatim from
//     test/stage1_detection_harness.dart's ES-6-redundant-pronoun).
//   - ST-R2: redundant "nosotros" (copied verbatim from
//     test/stage1_detection_harness.dart's ST-R2-redundant-pronoun).
//   - ST-R1: redundant emphatic "a mí" — the hardest case, 0/10 flag rate
//     in the earlier structural-battery run (also copied verbatim from
//     test/stage1_detection_harness.dart's ST-R1-redundant-article).
//   - ellos-redundant: a new case (redundant "ellos") for a broader sample
//     beyond yo/nosotros.
//
// Scoring per case, per run: (a) flag rate — did ANY returned phrase
// overlap the redundant pronoun at all (not which specific occurrence —
// this harness checks whether the redundancy pattern gets noticed at all,
// not per-occurrence precision, which the full Stage 1 harness already
// covers); (b) span cleanliness — every overlapping flagged phrase is
// bucketed by word count (word/phrase/clause, same buckets
// correction_consistency_harness.dart uses) and tallied, since a model that
// flags redundancy 10/10 but always quotes the whole sentence is a
// different (and less useful) outcome than one that quotes a clean single
// pronoun. Exact flagged spans are always recorded — both as a per-case
// distribution and in full per-run detail — since span quality matters as
// much as flag rate for downstream positioning.
//
// Model is read from --dart-define=REDUNDANCY_MODEL (default 'gpt-5.5') —
// this is what changes between the two comparison runs; nothing else in
// this file needs to change to point at a different model ID. The report
// header states the model ID prominently, and the report format is
// otherwise identical between runs so the two output files diff cleanly.
//
// Does NOT touch `correctText()`, any prompt constant, or any live path.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage1_redundancy_model_comparison_harness.dart --exclude-tags live
//
// Run against the gpt-5.5 baseline:
//   REDUNDANCY_MODEL=gpt-5.5 OPENAI_API_KEY=sk-... flutter test test/stage1_redundancy_model_comparison_harness.dart --timeout none
//
// Run against gpt-5.6-sol:
//   REDUNDANCY_MODEL=gpt-5.6-sol OPENAI_API_KEY=sk-... flutter test test/stage1_redundancy_model_comparison_harness.dart --timeout none
//
// IMPORTANT: the output path is NOT model-keyed by default — running twice
// with the default --dart-define=REDUNDANCY_OUTPUT overwrites the first
// report. Pass a distinct output path per run so both are available to
// diff, e.g.:
//   --dart-define=REDUNDANCY_OUTPUT=docs/stage1_redundancy_gpt-5.5.md
//   --dart-define=REDUNDANCY_OUTPUT=docs/stage1_redundancy_gpt-5.6-sol.md
// (default docs/stage1_redundancy_model_comparison_harness.md). Override
// run count per case with --dart-define=REDUNDANCY_RUNS_PER_CASE=...
// (default 10).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'REDUNDANCY_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'REDUNDANCY_OUTPUT',
  defaultValue: 'docs/stage1_redundancy_model_comparison_harness.md',
);

/// The one thing that changes between the two comparison runs. Override
/// with --dart-define=REDUNDANCY_MODEL=gpt-5.6-sol (default 'gpt-5.5').
const String redundancyModel = String.fromEnvironment(
  'REDUNDANCY_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'REDUNDANCY_CALL_DELAY_MS',
  defaultValue: 750,
);

/// One redundancy test case. [pronoun] is the bare redundant word/phrase
/// checked for overlap against Stage 1's returned flagged phrases — not a
/// specific occurrence (unlike the full Stage 1 harness's ES-6/ST-R2
/// entries, which target specific instances like "yo estudié" to test
/// per-occurrence precision). This harness only asks "did the redundancy
/// pattern get noticed at all, and how clean was the span."
class _RedundancyCase {
  const _RedundancyCase({
    required this.id,
    required this.text,
    required this.pronoun,
    required this.note,
  });

  final String id;
  final String text;
  final String pronoun;
  final String note;
}

const List<_RedundancyCase> _cases = [
  _RedundancyCase(
    id: 'ES-6-redundant-yo',
    text: 'Yo fui a casa, yo estudié, y yo hice la cena.',
    pronoun: 'yo',
    note:
        'Text/id copied verbatim from test/stage1_detection_harness.dart\'s '
        'ES-6-redundant-pronoun. Spanish is pro-drop; repeating "yo" '
        'before every verb is grammatical but unnatural.',
  ),
  _RedundancyCase(
    id: 'ST-R2-redundant-nosotros',
    text:
        'Nosotros vamos al cine, nosotros comemos palomitas y nosotros '
        'volvemos a casa.',
    pronoun: 'nosotros',
    note:
        'Text/id copied verbatim from test/stage1_detection_harness.dart\'s '
        'ST-R2-redundant-pronoun. Same class as ES-6, plural subject.',
  ),
  _RedundancyCase(
    id: 'ST-R1-redundant-a-mi',
    text:
        'Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a '
        'mí.',
    pronoun: 'a mí',
    note:
        'Text/id copied verbatim from test/stage1_detection_harness.dart\'s '
        'ST-R1-redundant-article. THE HARDEST case — 0/10 flag rate in the '
        'earlier structural-battery run. Included specifically to see '
        'whether gpt-5.6-sol does any better than the gpt-5.5 baseline '
        'here. Redundant emphatic "a mí" given "me gusta" already marks '
        'the subject.',
  ),
  _RedundancyCase(
    id: 'ellos-redundant',
    text:
        'Ellos trabajan mucho, ellos estudian por la noche y ellos nunca '
        'descansan.',
    pronoun: 'ellos',
    note:
        'New case, not in the existing battery — a broader sample beyond '
        'yo/nosotros, third-person plural.',
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Copied by value from
/// test/stage1_detection_harness.dart's `_normalizeForMatch` — this file
/// stays standalone, so it's duplicated rather than imported.
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
/// by value from test/stage1_detection_harness.dart's `_normalizedOverlap`.
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Span-width bucket for a flagged phrase, by word count — same
/// word/phrase/clause split correction_consistency_harness.dart's
/// `SpanBucket` uses, reimplemented locally since that file isn't imported
/// (this harness stays standalone). A single redundant pronoun quoted
/// cleanly lands in `word`; a whole clause or sentence lands in `clause`.
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

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. Copied by value from test/stage1_detection_harness.dart's
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
/// from test/stage1_detection_harness.dart's `extractReplyText`.
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

/// Parses a Stage 1 reply into the list of quoted phrases it flagged.
/// Copied by value from test/stage1_detection_harness.dart's
/// `parseDetectionArray`.
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
      throw FormatException(
        'Stage 1 reply array contained a non-string element: $element',
      );
    }
    return element;
  }).toList();
}

/// One run's outcome for one case. A transient API failure is recorded via
/// [error] rather than dropped, same as the other harnesses.
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

/// The flagged phrases from one run that actually overlap [pronoun] — a run
/// may return zero, one, or several (e.g. flagging two of the three
/// redundant "yo" instances as separate entries).
List<String> _overlappingSpans(List<String> flaggedPhrases, String pronoun) {
  return flaggedPhrases.where((phrase) => _normalizedOverlap(phrase, pronoun)).toList();
}

/// Aggregated results for one case across all its runs.
class _CaseAggregate {
  const _CaseAggregate({
    required this.caseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.consideredRuns,
    required this.flaggedCount,
    required this.overlappingSpanDistribution,
    required this.spanBucketDistribution,
  });

  final String caseId;
  final int totalRuns;
  final int errorRuns;

  /// Non-error runs — the denominator for [flaggedCount].
  final int consideredRuns;

  /// Runs where at least one returned phrase overlapped the pronoun.
  final int flaggedCount;

  /// Tally of every overlapping flagged phrase's exact text, across all
  /// runs (a run contributing more than one overlapping phrase counts each
  /// separately).
  final Map<String, int> overlappingSpanDistribution;

  /// Tally of every overlapping flagged phrase's word/phrase/clause bucket,
  /// across all runs — the span-cleanliness signal.
  final Map<String, int> spanBucketDistribution;
}

_CaseAggregate _aggregateCase(_RedundancyCase testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  var flaggedCount = 0;
  final overlapDist = <String, int>{};
  final bucketDist = <String, int>{};

  for (final record in okRecords) {
    final overlapping = _overlappingSpans(record.flaggedPhrases, testCase.pronoun);
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

/// Builds the full markdown report: a header block naming the model
/// prominently (the whole point of running this twice), one subsection per
/// case (flag rate, span-bucket distribution, exact overlapping-span
/// distribution, full run-by-run detail), then an overall-summary table.
///
/// Pure — takes already-collected [recordsByCaseId] rather than making any
/// calls itself, golden-testable against synthetic data with no live API
/// involved, same approach as the other harnesses' `_buildReport`. The
/// golden test always passes a literal `model` string ('test-model'), so
/// this report format is inherently model-agnostic — nothing here depends
/// on which real model (gpt-5.5 vs. gpt-5.6-sol) produced the input data.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_RedundancyCase> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Stage 1 Redundancy Model-Comparison Harness')
    ..writeln()
    ..writeln('Model: `$model`  ')
    ..writeln('Prompt: `stage1DetectionDialectSpanish`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per case: $runsPerCase')
    ..writeln();

  final summaryRows = <String>[];

  for (final testCase in cases) {
    final records = recordsByCaseId[testCase.id] ?? const <_RunRecord>[];
    final aggregate = _aggregateCase(testCase, records);
    final flagRateLabel = _percentLabel(aggregate.flaggedCount, aggregate.consideredRuns);

    report
      ..writeln('## ${testCase.id}')
      ..writeln()
      ..writeln('- Text: `${testCase.text}`')
      ..writeln('- Redundant pronoun: `${testCase.pronoun}`')
      ..writeln('- Note: ${testCase.note}')
      ..writeln()
      ..writeln(
        '### Summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))',
      )
      ..writeln()
      ..writeln('- Flag rate: $flagRateLabel')
      ..writeln(
        '- Span-bucket distribution (word/phrase/clause, among flagged spans): '
        '${_describeDistribution(aggregate.spanBucketDistribution)}',
      )
      ..writeln(
        '- Exact flagged-span distribution: '
        '${_describeDistribution(aggregate.overlappingSpanDistribution)}',
      )
      ..writeln()
      ..writeln('### Run detail')
      ..writeln();

    for (final record in records) {
      report.writeln(_describeRun(record));
    }
    report.writeln();

    summaryRows.add('| ${testCase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | $flagRateLabel | '
        '${_describeDistribution(aggregate.spanBucketDistribution)} |');
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Case | Runs | Errors | Flag rate | Span-bucket distribution |')
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

Future<List<String>> _callStage1Detection({
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
          systemPrompt: stage1DetectionDialectSpanish,
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

  return parseDetectionArray(extractReplyText(decoded));
}

void main() {
  test('redundancy comparison harness case fixtures are well-formed', () {
    expect(_cases.length, 4, reason: 'ES-6, ST-R2, ST-R1, plus one new "ellos" case.');

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(testCase.text.trim(), isNotEmpty, reason: testCase.id);
      expect(
        testCase.text.toLowerCase().contains(testCase.pronoun.toLowerCase()),
        isTrue,
        reason: '${testCase.id}: pronoun "${testCase.pronoun}" not found in text.',
      );
    }

    expect(
      _cases.map((c) => c.id).toList(),
      ['ES-6-redundant-yo', 'ST-R2-redundant-nosotros', 'ST-R1-redundant-a-mi', 'ellos-redundant'],
    );

    // Text copied verbatim from test/stage1_detection_harness.dart — guard
    // against retyping drift.
    final textsById = {for (final c in _cases) c.id: c.text};
    expect(
      textsById['ES-6-redundant-yo'],
      'Yo fui a casa, yo estudié, y yo hice la cena.',
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
  });

  test(
    'redundancyModel defaults to gpt-5.5 and is the only thing that varies '
    'between comparison runs',
    () {
      expect(redundancyModel, 'gpt-5.5');
    },
  );

  group('_bucketFor', () {
    test('single word is bucketed as word', () {
      expect(_bucketFor('yo'), _SpanBucket.word);
    });

    test('two words ("a mí") is bucketed as phrase, not word', () {
      // Only a single-token span (e.g. bare "yo") counts as `word`; "a mí"
      // is two tokens, so it lands in `phrase` even though it's the
      // cleanest possible quote for that target. Documented explicitly so
      // the bucket boundary isn't mistaken for a bug when reading the report.
      expect(_bucketFor('a mí'), _SpanBucket.phrase);
    });

    test('four words is bucketed as phrase (upper boundary)', () {
      expect(_bucketFor('nosotros comemos palomitas hoy'), _SpanBucket.phrase);
    });

    test('five or more words is bucketed as clause', () {
      expect(
        _bucketFor('Yo fui a casa, yo estudié, y yo hice la cena.'),
        _SpanBucket.clause,
      );
    });
  });

  group('_overlappingSpans', () {
    test('returns every flagged phrase overlapping the pronoun', () {
      final spans = _overlappingSpans(
        ['yo estudié', 'yo hice la cena', 'unrelated phrase'],
        'yo',
      );
      expect(spans, ['yo estudié', 'yo hice la cena']);
    });

    test('is case/diacritic-insensitive', () {
      expect(_overlappingSpans(['A MÍ'], 'a mí'), ['A MÍ']);
    });

    test('returns empty when nothing overlaps', () {
      expect(_overlappingSpans(['otono'], 'yo'), isEmpty);
    });

    test('returns empty for an empty flaggedPhrases list', () {
      expect(_overlappingSpans([], 'yo'), isEmpty);
    });
  });

  group('parseDetectionArray', () {
    test('parses a populated array', () {
      expect(parseDetectionArray('["yo estudié"]'), ['yo estudié']);
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
  });

  group('_buildRunRecord / _errorRunRecord', () {
    test('builds a plain run record with flaggedPhrases', () {
      final record = _buildRunRecord(
        caseId: 'ES-6-redundant-yo',
        runIndex: 1,
        flaggedPhrases: ['yo estudié'],
      );
      expect(record.isError, isFalse);
      expect(record.flaggedPhrases, ['yo estudié']);
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

  group('_aggregateCase', () {
    test('flag rate and distributions computed over non-error runs only', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-6-redundant-yo');

      final records = [
        _buildRunRecord(
          caseId: testCase.id,
          runIndex: 1,
          flaggedPhrases: ['yo estudié', 'yo hice la cena'],
        ),
        _buildRunRecord(caseId: testCase.id, runIndex: 2, flaggedPhrases: []),
        _errorRunRecord(caseId: testCase.id, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.consideredRuns, 2);
      expect(aggregate.flaggedCount, 1);
      expect(aggregate.overlappingSpanDistribution, {'yo estudié': 1, 'yo hice la cena': 1});
      expect(aggregate.spanBucketDistribution, {'phrase': 2});
    });

    test('a whole-clause flag is tallied under clause, not phrase', () {
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

    test('all runs erroring yields zeroed aggregates, not a crash', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-6-redundant-yo');
      final records = [
        _errorRunRecord(caseId: testCase.id, runIndex: 1, error: StateError('a')),
        _errorRunRecord(caseId: testCase.id, runIndex: 2, error: StateError('b')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 2);
      expect(aggregate.errorRuns, 2);
      expect(aggregate.consideredRuns, 0);
      expect(aggregate.flaggedCount, 0);
      expect(aggregate.overlappingSpanDistribution, isEmpty);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header states the model, per-case summary + run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: const [
          _RedundancyCase(
            id: 'TEST-1-yo',
            text: 'Yo fui, yo comí.',
            pronoun: 'yo',
            note: 'Synthetic case for report golden test.',
          ),
        ],
        recordsByCaseId: {
          'TEST-1-yo': [
            _buildRunRecord(
              caseId: 'TEST-1-yo',
              runIndex: 1,
              flaggedPhrases: ['yo comí'],
            ),
            _errorRunRecord(
              caseId: 'TEST-1-yo',
              runIndex: 2,
              error: StateError('Stage 1 call timed out'),
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'stage1 redundancy model-comparison harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the redundancy model-comparison '
          'harness. This script does NOT fall back to any hardcoded/'
          'default key — no AppConfig involved, by design (see the file '
          'header).',
        );
      }

      final httpClient = HttpClient();
      final recordsByCaseId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in _cases) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${testCase.id} (model: $redundancyModel) ===');

          for (var run = 1; run <= runsPerCase; run++) {
            _RunRecord record;
            try {
              final flaggedPhrases = await _callStage1Detection(
                httpClient: httpClient,
                apiKey: apiKey,
                model: redundancyModel,
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
        model: redundancyModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath (model: $redundancyModel)');
    },
    timeout: const Timeout(Duration(minutes: 20)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Stage 1 Redundancy Model-Comparison Harness\n\nModel: `test-model`  \nPrompt: `stage1DetectionDialectSpanish`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## TEST-1-yo\n\n- Text: `Yo fui, yo comí.`\n- Redundant pronoun: `yo`\n- Note: Synthetic case for report golden test.\n\n### Summary (2 runs, 1 error(s))\n\n- Flag rate: 100.0% (1/1)\n- Span-bucket distribution (word/phrase/clause, among flagged spans): \"phrase\": 1\n- Exact flagged-span distribution: \"yo comí\": 1\n\n### Run detail\n\n- Run 1: flagged: \"yo comí\"\n- Run 2: ERROR — Bad state: Stage 1 call timed out\n\n---\n\n## Overall summary\n\n| Case | Runs | Errors | Flag rate | Span-bucket distribution |\n| --- | --- | --- | --- | --- |\n| TEST-1-yo | 2 | 1 | 100.0% (1/1) | \"phrase\": 1 |\n"';
