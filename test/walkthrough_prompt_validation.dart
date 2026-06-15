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
// PROMPT 3.2 SCOPE: battery populated, harness body + logging helpers
// implemented, report generated. Remaining prompts:
//   3.3 — (this prompt already wires the call; 3.3 may swap in a dedicated
//          walkthrough service if Section 4 introduces one).
//   3.4 — review the generated report.
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

/// Path the harness writes its review report to.
const String reportPath = 'docs/walkthrough_prompt_validation.md';

void main() {
  test('walkthrough prompt validation harness', () async {
    final config = AppConfig.fromEnvironment();
    final apiKey = _readEnvironment(
      'OPENAI_API_KEY',
      defaultValue: config.openAiApiKey,
    );
    // TODO(3.3 / Section 4): swap this raw OpenAI call for a dedicated
    // walkthrough service once Section 4 introduces the WalkthroughQuestion
    // model and its service. The call below mirrors OpenAiCorrectionService's
    // /v1/responses pattern so no new client abstraction is introduced.
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

    final client = HttpClient();
    final body = StringBuffer();

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

    File(reportPath).writeAsStringSync(report.toString());
    // ignore: avoid_print
    print('Wrote $reportPath');
  }, timeout: const Timeout(Duration(minutes: 10)));
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
