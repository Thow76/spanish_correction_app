// Para + destination battery — standalone extraction.
//
// Investigating whether "motion verb + para + destination" (e.g. "volví
// para casa") is genuinely unstable in Stage 2 verdict output
// (`stage2CategorizationSpanish`, lib/core/services/prompts/correction_prompt.dart).
//
// The five cases below (PD-anchor, PD-T1, PD-T2, PD-T3, PD-neg) are copied
// by value, verbatim — same id, text, flaggedPhrase, note, and reusedKind —
// from the "para + destination" family inside `test/verdict_battery_merged.dart`
// (itself reused, per that file's own header, from
// `peninsular_norms_battery.dart`). Pulled into this standalone file so this
// investigation doesn't require running that file's full 37-case suite
// every time. No wording changed, no cases added or reinterpreted.
//
// Harness structure replicated from `verdict_battery_merged.dart`: the same
// `_Case` shape (minus the multi-family `_Section` enum and the
// catch-rate/`acceptedVerdicts`/`expectedCategory` scoring machinery — none
// of these five cases use either; they are convergence-only, exactly as
// they are in the merged file), the same raw `dart:io` `HttpClient` POST to
// `/v1/chat/completions` with `stage2CategorizationSpanish` as the system
// prompt (`_buildChatCompletionsBody`/`_extractReplyText`/
// `_parseCategorizationArray` copied by value), the same `_matchResultFor`/
// `_RunRecord`/`_aggregateCase` (verdict + category distribution,
// convergence % = max-count / total), and the same anchor/transfer/negative
// convergence rollup table (transfer convergence averaged across
// PD-T1/PD-T2/PD-T3) as `verdict_battery_merged.dart`'s
// `_FamilyRollup`/`_rollupFamily`.
//
// No prompt changes at this stage — this file only measures the existing
// `stage2CategorizationSpanish` prompt's behavior.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/para_destination_battery.dart --exclude-tags live
//
// Run everything, including the live battery (costs real API calls — 5
// cases * 10 runs = 50 calls):
//   OPENAI_API_KEY=sk-... flutter test test/para_destination_battery.dart --timeout none
//
// Writes a report to docs/para_destination_battery.md (override with
// --dart-define=PARA_DESTINATION_BATTERY_OUTPUT=...). Override run count per
// case with --dart-define=PARA_DESTINATION_BATTERY_RUNS_PER_CASE=... (default
// 10). Override the model with
// --dart-define=PARA_DESTINATION_BATTERY_MODEL=... (default 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'PARA_DESTINATION_BATTERY_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'PARA_DESTINATION_BATTERY_OUTPUT',
  defaultValue: 'docs/para_destination_battery.md',
);

const String paraDestinationBatteryModel = String.fromEnvironment(
  'PARA_DESTINATION_BATTERY_MODEL',
  defaultValue: 'gpt-5.5',
);

const int callDelayMs = int.fromEnvironment(
  'PARA_DESTINATION_BATTERY_CALL_DELAY_MS',
  defaultValue: 750,
);

const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};

/// A case's role within the para+destination family. Drives the
/// anchor/transfer/negative rollup table, same metric as
/// `verdict_battery_merged.dart`'s `_FamilyRollup`.
enum _ReusedKind { anchor, transfer, negative }

String _kindLabel(_ReusedKind kind) => switch (kind) {
  _ReusedKind.anchor => 'Anchor',
  _ReusedKind.transfer => 'Transfer',
  _ReusedKind.negative => 'Negative',
};

/// One test case: a full text plus a single flagged phrase. Convergence-only
/// — no ground truth (`acceptedVerdicts`/`expectedCategory`) is scored here,
/// same as these five cases in `verdict_battery_merged.dart`.
class _Case {
  const _Case({
    required this.id,
    required this.reusedKind,
    required this.text,
    required this.flaggedPhrase,
    required this.note,
  });

  final String id;
  final _ReusedKind reusedKind;
  final String text;
  final String flaggedPhrase;
  final String note;
}

