// Naturalness-only model comparison harness.
//
// Purpose: compare models on a separate task from the first-pass
// grammar/spelling/punctuation correction harness. This harness asks models
// to identify wording that is grammatical and understandable, but unlikely to
// be used naturally by a native Spanish speaker in context.
//
// It deliberately does NOT ask for a fully corrected text. The model returns
// issue spans and natural replacements only, so this can be tested as a
// possible parallel naturalness pass without conflating it with first-pass
// correction.
//
// Run offline tests only:
//   flutter test test/naturalness_model_comparison_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls):
//   OPENAI_API_KEY=sk-... \
//   NATURALNESS_LIVE=true \
//   NATURALNESS_COMPARISON_MODELS=gpt-4.1-mini,gpt-4.1 \
//   flutter test test/naturalness_model_comparison_harness.dart --tags live --timeout none
//
// Focused 5.1 vs 5.3 consistency run:
//   OPENAI_API_KEY=sk-... \
//   NATURALNESS_LIVE=true \
//   NATURALNESS_COMPARISON_MODELS=gpt-5.1,gpt-5.3-chat-latest \
//   NATURALNESS_RUNS_PER_CASE=5 \
//   NATURALNESS_OUTPUT=docs/naturalness_gpt_51_vs_53_live.md \
//   flutter test test/naturalness_model_comparison_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - NATURALNESS_FIXTURE_IDS: comma-separated fixture ids. Defaults to the
//   naturalnessModelComparisonFixtures set in shared/benchmark_fixtures.dart.
// - NATURALNESS_RUNS_PER_CASE: positive integer, defaults to 1.
// - NATURALNESS_OUTPUT: report path, defaults to
//   docs/naturalness_model_comparison_harness.md.
// - NATURALNESS_CALL_DELAY_MS: delay between calls, defaults to 750.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'shared/benchmark_fixtures.dart';
import 'shared/model_pricing.dart' as pricing;

const String naturalnessPromptVersion = 'v4';
const String naturalnessPromptLabel =
    'spanish-naturalness-only-variety-restraint';

const String legacyNaturalnessSystemPrompt =
    'Review the Spanish text only for naturalness.\n'
    '\n'
    'Identify wording that is grammatical and understandable, but that a '
    'native Spanish speaker would be unlikely to use naturally in this '
    'context.\n'
    '\n'
    'Do not report spelling, punctuation, or ordinary grammatical errors.\n'
    'If the only problem is grammar, spelling, or punctuation, return no '
    'issue.\n'
    'Ignore spelling, punctuation, or grammar errors even if they appear in '
    'the same sentence as a naturalness issue.\n'
    'Do not rewrite correct wording merely because another formulation is '
    'possible.\n'
    'Do not provide a fully corrected version of the text.\n'
    '\n'
    'Return JSON only.';

const String previousNaturalnessSystemPrompt =
    'You are a Spanish tutor reviewing a text that has been checked for '
    'grammar, spelling, and punctuation.\n'
    '\n'
    'Your task is to identify wording that is grammatical and understandable, '
    'but that a native Spanish speaker would be unlikely to use naturally in '
    'this context. This includes calques and unnatural uses of idioms or '
    'collocations.\n'
    '\n'
    'Do not report spelling, punctuation, or grammatical errors.\n'
    'If the only problem is grammar, spelling, or punctuation, return no '
    'issue.\n'
    'Ignore spelling, punctuation, or grammar errors even if they appear in '
    'the same sentence as a naturalness issue.\n'
    '\n'
    'Do not flag wording as unnatural if it is naturally used in an '
    'established regional variety of Spanish and is compatible with the '
    'context. Do not replace it merely because another form is more '
    'widespread, neutral, or commonly preferred across regions.\n'
    '\n'
    'Return JSON only.';

// v3 — superseded by `naturalnessSystemPrompt` (v4) below, issue #108.
// Kept by value, not deleted, same precedent as `legacyNaturalnessSystemPrompt`
// and `previousNaturalnessSystemPrompt` above: a prior harness-validated
// wording stays available for regression/diff comparison rather than being
// discarded once superseded.
const String previousNaturalnessSystemPromptV3 =
    'You are a Spanish tutor reviewing a text that has been checked for '
    'grammar, spelling, and punctuation.\n'
    '\n'
    'Your task is to identify wording that a native Spanish speaker would be '
    'unlikely to use naturally in this context. This includes calques, idioms, '
    'and collocations.\n'
    '\n'
    'Do not report spelling, punctuation, or grammatical errors.\n'
    'If the only problem is grammar, spelling, or punctuation, return no '
    'issue.\n'
    '\n'
    'Do not normalise wording that is natural in an established variety of '
    'Spanish. A form is not a naturalness issue merely because another form is '
    'more widespread, more neutral, or preferred by the reviewer\'s own '
    'regional variety.This includes established regional uses of para with verbs of movement to express direction or destination, such as ir para + place, where another variety may prefer ir a + place.\n'
    '\n'
    'Ignore spelling, punctuation, or grammar errors even if they appear in '
    'the same sentence as a naturalness issue.\n'
    '\n'
    'Return JSON only.';

