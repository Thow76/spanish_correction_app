// Chained Stage 1 -> Stage 2 harness.
//
// Runs the REAL pipeline live: each battery sentence goes through Stage 1
// detection (`stage1DetectionDialectSpanish` — the dialect-flagging variant
// being adopted, not the plain `stage1DetectionSpanish`), and whatever
// Stage 1 actually flags — messy spans included — is fed straight into
// Stage 2 categorization (`stage2CategorizationSpanish`). This is the first
// test of the two stages actually working together on real Stage 1 output,
// not the hand-written, idealized flagged-phrase lists
// test/stage2_categorization_harness.dart uses to keep Stage 2 separable
// from Stage 1. That separability was deliberate (a Stage 2 regression
// can't be mistaken for a Stage 1 regression, and vice versa) — this
// harness is the deliberate re-integration test on top of it, run only
// after both stages were already validated independently.
//
// Reuses both stages' call/parse paths, copied by value (this file stays
// standalone like every other harness here — no cross-test-file imports):
//   - Stage 1 side: `buildChatCompletionsBody`/`extractReplyText`/
//     `parseDetectionArray`/`_normalizeForMatch`/`_normalizedOverlap`,
//     copied from test/stage1_detection_harness.dart (and reused verbatim by
//     test/stage1_detection_dialect_harness.dart already).
//   - Stage 2 side: `_CategorizationResult`/`_parseCategorizationArray`/
//     `buildStage2UserContent`/`_matchResultFor`, copied from
//     test/stage2_categorization_harness.dart. Note `buildChatCompletionsBody`
//     and `extractReplyText` are identical between the two stages'
//     harnesses, so they're defined exactly once here, not twice.
//
// Handoff shape: Stage 1 returns a JSON array of quoted phrase strings.
// Stage 2 expects the learner's full text plus that same array of flagged
// phrase strings (`buildStage2UserContent(fullText:, flaggedPhrases:)`) —
// Stage 1's output is passed straight through as Stage 2's input with no
// transformation, which is exactly what the real pipeline would do.
//
// Per sentence, per run:
//   1. Call Stage 1 with the sentence text. Parse the flagged phrases.
//   2. If Stage 1 flagged nothing, record "clean — no Stage 2 call" and
//      move on (no Stage 2 call is made — nothing to categorize).
//   3. Otherwise call Stage 2 with the full text + Stage 1's actual flagged
//      phrases (not a hand-written stand-in). Parse the categorizations.
//   4. Record the full chain: what Stage 1 flagged, and for each, Stage 2's
//      verdict/category/corrected_phrase/occurrence (or that Stage 2 didn't
//      return a matching result, or that the Stage 2 call itself failed).
//
// Scoring is deliberately narrow — the point of chaining is to discover
// behaviour, not assert it. A hard pass/fail expectation exists ONLY for:
//   - Genuine errors (ES-1/ES-3/ES-4/ES-5): when Stage 1 flags something
//     overlapping a known error target, Stage 2's verdict for it must be
//     `error`.
//   - Ordinary regional vocabulary (ordenador/coche/carro): when Stage 1
//     flags the word, Stage 2's verdict must be `dialectal` or
//     `not_an_error` — never `error`.
// Everything else — dialectal/borderline (ES-2, coger), omissions
// (ST-O1..ST-O4), redundancy (ES-6, ST-R2), and the cross-language tiebreak
// (PT-2) — is observational only: the full chain is recorded (flagged span
// distribution, and for flagged runs, Stage 2's verdict/category/
// corrected_phrase/occurrence) with no pass/fail, because this is precisely
// where Stage 1's real (messy) output is expected to differ from the
// idealized fixtures Stage 2 was validated against — reading it is the
// point, not grading it.
//
// Does NOT touch `correctText()`, any prompt constant, or any live path.
//
// Run counts are TIERED per sentence, not a flat count, based on how stable
// each phrase already proved in the isolated Stage 1/Stage 2 harness runs —
// this concentrates live calls where categorization actually earns its
// keep instead of re-confirming already-rock-solid phrases 10 times over:
//   - Tier A (1 run): ES-1, ES-3, ES-4, ES-5, ST-O2, ST-O3 — already 10/10
//     stable in isolated Stage 1 detection, low integration risk. One
//     chained run just confirms the handoff doesn't break something.
//   - Tier B (3 runs): ES-2, coger, ordenador, coche, carro, ST-O1, ST-O4,
//     PT-2 — fairly stable, enough runs to see whether verdict/category
//     holds or wobbles without a full 10.
//   - Tier C (10 runs): ES-6, ST-R2 — the problem areas where Stage 1
//     produces junk spans (whole sentences, ", y" fragments) and Stage 2's
//     handling of them is the whole point of this harness. Full 10 runs to
//     characterise the behaviour properly.
// Total: 6x1 + 8x3 + 2x10 = 50 chained calls (up to ~100 HTTP calls, since
// a flagged run makes both a Stage 1 and a Stage 2 call), versus 320 HTTP
// calls at a flat 10 runs/sentence across all 16 sentences. The generated
// report states each sentence's actual run count next to its results (via
// the existing "N runs" summary line) and totals the real Stage 1/Stage 2
// call counts actually made.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage1_stage2_chained_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls — ~50
// chained calls per the tiering above, up to ~100 HTTP calls total):
//   OPENAI_API_KEY=sk-... flutter test test/stage1_stage2_chained_harness.dart --timeout none
//
// Writes a report to docs/stage1_stage2_chained_harness.md (override with
// --dart-define=CHAINED_OUTPUT=...). Override each tier's run count with
// --dart-define=CHAINED_TIER_A_RUNS=... / CHAINED_TIER_B_RUNS=... /
// CHAINED_TIER_C_RUNS=... (default 1/3/10). Override either stage's model
// independently with --dart-define=CHAINED_STAGE1_MODEL=... /
// --dart-define=CHAINED_STAGE2_MODEL=... (both default 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

/// Tier A: 1 run — already 10/10 stable in isolated Stage 1 detection, low
/// integration risk.
const int tierARuns = int.fromEnvironment('CHAINED_TIER_A_RUNS', defaultValue: 1);

/// Tier B: 3 runs — fairly stable, enough to see whether verdict/category
/// wobbles without a full 10.
const int tierBRuns = int.fromEnvironment('CHAINED_TIER_B_RUNS', defaultValue: 3);

/// Tier C: 10 runs — the messy-span problem cases where Stage 2's handling
/// of junk Stage 1 output is the whole point of this harness.
const int tierCRuns = int.fromEnvironment('CHAINED_TIER_C_RUNS', defaultValue: 10);

const String outputPath = String.fromEnvironment(
  'CHAINED_OUTPUT',
  defaultValue: 'docs/stage1_stage2_chained_harness.md',
);

