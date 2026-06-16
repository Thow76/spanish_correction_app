// Walkthrough prompt validation harness.
//
// This file is a manual validation harness (not an automated `flutter test`
// suite — it makes live API calls). It exercises the Spanish and Portuguese
// walkthrough question prompts in PromptBuilder against a hand-authored battery
// of test cases, then writes a reviewable markdown report to
// docs/walkthrough_prompt_validation.md.
//
// Run it like the provider-comparison tool:
//   flutter test test/walkthrough_prompt_validation.dart --timeout none
// It uses the same configuration source as the app (AppConfig.fromEnvironment
// with Platform.environment overrides for OPENAI_API_KEY / the model), so it
// runs out of the box against OpenAI.
//
// Output path and divergence mode are controlled with --dart-define (flutter
// test does not pass argv to the test main):
//   WALKTHROUGH_OUTPUT             output report path (default: the run 1 path)
//   WALKTHROUGH_DIVERGENCE_AGAINST when set, after writing the current run,
//                                  read that earlier run report and write a
//                                  divergence report comparing the two
//   WALKTHROUGH_DIVERGENCE_OUT     divergence report path
//
// Run 2 + divergence in a single execution (run 1 file is read, never touched):
//   flutter test test/walkthrough_prompt_validation.dart --timeout none \
//     --dart-define=WALKTHROUGH_OUTPUT=docs/walkthrough_prompt_validation_run2.md \
//     --dart-define=WALKTHROUGH_DIVERGENCE_AGAINST=docs/walkthrough_prompt_validation.md
//
// PROMPT 3.3 SCOPE: re-run the identical battery a second time and produce a
// divergence report measuring stability of chunk decomposition and grounding
// across the two runs. The battery, prompts, and per-run logging structure are
// unchanged from 3.2. Remaining prompt:
//   3.4 — judge prompt readiness against the stability threshold.
//
// ── Tracks ──────────────────────────────────────────────────────────────────
//
// Each language (Spanish, Portuguese) gets the same battery shape. A test case
// belongs to exactly one track, recorded in TestCase.track.
//
// Track A — Grounding (4 per language):
//   The user's attempt contains specific wrong forms that the prompt should
//   surface as distractors (the "ground distractors in the attempt" rule).
//   Pass criterion: the user's actual wrong form appears in the distractors for
//   the relevant chunk. Encoded per-chunk in TestCase.groundingExpectations.
//
// Track B — Fallback (4 per language):
//   The user's attempt is too far from the target to align — empty, near-empty,
//   off-topic, or radically wrong. There is nothing to ground against.
//   Pass criterion: the prompt falls back to generic error-pattern distractors
//   without forcing a grounded distractor that the attempt does not support.
//
// Edge (1 per language):
//   Short sentences that probe the two-chunk exception in the decomposition
//   rules. Pass criterion: the prompt produces 2 chunks rather than a forced
//   3-chunk split that would break a verb phrase, preposition + object,
//   article + noun, or contraction. The attempt also carries a small error so
//   the edge case tests grounding on top of the chunk-count exception.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/prompt_builder.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

/// Which validation track a [TestCase] belongs to. See the track documentation
/// in the file header for the pass criterion of each.
enum WalkthroughTrack { grounding, fallback, edge }

/// A single walkthrough-prompt validation scenario.
///
/// The four inputs ([targetSentence], [userAttempt], [englishSource],
/// [corrections]) mirror the four inputs the walkthrough question prompt
/// receives. The remaining fields are review metadata: what the test author
/// expects the model to produce, used only when scoring the report after a run.
class TestCase {
  const TestCase({
    required this.id,
    required this.track,
    required this.language,
    required this.targetSentence,
    required this.userAttempt,
    required this.englishSource,
    required this.corrections,
    this.expectedChunks = const [],
    this.groundingExpectations = const {},
  });

  /// Stable identifier, e.g. "ES-G-01" (Spanish-Grounding-01),
  /// "PT-F-03" (Portuguese-Fallback-03), "ES-E-01" (Spanish-Edge-01).
  final String id;

  /// Which track this case validates, and therefore which pass criterion
  /// applies.
  final WalkthroughTrack track;

  /// Target language for the walkthrough — selects which prompt template runs.
  final Language language;

  /// The correct sentence to decompose; the ground truth and source of every
  /// correct answer.
  final String targetSentence;

  /// The learner's own translation attempt.
  final String userAttempt;

  /// The English phrase the learner was asked to translate.
  final String englishSource;

  /// The assessment corrections for the attempt, supplied to the prompt as the
  /// `corrections` input.
  final List<CorrectionItem> corrections;

  /// The chunks the test author expects the model to produce. Used for
  /// post-run review only; never fed to the prompt.
  final List<String> expectedChunks;

  /// Per-chunk-position grounding expectations, keyed by chunk_position.
  ///
  /// The value is the wrong form that SHOULD appear in the distractors for that
  /// chunk if grounding works, or null if no grounding is expected for that
  /// chunk. Only populated for grounding-track (and edge) cases; left empty for
  /// fallback cases, where the test author asserts no grounding is expected.
  final Map<int, String?> groundingExpectations;
}

/// Minimal stand-in for the generated walkthrough question shape.
///
/// TODO(section-4): replace this local minimal type with the real
/// WalkthroughQuestion model once Section 4 introduces it. Until then the
/// harness decodes the four fields by hand so it does not depend on a model
/// that does not exist yet.
class WalkthroughQuestion {
  const WalkthroughQuestion({
    required this.englishStem,
    required this.correctTranslation,
    required this.distractors,
    required this.chunkPosition,
  });

  final String englishStem;
  final String correctTranslation;
  final List<String> distractors;
  final int chunkPosition;

  Map<String, Object?> toJson() => {
    'english_stem': englishStem,
    'correct_translation': correctTranslation,
    'distractors': distractors,
    'chunk_position': chunkPosition,
  };
}

/// Outcome of decoding a single walkthrough API response.
///
/// Parse failures and shape violations are captured in [findings] (and
/// [parseError] for a hard failure) rather than thrown — a malformed or
/// out-of-contract response is itself a validation finding worth recording.
class ParsedResponse {
  ParsedResponse({
    required this.rawResponse,
    this.targetSentenceEcho,
    this.questions = const [],
    this.findings = const [],
    this.parseError,
  });

