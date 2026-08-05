// Serial/linear two-pass pipeline comparison harness (issue #125).
//
// Purpose: prototype and evaluate a LINEAR (serial) two-pass execution
// order — the first pass completes fully, then naturalness reviews the
// first pass's OWN corrected text directly, sequentially — against
// production's PARALLEL execution
// (`runTwoPassCorrectionPipeline`,
// lib/features/corrections/data/two_pass_correction_pipeline.dart),
// which starts the first pass and naturalness-on-original concurrently
// and only reruns naturalness sequentially (the "fallback") when the
// parallel merge finds a conflict.
//
// The linear pipeline never needs a fallback at all: naturalness always
// reviews the exact text it is about to be merged into, so the merge's
// span can only fail to match because of a genuine model discrepancy
// (the model misquoting its own input), never because the text changed
// out from under it mid-flight the way the parallel path's
// naturalness-on-original call can. This harness measures whether that
// architectural simplicity also produces better (or worse, or slower)
// final output quality than production's parallel+conditional-fallback
// design — a question about pipeline ARCHITECTURE (serial vs parallel
// execution order), not about fallback PROMPT text, which is what
// `test/two_pass_fallback_pipeline_comparison_harness.dart` (issues
// #117/#122/#124) already investigates. The two questions are
// orthogonal, so this is deliberately a separate, self-contained
// harness rather than a mode added to that one — matching this issue's
// own "keep it separate" requirement. Both harnesses happen to draw
// fixtures from the same canonical source (`allTwoPassFixtures`,
// `test/two_pass_integration_harness.dart`, issue #82) but choose their
// own curated subset independently; this file does not import from or
// modify `two_pass_fallback_pipeline_comparison_harness.dart`.
//
// Does NOT call production's `runTwoPassCorrectionPipeline` directly
// for the "parallel" side of the comparison — instead it reimplements
// that exact call sequence inline, using the same underlying
// `callFirstPassCorrection`/`callNaturalnessReview`/
// `mergeNaturalnessReview`/`mapNaturalnessEditsIntoCorrectionResponse`
// production already composes it from. No production code is called or
// modified; this file only touches `lib/` via ordinary imports of the
// same pure functions the production pipeline itself imports.
//
// Issue #126: the linear (serial) side's first pass now uses
// [linearFirstPassPrompt] — a REVISED first-pass prompt sourced from a
// design review, not production's `firstPassCorrectionSpanish` — while
// the parallel (production-equivalent) side continues using production's
// current, unmodified prompt. See [linearFirstPassPrompt]'s own doc
// comment for the exact source and why the two sides no longer share a
// first-pass call: once the linear side started using a different
// prompt, sharing one first-pass call would silently make both sides
// measure the same prompt, which defeats the point of a "revised
// prompt + serial architecture" vs. "current prompt + parallel
// architecture" comparison — exactly the comparison the design review
// that produced this prompt asked for. This also means the parallel
// path's conditional fallback can no longer reuse the linear path's
// naturalness call (they now review two different first-pass outputs),
// so a genuine fallback call happens again when the parallel merge has
// a conflict, same as production.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls — default 17-fixture
// curated set: 2 first-pass calls (one per architecture, since they use
// different prompts) + 2 naturalness calls always, plus a conditional
// 3rd naturalness call only when the parallel merge genuinely conflicts
// — expect on the order of 70-90 total calls for the default set):
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LINEAR_COMPARISON_LIVE=true \
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - TWO_PASS_LINEAR_FIRST_PASS_MODEL: defaults to gpt-4.1 (issue #126's
//   own "use this prompt with gpt-4.1 unless the harness configuration
//   overrides it").
// - TWO_PASS_LINEAR_NATURALNESS_MODEL: defaults to gpt-5.1.
// - TWO_PASS_LINEAR_OUTPUT: report path, defaults to
//   docs/two_pass_linear_prompt_comparison.md.
// - TWO_PASS_LINEAR_CALL_DELAY_MS: delay between fixtures, defaults to
//   750.
// - TWO_PASS_LINEAR_FIXTURE_SET: "comparison" (default — the curated
//   17-fixture set below) or "all" (every fixture in
//   allTwoPassFixtures).

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
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

/// The revised first-pass prompt (issue #126), used as the linear
/// (serial) pipeline's grammar/spelling/punctuation pass in this harness
/// only — it does not replace or modify production's
/// `firstPassCorrectionSpanish`
/// (`lib/core/services/prompts/correction_prompt.dart`), which the
/// parallel (production-equivalent) side of this harness continues to
/// use unchanged.
///
/// **Source**: `Two-Pass_Prompt_Revision_Summary.docx`, section "Revised
/// First Pass Prompt" — a design-review document external to this repo
/// (not version-controlled here). Transcribed verbatim, including line
/// breaks, by unzipping the `.docx` and reading `word/document.xml`
/// directly (`<w:t>` runs and `<w:br/>` breaks), since no diffable
/// plain-text export of the source document exists to diff against.
/// Confirmed the source uses plain straight quotes/apostrophes
/// throughout (not Word's smart-quote autocorrect), so nothing here was
/// normalized or altered from what the document contains. Not
/// paraphrased or reworded in any way — issue #126's own "do not
/// silently rewrite the correction rules" requirement.
///
/// The design review's own stated goal for this revision: replace
/// subjective concepts ("naturalness", "word choice") with an objective
/// standard — "recognised as correct by authoritative Spanish language
/// references" — as the boundary between what the first pass may correct
/// (objective grammar/spelling/punctuation errors) and what it must
/// leave alone (word choice, style, fluency, general naturalness, valid
/// regional Spanish — all covered by the prompt's own "do not rewrite
/// wording solely because another expression would be more common, more
/// idiomatic, more fluent, or stylistically preferable" and "do not
/// treat awkward but grammatically valid Spanish as an error" lines).
///
/// The same document also contains a "Revised Second Pass Prompt
/// (Draft)" — deliberately out of scope for issue #126, which asks only
/// for the first-pass prompt. The linear pipeline's naturalness
/// (second-pass) step still uses production's unchanged
/// `naturalnessReviewSpanish`.
const String linearFirstPassPrompt =
    'You are a Spanish language tutor reviewing a student\'s writing.\n'
    '\n'
    'Your task is to correct only objective Spanish grammar, spelling, '
    'and punctuation errors.\n'
    '\n'
    'Do not rewrite wording solely because another expression would be '
    'more common, more idiomatic, more fluent, or stylistically '
    'preferable.\n'
    'Do not replace wording that is recognised as correct by '
    'authoritative Spanish language references with another accepted '
    'alternative.\n'
    'Do not treat awkward but grammatically valid Spanish as an error.\n'
    '\n'
    'Correct every objective grammar, spelling, and punctuation error '
    'that you find.\n'
    '\n'
    'When a sentence contains more than one objective grammar error, '
    'correct every instance, not only the first one. For example:\n'
    '\n'
    '"Tengo cita con médico mañana."\n'
    '\n'
    'is missing both "una" before "cita" and "el" before "médico", so '
    'correct it to:\n'
    '\n'
    '"Tengo una cita con el médico mañana."\n'
    '\n'
    'Return JSON only. Do not include Markdown or commentary.';

/// Calls [linearFirstPassPrompt] against [submittedText] and parses the
/// reply, mirroring `callFirstPassCorrection`'s exact call shape
/// (`first_pass_correction_client.dart`) — same `stageLabel`, same
/// [firstPassCorrectionResponseFormat] JSON schema (reused unchanged:
/// issue #126's own "add [the JSON wrapper] mechanically without
/// changing the prompt's intended contract" — the revised prompt's
/// contract is still exactly `{"corrected_text": "string"}`, so the
/// existing schema is reused rather than redefined), and the same
/// [buildFirstPassCorrectionUserContent]/[parseFirstPassCorrectionResponse]
/// helpers — with only the system prompt text swapped for
/// [linearFirstPassPrompt]. Cannot call `callFirstPassCorrection`
/// directly, since that function hardcodes production's
/// `firstPassCorrectionSpanish` as its system prompt with no override
/// parameter.
Future<CorrectionResponse> _callLinearFirstPassCorrection({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String submittedText,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: linearFirstPassPrompt,
    userText: buildFirstPassCorrectionUserContent(submittedText),
    stageLabel: 'linear_first_pass_correction',
    responseFormat: firstPassCorrectionResponseFormat,
  );
  final correctedText = parseFirstPassCorrectionResponse(replyText);

  return CorrectionResponse(
    originalText: submittedText,
    correctedText: correctedText,
    corrections: const [],
  );
}

/// Curated subset of `allTwoPassFixtures` (issue #82) this harness
/// exercises by default — a representative sample across language
/// points. Chosen independently of (and incidentally overlapping with,
/// since both draw ids from the same canonical fixture list) the
/// fallback comparison harness's own curated set (issue #117) — this
/// harness does not import that set.
const List<String> linearComparisonFixtureIds = [
  'clean-grammar-only',
  'correct-buenos-dias',
  'regional-voy-para-casa',
  'naturalness-buen-tiempo',
  'naturalness-corriendo-tarde',
  'mixed-personal-a-and-subjunctive',
  'mixed-verb-agreement-and-missing-que',
  'false-friend-atendio-universidad',
  'false-friend-aplico-trabajo',
  'subj-enviara',
  'ambiguous-naturalness-span',
  'article-la-tienda',
  'grammar-overlaps-naturalness',
  'collocation-hacer-paseo',
  'collocation-hace-sentido',
  'prep-empresa-en-la-que',
  'delete-repeated-yo-estudio',
];

List<TwoPassFixture> get linearComparisonFixtures => linearComparisonFixtureIds
    .map(
      (id) => allTwoPassFixtures.firstWhere(
        (f) => f.id == id,
        orElse: () =>
            throw StateError('No fixture with id "$id" in allTwoPassFixtures.'),
      ),
    )
    .toList();

/// Default `TWO_PASS_LINEAR_FIXTURE_SET` value — the curated 17-fixture
/// set above, unchanged from before this option existed.
const String defaultLinearFixtureSet = 'comparison';

/// Which fixtures `fixtureSet` selects: `"comparison"` (the curated set
/// above) or `"all"` (every fixture in [allTwoPassFixtures]). Throws
/// [ArgumentError] for anything else — same "fail fast rather than
/// silently run the wrong thing" precedent used throughout this
/// project's other harnesses.
List<TwoPassFixture> linearFixturesFor(String fixtureSet) {
  switch (fixtureSet) {
    case 'comparison':
      return linearComparisonFixtures;
    case 'all':
      return allTwoPassFixtures;
    default:
      throw ArgumentError(
        'Unknown TWO_PASS_LINEAR_FIXTURE_SET "$fixtureSet" — expected '
        '"comparison" or "all".',
      );
  }
}

/// Reads `TWO_PASS_LINEAR_FIXTURE_SET` from a real environment, same
/// real-environment-variable convention as [linearCallDelayMsFrom].
List<TwoPassFixture> linearFixturesFrom(Map<String, String> environment) {
  return linearFixturesFor(
    _runtimeString(
      environment: environment,
      key: 'TWO_PASS_LINEAR_FIXTURE_SET',
      defaultValue: defaultLinearFixtureSet,
    ),
  );
}

const String _defaultFirstPassModel = 'gpt-4.1';
const String _defaultNaturalnessModel = 'gpt-5.1';
const String defaultLinearOutputPath =
    'docs/two_pass_linear_prompt_comparison.md';

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'TWO_PASS_LINEAR_COMPARISON_LIVE',
  defaultValue: false,
);

