// Model comparison harness for the narrow Spanish grammar/spelling/
// punctuation correction task (issue: "Create a model comparison harness
// for Spanish grammar, spelling, and punctuation correction").
//
// Purpose: compare different OpenAI models on ONE narrow task — objective
// Spanish grammar, spelling, and punctuation correction only — using the
// exact same system prompt, user prompt, and JSON response contract for
// every model. This is a pure API/prompt-contract harness: it does NOT
// solve production span generation, `has_errors`/failure classification,
// diff spans, or any UI integration. Those are explicitly out of scope
// per the issue and are handled elsewhere.
//
// The ONLY model-generated correction field is `corrected_text` — no
// categories, explanations, spans, error counts, confidence scores, or
// alternative rewrites. The model must not correct word choice,
// naturalness, style, fluency, tone, elegance, valid regional Spanish, or
// awkward-but-grammatically-valid Spanish.
//
// STANDALONE, like every other harness in this repo: does not import
// PromptBuilder, CorrectionService, OpenAiCorrectionService, AppConfig, or
// any other `lib/` code (other than the app's package name in the
// `flutter_test` import path, which is not used). Auth reads
// OPENAI_API_KEY from Platform.environment ONLY, no hardcoded fallback.
//
// Targets the classic chat completions endpoint (/v1/chat/completions,
// `choices[0].message.content`), the same endpoint every other harness in
// this repo uses. The required `{"corrected_text": "string"}` contract is
// enforced through `response_format: json_schema`, so the prompt wording can
// stay exactly as specified in the issue while every model still receives the
// same response contract.
//
// Per-response data recorded (see `_ModelCaseResult`): model name, prompt
// version, input text, raw model response, parsed corrected text (where
// available), whether the response was valid per the JSON contract,
// latency in milliseconds, input/output/total tokens, and estimated cost
// in USD. This is what makes the models comparable side by side.
//
// Battery: a small, fixed first-pass subset from
// `test/shared/benchmark_fixtures.dart`, covering objective grammar/spelling/
// punctuation correction cases plus controls the model should leave untouched:
// regional/dialectal Spanish, CALCS-style natural language, word-choice/
// naturalness quirks, already-correct text, and accent-sensitive text across
// short, paragraph, two-paragraph, and near-limit input bands.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/model_comparison_harness.dart --exclude-tags live
//
// Run the live comparison deliberately (costs real API calls). The live run
// is skipped unless MODEL_COMPARISON_LIVE is explicitly true, and the model
// list must be supplied at runtime so candidate names are not treated as
// confirmed OpenAI API model IDs by this harness:
//
//   OPENAI_API_KEY=sk-... \
//   MODEL_COMPARISON_LIVE=true \
//   COMPARISON_MODELS=gpt-5.4,gpt-5.3-chat-latest,gpt-4.1 \
//   flutter test test/model_comparison_harness.dart --tags live --timeout none
//
// The same configuration can be passed with --dart-define:
//
//   flutter test test/model_comparison_harness.dart \
//     --tags live \
//     --timeout none \
//     --dart-define=MODEL_COMPARISON_LIVE=true \
//     --dart-define=COMPARISON_MODELS=gpt-5.4,gpt-5.3-chat-latest,gpt-4.1 \
//     --dart-define=MODEL_COMPARISON_FIXTURE_IDS=short-phrase-missing-accent,sentence-grammar-agreement
//
// `COMPARISON_MODELS` is comma-separated and must contain exact OpenAI API
// model IDs available to the account running the harness. If GPT-5.4,
// GPT-5.3 Chat, and GPT-4.1 are the intended candidates, pass exact API
// ids such as `gpt-5.4`, `gpt-5.3-chat-latest`, and `gpt-4.1` explicitly
// there rather than editing this file. Plain display labels such as
// `gpt-5.3` intentionally remain unpriced unless OpenAI documents them as
// exact API model ids.
//
// `MODEL_COMPARISON_FIXTURE_IDS` is optional and comma-separated. When omitted,
// the harness uses the documented `firstPassModelComparisonFixtures` subset
// from `test/shared/benchmark_fixtures.dart`. Override the output path with
// `MODEL_COMPARISON_OUTPUT` (default docs/model_comparison_harness.md).
//
// USD cost estimation uses the shared `test/shared/model_pricing.dart`
// helpers (see spanish_correction_app#6): a model only gets a dollar
// figure once a maintainer has verified its pricing against an explicit
// source and added an entry to `verifiedPricingPerModel` there, with that
// source, pricing version/effective date, and date-checked recorded
// alongside the number. Models missing from `verifiedPricingPerModel` show
// as `unknown` intentionally, not as an omission, while token usage and
// latency are still recorded either way. Do not reintroduce a local
// placeholder pricing table here.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'shared/benchmark_fixtures.dart';
import 'shared/model_pricing.dart' as pricing;

/// Identifies which version of the prompt/contract produced a result.
/// Bump this if the system prompt or user prompt template below ever
/// changes, so historical reports stay attributable to the wording that
/// produced them.
const String promptVersion = 'v1';

/// Human-readable label for this narrow first-pass prompt. This is metadata
/// only; changing it does not change prompt wording.
const String promptLabel = 'simple-spanish-grammar-spelling-punctuation-only';

/// Exact wording from the issue — the same system prompt every model in
/// the comparison receives. Deliberately not reworded or reformatted.
const String systemPrompt =
    'You are a Spanish correction engine.\n'
    '\n'
    'Correct only objective Spanish grammar, spelling, and punctuation '
    'errors.\n'
    '\n'
    'Do not correct word choice.\n'
    'Do not improve naturalness.\n'
    'Do not rewrite for style, fluency, tone, or elegance.\n'
    'Do not change valid regional Spanish.\n'
    'Do not treat awkward but grammatically valid Spanish as an error.\n'
    '\n'
    'Return JSON only. Do not include Markdown or commentary.';

/// Builds the exact user prompt wording from the issue for [inputText].
String buildUserPrompt(String inputText) {
  return 'Correct the following Spanish text for grammar, spelling, and '
      'punctuation only.\n'
      '\n'
      'Text:\n'
      '$inputText';
}

/// Models compared in the live run, read from --dart-define=COMPARISON_MODELS
/// or the COMPARISON_MODELS environment variable (comma-separated).
/// Everything else about the request is identical across models — same
/// system prompt, same user prompt, same JSON contract — so this list is the
/// only request field that varies.
const String _rawComparisonModelsFromDefine = String.fromEnvironment(
  'COMPARISON_MODELS',
  defaultValue: '',
);

List<String> get comparisonModels =>
    _configuredComparisonModels(Platform.environment);

const String _rawFixtureIdsFromDefine = String.fromEnvironment(
  'MODEL_COMPARISON_FIXTURE_IDS',
  defaultValue: '',
);