  final String rawResponse;
  final String? targetSentenceEcho;
  final List<WalkthroughQuestion> questions;
  final List<String> findings;
  final String? parseError;

  bool get parseFailed => parseError != null;
}

// ── Test battery ──────────────────────────────────────────────────────────────
//
// 18 cases: 9 per language (4 grounding, 4 fallback, 1 edge). Grounding and edge
// cases carry corrections shaped exactly as the assessment API returns them
// (original_phrase = what the learner wrote, corrected_phrase = the target
// form), which is the data the prompt is meant to mine for grounded distractors.

final List<TestCase> testBattery = [
  // ── Spanish · Grounding ─────────────────────────────────────────────────────
  // Wrong preposition / contraction error in the attempt.
  TestCase(
    id: 'ES-G-01',
    track: WalkthroughTrack.grounding,
    language: Language.spanish,
    targetSentence: 'Voy al banco el viernes.',
    userAttempt: 'Voy a el banco en viernes.',
    englishSource: "I'm going to the bank on Friday.",
    expectedChunks: ['Voy', 'al banco', 'el viernes'],
    groundingExpectations: {0: null, 1: 'a el banco', 2: 'en viernes'},
    corrections: [
      CorrectionItem(
        originalPhrase: 'a el banco',
        correctedPhrase: 'al banco',
        category: ErrorCategory.grammar,
        shortExplanation: 'Spanish contracts "a" + "el" into "al".',
      ),
      CorrectionItem(
        originalPhrase: 'en viernes',
        correctedPhrase: 'el viernes',
        category: ErrorCategory.grammar,
        shortExplanation:
            'Days of the week take the article "el", not the preposition "en".',
      ),
    ],
  ),
  // Person / conjugation confusion in the attempt.
  TestCase(
    id: 'ES-G-02',
    track: WalkthroughTrack.grounding,
    language: Language.spanish,
    targetSentence: 'Quiero estudiar español este año.',
    userAttempt: 'Quieres estudiar español este año.',
    englishSource: 'I want to study Spanish this year.',
    expectedChunks: ['Quiero', 'estudiar español', 'este año'],
    groundingExpectations: {0: 'Quieres', 1: null, 2: null},
    corrections: [
      CorrectionItem(
        originalPhrase: 'Quieres',
        correctedPhrase: 'Quiero',
        category: ErrorCategory.grammar,
        shortExplanation:
            '"Quieres" is second person; for "I want" use the first person "quiero".',
      ),
    ],
  ),
  // Calque / anglicism in the attempt ("aplicar para" for "to apply for").
  TestCase(
    id: 'ES-G-03',
    track: WalkthroughTrack.grounding,
    language: Language.spanish,
    targetSentence: 'Quiero solicitar ese trabajo.',
    userAttempt: 'Quiero aplicar para ese trabajo.',
    englishSource: 'I want to apply for that job.',
    expectedChunks: ['Quiero', 'solicitar', 'ese trabajo'],
    groundingExpectations: {0: null, 1: 'aplicar', 2: null},
    corrections: [
      CorrectionItem(
        originalPhrase: 'aplicar para',
        correctedPhrase: 'solicitar',
        category: ErrorCategory.naturalLanguage,
        shortExplanation:
            '"Aplicar para" is an anglicism; Spanish uses "solicitar" to apply for a job.',
      ),
    ],
  ),
  // Natural-language / false-friend error in the attempt ("atender" for "to attend").
  TestCase(
    id: 'ES-G-04',
    track: WalkthroughTrack.grounding,
    language: Language.spanish,
    targetSentence: 'Quiero asistir a la clase mañana.',
    userAttempt: 'Quiero atender la clase mañana.',
    englishSource: 'I want to attend the class tomorrow.',
    expectedChunks: ['Quiero', 'asistir a la clase', 'mañana'],
    groundingExpectations: {0: null, 1: 'atender', 2: null},
    corrections: [
      CorrectionItem(
        originalPhrase: 'atender',
        correctedPhrase: 'asistir a',
        category: ErrorCategory.naturalLanguage,
        shortExplanation:
            '"Atender" is a false friend; to attend a class is "asistir a".',
      ),
    ],
  ),

  // ── Spanish · Fallback ──────────────────────────────────────────────────────
  // Empty string.
  TestCase(
    id: 'ES-F-01',
    track: WalkthroughTrack.fallback,
    language: Language.spanish,
    targetSentence: 'Cociné pasta para la cena.',
    userAttempt: '',
    englishSource: 'I cooked pasta for dinner.',
    expectedChunks: ['Cociné', 'pasta', 'para la cena'],
    corrections: [],
  ),
  // Near-empty: a couple of words unrelated to the target meaning.
  TestCase(
    id: 'ES-F-02',
    track: WalkthroughTrack.fallback,
    language: Language.spanish,
    targetSentence: 'Mañana voy a visitar a mi abuela.',
    userAttempt: 'No se.',
    englishSource: "Tomorrow I'm going to visit my grandmother.",
    expectedChunks: ['Mañana', 'voy a visitar', 'a mi abuela'],
    corrections: [
      CorrectionItem(
        originalPhrase: 'se',
        correctedPhrase: 'sé',
        category: ErrorCategory.spelling,
        shortExplanation: '"Sé" (I know) needs the written accent.',
      ),
    ],
  ),
  // Off-topic: a coherent sentence about a different idea entirely.
  TestCase(
    id: 'ES-F-03',
    track: WalkthroughTrack.fallback,
    language: Language.spanish,
    targetSentence: 'El tren llega a las ocho.',
    userAttempt: 'Me gusta mucho el café en la mañana.',
    englishSource: 'The train arrives at eight.',
    expectedChunks: ['El tren', 'llega', 'a las ocho'],
    corrections: [
      CorrectionItem(
        originalPhrase: 'en la mañana',
        correctedPhrase: 'por la mañana',
        category: ErrorCategory.naturalLanguage,
        shortExplanation: 'Spanish says "por la mañana" for in the morning.',
      ),
    ],
  ),
  // Radically wrong: relevant topic, but wrong verb/tense/noun so no chunk aligns.
  TestCase(
    id: 'ES-F-04',
    track: WalkthroughTrack.fallback,
    language: Language.spanish,
    targetSentence: 'Compré tres manzanas en el mercado.',
    userAttempt: 'Yo voy a vender muchas naranjas.',
    englishSource: 'I bought three apples at the market.',
    expectedChunks: ['Compré', 'tres manzanas', 'en el mercado'],
    corrections: [
      CorrectionItem(
        originalPhrase: 'voy a vender',
        correctedPhrase: 'Compré',
        category: ErrorCategory.grammar,
        shortExplanation:
            'The English is past tense "bought", so use the preterite "compré".',
      ),
      CorrectionItem(
        originalPhrase: 'muchas naranjas',
        correctedPhrase: 'tres manzanas',
        category: ErrorCategory.wordChoice,
        shortExplanation: 'The source says three apples, not many oranges.',
      ),
    ],
  ),

  // ── Spanish · Edge ──────────────────────────────────────────────────────────
  // Short sentence: two chunks only ("al" must not be split). Small grounded
  // contraction error on top.
  TestCase(
    id: 'ES-E-01',
    track: WalkthroughTrack.edge,
    language: Language.spanish,
    targetSentence: 'Voy al gimnasio.',
    userAttempt: 'Voy a el gimnasio.',
    englishSource: "I'm going to the gym.",
    expectedChunks: ['Voy', 'al gimnasio'],
    groundingExpectations: {0: null, 1: 'a el gimnasio'},
    corrections: [
      CorrectionItem(
        originalPhrase: 'a el gimnasio',
        correctedPhrase: 'al gimnasio',
        category: ErrorCategory.grammar,
        shortExplanation: 'Spanish contracts "a" + "el" into "al".',
      ),
    ],
  ),

  // ── Portuguese · Grounding ──────────────────────────────────────────────────
  // Wrong preposition / contraction error in the attempt.
  TestCase(
    id: 'PT-G-01',
    track: WalkthroughTrack.grounding,
    language: Language.portuguese,
    targetSentence: 'Vou ao banco na sexta.',
    userAttempt: 'Vou a o banco em sexta.',
    englishSource: "I'm going to the bank on Friday.",
    expectedChunks: ['Vou', 'ao banco', 'na sexta'],
    groundingExpectations: {0: null, 1: 'a o banco', 2: 'em sexta'},
    corrections: [
      CorrectionItem(
        originalPhrase: 'a o banco',
        correctedPhrase: 'ao banco',
        category: ErrorCategory.grammar,
        shortExplanation: 'Portuguese contracts "a" + "o" into "ao".',
      ),
      CorrectionItem(
        originalPhrase: 'em sexta',
        correctedPhrase: 'na sexta',
        category: ErrorCategory.grammar,
        shortExplanation:
            'Use the contraction "na" (em + a) with days of the week.',
      ),
    ],
  ),
  // Person / conjugation confusion in the attempt.
  TestCase(
    id: 'PT-G-02',
    track: WalkthroughTrack.grounding,
    language: Language.portuguese,
    targetSentence: 'Quero estudar português este ano.',
    userAttempt: 'Quer estudar português este ano.',
    englishSource: 'I want to study Portuguese this year.',
    expectedChunks: ['Quero', 'estudar português', 'este ano'],
    groundingExpectations: {0: 'Quer', 1: null, 2: null},
    corrections: [
      CorrectionItem(
        originalPhrase: 'Quer',
        correctedPhrase: 'Quero',
        category: ErrorCategory.grammar,
        shortExplanation:
            '"Quer" is third person; for "I want" use the first person "quero".',
      ),
    ],
  ),
  // Portuñol hybrid in the attempt (Spanish article "el" grafted into Portuguese).
  TestCase(
    id: 'PT-G-03',
    track: WalkthroughTrack.grounding,
    language: Language.portuguese,
    targetSentence: 'Vou cortar o cabelo amanhã.',
    userAttempt: 'Vou cortar el cabelo amanhã.',
    englishSource: "I'm going to get my hair cut tomorrow.",
    expectedChunks: ['Vou cortar', 'o cabelo', 'amanhã'],
    groundingExpectations: {0: null, 1: 'el cabelo', 2: null},
    corrections: [
      CorrectionItem(
        originalPhrase: 'el cabelo',
        correctedPhrase: 'o cabelo',
        category: ErrorCategory.grammar,
        shortExplanation:
            '"El" is the Spanish article; Brazilian Portuguese uses "o".',
      ),
    ],
  ),
  // Natural-language / anglicism error in the attempt ("checar" for "to check").
  TestCase(
    id: 'PT-G-04',
    track: WalkthroughTrack.grounding,
    language: Language.portuguese,
    targetSentence: 'Quero verificar os dados amanhã.',
    userAttempt: 'Quero checar os dados amanhã.',
    englishSource: 'I want to check the data tomorrow.',
    expectedChunks: ['Quero', 'verificar os dados', 'amanhã'],
    groundingExpectations: {0: null, 1: 'checar', 2: null},
    corrections: [
      CorrectionItem(
        originalPhrase: 'checar',
        correctedPhrase: 'verificar',
        category: ErrorCategory.naturalLanguage,
        shortExplanation:
            '"Checar" is an anglicism; Brazilian Portuguese prefers "verificar" or "conferir".',
      ),
    ],
  ),

  // ── Portuguese · Fallback ───────────────────────────────────────────────────
  // Empty string.
  TestCase(
    id: 'PT-F-01',
    track: WalkthroughTrack.fallback,
    language: Language.portuguese,
    targetSentence: 'Cozinhei macarrão para o jantar.',
    userAttempt: '',
    englishSource: 'I cooked pasta for dinner.',
    expectedChunks: ['Cozinhei', 'macarrão', 'para o jantar'],
    corrections: [],
  ),
  // Near-empty: a couple of words unrelated to the target meaning.
  TestCase(
    id: 'PT-F-02',
    track: WalkthroughTrack.fallback,
    language: Language.portuguese,
    targetSentence: 'Amanhã vou visitar a minha avó.',
    userAttempt: 'Nao sei.',
    englishSource: "Tomorrow I'm going to visit my grandmother.",
    expectedChunks: ['Amanhã', 'vou visitar', 'a minha avó'],
    corrections: [
      CorrectionItem(
        originalPhrase: 'Nao',
        correctedPhrase: 'Não',
        category: ErrorCategory.spelling,
        shortExplanation: '"Não" needs the nasal tilde.',
      ),
    ],
  ),
  // Off-topic: a coherent sentence about a different idea entirely.
  TestCase(
    id: 'PT-F-03',
    track: WalkthroughTrack.fallback,
    language: Language.portuguese,
    targetSentence: 'O trem chega às oito.',
    userAttempt: 'Eu gosto muito de café na manhã.',
    englishSource: 'The train arrives at eight.',
    expectedChunks: ['O trem', 'chega', 'às oito'],
    corrections: [
      CorrectionItem(
        originalPhrase: 'na manhã',
        correctedPhrase: 'de manhã',
        category: ErrorCategory.naturalLanguage,
        shortExplanation: 'Brazilians say "de manhã" for in the morning.',
      ),
    ],
  ),
  // Radically wrong: relevant topic, but wrong verb/tense/noun so no chunk aligns.
  TestCase(
    id: 'PT-F-04',
    track: WalkthroughTrack.fallback,
    language: Language.portuguese,
    targetSentence: 'Comprei três maçãs no mercado.',
    userAttempt: 'Eu vou vender muitas laranjas.',
    englishSource: 'I bought three apples at the market.',
    expectedChunks: ['Comprei', 'três maçãs', 'no mercado'],
    corrections: [
      CorrectionItem(
        originalPhrase: 'vou vender',
        correctedPhrase: 'Comprei',
        category: ErrorCategory.grammar,
        shortExplanation:
            'The English is past tense "bought", so use the preterite "comprei".',
      ),
      CorrectionItem(
        originalPhrase: 'muitas laranjas',
        correctedPhrase: 'três maçãs',
        category: ErrorCategory.wordChoice,
        shortExplanation: 'The source says three apples, not many oranges.',
      ),
    ],
  ),

  // ── Portuguese · Edge ───────────────────────────────────────────────────────
  // Short sentence: two chunks only ("ao" must not be split). Small grounded
  // contraction error on top.
  TestCase(
    id: 'PT-E-01',
    track: WalkthroughTrack.edge,
    language: Language.portuguese,
    targetSentence: 'Vou ao mercado.',
    userAttempt: 'Vou a o mercado.',
    englishSource: "I'm going to the market.",
    expectedChunks: ['Vou', 'ao mercado'],
    groundingExpectations: {0: null, 1: 'a o mercado'},
    corrections: [
      CorrectionItem(
        originalPhrase: 'a o mercado',
        correctedPhrase: 'ao mercado',
        category: ErrorCategory.grammar,
        shortExplanation: 'Portuguese contracts "a" + "o" into "ao".',
      ),
    ],
  ),
];