const String chainedStage1Model = String.fromEnvironment(
  'CHAINED_STAGE1_MODEL',
  defaultValue: 'gpt-5.5',
);

const String chainedStage2Model = String.fromEnvironment(
  'CHAINED_STAGE2_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every live call (Stage 1 or Stage 2), same rate-limit
/// mitigation the other harnesses in this repo use. Chained runs make up to
/// two calls each, so this applies twice on a flagged run.
const int callDelayMs = int.fromEnvironment(
  'CHAINED_CALL_DELAY_MS',
  defaultValue: 750,
);

const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};

/// Which battery a sentence belongs to, so the report can print them under
/// separate headings.
enum _SentenceGroup {
  genuineErrors,
  dialectalBorderline,
  ordinaryVocab,
  omissions,
  redundancy,
  crossLanguage,
}

String _groupHeading(_SentenceGroup group) => switch (group) {
  _SentenceGroup.genuineErrors =>
    'Genuine errors (swap-type) — Stage 2 verdict must be error when Stage 1 '
        'flags the target',
  _SentenceGroup.dialectalBorderline => 'Dialectal / borderline (observational)',
  _SentenceGroup.ordinaryVocab =>
    'Ordinary regional vocabulary — must not chain into error',
  _SentenceGroup.omissions =>
    'Omissions (corrected_phrase diff-usability — observational)',
  _SentenceGroup.redundancy =>
    'Redundancy (messy-span handoff — the key integration risk, observational)',
  _SentenceGroup.crossLanguage => 'Cross-language tiebreak (observational)',
};

/// A hard pass/fail expectation for one known error/vocab target within a
/// sentence, scored ONLY across runs where Stage 1 actually flagged
/// something overlapping [targetSubstring] — a run where Stage 1 missed it
/// entirely is a Stage 1 detection-rate question (already measured by
/// test/stage1_detection_dialect_harness.dart), not something this
/// harness re-litigates.
class _HardExpectation {
  const _HardExpectation({
    required this.targetSubstring,
    required this.acceptedVerdicts,
  });

  final String targetSubstring;
  final Set<String> acceptedVerdicts;
}

/// One battery sentence. Text copied by value, verbatim, from
/// test/stage1_detection_harness.dart / test/stage2_categorization_harness.dart
/// so results are directly comparable to both. Empty [hardExpectations]
/// marks a fully observational sentence.
class _Sentence {
  const _Sentence({
    required this.id,
    required this.group,
    required this.text,
    this.hardExpectations = const [],
    required this.note,
    required this.runCount,
  });

  final String id;
  final _SentenceGroup group;
  final String text;
  final List<_HardExpectation> hardExpectations;
  final String note;

  /// Tiered by how stable this phrase already proved in the isolated
  /// Stage 1/Stage 2 harness runs — see tierARuns/tierBRuns/tierCRuns above.
  final int runCount;
}

const List<_Sentence> _sentences = [
  // ── Genuine errors (swap-type) ──────────────────────────────────────────
  _Sentence(
    id: 'ES-1',
    group: _SentenceGroup.genuineErrors,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    hardExpectations: [
      _HardExpectation(targetSubstring: 'para casa', acceptedVerdicts: {'error'}),
    ],
    note:
        'Also the occurrence-sanity sentence: when Stage 1 flags "volví '
        'para casa" or a bare "para", the run detail below shows exactly '
        'what occurrence Stage 2 returns — recorded, not scored, since the '
        'flagged span (and therefore which "para" Stage 2 is disambiguating '
        'against) is whatever Stage 1 actually produced this run, not a '
        'fixed input.',
    runCount: tierARuns,
  ),
  _Sentence(
    id: 'ES-3',
    group: _SentenceGroup.genuineErrors,
    text:
        'Ayer había mucho trafico y mis amigos llamaron para atrás para '
        'confirmar la cena.',
    hardExpectations: [
      _HardExpectation(targetSubstring: 'trafico', acceptedVerdicts: {'error'}),
      _HardExpectation(
        targetSubstring: 'llamaron para atrás',
        acceptedVerdicts: {'error'},
      ),
    ],
    note: 'Two independent genuine-error targets in one sentence.',
    runCount: tierARuns,
  ),
  _Sentence(
    id: 'ES-4',
    group: _SentenceGroup.genuineErrors,
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche.',
    hardExpectations: [
      _HardExpectation(
        targetSubstring: 'Puedo tener una cerveza',
        acceptedVerdicts: {'error'},
      ),
      _HardExpectation(
        targetSubstring: 'pasar un buen tiempo',
        acceptedVerdicts: {'error'},
      ),
    ],
    note:
        'Two calque targets. Live Stage 1 may flag either, both, or '
        'neither in a given run — each is scored independently.',
    runCount: tierARuns,
  ),
  _Sentence(
    id: 'ES-5',
    group: _SentenceGroup.genuineErrors,
    text:
        'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
    hardExpectations: [
      _HardExpectation(targetSubstring: 'Espana', acceptedVerdicts: {'error'}),
      _HardExpectation(targetSubstring: 'anos', acceptedVerdicts: {'error'}),
      _HardExpectation(targetSubstring: 'cumpleanos', acceptedVerdicts: {'error'}),
      _HardExpectation(targetSubstring: 'otono', acceptedVerdicts: {'error'}),
    ],
    note: 'Four independent missing-accent targets.',
    runCount: tierARuns,
  ),

  // ── Dialectal / borderline (observational) ──────────────────────────────
  _Sentence(
    id: 'ES-2',
    group: _SentenceGroup.dialectalBorderline,
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
    note:
        '"voy para casa" is standard in much of Latin America. No hard '
        'expectation — record whether/how Stage 1 flags it and what Stage '
        '2 does with whatever span it gets.',
    runCount: tierBRuns,
  ),
  _Sentence(
    id: 'coger',
    group: _SentenceGroup.dialectalBorderline,
    text: 'Voy a coger el autobús para ir al centro.',
    note:
        'Standard in Spain, vulgar in much of Latin America — the '
        'canonical dialectal case. No hard expectation here (already '
        'scored with a fixed input in test/stage2_categorization_harness.dart\'s '
        '"coger" case); this is about whether the live chain reproduces '
        'that result.',
    runCount: tierBRuns,
  ),

  // ── Ordinary regional vocabulary — must not chain into error ────────────
  _Sentence(
    id: 'ordenador',
    group: _SentenceGroup.ordinaryVocab,
    text: 'Voy a usar el ordenador en la oficina.',
    hardExpectations: [
      _HardExpectation(
        targetSubstring: 'ordenador',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      ),
    ],
    note:
        'The case stage1DetectionDialectSpanish surfaced 2/10 in the '
        'dialect-variant harness. Confirms the full chain never routes it '
        'to error, not just Stage 2 in isolation.',
    runCount: tierBRuns,
  ),
  _Sentence(
    id: 'coche',
    group: _SentenceGroup.ordinaryVocab,
    text: 'Aparqué el coche cerca de la oficina.',
    hardExpectations: [
      _HardExpectation(
        targetSubstring: 'coche',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      ),
    ],
    note:
        'Kept clean by Stage 1 in prior harness runs — if the live dialect '
        'variant ever does flag it here, confirms Stage 2 still doesn\'t '
        'call it an error.',
    runCount: tierBRuns,
  ),
  _Sentence(
    id: 'carro',
    group: _SentenceGroup.ordinaryVocab,
    text: 'Lavé el carro el fin de semana.',
    hardExpectations: [
      _HardExpectation(
        targetSubstring: 'carro',
        acceptedVerdicts: {'dialectal', 'not_an_error'},
      ),
    ],
    note: 'The other side of the coche/carro/auto split — same check.',
    runCount: tierBRuns,
  ),

  // ── Omissions (corrected_phrase diff-usability — observational) ─────────
  _Sentence(
    id: 'ST-O1',
    group: _SentenceGroup.omissions,
    text: 'Como estas hoy?',
    note:
        'Missing opening "¿". No hard expectation — Stage 1 quotes around '
        'the gap (or doesn\'t), and the run detail shows whether Stage 2\'s '
        'corrected_phrase reinstates the missing mark.',
    runCount: tierBRuns,
  ),
  _Sentence(
    id: 'ST-O2',
    group: _SentenceGroup.omissions,
    text: 'Creo está bien, pero no estoy seguro.',
    note:
        'Missing subordinating "que". Read the run detail for whether '
        'corrected_phrase comes back as "Creo que está bien" or similar — '
        'diff-usable — from whatever span Stage 1 actually flags live.',
    runCount: tierARuns,
  ),
  _Sentence(
    id: 'ST-O3',
    group: _SentenceGroup.omissions,
    text: 'Voy la playa este fin de semana.',
    note: 'Missing preposition "a" — same diff-usability read as ST-O2.',
    runCount: tierARuns,
  ),
  _Sentence(
    id: 'ST-O4',
    group: _SentenceGroup.omissions,
    text: 'Que bonito es este lugar!',
    note:
        'Missing opening "¡" (pure omission) bundled with a real accent '
        'swap ("Que" -> "Qué"). No hard expectation here — read both off '
        'the run detail.',
    runCount: tierBRuns,
  ),

  // ── Redundancy (messy-span handoff — the key integration risk) ──────────
  _Sentence(
    id: 'ES-6',
    group: _SentenceGroup.redundancy,
    text: 'Yo fui a casa, yo estudié, y yo hice la cena.',
    note:
        'THE key integration risk. Stage 1 has been observed flagging '
        'anything from a clean single "yo" to the entire clause, or a '
        'fragment like ", y". No hard expectation — the run detail records '
        'exactly what span Stage 1 hands off and exactly what Stage 2 does '
        'with it (sane correction, empty/garbage one, or a parse failure).',
    runCount: tierCRuns,
  ),
  _Sentence(
    id: 'ST-R2',
    group: _SentenceGroup.redundancy,
    text:
        'Nosotros vamos al cine, nosotros comemos palomitas y nosotros '
        'volvemos a casa.',
    note: 'Same class and same reason as ES-6 — second messy-span example.',
    runCount: tierCRuns,
  ),

  // ── Cross-language tiebreak (observational) ─────────────────────────────
  _Sentence(
    id: 'PT-2',
    group: _SentenceGroup.crossLanguage,
    text: 'Eu gosto de ir a praia nos fins de semana.',
    note:
        'Portuguese text through the Spanish-only prompts, deliberately — '
        'the docs/correction_consistency_harness.md PT-2 tiebreak case. No '
        'hard expectation; read the run detail for what the live chain '
        'actually does end to end.',
    runCount: tierBRuns,
  ),
];

