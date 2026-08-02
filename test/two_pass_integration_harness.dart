// Live two-pass integration harness (issue #42).
//
// Purpose: measure the REAL, already-built two-pass pipeline's combined
// live behavior — first pass (callFirstPassCorrection, issue #68/#67/#65 —
// the narrow grammar/spelling/accents/punctuation-only client, no longer
// the old broad runStagedCorrectionPipeline), naturalness review
// (callNaturalnessReview), the merge (mergeNaturalnessReview), and the
// fallback rerun — across a small, deliberately chosen fixture set, and
// compare naturalness run on the original text against naturalness run on
// the first pass's own corrected text for the same input.
//
// Unlike the earlier prototyping harnesses in this repo
// (model_comparison_harness.dart, naturalness_model_comparison_harness.dart),
// this one is NOT standalone: by the time this issue exists, #27-#39 have
// already built and merged the real two-pass pipeline
// (lib/features/corrections/data/two_pass_correction_pipeline.dart and its
// dependencies), so re-prototyping that logic here from scratch would just
// risk drifting from what production actually does. This harness calls the
// same production functions runTwoPassCorrectionPipeline itself calls
// (mergeNaturalnessReview, mapNaturalnessEditsIntoCorrectionResponse), just
// sequenced by hand so it can also capture the naturalness-on-original-text
// result for comparison — production only ever needs the final answer, but
// a measurement harness needs the intermediate one too.
//
// Deliberately calls naturalness on BOTH the original text and the first
// pass's corrected text for every fixture, unconditionally — unlike
// production, which only calls the second (fallback) naturalness pass when
// the first merge attempt actually conflicts. That's the point: this
// harness exists to compare the two variants directly, not to reproduce
// production's own call-minimizing behavior.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_integration_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls — 5 fixtures, first pass
// (1 call each, issue #68) + 2 naturalness calls each; expect on the order
// of 15 total API calls):
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LIVE=true \
//   flutter test test/two_pass_integration_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - FIRST_PASS_MODEL: defaults to gpt-4.1.
// - NATURALNESS_MODEL: defaults to gpt-5.1.
// - TWO_PASS_OUTPUT: report path, defaults to
//   docs/two_pass_integration_harness.md.
// - TWO_PASS_CALL_DELAY_MS: delay between fixtures, defaults to 750.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

import 'shared/model_pricing.dart' as pricing;

/// Which edit shape a fixture is expected to exercise (issue #81) — lets a
/// benchmark reader tell a replacement case from an insertion, deletion,
/// mixed (more than one operation type in the same input), or
/// deliberately-unchanged one without re-deriving it from the input/
/// expected-output diff by eye. See
/// `docs/two_pass_language_point_test_map.md` for the full language-point
/// matrix this taxonomy is drawn from.
enum TwoPassOperationType { replacement, insertion, deletion, mixed, noChange }

/// Which pass a fixture expects to be responsible for its fix, or that no
/// fix is expected at all (issue #81). [either] covers both "either pass
/// alone would be an acceptable source of the fix" (e.g. a collocation
/// either pass might catch) and "both passes contribute independently, in
/// separate spans" (a fixture combining two language points) — the
/// distinction that matters for reading a report is that no single pass
/// is the sole expected owner, not which of those two shapes applies.
enum TwoPassExpectedOwner { firstPass, naturalness, either, noChange }

/// One fixture for this harness, chosen to exercise a distinct point on
/// the comparison this issue asks for.
class TwoPassFixture {
  const TwoPassFixture({
    required this.id,
    required this.text,
    required this.note,
    required this.languagePoint,
    required this.operationType,
    required this.expectedOwner,
    required this.expectedCorrectedText,
    this.acceptableAlternatives = const [],
  });

  final String id;
  final String text;
  final String note;

  /// The Spanish language point this fixture targets (e.g. "Accents /
  /// Diacritics", "Collocations / Strong Calques") — see
  /// `docs/two_pass_language_point_test_map.md` for the full matrix.
  final String languagePoint;

  /// The edit shape this fixture exercises.
  final TwoPassOperationType operationType;

  /// Which pass is expected to own this fixture's fix.
  final TwoPassExpectedOwner expectedOwner;

  /// The corrected text this fixture expects the two-pass pipeline to
  /// produce. For [TwoPassOperationType.noChange] fixtures, this equals
  /// [text] itself — no edit is expected.
  final String expectedCorrectedText;

