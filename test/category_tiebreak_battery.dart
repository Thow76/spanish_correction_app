// Category tiebreak transfer battery — a standalone, disposable diagnostic.
//
// Tests whether the five category-tiebreak rules added to
// `stage2CategorizationSpanish` (lib/core/services/prompts/correction_prompt.dart,
// `Boundary rules:` section) generalize to error patterns they don't name,
// not just the seed cases (habían muchos coches, coger el autobús, se los
// dije) the rules were written from. Re-running those three seeds alone
// would only confirm the patch fixed the examples it was patched for — the
// anti-whack-a-mole design here is the same as `peninsular_norms_battery.dart`:
// one anchor (already-named/measured) plus one transfer (same principle,
// unnamed surface form) per boundary pair.
//
// Ten cases, eight boundary pairs:
// 1-2. GWC — Rule "never use Word Choice merely because the correction
//      changes one token": anchor is existential "haber" wrongly
//      pluralized (habían muchos coches); transfer is impersonal "hacer"
//      with a time expression (hacían dos años), same one-token-agreement
//      shape, never named in the added rules.
// 3-4. SG — mandatory contraction / suppletive form rule: anchor is an
//      al-contraction error (a el -> al); transfer is a suppletive-form
//      error (con mí -> conmigo) — same rule, a genuinely different error
//      shape than the contraction case it was written from.
// 5.   WCO — "coger el autobús", the canonical dialectal-vocabulary case.
//      This is a CONTINUITY BASELINE, not a test of the five new rules: its
//      Other categorization comes from the pre-existing, unmodified
//      Restraint paragraph (dialectal verdict -> category always Other),
//      not from anything added this round.
// 6-7. GO — clitic/pronoun case, agreement, order rule: anchor is
//      "se los dije" (reused verbatim from `verdict_battery_merged.dart`'s
//      `SLD-1` for continuity — a clitic-number-agreement error); transfer
//      is "me se cayó" (clitic-order error — se/me reversed), same rule,
//      different specific error.
// 8.   CHAIN-SS-1 — composition test, not a counterfactual. se/sé has no
//      genuine overlap with the contraction/suppletive carve-out (se/sé is
//      never itself a contraction or suppletive form), so there is nothing
//      to counterfactually confirm. Instead: one sentence with three
//      things to get right at once — "Se" (Spelling, accent), "a el"
//      (Grammar, contraction), "conmigo" (correct as-is, not_an_error) —
//      sent to Stage 2 as three flagged phrases in a single call, to check
//      the Grammar-flagged contraction doesn't pull the accent error into
//      Grammar too, and the correct suppletive form doesn't get
//      overcorrected by proximity to the other two.
// 9-10. CHAIN-REFL — reflexive/non-reflexive verb-pair rule: CHAIN-REFL-1
//      is the obligatory-reflexive branch (Levantó temprano -> missing
//      "se", Grammar). CHAIN-REFL-2 is the alternating-complement branch,
//      built as a comparative pair across two separate sentences (not one
//      sentence with two phrases, since "decidir el color" and "decidirse
//      por el azul" are different sentences): "Decidí el color del coche"
//      (decidir + direct object) vs. "Me decidí por el azul" (decidirse +
//      por-phrase). Both sentences as given are independently correct
//      Spanish — this pair does not exercise a miscategorization of a
//      genuine error into Natural Language (neither sentence contains an
//      error), it instead confirms the model doesn't treat the two
//      complement patterns as a single right-vs-wrong pair and overcorrect
//      one into the other's shape. That is a narrower claim than "the
//      choice is Natural Language" would be for an actual complement-
//      mismatch error; flagged here rather than silently building a
//      stronger claim the given sentences can't support.
//
// STANDALONE: does not import from or modify any other battery/harness
// file. Helper functions (parsing, HTTP body, matching, aggregation) are
// duplicated by value rather than imported — same reasoning
// `peninsular_norms_battery.dart` and `verdict_battery_merged.dart` give
// for duplicating from `stage2_categorization_harness.dart`.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/category_tiebreak_battery.dart --exclude-tags live
//
// Run everything, including the live battery (costs real API calls — 11
// Stage 2 calls/run [9 single-phrase cases + 1 three-phrase call for
// CHAIN-SS-1 + 2 calls for CHAIN-REFL-2's two sentences] * 10 runs = 110
// calls):
//   OPENAI_API_KEY=sk-... flutter test test/category_tiebreak_battery.dart --timeout none
//
// Writes a report to docs/category_tiebreak_battery.md (override with
// --dart-define=CATEGORY_TIEBREAK_OUTPUT=...). Override run count per case
// with --dart-define=CATEGORY_TIEBREAK_RUNS_PER_CASE=... (default 10).
// Override the model with --dart-define=CATEGORY_TIEBREAK_MODEL=... (default
// 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'CATEGORY_TIEBREAK_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'CATEGORY_TIEBREAK_OUTPUT',
  defaultValue: 'docs/category_tiebreak_battery.md',
);