// ── Shared helpers (Stage 1 side, copied by value from
// test/stage1_detection_harness.dart) ─────────────────────────────────────

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself.
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
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. Shared by both stages here — identical in the Stage 1 and Stage 2
/// harness files, so defined once rather than twice.
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
/// response body: `choices[0].message.content`, trimmed.
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

/// Parses a Stage 1 reply into the list of quoted phrases it flagged.
List<String> parseDetectionArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 1 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('Stage 1 reply array did not decode to a List.');
  }

  return decoded.map((element) {
    if (element is! String) {
      throw FormatException(
        'Stage 1 reply array contained a non-string element: $element',
      );
    }
    return element;
  }).toList();
}

// ── Shared helpers (Stage 2 side, copied by value from
// test/stage2_categorization_harness.dart) ────────────────────────────────

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

/// Builds the user-message content sent alongside `stage2CategorizationSpanish`:
/// the learner's full text plus a JSON array of the flagged phrases. This is
/// the handoff itself — Stage 1's raw output array is passed straight
/// through as [flaggedPhrases], unmodified.
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

/// Parses a Stage 2 reply into one [_CategorizationResult] per returned
/// object. Tolerates Markdown fences/commentary via bracket extraction, same
/// as the Stage 1 parser. Throws on any malformed object, including an
/// unrecognized `verdict`.
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

/// The first flagged phrase (in order) overlapping [target], or null if
/// none of Stage 1's flagged phrases this run touched it at all.
String? _firstFlaggedOverlapping(List<String> flaggedPhrases, String target) {
  for (final phrase in flaggedPhrases) {
    if (_normalizedOverlap(phrase, target)) {
      return phrase;
    }
  }
  return null;
}

// ── Chained run/aggregate model ────────────────────────────────────────

/// One run's outcome for one sentence, through the full live chain.
///
/// Exactly one of three shapes:
///   - `stage1Error != null`: the Stage 1 call itself failed. No Stage 2
///     call was attempted.
///   - `flaggedPhrases.isEmpty` (and both errors null): Stage 1 flagged
///     nothing — "clean", no Stage 2 call was made (matching the real
///     pipeline: nothing to categorize).
///   - otherwise: Stage 1 flagged something; `stage2Error` is set if the
///     Stage 2 call then failed, or `categorizations` holds Stage 2's
///     parsed results (possibly not covering every flagged phrase — that's
///     itself part of what this harness is checking for).
class _ChainedRunRecord {
  const _ChainedRunRecord({
    required this.sentenceId,
    required this.runIndex,
    this.flaggedPhrases = const [],
    this.categorizations = const [],
    this.stage1Error,
    this.stage2Error,
  });

  final String sentenceId;
  final int runIndex;
  final List<String> flaggedPhrases;
  final List<_CategorizationResult> categorizations;
  final Object? stage1Error;
  final Object? stage2Error;
}