  /// Other outputs that would also be an acceptable fix, alongside (not
  /// instead of) [expectedCorrectedText] — e.g. a synonym replacement
  /// naturalness sometimes proposes. Empty when only one output is
  /// considered correct.
  final List<String> acceptableAlternatives;
}

const List<TwoPassFixture> twoPassIntegrationFixtures = [
  TwoPassFixture(
    id: 'clean-grammar-only',
    text: 'Vi mucho trafico ayer.',
    note:
        'First-pass-only fixable error (missing accent); no naturalness '
        'issue anywhere. Expect: no conflict, no fallback.',
    languagePoint: 'Accents / Diacritics',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Vi mucho tráfico ayer.',
  ),
  TwoPassFixture(
    id: 'naturalness-only',
    text: 'Voy a hacer una decisión importante.',
    note:
        'No first-pass-fixable error; a naturalness calque only. Expect: '
        'naturalness-on-original and naturalness-on-corrected agree '
        '(the text is identical either way), no conflict.',
    languagePoint: 'Collocations / Strong Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.naturalness,
    expectedCorrectedText: 'Voy a tomar una decisión importante.',
  ),
  TwoPassFixture(
    id: 'grammar-and-naturalness-independent',
    text:
        'El profesor dijo que devia estudiar más, y ella hizo una '
        'decisión importante.',
    note:
        'Spatially separate first-pass fix ("devia" -> "debía") and '
        'naturalness calque ("hizo una decisión"). Expect: the '
        'naturalness span is untouched by the first pass, so both '
        'variants agree; no conflict.',
    // Two independent language points in one fixture: the accent fix is
    // first-pass-owned on its own, but the fixture as a whole isn't
    // solely either pass's job — see TwoPassExpectedOwner.either's doc.
    languagePoint:
        'Accents / Diacritics + Collocations / Strong Calques '
        '(independent spans)',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText:
        'El profesor dijo que debía estudiar más, y ella tomó una '
        'decisión importante.',
  ),
  TwoPassFixture(
    id: 'grammar-overlaps-naturalness',
    text: 'Ayer iso una decisión importante.',
    note:
        'The first-pass fix ("iso" -> "hizo") sits inside the exact '
        'naturalness calque span ("hizo una decisión") — the case the '
        'fallback exists for. Expect: naturalness-on-original flags the '
        'pre-correction wording (conflict against firstPassCorrectedText), '
        'naturalness-on-corrected flags the post-correction wording '
        '(resolves cleanly) — fallback used.',
    languagePoint:
        'Verb Morphology (spelling) overlapping Collocations / Strong '
        'Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Ayer tomó una decisión importante.',
  ),
  TwoPassFixture(
    id: 'ambiguous-naturalness-span',
    text: 'Vi mucho tráfico, y luego vi más tráfico.',
    note:
        'No first-pass fix needed; naturalness may flag a bare repeated '
        'word ambiguously on both passes. Expect: possible conflict that '
        'the fallback does not resolve either — the "still unsafe after a '
        'rerun" case from issue #37, observed live rather than simulated.',
    languagePoint: 'Ambiguous / Repeated Span Safety (Naturalness)',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Vi mucho tráfico, y luego vi más tráfico.',
  ),
];

const String _defaultFirstPassModel = 'gpt-4.1';
const String _defaultNaturalnessModel = 'gpt-5.1';
const String defaultTwoPassOutputPath =
    'docs/two_pass_integration_harness.md';

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'TWO_PASS_LIVE',
  defaultValue: false,
);

/// Parses `TWO_PASS_CALL_DELAY_MS` from [environment] (a real environment
/// variable, e.g. `TWO_PASS_CALL_DELAY_MS=2000 flutter test ...`) — not
/// `int.fromEnvironment`, which only ever reads a compile-time
/// `--dart-define` value and would silently ignore the environment
/// variable this file's own header comment documents. Falls back to `750`
/// when unset or unparsable, same default as before.
int callDelayMsFrom(Map<String, String> environment) {
  final raw = _runtimeString(
    environment: environment,
    key: 'TWO_PASS_CALL_DELAY_MS',
    defaultValue: '750',
  );
  return int.tryParse(raw) ?? 750;
}

String _runtimeString({
  required Map<String, String> environment,
  required String key,
  required String defaultValue,
}) {
  final fromEnvironment = environment[key]?.trim() ?? '';
  if (fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }
  return defaultValue;
}

bool _liveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      (environment['TWO_PASS_LIVE']?.trim().toLowerCase() == 'true');
}