const String categoryTiebreakModel = String.fromEnvironment(
  'CATEGORY_TIEBREAK_MODEL',
  defaultValue: 'gpt-5.5',
);

const int callDelayMs = int.fromEnvironment(
  'CATEGORY_TIEBREAK_CALL_DELAY_MS',
  defaultValue: 750,
);

const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};
const Set<String> _validCategories = {
  'Grammar',
  'Spelling',
  'Word Choice',
  'Natural Language',
  'Other',
};

/// One thing to check within a case: a full carrier sentence, a flagged
/// phrase within it, and the ground truth verdict/category the tiebreak
/// rules say Stage 2 should return.
///
/// Most cases have exactly one check. CHAIN-SS-1 has three checks that
/// share the same [text] (sent to Stage 2 together, as three flagged
/// phrases in one call, to test composition). CHAIN-REFL-2 has two checks
/// with different [text] (two separate sentences, two separate calls).
class _PhraseCheck {
  const _PhraseCheck({
    required this.id,
    required this.label,
    required this.text,
    required this.phrase,
    required this.expectedVerdict,
    this.expectedCategory,
  });

  final String id;
  final String label;
  final String text;
  final String phrase;
  final String expectedVerdict;
  final String? expectedCategory;
}

class _Case {
  const _Case({
    required this.id,
    required this.ruleTested,
    required this.note,
    required this.checks,
  });

  final String id;
  final String ruleTested;
  final String note;
  final List<_PhraseCheck> checks;
}