/// Default path for a single run's report (run 1).
const String reportPath = 'docs/walkthrough_prompt_validation.md';

/// Output path for the run produced by this execution. Override via
/// `--dart-define=WALKTHROUGH_OUTPUT=...`; defaults to the run 1 path so the
/// 3.2 single-run invocation is unchanged.
const String outputPath = String.fromEnvironment(
  'WALKTHROUGH_OUTPUT',
  defaultValue: reportPath,
);

/// When set, after the current run is written the harness reads that earlier
/// run's report and writes a divergence report comparing the two. The earlier
/// run file is only read, never modified.
const String divergenceAgainst = String.fromEnvironment(
  'WALKTHROUGH_DIVERGENCE_AGAINST',
  defaultValue: '',
);

/// Output path for the divergence report.
const String divergenceOutputPath = String.fromEnvironment(
  'WALKTHROUGH_DIVERGENCE_OUT',
  defaultValue: 'docs/walkthrough_prompt_validation_divergence.md',
);

void main() {
  test('walkthrough prompt validation harness', () async {
    final config = AppConfig.fromEnvironment();
    final apiKey = _readEnvironment(
      'OPENAI_API_KEY',
      defaultValue: config.openAiApiKey,
    );
    // TODO(Section 4): swap this raw OpenAI call for a dedicated walkthrough
    // service once Section 4 introduces the WalkthroughQuestion model and its
    // service. The call mirrors OpenAiCorrectionService's /v1/responses pattern
    // so no new client abstraction is introduced.
    final model = _readEnvironment(
      'OPENAI_WALKTHROUGH_MODEL',
      defaultValue: _readEnvironment(
        'OPENAI_CORRECTION_MODEL',
        defaultValue: config.openAiCorrectionModel,
      ),
    );

    if (apiKey.isEmpty) {
      fail(
        'Set OPENAI_API_KEY, or configure a default in AppConfig, to run the '
        'walkthrough prompt validation harness.',
      );
    }

    final currentRun = await _runBattery(
      apiKey: apiKey,
      model: model,
      output: outputPath,
    );

    if (divergenceAgainst.isNotEmpty) {
      // Run 1 is read from its committed report — never re-run or overwritten —
      // so the divergence compares the reviewed run 1 against this fresh run.
      final priorRun = _parseRunFile(divergenceAgainst);
      _writeDivergenceReport(
        run1: priorRun,
        run2: currentRun,
        run1Path: divergenceAgainst,
        run2Path: outputPath,
        out: divergenceOutputPath,
      );
      // ignore: avoid_print
      print('Wrote $divergenceOutputPath');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Runs the full battery once, writes the markdown report to [output], and
/// returns the parsed response per test-case id for in-memory comparison.
Future<Map<String, ParsedResponse>> _runBattery({
  required String apiKey,
  required String model,
  required String output,
}) async {
  final client = HttpClient();
  final body = StringBuffer();
  final results = <String, ParsedResponse>{};

  try {
    for (final tc in testBattery) {
      // ignore: avoid_print
      print('Running ${tc.id} (${tc.track.name}, ${tc.language.name})...');

      final prompt = _buildPrompt(tc);
      ParsedResponse parsed;
      try {
        final raw = await _callWalkthroughPrompt(
          client: client,
          apiKey: apiKey,
          model: model,
          prompt: prompt,
        );
        parsed = _parseResponse(raw);
      } catch (error) {
        parsed = ParsedResponse(
          rawResponse: '',
          parseError: 'API call failed: $error',
        );
      }
      results[tc.id] = parsed;

      writeTestCaseHeader(body, tc);
      writeInputs(body, tc);
      writeGeneratedQuestions(body, parsed);
      writeGroundingTable(body, tc, parsed.questions);
      writeNotesPlaceholder(body);
    }
  } finally {
    client.close(force: true);
  }

  final report = StringBuffer()
    ..write(_buildHeader(model: model))
    ..write(_buildSummary())
    ..write('\n')
    ..write(body.toString());

  File(output).writeAsStringSync(report.toString());
  // ignore: avoid_print
  print('Wrote $output');

  return results;
}

// ── Prompt assembly ─────────────────────────────────────────────────────────

/// Substitutes the four inputs into the language's walkthrough prompt template.
String _buildPrompt(TestCase tc) {
  return PromptBuilder.walkthroughQuestionPromptTemplate(tc.language)
      .replaceAll('{{targetSentence}}', tc.targetSentence)
      .replaceAll('{{userAttempt}}', tc.userAttempt)
      .replaceAll('{{englishSource}}', tc.englishSource)
      .replaceAll('{{corrections}}', _serialiseCorrections(tc.corrections));
}

/// Serialises corrections as the compact JSON array the prompt expects:
/// [{original_phrase, corrected_phrase, category, short_explanation}, ...].
String _serialiseCorrections(List<CorrectionItem> corrections) {
  return jsonEncode([
    for (final c in corrections)
      {
        'original_phrase': c.originalPhrase,
        'corrected_phrase': c.correctedPhrase,
        'category': c.category.label,
        'short_explanation': c.shortExplanation,
      },
  ]);
}

// ── API call (mirrors OpenAiCorrectionService._createResponse) ──────────────

Future<String> _callWalkthroughPrompt({
  required HttpClient client,
  required String apiKey,
  required String model,
  required String prompt,
}) async {
  final request = await client
      .postUrl(Uri.https('api.openai.com', '/v1/responses'))
      .timeout(const Duration(seconds: 15));

  request.headers
    ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
    ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

  request.add(
    utf8.encode(
      jsonEncode({
        'model': model,
        'input': [
          {'role': 'system', 'content': prompt},
          {
            'role': 'user',
            'content':
                'Produce the walkthrough question JSON for the inputs above.',
          },
        ],
      }),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 60));
  final responseBody = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw FormatException(
      'OpenAI request failed with HTTP ${response.statusCode}: $responseBody',
    );
  }

  final decoded = jsonDecode(responseBody);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('OpenAI response root is not an object.');
  }
  return _extractOutputText(decoded);
}

String _extractOutputText(Map<String, Object?> decoded) {
  final outputText = decoded['output_text'];
  if (outputText is String && outputText.trim().isNotEmpty) {
    return outputText.trim();
  }

  final output = decoded['output'];
  if (output is! List) {
    throw const FormatException('OpenAI response has no output.');
  }

  final buffer = StringBuffer();
  for (final item in output) {
    if (item is! Map<String, Object?>) continue;
    final content = item['content'];
    if (content is! List) continue;
    for (final part in content) {
      if (part is! Map<String, Object?>) continue;
      final text = part['text'];
      if (text is String) buffer.write(text);
    }
  }

  final text = buffer.toString().trim();
  if (text.isEmpty) {
    throw const FormatException('OpenAI response has no output text.');
  }
  return text;
}

// ── Response parsing ────────────────────────────────────────────────────────

String _extractJsonObject(String text) {
  final trimmed = text.trim();
  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    return trimmed;
  }
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON object found in response.');
  }
  return trimmed.substring(start, end + 1);
}