/// Latency/token/cost totals for one logical phase of one fixture (the
/// first pass, naturalness-on-original, or naturalness-on-first-pass).
class CallStats {
  const CallStats({
    required this.wallClockMs,
    required this.totalTokens,
    required this.costUsd,
  });

  /// Wall-clock time for the whole phase, not the sum of individual API
  /// call latencies — kept distinct from a simple token/call sum since a
  /// phase can in general span more than one API call.
  final int wallClockMs;
  final int totalTokens;

  /// Null when the model has no verified pricing entry — see
  /// `test/shared/model_pricing.dart`.
  final double? costUsd;

  static const CallStats zero = CallStats(
    wallClockMs: 0,
    totalTokens: 0,
    costUsd: 0,
  );

  CallStats operator +(CallStats other) {
    final otherCost = other.costUsd;
    final thisCost = costUsd;
    return CallStats(
      wallClockMs: wallClockMs + other.wallClockMs,
      totalTokens: totalTokens + other.totalTokens,
      costUsd: (thisCost == null || otherCost == null)
          ? null
          : thisCost + otherCost,
    );
  }
}

/// Sums the [ChatCompletionsUsage] records a single phase produced (an
/// exact slice of the shared usage log, taken by the caller) into one
/// [CallStats], estimating cost from the phase's own model — every usage
/// record in one phase shares the same model, since a phase only ever
/// calls one model.
CallStats statsFor(List<ChatCompletionsUsage> usages, {required int wallClockMs}) {
  var totalTokens = 0;
  var inputTokens = 0;
  var outputTokens = 0;
  String? model;
  for (final usage in usages) {
    totalTokens += usage.totalTokens ?? 0;
    inputTokens += usage.promptTokens ?? 0;
    outputTokens += usage.completionTokens ?? 0;
    model ??= usage.model;
  }
  final cost = model == null
      ? const pricing.CostEstimate.unknown()
      : pricing.estimateCostUsd(
          model: model,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
  return CallStats(
    wallClockMs: wallClockMs,
    totalTokens: totalTokens,
    costUsd: cost.usd,
  );
}

/// Full per-fixture result: every value in the "Compare" list issue #42
/// asks for, for one fixture — or, when the live run for this fixture
/// threw (a malformed model response, a network failure, etc.),
/// [errorMessage] instead. One fixture's failure must never take down the
/// whole experiment or lose the data already gathered for every other
/// fixture — see the try/catch around [runFixture] in the live test below.
class FixtureResult {
  const FixtureResult({
    required this.fixture,
    required this.firstPassCorrectedText,
    required this.firstPassStats,
    required this.naturalnessOnOriginal,
    required this.naturalnessOnOriginalStats,
    required this.naturalnessOnFirstPass,
    required this.naturalnessOnFirstPassStats,
    required this.hadConflict,
    required this.usedFallback,
    required this.finalCorrectedText,
    required this.finalCorrectionCount,
    this.errorMessage,
  });

  /// [partialStats] is whatever latency/token/cost was already spent on
  /// real API calls before the failure — e.g. the first pass can succeed
  /// (and spend real tokens) before a later naturalness call fails to
  /// parse. Defaults to [CallStats.zero] for a failure before any call
  /// went out at all. Reported as [firstPassStats] here so it still shows
  /// up in the report and the overall summary's totals, rather than
  /// silently disappearing as an unreported $0.
  factory FixtureResult.error(
    TwoPassFixture fixture,
    String message, {
    CallStats partialStats = CallStats.zero,
  }) {
    const emptyReview = NaturalnessReview(
      hasNaturalnessIssue: false,
      issues: [],
    );
    return FixtureResult(
      fixture: fixture,
      firstPassCorrectedText: '',
      firstPassStats: partialStats,
      naturalnessOnOriginal: emptyReview,
      naturalnessOnOriginalStats: CallStats.zero,
      naturalnessOnFirstPass: emptyReview,
      naturalnessOnFirstPassStats: CallStats.zero,
      hadConflict: false,
      usedFallback: false,
      finalCorrectedText: '',
      finalCorrectionCount: 0,
      errorMessage: message,
    );
  }

  final TwoPassFixture fixture;
  final String firstPassCorrectedText;
  final CallStats firstPassStats;
  final NaturalnessReview naturalnessOnOriginal;
  final CallStats naturalnessOnOriginalStats;
  final NaturalnessReview naturalnessOnFirstPass;
  final CallStats naturalnessOnFirstPassStats;
  final bool hadConflict;
  final bool usedFallback;
  final String finalCorrectedText;
  final int finalCorrectionCount;
  final String? errorMessage;

  bool get isError => errorMessage != null;

  CallStats get totalStats =>
      firstPassStats + naturalnessOnOriginalStats + naturalnessOnFirstPassStats;
}

/// Runs the full comparison for one fixture: first pass
/// (`callFirstPassCorrection`, the narrow simple first-pass client — issue
/// #68), naturalness on the original text, naturalness on the first
/// pass's own corrected text, the parallel merge (to determine whether a
/// conflict exists), and —
/// only when a conflict exists, matching runTwoPassCorrectionPipeline's
/// own fallback-trigger condition — the fallback merge using the
/// naturalness-on-first-pass result already fetched above.
///
/// If any call fails partway through (a malformed model response, a
/// network error), whatever latency/tokens/cost was spent before the
/// failure is preserved — see [FixtureResult.error]'s `partialStats` —
/// rather than silently discarded, so the report's totals still reflect
/// real money spent even on a fixture that ultimately failed. Critically,
/// this includes the *failing* call's own spend, not just earlier calls
/// that fully succeeded: a naturalness call can get a valid, billed HTTP
/// response (recorded in [usageLog] the moment it arrives) and only then
/// throw while parsing that response's JSON — see [_trackedCall], which
/// records a phase's stats in a `finally` block so that always happens,
/// on success or failure alike, rather than only after an `await`
/// expression that might never finish normally.
Future<FixtureResult> runFixture({
  required OpenAiChatCompletionsClient client,
  required List<ChatCompletionsUsage> usageLog,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
}) async {
  var firstPassStats = CallStats.zero;
  var naturalOriginalStats = CallStats.zero;
  var naturalFirstPassStats = CallStats.zero;

  try {
    final firstPassResponse = await _trackedCall(
      usageLog,
      () => callFirstPassCorrection(
        client: client,
        model: firstPassModel,
        submittedText: fixture.text,
      ),
      onStats: (stats) => firstPassStats = stats,
    );

    final naturalnessOnOriginal = await _trackedCall(
      usageLog,
      () => callNaturalnessReview(
        client: client,
        model: naturalnessModel,
        text: fixture.text,
      ),
      onStats: (stats) => naturalOriginalStats = stats,
    );

    final naturalnessOnFirstPass = await _trackedCall(
      usageLog,
      () => callNaturalnessReview(
        client: client,
        model: naturalnessModel,
        text: firstPassResponse.correctedText,
      ),
      onStats: (stats) => naturalFirstPassStats = stats,
    );

    final parallelMerge = mergeNaturalnessReview(
      originalText: fixture.text,
      firstPassCorrectedText: firstPassResponse.correctedText,
      naturalnessReview: naturalnessOnOriginal,
    );
    final hadConflict = parallelMerge.skippedEdits.isNotEmpty;

    final finalMerge = hadConflict
        ? mergeNaturalnessReview(
            originalText: fixture.text,
            firstPassCorrectedText: firstPassResponse.correctedText,
            naturalnessReview: naturalnessOnFirstPass,
          )
        : parallelMerge;

    final finalResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: finalMerge,
    );

    return FixtureResult(
      fixture: fixture,
      firstPassCorrectedText: firstPassResponse.correctedText,
      firstPassStats: firstPassStats,
      naturalnessOnOriginal: naturalnessOnOriginal,
      naturalnessOnOriginalStats: naturalOriginalStats,
      naturalnessOnFirstPass: naturalnessOnFirstPass,
      naturalnessOnFirstPassStats: naturalFirstPassStats,
      hadConflict: hadConflict,
      usedFallback: hadConflict,
      finalCorrectedText: finalResponse.correctedText,
      finalCorrectionCount: finalResponse.corrections.length,
    );
  } catch (error) {
    return FixtureResult.error(
      fixture,
      error.toString(),
      partialStats: firstPassStats + naturalOriginalStats + naturalFirstPassStats,
    );
  }
}