const List<_Case> _cases = [
  _Case(
    id: 'PD-anchor',
    reusedKind: _ReusedKind.anchor,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    flaggedPhrase: 'volví para casa',
    note:
        'Same text as ES-1 in stage2_categorization_harness.dart, reused '
        'verbatim as the anchor for continuity with the already-measured '
        'baseline (30% verdict convergence live, per '
        'docs/stage2_categorization_harness.md).',
  ),
  _Case(
    id: 'PD-T1',
    reusedKind: _ReusedKind.transfer,
    text: 'Ya era tarde cuando vine para casa.',
    flaggedPhrase: 'vine para casa',
    note: 'Same "para + destination" construction, different verb.',
  ),
  _Case(
    id: 'PD-T2',
    reusedKind: _ReusedKind.transfer,
    text: 'Subió para la oficina en cuanto llegó.',
    flaggedPhrase: 'Subió para la oficina',
    note: 'Same construction, different destination and verb.',
  ),
  _Case(
    id: 'PD-T3',
    reusedKind: _ReusedKind.transfer,
    text: 'Al terminar el partido, regresamos para el pueblo.',
    flaggedPhrase: 'regresamos para el pueblo',
    note: 'Same construction, different destination and verb.',
  ),
  _Case(
    id: 'PD-neg',
    reusedKind: _ReusedKind.negative,
    text: 'Ya era tarde cuando volví a casa.',
    flaggedPhrase: 'volví a casa',
    note:
        'The accepted Peninsular form of the anchor construction (its own '
        'corrected_phrase). Must not be flagged at all.',
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Duplicated by value from
/// `verdict_battery_merged.dart`'s `_normalizeForMatch`.
String _normalizeForMatch(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâã]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöôõ]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c');
}

/// Case/diacritic-insensitive containment check in either direction.
/// Duplicated by value from `verdict_battery_merged.dart`'s
/// `_normalizedOverlap`.
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Builds the user-message content sent alongside `stage2CategorizationSpanish`:
/// the case's full text plus a JSON array containing its single flagged
/// phrase. Pure — no network. Duplicated by value from
/// `verdict_battery_merged.dart`'s `_buildUserContent`.
String _buildUserContent({required String fullText, required String flaggedPhrase}) {
  return '''
Learner's text:
$fullText

Flagged phrases:
${jsonEncode([flaggedPhrase])}
''';
}

/// One flagged phrase's categorization, as returned by Stage 2.
class _CategorizationResult {
  const _CategorizationResult({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.occurrence,
    required this.category,
    required this.verdict,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final int occurrence;
  final String? category;
  final String verdict;
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. Duplicated by value from `verdict_battery_merged.dart`'s
/// `_buildChatCompletionsBody`.
Map<String, Object?> _buildChatCompletionsBody({
  required String model,
  required String systemPrompt,
  required String userText,
}) {
  return {
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userText},
    ],
  };
}

/// Extracts the assistant's reply text from a decoded chat completions
/// response body. Duplicated by value from `verdict_battery_merged.dart`'s
/// `_extractReplyText`.
String _extractReplyText(Map<String, Object?> decodedBody) {
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

/// Parses a Stage 2 reply into [_CategorizationResult]s. Duplicated by value
/// from `verdict_battery_merged.dart`'s `_parseCategorizationArray`, same
/// tolerance for Markdown fences / commentary.
List<_CategorizationResult> _parseCategorizationArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 2 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('Stage 2 reply array did not decode to a List.');
  }

  return decoded.map((element) {
    if (element is! Map<String, Object?>) {
      throw FormatException(
        'Stage 2 reply array contained a non-object element: $element',
      );
    }

    final originalPhrase = element['original_phrase'];
    final correctedPhrase = element['corrected_phrase'];
    final occurrence = element['occurrence'];
    final category = element['category'];
    final verdict = element['verdict'];

    if (originalPhrase is! String || originalPhrase.isEmpty) {
      throw FormatException(
        'Stage 2 result missing/invalid original_phrase: $element',
      );
    }
    if (correctedPhrase is! String) {
      throw FormatException(
        'Stage 2 result missing/invalid corrected_phrase: $element',
      );
    }
    if (occurrence is! num || occurrence != occurrence.roundToDouble()) {
      throw FormatException('Stage 2 result missing/invalid occurrence: $element');
    }
    if (category != null && category is! String) {
      throw FormatException('Stage 2 result has a non-string category: $element');
    }
    if (verdict is! String || !_validVerdicts.contains(verdict)) {
      throw FormatException('Stage 2 result has an invalid verdict: $element');
    }

    return _CategorizationResult(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      occurrence: occurrence.round(),
      category: category as String?,
      verdict: verdict,
    );
  }).toList();
}

