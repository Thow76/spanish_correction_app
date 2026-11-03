// Live two-pass collocation boundary harness.
//
// Purpose: test whether the current narrow first-pass prompt, run with
// gpt-4.1 by default, leaves English-influenced Spanish collocations alone
// or corrects them anyway. The second/naturalness pass is still run so the
// experiment keeps the same two-pass shape, but pass 1 is the main boundary
// under test.
//
// Run offline sanity tests only:
//   flutter test test/collocation_two_pass_boundary_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls; default 10 fixtures x 5 runs
// x 3 calls = 150 chat-completions calls):
//   OPENAI_API_KEY=sk-... \
//   COLLOCATION_LIVE=true \
//   flutter test test/collocation_two_pass_boundary_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - COLLOCATION_FIRST_PASS_MODEL: defaults to gpt-4.1.
// - COLLOCATION_NATURALNESS_MODEL: defaults to gpt-5.1.
// - COLLOCATION_RUNS_PER_CASE: defaults to 5.
// - COLLOCATION_FIXTURE_IDS: comma-separated fixture ids.
// - COLLOCATION_OUTPUT: defaults to docs/collocation_two_pass_boundary_harness.md.
// - COLLOCATION_CALL_DELAY_MS: delay after each run, defaults to 750.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_issue.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

import 'shared/model_pricing.dart' as pricing;

const String firstPassPromptVersion = 'v1';
const String naturalnessPromptVersion = 'v3';

const String firstPassPromptLabel =
    'simple-spanish-grammar-spelling-punctuation-only';
const String naturalnessPromptLabel =
    'spanish-naturalness-only-variety-restraint';

const String defaultOutputPath =
    'docs/collocation_two_pass_boundary_harness.md';

class CollocationFixture {
  const CollocationFixture({
    required this.id,
    required this.text,
    required this.problemPhrase,
    required this.naturalReplacement,
    required this.englishSource,
    required this.note,
  });

  final String id;
  final String text;
  final String problemPhrase;
  final String naturalReplacement;
  final String englishSource;
  final String note;
}

const List<CollocationFixture> collocationFixtures = [
  CollocationFixture(
    id: 'make-a-decision',
    text: 'Voy a hacer una decisión importante antes del viernes.',
    problemPhrase: 'hacer una decisión',
    naturalReplacement: 'tomar una decisión',
    englishSource: 'make a decision',
    note: 'Classic English-influenced verb-noun collocation.',
  ),
  CollocationFixture(
    id: 'make-sense',
    text: 'Tu explicación no hace sentido en este contexto.',
    problemPhrase: 'hace sentido',
    naturalReplacement: 'tiene sentido',
    englishSource: 'make sense',
    note: 'Common calque where Spanish normally uses tener sentido.',
  ),
  CollocationFixture(
    id: 'pay-attention',
    text: 'Tienes que pagar atención a los detalles del contrato.',
    problemPhrase: 'pagar atención',
    naturalReplacement: 'prestar atención',
    englishSource: 'pay attention',
    note: 'English-influenced collocation with atención.',
  ),
  CollocationFixture(
    id: 'take-a-meeting',
    text: 'El equipo tomó una reunión para hablar del problema.',
    problemPhrase: 'tomó una reunión',
    naturalReplacement: 'tuvo una reunión',
    englishSource: 'take a meeting',
    note: 'English-influenced business phrase.',
  ),
  CollocationFixture(
    id: 'apply-for-job',
    text: 'Mi hermano aplicó para un trabajo en Madrid.',
    problemPhrase: 'aplicó para un trabajo',
    naturalReplacement: 'solicitó un trabajo',
    englishSource: 'applied for a job',
    note: 'False-friend and collocation boundary case.',
  ),
  CollocationFixture(
    id: 'attend-university',
    text: 'Ella atendió la universidad en Salamanca.',
    problemPhrase: 'atendió la universidad',
    naturalReplacement: 'asistió a la universidad',
    englishSource: 'attended university',
    note: 'False-friend collocation around attend/asistir.',
  ),
  CollocationFixture(
    id: 'have-good-time',
    text: 'Tuvimos un buen tiempo en la fiesta anoche.',
    problemPhrase: 'tuvimos un buen tiempo',
    naturalReplacement: 'lo pasamos bien',
    englishSource: 'had a good time',
    note: 'English-influenced expression for enjoying oneself.',
  ),
  CollocationFixture(
    id: 'make-a-point',
    text: 'La profesora hizo un punto interesante durante la clase.',
    problemPhrase: 'hizo un punto',
    naturalReplacement: 'planteó un punto',
    englishSource: 'made a point',
    note: 'English-influenced discourse collocation.',
  ),
  CollocationFixture(
    id: 'take-a-look',
    text: 'Voy a tomar una mirada al documento esta tarde.',
    problemPhrase: 'tomar una mirada',
    naturalReplacement: 'echar un vistazo',
    englishSource: 'take a look',
    note: 'English-influenced light-verb phrase.',
  ),
  CollocationFixture(
    id: 'running-late',
    text: 'Estoy corriendo tarde para la reunión.',
    problemPhrase: 'corriendo tarde',
    naturalReplacement: 'llegando tarde',
    englishSource: 'running late',
    note: 'English-influenced predicate phrase.',
  ),
];