bool _liveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      (environment['TWO_PASS_LINEAR_COMPARISON_LIVE']?.trim().toLowerCase() ==
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

int linearCallDelayMsFrom(Map<String, String> environment) {
  final raw = _runtimeString(
    environment: environment,
    key: 'TWO_PASS_LINEAR_CALL_DELAY_MS',
    defaultValue: '750',
  );
  return int.tryParse(raw) ?? 750;
}

/// Runs the two-pass pipeline SERIALLY (issue #125): the first pass
/// (using [linearFirstPassPrompt], issue #126 — not production's
/// `firstPassCorrectionSpanish`) completes fully, then naturalness
/// reviews the first pass's own corrected text directly — never the
/// original text, never concurrently with the first pass, and never
/// with a conditional fallback rerun, because naturalness only ever sees
/// the exact text it is about to be merged into. Contrast with
/// production's `runTwoPassCorrectionPipeline`
/// (`lib/features/corrections/data/two_pass_correction_pipeline.dart`),
/// which starts the first pass and naturalness-on-original concurrently
/// and only reruns naturalness sequentially when the parallel merge
/// finds a conflict.
///
/// A pure prototype for this harness's own comparison — not called by
/// or wired into production code anywhere.
Future<CorrectionResponse> runLinearTwoPassPipeline({
  required OpenAiChatCompletionsClient client,
  required String firstPassModel,
  required String naturalnessModel,
  required String submittedText,
}) async {
  final firstPassResponse = await _callLinearFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: submittedText,
  );

  final naturalnessReview = await callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: firstPassResponse.correctedText,
  );

  final merge = mergeNaturalnessReview(
    originalText: submittedText,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: naturalnessReview,
  );

  return mapNaturalnessEditsIntoCorrectionResponse(
    firstPassResponse: firstPassResponse,
    naturalnessMerge: merge,
  );
}

