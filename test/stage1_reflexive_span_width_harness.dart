// Reflexive-insertion span-width harness — end-to-end, real pipeline.
//
// Context: reflexive-insertion corrections ("Quejó" -> "Se quejó", "Atrevió"
// -> "Se atrevió") were previously returning inconsistent span widths —
// sometimes the correct minimal word, sometimes the whole sentence — because
// no detection stage had span-width guidance for this pattern.
// `stage1ReflexiveDetectionSpanish` (Stage 1C, correction_prompt.dart) was
// added to close that gap and is now wired into
// `callStage1AndMergeFlaggedPhrases` (stage1_detection_client.dart),
// reached live via `runStagedCorrectionPipeline` /
// `OpenAiCorrectionService.correctText`.
//
// This harness measures whether wiring Stage 1C in actually fixed the span
// width, end to end — detection -> Stage 2 categorization -> position
// resolution -> insertion narrowing -> dedup -> Stage 3 -> corrected-range
// computation — not just Stage 1C's own output in isolation (that's what
// `stage1_reflexive_detection_harness.dart` already covers). It calls the
// real `runStagedCorrectionPipeline` against the real API, using a real
// `OpenAiChatCompletionsClient` — no fake HTTP layer, same as
// `stage1_stage2_chained_harness.dart`.
//
// Measures BOTH sides of the correction independently:
//   - Original-side span: whether the flagged/highlighted range in the
//     submitted text is exactly the bare verb ("Quejó" / "Atrevió"), nothing
//     wider.
//   - Corrected-side span: whether the highlighted range in the
//     code-reconstructed corrected text (`correctedStartIndex`/
//     `correctedEndIndex`, computed by `computeCorrectedRanges`) exactly
//     covers the inserted reflexive pronoun plus the verb ("Se quejó" / "Se
//     atrevió"), nothing wider and not missing the "Se" — since "Se" does
//     not exist anywhere in the original text, a correct original-side span
//     does not by itself guarantee a correct corrected-side span; they are
//     resolved by different code (position/insertion resolution vs.
//     `computeCorrectedRanges`) and can diverge independently.
//
// Deliberately narrow: exactly the two sentences that motivated this work,
// nothing else. This is NOT a general span-width audit — see the case list
// below.
//
// Run only the offline tests (fixture/report-format checks, no live call):
//   flutter test test/stage1_reflexive_span_width_harness.dart --exclude-tags live
//
// Run the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/stage1_reflexive_span_width_harness.dart --timeout none
//
// Writes a report to docs/stage1_reflexive_span_width_harness.md (override
// with --dart-define=REFLEXIVE_SPAN_WIDTH_OUTPUT=...). Override run count
// per case with --dart-define=REFLEXIVE_SPAN_WIDTH_RUNS_PER_CASE=...
// (default 10). Override the model with
// --dart-define=REFLEXIVE_SPAN_WIDTH_MODEL=... (default 'gpt-5.5') — this is
// the single `model` param `runStagedCorrectionPipeline` uses for every
// stage (1C included), same as every other live call in this pipeline.

import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/staged_correction_pipeline.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_note.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

const int runsPerCase = int.fromEnvironment(
  'REFLEXIVE_SPAN_WIDTH_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'REFLEXIVE_SPAN_WIDTH_OUTPUT',
  defaultValue: 'docs/stage1_reflexive_span_width_harness.md',
);