/// Aggregated results for one hard-expectation target within a sentence,
/// across every run where Stage 1 actually flagged something overlapping
/// it (a run that never flagged it at all is excluded from every count
/// here — that's a Stage 1 detection-rate question, not this harness's).
class _HardExpectationAggregate {
  const _HardExpectationAggregate({
    required this.targetSubstring,
    required this.consideredRuns,
    required this.flaggedCount,
    required this.caughtCount,
    required this.verdictDistribution,
    required this.categoryDistribution,
    required this.correctedPhraseDistribution,
    required this.occurrenceDistribution,
  });

  final String targetSubstring;

  /// Total non-Stage-1-error runs for the sentence (the denominator for
  /// "how often did Stage 1 even flag this").
  final int consideredRuns;

  /// Runs where some flagged phrase overlapped [targetSubstring].
  final int flaggedCount;

  /// Among flagged runs, how many produced a matched Stage 2 result whose
  /// verdict landed in the expectation's accepted set. A Stage 2 error or a
  /// flagged-but-unmatched result both count against this, same as a wrong
  /// verdict would — the question is whether the FULL chain worked, not
  /// just Stage 2 in isolation.
  final int caughtCount;

  /// Tally of the matched result's verdict per flagged run, plus
  /// `(stage2 error)` / `(no matching stage2 result)` buckets so failures
  /// are visible in the same distribution rather than silently dropped.
  final Map<String, int> verdictDistribution;

  /// Tally over runs with a matched Stage 2 result only (error/no-match
  /// runs excluded, since there's no category to tally).
  final Map<String, int> categoryDistribution;
  final Map<String, int> correctedPhraseDistribution;
  final Map<String, int> occurrenceDistribution;
}

_HardExpectationAggregate _aggregateHardExpectation(
  _HardExpectation expectation,
  List<_ChainedRunRecord> nonStage1ErrorRuns,
) {
  var flaggedCount = 0;
  var caughtCount = 0;
  final verdictDist = <String, int>{};
  final categoryDist = <String, int>{};
  final correctedDist = <String, int>{};
  final occurrenceDist = <String, int>{};

  for (final run in nonStage1ErrorRuns) {
    final flaggedMatch = _firstFlaggedOverlapping(
      run.flaggedPhrases,
      expectation.targetSubstring,
    );
    if (flaggedMatch == null) {
      continue;
    }
    flaggedCount++;

    if (run.stage2Error != null) {
      verdictDist['(stage2 error)'] = (verdictDist['(stage2 error)'] ?? 0) + 1;
      continue;
    }

    final result = _matchResultFor(run.categorizations, flaggedMatch);
    if (result == null) {
      verdictDist['(no matching stage2 result)'] =
          (verdictDist['(no matching stage2 result)'] ?? 0) + 1;
      continue;
    }

    verdictDist[result.verdict] = (verdictDist[result.verdict] ?? 0) + 1;
    final categoryKey = result.category ?? '(none)';
    categoryDist[categoryKey] = (categoryDist[categoryKey] ?? 0) + 1;
    correctedDist[result.correctedPhrase] =
        (correctedDist[result.correctedPhrase] ?? 0) + 1;
    final occurrenceKey = '${result.occurrence}';
    occurrenceDist[occurrenceKey] = (occurrenceDist[occurrenceKey] ?? 0) + 1;

    if (expectation.acceptedVerdicts.contains(result.verdict)) {
      caughtCount++;
    }
  }

  return _HardExpectationAggregate(
    targetSubstring: expectation.targetSubstring,
    consideredRuns: nonStage1ErrorRuns.length,
    flaggedCount: flaggedCount,
    caughtCount: caughtCount,
    verdictDistribution: verdictDist,
    categoryDistribution: categoryDist,
    correctedPhraseDistribution: correctedDist,
    occurrenceDistribution: occurrenceDist,
  );
}

/// Tally of every flagged phrase string Stage 1 returned across
/// [nonStage1ErrorRuns], plus a `(clean)` bucket for runs that flagged
/// nothing — the single view that makes span messiness (ES-6/ST-R2's whole
/// point) visible at a glance.
Map<String, int> _flaggedSpanDistribution(List<_ChainedRunRecord> nonStage1ErrorRuns) {
  final dist = <String, int>{};
  for (final run in nonStage1ErrorRuns) {
    if (run.flaggedPhrases.isEmpty) {
      dist['(clean)'] = (dist['(clean)'] ?? 0) + 1;
    } else {
      for (final phrase in run.flaggedPhrases) {
        dist[phrase] = (dist[phrase] ?? 0) + 1;
      }
    }
  }
  return dist;
}

/// Aggregated results for one sentence across all its runs.
class _SentenceAggregate {
  const _SentenceAggregate({
    required this.sentenceId,
    required this.totalRuns,
    required this.stage1ErrorRuns,
    required this.stage2ErrorRuns,
    required this.consideredRuns,
    required this.flaggedRuns,
    required this.cleanRuns,
    required this.flaggedSpanDistribution,
    required this.hardExpectationAggregates,
  });

  final String sentenceId;
  final int totalRuns;
  final int stage1ErrorRuns;
  final int stage2ErrorRuns;
  final int consideredRuns;
  final int flaggedRuns;
  final int cleanRuns;
  final Map<String, int> flaggedSpanDistribution;
  final List<_HardExpectationAggregate> hardExpectationAggregates;
}