/// Runs [call], recording its [CallStats] (wall-clock latency plus every
/// [ChatCompletionsUsage] logged to [usageLog] during the call) via
/// [onStats] — always, whether [call] completes normally or throws. Using
/// `finally` rather than only recording stats after a successful `await`
/// is what lets a phase that gets a valid, billed API response and then
/// throws while parsing it (the exact failure mode this harness's live
/// runs hit before issue #63's fix) still have its spend accounted for.
Future<T> _trackedCall<T>(
  List<ChatCompletionsUsage> usageLog,
  Future<T> Function() call, {
  required void Function(CallStats stats) onStats,
}) async {
  final stopwatch = Stopwatch()..start();
  final start = usageLog.length;
  try {
    return await call();
  } finally {
    stopwatch.stop();
    onStats(
      statsFor(
        usageLog.sublist(start),
        wallClockMs: stopwatch.elapsedMilliseconds,
      ),
    );
  }
}

String _describeReview(NaturalnessReview review) {
  if (!review.hasNaturalnessIssue) {
    return '(none)';
  }
  return review.issues
      .map((issue) => '${issue.span} -> ${issue.naturalReplacement}')
      .join('<br>');
}

String _formatCost(double? usd) =>
    usd == null ? 'unknown' : '\$${usd.toStringAsFixed(6)}';