const String _firstPassModelFromDefine = String.fromEnvironment(
  'COLLOCATION_FIRST_PASS_MODEL',
  defaultValue: '',
);
const String _naturalnessModelFromDefine = String.fromEnvironment(
  'COLLOCATION_NATURALNESS_MODEL',
  defaultValue: '',
);
const String _fixtureIdsFromDefine = String.fromEnvironment(
  'COLLOCATION_FIXTURE_IDS',
  defaultValue: '',
);
const String _runsPerCaseFromDefine = String.fromEnvironment(
  'COLLOCATION_RUNS_PER_CASE',
  defaultValue: '',
);
const String _outputPathFromDefine = String.fromEnvironment(
  'COLLOCATION_OUTPUT',
  defaultValue: '',
);
const String _callDelayMsFromDefine = String.fromEnvironment(
  'COLLOCATION_CALL_DELAY_MS',
  defaultValue: '',
);
const bool _liveOptInFromDefine = bool.fromEnvironment(
  'COLLOCATION_LIVE',
  defaultValue: false,
);

class HarnessConfig {
  const HarnessConfig({
    required this.firstPassModel,
    required this.naturalnessModel,
    required this.fixtures,
    required this.runsPerCase,
    required this.outputPath,
    required this.callDelayMs,
    required this.liveOptIn,
  });

  final String firstPassModel;
  final String naturalnessModel;
  final List<CollocationFixture> fixtures;
  final int runsPerCase;
  final String outputPath;
  final int callDelayMs;
  final bool liveOptIn;
}

HarnessConfig buildConfig(Map<String, String> environment) {
  return HarnessConfig(
    firstPassModel: _runtimeString(
      dartDefineValue: _firstPassModelFromDefine,
      environment: environment,
      key: 'COLLOCATION_FIRST_PASS_MODEL',
      defaultValue: 'gpt-4.1',
    ),
    naturalnessModel: _runtimeString(
      dartDefineValue: _naturalnessModelFromDefine,
      environment: environment,
      key: 'COLLOCATION_NATURALNESS_MODEL',
      defaultValue: 'gpt-5.1',
    ),
    fixtures: _resolveFixtures(
      _runtimeString(
        dartDefineValue: _fixtureIdsFromDefine,
        environment: environment,
        key: 'COLLOCATION_FIXTURE_IDS',
        defaultValue: '',
      ),
    ),
    runsPerCase: _positiveInt(
      _runtimeString(
        dartDefineValue: _runsPerCaseFromDefine,
        environment: environment,
        key: 'COLLOCATION_RUNS_PER_CASE',
        defaultValue: '5',
      ),
      defaultValue: 5,
    ),
    outputPath: _runtimeString(
      dartDefineValue: _outputPathFromDefine,
      environment: environment,
      key: 'COLLOCATION_OUTPUT',
      defaultValue: defaultOutputPath,
    ),
    callDelayMs: _positiveInt(
      _runtimeString(
        dartDefineValue: _callDelayMsFromDefine,
        environment: environment,
        key: 'COLLOCATION_CALL_DELAY_MS',
        defaultValue: '750',
      ),
      defaultValue: 750,
      allowZero: true,
    ),
    liveOptIn:
        _liveOptInFromDefine ||
        _parseBool(environment['COLLOCATION_LIVE']),
  );
}

