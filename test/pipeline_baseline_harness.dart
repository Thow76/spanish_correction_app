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
// input text, model, commit, total end-to-end latency, request count,
// stages called, per-stage latency and token usage (via `onUsage`), total
// input/output/total tokens, estimated cost (reusing
// `model_comparison_harness.dart`'s pricing-table approach), whether the
// run exited early, a summary of the correction result, and any error.
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
  const _BaselineCase({required this.id, required this.text, required this.note});

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

/// Where a run's requests stopped, mirroring `runStagedCorrectionPipeline`'s
/// two early-return points exactly.
enum PipelineExitPoint {
  /// Stage 1/1B/1C ran and flagged nothing; the pipeline returned before
  /// Stage 2 ever ran.
  stage1Only,

  /// Stage 2 ran, but verdict splitting left no error-verdict or
  /// dialectal-verdict candidates; the pipeline returned before Stage 3.
  stage1AndStage2Only,

  /// Stage 3 also ran — every stage the pipeline can call.
  fullPipeline,
}

/// Classifies [stagesCalled] (the distinct `stageLabel`s a run's
/// `ChatCompletionsUsage`s carried) into a [PipelineExitPoint]. Pure —
/// looks only at which stage labels are present, not at counts, order, or
/// anything else.
PipelineExitPoint classifyExitPoint(Set<String> stagesCalled) {
  if (stagesCalled.contains('stage3_feedback')) {
    return PipelineExitPoint.fullPipeline;
  }
  if (stagesCalled.contains('stage2_categorization')) {
    return PipelineExitPoint.stage1AndStage2Only;
  }
  return PipelineExitPoint.stage1Only;
}

bool isEarlyExit(PipelineExitPoint exitPoint) =>
    exitPoint != PipelineExitPoint.fullPipeline;