/// Finds the result in [results] whose `originalPhrase` overlaps
/// [flaggedPhrase], or null if Stage 2 didn't return a matching object.
/// Duplicated by value from `verdict_battery_merged.dart`'s
/// `_matchResultFor`.
_CategorizationResult? _matchResultFor(
  List<_CategorizationResult> results,
  String flaggedPhrase,
) {
  for (final result in results) {
    if (_normalizedOverlap(flaggedPhrase, result.originalPhrase)) {
      return result;
    }
  }
  return null;
}

/// One run's outcome for one case.
class _RunRecord {
  const _RunRecord({required this.caseId, required this.runIndex, this.result, this.error});

  final String caseId;
  final int runIndex;
  final _CategorizationResult? result;
  final Object? error;

  bool get isError => error != null;
}

_RunRecord _buildRunRecord({
  required _Case testCase,
  required int runIndex,
  required List<_CategorizationResult> results,
}) {
  return _RunRecord(
    caseId: testCase.id,
    runIndex: runIndex,
    result: _matchResultFor(results, testCase.flaggedPhrase),
  );
}

_RunRecord _errorRunRecord({
  required _Case testCase,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(caseId: testCase.id, runIndex: runIndex, error: error);
}

String _distKey(String? value) => value ?? '(none)';

/// Aggregated results for one case across all its non-error runs:
/// verdict/category distribution and convergence % (max-count / total).
/// Convergence-only — no catch-rate fields, since none of these five cases
/// carry ground truth.
class _Aggregate {
  const _Aggregate({
    required this.caseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.okRunCount,
    required this.verdictDistribution,
    required this.categoryDistribution,
    required this.verdictConvergencePct,
    required this.categoryConvergencePct,
  });

  final String caseId;
  final int totalRuns;
  final int errorRuns;
  final int okRunCount;
  final Map<String, int> verdictDistribution;
  final Map<String, int> categoryDistribution;
  final double verdictConvergencePct;
  final double categoryConvergencePct;
}

int _maxCount(Map<String, int> distribution) {
  if (distribution.isEmpty) {
    return 0;
  }
  return distribution.values.reduce((a, b) => a > b ? a : b);
}

double _convergencePct(Map<String, int> distribution, int total) {
  if (total == 0 || distribution.isEmpty) {
    return 0.0;
  }
  return _maxCount(distribution) / total * 100;
}

_Aggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  final errorCount = records.length - okRecords.length;

  final verdictDist = <String, int>{};
  final categoryDist = <String, int>{};

  for (final record in okRecords) {
    final verdictKey = record.result == null ? '(missing)' : record.result!.verdict;
    verdictDist[verdictKey] = (verdictDist[verdictKey] ?? 0) + 1;

    final categoryKey = record.result == null ? '(missing)' : _distKey(record.result!.category);
    categoryDist[categoryKey] = (categoryDist[categoryKey] ?? 0) + 1;
  }

  return _Aggregate(
    caseId: testCase.id,
    totalRuns: records.length,
    errorRuns: errorCount,
    okRunCount: okRecords.length,
    verdictDistribution: verdictDist,
    categoryDistribution: categoryDist,
    verdictConvergencePct: _convergencePct(verdictDist, okRecords.length),
    categoryConvergencePct: _convergencePct(categoryDist, okRecords.length),
  );
}

String _percentLabel(int count, int total) {
  if (total == 0) {
    return '0.0% (0/0)';
  }
  final pct = (count / total * 100).toStringAsFixed(1);
  return '$pct% ($count/$total)';
}

String _describeDistribution(Map<String, int> counts) {
  if (counts.isEmpty) {
    return '(none)';
  }
  final entries = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((e) => '${e.key}: ${e.value}').join(', ');
}

String _describeError(Object error) => error.toString();

String _describeRun(_RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }
  final result = record.result;
  if (result == null) {
    return '- $prefix: (no matching result returned)';
  }
  return '- $prefix: verdict=${result.verdict}, category=${_distKey(result.category)}, '
      'occurrence=${result.occurrence}';
}

