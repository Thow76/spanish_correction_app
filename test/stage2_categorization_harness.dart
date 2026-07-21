// Stage 2 categorization harness.
//
// Tests `stage2CategorizationSpanish`
// (lib/core/services/prompts/correction_prompt.dart) — an experimental
// second-stage prompt that takes a flagged phrase (in the full text's
// context) and decides its corrected form, category, and verdict (error /
// dialectal / not_an_error) — against a set of fixed, hand-written
// flagged-phrase inputs.
//
// ISOLATED, not chained to a live Stage 1 call: every fixture's flagged-
// phrase list is hand-written, standing in for whatever Stage 1 would have
// produced. This keeps Stage 2's behaviour separable from Stage 1's — a
// Stage 2 regression can't be a Stage 1 regression in disguise, and vice
// versa. See test/stage1_detection_harness.dart for the detection-only
// harness this one is modeled on (same fixtures -> run records ->
// aggregation -> golden-tested report -> gated live test shape, same direct
// `/v1/chat/completions` call, env-only OPENAI_API_KEY, GPT-5.5 default).
//
// Does NOT touch `correctText()`, existing prompt constants, or any live
// path.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage2_categorization_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/stage2_categorization_harness.dart --timeout none
//
// Writes a report to docs/stage2_categorization_harness.md (override with
// --dart-define=STAGE2_CATEGORIZATION_OUTPUT=...). Override run count per
// case with --dart-define=STAGE2_RUNS_PER_CASE=... (default 10). Override
// the model with --dart-define=STAGE2_CATEGORIZATION_MODEL=... (default
// 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'STAGE2_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'STAGE2_CATEGORIZATION_OUTPUT',
  defaultValue: 'docs/stage2_categorization_harness.md',
);

/// Model used for the live run. Override with
/// `--dart-define=STAGE2_CATEGORIZATION_MODEL=...`, same override pattern
/// as `stage1_detection_harness.dart`'s `stage1Model`.
const String stage2Model = String.fromEnvironment(
  'STAGE2_CATEGORIZATION_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'STAGE2_CALL_DELAY_MS',
  defaultValue: 750,
);

const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};

/// Which battery a case belongs to, so the report can print them under
/// separate headings.
enum _CaseGroup {
  core,
  occurrence,
  dialectal,
  ordinaryVocab,
  omission,
  crossLanguage,
}

String _groupHeading(_CaseGroup group) => switch (group) {
  _CaseGroup.core => 'Core (swap-type, from the validated Stage 1 targets)',
  _CaseGroup.occurrence => 'Occurrence gating case',
  _CaseGroup.dialectal => 'Dialectal',
  _CaseGroup.ordinaryVocab => 'Ordinary regional vocabulary — must not be error',
  _CaseGroup.omission => 'Omission (corrected_phrase diff-usability)',
  _CaseGroup.crossLanguage =>
    'Cross-language category-stability check (PT-2)',
};

/// What's expected of Stage 2's result for one flagged phrase.
///
/// Only dimensions the test case actually specifies are scored (non-null);
/// everything else is still recorded (distribution printed in the report)
/// but doesn't count toward a catch rate. [acceptedVerdicts] is the one
/// dimension that's always required — Stage 2's whole job is classifying
/// error/dialectal/not_an_error, so every case states a ground-truth verdict
/// set even where the task didn't call it out as the case's main point.
class _ExpectedResult {
  const _ExpectedResult({
    required this.flaggedPhrase,
    required this.acceptedVerdicts,
    this.expectedCategory,
    this.expectedCorrectedPhrase,
    this.expectedOccurrence,
  });

  final String flaggedPhrase;
  final Set<String> acceptedVerdicts;
  final String? expectedCategory;
  final String? expectedCorrectedPhrase;
  final int? expectedOccurrence;
}

/// One test case: a full text plus a fixed, hand-written list of flagged
/// phrases (standing in for Stage 1 output) and one [_ExpectedResult] per
/// flagged phrase, same order.
class _Case {
  const _Case({
    required this.id,
    required this.group,
    required this.text,
    required this.flaggedPhrases,
    required this.expectations,
    required this.note,
  });

  final String id;
  final _CaseGroup group;
  final String text;
  final List<String> flaggedPhrases;
  final List<_ExpectedResult> expectations;
  final String note;
}