// v4 (issue #108): adds one new paragraph to v3 above — everything else is
// byte-for-byte unchanged, including the known "regional variety.This
// includes" missing-space typo, which stays untouched here since fixing it
// is not this issue's scope. The new paragraph requires naturalness edits
// to propose exactly one replacement, never a slash-separated menu of
// options — see docs/two_pass_prompt_contract_audit.md §7b for the
// recorded failures this addresses (the "beer" and "pasar un buen tiempo"
// patterns) and lib/features/corrections/domain/naturalness_merge.dart's
// new multiOptionReplacement skip reason for the deterministic code-level
// backstop this prompt change is paired with.
const String naturalnessSystemPrompt =
    'You are a Spanish tutor reviewing a text that has been checked for '
    'grammar, spelling, and punctuation.\n'
    '\n'
    'Your task is to identify wording that a native Spanish speaker would be '
    'unlikely to use naturally in this context. This includes calques, idioms, '
    'and collocations.\n'
    '\n'
    'Do not report spelling, punctuation, or grammatical errors.\n'
    'If the only problem is grammar, spelling, or punctuation, return no '
    'issue.\n'
    '\n'
    'Do not normalise wording that is natural in an established variety of '
    'Spanish. A form is not a naturalness issue merely because another form is '
    'more widespread, more neutral, or preferred by the reviewer\'s own '
    'regional variety.This includes established regional uses of para with verbs of movement to express direction or destination, such as ir para + place, where another variety may prefer ir a + place.\n'
    '\n'
    'Ignore spelling, punctuation, or grammar errors even if they appear in '
    'the same sentence as a naturalness issue.\n'
    '\n'
    'Give exactly one natural replacement for each issue — never more than '
    'one option, and never join alternatives with a slash, "or", or a list. '
    'If more than one wording would work, choose the single best one '
    'yourself.\n'
    '\n'
    'Return JSON only.';

String buildNaturalnessUserPrompt(String inputText) {
  return 'Review this Spanish text for naturalness only.\n'
      '\n'
      'Text:\n'
      '$inputText';
}

const Map<String, Object?> naturalnessResponseFormat = {
  'type': 'json_schema',
  'json_schema': {
    'name': 'spanish_naturalness_response',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['has_naturalness_issue', 'issues'],
      'properties': {
        'has_naturalness_issue': {'type': 'boolean'},
        'issues': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['span', 'natural_replacement', 'explanation'],
            'properties': {
              'span': {'type': 'string'},
              'natural_replacement': {'type': 'string'},
              'explanation': {'type': 'string'},
            },
          },
        },
      },
    },
  },
};

const String _rawModelsFromDefine = String.fromEnvironment(
  'NATURALNESS_COMPARISON_MODELS',
  defaultValue: '',
);
const String _rawFixtureIdsFromDefine = String.fromEnvironment(
  'NATURALNESS_FIXTURE_IDS',
  defaultValue: '',
);
const String _rawRunsPerCaseFromDefine = String.fromEnvironment(
  'NATURALNESS_RUNS_PER_CASE',
  defaultValue: '',
);
const String _outputPathFromDefine = String.fromEnvironment(
  'NATURALNESS_OUTPUT',
  defaultValue: '',
);
const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'NATURALNESS_LIVE',
  defaultValue: false,
);

const String defaultNaturalnessOutputPath =
    'docs/naturalness_model_comparison_harness.md';

const int callDelayMs = int.fromEnvironment(
  'NATURALNESS_CALL_DELAY_MS',
  defaultValue: 750,
);

const List<NaturalnessBenchmarkFixture> _cases =
    naturalnessModelComparisonFixtures;

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

List<String> _configuredModels(Map<String, String> environment) {
  return _parseCommaSeparatedValues(
    _runtimeString(
      dartDefineValue: _rawModelsFromDefine,
      environment: environment,
      key: 'NATURALNESS_COMPARISON_MODELS',
      defaultValue: '',
    ),
  );
}

String _configuredOutputPath(Map<String, String> environment) {
  return _runtimeString(
    dartDefineValue: _outputPathFromDefine,
    environment: environment,
    key: 'NATURALNESS_OUTPUT',
    defaultValue: defaultNaturalnessOutputPath,
  );
}

int _parseRunsPerCase(String rawRunsPerCase) {
  final trimmed = rawRunsPerCase.trim();
  if (trimmed.isEmpty) {
    return 1;
  }
  final parsed = int.tryParse(trimmed);
  if (parsed == null || parsed < 1) {
    throw StateError(
      'NATURALNESS_RUNS_PER_CASE must be a positive integer; '
      'received "$rawRunsPerCase".',
    );
  }
  return parsed;
}

int _configuredRunsPerCase(Map<String, String> environment) {
  final rawRunsPerCase = _runtimeString(
    dartDefineValue: _rawRunsPerCaseFromDefine,
    environment: environment,
    key: 'NATURALNESS_RUNS_PER_CASE',
    defaultValue: '',
  );
  return _parseRunsPerCase(rawRunsPerCase);
}

List<NaturalnessBenchmarkFixture> _resolveFixtureSubset(String rawFixtureIds) {
  final ids = _parseCommaSeparatedValues(rawFixtureIds);
  if (ids.isEmpty) {
    return List<NaturalnessBenchmarkFixture>.unmodifiable(_cases);
  }
  return List<NaturalnessBenchmarkFixture>.unmodifiable(
    ids.map((id) {
      final fixture = benchmarkFixtureById(id);
      if (fixture is! NaturalnessBenchmarkFixture) {
        throw StateError(
          'Fixture "$id" is not a naturalness fixture. Use one of: '
          '${_cases.map((fixture) => fixture.id).join(', ')}.',
        );
      }
      return fixture;
    }),
  );
}

List<NaturalnessBenchmarkFixture> _configuredFixtures(
  Map<String, String> environment,
) {
  final rawFixtureIds = _runtimeString(
    dartDefineValue: _rawFixtureIdsFromDefine,
    environment: environment,
    key: 'NATURALNESS_FIXTURE_IDS',
    defaultValue: '',
  );
  return _resolveFixtureSubset(rawFixtureIds);
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
      _parseBooleanOptIn(environment['NATURALNESS_LIVE']);
}

class _LiveRunConfig {
  const _LiveRunConfig({
    required this.models,
    required this.cases,
    required this.outputPath,
    required this.runsPerCase,
    required this.liveRunOptIn,
  });

