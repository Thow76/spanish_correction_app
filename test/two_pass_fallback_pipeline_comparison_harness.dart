// Full-pipeline fallback prompt comparison harness (issue #117).
//
// Purpose: answer the actual product question issue #110's isolated,
// forced-call comparison could not: "when the full two-pass pipeline
// naturally triggers fallback, does a fallback-specific prompt improve
// the final output?" Issue #110 called the naturalness endpoint directly
// against known first-pass output, bypassing conflict detection entirely
// — useful exploratory evidence, but not proof about real pipeline
// behavior. This harness runs the REAL sequence: pass 1
// (`callFirstPassCorrection`) and pass 2 (`callNaturalnessReview`,
// parallel) exactly as production calls them, the real
// `mergeNaturalnessReview` conflict detection, and — only when that
// merge genuinely has a skipped edit — a fallback naturalness call,
// compared side by side under two system prompts.
//
// Pass 1 and the parallel naturalness call are run ONCE per fixture and
// shared between both variants: which fallback prompt is under test can
// never affect either of those calls, so sharing them is both cheaper and
// more scientifically valid (both variants see an identical fallback
// trigger decision and an identical `firstPassCorrectedText` to fall back
// against). Only the fallback call itself — run once per variant, and
// only when the real conflict logic actually triggers it — differs.
//
// Self-contained: does not import anything from the (unmerged) issue #110
// branch. `candidateFallbackPrompt` is redefined here by value, same text.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_fallback_pipeline_comparison_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls — default mode is the
// 27-fixture comparison set, one run each: first pass +
// naturalness-on-original always (54 calls), plus up to 2 fallback calls
// per fixture only when a conflict is genuinely triggered — expect on the
// order of 80-108 total calls, well under a full benchmark run):
//   OPENAI_API_KEY=sk-... \
//   FALLBACK_PIPELINE_COMPARISON_LIVE=true \
//   flutter test test/two_pass_fallback_pipeline_comparison_harness.dart --tags live --timeout none
//
// Run the all-fixtures, repeated-run mode (issue #122) — every fixture in
// allTwoPassFixtures (85 as of this writing), 5 runs each, to make live
// model variance visible rather than trusting a single-run result. This
// is expensive: up to 85 * 5 * 4 = 1700 calls in the worst case (every
// run triggering fallback). Use FALLBACK_PIPELINE_RUNS_PER_FIXTURE=1 with
// FALLBACK_PIPELINE_FIXTURE_SET=all first if you just want broader
// coverage without the repeat-run cost:
//   OPENAI_API_KEY=sk-... \
//   FALLBACK_PIPELINE_COMPARISON_LIVE=true \
//   FALLBACK_PIPELINE_FIXTURE_SET=all \
//   FALLBACK_PIPELINE_RUNS_PER_FIXTURE=5 \
//   flutter test test/two_pass_fallback_pipeline_comparison_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - FALLBACK_PIPELINE_FIRST_PASS_MODEL: defaults to gpt-4.1.
// - FALLBACK_PIPELINE_NATURALNESS_MODEL: defaults to gpt-5.1.
// - FALLBACK_PIPELINE_OUTPUT: report path, defaults to
//   docs/two_pass_fallback_pipeline_comparison.md.
// - FALLBACK_PIPELINE_CALL_DELAY_MS: delay between fixture runs, defaults
//   to 750.
// - FALLBACK_PIPELINE_FIXTURE_SET (issue #122): "comparison" (default —
//   the curated 27-fixture set below) or "all" (every fixture in
//   allTwoPassFixtures).
// - FALLBACK_PIPELINE_RUNS_PER_FIXTURE (issue #122): how many times to
//   run each selected fixture with the exact same submitted text, so a
//   repeated live failure can be told apart from a one-off stochastic
//   result — same convention as TWO_PASS_RUNS_PER_FIXTURE (issue #107).
//   Defaults to 1.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

import 'two_pass_integration_harness.dart'
    show
        CallStats,
        FixtureResult,
        TwoPassFixture,
        TwoPassScoreLabel,
        TwoPassScoreLabelReportName,
        allTwoPassFixtures,
        isPassingScore,
        scoreFixtureResult;

/// The candidate fallback-specific prompt evaluated in issue #110,
/// redefined here by value (this file does not depend on the unmerged
/// #110 branch). Keeps every restraint `naturalnessReviewSpanish` (v4,
/// issue #108) already has, plus explicit "this text was already
/// corrected; only flag a clear remaining issue; do not restructure or
/// add content" framing.
const String candidateFallbackPrompt =
    'You are a Spanish tutor doing a final naturalness check on text that '
    'has already been corrected for grammar, spelling, and punctuation, '
    'and already reviewed once for naturalness.\n'
    '\n'
    'Only flag wording that is still clearly unnatural — a calque, idiom, '
    'or collocation a native Spanish speaker would not use. Do not flag '
    'anything you are not confident about.\n'
    '\n'
    'Do not restructure the sentence. Do not add new information, new '
    'clauses, or new ideas that were not in the original text. Do not '
    'change the meaning.\n'
    '\n'
    'Do not report spelling, punctuation, or grammatical errors.\n'
    'If the only problem is grammar, spelling, or punctuation, return no '
    'issue.\n'
    '\n'
    'Do not normalise wording that is natural in an established variety of '
    'Spanish. A form is not a naturalness issue merely because another '
    'form is more widespread, more neutral, or preferred by the '
    'reviewer\'s own regional variety.\n'
    '\n'
    'Ignore spelling, punctuation, or grammar errors even if they appear '
    'in the same sentence as a naturalness issue.\n'
    '\n'
    'Give exactly one natural replacement for each issue — never more '
    'than one option, and never join alternatives with a slash, "or", or '
    'a list. If more than one wording would work, choose the single best '
    'one yourself.\n'
    '\n'
    'Return JSON only.';

