// Staged pipeline latency/cost baseline harness.
//
// Issue: "Audit and extend current staged pipeline benchmarking for latency
// and cost baseline". Purpose: establish a reliable latency, request-count,
// token-usage, and cost baseline for the CURRENT Spanish staged correction
// pipeline — not a new/parallel benchmark, and not a change to prompts,
// model behavior, UI flow, or the staged pipeline itself.
//
// Audit summary (see the issue for the full audit scope):
// - The path actually used by the app for Spanish correction is
//   `OpenAiCorrectionService.correctText()` -> (for `Language.spanish`)
//   `_correctSpanishTextViaStagedPipeline()` -> `runStagedCorrectionPipeline`
//   in `lib/features/corrections/data/staged_correction_pipeline.dart`.
// - That function can call up to five API requests per input: Stage 1,
//   Stage 1B, and Stage 1C detection (concurrent), Stage 2 categorization,
//   and Stage 3 feedback — every one of them via the shared
//   `OpenAiChatCompletionsClient.complete()`, each tagged with a
//   `stageLabel` ('stage1_dialect', 'stage1b_redundancy',
//   'stage1c_reflexive', 'stage2_categorization', 'stage3_feedback').
// - Two early-exit points exist: if Stage 1/1B/1C flag nothing, the
//   pipeline returns before Stage 2 runs at all; if Stage 2's categorized
//   candidates contain no error-verdict or dialectal-verdict items after
//   verdict splitting, the pipeline returns before Stage 3 runs. Only a
//   full run — one that reaches Stage 3 — makes all five requests.
// - Before this harness, `OpenAiChatCompletionsClient` only *printed* each
//   call's OpenAI `usage` object (`[usage] stage=... model=... usage=...`)
//   — nothing captured it as data, and nothing recorded latency at all.
//   `correction_consistency_harness.dart` already calls the real
//   `OpenAiCorrectionService.correctText()` live, but records only
//   accuracy/consistency data (target catch rate, span-width/category
//   distribution) — no latency, request count, tokens, or cost.
//   `model_comparison_harness.dart` already records latency/tokens/cost,
//   but against a single bare `/v1/chat/completions` call it makes
//   directly, not the staged pipeline, and is not wired to
//   `OpenAiCorrectionService` at all.
// - Smallest change made to close the gap: `OpenAiChatCompletionsClient`
//   gained an optional `onUsage` constructor callback (default `null`, so
//   every existing caller is unaffected) that receives a structured
//   `ChatCompletionsUsage` — stage label, model, latency, and token counts
//   — for every successful call, alongside (not instead of) the existing
//   console log. `OpenAiCorrectionService` gained the same optional
//   `onUsage` parameter, forwarded straight through to the
//   `OpenAiChatCompletionsClient` it already owns. This harness is the
//   first thing to actually use that hook.
//
// This harness calls the REAL, unmodified `OpenAiCorrectionService
// .correctText()` for a small fixed battery of Spanish inputs — one
// expected to reach the full pipeline, one expected to stay clean (Stage 1
// early exit), and one dialectal/regional case — recording, per input: the
// input text, model, commit, total end-to-end latency, observed usage-record
// count, stages observed, per-stage latency and token usage (via `onUsage`),
// total input/output/total tokens (shown as `unknown` if any stage is missing
// a token field — never silently treated as zero), estimated cost (reusing
// `model_comparison_harness.dart`'s pricing-table approach, and never
// computed from an incomplete token total), a `RunStatus` distinguishing a
// successful early exit / full pipeline run from a failed run (and, for a
// failed run, which stages had already reported usage before it failed —
// see `RunStatus` and `classifyRunStatus` below), a summary of the
// correction result, and any error.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/pipeline_baseline_harness.dart --exclude-tags live
//
// Run the live baseline (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/pipeline_baseline_harness.dart --timeout none
//
// Override the model with --dart-define=BASELINE_MODEL=... (default
// 'gpt-5.5'). Override the output path with
// --dart-define=BASELINE_OUTPUT=... (default
// 'docs/pipeline_baseline_harness.md').

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';

/// Model used for the live baseline run. Override with
/// `--dart-define=BASELINE_MODEL=...` without editing this file — same
/// override pattern as `correction_consistency_harness.dart`'s
/// `consistencyModel`.
const String baselineModel = String.fromEnvironment(
  'BASELINE_MODEL',
  defaultValue: 'gpt-5.5',
);

const String outputPath = String.fromEnvironment(
  'BASELINE_OUTPUT',
  defaultValue: 'docs/pipeline_baseline_harness.md',
);

/// Delay after every `correctText()` call in the live run — same
/// rate-limit mitigation every other live harness in this repo uses.
const int callDelayMs = int.fromEnvironment('CALL_DELAY_MS', defaultValue: 750);

/// USD-per-million-token pricing used for [estimateCostUsd]. Copied by
/// value from `model_comparison_harness.dart`'s `_pricingPerModel` — same
/// precedent as every other small helper duplicated across this repo's
/// standalone harness files (e.g. `staged_correction_pipeline.dart`'s
/// `_reconstructCorrectedText`), and the same caveat: illustrative
/// placeholders, not verified published pricing. A model missing from this
/// table yields a `null` estimate rather than a silently wrong number.
class _ModelPricing {
  const _ModelPricing({
    required this.inputPerMillionUsd,
    required this.outputPerMillionUsd,
  });