/// The family's anchor/transfer/negative convergence rollup — same metric as
/// `verdict_battery_merged.dart`'s `_FamilyRollup`, for this one family only
/// (transfer convergence averaged across PD-T1/PD-T2/PD-T3).
class _FamilyRollup {
  const _FamilyRollup({
    required this.anchorPct,
    required this.transferPct,
    required this.negativePct,
  });

  final double anchorPct;
  final double transferPct;
  final double negativePct;

  double get gap => anchorPct - transferPct;
}

double _average(Iterable<double> values) {
  final list = values.toList();
  if (list.isEmpty) {
    return 0.0;
  }
  return list.reduce((a, b) => a + b) / list.length;
}

_FamilyRollup _rollupFamily(List<_Case> cases, Map<String, _Aggregate> aggregatesById) {
  double pctFor(_ReusedKind kind) => _average(
    cases
        .where((c) => c.reusedKind == kind)
        .map((c) => aggregatesById[c.id]!.verdictConvergencePct),
  );

  return _FamilyRollup(
    anchorPct: pctFor(_ReusedKind.anchor),
    transferPct: pctFor(_ReusedKind.transfer),
    negativePct: pctFor(_ReusedKind.negative),
  );
}

/// Builds the full markdown report: header, one section per case (metadata,
/// verdict/category distributions with convergence, run-by-run detail),
/// then the anchor/transfer/negative convergence rollup table.
///
/// Pure — takes already-collected [recordsByCaseId] rather than making any
/// calls itself, so it's golden-testable against synthetic data.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final aggregatesById = {
    for (final testCase in cases)
      testCase.id: _aggregateCase(testCase, recordsByCaseId[testCase.id] ?? const []),
  };

  final report = StringBuffer()
    ..writeln('# Para + Destination Battery')
    ..writeln()
    ..writeln(
      'Standalone extraction of the "para + destination" family from '
      '`verdict_battery_merged.dart` (PD-anchor, PD-T1, PD-T2, PD-T3, '
      'PD-neg), for investigating whether this construction is genuinely '
      'unstable in `stage2CategorizationSpanish` verdict output, without '
      'running the full 37-case merged suite.',
    )
    ..writeln()
    ..writeln('Model: `$model`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per case: $runsPerCase')
    ..writeln();

  for (final testCase in cases) {
    final aggregate = aggregatesById[testCase.id]!;
    final records = recordsByCaseId[testCase.id] ?? const <_RunRecord>[];

    report
      ..writeln('## ${testCase.id} (${_kindLabel(testCase.reusedKind)})')
      ..writeln()
      ..writeln('- Text: `${testCase.text}`')
      ..writeln('- Flagged phrase: "${testCase.flaggedPhrase}"')
      ..writeln('- Note: ${testCase.note}')
      ..writeln()
      ..writeln('### Summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))')
      ..writeln()
      ..writeln(
        '- Verdict distribution: ${_describeDistribution(aggregate.verdictDistribution)} '
        '-> convergence ${_percentLabel(_maxCount(aggregate.verdictDistribution), aggregate.okRunCount)}',
      )
      ..writeln(
        '- Category distribution: ${_describeDistribution(aggregate.categoryDistribution)} '
        '-> convergence ${_percentLabel(_maxCount(aggregate.categoryDistribution), aggregate.okRunCount)}',
      )
      ..writeln()
      ..writeln('### Run detail')
      ..writeln();

    for (final record in records) {
      report.writeln(_describeRun(record));
    }
    report.writeln();
  }

  final rollup = _rollupFamily(cases, aggregatesById);
  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Convergence rollup')
    ..writeln()
    ..writeln(
      '| Anchor convergence (verdict) | Transfer convergence (avg, T1+T2+T3) | '
      'Negative convergence | Anchor→Transfer gap |',
    )
    ..writeln('| --- | --- | --- | --- |')
    ..writeln(
      '| ${rollup.anchorPct.toStringAsFixed(1)}% | ${rollup.transferPct.toStringAsFixed(1)}% | '
      '${rollup.negativePct.toStringAsFixed(1)}% | ${rollup.gap.toStringAsFixed(1)} pts |',
    );

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

