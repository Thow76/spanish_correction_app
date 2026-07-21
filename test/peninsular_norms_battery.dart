// Peninsular norms transfer battery — a standalone, disposable diagnostic.
//
// Tests `stage2CategorizationSpanish`
// (lib/core/services/prompts/correction_prompt.dart) against constructions
// that share a principle with cases already named in the prompt/tests, but
// are not themselves named. The question: does the model apply a general
// rule (Peninsular norms as the baseline, regional variants noted rather
// than flagged as errors) or does it only get the *named* examples right
// because they pattern-match text it has effectively memorized?
//
// Four construction families, each with three case kinds:
// - anchor: the case already covered by stage2_categorization_harness.dart
//   (or, for the ordinary-vocab family, all three of its anchor cases).
// - transfer: 2-3 same-principle cases the prompt does NOT name. This is
//   the actual test — if these converge as reliably as the anchor, the
//   principle transferred; if convergence drops, it didn't.
// - negative: one case that looks similar but should NOT be flagged, to
//   catch overcorrection.
//
// STANDALONE: does not import from or modify
// stage2_categorization_harness.dart or correction_consistency_harness.dart.
// Helper functions (parsing, HTTP body, matching) are duplicated by value
// rather than imported, same reasoning stage2_categorization_harness.dart
// itself gives for duplicating from stage1_detection_harness.dart — this
// file stays independently readable and disposable.
//
// Narrower than the Stage 2 harness by design: 5 runs/case (not 10),
// verdict + category only (no occurrence or corrected_phrase scoring), and
// no ground-truth catch-rate scoring — the metric here is convergence
// (do all runs agree with each other), not correctness against an expected
// answer. This is not meant to become permanent regression coverage.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/peninsular_norms_battery.dart --exclude-tags live
//
// Run everything, including the live battery (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/peninsular_norms_battery.dart --timeout none
//
// Writes a report to docs/peninsular_norms_battery.md (override with
// --dart-define=PENINSULAR_NORMS_OUTPUT=...). Override run count per case
// with --dart-define=PENINSULAR_NORMS_RUNS_PER_CASE=... (default 5).
// Override the model with --dart-define=PENINSULAR_NORMS_MODEL=... (default
// 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'PENINSULAR_NORMS_RUNS_PER_CASE',
  defaultValue: 5,
);

const String outputPath = String.fromEnvironment(
  'PENINSULAR_NORMS_OUTPUT',
  defaultValue: 'docs/peninsular_norms_battery.md',
);

const String peninsularNormsModel = String.fromEnvironment(
  'PENINSULAR_NORMS_MODEL',
  defaultValue: 'gpt-5.5',
);

const int callDelayMs = int.fromEnvironment(
  'PENINSULAR_NORMS_CALL_DELAY_MS',
  defaultValue: 750,
);

const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};

/// Which construction family a case belongs to.
enum _Family { paraDestination, cogerVocab, ordinaryVocab, softRegister }

String _familyHeading(_Family family) => switch (family) {
  _Family.paraDestination => 'Para + destination',
  _Family.cogerVocab => 'Coger-type vocabulary',
  _Family.ordinaryVocab => 'Ordinary regional vocabulary pairs',
  _Family.softRegister => 'Soft-register / circumlocution (BP-001-style)',
};

/// A case's role within its family.
enum _CaseKind { anchor, transfer, negative }

String _kindLabel(_CaseKind kind) => switch (kind) {
  _CaseKind.anchor => 'Anchor',
  _CaseKind.transfer => 'Transfer',
  _CaseKind.negative => 'Negative',
};

/// One test case: a full text plus a single flagged phrase (every case here
/// targets exactly one construction — no multi-target cases like the Stage
/// 2 harness has).
class _Case {
  const _Case({
    required this.id,
    required this.family,
    required this.kind,
    required this.text,
    required this.flaggedPhrase,
    required this.note,
  });