  final double inputPerMillionUsd;
  final double outputPerMillionUsd;
}

const Map<String, _ModelPricing> _pricingPerModel = {
  'gpt-5.5': _ModelPricing(
    inputPerMillionUsd: 3.00,
    outputPerMillionUsd: 12.00,
  ),
  'gpt-5.6-sol': _ModelPricing(
    inputPerMillionUsd: 4.00,
    outputPerMillionUsd: 16.00,
  ),
  'gpt-5.6-terra': _ModelPricing(
    inputPerMillionUsd: 1.20,
    outputPerMillionUsd: 6.00,
  ),
  'gpt-5.6-luna': _ModelPricing(
    inputPerMillionUsd: 0.30,
    outputPerMillionUsd: 1.50,
  ),
};

/// Estimated cost in USD for [inputTokens]/[outputTokens] under [model], or
/// `null` if [model] has no entry in [_pricingPerModel].
double? estimateCostUsd({
  required String model,
  required int inputTokens,
  required int outputTokens,
}) {
  final pricing = _pricingPerModel[model];
  if (pricing == null) {
    return null;
  }
  return (inputTokens / 1000000) * pricing.inputPerMillionUsd +
      (outputTokens / 1000000) * pricing.outputPerMillionUsd;
}

/// One fixed Spanish input in the baseline battery.
class _BaselineCase {
  const _BaselineCase({
    required this.id,
    required this.text,
    required this.note,
  });

  final String id;
  final String text;
  final String note;
}

const List<_BaselineCase> _cases = [
  _BaselineCase(
    id: 'full-pipeline-grammar-error',
    text: 'Los niño come muchas manzana en el jardín ayer.',
    note:
        'Objective grammar errors (missing plural agreement). Expected to '
        'reach Stage 2 and Stage 3 (an error-verdict candidate always '
        'triggers Stage 3 feedback) — the "full pipeline" case.',
  ),
  _BaselineCase(
    id: 'clean-text-no-errors',
    text: 'El cielo está despejado hoy y hace mucho sol en la ciudad.',
    note:
        'Already-correct Spanish with no objective errors and nothing '
        'dialectal. Expected to be flagged by neither Stage 1, Stage 1B, '
        'nor Stage 1C, so the pipeline returns before Stage 2 — the '
        '"Stage 1 only" early-exit case.',
  ),
  _BaselineCase(
    id: 'dialectal-voseo',
    text: 'Vos tenés razón, pero yo no puedo hacerlo hoy.',
    note:
        'Regional (voseo) Spanish, grammatically valid, not an objective '
        'error. Expected to be flagged by Stage 1 and categorized as a '
        'dialectal candidate by Stage 2, which (per '
        '`runStagedCorrectionPipeline`) still proceeds to Stage 3 — '
        'included to exercise the dialectal path, not to force a '
        'post-Stage-2 early exit that model behavior can\'t guarantee.',
  ),
];

/// `stageLabel`s the staged pipeline can emit, in the order a full run
/// would reach them — used only to order the per-stage table in the report
/// deterministically, since Stage 1/1B/1C run concurrently and can finish
/// (and so call `onUsage`) in any order.
const List<String> _stageOrder = [
  'stage1_dialect',
  'stage1b_redundancy',
  'stage1c_reflexive',
  'stage2_categorization',
  'stage3_feedback',
];

List<ChatCompletionsUsage> _sortedForReport(List<ChatCompletionsUsage> usages) {
  final indexOf = {
    for (var i = 0; i < _stageOrder.length; i++) _stageOrder[i]: i,
  };
  final sorted = [...usages]
    ..sort(
      (a, b) => (indexOf[a.stageLabel] ?? _stageOrder.length).compareTo(
        indexOf[b.stageLabel] ?? _stageOrder.length,
      ),
    );
  return sorted;
}

/// The three stage labels Stage 1/1B/1C detection can carry — grouped
/// because they run concurrently and are all "Stage 1" for classification
/// purposes.
const Set<String> _stage1Labels = {
  'stage1_dialect',
  'stage1b_redundancy',
  'stage1c_reflexive',
};

/// A run's final outcome for the baseline report — a single field that
/// combines *whether the run succeeded* with *which stages produced
/// observed `onUsage` data*, so a failed run can never be mistaken for a
/// successful early exit (or for a full pipeline run) just because it
/// happened to fail after some stages had already reported usage.
///
/// "Observed" here deliberately does not mean "completed successfully" —
/// `OpenAiChatCompletionsClient.complete` invokes `onUsage` as soon as it
/// has a decodable HTTP response, before it attempts to extract/parse the
/// assistant's reply content. So a request can report usage and still be
/// the one that ultimately caused the run to fail (e.g. a malformed
/// assistant reply after a perfectly good HTTP response). The `failedAfter*`
/// values name what was *observed before failure*, not what *completed*.
enum RunStatus {
  /// The run finished without error. Stage 1/1B/1C ran and flagged
  /// nothing; the pipeline returned before Stage 2 ever ran.
  completedStage1EarlyExit,