/// Decodes the four fields per question and collects any shape violations as
/// findings rather than throwing. A hard JSON failure is recorded in
/// [ParsedResponse.parseError] with the raw text preserved for review.
ParsedResponse _parseResponse(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(_extractJsonObject(raw));
  } on FormatException catch (error) {
    return ParsedResponse(rawResponse: raw, parseError: error.message);
  }

  if (decoded is! Map<String, Object?>) {
    return ParsedResponse(
      rawResponse: raw,
      parseError: 'Root value is not a JSON object.',
    );
  }

  final findings = <String>[];

  final echo = decoded['target_sentence'];
  final targetSentenceEcho = echo is String ? echo : null;
  if (echo is! String) {
    findings.add('target_sentence missing or not a string.');
  }

  final rawQuestions = decoded['questions'];
  if (rawQuestions is! List) {
    return ParsedResponse(
      rawResponse: raw,
      targetSentenceEcho: targetSentenceEcho,
      parseError: 'questions missing or not a list.',
    );
  }

  final questions = <WalkthroughQuestion>[];
  for (var i = 0; i < rawQuestions.length; i++) {
    final entry = rawQuestions[i];
    if (entry is! Map<String, Object?>) {
      findings.add('Question at index $i is not an object.');
      continue;
    }

    final stem = entry['english_stem'];
    final correct = entry['correct_translation'];
    final rawDistractors = entry['distractors'];
    final chunkPosition = entry['chunk_position'];

    if (stem is! String) {
      findings.add('Question at index $i: english_stem missing or not a string.');
    }
    if (correct is! String) {
      findings.add(
        'Question at index $i: correct_translation missing or not a string.',
      );
    }

    final distractors = <String>[];
    if (rawDistractors is List) {
      for (final d in rawDistractors) {
        if (d is String) {
          distractors.add(d);
        } else {
          findings.add('Question at index $i: a distractor is not a string.');
        }
      }
    } else {
      findings.add('Question at index $i: distractors missing or not a list.');
    }

    if (distractors.length != 2) {
      findings.add(
        'Question at index $i: expected exactly 2 distractors, got '
        '${distractors.length}.',
      );
    }
    if (distractors.length == 2 && distractors[0] == distractors[1]) {
      findings.add('Question at index $i: the two distractors are identical.');
    }
    if (correct is String && distractors.contains(correct)) {
      findings.add(
        'Question at index $i: a distractor equals correct_translation.',
      );
    }

    final position = chunkPosition is int
        ? chunkPosition
        : (chunkPosition is num ? chunkPosition.toInt() : i);
    if (chunkPosition is! int) {
      findings.add(
        'Question at index $i: chunk_position missing or not an integer.',
      );
    }

    questions.add(
      WalkthroughQuestion(
        englishStem: stem is String ? stem : '',
        correctTranslation: correct is String ? correct : '',
        distractors: distractors,
        chunkPosition: position,
      ),
    );
  }

  final positions = questions.map((q) => q.chunkPosition).toList();
  if (questions.length < 2 || questions.length > 5) {
    findings.add(
      'Expected 2-5 questions, got ${questions.length}.',
    );
  }
  for (var i = 0; i < positions.length; i++) {
    if (positions[i] != i) {
      findings.add(
        'chunk_position values are not contiguous starting at 0: $positions.',
      );
      break;
    }
  }

  return ParsedResponse(
    rawResponse: raw,
    targetSentenceEcho: targetSentenceEcho,
    questions: questions,
    findings: findings,
  );
}