/// The curated test set (issue #117's own "Test Set" section) — ids drawn
/// from the real language-point benchmark (`allTwoPassFixtures`,
/// issue #82). Issue #117 asked to use the previous live benchmark
/// (`docs/two_pass_live_language_point_benchmark_issue_log.md`) as the
/// base, including every phrase where fallback triggered, changed text,
/// or caused a fail there.
///
/// This list includes every row in that log marked `Fallback pass:
/// Changed` — both the `Fail` rows (the ones that motivated this
/// evaluation in the first place) and the `Pass` rows (changed-but-
/// correct cases, included so the comparison isn't skewed toward only
/// failure cases) — plus a handful of `Unchanged` baseline rows
/// (`correct-buenos-dias`, `regional-voy-para-casa`) kept from the
/// original curated set to cover already-correct do-not-touch and
/// valid-regional behavior, which the "Changed" filter alone wouldn't
/// surface. Notable individual entries:
/// - `grammar-overlaps-naturalness`: documented in its own fixture note
///   as "the case the fallback exists for" (a first-pass fix landing
///   inside a naturalness calque span) — the single most load-bearing
///   fixture for this evaluation's question, previously omitted.
/// - `ambiguous-naturalness-span`, `article-la-tienda`: the repeated-
///   span rewrite and article-duplication fails.
/// - `false-friend-aplico-trabajo`, `false-friend-embarazado`: false-
///   friend fails beyond `atendio-universidad`.
/// - `naturalness-pasar-buen-tiempo`, `naturalness-puedo-tener-cerveza`:
///   the slash-alternative naturalness fails.
/// - `mixed-preposition-and-redundant-pronoun`,
///   `mixed-gender-agreement-and-redundant-pronoun`: mixed-operation
///   cases beyond the personal-a/subjunctive and verb-agreement/que ones.
/// - `delete-repeated-yo-estudio`, `delete-repeated-ellos-visitaron`,
///   `delete-repeated-yo-compre`, `delete-repeated-nosotros`: the
///   redundant-repeated-pronoun deletion cases (both Pass and Fail).
/// - `collocation-hacer-paseo`, `collocation-hace-sentido`,
///   `prep-empresa-en-la-que`, `naturalness-llamar-para-atras`: the
///   remaining changed-but-correct naturalness/preposition cases.
///
/// Reusing real fixtures (not hand-typed inputs) means expected outputs
/// and language-point grouping stay identical to every other benchmark
/// report.
const List<String> fallbackPipelineComparisonFixtureIds = [
  'clean-grammar-only',
  'correct-tomar-foto',
  'correct-buenos-dias',
  'regional-voy-para-casa',
  'naturalness-buen-tiempo',
  'naturalness-corriendo-tarde',
  'mixed-personal-a-and-subjunctive',
  'mixed-verb-agreement-and-missing-que',
  'false-friend-atendio-universidad',
  'subj-enviara',
  'ambiguous-naturalness-span',
  'article-la-tienda',
  'false-friend-aplico-trabajo',
  'false-friend-embarazado',
  'naturalness-pasar-buen-tiempo',
  'naturalness-puedo-tener-cerveza',
  'mixed-preposition-and-redundant-pronoun',
  'grammar-overlaps-naturalness',
  'collocation-hacer-paseo',
  'collocation-hace-sentido',
  'prep-empresa-en-la-que',
  'delete-repeated-yo-estudio',
  'delete-repeated-ellos-visitaron',
  'delete-repeated-yo-compre',
  'delete-repeated-nosotros',
  'naturalness-llamar-para-atras',
  'mixed-gender-agreement-and-redundant-pronoun',
];

List<TwoPassFixture> get fallbackPipelineComparisonFixtures =>
    fallbackPipelineComparisonFixtureIds
        .map(
          (id) => allTwoPassFixtures.firstWhere(
            (f) => f.id == id,
            orElse: () => throw StateError(
              'No fixture with id "$id" in allTwoPassFixtures.',
            ),
          ),
        )
        .toList();

const String _defaultFirstPassModel = 'gpt-4.1';
const String _defaultNaturalnessModel = 'gpt-5.1';
const String defaultFallbackPipelineOutputPath =
    'docs/two_pass_fallback_pipeline_comparison.md';

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'FALLBACK_PIPELINE_COMPARISON_LIVE',
  defaultValue: false,
);

bool _liveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      (environment['FALLBACK_PIPELINE_COMPARISON_LIVE']
              ?.trim()
              .toLowerCase() ==
          'true');
}

String _runtimeString({
  required Map<String, String> environment,
  required String key,
  required String defaultValue,
}) {
  final fromEnvironment = environment[key]?.trim() ?? '';
  return fromEnvironment.isNotEmpty ? fromEnvironment : defaultValue;
}

int callDelayMsFrom(Map<String, String> environment) {
  final raw = _runtimeString(
    environment: environment,
    key: 'FALLBACK_PIPELINE_CALL_DELAY_MS',
    defaultValue: '750',
  );
  return int.tryParse(raw) ?? 750;
}

/// Default `FALLBACK_PIPELINE_FIXTURE_SET` value (issue #122) — the
/// existing curated 27-fixture comparison set, unchanged from before this
/// existed.
const String defaultFallbackPipelineFixtureSet = 'comparison';

/// Which fixtures `fixtureSet` selects (issue #122): `"comparison"` (the
/// curated set issue #117 built, [fallbackPipelineComparisonFixtures]) or
/// `"all"` (every fixture in [allTwoPassFixtures], for broader coverage
/// than the curated set alone can offer). Throws [ArgumentError] for
/// anything else, same "fail fast rather than silently run the wrong
/// thing" precedent as [fallbackPipelineRunsPerFixtureFrom] and
/// `two_pass_integration_harness.dart`'s own `selectFixtures`.
List<TwoPassFixture> fallbackPipelineFixturesFor(String fixtureSet) {
  switch (fixtureSet) {
    case 'comparison':
      return fallbackPipelineComparisonFixtures;
    case 'all':
      return allTwoPassFixtures;
    default:
      throw ArgumentError(
        'Unknown FALLBACK_PIPELINE_FIXTURE_SET "$fixtureSet" — expected '
        '"comparison" or "all".',
      );
  }
}