  /// The run finished without error. Stage 2 ran, but verdict splitting
  /// left no error-verdict or dialectal-verdict candidates; the pipeline
  /// returned before Stage 3.
  completedStage2EarlyExit,

  /// The run finished without error and Stage 3 also ran — every stage
  /// the pipeline can call.
  completedFullPipeline,

  /// The run threw, and no `onUsage` call was ever observed — failure
  /// happened before any stage produced a decodable response (or before
  /// any request was even made).
  failedNoUsageRecorded,

  /// The run threw, and the only usage observed came from Stage 1/1B/1C —
  /// failure happened at or before Stage 2.
  failedAfterObservedStage1,

  /// The run threw, and usage was observed for Stage 2 categorization —
  /// failure happened at or before Stage 3.
  failedAfterObservedStage2,

  /// The run threw, and usage was observed for Stage 3 feedback — the
  /// failure happened after every stage's request had a decodable
  /// response, most likely while parsing/assembling the final result.
  failedAfterObservedStage3,
}

/// `true` for every [RunStatus] that represents a run finishing without
/// throwing — i.e. every value that is *not* one of the `failed*` cases.
bool isSuccessfulRunStatus(RunStatus status) => switch (status) {
  RunStatus.completedStage1EarlyExit ||
  RunStatus.completedStage2EarlyExit ||
  RunStatus.completedFullPipeline => true,
  RunStatus.failedNoUsageRecorded ||
  RunStatus.failedAfterObservedStage1 ||
  RunStatus.failedAfterObservedStage2 ||
  RunStatus.failedAfterObservedStage3 => false,
};

/// Classifies a run into a [RunStatus] from whether it [isError] and which
/// `stageLabel`s its `ChatCompletionsUsage`s carried ([stagesObserved]).
/// Pure — looks only at those two inputs, not at counts, order, or
/// anything else. [isError] is checked first and is authoritative: a run
/// that threw is *never* classified as a successful early exit or a
/// successful full pipeline run, no matter which stages reported usage
/// before it failed.
RunStatus classifyRunStatus({
  required bool isError,
  required Set<String> stagesObserved,
}) {
  final reachedStage3 = stagesObserved.contains('stage3_feedback');
  final reachedStage2 = stagesObserved.contains('stage2_categorization');
  final reachedStage1 = stagesObserved.any(_stage1Labels.contains);

  if (isError) {
    if (reachedStage3) return RunStatus.failedAfterObservedStage3;
    if (reachedStage2) return RunStatus.failedAfterObservedStage2;
    if (reachedStage1) return RunStatus.failedAfterObservedStage1;
    return RunStatus.failedNoUsageRecorded;
  }

  if (reachedStage3) return RunStatus.completedFullPipeline;
  if (reachedStage2) return RunStatus.completedStage2EarlyExit;
  return RunStatus.completedStage1EarlyExit;
}

String describeRunStatus(RunStatus status) {
  switch (status) {
    case RunStatus.completedStage1EarlyExit:
      return 'completed — early exit — no flagged phrases after Stage 1/1B/1C';
    case RunStatus.completedStage2EarlyExit:
      return 'completed — early exit — no error/dialectal candidates after Stage 2';
    case RunStatus.completedFullPipeline:
      return 'completed — full pipeline (Stage 3 ran)';
    case RunStatus.failedNoUsageRecorded:
      return 'FAILED — no usage observed before failure';
    case RunStatus.failedAfterObservedStage1:
      return 'FAILED — usage observed only for Stage 1/1B/1C before failure';
    case RunStatus.failedAfterObservedStage2:
      return 'FAILED — usage observed through Stage 2 before failure';
    case RunStatus.failedAfterObservedStage3:
      return 'FAILED — usage observed through Stage 3 before failure';
  }
}

/// One case's baseline measurement — every `ChatCompletionsUsage` the
/// staged pipeline emitted for it (via `OpenAiCorrectionService`'s
/// `onUsage` hook), the case's total wall-clock latency, and its outcome
/// (a finished `CorrectionResponse`, or the error it failed with).
class CaseResult {
  const CaseResult({
    required this.caseId,
    required this.model,
    required this.totalLatencyMs,
    required this.stageUsages,
    this.response,
    this.error,
  });

  final String caseId;
  final String model;
  final int totalLatencyMs;
  final List<ChatCompletionsUsage> stageUsages;
  final CorrectionResponse? response;
  final Object? error;

  bool get isError => error != null;

  int get usageRecordCount => stageUsages.length;

  /// The distinct `stageLabel`s this run's `ChatCompletionsUsage`s
  /// carried. Named "observed", not "called" or "completed": `onUsage`
  /// fires once a request has a decodable HTTP response, which is *not*
  /// the same as that stage's result having been successfully parsed and
  /// used by the pipeline — see [RunStatus].
  Set<String> get stagesObserved =>
      stageUsages.map((usage) => usage.stageLabel).toSet();

  RunStatus get runStatus =>
      classifyRunStatus(isError: isError, stagesObserved: stagesObserved);

  /// Sum of every stage's `promptTokens`, or `null` if any stage in
  /// [stageUsages] is missing that field — a missing per-stage value must
  /// never be silently treated as zero, since that would understate the
  /// true total instead of flagging it as incomplete.
  int? get totalInputTokens =>
      _sumOrNullIfAnyMissing(stageUsages.map((usage) => usage.promptTokens));