const List<_Case> _cases = [
  _Case(
    id: 'GWC-anchor',
    ruleTested:
        'Never use Word Choice merely because the correction changes one '
        'token (existential "haber" agreement)',
    note:
        'Existential "haber" wrongly pluralized to agree with its '
        'complement. Only one token changes (habían -> había) — the '
        'consolidated principle exists specifically so this stays Grammar '
        'rather than drifting to Word Choice.',
    checks: [
      _PhraseCheck(
        id: 'GWC-anchor',
        label: 'habían muchos coches -> Grammar',
        text: 'En la fiesta habían muchos coches aparcados en la calle.',
        phrase: 'habían muchos coches',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
    ],
  ),
  _Case(
    id: 'GWC-T1',
    ruleTested: 'Same rule as GWC-anchor, transfer to an unnamed construction',
    note:
        'Impersonal "hacer" with a time-duration expression is invariable '
        '("hacía dos años", never "hacían"), same one-token-agreement shape '
        'as existential "haber" but a different verb, never mentioned in '
        'the added rules.',
    checks: [
      _PhraseCheck(
        id: 'GWC-T1',
        label: 'Hacían dos años -> Grammar',
        text: 'Hacían dos años que vivía allí cuando decidió mudarse.',
        phrase: 'Hacían dos años',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
    ],
  ),
  _Case(
    id: 'SG-anchor',
    ruleTested:
        'Mandatory contraction (al/del) is Grammar, even though it looks '
        'like a spelling/fusion issue',
    note: 'Missing the obligatory a+el -> al contraction.',
    checks: [
      _PhraseCheck(
        id: 'SG-anchor',
        label: 'a el mercado -> Grammar',
        text: 'Fui a el mercado esta mañana.',
        phrase: 'a el mercado',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
    ],
  ),
  _Case(
    id: 'SG-T1',
    ruleTested: 'Same rule as SG-anchor, transfer to the suppletive-form half',
    note:
        'Con + mí is not valid Spanish; the suppletive form "conmigo" is '
        'obligatory. Same Grammar rule as the al/del contraction, but a '
        'genuinely different error shape (a suppletive pronoun form, not a '
        'preposition+article fusion).',
    checks: [
      _PhraseCheck(
        id: 'SG-T1',
        label: 'con mí -> Grammar',
        text: '¿Quieres venir con mí al cine?',
        phrase: 'con mí',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
    ],
  ),
  _Case(
    id: 'WCO-anchor',
    ruleTested:
        'CONTINUITY BASELINE, not one of the five new rules — dialectal '
        'taboo vocabulary is Other via the pre-existing, unmodified '
        'Restraint paragraph',
    note:
        'Same text as `COG-anchor`/`CTRL-coger` in verdict_battery_merged.dart, '
        'reused for continuity. Included so the report shows whether the '
        'five new Boundary-rule additions coexist with the older Restraint '
        'mechanism without regressing it — not itself evidence about the '
        'new rules.',
    checks: [
      _PhraseCheck(
        id: 'WCO-anchor',
        label: 'coger el autobús -> dialectal/Other',
        text: 'Voy a coger el autobús para ir al centro.',
        phrase: 'coger el autobús',
        expectedVerdict: 'dialectal',
        expectedCategory: 'Other',
      ),
    ],
  ),
  _Case(
    id: 'GO-anchor',
    ruleTested:
        'Pronoun/clitic case, agreement, order, placement, or doubling is '
        'Grammar, never Other',
    note:
        'Reused verbatim from `SLD-1` in verdict_battery_merged.dart for '
        'continuity. "El secreto" is singular, so the correct clitic is "se '
        'lo dije"; "se los" wrongly extends plural marking onto the direct-'
        'object clitic — a clitic-agreement error.',
    checks: [
      _PhraseCheck(
        id: 'GO-anchor',
        label: 'se los dije -> Grammar',
        text: 'Mis padres querían saber el secreto y se los dije.',
        phrase: 'se los dije',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
    ],
  ),
  _Case(
    id: 'GO-T1',
    ruleTested: 'Same rule as GO-anchor, transfer to a clitic-order error',
    note:
        'Reflexive/dative clitic cluster order is fixed (se before me); '
        '"me se cayó" reverses it. Same Grammar-never-Other rule as the '
        'clitic-agreement case above, but the specific defect is order, not '
        'agreement.',
    checks: [
      _PhraseCheck(
        id: 'GO-T1',
        label: 'me se cayó -> Grammar',
        text: 'Estábamos lavando los platos cuando me se cayó el vaso de las manos.',
        phrase: 'me se cayó',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
    ],
  ),
  _Case(
    id: 'CHAIN-SS-1',
    ruleTested:
        'Composition: the se/sé accent rule and the contraction rule must '
        'not bleed into each other',
    note:
        'One sentence, three flagged phrases sent to Stage 2 together in a '
        'single call (not three separate calls) — the point is whether '
        'having a Grammar-flagged contraction ("a el") in the same context '
        'pulls the unrelated accent error ("Se") into Grammar too, or '
        'causes the correct suppletive form ("conmigo") to be overcorrected '
        'by proximity to the other two errors.',
    checks: [
      _PhraseCheck(
        id: 'CHAIN-SS-1-accent',
        label: 'Se -> Spelling (missing accent, unrelated to contraction)',
        text: 'Se amable y ven a el cine conmigo.',
        phrase: 'Se',
        expectedVerdict: 'error',
        expectedCategory: 'Spelling',
      ),
      _PhraseCheck(
        id: 'CHAIN-SS-1-contraction',
        label: 'a el -> Grammar (mandatory contraction)',
        text: 'Se amable y ven a el cine conmigo.',
        phrase: 'a el',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
      _PhraseCheck(
        id: 'CHAIN-SS-1-suppletive',
        label: 'conmigo -> correct as-is, not_an_error',
        text: 'Se amable y ven a el cine conmigo.',
        phrase: 'conmigo',
        expectedVerdict: 'not_an_error',
      ),
    ],
  ),
  _Case(
    id: 'CHAIN-REFL-1',
    ruleTested:
        'Reflexive/non-reflexive verb pairs: obligatory-reflexive branch is '
        'Grammar',
    note:
        '"Levantarse" has no standard non-reflexive use for "to get up"; '
        'the missing "se" is a Grammar error, not a Word Choice or Natural '
        'Language issue.',
    checks: [
      _PhraseCheck(
        id: 'CHAIN-REFL-1',
        label: 'Levantó -> Grammar (missing obligatory reflexive)',
        text: 'Levantó temprano para coger el tren.',
        phrase: 'Levantó',
        expectedVerdict: 'error',
        expectedCategory: 'Grammar',
      ),
    ],
  ),
  _Case(
    id: 'CHAIN-REFL-2',
    ruleTested:
        'Reflexive/non-reflexive verb pairs: alternating-complement branch '
        'must not be overcorrected across the alternation',
    note:
        'Comparative pair across two separate sentences, two separate '
        'Stage 2 calls (not one sentence with two phrases — "decidir el '
        'color" and "decidirse por el azul" are different sentences). Both '
        'sentences as given are independently correct Spanish: "decidir" + '
        'direct object vs. "decidirse" + por-phrase are different, equally '
        'valid complement patterns. This does NOT test miscategorizing a '
        'genuine complement-mismatch error as Natural Language (neither '
        'sentence contains an error) — it tests the narrower claim that the '
        'model does not treat the two patterns as a single right/wrong pair '
        'and "correct" one into the other\'s shape.',
    checks: [
      _PhraseCheck(
        id: 'CHAIN-REFL-2-directObject',
        label: 'Decidí el color del coche -> not_an_error (decidir + direct object)',
        text: 'Decidí el color del coche.',
        phrase: 'Decidí el color del coche',
        expectedVerdict: 'not_an_error',
      ),
      _PhraseCheck(
        id: 'CHAIN-REFL-2-porPhrase',
        label: 'Me decidí por el azul -> not_an_error (decidirse + por-phrase)',
        text: 'Me decidí por el azul.',
        phrase: 'Me decidí por el azul',
        expectedVerdict: 'not_an_error',
      ),
    ],
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Duplicated by value from
/// verdict_battery_merged.dart's `_normalizeForMatch` — this file stays
/// standalone.
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
/// Duplicated by value from verdict_battery_merged.dart's
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
/// the full text plus a JSON array of the flagged phrases sent together
/// (one for most checks; three for CHAIN-SS-1's composition test). Pure —
/// no network.
String _buildUserContent({required String fullText, required List<String> flaggedPhrases}) {
  return '''
Learner's text:
$fullText

Flagged phrases:
${jsonEncode(flaggedPhrases)}
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

/// Duplicated by value from verdict_battery_merged.dart's
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

/// Duplicated by value from verdict_battery_merged.dart's
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

/// Duplicated by value from verdict_battery_merged.dart's
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
/// Duplicated by value from verdict_battery_merged.dart's
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

/// One run's outcome for one [_PhraseCheck].
class _RunRecord {
  const _RunRecord({required this.checkId, required this.runIndex, this.result, this.error});

  final String checkId;
  final int runIndex;
  final _CategorizationResult? result;
  final Object? error;

  bool get isError => error != null;
}

_RunRecord _buildRunRecord({
  required _PhraseCheck check,
  required int runIndex,
  required List<_CategorizationResult> results,
}) {
  return _RunRecord(
    checkId: check.id,
    runIndex: runIndex,
    result: _matchResultFor(results, check.phrase),
  );
}

_RunRecord _errorRunRecord({
  required _PhraseCheck check,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(checkId: check.id, runIndex: runIndex, error: error);
}

String _distKey(String? value) => value ?? '(none)';

/// Aggregated results for one [_PhraseCheck] across all its non-error runs.
/// Every check here has ground truth (unlike verdict_battery_merged.dart's
/// reused half), so [verdictCaughtCount] is always scored;
/// [categoryCaughtCount] is null exactly when [_PhraseCheck.expectedCategory]
/// is null (not_an_error checks expect no category).
class _Aggregate {
  const _Aggregate({
    required this.checkId,
    required this.totalRuns,
    required this.errorRuns,
    required this.okRunCount,
    required this.verdictDistribution,
    required this.categoryDistribution,
    required this.verdictConvergencePct,
    required this.categoryConvergencePct,
    required this.verdictCaughtCount,
    required this.categoryCaughtCount,
  });

  final String checkId;
  final int totalRuns;
  final int errorRuns;
  final int okRunCount;
  final Map<String, int> verdictDistribution;
  final Map<String, int> categoryDistribution;
  final double verdictConvergencePct;
  final double categoryConvergencePct;
  final int verdictCaughtCount;
  final int? categoryCaughtCount;
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

_Aggregate _aggregateCheck(_PhraseCheck check, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  final errorCount = records.length - okRecords.length;

  final verdictDist = <String, int>{};
  final categoryDist = <String, int>{};
  var verdictCaught = 0;
  int? categoryCaught = check.expectedCategory != null ? 0 : null;

  for (final record in okRecords) {
    final verdictKey = record.result == null ? '(missing)' : record.result!.verdict;
    verdictDist[verdictKey] = (verdictDist[verdictKey] ?? 0) + 1;

    final categoryKey =
        record.result == null ? '(missing)' : _distKey(record.result!.category);
    categoryDist[categoryKey] = (categoryDist[categoryKey] ?? 0) + 1;

    if (record.result != null && record.result!.verdict == check.expectedVerdict) {
      verdictCaught += 1;
    }
    if (check.expectedCategory != null &&
        record.result != null &&
        record.result!.category == check.expectedCategory) {
      categoryCaught = (categoryCaught ?? 0) + 1;
    }
  }

  return _Aggregate(
    checkId: check.id,
    totalRuns: records.length,
    errorRuns: errorCount,
    okRunCount: okRecords.length,
    verdictDistribution: verdictDist,
    categoryDistribution: categoryDist,
    verdictConvergencePct: _convergencePct(verdictDist, okRecords.length),
    categoryConvergencePct: _convergencePct(categoryDist, okRecords.length),
    verdictCaughtCount: verdictCaught,
    categoryCaughtCount: categoryCaught,
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

/// Builds the full markdown report: one section per case (its rule and
/// note, then one subsection per check with verdict/category distributions,
/// convergence, catch rate against ground truth, and run-by-run detail).
///
/// Pure — takes already-collected [recordsByCheckId] rather than making any
/// calls itself, so it's golden-testable against synthetic data.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCheckId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Category Tiebreak Transfer Battery')
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
    report
      ..writeln('## ${testCase.id}')
      ..writeln()
      ..writeln('Rule tested: ${testCase.ruleTested}  ')
      ..writeln('Note: ${testCase.note}')
      ..writeln();

    for (final check in testCase.checks) {
      final records = recordsByCheckId[check.id] ?? const <_RunRecord>[];
      final aggregate = _aggregateCheck(check, records);

      report
        ..writeln('### ${check.id}')
        ..writeln()
        ..writeln('- Label: ${check.label}')
        ..writeln('- Text: `${check.text}`')
        ..writeln('- Flagged phrase: "${check.phrase}"')
        ..writeln('- Expected verdict: ${check.expectedVerdict}')
        ..writeln('- Expected category: ${check.expectedCategory ?? '(none)'}')
        ..writeln()
        ..writeln('#### Summary (${aggregate.totalRuns} runs, ${aggregate.errorRuns} error(s))')
        ..writeln()
        ..writeln(
          '- Verdict distribution: ${_describeDistribution(aggregate.verdictDistribution)} '
          '-> convergence ${_percentLabel(_maxCount(aggregate.verdictDistribution), aggregate.okRunCount)} '
          '-> caught ${_percentLabel(aggregate.verdictCaughtCount, aggregate.okRunCount)}',
        )
        ..writeln(
          '- Category distribution: ${_describeDistribution(aggregate.categoryDistribution)} '
          '-> convergence ${_percentLabel(_maxCount(aggregate.categoryDistribution), aggregate.okRunCount)}'
          '${aggregate.categoryCaughtCount == null ? '' : ' -> caught ${_percentLabel(aggregate.categoryCaughtCount!, aggregate.okRunCount)}'}',
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
  required List<String> flaggedPhrases,
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
          userText: _buildUserContent(fullText: fullText, flaggedPhrases: flaggedPhrases),
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

/// Groups a case's checks by shared [_PhraseCheck.text] — checks with the
/// same text are sent to Stage 2 together, in one call, as multiple
/// flagged phrases (this is what makes CHAIN-SS-1's composition test a
/// single call rather than three independent ones). Checks with different
/// text (CHAIN-REFL-2's two sentences) land in separate groups.
Map<String, List<_PhraseCheck>> _groupChecksByText(List<_PhraseCheck> checks) {
  final groups = <String, List<_PhraseCheck>>{};
  for (final check in checks) {
    groups.putIfAbsent(check.text, () => []).add(check);
  }
  return groups;
}

void main() {
  test('category tiebreak battery case fixtures are well-formed', () {
    expect(_cases.length, 10, reason: 'Finalized case list is exactly 10 cases.');

    final caseIds = _cases.map((c) => c.id).toSet();
    expect(caseIds.length, _cases.length, reason: 'Case ids must be unique.');

    final allChecks = _cases.expand((c) => c.checks).toList();
    final checkIds = allChecks.map((c) => c.id).toSet();
    expect(checkIds.length, allChecks.length, reason: 'Check ids must be unique.');

    for (final testCase in _cases) {
      expect(testCase.checks, isNotEmpty, reason: '${testCase.id}: must have at least one check.');
      for (final check in testCase.checks) {
        expect(check.text.trim(), isNotEmpty, reason: check.id);
        expect(
          check.text.contains(check.phrase),
          isTrue,
          reason:
              '${check.id}: flagged phrase "${check.phrase}" not found in '
              'check text.',
        );
        expect(
          _validVerdicts.contains(check.expectedVerdict),
          isTrue,
          reason: '${check.id}: unknown expectedVerdict "${check.expectedVerdict}".',
        );
        if (check.expectedVerdict == 'not_an_error') {
          expect(
            check.expectedCategory,
            isNull,
            reason: '${check.id}: not_an_error checks must have no expectedCategory.',
          );
        } else {
          expect(
            check.expectedCategory,
            isNotNull,
            reason:
                '${check.id}: error/dialectal checks must state an '
                'expectedCategory.',
          );
          expect(
            _validCategories.contains(check.expectedCategory),
            isTrue,
            reason: '${check.id}: unknown expectedCategory "${check.expectedCategory}".',
          );
        }
        if (check.expectedVerdict == 'dialectal') {
          expect(
            check.expectedCategory,
            'Other',
            reason: '${check.id}: dialectal verdict must map to category Other.',
          );
        }
      }
    }

    // Multi-check cases have the expected shape: CHAIN-SS-1's three checks
    // share one sentence (single Stage 2 call); CHAIN-REFL-2's two checks
    // are two different sentences (two calls).
    final chainSS1 = _cases.firstWhere((c) => c.id == 'CHAIN-SS-1');
    expect(chainSS1.checks, hasLength(3));
    expect(chainSS1.checks.map((c) => c.text).toSet(), hasLength(1));

    final chainRefl2 = _cases.firstWhere((c) => c.id == 'CHAIN-REFL-2');
    expect(chainRefl2.checks, hasLength(2));
    expect(chainRefl2.checks.map((c) => c.text).toSet(), hasLength(2));

    for (final testCase in _cases.where((c) => c.id != 'CHAIN-SS-1' && c.id != 'CHAIN-REFL-2')) {
      expect(testCase.checks, hasLength(1), reason: '${testCase.id}: expected a single check.');
    }

    // Every locked-list expected verdict/category, checked explicitly.
    _PhraseCheck checkFor(String id) => allChecks.firstWhere((c) => c.id == id);
    expect(checkFor('GWC-anchor').expectedCategory, 'Grammar');
    expect(checkFor('GWC-T1').expectedCategory, 'Grammar');
    expect(checkFor('SG-anchor').expectedCategory, 'Grammar');
    expect(checkFor('SG-T1').expectedCategory, 'Grammar');
    expect(checkFor('WCO-anchor').expectedVerdict, 'dialectal');
    expect(checkFor('WCO-anchor').expectedCategory, 'Other');
    expect(checkFor('GO-anchor').expectedCategory, 'Grammar');
    expect(checkFor('GO-T1').expectedCategory, 'Grammar');
    expect(checkFor('CHAIN-SS-1-accent').expectedCategory, 'Spelling');
    expect(checkFor('CHAIN-SS-1-contraction').expectedCategory, 'Grammar');
    expect(checkFor('CHAIN-SS-1-suppletive').expectedVerdict, 'not_an_error');
    expect(checkFor('CHAIN-REFL-1').expectedCategory, 'Grammar');
    expect(checkFor('CHAIN-REFL-2-directObject').expectedVerdict, 'not_an_error');
    expect(checkFor('CHAIN-REFL-2-porPhrase').expectedVerdict, 'not_an_error');
  });

  group('_groupChecksByText', () {
    test('groups same-text checks together and different-text checks apart', () {
      final chainSS1 = _cases.firstWhere((c) => c.id == 'CHAIN-SS-1');
      final groups = _groupChecksByText(chainSS1.checks);
      expect(groups, hasLength(1));
      expect(groups.values.single, hasLength(3));

      final chainRefl2 = _cases.firstWhere((c) => c.id == 'CHAIN-REFL-2');
      final refl2Groups = _groupChecksByText(chainRefl2.checks);
      expect(refl2Groups, hasLength(2));
      expect(refl2Groups.values.every((g) => g.length == 1), isTrue);
    });
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

    test('parses multiple objects from one three-phrase call', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "Se", "corrected_phrase": "Sé", "occurrence": 1, '
        '"category": "Spelling", "verdict": "error"},'
        '{"original_phrase": "a el", "corrected_phrase": "al", "occurrence": 1, '
        '"category": "Grammar", "verdict": "error"},'
        '{"original_phrase": "conmigo", "corrected_phrase": "conmigo", '
        '"occurrence": 1, "category": null, "verdict": "not_an_error"}]',
      );
      expect(results, hasLength(3));
      expect(results[2].category, isNull);
      expect(results[2].verdict, 'not_an_error');
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = _parseCategorizationArray(
        '```json\n[{"original_phrase": "me se cayó", "corrected_phrase": '
        '"se me cayó", "occurrence": 1, "category": "Grammar", '
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

  group('_aggregateCheck', () {
    test('an error/category check computes verdict and category catch rate', () {
      final check = _cases.firstWhere((c) => c.id == 'GWC-anchor').checks.single;
      final records = [
        _buildRunRecord(
          check: check,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'habían muchos coches',
              correctedPhrase: 'había muchos coches',
              occurrence: 1,
              category: 'Grammar',
              verdict: 'error',
            ),
          ],
        ),
        _buildRunRecord(
          check: check,
          runIndex: 2,
          results: const [
            _CategorizationResult(
              originalPhrase: 'habían muchos coches',
              correctedPhrase: 'había muchos coches',
              occurrence: 1,
              category: 'Word Choice',
              verdict: 'error',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateCheck(check, records);
      expect(aggregate.okRunCount, 2);
      expect(aggregate.verdictCaughtCount, 2);
      expect(aggregate.categoryCaughtCount, 1);
    });

    test('a not_an_error check leaves categoryCaughtCount null', () {
      final check = _cases.firstWhere((c) => c.id == 'CHAIN-SS-1').checks.firstWhere(
        (c) => c.id == 'CHAIN-SS-1-suppletive',
      );
      final records = [
        _buildRunRecord(
          check: check,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'conmigo',
              correctedPhrase: 'conmigo',
              occurrence: 1,
              category: null,
              verdict: 'not_an_error',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateCheck(check, records);
      expect(aggregate.categoryCaughtCount, isNull);
      expect(aggregate.verdictCaughtCount, 1);
    });

    test('errored runs are excluded from convergence and catch-rate denominators', () {
      final check = _cases.firstWhere((c) => c.id == 'GO-T1').checks.single;
      final records = [
        _buildRunRecord(
          check: check,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'me se cayó',
              correctedPhrase: 'se me cayó',
              occurrence: 1,
              category: 'Grammar',
              verdict: 'error',
            ),
          ],
        ),
        _errorRunRecord(check: check, runIndex: 2, error: StateError('boom')),
      ];

      final aggregate = _aggregateCheck(check, records);
      expect(aggregate.okRunCount, 1);
      expect(aggregate.verdictCaughtCount, 1);
    });
  });

  test('_buildReport includes each check\'s id, expectations, and metrics', () {
    final testCase = _cases.firstWhere((c) => c.id == 'GWC-anchor');
    final check = testCase.checks.single;
    final recordsByCheckId = {
      check.id: [
        _buildRunRecord(
          check: check,
          runIndex: 1,
          results: const [
            _CategorizationResult(
              originalPhrase: 'habían muchos coches',
              correctedPhrase: 'había muchos coches',
              occurrence: 1,
              category: 'Grammar',
              verdict: 'error',
            ),
          ],
        ),
      ],
    };

    final report = _buildReport(
      model: 'test-model',
      runsPerCase: 1,
      generatedAt: DateTime.utc(2026, 1, 1, 12),
      cases: [testCase],
      recordsByCheckId: recordsByCheckId,
      commit: 'abc1234',
    );

    expect(report, contains('# Category Tiebreak Transfer Battery'));
    expect(report, contains('Model: `test-model`'));
    expect(report, contains('Commit: `abc1234`'));
    expect(report, contains('## GWC-anchor'));
    expect(report, contains('### ${check.id}'));
    expect(report, contains('Expected verdict: error'));
    expect(report, contains('Expected category: Grammar'));
    expect(report, contains('-> caught 100.0% (1/1)'));
    expect(report, contains('Run 1: verdict=error, category=Grammar, occurrence=1'));
  });

  test(
    'category tiebreak battery (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the category tiebreak battery. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final recordsByCheckId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in _cases) {
          final groups = _groupChecksByText(testCase.checks);
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (var run = 1; run <= runsPerCase; run++) {
            for (final entry in groups.entries) {
              final fullText = entry.key;
              final groupChecks = entry.value;
              final phrases = groupChecks.map((c) => c.phrase).toList();

              List<_CategorizationResult>? results;
              Object? callError;
              try {
                results = await _callStage2Categorization(
                  httpClient: httpClient,
                  apiKey: apiKey,
                  model: categoryTiebreakModel,
                  fullText: fullText,
                  flaggedPhrases: phrases,
                );
              } catch (error) {
                callError = error;
              }

              for (final check in groupChecks) {
                final record = callError != null
                    ? _errorRunRecord(check: check, runIndex: run, error: callError)
                    : _buildRunRecord(check: check, runIndex: run, results: results!);
                recordsByCheckId.putIfAbsent(check.id, () => []).add(record);
                // ignore: avoid_print
                print(_describeRun(record));
              }

              await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
            }
          }
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: categoryTiebreakModel,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCheckId: recordsByCheckId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 60)),
    tags: ['live'],
  );
}