/// Reads `FALLBACK_PIPELINE_FIXTURE_SET` from a real environment (issue
/// #122), same real-environment-variable convention as [callDelayMsFrom].
List<TwoPassFixture> fallbackPipelineFixturesFrom(
  Map<String, String> environment,
) {
  return fallbackPipelineFixturesFor(
    _runtimeString(
      environment: environment,
      key: 'FALLBACK_PIPELINE_FIXTURE_SET',
      defaultValue: defaultFallbackPipelineFixtureSet,
    ),
  );
}

/// Default number of times to run each selected fixture (issue #122) —
/// unchanged single-run behavior from before this existed.
const int defaultFallbackPipelineRunsPerFixture = 1;

/// Reads `FALLBACK_PIPELINE_RUNS_PER_FIXTURE` from a real environment
/// (issue #122) — how many times to run each selected fixture with the
/// exact same submitted text, so a repeated live failure (or a repeated
/// candidate win) can be told apart from a one-off stochastic result.
/// Same convention as `two_pass_integration_harness.dart`'s
/// `TWO_PASS_RUNS_PER_FIXTURE` (issue #107), including throwing
/// [ArgumentError] for a zero or negative value rather than silently
/// running every selected fixture zero times.
int fallbackPipelineRunsPerFixtureFrom(Map<String, String> environment) {
  final raw =
      environment['FALLBACK_PIPELINE_RUNS_PER_FIXTURE']?.trim() ?? '';
  final runsPerFixture =
      int.tryParse(raw) ?? defaultFallbackPipelineRunsPerFixture;
  if (runsPerFixture < 1) {
    throw ArgumentError(
      'FALLBACK_PIPELINE_RUNS_PER_FIXTURE must be >= 1 (was '
      '$runsPerFixture) — 0 or negative would silently run every '
      'selected fixture zero times.',
    );
  }
  return runsPerFixture;
}

/// One prompt variant's outcome for one fixture, within the real pipeline.
class FallbackVariantOutcome {
  const FallbackVariantOutcome({
    required this.fallbackTriggered,
    required this.fallbackReviewDescription,
    required this.finalCorrectedText,
    required this.score,
    required this.reason,
  });

  final bool fallbackTriggered;

  /// Description of what the fallback call itself flagged, or `null` when
  /// fallback was never triggered (real conflict logic said no).
  final String? fallbackReviewDescription;
  final String finalCorrectedText;
  final TwoPassScoreLabel score;
  final String reason;
}

/// Both variants' results for one fixture, sharing the real pass 1 /
/// parallel-naturalness-pass 2 results and the real conflict decision.
class FallbackPipelineComparisonResult {
  const FallbackPipelineComparisonResult({
    required this.fixture,
    required this.firstPassCorrectedText,
    required this.naturalnessOnOriginalDescription,
    required this.hadConflict,
    required this.current,
    required this.candidate,
    this.runIndex = 1,
  });

  final TwoPassFixture fixture;
  final String firstPassCorrectedText;
  final String naturalnessOnOriginalDescription;

  /// Whether the real `mergeNaturalnessReview` conflict logic triggered
  /// fallback at all — identical for both variants, since the trigger
  /// condition depends only on the parallel merge, never on which
  /// fallback prompt exists.
  final bool hadConflict;

  final FallbackVariantOutcome current;
  final FallbackVariantOutcome candidate;

  /// 1-based index of this run among a fixture's repeated runs (issue
  /// #122) — same convention as `two_pass_integration_harness.dart`'s
  /// `FixtureResult.runIndex` (issue #107). Defaults to 1, unchanged
  /// single-run behavior from before repeated runs existed.
  final int runIndex;
}

String _describeReview(NaturalnessReview review) {
  if (!review.hasNaturalnessIssue) {
    return '(none)';
  }
  return review.issues
      .map((issue) => '${issue.span} -> ${issue.naturalReplacement}')
      .join('<br>');
}

TwoPassScoreLabel _score(TwoPassFixture fixture, String finalCorrectedText) {
  const emptyReview = NaturalnessReview(hasNaturalnessIssue: false, issues: []);
  final result = FixtureResult(
    fixture: fixture,
    firstPassCorrectedText: finalCorrectedText,
    firstPassStats: CallStats.zero,
    naturalnessOnOriginal: emptyReview,
    naturalnessOnOriginalStats: CallStats.zero,
    naturalnessOnFirstPass: emptyReview,
    naturalnessOnFirstPassStats: CallStats.zero,
    parallelPhaseWallClockMs: 0,
    hadConflict: false,
    usedFallback: false,
    finalCorrectedText: finalCorrectedText,
    finalCorrectionCount: 0,
  );
  return scoreFixtureResult(result);
}

String _reasonFor({
  required TwoPassFixture fixture,
  required String finalCorrectedText,
  required String firstPassCorrectedText,
  required bool fallbackTriggered,
}) {
  final score = _score(fixture, finalCorrectedText);
  if (isPassingScore(score)) {
    if (finalCorrectedText == firstPassCorrectedText) {
      return 'Matches expected output; already-correct first-pass text was '
          'left unchanged.';
    }
    return fallbackTriggered
        ? 'Matches expected output after the fallback edit was applied.'
        : 'Matches expected output after the parallel naturalness edit '
              'was applied.';
  }
  if (!fallbackTriggered) {
    return 'Fallback was never triggered (no conflict), but the parallel '
        'merge alone still did not produce the expected output.';
  }
  if (finalCorrectedText == firstPassCorrectedText) {
    return 'Fallback flagged something, but the merge could not safely '
        'apply it (or the model reported no issue) — already-correct '
        'first-pass text was preserved regardless.';
  }
  return 'Fallback changed the first-pass text to something that does '
      'not match the expected output.';
}