/// One fixture's side-by-side result: the linear (serial) pipeline
/// (using [linearFirstPassPrompt], issue #126) vs. the parallel
/// (production-equivalent) pipeline (using production's unmodified
/// `firstPassCorrectionSpanish`). The two architectures use different
/// first-pass prompts, so — unlike issue #125's original design — they
/// no longer share a first-pass call; see [linearFirstPassCorrectedText]
/// and [parallelFirstPassCorrectedText].
class LinearPipelineComparisonResult {
  const LinearPipelineComparisonResult({
    required this.fixture,
    required this.linearFirstPassCorrectedText,
    required this.linearNaturalnessDescription,
    required this.linearCorrectedText,
    required this.linearScore,
    required this.linearReason,
    required this.parallelFirstPassCorrectedText,
    required this.parallelNaturalnessOnOriginalDescription,
    required this.parallelUsedFallback,
    required this.parallelCorrectedText,
    required this.parallelScore,
    required this.parallelReason,
  });

  final TwoPassFixture fixture;

  /// First-pass output from [linearFirstPassPrompt] (issue #126) — NOT
  /// the same call or necessarily the same text as
  /// [parallelFirstPassCorrectedText], since the two architectures now
  /// use different first-pass prompts and can no longer share one
  /// first-pass call (see this file's own header comment).
  final String linearFirstPassCorrectedText;
  final String linearNaturalnessDescription;
  final String linearCorrectedText;
  final TwoPassScoreLabel linearScore;
  final String linearReason;