String _runtimeString({
  required String dartDefineValue,
  required Map<String, String> environment,
  required String key,
  required String defaultValue,
}) {
  final fromDefine = dartDefineValue.trim();
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  final fromEnvironment = environment[key]?.trim() ?? '';
  if (fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }
  return defaultValue;
}

bool _parseBool(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'y':
      return true;
    default:
      return false;
  }
}

int _positiveInt(
  String raw, {
  required int defaultValue,
  bool allowZero = false,
}) {
  final parsed = int.tryParse(raw.trim());
  if (parsed == null) {
    return defaultValue;
  }
  if (allowZero && parsed == 0) {
    return parsed;
  }
  return parsed > 0 ? parsed : defaultValue;
}

List<CollocationFixture> _resolveFixtures(String rawIds) {
  final ids = rawIds
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
  if (ids.isEmpty) {
    return List<CollocationFixture>.unmodifiable(collocationFixtures);
  }
  return List<CollocationFixture>.unmodifiable(
    ids.map((id) => collocationFixtures.firstWhere((f) => f.id == id)),
  );
}

class Usage {
  const Usage({
    required this.latencyMs,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
  });

  final int latencyMs;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
}

class FirstPassResult {
  const FirstPassResult({
    required this.validJson,
    required this.usage,
    this.correctedText,
    this.error,
  });

  final String? correctedText;
  final bool validJson;
  final Usage usage;
  final Object? error;

  bool get isError => error != null;
  bool get changed => !isError && validJson && correctedText != null;
}

class NaturalnessResult {
  const NaturalnessResult({
    required this.validJson,
    required this.hasIssue,
    required this.issues,
    required this.usage,
    this.error,
  });

  final bool validJson;
  final bool hasIssue;
  final List<NaturalnessIssue> issues;
  final Usage usage;
  final Object? error;
}

class FixtureRunResult {
  const FixtureRunResult({
    required this.fixture,
    required this.run,
    required this.firstPass,
    required this.naturalnessOnOriginal,
    required this.naturalnessOnFirstPass,
  });

  final CollocationFixture fixture;
  final int run;
  final FirstPassResult firstPass;
  final NaturalnessResult naturalnessOnOriginal;
  final NaturalnessResult? naturalnessOnFirstPass;

  bool get firstPassLeftAlone =>
      firstPass.validJson && firstPass.correctedText == fixture.text;

  bool get firstPassChanged =>
      firstPass.validJson && firstPass.correctedText != fixture.text;

  int get totalLatencyMs =>
      firstPass.usage.latencyMs +
      naturalnessOnOriginal.usage.latencyMs +
      (naturalnessOnFirstPass?.usage.latencyMs ?? 0);

  int get totalTokens =>
      (firstPass.usage.totalTokens ?? 0) +
      (naturalnessOnOriginal.usage.totalTokens ?? 0) +
      (naturalnessOnFirstPass?.usage.totalTokens ?? 0);

  double? totalCostUsd({
    required String firstPassModel,
    required String naturalnessModel,
  }) {
    final costs = [
      _costFor(firstPass.usage, firstPassModel),
      _costFor(naturalnessOnOriginal.usage, naturalnessModel),
      if (naturalnessOnFirstPass != null)
        _costFor(naturalnessOnFirstPass!.usage, naturalnessModel),
    ];
    if (costs.any((cost) => cost == null)) {
      return null;
    }
    return costs.fold<double>(0, (sum, cost) => sum + cost!);
  }
}

double? _costFor(Usage usage, String model) {
  final inputTokens = usage.inputTokens;
  final outputTokens = usage.outputTokens;
  if (inputTokens == null || outputTokens == null) {
    return null;
  }
  return pricing
      .estimateCostUsd(
        model: model,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      )
      .usd;
}

class _TrackedResult<T> {
  const _TrackedResult({
    required this.usage,
    this.value,
    this.error,
  });

  final Usage usage;
  final T? value;
  final Object? error;
}

Future<_TrackedResult<T>> _trackedCall<T>({
  required List<ChatCompletionsUsage> usageLog,
  required Future<T> Function() call,
}) async {
  final stopwatch = Stopwatch()..start();
  final start = usageLog.length;
  try {
    final value = await call();
    stopwatch.stop();
    return _TrackedResult(
      value: value,
      usage: _usageFrom(
        usageLog.sublist(start),
        stopwatch.elapsedMilliseconds,
      ),
    );
  } catch (error) {
    stopwatch.stop();
    return _TrackedResult(
      usage: _usageFrom(
        usageLog.sublist(start),
        stopwatch.elapsedMilliseconds,
      ),
      error: error,
    );
  }
}