/// Runs the real pipeline sequence once (pass 1 + parallel naturalness +
/// merge + conflict check), then — only if the real conflict logic
/// triggers it — runs the fallback call once per prompt variant, against
/// the exact same `firstPassCorrectedText`, so the system prompt is the
/// only variable between the two variants' fallback calls.
Future<FallbackPipelineComparisonResult> runFallbackPipelineComparison({
  required OpenAiChatCompletionsClient client,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
  int runIndex = 1,
}) async {
  final firstPassFuture = callFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: fixture.text,
  );
  final parallelNaturalnessFuture = callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: fixture.text,
  );
  final firstPassResponse = await firstPassFuture;
  final parallelNaturalnessReview = await parallelNaturalnessFuture;

  final parallelMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: parallelNaturalnessReview,
  );
  final hadConflict = parallelMerge.skippedEdits.isNotEmpty;

  Future<FallbackVariantOutcome> runVariant(String fallbackSystemPrompt) async {
    if (!hadConflict) {
      final response = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: parallelMerge,
      );
      return FallbackVariantOutcome(
        fallbackTriggered: false,
        fallbackReviewDescription: null,
        finalCorrectedText: response.correctedText,
        score: _score(fixture, response.correctedText),
        reason: _reasonFor(
          fixture: fixture,
          finalCorrectedText: response.correctedText,
          firstPassCorrectedText: firstPassResponse.correctedText,
          fallbackTriggered: false,
        ),
      );
    }

    final replyText = await client.complete(
      model: naturalnessModel,
      systemPrompt: fallbackSystemPrompt,
      userText: buildNaturalnessUserContent(firstPassResponse.correctedText),
      stageLabel: 'fallback_pipeline_comparison',
      responseFormat: naturalnessReviewResponseFormat,
    );
    final fallbackReview = parseNaturalnessReviewResponse(replyText);
    final fallbackMerge = mergeNaturalnessReview(
      originalText: fixture.text,
      firstPassCorrectedText: firstPassResponse.correctedText,
      naturalnessReview: fallbackReview,
    );
    final response = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: fallbackMerge,
    );
    return FallbackVariantOutcome(
      fallbackTriggered: true,
      fallbackReviewDescription: _describeReview(fallbackReview),
      finalCorrectedText: response.correctedText,
      score: _score(fixture, response.correctedText),
      reason: _reasonFor(
        fixture: fixture,
        finalCorrectedText: response.correctedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        fallbackTriggered: true,
      ),
    );
  }

  final currentOutcome = await runVariant(naturalnessReviewSpanish);
  final candidateOutcome = await runVariant(candidateFallbackPrompt);

  return FallbackPipelineComparisonResult(
    fixture: fixture,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessOnOriginalDescription: _describeReview(
      parallelNaturalnessReview,
    ),
    hadConflict: hadConflict,
    current: currentOutcome,
    candidate: candidateOutcome,
    runIndex: runIndex,
  );
}

/// Builds the comparison report, grouped by language point (issue #117's
/// own "grouped by case type" requirement) so mixed/coherence cases don't
/// distort clean do-not-touch cases in the reader's impression.
/// Distinct `selector(run)` values across [runs], in first-seen order —
/// used to show how much a variant's output actually varies across
/// repeated runs of the same fixture (issue #122).
List<String> _distinctOutputs(
  List<FallbackPipelineComparisonResult> runs,
  String Function(FallbackPipelineComparisonResult) selector,
) {
  final seen = <String>[];
  for (final run in runs) {
    final text = selector(run);
    if (!seen.contains(text)) {
      seen.add(text);
    }
  }
  return seen;
}

String _formatOutputList(List<String> outputs) {
  return outputs.map((text) => '`$text`').join('; ');
}

/// Which prompt "won" one run, by pass/fail score comparison (issue
/// #122) — a candidate win is a run the candidate prompt passed and the
/// current prompt did not; a current win (a regression for the
/// candidate) is the reverse; anything else (both pass, both fail, or
/// fallback never triggered so both variants are identical by
/// construction) is a tie.
enum _RunOutcome { candidateWin, currentWin, tie }

_RunOutcome _classifyRun(FallbackPipelineComparisonResult result) {
  final currentPass = isPassingScore(result.current.score);
  final candidatePass = isPassingScore(result.candidate.score);
  if (candidatePass && !currentPass) {
    return _RunOutcome.candidateWin;
  }
  if (currentPass && !candidatePass) {
    return _RunOutcome.currentWin;
  }
  return _RunOutcome.tie;
}