  /// First-pass output from production's unchanged
  /// `firstPassCorrectionSpanish`.
  final String parallelFirstPassCorrectedText;
  final String parallelNaturalnessOnOriginalDescription;

  /// Whether the parallel path's merge on naturalness-on-original had a
  /// skipped edit, i.e. whether production's real pipeline would trigger
  /// its sequential fallback here. Since issue #126, this fallback's own
  /// naturalness call IS genuinely re-issued when triggered — it can no
  /// longer reuse the linear path's naturalness call, which reviews a
  /// different (revised-prompt) first-pass output.
  final bool parallelUsedFallback;
  final String parallelCorrectedText;
  final TwoPassScoreLabel parallelScore;
  final String parallelReason;
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

String _reasonFor(TwoPassFixture fixture, String finalCorrectedText) {
  final score = _score(fixture, finalCorrectedText);
  if (isPassingScore(score)) {
    return finalCorrectedText == fixture.text
        ? 'Matches expected output; already-correct text was left '
              'unchanged.'
        : 'Matches expected output.';
  }
  return finalCorrectedText == fixture.text
      ? 'Left the text unchanged, but that did not match the expected '
            'output.'
      : 'Changed the text to something that does not match the expected '
            'output.';
}

/// Runs both pipeline architectures against [fixture] and scores each.
///
/// Since issue #126, the linear side's first pass uses
/// [linearFirstPassPrompt] and the parallel side's uses production's
/// unchanged `firstPassCorrectionSpanish` — two different prompts, so
/// (unlike this function's original #125 design) they can no longer
/// share a single first-pass call, and the parallel path's conditional
/// fallback can no longer reuse the linear path's naturalness call
/// either, since that call now reviews a different first-pass output.
/// Both first-pass calls and, when triggered, the fallback call, are
/// now genuinely independent — the same shape production's own pipeline
/// has, just with the linear side's first pass swapped for the revised
/// prompt.
Future<LinearPipelineComparisonResult> runLinearPipelineComparison({
  required OpenAiChatCompletionsClient client,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
}) async {
  // Linear: revised first-pass prompt (issue #126), then naturalness
  // reviews the first pass's own corrected text, sequentially, no
  // fallback possible.
  final linearFirstPassResponse = await _callLinearFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: fixture.text,
  );
  final linearNaturalnessReview = await callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: linearFirstPassResponse.correctedText,
  );
  final linearMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: linearFirstPassResponse.correctedText,
    naturalnessReview: linearNaturalnessReview,
  );
  final linearResponse = mapNaturalnessEditsIntoCorrectionResponse(
    firstPassResponse: linearFirstPassResponse,
    naturalnessMerge: linearMerge,
  );

  // Parallel: production's current, unmodified first-pass prompt, then
  // naturalness reviews the ORIGINAL text — production's own "started
  // concurrently with the first pass" call. Reproducing the exact
  // wall-clock concurrency isn't necessary for comparing final output
  // quality, only awaiting it after the first pass instead of alongside
  // it.
  final parallelFirstPassResponse = await callFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: fixture.text,
  );
  final parallelNaturalnessOnOriginal = await callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: fixture.text,
  );
  final parallelMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: parallelFirstPassResponse.correctedText,
    naturalnessReview: parallelNaturalnessOnOriginal,
  );

  final parallelUsedFallback = parallelMerge.skippedEdits.isNotEmpty;
  final CorrectionResponse parallelResponse;
  if (!parallelUsedFallback) {
    parallelResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: parallelFirstPassResponse,
      naturalnessMerge: parallelMerge,
    );
  } else {
    // Genuine fallback call (issue #126) — can no longer reuse the
    // linear path's naturalness call, since that reviewed a different
    // (revised-prompt) first-pass output than this (production-prompt)
    // one.
    final fallbackNaturalnessReview = await callNaturalnessReview(
      client: client,
      model: naturalnessModel,
      text: parallelFirstPassResponse.correctedText,
    );
    final fallbackMerge = mergeNaturalnessReview(
      originalText: fixture.text,
      firstPassCorrectedText: parallelFirstPassResponse.correctedText,
      naturalnessReview: fallbackNaturalnessReview,
    );
    parallelResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: parallelFirstPassResponse,
      naturalnessMerge: fallbackMerge,
    );
  }

  return LinearPipelineComparisonResult(
    fixture: fixture,
    linearFirstPassCorrectedText: linearFirstPassResponse.correctedText,
    linearNaturalnessDescription: _describeReview(linearNaturalnessReview),
    linearCorrectedText: linearResponse.correctedText,
    linearScore: _score(fixture, linearResponse.correctedText),
    linearReason: _reasonFor(fixture, linearResponse.correctedText),
    parallelFirstPassCorrectedText: parallelFirstPassResponse.correctedText,
    parallelNaturalnessOnOriginalDescription: _describeReview(
      parallelNaturalnessOnOriginal,
    ),
    parallelUsedFallback: parallelUsedFallback,
    parallelCorrectedText: parallelResponse.correctedText,
    parallelScore: _score(fixture, parallelResponse.correctedText),
    parallelReason: _reasonFor(fixture, parallelResponse.correctedText),
  );
}