Usage _usageFrom(List<ChatCompletionsUsage> usages, int latencyMs) {
  var inputTokens = 0;
  var outputTokens = 0;
  var totalTokens = 0;
  var sawPromptTokens = false;
  var sawCompletionTokens = false;
  var sawTotalTokens = false;
  for (final usage in usages) {
    final promptTokens = usage.promptTokens;
    if (promptTokens != null) {
      inputTokens += promptTokens;
      sawPromptTokens = true;
    }
    final completionTokens = usage.completionTokens;
    if (completionTokens != null) {
      outputTokens += completionTokens;
      sawCompletionTokens = true;
    }
    final usageTotalTokens = usage.totalTokens;
    if (usageTotalTokens != null) {
      totalTokens += usageTotalTokens;
      sawTotalTokens = true;
    }
  }
  return Usage(
    latencyMs: latencyMs,
    inputTokens: sawPromptTokens ? inputTokens : null,
    outputTokens: sawCompletionTokens ? outputTokens : null,
    totalTokens: sawTotalTokens ? totalTokens : null,
  );
}

Future<FixtureRunResult> runFixtureOnce({
  required OpenAiChatCompletionsClient client,
  required List<ChatCompletionsUsage> usageLog,
  required HarnessConfig config,
  required CollocationFixture fixture,
  required int run,
}) async {
  final firstPassCall = await _trackedCall(
    usageLog: usageLog,
    call: () => callFirstPassCorrection(
      client: client,
      model: config.firstPassModel,
      submittedText: fixture.text,
    ),
  );
  final firstPassResponse = firstPassCall.value;
  final firstPass = FirstPassResult(
    correctedText: firstPassResponse?.correctedText,
    validJson: firstPassCall.error == null && firstPassResponse != null,
    usage: firstPassCall.usage,
    error: firstPassCall.error,
  );

  final naturalnessOnOriginal = await _runNaturalnessSafely(
    client: client,
    usageLog: usageLog,
    model: config.naturalnessModel,
    text: fixture.text,
  );

  NaturalnessResult? naturalnessOnFirstPass;
  final correctedText = firstPass.correctedText;
  if (correctedText != null) {
    naturalnessOnFirstPass = await _runNaturalnessSafely(
      client: client,
      usageLog: usageLog,
      model: config.naturalnessModel,
      text: correctedText,
    );
  }

  return FixtureRunResult(
    fixture: fixture,
    run: run,
    firstPass: firstPass,
    naturalnessOnOriginal: naturalnessOnOriginal,
    naturalnessOnFirstPass: naturalnessOnFirstPass,
  );
}

Future<NaturalnessResult> _runNaturalnessSafely({
  required OpenAiChatCompletionsClient client,
  required List<ChatCompletionsUsage> usageLog,
  required String model,
  required String text,
}) async {
  final reviewCall = await _trackedCall(
    usageLog: usageLog,
    call: () => callNaturalnessReview(
      client: client,
      model: model,
      text: text,
    ),
  );
  final review = reviewCall.value;
  return NaturalnessResult(
    validJson: reviewCall.error == null && review != null,
    hasIssue: review?.hasNaturalnessIssue ?? false,
    issues: review?.issues ?? const [],
    usage: reviewCall.usage,
    error: reviewCall.error,
  );
}