  final String id;
  final _Family family;
  final _CaseKind kind;
  final String text;
  final String flaggedPhrase;
  final String note;
}

const List<_Case> _cases = [
  // ── Para + destination ──────────────────────────────────────────────────
  _Case(
    id: 'PD-anchor',
    family: _Family.paraDestination,
    kind: _CaseKind.anchor,
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
    family: _Family.paraDestination,
    kind: _CaseKind.transfer,
    text: 'Ya era tarde cuando vine para casa.',
    flaggedPhrase: 'vine para casa',
    note: 'Same "para + destination" construction, different verb.',
  ),
  _Case(
    id: 'PD-T2',
    family: _Family.paraDestination,
    kind: _CaseKind.transfer,
    text: 'Subió para la oficina en cuanto llegó.',
    flaggedPhrase: 'Subió para la oficina',
    note: 'Same construction, different destination and verb.',
  ),
  _Case(
    id: 'PD-T3',
    family: _Family.paraDestination,
    kind: _CaseKind.transfer,
    text: 'Al terminar el partido, regresamos para el pueblo.',
    flaggedPhrase: 'regresamos para el pueblo',
    note: 'Same construction, different destination and verb.',
  ),
  _Case(
    id: 'PD-neg',
    family: _Family.paraDestination,
    kind: _CaseKind.negative,
    text: 'Ya era tarde cuando volví a casa.',
    flaggedPhrase: 'volví a casa',
    note:
        'The accepted Peninsular form of the anchor construction (its own '
        'corrected_phrase). Must not be flagged at all.',
  ),

  // ── Coger-type vocabulary ────────────────────────────────────────────────
  _Case(
    id: 'COG-anchor',
    family: _Family.cogerVocab,
    kind: _CaseKind.anchor,
    text: 'Voy a coger el autobús para ir al centro.',
    flaggedPhrase: 'coger el autobús',
    note:
        'Same text as the "coger" case in stage2_categorization_harness.dart '
        '— the canonical dialectal case (100% convergence live).',
  ),
  _Case(
    id: 'COG-T1',
    family: _Family.cogerVocab,
    kind: _CaseKind.transfer,
    text: 'Espera, voy a coger las llaves antes de salir.',
    flaggedPhrase: 'coger las llaves',
    note: 'Same coger-is-vulgar-in-parts-of-Latin-America split, different object.',
  ),
  _Case(
    id: 'COG-T2',
    family: _Family.cogerVocab,
    kind: _CaseKind.transfer,
    text: 'Vamos a coger un taxi para llegar antes.',
    flaggedPhrase: 'coger un taxi',
    note: 'Same split, different vehicle.',
  ),
  _Case(
    id: 'COG-T3',
    family: _Family.cogerVocab,
    kind: _CaseKind.transfer,
    text: 'Con esta lluvia vas a coger frío.',
    flaggedPhrase: 'coger frío',
    note: 'Same split, idiomatic non-transport use of "coger".',
  ),
  _Case(
    id: 'COG-neg',
    family: _Family.cogerVocab,
    kind: _CaseKind.negative,
    text: 'Vamos a tomar el autobús para ir al centro.',
    flaggedPhrase: 'tomar el autobús',
    note:
        'Mirrors PD-neg: reuses the pan-dialectal accepted form (the '
        'anchor\'s own corrected_phrase) rather than a same-verb-different-'
        'context "coger" sentence. In the varieties where "coger" is '
        'taboo, the stigma generally attaches to the verb itself, not to '
        'specific senses of it — so a "coger + [some other object]" '
        'negative (e.g. "coger un libro de la mesa") would not reliably '
        'test anything; it could just as easily read as another instance '
        'of the same split. "Tomar el autobús" is accepted everywhere, so '
        'a flag on it is an unambiguous overcorrection signal.',
  ),

  // ── Ordinary regional vocabulary pairs ───────────────────────────────────
  _Case(
    id: 'VOC-anchor-ordenador',
    family: _Family.ordinaryVocab,
    kind: _CaseKind.anchor,
    text: 'Voy a usar el ordenador en la oficina.',
    flaggedPhrase: 'ordenador',
    note:
        'Same text as the "ordenador" case in '
        'stage2_categorization_harness.dart.',
  ),
  _Case(
    id: 'VOC-anchor-coche',
    family: _Family.ordinaryVocab,
    kind: _CaseKind.anchor,
    text: 'Aparqué el coche cerca de la oficina.',
    flaggedPhrase: 'coche',
    note: 'Same text as the "coche" case in stage2_categorization_harness.dart.',
  ),
  _Case(
    id: 'VOC-anchor-carro',
    family: _Family.ordinaryVocab,
    kind: _CaseKind.anchor,
    text: 'Lavé el carro el fin de semana.',
    flaggedPhrase: 'carro',
    note: 'Same text as the "carro" case in stage2_categorization_harness.dart.',
  ),
  _Case(
    id: 'VOC-T1-gafas',
    family: _Family.ordinaryVocab,
    kind: _CaseKind.transfer,
    text: 'No veo bien sin mis gafas.',
    flaggedPhrase: 'gafas',
    note: 'Same ordinary-regional-pair shape: gafas (Spain) / lentes (Latin America).',
  ),
  _Case(
    id: 'VOC-T2-movil',
    family: _Family.ordinaryVocab,
    kind: _CaseKind.transfer,
    text: 'Se me quedó el móvil en casa.',
    flaggedPhrase: 'móvil',
    note: 'móvil (Spain) / celular (Latin America).',
  ),
  _Case(
    id: 'VOC-T3-piso',
    family: _Family.ordinaryVocab,
    kind: _CaseKind.transfer,
    text: 'Alquilamos un piso cerca del centro.',
    flaggedPhrase: 'piso',
    note: 'piso (Spain) / apartamento (Latin America).',
  ),
  _Case(
    id: 'VOC-neg-libreria',
    family: _Family.ordinaryVocab,
    kind: _CaseKind.negative,
    text: 'Fui a la librería a devolver el libro que pedí prestado.',
    flaggedPhrase: 'librería',
    note:
        'Looks like a regional-pair candidate but is a genuine false-'
        'friend error in every variety — no established dialect uses '
        '"librería" to mean "library" (it means "bookstore" everywhere; '
        '"biblioteca" is library everywhere). Must come back as error, '
        'not dialectal/not_an_error.',
  ),

  // ── Soft-register / circumlocution (BP-001-style) ───────────────────────
  _Case(
    id: 'SR-anchor',
    family: _Family.softRegister,
    kind: _CaseKind.anchor,
    text: 'En el gimnasio hay una máquina de correr nueva.',
    flaggedPhrase: 'máquina de correr',
    note:
        'The Portuguese prompt has a dedicated soft-register bullet '
        '(_ptSoftRegisterBullet) built around exactly this phrase '
        '("máquina de correr" -> "esteira"); stage2CategorizationSpanish '
        'has no Spanish equivalent bullet. This family tests whether the '
        'existing calque/Natural Language machinery catches the same kind '
        'of issue in Spanish ("máquina de correr" -> "cinta de correr") '
        'without one.',
  ),
  _Case(
    id: 'SR-T1',
    family: _Family.softRegister,
    kind: _CaseKind.transfer,
    text: 'Compramos una máquina de lavar la ropa.',
    flaggedPhrase: 'máquina de lavar la ropa',
    note: 'Same circumlocution-for-an-everyday-appliance shape, vs. "lavadora".',
  ),
  _Case(
    id: 'SR-T2',
    family: _Family.softRegister,
    kind: _CaseKind.transfer,
    text: 'Necesito un aparato para calentar la comida.',
    flaggedPhrase: 'aparato para calentar la comida',
    note: 'Same shape, vs. "microondas".',
  ),
  _Case(
    id: 'SR-neg',
    family: _Family.softRegister,
    kind: _CaseKind.negative,
    text: 'Puse el aire acondicionado porque hacía calor.',
    flaggedPhrase: 'aire acondicionado',
    note:
        '"Aire acondicionado" is itself the standard idiomatic phrase — '
        'there is no shorter single-word native term to prefer instead. '
        'Flagging it as an overly wordy circumlocution would be '
        'overcorrection.',
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Duplicated by value from
/// stage2_categorization_harness.dart's `_normalizeForMatch` — this file
/// stays standalone.
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
/// Duplicated by value from stage2_categorization_harness.dart's
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
/// phrase. Pure — no network.
String _buildUserContent({required String fullText, required String flaggedPhrase}) {
  return '''
Learner's text:
$fullText

Flagged phrases:
${jsonEncode([flaggedPhrase])}
''';
}

/// One flagged phrase's categorization, as returned by Stage 2. Parsed in
/// full (all five fields, matching the prompt's actual output shape) even
/// though this battery only scores verdict + category — occurrence and
/// corrected_phrase are kept around for the run-detail line but not
/// aggregated.
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
/// call. Duplicated by value from stage2_categorization_harness.dart's
/// `buildChatCompletionsBody`.
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
/// response body. Duplicated by value from
/// stage2_categorization_harness.dart's `extractReplyText`.
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

/// Parses a Stage 2 reply into [_CategorizationResult]s. Duplicated by
/// value from stage2_categorization_harness.dart's
/// `_parseCategorizationArray`, same tolerance for Markdown fences /
/// commentary.
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

/// Aggregated results for one case across all its non-error runs.
///
/// [verdictConvergencePct] / [categoryConvergencePct] are the size of the
/// largest group in each distribution as a percentage of [okRunCount] — 100%
/// means every run agreed; lower values quantify partial agreement rather
/// than collapsing to a plain yes/no on whether all runs happened to match.
class _CaseAggregate {
  const _CaseAggregate({
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

double _convergencePct(Map<String, int> distribution, int total) {
  if (total == 0 || distribution.isEmpty) {
    return 0.0;
  }
  final maxCount = distribution.values.reduce((a, b) => a > b ? a : b);
  return maxCount / total * 100;
}

_CaseAggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  final errorCount = records.length - okRecords.length;

  final verdictDist = <String, int>{};
  final categoryDist = <String, int>{};

  for (final record in okRecords) {
    final verdictKey = record.result == null ? '(missing)' : record.result!.verdict;
    verdictDist[verdictKey] = (verdictDist[verdictKey] ?? 0) + 1;

    final categoryKey =
        record.result == null ? '(missing)' : _distKey(record.result!.category);
    categoryDist[categoryKey] = (categoryDist[categoryKey] ?? 0) + 1;
  }

  return _CaseAggregate(
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

String _convergenceLabel(Map<String, int> distribution, int total) {
  if (total == 0 || distribution.isEmpty) {
    return '0.0% (0/0)';
  }
  final maxCount = distribution.values.reduce((a, b) => a > b ? a : b);
  return _percentLabel(maxCount, total);
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
  return '- $prefix: verdict=${result.verdict}, category=${_distKey(result.category)}';
}

/// One family's rollup for the top-level summary table: the anchor
/// convergence, the transfer convergence averaged across its 2-3 transfer
/// cases, the negative convergence, and the anchor-minus-transfer gap — the
/// number that answers whether the principle transferred or not.
class _FamilyRollup {
  const _FamilyRollup({
    required this.family,
    required this.anchorPct,
    required this.transferPct,
    required this.negativePct,
  });

  final _Family family;
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

_FamilyRollup _rollupFamily(
  _Family family,
  List<_Case> cases,
  Map<String, _CaseAggregate> aggregatesById,
) {
  double pctFor(_CaseKind kind) => _average(
    cases
        .where((c) => c.family == family && c.kind == kind)
        .map((c) => aggregatesById[c.id]!.verdictConvergencePct),
  );

  return _FamilyRollup(
    family: family,
    anchorPct: pctFor(_CaseKind.anchor),
    transferPct: pctFor(_CaseKind.transfer),
    negativePct: pctFor(_CaseKind.negative),
  );
}

/// Builds the full markdown report: header, one section per family (each
/// case's metadata, verdict/category distributions with convergence, and
/// run-by-run detail), then a family-level convergence rollup table.
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
    ..writeln('# Peninsular Norms Transfer Battery')
    ..writeln()
    ..writeln('Model: `$model`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per case: $runsPerCase')
    ..writeln();

  for (final family in _Family.values) {
    final familyCases = cases.where((c) => c.family == family).toList();
    if (familyCases.isEmpty) {
      continue;
    }

    report
      ..writeln('## ${_familyHeading(family)}')
      ..writeln();

    for (final testCase in familyCases) {
      final aggregate = aggregatesById[testCase.id]!;
      final records = recordsByCaseId[testCase.id] ?? const <_RunRecord>[];

      report
        ..writeln('### ${testCase.id} (${_kindLabel(testCase.kind)})')
        ..writeln()
        ..writeln('- Text: `${testCase.text}`')
        ..writeln('- Flagged phrase: "${testCase.flaggedPhrase}"')
        ..writeln('- Note: ${testCase.note}')
        ..writeln()
        ..writeln('#### Summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))')
        ..writeln()
        ..writeln(
          '- Verdict distribution: ${_describeDistribution(aggregate.verdictDistribution)} '
          '-> convergence ${_convergenceLabel(aggregate.verdictDistribution, aggregate.okRunCount)}',
        )
        ..writeln(
          '- Category distribution: ${_describeDistribution(aggregate.categoryDistribution)} '
          '-> convergence ${_convergenceLabel(aggregate.categoryDistribution, aggregate.okRunCount)}',
        )
        ..writeln()
        ..writeln('#### Run detail')
        ..writeln();

      for (final record in records) {
        report.writeln(_describeRun(record));
      }
      report.writeln();
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Family convergence summary')
    ..writeln()
    ..writeln(
      '| Construction family | Anchor convergence (verdict) | '
      'Transfer convergence (avg) | Negative convergence | Anchor→Transfer gap |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');

  for (final family in _Family.values) {
    final familyCases = cases.where((c) => c.family == family).toList();
    if (familyCases.isEmpty) {
      continue;
    }
    final rollup = _rollupFamily(family, familyCases, aggregatesById);
    report.writeln(
      '| ${_familyHeading(family)} | ${rollup.anchorPct.toStringAsFixed(1)}% | '
      '${rollup.transferPct.toStringAsFixed(1)}% | '
      '${rollup.negativePct.toStringAsFixed(1)}% | '
      '${rollup.gap.toStringAsFixed(1)} pts |',
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
  test('peninsular norms battery case fixtures are well-formed', () {
    expect(
      _cases.length,
      21,
      reason:
          'para(1+3+1) + coger(1+3+1) + ordinaryVocab(3+3+1) + softRegister(1+2+1).',
    );

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

    final countsByFamilyAndKind = <_Family, Map<_CaseKind, int>>{};
    for (final testCase in _cases) {
      final byKind = countsByFamilyAndKind.putIfAbsent(testCase.family, () => {});
      byKind[testCase.kind] = (byKind[testCase.kind] ?? 0) + 1;
    }

    expect(
      countsByFamilyAndKind[_Family.paraDestination],
      {_CaseKind.anchor: 1, _CaseKind.transfer: 3, _CaseKind.negative: 1},
    );
    expect(
      countsByFamilyAndKind[_Family.cogerVocab],
      {_CaseKind.anchor: 1, _CaseKind.transfer: 3, _CaseKind.negative: 1},
    );
    expect(
      countsByFamilyAndKind[_Family.ordinaryVocab],
      {_CaseKind.anchor: 3, _CaseKind.transfer: 3, _CaseKind.negative: 1},
    );
    expect(
      countsByFamilyAndKind[_Family.softRegister],
      {_CaseKind.anchor: 1, _CaseKind.transfer: 2, _CaseKind.negative: 1},
    );
  });

  group('_parseCategorizationArray', () {
    test('parses a populated array', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "coger el autobús", "corrected_phrase": '
        '"tomar el autobús", "occurrence": 1, "category": "Other", '
        '"verdict": "dialectal"}]',
      );

      expect(results, hasLength(1));
      expect(results.single.verdict, 'dialectal');
      expect(results.single.category, 'Other');
    });

    test('parses a null category for not_an_error', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "gafas", "corrected_phrase": "gafas", '
        '"occurrence": 1, "category": null, "verdict": "not_an_error"}]',
      );
      expect(results.single.category, isNull);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = _parseCategorizationArray(
        '```json\n[{"original_phrase": "librería", "corrected_phrase": '
        '"biblioteca", "occurrence": 1, "category": "Word Choice", '
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

  group('_aggregateCase convergence', () {
    test('100% when every run agrees', () {
      final testCase = _cases.firstWhere((c) => c.id == 'COG-anchor');
      final records = [
        _buildRunRecord(
          testCase: testCase,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'coger el autobús',
              correctedPhrase: 'tomar el autobús',
              occurrence: 1,
              category: 'Other',
              verdict: 'dialectal',
            ),
          ],
        ),
        _buildRunRecord(
          testCase: testCase,
          runIndex: 2,
          results: const [
            _CategorizationResult(
              originalPhrase: 'coger el autobús',
              correctedPhrase: 'tomar el autobús',
              occurrence: 1,
              category: 'Other',
              verdict: 'dialectal',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);
      expect(aggregate.verdictConvergencePct, 100.0);
      expect(aggregate.categoryConvergencePct, 100.0);
    });

    test('partial convergence when runs disagree', () {
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
      ];

      final aggregate = _aggregateCase(testCase, records);
      expect(aggregate.verdictConvergencePct, 50.0);
    });

    test('errored runs are excluded from convergence denominators', () {
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
        _errorRunRecord(testCase: testCase, runIndex: 2, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);
      expect(aggregate.okRunCount, 1);
      expect(aggregate.verdictConvergencePct, 100.0);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, per-family case sections, family convergence rollup table)',
    () {
      const synthCases = [
        _Case(
          id: 'SYN-PD-anchor',
          family: _Family.paraDestination,
          kind: _CaseKind.anchor,
          text: 'Volví para casa ayer.',
          flaggedPhrase: 'Volví para casa',
          note: 'synthetic anchor',
        ),
        _Case(
          id: 'SYN-PD-T1',
          family: _Family.paraDestination,
          kind: _CaseKind.transfer,
          text: 'Vine para casa tarde.',
          flaggedPhrase: 'Vine para casa',
          note: 'synthetic transfer 1',
        ),
        _Case(
          id: 'SYN-PD-T2',
          family: _Family.paraDestination,
          kind: _CaseKind.transfer,
          text: 'Subió para la oficina rápido.',
          flaggedPhrase: 'Subió para la oficina',
          note: 'synthetic transfer 2',
        ),
        _Case(
          id: 'SYN-PD-neg',
          family: _Family.paraDestination,
          kind: _CaseKind.negative,
          text: 'Volví a casa ayer.',
          flaggedPhrase: 'Volví a casa',
          note: 'synthetic negative',
        ),
      ];

      final recordsByCaseId = {
        'SYN-PD-anchor': [
          _buildRunRecord(
            testCase: synthCases[0],
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
          _buildRunRecord(
            testCase: synthCases[0],
            runIndex: 2,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Volví para casa',
                correctedPhrase: 'Volví a casa',
                occurrence: 1,
                category: 'Other',
                verdict: 'error',
              ),
            ],
          ),
        ],
        'SYN-PD-T1': [
          _buildRunRecord(
            testCase: synthCases[1],
            runIndex: 1,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Vine para casa',
                correctedPhrase: 'Vine a casa',
                occurrence: 1,
                category: 'Natural Language',
                verdict: 'error',
              ),
            ],
          ),
          _buildRunRecord(
            testCase: synthCases[1],
            runIndex: 2,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Vine para casa',
                correctedPhrase: 'Vine para casa',
                occurrence: 1,
                category: null,
                verdict: 'not_an_error',
              ),
            ],
          ),
        ],
        'SYN-PD-T2': [
          _buildRunRecord(
            testCase: synthCases[2],
            runIndex: 1,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Subió para la oficina',
                correctedPhrase: 'Subió para la oficina',
                occurrence: 1,
                category: null,
                verdict: 'not_an_error',
              ),
            ],
          ),
          _buildRunRecord(
            testCase: synthCases[2],
            runIndex: 2,
            results: const [
              _CategorizationResult(
                originalPhrase: 'Subió para la oficina',
                correctedPhrase: 'Subió para la oficina',
                occurrence: 1,
                category: null,
                verdict: 'not_an_error',
              ),
            ],
          ),
        ],
        'SYN-PD-neg': [
          _buildRunRecord(
            testCase: synthCases[3],
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
            testCase: synthCases[3],
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
      };

      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: synthCases,
        recordsByCaseId: recordsByCaseId,
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'peninsular norms battery (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the peninsular norms battery. This '
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
                model: peninsularNormsModel,
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
        model: peninsularNormsModel,
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
    timeout: const Timeout(Duration(minutes: 30)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Peninsular Norms Transfer Battery\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## Para + destination\n\n### SYN-PD-anchor (Anchor)\n\n- Text: `Volví para casa ayer.`\n- Flagged phrase: \"Volví para casa\"\n- Note: synthetic anchor\n\n#### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: error: 2 -> convergence 100.0% (2/2)\n- Category distribution: Grammar: 1, Other: 1 -> convergence 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: verdict=error, category=Grammar\n- Run 2: verdict=error, category=Other\n\n### SYN-PD-T1 (Transfer)\n\n- Text: `Vine para casa tarde.`\n- Flagged phrase: \"Vine para casa\"\n- Note: synthetic transfer 1\n\n#### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: error: 1, not_an_error: 1 -> convergence 50.0% (1/2)\n- Category distribution: (none): 1, Natural Language: 1 -> convergence 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: verdict=error, category=Natural Language\n- Run 2: verdict=not_an_error, category=(none)\n\n### SYN-PD-T2 (Transfer)\n\n- Text: `Subió para la oficina rápido.`\n- Flagged phrase: \"Subió para la oficina\"\n- Note: synthetic transfer 2\n\n#### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: not_an_error: 2 -> convergence 100.0% (2/2)\n- Category distribution: (none): 2 -> convergence 100.0% (2/2)\n\n#### Run detail\n\n- Run 1: verdict=not_an_error, category=(none)\n- Run 2: verdict=not_an_error, category=(none)\n\n### SYN-PD-neg (Negative)\n\n- Text: `Volví a casa ayer.`\n- Flagged phrase: \"Volví a casa\"\n- Note: synthetic negative\n\n#### Summary (2 runs, 0 error(s))\n\n- Verdict distribution: not_an_error: 2 -> convergence 100.0% (2/2)\n- Category distribution: (none): 2 -> convergence 100.0% (2/2)\n\n#### Run detail\n\n- Run 1: verdict=not_an_error, category=(none)\n- Run 2: verdict=not_an_error, category=(none)\n\n---\n\n## Family convergence summary\n\n| Construction family | Anchor convergence (verdict) | Transfer convergence (avg) | Negative convergence | Anchor→Transfer gap |\n| --- | --- | --- | --- | --- |\n| Para + destination | 100.0% | 75.0% | 100.0% | 25.0 pts |\n"';
