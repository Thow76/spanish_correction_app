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
// production already composes it from. This is the same "share calls
// for a fair, confound-free comparison" precedent
// `runFallbackPipelineComparison` (issue #117) already established: the
// first pass is called ONCE and shared between both architectures under
// test (only the naturalness step's timing/target text differs between
// them), and the parallel path's conditional fallback call — which asks
// the model the *exact* same question the linear path's own naturalness
// call already asked ("review this first-pass text for naturalness") —
// reuses that already-made result rather than spending a second live
// call asking the same question again. No production code is called or
// modified; this file only touches `lib/` via ordinary imports of the
// same pure functions the production pipeline itself imports.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls — default 17-fixture
// curated set: 1 shared first-pass call + 1 linear naturalness call + 1
// parallel naturalness-on-original call per fixture, i.e. always 3 total
// per fixture regardless of whether a conflict would have triggered a
// fallback, since the fallback call is never actually re-issued — expect
// on the order of 50 total calls for the default set):
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LINEAR_COMPARISON_LIVE=true \
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - TWO_PASS_LINEAR_FIRST_PASS_MODEL: defaults to gpt-4.1.
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
/// completes fully, then naturalness reviews the first pass's own
/// corrected text directly — never the original text, never
/// concurrently with the first pass, and never with a conditional
/// fallback rerun, because naturalness only ever sees the exact text it
/// is about to be merged into. Contrast with production's
/// `runTwoPassCorrectionPipeline`
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
  final firstPassResponse = await callFirstPassCorrection(
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

/// One fixture's side-by-side result: the linear (serial) pipeline vs.
/// the parallel (production-equivalent) pipeline, sharing the same
/// first-pass call.
class LinearPipelineComparisonResult {
  const LinearPipelineComparisonResult({
    required this.fixture,
    required this.firstPassCorrectedText,
    required this.linearNaturalnessDescription,
    required this.linearCorrectedText,
    required this.linearScore,
    required this.linearReason,
    required this.parallelNaturalnessOnOriginalDescription,
    required this.parallelUsedFallback,
    required this.parallelCorrectedText,
    required this.parallelScore,
    required this.parallelReason,
  });

  final TwoPassFixture fixture;
  final String firstPassCorrectedText;

  final String linearNaturalnessDescription;
  final String linearCorrectedText;
  final TwoPassScoreLabel linearScore;
  final String linearReason;

  final String parallelNaturalnessOnOriginalDescription;

  /// Whether the parallel path's merge on naturalness-on-original had a
  /// skipped edit, i.e. whether production's real pipeline would have
  /// triggered its sequential fallback here. That fallback's own
  /// naturalness call is never separately re-issued — it would ask the
  /// exact question the linear pipeline's own naturalness call already
  /// asked, so this result reuses that call's data instead.
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

/// Runs both pipeline architectures against [fixture] and scores each,
/// sharing the first-pass call between them (see this file's own header
/// comment for why) and reusing the linear pipeline's own naturalness
/// call as the parallel path's fallback result rather than re-issuing
/// the identical question a second time.
Future<LinearPipelineComparisonResult> runLinearPipelineComparison({
  required OpenAiChatCompletionsClient client,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
}) async {
  final firstPassResponse = await callFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: fixture.text,
  );

  // Linear: naturalness reviews the first pass's own corrected text,
  // sequentially, no fallback possible.
  final linearNaturalnessReview = await callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: firstPassResponse.correctedText,
  );
  final linearMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: linearNaturalnessReview,
  );
  final linearResponse = mapNaturalnessEditsIntoCorrectionResponse(
    firstPassResponse: firstPassResponse,
    naturalnessMerge: linearMerge,
  );

  // Parallel: naturalness reviews the ORIGINAL text — production's own
  // "started concurrently with the first pass" call. Reproducing the
  // exact wall-clock concurrency isn't necessary for comparing final
  // output quality, only awaiting it after the first pass instead of
  // alongside it.
  final parallelNaturalnessOnOriginal = await callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: fixture.text,
  );
  final parallelMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: parallelNaturalnessOnOriginal,
  );

  final parallelUsedFallback = parallelMerge.skippedEdits.isNotEmpty;
  final CorrectionResponse parallelResponse;
  if (!parallelUsedFallback) {
    parallelResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: parallelMerge,
    );
  } else {
    // Production's fallback asks the exact same question the linear
    // pipeline's own naturalness call already asked — reuse that
    // result instead of calling the API again.
    final fallbackMerge = mergeNaturalnessReview(
      originalText: fixture.text,
      firstPassCorrectedText: firstPassResponse.correctedText,
      naturalnessReview: linearNaturalnessReview,
    );
    parallelResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: fallbackMerge,
    );
  }

  return LinearPipelineComparisonResult(
    fixture: fixture,
    firstPassCorrectedText: firstPassResponse.correctedText,
    linearNaturalnessDescription: _describeReview(linearNaturalnessReview),
    linearCorrectedText: linearResponse.correctedText,
    linearScore: _score(fixture, linearResponse.correctedText),
    linearReason: _reasonFor(fixture, linearResponse.correctedText),
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
      '(issue #125)',
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
      'The first pass is run once per fixture and shared between both '
      'architectures below. "Linear" reviews the first pass\'s own '
      'corrected text once, sequentially, with no fallback concept. '
      '"Parallel" reviews the original text (production\'s own '
      'concurrent call) and — only when that merge has a conflict — '
      'falls back to the exact naturalness call the linear pipeline '
      'already made, rather than issuing it again.',
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
          '- Pass 1 (first-pass corrected text, shared): '
          '`${result.firstPassCorrectedText}`',
        )
        ..writeln(
          '- Parallel would use fallback: ${result.parallelUsedFallback}',
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
      'runLinearTwoPassPipeline reviews the first pass\'s own corrected '
      'text, not the original — and makes exactly two calls, never a '
      'third',
      () async {
        const fixtureText = 'Vi mucho trafico ayer.';
        final client = _RoutingHttpClient(
          firstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
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
        expect(client.naturalnessCallCount, 1);
      },
    );

    test(
      'runLinearPipelineComparison shares one first-pass call and never '
      'issues a third naturalness call even when the parallel merge '
      'would trigger a fallback — it reuses the linear pipeline\'s own '
      'naturalness-on-first-pass result instead',
      () async {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        final client = _RoutingHttpClient(
          firstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          originalText: fixture.text,
          // Flags the whole sentence against the ORIGINAL text — this
          // won't match the first pass's own corrected text exactly, so
          // the parallel merge conflicts (would trigger a fallback in
          // production).
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
        // Linear found no remaining issue reviewing the first-pass text
        // directly.
        expect(result.linearCorrectedText, 'Vi mucho tráfico ayer.');
        // Parallel's "fallback" reused that exact same result rather
        // than asking again.
        expect(result.parallelCorrectedText, 'Vi mucho tráfico ayer.');
        // Exactly one first-pass call and two naturalness calls total —
        // never a third for the fallback.
        expect(client.firstPassCallCount, 1);
        expect(client.naturalnessCallCount, 2);
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
          firstPassCorrectedText: fixture.expectedCorrectedText,
          linearNaturalnessDescription: '(none)',
          linearCorrectedText: fixture.expectedCorrectedText,
          linearScore: TwoPassScoreLabel.correctFix,
          linearReason: 'Matches expected output.',
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

/// Fake HTTP client routing by request shape: the first-pass prompt
/// always gets [firstPassReply]; a naturalness call is routed by
/// *user text* — whether it targets [originalText] (the parallel path's
/// concurrent call) or anything else (the linear path's call, always
/// targeting the first pass's own corrected text). Unlike the fallback
/// comparison harness's fake client (issue #117), there is only ever
/// one naturalness system prompt in play here, so no per-variant
/// system-prompt routing is needed. All routing state lives on this
/// client instance (constructed fresh per test), never a static field.
class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient({
    required this.firstPassReply,
    required this.originalText,
    required this.naturalnessOnOriginalReply,
    required this.naturalnessOnFirstPassReply,
  });

  final String firstPassReply;
  final String originalText;
  final String naturalnessOnOriginalReply;
  final String naturalnessOnFirstPassReply;
  int firstPassCallCount = 0;
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

    if (systemPrompt == firstPassCorrectionSpanish) {
      client.firstPassCallCount++;
      return _FakeHttpClientResponse(replyBody: client.firstPassReply);
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