  final List<String> models;
  final List<NaturalnessBenchmarkFixture> cases;
  final String outputPath;
  final int runsPerCase;
  final bool liveRunOptIn;

  List<String> get caseIds => cases.map((testCase) => testCase.id).toList();
}

_LiveRunConfig _buildLiveRunConfig(Map<String, String> environment) {
  return _LiveRunConfig(
    models: _configuredModels(environment),
    cases: _configuredFixtures(environment),
    outputPath: _configuredOutputPath(environment),
    runsPerCase: _configuredRunsPerCase(environment),
    liveRunOptIn: _hasLiveRunOptIn(environment),
  );
}

String? _liveRunConfigError(_LiveRunConfig config) {
  if (config.models.isEmpty) {
    return 'Set NATURALNESS_COMPARISON_MODELS to a comma-separated list of '
        'exact OpenAI API model IDs before opting into the live run.';
  }
  if (config.cases.isEmpty) {
    return 'The naturalness live run needs at least one fixture case.';
  }
  if (config.runsPerCase < 1) {
    return 'NATURALNESS_RUNS_PER_CASE must be a positive integer.';
  }
  return null;
}

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
    'response_format': naturalnessResponseFormat,
  };
}

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

class _NaturalnessIssue {
  const _NaturalnessIssue({
    required this.span,
    required this.naturalReplacement,
    required this.explanation,
  });

  final String span;
  final String naturalReplacement;
  final String explanation;

  String get reportLabel =>
      '$span -> $naturalReplacement (${_escapeInline(explanation)})';
}

class _ParsedNaturalnessResponse {
  const _ParsedNaturalnessResponse({
    required this.validJson,
    required this.hasNaturalnessIssue,
    required this.issues,
  });

  const _ParsedNaturalnessResponse.invalid()
    : validJson = false,
      hasNaturalnessIssue = false,
      issues = const [];

  final bool validJson;
  final bool hasNaturalnessIssue;
  final List<_NaturalnessIssue> issues;
}

_ParsedNaturalnessResponse parseNaturalnessResponse(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    return const _ParsedNaturalnessResponse.invalid();
  }

  Object? decoded;
  try {
    decoded = jsonDecode(trimmed.substring(start, end + 1));
  } on FormatException {
    return const _ParsedNaturalnessResponse.invalid();
  }

  if (decoded is! Map<String, Object?>) {
    return const _ParsedNaturalnessResponse.invalid();
  }
  if (decoded.length != 2 ||
      !decoded.containsKey('has_naturalness_issue') ||
      !decoded.containsKey('issues')) {
    return const _ParsedNaturalnessResponse.invalid();
  }

  final hasNaturalnessIssue = decoded['has_naturalness_issue'];
  final rawIssues = decoded['issues'];
  if (hasNaturalnessIssue is! bool || rawIssues is! List) {
    return const _ParsedNaturalnessResponse.invalid();
  }

  final issues = <_NaturalnessIssue>[];
  for (final rawIssue in rawIssues) {
    if (rawIssue is! Map<String, Object?>) {
      return const _ParsedNaturalnessResponse.invalid();
    }
    if (rawIssue.length != 3 ||
        !rawIssue.containsKey('span') ||
        !rawIssue.containsKey('natural_replacement') ||
        !rawIssue.containsKey('explanation')) {
      return const _ParsedNaturalnessResponse.invalid();
    }
    final span = rawIssue['span'];
    final naturalReplacement = rawIssue['natural_replacement'];
    final explanation = rawIssue['explanation'];
    if (span is! String ||
        naturalReplacement is! String ||
        explanation is! String) {
      return const _ParsedNaturalnessResponse.invalid();
    }
    issues.add(
      _NaturalnessIssue(
        span: span,
        naturalReplacement: naturalReplacement,
        explanation: explanation,
      ),
    );
  }

  if (!hasNaturalnessIssue && issues.isNotEmpty) {
    return const _ParsedNaturalnessResponse.invalid();
  }
  if (hasNaturalnessIssue && issues.isEmpty) {
    return const _ParsedNaturalnessResponse.invalid();
  }

  return _ParsedNaturalnessResponse(
    validJson: true,
    hasNaturalnessIssue: hasNaturalnessIssue,
    issues: List.unmodifiable(issues),
  );
}

class _ModelCaseResult {
  const _ModelCaseResult({
    required this.model,
    required this.promptVersion,
    required this.caseId,
    required this.runNumber,
    required this.inputText,
    required this.validJson,
    required this.hasNaturalnessIssue,
    required this.issues,
    required this.latencyMs,
    this.rawResponse,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.estimatedCostUsd,
    this.error,
  });

  final String model;
  final String promptVersion;
  final String caseId;
  final int runNumber;
  final String inputText;
  final bool validJson;
  final bool hasNaturalnessIssue;
  final List<_NaturalnessIssue> issues;
  final int latencyMs;
  final String? rawResponse;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final double? estimatedCostUsd;
  final Object? error;

  bool get isError => error != null;
}

enum _ReviewStatus {
  expectedIssuesDetected('expected_issues_detected'),
  missingExpectedIssue('missing_expected_issue'),
  cleanControl('clean_control'),
  falsePositive('false_positive'),
  ignoredTrapReported('ignored_trap_reported'),
  invalidJson('invalid_json'),
  error('error');

  const _ReviewStatus(this.reportLabel);

  final String reportLabel;

  bool get isTaskSuccess =>
      this == _ReviewStatus.expectedIssuesDetected ||
      this == _ReviewStatus.cleanControl;
}