String buildReport({
  required HarnessConfig config,
  required List<FixtureRunResult> results,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# Collocation Two-Pass Boundary Harness')
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- First-pass prompt: `$firstPassPromptLabel` `$firstPassPromptVersion`')
    ..writeln('- Naturalness prompt: `$naturalnessPromptLabel` `$naturalnessPromptVersion`')
    ..writeln('- First-pass model: `${config.firstPassModel}`')
    ..writeln('- Naturalness model: `${config.naturalnessModel}`')
    ..writeln('- Fixtures: `${config.fixtures.length}`')
    ..writeln('- Runs per fixture: `${config.runsPerCase}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(pricing.pricingSection([
      config.firstPassModel,
      config.naturalnessModel,
    ]));

  final totalRuns = results.length;
  final leftAlone = results.where((r) => r.firstPassLeftAlone).length;
  final changed = results.where((r) => r.firstPassChanged).length;
  final invalidOrError = totalRuns - leftAlone - changed;
  final totalLatency = results.fold<int>(0, (sum, r) => sum + r.totalLatencyMs);
  final totalTokens = results.fold<int>(0, (sum, r) => sum + r.totalTokens);
  final costs = [
    for (final result in results)
      result.totalCostUsd(
        firstPassModel: config.firstPassModel,
        naturalnessModel: config.naturalnessModel,
      ),
  ];
  final totalCost = costs.any((cost) => cost == null)
      ? null
      : costs.fold<double>(0, (sum, cost) => sum + cost!);

  buffer
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln(
      '| Runs | First pass left alone | First pass changed | Invalid/error | '
      'Total latency (ms) | Total tokens | Total est. cost (USD) |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |')
    ..writeln(
      '| $totalRuns | ${_rate(leftAlone, totalRuns)} | ${_rate(changed, totalRuns)} | '
      '${_rate(invalidOrError, totalRuns)} | $totalLatency | $totalTokens | '
      '${_formatCost(totalCost)} |',
    )
    ..writeln();

  buffer
    ..writeln('## Fixture summary')
    ..writeln()
    ..writeln(
      '| Fixture | Problem phrase | Expected natural phrase | First pass left alone | '
      'First pass changed | Naturalness on original flagged | Naturalness on first-pass flagged | '
      'Distinct first-pass outputs |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');

  for (final fixture in config.fixtures) {
    final fixtureResults = results.where((r) => r.fixture.id == fixture.id).toList();
    final firstPassOutputs = {
      for (final result in fixtureResults)
        if (result.firstPass.correctedText != null) result.firstPass.correctedText!,
    };
    buffer.writeln(
      '| `${fixture.id}` | `${fixture.problemPhrase}` | `${fixture.naturalReplacement}` | '
      '${_rate(fixtureResults.where((r) => r.firstPassLeftAlone).length, fixtureResults.length)} | '
      '${_rate(fixtureResults.where((r) => r.firstPassChanged).length, fixtureResults.length)} | '
      '${_rate(fixtureResults.where((r) => r.naturalnessOnOriginal.hasIssue).length, fixtureResults.length)} | '
      '${_rate(fixtureResults.where((r) => r.naturalnessOnFirstPass?.hasIssue ?? false).length, fixtureResults.length)} | '
      '${_markdownCell(firstPassOutputs.map((text) => '`$text`').join('<br>'))} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Individual runs')
    ..writeln()
    ..writeln(
      '| Fixture | Run | Input | First-pass output | First-pass result | '
      'Naturalness on original | Naturalness on first-pass output | Latency (ms) | Tokens | Cost |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |');

  for (final result in results) {
    final firstPassLabel = result.firstPassLeftAlone
        ? 'left alone'
        : result.firstPassChanged
            ? 'changed'
            : 'invalid/error';
    buffer.writeln(
      '| `${result.fixture.id}` | ${result.run} | `${result.fixture.text}` | '
      '`${result.firstPass.correctedText ?? '(none)'}` | $firstPassLabel | '
      '${_markdownCell(_describeNaturalness(result.naturalnessOnOriginal))} | '
      '${_markdownCell(_describeNaturalness(result.naturalnessOnFirstPass))} | '
      '${result.totalLatencyMs} | ${result.totalTokens} | '
      '${_formatCost(result.totalCostUsd(firstPassModel: config.firstPassModel, naturalnessModel: config.naturalnessModel))} |',
    );
  }

  return buffer.toString();
}

String _describeNaturalness(NaturalnessResult? result) {
  if (result == null) {
    return '(not run)';
  }
  if (result.error != null) {
    return 'ERROR: ${result.error}';
  }
  if (!result.validJson) {
    return 'invalid JSON';
  }
  if (!result.hasIssue || result.issues.isEmpty) {
    return '(none)';
  }
  return result.issues
      .map((issue) => '${issue.span} -> ${issue.naturalReplacement}')
      .join('<br>');
}

