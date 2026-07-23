// Stage 2 `span_scope` classification-consistency harness.
//
// Tests the new `span_scope` field alone (correction_prompt.dart's
// `stage2CategorizationSpanish`, `exact` vs `full`) — separate from
// `stage2_categorization_harness.dart`, which already covers verdict/
// category/corrected_phrase/occurrence and does not score span_scope at
// all. This harness exists to answer one question before any span-trimming
// logic gets wired to this field (STEP 4/5): does Stage 2 self-report
// span_scope consistently across repeated runs of the same input, and does
// it match the value a human would assign? Same bar this repo already
// applies to occurrence gating in `stage2_categorization_harness.dart`'s
// ES-1-occurrence case.
//
// ISOLATED, not chained to a live Stage 1 call and not run through
// `runStagedCorrectionPipeline` — same reasoning as
// `stage2_categorization_harness.dart`: each case's single flagged phrase
// is hand-written, standing in for whatever Stage 1 would have produced,
// so a Stage 2 span_scope regression can't be a Stage 1 regression in
// disguise. Direct `/v1/chat/completions` call, env-only OPENAI_API_KEY, no
// AppConfig fallback — same as every other live harness in this repo.
//
// Does NOT touch `correctText()`, `staged_correction_pipeline.dart`, or any
// live path. span_scope is parsed and stored on `StagedCorrectionCandidate`
// (see staged_correction_span_scope.dart) but nothing yet reads it to
// adjust a span — this harness is what gates whether that wiring is safe
// to add.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage2_span_scope_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls — 4
// cases x 10 runs = 40 calls by default):
//   OPENAI_API_KEY=sk-... flutter test test/stage2_span_scope_harness.dart --timeout none
//
// Writes a report to docs/stage2_span_scope_harness.md (override with
// --dart-define=SPAN_SCOPE_OUTPUT=...). Override run count per case with
// --dart-define=SPAN_SCOPE_RUNS_PER_CASE=... (default 10). Override the
// model with --dart-define=SPAN_SCOPE_MODEL=... (default 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'SPAN_SCOPE_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'SPAN_SCOPE_OUTPUT',
  defaultValue: 'docs/stage2_span_scope_harness.md',
);

/// Model used for the live run. Override with
/// `--dart-define=SPAN_SCOPE_MODEL=...`, same override pattern as
/// `stage2_categorization_harness.dart`'s `stage2Model`.
const String spanScopeModel = String.fromEnvironment(
  'SPAN_SCOPE_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'SPAN_SCOPE_CALL_DELAY_MS',
  defaultValue: 750,
);

/// Restricts the live run to a single case id (e.g. re-running just
/// `mesa-clause` to check a targeted prompt change, without spending calls
/// re-verifying cases that are already stable). Empty (the default) runs
/// every case in [_cases]. Override with
/// `--dart-define=SPAN_SCOPE_CASE_ID=...`.
const String caseIdFilter = String.fromEnvironment('SPAN_SCOPE_CASE_ID', defaultValue: '');

const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};
const Set<String> _validSpanScopes = {'exact', 'full'};

/// One test case: a full text plus a single hand-written flagged phrase
/// (standing in for Stage 1 output), the category/span_scope a human
/// annotator would assign, and a note on why.
///
/// Deliberately one flagged phrase per case, not a list —
/// span_scope only has meaning for a single Natural Language correction's
/// own quoted span, so there is nothing to gain from batching phrases the
/// way `stage2_categorization_harness.dart` does.
class _Case {
  const _Case({
    required this.id,
    required this.text,
    required this.flaggedPhrase,
    required this.expectedCategory,
    required this.expectedSpanScope,
    required this.note,
  });

  final String id;
  final String text;
  final String flaggedPhrase;
  final String expectedCategory;
  final String expectedSpanScope;
  final String note;
}

const List<_Case> _cases = [
  _Case(
    id: 'cerveza-predicate',
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche.',
    flaggedPhrase: 'Puedo tener una cerveza',
    expectedCategory: 'Natural Language',
    expectedSpanScope: 'exact',
    note:
        'Predicate restructure — the prompt\'s own worked exact example. '
        '"una cerveza" is unchanged context that means the same thing '
        'alone; only "Puedo tener" -> "Me da"/"Me pone" actually differs.',
  ),
  _Case(
    id: 'decision-collocation',
    text: 'Hice una decisión importante sobre mi futuro académico.',
    flaggedPhrase: 'Hice una decisión importante',
    expectedCategory: 'Natural Language',
    expectedSpanScope: 'full',
    note:
        'Fixed-phrase collocation ("hacer" vs "tomar" una decisión) — the '
        'prompt\'s own worked full example, now embedded in a longer '
        'sentence than the prompt\'s bare phrase to check the value still '
        'holds once there is real surrounding context to be tempted into '
        'trimming.',
  ),
  _Case(
    id: 'mesa-clause',
    text:
        'La mesa tiene cuatro personas porque no hay más sillas '
        'disponibles.',
    flaggedPhrase: 'La mesa tiene cuatro personas',
    expectedCategory: 'Natural Language',
    expectedSpanScope: 'full',
    note:
        'Core-clause restructure — capacity calque ("the table has four '
        'people" for "the table seats/holds four people"). The natural fix '
        'reassigns grammatical roles across the whole clause (e.g. "tiene" '
        '-> "es para"/"caben"), not a single-word swap inside an otherwise '
        'unchanged frame, so no smaller piece of the quoted phrase stands '
        'on its own.',
  ),
  _Case(
    id: 'redundant-pronoun-fresh',
    text:
        'Mi hermana trabaja en un hospital y ella ayuda mucho a los '
        'pacientes enfermos.',
    flaggedPhrase: 'ella ayuda mucho a los pacientes enfermos',
    expectedCategory: 'Natural Language',
    expectedSpanScope: 'exact',
    note:
        'Fresh construction (not from any existing catalog): a single '
        'redundant-pronoun token ("ella" repeating "mi hermana"), not a '
        'fixed collocation — the token-type case the task asked for, with '
        'a genuinely wide flagged phrase around the one word that\'s '
        'actually wrong, so trimming down to "exact" is non-trivial rather '
        'than already-minimal (unlike the catalog\'s only redundant-'
        'pronoun example, ES-6, which flags the bare pronoun alone).',
  ),
];