// ── Report assembly ───────────────────────────────────────────────────────────

String _buildHeader({required String model}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return '''
# Walkthrough Prompt Validation

Generated by `test/walkthrough_prompt_validation.dart`.

- Run (UTC): $now
- Model: `$model`
- Cases: ${testBattery.length}

Pass/fail flags and notes are left blank for manual review.

''';
}

String _buildSummary() {
  final out = StringBuffer()
    ..writeln('## Summary')
    ..writeln()
    ..writeln('| Test case | Track | Language | Pass/fail |')
    ..writeln('| --- | --- | --- | --- |');
  for (final tc in testBattery) {
    out.writeln(
      '| ${tc.id} | ${tc.track.name} | ${tc.language.name} | '
      '[ ] pass / [ ] fail |',
    );
  }
  return out.toString();
}

// ── Logging helpers ───────────────────────────────────────────────────────────
//
// Each helper appends to the shared [out] buffer that main() flushes to
// [reportPath]. The structure matches the scaffold declared in prompt 3.1.

/// Writes the per-test-case H2 header (id, track, language).
void writeTestCaseHeader(StringBuffer out, TestCase tc) {
  out
    ..writeln()
    ..writeln('## ${tc.id} — ${tc.track.name} — ${tc.language.name}')
    ..writeln();
}