String _rate(int count, int total) {
  if (total == 0) {
    return '0.0% (0/0)';
  }
  return '${(count / total * 100).toStringAsFixed(1)}% ($count/$total)';
}

String _formatCost(double? value) {
  return value == null ? 'unknown' : '\$${value.toStringAsFixed(6)}';
}

String _markdownCell(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', '<br>');
}

void main() {
  group('offline sanity', () {
    test('fixture ids are unique and there are ten fixtures', () {
      final ids = collocationFixtures.map((fixture) => fixture.id).toSet();
      expect(ids.length, collocationFixtures.length);
      expect(collocationFixtures, hasLength(10));
    });

    test('default config uses gpt-4.1, gpt-5.1, and five runs', () {
      final config = buildConfig(const {});
      expect(config.firstPassModel, 'gpt-4.1');
      expect(config.naturalnessModel, 'gpt-5.1');
      expect(config.runsPerCase, 5);
      expect(config.fixtures, hasLength(10));
      expect(config.outputPath, defaultOutputPath);
    });

    test('usage aggregation keeps live client token accounting', () {
      final usage = _usageFrom(
        const [
          ChatCompletionsUsage(
            stageLabel: 'first_pass_correction',
            model: 'gpt-4.1',
            latencyMs: 50,
            promptTokens: 100,
            completionTokens: 20,
            totalTokens: 120,
          ),
          ChatCompletionsUsage(
            stageLabel: 'first_pass_correction',
            model: 'gpt-4.1',
            latencyMs: 60,
            promptTokens: 80,
            completionTokens: 10,
            totalTokens: 90,
          ),
        ],
        75,
      );

      expect(usage.latencyMs, 75);
      expect(usage.inputTokens, 180);
      expect(usage.outputTokens, 30);
      expect(usage.totalTokens, 210);
    });

    test('buildReport separates first-pass boundary from naturalness observation', () {
      final fixture = collocationFixtures.first;
      final report = buildReport(
        config: HarnessConfig(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          fixtures: [fixture],
          runsPerCase: 1,
          outputPath: defaultOutputPath,
          callDelayMs: 0,
          liveOptIn: false,
        ),
        results: [
          FixtureRunResult(
            fixture: fixture,
            run: 1,
            firstPass: FirstPassResult(
              correctedText: fixture.text,
              validJson: true,
              usage: const Usage(latencyMs: 10, totalTokens: 10),
            ),
            naturalnessOnOriginal: const NaturalnessResult(
              validJson: true,
              hasIssue: false,
              issues: [],
              usage: Usage(latencyMs: 20, totalTokens: 20),
            ),
            naturalnessOnFirstPass: const NaturalnessResult(
              validJson: true,
              hasIssue: false,
              issues: [],
              usage: Usage(latencyMs: 30, totalTokens: 30),
            ),
          ),
        ],
        generatedAt: DateTime.utc(2026, 1, 1),
      );

      expect(report, contains('First pass left alone'));
      expect(report, contains('Naturalness on original flagged'));
      expect(report, contains('100.0% (1/1)'));
    });
  });

  test(
    'live collocation two-pass boundary run',
    () async {
      final config = buildConfig(Platform.environment);
      if (!config.liveOptIn) {
        return;
      }

      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail('Set OPENAI_API_KEY before running the live harness.');
      }

      final httpClient = HttpClient();
      final usageLog = <ChatCompletionsUsage>[];
      final client = OpenAiChatCompletionsClient(
        apiKey: apiKey,
        httpClient: httpClient,
        onUsage: usageLog.add,
      );
      final results = <FixtureRunResult>[];
      try {
        for (final fixture in config.fixtures) {
          for (var run = 1; run <= config.runsPerCase; run++) {
            final result = await runFixtureOnce(
              client: client,
              usageLog: usageLog,
              config: config,
              fixture: fixture,
              run: run,
            );
            results.add(result);
            if (config.callDelayMs > 0) {
              await Future<void>.delayed(
                Duration(milliseconds: config.callDelayMs),
              );
            }
          }
        }
      } finally {
        httpClient.close(force: true);
      }

      final report = buildReport(
        config: config,
        results: results,
        generatedAt: DateTime.now(),
      );
      final output = File(config.outputPath);
      output.parent.createSync(recursive: true);
      output.writeAsStringSync(report);
    },
    tags: ['live'],
    timeout: Timeout.none,
  );
}