_SentenceAggregate _aggregateSentence(
  _Sentence sentence,
  List<_ChainedRunRecord> records,
) {
  final nonStage1ErrorRuns = records.where((r) => r.stage1Error == null).toList();
  final stage1ErrorRuns = records.length - nonStage1ErrorRuns.length;
  final stage2ErrorRuns = nonStage1ErrorRuns.where((r) => r.stage2Error != null).length;
  final flaggedRuns = nonStage1ErrorRuns.where((r) => r.flaggedPhrases.isNotEmpty).length;
  final cleanRuns = nonStage1ErrorRuns.where((r) => r.flaggedPhrases.isEmpty).length;

  return _SentenceAggregate(
    sentenceId: sentence.id,
    totalRuns: records.length,
    stage1ErrorRuns: stage1ErrorRuns,
    stage2ErrorRuns: stage2ErrorRuns,
    consideredRuns: nonStage1ErrorRuns.length,
    flaggedRuns: flaggedRuns,
    cleanRuns: cleanRuns,
    flaggedSpanDistribution: _flaggedSpanDistribution(nonStage1ErrorRuns),
    hardExpectationAggregates: sentence.hardExpectations
        .map((expectation) => _aggregateHardExpectation(expectation, nonStage1ErrorRuns))
        .toList(),
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
  return entries.map((e) => '"${e.key}": ${e.value}').join(', ');
}

String _describeRun(_ChainedRunRecord record) {
  final prefix = 'Run ${record.runIndex}';

  if (record.stage1Error != null) {
    return '- $prefix: STAGE1 ERROR — ${record.stage1Error}';
  }
  if (record.flaggedPhrases.isEmpty) {
    return '- $prefix: clean — no Stage 2 call';
  }
  if (record.stage2Error != null) {
    return '- $prefix: Stage 1 flagged ${jsonEncode(record.flaggedPhrases)} · '
        'STAGE2 ERROR — ${record.stage2Error}';
  }

  final parts = record.flaggedPhrases.map((phrase) {
    final result = _matchResultFor(record.categorizations, phrase);
    if (result == null) {
      return '"$phrase" -> (no matching Stage 2 result)';
    }
    return '"$phrase" -> verdict=${result.verdict}, '
        'category=${result.category ?? '(none)'}, '
        'occurrence=${result.occurrence}, '
        'corrected="${result.correctedPhrase}"';
  }).join(' | ');

  return '- $prefix: $parts';
}

/// Builds the full markdown report: a header block, then each sentence
/// group as its own section, one subsection per sentence (metadata, Stage 1
/// flag-rate summary, flagged-span distribution, hard-expectation summaries
/// where applicable), a run-by-run breakdown showing the full chain, then an
/// overall-summary table.
///
/// Run counts are tiered per sentence (see tierARuns/tierBRuns/tierCRuns),
/// not a flat count, so the header states each tier's sentences and run
/// count explicitly — a "N runs" figure elsewhere in the report is
/// meaningless without knowing which tier produced it — and the real
/// Stage 1/Stage 2 call totals actually made, derived from
/// [recordsBySentenceId] itself rather than assumed from the tier config,
/// so it reflects what actually happened (including any Stage 1 errors that
/// short-circuited a Stage 2 call).
///
/// Pure — takes already-collected [recordsBySentenceId] rather than making
/// any calls itself, golden-testable against synthetic data with no live
/// API involved, same approach as the other harnesses' `_buildReport`.
String _buildReport({
  required String stage1Model,
  required String stage2Model,
  required DateTime generatedAt,
  required List<_Sentence> sentences,
  required Map<String, List<_ChainedRunRecord>> recordsBySentenceId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Chained Stage 1 -> Stage 2 Harness')
    ..writeln()
    ..writeln(
      'Stage 1 model: `$stage1Model` (stage1DetectionDialectSpanish)  ',
    )
    ..writeln('Stage 2 model: `$stage2Model` (stage2CategorizationSpanish)  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report.writeln('Generated: ${generatedAt.toIso8601String()}  ');

  final idsByRunCount = <int, List<String>>{};
  for (final sentence in sentences) {
    idsByRunCount.putIfAbsent(sentence.runCount, () => []).add(sentence.id);
  }
  final runCounts = idsByRunCount.keys.toList()..sort();
  report.writeln('Run counts (tiered by phrase stability):  ');
  for (final count in runCounts) {
    report.writeln('- $count run(s): ${idsByRunCount[count]!.join(', ')}');
  }

  final callCounts = _countCalls(recordsBySentenceId);
  report
    ..writeln(
      'Actual live calls made: ${callCounts.stage1Calls} Stage 1 + '
      '${callCounts.stage2Calls} Stage 2 = '
      '${callCounts.stage1Calls + callCounts.stage2Calls} total  ',
    )
    ..writeln();

  final summaryRows = <String>[];

  for (final group in _SentenceGroup.values) {
    final groupSentences = sentences.where((s) => s.group == group).toList();
    if (groupSentences.isEmpty) {
      continue;
    }

    report
      ..writeln('## ${_groupHeading(group)}')
      ..writeln();

    for (final sentence in groupSentences) {
      final records = recordsBySentenceId[sentence.id] ?? const <_ChainedRunRecord>[];
      final aggregate = _aggregateSentence(sentence, records);

      report
        ..writeln('### ${sentence.id}')
        ..writeln()
        ..writeln('- Text: `${sentence.text}`')
        ..writeln('- Note: ${sentence.note}')
        ..writeln()
        ..writeln(
          '#### Summary (${aggregate.totalRuns} runs, '
          '${aggregate.stage1ErrorRuns} Stage 1 error(s), '
          '${aggregate.stage2ErrorRuns} Stage 2 error(s))',
        )
        ..writeln()
        ..writeln(
          '- Stage 1 flag rate: '
          '${_percentLabel(aggregate.flaggedRuns, aggregate.consideredRuns)} '
          '(clean: ${_percentLabel(aggregate.cleanRuns, aggregate.consideredRuns)})',
        )
        ..writeln(
          '- Flagged span distribution: '
          '${_describeDistribution(aggregate.flaggedSpanDistribution)}',
        );

      for (final hardAgg in aggregate.hardExpectationAggregates) {
        report
          ..writeln('- Hard expectation ("${hardAgg.targetSubstring}"):')
          ..writeln(
            '  - Flagged by Stage 1: '
            '${_percentLabel(hardAgg.flaggedCount, hardAgg.consideredRuns)}',
          )
          ..writeln(
            '  - Verdict distribution (when flagged): '
            '${_describeDistribution(hardAgg.verdictDistribution)} '
            '-> caught ${_percentLabel(hardAgg.caughtCount, hardAgg.flaggedCount)}',
          )
          ..writeln(
            '  - Category distribution: '
            '${_describeDistribution(hardAgg.categoryDistribution)}',
          )
          ..writeln(
            '  - Corrected-phrase distribution: '
            '${_describeDistribution(hardAgg.correctedPhraseDistribution)}',
          )
          ..writeln(
            '  - Occurrence distribution: '
            '${_describeDistribution(hardAgg.occurrenceDistribution)}',
          );
      }

      report
        ..writeln()
        ..writeln('#### Run detail')
        ..writeln();

      for (final record in records) {
        report.writeln(_describeRun(record));
      }
      report.writeln();

      final headlineRate = aggregate.hardExpectationAggregates.isEmpty
          ? '—'
          : aggregate.hardExpectationAggregates
              .map(
                (a) => _percentLabel(a.caughtCount, a.flaggedCount),
              )
              .join(', ');
      summaryRows.add(
        '| ${sentence.id} | ${aggregate.totalRuns} | '
        '${aggregate.stage1ErrorRuns} | ${aggregate.stage2ErrorRuns} | '
        '${_percentLabel(aggregate.flaggedRuns, aggregate.consideredRuns)} | '
        '$headlineRate |',
      );
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln(
      '| Sentence | Runs | Stage1 errors | Stage2 errors | Stage 1 flag rate '
      '| Hard-expectation caught rate(s) |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- |');
  for (final row in summaryRows) {
    report.writeln(row);
  }

  return report.toString();
}

/// Counts the real Stage 1/Stage 2 calls represented by [recordsBySentenceId]:
/// one Stage 1 call per run record (even one that errored — the call was
/// still attempted), and one Stage 2 call per run where Stage 1 succeeded
/// and flagged something (again, even if that Stage 2 call then errored).
({int stage1Calls, int stage2Calls}) _countCalls(
  Map<String, List<_ChainedRunRecord>> recordsBySentenceId,
) {
  var stage1Calls = 0;
  var stage2Calls = 0;
  for (final records in recordsBySentenceId.values) {
    for (final record in records) {
      stage1Calls++;
      if (record.stage1Error == null && record.flaggedPhrases.isNotEmpty) {
        stage2Calls++;
      }
    }
  }
  return (stage1Calls: stage1Calls, stage2Calls: stage2Calls);
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

Future<List<String>> _callStage1Detection({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required String userText,
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
          systemPrompt: stage1DetectionDialectSpanish,
          userText: userText,
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Stage 1 chat completions call failed with HTTP '
      '${response.statusCode}: $body',
    );
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'Stage 1 chat completions response root is not an object.',
    );
  }

  return parseDetectionArray(extractReplyText(decoded));
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
      'Stage 2 chat completions call failed with HTTP '
      '${response.statusCode}: $body',
    );
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'Stage 2 chat completions response root is not an object.',
    );
  }

  return _parseCategorizationArray(extractReplyText(decoded));
}

/// Runs the full live chain once for [sentence]: Stage 1, then (if
/// anything was flagged) Stage 2 with Stage 1's actual output. Never
/// throws — every failure mode is captured in the returned
/// [_ChainedRunRecord] so one bad run doesn't lose the whole battery, same
/// discipline as every other harness in this repo.
Future<_ChainedRunRecord> _runChainedOnce({
  required HttpClient httpClient,
  required String apiKey,
  required String stage1Model,
  required String stage2Model,
  required _Sentence sentence,
  required int runIndex,
}) async {
  List<String> flaggedPhrases;
  try {
    flaggedPhrases = await _callStage1Detection(
      httpClient: httpClient,
      apiKey: apiKey,
      model: stage1Model,
      userText: sentence.text,
    );
  } catch (error) {
    return _ChainedRunRecord(
      sentenceId: sentence.id,
      runIndex: runIndex,
      stage1Error: error,
    );
  }

  await Future<void>.delayed(const Duration(milliseconds: callDelayMs));

  if (flaggedPhrases.isEmpty) {
    return _ChainedRunRecord(
      sentenceId: sentence.id,
      runIndex: runIndex,
      flaggedPhrases: const [],
    );
  }

  try {
    final categorizations = await _callStage2Categorization(
      httpClient: httpClient,
      apiKey: apiKey,
      model: stage2Model,
      fullText: sentence.text,
      flaggedPhrases: flaggedPhrases,
    );
    return _ChainedRunRecord(
      sentenceId: sentence.id,
      runIndex: runIndex,
      flaggedPhrases: flaggedPhrases,
      categorizations: categorizations,
    );
  } catch (error) {
    return _ChainedRunRecord(
      sentenceId: sentence.id,
      runIndex: runIndex,
      flaggedPhrases: flaggedPhrases,
      stage2Error: error,
    );
  } finally {
    await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
  }
}

void main() {
  test('chained harness sentence fixtures are well-formed', () {
    expect(
      _sentences.length,
      16,
      reason:
          '4 genuine-errors + 2 dialectal-borderline + 3 ordinary-vocab + '
          '4 omissions + 2 redundancy + 1 cross-language.',
    );

    final ids = _sentences.map((s) => s.id).toSet();
    expect(ids.length, _sentences.length, reason: 'Sentence ids must be unique.');

    for (final sentence in _sentences) {
      expect(sentence.text.trim(), isNotEmpty, reason: sentence.id);
      for (final expectation in sentence.hardExpectations) {
        expect(
          sentence.text.contains(expectation.targetSubstring),
          isTrue,
          reason:
              '${sentence.id}: hard-expectation target '
              '"${expectation.targetSubstring}" not found in sentence text.',
        );
        expect(
          expectation.acceptedVerdicts.isNotEmpty,
          isTrue,
          reason: sentence.id,
        );
        expect(
          expectation.acceptedVerdicts.difference(_validVerdicts),
          isEmpty,
          reason: '${sentence.id}: unknown verdict in acceptedVerdicts.',
        );
      }
    }

    final idsByGroup = {
      for (final group in _SentenceGroup.values)
        group: _sentences.where((s) => s.group == group).map((s) => s.id).toList(),
    };
    expect(idsByGroup[_SentenceGroup.genuineErrors], ['ES-1', 'ES-3', 'ES-4', 'ES-5']);
    expect(idsByGroup[_SentenceGroup.dialectalBorderline], ['ES-2', 'coger']);
    expect(
      idsByGroup[_SentenceGroup.ordinaryVocab],
      ['ordenador', 'coche', 'carro'],
    );
    expect(
      idsByGroup[_SentenceGroup.omissions],
      ['ST-O1', 'ST-O2', 'ST-O3', 'ST-O4'],
    );
    expect(idsByGroup[_SentenceGroup.redundancy], ['ES-6', 'ST-R2']);
    expect(idsByGroup[_SentenceGroup.crossLanguage], ['PT-2']);

    // Genuine-errors and ordinary-vocab sentences carry hard expectations;
    // every other group is fully observational (empty hardExpectations).
    for (final sentence in _sentences) {
      final expectHard = sentence.group == _SentenceGroup.genuineErrors ||
          sentence.group == _SentenceGroup.ordinaryVocab;
      expect(
        sentence.hardExpectations.isNotEmpty,
        expectHard,
        reason: sentence.id,
      );
    }

    // Ordinary-vocab hard expectations must never accept 'error'.
    for (final sentence in _sentences.where((s) => s.group == _SentenceGroup.ordinaryVocab)) {
      expect(
        sentence.hardExpectations.single.acceptedVerdicts,
        {'dialectal', 'not_an_error'},
        reason: sentence.id,
      );
    }

    // Text copied verbatim from the Stage 1 / Stage 2 harnesses — guard
    // against retyping drift.
    final textsById = {for (final s in _sentences) s.id: s.text};
    expect(
      textsById['ES-1'],
      'Ayer fui al supermercado para comprar pan y después volví para casa '
      'para preparar la cena.',
    );
    expect(
      textsById['ES-6'],
      'Yo fui a casa, yo estudié, y yo hice la cena.',
    );
    expect(
      textsById['ST-R2'],
      'Nosotros vamos al cine, nosotros comemos palomitas y nosotros '
      'volvemos a casa.',
    );
    expect(
      textsById['PT-2'],
      'Eu gosto de ir a praia nos fins de semana.',
    );

    // Tier assignment matches the specified tiering exactly.
    final tierAIds = _sentences.where((s) => s.runCount == tierARuns).map((s) => s.id).toList();
    final tierBIds = _sentences.where((s) => s.runCount == tierBRuns).map((s) => s.id).toList();
    final tierCIds = _sentences.where((s) => s.runCount == tierCRuns).map((s) => s.id).toList();
    expect(tierAIds, ['ES-1', 'ES-3', 'ES-4', 'ES-5', 'ST-O2', 'ST-O3']);
    expect(
      tierBIds,
      ['ES-2', 'coger', 'ordenador', 'coche', 'carro', 'ST-O1', 'ST-O4', 'PT-2'],
    );
    expect(tierCIds, ['ES-6', 'ST-R2']);
    expect(tierAIds.length + tierBIds.length + tierCIds.length, _sentences.length);

    final totalChainedCalls =
        tierAIds.length * tierARuns + tierBIds.length * tierBRuns + tierCIds.length * tierCRuns;
    expect(
      totalChainedCalls,
      50,
      reason: '6x1 + 8x3 + 2x10 = 50 chained calls at the default tier run counts.',
    );
  });

  group('parseDetectionArray', () {
    test('parses a populated array', () {
      expect(parseDetectionArray('["para casa"]'), ['para casa']);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      expect(parseDetectionArray('```json\n["ordenador"]\n```'), ['ordenador']);
    });

    test('throws when no array is present', () {
      expect(() => parseDetectionArray('nothing here'), throwsFormatException);
    });
  });

  group('_parseCategorizationArray', () {
    test('parses a populated array', () {
      final results = _parseCategorizationArray(
        '[{"original_phrase": "ordenador", "corrected_phrase": "ordenador", '
        '"occurrence": 1, "category": null, "verdict": "not_an_error"}]',
      );
      expect(results.single.verdict, 'not_an_error');
      expect(results.single.category, isNull);
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

  group('_matchResultFor / _firstFlaggedOverlapping', () {
    test('_matchResultFor matches by normalized overlap', () {
      final results = [
        const _CategorizationResult(
          originalPhrase: 'PARA CASA',
          correctedPhrase: 'a casa',
          occurrence: 1,
          category: 'Grammar',
          verdict: 'error',
        ),
      ];
      final match = _matchResultFor(results, 'para casa');
      expect(match, isNotNull);
      expect(match!.correctedPhrase, 'a casa');
    });

    test('_firstFlaggedOverlapping finds the first overlapping phrase', () {
      final match = _firstFlaggedOverlapping(
        ['trafico', 'llamaron para atrás'],
        'llamaron para atrás',
      );
      expect(match, 'llamaron para atrás');
    });

    test('_firstFlaggedOverlapping returns null when nothing overlaps', () {
      expect(_firstFlaggedOverlapping(['otono'], 'trafico'), isNull);
    });
  });

  group('_aggregateHardExpectation', () {
    const expectation = _HardExpectation(
      targetSubstring: 'ordenador',
      acceptedVerdicts: {'dialectal', 'not_an_error'},
    );

    test('runs where the target was never flagged are excluded entirely', () {
      final records = [
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 1,
          flaggedPhrases: [],
        ),
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 2,
          flaggedPhrases: ['ordenador'],
          categorizations: [
            _CategorizationResult(
              originalPhrase: 'ordenador',
              correctedPhrase: 'ordenador',
              occurrence: 1,
              category: null,
              verdict: 'not_an_error',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateHardExpectation(expectation, records);

      expect(aggregate.consideredRuns, 2);
      expect(aggregate.flaggedCount, 1);
      expect(aggregate.caughtCount, 1);
      expect(aggregate.verdictDistribution, {'not_an_error': 1});
    });

    test('a Stage 2 error on a flagged run counts against caught, tallied separately', () {
      final records = [
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 1,
          flaggedPhrases: ['ordenador'],
          stage2Error: 'boom',
        ),
      ];

      final aggregate = _aggregateHardExpectation(expectation, records);

      expect(aggregate.flaggedCount, 1);
      expect(aggregate.caughtCount, 0);
      expect(aggregate.verdictDistribution, {'(stage2 error)': 1});
    });

    test('a flagged run with no matching Stage 2 result is tallied, not silently dropped', () {
      final records = [
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 1,
          flaggedPhrases: ['ordenador'],
          categorizations: [
            _CategorizationResult(
              originalPhrase: 'unrelated phrase',
              correctedPhrase: 'x',
              occurrence: 1,
              category: 'Other',
              verdict: 'error',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateHardExpectation(expectation, records);

      expect(aggregate.flaggedCount, 1);
      expect(aggregate.caughtCount, 0);
      expect(aggregate.verdictDistribution, {'(no matching stage2 result)': 1});
    });

    test('a caught verdict of error is excluded from acceptedVerdicts and not counted', () {
      final records = [
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 1,
          flaggedPhrases: ['ordenador'],
          categorizations: [
            _CategorizationResult(
              originalPhrase: 'ordenador',
              correctedPhrase: 'computadora',
              occurrence: 1,
              category: 'Word Choice',
              verdict: 'error',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateHardExpectation(expectation, records);

      expect(aggregate.flaggedCount, 1);
      expect(aggregate.caughtCount, 0);
      expect(aggregate.verdictDistribution, {'error': 1});
    });
  });

  group('_flaggedSpanDistribution', () {
    test('tallies clean runs and every flagged phrase across runs', () {
      final records = [
        const _ChainedRunRecord(sentenceId: 'ES-6', runIndex: 1, flaggedPhrases: []),
        const _ChainedRunRecord(
          sentenceId: 'ES-6',
          runIndex: 2,
          flaggedPhrases: ['yo estudié'],
        ),
        const _ChainedRunRecord(
          sentenceId: 'ES-6',
          runIndex: 3,
          flaggedPhrases: ['Yo fui a casa, yo estudié, y yo hice la cena.'],
        ),
      ];

      final dist = _flaggedSpanDistribution(records);

      expect(dist['(clean)'], 1);
      expect(dist['yo estudié'], 1);
      expect(dist['Yo fui a casa, yo estudié, y yo hice la cena.'], 1);
    });
  });

  group('_aggregateSentence', () {
    test('stage1 error runs are excluded from consideredRuns entirely', () {
      final sentence = _sentences.firstWhere((s) => s.id == 'ordenador');
      final records = [
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 1,
          stage1Error: 'timed out',
        ),
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 2,
          flaggedPhrases: [],
        ),
        const _ChainedRunRecord(
          sentenceId: 'ordenador',
          runIndex: 3,
          flaggedPhrases: ['ordenador'],
          categorizations: [
            _CategorizationResult(
              originalPhrase: 'ordenador',
              correctedPhrase: 'ordenador',
              occurrence: 1,
              category: null,
              verdict: 'dialectal',
            ),
          ],
        ),
      ];

      final aggregate = _aggregateSentence(sentence, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.stage1ErrorRuns, 1);
      expect(aggregate.consideredRuns, 2);
      expect(aggregate.cleanRuns, 1);
      expect(aggregate.flaggedRuns, 1);
      expect(aggregate.hardExpectationAggregates.single.caughtCount, 1);
    });

    test('a sentence with no hardExpectations produces an empty aggregate list', () {
      final sentence = _sentences.firstWhere((s) => s.id == 'ES-6');
      final aggregate = _aggregateSentence(sentence, const []);
      expect(aggregate.hardExpectationAggregates, isEmpty);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, grouped sections, flag-rate + span distribution + hard-expectation '
    'summary, run detail, overall table)',
    () {
      const sentence1 = _Sentence(
        id: 'TEST-1-genuine',
        group: _SentenceGroup.genuineErrors,
        text: 'Ejemplo con un error de prueba.',
        hardExpectations: [
          _HardExpectation(
            targetSubstring: 'error de prueba',
            acceptedVerdicts: {'error'},
          ),
        ],
        note: 'Synthetic genuine-error sentence for report golden test.',
        runCount: 1,
      );
      const sentence2 = _Sentence(
        id: 'TEST-2-redundancy',
        group: _SentenceGroup.redundancy,
        text: 'Yo yo yo repito la palabra.',
        note: 'Synthetic observational redundancy sentence for report golden test.',
        runCount: 10,
      );

      final report = _buildReport(
        stage1Model: 'test-stage1-model',
        stage2Model: 'test-stage2-model',
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        sentences: const [sentence1, sentence2],
        recordsBySentenceId: {
          'TEST-1-genuine': [
            const _ChainedRunRecord(
              sentenceId: 'TEST-1-genuine',
              runIndex: 1,
              flaggedPhrases: ['error de prueba'],
              categorizations: [
                _CategorizationResult(
                  originalPhrase: 'error de prueba',
                  correctedPhrase: 'error corregido',
                  occurrence: 1,
                  category: 'Other',
                  verdict: 'error',
                ),
              ],
            ),
            const _ChainedRunRecord(
              sentenceId: 'TEST-1-genuine',
              runIndex: 2,
              stage1Error: 'Stage 1 call timed out',
            ),
          ],
          'TEST-2-redundancy': [
            const _ChainedRunRecord(
              sentenceId: 'TEST-2-redundancy',
              runIndex: 1,
              flaggedPhrases: [],
            ),
            const _ChainedRunRecord(
              sentenceId: 'TEST-2-redundancy',
              runIndex: 2,
              flaggedPhrases: ['Yo yo yo'],
              stage2Error: 'Stage 2 call timed out',
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'chained Stage 1 -> Stage 2 harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the chained harness. This script does '
          'NOT fall back to any hardcoded/default key — no AppConfig '
          'involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final recordsBySentenceId = <String, List<_ChainedRunRecord>>{};

      try {
        for (final sentence in _sentences) {
          final records = <_ChainedRunRecord>[];
          // ignore: avoid_print
          print('=== ${sentence.id} ===');

          for (var run = 1; run <= sentence.runCount; run++) {
            final record = await _runChainedOnce(
              httpClient: httpClient,
              apiKey: apiKey,
              stage1Model: chainedStage1Model,
              stage2Model: chainedStage2Model,
              sentence: sentence,
              runIndex: run,
            );
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(record));
          }

          recordsBySentenceId[sentence.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        stage1Model: chainedStage1Model,
        stage2Model: chainedStage2Model,
        generatedAt: DateTime.now(),
        sentences: _sentences,
        recordsBySentenceId: recordsBySentenceId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      final callCounts = _countCalls(recordsBySentenceId);
      // ignore: avoid_print
      print(
        'Actual live calls made: ${callCounts.stage1Calls} Stage 1 + '
        '${callCounts.stage2Calls} Stage 2 = '
        '${callCounts.stage1Calls + callCounts.stage2Calls} total',
      );
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 90)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Chained Stage 1 -> Stage 2 Harness\n\nStage 1 model: `test-stage1-model` (stage1DetectionDialectSpanish)  \nStage 2 model: `test-stage2-model` (stage2CategorizationSpanish)  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRun counts (tiered by phrase stability):  \n- 1 run(s): TEST-1-genuine\n- 10 run(s): TEST-2-redundancy\nActual live calls made: 4 Stage 1 + 2 Stage 2 = 6 total  \n\n## Genuine errors (swap-type) — Stage 2 verdict must be error when Stage 1 flags the target\n\n### TEST-1-genuine\n\n- Text: `Ejemplo con un error de prueba.`\n- Note: Synthetic genuine-error sentence for report golden test.\n\n#### Summary (2 runs, 1 Stage 1 error(s), 0 Stage 2 error(s))\n\n- Stage 1 flag rate: 100.0% (1/1) (clean: 0.0% (0/1))\n- Flagged span distribution: \"error de prueba\": 1\n- Hard expectation (\"error de prueba\"):\n  - Flagged by Stage 1: 100.0% (1/1)\n  - Verdict distribution (when flagged): \"error\": 1 -> caught 100.0% (1/1)\n  - Category distribution: \"Other\": 1\n  - Corrected-phrase distribution: \"error corregido\": 1\n  - Occurrence distribution: \"1\": 1\n\n#### Run detail\n\n- Run 1: \"error de prueba\" -> verdict=error, category=Other, occurrence=1, corrected=\"error corregido\"\n- Run 2: STAGE1 ERROR — Stage 1 call timed out\n\n## Redundancy (messy-span handoff — the key integration risk, observational)\n\n### TEST-2-redundancy\n\n- Text: `Yo yo yo repito la palabra.`\n- Note: Synthetic observational redundancy sentence for report golden test.\n\n#### Summary (2 runs, 0 Stage 1 error(s), 1 Stage 2 error(s))\n\n- Stage 1 flag rate: 50.0% (1/2) (clean: 50.0% (1/2))\n- Flagged span distribution: \"(clean)\": 1, \"Yo yo yo\": 1\n\n#### Run detail\n\n- Run 1: clean — no Stage 2 call\n- Run 2: Stage 1 flagged [\"Yo yo yo\"] · STAGE2 ERROR — Stage 2 call timed out\n\n---\n\n## Overall summary\n\n| Sentence | Runs | Stage1 errors | Stage2 errors | Stage 1 flag rate | Hard-expectation caught rate(s) |\n| --- | --- | --- | --- | --- | --- |\n| TEST-1-genuine | 2 | 1 | 0 | 100.0% (1/1) | 100.0% (1/1) |\n| TEST-2-redundancy | 2 | 0 | 1 | 50.0% (1/2) | — |\n"';
