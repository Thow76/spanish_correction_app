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
// Battery: a small, fixed set of Spanish input texts covering objective
// grammar/spelling/punctuation errors (things the model SHOULD fix) and
// control cases the model should leave untouched — regional/dialectal
// Spanish, word-choice/naturalness quirks, and text that is already
// correct including Spanish diacritics/ñ — so a "fix" applied to a control
// case is itself a signal of over-correction, not just a missed fix.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/model_comparison_harness.dart --exclude-tags live
//
// Run the live comparison across every model in `comparisonModels` (costs
// real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/model_comparison_harness.dart --timeout none
//
// Override the model list with --dart-define=COMPARISON_MODELS=a,b,c
// (comma-separated, default 'gpt-5.5,gpt-5.6-sol,gpt-5.6-terra,gpt-5.6-luna').
// Override the output path with --dart-define=MODEL_COMPARISON_OUTPUT=...
// (default docs/model_comparison_harness.md).
//
// To compare the default higher-tier set against lower-cost/earlier
// candidates (5.4, 5.3, and 4.1 family models), pass them explicitly via
// COMPARISON_MODELS instead of changing the default — the prompt, fixture
// set, response contract, and scoring/logging format are identical either
// way, so the model name is still the only variable. For example:
//   --dart-define=COMPARISON_MODELS=gpt-5.5,gpt-5.4,gpt-5.3,gpt-4.1,gpt-4.1-mini
//
// Per-model USD-per-million-token pricing lives in `_pricingPerModel`
// below. These figures are illustrative placeholders, not verified
// published pricing — update them before treating `estimatedCostUsd` as
// authoritative. A model missing from the table yields a `null` estimate
// rather than a silently wrong number. `gpt-5.4` and `gpt-5.3` are
// intentionally omitted (no verified pricing available for this project's
// account); `gpt-4.1` and `gpt-4.1-mini` use OpenAI's published list
// pricing as of this writing.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Identifies which version of the prompt/contract produced a result.
/// Bump this if the system prompt or user prompt template below ever
/// changes, so historical reports stay attributable to the wording that
/// produced them.
const String promptVersion = 'v1';

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
/// (comma-separated). Everything else about the request is identical
/// across models — same system prompt, same user prompt, same JSON
/// contract — so this list is the only thing that varies.
const String _rawComparisonModels = String.fromEnvironment(
  'COMPARISON_MODELS',
  defaultValue: 'gpt-5.5,gpt-5.6-sol,gpt-5.6-terra,gpt-5.6-luna',
);

List<String> get comparisonModels => _rawComparisonModels
    .split(',')
    .map((m) => m.trim())
    .where((m) => m.isNotEmpty)
    .toList();

const String outputPath = String.fromEnvironment(
  'MODEL_COMPARISON_OUTPUT',
  defaultValue: 'docs/model_comparison_harness.md',
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

/// USD-per-million-token pricing used for [estimateCostUsd]. Illustrative
/// placeholders — see the file header. A model not listed here simply
/// yields no cost estimate rather than a wrong one.
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
  // Earlier-generation/lower-cost candidates (see issue: expand the
  // comparison harness beyond the higher-tier model set). `gpt-5.4` and
  // `gpt-5.3` deliberately have no entry — no verified pricing is
  // available for this project's account, so `estimateCostUsd` reports
  // `null` ("unknown") for them rather than a guessed number.
  'gpt-4.1': _ModelPricing(
    inputPerMillionUsd: 2.00,
    outputPerMillionUsd: 8.00,
  ),
  'gpt-4.1-mini': _ModelPricing(
    inputPerMillionUsd: 0.40,
    outputPerMillionUsd: 1.60,
  ),
};

/// Estimated cost in USD for one call, or `null` if [model] has no entry in
/// [_pricingPerModel].
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

/// One fixed input text in the comparison battery.
class _TestCase {
  const _TestCase({required this.id, required this.text, required this.note});

  final String id;
  final String text;
  final String note;
}