  /// Sum of every stage's `completionTokens`, or `null` under the same
  /// "any missing value poisons the total" rule as [totalInputTokens].
  int? get totalOutputTokens => _sumOrNullIfAnyMissing(
    stageUsages.map((usage) => usage.completionTokens),
  );

  /// Sum of every stage's `totalTokens`, or `null` under the same rule as
  /// [totalInputTokens].
  int? get totalTokens =>
      _sumOrNullIfAnyMissing(stageUsages.map((usage) => usage.totalTokens));

  /// `true` if [stageUsages] is non-empty but at least one of its usages
  /// is missing a token field — i.e. the token totals above are partial,
  /// not simply "no usage was ever recorded".
  bool get hasPartialTokenUsage =>
      stageUsages.isNotEmpty &&
      (totalInputTokens == null ||
          totalOutputTokens == null ||
          totalTokens == null);

  /// Estimated cost from [totalInputTokens]/[totalOutputTokens], or `null`
  /// if either total is `null` (unknown model pricing, or an incomplete
  /// token total) — cost is never estimated from a partial total.
  double? get estimatedCostUsd {
    final inputTokens = totalInputTokens;
    final outputTokens = totalOutputTokens;
    if (inputTokens == null || outputTokens == null) {
      return null;
    }
    return estimateCostUsd(
      model: model,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );
  }
}

/// Sums [values], or returns `null` if any element is `null` — an empty
/// iterable sums to `0` (a known, empty total), which is distinct from a
/// non-empty iterable where at least one entry is missing (an unknown,
/// partial total).
int? _sumOrNullIfAnyMissing(Iterable<int?> values) {
  var sum = 0;
  for (final value in values) {
    if (value == null) {
      return null;
    }
    sum += value;
  }
  return sum;
}

/// Summarizes a finished [response]'s corrections for the report — a
/// human-readable line, not a full re-serialization.
String correctionSummary(CorrectionResponse response) {
  if (!response.hasCorrections) {
    return 'no corrections';
  }
  return response.corrections
      .map(
        (correction) =>
            '[${correction.category.label}] '
            '"${correction.originalPhrase}" -> "${correction.correctedPhrase}"',
      )
      .join('; ');
}

/// Renders an error for the report — `Object.toString()` is sufficient
/// here (unlike `correction_consistency_harness.dart`'s `_describeError`,
/// which special-cases `CorrectionServiceException` to surface
/// `reason`/`message`) since `CorrectionServiceException.toString()` isn't
/// overridden either way; kept as its own function so a future case-specific
/// override doesn't require touching every call site.
String describeError(Object error) => error.toString();

String _markdownTableCell(String value) {
  return value
      .replaceAll('|', r'\|')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', '<br>');
}

String _formatCost(double? cost) =>
    cost == null ? 'unknown' : cost.toStringAsFixed(6);

/// Renders a nullable token total for the report — `null` means at least
/// one stage was missing that field, so it's shown as `unknown` rather
/// than the misleading `0`.
String _formatTokenTotal(int? total) => total == null ? 'unknown' : '$total';