String _normalizeSpan(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[¿?¡!.,;:"“”()]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

bool _spanMatches(String expectedSpan, String actualSpan) {
  final expected = _normalizeSpan(expectedSpan);
  final actual = _normalizeSpan(actualSpan);
  return actual == expected ||
      actual.contains(expected) ||
      expected.contains(actual);
}

bool _reportsAnyIgnoredSpan(
  NaturalnessBenchmarkFixture testCase,
  _ModelCaseResult result,
) {
  return testCase.ignoredSpans.any(
    (ignoredSpan) =>
        result.issues.any((issue) => _spanMatches(ignoredSpan, issue.span)),
  );
}

bool _reportsAllExpectedIssues(
  NaturalnessBenchmarkFixture testCase,
  _ModelCaseResult result,
) {
  return testCase.expectedIssues.every(
    (expected) =>
        result.issues.any((issue) => _spanMatches(expected.span, issue.span)),
  );
}

_ReviewStatus classifyNaturalnessOutput({
  required NaturalnessBenchmarkFixture testCase,
  required _ModelCaseResult result,
}) {
  if (result.isError) {
    return _ReviewStatus.error;
  }
  if (!result.validJson) {
    return _ReviewStatus.invalidJson;
  }
  if (_reportsAnyIgnoredSpan(testCase, result)) {
    return _ReviewStatus.ignoredTrapReported;
  }
  if (testCase.expectedIssues.isEmpty) {
    return !result.hasNaturalnessIssue && result.issues.isEmpty
        ? _ReviewStatus.cleanControl
        : _ReviewStatus.falsePositive;
  }
  return result.hasNaturalnessIssue &&
          _reportsAllExpectedIssues(testCase, result)
      ? _ReviewStatus.expectedIssuesDetected
      : _ReviewStatus.missingExpectedIssue;
}

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

_ModelCaseResult _successResult({
  required String model,
  required String caseId,
  required int runNumber,
  required String inputText,
  required String rawResponse,
  required _ParsedNaturalnessResponse parsed,
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
    promptVersion: naturalnessPromptVersion,
    caseId: caseId,
    runNumber: runNumber,
    inputText: inputText,
    rawResponse: rawResponse,
    validJson: parsed.validJson,
    hasNaturalnessIssue: parsed.hasNaturalnessIssue,
    issues: parsed.issues,
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
  required int runNumber,
  required String inputText,
  required int latencyMs,
  required Object error,
}) {
  return _ModelCaseResult(
    model: model,
    promptVersion: naturalnessPromptVersion,
    caseId: caseId,
    runNumber: runNumber,
    inputText: inputText,
    validJson: false,
    hasNaturalnessIssue: false,
    issues: const [],
    latencyMs: latencyMs,
    error: error,
  );
}

Future<_ModelCaseResult> _runOnce({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required NaturalnessBenchmarkFixture testCase,
  required int runNumber,
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
            systemPromptText: naturalnessSystemPrompt,
            userText: buildNaturalnessUserPrompt(testCase.text),
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
    final parsed = parseNaturalnessResponse(replyText);
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
      runNumber: runNumber,
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
      runNumber: runNumber,
      inputText: testCase.text,
      latencyMs: stopwatch.elapsedMilliseconds,
      error: error,
    );
  }
}

String _formatCost(double? cost) {
  if (cost == null) {
    return 'unknown';
  }
  return 'verified ${cost.toStringAsFixed(6)}';
}

String _formatTokens(_ModelCaseResult result) {
  return [
    result.inputTokens?.toString() ?? '?',
    result.outputTokens?.toString() ?? '?',
    result.totalTokens?.toString() ?? '?',
  ].join('/');
}

String _escapeTableCell(String value) {
  return value
      .replaceAll('|', r'\|')
      .replaceAll('\r\n', '<br>')
      .replaceAll('\n', '<br>');
}

String _escapeInline(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', ' ');
}

String _issueListLabel(List<_NaturalnessIssue> issues) {
  if (issues.isEmpty) {
    return '(none)';
  }
  return issues
      .map(
        (issue) =>
            '${_escapeInline(issue.span)} -> '
            '${_escapeInline(issue.naturalReplacement)}',
      )
      .join('<br>');
}

String _expectedIssueLabel(NaturalnessBenchmarkFixture testCase) {
  if (testCase.expectedIssues.isEmpty) {
    return '(none)';
  }
  return testCase.expectedIssues
      .map(
        (issue) =>
            '${issue.span} -> ${issue.naturalReplacement} '
            '(${issue.issueType.reportLabel})',
      )
      .join('<br>');
}

class _ModelAggregate {
  const _ModelAggregate({
    required this.model,
    required this.totalRuns,
    required this.passed,
    required this.missingExpectedIssues,
    required this.falsePositives,
    required this.ignoredTrapReports,
    required this.invalidJson,
    required this.errors,
    required this.avgLatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.totalTokens,
    required this.totalCostUsd,
  });

  final String model;
  final int totalRuns;
  final int passed;
  final int missingExpectedIssues;
  final int falsePositives;
  final int ignoredTrapReports;
  final int invalidJson;
  final int errors;
  final double avgLatencyMs;
  final int minLatencyMs;
  final int maxLatencyMs;
  final int totalTokens;
  final double? totalCostUsd;

  String get passRateLabel {
    if (totalRuns == 0) {
      return '0.0% (0/0)';
    }
    return '${(passed / totalRuns * 100).toStringAsFixed(1)}% '
        '($passed/$totalRuns)';
  }
}

List<_ModelAggregate> _aggregateModelResults({
  required _LiveRunConfig config,
  required List<_ModelCaseResult> allResults,
}) {
  return config.models
      .map((model) {
        final modelResults = allResults
            .where((result) => result.model == model)
            .toList(growable: false);
        final statusCounts = <_ReviewStatus, int>{};
        var passed = 0;
        for (final result in modelResults) {
          final testCase = config.cases.firstWhere(
            (item) => item.id == result.caseId,
          );
          final status = classifyNaturalnessOutput(
            testCase: testCase,
            result: result,
          );
          statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          if (status.isTaskSuccess) {
            passed++;
          }
        }

        final latencies = modelResults
            .map((result) => result.latencyMs)
            .toList();
        final avgLatency = latencies.isEmpty
            ? 0.0
            : latencies.reduce((a, b) => a + b) / latencies.length;
        final minLatency = latencies.isEmpty
            ? 0
            : latencies.reduce((a, b) => a < b ? a : b);
        final maxLatency = latencies.isEmpty
            ? 0
            : latencies.reduce((a, b) => a > b ? a : b);
        final totalTokens = modelResults.fold<int>(
          0,
          (sum, result) => sum + (result.totalTokens ?? 0),
        );
        final totalCost = modelResults.fold<double?>(
          null,
          (sum, result) => result.estimatedCostUsd == null
              ? sum
              : (sum ?? 0) + result.estimatedCostUsd!,
        );

        return _ModelAggregate(
          model: model,
          totalRuns: modelResults.length,
          passed: passed,
          missingExpectedIssues:
              statusCounts[_ReviewStatus.missingExpectedIssue] ?? 0,
          falsePositives: statusCounts[_ReviewStatus.falsePositive] ?? 0,
          ignoredTrapReports:
              statusCounts[_ReviewStatus.ignoredTrapReported] ?? 0,
          invalidJson: statusCounts[_ReviewStatus.invalidJson] ?? 0,
          errors: statusCounts[_ReviewStatus.error] ?? 0,
          avgLatencyMs: avgLatency,
          minLatencyMs: minLatency,
          maxLatencyMs: maxLatency,
          totalTokens: totalTokens,
          totalCostUsd: totalCost,
        );
      })
      .toList(growable: false);
}

String _leaderLabel(
  List<_ModelAggregate> aggregates, {
  required num Function(_ModelAggregate aggregate) value,
  required bool lowerIsBetter,
}) {
  if (aggregates.isEmpty) {
    return '(none)';
  }
  final ordered = [...aggregates]
    ..sort((left, right) {
      final comparison = value(left).compareTo(value(right));
      return lowerIsBetter ? comparison : -comparison;
    });
  final bestValue = value(ordered.first);
  final leaders = ordered
      .where((aggregate) => value(aggregate).compareTo(bestValue) == 0)
      .map((aggregate) => '`${aggregate.model}`')
      .join(', ');
  return leaders;
}

String _differenceLabel(num left, num right, String unit) {
  final difference = (left - right).abs();
  if (difference == 0) {
    return 'tied';
  }
  final formatted = difference is int
      ? difference.toString()
      : difference.toStringAsFixed(1);
  return '$formatted $unit';
}

String _buildCompareAndContrastSection({
  required _LiveRunConfig config,
  required List<_ModelCaseResult> allResults,
}) {
  final aggregates = _aggregateModelResults(
    config: config,
    allResults: allResults,
  );
  final buffer = StringBuffer()
    ..writeln()
    ..writeln('## Compare and contrast')
    ..writeln()
    ..writeln(
      '| Model | Pass rate | Failed expected-issue runs | False-positive control runs | Ignored grammar/spelling trap runs | Invalid/error runs | Avg latency (ms) | Total tokens | Total est. cost (USD) |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');

  for (final aggregate in aggregates) {
    buffer.writeln(
      '| ${aggregate.model} | ${aggregate.passRateLabel} | '
      '${aggregate.missingExpectedIssues} | ${aggregate.falsePositives} | '
      '${aggregate.ignoredTrapReports} | '
      '${aggregate.invalidJson + aggregate.errors} | '
      '${aggregate.avgLatencyMs.toStringAsFixed(1)} | '
      '${aggregate.totalTokens} | ${_formatCost(aggregate.totalCostUsd)} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('### Direct readout')
    ..writeln();

  if (aggregates.length < 2) {
    buffer.writeln(
      '- Only one model was run, so there is no direct model contrast.',
    );
    return buffer.toString();
  }

  final first = aggregates[0];
  final second = aggregates[1];
  final promptAdjustmentSignals = aggregates.fold<int>(
    0,
    (sum, aggregate) =>
        sum +
        aggregate.missingExpectedIssues +
        aggregate.falsePositives +
        aggregate.ignoredTrapReports,
  );

  buffer
    ..writeln(
      '- Accuracy leader: ${_leaderLabel(aggregates, value: (aggregate) => aggregate.passed, lowerIsBetter: false)} '
      '(${_differenceLabel(first.passed, second.passed, 'run(s)')} between '
      '`${first.model}` and `${second.model}`).',
    )
    ..writeln(
      '- False-positive control leader: ${_leaderLabel(aggregates, value: (aggregate) => aggregate.falsePositives + aggregate.ignoredTrapReports, lowerIsBetter: true)}.',
    )
    ..writeln(
      '- Latency leader: ${_leaderLabel(aggregates, value: (aggregate) => aggregate.avgLatencyMs, lowerIsBetter: true)}.',
    )
    ..writeln(
      '- Token-use leader: ${_leaderLabel(aggregates, value: (aggregate) => aggregate.totalTokens, lowerIsBetter: true)}.',
    );

  final costs = aggregates.where((aggregate) => aggregate.totalCostUsd != null);
  if (costs.length == aggregates.length) {
    buffer.writeln(
      '- Cost leader: ${_leaderLabel(aggregates, value: (aggregate) => aggregate.totalCostUsd!, lowerIsBetter: true)}.',
    );
  } else {
    buffer.writeln(
      '- Cost leader: unavailable because at least one model has unknown cost.',
    );
  }

  if (promptAdjustmentSignals == 0) {
    buffer.writeln(
      '- Prompt adjustment signal: none from this run; model choice can be '
      'judged on latency, cost, and output consistency.',
    );
  } else {
    buffer.writeln(
      '- Prompt adjustment signal: inspect failed expected-issue, control, '
      'and trap rows before changing the prompt; repeated failures point to '
      'candidate prompt boundaries.',
    );
  }

  return buffer.toString();
}

String _buildReport({
  required _LiveRunConfig config,
  required Map<String, Map<String, List<_ModelCaseResult>>>
  resultsByCaseThenModel,
}) {
  final buffer = StringBuffer()
    ..writeln('# Spanish Naturalness Model Comparison Harness')
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- Prompt label: `$naturalnessPromptLabel`')
    ..writeln('- Prompt version: `$naturalnessPromptVersion`')
    ..writeln('- Models: `${config.models.join('`, `')}`')
    ..writeln('- Fixture case ids: `${config.caseIds.join('`, `')}`')
    ..writeln('- Runs per model/fixture case: `${config.runsPerCase}`')
    ..writeln('- Generated: ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln(
      '- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`',
    )
    ..writeln()
    ..write(pricing.pricingSection(config.models))
    ..writeln();

  for (final testCase in config.cases) {
    buffer
      ..writeln('## ${testCase.id}')
      ..writeln()
      ..writeln('- Input text: `${testCase.text}`')
      ..writeln('- Note: ${testCase.note}')
      ..writeln(
        '- Expected naturalness issue(s): ${_expectedIssueLabel(testCase)}',
      );
    if (testCase.ignoredSpans.isNotEmpty) {
      buffer.writeln(
        '- Must ignore span(s): `${testCase.ignoredSpans.join('`, `')}`',
      );
    }
    buffer
      ..writeln()
      ..writeln(
        '| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');

    for (final model in config.models) {
      final results = resultsByCaseThenModel[testCase.id]?[model] ?? const [];
      final statuses = results
          .map(
            (result) =>
                classifyNaturalnessOutput(testCase: testCase, result: result),
          )
          .toList(growable: false);
      final passed = statuses.where((status) => status.isTaskSuccess).length;
      final issueOutputs = results
          .map((result) => _issueListLabel(result.issues))
          .toSet()
          .toList(growable: false);
      final latencies = results.map((result) => result.latencyMs).toList();
      final totalTokens = results.fold<int>(
        0,
        (sum, result) => sum + (result.totalTokens ?? 0),
      );
      final totalCost = results.fold<double?>(
        null,
        (sum, result) => result.estimatedCostUsd == null
            ? sum
            : (sum ?? 0) + result.estimatedCostUsd!,
      );
      final avgLatency = latencies.isEmpty
          ? 0
          : latencies.reduce((a, b) => a + b) / latencies.length;
      final minLatency = latencies.isEmpty
          ? 0
          : latencies.reduce((a, b) => a < b ? a : b);
      final maxLatency = latencies.isEmpty
          ? 0
          : latencies.reduce((a, b) => a > b ? a : b);

      buffer.writeln(
        '| $model | $passed/${results.length} | ${issueOutputs.length <= 1} | '
        '${_escapeTableCell(issueOutputs.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('<br>'))} | '
        '${avgLatency.toStringAsFixed(1)} | $minLatency | $maxLatency | '
        '$totalTokens | ${_formatCost(totalCost)} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('### Individual runs')
      ..writeln()
      ..writeln(
        '| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
      );

    for (final model in config.models) {
      final results = resultsByCaseThenModel[testCase.id]?[model] ?? const [];
      for (final result in results) {
        final status = classifyNaturalnessOutput(
          testCase: testCase,
          result: result,
        );
        buffer.writeln(
          '| ${result.model} | ${testCase.id} | ${result.runNumber} | '
          '${_escapeTableCell(testCase.text)} | '
          '${_escapeTableCell(_expectedIssueLabel(testCase))} | '
          '${_escapeTableCell(_issueListLabel(result.issues))} | '
          '${result.hasNaturalnessIssue} | '
          '${status.isTaskSuccess ? 'PASS' : 'FAIL'} | '
          '${result.validJson} | ${status.reportLabel} | '
          '${result.latencyMs} | ${_formatTokens(result)} | '
          '${_formatCost(result.estimatedCostUsd)} | '
          '${_escapeTableCell(result.rawResponse ?? result.error.toString())} |',
        );
      }
    }
    buffer.writeln();
  }

  final allResults = [
    for (final byModel in resultsByCaseThenModel.values)
      for (final results in byModel.values) ...results,
  ];
  final aggregates = _aggregateModelResults(
    config: config,
    allResults: allResults,
  );

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall model aggregates')
    ..writeln()
    ..writeln(
      '| Model | Total runs | Total passed | Pass rate | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- | --- |');

  for (final aggregate in aggregates) {
    buffer.writeln(
      '| ${aggregate.model} | ${aggregate.totalRuns} | '
      '${aggregate.passed} | ${aggregate.passRateLabel} | '
      '${aggregate.avgLatencyMs.toStringAsFixed(1)} | '
      '${aggregate.minLatencyMs} | ${aggregate.maxLatencyMs} | '
      '${aggregate.totalTokens} | ${_formatCost(aggregate.totalCostUsd)} |',
    );
  }

  buffer.write(
    _buildCompareAndContrastSection(config: config, allResults: allResults),
  );

  return buffer.toString();
}

Future<void> _writeReport(String path, String contents) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

void main() {
  group('naturalness fixture configuration', () {
    test('uses the shared naturalness fixture set by default', () {
      expect(_cases, same(naturalnessModelComparisonFixtures));
      expect(_cases, hasLength(12));
    });

    test('resolves naturalness fixture ids only', () {
      final fixtures = _resolveFixtureSubset(
        'naturalness-calque-llamar-para-atras,naturalness-es3-multi-correction',
      );
      expect(fixtures.map((fixture) => fixture.id), [
        'naturalness-calque-llamar-para-atras',
        'naturalness-es3-multi-correction',
      ]);
    });

    test('rejects non-naturalness fixture ids', () {
      expect(
        () => _resolveFixtureSubset('boundary-redundant-yo'),
        throwsA(isA<StateError>()),
      );
    });

    test('parses runs per case', () {
      expect(_parseRunsPerCase(''), 1);
      expect(_parseRunsPerCase(' 5 '), 5);
      expect(() => _parseRunsPerCase('0'), throwsA(isA<StateError>()));
    });
  });

  group('naturalness prompt and schema', () {
    test('prompt states the naturalness-only scope', () {
      expect(naturalnessPromptVersion, 'v4');
      expect(
        naturalnessSystemPrompt,
        contains('checked for grammar, spelling, and punctuation'),
      );
      expect(naturalnessSystemPrompt, contains('calques'));
      expect(naturalnessSystemPrompt, contains('idioms, and collocations'));
      expect(naturalnessSystemPrompt, contains('Do not report spelling'));
      expect(
        naturalnessSystemPrompt,
        contains('If the only problem is grammar, spelling, or punctuation'),
      );
      expect(
        naturalnessSystemPrompt,
        contains('Do not normalise wording that is natural'),
      );
      expect(
        naturalnessSystemPrompt,
        contains('preferred by the reviewer\'s own regional variety'),
      );
    });

    test(
      'prompt requires exactly one replacement, never a slash-separated '
      'menu of options (issue #108)',
      () {
        expect(
          naturalnessSystemPrompt,
          contains('Give exactly one natural replacement'),
        );
        expect(
          naturalnessSystemPrompt,
          contains('never join alternatives with a slash'),
        );
      },
    );

    test(
      'keeps previous naturalness prompts available for regression runs',
      () {
        expect(legacyNaturalnessSystemPrompt, contains('only for naturalness'));
        expect(
          legacyNaturalnessSystemPrompt,
          contains('Do not provide a fully corrected'),
        );
        expect(
          previousNaturalnessSystemPromptV3,
          contains('checked for grammar, spelling, and punctuation'),
        );
        expect(
          previousNaturalnessSystemPromptV3,
          isNot(contains('Give exactly one natural replacement')),
        );
        expect(
          previousNaturalnessSystemPrompt,
          contains('established regional variety of Spanish'),
        );
        expect(
          previousNaturalnessSystemPrompt,
          contains('Do not replace it merely because another form'),
        );
      },
    );

    test('request body includes the naturalness JSON schema', () {
      final body = buildChatCompletionsBody(
        model: 'gpt-4.1-mini',
        systemPromptText: naturalnessSystemPrompt,
        userText: buildNaturalnessUserPrompt('Hola.'),
      );
      expect(body['model'], 'gpt-4.1-mini');
      expect(body['response_format'], naturalnessResponseFormat);
    });
  });

  group('parseNaturalnessResponse', () {
    test('parses a clean no-issue response', () {
      final parsed = parseNaturalnessResponse(
        '{"has_naturalness_issue": false, "issues": []}',
      );
      expect(parsed.validJson, isTrue);
      expect(parsed.hasNaturalnessIssue, isFalse);
      expect(parsed.issues, isEmpty);
    });

    test('parses issue responses', () {
      final parsed = parseNaturalnessResponse(
        '{"has_naturalness_issue": true, "issues": ['
        '{"span": "llamaron para atrás", '
        '"natural_replacement": "devolvieron la llamada", '
        '"explanation": "This is a literal calque."}]}',
      );
      expect(parsed.validJson, isTrue);
      expect(parsed.hasNaturalnessIssue, isTrue);
      expect(parsed.issues.single.span, 'llamaron para atrás');
    });

    test('rejects extra fields and inconsistent issue state', () {
      expect(
        parseNaturalnessResponse(
          '{"has_naturalness_issue": false, "issues": [], "extra": 1}',
        ).validJson,
        isFalse,
      );
      expect(
        parseNaturalnessResponse(
          '{"has_naturalness_issue": false, "issues": ['
          '{"span": "x", "natural_replacement": "y", "explanation": "z"}]}',
        ).validJson,
        isFalse,
      );
    });
  });

  group('classifyNaturalnessOutput', () {
    _ModelCaseResult resultFor({
      required NaturalnessBenchmarkFixture fixture,
      required bool hasIssue,
      required List<_NaturalnessIssue> issues,
    }) {
      return _ModelCaseResult(
        model: 'gpt-4.1-mini',
        promptVersion: naturalnessPromptVersion,
        caseId: fixture.id,
        runNumber: 1,
        inputText: fixture.text,
        validJson: true,
        hasNaturalnessIssue: hasIssue,
        issues: issues,
        latencyMs: 100,
      );
    }

    test('passes expected naturalness issue detection', () {
      final fixture = naturalnessEs3MultiCorrection;
      final result = resultFor(
        fixture: fixture,
        hasIssue: true,
        issues: const [
          _NaturalnessIssue(
            span: 'mis amigos llamaron para atrás',
            naturalReplacement: 'mis amigos devolvieron la llamada',
            explanation: 'Literal calque.',
          ),
        ],
      );
      expect(
        classifyNaturalnessOutput(testCase: fixture, result: result),
        _ReviewStatus.expectedIssuesDetected,
      );
    });

    test('fails if an ignored spelling or grammar trap is reported', () {
      final fixture = naturalnessEs3MultiCorrection;
      final result = resultFor(
        fixture: fixture,
        hasIssue: true,
        issues: const [
          _NaturalnessIssue(
            span: 'trafico',
            naturalReplacement: 'tráfico',
            explanation: 'Missing accent.',
          ),
        ],
      );
      expect(
        classifyNaturalnessOutput(testCase: fixture, result: result),
        _ReviewStatus.ignoredTrapReported,
      );
    });

    test('passes clean controls and grammar traps with no issues', () {
      final fixture = naturalnessGrammarTrapGustar;
      final result = resultFor(
        fixture: fixture,
        hasIssue: false,
        issues: const [],
      );
      expect(
        classifyNaturalnessOutput(testCase: fixture, result: result),
        _ReviewStatus.cleanControl,
      );
    });
  });

  group('report summary', () {
    _ModelCaseResult resultFor({
      required String model,
      required NaturalnessBenchmarkFixture fixture,
      required int runNumber,
      required List<_NaturalnessIssue> issues,
      required int latencyMs,
    }) {
      return _ModelCaseResult(
        model: model,
        promptVersion: naturalnessPromptVersion,
        caseId: fixture.id,
        runNumber: runNumber,
        inputText: fixture.text,
        validJson: true,
        hasNaturalnessIssue: issues.isNotEmpty,
        issues: issues,
        latencyMs: latencyMs,
        inputTokens: 200,
        outputTokens: 50,
        totalTokens: 250,
        estimatedCostUsd: estimateCostUsd(
          model: model,
          inputTokens: 200,
          outputTokens: 50,
        ),
      );
    }

    test('adds a compare and contrast section for focused model runs', () {
      final config = _LiveRunConfig(
        models: const ['gpt-5.1', 'gpt-5.3-chat-latest'],
        cases: const [naturalnessEs4CalquePair, naturalnessControlParaCasa],
        outputPath: 'docs/naturalness_gpt_51_vs_53_live.md',
        runsPerCase: 1,
        liveRunOptIn: true,
      );
      final report = _buildReport(
        config: config,
        resultsByCaseThenModel: {
          naturalnessEs4CalquePair.id: {
            'gpt-5.1': [
              resultFor(
                model: 'gpt-5.1',
                fixture: naturalnessEs4CalquePair,
                runNumber: 1,
                issues: const [
                  _NaturalnessIssue(
                    span: 'pasar un buen tiempo',
                    naturalReplacement: 'pasarlo bien',
                    explanation: 'Literal calque.',
                  ),
                ],
                latencyMs: 2000,
              ),
            ],
            'gpt-5.3-chat-latest': [
              resultFor(
                model: 'gpt-5.3-chat-latest',
                fixture: naturalnessEs4CalquePair,
                runNumber: 1,
                issues: const [
                  _NaturalnessIssue(
                    span: 'Puedo tener una cerveza',
                    naturalReplacement: 'Me pones una cerveza',
                    explanation: 'Literal request form.',
                  ),
                  _NaturalnessIssue(
                    span: 'pasar un buen tiempo',
                    naturalReplacement: 'pasarlo bien',
                    explanation: 'Literal calque.',
                  ),
                ],
                latencyMs: 3000,
              ),
            ],
          },
          naturalnessControlParaCasa.id: {
            'gpt-5.1': [
              resultFor(
                model: 'gpt-5.1',
                fixture: naturalnessControlParaCasa,
                runNumber: 1,
                issues: const [],
                latencyMs: 1500,
              ),
            ],
            'gpt-5.3-chat-latest': [
              resultFor(
                model: 'gpt-5.3-chat-latest',
                fixture: naturalnessControlParaCasa,
                runNumber: 1,
                issues: const [],
                latencyMs: 2500,
              ),
            ],
          },
        },
      );

      expect(report, contains('## Compare and contrast'));
      expect(report, contains('| gpt-5.1 | 50.0% (1/2) | 1 | 0 | 0 | 0 |'));
      expect(
        report,
        contains('| gpt-5.3-chat-latest | 100.0% (2/2) | 0 | 0 | 0 | 0 |'),
      );
      expect(report, contains('Accuracy leader: `gpt-5.3-chat-latest`'));
      expect(report, contains('Prompt adjustment signal: inspect failed'));
    });
  });

  test('naturalness model comparison harness (live)', tags: 'live', () async {
    final config = _buildLiveRunConfig(Platform.environment);

    if (!config.liveRunOptIn) {
      // ignore: avoid_print
      print(
        'Skipping live naturalness comparison. Set NATURALNESS_LIVE=true '
        'and NATURALNESS_COMPARISON_MODELS=<exact OpenAI API model IDs> '
        'to opt in.',
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
        'Set OPENAI_API_KEY to run the naturalness comparison harness. This '
        'script does NOT fall back to any hardcoded/default key.',
      );
    }

    final httpClient = HttpClient();
    final resultsByCaseThenModel =
        <String, Map<String, List<_ModelCaseResult>>>{};

    try {
      for (final testCase in config.cases) {
        final resultsByModel = <String, List<_ModelCaseResult>>{};
        // ignore: avoid_print
        print('=== ${testCase.id} ===');

        for (final model in config.models) {
          final modelResults = <_ModelCaseResult>[];
          for (
            var runNumber = 1;
            runNumber <= config.runsPerCase;
            runNumber++
          ) {
            final result = await _runOnce(
              httpClient: httpClient,
              apiKey: apiKey,
              model: model,
              testCase: testCase,
              runNumber: runNumber,
            );
            modelResults.add(result);
            final status = classifyNaturalnessOutput(
              testCase: testCase,
              result: result,
            );
            // ignore: avoid_print
            print(
              '$model run $runNumber: ${status.reportLabel} '
              '(${result.latencyMs} ms) ${_issueListLabel(result.issues)}',
            );
            if (callDelayMs > 0) {
              await Future<void>.delayed(Duration(milliseconds: callDelayMs));
            }
          }
          resultsByModel[model] = modelResults;
        }

        resultsByCaseThenModel[testCase.id] = resultsByModel;
      }
    } finally {
      httpClient.close(force: true);
    }

    final report = _buildReport(
      config: config,
      resultsByCaseThenModel: resultsByCaseThenModel,
    );
    await _writeReport(config.outputPath, report);
    // ignore: avoid_print
    print('Wrote naturalness model comparison report to ${config.outputPath}');
  });
}