/// Which pipeline "won" one fixture, by pass/fail score comparison.
enum _PipelineOutcome { linearWin, parallelWin, tie }

_PipelineOutcome _classify(LinearPipelineComparisonResult result) {
  final linearPass = isPassingScore(result.linearScore);
  final parallelPass = isPassingScore(result.parallelScore);
  if (linearPass && !parallelPass) {
    return _PipelineOutcome.linearWin;
  }
  if (parallelPass && !linearPass) {
    return _PipelineOutcome.parallelWin;
  }
  return _PipelineOutcome.tie;
}

/// Builds the comparison report, grouped by language point (same
/// convention every other benchmark report in this project uses).
String buildLinearPipelineComparisonReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<LinearPipelineComparisonResult> results,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln(
      '# Two-Pass Pipeline Architecture Comparison: Linear vs. Parallel '
      '(issues #125, #126)',
    )
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixture count: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(
      '"Linear" uses the revised first-pass prompt (issue #126, '
      '`linearFirstPassPrompt`, sourced from '
      '`Two-Pass_Prompt_Revision_Summary.docx`), then reviews that '
      'first pass\'s own corrected text once, sequentially, with no '
      'fallback concept. "Parallel" uses production\'s current, '
      'unmodified first-pass prompt, then reviews the original text '
      '(production\'s own concurrent call) and — only when that merge '
      'has a conflict — falls back to a genuine second naturalness '
      'call, same as production. The two architectures no longer share '
      'a first-pass call, since they now use different prompts.',
    )
    ..writeln();

  final byLanguagePoint = <String, List<LinearPipelineComparisonResult>>{};
  final order = <String>[];
  for (final result in results) {
    final key = result.fixture.languagePoint;
    if (!byLanguagePoint.containsKey(key)) {
      order.add(key);
    }
    (byLanguagePoint[key] ??= []).add(result);
  }

  for (final languagePoint in order) {
    buffer
      ..writeln('## $languagePoint')
      ..writeln();
    for (final result in byLanguagePoint[languagePoint]!) {
      buffer
        ..writeln('### ${result.fixture.id}')
        ..writeln()
        ..writeln('- Original text: `${result.fixture.text}`')
        ..writeln(
          '- Expected corrected text: '
          '`${result.fixture.expectedCorrectedText}`',
        )
        ..writeln(
          '- Pass 1, linear (revised prompt): '
          '`${result.linearFirstPassCorrectedText}`',
        )
        ..writeln(
          '- Pass 1, parallel (current prompt): '
          '`${result.parallelFirstPassCorrectedText}`',
        )
        ..writeln(
          '- Parallel used fallback: ${result.parallelUsedFallback}',
        )
        ..writeln()
        ..writeln(
          '| Architecture | Naturalness signal | Final output | Score | '
          'Reason |',
        )
        ..writeln('| --- | --- | --- | --- | --- |')
        ..writeln(
          '| Linear (serial) | ${result.linearNaturalnessDescription} | '
          '`${result.linearCorrectedText}` | '
          '${result.linearScore.reportLabel} | ${result.linearReason} |',
        )
        ..writeln(
          '| Parallel (production-equivalent) | '
          '${result.parallelNaturalnessOnOriginalDescription} | '
          '`${result.parallelCorrectedText}` | '
          '${result.parallelScore.reportLabel} | '
          '${result.parallelReason} |',
        )
        ..writeln();
    }
  }

  final linearPassCount = results
      .where((r) => isPassingScore(r.linearScore))
      .length;
  final parallelPassCount = results
      .where((r) => isPassingScore(r.parallelScore))
      .length;
  final fallbackCount = results.where((r) => r.parallelUsedFallback).length;
  final outcomes = results.map(_classify).toList();
  final linearWins = outcomes
      .where((o) => o == _PipelineOutcome.linearWin)
      .length;
  final parallelWins = outcomes
      .where((o) => o == _PipelineOutcome.parallelWin)
      .length;
  final ties = outcomes.where((o) => o == _PipelineOutcome.tie).length;

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Fixtures | ${results.length} |')
    ..writeln(
      '| Fixtures where parallel would use fallback | $fallbackCount |',
    )
    ..writeln(
      '| Linear pass rate | $linearPassCount/${results.length} |',
    )
    ..writeln(
      '| Parallel pass rate | $parallelPassCount/${results.length} |',
    )
    ..writeln('| Linear wins | $linearWins |')
    ..writeln('| Parallel wins | $parallelWins |')
    ..writeln('| Ties | $ties |');

  return buffer.toString();
}