/// Writes the H3 "Inputs" section: target, attempt, English source, and the
/// corrections array, in a fenced block.
void writeInputs(StringBuffer out, TestCase tc) {
  final correctionsPretty = const JsonEncoder.withIndent('  ').convert([
    for (final c in tc.corrections)
      {
        'original_phrase': c.originalPhrase,
        'corrected_phrase': c.correctedPhrase,
        'category': c.category.label,
        'short_explanation': c.shortExplanation,
      },
  ]);

  out
    ..writeln('### Inputs')
    ..writeln()
    ..writeln('```text')
    ..writeln('target:        ${tc.targetSentence}')
    ..writeln('attempt:       ${tc.userAttempt.isEmpty ? '(empty)' : tc.userAttempt}')
    ..writeln('englishSource: ${tc.englishSource}')
    ..writeln('corrections:')
    ..writeln(correctionsPretty)
    ..writeln('```')
    ..writeln();
}

/// Writes the H3 "Generated questions" section. On success, a fenced JSON block
/// of the parsed questions; on parse failure, the raw response plus an error
/// note. Any shape-violation findings are listed beneath.
void writeGeneratedQuestions(StringBuffer out, ParsedResponse parsed) {
  out
    ..writeln('### Generated questions')
    ..writeln();

  if (parsed.parseFailed) {
    out
      ..writeln('> **Parse error:** ${parsed.parseError}')
      ..writeln()
      ..writeln('Raw response:')
      ..writeln()
      ..writeln('```text')
      ..writeln(parsed.rawResponse.isEmpty ? '(no response)' : parsed.rawResponse)
      ..writeln('```')
      ..writeln();
    return;
  }

  final pretty = const JsonEncoder.withIndent('  ').convert({
    'target_sentence': parsed.targetSentenceEcho,
    'questions': parsed.questions.map((q) => q.toJson()).toList(),
  });

  out
    ..writeln('```json')
    ..writeln(pretty)
    ..writeln('```')
    ..writeln();

  if (parsed.findings.isNotEmpty) {
    out
      ..writeln('Shape findings:')
      ..writeln();
    for (final finding in parsed.findings) {
      out.writeln('- $finding');
    }
    out.writeln();
  }
}

/// Writes the H3 "Grounding check" section: a markdown table with one row per
/// produced chunk. The grounding-pass column reports whether the expected wrong
/// form (from [TestCase.groundingExpectations]) appears in that chunk's
/// distractors. Fallback cases show "n/a (fallback)" / "n/a".
void writeGroundingTable(
  StringBuffer out,
  TestCase tc,
  List<WalkthroughQuestion> questions,
) {
  out
    ..writeln('### Grounding check')
    ..writeln()
    ..writeln(
      '| chunk_position | expected wrong form | distractor 1 | distractor 2 | grounding pass |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');

  if (questions.isEmpty) {
    out
      ..writeln('| _no questions parsed_ | | | | |')
      ..writeln();
    return;
  }

  final sorted = [...questions]
    ..sort((a, b) => a.chunkPosition.compareTo(b.chunkPosition));

  for (final q in sorted) {
    final distractor1 = q.distractors.isNotEmpty ? q.distractors[0] : '—';
    final distractor2 = q.distractors.length > 1 ? q.distractors[1] : '—';

    final String expectedCell;
    final String passCell;
    if (tc.track == WalkthroughTrack.fallback) {
      expectedCell = 'n/a (fallback)';
      passCell = 'n/a';
    } else {
      final hasExpectation =
          tc.groundingExpectations.containsKey(q.chunkPosition) &&
          tc.groundingExpectations[q.chunkPosition] != null;
      if (!hasExpectation) {
        expectedCell = 'n/a';
        passCell = 'n/a';
      } else {
        final expected = tc.groundingExpectations[q.chunkPosition]!;
        expectedCell = expected;
        passCell = _grounded(expected, q.distractors) ? 'PASS' : 'FAIL';
      }
    }

    out.writeln(
      '| ${q.chunkPosition} | ${_cell(expectedCell)} | ${_cell(distractor1)} '
      '| ${_cell(distractor2)} | $passCell |',
    );
  }
  out.writeln();
}

/// Writes the H3 "Notes" section with free-text placeholders for the reviewer.
void writeNotesPlaceholder(StringBuffer out) {
  out
    ..writeln('### Notes')
    ..writeln()
    ..writeln('Distractor quality observations: _________________')
    ..writeln()
    ..writeln('Overall pass/fail: [ ] pass [ ] fail')
    ..writeln();
}