/// Builds the comparison report, grouped by language point (issue #117's
/// own "grouped by case type" requirement) then by fixture, with each
/// fixture's repeated runs (issue #122) rolled up into a summary plus one
/// subsection per run, so mixed/coherence cases don't distort clean
/// do-not-touch cases and repeated-run variance isn't collapsed into a
/// single misleading result.
String buildFallbackPipelineComparisonReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<FallbackPipelineComparisonResult> results,
  required DateTime generatedAt,
}) {
  final byFixtureId = <String, List<FallbackPipelineComparisonResult>>{};
  final fixtureOrder = <String>[];
  for (final result in results) {
    final key = result.fixture.id;
    if (!byFixtureId.containsKey(key)) {
      fixtureOrder.add(key);
    }
    (byFixtureId[key] ??= []).add(result);
  }
  for (final runs in byFixtureId.values) {
    runs.sort((a, b) => a.runIndex.compareTo(b.runIndex));
  }
  final distinctFixtureCount = fixtureOrder.length;

  final buffer = StringBuffer()
    ..writeln(
      '# Two-Pass Fallback Prompt Comparison: Full Pipeline (issues '
      '#117, #122)',
    )
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixtures: `$distinctFixtureCount`')
    ..writeln('- Total runs: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(
      'Pass 1 and the parallel naturalness call are run once per fixture '
      'run and shared between both variants below — only the fallback '
      'call itself (run once per variant, only when the real conflict '
      'logic in `mergeNaturalnessReview` actually triggers it) differs.',
    )
    ..writeln();

  buffer
    ..writeln('## Per-fixture summary')
    ..writeln()
    ..writeln(
      'Pass counts are `passed/runs`; "distinct outputs" lists every '
      'unique final output a variant produced across this fixture\'s '
      'runs — more than one entry means the model was not stable for '
      'that fixture.',
    )
    ..writeln()
    ..writeln(
      '| Fixture | Runs | Fallback triggered | Current pass | Candidate '
      'pass | Distinct current outputs | Distinct candidate outputs |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  for (final fixtureId in fixtureOrder) {
    final runs = byFixtureId[fixtureId]!;
    final triggeredCount = runs.where((r) => r.hadConflict).length;
    final currentPassCount = runs
        .where((r) => isPassingScore(r.current.score))
        .length;
    final candidatePassCount = runs
        .where((r) => isPassingScore(r.candidate.score))
        .length;
    final distinctCurrent = _distinctOutputs(
      runs,
      (r) => r.current.finalCorrectedText,
    );
    final distinctCandidate = _distinctOutputs(
      runs,
      (r) => r.candidate.finalCorrectedText,
    );
    buffer.writeln(
      '| $fixtureId | ${runs.length} | $triggeredCount/${runs.length} | '
      '$currentPassCount/${runs.length} | '
      '$candidatePassCount/${runs.length} | '
      '${_formatOutputList(distinctCurrent)} | '
      '${_formatOutputList(distinctCandidate)} |',
    );
  }
  buffer.writeln();

  final byLanguagePoint = <String, List<String>>{};
  final languagePointOrder = <String>[];
  for (final fixtureId in fixtureOrder) {
    final key = byFixtureId[fixtureId]!.first.fixture.languagePoint;
    if (!byLanguagePoint.containsKey(key)) {
      languagePointOrder.add(key);
    }
    (byLanguagePoint[key] ??= []).add(fixtureId);
  }

  for (final languagePoint in languagePointOrder) {
    buffer
      ..writeln('## $languagePoint')
      ..writeln();
    for (final fixtureId in byLanguagePoint[languagePoint]!) {
      final runs = byFixtureId[fixtureId]!;
      final fixture = runs.first.fixture;
      final triggeredCount = runs.where((r) => r.hadConflict).length;
      final currentPassCount = runs
          .where((r) => isPassingScore(r.current.score))
          .length;
      final candidatePassCount = runs
          .where((r) => isPassingScore(r.candidate.score))
          .length;

      buffer
        ..writeln('### $fixtureId')
        ..writeln()
        ..writeln('- Original text: `${fixture.text}`')
        ..writeln(
          '- Expected corrected text: `${fixture.expectedCorrectedText}`',
        )
        ..writeln('- Runs: ${runs.length}')
        ..writeln(
          '- Fallback triggered: $triggeredCount/${runs.length}',
        )
        ..writeln('- Current pass: $currentPassCount/${runs.length}')
        ..writeln('- Candidate pass: $candidatePassCount/${runs.length}')
        ..writeln(
          '- Distinct current outputs: '
          '${_formatOutputList(_distinctOutputs(runs, (r) => r.current.finalCorrectedText))}',
        )
        ..writeln(
          '- Distinct candidate outputs: '
          '${_formatOutputList(_distinctOutputs(runs, (r) => r.candidate.finalCorrectedText))}',
        )
        ..writeln();

      void writeVariantTable(FallbackPipelineComparisonResult result) {
        buffer
          ..writeln(
            '| Variant | Fallback output | Final output | Score | '
            'Reason |',
          )
          ..writeln('| --- | --- | --- | --- | --- |')
          ..writeln(
            '| Current (reused prompt) | '
            '${result.current.fallbackReviewDescription ?? '(fallback not triggered)'} | '
            '`${result.current.finalCorrectedText}` | '
            '${result.current.score.reportLabel} | ${result.current.reason} |',
          )
          ..writeln(
            '| Candidate (fallback-specific) | '
            '${result.candidate.fallbackReviewDescription ?? '(fallback not triggered)'} | '
            '`${result.candidate.finalCorrectedText}` | '
            '${result.candidate.score.reportLabel} | '
            '${result.candidate.reason} |',
          )
          ..writeln();
      }

      if (runs.length == 1) {
        final result = runs.single;
        buffer
          ..writeln(
            '- Pass 1 (first-pass corrected text): '
            '`${result.firstPassCorrectedText}`',
          )
          ..writeln(
            '- Pass 2 (naturalness on original): '
            '${result.naturalnessOnOriginalDescription}',
          )
          ..writeln();
        writeVariantTable(result);
      } else {
        for (final result in runs) {
          buffer
            ..writeln('#### Run ${result.runIndex} of ${runs.length}')
            ..writeln()
            ..writeln(
              '- Pass 1 (first-pass corrected text): '
              '`${result.firstPassCorrectedText}`',
            )
            ..writeln(
              '- Pass 2 (naturalness on original): '
              '${result.naturalnessOnOriginalDescription}',
            )
            ..writeln('- Fallback triggered: ${result.hadConflict}')
            ..writeln();
          writeVariantTable(result);
        }
      }
    }
  }

  final triggeredResults = results.where((r) => r.hadConflict).toList();
  final untriggeredResults = results.where((r) => !r.hadConflict).toList();
  final currentPassCount = results
      .where((r) => isPassingScore(r.current.score))
      .length;
  final candidatePassCount = results
      .where((r) => isPassingScore(r.candidate.score))
      .length;
  final currentTriggeredPassCount = triggeredResults
      .where((r) => isPassingScore(r.current.score))
      .length;
  final candidateTriggeredPassCount = triggeredResults
      .where((r) => isPassingScore(r.candidate.score))
      .length;
  final currentUntriggeredPassCount = untriggeredResults
      .where((r) => isPassingScore(r.current.score))
      .length;
  final candidateUntriggeredPassCount = untriggeredResults
      .where((r) => isPassingScore(r.candidate.score))
      .length;

  final triggeredOutcomes = triggeredResults.map(_classifyRun).toList();
  final candidateWins = triggeredOutcomes
      .where((o) => o == _RunOutcome.candidateWin)
      .length;
  final currentWins = triggeredOutcomes
      .where((o) => o == _RunOutcome.currentWin)
      .length;
  final ties = triggeredOutcomes
      .where((o) => o == _RunOutcome.tie)
      .length;

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln(
      'Both variants score identically on every run where fallback was '
      'never triggered, since neither variant\'s fallback call runs in '
      'that case — the "all runs" rate below is diluted by those shared '
      'results and is not the number that speaks to the fallback prompt '
      'itself. The "fallback-triggered runs only" rate, and the win/tie/'
      'regression breakdown below it, are what actually compare the two '
      'prompts.',
    )
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Fixtures | $distinctFixtureCount |')
    ..writeln('| Total runs | ${results.length} |')
    ..writeln('| Runs where fallback triggered | '
        '${triggeredResults.length} |')
    ..writeln('| Runs where fallback did not trigger | '
        '${untriggeredResults.length} |')
    ..writeln(
      '| Current pass rate, fallback-triggered runs only | '
      '$currentTriggeredPassCount/${triggeredResults.length} |',
    )
    ..writeln(
      '| Candidate pass rate, fallback-triggered runs only | '
      '$candidateTriggeredPassCount/${triggeredResults.length} |',
    )
    ..writeln(
      '| Current pass rate, non-triggered runs only | '
      '$currentUntriggeredPassCount/${untriggeredResults.length} |',
    )
    ..writeln(
      '| Candidate pass rate, non-triggered runs only | '
      '$candidateUntriggeredPassCount/${untriggeredResults.length} |',
    )
    ..writeln(
      '| Current pass rate, all runs (diluted, see note above) | '
      '$currentPassCount/${results.length} |',
    )
    ..writeln(
      '| Candidate pass rate, all runs (diluted, see note above) | '
      '$candidatePassCount/${results.length} |',
    )
    ..writeln(
      '| Candidate wins (fallback-triggered runs only) | $candidateWins |',
    )
    ..writeln(
      '| Current wins / candidate regressions (fallback-triggered runs '
      'only) | $currentWins |',
    )
    ..writeln('| Ties (fallback-triggered runs only) | $ties |');

  return buffer.toString();
}