const String _outputPathFromDefine = String.fromEnvironment(
  'MODEL_COMPARISON_OUTPUT',
  defaultValue: '',
);

const String defaultOutputPath = 'docs/model_comparison_harness.md';

String get outputPath => _runtimeString(
  dartDefineValue: _outputPathFromDefine,
  environment: Platform.environment,
  key: 'MODEL_COMPARISON_OUTPUT',
  defaultValue: defaultOutputPath,
);

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'MODEL_COMPARISON_LIVE',
  defaultValue: false,
);

const Map<String, Object?> correctedTextResponseFormat = {
  'type': 'json_schema',
  'json_schema': {
    'name': 'spanish_correction_response',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['corrected_text'],
      'properties': {
        'corrected_text': {'type': 'string'},
      },
    },
  },
};

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'MODEL_COMPARISON_CALL_DELAY_MS',
  defaultValue: 750,
);

/// Estimated cost in USD for one call, or `null` unless `model` has a
/// verified entry in `pricing.verifiedPricingPerModel` — see the file
/// header and `test/shared/model_pricing.dart`.
double? estimateCostUsd({
  required String model,
  required int inputTokens,
  required int outputTokens,
}) {
  return pricing
      .estimateCostUsd(
        model: model,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
      )
      .usd;
}

/// The model-comparison battery is a deliberately small subset of the shared
/// benchmark fixtures, not a harness-local ad hoc fixture list.
const List<BenchmarkFixture> _cases = firstPassModelComparisonFixtures;

/// Harness-local expected outputs for exact first-pass result scoring.
///
/// The shared benchmark fixtures intentionally stay prompt/report agnostic;
/// expected output lives here because this harness owns the narrow
/// grammar/spelling/punctuation-only interpretation. Control fixtures are
/// included explicitly with unchanged text so over-corrections can be counted.
final Map<String, String> _firstPassExpectedCorrectedText = Map.unmodifiable({
  'short-phrase-missing-accent': 'Voy al parque mañana por la tarde.',
  'sentence-grammar-agreement': 'Los niños comen muchas manzanas en el jardín.',
  'sentence-punctuation-question':
      '¿Cómo estás hoy? Necesito saber si vienes a la fiesta.',
  'sentence-correct-voseo': sentenceCorrectVoseo.text,
  'sentence-regional-word-choice': sentenceRegionalWordChoice.text,
  'paragraph-calcs-natural': paragraphCalcsNatural.text,
  'paragraph-mixed-errors':
      'Ayer fui a la tienda y compré pan, leche y unas manzanas. Cuando '
      'llegué a casa, mi hermano me preguntó si quería ayudarlo con la '
      'tarea, pero yo estaba muy cansado después del trabajo.',
  'two-paragraph-already-correct': twoParagraphAlreadyCorrect.text,
  'near-limit-full-text':
      'El fin de semana pasado decidimos hacer un viaje corto a la montaña '
      'para descansar del trabajo y de la ciudad. Salimos muy temprano, antes '
      'de que saliera el sol, y llegamos al pequeño pueblo justo a tiempo para '
      'desayunar en un café que mi hermano había recomendado. Durante la tarde '
      'caminamos por un sendero cerca del río, sacamos muchas fotos y hablamos '
      'de nuestros planes para el próximo año. Cuando volvimos al hotel, todos '
      'estábamos muy cansados pero contentos, y decidimos que teníamos que '
      'regresar pronto porque el lugar nos había gustado mucho a todos.',
});

List<String> _parseCommaSeparatedValues(String raw) {
  return raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
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

List<String> _configuredComparisonModels(Map<String, String> environment) {
  return _parseCommaSeparatedValues(
    _runtimeString(
      dartDefineValue: _rawComparisonModelsFromDefine,
      environment: environment,
      key: 'COMPARISON_MODELS',
      defaultValue: '',
    ),
  );
}

String _configuredOutputPath(Map<String, String> environment) {
  return _runtimeString(
    dartDefineValue: _outputPathFromDefine,
    environment: environment,
    key: 'MODEL_COMPARISON_OUTPUT',
    defaultValue: defaultOutputPath,
  );
}

List<BenchmarkFixture> _configuredFixtureSubset(
  Map<String, String> environment,
) {
  final rawFixtureIds = _runtimeString(
    dartDefineValue: _rawFixtureIdsFromDefine,
    environment: environment,
    key: 'MODEL_COMPARISON_FIXTURE_IDS',
    defaultValue: '',
  );
  return _resolveFixtureSubset(rawFixtureIds, defaultCases: _cases);
}

List<BenchmarkFixture> _resolveFixtureSubset(
  String rawFixtureIds, {
  required List<BenchmarkFixture> defaultCases,
}) {
  final ids = _parseCommaSeparatedValues(rawFixtureIds);
  if (ids.isEmpty) {
    return List<BenchmarkFixture>.unmodifiable(defaultCases);
  }

  return List<BenchmarkFixture>.unmodifiable(ids.map(benchmarkFixtureById));
}

bool _parseBooleanOptIn(String? value) {
  switch (value?.trim().toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'y':
      return true;
    default:
      return false;
  }
}

bool _hasLiveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      _parseBooleanOptIn(environment['MODEL_COMPARISON_LIVE']);
}

class _LiveRunConfig {
  const _LiveRunConfig({
    required this.models,
    required this.cases,
    required this.outputPath,
    required this.liveRunOptIn,
  });

  final List<String> models;
  final List<BenchmarkFixture> cases;
  final String outputPath;
  final bool liveRunOptIn;

  List<String> get caseIds => cases.map((testCase) => testCase.id).toList();
}

_LiveRunConfig _buildLiveRunConfig(Map<String, String> environment) {
  return _LiveRunConfig(
    models: _configuredComparisonModels(environment),
    cases: _configuredFixtureSubset(environment),
    outputPath: _configuredOutputPath(environment),
    liveRunOptIn: _hasLiveRunOptIn(environment),
  );
}

String? _liveRunConfigError(_LiveRunConfig config) {
  if (config.models.isEmpty) {
    return 'Set COMPARISON_MODELS to a comma-separated list of exact OpenAI '
        'API model IDs before opting into the live comparison run.';
  }
  if (config.cases.isEmpty) {
    return 'The live comparison run needs at least one fixture case.';
  }
  return null;
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. `response_format: json_schema` enforces the exact
/// `{"corrected_text": "string"}` contract at the API level rather than
/// relying solely on the prompt.
Map<String, Object?> buildChatCompletionsBody({
  required String model,
  required String systemPromptText,
  required String userText,
}) {
  return {
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPromptText},
      {'role': 'user', 'content': userText},
    ],
    'response_format': correctedTextResponseFormat,
  };
}