/// True when [expected] appears in [distractors] (case-insensitive, trimmed;
/// substring match so a slightly longer grounded distractor still counts).
bool _grounded(String expected, List<String> distractors) {
  final needle = expected.trim().toLowerCase();
  if (needle.isEmpty) return false;
  return distractors.any((d) {
    final haystack = d.trim().toLowerCase();
    return haystack == needle || haystack.contains(needle);
  });
}

/// Escapes pipe characters so cell content does not break the markdown table.
String _cell(String value) => value.replaceAll('|', '\\|');

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}

// ── Run 2 / divergence support ──────────────────────────────────────────────
//
// The divergence step reconstructs an earlier run's parsed questions from its
// report's fenced JSON blocks and re-derives grounding with the same _grounded
// logic used live, so both runs are scored identically. The earlier run file is
// only read.

/// Reconstructs the parsed response per test-case id from a written report.
Map<String, ParsedResponse> _parseRunFile(String path) {
  final content = File(path).readAsStringSync();
  return {
    for (final tc in testBattery)
      tc.id: _extractCaseFromReport(content, tc.id, path),
  };
}

ParsedResponse _extractCaseFromReport(String content, String id, String path) {
  final headerIdx = content.indexOf('## $id — ');
  if (headerIdx == -1) {
    return ParsedResponse(
      rawResponse: '',
      parseError: 'Case $id not found in $path.',
    );
  }
  final nextCase = content.indexOf('\n## ', headerIdx + 1);
  final section = content.substring(
    headerIdx,
    nextCase == -1 ? content.length : nextCase,
  );

  final gqIdx = section.indexOf('### Generated questions');
  if (gqIdx == -1) {
    return ParsedResponse(
      rawResponse: '',
      parseError: 'No "Generated questions" section for $id in $path.',
    );
  }
  final nextSub = section.indexOf('\n### ', gqIdx + 1);
  final gq = section.substring(
    gqIdx,
    nextSub == -1 ? section.length : nextSub,
  );

  if (gq.contains('**Parse error:**')) {
    return ParsedResponse(
      rawResponse: '',
      parseError: 'Run reported a parse error for $id.',
    );
  }

  final fenceStart = gq.indexOf('```json');
  if (fenceStart == -1) {
    return ParsedResponse(
      rawResponse: '',
      parseError: 'No JSON block for $id in $path.',
    );
  }
  final jsonStart = gq.indexOf('\n', fenceStart) + 1;
  final fenceEnd = gq.indexOf('```', jsonStart);
  return _parseResponse(gq.substring(jsonStart, fenceEnd));
}

/// Sorted chunk strings (correct_translation by ascending chunk_position).
List<String> _chunks(ParsedResponse run) {
  final sorted = [...run.questions]
    ..sort((a, b) => a.chunkPosition.compareTo(b.chunkPosition));
  return [for (final q in sorted) q.correctTranslation];
}

/// Distractors produced for [position], or empty if no such chunk exists.
List<String> _distractorsAt(ParsedResponse run, int position) {
  for (final q in run.questions) {
    if (q.chunkPosition == position) return q.distractors;
  }
  return const [];
}