void main() {
  group('offline sanity (no API calls)', () {
    test('linearComparisonFixtureIds all resolve to real fixtures', () {
      expect(
        linearComparisonFixtures.map((f) => f.id).toList(),
        linearComparisonFixtureIds,
      );
    });

    test('fixture ids are unique', () {
      final ids = linearComparisonFixtureIds.toSet();
      expect(ids.length, linearComparisonFixtureIds.length);
    });

    group('linearFirstPassPrompt (issue #126)', () {
      test(
        'matches the source document\'s exact wording — pinned so an '
        'accidental future edit is caught rather than silently drifting '
        'from Two-Pass_Prompt_Revision_Summary.docx',
        () {
          expect(
            linearFirstPassPrompt,
            'You are a Spanish language tutor reviewing a student\'s '
            'writing.\n'
            '\n'
            'Your task is to correct only objective Spanish grammar, '
            'spelling, and punctuation errors.\n'
            '\n'
            'Do not rewrite wording solely because another expression '
            'would be more common, more idiomatic, more fluent, or '
            'stylistically preferable.\n'
            'Do not replace wording that is recognised as correct by '
            'authoritative Spanish language references with another '
            'accepted alternative.\n'
            'Do not treat awkward but grammatically valid Spanish as an '
            'error.\n'
            '\n'
            'Correct every objective grammar, spelling, and punctuation '
            'error that you find.\n'
            '\n'
            'When a sentence contains more than one objective grammar '
            'error, correct every instance, not only the first one. For '
            'example:\n'
            '\n'
            '"Tengo cita con médico mañana."\n'
            '\n'
            'is missing both "una" before "cita" and "el" before '
            '"médico", so correct it to:\n'
            '\n'
            '"Tengo una cita con el médico mañana."\n'
            '\n'
            'Return JSON only. Do not include Markdown or commentary.',
          );
        },
      );

      test(
        'says only objective grammar/spelling/punctuation are in scope, '
        'and explicitly excludes word choice, style, fluency, general '
        'naturalness, and valid regional Spanish (acceptance criteria)',
        () {
          expect(
            linearFirstPassPrompt,
            contains(
              'correct only objective Spanish grammar, spelling, and '
              'punctuation errors',
            ),
          );
          expect(
            linearFirstPassPrompt,
            contains(
              'Do not rewrite wording solely because another expression '
              'would be more common, more idiomatic, more fluent, or '
              'stylistically preferable',
            ),
          );
          expect(
            linearFirstPassPrompt,
            contains(
              'Do not treat awkward but grammatically valid Spanish as '
              'an error',
            ),
          );
        },
      );

      test('requests a plain JSON reply with no wrapper commentary', () {
        expect(
          linearFirstPassPrompt,
          contains('Return JSON only. Do not include Markdown or commentary.'),
        );
      });
    });

    group('fixture-set selection', () {
      test('"comparison" returns the curated 17-fixture comparison set', () {
        expect(linearFixturesFor('comparison'), linearComparisonFixtures);
      });

      test('"all" returns every fixture in allTwoPassFixtures', () {
        expect(linearFixturesFor('all'), allTwoPassFixtures);
      });

      test('an unrecognized fixture set throws', () {
        expect(() => linearFixturesFor('bogus'), throwsArgumentError);
      });

      test(
        'linearFixturesFrom reads TWO_PASS_LINEAR_FIXTURE_SET from a '
        'real environment, defaulting to "comparison" when unset',
        () {
          expect(linearFixturesFrom(const {}), linearComparisonFixtures);
          expect(
            linearFixturesFrom(const {'TWO_PASS_LINEAR_FIXTURE_SET': 'all'}),
            allTwoPassFixtures,
          );
        },
      );
    });

    test('linearCallDelayMsFrom reads a real environment variable', () {
      expect(
        linearCallDelayMsFrom(const {'TWO_PASS_LINEAR_CALL_DELAY_MS': '2000'}),
        2000,
      );
      expect(linearCallDelayMsFrom(const {}), 750);
    });

    test(
      'runLinearTwoPassPipeline uses linearFirstPassPrompt (issue #126, '
      'not production\'s firstPassCorrectionSpanish), then reviews the '
      'first pass\'s own corrected text, not the original — and makes '
      'exactly two calls, never a third',
      () async {
        const fixtureText = 'Vi mucho trafico ayer.';
        final client = _RoutingHttpClient(
          linearFirstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
          originalText: fixtureText,
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": false, "issues": []}',
          ),
          naturalnessOnFirstPassReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "Vi mucho tráfico ayer.", '
            '"natural_replacement": "Había mucho tráfico ayer.", '
            '"explanation": "Sounds more natural."}'
            ']}',
          ),
        );

        final response = await runLinearTwoPassPipeline(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          submittedText: fixtureText,
        );

        // Applied the naturalness-on-first-pass reply, not the
        // naturalness-on-original reply (which reported no issue).
        expect(response.correctedText, 'Había mucho tráfico ayer.');
        expect(client.linearFirstPassCallCount, 1);
        expect(client.parallelFirstPassCallCount, 0);
        expect(client.naturalnessCallCount, 1);
      },
    );

    test(
      'runLinearPipelineComparison (issue #126) makes two independent '
      'first-pass calls — one per prompt — and genuinely re-issues the '
      'parallel path\'s fallback naturalness call when the parallel '
      'merge conflicts, rather than reusing the linear path\'s call',
      () async {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        final client = _RoutingHttpClient(
          linearFirstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          parallelFirstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          originalText: fixture.text,
          // Flags the whole sentence against the ORIGINAL text — this
          // won't match the parallel first pass's own corrected text
          // exactly, so the parallel merge conflicts and triggers a
          // fallback.
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "Vi mucho trafico ayer.", '
            '"natural_replacement": "Había mucho tráfico ayer.", '
            '"explanation": "Sounds more natural."}'
            ']}',
          ),
          naturalnessOnFirstPassReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": false, "issues": []}',
          ),
        );

        final result = await runLinearPipelineComparison(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          fixture: fixture,
        );

        expect(result.parallelUsedFallback, isTrue);
        expect(result.linearCorrectedText, 'Vi mucho tráfico ayer.');
        expect(result.parallelCorrectedText, 'Vi mucho tráfico ayer.');
        // One first-pass call per architecture (no longer shared, issue
        // #126) and three naturalness calls: linear's own call, the
        // parallel merge's naturalness-on-original call, and a genuine
        // third call for the parallel path's fallback.
        expect(client.linearFirstPassCallCount, 1);
        expect(client.parallelFirstPassCallCount, 1);
        expect(client.naturalnessCallCount, 3);
      },
    );

    test(
      'buildLinearPipelineComparisonReport groups fixtures by language '
      'point and renders both architectures',
      () {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        final result = LinearPipelineComparisonResult(
          fixture: fixture,
          linearFirstPassCorrectedText: fixture.expectedCorrectedText,
          linearNaturalnessDescription: '(none)',
          linearCorrectedText: fixture.expectedCorrectedText,
          linearScore: TwoPassScoreLabel.correctFix,
          linearReason: 'Matches expected output.',
          parallelFirstPassCorrectedText: fixture.expectedCorrectedText,
          parallelNaturalnessOnOriginalDescription: '(none)',
          parallelUsedFallback: false,
          parallelCorrectedText: fixture.expectedCorrectedText,
          parallelScore: TwoPassScoreLabel.correctFix,
          parallelReason: 'Matches expected output.',
        );

        final report = buildLinearPipelineComparisonReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [result],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(report, contains('## ${fixture.languagePoint}'));
        expect(report, contains('### clean-grammar-only'));
        expect(report, contains('Linear (serial)'));
        expect(report, contains('Parallel (production-equivalent)'));
        expect(report, contains('| Linear pass rate | 1/1 |'));
        expect(report, contains('| Parallel pass rate | 1/1 |'));
      },
    );
  });

  test(
    'two-pass pipeline architecture comparison: linear vs. parallel',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!_liveRunOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live linear/parallel pipeline comparison. Set '
          'TWO_PASS_LINEAR_COMPARISON_LIVE=true to opt in.',
        );
        return;
      }

      final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the linear pipeline comparison '
          'harness. This script does NOT fall back to any hardcoded/'
          'default key.',
        );
      }

      final firstPassModel = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_FIRST_PASS_MODEL',
        defaultValue: _defaultFirstPassModel,
      );
      final naturalnessModel = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_NATURALNESS_MODEL',
        defaultValue: _defaultNaturalnessModel,
      );
      final outputPath = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_OUTPUT',
        defaultValue: defaultLinearOutputPath,
      );
      final callDelayMs = linearCallDelayMsFrom(environment);
      final fixtures = linearFixturesFrom(environment);
      final httpClient = HttpClient();
      final client = OpenAiChatCompletionsClient(
        apiKey: apiKey,
        httpClient: httpClient,
      );

      final results = <LinearPipelineComparisonResult>[];
      for (final fixture in fixtures) {
        final result = await runLinearPipelineComparison(
          client: client,
          firstPassModel: firstPassModel,
          naturalnessModel: naturalnessModel,
          fixture: fixture,
        );
        results.add(result);
        // ignore: avoid_print
        print(
          '=== ${fixture.id} === fallback=${result.parallelUsedFallback} '
          'linear="${result.linearCorrectedText}" '
          '(${result.linearScore.reportLabel}) '
          'parallel="${result.parallelCorrectedText}" '
          '(${result.parallelScore.reportLabel})',
        );
        await Future<void>.delayed(Duration(milliseconds: callDelayMs));
      }

      final report = buildLinearPipelineComparisonReport(
        firstPassModel: firstPassModel,
        naturalnessModel: naturalnessModel,
        results: results,
        generatedAt: DateTime.now(),
      );

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote linear pipeline comparison report to $outputPath');
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