/// Builds the full markdown baseline report from already-collected
/// [results] — one section per case (inputs, totals, per-stage detail) plus
/// an overall summary table. Pure — takes data, makes no calls itself,
/// golden/assertion-testable against synthetic [CaseResult]s.
String _buildReport({
  required String model,
  required String commit,
  required DateTime generatedAt,
  required List<_BaselineCase> cases,
  required List<CaseResult> results,
}) {
  final report = StringBuffer()
    ..writeln('# Pipeline Baseline Harness')
    ..writeln()
    ..writeln('Model: `$model`  ')
    ..writeln('Commit: `$commit`  ')
    ..writeln('Generated: ${generatedAt.toIso8601String()}')
    ..writeln();

  final caseById = {for (final testCase in cases) testCase.id: testCase};

  for (final result in results) {
    final testCase = caseById[result.caseId];
    report
      ..writeln('## ${result.caseId}')
      ..writeln()
      ..writeln('- Input text: `${testCase?.text ?? '(unknown)'}`')
      ..writeln('- Note: ${testCase?.note ?? '(unknown)'}')
      ..writeln('- Usage records observed: ${result.usageRecordCount}')
      ..writeln(
        '- Stages observed: '
        '${result.stagesObserved.isEmpty ? '(none)' : (result.stagesObserved.toList()..sort()).join(', ')}',
      )
      ..writeln('- Run status: ${describeRunStatus(result.runStatus)}')
      ..writeln('- Total latency (ms): ${result.totalLatencyMs}')
      ..writeln(
        '- Total input tokens: ${_formatTokenTotal(result.totalInputTokens)}',
      )
      ..writeln(
        '- Total output tokens: ${_formatTokenTotal(result.totalOutputTokens)}',
      )
      ..writeln('- Total tokens: ${_formatTokenTotal(result.totalTokens)}')
      ..writeln(
        '- Estimated cost (USD): ${_formatCost(result.estimatedCostUsd)}',
      )
      ..writeln(
        '- Result: ${result.isError ? 'ERROR — ${describeError(result.error!)}' : correctionSummary(result.response!)}',
      )
      ..writeln();

    if (result.stageUsages.isNotEmpty) {
      report
        ..writeln('### Per-stage detail')
        ..writeln()
        ..writeln(
          '| Stage | Latency (ms) | Input tokens | Output tokens | Total tokens |',
        )
        ..writeln('| --- | --- | --- | --- | --- |');
      for (final usage in _sortedForReport(result.stageUsages)) {
        report.writeln(
          '| ${_markdownTableCell(usage.stageLabel)} | ${usage.latencyMs} | '
          '${usage.promptTokens ?? 'unknown'} | '
          '${usage.completionTokens ?? 'unknown'} | '
          '${usage.totalTokens ?? 'unknown'} |',
        );
      }
      report.writeln();
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln(
      '| Case | Usage records observed | Run status | Total latency (ms) | Total tokens | Est. cost (USD) |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- |');

  for (final result in results) {
    report.writeln(
      '| ${result.caseId} | ${result.usageRecordCount} | '
      '${describeRunStatus(result.runStatus)} | ${result.totalLatencyMs} | '
      '${_formatTokenTotal(result.totalTokens)} | ${_formatCost(result.estimatedCostUsd)} |',
    );
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

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}

void main() {
  test(
    'baseline battery cases are well-formed and cover early exit and full pipeline',
    () {
      expect(_cases.length, 3);
      expect(
        _cases.map((c) => c.id).toSet().length,
        _cases.length,
        reason: 'case ids must be unique',
      );
      for (final testCase in _cases) {
        expect(testCase.text.trim(), isNotEmpty);
        expect(testCase.note.trim(), isNotEmpty);
      }
    },
  );

  group('classifyRunStatus', () {
    test(
      'no stages observed, no error classifies as completedStage1EarlyExit',
      () {
        expect(
          classifyRunStatus(isError: false, stagesObserved: <String>{}),
          RunStatus.completedStage1EarlyExit,
        );
      },
    );

    test(
      'stage1 labels only, no error classifies as completedStage1EarlyExit',
      () {
        expect(
          classifyRunStatus(
            isError: false,
            stagesObserved: {
              'stage1_dialect',
              'stage1b_redundancy',
              'stage1c_reflexive',
            },
          ),
          RunStatus.completedStage1EarlyExit,
        );
      },
    );

    test(
      'stage1 + stage2 without stage3, no error classifies as completedStage2EarlyExit',
      () {
        expect(
          classifyRunStatus(
            isError: false,
            stagesObserved: {'stage1_dialect', 'stage2_categorization'},
          ),
          RunStatus.completedStage2EarlyExit,
        );
      },
    );

    test(
      'presence of stage3, no error always classifies as completedFullPipeline',
      () {
        expect(
          classifyRunStatus(
            isError: false,
            stagesObserved: {
              'stage1_dialect',
              'stage2_categorization',
              'stage3_feedback',
            },
          ),
          RunStatus.completedFullPipeline,
        );
      },
    );

    test(
      'error with no usage observed classifies as failedNoUsageRecorded',
      () {
        expect(
          classifyRunStatus(isError: true, stagesObserved: <String>{}),
          RunStatus.failedNoUsageRecorded,
        );
      },
    );

    test(
      'error after only stage1 usage classifies as failedAfterObservedStage1, never as a successful exit',
      () {
        expect(
          classifyRunStatus(
            isError: true,
            stagesObserved: {'stage1_dialect', 'stage1b_redundancy'},
          ),
          RunStatus.failedAfterObservedStage1,
        );
      },
    );

    test(
      'error after stage2 usage (but not stage3) classifies as failedAfterObservedStage2',
      () {
        expect(
          classifyRunStatus(
            isError: true,
            stagesObserved: {'stage1_dialect', 'stage2_categorization'},
          ),
          RunStatus.failedAfterObservedStage2,
        );
      },
    );

    test(
      'error after stage3 usage classifies as failedAfterObservedStage3, never as completedFullPipeline',
      () {
        expect(
          classifyRunStatus(
            isError: true,
            stagesObserved: {
              'stage1_dialect',
              'stage2_categorization',
              'stage3_feedback',
            },
          ),
          RunStatus.failedAfterObservedStage3,
        );
      },
    );
  });

  group('isSuccessfulRunStatus / describeRunStatus', () {
    test('only the completed* statuses are successful', () {
      expect(isSuccessfulRunStatus(RunStatus.completedStage1EarlyExit), isTrue);
      expect(isSuccessfulRunStatus(RunStatus.completedStage2EarlyExit), isTrue);
      expect(isSuccessfulRunStatus(RunStatus.completedFullPipeline), isTrue);
      expect(isSuccessfulRunStatus(RunStatus.failedNoUsageRecorded), isFalse);
      expect(
        isSuccessfulRunStatus(RunStatus.failedAfterObservedStage1),
        isFalse,
      );
      expect(
        isSuccessfulRunStatus(RunStatus.failedAfterObservedStage2),
        isFalse,
      );
      expect(
        isSuccessfulRunStatus(RunStatus.failedAfterObservedStage3),
        isFalse,
      );
    });

    test('describeRunStatus gives a distinct message per status', () {
      final descriptions = RunStatus.values.map(describeRunStatus).toSet();
      expect(descriptions.length, RunStatus.values.length);
    });

    test(
      'every failed* status description is unmistakably a failure, not an early exit or full pipeline claim',
      () {
        for (final status in RunStatus.values.where(
          (s) => !isSuccessfulRunStatus(s),
        )) {
          final description = describeRunStatus(status);
          expect(description, contains('FAILED'));
          expect(description, isNot(contains('early exit')));
          expect(description, isNot(contains('full pipeline')));
        }
      },
    );
  });

  group('estimateCostUsd', () {
    test('computes cost for a known model', () {
      final cost = estimateCostUsd(
        model: 'gpt-5.5',
        inputTokens: 1000000,
        outputTokens: 1000000,
      );
      expect(cost, closeTo(15.0, 1e-9));
    });

    test('returns null for an unknown model', () {
      expect(
        estimateCostUsd(
          model: 'not-a-model',
          inputTokens: 10,
          outputTokens: 10,
        ),
        isNull,
      );
    });

    test('scales linearly with token counts', () {
      final half = estimateCostUsd(
        model: 'gpt-5.6-terra',
        inputTokens: 500000,
        outputTokens: 0,
      );
      final full = estimateCostUsd(
        model: 'gpt-5.6-terra',
        inputTokens: 1000000,
        outputTokens: 0,
      );
      expect(full, closeTo(half! * 2, 1e-9));
    });
  });

  group('CaseResult', () {
    const successUsages = [
      ChatCompletionsUsage(
        stageLabel: 'stage1_dialect',
        model: 'gpt-5.5',
        latencyMs: 800,
        promptTokens: 100,
        completionTokens: 20,
        totalTokens: 120,
      ),
      ChatCompletionsUsage(
        stageLabel: 'stage2_categorization',
        model: 'gpt-5.5',
        latencyMs: 600,
        promptTokens: 150,
        completionTokens: 30,
        totalTokens: 180,
      ),
      ChatCompletionsUsage(
        stageLabel: 'stage3_feedback',
        model: 'gpt-5.5',
        latencyMs: 400,
        promptTokens: 80,
        completionTokens: 40,
        totalTokens: 120,
      ),
    ];

    test('aggregates request count, stages observed, and token totals', () {
      final result = CaseResult(
        caseId: 'case-1',
        model: 'gpt-5.5',
        totalLatencyMs: 2000,
        stageUsages: successUsages,
        response: CorrectionResponse(
          originalText: 'x',
          correctedText: 'x',
          corrections: [],
        ),
      );

      expect(result.usageRecordCount, 3);
      expect(result.stagesObserved, {
        'stage1_dialect',
        'stage2_categorization',
        'stage3_feedback',
      });
      expect(result.runStatus, RunStatus.completedFullPipeline);
      expect(result.totalInputTokens, 330);
      expect(result.totalOutputTokens, 90);
      expect(result.totalTokens, 420);
      expect(result.hasPartialTokenUsage, isFalse);
      expect(result.estimatedCostUsd, isNotNull);
      expect(result.isError, isFalse);
    });

    test('a missing usage field makes totals and cost unknown, not zero', () {
      final result = CaseResult(
        caseId: 'case-missing-usage',
        model: 'gpt-5.5',
        totalLatencyMs: 500,
        stageUsages: [
          ChatCompletionsUsage(
            stageLabel: 'stage1_dialect',
            model: 'gpt-5.5',
            latencyMs: 500,
          ),
        ],
        response: CorrectionResponse(
          originalText: 'x',
          correctedText: 'x',
          corrections: [],
        ),
      );

      expect(result.totalInputTokens, isNull);
      expect(result.totalOutputTokens, isNull);
      expect(result.totalTokens, isNull);
      expect(result.hasPartialTokenUsage, isTrue);
      expect(
        result.estimatedCostUsd,
        isNull,
        reason: 'cost must never be estimated from a partial token total',
      );
      expect(result.runStatus, RunStatus.completedStage1EarlyExit);
    });

    test(
      'a partial total from one stage among several is still unknown, not just the missing stage',
      () {
        const result = CaseResult(
          caseId: 'case-partial-usage',
          model: 'gpt-5.5',
          totalLatencyMs: 1400,
          stageUsages: [
            ChatCompletionsUsage(
              stageLabel: 'stage1_dialect',
              model: 'gpt-5.5',
              latencyMs: 500,
              promptTokens: 100,
              completionTokens: 20,
              totalTokens: 120,
            ),
            ChatCompletionsUsage(
              stageLabel: 'stage2_categorization',
              model: 'gpt-5.5',
              latencyMs: 500,
              // Token fields intentionally omitted.
            ),
          ],
          response: CorrectionResponse(
            originalText: 'x',
            correctedText: 'x',
            corrections: [],
          ),
        );

        expect(result.totalInputTokens, isNull);
        expect(result.totalOutputTokens, isNull);
        expect(result.totalTokens, isNull);
        expect(result.hasPartialTokenUsage, isTrue);
        expect(result.estimatedCostUsd, isNull);
      },
    );

    test('no stage usages at all yields known-zero totals, not "partial"', () {
      final result = CaseResult(
        caseId: 'case-no-usage',
        model: 'gpt-5.5',
        totalLatencyMs: 100,
        stageUsages: [],
        error: StateError('boom'),
      );

      expect(result.totalInputTokens, 0);
      expect(result.totalOutputTokens, 0);
      expect(result.totalTokens, 0);
      expect(result.hasPartialTokenUsage, isFalse);
      expect(result.runStatus, RunStatus.failedNoUsageRecorded);
    });

    test(
      'a failed run after only stage1 usage is not classified as a successful early exit',
      () {
        final result = CaseResult(
          caseId: 'case-error-after-stage1',
          model: 'gpt-5.5',
          totalLatencyMs: 1200,
          stageUsages: const [
            ChatCompletionsUsage(
              stageLabel: 'stage1_dialect',
              model: 'gpt-5.5',
              latencyMs: 700,
              promptTokens: 90,
              completionTokens: 15,
              totalTokens: 105,
            ),
          ],
          error: StateError('boom'),
        );

        expect(result.isError, isTrue);
        expect(result.usageRecordCount, 1);
        expect(result.runStatus, RunStatus.failedAfterObservedStage1);
        expect(isSuccessfulRunStatus(result.runStatus), isFalse);
        expect(describeError(result.error!), 'Bad state: boom');
      },
    );

    test(
      'a failed run after stage1 and stage2 usage (before stage3) is failedAfterObservedStage2',
      () {
        final result = CaseResult(
          caseId: 'case-error-after-stage2',
          model: 'gpt-5.5',
          totalLatencyMs: 2200,
          stageUsages: const [
            ChatCompletionsUsage(
              stageLabel: 'stage1_dialect',
              model: 'gpt-5.5',
              latencyMs: 700,
              promptTokens: 90,
              completionTokens: 15,
              totalTokens: 105,
            ),
            ChatCompletionsUsage(
              stageLabel: 'stage2_categorization',
              model: 'gpt-5.5',
              latencyMs: 600,
              promptTokens: 150,
              completionTokens: 30,
              totalTokens: 180,
            ),
          ],
          error: StateError('boom'),
        );

        expect(result.runStatus, RunStatus.failedAfterObservedStage2);
        expect(isSuccessfulRunStatus(result.runStatus), isFalse);
      },
    );

    test(
      'a failed run after full stage3 usage is failedAfterObservedStage3, not completedFullPipeline',
      () {
        final result = CaseResult(
          caseId: 'case-error-after-stage3',
          model: 'gpt-5.5',
          totalLatencyMs: 2600,
          stageUsages: successUsages,
          error: StateError('parsing blew up after every stage responded'),
        );

        expect(result.runStatus, RunStatus.failedAfterObservedStage3);
        expect(isSuccessfulRunStatus(result.runStatus), isFalse);
      },
    );
  });

  group('correctionSummary', () {
    test('reports "no corrections" when the response has none', () {
      expect(
        correctionSummary(
          const CorrectionResponse(
            originalText: 'x',
            correctedText: 'x',
            corrections: [],
          ),
        ),
        'no corrections',
      );
    });
  });

  group('buildReport', () {
    test('renders totals, early-exit vs. full-pipeline, and errors', () {
      final report = _buildReport(
        model: 'test-model',
        commit: 'abc1234',
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: _cases,
        results: [
          CaseResult(
            caseId: _cases[0].id,
            model: 'test-model',
            totalLatencyMs: 3000,
            stageUsages: const [
              ChatCompletionsUsage(
                stageLabel: 'stage1_dialect',
                model: 'test-model',
                latencyMs: 900,
                promptTokens: 100,
                completionTokens: 20,
                totalTokens: 120,
              ),
              ChatCompletionsUsage(
                stageLabel: 'stage2_categorization',
                model: 'test-model',
                latencyMs: 700,
                promptTokens: 150,
                completionTokens: 30,
                totalTokens: 180,
              ),
              ChatCompletionsUsage(
                stageLabel: 'stage3_feedback',
                model: 'test-model',
                latencyMs: 500,
                promptTokens: 80,
                completionTokens: 40,
                totalTokens: 120,
              ),
            ],
            response: const CorrectionResponse(
              originalText: 'Los niño come.',
              correctedText: 'Los niños comen.',
              corrections: [],
            ),
          ),
          CaseResult(
            caseId: _cases[1].id,
            model: 'test-model',
            totalLatencyMs: 900,
            stageUsages: const [
              ChatCompletionsUsage(
                stageLabel: 'stage1_dialect',
                model: 'test-model',
                latencyMs: 900,
                promptTokens: 60,
                completionTokens: 5,
                totalTokens: 65,
              ),
            ],
            response: const CorrectionResponse(
              originalText: 'El cielo está despejado.',
              correctedText: 'El cielo está despejado.',
              corrections: [],
            ),
          ),
          CaseResult(
            caseId: _cases[2].id,
            model: 'test-model',
            totalLatencyMs: 5000,
            stageUsages: const [],
            error: StateError('timed out'),
          ),
        ],
      );

      expect(report, contains('# Pipeline Baseline Harness'));
      expect(report, contains('Model: `test-model`'));
      expect(report, contains('Commit: `abc1234`'));

      expect(report, contains('## ${_cases[0].id}'));
      expect(report, contains('- Usage records observed: 3'));
      expect(
        report,
        contains(
          '- Stages observed: stage1_dialect, stage2_categorization, stage3_feedback',
        ),
      );
      expect(
        report,
        contains('- Run status: completed — full pipeline (Stage 3 ran)'),
      );
      expect(report, contains('- Total tokens: 420'));
      expect(report, contains('| stage1_dialect | 900 | 100 | 20 | 120 |'));

      expect(report, contains('## ${_cases[1].id}'));
      expect(report, contains('- Usage records observed: 1'));
      expect(
        report,
        contains(
          '- Run status: completed — early exit — no flagged phrases after Stage 1/1B/1C',
        ),
      );
      expect(report, contains('- Result: no corrections'));

      expect(report, contains('## ${_cases[2].id}'));
      expect(report, contains('- Usage records observed: 0'));
      expect(report, contains('- Stages observed: (none)'));
      expect(
        report,
        contains('- Run status: FAILED — no usage observed before failure'),
      );
      expect(report, contains('- Result: ERROR — Bad state: timed out'));

      expect(report, contains('## Overall summary'));
      expect(
        report,
        contains(
          '| ${_cases[0].id} | 3 | completed — full pipeline (Stage 3 ran) | 3000 | 420 |',
        ),
      );
    });

    test(
      'a failed run after observed Stage 1 usage is reported as a failure, not an early exit',
      () {
        final report = _buildReport(
          model: 'test-model',
          commit: 'abc1234',
          generatedAt: DateTime.utc(2026, 1, 1, 12),
          cases: _cases,
          results: [
            CaseResult(
              caseId: _cases[0].id,
              model: 'test-model',
              totalLatencyMs: 1500,
              stageUsages: const [
                ChatCompletionsUsage(
                  stageLabel: 'stage1_dialect',
                  model: 'test-model',
                  latencyMs: 900,
                  promptTokens: 100,
                  completionTokens: 20,
                  totalTokens: 120,
                ),
              ],
              error: StateError('stage2 request timed out'),
            ),
          ],
        );

        expect(report, contains('- Usage records observed: 1'));
        expect(report, contains('- Stages observed: stage1_dialect'));
        expect(
          report,
          contains(
            '- Run status: FAILED — usage observed only for Stage 1/1B/1C before failure',
          ),
        );
        expect(report, isNot(contains('- Run status: completed')));
        expect(
          report,
          contains('- Result: ERROR — Bad state: stage2 request timed out'),
        );
      },
    );

    test(
      'missing per-stage token usage renders as unknown, not zero, and cost is unknown',
      () {
        final report = _buildReport(
          model: 'test-model',
          commit: 'abc1234',
          generatedAt: DateTime.utc(2026, 1, 1, 12),
          cases: _cases,
          results: [
            CaseResult(
              caseId: _cases[0].id,
              model: 'test-model',
              totalLatencyMs: 800,
              stageUsages: const [
                ChatCompletionsUsage(
                  stageLabel: 'stage1_dialect',
                  model: 'test-model',
                  latencyMs: 800,
                ),
              ],
              response: const CorrectionResponse(
                originalText: 'x',
                correctedText: 'x',
                corrections: [],
              ),
            ),
          ],
        );

        expect(report, contains('- Total input tokens: unknown'));
        expect(report, contains('- Total output tokens: unknown'));
        expect(report, contains('- Total tokens: unknown'));
        expect(report, contains('- Estimated cost (USD): unknown'));
        expect(
          report,
          contains('| stage1_dialect | 800 | unknown | unknown | unknown |'),
        );
      },
    );
  });

  test(
    'pipeline baseline harness (live)',
    () async {
      final config = AppConfig.fromEnvironment();
      final apiKey = _readEnvironment(
        'OPENAI_API_KEY',
        defaultValue: config.openAiApiKey,
      );
      const model = baselineModel;

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY (or a default in AppConfig) to run the pipeline baseline harness.',
        );
      }

      final results = <CaseResult>[];

      for (final testCase in _cases) {
        final stageUsages = <ChatCompletionsUsage>[];
        final service = OpenAiCorrectionService(
          apiKey: apiKey,
          model: model,
          onUsage: stageUsages.add,
        );
        final stopwatch = Stopwatch()..start();
        CaseResult result;
        try {
          final response = await service.correctText(
            testCase.text,
            Language.spanish,
          );
          stopwatch.stop();
          result = CaseResult(
            caseId: testCase.id,
            model: model,
            totalLatencyMs: stopwatch.elapsedMilliseconds,
            stageUsages: List.of(stageUsages),
            response: response,
          );
        } catch (error) {
          stopwatch.stop();
          result = CaseResult(
            caseId: testCase.id,
            model: model,
            totalLatencyMs: stopwatch.elapsedMilliseconds,
            stageUsages: List.of(stageUsages),
            error: error,
          );
        }
        results.add(result);
        // ignore: avoid_print
        print(
          '=== ${testCase.id} === usage_records=${result.usageRecordCount} '
          'latency_ms=${result.totalLatencyMs} status=${describeRunStatus(result.runStatus)} '
          'tokens=${_formatTokenTotal(result.totalTokens)} cost_usd=${_formatCost(result.estimatedCostUsd)}',
        );
        await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
      }

      final report = _buildReport(
        model: model,
        commit: _gitHead(),
        generatedAt: DateTime.now(),
        cases: _cases,
        results: results,
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 30)),
    tags: ['live'],
  );
}