const List<_TestCase> _cases = [
  _TestCase(
    id: 'grammar-agreement',
    text: 'Los niño come muchas manzana en el jardín.',
    note:
        'Objective grammar errors: missing plural agreement ("Los niño" '
        '-> "Los niños", "manzana" -> "manzanas"). Should be corrected.',
  ),
  _TestCase(
    id: 'spelling-accents',
    text: 'El corazon del problema es que nadie presto atencion a tiempo.',
    note:
        'Objective spelling errors: missing accents on "corazón", '
        '"prestó", "atención". Should be corrected.',
  ),
  _TestCase(
    id: 'punctuation-question',
    text: 'Como estas hoy Necesito saber si vienes a la fiesta',
    note:
        'Objective punctuation errors: missing inverted/closing question '
        'marks and missing accent on "cómo"/"estás", missing sentence-'
        'final punctuation. Should be corrected.',
  ),
  _TestCase(
    id: 'control-voseo',
    text: 'Vos tenés razón, che, así que dale nomás.',
    note:
        'Control case: valid Argentine voseo/regional Spanish, correctly '
        'spelled and punctuated. Must NOT be rewritten to "tú tienes".',
  ),
  _TestCase(
    id: 'control-word-choice',
    text: 'Voy a coger el autobús para ir al trabajo.',
    note:
        'Control case: "coger" is a word-choice/regional-register matter, '
        'not a grammar/spelling/punctuation error. Text is already '
        'grammatically correct and must NOT be rewritten.',
  ),
  _TestCase(
    id: 'control-already-correct',
    text: 'Mañana visitaré a mi abuela en su pequeño pueblo junto al río.',
    note:
        'Control case: already correct, with several Spanish diacritics '
        'and ñ. Must be returned unchanged, and the special characters '
        'must survive round-trip through the model untouched.',
  ),
];

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
_ParsedResponse parseCorrectedTextResponse(String replyText) {
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
  required _TestCase testCase,
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
    final parsed = parseCorrectedTextResponse(replyText);

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
      ? '\$${result.estimatedCostUsd!.toStringAsFixed(6)}'
      : 'unknown';
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

String _markdownTableCell(String value) {
  return value
      .replaceAll('|', r'\|')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', '<br>');
}

/// Builds the full markdown comparison report: one section per case with a
/// table comparing every model's result, then an overall per-model summary
/// table (valid JSON rate, average latency, total tokens, total estimated
/// cost). Pure — takes already-collected [resultsByCaseThenModel] rather
/// than making any calls itself, golden-testable against synthetic data.
String _buildReport({
  required List<String> models,
  required DateTime generatedAt,
  required List<_TestCase> cases,
  required Map<String, Map<String, _ModelCaseResult>> resultsByCaseThenModel,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Spanish Correction Model Comparison Harness')
    ..writeln()
    ..writeln('Prompt version: `$promptVersion`  ')
    ..writeln('Models: ${models.map((m) => '`$m`').join(', ')}  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}')
    ..writeln();

  for (final testCase in cases) {
    final resultsByModel = resultsByCaseThenModel[testCase.id] ?? const {};

    report
      ..writeln('## ${testCase.id}')
      ..writeln()
      ..writeln('- Input text: `${testCase.text}`')
      ..writeln('- Note: ${testCase.note}')
      ..writeln()
      ..writeln(
        '| Model | Valid JSON | Latency (ms) | Tokens (in/out/total) | '
        'Est. cost (USD) | corrected_text | raw_response |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- | --- |');

    for (final model in models) {
      final result = resultsByModel[model];
      if (result == null) {
        report.writeln('| $model | (no result) | | | | | |');
        continue;
      }
      if (result.isError) {
        report.writeln(
          '| $model | ERROR | ${result.latencyMs} | | | | ${_markdownTableCell(result.error.toString())} |',
        );
        continue;
      }
      final tokens = result.totalTokens != null
          ? '${result.inputTokens}/${result.outputTokens}/${result.totalTokens}'
          : 'unknown';
      final cost = result.estimatedCostUsd != null
          ? result.estimatedCostUsd!.toStringAsFixed(6)
          : 'unknown';
      final corrected = _markdownTableCell(result.correctedText ?? '(unparsed)');
      final rawResponse = _markdownTableCell(result.rawResponse ?? '(missing)');
      report.writeln(
        '| $model | ${result.validJson} | ${result.latencyMs} | $tokens | $cost | $corrected | $rawResponse |',
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
      '| Model | Cases | Valid JSON rate | Avg latency (ms) | Total tokens | '
      'Total est. cost (USD) |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- |');

  for (final model in models) {
    var caseCount = 0;
    var validJsonCount = 0;
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
    final avgLatency = latencyCount == 0
        ? 'n/a'
        : (latencySum / latencyCount).toStringAsFixed(1);
    final costLabel = hasCost ? totalCost.toStringAsFixed(6) : 'unknown';

    report.writeln(
      '| $model | $caseCount | $validJsonRate | $avgLatency | $totalTokens | $costLabel |',
    );
  }

  return report.toString();
}

void main() {
  test('battery cases are well-formed and cover the required scenarios', () {
    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(testCase.text.trim(), isNotEmpty, reason: testCase.id);
      expect(testCase.note.trim(), isNotEmpty, reason: testCase.id);
    }

    expect(
      ids,
      containsAll(<String>[
        'grammar-agreement',
        'spelling-accents',
        'punctuation-question',
        'control-voseo',
        'control-word-choice',
        'control-already-correct',
      ]),
    );
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

  test('comparisonModels defaults to the four-model comparison set', () {
    expect(comparisonModels, [
      'gpt-5.5',
      'gpt-5.6-sol',
      'gpt-5.6-terra',
      'gpt-5.6-luna',
    ]);
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

  group('parseCorrectedTextResponse', () {
    test('parses a well-formed contract response', () {
      final parsed = parseCorrectedTextResponse('{"corrected_text": "Hola."}');
      expect(parsed.validJson, isTrue);
      expect(parsed.correctedText, 'Hola.');
    });

    test('tolerates a Markdown code fence around the JSON object', () {
      final parsed = parseCorrectedTextResponse(
        '```json\n{"corrected_text": "Hola."}\n```',
      );
      expect(parsed.validJson, isTrue);
      expect(parsed.correctedText, 'Hola.');
    });

    test('preserves Spanish diacritics and ñ in the parsed value', () {
      final parsed = parseCorrectedTextResponse(
        '{"corrected_text": "Mañana visitaré a mi abuela junto al río."}',
      );
      expect(parsed.validJson, isTrue);
      expect(parsed.correctedText, 'Mañana visitaré a mi abuela junto al río.');
    });

    test('marks invalid when the reply is not JSON at all', () {
      final parsed = parseCorrectedTextResponse('not json');
      expect(parsed.validJson, isFalse);
      expect(parsed.correctedText, isNull);
    });

    test('marks invalid when corrected_text is missing', () {
      final parsed = parseCorrectedTextResponse('{"other_field": "x"}');
      expect(parsed.validJson, isFalse);
    });

    test('marks invalid when extra fields are present', () {
      final parsed = parseCorrectedTextResponse(
        '{"corrected_text": "Hola.", "explanation": "changed punctuation"}',
      );
      expect(parsed.validJson, isFalse);
    });

    test('marks invalid when corrected_text is not a string', () {
      final parsed = parseCorrectedTextResponse('{"corrected_text": 5}');
      expect(parsed.validJson, isFalse);
    });

    test('marks invalid for an empty string', () {
      final parsed = parseCorrectedTextResponse('');
      expect(parsed.validJson, isFalse);
    });
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
      final cost = estimateCostUsd(
        model: 'not-a-real-model',
        inputTokens: 100,
        outputTokens: 100,
      );
      expect(cost, isNull);
    });

    test('scales linearly with token counts', () {
      final cost = estimateCostUsd(
        model: 'gpt-5.6-luna',
        inputTokens: 500000,
        outputTokens: 0,
      );
      expect(cost, closeTo(0.15, 1e-9));
    });

    test('computes cost for the gpt-4.1 candidate', () {
      final cost = estimateCostUsd(
        model: 'gpt-4.1',
        inputTokens: 1000000,
        outputTokens: 1000000,
      );
      expect(cost, closeTo(10.0, 1e-9));
    });

    test('computes cost for the gpt-4.1-mini candidate', () {
      final cost = estimateCostUsd(
        model: 'gpt-4.1-mini',
        inputTokens: 1000000,
        outputTokens: 1000000,
      );
      expect(cost, closeTo(2.0, 1e-9));
    });

    test('reports unknown (null) for the gpt-5.4 candidate', () {
      final cost = estimateCostUsd(
        model: 'gpt-5.4',
        inputTokens: 100,
        outputTokens: 100,
      );
      expect(cost, isNull);
    });

    test('reports unknown (null) for the gpt-5.3 candidate', () {
      final cost = estimateCostUsd(
        model: 'gpt-5.3',
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
    test('_successResult computes estimated cost from tokens', () {
      final result = _successResult(
        model: 'gpt-5.5',
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
      expect(result.estimatedCostUsd, isNotNull);
      expect(result.promptVersion, promptVersion);
    });

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

  test('report golden test', () {
    final report = _buildReport(
      models: ['test-model-a', 'test-model-b'],
      generatedAt: DateTime.utc(2026, 1, 1, 12),
      cases: const [
        _TestCase(
          id: 'TEST-1',
          text: 'Los niño come.',
          note: 'Synthetic case.',
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
      commit: 'abc1234',
    );

    expect(report, jsonDecode(_expectedReportGolden));
  });

  test(
    'model comparison harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the model comparison harness. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final models = comparisonModels;
      final httpClient = HttpClient();
      final resultsByCaseThenModel = <String, Map<String, _ModelCaseResult>>{};

      try {
        for (final testCase in _cases) {
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
        generatedAt: DateTime.now(),
        cases: _cases,
        resultsByCaseThenModel: resultsByCaseThenModel,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath (models: ${models.join(", ")})');
    },
    timeout: const Timeout(Duration(minutes: 30)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Spanish Correction Model Comparison Harness\n\nPrompt version: `v1`  \nModels: `test-model-a`, `test-model-b`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z\n\n## TEST-1\n\n- Input text: `Los niño come.`\n- Note: Synthetic case.\n\n| Model | Valid JSON | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |\n| --- | --- | --- | --- | --- | --- | --- |\n| test-model-a | true | 200 | 20/500000/500020 | unknown | Los niños comen. | {\"corrected_text\": \"Los niños comen.\"} |\n| test-model-b | ERROR | 9000 | | | | Bad state: timed out |\n\n---\n\n## Overall summary\n\n| Model | Cases | Valid JSON rate | Avg latency (ms) | Total tokens | Total est. cost (USD) |\n| --- | --- | --- | --- | --- | --- |\n| test-model-a | 1 | 100.0% (1/1) | 200.0 | 500020 | unknown |\n| test-model-b | 1 | 0.0% (0/1) | n/a | 0 | unknown |\n"';