/// Fake HTTP client routing by request shape: a first-pass call is
/// routed by *system prompt* — [linearFirstPassPrompt] (issue #126) vs.
/// production's `firstPassCorrectionSpanish` — since issue #126 the two
/// architectures no longer share one first-pass call. A naturalness
/// call is routed by *user text* — whether it targets [originalText]
/// (the parallel path's concurrent call) or anything else (a call
/// reviewing a first-pass output, whether the linear path's own call or
/// the parallel path's genuine fallback call). Unlike the fallback
/// comparison harness's fake client (issue #117), there is only ever
/// one naturalness system prompt in play here, so no per-variant
/// naturalness system-prompt routing is needed. All routing state lives
/// on this client instance (constructed fresh per test), never a static
/// field.
class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient({
    required this.linearFirstPassReply,
    required this.parallelFirstPassReply,
    required this.originalText,
    required this.naturalnessOnOriginalReply,
    required this.naturalnessOnFirstPassReply,
  });

  /// Reply for a first-pass call using [linearFirstPassPrompt] (issue
  /// #126).
  final String linearFirstPassReply;

  /// Reply for a first-pass call using production's
  /// `firstPassCorrectionSpanish`.
  final String parallelFirstPassReply;
  final String originalText;
  final String naturalnessOnOriginalReply;

  /// Reply for any naturalness call NOT targeting [originalText] —
  /// covers both the linear path's own naturalness call and, when
  /// triggered, the parallel path's genuine fallback call (issue #126
  /// made these two separate HTTP requests again; tests that don't need
  /// to tell them apart by content can share this one reply).
  final String naturalnessOnFirstPassReply;
  int linearFirstPassCallCount = 0;
  int parallelFirstPassCallCount = 0;
  int naturalnessCallCount = 0;

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

    if (systemPrompt == linearFirstPassPrompt) {
      client.linearFirstPassCallCount++;
      return _FakeHttpClientResponse(replyBody: client.linearFirstPassReply);
    }
    if (systemPrompt == firstPassCorrectionSpanish) {
      client.parallelFirstPassCallCount++;
      return _FakeHttpClientResponse(
        replyBody: client.parallelFirstPassReply,
      );
    }

    client.naturalnessCallCount++;
    final isOnOriginal =
        userText == buildNaturalnessUserContent(client.originalText);
    return _FakeHttpClientResponse(
      replyBody: isOnOriginal
          ? client.naturalnessOnOriginalReply
          : client.naturalnessOnFirstPassReply,
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