/// Lowercases and strips Spanish diacritics so phrase matching survives the
/// model normalizing accents itself. Copied by value from
/// `stage2_categorization_harness.dart`'s `_normalizeForMatch`.
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
/// by value from `stage2_categorization_harness.dart`'s `_normalizedOverlap`.
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Builds the user-message content sent alongside `stage2CategorizationSpanish`.
/// Copied by value from `stage2_categorization_harness.dart`'s
/// `buildStage2UserContent`.
String buildStage2UserContent({
  required String fullText,
  required List<String> flaggedPhrases,
}) {
  return '''
Learner's text:
$fullText

Flagged phrases:
${jsonEncode(flaggedPhrases)}
''';
}

/// One flagged phrase's categorization, as returned by Stage 2 — extended
/// with [spanScope] beyond what `stage2_categorization_harness.dart`'s own
/// `_CategorizationResult` carries, since that's the one field this harness
/// exists to score.
class _CategorizationResult {
  const _CategorizationResult({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.occurrence,
    required this.category,
    required this.verdict,
    required this.spanScope,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final int occurrence;
  final String? category;
  final String verdict;
  final String? spanScope;
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. Copied by value from `stage2_categorization_harness.dart`'s
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
/// response body. Copied by value from `stage2_categorization_harness.dart`'s
/// `extractReplyText`.
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

/// Parses a Stage 2 reply into one [_CategorizationResult] per returned
/// object, including `span_scope`.
///
/// Same defensive extraction as `stage2_categorization_harness.dart`'s
/// `_parseCategorizationArray` (substring between first `[` and last `]`,
/// tolerating Markdown fences/commentary). `span_scope` parsing mirrors the
/// production parser added to `stage2_categorization_client.dart`: an
/// unrecognized non-null value throws (sign of prompt drift), a missing key
/// parses to `null` rather than being required — this harness does not
/// itself enforce the prompt's "only for Natural Language" instruction,
/// since silently under-populating that instruction is exactly the kind of
/// drift this harness is meant to surface, not paper over.
List<_CategorizationResult> _parseCategorizationArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 2 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('Stage 2 reply array did not decode to a List.');
  }

  return decoded.map((element) {
    if (element is! Map<String, Object?>) {
      throw FormatException(
        'Stage 2 reply array contained a non-object element: $element',
      );
    }

    final originalPhrase = element['original_phrase'];
    final correctedPhrase = element['corrected_phrase'];
    final occurrence = element['occurrence'];
    final category = element['category'];
    final verdict = element['verdict'];
    final spanScope = element['span_scope'];

    if (originalPhrase is! String || originalPhrase.isEmpty) {
      throw FormatException(
        'Stage 2 result missing/invalid original_phrase: $element',
      );
    }
    if (correctedPhrase is! String) {
      throw FormatException(
        'Stage 2 result missing/invalid corrected_phrase: $element',
      );
    }
    if (occurrence is! num || occurrence != occurrence.roundToDouble()) {
      throw FormatException(
        'Stage 2 result missing/invalid occurrence: $element',
      );
    }
    if (category != null && category is! String) {
      throw FormatException(
        'Stage 2 result has a non-string category: $element',
      );
    }
    if (verdict is! String || !_validVerdicts.contains(verdict)) {
      throw FormatException('Stage 2 result has an invalid verdict: $element');
    }
    if (spanScope != null &&
        (spanScope is! String || !_validSpanScopes.contains(spanScope))) {
      throw FormatException(
        'Stage 2 result has an invalid span_scope: $element',
      );
    }

    return _CategorizationResult(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      occurrence: occurrence.round(),
      category: category as String?,
      verdict: verdict,
      spanScope: spanScope as String?,
    );
  }).toList();
}

/// Finds the result in [results] whose `originalPhrase` overlaps
/// [flaggedPhrase], or null if Stage 2 didn't return a matching object.
/// Copied by value from `stage2_categorization_harness.dart`'s
/// `_matchResultFor`.
_CategorizationResult? _matchResultFor(
  List<_CategorizationResult> results,
  String flaggedPhrase,
) {
  for (final result in results) {
    if (_normalizedOverlap(flaggedPhrase, result.originalPhrase)) {
      return result;
    }
  }
  return null;
}

/// One run's outcome for one case. A transient API/parse failure is
/// recorded via [error] rather than dropped, same as every other harness's
/// `_RunRecord`.
class _RunRecord {
  const _RunRecord({
    required this.caseId,
    required this.runIndex,
    this.result,
    this.error,
  });