/// Builds the full markdown report for [results], in the same style as
/// this repo's other harness reports.
String buildReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<FixtureResult> results,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# Two-Pass Live Integration Harness')
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln(
      '- Pass 1: `callFirstPassCorrection` — the simple, narrow '
      '`corrected_text`-only first-pass client (issue #68/#65), not the '
      'old broad `runStagedCorrectionPipeline`.',
    )
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixture count: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(pricing.pricingSection([firstPassModel, naturalnessModel]));

  for (final result in results) {
    if (result.isError) {
      buffer
        ..writeln('## ${result.fixture.id}')
        ..writeln()
        ..writeln('- Input text: `${result.fixture.text}`')
        ..writeln('- Note: ${result.fixture.note}')
        ..writeln('- Language point: ${result.fixture.languagePoint}')
        ..writeln(
          '- Operation type: ${result.fixture.operationType.name}',
        )
        ..writeln('- Expected owner: ${result.fixture.expectedOwner.name}')
        ..writeln(
          '- Expected corrected text: '
          '`${result.fixture.expectedCorrectedText}`',
        )
        ..writeln('- **ERROR**: ${result.errorMessage}');
      if (result.totalStats.totalTokens > 0) {
        buffer.writeln(
          '- Spent before the failure: '
          '${result.totalStats.wallClockMs} ms, '
          '${result.totalStats.totalTokens} tokens, '
          '${_formatCost(result.totalStats.costUsd)}',
        );
      }
      buffer.writeln();
      continue;
    }

    buffer
      ..writeln('## ${result.fixture.id}')
      ..writeln()
      ..writeln('- Input text: `${result.fixture.text}`')
      ..writeln('- Note: ${result.fixture.note}')
      ..writeln('- Language point: ${result.fixture.languagePoint}')
      ..writeln('- Operation type: ${result.fixture.operationType.name}')
      ..writeln('- Expected owner: ${result.fixture.expectedOwner.name}')
      ..writeln(
        '- Expected corrected text: '
        '`${result.fixture.expectedCorrectedText}`',
      );
    if (result.fixture.acceptableAlternatives.isNotEmpty) {
      buffer.writeln(
        '- Acceptable alternatives: '
        '${result.fixture.acceptableAlternatives.map((a) => '`$a`').join(', ')}',
      );
    }
    buffer
      ..writeln(
        '- First-pass corrected text: `${result.firstPassCorrectedText}`',
      )
      ..writeln(
        '- Naturalness on original text: '
        '${_describeReview(result.naturalnessOnOriginal)}',
      )
      ..writeln(
        '- Naturalness on first-pass corrected text: '
        '${_describeReview(result.naturalnessOnFirstPass)}',
      )
      ..writeln('- Conflict (parallel merge had a skipped edit): '
          '${result.hadConflict}')
      ..writeln('- Fallback used: ${result.usedFallback}')
      ..writeln('- Final merged output: `${result.finalCorrectedText}`')
      ..writeln('- Final correction count: ${result.finalCorrectionCount}')
      ..writeln()
      ..writeln(
        '| Phase | Latency (ms) | Total tokens | Est. cost (USD) |',
      )
      ..writeln('| --- | --- | --- | --- |')
      ..writeln(
        '| First pass | ${result.firstPassStats.wallClockMs} | '
        '${result.firstPassStats.totalTokens} | '
        '${_formatCost(result.firstPassStats.costUsd)} |',
      )
      ..writeln(
        '| Naturalness (original) | '
        '${result.naturalnessOnOriginalStats.wallClockMs} | '
        '${result.naturalnessOnOriginalStats.totalTokens} | '
        '${_formatCost(result.naturalnessOnOriginalStats.costUsd)} |',
      )
      ..writeln(
        '| Naturalness (first-pass corrected) | '
        '${result.naturalnessOnFirstPassStats.wallClockMs} | '
        '${result.naturalnessOnFirstPassStats.totalTokens} | '
        '${_formatCost(result.naturalnessOnFirstPassStats.costUsd)} |',
      )
      ..writeln(
        '| **Total** | ${result.totalStats.wallClockMs} | '
        '${result.totalStats.totalTokens} | '
        '${_formatCost(result.totalStats.costUsd)} |',
      )
      ..writeln();
  }

  final errorCount = results.where((r) => r.isError).length;
  final conflictCount = results.where((r) => r.hadConflict).length;
  final fallbackCount = results.where((r) => r.usedFallback).length;
  final totalLatencyMs = results.fold<int>(
    0,
    (sum, r) => sum + r.totalStats.wallClockMs,
  );
  final totalTokens = results.fold<int>(
    0,
    (sum, r) => sum + r.totalStats.totalTokens,
  );
  // Applies uniformly to error and non-error results alike: a result
  // whose partial spend used a model with no verified pricing is
  // "unknown", not $0 — regardless of whether that fixture went on to
  // fail.
  final anyUnknownCost = results.any((r) => r.totalStats.costUsd == null);
  final totalCostUsd = anyUnknownCost
      ? null
      : results.fold<double>(0, (sum, r) => sum + (r.totalStats.costUsd ?? 0));

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Fixtures | Errors | Conflicts | Fallbacks used | '
        'Total latency (ms) | Total tokens | Total est. cost (USD) |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |')
    ..writeln(
      '| ${results.length} | $errorCount | $conflictCount | $fallbackCount | '
      '$totalLatencyMs | $totalTokens | ${_formatCost(totalCostUsd)} |',
    );

  return buffer.toString();
}