void main() {
  group('offline sanity (no API calls)', () {
    test('fallbackPipelineComparisonFixtureIds all resolve to real fixtures', () {
      expect(
        fallbackPipelineComparisonFixtures.map((f) => f.id).toList(),
        fallbackPipelineComparisonFixtureIds,
      );
    });

    test('fixture ids are unique', () {
      final ids = fallbackPipelineComparisonFixtureIds.toSet();
      expect(ids.length, fallbackPipelineComparisonFixtureIds.length);
    });

    test(
      'candidateFallbackPrompt keeps every naturalness-scope restraint '
      'and adds fallback-specific framing',
      () {
        expect(
          candidateFallbackPrompt,
          contains('has already been corrected for grammar'),
        );
        expect(
          candidateFallbackPrompt,
          contains('Do not restructure the sentence'),
        );
        expect(
          candidateFallbackPrompt,
          contains('Give exactly one natural replacement'),
        );
      },
    );

    test('callDelayMsFrom reads a real environment variable', () {
      expect(
        callDelayMsFrom(const {'FALLBACK_PIPELINE_CALL_DELAY_MS': '2000'}),
        2000,
      );
      expect(callDelayMsFrom(const {}), 750);
    });

    group('fixture-set selection (issue #122)', () {
      test('"comparison" returns the curated 27-fixture comparison set', () {
        expect(
          fallbackPipelineFixturesFor('comparison'),
          fallbackPipelineComparisonFixtures,
        );
      });

      test('"all" returns every fixture in allTwoPassFixtures', () {
        expect(fallbackPipelineFixturesFor('all'), allTwoPassFixtures);
      });

      test('an unrecognized fixture set throws', () {
        expect(
          () => fallbackPipelineFixturesFor('bogus'),
          throwsArgumentError,
        );
      });

      test(
        'fallbackPipelineFixturesFrom reads FALLBACK_PIPELINE_FIXTURE_SET '
        'from a real environment, defaulting to "comparison" when unset',
        () {
          expect(
            fallbackPipelineFixturesFrom(const {}),
            fallbackPipelineComparisonFixtures,
          );
          expect(
            fallbackPipelineFixturesFrom(const {
              'FALLBACK_PIPELINE_FIXTURE_SET': 'all',
            }),
            allTwoPassFixtures,
          );
        },
      );
    });

    group('repeat-count parsing (issue #122)', () {
      test(
        'fallbackPipelineRunsPerFixtureFrom defaults to 1 and reads a '
        'real environment variable',
        () {
          expect(fallbackPipelineRunsPerFixtureFrom(const {}), 1);
          expect(
            fallbackPipelineRunsPerFixtureFrom(const {
              'FALLBACK_PIPELINE_RUNS_PER_FIXTURE': '5',
            }),
            5,
          );
        },
      );

      test(
        'fallbackPipelineRunsPerFixtureFrom throws for a zero or negative '
        'value instead of silently running every fixture zero times',
        () {
          expect(
            () => fallbackPipelineRunsPerFixtureFrom(const {
              'FALLBACK_PIPELINE_RUNS_PER_FIXTURE': '0',
            }),
            throwsArgumentError,
          );
          expect(
            () => fallbackPipelineRunsPerFixtureFrom(const {
              'FALLBACK_PIPELINE_RUNS_PER_FIXTURE': '-3',
            }),
            throwsArgumentError,
          );
        },
      );
    });

    test(
      'buildFallbackPipelineComparisonReport groups fixtures by language '
      'point and renders both variants',
      () {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        final result = FallbackPipelineComparisonResult(
          fixture: fixture,
          firstPassCorrectedText: fixture.expectedCorrectedText,
          naturalnessOnOriginalDescription: '(none)',
          hadConflict: false,
          current: FallbackVariantOutcome(
            fallbackTriggered: false,
            fallbackReviewDescription: null,
            finalCorrectedText: fixture.expectedCorrectedText,
            score: TwoPassScoreLabel.correctFix,
            reason: 'Matches expected output.',
          ),
          candidate: FallbackVariantOutcome(
            fallbackTriggered: false,
            fallbackReviewDescription: null,
            finalCorrectedText: fixture.expectedCorrectedText,
            score: TwoPassScoreLabel.correctFix,
            reason: 'Matches expected output.',
          ),
        );

        final report = buildFallbackPipelineComparisonReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [result],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(report, contains('## ${fixture.languagePoint}'));
        expect(report, contains('### clean-grammar-only'));
        expect(report, contains('Current (reused prompt)'));
        expect(report, contains('Candidate (fallback-specific)'));
        expect(report, contains('| Current pass rate'));
      },
    );

    test(
      'buildFallbackPipelineComparisonReport (issue #122) renders per-run '
      'subsections, a per-fixture pass-count/distinct-output summary, '
      'and a candidate-win/current-win/tie breakdown across repeated runs',
      () {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );

        FallbackVariantOutcome outcome(String text, TwoPassScoreLabel score) {
          return FallbackVariantOutcome(
            fallbackTriggered: true,
            fallbackReviewDescription: 'span -> $text',
            finalCorrectedText: text,
            score: score,
            reason: 'Synthetic test outcome.',
          );
        }

        final results = [
          // Run 1: candidate wins (candidate passes, current fails).
          FallbackPipelineComparisonResult(
            fixture: fixture,
            firstPassCorrectedText: fixture.expectedCorrectedText,
            naturalnessOnOriginalDescription: '(none)',
            hadConflict: true,
            current: outcome('Había mucho tráfico ayer.', TwoPassScoreLabel.ambiguous),
            candidate: outcome(
              fixture.expectedCorrectedText,
              TwoPassScoreLabel.correctFix,
            ),
            runIndex: 1,
          ),
          // Run 2: tie (both fail, different outputs).
          FallbackPipelineComparisonResult(
            fixture: fixture,
            firstPassCorrectedText: fixture.expectedCorrectedText,
            naturalnessOnOriginalDescription: '(none)',
            hadConflict: true,
            current: outcome('Había mucho tráfico ayer.', TwoPassScoreLabel.ambiguous),
            candidate: outcome('Hubo mucho tráfico ayer.', TwoPassScoreLabel.ambiguous),
            runIndex: 2,
          ),
          // Run 3: current wins / candidate regresses.
          FallbackPipelineComparisonResult(
            fixture: fixture,
            firstPassCorrectedText: fixture.expectedCorrectedText,
            naturalnessOnOriginalDescription: '(none)',
            hadConflict: true,
            current: outcome(
              fixture.expectedCorrectedText,
              TwoPassScoreLabel.correctFix,
            ),
            candidate: outcome('Hubo mucho tráfico ayer.', TwoPassScoreLabel.ambiguous),
            runIndex: 3,
          ),
        ];

        final report = buildFallbackPipelineComparisonReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: results,
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        // Per-fixture summary table: 3 runs, all triggered, 1/3 pass each,
        // 2 distinct outputs for each variant (fixture.expectedCorrectedText
        // appears twice for current, but only 2 unique texts total).
        expect(
          report,
          contains(
            '| clean-grammar-only | 3 | 3/3 | 1/3 | 1/3 | '
            '`Había mucho tráfico ayer.`; `${fixture.expectedCorrectedText}` | '
            '`${fixture.expectedCorrectedText}`; `Hubo mucho tráfico ayer.` |',
          ),
        );

        // Per-run subsections, not collapsed into one result.
        expect(report, contains('#### Run 1 of 3'));
        expect(report, contains('#### Run 2 of 3'));
        expect(report, contains('#### Run 3 of 3'));

        // Win/tie/regression breakdown.
        expect(
          report,
          contains('| Candidate wins (fallback-triggered runs only) | 1 |'),
        );
        expect(
          report,
          contains(
            '| Current wins / candidate regressions (fallback-triggered '
            'runs only) | 1 |',
          ),
        );
        expect(
          report,
          contains('| Ties (fallback-triggered runs only) | 1 |'),
        );
      },
    );

    test(
      'runFallbackPipelineComparison never calls the fallback endpoint '
      'for either variant when the real conflict logic finds no conflict',
      () async {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'correct-buenos-dias',
        );
        final client = _RoutingHttpClient(
          firstPassReply: _firstPassEnvelope(fixture.text),
          originalText: fixture.text,
          firstPassCorrectedText: fixture.text,
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": false, "issues": []}',
          ),
        );

        final result = await runFallbackPipelineComparison(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          fixture: fixture,
        );

        expect(result.hadConflict, isFalse);
        expect(result.current.fallbackTriggered, isFalse);
        expect(result.candidate.fallbackTriggered, isFalse);
        expect(result.current.finalCorrectedText, fixture.text);
        expect(result.candidate.finalCorrectedText, fixture.text);
        expect(client.fallbackCallCount, 0);
      },
    );

    test(
      'runFallbackPipelineComparison calls the fallback endpoint once per '
      'variant, with each variant\'s own system prompt, when the real '
      'conflict logic triggers fallback',
      () async {
        const fixtureText = 'Vi mucho trafico ayer.';
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        expect(fixture.text, fixtureText);

        final client = _RoutingHttpClient(
          firstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          originalText: fixtureText,
          firstPassCorrectedText: 'Vi mucho tráfico ayer.',
          // Flags the whole sentence against the ORIGINAL text -- this
          // won't match the first pass's own corrected text exactly
          // (accent added), so the parallel merge conflicts and fallback
          // triggers, for both variants.
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "Vi mucho trafico ayer.", '
            '"natural_replacement": "Había mucho tráfico ayer.", '
            '"explanation": "Sounds more natural."}'
            ']}',
          ),
          fallbackReplyByVariant: {
            naturalnessReviewSpanish: _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
              '{"span": "Vi mucho tráfico ayer.", '
              '"natural_replacement": "Había mucho tráfico ayer.", '
              '"explanation": "Sounds more natural."}'
              ']}',
            ),
            candidateFallbackPrompt: _naturalnessEnvelope(
              '{"has_naturalness_issue": false, "issues": []}',
            ),
          },
        );

        final result = await runFallbackPipelineComparison(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          fixture: fixture,
        );

        expect(result.hadConflict, isTrue);
        expect(result.current.fallbackTriggered, isTrue);
        expect(result.candidate.fallbackTriggered, isTrue);
        expect(client.fallbackCallCount, 2);
        // Current variant's fallback still over-rewrites. (issue #111
        // originally added a span-breadth guard meant to catch exactly
        // this, but review found it also blocked a genuinely correct
        // full-sentence naturalness fix elsewhere — see
        // naturalness_merge_test.dart's "span-breadth guard removed"
        // group — so it was removed rather than tuned, and this case
        // remains an open over-rewrite issue, not a merge-layer bug.)
        expect(result.current.finalCorrectedText, 'Había mucho tráfico ayer.');
        // Candidate variant's fallback correctly finds no remaining issue.
        expect(
          result.candidate.finalCorrectedText,
          'Vi mucho tráfico ayer.',
        );
      },
    );
  });

  test(
    'two-pass fallback prompt comparison: full pipeline',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!_liveRunOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live fallback pipeline comparison. Set '
          'FALLBACK_PIPELINE_COMPARISON_LIVE=true to opt in.',
        );
        return;
      }

      final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the fallback pipeline comparison '
          'harness. This script does NOT fall back to any hardcoded/'
          'default key.',
        );
      }

      final firstPassModel = _runtimeString(
        environment: environment,
        key: 'FALLBACK_PIPELINE_FIRST_PASS_MODEL',
        defaultValue: _defaultFirstPassModel,
      );
      final naturalnessModel = _runtimeString(
        environment: environment,
        key: 'FALLBACK_PIPELINE_NATURALNESS_MODEL',
        defaultValue: _defaultNaturalnessModel,
      );
      final outputPath = _runtimeString(
        environment: environment,
        key: 'FALLBACK_PIPELINE_OUTPUT',
        defaultValue: defaultFallbackPipelineOutputPath,
      );
      final callDelayMs = callDelayMsFrom(environment);
      final fixtures = fallbackPipelineFixturesFrom(environment);
      final runsPerFixture = fallbackPipelineRunsPerFixtureFrom(environment);
      final httpClient = HttpClient();
      final client = OpenAiChatCompletionsClient(
        apiKey: apiKey,
        httpClient: httpClient,
      );

      final results = <FallbackPipelineComparisonResult>[];
      for (final fixture in fixtures) {
        for (var runIndex = 1; runIndex <= runsPerFixture; runIndex++) {
          final result = await runFallbackPipelineComparison(
            client: client,
            firstPassModel: firstPassModel,
            naturalnessModel: naturalnessModel,
            fixture: fixture,
            runIndex: runIndex,
          );
          results.add(result);
          // ignore: avoid_print
          print(
            '=== ${fixture.id} (run $runIndex/$runsPerFixture) === '
            'conflict=${result.hadConflict} '
            'current="${result.current.finalCorrectedText}" '
            '(${result.current.score.reportLabel}) '
            'candidate="${result.candidate.finalCorrectedText}" '
            '(${result.candidate.score.reportLabel})',
          );
          await Future<void>.delayed(Duration(milliseconds: callDelayMs));
        }
      }

      final report = buildFallbackPipelineComparisonReport(
        firstPassModel: firstPassModel,
        naturalnessModel: naturalnessModel,
        results: results,
        generatedAt: DateTime.now(),
      );

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote fallback pipeline comparison report to $outputPath');
    },
  );
}