/// Model used for the live run — passed straight through to
/// `runStagedCorrectionPipeline`, which uses it for every stage (1C
/// included). Override with `--dart-define=REFLEXIVE_SPAN_WIDTH_MODEL=...`
/// (default 'gpt-5.5').
const String spanWidthModel = String.fromEnvironment(
  'REFLEXIVE_SPAN_WIDTH_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every run, same rate-limit mitigation the other harnesses in
/// this repo use.
const int callDelayMs = int.fromEnvironment(
  'REFLEXIVE_SPAN_WIDTH_CALL_DELAY_MS',
  defaultValue: 750,
);

/// One of the two sentences that motivated this harness. [targetVerb] is
/// the bare verb the resolved original-side span is expected to match
/// exactly. [expectedCorrectedPhrase] is the reflexive pronoun plus the verb
/// ("Se quejó" / "Se atrevió") the resolved corrected-side span is expected
/// to match exactly — a separate expectation, since "Se" does not appear
/// anywhere in the original text.
class _Case {
  const _Case({
    required this.id,
    required this.text,
    required this.targetVerb,
    required this.expectedCorrectedPhrase,
  });

  final String id;
  final String text;
  final String targetVerb;
  final String expectedCorrectedPhrase;
}

const List<_Case> _cases = [
  _Case(
    id: 'quejo',
    text: 'Quejó del ruido toda la noche.',
    targetVerb: 'Quejó',
    expectedCorrectedPhrase: 'Se quejó',
  ),
  _Case(
    id: 'atrevio',
    text: 'Atrevió a preguntarle directamente.',
    targetVerb: 'Atrevió',
    expectedCorrectedPhrase: 'Se atrevió',
  ),
];

/// Span-width bucket by word count — same word/phrase/clause split every
/// other span-width harness in this repo uses, reimplemented locally since
/// this harness stays standalone.
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

bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Whether [text] contains the reflexive pronoun "se" as its own word (not
/// as a substring of some other word), after normalization. Used to detect
/// the specific failure mode this harness was built to catch: a
/// corrected-side span that covers the verb but was never widened to
/// include the inserted "Se" at all.
bool _containsReflexiveToken(String text) {
  return RegExp(r'\bse\b').hasMatch(_normalizeForMatch(text));
}

/// Slices [text] by user-perceived character (grapheme cluster) offsets,
/// the same unit `correctedStartIndex`/`correctedEndIndex` are expressed in
/// (see `correction_corrected_range_calculator.dart`). Copied by value from
/// `CorrectionItem`'s private `_sliceSubmittedText` — same precedent as
/// every other copied helper in this repo's harnesses.
String _sliceCharacters(String text, int start, int end) {
  final characters = text.characters;
  if (start < 0 || end < start || end > characters.length) {
    throw FormatException(
      'Invalid corrected-side range $start..$end in text of length ${characters.length}.',
    );
  }
  return characters.skip(start).take(end - start).toString();
}

/// One resolved span the pipeline produced. `kind` is `'correction'` or
/// `'note'` for an original-side span (see [_resolvedSpansFrom]), or
/// `'corrected'` for a corrected-side span (see [_correctedSpansFrom]).
/// Reported uniformly since a surprising kind (e.g. a note, where an error
/// is expected) is itself a finding worth surfacing for these two
/// sentences.
class _ResolvedSpan {
  const _ResolvedSpan({
    required this.text,
    required this.kind,
    this.startIndex,
    this.endIndex,
  });

  final String text;
  final String kind;
  final int? startIndex;
  final int? endIndex;

  bool overlapsTarget(String target) => _normalizedOverlap(text, target);

  String describe() {
    final bucket = _bucketFor(text).name;
    final range = startIndex != null && endIndex != null
        ? ' [$startIndex, $endIndex)'
        : '';
    return '"$text"$range ($kind, $bucket)';
  }
}

/// One run's outcome for one case: both the original-side and corrected-side
/// resolved spans, captured together so a single run's full behavior is
/// visible without cross-referencing two separate records. A transient
/// API/pipeline failure is recorded via [error] rather than dropped, same as
/// every other harness's `_RunRecord`.
class _RunRecord {
  const _RunRecord({
    required this.caseId,
    required this.runIndex,
    required this.resolvedSpans,
    this.correctedSpans = const [],
    this.error,
  });

  final String caseId;
  final int runIndex;
  final List<_ResolvedSpan> resolvedSpans;
  final List<_ResolvedSpan> correctedSpans;
  final Object? error;

  bool get isError => error != null;

  /// Original-side resolved span(s) overlapping [target], if any.
  List<_ResolvedSpan> overlapping(String target) =>
      resolvedSpans.where((s) => s.overlapsTarget(target)).toList();

  /// Corrected-side resolved span(s) overlapping [target], if any.
  List<_ResolvedSpan> correctedOverlapping(String target) =>
      correctedSpans.where((s) => s.overlapsTarget(target)).toList();
}

_RunRecord _buildRunRecord({
  required String caseId,
  required int runIndex,
  required List<_ResolvedSpan> resolvedSpans,
  List<_ResolvedSpan> correctedSpans = const [],
}) {
  return _RunRecord(
    caseId: caseId,
    runIndex: runIndex,
    resolvedSpans: resolvedSpans,
    correctedSpans: correctedSpans,
  );
}

_RunRecord _errorRunRecord({
  required String caseId,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(caseId: caseId, runIndex: runIndex, resolvedSpans: const [], error: error);
}

/// Extracts the original-side resolved spans from a real
/// `CorrectionResponse`: every error-verdict correction (with its numeric
/// range) plus every dialectal note (phrase only, no numeric range —
/// `CorrectionNote` doesn't carry one).
List<_ResolvedSpan> _resolvedSpansFrom({
  required List<CorrectionItem> corrections,
  required List<CorrectionNote> notes,
}) {
  return [
    for (final c in corrections)
      _ResolvedSpan(
        text: c.originalPhrase,
        kind: 'correction',
        startIndex: c.startIndex,
        endIndex: c.endIndex,
      ),
    for (final n in notes) _ResolvedSpan(text: n.phrase, kind: 'note'),
  ];
}

/// Extracts the corrected-side resolved spans from a real
/// `CorrectionResponse`'s corrections: for every correction that carries a
/// computed `correctedStartIndex`/`correctedEndIndex` (i.e. went through
/// `computeCorrectedRanges`), slices [correctedText] at that range to get
/// the actual text it covers — not the model's own `correctedPhrase` field,
/// so a divergence between the two would itself surface as a slicing
/// mismatch rather than being silently hidden. Dialectal notes never carry
/// a corrected range (they never touch `correctedText`), so they have no
/// corrected-side counterpart here.
List<_ResolvedSpan> _correctedSpansFrom({
  required List<CorrectionItem> corrections,
  required String correctedText,
}) {
  return [
    for (final c in corrections)
      if (c.correctedStartIndex != null && c.correctedEndIndex != null)
        _ResolvedSpan(
          text: _sliceCharacters(correctedText, c.correctedStartIndex!, c.correctedEndIndex!),
          kind: 'corrected',
          startIndex: c.correctedStartIndex,
          endIndex: c.correctedEndIndex,
        ),
  ];
}

String _describeError(Object error) => error.toString();

/// Describes one run's full behavior — original-side and corrected-side
/// spans together — in a single line, so nothing about a run's outcome is
/// split across two disconnected reports.
String _describeRun(_RunRecord record, String targetVerb, String expectedCorrectedPhrase) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }

  final originalPart = record.resolvedSpans.isEmpty
      ? 'original: (none)'
      : 'original: ${record.resolvedSpans.map((s) => s.describe()).join('; ')}';

  final correctedOverlap = record.correctedOverlapping(targetVerb);
  String correctedPart;
  if (record.correctedSpans.isEmpty) {
    correctedPart = 'corrected: (none)';
  } else if (correctedOverlap.isEmpty) {
    correctedPart =
        'corrected: ${record.correctedSpans.map((s) => s.describe()).join('; ')}'
        ' — NONE overlap the target verb "$targetVerb"';
  } else {
    final hasReflexive = correctedOverlap.any((s) => _containsReflexiveToken(s.text));
    final flag = hasReflexive ? '' : ' — MISSING REFLEXIVE';
    correctedPart = 'corrected: ${correctedOverlap.map((s) => s.describe()).join('; ')}$flag';
  }

  return '- $prefix: $originalPart | $correctedPart';
}

/// Aggregated results for one case across all its runs — original-side and
/// corrected-side outcomes tallied independently, since they are resolved
/// by different code and can diverge.
class _CaseAggregate {
  const _CaseAggregate({
    required this.totalRuns,
    required this.errorRuns,
    required this.consideredRuns,
    required this.cleanRuns,
    required this.exactWordMatchCount,
    required this.overlapButWiderCount,
    required this.noOverlapCount,
    required this.bucketDistribution,
    required this.exactSpanDistribution,
    required this.correctedExactMatchCount,
    required this.correctedOverlapButWiderCount,
    required this.correctedMissingReflexiveCount,
    required this.correctedNoOverlapOrCleanCount,
    required this.correctedBucketDistribution,
    required this.correctedExactSpanDistribution,
  });

  final int totalRuns;
  final int errorRuns;
  final int consideredRuns;

  // ── Original-side (unchanged from before this harness gained corrected-
  // side reporting) ──────────────────────────────────────────────────────

  /// Runs where nothing was flagged at all.
  final int cleanRuns;

  /// Runs where exactly the target verb, nothing more, was the resolved
  /// original-side span — the desired outcome.
  final int exactWordMatchCount;

  /// Runs where a resolved original-side span overlapped the target verb
  /// but was wider than just the verb (e.g. the whole sentence).
  final int overlapButWiderCount;

  /// Runs where something was flagged but none of it overlapped the
  /// target verb at all.
  final int noOverlapCount;
  final Map<String, int> bucketDistribution;
  final Map<String, int> exactSpanDistribution;

  // ── Corrected-side ──────────────────────────────────────────────────────

  /// Runs where the corrected-side span exactly matched
  /// `expectedCorrectedPhrase` ("Se quejó" / "Se atrevió") — the desired
  /// outcome.
  final int correctedExactMatchCount;

  /// Runs where a corrected-side span overlapped the target verb and
  /// included the reflexive pronoun, but was wider than
  /// `expectedCorrectedPhrase` (e.g. covered the whole corrected sentence).
  final int correctedOverlapButWiderCount;

  /// Runs where a corrected-side span covered the verb but not the inserted
  /// "Se" at all — the specific failure mode this harness exists to catch.
  final int correctedMissingReflexiveCount;

  /// Runs where nothing on the corrected side overlapped the target verb,
  /// or nothing was highlighted on the corrected side at all. Combined into
  /// one bucket — both mean the corrected panel would show nothing useful
  /// for this correction.
  final int correctedNoOverlapOrCleanCount;
  final Map<String, int> correctedBucketDistribution;
  final Map<String, int> correctedExactSpanDistribution;
}

_CaseAggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();

  var cleanRuns = 0;
  var exactWordMatchCount = 0;
  var overlapButWiderCount = 0;
  var noOverlapCount = 0;
  final bucketDist = <String, int>{};
  final exactSpanDist = <String, int>{};

  var correctedExactMatchCount = 0;
  var correctedOverlapButWiderCount = 0;
  var correctedMissingReflexiveCount = 0;
  var correctedNoOverlapOrCleanCount = 0;
  final correctedBucketDist = <String, int>{};
  final correctedExactSpanDist = <String, int>{};

  for (final record in okRecords) {
    // ── Original side ──
    if (record.resolvedSpans.isEmpty) {
      cleanRuns++;
    } else {
      final overlapping = record.overlapping(testCase.targetVerb);
      if (overlapping.isEmpty) {
        noOverlapCount++;
      } else {
        for (final span in overlapping) {
          exactSpanDist[span.text] = (exactSpanDist[span.text] ?? 0) + 1;
          final bucketKey = _bucketFor(span.text).name;
          bucketDist[bucketKey] = (bucketDist[bucketKey] ?? 0) + 1;
        }

        final hasExactMatch = overlapping.any(
          (s) => _normalizeForMatch(s.text) == _normalizeForMatch(testCase.targetVerb),
        );
        if (hasExactMatch) {
          exactWordMatchCount++;
        } else {
          overlapButWiderCount++;
        }
      }
    }

    // ── Corrected side ──
    final correctedOverlapping = record.correctedOverlapping(testCase.targetVerb);
    if (correctedOverlapping.isEmpty) {
      correctedNoOverlapOrCleanCount++;
    } else {
      for (final span in correctedOverlapping) {
        correctedExactSpanDist[span.text] = (correctedExactSpanDist[span.text] ?? 0) + 1;
        final bucketKey = _bucketFor(span.text).name;
        correctedBucketDist[bucketKey] = (correctedBucketDist[bucketKey] ?? 0) + 1;
      }

      final hasExactMatch = correctedOverlapping.any(
        (s) => _normalizeForMatch(s.text) == _normalizeForMatch(testCase.expectedCorrectedPhrase),
      );
      if (hasExactMatch) {
        correctedExactMatchCount++;
      } else if (correctedOverlapping.any((s) => _containsReflexiveToken(s.text))) {
        correctedOverlapButWiderCount++;
      } else {
        correctedMissingReflexiveCount++;
      }
    }
  }

  return _CaseAggregate(
    totalRuns: records.length,
    errorRuns: records.length - okRecords.length,
    consideredRuns: okRecords.length,
    cleanRuns: cleanRuns,
    exactWordMatchCount: exactWordMatchCount,
    overlapButWiderCount: overlapButWiderCount,
    noOverlapCount: noOverlapCount,
    bucketDistribution: bucketDist,
    exactSpanDistribution: exactSpanDist,
    correctedExactMatchCount: correctedExactMatchCount,
    correctedOverlapButWiderCount: correctedOverlapButWiderCount,
    correctedMissingReflexiveCount: correctedMissingReflexiveCount,
    correctedNoOverlapOrCleanCount: correctedNoOverlapOrCleanCount,
    correctedBucketDistribution: correctedBucketDist,
    correctedExactSpanDistribution: correctedExactSpanDist,
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

/// Builds the full markdown report. Pure — takes already-collected
/// [recordsByCaseId] rather than making any calls itself, golden-testable
/// against synthetic data with no live API involved, same approach as every
/// other harness's `_buildReport`.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Reflexive-Insertion Span-Width Harness (End-to-End)')
    ..writeln()
    ..writeln(
      'Runs the real `runStagedCorrectionPipeline` (Stage 1/1B/1C -> Stage '
      '2 -> position resolution -> insertion narrowing -> dedup -> Stage 3 '
      '-> corrected-range computation) against exactly the two sentences '
      'that motivated adding `stage1ReflexiveDetectionSpanish`, and reports '
      'what text the final resolved span actually covers on both the '
      'original side and the corrected side.',
    )
    ..writeln()
    ..writeln('Model: `$model`  ');
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

    report
      ..writeln('## ${testCase.id}')
      ..writeln()
      ..writeln('- Text: `${testCase.text}`')
      ..writeln('- Target verb (expected exact original-side span): `${testCase.targetVerb}`')
      ..writeln(
        '- Expected corrected phrase (expected exact corrected-side span): '
        '`${testCase.expectedCorrectedPhrase}`',
      )
      ..writeln()
      ..writeln(
        '### Original-side span summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))',
      )
      ..writeln()
      ..writeln(
        '- Exact word match (span == target verb, nothing wider): '
        '${_percentLabel(aggregate.exactWordMatchCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Overlaps target but wider (e.g. whole sentence): '
        '${_percentLabel(aggregate.overlapButWiderCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Flagged something, but none of it overlaps the target verb: '
        '${_percentLabel(aggregate.noOverlapCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Clean (nothing flagged at all): '
        '${_percentLabel(aggregate.cleanRuns, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Span-bucket distribution (word/phrase/clause, among target-overlapping spans): '
        '${_describeDistribution(aggregate.bucketDistribution)}',
      )
      ..writeln(
        '- Exact resolved-span distribution (target-overlapping spans): '
        '${_describeDistribution(aggregate.exactSpanDistribution)}',
      )
      ..writeln()
      ..writeln(
        '### Corrected-side span summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))',
      )
      ..writeln()
      ..writeln(
        '- Exact match (corrected span == "${testCase.expectedCorrectedPhrase}", nothing wider): '
        '${_percentLabel(aggregate.correctedExactMatchCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Overlaps expected phrase but wider (e.g. whole corrected sentence): '
        '${_percentLabel(aggregate.correctedOverlapButWiderCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Missing the reflexive entirely (covers the verb but not "Se"): '
        '${_percentLabel(aggregate.correctedMissingReflexiveCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- No overlap / clean (nothing highlighted on the corrected side): '
        '${_percentLabel(aggregate.correctedNoOverlapOrCleanCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Span-bucket distribution (word/phrase/clause, among target-overlapping corrected spans): '
        '${_describeDistribution(aggregate.correctedBucketDistribution)}',
      )
      ..writeln(
        '- Exact corrected-span distribution (target-overlapping spans): '
        '${_describeDistribution(aggregate.correctedExactSpanDistribution)}',
      )
      ..writeln()
      ..writeln('### Run detail')
      ..writeln();

    for (final record in records) {
      report.writeln(_describeRun(record, testCase.targetVerb, testCase.expectedCorrectedPhrase));
    }
    report.writeln();

    summaryRows.add(
      '| ${testCase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
      '${_percentLabel(aggregate.exactWordMatchCount, aggregate.consideredRuns)} | '
      '${_percentLabel(aggregate.overlapButWiderCount, aggregate.consideredRuns)} | '
      '${_describeDistribution(aggregate.bucketDistribution)} | '
      '${_percentLabel(aggregate.correctedExactMatchCount, aggregate.consideredRuns)} | '
      '${_percentLabel(aggregate.correctedMissingReflexiveCount, aggregate.consideredRuns)} |',
    );
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln(
      '| Case | Runs | Errors | Exact word match | Overlap but wider | '
      'Span-bucket distribution | Corrected exact match | Corrected missing reflexive |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
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

void main() {
  test('span-width harness case fixtures are well-formed', () {
    expect(_cases.length, 2, reason: 'Exactly the two motivating sentences — no general audit.');

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(
        testCase.text.contains(testCase.targetVerb),
        isTrue,
        reason: '${testCase.id}: target verb "${testCase.targetVerb}" not found in text.',
      );
      expect(
        _normalizedOverlap(testCase.expectedCorrectedPhrase, testCase.targetVerb),
        isTrue,
        reason:
            '${testCase.id}: expected corrected phrase must still contain the '
            'target verb.',
      );
      expect(
        testCase.expectedCorrectedPhrase,
        isNot(equals(testCase.targetVerb)),
        reason: '${testCase.id}: expected corrected phrase must add "Se", not equal the bare verb.',
      );
    }

    final textsById = {for (final c in _cases) c.id: c.text};
    expect(textsById['quejo'], 'Quejó del ruido toda la noche.');
    expect(textsById['atrevio'], 'Atrevió a preguntarle directamente.');

    final expectedCorrectedById = {for (final c in _cases) c.id: c.expectedCorrectedPhrase};
    expect(expectedCorrectedById['quejo'], 'Se quejó');
    expect(expectedCorrectedById['atrevio'], 'Se atrevió');
  });

  test('runsPerCase defaults to 10', () {
    expect(runsPerCase, 10);
  });

  test('spanWidthModel defaults to gpt-5.5', () {
    expect(spanWidthModel, 'gpt-5.5');
  });

  group('_bucketFor', () {
    test('single word is bucketed as word', () {
      expect(_bucketFor('Quejó'), _SpanBucket.word);
    });

    test('two words is bucketed as phrase', () {
      expect(_bucketFor('Se quejó'), _SpanBucket.phrase);
    });

    test('a whole sentence is bucketed as clause', () {
      expect(_bucketFor('Quejó del ruido toda la noche.'), _SpanBucket.clause);
    });
  });

  group('_containsReflexiveToken', () {
    test('true when "se" appears as its own word', () {
      expect(_containsReflexiveToken('Se quejó'), isTrue);
    });

    test('false when the bare verb has no reflexive pronoun', () {
      expect(_containsReflexiveToken('Quejó'), isFalse);
    });

    test('false when the whole sentence contains no "se" token', () {
      expect(_containsReflexiveToken('Quejó del ruido toda la noche.'), isFalse);
    });

    test('is case/diacritic-insensitive', () {
      expect(_containsReflexiveToken('SE QUEJÓ'), isTrue);
    });
  });

  group('_sliceCharacters', () {
    test('slices a substring by character offsets', () {
      expect(_sliceCharacters('Se quejó del ruido.', 0, 8), 'Se quejó');
    });

    test('throws on an out-of-range end index', () {
      expect(() => _sliceCharacters('abc', 0, 10), throwsFormatException);
    });

    test('throws when end is before start', () {
      expect(() => _sliceCharacters('abc', 2, 1), throwsFormatException);
    });
  });

  group('_ResolvedSpan.overlapsTarget', () {
    test('matches the bare verb exactly', () {
      const span = _ResolvedSpan(text: 'Quejó', kind: 'correction', startIndex: 0, endIndex: 5);
      expect(span.overlapsTarget('Quejó'), isTrue);
    });

    test('matches when the span is wider than the target verb', () {
      const span = _ResolvedSpan(
        text: 'Quejó del ruido toda la noche.',
        kind: 'correction',
        startIndex: 0,
        endIndex: 31,
      );
      expect(span.overlapsTarget('Quejó'), isTrue);
    });

    test('does not match an unrelated span', () {
      const span = _ResolvedSpan(text: 'ruido', kind: 'correction', startIndex: 6, endIndex: 11);
      expect(span.overlapsTarget('Quejó'), isFalse);
    });
  });

  group('_resolvedSpansFrom', () {
    test('maps corrections and notes into a uniform list', () {
      final spans = _resolvedSpansFrom(
        corrections: const [
          CorrectionItem(
            originalPhrase: 'Quejó',
            correctedPhrase: 'Se quejó',
            category: ErrorCategory.grammar,
            shortExplanation: '',
            startIndex: 0,
            endIndex: 5,
          ),
        ],
        notes: const [CorrectionNote(phrase: 'autobús', note: 'dialectal split')],
      );

      expect(spans, hasLength(2));
      expect(spans[0].text, 'Quejó');
      expect(spans[0].kind, 'correction');
      expect(spans[0].startIndex, 0);
      expect(spans[0].endIndex, 5);
      expect(spans[1].text, 'autobús');
      expect(spans[1].kind, 'note');
      expect(spans[1].startIndex, isNull);
    });
  });

  group('_correctedSpansFrom', () {
    test('slices the corrected text at each correction\'s corrected range', () {
      final spans = _correctedSpansFrom(
        corrections: const [
          CorrectionItem(
            originalPhrase: 'Quejó',
            correctedPhrase: 'Se quejó',
            category: ErrorCategory.grammar,
            shortExplanation: '',
            startIndex: 0,
            endIndex: 5,
            correctedStartIndex: 0,
            correctedEndIndex: 8,
          ),
        ],
        correctedText: 'Se quejó del ruido toda la noche.',
      );

      expect(spans, hasLength(1));
      expect(spans[0].text, 'Se quejó');
      expect(spans[0].kind, 'corrected');
      expect(spans[0].startIndex, 0);
      expect(spans[0].endIndex, 8);
    });

    test('skips corrections with no computed corrected range', () {
      final spans = _correctedSpansFrom(
        corrections: const [
          CorrectionItem(
            originalPhrase: 'Quejó',
            correctedPhrase: 'Se quejó',
            category: ErrorCategory.grammar,
            shortExplanation: '',
            startIndex: 0,
            endIndex: 5,
          ),
        ],
        correctedText: 'Se quejó del ruido toda la noche.',
      );

      expect(spans, isEmpty);
    });
  });

  group('_aggregateCase (original side)', () {
    test('an exact-match run is tallied as exactWordMatchCount, not overlapButWiderCount', () {
      const testCase = _Case(
        id: 'quejo',
        text: 'Quejó del ruido toda la noche.',
        targetVerb: 'Quejó',
        expectedCorrectedPhrase: 'Se quejó',
      );
      final records = [
        _buildRunRecord(
          caseId: 'quejo',
          runIndex: 1,
          resolvedSpans: const [
            _ResolvedSpan(text: 'Quejó', kind: 'correction', startIndex: 0, endIndex: 5),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.exactWordMatchCount, 1);
      expect(aggregate.overlapButWiderCount, 0);
      expect(aggregate.bucketDistribution, {'word': 1});
    });

    test('a whole-sentence run is tallied as overlapButWiderCount, bucketed clause', () {
      const testCase = _Case(
        id: 'quejo',
        text: 'Quejó del ruido toda la noche.',
        targetVerb: 'Quejó',
        expectedCorrectedPhrase: 'Se quejó',
      );
      final records = [
        _buildRunRecord(
          caseId: 'quejo',
          runIndex: 1,
          resolvedSpans: const [
            _ResolvedSpan(
              text: 'Quejó del ruido toda la noche.',
              kind: 'correction',
              startIndex: 0,
              endIndex: 31,
            ),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.exactWordMatchCount, 0);
      expect(aggregate.overlapButWiderCount, 1);
      expect(aggregate.bucketDistribution, {'clause': 1});
    });

    test('a clean run (nothing flagged) is tallied as cleanRuns', () {
      const testCase = _Case(
        id: 'quejo',
        text: 'Quejó del ruido toda la noche.',
        targetVerb: 'Quejó',
        expectedCorrectedPhrase: 'Se quejó',
      );
      final records = [
        _buildRunRecord(caseId: 'quejo', runIndex: 1, resolvedSpans: const []),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.cleanRuns, 1);
      expect(aggregate.exactWordMatchCount, 0);
    });

    test('a run flagging something unrelated is tallied as noOverlapCount', () {
      const testCase = _Case(
        id: 'quejo',
        text: 'Quejó del ruido toda la noche.',
        targetVerb: 'Quejó',
        expectedCorrectedPhrase: 'Se quejó',
      );
      final records = [
        _buildRunRecord(
          caseId: 'quejo',
          runIndex: 1,
          resolvedSpans: const [
            _ResolvedSpan(text: 'noche', kind: 'correction', startIndex: 25, endIndex: 30),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.noOverlapCount, 1);
      expect(aggregate.exactWordMatchCount, 0);
      expect(aggregate.overlapButWiderCount, 0);
    });

    test('error runs are excluded from consideredRuns and every count', () {
      const testCase = _Case(
        id: 'quejo',
        text: 'Quejó del ruido toda la noche.',
        targetVerb: 'Quejó',
        expectedCorrectedPhrase: 'Se quejó',
      );
      final records = [
        _errorRunRecord(caseId: 'quejo', runIndex: 1, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 1);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.consideredRuns, 0);
      expect(aggregate.cleanRuns, 0);
    });
  });

  group('_aggregateCase (corrected side)', () {
    const testCase = _Case(
      id: 'quejo',
      text: 'Quejó del ruido toda la noche.',
      targetVerb: 'Quejó',
      expectedCorrectedPhrase: 'Se quejó',
    );

    test('an exact corrected match is tallied as correctedExactMatchCount', () {
      final records = [
        _buildRunRecord(
          caseId: 'quejo',
          runIndex: 1,
          resolvedSpans: const [
            _ResolvedSpan(text: 'Quejó', kind: 'correction', startIndex: 0, endIndex: 5),
          ],
          correctedSpans: const [
            _ResolvedSpan(text: 'Se quejó', kind: 'corrected', startIndex: 0, endIndex: 8),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.correctedExactMatchCount, 1);
      expect(aggregate.correctedOverlapButWiderCount, 0);
      expect(aggregate.correctedMissingReflexiveCount, 0);
      expect(aggregate.correctedBucketDistribution, {'phrase': 1});
    });

    test('a whole-corrected-sentence span (has "se") is tallied as correctedOverlapButWiderCount', () {
      final records = [
        _buildRunRecord(
          caseId: 'quejo',
          runIndex: 1,
          resolvedSpans: const [
            _ResolvedSpan(text: 'Quejó', kind: 'correction', startIndex: 0, endIndex: 5),
          ],
          correctedSpans: const [
            _ResolvedSpan(
              text: 'Se quejó del ruido toda la noche.',
              kind: 'corrected',
              startIndex: 0,
              endIndex: 34,
            ),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.correctedExactMatchCount, 0);
      expect(aggregate.correctedOverlapButWiderCount, 1);
      expect(aggregate.correctedMissingReflexiveCount, 0);
    });

    test(
      'a corrected span covering the verb but without "se" is tallied as '
      'correctedMissingReflexiveCount',
      () {
        final records = [
          _buildRunRecord(
            caseId: 'quejo',
            runIndex: 1,
            resolvedSpans: const [
              _ResolvedSpan(text: 'Quejó', kind: 'correction', startIndex: 0, endIndex: 5),
            ],
            correctedSpans: const [
              _ResolvedSpan(text: 'Quejó', kind: 'corrected', startIndex: 0, endIndex: 5),
            ],
          ),
        ];

        final aggregate = _aggregateCase(testCase, records);

        expect(aggregate.correctedExactMatchCount, 0);
        expect(aggregate.correctedOverlapButWiderCount, 0);
        expect(aggregate.correctedMissingReflexiveCount, 1);
      },
    );

    test(
      'no corrected spans at all is tallied as correctedNoOverlapOrCleanCount',
      () {
        final records = [
          _buildRunRecord(caseId: 'quejo', runIndex: 1, resolvedSpans: const []),
        ];

        final aggregate = _aggregateCase(testCase, records);

        expect(aggregate.correctedNoOverlapOrCleanCount, 1);
        expect(aggregate.correctedExactMatchCount, 0);
      },
    );

    test(
      'a corrected span present but unrelated to the target verb is also '
      'tallied as correctedNoOverlapOrCleanCount',
      () {
        final records = [
          _buildRunRecord(
            caseId: 'quejo',
            runIndex: 1,
            resolvedSpans: const [],
            correctedSpans: const [
              _ResolvedSpan(text: 'noche', kind: 'corrected', startIndex: 25, endIndex: 30),
            ],
          ),
        ];

        final aggregate = _aggregateCase(testCase, records);

        expect(aggregate.correctedNoOverlapOrCleanCount, 1);
        expect(aggregate.correctedMissingReflexiveCount, 0);
      },
    );
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, per-case original + corrected summaries + unified run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: const [
          _Case(
            id: 'quejo',
            text: 'Quejó del ruido toda la noche.',
            targetVerb: 'Quejó',
            expectedCorrectedPhrase: 'Se quejó',
          ),
        ],
        recordsByCaseId: {
          'quejo': [
            _buildRunRecord(
              caseId: 'quejo',
              runIndex: 1,
              resolvedSpans: const [
                _ResolvedSpan(text: 'Quejó', kind: 'correction', startIndex: 0, endIndex: 5),
              ],
              correctedSpans: const [
                _ResolvedSpan(text: 'Se quejó', kind: 'corrected', startIndex: 0, endIndex: 8),
              ],
            ),
            _errorRunRecord(
              caseId: 'quejo',
              runIndex: 2,
              error: StateError('Stage 1 reflexive span-width call timed out'),
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'reflexive span-width harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the reflexive span-width harness. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final client = OpenAiChatCompletionsClient(apiKey: apiKey, httpClient: httpClient);
      final recordsByCaseId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in _cases) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (var run = 1; run <= runsPerCase; run++) {
            _RunRecord record;
            try {
              final response = await runStagedCorrectionPipeline(
                client: client,
                model: spanWidthModel,
                submittedText: testCase.text,
              );
              record = _buildRunRecord(
                caseId: testCase.id,
                runIndex: run,
                resolvedSpans: _resolvedSpansFrom(
                  corrections: response.corrections,
                  notes: response.notes,
                ),
                correctedSpans: _correctedSpansFrom(
                  corrections: response.corrections,
                  correctedText: response.correctedText,
                ),
              );
            } catch (error) {
              record = _errorRunRecord(caseId: testCase.id, runIndex: run, error: error);
            }
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(record, testCase.targetVerb, testCase.expectedCorrectedPhrase));
            await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
          }

          recordsByCaseId[testCase.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: spanWidthModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath (model: $spanWidthModel)');
    },
    timeout: const Timeout(Duration(minutes: 20)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Reflexive-Insertion Span-Width Harness (End-to-End)\n\nRuns the real `runStagedCorrectionPipeline` (Stage 1/1B/1C -> Stage 2 -> position resolution -> insertion narrowing -> dedup -> Stage 3 -> corrected-range computation) against exactly the two sentences that motivated adding `stage1ReflexiveDetectionSpanish`, and reports what text the final resolved span actually covers on both the original side and the corrected side.\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## quejo\n\n- Text: `Quejó del ruido toda la noche.`\n- Target verb (expected exact original-side span): `Quejó`\n- Expected corrected phrase (expected exact corrected-side span): `Se quejó`\n\n### Original-side span summary (2 runs, 1 error(s))\n\n- Exact word match (span == target verb, nothing wider): 100.0% (1/1)\n- Overlaps target but wider (e.g. whole sentence): 0.0% (0/1)\n- Flagged something, but none of it overlaps the target verb: 0.0% (0/1)\n- Clean (nothing flagged at all): 0.0% (0/1)\n- Span-bucket distribution (word/phrase/clause, among target-overlapping spans): \"word\": 1\n- Exact resolved-span distribution (target-overlapping spans): \"Quejó\": 1\n\n### Corrected-side span summary (2 runs, 1 error(s))\n\n- Exact match (corrected span == \"Se quejó\", nothing wider): 100.0% (1/1)\n- Overlaps expected phrase but wider (e.g. whole corrected sentence): 0.0% (0/1)\n- Missing the reflexive entirely (covers the verb but not \"Se\"): 0.0% (0/1)\n- No overlap / clean (nothing highlighted on the corrected side): 0.0% (0/1)\n- Span-bucket distribution (word/phrase/clause, among target-overlapping corrected spans): \"phrase\": 1\n- Exact corrected-span distribution (target-overlapping spans): \"Se quejó\": 1\n\n### Run detail\n\n- Run 1: original: \"Quejó\" [0, 5) (correction, word) | corrected: \"Se quejó\" [0, 8) (corrected, phrase)\n- Run 2: ERROR — Bad state: Stage 1 reflexive span-width call timed out\n\n---\n\n## Overall summary\n\n| Case | Runs | Errors | Exact word match | Overlap but wider | Span-bucket distribution | Corrected exact match | Corrected missing reflexive |\n| --- | --- | --- | --- | --- | --- | --- | --- |\n| quejo | 2 | 1 | 100.0% (1/1) | 0.0% (0/1) | \"word\": 1 | 100.0% (1/1) | 0.0% (0/1) |\n"';