void main() {
  group('offline sanity (no API calls)', () {
    test('fixture ids are unique', () {
      final ids = twoPassIntegrationFixtures.map((f) => f.id).toSet();
      expect(ids.length, twoPassIntegrationFixtures.length);
    });

    test(
      'every fixture carries required benchmark metadata (issue #81)',
      () {
        for (final fixture in twoPassIntegrationFixtures) {
          expect(
            fixture.languagePoint,
            isNotEmpty,
            reason: '${fixture.id} is missing a languagePoint',
          );
          expect(
            fixture.note,
            isNotEmpty,
            reason: '${fixture.id} is missing a note',
          );
          expect(
            fixture.expectedCorrectedText,
            isNotEmpty,
            reason: '${fixture.id} is missing an expectedCorrectedText',
          );
        }
      },
    );

    test(
      'a noChange operation type always expects the input text unchanged '
      '(issue #81)',
      () {
        for (final fixture in twoPassIntegrationFixtures) {
          if (fixture.operationType == TwoPassOperationType.noChange) {
            expect(
              fixture.expectedCorrectedText,
              fixture.text,
              reason:
                  '${fixture.id} is tagged noChange but expects a '
                  'different corrected text',
            );
          }
        }
      },
    );

    test(
      'TwoPassOperationType distinguishes replacement, insertion, '
      'deletion, mixed, and no-change (issue #81)',
      () {
        expect(TwoPassOperationType.values.toSet(), {
          TwoPassOperationType.replacement,
          TwoPassOperationType.insertion,
          TwoPassOperationType.deletion,
          TwoPassOperationType.mixed,
          TwoPassOperationType.noChange,
        });
      },
    );

    test(
      'TwoPassExpectedOwner distinguishes first pass, naturalness, '
      'either, and no-change (issue #81)',
      () {
        expect(TwoPassExpectedOwner.values.toSet(), {
          TwoPassExpectedOwner.firstPass,
          TwoPassExpectedOwner.naturalness,
          TwoPassExpectedOwner.either,
          TwoPassExpectedOwner.noChange,
        });
      },
    );

    test(
      'callDelayMsFrom reads a real environment variable, not just '
      '--dart-define',
      () {
        expect(
          callDelayMsFrom(const {'TWO_PASS_CALL_DELAY_MS': '2000'}),
          2000,
        );
        expect(callDelayMsFrom(const {}), 750);
        expect(
          callDelayMsFrom(const {'TWO_PASS_CALL_DELAY_MS': 'not-a-number'}),
          750,
        );
      },
    );

    test(
      '_trackedCall records stats via onStats even when the call throws '
      'after usage was already logged — the exact failure mode this '
      'harness\'s live runs hit: a valid, billed API response that only '
      'fails to parse afterward',
      () async {
        final usageLog = <ChatCompletionsUsage>[];
        CallStats? captured;

        await expectLater(
          () => _trackedCall(
            usageLog,
            () async {
              usageLog.add(
                const ChatCompletionsUsage(
                  stageLabel: 'naturalness_review',
                  model: 'gpt-5.1',
                  latencyMs: 500,
                  promptTokens: 200,
                  completionTokens: 100,
                  totalTokens: 300,
                ),
              );
              throw const FormatException(
                'Naturalness review is missing "has_naturalness_issue".',
              );
            },
            onStats: (stats) => captured = stats,
          ),
          throwsFormatException,
        );

        expect(captured, isNotNull);
        expect(captured!.totalTokens, 300);
        expect(captured!.costUsd, isNotNull);
      },
    );

    test(
      '_trackedCall records stats on success too, unaffected by adding '
      'failure-path support',
      () async {
        final usageLog = <ChatCompletionsUsage>[];
        CallStats? captured;

        final result = await _trackedCall(
          usageLog,
          () async {
            usageLog.add(
              const ChatCompletionsUsage(
                stageLabel: 'naturalness_review',
                model: 'gpt-5.1',
                latencyMs: 500,
                promptTokens: 10,
                completionTokens: 5,
                totalTokens: 15,
              ),
            );
            return 'ok';
          },
          onStats: (stats) => captured = stats,
        );

        expect(result, 'ok');
        expect(captured, isNotNull);
        expect(captured!.totalTokens, 15);
      },
    );

    test('statsFor sums tokens and computes verified cost from the '
        'phase\'s own model', () {
      final stats = statsFor(
        const [
          ChatCompletionsUsage(
            stageLabel: 'stage1_dialect',
            model: 'gpt-4.1',
            latencyMs: 500,
            promptTokens: 100,
            completionTokens: 20,
            totalTokens: 120,
          ),
          ChatCompletionsUsage(
            stageLabel: 'stage2_categorization',
            model: 'gpt-4.1',
            latencyMs: 700,
            promptTokens: 200,
            completionTokens: 40,
            totalTokens: 240,
          ),
        ],
        wallClockMs: 900,
      );

      expect(stats.wallClockMs, 900);
      expect(stats.totalTokens, 360);
      expect(stats.costUsd, isNotNull);
    });

    test('statsFor returns unknown cost for an unverified model', () {
      final stats = statsFor(
        const [
          ChatCompletionsUsage(
            stageLabel: 'naturalness_review',
            model: 'not-a-real-model',
            latencyMs: 500,
            promptTokens: 100,
            completionTokens: 20,
            totalTokens: 120,
          ),
        ],
        wallClockMs: 500,
      );

      expect(stats.costUsd, isNull);
    });

    test('CallStats addition sums fields, propagating an unknown cost', () {
      const a = CallStats(wallClockMs: 100, totalTokens: 10, costUsd: 0.01);
      const b = CallStats(wallClockMs: 200, totalTokens: 20, costUsd: null);
      final sum = a + b;

      expect(sum.wallClockMs, 300);
      expect(sum.totalTokens, 30);
      expect(sum.costUsd, isNull);
    });

    test('buildReport includes every fixture id and the overall summary '
        'table', () {
      final report = buildReport(
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        results: [
          FixtureResult(
            fixture: twoPassIntegrationFixtures.first,
            firstPassCorrectedText: 'Vi mucho tráfico ayer.',
            firstPassStats: CallStats.zero,
            naturalnessOnOriginal: const NaturalnessReview(
              hasNaturalnessIssue: false,
              issues: [],
            ),
            naturalnessOnOriginalStats: CallStats.zero,
            naturalnessOnFirstPass: const NaturalnessReview(
              hasNaturalnessIssue: false,
              issues: [],
            ),
            naturalnessOnFirstPassStats: CallStats.zero,
            hadConflict: false,
            usedFallback: false,
            finalCorrectedText: 'Vi mucho tráfico ayer.',
            finalCorrectionCount: 1,
          ),
        ],
        generatedAt: DateTime.utc(2026, 1, 1),
      );

      expect(report, contains('## clean-grammar-only'));
      expect(report, contains('## Overall summary'));
      expect(report, contains('| 1 | 0 | 0 | 0 |'));
    });

    test(
      'buildReport renders a fixture error without a data table, and '
      'counts it in the overall summary — one fixture\'s failure must '
      'still produce a complete, readable report for every other fixture',
      () {
        final report = buildReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [
            FixtureResult.error(
              twoPassIntegrationFixtures.first,
              'FormatException: Naturalness review is missing '
              '"has_naturalness_issue".',
            ),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(report, contains('## clean-grammar-only'));
        expect(
          report,
          contains(
            '**ERROR**: FormatException: Naturalness review is missing '
            '"has_naturalness_issue".',
          ),
        );
        expect(report, isNot(contains('| Phase | Latency (ms)')));
        expect(report, contains('| 1 | 1 | 0 | 0 |'));
      },
    );

    test(
      'buildReport shows tokens/cost already spent before a fixture '
      'failed partway through, instead of a misleading zero in the totals',
      () {
        const partialStats = CallStats(
          wallClockMs: 2500,
          totalTokens: 500,
          costUsd: 0.002,
        );
        final report = buildReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [
            FixtureResult.error(
              twoPassIntegrationFixtures.first,
              'FormatException: boom',
              partialStats: partialStats,
            ),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(
          report,
          contains('Spent before the failure: 2500 ms, 500 tokens'),
        );
        // The overall summary's totals include it too, not just the
        // per-fixture note.
        expect(report, contains('| 1 | 1 | 0 | 0 | 2500 | 500 |'));
      },
    );
  });

  test('two-pass live integration experiment', tags: 'live', () async {
    final environment = Platform.environment;
    if (!_liveRunOptIn(environment)) {
      // ignore: avoid_print
      print('Skipping live two-pass integration harness. Set '
          'TWO_PASS_LIVE=true to opt in.');
      return;
    }

    final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      fail(
        'Set OPENAI_API_KEY to run the two-pass integration harness. This '
        'script does NOT fall back to any hardcoded/default key.',
      );
    }

    final firstPassModel = _runtimeString(
      environment: environment,
      key: 'FIRST_PASS_MODEL',
      defaultValue: _defaultFirstPassModel,
    );
    final naturalnessModel = _runtimeString(
      environment: environment,
      key: 'NATURALNESS_MODEL',
      defaultValue: _defaultNaturalnessModel,
    );
    final outputPath = _runtimeString(
      environment: environment,
      key: 'TWO_PASS_OUTPUT',
      defaultValue: defaultTwoPassOutputPath,
    );
    final callDelayMs = callDelayMsFrom(environment);

    final usageLog = <ChatCompletionsUsage>[];
    final client = OpenAiChatCompletionsClient(
      apiKey: apiKey,
      httpClient: HttpClient(),
      onUsage: usageLog.add,
    );

    final results = <FixtureResult>[];
    for (final fixture in twoPassIntegrationFixtures) {
      // runFixture already catches its own failures and returns a
      // FixtureResult.error rather than throwing; this try/catch is a
      // defensive second layer only, in case something outside runFixture
      // itself (e.g. a bug in the print line below) throws — either way,
      // one fixture's failure must never lose the data already gathered
      // for every other fixture.
      try {
        final result = await runFixture(
          client: client,
          usageLog: usageLog,
          firstPassModel: firstPassModel,
          naturalnessModel: naturalnessModel,
          fixture: fixture,
        );
        results.add(result);
        // ignore: avoid_print
        print(
          result.isError
              ? '=== ${fixture.id} === ERROR: ${result.errorMessage}'
              : '=== ${fixture.id} ===\n'
                    'conflict=${result.hadConflict} '
                    'fallback=${result.usedFallback} '
                    'final="${result.finalCorrectedText}"',
        );
      } catch (error) {
        results.add(FixtureResult.error(fixture, error.toString()));
        // ignore: avoid_print
        print('=== ${fixture.id} === ERROR: $error');
      }
      await Future<void>.delayed(Duration(milliseconds: callDelayMs));
    }

    final report = buildReport(
      firstPassModel: firstPassModel,
      naturalnessModel: naturalnessModel,
      results: results,
      generatedAt: DateTime.now(),
    );

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(report);
    // ignore: avoid_print
    print('Wrote two-pass integration report to $outputPath');
  });
}