  final String caseId;
  final int runIndex;
  final _CategorizationResult? result;
  final Object? error;

  bool get isError => error != null;
}

_RunRecord _buildRunRecord({
  required String caseId,
  required int runIndex,
  required _CategorizationResult? result,
}) {
  return _RunRecord(caseId: caseId, runIndex: runIndex, result: result);
}

_RunRecord _errorRunRecord({
  required String caseId,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(caseId: caseId, runIndex: runIndex, error: error);
}

/// One distinct `corrected_phrase` seen among a case's category-matching
/// runs (grouped case/diacritic-insensitively via [_normalizeForMatch]),
/// and every span_scope value reported alongside it — see
/// [_CaseAggregate.internallyConsistent].
///
/// [correctedPhrase] is the first raw (non-normalized) form seen for this
/// group, kept for display; grouping itself is by the normalized form, so
/// two runs differing only in case/accents still land in the same group.
class _CorrectedPhraseGroup {
  const _CorrectedPhraseGroup({
    required this.correctedPhrase,
    required this.runCount,
    required this.spanScopeValues,
  });

  final String correctedPhrase;
  final int runCount;

  /// `'(missing)'` stands in for a null span_scope, same convention as
  /// [_CaseAggregate.spanScopeDistribution].
  final Set<String> spanScopeValues;

  /// Whether every run that produced this exact corrected_phrase reported
  /// the same span_scope. A group with more than one distinct value is a
  /// real inconsistency — Stage 2 disagreeing with itself about the same
  /// text — as opposed to two *different* corrected_phrase groups
  /// legitimately disagreeing with each other.
  bool get isConsistent => spanScopeValues.length <= 1;
}

/// Aggregated results for one case across all its non-error runs.
///
/// span_scope consistency is only meaningful conditional on Stage 2 having
/// actually categorized the phrase as Natural Language in the first place
/// (span_scope is only ever expected then) — so [spanScopeMatchCount],
/// [spanScopeMismatchCount], [spanScopeMissingCount], and
/// [correctedPhraseGroups] are all counted over [categoryMatchCount], not
/// [consideredRuns]. A run where Stage 2 didn't even agree on category is a
/// category-consistency problem, a different (and prior) question to the
/// one this harness asks.
class _CaseAggregate {
  const _CaseAggregate({
    required this.totalRuns,
    required this.errorRuns,
    required this.consideredRuns,
    required this.noMatchCount,
    required this.categoryMatchCount,
    required this.categoryDistribution,
    required this.spanScopeMatchCount,
    required this.spanScopeMismatchCount,
    required this.spanScopeMissingCount,
    required this.spanScopeDistribution,
    required this.correctedPhraseGroups,
    required this.internallyConsistent,
  });

  final int totalRuns;
  final int errorRuns;
  final int consideredRuns;

  /// Runs where nothing Stage 2 returned overlapped the flagged phrase at
  /// all.
  final int noMatchCount;

  /// Runs where a matched result's category equals [_Case.expectedCategory]
  /// ("Natural Language" for every case here).
  final int categoryMatchCount;
  final Map<String, int> categoryDistribution;

  /// Among [categoryMatchCount] runs: span_scope equals
  /// [_Case.expectedSpanScope] — the desired outcome for a case with one
  /// right answer. Kept alongside [internallyConsistent] rather than
  /// replaced by it: a case like mesa-clause can be fully
  /// [internallyConsistent] (every distinct correction labeled itself the
  /// same way every time) while still scoring below 100% here, because
  /// more than one corrected_phrase is legitimately in play and only one
  /// of them matches [_Case.expectedSpanScope]. Both numbers are real
  /// signal; neither alone tells the full story.
  final int spanScopeMatchCount;

  /// Among [categoryMatchCount] runs: span_scope was returned but doesn't
  /// equal [_Case.expectedSpanScope].
  final int spanScopeMismatchCount;

  /// Among [categoryMatchCount] runs: span_scope was null even though
  /// category was Natural Language — the prompt's "only omit it for every
  /// other category" instruction not being followed.
  final int spanScopeMissingCount;

  /// Distribution among [categoryMatchCount] runs; `'(missing)'` stands in
  /// for a null span_scope so it's visible in the same table as the real
  /// values rather than silently dropped.
  final Map<String, int> spanScopeDistribution;

  /// Every distinct corrected_phrase seen among [categoryMatchCount] runs,
  /// each with the span_scope value(s) reported alongside it. Sorted by
  /// descending [_CorrectedPhraseGroup.runCount] (most common correction
  /// first), tie-broken alphabetically for a stable report order.
  final List<_CorrectedPhraseGroup> correctedPhraseGroups;

  /// True when every group in [correctedPhraseGroups] is internally
  /// consistent — i.e. Stage 2 never reported two different span_scope
  /// values for the exact same corrected_phrase. Vacuously true when
  /// [correctedPhraseGroups] is empty (nothing to be inconsistent about).
  /// This is deliberately independent of [spanScopeMatchCount]: two groups
  /// can each be internally consistent while disagreeing with each other
  /// and with [_Case.expectedSpanScope] — that's legitimate divergence
  /// (different corrections can validly carry different span_scope
  /// values), not the pure inconsistency this field exists to catch.
  final bool internallyConsistent;
}

_CaseAggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();

  var noMatchCount = 0;
  var categoryMatchCount = 0;
  final categoryDist = <String, int>{};
  var spanScopeMatchCount = 0;
  var spanScopeMismatchCount = 0;
  var spanScopeMissingCount = 0;
  final spanScopeDist = <String, int>{};

  final groupDisplayByNormalized = <String, String>{};
  final groupRunCountByNormalized = <String, int>{};
  final groupScopesByNormalized = <String, Set<String>>{};

  for (final record in okRecords) {
    final result = record.result;
    if (result == null) {
      noMatchCount++;
      continue;
    }

    final categoryKey = result.category ?? '(none)';
    categoryDist[categoryKey] = (categoryDist[categoryKey] ?? 0) + 1;

    if (result.category != testCase.expectedCategory) {
      continue;
    }
    categoryMatchCount++;

    final spanScopeKey = result.spanScope ?? '(missing)';
    spanScopeDist[spanScopeKey] = (spanScopeDist[spanScopeKey] ?? 0) + 1;

    if (result.spanScope == null) {
      spanScopeMissingCount++;
    } else if (result.spanScope == testCase.expectedSpanScope) {
      spanScopeMatchCount++;
    } else {
      spanScopeMismatchCount++;
    }

    final normalizedPhrase = _normalizeForMatch(result.correctedPhrase);
    groupDisplayByNormalized.putIfAbsent(normalizedPhrase, () => result.correctedPhrase);
    groupRunCountByNormalized[normalizedPhrase] =
        (groupRunCountByNormalized[normalizedPhrase] ?? 0) + 1;
    groupScopesByNormalized
        .putIfAbsent(normalizedPhrase, () => <String>{})
        .add(spanScopeKey);
  }

  final correctedPhraseGroups = groupDisplayByNormalized.keys
      .map(
        (normalizedPhrase) => _CorrectedPhraseGroup(
          correctedPhrase: groupDisplayByNormalized[normalizedPhrase]!,
          runCount: groupRunCountByNormalized[normalizedPhrase]!,
          spanScopeValues: groupScopesByNormalized[normalizedPhrase]!,
        ),
      )
      .toList()
    ..sort((a, b) {
      final byCount = b.runCount.compareTo(a.runCount);
      return byCount != 0 ? byCount : a.correctedPhrase.compareTo(b.correctedPhrase);
    });

  return _CaseAggregate(
    totalRuns: records.length,
    errorRuns: records.length - okRecords.length,
    consideredRuns: okRecords.length,
    noMatchCount: noMatchCount,
    categoryMatchCount: categoryMatchCount,
    categoryDistribution: categoryDist,
    spanScopeMatchCount: spanScopeMatchCount,
    spanScopeMismatchCount: spanScopeMismatchCount,
    spanScopeMissingCount: spanScopeMissingCount,
    spanScopeDistribution: spanScopeDist,
    correctedPhraseGroups: correctedPhraseGroups,
    internallyConsistent: correctedPhraseGroups.every((g) => g.isConsistent),
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

/// Describes one [_CorrectedPhraseGroup] as a single report line, flagging
/// it explicitly when it isn't internally consistent — that's the specific
/// failure mode (Stage 2 disagreeing with itself about the exact same
/// text) this section exists to surface, as opposed to two different
/// groups legitimately disagreeing with each other.
String _describeGroup(_CorrectedPhraseGroup group) {
  final scopes = group.spanScopeValues.toList()..sort();
  final scopesText = scopes.map((s) => '"$s"').join(', ');
  final runWord = group.runCount == 1 ? 'run' : 'runs';
  final flag = group.isConsistent ? '' : ' ⚠ INCONSISTENT WITHIN THIS CORRECTION';
  return '- "${group.correctedPhrase}" (${group.runCount} $runWord): span_scope = $scopesText$flag';
}

String _describeRun(_RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${record.error}';
  }
  final result = record.result;
  if (result == null) {
    return '- $prefix: no result overlapping the flagged phrase';
  }
  return '- $prefix: category=${result.category ?? '(none)'}, '
      'span_scope=${result.spanScope ?? '(missing)'}, '
      'original_phrase="${result.originalPhrase}", '
      'corrected_phrase="${result.correctedPhrase}"';
}

/// Builds the full markdown report. Pure — takes already-collected
/// [recordsByCaseId] rather than making any calls itself, golden-testable
/// against synthetic data, same approach as every other harness's
/// `_buildReport`.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Stage 2 `span_scope` Classification-Consistency Harness')
    ..writeln()
    ..writeln(
      'Calls `stage2CategorizationSpanish` in isolation (one hand-written '
      'flagged phrase per case, standing in for Stage 1 output) and reports '
      'whether the new `span_scope` field (`exact`/`full`) is returned '
      'consistently and correctly across repeated runs, before any span-'
      'trimming logic is wired to read it.',
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
      ..writeln('- Flagged phrase: `${testCase.flaggedPhrase}`')
      ..writeln('- Expected category: `${testCase.expectedCategory}`')
      ..writeln('- Expected span_scope: `${testCase.expectedSpanScope}`')
      ..writeln('- Note: ${testCase.note}')
      ..writeln()
      ..writeln(
        '### Summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))',
      )
      ..writeln()
      ..writeln(
        '- No result overlapping the flagged phrase: '
        '${_percentLabel(aggregate.noMatchCount, aggregate.consideredRuns)}',
      )
      ..writeln(
        '- Category matches "${testCase.expectedCategory}": '
        '${_percentLabel(aggregate.categoryMatchCount, aggregate.consideredRuns)}',
      )
      ..writeln('- Category distribution: ${_describeDistribution(aggregate.categoryDistribution)}')
      ..writeln(
        '- span_scope matches "${testCase.expectedSpanScope}" '
        '(among category-matching runs): '
        '${_percentLabel(aggregate.spanScopeMatchCount, aggregate.categoryMatchCount)}',
      )
      ..writeln(
        '- span_scope present but wrong value (among category-matching runs): '
        '${_percentLabel(aggregate.spanScopeMismatchCount, aggregate.categoryMatchCount)}',
      )
      ..writeln(
        '- span_scope missing entirely despite Natural Language category '
        '(among category-matching runs): '
        '${_percentLabel(aggregate.spanScopeMissingCount, aggregate.categoryMatchCount)}',
      )
      ..writeln(
        '- span_scope distribution (among category-matching runs): '
        '${_describeDistribution(aggregate.spanScopeDistribution)}',
      )
      ..writeln()
      ..writeln('### Consistency by corrected_phrase')
      ..writeln();

    if (aggregate.correctedPhraseGroups.isEmpty) {
      report.writeln('(none)');
    } else {
      for (final group in aggregate.correctedPhraseGroups) {
        report.writeln(_describeGroup(group));
      }
    }
    report
      ..writeln()
      ..writeln(
        'Internally consistent across ${aggregate.correctedPhraseGroups.length} '
        'distinct correction${aggregate.correctedPhraseGroups.length == 1 ? '' : 's'}: '
        '${aggregate.internallyConsistent ? 'yes' : 'no'}',
      )
      ..writeln()
      ..writeln('### Run detail')
      ..writeln();

    for (final record in records) {
      report.writeln(_describeRun(record));
    }
    report.writeln();

    summaryRows.add(
      '| ${testCase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
      '${_percentLabel(aggregate.categoryMatchCount, aggregate.consideredRuns)} | '
      '${_percentLabel(aggregate.spanScopeMatchCount, aggregate.categoryMatchCount)} | '
      '${_percentLabel(aggregate.spanScopeMissingCount, aggregate.categoryMatchCount)} | '
      '${_describeDistribution(aggregate.spanScopeDistribution)} | '
      '${aggregate.internallyConsistent ? 'yes' : 'no'} |',
    );
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln(
      '| Case | Runs | Errors | Category match | span_scope match | '
      'span_scope missing | span_scope distribution | Internally consistent |',
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

Future<List<_CategorizationResult>> _callStage2Categorization({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required String fullText,
  required String flaggedPhrase,
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
          systemPrompt: stage2CategorizationSpanish,
          userText: buildStage2UserContent(
            fullText: fullText,
            flaggedPhrases: [flaggedPhrase],
          ),
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

  return _parseCategorizationArray(extractReplyText(decoded));
}

void main() {
  test('span_scope harness case fixtures are well-formed', () {
    expect(_cases.length, 4, reason: 'Exactly the four cases the task specified.');

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(
        testCase.text.contains(testCase.flaggedPhrase),
        isTrue,
        reason: '${testCase.id}: flagged phrase not found verbatim in text.',
      );
      expect(
        testCase.expectedCategory,
        'Natural Language',
        reason: '${testCase.id}: span_scope is only ever expected for Natural Language.',
      );
      expect(
        _validSpanScopes.contains(testCase.expectedSpanScope),
        isTrue,
        reason: '${testCase.id}: expectedSpanScope must be "exact" or "full".',
      );
    }

    final expectedScopeById = {for (final c in _cases) c.id: c.expectedSpanScope};
    expect(expectedScopeById['cerveza-predicate'], 'exact');
    expect(expectedScopeById['decision-collocation'], 'full');
    expect(expectedScopeById['mesa-clause'], 'full');
    expect(expectedScopeById['redundant-pronoun-fresh'], 'exact');
  });

  test('runsPerCase defaults to 10', () {
    expect(runsPerCase, 10);
  });

  test('spanScopeModel defaults to gpt-5.5', () {
    expect(spanScopeModel, 'gpt-5.5');
  });

  group('_normalizedOverlap', () {
    test('matches case/diacritic-insensitively', () {
      expect(_normalizedOverlap('Puedo tener una cerveza', 'PUEDO TENER UNA CERVEZA'), isTrue);
    });

    test('false when neither contains the other', () {
      expect(_normalizedOverlap('una cerveza', 'la mesa'), isFalse);
    });
  });

  group('_parseCategorizationArray', () {
    test('parses span_scope when present', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "Puedo tener una cerveza", '
        '"corrected_phrase": "Me da una cerveza", "occurrence": 1, '
        '"category": "Natural Language", "verdict": "error", '
        '"span_scope": "exact"}]',
      );
      expect(results, hasLength(1));
      expect(results.single.spanScope, 'exact');
    });

    test('parses a missing span_scope key as null', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
        '"occurrence": 1, "category": "Spelling", "verdict": "error"}]',
      );
      expect(results.single.spanScope, isNull);
    });

    test('parses an explicit null span_scope as null', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
        '"occurrence": 1, "category": "Spelling", "verdict": "error", '
        '"span_scope": null}]',
      );
      expect(results.single.spanScope, isNull);
    });