Future<List<_CategorizationResult>> _callStage2Categorization({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required String fullText,
  required String flaggedPhrase,
}) async {
  final request = await httpClient
      .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
      .timeout(const Duration(seconds: 10));

  request.headers
    ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
    ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

  request.add(
    utf8.encode(
      jsonEncode(
        _buildChatCompletionsBody(
          model: model,
          systemPrompt: stage2CategorizationSpanish,
          userText: _buildUserContent(fullText: fullText, flaggedPhrase: flaggedPhrase),
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Chat completions call failed with HTTP ${response.statusCode}: $body');
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Chat completions response root is not an object.');
  }

  return _parseCategorizationArray(_extractReplyText(decoded));
}

void main() {
  test('para+destination battery case fixtures are well-formed', () {
    expect(_cases.length, 5, reason: 'PD-anchor, PD-T1, PD-T2, PD-T3, PD-neg.');

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(testCase.text.trim(), isNotEmpty, reason: testCase.id);
      expect(
        testCase.text.contains(testCase.flaggedPhrase),
        isTrue,
        reason:
            '${testCase.id}: flagged phrase "${testCase.flaggedPhrase}" not '
            'found in case text.',
      );
    }

    final kindsById = {for (final c in _cases) c.id: c.reusedKind};
    expect(kindsById['PD-anchor'], _ReusedKind.anchor);
    expect(kindsById['PD-T1'], _ReusedKind.transfer);
    expect(kindsById['PD-T2'], _ReusedKind.transfer);
    expect(kindsById['PD-T3'], _ReusedKind.transfer);
    expect(kindsById['PD-neg'], _ReusedKind.negative);

    // Text/flaggedPhrase copied verbatim from verdict_battery_merged.dart —
    // guard against retyping drift.
    final textsById = {for (final c in _cases) c.id: c.text};
    expect(
      textsById['PD-anchor'],
      'Ayer fui al supermercado para comprar pan y después volví para casa '
      'para preparar la cena.',
    );
    expect(textsById['PD-T1'], 'Ya era tarde cuando vine para casa.');
    expect(textsById['PD-T2'], 'Subió para la oficina en cuanto llegó.');
    expect(textsById['PD-T3'], 'Al terminar el partido, regresamos para el pueblo.');
    expect(textsById['PD-neg'], 'Ya era tarde cuando volví a casa.');

    final flaggedById = {for (final c in _cases) c.id: c.flaggedPhrase};
    expect(flaggedById['PD-anchor'], 'volví para casa');
    expect(flaggedById['PD-T1'], 'vine para casa');
    expect(flaggedById['PD-T2'], 'Subió para la oficina');
    expect(flaggedById['PD-T3'], 'regresamos para el pueblo');
    expect(flaggedById['PD-neg'], 'volví a casa');
  });

  test('runsPerCase defaults to 10', () {
    expect(runsPerCase, 10);
  });

  test('paraDestinationBatteryModel defaults to gpt-5.5', () {
    expect(paraDestinationBatteryModel, 'gpt-5.5');
  });

  group('_parseCategorizationArray', () {
    test('parses a populated array', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "volví para casa", "corrected_phrase": '
        '"volví a casa", "occurrence": 1, "category": "Grammar", '
        '"verdict": "error"}]',
      );

      expect(results, hasLength(1));
      expect(results.single.verdict, 'error');
      expect(results.single.category, 'Grammar');
    });

    test('parses a null category for not_an_error', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "volví a casa", "corrected_phrase": '
        '"volví a casa", "occurrence": 1, "category": null, '
        '"verdict": "not_an_error"}]',
      );
      expect(results.single.category, isNull);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = _parseCategorizationArray(
        '```json\n[{"original_phrase": "vine para casa", "corrected_phrase": '
        '"vine a casa", "occurrence": 1, "category": "Grammar", '
        '"verdict": "error"}]\n```',
      );
      expect(results, hasLength(1));
    });

    test('throws on an unrecognized verdict', () {
      expect(
        () => _parseCategorizationArray(
          '[{"original_phrase": "x", "corrected_phrase": "y", '
          '"occurrence": 1, "category": "Other", "verdict": "maybe"}]',
        ),
        throwsFormatException,
      );
    });
  });

  group('_matchResultFor', () {
    test('finds the result overlapping the flagged phrase, diacritic-insensitive', () {
      const results = [
        _CategorizationResult(
          originalPhrase: 'Volvi Para Casa',
          correctedPhrase: 'volví a casa',
          occurrence: 1,
          category: 'Grammar',
          verdict: 'error',
        ),
      ];
      expect(_matchResultFor(results, 'volví para casa')?.verdict, 'error');
    });

    test('returns null when nothing overlaps', () {
      const results = [
        _CategorizationResult(
          originalPhrase: 'coche',
          correctedPhrase: 'coche',
          occurrence: 1,
          category: null,
          verdict: 'not_an_error',
        ),
      ];
      expect(_matchResultFor(results, 'volví para casa'), isNull);
    });
  });

  group('_aggregateCase', () {
    test('computes verdict/category distributions and convergence over non-error runs', () {
      final testCase = _cases.firstWhere((c) => c.id == 'PD-anchor');
      final records = [
        _buildRunRecord(
          testCase: testCase,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'volví para casa',
              correctedPhrase: 'volví a casa',
              occurrence: 1,
              category: 'Grammar',
              verdict: 'error',
            ),
          ],
        ),
        _buildRunRecord(
          testCase: testCase,
          runIndex: 2,
          results: const [
            _CategorizationResult(
              originalPhrase: 'volví para casa',
              correctedPhrase: 'volví para casa',
              occurrence: 1,
              category: null,
              verdict: 'not_an_error',
            ),
          ],
        ),
        _errorRunRecord(testCase: testCase, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.okRunCount, 2);
      expect(aggregate.verdictDistribution, {'error': 1, 'not_an_error': 1});
      expect(aggregate.verdictConvergencePct, 50.0);
      expect(aggregate.categoryDistribution, {'Grammar': 1, '(none)': 1});
    });

    test('a run with no matching result is tallied under (missing)', () {
      final testCase = _cases.firstWhere((c) => c.id == 'PD-neg');
      final records = [
        _buildRunRecord(testCase: testCase, runIndex: 1, results: const []),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.verdictDistribution, {'(missing)': 1});
      expect(aggregate.categoryDistribution, {'(missing)': 1});
    });
  });

  group('_rollupFamily', () {
    test('averages transfer convergence across PD-T1/PD-T2/PD-T3 and computes the anchor gap', () {
      final aggregatesById = {
        'PD-anchor': const _Aggregate(
          caseId: 'PD-anchor',
          totalRuns: 10,
          errorRuns: 0,
          okRunCount: 10,
          verdictDistribution: {'error': 10},
          categoryDistribution: {'Grammar': 10},
          verdictConvergencePct: 100.0,
          categoryConvergencePct: 100.0,
        ),
        'PD-T1': const _Aggregate(
          caseId: 'PD-T1',
          totalRuns: 10,
          errorRuns: 0,
          okRunCount: 10,
          verdictDistribution: {'error': 4, 'not_an_error': 6},
          categoryDistribution: {},
          verdictConvergencePct: 60.0,
          categoryConvergencePct: 0.0,
        ),
        'PD-T2': const _Aggregate(
          caseId: 'PD-T2',
          totalRuns: 10,
          errorRuns: 0,
          okRunCount: 10,
          verdictDistribution: {'error': 8, 'not_an_error': 2},
          categoryDistribution: {},
          verdictConvergencePct: 80.0,
          categoryConvergencePct: 0.0,
        ),
        'PD-T3': const _Aggregate(
          caseId: 'PD-T3',
          totalRuns: 10,
          errorRuns: 0,
          okRunCount: 10,
          verdictDistribution: {'error': 10},
          categoryDistribution: {},
          verdictConvergencePct: 100.0,
          categoryConvergencePct: 0.0,
        ),
        'PD-neg': const _Aggregate(
          caseId: 'PD-neg',
          totalRuns: 10,
          errorRuns: 0,
          okRunCount: 10,
          verdictDistribution: {'not_an_error': 10},
          categoryDistribution: {},
          verdictConvergencePct: 100.0,
          categoryConvergencePct: 0.0,
        ),
      };

      final rollup = _rollupFamily(_cases, aggregatesById);

      expect(rollup.anchorPct, 100.0);
      expect(rollup.transferPct, closeTo(80.0, 0.001)); // (60 + 80 + 100) / 3
      expect(rollup.negativePct, 100.0);
      expect(rollup.gap, closeTo(20.0, 0.001));
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, per-case summary + run detail, rollup table)',
    () {
      const anchorCase = _Case(
        id: 'PD-anchor',
        reusedKind: _ReusedKind.anchor,
        text: 'Volví para casa ayer.',
        flaggedPhrase: 'Volví para casa',
        note: 'synthetic anchor',
      );
      const negCase = _Case(
        id: 'PD-neg',
        reusedKind: _ReusedKind.negative,
        text: 'Volví a casa ayer.',
        flaggedPhrase: 'Volví a casa',
        note: 'synthetic negative',
      );

      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: const [anchorCase, negCase],
        recordsByCaseId: {
          'PD-anchor': [
            _buildRunRecord(
              testCase: anchorCase,
              runIndex: 1,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'Volví para casa',
                  correctedPhrase: 'Volví a casa',
                  occurrence: 1,
                  category: 'Grammar',
                  verdict: 'error',
                ),
              ],
            ),
            _errorRunRecord(
              testCase: anchorCase,
              runIndex: 2,
              error: StateError('Stage 2 call timed out'),
            ),
          ],
          'PD-neg': [
            _buildRunRecord(
              testCase: negCase,
              runIndex: 1,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'Volví a casa',
                  correctedPhrase: 'Volví a casa',
                  occurrence: 1,
                  category: null,
                  verdict: 'not_an_error',
                ),
              ],
            ),
            _buildRunRecord(
              testCase: negCase,
              runIndex: 2,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'Volví a casa',
                  correctedPhrase: 'Volví a casa',
                  occurrence: 1,
                  category: null,
                  verdict: 'not_an_error',
                ),
              ],
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'para+destination battery (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the para+destination battery. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final recordsByCaseId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in _cases) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (var run = 1; run <= runsPerCase; run++) {
            _RunRecord record;
            try {
              final results = await _callStage2Categorization(
                httpClient: httpClient,
                apiKey: apiKey,
                model: paraDestinationBatteryModel,
                fullText: testCase.text,
                flaggedPhrase: testCase.flaggedPhrase,
              );
              record = _buildRunRecord(testCase: testCase, runIndex: run, results: results);
            } catch (error) {
              record = _errorRunRecord(testCase: testCase, runIndex: run, error: error);
            }
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(record));
            await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
          }

          recordsByCaseId[testCase.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: paraDestinationBatteryModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 20)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Para + Destination Battery\n\nStandalone extraction of the \"para + destination\" family from `verdict_battery_merged.dart` (PD-anchor, PD-T1, PD-T2, PD-T3, PD-neg), for investigating whether this construction is genuinely unstable in `stage2CategorizationSpanish` verdict output, without running the full 37-case merged suite.\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## PD-anchor (Anchor)\n\n- Text: `Volví para casa ayer.`\n- Flagged phrase: \"Volví para casa\"\n- Note: synthetic anchor\n\n### Summary (2 runs, 1 error(s))\n\n- Verdict distribution: error: 1 -> convergence 100.0% (1/1)\n- Category distribution: Grammar: 1 -> convergence 100.0% (1/1)\n\n### Run detail\n\n- Run 1: verdict=error, category=Grammar, occurrence=1\n- Run 2: ERROR — Bad state: Stage 2 call timed out\n\n## PD-neg (Negative)\n\n- Text: `Volví a casa ayer.`\n- Flagged phrase: \"Volví a casa\"\n- Note: synthetic negative\n\n### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: not_an_error: 2 -> convergence 100.0% (2/2)\n- Category distribution: (none): 2 -> convergence 100.0% (2/2)\n\n### Run detail\n\n- Run 1: verdict=not_an_error, category=(none), occurrence=1\n- Run 2: verdict=not_an_error, category=(none), occurrence=1\n\n---\n\n## Convergence rollup\n\n| Anchor convergence (verdict) | Transfer convergence (avg, T1+T2+T3) | Negative convergence | Anchor→Transfer gap |\n| --- | --- | --- | --- |\n| 100.0% | 0.0% | 100.0% | 100.0 pts |\n"';