/// Extracts the assistant's reply text from a decoded chat completions
/// response body: `choices[0].message.content`, trimmed.
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

/// Result of parsing one raw reply against the required
/// `{"corrected_text": "string"}` contract.
class _ParsedResponse {
  const _ParsedResponse({required this.validJson, this.correctedText});

  /// True only when the reply decodes as a JSON object whose only field is
  /// `corrected_text`, and that field is a string — the exact required shape.
  final bool validJson;

  /// The parsed `corrected_text` value, if [validJson] is true.
  final String? correctedText;
}

/// Parses [replyText] against the required JSON contract. Tolerates a
/// Markdown code fence around the JSON object even though the prompt asks
/// the model not to include one, since real models sometimes add one
/// anyway and this harness is measuring JSON reliability, not punishing a
/// recoverable formatting slip.
_ParsedResponse _parseCorrectedTextResponse(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    return const _ParsedResponse(validJson: false);
  }

  Object? decoded;
  try {
    decoded = jsonDecode(trimmed.substring(start, end + 1));
  } on FormatException {
    return const _ParsedResponse(validJson: false);
  }

  if (decoded is! Map<String, Object?>) {
    return const _ParsedResponse(validJson: false);
  }

  if (decoded.length != 1 || !decoded.containsKey('corrected_text')) {
    return const _ParsedResponse(validJson: false);
  }

  final correctedText = decoded['corrected_text'];
  if (correctedText is! String) {
    return const _ParsedResponse(validJson: false);
  }

  return _ParsedResponse(validJson: true, correctedText: correctedText);
}

/// Full per-response record for one model, one case, one call. A failed
/// call (network/timeout/HTTP error) is recorded via [error] rather than
/// dropped, same as the other harnesses.
class _ModelCaseResult {
  const _ModelCaseResult({
    required this.model,
    required this.promptVersion,
    required this.caseId,
    required this.inputText,
    required this.validJson,
    required this.latencyMs,
    this.rawResponse,
    this.correctedText,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.estimatedCostUsd,
    this.error,
  });

  final String model;
  final String promptVersion;
  final String caseId;
  final String inputText;
  final bool validJson;
  final int latencyMs;
  final String? rawResponse;
  final String? correctedText;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final double? estimatedCostUsd;
  final Object? error;

  bool get isError => error != null;
}

enum _ReviewStatus {
  expectedCorrection('expected_correction'),
  missedCorrection('missed_correction'),
  unexpectedCorrection('unexpected_correction'),
  unchangedControl('unchanged_control'),
  overCorrection('over_correction'),
  invalidJson('invalid_json'),
  error('error'),
  unscored('unscored');

  const _ReviewStatus(this.reportLabel);

  final String reportLabel;

  bool get isTaskSuccess =>
      this == _ReviewStatus.expectedCorrection ||
      this == _ReviewStatus.unchangedControl;
}

_ReviewStatus _classifyFirstPassOutput({
  required BenchmarkFixtureKind kind,
  required String inputText,
  required String? expectedCorrectedText,
  required bool validJson,
  required String? correctedText,
  required bool isError,
}) {
  if (isError) {
    return _ReviewStatus.error;
  }
  if (!validJson || correctedText == null) {
    return _ReviewStatus.invalidJson;
  }
  if (expectedCorrectedText == null) {
    return _ReviewStatus.unscored;
  }

  if (kind == BenchmarkFixtureKind.control) {
    return correctedText == expectedCorrectedText
        ? _ReviewStatus.unchangedControl
        : _ReviewStatus.overCorrection;
  }

  if (correctedText == expectedCorrectedText) {
    return _ReviewStatus.expectedCorrection;
  }
  if (correctedText == inputText) {
    return _ReviewStatus.missedCorrection;
  }
  return _ReviewStatus.unexpectedCorrection;
}

_ReviewStatus _reviewStatusFor(
  BenchmarkFixture testCase,
  _ModelCaseResult result,
) {
  return _classifyFirstPassOutput(
    kind: testCase.kind,
    inputText: testCase.text,
    expectedCorrectedText: _firstPassExpectedCorrectedText[testCase.id],
    validJson: result.validJson,
    correctedText: result.correctedText,
    isError: result.isError,
  );
}

_ModelCaseResult _successResult({
  required String model,
  required String caseId,
  required String inputText,
  required String rawResponse,
  required _ParsedResponse parsed,
  required int latencyMs,
  int? inputTokens,
  int? outputTokens,
  int? totalTokens,
}) {
  final estimatedCost = (inputTokens != null && outputTokens != null)
      ? estimateCostUsd(
          model: model,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        )
      : null;

  return _ModelCaseResult(
    model: model,
    promptVersion: promptVersion,
    caseId: caseId,
    inputText: inputText,
    rawResponse: rawResponse,
    correctedText: parsed.correctedText,
    validJson: parsed.validJson,
    latencyMs: latencyMs,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    totalTokens: totalTokens,
    estimatedCostUsd: estimatedCost,
  );
}

_ModelCaseResult _errorResult({
  required String model,
  required String caseId,
  required String inputText,
  required int latencyMs,
  required Object error,
}) {
  return _ModelCaseResult(
    model: model,
    promptVersion: promptVersion,
    caseId: caseId,
    inputText: inputText,
    validJson: false,
    latencyMs: latencyMs,
    error: error,
  );
}

/// Calls `/v1/chat/completions` for [model]/[testCase] and returns the full
/// [_ModelCaseResult], timing the call with a [Stopwatch] and pulling
/// token counts from OpenAI's standard `usage` object
/// (`prompt_tokens`/`completion_tokens`/`total_tokens`).
Future<_ModelCaseResult> _runOnce({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required BenchmarkFixture testCase,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
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
            systemPromptText: systemPrompt,
            userText: buildUserPrompt(testCase.text),
          ),
        ),
      ),
    );

    final response = await request.close().timeout(const Duration(seconds: 30));
    final body = await utf8.decodeStream(response);
    stopwatch.stop();

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

    final replyText = extractReplyText(decoded);
    final parsed = _parseCorrectedTextResponse(replyText);

    final usage = decoded['usage'];
    int? inputTokens;
    int? outputTokens;
    int? totalTokens;
    if (usage is Map<String, Object?>) {
      inputTokens = (usage['prompt_tokens'] as num?)?.toInt();
      outputTokens = (usage['completion_tokens'] as num?)?.toInt();
      totalTokens = (usage['total_tokens'] as num?)?.toInt();
    }

    return _successResult(
      model: model,
      caseId: testCase.id,
      inputText: testCase.text,
      rawResponse: replyText,
      parsed: parsed,
      latencyMs: stopwatch.elapsedMilliseconds,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
    );
  } catch (error) {
    stopwatch.stop();
    return _errorResult(
      model: model,
      caseId: testCase.id,
      inputText: testCase.text,
      latencyMs: stopwatch.elapsedMilliseconds,
      error: error,
    );
  }
}