String _firstPassEnvelope(String correctedText) => jsonEncode({
  'choices': [
    {
      'message': {
        'role': 'assistant',
        'content': jsonEncode({'corrected_text': correctedText}),
      },
    },
  ],
});

String _naturalnessEnvelope(String replyContent) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': replyContent},
    },
  ],
});

/// Fake HTTP client routing by request shape: the first-pass prompt
/// always gets [firstPassReply]; the naturalness prompt against the
/// ORIGINAL fixture text gets [naturalnessOnOriginalReply]; a fallback
/// call (naturalness prompt against the first pass's own corrected text)
/// is routed by which system prompt it used, via [fallbackReplyByVariant]
/// — this is what lets the fake distinguish the current-reused-prompt
/// fallback call from the candidate-fallback-specific-prompt call, since
/// production code has no other way to tell them apart at the transport
/// level.
/// Fake HTTP client routing by request shape. The first-pass prompt
/// always gets [firstPassReply]. For the naturalness prompt, this
/// distinguishes the parallel call from a fallback call by *user text*,
/// not system prompt — since the current-reused fallback variant uses
/// the exact same system prompt (`naturalnessReviewSpanish`) as the
/// parallel call, and only its user text (reviewing the first pass's own
/// corrected text, not the original) differs: the parallel call's user
/// text always matches [originalText]; anything else is a fallback call,
/// routed by which system prompt it used via [fallbackReplyByVariant].
/// All routing state lives on this client instance (constructed fresh
/// per test), not on any per-request object or static field, so nothing
/// leaks between tests or between the multiple requests one test makes.
class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient({
    required this.firstPassReply,
    required this.originalText,
    required this.firstPassCorrectedText,
    required this.naturalnessOnOriginalReply,
    this.fallbackReplyByVariant = const {},
  });

  final String firstPassReply;
  final String originalText;
  final String firstPassCorrectedText;
  final String naturalnessOnOriginalReply;
  final Map<String, String> fallbackReplyByVariant;
  int fallbackCallCount = 0;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _RoutingRequest(client: this);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _RoutingRequest implements HttpClientRequest {
  _RoutingRequest({required this.client});

  final _RoutingHttpClient client;
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
    final userText = (messages[1] as Map)['content'] as String;

    if (systemPrompt == firstPassCorrectionSpanish) {
      return _FakeHttpClientResponse(replyBody: client.firstPassReply);
    }

    final isParallelCall =
        userText == buildNaturalnessUserContent(client.originalText);
    if (isParallelCall) {
      return _FakeHttpClientResponse(
        replyBody: client.naturalnessOnOriginalReply,
      );
    }

    // Anything else reviewing the first pass's own corrected text is a
    // fallback call — routed by which system prompt it used.
    final fallbackReply = client.fallbackReplyByVariant[systemPrompt];
    if (fallbackReply != null) {
      client.fallbackCallCount++;
      return _FakeHttpClientResponse(replyBody: fallbackReply);
    }

    throw StateError(
      'No fake reply registered for system prompt "$systemPrompt" / user '
      'text "$userText".',
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({required String replyBody}) : _body = replyBody;

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