const List<_Case> _cases = [
  // ── Core (swap-type, from the validated Stage 1 targets) ────────────────
  _Case(
    id: 'ES-1',
    group: _CaseGroup.core,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    flaggedPhrases: ['volví para casa'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'volví para casa',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Grammar',
        expectedCorrectedPhrase: 'volví a casa',
        expectedOccurrence: 1,
      ),
    ],
    note: '"para" -> "a" is a preposition fix: Grammar, not Spelling.',
  ),
  _Case(
    id: 'ES-3',
    group: _CaseGroup.core,
    text:
        'Ayer había mucho trafico y mis amigos llamaron para atrás para '
        'confirmar la cena.',
    flaggedPhrases: ['trafico', 'llamaron para atrás'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'trafico',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Spelling',
      ),
      _ExpectedResult(
        flaggedPhrase: 'llamaron para atrás',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Natural Language',
      ),
    ],
    note:
        'Two independent targets in one case: a missing-accent Spelling fix '
        'and a calque Natural Language fix.',
  ),
  _Case(
    id: 'ES-4',
    group: _CaseGroup.core,
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche.',
    flaggedPhrases: ['pasar un buen tiempo'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'pasar un buen tiempo',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Natural Language',
      ),
    ],
    note: 'Calque -> idiomatic restructure: Natural Language.',
  ),
  _Case(
    id: 'ES-5',
    group: _CaseGroup.core,
    text:
        'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
    flaggedPhrases: ['Espana', 'anos', 'cumpleanos', 'otono'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'Espana',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Spelling',
      ),
      _ExpectedResult(
        flaggedPhrase: 'anos',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Spelling',
      ),
      _ExpectedResult(
        flaggedPhrase: 'cumpleanos',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Spelling',
      ),
      _ExpectedResult(
        flaggedPhrase: 'otono',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Spelling',
      ),
    ],
    note: 'Four independent missing-accent targets, all plain Spelling.',
  ),
  _Case(
    id: 'ES-6',
    group: _CaseGroup.core,
    text: 'Yo fui a casa, yo estudié, y yo hice la cena.',
    flaggedPhrases: ['yo'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'yo',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Natural Language',
        expectedCorrectedPhrase: '',
      ),
    ],
    note:
        'Category-stability check for the redundant-pronoun boundary rule — '
        'the live bug this case guards against: a redundant "yo" repeated '
        'across clauses genuinely fits both Grammar\'s pronoun-use clause '
        'and Natural Language\'s "unnatural combination of otherwise-'
        'acceptable words," and without an explicit tiebreak the category '
        'flip-flopped between runs. The boundary rule exists specifically '
        'so this converges to Natural Language, not Grammar — that '
        'convergence is what\'s under test. corrected_phrase is expected '
        'empty (a pure deletion), and verdict must stay error throughout.',
  ),

  // ── Occurrence gating case ───────────────────────────────────────────────
  _Case(
    id: 'ES-1-occurrence',
    group: _CaseGroup.occurrence,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    flaggedPhrases: ['para'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'para',
        acceptedVerdicts: {'error'},
        expectedOccurrence: 2,
      ),
    ],
    note:
        'Same text as ES-1, but the flagged phrase is the bare, ambiguous '
        '"para" (appears 3 times: before "comprar", before "casa", before '
        '"preparar") to force disambiguation. The intended instance is the '
        '2nd ("para casa" -> "a casa") — the other two are correctly used. '
        'THE KEY RESULT is whether occurrence comes back as 2; category and '
        'corrected_phrase are recorded but not scored here.',
  ),

  // ── Dialectal ─────────────────────────────────────────────────────────
  _Case(
    id: 'ES-2',
    group: _CaseGroup.dialectal,
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
    flaggedPhrases: ['voy para casa'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'voy para casa',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      ),
    ],
    note:
        '"voy para casa" is standard in much of Latin America. Must NOT '
        'come back as error. Record which of dialectal/not_an_error it '
        'actually returns.',
  ),
  _Case(
    id: 'coger',
    group: _CaseGroup.dialectal,
    text: 'Voy a coger el autobús para ir al centro.',
    flaggedPhrases: ['coger el autobús'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'coger el autobús',
        acceptedVerdicts: {'dialectal'},
        expectedCategory: 'Other',
      ),
    ],
    note:
        'Standard in Spain, vulgar in much of Latin America — the '
        'canonical dialectal case. category must be Other per the prompt\'s '
        'own rule for dialectal verdicts.',
  ),

  // ── Ordinary regional vocabulary — must not be error. Confirmation cases
  // for the one open question left by the Stage 1 dialect-variant run:
  // stage1DetectionDialectSpanish's "Flag standard dialect differences"
  // sentence surfaced "ordenador" 2/10 runs even though it's ordinary
  // interchangeable regional vocabulary, not a dialectal split with real
  // risk of confusion or offense (unlike "coger el autobús" above). These
  // cases check that IF Stage 1 ever surfaces this kind of phrase, Stage 2
  // still routes it correctly — never `error`. acceptedVerdicts mirrors
  // ES-2's {'dialectal', 'not_an_error'} exactly; no expectedCategory or
  // expectedCorrectedPhrase, since dialectal->Other and not_an_error->none
  // are both acceptable outcomes here and we want the actual distribution
  // visible, not a single value enforced. ──────────────────────────────
  _Case(
    id: 'ordenador',
    group: _CaseGroup.ordinaryVocab,
    text: 'Voy a usar el ordenador en la oficina.',
    flaggedPhrases: ['ordenador'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'ordenador',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      ),
    ],
    note:
        'The specific case Stage 1\'s dialect variant surfaced (flagged '
        '2/10 by stage1DetectionDialectSpanish, per '
        'docs/stage1_detection_dialect_harness.md) but had never been run '
        'through Stage 2. "ordenador" (Spain) vs. "computadora" (Latin '
        'America) is ordinary regional vocabulary — must not come back as '
        'error. Record which of dialectal/not_an_error it returns, plus '
        'category and corrected_phrase.',
  ),
  _Case(
    id: 'coche',
    group: _CaseGroup.ordinaryVocab,
    text: 'Aparqué el coche cerca de la oficina.',
    flaggedPhrases: ['coche'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'coche',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      ),
    ],
    note:
        'The case Stage 1 kept clean in both the base and dialect-variant '
        'harnesses (never actually surfaced to Stage 2 in practice) — '
        'confirms Stage 2 agrees it is not an error, if it were ever fed '
        'this phrase.',
  ),
  _Case(
    id: 'carro',
    group: _CaseGroup.ordinaryVocab,
    text: 'Lavé el carro el fin de semana.',
    flaggedPhrases: ['carro'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'carro',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      ),
    ],
    note: 'The other side of the coche/carro/auto split — same check.',
  ),

  // ── Omission (corrected_phrase diff-usability) ──────────────────────────
  _Case(
    id: 'ST-O2',
    group: _CaseGroup.omission,
    text: 'Creo está bien, pero no estoy seguro.',
    flaggedPhrases: ['Creo está bien'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'Creo está bien',
        acceptedVerdicts: {'error'},
        expectedCorrectedPhrase: 'Creo que está bien',
      ),
    ],
    note:
        'Missing subordinating "que". The point is whether corrected_phrase '
        'comes back diff-usable ("Creo que está bien") — that\'s what code '
        'would diff against the original to find the insertion.',
  ),
  _Case(
    id: 'ST-O3',
    group: _CaseGroup.omission,
    text: 'Voy la playa este fin de semana.',
    flaggedPhrases: ['Voy la playa'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'Voy la playa',
        acceptedVerdicts: {'error'},
        expectedCorrectedPhrase: 'Voy a la playa',
      ),
    ],
    note: 'Missing preposition "a" — same diff-usability check as ST-O2.',
  ),

  // ── Cross-language category-stability check (PT-2) ──────────────────────
  _Case(
    id: 'PT-2',
    group: _CaseGroup.crossLanguage,
    text: 'Eu gosto de ir a praia nos fins de semana.',
    flaggedPhrases: ['a praia'],
    expectations: [
      _ExpectedResult(
        flaggedPhrase: 'a praia',
        acceptedVerdicts: {'error'},
        expectedCategory: 'Grammar',
        expectedCorrectedPhrase: 'à praia',
      ),
    ],
    note:
        'Portuguese text run through the Spanish-only stage2CategorizationSpanish '
        'prompt deliberately — this is the tiebreak case from '
        'docs/correction_consistency_harness.md\'s PT-2 (60% catch rate, '
        'split Grammar/Spelling under the app\'s current single-call '
        'prompt). The preposition-plus-article-contraction boundary rule '
        'exists specifically so this converges to Grammar, not Spelling — '
        'that convergence is what\'s under test, not general PT support.',
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Copied by value from
/// stage1_detection_harness.dart's `_normalizeForMatch` — this file stays
/// standalone, so it's duplicated rather than imported.
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

/// Case/diacritic-insensitive containment check in either direction. Copied
/// by value from stage1_detection_harness.dart's `_normalizedOverlap`.
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Builds the user-message content sent alongside `stage2CategorizationSpanish`:
/// the learner's full text plus a JSON array of the flagged phrases. Pure —
/// no network, golden-testable on its own.
String buildStage2UserContent({
  required String fullText,
  required List<String> flaggedPhrases,
}) {
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

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. No `response_format` — Stage 2's JSON-array instruction lives
/// entirely in the prompt text, same approach as
/// stage1_detection_harness.dart's `buildChatCompletionsBody`.
Map<String, Object?> buildChatCompletionsBody({
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
/// response body: `choices[0].message.content`, trimmed. Copied by value
/// from stage1_detection_harness.dart's `extractReplyText`.
String extractReplyText(Map<String, Object?> decodedBody) {
  final choices = decodedBody['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException(
      'Chat completions response has no choices.',
    );
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

/// Parses a Stage 2 reply into one [_CategorizationResult] per returned
/// object.
///
/// Tolerates the model wrapping the array in Markdown code fences or
/// trailing commentary by extracting the substring between the first `[`
/// and the last `]` before decoding, same defensive approach as
/// `parseDetectionArray` in stage1_detection_harness.dart. Throws a
/// [FormatException] on anything that doesn't match the expected object
/// shape once extracted — including an unrecognized `verdict` value, since
/// that's a clear sign of prompt drift worth surfacing as a run error
/// rather than silently scoring it as a miss.
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
      throw FormatException(
        'Stage 2 result missing/invalid occurrence: $element',
      );
    }
    if (category != null && category is! String) {
      throw FormatException(
        'Stage 2 result has a non-string category: $element',
      );
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

/// Whether [result] satisfies every dimension [expected] actually specifies
/// (unspecified dimensions don't count against it). Null [result] (Stage 2
/// didn't return a matching object) never counts as caught.
bool _targetFullyCaught(_ExpectedResult expected, _CategorizationResult? result) {
  if (result == null) {
    return false;
  }
  if (!expected.acceptedVerdicts.contains(result.verdict)) {
    return false;
  }
  if (expected.expectedCategory != null &&
      result.category != expected.expectedCategory) {
    return false;
  }
  if (expected.expectedCorrectedPhrase != null &&
      result.correctedPhrase.trim() != expected.expectedCorrectedPhrase!.trim()) {
    return false;
  }
  if (expected.expectedOccurrence != null &&
      result.occurrence != expected.expectedOccurrence) {
    return false;
  }
  return true;
}

/// One run's outcome for one case: one matched result per flagged phrase
/// (null entries mean Stage 2 didn't return anything overlapping that
/// phrase), in `case.flaggedPhrases` order. A transient API failure is
/// recorded via [error] rather than dropped, same as the other harnesses.
class _RunRecord {
  const _RunRecord({
    required this.caseId,
    required this.runIndex,
    this.matchedResults = const [],
    this.error,
  });

  final String caseId;
  final int runIndex;
  final List<_CategorizationResult?> matchedResults;
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
    matchedResults: testCase.flaggedPhrases
        .map((phrase) => _matchResultFor(results, phrase))
        .toList(),
  );
}

_RunRecord _errorRunRecord({
  required _Case testCase,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(caseId: testCase.id, runIndex: runIndex, error: error);
}

/// Aggregated results for one flagged phrase (one "target") within a case,
/// across all its non-error runs.
class _TargetAggregate {
  const _TargetAggregate({
    required this.total,
    required this.verdictDistribution,
    required this.categoryDistribution,
    required this.correctedPhraseDistribution,
    required this.occurrenceDistribution,
    required this.verdictCaughtCount,
    required this.categoryCaughtCount,
    required this.correctedPhraseCaughtCount,
    required this.occurrenceCaughtCount,
  });

  final int total;
  final Map<String, int> verdictDistribution;
  final Map<String, int> categoryDistribution;
  final Map<String, int> correctedPhraseDistribution;
  final Map<String, int> occurrenceDistribution;
  final int verdictCaughtCount;
  final int categoryCaughtCount;
  final int correctedPhraseCaughtCount;
  final int occurrenceCaughtCount;
}

/// Aggregated results for one case across all its runs.
class _CaseAggregate {
  const _CaseAggregate({
    required this.caseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.targets,
    required this.fullyCaughtCount,
    required this.okRunCount,
  });

  final String caseId;
  final int totalRuns;
  final int errorRuns;
  final List<_TargetAggregate> targets;
  final int fullyCaughtCount;
  final int okRunCount;
}

String _distKey(String? value) => value ?? '(none)';

_CaseAggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  final errorCount = records.length - okRecords.length;

  final targets = <_TargetAggregate>[];
  for (var i = 0; i < testCase.flaggedPhrases.length; i++) {
    final expected = testCase.expectations[i];
    final results = okRecords.map((r) => r.matchedResults[i]).toList();

    final verdictDist = <String, int>{};
    final categoryDist = <String, int>{};
    final correctedDist = <String, int>{};
    final occurrenceDist = <String, int>{};
    var verdictCaught = 0;
    var categoryCaught = 0;
    var correctedCaught = 0;
    var occurrenceCaught = 0;

    for (final result in results) {
      final verdictKey = result == null ? '(missing)' : result.verdict;
      verdictDist[verdictKey] = (verdictDist[verdictKey] ?? 0) + 1;

      final categoryKey = result == null ? '(missing)' : _distKey(result.category);
      categoryDist[categoryKey] = (categoryDist[categoryKey] ?? 0) + 1;

      final correctedKey = result == null ? '(missing)' : result.correctedPhrase;
      correctedDist[correctedKey] = (correctedDist[correctedKey] ?? 0) + 1;

      final occurrenceKey = result == null ? '(missing)' : '${result.occurrence}';
      occurrenceDist[occurrenceKey] = (occurrenceDist[occurrenceKey] ?? 0) + 1;

      if (result != null && expected.acceptedVerdicts.contains(result.verdict)) {
        verdictCaught++;
      }
      if (expected.expectedCategory != null &&
          result != null &&
          result.category == expected.expectedCategory) {
        categoryCaught++;
      }
      if (expected.expectedCorrectedPhrase != null &&
          result != null &&
          result.correctedPhrase.trim() ==
              expected.expectedCorrectedPhrase!.trim()) {
        correctedCaught++;
      }
      if (expected.expectedOccurrence != null &&
          result != null &&
          result.occurrence == expected.expectedOccurrence) {
        occurrenceCaught++;
      }
    }

    targets.add(
      _TargetAggregate(
        total: results.length,
        verdictDistribution: verdictDist,
        categoryDistribution: categoryDist,
        correctedPhraseDistribution: correctedDist,
        occurrenceDistribution: occurrenceDist,
        verdictCaughtCount: verdictCaught,
        categoryCaughtCount: categoryCaught,
        correctedPhraseCaughtCount: correctedCaught,
        occurrenceCaughtCount: occurrenceCaught,
      ),
    );
  }

  final fullyCaughtCount = okRecords.where((record) {
    for (var i = 0; i < testCase.flaggedPhrases.length; i++) {
      if (!_targetFullyCaught(testCase.expectations[i], record.matchedResults[i])) {
        return false;
      }
    }
    return true;
  }).length;

  return _CaseAggregate(
    caseId: testCase.id,
    totalRuns: records.length,
    errorRuns: errorCount,
    targets: targets,
    fullyCaughtCount: fullyCaughtCount,
    okRunCount: okRecords.length,
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

String _describeRun(_Case testCase, _RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }

  final parts = <String>[];
  for (var i = 0; i < testCase.flaggedPhrases.length; i++) {
    final flagged = testCase.flaggedPhrases[i];
    final result = record.matchedResults[i];
    if (result == null) {
      parts.add('"$flagged" -> (no matching result returned)');
    } else {
      parts.add(
        '"$flagged" -> verdict=${result.verdict}, '
        'category=${_distKey(result.category)}, '
        'occurrence=${result.occurrence}, '
        'corrected="${result.correctedPhrase}"',
      );
    }
  }

  return '- $prefix: ${parts.join(' | ')}';
}

/// Builds the full markdown report: a header block, then each case group as
/// its own section, one subsection per case (metadata, per-target summary
/// with full distributions, run-by-run breakdown), then an overall-summary
/// table.
///
/// Pure — takes already-collected [recordsByCaseId] rather than making any
/// calls itself, golden-testable against synthetic data with no live API
/// involved, same approach as the other harnesses' `_buildReport`.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Stage 2 Categorization Harness')
    ..writeln()
    ..writeln('Model: `$model`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per case: $runsPerCase')
    ..writeln();

  final summaryRows = <String>[];

  for (final group in _CaseGroup.values) {
    final groupCases = cases.where((c) => c.group == group).toList();
    if (groupCases.isEmpty) {
      continue;
    }

    report
      ..writeln('## ${_groupHeading(group)}')
      ..writeln();

    for (final testCase in groupCases) {
      final records = recordsByCaseId[testCase.id] ?? const <_RunRecord>[];
      final aggregate = _aggregateCase(testCase, records);

      report
        ..writeln('### ${testCase.id}')
        ..writeln()
        ..writeln('- Text: `${testCase.text}`')
        ..writeln('- Flagged phrases: ${jsonEncode(testCase.flaggedPhrases)}')
        ..writeln('- Note: ${testCase.note}')
        ..writeln()
        ..writeln(
          '#### Summary (${aggregate.totalRuns} runs, '
          '${aggregate.errorRuns} error(s))',
        )
        ..writeln();

      for (var i = 0; i < testCase.flaggedPhrases.length; i++) {
        final flagged = testCase.flaggedPhrases[i];
        final expected = testCase.expectations[i];
        final target = aggregate.targets[i];

        report
          ..writeln('- Target ${i + 1} ("$flagged"):')
          ..writeln(
            '  - Verdict distribution: '
            '${_describeDistribution(target.verdictDistribution)} '
            '(accepted: ${(expected.acceptedVerdicts.toList()..sort()).join('/')}) '
            '-> ${_percentLabel(target.verdictCaughtCount, target.total)}',
          )
          ..writeln(
            '  - Category distribution: '
            '${_describeDistribution(target.categoryDistribution)}'
            '${expected.expectedCategory == null ? ' (not scored)' : ' (expected ${expected.expectedCategory}) -> ${_percentLabel(target.categoryCaughtCount, target.total)}'}',
          )
          ..writeln(
            '  - Corrected-phrase distribution: '
            '${_describeDistribution(target.correctedPhraseDistribution)}'
            '${expected.expectedCorrectedPhrase == null ? ' (not scored)' : ' (expected "${expected.expectedCorrectedPhrase}") -> ${_percentLabel(target.correctedPhraseCaughtCount, target.total)}'}',
          )
          ..writeln(
            '  - Occurrence distribution: '
            '${_describeDistribution(target.occurrenceDistribution)}'
            '${expected.expectedOccurrence == null ? ' (not scored)' : ' (expected ${expected.expectedOccurrence}) -> ${_percentLabel(target.occurrenceCaughtCount, target.total)}'}',
          );
      }

      final fullyCaughtLabel = _percentLabel(
        aggregate.fullyCaughtCount,
        aggregate.okRunCount,
      );
      report
        ..writeln('- Fully caught (every scored dimension in one run): $fullyCaughtLabel')
        ..writeln()
        ..writeln('#### Run detail')
        ..writeln();

      for (final record in records) {
        report.writeln(_describeRun(testCase, record));
      }
      report.writeln();

      final verdictRates = List.generate(
        testCase.flaggedPhrases.length,
        (i) => _percentLabel(
          aggregate.targets[i].verdictCaughtCount,
          aggregate.targets[i].total,
        ),
      );
      summaryRows.add(
        '| ${testCase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
        '$fullyCaughtLabel (fully caught) | ${verdictRates.join(', ')} |',
      );
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Case | Runs | Errors | Headline rate | Per-target verdict rates |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final row in summaryRows) {
    report.writeln(row);
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
        buildChatCompletionsBody(
          model: model,
          systemPrompt: stage2CategorizationSpanish,
          userText: buildStage2UserContent(
            fullText: fullText,
            flaggedPhrases: flaggedPhrases,
          ),
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

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

  return _parseCategorizationArray(extractReplyText(decoded));
}

void main() {
  test('stage2 categorization harness case fixtures are well-formed', () {
    expect(
      _cases.length,
      14,
      reason:
          '5 core + 1 occurrence + 2 dialectal + 3 ordinary-vocab + 2 '
          'omission + 1 cross-language.',
    );

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(testCase.text.trim(), isNotEmpty, reason: testCase.id);
      expect(
        testCase.expectations.length,
        testCase.flaggedPhrases.length,
        reason: '${testCase.id}: one expectation per flagged phrase.',
      );

      for (var i = 0; i < testCase.flaggedPhrases.length; i++) {
        final flagged = testCase.flaggedPhrases[i];
        expect(
          testCase.text.contains(flagged),
          isTrue,
          reason:
              '${testCase.id}: flagged phrase "$flagged" not found in case '
              'text.',
        );
        expect(
          testCase.expectations[i].flaggedPhrase,
          flagged,
          reason: '${testCase.id}: expectations must line up with flaggedPhrases.',
        );
        expect(
          testCase.expectations[i].acceptedVerdicts.isNotEmpty,
          isTrue,
          reason: '${testCase.id}: acceptedVerdicts must be non-empty.',
        );
        expect(
          testCase.expectations[i].acceptedVerdicts.difference(_validVerdicts),
          isEmpty,
          reason: '${testCase.id}: unknown verdict in acceptedVerdicts.',
        );
      }
    }

    final idsByGroup = {
      for (final group in _CaseGroup.values)
        group: _cases.where((c) => c.group == group).map((c) => c.id).toList(),
    };
    expect(idsByGroup[_CaseGroup.core], ['ES-1', 'ES-3', 'ES-4', 'ES-5', 'ES-6']);
    expect(idsByGroup[_CaseGroup.occurrence], ['ES-1-occurrence']);
    expect(idsByGroup[_CaseGroup.dialectal], ['ES-2', 'coger']);
    expect(idsByGroup[_CaseGroup.ordinaryVocab], ['ordenador', 'coche', 'carro']);
    expect(idsByGroup[_CaseGroup.omission], ['ST-O2', 'ST-O3']);
    expect(idsByGroup[_CaseGroup.crossLanguage], ['PT-2']);

    // Every ordinary-vocab case must accept exactly {dialectal, not_an_error}
    // — error is a hard fail for all of them, per the scoring rule.
    for (final testCase in _cases.where((c) => c.group == _CaseGroup.ordinaryVocab)) {
      expect(
        testCase.expectations.single.acceptedVerdicts,
        {'dialectal', 'not_an_error'},
        reason: testCase.id,
      );
    }
  });

  test(
    'stage2CategorizationSpanish prompt asks for corrected/category/verdict '
    'JSON, one object per flagged phrase',
    () {
      expect(stage2CategorizationSpanish, contains('Spanish tutor'));
      expect(stage2CategorizationSpanish, contains('occurrence'));
      expect(stage2CategorizationSpanish, contains('"verdict"'));
      expect(stage2CategorizationSpanish, contains('error, dialectal, not_an_error'));
      expect(stage2CategorizationSpanish, contains('collocation test'));
      expect(stage2CategorizationSpanish, contains('Calque test'));
      expect(
        stage2CategorizationSpanish,
        contains('preposition-plus-article contraction'),
      );
      expect(
        stage2CategorizationSpanish,
        contains('stylistic redundancy of an otherwise correctly used pronoun'),
      );
    },
  );

  group('buildStage2UserContent', () {
    test('includes the full text and a JSON array of flagged phrases', () {
      final content = buildStage2UserContent(
        fullText: 'Voy para casa.',
        flaggedPhrases: ['voy para casa'],
      );

      expect(content, contains('Voy para casa.'));
      expect(content, contains(jsonEncode(['voy para casa'])));
    });

    test('JSON-encodes multiple flagged phrases as a single array', () {
      final content = buildStage2UserContent(
        fullText: 'Texto de ejemplo.',
        flaggedPhrases: ['uno', 'dos'],
      );

      expect(content, contains(jsonEncode(['uno', 'dos'])));
    });
  });

  group('_parseCategorizationArray', () {
    test('parses a populated array', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "trafico", "corrected_phrase": "tráfico", '
        '"occurrence": 1, "category": "Spelling", "verdict": "error"}]',
      );

      expect(results, hasLength(1));
      expect(results.single.originalPhrase, 'trafico');
      expect(results.single.correctedPhrase, 'tráfico');
      expect(results.single.occurrence, 1);
      expect(results.single.category, 'Spelling');
      expect(results.single.verdict, 'error');
    });

    test('parses a null category for not_an_error', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "coche", "corrected_phrase": "coche", '
        '"occurrence": 1, "category": null, "verdict": "not_an_error"}]',
      );

      expect(results.single.category, isNull);
      expect(results.single.verdict, 'not_an_error');
    });

    test('parses an empty array', () {
      expect(_parseCategorizationArray('[]'), isEmpty);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = _parseCategorizationArray(
        '```json\n[{"original_phrase": "trafico", "corrected_phrase": '
        '"tráfico", "occurrence": 1, "category": "Spelling", "verdict": '
        '"error"}]\n```',
      );
      expect(results, hasLength(1));
    });

    test('throws when no array is present', () {
      expect(
        () => _parseCategorizationArray('No errors found.'),
        throwsFormatException,
      );
    });

    test('throws when an element is missing original_phrase', () {
      expect(
        () => _parseCategorizationArray(
          '[{"corrected_phrase": "x", "occurrence": 1, "category": "Other", '
          '"verdict": "error"}]',
        ),
        throwsFormatException,
      );
    });

    test('throws when occurrence is not an integer', () {
      expect(
        () => _parseCategorizationArray(
          '[{"original_phrase": "x", "corrected_phrase": "y", '
          '"occurrence": "first", "category": "Other", "verdict": "error"}]',
        ),
        throwsFormatException,
      );
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
    _CategorizationResult result({
      required String originalPhrase,
      String verdict = 'error',
    }) {
      return _CategorizationResult(
        originalPhrase: originalPhrase,
        correctedPhrase: 'x',
        occurrence: 1,
        category: 'Other',
        verdict: verdict,
      );
    }

    test('matches by normalized overlap', () {
      final match = _matchResultFor(
        [result(originalPhrase: 'TRÁFICO')],
        'trafico',
      );
      expect(match, isNotNull);
      expect(match!.originalPhrase, 'TRÁFICO');
    });

    test('returns null when nothing overlaps', () {
      expect(_matchResultFor([result(originalPhrase: 'otono')], 'trafico'), isNull);
    });

    test('returns null for an empty results list', () {
      expect(_matchResultFor(const [], 'trafico'), isNull);
    });
  });

  group('_targetFullyCaught', () {
    const expected = _ExpectedResult(
      flaggedPhrase: 'trafico',
      acceptedVerdicts: {'error'},
      expectedCategory: 'Spelling',
      expectedCorrectedPhrase: 'tráfico',
      expectedOccurrence: 1,
    );

    _CategorizationResult result({
      String verdict = 'error',
      String? category = 'Spelling',
      String correctedPhrase = 'tráfico',
      int occurrence = 1,
    }) {
      return _CategorizationResult(
        originalPhrase: 'trafico',
        correctedPhrase: correctedPhrase,
        occurrence: occurrence,
        category: category,
        verdict: verdict,
      );
    }

    test('true when every specified dimension matches', () {
      expect(_targetFullyCaught(expected, result()), isTrue);
    });

    test('false when result is null', () {
      expect(_targetFullyCaught(expected, null), isFalse);
    });

    test('false when verdict is not accepted', () {
      expect(
        _targetFullyCaught(expected, result(verdict: 'dialectal')),
        isFalse,
      );
    });

    test('false when category mismatches', () {
      expect(
        _targetFullyCaught(expected, result(category: 'Word Choice')),
        isFalse,
      );
    });

    test('false when corrected_phrase mismatches', () {
      expect(
        _targetFullyCaught(expected, result(correctedPhrase: 'trafico')),
        isFalse,
      );
    });

    test('false when occurrence mismatches', () {
      expect(_targetFullyCaught(expected, result(occurrence: 2)), isFalse);
    });

    test('unspecified dimensions never block a match', () {
      const looseExpected = _ExpectedResult(
        flaggedPhrase: 'voy para casa',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      );
      final looseResult = _CategorizationResult(
        originalPhrase: 'voy para casa',
        correctedPhrase: 'voy para casa',
        occurrence: 1,
        category: null,
        verdict: 'not_an_error',
      );
      expect(_targetFullyCaught(looseExpected, looseResult), isTrue);
    });
  });

  group('_buildRunRecord / _errorRunRecord', () {
    test('matches each flagged phrase to its result, in order', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-3');
      final record = _buildRunRecord(
        testCase: testCase,
        runIndex: 1,
        results: [
          const _CategorizationResult(
            originalPhrase: 'trafico',
            correctedPhrase: 'tráfico',
            occurrence: 1,
            category: 'Spelling',
            verdict: 'error',
          ),
          const _CategorizationResult(
            originalPhrase: 'llamaron para atrás',
            correctedPhrase: 'devolvieron la llamada',
            occurrence: 1,
            category: 'Natural Language',
            verdict: 'error',
          ),
        ],
      );

      expect(record.caseId, 'ES-3');
      expect(record.matchedResults, hasLength(2));
      expect(record.matchedResults[0]!.correctedPhrase, 'tráfico');
      expect(record.matchedResults[1]!.correctedPhrase, 'devolvieron la llamada');
      expect(record.isError, isFalse);
    });

    test('a flagged phrase with no matching result gets a null entry', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-1');
      final record = _buildRunRecord(testCase: testCase, runIndex: 1, results: const []);

      expect(record.matchedResults, [null]);
    });

    test('_errorRunRecord carries the error and no data', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-1');
      final record = _errorRunRecord(
        testCase: testCase,
        runIndex: 2,
        error: StateError('timed out'),
      );

      expect(record.isError, isTrue);
      expect(record.error, isA<StateError>());
      expect(record.matchedResults, isEmpty);
    });
  });

  group('_aggregateCase', () {
    test('rates and distributions computed over non-error runs only', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-1');

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
              correctedPhrase: 'volví a casa',
              occurrence: 1,
              category: 'Spelling',
              verdict: 'error',
            ),
          ],
        ),
        _errorRunRecord(testCase: testCase, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.targets, hasLength(1));

      final target = aggregate.targets.single;
      expect(target.total, 2);
      expect(target.verdictCaughtCount, 2);
      expect(target.categoryCaughtCount, 1);
      expect(target.correctedPhraseCaughtCount, 2);
      expect(target.occurrenceCaughtCount, 2);
      expect(target.categoryDistribution, {'Grammar': 1, 'Spelling': 1});

      // Only run 1 satisfies every scored dimension (run 2's category is
      // Spelling, not the expected Grammar).
      expect(aggregate.fullyCaughtCount, 1);
      expect(aggregate.okRunCount, 2);
    });

    test('a missing match counts against every scored dimension', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-1');
      final records = [
        _buildRunRecord(testCase: testCase, runIndex: 1, results: const []),
      ];

      final aggregate = _aggregateCase(testCase, records);
      final target = aggregate.targets.single;

      expect(target.verdictDistribution, {'(missing)': 1});
      expect(target.verdictCaughtCount, 0);
      expect(aggregate.fullyCaughtCount, 0);
    });

    test('all runs erroring yields zeroed aggregates, not a crash', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-1');
      final records = [
        _errorRunRecord(testCase: testCase, runIndex: 1, error: StateError('a')),
        _errorRunRecord(testCase: testCase, runIndex: 2, error: StateError('b')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 2);
      expect(aggregate.errorRuns, 2);
      expect(aggregate.okRunCount, 0);
      expect(aggregate.fullyCaughtCount, 0);
      expect(aggregate.targets.single.total, 0);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, grouped sections, per-target distributions, run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: const [
          _Case(
            id: 'TEST-1-core',
            group: _CaseGroup.core,
            text: 'Ejemplo con un error de prueba.',
            flaggedPhrases: ['error de prueba'],
            expectations: [
              _ExpectedResult(
                flaggedPhrase: 'error de prueba',
                acceptedVerdicts: {'error'},
                expectedCategory: 'Other',
              ),
            ],
            note: 'Synthetic case for report golden test.',
          ),
          _Case(
            id: 'TEST-2-occurrence',
            group: _CaseGroup.occurrence,
            text: 'Para probar, para verificar, para confirmar.',
            flaggedPhrases: ['para'],
            expectations: [
              _ExpectedResult(
                flaggedPhrase: 'para',
                acceptedVerdicts: {'error'},
                expectedOccurrence: 2,
              ),
            ],
            note: 'Synthetic occurrence case for report golden test.',
          ),
          _Case(
            id: 'TEST-3-ordinary-vocab',
            group: _CaseGroup.ordinaryVocab,
            text: 'Usé la palabra ordinaria en la oficina.',
            flaggedPhrases: ['palabra ordinaria'],
            expectations: [
              _ExpectedResult(
                flaggedPhrase: 'palabra ordinaria',
                acceptedVerdicts: {'dialectal', 'not_an_error'},
              ),
            ],
            note: 'Synthetic ordinary-vocab case for report golden test.',
          ),
        ],
        recordsByCaseId: {
          'TEST-1-core': [
            _buildRunRecord(
              testCase: const _Case(
                id: 'TEST-1-core',
                group: _CaseGroup.core,
                text: 'Ejemplo con un error de prueba.',
                flaggedPhrases: ['error de prueba'],
                expectations: [
                  _ExpectedResult(
                    flaggedPhrase: 'error de prueba',
                    acceptedVerdicts: {'error'},
                    expectedCategory: 'Other',
                  ),
                ],
                note: '',
              ),
              runIndex: 1,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'error de prueba',
                  correctedPhrase: 'error corregido',
                  occurrence: 1,
                  category: 'Other',
                  verdict: 'error',
                ),
              ],
            ),
            _errorRunRecord(
              testCase: const _Case(
                id: 'TEST-1-core',
                group: _CaseGroup.core,
                text: 'Ejemplo con un error de prueba.',
                flaggedPhrases: ['error de prueba'],
                expectations: [
                  _ExpectedResult(
                    flaggedPhrase: 'error de prueba',
                    acceptedVerdicts: {'error'},
                    expectedCategory: 'Other',
                  ),
                ],
                note: '',
              ),
              runIndex: 2,
              error: StateError('Stage 2 call timed out'),
            ),
          ],
          'TEST-2-occurrence': [
            _buildRunRecord(
              testCase: const _Case(
                id: 'TEST-2-occurrence',
                group: _CaseGroup.occurrence,
                text: 'Para probar, para verificar, para confirmar.',
                flaggedPhrases: ['para'],
                expectations: [
                  _ExpectedResult(
                    flaggedPhrase: 'para',
                    acceptedVerdicts: {'error'},
                    expectedOccurrence: 2,
                  ),
                ],
                note: '',
              ),
              runIndex: 1,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'para',
                  correctedPhrase: 'para',
                  occurrence: 2,
                  category: 'Grammar',
                  verdict: 'error',
                ),
              ],
            ),
            _buildRunRecord(
              testCase: const _Case(
                id: 'TEST-2-occurrence',
                group: _CaseGroup.occurrence,
                text: 'Para probar, para verificar, para confirmar.',
                flaggedPhrases: ['para'],
                expectations: [
                  _ExpectedResult(
                    flaggedPhrase: 'para',
                    acceptedVerdicts: {'error'},
                    expectedOccurrence: 2,
                  ),
                ],
                note: '',
              ),
              runIndex: 2,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'para',
                  correctedPhrase: 'para',
                  occurrence: 1,
                  category: 'Grammar',
                  verdict: 'error',
                ),
              ],
            ),
          ],
          'TEST-3-ordinary-vocab': [
            _buildRunRecord(
              testCase: const _Case(
                id: 'TEST-3-ordinary-vocab',
                group: _CaseGroup.ordinaryVocab,
                text: 'Usé la palabra ordinaria en la oficina.',
                flaggedPhrases: ['palabra ordinaria'],
                expectations: [
                  _ExpectedResult(
                    flaggedPhrase: 'palabra ordinaria',
                    acceptedVerdicts: {'dialectal', 'not_an_error'},
                  ),
                ],
                note: '',
              ),
              runIndex: 1,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'palabra ordinaria',
                  correctedPhrase: 'palabra ordinaria',
                  occurrence: 1,
                  category: null,
                  verdict: 'not_an_error',
                ),
              ],
            ),
            _buildRunRecord(
              testCase: const _Case(
                id: 'TEST-3-ordinary-vocab',
                group: _CaseGroup.ordinaryVocab,
                text: 'Usé la palabra ordinaria en la oficina.',
                flaggedPhrases: ['palabra ordinaria'],
                expectations: [
                  _ExpectedResult(
                    flaggedPhrase: 'palabra ordinaria',
                    acceptedVerdicts: {'dialectal', 'not_an_error'},
                  ),
                ],
                note: '',
              ),
              runIndex: 2,
              results: const [
                _CategorizationResult(
                  originalPhrase: 'palabra ordinaria',
                  correctedPhrase: 'palabra ordinaria',
                  occurrence: 1,
                  category: 'Other',
                  verdict: 'dialectal',
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
    'stage2 categorization harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the Stage 2 categorization harness. '
          'This script does NOT fall back to any hardcoded/default key — '
          'no AppConfig involved, by design (see the file header).',
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
                model: stage2Model,
                fullText: testCase.text,
                flaggedPhrases: testCase.flaggedPhrases,
              );
              record = _buildRunRecord(
                testCase: testCase,
                runIndex: run,
                results: results,
              );
            } catch (error) {
              record = _errorRunRecord(testCase: testCase, runIndex: run, error: error);
            }
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(testCase, record));
            await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
          }

          recordsByCaseId[testCase.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: stage2Model,
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
    r'"# Stage 2 Categorization Harness\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## Core (swap-type, from the validated Stage 1 targets)\n\n### TEST-1-core\n\n- Text: `Ejemplo con un error de prueba.`\n- Flagged phrases: [\"error de prueba\"]\n- Note: Synthetic case for report golden test.\n\n#### Summary (2 runs, 1 error(s))\n\n- Target 1 (\"error de prueba\"):\n  - Verdict distribution: error: 1 (accepted: error) -> 100.0% (1/1)\n  - Category distribution: Other: 1 (expected Other) -> 100.0% (1/1)\n  - Corrected-phrase distribution: error corregido: 1 (not scored)\n  - Occurrence distribution: 1: 1 (not scored)\n- Fully caught (every scored dimension in one run): 100.0% (1/1)\n\n#### Run detail\n\n- Run 1: \"error de prueba\" -> verdict=error, category=Other, occurrence=1, corrected=\"error corregido\"\n- Run 2: ERROR — Bad state: Stage 2 call timed out\n\n## Occurrence gating case\n\n### TEST-2-occurrence\n\n- Text: `Para probar, para verificar, para confirmar.`\n- Flagged phrases: [\"para\"]\n- Note: Synthetic occurrence case for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Target 1 (\"para\"):\n  - Verdict distribution: error: 2 (accepted: error) -> 100.0% (2/2)\n  - Category distribution: Grammar: 2 (not scored)\n  - Corrected-phrase distribution: para: 2 (not scored)\n  - Occurrence distribution: 1: 1, 2: 1 (expected 2) -> 50.0% (1/2)\n- Fully caught (every scored dimension in one run): 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: \"para\" -> verdict=error, category=Grammar, occurrence=2, corrected=\"para\"\n- Run 2: \"para\" -> verdict=error, category=Grammar, occurrence=1, corrected=\"para\"\n\n## Ordinary regional vocabulary — must not be error\n\n### TEST-3-ordinary-vocab\n\n- Text: `Usé la palabra ordinaria en la oficina.`\n- Flagged phrases: [\"palabra ordinaria\"]\n- Note: Synthetic ordinary-vocab case for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Target 1 (\"palabra ordinaria\"):\n  - Verdict distribution: dialectal: 1, not_an_error: 1 (accepted: dialectal/not_an_error) -> 100.0% (2/2)\n  - Category distribution: (none): 1, Other: 1 (not scored)\n  - Corrected-phrase distribution: palabra ordinaria: 2 (not scored)\n  - Occurrence distribution: 1: 2 (not scored)\n- Fully caught (every scored dimension in one run): 100.0% (2/2)\n\n#### Run detail\n\n- Run 1: \"palabra ordinaria\" -> verdict=not_an_error, category=(none), occurrence=1, corrected=\"palabra ordinaria\"\n- Run 2: \"palabra ordinaria\" -> verdict=dialectal, category=Other, occurrence=1, corrected=\"palabra ordinaria\"\n\n---\n\n## Overall summary\n\n| Case | Runs | Errors | Headline rate | Per-target verdict rates |\n| --- | --- | --- | --- | --- |\n| TEST-1-core | 2 | 1 | 100.0% (1/1) (fully caught) | 100.0% (1/1) |\n| TEST-2-occurrence | 2 | 0 | 50.0% (1/2) (fully caught) | 100.0% (2/2) |\n| TEST-3-ordinary-vocab | 2 | 0 | 100.0% (2/2) (fully caught) | 100.0% (2/2) |\n"';