/// Per grounded chunk_position (non-null grounding expectation), whether the
/// expected wrong form was grounded in this run's distractors.
Map<int, bool> _groundingResults(TestCase tc, ParsedResponse run) {
  final results = <int, bool>{};
  tc.groundingExpectations.forEach((position, expected) {
    if (expected == null) return;
    results[position] = _grounded(expected, _distractorsAt(run, position));
  });
  return results;
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals(Map<int, bool> a, Map<int, bool> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// Computed comparison of one test case across two runs.
class _CaseComparison {
  _CaseComparison(this.tc, this.run1, this.run2);

  final TestCase tc;
  final ParsedResponse run1;
  final ParsedResponse run2;

  bool get p1ok => !run1.parseFailed;
  bool get p2ok => !run2.parseFailed;

  int get count1 => run1.questions.length;
  int get count2 => run2.questions.length;
  List<String> get chunks1 => _chunks(run1);
  List<String> get chunks2 => _chunks(run2);

  /// Number of grounded chunks the test author expects (denominator of the
  /// "X of M" pass count); 0 for fallback cases.
  int get groundedCount =>
      tc.groundingExpectations.values.where((v) => v != null).length;

  Map<int, bool> get grounding1 => _groundingResults(tc, run1);
  Map<int, bool> get grounding2 => _groundingResults(tc, run2);

  String get chunkCountMatch {
    if (!p1ok || !p2ok) return 'n/a';
    return count1 == count2 ? 'yes' : 'no';
  }

  String get groundingMatch {
    if (groundedCount == 0) return 'n/a';
    if (!p1ok || !p2ok) return 'n/a';
    return _mapEquals(grounding1, grounding2) ? 'yes' : 'no';
  }

  String get parseMatch => p1ok == p2ok ? 'yes' : 'no';

  /// Overall divergence flag: yes if any of the three match columns is "no".
  bool get diverged =>
      chunkCountMatch == 'no' ||
      groundingMatch == 'no' ||
      parseMatch == 'no';

  bool get decompositionIdentical =>
      p1ok && p2ok && _listEquals(chunks1, chunks2);

  String passCount({required bool runOne}) {
    if (groundedCount == 0) return 'n/a';
    final ok = runOne ? p1ok : p2ok;
    if (!ok) return 'n/a';
    final results = runOne ? grounding1 : grounding2;
    final passed = results.values.where((v) => v).length;
    return '$passed of $groundedCount';
  }
}

void _writeDivergenceReport({
  required Map<String, ParsedResponse> run1,
  required Map<String, ParsedResponse> run2,
  required String run1Path,
  required String run2Path,
  required String out,
}) {
  final comparisons = [
    for (final tc in testBattery)
      _CaseComparison(
        tc,
        run1[tc.id] ??
            ParsedResponse(rawResponse: '', parseError: 'Missing in run 1.'),
        run2[tc.id] ??
            ParsedResponse(rawResponse: '', parseError: 'Missing in run 2.'),
      ),
  ];

  final buffer = StringBuffer()
    ..writeln('# Walkthrough Prompt Validation — Run Divergence')
    ..writeln()
    ..writeln(
      'Compares two runs of the identical ${testBattery.length}-case battery '
      'to check the stability of chunk decomposition and grounding behavior '
      'across non-deterministic LLM outputs.',
    )
    ..writeln()
    ..writeln('- Run 1 (reviewed): `$run1Path`')
    ..writeln('- Run 2: `$run2Path`')
    ..writeln('- Generated (UTC): ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln();

  _writeDivergenceSummaryTable(buffer, comparisons);
  buffer.writeln();

  for (final c in comparisons.where((c) => c.diverged)) {
    _writeDivergenceCaseSection(buffer, c);
  }

  _writeStabilitySummary(buffer, comparisons);

  File(out).writeAsStringSync(buffer.toString());
}

void _writeDivergenceSummaryTable(
  StringBuffer out,
  List<_CaseComparison> comparisons,
) {
  out
    ..writeln('## Summary')
    ..writeln()
    ..writeln(
      '| Test case | R1 chunks | R2 chunks | Chunk count match | '
      'R1 grounding | R2 grounding | Grounding match | Parse match | '
      'Divergence |',
    )
    ..writeln(
      '| --- | --- | --- | --- | --- | --- | --- | --- | --- |',
    );

  for (final c in comparisons) {
    final r1Chunks = c.p1ok ? '${c.count1}' : '—';
    final r2Chunks = c.p2ok ? '${c.count2}' : '—';
    out.writeln(
      '| ${c.tc.id} | $r1Chunks | $r2Chunks | ${c.chunkCountMatch} | '
      '${c.passCount(runOne: true)} | ${c.passCount(runOne: false)} | '
      '${c.groundingMatch} | ${c.parseMatch} | '
      '${c.diverged ? 'yes' : 'no'} |',
    );
  }
}

void _writeDivergenceCaseSection(StringBuffer out, _CaseComparison c) {
  final axes = <String>[
    if (c.chunkCountMatch == 'no') 'chunk count',
    if (c.groundingMatch == 'no') 'grounding',
    if (c.parseMatch == 'no') 'parse',
  ];

  out
    ..writeln('## ${c.tc.id}')
    ..writeln()
    ..writeln('Diverged on: ${axes.join(', ')}.')
    ..writeln();

  // Chunks side by side.
  out
    ..writeln('| chunk_position | run 1 chunk | run 2 chunk |')
    ..writeln('| --- | --- | --- |');
  final maxChunks = c.count1 > c.count2 ? c.count1 : c.count2;
  for (var i = 0; i < maxChunks; i++) {
    final r1 = i < c.chunks1.length ? c.chunks1[i] : '—';
    final r2 = i < c.chunks2.length ? c.chunks2[i] : '—';
    out.writeln('| $i | ${_cell(r1)} | ${_cell(r2)} |');
  }
  out.writeln();

  // Grounding detail for affected positions.
  if (c.groundingMatch == 'no') {
    out
      ..writeln(
        '| chunk_position | expected wrong form | run 1 distractors | '
        'run 2 distractors | run 1 pass | run 2 pass |',
      )
      ..writeln('| --- | --- | --- | --- | --- | --- |');
    final positions = c.grounding1.keys.toList()..sort();
    for (final pos in positions) {
      if (c.grounding1[pos] == c.grounding2[pos]) continue;
      final expected = c.tc.groundingExpectations[pos]!;
      final d1 = _distractorsAt(c.run1, pos);
      final d2 = _distractorsAt(c.run2, pos);
      out.writeln(
        '| $pos | ${_cell(expected)} | '
        '${_cell(d1.isEmpty ? '—' : d1.join(', '))} | '
        '${_cell(d2.isEmpty ? '—' : d2.join(', '))} | '
        '${c.grounding1[pos]! ? 'PASS' : 'FAIL'} | '
        '${c.grounding2[pos]! ? 'PASS' : 'FAIL'} |',
      );
    }
    out.writeln();
  }

  out
    ..writeln(_observation(c))
    ..writeln();
}

/// Factual, non-interpretive description of the difference between the runs.
String _observation(_CaseComparison c) {
  if (c.parseMatch == 'no') {
    final failed = c.p1ok ? 'Run 2' : 'Run 1';
    final ok = c.p1ok ? 'run 1' : 'run 2';
    return '$failed failed to parse where $ok parsed.';
  }

  final parts = <String>[];
  if (c.count1 != c.count2) {
    parts.add(
      'Run 2 produced a ${c.count2}-chunk decomposition where run 1 produced '
      '${c.count1}.',
    );
  } else if (!_listEquals(c.chunks1, c.chunks2)) {
    final diffs = [
      for (var i = 0; i < c.count1; i++)
        if (c.chunks1[i] != c.chunks2[i]) i,
    ];
    parts.add(
      'Chunk count identical (${c.count1}); chunk boundaries differed at '
      'position(s) ${diffs.join(', ')}.',
    );
  } else {
    parts.add('Chunk boundaries identical.');
  }

  if (c.groundingMatch == 'no') {
    final positions = [
      for (final pos in c.grounding1.keys)
        if (c.grounding1[pos] != c.grounding2[pos]) pos,
    ]..sort();
    parts.add('Grounding pass differed on chunk(s) ${positions.join(', ')}.');
  }

  return parts.join(' ');
}

void _writeStabilitySummary(
  StringBuffer out,
  List<_CaseComparison> comparisons,
) {
  final total = comparisons.length;
  final identicalDecomp =
      comparisons.where((c) => c.decompositionIdentical).length;
  final groundingCases =
      comparisons.where((c) => c.tc.track == WalkthroughTrack.grounding);
  final groundingStable =
      groundingCases.where((c) => c.groundingMatch == 'yes').length;
  final bothParsed = comparisons.where((c) => c.p1ok && c.p2ok).length;
  final zeroDivergence = comparisons.where((c) => !c.diverged).length;

  out
    ..writeln('## Stability summary')
    ..writeln()
    ..writeln('- Total test cases run: $total')
    ..writeln(
      '- Test cases with identical chunk decomposition across runs: '
      '$identicalDecomp of $total',
    )
    ..writeln(
      '- Test cases where grounding behavior was stable across runs: '
      '$groundingStable of ${groundingCases.length}',
    )
    ..writeln(
      '- Test cases where both runs parsed successfully: $bothParsed of $total',
    )
    ..writeln(
      '- Test cases with zero divergence on any axis: $zeroDivergence of $total',
    )
    ..writeln();
}