    test('throws on an unrecognized span_scope value', () {
      expect(
        () => _parseCategorizationArray(
          '[{"original_phrase": "x", "corrected_phrase": "y", '
          '"occurrence": 1, "category": "Natural Language", "verdict": '
          '"error", "span_scope": "partial"}]',
        ),
        throwsFormatException,
      );
    });

    test('throws on a non-string span_scope', () {
      expect(
        () => _parseCategorizationArray(
          '[{"original_phrase": "x", "corrected_phrase": "y", '
          '"occurrence": 1, "category": "Natural Language", "verdict": '
          '"error", "span_scope": 1}]',
        ),
        throwsFormatException,
      );
    });

    test('tolerates surrounding Markdown fences', () {
      final results = _parseCategorizationArray(
        '```json\n[{"original_phrase": "x", "corrected_phrase": "y", '
        '"occurrence": 1, "category": "Natural Language", "verdict": '
        '"error", "span_scope": "full"}]\n```',
      );
      expect(results.single.spanScope, 'full');
    });
  });

  group('_matchResultFor', () {
    test('finds the result overlapping the flagged phrase', () {
      const result = _CategorizationResult(
        originalPhrase: 'Puedo tener una cerveza',
        correctedPhrase: 'Me da una cerveza',
        occurrence: 1,
        category: 'Natural Language',
        verdict: 'error',
        spanScope: 'exact',
      );
      expect(_matchResultFor([result], 'Puedo tener una cerveza'), same(result));
    });

    test('returns null when nothing overlaps', () {
      const result = _CategorizationResult(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        occurrence: 1,
        category: 'Spelling',
        verdict: 'error',
        spanScope: null,
      );
      expect(_matchResultFor([result], 'la mesa'), isNull);
    });
  });

  group('_aggregateCase', () {
    const testCase = _Case(
      id: 'cerveza-predicate',
      text: '¿Puedo tener una cerveza?',
      flaggedPhrase: 'Puedo tener una cerveza',
      expectedCategory: 'Natural Language',
      expectedSpanScope: 'exact',
      note: 'test case',
    );

    test('a matching category and matching span_scope both count', () {
      final records = [
        _buildRunRecord(
          caseId: testCase.id,
          runIndex: 1,
          result: const _CategorizationResult(
            originalPhrase: 'Puedo tener una cerveza',
            correctedPhrase: 'Me da una cerveza',
            occurrence: 1,
            category: 'Natural Language',
            verdict: 'error',
            spanScope: 'exact',
          ),
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.categoryMatchCount, 1);
      expect(aggregate.spanScopeMatchCount, 1);
      expect(aggregate.spanScopeMismatchCount, 0);
      expect(aggregate.spanScopeMissingCount, 0);
    });

    test('matching category but wrong span_scope counts as a mismatch', () {
      final records = [
        _buildRunRecord(
          caseId: testCase.id,
          runIndex: 1,
          result: const _CategorizationResult(
            originalPhrase: 'Puedo tener una cerveza',
            correctedPhrase: 'Me da una cerveza',
            occurrence: 1,
            category: 'Natural Language',
            verdict: 'error',
            spanScope: 'full',
          ),
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.categoryMatchCount, 1);
      expect(aggregate.spanScopeMatchCount, 0);
      expect(aggregate.spanScopeMismatchCount, 1);
      expect(aggregate.spanScopeMissingCount, 0);
    });

    test('matching category with a null span_scope counts as missing', () {
      final records = [
        _buildRunRecord(
          caseId: testCase.id,
          runIndex: 1,
          result: const _CategorizationResult(
            originalPhrase: 'Puedo tener una cerveza',
            correctedPhrase: 'Me da una cerveza',
            occurrence: 1,
            category: 'Natural Language',
            verdict: 'error',
            spanScope: null,
          ),
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.categoryMatchCount, 1);
      expect(aggregate.spanScopeMatchCount, 0);
      expect(aggregate.spanScopeMismatchCount, 0);
      expect(aggregate.spanScopeMissingCount, 1);
    });

    test('a mismatched category is not counted toward span_scope at all', () {
      final records = [
        _buildRunRecord(
          caseId: testCase.id,
          runIndex: 1,
          result: const _CategorizationResult(
            originalPhrase: 'Puedo tener una cerveza',
            correctedPhrase: 'Me da una cerveza',
            occurrence: 1,
            category: 'Word Choice',
            verdict: 'error',
            spanScope: null,
          ),
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.categoryMatchCount, 0);
      expect(aggregate.spanScopeMatchCount, 0);
      expect(aggregate.spanScopeMismatchCount, 0);
      expect(aggregate.spanScopeMissingCount, 0);
      expect(aggregate.categoryDistribution, {'Word Choice': 1});
    });

    test('no matching result is tallied as noMatchCount', () {
      final records = [
        _buildRunRecord(caseId: testCase.id, runIndex: 1, result: null),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.noMatchCount, 1);
      expect(aggregate.categoryMatchCount, 0);
    });

    test('error runs are excluded from consideredRuns and every count', () {
      final records = [
        _errorRunRecord(caseId: testCase.id, runIndex: 1, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 1);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.consideredRuns, 0);
      expect(aggregate.categoryMatchCount, 0);
    });
  });

  group('_aggregateCase (internal consistency by corrected_phrase)', () {
    const testCase = _Case(
      id: 'cerveza-predicate',
      text: '¿Puedo tener una cerveza?',
      flaggedPhrase: 'Puedo tener una cerveza',
      expectedCategory: 'Natural Language',
      expectedSpanScope: 'exact',
      note: 'test case',
    );

    test(
      'fully consistent: all runs share one corrected_phrase and one '
      'span_scope, reported as a single consistent group',
      () {
        final records = List.generate(
          3,
          (i) => _buildRunRecord(
            caseId: testCase.id,
            runIndex: i + 1,
            result: const _CategorizationResult(
              originalPhrase: 'Puedo tener una cerveza',
              correctedPhrase: 'Me da una cerveza',
              occurrence: 1,
              category: 'Natural Language',
              verdict: 'error',
              spanScope: 'exact',
            ),
          ),
        );

        final aggregate = _aggregateCase(testCase, records);

        expect(aggregate.correctedPhraseGroups, hasLength(1));
        final group = aggregate.correctedPhraseGroups.single;
        expect(group.correctedPhrase, 'Me da una cerveza');
        expect(group.runCount, 3);
        expect(group.spanScopeValues, {'exact'});
        expect(group.isConsistent, isTrue);
        expect(aggregate.internallyConsistent, isTrue);
      },
    );

    test(
      'mesa-clause-shaped: two distinct corrected_phrase groups, each '
      'internally consistent, disagreeing with each other and with the '
      'static expected value — internally consistent overall even though '
      'the static match rate is below 100%',
      () {
        const mesaCase = _Case(
          id: 'mesa-clause',
          text: 'La mesa tiene cuatro personas porque no hay más sillas disponibles.',
          flaggedPhrase: 'La mesa tiene cuatro personas',
          expectedCategory: 'Natural Language',
          expectedSpanScope: 'full',
          note: 'test case',
        );

        final records = [
          for (var i = 1; i <= 8; i++)
            _buildRunRecord(
              caseId: mesaCase.id,
              runIndex: i,
              result: const _CategorizationResult(
                originalPhrase: 'La mesa tiene cuatro personas',
                correctedPhrase: 'En la mesa hay cuatro personas',
                occurrence: 1,
                category: 'Natural Language',
                verdict: 'error',
                spanScope: 'full',
              ),
            ),
          for (var i = 9; i <= 10; i++)
            _buildRunRecord(
              caseId: mesaCase.id,
              runIndex: i,
              result: const _CategorizationResult(
                originalPhrase: 'La mesa tiene cuatro personas',
                correctedPhrase: 'La mesa es para cuatro personas',
                occurrence: 1,
                category: 'Natural Language',
                verdict: 'error',
                spanScope: 'exact',
              ),
            ),
        ];

        final aggregate = _aggregateCase(mesaCase, records);

        // Static match rate stays below 100% — that signal is still real
        // and still shown; it's just not the same question as internal
        // consistency.
        expect(aggregate.spanScopeMatchCount, 8);
        expect(aggregate.spanScopeMismatchCount, 2);
        expect(
          _percentLabel(aggregate.spanScopeMatchCount, aggregate.categoryMatchCount),
          '80.0% (8/10)',
        );

        expect(aggregate.correctedPhraseGroups, hasLength(2));
        final hayGroup = aggregate.correctedPhraseGroups.firstWhere(
          (g) => g.correctedPhrase == 'En la mesa hay cuatro personas',
        );
        expect(hayGroup.runCount, 8);
        expect(hayGroup.spanScopeValues, {'full'});
        expect(hayGroup.isConsistent, isTrue);

        final esParaGroup = aggregate.correctedPhraseGroups.firstWhere(
          (g) => g.correctedPhrase == 'La mesa es para cuatro personas',
        );
        expect(esParaGroup.runCount, 2);
        expect(esParaGroup.spanScopeValues, {'exact'});
        expect(esParaGroup.isConsistent, isTrue);

        expect(aggregate.internallyConsistent, isTrue);
      },
    );

    test(
      'genuine inconsistency: the same corrected_phrase reported with two '
      'different span_scope values is NOT internally consistent, and the '
      'failing group is identifiable',
      () {
        final records = [
          _buildRunRecord(
            caseId: testCase.id,
            runIndex: 1,
            result: const _CategorizationResult(
              originalPhrase: 'Puedo tener una cerveza',
              correctedPhrase: 'Me da una cerveza',
              occurrence: 1,
              category: 'Natural Language',
              verdict: 'error',
              spanScope: 'exact',
            ),
          ),
          _buildRunRecord(
            caseId: testCase.id,
            runIndex: 2,
            result: const _CategorizationResult(
              originalPhrase: 'Puedo tener una cerveza',
              correctedPhrase: 'Me da una cerveza',
              occurrence: 1,
              category: 'Natural Language',
              verdict: 'error',
              spanScope: 'full',
            ),
          ),
        ];

        final aggregate = _aggregateCase(testCase, records);

        expect(aggregate.correctedPhraseGroups, hasLength(1));
        final group = aggregate.correctedPhraseGroups.single;
        expect(group.correctedPhrase, 'Me da una cerveza');
        expect(group.runCount, 2);
        expect(group.spanScopeValues, {'exact', 'full'});
        expect(group.isConsistent, isFalse);
        expect(aggregate.internallyConsistent, isFalse);
      },
    );

    test(
      'error runs and non-matching-category runs are excluded from group '
      'consistency exactly as they already are from the existing '
      'dimensions',
      () {
        final records = [
          _errorRunRecord(caseId: testCase.id, runIndex: 1, error: StateError('boom')),
          _buildRunRecord(
            caseId: testCase.id,
            runIndex: 2,
            result: const _CategorizationResult(
              originalPhrase: 'Puedo tener una cerveza',
              correctedPhrase: 'Me da una cerveza',
              occurrence: 1,
              category: 'Word Choice',
              verdict: 'error',
              spanScope: null,
            ),
          ),
          _buildRunRecord(caseId: testCase.id, runIndex: 3, result: null),
        ];

        final aggregate = _aggregateCase(testCase, records);

        expect(aggregate.categoryMatchCount, 0);
        expect(aggregate.correctedPhraseGroups, isEmpty);
        expect(
          aggregate.internallyConsistent,
          isTrue,
          reason: 'vacuously true — no category-matching runs, nothing to be inconsistent about',
        );
      },
    );
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, per-case summary + run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 1,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: const [
          _Case(
            id: 'cerveza-predicate',
            text: '¿Puedo tener una cerveza?',
            flaggedPhrase: 'Puedo tener una cerveza',
            expectedCategory: 'Natural Language',
            expectedSpanScope: 'exact',
            note: 'Predicate restructure.',
          ),
        ],
        recordsByCaseId: {
          'cerveza-predicate': [
            _buildRunRecord(
              caseId: 'cerveza-predicate',
              runIndex: 1,
              result: const _CategorizationResult(
                originalPhrase: 'Puedo tener una cerveza',
                correctedPhrase: 'Me da una cerveza',
                occurrence: 1,
                category: 'Natural Language',
                verdict: 'error',
                spanScope: 'exact',
              ),
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'span_scope classification-consistency harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the span_scope harness. This script '
          'does NOT fall back to any hardcoded/default key — no AppConfig '
          'involved, by design (see the file header).',
        );
      }

      final casesToRun = caseIdFilter.isEmpty
          ? _cases
          : _cases.where((c) => c.id == caseIdFilter).toList();
      if (casesToRun.isEmpty) {
        fail('SPAN_SCOPE_CASE_ID="$caseIdFilter" matched no case in _cases.');
      }

      final httpClient = HttpClient();
      final recordsByCaseId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in casesToRun) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (var run = 1; run <= runsPerCase; run++) {
            _RunRecord record;
            try {
              final results = await _callStage2Categorization(
                httpClient: httpClient,
                apiKey: apiKey,
                model: spanScopeModel,
                fullText: testCase.text,
                flaggedPhrase: testCase.flaggedPhrase,
              );
              record = _buildRunRecord(
                caseId: testCase.id,
                runIndex: run,
                result: _matchResultFor(results, testCase.flaggedPhrase),
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
        model: spanScopeModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: casesToRun,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath (model: $spanScopeModel)');
    },
    timeout: const Timeout(Duration(minutes: 20)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Stage 2 `span_scope` Classification-Consistency Harness\n\nCalls `stage2CategorizationSpanish` in isolation (one hand-written flagged phrase per case, standing in for Stage 1 output) and reports whether the new `span_scope` field (`exact`/`full`) is returned consistently and correctly across repeated runs, before any span-trimming logic is wired to read it.\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 1\n\n## cerveza-predicate\n\n- Text: `¿Puedo tener una cerveza?`\n- Flagged phrase: `Puedo tener una cerveza`\n- Expected category: `Natural Language`\n- Expected span_scope: `exact`\n- Note: Predicate restructure.\n\n### Summary (1 runs, 0 error(s))\n\n- No result overlapping the flagged phrase: 0.0% (0/1)\n- Category matches \"Natural Language\": 100.0% (1/1)\n- Category distribution: \"Natural Language\": 1\n- span_scope matches \"exact\" (among category-matching runs): 100.0% (1/1)\n- span_scope present but wrong value (among category-matching runs): 0.0% (0/1)\n- span_scope missing entirely despite Natural Language category (among category-matching runs): 0.0% (0/1)\n- span_scope distribution (among category-matching runs): \"exact\": 1\n\n### Consistency by corrected_phrase\n\n- \"Me da una cerveza\" (1 run): span_scope = \"exact\"\n\nInternally consistent across 1 distinct correction: yes\n\n### Run detail\n\n- Run 1: category=Natural Language, span_scope=exact, original_phrase=\"Puedo tener una cerveza\", corrected_phrase=\"Me da una cerveza\"\n\n---\n\n## Overall summary\n\n| Case | Runs | Errors | Category match | span_scope match | span_scope missing | span_scope distribution | Internally consistent |\n| --- | --- | --- | --- | --- | --- | --- | --- |\n| cerveza-predicate | 1 | 0 | 100.0% (1/1) | 100.0% (1/1) | 0.0% (0/1) | \"exact\": 1 | yes |\n"';