String _describeResult(_ModelCaseResult result) {
  if (result.isError) {
    return 'ERROR — ${result.error}';
  }
  final corrected = result.correctedText ?? '(no corrected_text parsed)';
  final tokens = result.totalTokens != null
      ? '${result.inputTokens}/${result.outputTokens}/${result.totalTokens}'
      : 'unknown';
  final cost = result.estimatedCostUsd != null
      ? 'verified \$${result.estimatedCostUsd!.toStringAsFixed(6)}'
      : 'unknown (pricing unavailable/unverified)';
  return 'valid_json=${result.validJson} latency_ms=${result.latencyMs} '
      'tokens(in/out/total)=$tokens cost_usd=$cost '
      'corrected_text="$corrected"';
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

String _gitBranch() {
  try {
    final result = Process.runSync('git', [
      'rev-parse',
      '--abbrev-ref',
      'HEAD',
    ]);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

String _markdownTableCell(String value) {
  return value
      .replaceAll('|', r'\|')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', '<br>');
}

String _formatCostForReport(double? cost) {
  if (cost == null) {
    return 'unknown (pricing unavailable/unverified)';
  }
  return 'verified ${cost.toStringAsFixed(6)}';
}

/// Builds the full markdown comparison report: one section per case with a
/// table comparing every model's result, then an overall per-model summary
/// table (valid JSON rate, average latency, total tokens, total estimated
/// cost). Pure — takes already-collected [resultsByCaseThenModel] rather
/// than making any calls itself, golden-testable against synthetic data.
String _buildReport({
  required List<String> models,
  required DateTime generatedAt,
  required List<BenchmarkFixture> cases,
  required Map<String, Map<String, _ModelCaseResult>> resultsByCaseThenModel,
  String? branch,
  String? commit,
}) {
  final generatedAtUtc = generatedAt.toUtc();
  final caseIds = cases.map((testCase) => testCase.id).toList();
  final report = StringBuffer()
    ..writeln('# Spanish Correction Model Comparison Harness')
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- Prompt label: `$promptLabel`')
    ..writeln('- Prompt version: `$promptVersion`')
    ..writeln('- Models: ${models.map((m) => '`$m`').join(', ')}')
    ..writeln('- Fixture case ids: ${caseIds.map((id) => '`$id`').join(', ')}')
    ..writeln('- Generated: ${generatedAtUtc.toIso8601String()}');
  if (branch != null) {
    report.writeln('- Git branch: `$branch`');
  }
  if (commit != null) {
    report.writeln('- Git commit: `$commit`');
  }
  report
    ..writeln(
      '- Cost status: `unknown` unless verified pricing exists in '
      '`test/shared/model_pricing.dart`',
    )
    ..writeln()
    ..write(pricing.pricingSection(models))
    ..writeln();

  for (final testCase in cases) {
    final resultsByModel = resultsByCaseThenModel[testCase.id] ?? const {};

    report
      ..writeln('## ${testCase.id}')
      ..writeln()
      ..writeln('- Input text: `${testCase.text}`')
      ..writeln('- Note: ${testCase.note}')
      ..writeln(
        '- Expected corrected_text: '
        '`${_firstPassExpectedCorrectedText[testCase.id] ?? '(unscored)'}`',
      )
      ..writeln()
      ..writeln(
        '| Model | Valid JSON | Review status | Latency (ms) | '
        'Tokens (in/out/total) | Est. cost (USD) | corrected_text | '
        'raw_response |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');

    for (final model in models) {
      final result = resultsByModel[model];
      if (result == null) {
        report.writeln('| $model | (no result) | | | | | | |');
        continue;
      }
      final status = _reviewStatusFor(testCase, result).reportLabel;
      if (result.isError) {
        report.writeln(
          '| $model | ERROR | $status | ${result.latencyMs} | | | | '
          '${_markdownTableCell(result.error.toString())} |',
        );
        continue;
      }
      final tokens = result.totalTokens != null
          ? '${result.inputTokens}/${result.outputTokens}/${result.totalTokens}'
          : 'unknown';
      final cost = _formatCostForReport(result.estimatedCostUsd);
      final corrected = _markdownTableCell(
        result.correctedText ?? '(unparsed)',
      );
      final rawResponse = _markdownTableCell(result.rawResponse ?? '(missing)');
      report.writeln(
        '| $model | ${result.validJson} | $status | ${result.latencyMs} | '
        '$tokens | $cost | $corrected | $rawResponse |',
      );
    }
    report.writeln();
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln(
      '| Model | Cases | Valid JSON rate | Task success rate | '
      'Expected corrections | Missed fixes | Controls unchanged | '
      'Over-corrections | Unexpected outputs | Avg latency (ms) | '
      'Total tokens | Total est. cost (USD) |',
    )
    ..writeln(
      '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
    );

  for (final model in models) {
    var caseCount = 0;
    var validJsonCount = 0;
    var scoredCount = 0;
    var taskSuccessCount = 0;
    var expectedCorrectionCount = 0;
    var correctionCaseCount = 0;
    var missedCorrectionCount = 0;
    var unchangedControlCount = 0;
    var controlCaseCount = 0;
    var overCorrectionCount = 0;
    var unexpectedCorrectionCount = 0;
    var latencySum = 0;
    var latencyCount = 0;
    var totalTokens = 0;
    var totalCost = 0.0;
    var hasCost = false;

    for (final testCase in cases) {
      final result = resultsByCaseThenModel[testCase.id]?[model];
      if (result == null) {
        continue;
      }
      caseCount++;
      if (result.validJson) {
        validJsonCount++;
      }
      final status = _reviewStatusFor(testCase, result);
      final hasExpectedOutput = _firstPassExpectedCorrectedText.containsKey(
        testCase.id,
      );
      if (hasExpectedOutput) {
        scoredCount++;
      }
      if (hasExpectedOutput && status.isTaskSuccess) {
        taskSuccessCount++;
      }
      if (hasExpectedOutput && testCase.isCorrectionCase) {
        correctionCaseCount++;
      }
      if (hasExpectedOutput && testCase.isControlCase) {
        controlCaseCount++;
      }
      switch (status) {
        case _ReviewStatus.expectedCorrection:
          expectedCorrectionCount++;
        case _ReviewStatus.missedCorrection:
          missedCorrectionCount++;
        case _ReviewStatus.unexpectedCorrection:
          unexpectedCorrectionCount++;
        case _ReviewStatus.unchangedControl:
          unchangedControlCount++;
        case _ReviewStatus.overCorrection:
          overCorrectionCount++;
        case _ReviewStatus.invalidJson:
        case _ReviewStatus.error:
        case _ReviewStatus.unscored:
          break;
      }
      if (!result.isError) {
        latencySum += result.latencyMs;
        latencyCount++;
      }
      if (result.totalTokens != null) {
        totalTokens += result.totalTokens!;
      }
      if (result.estimatedCostUsd != null) {
        totalCost += result.estimatedCostUsd!;
        hasCost = true;
      }
    }

    final validJsonRate = caseCount == 0
        ? '0.0% (0/0)'
        : '${(validJsonCount / caseCount * 100).toStringAsFixed(1)}% '
              '($validJsonCount/$caseCount)';
    final taskSuccessRate = _formatRate(taskSuccessCount, scoredCount);
    final expectedCorrectionRate = _formatRate(
      expectedCorrectionCount,
      correctionCaseCount,
    );
    final missedCorrectionRate = _formatRate(
      missedCorrectionCount,
      correctionCaseCount,
    );
    final unchangedControlRate = _formatRate(
      unchangedControlCount,
      controlCaseCount,
    );
    final overCorrectionRate = _formatRate(
      overCorrectionCount,
      controlCaseCount,
    );
    final avgLatency = latencyCount == 0
        ? 'n/a'
        : (latencySum / latencyCount).toStringAsFixed(1);
    final costLabel = hasCost
        ? _formatCostForReport(totalCost)
        : _formatCostForReport(null);

    report.writeln(
      '| $model | $caseCount | $validJsonRate | $taskSuccessRate | '
      '$expectedCorrectionRate | $missedCorrectionRate | '
      '$unchangedControlRate | $overCorrectionRate | '
      '$unexpectedCorrectionCount | $avgLatency | $totalTokens | '
      '$costLabel |',
    );
  }

  return report.toString();
}

String _formatRate(int numerator, int denominator) {
  if (denominator == 0) {
    return '0.0% (0/0)';
  }
  return '${(numerator / denominator * 100).toStringAsFixed(1)}% '
      '($numerator/$denominator)';
}

void main() {
  test('battery uses the shared first-pass benchmark fixture subset', () {
    expect(_cases, same(firstPassModelComparisonFixtures));
  });

  test('battery cases are well-formed and cover the required scenarios', () {
    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(testCase.text.trim(), isNotEmpty, reason: testCase.id);
      expect(testCase.note.trim(), isNotEmpty, reason: testCase.id);
      expect(
        testCase.text.length,
        lessThanOrEqualTo(appCharacterLimit),
        reason: testCase.id,
      );
    }

    final bands = _cases.map((c) => c.lengthBand).toSet();
    expect(
      bands,
      containsAll(<BenchmarkLengthBand>[
        BenchmarkLengthBand.shortPhrase,
        BenchmarkLengthBand.paragraph,
        BenchmarkLengthBand.twoParagraph,
        BenchmarkLengthBand.nearLimit,
      ]),
    );
    expect(_cases.where((c) => c.isCorrectionCase), isNotEmpty);
    expect(_cases.where((c) => c.isControlCase), isNotEmpty);
    expect(_cases.where((c) => c.isCalcsStyle), isNotEmpty);
    expect(_cases.where((c) => c.isAccentSensitive), isNotEmpty);
    expect(
      _cases.where((c) => c.isControlCase && c.isValidRegionalSpanish),
      isNotEmpty,
    );
  });

  test('first-pass expected outputs cover every harness fixture', () {
    expect(
      _firstPassExpectedCorrectedText.keys.toSet(),
      _cases.map((testCase) => testCase.id).toSet(),
    );

    for (final testCase in _cases) {
      final expected = _firstPassExpectedCorrectedText[testCase.id];
      expect(expected, isNotNull, reason: testCase.id);
      if (testCase.isControlCase) {
        expect(expected, testCase.text, reason: testCase.id);
      } else {
        expect(expected, isNot(testCase.text), reason: testCase.id);
      }
    }
  });

  test('systemPrompt matches the issue wording exactly', () {
    expect(
      systemPrompt,
      'You are a Spanish correction engine.\n'
      '\n'
      'Correct only objective Spanish grammar, spelling, and punctuation '
      'errors.\n'
      '\n'
      'Do not correct word choice.\n'
      'Do not improve naturalness.\n'
      'Do not rewrite for style, fluency, tone, or elegance.\n'
      'Do not change valid regional Spanish.\n'
      'Do not treat awkward but grammatically valid Spanish as an error.\n'
      '\n'
      'Return JSON only. Do not include Markdown or commentary.',
    );
  });

  test('buildUserPrompt matches the issue wording exactly', () {
    expect(
      buildUserPrompt('Hola mundo.'),
      'Correct the following Spanish text for grammar, spelling, and '
      'punctuation only.\n'
      '\n'
      'Text:\n'
      'Hola mundo.',
    );
  });

  group('live run configuration', () {
    test('comparison model list is explicit and has no hardcoded default', () {
      expect(_configuredComparisonModels(const {}), isEmpty);
    });

    test('comparison model list can be supplied from environment', () {
      expect(
        _configuredComparisonModels(const {
          'COMPARISON_MODELS': ' gpt-5.4, gpt-5.3-chat-latest, gpt-4.1 ',
        }),
        ['gpt-5.4', 'gpt-5.3-chat-latest', 'gpt-4.1'],
      );
    });

    test('fixture subset defaults to the first-pass fixture set', () {
      final cases = _configuredFixtureSubset(const {});
      expect(cases, _cases);
    });

    test('output path defaults and can be supplied from environment', () {
      expect(_configuredOutputPath(const {}), defaultOutputPath);
      expect(
        _configuredOutputPath(const {
          'MODEL_COMPARISON_OUTPUT': 'docs/model_comparison_first_pass_live.md',
        }),
        'docs/model_comparison_first_pass_live.md',
      );
    });

    test('fixture subset can be supplied by stable fixture ids', () {
      final cases = _configuredFixtureSubset(const {
        'MODEL_COMPARISON_FIXTURE_IDS':
            'sentence-grammar-agreement, paragraph-calcs-natural',
      });

      expect(cases.map((testCase) => testCase.id), [
        'sentence-grammar-agreement',
        'paragraph-calcs-natural',
      ]);
    });

    test('fixture subset rejects unknown ids with the available id list', () {
      expect(
        () => _configuredFixtureSubset(const {
          'MODEL_COMPARISON_FIXTURE_IDS': 'does-not-exist',
        }),
        throwsStateError,
      );
    });

    test('live opt-in accepts only explicit true-ish values', () {
      expect(_parseBooleanOptIn('true'), isTrue);
      expect(_parseBooleanOptIn('1'), isTrue);
      expect(_parseBooleanOptIn('yes'), isTrue);
      expect(_parseBooleanOptIn('false'), isFalse);
      expect(_parseBooleanOptIn(null), isFalse);
    });

    test('live run config reports missing model list as invalid', () {
      final config = _LiveRunConfig(
        models: const [],
        cases: _cases,
        outputPath: defaultOutputPath,
        liveRunOptIn: true,
      );

      expect(_liveRunConfigError(config), contains('COMPARISON_MODELS'));
    });
  });

  group('_classifyFirstPassOutput', () {
    test('marks exact expected fixes on correction cases', () {
      final status = _classifyFirstPassOutput(
        kind: BenchmarkFixtureKind.correction,
        inputText: 'Los niño come.',
        expectedCorrectedText: 'Los niños comen.',
        validJson: true,
        correctedText: 'Los niños comen.',
        isError: false,
      );

      expect(status, _ReviewStatus.expectedCorrection);
    });

    test('marks unchanged correction cases as missed corrections', () {
      final status = _classifyFirstPassOutput(
        kind: BenchmarkFixtureKind.correction,
        inputText: 'Los niño come.',
        expectedCorrectedText: 'Los niños comen.',
        validJson: true,
        correctedText: 'Los niño come.',
        isError: false,
      );

      expect(status, _ReviewStatus.missedCorrection);
    });

    test('marks changed-but-not-expected correction cases separately', () {
      final status = _classifyFirstPassOutput(
        kind: BenchmarkFixtureKind.correction,
        inputText: 'Los niño come.',
        expectedCorrectedText: 'Los niños comen.',
        validJson: true,
        correctedText: 'Los niños comen bien.',
        isError: false,
      );

      expect(status, _ReviewStatus.unexpectedCorrection);
    });

    test('marks unchanged controls and over-corrected controls', () {
      final unchanged = _classifyFirstPassOutput(
        kind: BenchmarkFixtureKind.control,
        inputText: sentenceCorrectVoseo.text,
        expectedCorrectedText: sentenceCorrectVoseo.text,
        validJson: true,
        correctedText: sentenceCorrectVoseo.text,
        isError: false,
      );
      final overCorrected = _classifyFirstPassOutput(
        kind: BenchmarkFixtureKind.control,
        inputText: sentenceCorrectVoseo.text,
        expectedCorrectedText: sentenceCorrectVoseo.text,
        validJson: true,
        correctedText: 'Tú tienes razón, amigo, así que adelante.',
        isError: false,
      );

      expect(unchanged, _ReviewStatus.unchangedControl);
      expect(overCorrected, _ReviewStatus.overCorrection);
    });

    test('marks invalid JSON, errors, and unscored cases distinctly', () {
      expect(
        _classifyFirstPassOutput(
          kind: BenchmarkFixtureKind.correction,
          inputText: 'Los niño come.',
          expectedCorrectedText: 'Los niños comen.',
          validJson: false,
          correctedText: null,
          isError: false,
        ),
        _ReviewStatus.invalidJson,
      );
      expect(
        _classifyFirstPassOutput(
          kind: BenchmarkFixtureKind.correction,
          inputText: 'Los niño come.',
          expectedCorrectedText: 'Los niños comen.',
          validJson: false,
          correctedText: null,
          isError: true,
        ),
        _ReviewStatus.error,
      );
      expect(
        _classifyFirstPassOutput(
          kind: BenchmarkFixtureKind.correction,
          inputText: 'Los niño come.',
          expectedCorrectedText: null,
          validJson: true,
          correctedText: 'Los niños comen.',
          isError: false,
        ),
        _ReviewStatus.unscored,
      );
    });
  });

  group('buildChatCompletionsBody', () {
    test('has model, messages, and strict corrected_text response schema', () {
      final body = buildChatCompletionsBody(
        model: 'gpt-5.5',
        systemPromptText: 'sys',
        userText: 'usr',
      );

      expect(body['model'], 'gpt-5.5');
      expect(body['messages'], [
        {'role': 'system', 'content': 'sys'},
        {'role': 'user', 'content': 'usr'},
      ]);
      expect(body['response_format'], correctedTextResponseFormat);
    });
  });

  group('_parseCorrectedTextResponse', () {
    test('parses a well-formed contract response', () {
      final parsed = _parseCorrectedTextResponse('{"corrected_text": "Hola."}');
      expect(parsed.validJson, isTrue);
      expect(parsed.correctedText, 'Hola.');
    });

    test('tolerates a Markdown code fence around the JSON object', () {
      final parsed = _parseCorrectedTextResponse(
        '```json\n{"corrected_text": "Hola."}\n```',
      );
      expect(parsed.validJson, isTrue);
      expect(parsed.correctedText, 'Hola.');
    });

    test('preserves Spanish diacritics and ñ in the parsed value', () {
      final parsed = _parseCorrectedTextResponse(
        '{"corrected_text": "Mañana visitaré a mi abuela junto al río."}',
      );
      expect(parsed.validJson, isTrue);
      expect(parsed.correctedText, 'Mañana visitaré a mi abuela junto al río.');
    });

    test('marks invalid when the reply is not JSON at all', () {
      final parsed = _parseCorrectedTextResponse('not json');
      expect(parsed.validJson, isFalse);
      expect(parsed.correctedText, isNull);
    });

    test('marks invalid when corrected_text is missing', () {
      final parsed = _parseCorrectedTextResponse('{"other_field": "x"}');
      expect(parsed.validJson, isFalse);
    });

    test('marks invalid when extra fields are present', () {
      final parsed = _parseCorrectedTextResponse(
        '{"corrected_text": "Hola.", "explanation": "changed punctuation"}',
      );
      expect(parsed.validJson, isFalse);
    });

    test('marks invalid when corrected_text is not a string', () {
      final parsed = _parseCorrectedTextResponse('{"corrected_text": 5}');
      expect(parsed.validJson, isFalse);
    });

    test('marks invalid for an empty string', () {
      final parsed = _parseCorrectedTextResponse('');
      expect(parsed.validJson, isFalse);
    });
  });

  group('estimateCostUsd', () {
    test('returns a verified cost for verified first-pass model ids', () {
      final expectedCosts = {
        'gpt-5.5': 35.00,
        'gpt-5.3-chat-latest': 15.75,
        'gpt-5.2': 15.75,
        'gpt-5.1': 11.25,
        'gpt-5': 11.25,
        'gpt-5-mini': 2.25,
        'gpt-4.1': 10.00,
        'gpt-4.1-mini': 2.00,
        'gpt-4o': 12.50,
        'gpt-4o-mini': 0.75,
      };

      for (final entry in expectedCosts.entries) {
        final cost = estimateCostUsd(
          model: entry.key,
          inputTokens: 1000000,
          outputTokens: 1000000,
        );
        expect(cost, closeTo(entry.value, 1e-9), reason: entry.key);
      }
    });

    test('returns null for unverified model ids', () {
      for (final model in ['gpt-5.6-sol', 'gpt-5.4-mini', 'gpt-5.3']) {
        final cost = estimateCostUsd(
          model: model,
          inputTokens: 1000000,
          outputTokens: 1000000,
        );
        expect(cost, isNull, reason: model);
      }
    });

    test('returns null for an unknown model', () {
      final cost = estimateCostUsd(
        model: 'not-a-real-model',
        inputTokens: 100,
        outputTokens: 100,
      );
      expect(cost, isNull);
    });
  });

  group('extractReplyText', () {
    test('extracts trimmed content from a well-formed body', () {
      final body = {
        'choices': [
          {
            'message': {'content': '  {"corrected_text": "Hola."}  '},
          },
        ],
      };
      expect(extractReplyText(body), '{"corrected_text": "Hola."}');
    });

    test('throws when choices is missing', () {
      expect(() => extractReplyText({}), throwsFormatException);
    });
  });

  group('result builders', () {
    test(
      '_successResult computes estimated cost (null — no verified pricing)',
      () {
        final result = _successResult(
          model: 'gpt-5.3',
          caseId: 'grammar-agreement',
          inputText: 'Los niño come.',
          rawResponse: '{"corrected_text": "Los niños comen."}',
          parsed: const _ParsedResponse(
            validJson: true,
            correctedText: 'Los niños comen.',
          ),
          latencyMs: 250,
          inputTokens: 100,
          outputTokens: 50,
          totalTokens: 150,
        );

        expect(result.isError, isFalse);
        expect(result.validJson, isTrue);
        expect(result.correctedText, 'Los niños comen.');
        expect(
          result.estimatedCostUsd,
          isNull,
          reason: 'gpt-5.3 has no verified pricing entry',
        );
        expect(result.promptVersion, promptVersion);
      },
    );

    test(
      '_successResult computes verified estimated cost when pricing exists',
      () {
        final result = _successResult(
          model: 'gpt-4.1',
          caseId: 'grammar-agreement',
          inputText: 'Los niño come.',
          rawResponse: '{"corrected_text": "Los niños comen."}',
          parsed: const _ParsedResponse(
            validJson: true,
            correctedText: 'Los niños comen.',
          ),
          latencyMs: 250,
          inputTokens: 1000000,
          outputTokens: 1000000,
          totalTokens: 2000000,
        );

        expect(result.isError, isFalse);
        expect(result.estimatedCostUsd, closeTo(10.0, 1e-9));
        expect(result.promptVersion, promptVersion);
      },
    );

    test('_errorResult carries the error and no token/cost data', () {
      final result = _errorResult(
        model: 'gpt-5.5',
        caseId: 'grammar-agreement',
        inputText: 'Los niño come.',
        latencyMs: 5000,
        error: StateError('timed out'),
      );

      expect(result.isError, isTrue);
      expect(result.validJson, isFalse);
      expect(result.estimatedCostUsd, isNull);
      expect(result.error, isA<StateError>());
    });
  });

  test('report renders task status and per-model outcome rates', () {
    final report = _buildReport(
      models: ['model-a', 'model-b'],
      generatedAt: DateTime.utc(2026, 1, 1, 12),
      cases: const [sentenceGrammarAgreement, sentenceCorrectVoseo],
      resultsByCaseThenModel: {
        sentenceGrammarAgreement.id: {
          'model-a': _successResult(
            model: 'model-a',
            caseId: sentenceGrammarAgreement.id,
            inputText: sentenceGrammarAgreement.text,
            rawResponse:
                '{"corrected_text": "Los niños comen muchas manzanas en el jardín."}',
            parsed: const _ParsedResponse(
              validJson: true,
              correctedText: 'Los niños comen muchas manzanas en el jardín.',
            ),
            latencyMs: 200,
            inputTokens: 20,
            outputTokens: 10,
            totalTokens: 30,
          ),
          'model-b': _successResult(
            model: 'model-b',
            caseId: sentenceGrammarAgreement.id,
            inputText: sentenceGrammarAgreement.text,
            rawResponse:
                '{"corrected_text": "Los niño come muchas manzana en el jardín."}',
            parsed: const _ParsedResponse(
              validJson: true,
              correctedText: 'Los niño come muchas manzana en el jardín.',
            ),
            latencyMs: 220,
            inputTokens: 20,
            outputTokens: 10,
            totalTokens: 30,
          ),
        },
        sentenceCorrectVoseo.id: {
          'model-a': _successResult(
            model: 'model-a',
            caseId: sentenceCorrectVoseo.id,
            inputText: sentenceCorrectVoseo.text,
            rawResponse:
                '{"corrected_text": "Vos tenés razón, che, así que dale nomás."}',
            parsed: const _ParsedResponse(
              validJson: true,
              correctedText: 'Vos tenés razón, che, así que dale nomás.',
            ),
            latencyMs: 210,
            inputTokens: 20,
            outputTokens: 10,
            totalTokens: 30,
          ),
          'model-b': _successResult(
            model: 'model-b',
            caseId: sentenceCorrectVoseo.id,
            inputText: sentenceCorrectVoseo.text,
            rawResponse:
                '{"corrected_text": "Tú tienes razón, amigo, así que adelante."}',
            parsed: const _ParsedResponse(
              validJson: true,
              correctedText: 'Tú tienes razón, amigo, así que adelante.',
            ),
            latencyMs: 230,
            inputTokens: 20,
            outputTokens: 10,
            totalTokens: 30,
          ),
        },
      },
    );

    expect(report, contains('| model-a | true | expected_correction |'));
    expect(report, contains('| model-a | true | unchanged_control |'));
    expect(report, contains('| model-b | true | missed_correction |'));
    expect(report, contains('| model-b | true | over_correction |'));
    expect(
      report,
      contains(
        '| model-a | 2 | 100.0% (2/2) | 100.0% (2/2) | '
        '100.0% (1/1) | 0.0% (0/1) | 100.0% (1/1) | '
        '0.0% (0/1) | 0 | 205.0 | 60 |',
      ),
    );
    expect(
      report,
      contains(
        '| model-b | 2 | 100.0% (2/2) | 0.0% (0/2) | '
        '0.0% (0/1) | 100.0% (1/1) | 0.0% (0/1) | '
        '100.0% (1/1) | 0 | 225.0 | 60 |',
      ),
    );
  });

  test('report golden test', () {
    final report = _buildReport(
      models: ['test-model-a', 'test-model-b'],
      generatedAt: DateTime.utc(2026, 1, 1, 12),
      cases: const [
        BenchmarkFixture(
          id: 'TEST-1',
          text: 'Los niño come.',
          note: 'Synthetic case.',
          lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
          kind: BenchmarkFixtureKind.correction,
        ),
      ],
      resultsByCaseThenModel: {
        'TEST-1': {
          'test-model-a': _successResult(
            model: 'test-model-a',
            caseId: 'TEST-1',
            inputText: 'Los niño come.',
            rawResponse: '{"corrected_text": "Los niños comen."}',
            parsed: const _ParsedResponse(
              validJson: true,
              correctedText: 'Los niños comen.',
            ),
            latencyMs: 200,
            inputTokens: 20,
            outputTokens: 500000,
            totalTokens: 500020,
          ),
          'test-model-b': _errorResult(
            model: 'test-model-b',
            caseId: 'TEST-1',
            inputText: 'Los niño come.',
            latencyMs: 9000,
            error: StateError('timed out'),
          ),
        },
      },
      branch: 'prepare-first-pass-live-model-run-config',
      commit: 'abc1234',
    );

    expect(report, _expectedReportGolden);
  });

  test('report renders verified and unknown costs distinctly', () {
    final report = _buildReport(
      models: ['gpt-4.1', 'gpt-5.3'],
      generatedAt: DateTime.utc(2026, 1, 1, 12),
      cases: const [
        BenchmarkFixture(
          id: 'TEST-1',
          text: 'Los niño come.',
          note: 'Synthetic case.',
          lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
          kind: BenchmarkFixtureKind.correction,
        ),
      ],
      resultsByCaseThenModel: {
        'TEST-1': {
          'gpt-4.1': _successResult(
            model: 'gpt-4.1',
            caseId: 'TEST-1',
            inputText: 'Los niño come.',
            rawResponse: '{"corrected_text": "Los niños comen."}',
            parsed: const _ParsedResponse(
              validJson: true,
              correctedText: 'Los niños comen.',
            ),
            latencyMs: 200,
            inputTokens: 20,
            outputTokens: 500000,
            totalTokens: 500020,
          ),
          'gpt-5.3': _successResult(
            model: 'gpt-5.3',
            caseId: 'TEST-1',
            inputText: 'Los niño come.',
            rawResponse: '{"corrected_text": "Los niños comen."}',
            parsed: const _ParsedResponse(
              validJson: true,
              correctedText: 'Los niños comen.',
            ),
            latencyMs: 250,
            inputTokens: 20,
            outputTokens: 500000,
            totalTokens: 500020,
          ),
        },
      },
    );

    expect(report, contains('Verified estimated costs use:'));
    expect(report, contains('`gpt-4.1`: input=2.0 USD'));
    expect(
      report,
      contains(
        'Unknown cost because pricing is unavailable or unverified for: '
        '`gpt-5.3`.',
      ),
    );
    expect(
      report,
      contains(
        '| gpt-4.1 | true | unscored | 200 | 20/500000/500020 | '
        'verified 4.000040 |',
      ),
    );
    expect(
      report,
      contains(
        '| gpt-5.3 | true | unscored | 250 | 20/500000/500020 | '
        'unknown (pricing unavailable/unverified) |',
      ),
    );
    expect(
      report,
      contains(
        '| gpt-4.1 | 1 | 100.0% (1/1) | 0.0% (0/0) | '
        '0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | '
        '0 | 200.0 | 500020 | verified 4.000040 |',
      ),
    );
    expect(
      report,
      contains(
        '| gpt-5.3 | 1 | 100.0% (1/1) | 0.0% (0/0) | '
        '0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | '
        '0 | 250.0 | 500020 | '
        'unknown (pricing unavailable/unverified) |',
      ),
    );
  });

  test(
    'model comparison harness (live)',
    () async {
      final config = _buildLiveRunConfig(Platform.environment);

      if (!config.liveRunOptIn) {
        // ignore: avoid_print
        print(
          'Skipping live model comparison. Set MODEL_COMPARISON_LIVE=true '
          'and COMPARISON_MODELS=<exact OpenAI API model IDs> to opt in.',
        );
        return;
      }

      final configError = _liveRunConfigError(config);
      if (configError != null) {
        fail(configError);
      }

      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the model comparison harness. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final models = config.models;
      final cases = config.cases;
      final httpClient = HttpClient();
      final resultsByCaseThenModel = <String, Map<String, _ModelCaseResult>>{};

      try {
        for (final testCase in cases) {
          final resultsByModel = <String, _ModelCaseResult>{};
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (final model in models) {
            final result = await _runOnce(
              httpClient: httpClient,
              apiKey: apiKey,
              model: model,
              testCase: testCase,
            );
            resultsByModel[model] = result;
            // ignore: avoid_print
            print('[$model] ${_describeResult(result)}');
            await Future<void>.delayed(
              const Duration(milliseconds: callDelayMs),
            );
          }

          resultsByCaseThenModel[testCase.id] = resultsByModel;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        models: models,
        generatedAt: DateTime.now().toUtc(),
        cases: cases,
        resultsByCaseThenModel: resultsByCaseThenModel,
        branch: _gitBranch(),
        commit: _gitHead(),
      );

      File(config.outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print(
        'Wrote ${config.outputPath} '
        '(models: ${models.join(", ")}, cases: ${config.caseIds.join(", ")})',
      );
    },
    timeout: const Timeout(Duration(minutes: 30)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    '''# Spanish Correction Model Comparison Harness

## Run configuration

- Prompt label: `simple-spanish-grammar-spelling-punctuation-only`
- Prompt version: `v1`
- Models: `test-model-a`, `test-model-b`
- Fixture case ids: `TEST-1`
- Generated: 2026-01-01T12:00:00.000Z
- Git branch: `prepare-first-pass-live-model-run-config`
- Git commit: `abc1234`
- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`

## Pricing

No verified pricing is configured for any model in this report. Every cost estimate below shows as `unknown` by design — see `test/shared/model_pricing.dart` to add a verified entry once a maintainer has verified pricing for that model against its provider-published pricing page.

Unknown cost because pricing is unavailable or unverified for: `test-model-a`, `test-model-b`.

## TEST-1

- Input text: `Los niño come.`
- Note: Synthetic case.
- Expected corrected_text: `(unscored)`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| test-model-a | true | unscored | 200 | 20/500000/500020 | unknown (pricing unavailable/unverified) | Los niños comen. | {"corrected_text": "Los niños comen."} |
| test-model-b | ERROR | error | 9000 | | | | Bad state: timed out |

---

## Overall summary

| Model | Cases | Valid JSON rate | Task success rate | Expected corrections | Missed fixes | Controls unchanged | Over-corrections | Unexpected outputs | Avg latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| test-model-a | 1 | 100.0% (1/1) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0 | 200.0 | 500020 | unknown (pricing unavailable/unverified) |
| test-model-b | 1 | 0.0% (0/1) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0.0% (0/0) | 0 | n/a | 0 | unknown (pricing unavailable/unverified) |
''';