String describeExitPoint(PipelineExitPoint exitPoint) {
  switch (exitPoint) {
    case PipelineExitPoint.stage1Only:
      return 'early exit — no flagged phrases after Stage 1/1B/1C';
    case PipelineExitPoint.stage1AndStage2Only:
      return 'early exit — no error/dialectal candidates after Stage 2';
    case PipelineExitPoint.fullPipeline:
      return 'full pipeline (Stage 3 ran)';
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

  int get requestCount => stageUsages.length;

  Set<String> get stagesCalled =>
      stageUsages.map((usage) => usage.stageLabel).toSet();

  PipelineExitPoint get exitPoint => classifyExitPoint(stagesCalled);

  int get totalInputTokens =>
      stageUsages.fold(0, (sum, usage) => sum + (usage.promptTokens ?? 0));

  int get totalOutputTokens => stageUsages.fold(
    0,
    (sum, usage) => sum + (usage.completionTokens ?? 0),
  );

  int get totalTokens =>
      stageUsages.fold(0, (sum, usage) => sum + (usage.totalTokens ?? 0));

  double? get estimatedCostUsd => estimateCostUsd(
    model: model,
    inputTokens: totalInputTokens,
    outputTokens: totalOutputTokens,
  );
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

/// Builds the full markdown baseline report from already-collected
/// [results] — one section per case (inputs, totals, per-stage detail) plus
/// an overall summary table. Pure — takes data, makes no calls itself,
/// golden/assertion-testable against synthetic [CaseResult]s.
String buildReport({
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
      ..writeln('- Requests made: ${result.requestCount}')
      ..writeln(
        '- Stages called: '
        '${result.stagesCalled.isEmpty ? '(none)' : (result.stagesCalled.toList()..sort()).join(', ')}',
      )
      ..writeln('- Exit point: ${describeExitPoint(result.exitPoint)}')
      ..writeln('- Total latency (ms): ${result.totalLatencyMs}')
      ..writeln('- Total input tokens: ${result.totalInputTokens}')
      ..writeln('- Total output tokens: ${result.totalOutputTokens}')
      ..writeln('- Total tokens: ${result.totalTokens}')
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
      '| Case | Requests | Exit point | Total latency (ms) | Total tokens | Est. cost (USD) |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- |');

  for (final result in results) {
    report.writeln(
      '| ${result.caseId} | ${result.requestCount} | '
      '${describeExitPoint(result.exitPoint)} | ${result.totalLatencyMs} | '
      '${result.totalTokens} | ${_formatCost(result.estimatedCostUsd)} |',
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
  test('baseline battery cases are well-formed and cover early exit and full pipeline', () {
    expect(_cases.length, 3);
    expect(_cases.map((c) => c.id).toSet().length, _cases.length, reason: 'case ids must be unique');
    for (final testCase in _cases) {
      expect(testCase.text.trim(), isNotEmpty);
      expect(testCase.note.trim(), isNotEmpty);
    }
  });

  group('classifyExitPoint', () {
    test('no stages called classifies as stage1Only', () {
      expect(classifyExitPoint(<String>{}), PipelineExitPoint.stage1Only);
    });

    test('stage1 labels only classify as stage1Only', () {
      expect(
        classifyExitPoint({'stage1_dialect', 'stage1b_redundancy', 'stage1c_reflexive'}),
        PipelineExitPoint.stage1Only,
      );
    });

    test('stage1 + stage2 without stage3 classifies as stage1AndStage2Only', () {
      expect(
        classifyExitPoint({'stage1_dialect', 'stage2_categorization'}),
        PipelineExitPoint.stage1AndStage2Only,
      );
    });

    test('presence of stage3 always classifies as fullPipeline', () {
      expect(
        classifyExitPoint({'stage1_dialect', 'stage2_categorization', 'stage3_feedback'}),
        PipelineExitPoint.fullPipeline,
      );
    });
  });

  group('isEarlyExit / describeExitPoint', () {
    test('stage1Only and stage1AndStage2Only are early exits; fullPipeline is not', () {
      expect(isEarlyExit(PipelineExitPoint.stage1Only), isTrue);
      expect(isEarlyExit(PipelineExitPoint.stage1AndStage2Only), isTrue);
      expect(isEarlyExit(PipelineExitPoint.fullPipeline), isFalse);
    });

    test('describeExitPoint gives a distinct message per exit point', () {
      final descriptions = PipelineExitPoint.values.map(describeExitPoint).toSet();
      expect(descriptions.length, PipelineExitPoint.values.length);
    });
  });

  group('estimateCostUsd', () {
    test('computes cost for a known model', () {
      final cost = estimateCostUsd(model: 'gpt-5.5', inputTokens: 1000000, outputTokens: 1000000);
      expect(cost, closeTo(15.0, 1e-9));
    });

    test('returns null for an unknown model', () {
      expect(estimateCostUsd(model: 'not-a-model', inputTokens: 10, outputTokens: 10), isNull);
    });

    test('scales linearly with token counts', () {
      final half = estimateCostUsd(model: 'gpt-5.6-terra', inputTokens: 500000, outputTokens: 0);
      final full = estimateCostUsd(model: 'gpt-5.6-terra', inputTokens: 1000000, outputTokens: 0);
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

    test('aggregates request count, stages called, and token totals', () {
      const result = CaseResult(
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

      expect(result.requestCount, 3);
      expect(result.stagesCalled, {'stage1_dialect', 'stage2_categorization', 'stage3_feedback'});
      expect(result.exitPoint, PipelineExitPoint.fullPipeline);
      expect(result.totalInputTokens, 330);
      expect(result.totalOutputTokens, 90);
      expect(result.totalTokens, 420);
      expect(result.estimatedCostUsd, isNotNull);
      expect(result.isError, isFalse);
    });

    test('treats a missing usage field as zero rather than throwing', () {
      const result = CaseResult(
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

      expect(result.totalInputTokens, 0);
      expect(result.totalOutputTokens, 0);
      expect(result.totalTokens, 0);
      expect(result.exitPoint, PipelineExitPoint.stage1Only);
    });

    test('an error result still reports whatever stages ran before failing', () {
      final result = CaseResult(
        caseId: 'case-error',
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
      expect(result.requestCount, 1);
      expect(result.exitPoint, PipelineExitPoint.stage1Only);
      expect(describeError(result.error!), 'Bad state: boom');
    });
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
      final report = buildReport(
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
      expect(report, contains('- Requests made: 3'));
      expect(
        report,
        contains(
          '- Stages called: stage1_dialect, stage2_categorization, stage3_feedback',
        ),
      );
      expect(report, contains('- Exit point: full pipeline (Stage 3 ran)'));
      expect(report, contains('- Total tokens: 420'));
      expect(report, contains('| stage1_dialect | 900 | 100 | 20 | 120 |'));

      expect(report, contains('## ${_cases[1].id}'));
      expect(report, contains('- Requests made: 1'));
      expect(
        report,
        contains(
          '- Exit point: early exit — no flagged phrases after Stage 1/1B/1C',
        ),
      );
      expect(report, contains('- Result: no corrections'));

      expect(report, contains('## ${_cases[2].id}'));
      expect(report, contains('- Requests made: 0'));
      expect(report, contains('- Stages called: (none)'));
      expect(report, contains('- Result: ERROR — Bad state: timed out'));

      expect(report, contains('## Overall summary'));
      expect(
        report,
        contains(
          '| ${_cases[0].id} | 3 | full pipeline (Stage 3 ran) | 3000 | 420 |',
        ),
      );
    });
  });

  test(
    'pipeline baseline harness (live)',
    () async {
      final config = AppConfig.fromEnvironment();
      final apiKey = _readEnvironment('OPENAI_API_KEY', defaultValue: config.openAiApiKey);
      const model = baselineModel;

      if (apiKey.isEmpty) {
        fail('Set OPENAI_API_KEY (or a default in AppConfig) to run the pipeline baseline harness.');
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
          final response = await service.correctText(testCase.text, Language.spanish);
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
          '=== ${testCase.id} === requests=${result.requestCount} '
          'latency_ms=${result.totalLatencyMs} exit=${describeExitPoint(result.exitPoint)} '
          'tokens=${result.totalTokens} cost_usd=${_formatCost(result.estimatedCostUsd)}',
        );
        await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
      }

      final report = buildReport(
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
