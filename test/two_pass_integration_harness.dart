// Live two-pass integration harness (issue #42).
//
// Purpose: measure the REAL, already-built two-pass pipeline's combined
// live behavior — first pass (callFirstPassCorrection, issue #68/#67/#65 —
// the narrow grammar/spelling/accents/punctuation-only client, no longer
// the old broad runStagedCorrectionPipeline), naturalness review
// (callNaturalnessReview), the merge (mergeNaturalnessReview), and the
// fallback rerun — across a small, deliberately chosen fixture set, and
// compare naturalness run on the original text against naturalness run on
// the first pass's own corrected text for the same input.
//
// Unlike the earlier prototyping harnesses in this repo
// (model_comparison_harness.dart, naturalness_model_comparison_harness.dart),
// this one is NOT standalone: by the time this issue exists, #27-#39 have
// already built and merged the real two-pass pipeline
// (lib/features/corrections/data/two_pass_correction_pipeline.dart and its
// dependencies), so re-prototyping that logic here from scratch would just
// risk drifting from what production actually does. This harness calls the
// same production functions runTwoPassCorrectionPipeline itself calls
// (mergeNaturalnessReview, mapNaturalnessEditsIntoCorrectionResponse), just
// sequenced by hand so it can also capture the naturalness-on-original-text
// result for comparison — production only ever needs the final answer, but
// a measurement harness needs the intermediate one too.
//
// Deliberately calls naturalness on BOTH the original text and the first
// pass's corrected text for every fixture, unconditionally — unlike
// production, which only calls the second (fallback) naturalness pass when
// the first merge attempt actually conflicts. That's the point: this
// harness exists to compare the two variants directly, not to reproduce
// production's own call-minimizing behavior.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_integration_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls). The live test iterates
// allTwoPassFixtures — as of issue #82, that's the original 5-fixture
// smoke subset (twoPassIntegrationFixtures) PLUS the full 80-fixture
// language-point benchmark (languagePointBenchmarkFixtures, 16 groups x 5,
// converted from docs/two_pass_language_point_test_map.md), so 85
// fixtures total, first pass (1 call each) + 2 naturalness calls each —
// expect on the order of 255 total API calls for a full run. There is no
// built-in way yet to run only a subset; consider that before opting in,
// or run a smaller ad hoc fixture list locally first.
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LIVE=true \
//   flutter test test/two_pass_integration_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - FIRST_PASS_MODEL: defaults to gpt-4.1.
// - NATURALNESS_MODEL: defaults to gpt-5.1.
// - TWO_PASS_OUTPUT: report path, defaults to
//   docs/two_pass_integration_harness.md.
// - TWO_PASS_CALL_DELAY_MS: delay between fixtures, defaults to 750.

import 'dart:io';
import 'dart:math' show min;

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

import 'shared/model_pricing.dart' as pricing;

/// Which edit shape a fixture is expected to exercise (issue #81) — lets a
/// benchmark reader tell a replacement case from an insertion, deletion,
/// mixed (more than one operation type in the same input), or
/// deliberately-unchanged one without re-deriving it from the input/
/// expected-output diff by eye. See
/// `docs/two_pass_language_point_test_map.md` for the full language-point
/// matrix this taxonomy is drawn from.
enum TwoPassOperationType { replacement, insertion, deletion, mixed, noChange }

/// Which pass a fixture expects to be responsible for its fix, or that no
/// fix is expected at all (issue #81). [either] covers both "either pass
/// alone would be an acceptable source of the fix" (e.g. a collocation
/// either pass might catch) and "both passes contribute independently, in
/// separate spans" (a fixture combining two language points) — the
/// distinction that matters for reading a report is that no single pass
/// is the sole expected owner, not which of those two shapes applies.
enum TwoPassExpectedOwner { firstPass, naturalness, either, noChange }

/// One fixture for this harness, chosen to exercise a distinct point on
/// the comparison this issue asks for.
class TwoPassFixture {
  const TwoPassFixture({
    required this.id,
    required this.text,
    required this.note,
    required this.languagePoint,
    required this.operationType,
    required this.expectedOwner,
    required this.expectedCorrectedText,
    this.acceptableAlternatives = const [],
  });

  final String id;
  final String text;
  final String note;

  /// The Spanish language point this fixture targets (e.g. "Accents /
  /// Diacritics", "Collocations / Strong Calques") — see
  /// `docs/two_pass_language_point_test_map.md` for the full matrix.
  final String languagePoint;

  /// The edit shape this fixture exercises.
  final TwoPassOperationType operationType;

  /// Which pass is expected to own this fixture's fix.
  final TwoPassExpectedOwner expectedOwner;

  /// The corrected text this fixture expects the two-pass pipeline to
  /// produce. For [TwoPassOperationType.noChange] fixtures, this equals
  /// [text] itself — no edit is expected.
  final String expectedCorrectedText;

  /// Other outputs that would also be an acceptable fix, alongside (not
  /// instead of) [expectedCorrectedText] — e.g. a synonym replacement
  /// naturalness sometimes proposes. Empty when only one output is
  /// considered correct.
  final List<String> acceptableAlternatives;
}

/// The original 5-fixture smoke subset (issue #42), kept small and fast
/// deliberately. For the full benchmark, see [languagePointBenchmarkFixtures]
/// (issue #82) and the combined [allTwoPassFixtures].
const List<TwoPassFixture> twoPassIntegrationFixtures = [
  TwoPassFixture(
    id: 'clean-grammar-only',
    text: 'Vi mucho trafico ayer.',
    note:
        'First-pass-only fixable error (missing accent); no naturalness '
        'issue anywhere. Expect: no conflict, no fallback.',
    languagePoint: 'Accents / Diacritics',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Vi mucho tráfico ayer.',
  ),
  TwoPassFixture(
    id: 'naturalness-only',
    text: 'Voy a hacer una decisión importante.',
    note:
        'No first-pass-fixable error; a naturalness calque only. Expect: '
        'naturalness-on-original and naturalness-on-corrected agree '
        '(the text is identical either way), no conflict.',
    languagePoint: 'Collocations / Strong Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.naturalness,
    expectedCorrectedText: 'Voy a tomar una decisión importante.',
  ),
  TwoPassFixture(
    id: 'grammar-and-naturalness-independent',
    text:
        'El profesor dijo que devia estudiar más, y ella hizo una '
        'decisión importante.',
    note:
        'Spatially separate first-pass fix ("devia" -> "debía") and '
        'naturalness calque ("hizo una decisión"). Expect: the '
        'naturalness span is untouched by the first pass, so both '
        'variants agree; no conflict.',
    // Two independent language points in one fixture: the accent fix is
    // first-pass-owned on its own, but the fixture as a whole isn't
    // solely either pass's job — see TwoPassExpectedOwner.either's doc.
    languagePoint:
        'Accents / Diacritics + Collocations / Strong Calques '
        '(independent spans)',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText:
        'El profesor dijo que debía estudiar más, y ella tomó una '
        'decisión importante.',
  ),
  TwoPassFixture(
    id: 'grammar-overlaps-naturalness',
    text: 'Ayer iso una decisión importante.',
    note:
        'The first-pass fix ("iso" -> "hizo") sits inside the exact '
        'naturalness calque span ("hizo una decisión") — the case the '
        'fallback exists for. Expect: naturalness-on-original flags the '
        'pre-correction wording (conflict against firstPassCorrectedText), '
        'naturalness-on-corrected flags the post-correction wording '
        '(resolves cleanly) — fallback used.',
    languagePoint:
        'Verb Morphology (spelling) overlapping Collocations / Strong '
        'Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Ayer tomó una decisión importante.',
  ),
  TwoPassFixture(
    id: 'ambiguous-naturalness-span',
    text: 'Vi mucho tráfico, y luego vi más tráfico.',
    note:
        'No first-pass fix needed; naturalness may flag a bare repeated '
        'word ambiguously on both passes. Expect: possible conflict that '
        'the fallback does not resolve either — the "still unsafe after a '
        'rerun" case from issue #37, observed live rather than simulated.',
    languagePoint: 'Ambiguous / Repeated Span Safety (Naturalness)',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Vi mucho tráfico, y luego vi más tráfico.',
  ),
];

/// The full language-point benchmark (issue #82), converted from
/// `docs/two_pass_language_point_test_map.md`'s matrix into executable
/// [TwoPassFixture]s: 16 language-point groups, 5 fixtures each. Distinct
/// from [twoPassIntegrationFixtures] (kept as a small smoke subset) — see
/// [allTwoPassFixtures] for the combined set this harness actually runs.
const List<TwoPassFixture> languagePointBenchmarkFixtures = [
  // --- 1. Accents / Diacritics — expected owner: first pass ---
  TwoPassFixture(
    id: 'accent-manana',
    text: 'Voy al parque manana por la tarde.',
    note: 'Missing accent on "mañana".',
    languagePoint: 'Accents / Diacritics',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Voy al parque mañana por la tarde.',
  ),
  TwoPassFixture(
    id: 'accent-medico',
    text: 'El medico llego despues de la reunion.',
    note: 'Missing accents on "médico", "llegó", "después", "reunión".',
    languagePoint: 'Accents / Diacritics',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'El médico llegó después de la reunión.',
  ),
  TwoPassFixture(
    id: 'accent-espana-pais',
    text: 'Espana es un pais muy diverso.',
    note: 'Missing accent/ñ on "España" and accent on "país".',
    languagePoint: 'Accents / Diacritics',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'España es un país muy diverso.',
  ),
  TwoPassFixture(
    id: 'accent-cumpleanos-otono',
    text: 'Mi cumpleanos es en otono.',
    note: 'Missing ñ/accent on "cumpleaños" and "otoño".',
    languagePoint: 'Accents / Diacritics',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Mi cumpleaños es en otoño.',
  ),
  TwoPassFixture(
    id: 'accent-cafe-cafeteria',
    text: 'Compre cafe en una cafeteria pequena.',
    note: 'Missing accents on "Compré", "café", "cafetería", "pequeña".',
    languagePoint: 'Accents / Diacritics',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Compré café en una cafetería pequeña.',
  ),

  // --- 2. Gender / Number Agreement — expected owner: first pass ---
  TwoPassFixture(
    id: 'agreement-ninos-manzanas',
    text: 'Los niño come muchas manzana.',
    note: 'Plural article/noun/verb and noun-number agreement.',
    languagePoint: 'Gender / Number Agreement',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Los niños comen muchas manzanas.',
  ),
  TwoPassFixture(
    id: 'agreement-ventanas-abiertas',
    text: 'Las ventanas estaban abierto.',
    note: 'Predicate adjective must agree in gender/number with "ventanas".',
    languagePoint: 'Gender / Number Agreement',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Las ventanas estaban abiertas.',
  ),
  TwoPassFixture(
    id: 'agreement-puerta-cerrada',
    text: 'Una puerta estaba cerrado.',
    note: 'Predicate adjective must agree in gender with "puerta".',
    languagePoint: 'Gender / Number Agreement',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Una puerta estaba cerrada.',
  ),
  TwoPassFixture(
    id: 'agreement-billetes-caros',
    text: 'Los billetes estaban caro.',
    note: 'Predicate adjective must agree in number with "billetes".',
    languagePoint: 'Gender / Number Agreement',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Los billetes estaban caros.',
  ),
  TwoPassFixture(
    id: 'agreement-fechas-escritas',
    text: 'Las fechas estaban escrito sin tilde.',
    note: 'Predicate participle must agree in gender/number with "fechas".',
    languagePoint: 'Gender / Number Agreement',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Las fechas estaban escritas sin tilde.',
  ),

  // --- 3. Verb Agreement / Morphology — expected owner: first pass ---
  TwoPassFixture(
    id: 'verb-nosotros-fuimos',
    text: 'Mis compañeros y yo fue a la biblioteca.',
    note: '"fue" must be "fuimos" to agree with "mis compañeros y yo".',
    languagePoint: 'Verb Agreement / Morphology',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Mis compañeros y yo fuimos a la biblioteca.',
  ),
  TwoPassFixture(
    id: 'verb-ninos-comen',
    text: 'Los niños come en el jardín.',
    note: '"come" must be "comen" to agree with the plural subject.',
    languagePoint: 'Verb Agreement / Morphology',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Los niños comen en el jardín.',
  ),
  TwoPassFixture(
    id: 'verb-compre-pan',
    text: 'Yo fui al mercado y compra pan.',
    note: '"compra" must be first-person preterite "compré".',
    languagePoint: 'Verb Agreement / Morphology',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Yo fui al mercado y compré pan.',
  ),
  TwoPassFixture(
    id: 'verb-ellos-estudian',
    text: 'Ellos estudia todas las noches.',
    note: '"estudia" must be "estudian" to agree with "ellos".',
    languagePoint: 'Verb Agreement / Morphology',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Ellos estudian todas las noches.',
  ),
  TwoPassFixture(
    id: 'verb-nosotros-vivimos',
    text: 'Nosotros vive cerca del centro.',
    note: '"vive" must be "vivimos" to agree with "nosotros".',
    languagePoint: 'Verb Agreement / Morphology',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Nosotros vivimos cerca del centro.',
  ),

  // --- 4. Required Prepositions — expected owner: first pass ---
  TwoPassFixture(
    id: 'prep-insisto-en',
    text: 'Insisto que revises el contrato.',
    note: '"insistir" requires "en" before a "que" clause.',
    languagePoint: 'Required Prepositions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Insisto en que revises el contrato.',
  ),
  TwoPassFixture(
    id: 'prep-empresa-en-la-que',
    text: 'La empresa que trabajo está cerca.',
    note: 'Relative clause needs "en la que" (working "at/in" the company).',
    languagePoint: 'Required Prepositions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'La empresa en la que trabajo está cerca.',
  ),
  TwoPassFixture(
    id: 'prep-dependo-de',
    text: 'Dependo que me ayudes mañana.',
    note: '"depender" requires "de" before a "que" clause.',
    languagePoint: 'Required Prepositions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Dependo de que me ayudes mañana.',
  ),
  TwoPassFixture(
    id: 'prep-pienso-en-ti',
    text: 'Pienso ti todos los días.',
    note: '"pensar en" requires the preposition "en" before its object.',
    languagePoint: 'Required Prepositions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Pienso en ti todos los días.',
  ),
  TwoPassFixture(
    id: 'prep-sone-con',
    text: 'Soñé mi antiguo colegio.',
    note: '"soñar con" requires the preposition "con".',
    languagePoint: 'Required Prepositions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Soñé con mi antiguo colegio.',
  ),

  // --- 5. Articles / Determiners — expected owner: first pass ---
  TwoPassFixture(
    id: 'article-puerta-principal',
    text: 'Abrió puerta principal.',
    note: 'Missing definite article before "puerta principal".',
    languagePoint: 'Articles / Determiners',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Abrió la puerta principal.',
  ),
  TwoPassFixture(
    id: 'article-un-libro',
    text: 'Necesito comprar libro para la clase.',
    note: 'Missing indefinite article before "libro".',
    languagePoint: 'Articles / Determiners',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Necesito comprar un libro para la clase.',
  ),
  TwoPassFixture(
    id: 'article-el-profesor-la-regla',
    text: 'Profesor explicó regla otra vez.',
    note: 'Missing definite articles before both "profesor" and "regla".',
    languagePoint: 'Articles / Determiners',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'El profesor explicó la regla otra vez.',
  ),
  TwoPassFixture(
    id: 'article-la-tienda',
    text: 'Fui a tienda después del trabajo.',
    note: 'Missing definite article before "tienda".',
    languagePoint: 'Articles / Determiners',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Fui a la tienda después del trabajo.',
  ),
  TwoPassFixture(
    id: 'article-cita-medico',
    text: 'Tengo cita con médico mañana.',
    note: 'Missing indefinite article before "cita" and definite before '
        '"médico".',
    languagePoint: 'Articles / Determiners',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Tengo una cita con el médico mañana.',
  ),

  // --- 6. Subjunctive / Mood — expected owner: first pass ---
  TwoPassFixture(
    id: 'subj-estudies',
    text: 'Es importante que estudias.',
    note: 'Impersonal "es importante que" requires the subjunctive.',
    languagePoint: 'Subjunctive / Mood',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Es importante que estudies.',
  ),
  TwoPassFixture(
    id: 'subj-tenga-razon',
    text: 'No creo que tiene razón.',
    note: 'Negated "creer" triggers the subjunctive in its clause.',
    languagePoint: 'Subjunctive / Mood',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'No creo que tenga razón.',
  ),
  TwoPassFixture(
    id: 'subj-vengas',
    text: 'Quiero que vienes conmigo.',
    note: '"querer que" requires the subjunctive.',
    languagePoint: 'Subjunctive / Mood',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Quiero que vengas conmigo.',
  ),
  TwoPassFixture(
    id: 'subj-enviara',
    text: 'Era necesario que enviaba su parte.',
    note: 'Impersonal past "era necesario que" requires the imperfect '
        'subjunctive.',
    languagePoint: 'Subjunctive / Mood',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Era necesario que enviara su parte.',
  ),
  TwoPassFixture(
    id: 'subj-hable-frances',
    text: 'Busco a alguien que habla francés.',
    note: 'Nonspecific antecedent ("alguien que...") requires the '
        'subjunctive.',
    languagePoint: 'Subjunctive / Mood',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Busco a alguien que hable francés.',
  ),

  // --- 7. Required Additions / Omissions — expected owner: first pass ---
  TwoPassFixture(
    id: 'missing-que-creo',
    text: 'Creo está bien terminar hoy.',
    note: '"creer" requires the connector "que" before its clause.',
    languagePoint: 'Required Additions / Omissions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Creo que está bien terminar hoy.',
  ),
  TwoPassFixture(
    id: 'missing-les-ninos',
    text: 'A los niños expliqué la regla.',
    note: 'Fronted indirect object "a los niños" requires the clitic "les".',
    languagePoint: 'Required Additions / Omissions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'A los niños les expliqué la regla.',
  ),
  TwoPassFixture(
    id: 'missing-personal-a-profesor',
    text: 'Vi mi profesor en la estación.',
    note: 'Definite human direct object requires the personal "a".',
    languagePoint: 'Required Additions / Omissions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Vi a mi profesor en la estación.',
  ),
  TwoPassFixture(
    id: 'missing-se-levanto',
    text: 'Levantó temprano ayer.',
    note: 'Reflexive "levantarse" requires the reflexive pronoun "se".',
    languagePoint: 'Required Additions / Omissions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Se levantó temprano ayer.',
  ),
  TwoPassFixture(
    id: 'missing-le-gusta',
    text: 'A Juan gusta el café.',
    note: 'Fronted "a Juan" with "gustar" requires the clitic "le".',
    languagePoint: 'Required Additions / Omissions',
    operationType: TwoPassOperationType.insertion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'A Juan le gusta el café.',
  ),

  // --- 8. Unnecessary Extras / Deletions — expected owner: first pass ---
  // (first pass may catch; for POC scoring, judge final corrected text
  // rather than correction-card detail — see the language-point test map).
  TwoPassFixture(
    id: 'delete-repeated-yo-estudio',
    text: 'Yo trabajo mucho y yo estudio por las noches.',
    note: 'Second "yo" is a redundant repeated subject pronoun.',
    languagePoint: 'Unnecessary Extras / Deletions',
    operationType: TwoPassOperationType.deletion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Yo trabajo mucho y estudio por las noches.',
  ),
  TwoPassFixture(
    id: 'delete-repeated-ellos-visitaron',
    text: 'Ellos viajaron a México y ellos visitaron varias ciudades.',
    note: 'Second "ellos" is a redundant repeated subject pronoun.',
    languagePoint: 'Unnecessary Extras / Deletions',
    operationType: TwoPassOperationType.deletion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText:
        'Ellos viajaron a México y visitaron varias ciudades.',
  ),
  TwoPassFixture(
    id: 'delete-repeated-a-mi',
    text: 'A mí me gusta el café a mí.',
    note: 'Trailing "a mí" repeats the fronted emphatic pronoun.',
    languagePoint: 'Unnecessary Extras / Deletions',
    operationType: TwoPassOperationType.deletion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'A mí me gusta el café.',
  ),
  TwoPassFixture(
    id: 'delete-repeated-yo-compre',
    text: 'Yo fui al mercado y yo compré pan.',
    note: 'Second "yo" is a redundant repeated subject pronoun.',
    languagePoint: 'Unnecessary Extras / Deletions',
    operationType: TwoPassOperationType.deletion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Fui al mercado y compré pan.',
  ),
  TwoPassFixture(
    id: 'delete-repeated-nosotros',
    text: 'Nosotros salimos temprano y nosotros llegamos a tiempo.',
    note: 'Second "nosotros" is a redundant repeated subject pronoun.',
    languagePoint: 'Unnecessary Extras / Deletions',
    operationType: TwoPassOperationType.deletion,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Nosotros salimos temprano y llegamos a tiempo.',
  ),

  // --- 9. Ser / Estar / Haber — expected owner: first pass ---
  TwoPassFixture(
    id: 'ser-profesor',
    text: 'Mi hermano está profesor.',
    note: 'Profession/identity requires "ser", not "estar".',
    languagePoint: 'Ser / Estar / Haber',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Mi hermano es profesor.',
  ),
  TwoPassFixture(
    id: 'haber-veinte-personas',
    text: 'En la sala son veinte personas.',
    note: 'Existential "there are" requires impersonal "hay", not "son".',
    languagePoint: 'Ser / Estar / Haber',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'En la sala hay veinte personas.',
  ),
  TwoPassFixture(
    id: 'ser-capital-madrid',
    text: 'Madrid está la capital de España.',
    note: 'Identity/definition requires "ser", not "estar".',
    languagePoint: 'Ser / Estar / Haber',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Madrid es la capital de España.',
  ),
  TwoPassFixture(
    id: 'estar-contento',
    text: 'Estoy muy contento con el resultado.',
    note: 'Already correct: temporary state correctly uses "estar".',
    languagePoint: 'Ser / Estar / Haber',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Estoy muy contento con el resultado.',
  ),
  TwoPassFixture(
    id: 'ser-reunion-segunda-planta',
    text: 'La reunión es en la segunda planta.',
    note: 'Already correct: event location correctly uses "ser".',
    languagePoint: 'Ser / Estar / Haber',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'La reunión es en la segunda planta.',
  ),

  // --- 10. Impersonal Haber / Se — expected owner: first pass ---
  TwoPassFixture(
    id: 'haber-habia-personas',
    text: 'Habían muchas personas en la entrada.',
    note: 'Impersonal "haber" is invariant: "había", never "habían".',
    languagePoint: 'Impersonal Haber / Se',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Había muchas personas en la entrada.',
  ),
  TwoPassFixture(
    id: 'haber-hubo-problemas',
    text: 'Hubieron varios problemas durante la reunión.',
    note: 'Impersonal "haber" is invariant: "hubo", never "hubieron".',
    languagePoint: 'Impersonal Haber / Se',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Hubo varios problemas durante la reunión.',
  ),
  TwoPassFixture(
    id: 'se-venden-pisos',
    text: 'Se vende pisos en el centro.',
    note: 'Passive "se" must agree in number with the plural "pisos".',
    languagePoint: 'Impersonal Haber / Se',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Se venden pisos en el centro.',
  ),
  TwoPassFixture(
    id: 'se-necesitan-voluntarios',
    text: 'Se necesita voluntarios para el evento.',
    note: 'Passive "se" must agree in number with the plural '
        '"voluntarios".',
    languagePoint: 'Impersonal Haber / Se',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Se necesitan voluntarios para el evento.',
  ),
  TwoPassFixture(
    id: 'haber-habia-cifras',
    text: 'Habían varias cifras incorrectas.',
    note: 'Impersonal "haber" is invariant: "había", never "habían".',
    languagePoint: 'Impersonal Haber / Se',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText: 'Había varias cifras incorrectas.',
  ),

  // --- 11. Collocations / Strong Calques — expected owner: either ---
  TwoPassFixture(
    id: 'collocation-hacer-decision',
    text: 'Necesito hacer una decisión.',
    note: 'English-influenced "hacer una decisión" calque.',
    languagePoint: 'Collocations / Strong Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Necesito tomar una decisión.',
  ),
  TwoPassFixture(
    id: 'collocation-hacer-atencion',
    text: 'Tenemos que hacer atención.',
    note: 'English-influenced "hacer atención" calque.',
    languagePoint: 'Collocations / Strong Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Tenemos que prestar atención.',
  ),
  TwoPassFixture(
    id: 'collocation-tomar-reunion',
    text: 'El equipo tomó una reunión.',
    note: 'English-influenced "tomar una reunión" calque.',
    languagePoint: 'Collocations / Strong Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'El equipo tuvo una reunión.',
  ),
  TwoPassFixture(
    id: 'collocation-hacer-paseo',
    text: 'Ella hizo un paseo.',
    note: 'English-influenced "hacer un paseo" calque.',
    languagePoint: 'Collocations / Strong Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Ella dio un paseo.',
  ),
  TwoPassFixture(
    id: 'collocation-hace-sentido',
    text: 'Esto hace sentido.',
    note: 'English-influenced "hace sentido" calque.',
    languagePoint: 'Collocations / Strong Calques',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Esto tiene sentido.',
  ),

  // --- 12. False Friends / Word Choice — expected owner: either ---
  TwoPassFixture(
    id: 'false-friend-atendio-universidad',
    text: 'Atendió la universidad en Madrid.',
    note: '"atender" is a false friend for "attend"; needs "asistir a".',
    languagePoint: 'False Friends / Word Choice',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Asistió a la universidad en Madrid.',
  ),
  TwoPassFixture(
    id: 'false-friend-aplico-trabajo',
    text: 'Aplicó para un trabajo.',
    note: '"aplicar para" is a false friend for "apply for"; needs '
        '"solicitar".',
    languagePoint: 'False Friends / Word Choice',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Solicitó un trabajo.',
  ),
  TwoPassFixture(
    id: 'false-friend-realice',
    text: 'Realicé que estaba equivocado.',
    note: '"realizar" is a false friend for "realize"; needs "darse '
        'cuenta de".',
    languagePoint: 'False Friends / Word Choice',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Me di cuenta de que estaba equivocado.',
  ),
  TwoPassFixture(
    id: 'false-friend-embarazado',
    text: 'Estoy embarazado por llegar tarde.',
    note: '"embarazado" is a false friend for "embarrassed"; needs "me da '
        'vergüenza".',
    languagePoint: 'False Friends / Word Choice',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.either,
    expectedCorrectedText: 'Me da vergüenza llegar tarde.',
  ),
  TwoPassFixture(
    id: 'false-friend-actualmente-control',
    text: 'Actualmente vivo en Londres.',
    note: 'Already correct: "actualmente" (currently) used correctly here, '
        'not as a false-friend trap for "actually".',
    languagePoint: 'False Friends / Word Choice',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Actualmente vivo en Londres.',
  ),

  // --- 13. Phrase-Level Naturalness — expected owner: naturalness ---
  TwoPassFixture(
    id: 'naturalness-buen-tiempo',
    text: 'Tuvimos un buen tiempo.',
    note: 'English-influenced "tener un buen tiempo" ("had a good time").',
    languagePoint: 'Phrase-Level Naturalness',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.naturalness,
    expectedCorrectedText: 'Lo pasamos bien.',
  ),
  TwoPassFixture(
    id: 'naturalness-corriendo-tarde',
    text: 'Estoy corriendo tarde para la reunión.',
    note: 'English-influenced "corriendo tarde" ("running late").',
    languagePoint: 'Phrase-Level Naturalness',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.naturalness,
    expectedCorrectedText: 'Voy tarde a la reunión.',
  ),
  TwoPassFixture(
    id: 'naturalness-pasar-buen-tiempo',
    text: 'Quiero pasar un buen tiempo.',
    note: 'English-influenced "pasar un buen tiempo" ("have a good time").',
    languagePoint: 'Phrase-Level Naturalness',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.naturalness,
    expectedCorrectedText: 'Quiero pasarlo bien.',
  ),
  TwoPassFixture(
    id: 'naturalness-puedo-tener-cerveza',
    text: '¿Puedo tener una cerveza?',
    note: 'English-influenced "¿puedo tener?" ("can I have?").',
    languagePoint: 'Phrase-Level Naturalness',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.naturalness,
    expectedCorrectedText: '¿Me pones una cerveza?',
  ),
  TwoPassFixture(
    id: 'naturalness-llamar-para-atras',
    text: 'Te llamo para atrás.',
    note: 'English-influenced "llamar para atrás" ("call back").',
    languagePoint: 'Phrase-Level Naturalness',
    operationType: TwoPassOperationType.replacement,
    expectedOwner: TwoPassExpectedOwner.naturalness,
    expectedCorrectedText: 'Te devuelvo la llamada.',
  ),

  // --- 14. Valid Regional / Should Not Flag — expected owner: no pass ---
  TwoPassFixture(
    id: 'regional-voy-para-casa',
    text: 'Voy para casa ahora mismo.',
    note: 'Valid regional Spanish ("para casa"); must not be flagged.',
    languagePoint: 'Valid Regional / Should Not Flag',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Voy para casa ahora mismo.',
  ),
  TwoPassFixture(
    id: 'regional-vos-tenes',
    text: 'Vos tenés razón.',
    note: 'Valid Rioplatense voseo; must not be flagged.',
    languagePoint: 'Valid Regional / Should Not Flag',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Vos tenés razón.',
  ),
  TwoPassFixture(
    id: 'regional-cojo-autobus',
    text: 'Cojo el autobús cada mañana.',
    note: 'Valid Peninsular "coger"; must not be flagged.',
    languagePoint: 'Valid Regional / Should Not Flag',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Cojo el autobús cada mañana.',
  ),
  TwoPassFixture(
    id: 'regional-preterite-esta-manana',
    text: 'Esta mañana hablé con mi jefe.',
    note: 'Valid preterite-for-recent-past regional usage; must not be '
        'flagged.',
    languagePoint: 'Valid Regional / Should Not Flag',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Esta mañana hablé con mi jefe.',
  ),
  TwoPassFixture(
    id: 'regional-dale',
    text: 'Dale, nos vemos más tarde.',
    note: 'Valid colloquial "dale"; must not be flagged.',
    languagePoint: 'Valid Regional / Should Not Flag',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Dale, nos vemos más tarde.',
  ),

  // --- 15. Already Correct / Do Not Tinker — expected owner: no pass ---
  TwoPassFixture(
    id: 'correct-buenos-dias',
    text: 'Buenos días, ¿cómo estás?',
    note: 'Already correct; must not be tinkered with.',
    languagePoint: 'Already Correct / Do Not Tinker',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Buenos días, ¿cómo estás?',
  ),
  TwoPassFixture(
    id: 'correct-hacer-pregunta',
    text: 'Voy a hacer una pregunta al profesor.',
    note: 'Already correct ("hacer una pregunta" is standard, unlike '
        '"hacer una decisión"); must not be tinkered with.',
    languagePoint: 'Already Correct / Do Not Tinker',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Voy a hacer una pregunta al profesor.',
  ),
  TwoPassFixture(
    id: 'correct-tomar-foto',
    text: 'Necesito tomar una foto del documento.',
    note: 'Already correct; must not be tinkered with.',
    languagePoint: 'Already Correct / Do Not Tinker',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Necesito tomar una foto del documento.',
  ),
  TwoPassFixture(
    id: 'correct-visitar-abuela',
    text: 'Mañana visitaré a mi abuela.',
    note: 'Already correct; must not be tinkered with.',
    languagePoint: 'Already Correct / Do Not Tinker',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Mañana visitaré a mi abuela.',
  ),
  TwoPassFixture(
    id: 'correct-me-quedo-en-casa',
    text: 'Está lloviendo, así que me quedo en casa.',
    note: 'Already correct; must not be tinkered with.',
    languagePoint: 'Already Correct / Do Not Tinker',
    operationType: TwoPassOperationType.noChange,
    expectedOwner: TwoPassExpectedOwner.noChange,
    expectedCorrectedText: 'Está lloviendo, así que me quedo en casa.',
  ),

  // --- 16. Mixed Operations — expected owner: first pass ---
  // Synthesized (not a row in the language-point map itself) to give this
  // benchmark genuine TwoPassOperationType.mixed coverage: each fixture
  // splices two already-vetted single-operation-type sentences from other
  // groups above into one input, so both operations must be corrected in
  // the same pass.
  TwoPassFixture(
    id: 'mixed-preposition-and-redundant-pronoun',
    text:
        'Insisto que revises el contrato, y yo trabajo mucho y yo estudio '
        'por las noches.',
    note: 'Combines a required-preposition insertion ("insisto en que") '
        'with a redundant repeated-pronoun deletion (second "yo").',
    languagePoint: 'Mixed Operations',
    operationType: TwoPassOperationType.mixed,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText:
        'Insisto en que revises el contrato, y yo trabajo mucho y estudio '
        'por las noches.',
  ),
  TwoPassFixture(
    id: 'mixed-article-and-accent',
    text: 'Necesito comprar libro para la clase, y compre cafe en una '
        'cafeteria pequena.',
    note: 'Combines a missing-article insertion ("un libro") with missing '
        'accents ("compré", "café", "cafetería", "pequeña").',
    languagePoint: 'Mixed Operations',
    operationType: TwoPassOperationType.mixed,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText:
        'Necesito comprar un libro para la clase, y compré café en una '
        'cafetería pequeña.',
  ),
  TwoPassFixture(
    id: 'mixed-personal-a-and-subjunctive',
    text: 'Vi mi profesor en la estación, y es importante que estudias.',
    note: 'Combines a missing personal-"a" insertion with a subjunctive-'
        'mood replacement ("estudias" -> "estudies").',
    languagePoint: 'Mixed Operations',
    operationType: TwoPassOperationType.mixed,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText:
        'Vi a mi profesor en la estación, y es importante que estudies.',
  ),
  TwoPassFixture(
    id: 'mixed-gender-agreement-and-redundant-pronoun',
    text: 'Las ventanas estaban abierto, y a mí me gusta el café a mí.',
    note: 'Combines a gender-agreement replacement ("abierto" -> '
        '"abiertas") with a redundant-pronoun deletion (trailing "a mí").',
    languagePoint: 'Mixed Operations',
    operationType: TwoPassOperationType.mixed,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText:
        'Las ventanas estaban abiertas, y a mí me gusta el café.',
  ),
  TwoPassFixture(
    id: 'mixed-verb-agreement-and-missing-que',
    text: 'Ellos estudia todas las noches, y creo está bien terminar hoy.',
    note: 'Combines a verb-agreement replacement ("estudia" -> "estudian") '
        'with a missing-connector insertion ("creo que").',
    languagePoint: 'Mixed Operations',
    operationType: TwoPassOperationType.mixed,
    expectedOwner: TwoPassExpectedOwner.firstPass,
    expectedCorrectedText:
        'Ellos estudian todas las noches, y creo que está bien terminar '
        'hoy.',
  ),
];

/// The full executable benchmark set this harness can run: the original
/// small smoke-test fixtures plus the full language-point matrix (issue
/// #82). [twoPassIntegrationFixtures] stays available on its own as a
/// smaller, faster smoke subset — see that list's own doc comment.
const List<TwoPassFixture> allTwoPassFixtures = [
  ...twoPassIntegrationFixtures,
  ...languagePointBenchmarkFixtures,
];

const String _defaultFirstPassModel = 'gpt-4.1';
const String _defaultNaturalnessModel = 'gpt-5.1';
const String defaultTwoPassOutputPath =
    'docs/two_pass_integration_harness.md';

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'TWO_PASS_LIVE',
  defaultValue: false,
);

/// Parses `TWO_PASS_CALL_DELAY_MS` from [environment] (a real environment
/// variable, e.g. `TWO_PASS_CALL_DELAY_MS=2000 flutter test ...`) — not
/// `int.fromEnvironment`, which only ever reads a compile-time
/// `--dart-define` value and would silently ignore the environment
/// variable this file's own header comment documents. Falls back to `750`
/// when unset or unparsable, same default as before.
int callDelayMsFrom(Map<String, String> environment) {
  final raw = _runtimeString(
    environment: environment,
    key: 'TWO_PASS_CALL_DELAY_MS',
    defaultValue: '750',
  );
  return int.tryParse(raw) ?? 750;
}

String _runtimeString({
  required Map<String, String> environment,
  required String key,
  required String defaultValue,
}) {
  final fromEnvironment = environment[key]?.trim() ?? '';
  if (fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }
  return defaultValue;
}

bool _liveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      (environment['TWO_PASS_LIVE']?.trim().toLowerCase() == 'true');
}

/// Latency/token/cost totals for one logical phase of one fixture (the
/// first pass, naturalness-on-original, or naturalness-on-first-pass).
class CallStats {
  const CallStats({
    required this.wallClockMs,
    required this.totalTokens,
    required this.costUsd,
  });

  /// Wall-clock time for the whole phase, not the sum of individual API
  /// call latencies — kept distinct from a simple token/call sum since a
  /// phase can in general span more than one API call.
  final int wallClockMs;
  final int totalTokens;

  /// Null when the model has no verified pricing entry — see
  /// `test/shared/model_pricing.dart`.
  final double? costUsd;

  static const CallStats zero = CallStats(
    wallClockMs: 0,
    totalTokens: 0,
    costUsd: 0,
  );

  CallStats operator +(CallStats other) {
    final otherCost = other.costUsd;
    final thisCost = costUsd;
    return CallStats(
      wallClockMs: wallClockMs + other.wallClockMs,
      totalTokens: totalTokens + other.totalTokens,
      costUsd: (thisCost == null || otherCost == null)
          ? null
          : thisCost + otherCost,
    );
  }
}

/// Sums the [ChatCompletionsUsage] records a single phase produced (an
/// exact slice of the shared usage log, taken by the caller) into one
/// [CallStats], estimating cost from the phase's own model — every usage
/// record in one phase shares the same model, since a phase only ever
/// calls one model.
CallStats statsFor(List<ChatCompletionsUsage> usages, {required int wallClockMs}) {
  var totalTokens = 0;
  var inputTokens = 0;
  var outputTokens = 0;
  String? model;
  for (final usage in usages) {
    totalTokens += usage.totalTokens ?? 0;
    inputTokens += usage.promptTokens ?? 0;
    outputTokens += usage.completionTokens ?? 0;
    model ??= usage.model;
  }
  final cost = model == null
      ? const pricing.CostEstimate.unknown()
      : pricing.estimateCostUsd(
          model: model,
          inputTokens: inputTokens,
          outputTokens: outputTokens,
        );
  return CallStats(
    wallClockMs: wallClockMs,
    totalTokens: totalTokens,
    costUsd: cost.usd,
  );
}

/// Full per-fixture result: every value in the "Compare" list issue #42
/// asks for, for one fixture — or, when the live run for this fixture
/// threw (a malformed model response, a network failure, etc.),
/// [errorMessage] instead. One fixture's failure must never take down the
/// whole experiment or lose the data already gathered for every other
/// fixture — see the try/catch around [runFixture] in the live test below.
class FixtureResult {
  const FixtureResult({
    required this.fixture,
    required this.firstPassCorrectedText,
    required this.firstPassStats,
    required this.naturalnessOnOriginal,
    required this.naturalnessOnOriginalStats,
    required this.naturalnessOnFirstPass,
    required this.naturalnessOnFirstPassStats,
    required this.hadConflict,
    required this.usedFallback,
    required this.finalCorrectedText,
    required this.finalCorrectionCount,
    this.errorMessage,
  });

  /// [partialStats] is whatever latency/token/cost was already spent on
  /// real API calls before the failure — e.g. the first pass can succeed
  /// (and spend real tokens) before a later naturalness call fails to
  /// parse. Defaults to [CallStats.zero] for a failure before any call
  /// went out at all. Reported as [firstPassStats] here so it still shows
  /// up in the report and the overall summary's totals, rather than
  /// silently disappearing as an unreported $0.
  factory FixtureResult.error(
    TwoPassFixture fixture,
    String message, {
    CallStats partialStats = CallStats.zero,
  }) {
    const emptyReview = NaturalnessReview(
      hasNaturalnessIssue: false,
      issues: [],
    );
    return FixtureResult(
      fixture: fixture,
      firstPassCorrectedText: '',
      firstPassStats: partialStats,
      naturalnessOnOriginal: emptyReview,
      naturalnessOnOriginalStats: CallStats.zero,
      naturalnessOnFirstPass: emptyReview,
      naturalnessOnFirstPassStats: CallStats.zero,
      hadConflict: false,
      usedFallback: false,
      finalCorrectedText: '',
      finalCorrectionCount: 0,
      errorMessage: message,
    );
  }

  final TwoPassFixture fixture;
  final String firstPassCorrectedText;
  final CallStats firstPassStats;
  final NaturalnessReview naturalnessOnOriginal;
  final CallStats naturalnessOnOriginalStats;
  final NaturalnessReview naturalnessOnFirstPass;
  final CallStats naturalnessOnFirstPassStats;
  final bool hadConflict;
  final bool usedFallback;
  final String finalCorrectedText;
  final int finalCorrectionCount;
  final String? errorMessage;

  bool get isError => errorMessage != null;

  CallStats get totalStats =>
      firstPassStats + naturalnessOnOriginalStats + naturalnessOnFirstPassStats;
}

/// Benchmark outcome labels for one fixture's result (issue #83), matching
/// `docs/two_pass_language_point_test_map.md`'s "Scoring Labels" table —
/// see that doc for each label's intended meaning; [scoreFixtureResult]
/// below computes them mechanically where that's honest to do, and falls
/// back to [ambiguous] rather than guessing where it isn't.
enum TwoPassScoreLabel {
  correctFix,
  partialFix,
  missedIssue,
  overcorrection,
  acceptableNoChange,
  ambiguous,
  error,
}

extension TwoPassScoreLabelReportName on TwoPassScoreLabel {
  /// The external benchmark label this score maps to — issue #83's own
  /// "Required labels" list and `docs/two_pass_language_point_test_map.md`'s
  /// "Scoring Labels" table, both snake_case (`correct_fix`, not this
  /// enum's own Dart identifier name, which `.name` would render as
  /// `correctFix`). Reports must use this, not `.name`, so a generated
  /// report actually matches the documented taxonomy.
  String get reportLabel {
    switch (this) {
      case TwoPassScoreLabel.correctFix:
        return 'correct_fix';
      case TwoPassScoreLabel.partialFix:
        return 'partial_fix';
      case TwoPassScoreLabel.missedIssue:
        return 'missed_issue';
      case TwoPassScoreLabel.overcorrection:
        return 'overcorrection';
      case TwoPassScoreLabel.acceptableNoChange:
        return 'acceptable_no_change';
      case TwoPassScoreLabel.ambiguous:
        return 'ambiguous';
      case TwoPassScoreLabel.error:
        return 'error';
    }
  }
}

/// Scores [result] against its own fixture's expected output.
///
/// Deliberately mechanical, not semantic — this is a "small" scoring
/// model (per issue #83's own scope), not a second correction engine:
///
/// - [TwoPassScoreLabel.error]: [result] itself failed
///   ([FixtureResult.isError]) — reported as a benchmark outcome, not a
///   crash (a fixture's failure never prevents scoring every other one;
///   see [runFixture]'s own per-fixture try/catch).
/// - For a [TwoPassOperationType.noChange] fixture (no fix expected):
///   [TwoPassScoreLabel.acceptableNoChange] when the final text matches
///   the input verbatim, else [TwoPassScoreLabel.overcorrection] — this
///   is the one case this scorer labels overcorrection with full
///   confidence, matching the label's own definition ("changed acceptable
///   Spanish unnecessarily") exactly.
/// - Otherwise (a real fix is expected):
///   - [TwoPassScoreLabel.correctFix] when the final text matches
///     [TwoPassFixture.expectedCorrectedText] exactly, or any of
///     [TwoPassFixture.acceptableAlternatives] exactly — no partial
///     credit is required where an alternative is supplied (per this
///     issue's own out-of-scope note).
///   - [TwoPassScoreLabel.missedIssue] when the final text is identical
///     to the original input — a fix was expected and nothing happened.
///   - Otherwise, something changed but didn't match the expected output
///     or any alternative. This scorer does not attempt to distinguish a
///     genuine partial fix from a wrong-direction change by semantic
///     judgment — that would force false precision a string comparison
///     can't honestly back up. It uses one cheap, defensible signal
///     instead: grapheme-level Levenshtein distance from the final text
///     to the expected text, compared against the same distance from the
///     *original* text to the expected text.
///     - Strictly closer than the original was ->
///       [TwoPassScoreLabel.partialFix] — measurable, if incomplete,
///       progress toward the expected fix.
///     - Not strictly closer (same distance, or farther) ->
///       [TwoPassScoreLabel.ambiguous] — the model changed something, but
///       this scorer has no honest basis to call that progress, a wrong
///       fix, or a valid alternative nobody has listed yet. A human
///       reviewer (or a specific [acceptableAlternatives] addition) is
///       the right way to resolve one of these, not a guessed label.
TwoPassScoreLabel scoreFixtureResult(FixtureResult result) {
  if (result.isError) {
    return TwoPassScoreLabel.error;
  }

  final fixture = result.fixture;
  final actual = result.finalCorrectedText;

  if (fixture.operationType == TwoPassOperationType.noChange) {
    return actual == fixture.text
        ? TwoPassScoreLabel.acceptableNoChange
        : TwoPassScoreLabel.overcorrection;
  }

  if (actual == fixture.expectedCorrectedText ||
      fixture.acceptableAlternatives.contains(actual)) {
    return TwoPassScoreLabel.correctFix;
  }

  if (actual == fixture.text) {
    return TwoPassScoreLabel.missedIssue;
  }

  final distanceFromActual = _levenshteinDistance(
    actual,
    fixture.expectedCorrectedText,
  );
  final distanceFromOriginal = _levenshteinDistance(
    fixture.text,
    fixture.expectedCorrectedText,
  );
  return distanceFromActual < distanceFromOriginal
      ? TwoPassScoreLabel.partialFix
      : TwoPassScoreLabel.ambiguous;
}

/// Grapheme-cluster-safe Levenshtein (edit) distance between [a] and [b] —
/// operates on `characters`, not UTF-16 code units, so combining accents
/// and other multi-code-unit Spanish characters each count as one edit
/// position, consistent with how the rest of this codebase treats
/// user-perceived characters (see e.g. `correction_item.dart`).
int _levenshteinDistance(String a, String b) {
  final aChars = a.characters.toList();
  final bChars = b.characters.toList();

  var previousRow = List<int>.generate(bChars.length + 1, (j) => j);
  for (var i = 1; i <= aChars.length; i++) {
    final currentRow = List<int>.filled(bChars.length + 1, 0);
    currentRow[0] = i;
    for (var j = 1; j <= bChars.length; j++) {
      if (aChars[i - 1] == bChars[j - 1]) {
        currentRow[j] = previousRow[j - 1];
      } else {
        currentRow[j] =
            1 +
            min(previousRow[j], min(currentRow[j - 1], previousRow[j - 1]));
      }
    }
    previousRow = currentRow;
  }
  return previousRow[bChars.length];
}

/// Runs the full comparison for one fixture: first pass
/// (`callFirstPassCorrection`, the narrow simple first-pass client — issue
/// #68), naturalness on the original text, naturalness on the first
/// pass's own corrected text, the parallel merge (to determine whether a
/// conflict exists), and —
/// only when a conflict exists, matching runTwoPassCorrectionPipeline's
/// own fallback-trigger condition — the fallback merge using the
/// naturalness-on-first-pass result already fetched above.
///
/// If any call fails partway through (a malformed model response, a
/// network error), whatever latency/tokens/cost was spent before the
/// failure is preserved — see [FixtureResult.error]'s `partialStats` —
/// rather than silently discarded, so the report's totals still reflect
/// real money spent even on a fixture that ultimately failed. Critically,
/// this includes the *failing* call's own spend, not just earlier calls
/// that fully succeeded: a naturalness call can get a valid, billed HTTP
/// response (recorded in [usageLog] the moment it arrives) and only then
/// throw while parsing that response's JSON — see [_trackedCall], which
/// records a phase's stats in a `finally` block so that always happens,
/// on success or failure alike, rather than only after an `await`
/// expression that might never finish normally.
Future<FixtureResult> runFixture({
  required OpenAiChatCompletionsClient client,
  required List<ChatCompletionsUsage> usageLog,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
}) async {
  var firstPassStats = CallStats.zero;
  var naturalOriginalStats = CallStats.zero;
  var naturalFirstPassStats = CallStats.zero;

  try {
    final firstPassResponse = await _trackedCall(
      usageLog,
      () => callFirstPassCorrection(
        client: client,
        model: firstPassModel,
        submittedText: fixture.text,
      ),
      onStats: (stats) => firstPassStats = stats,
    );

    final naturalnessOnOriginal = await _trackedCall(
      usageLog,
      () => callNaturalnessReview(
        client: client,
        model: naturalnessModel,
        text: fixture.text,
      ),
      onStats: (stats) => naturalOriginalStats = stats,
    );

    final naturalnessOnFirstPass = await _trackedCall(
      usageLog,
      () => callNaturalnessReview(
        client: client,
        model: naturalnessModel,
        text: firstPassResponse.correctedText,
      ),
      onStats: (stats) => naturalFirstPassStats = stats,
    );

    final parallelMerge = mergeNaturalnessReview(
      originalText: fixture.text,
      firstPassCorrectedText: firstPassResponse.correctedText,
      naturalnessReview: naturalnessOnOriginal,
    );
    final hadConflict = parallelMerge.skippedEdits.isNotEmpty;

    final finalMerge = hadConflict
        ? mergeNaturalnessReview(
            originalText: fixture.text,
            firstPassCorrectedText: firstPassResponse.correctedText,
            naturalnessReview: naturalnessOnFirstPass,
          )
        : parallelMerge;

    final finalResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: finalMerge,
    );

    return FixtureResult(
      fixture: fixture,
      firstPassCorrectedText: firstPassResponse.correctedText,
      firstPassStats: firstPassStats,
      naturalnessOnOriginal: naturalnessOnOriginal,
      naturalnessOnOriginalStats: naturalOriginalStats,
      naturalnessOnFirstPass: naturalnessOnFirstPass,
      naturalnessOnFirstPassStats: naturalFirstPassStats,
      hadConflict: hadConflict,
      usedFallback: hadConflict,
      finalCorrectedText: finalResponse.correctedText,
      finalCorrectionCount: finalResponse.corrections.length,
    );
  } catch (error) {
    return FixtureResult.error(
      fixture,
      error.toString(),
      partialStats: firstPassStats + naturalOriginalStats + naturalFirstPassStats,
    );
  }
}

/// Runs [call], recording its [CallStats] (wall-clock latency plus every
/// [ChatCompletionsUsage] logged to [usageLog] during the call) via
/// [onStats] — always, whether [call] completes normally or throws. Using
/// `finally` rather than only recording stats after a successful `await`
/// is what lets a phase that gets a valid, billed API response and then
/// throws while parsing it (the exact failure mode this harness's live
/// runs hit before issue #63's fix) still have its spend accounted for.
Future<T> _trackedCall<T>(
  List<ChatCompletionsUsage> usageLog,
  Future<T> Function() call, {
  required void Function(CallStats stats) onStats,
}) async {
  final stopwatch = Stopwatch()..start();
  final start = usageLog.length;
  try {
    return await call();
  } finally {
    stopwatch.stop();
    onStats(
      statsFor(
        usageLog.sublist(start),
        wallClockMs: stopwatch.elapsedMilliseconds,
      ),
    );
  }
}

String _describeReview(NaturalnessReview review) {
  if (!review.hasNaturalnessIssue) {
    return '(none)';
  }
  return review.issues
      .map((issue) => '${issue.span} -> ${issue.naturalReplacement}')
      .join('<br>');
}

String _formatCost(double? usd) =>
    usd == null ? 'unknown' : '\$${usd.toStringAsFixed(6)}';

/// Builds the full markdown report for [results], in the same style as
/// this repo's other harness reports.
String buildReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<FixtureResult> results,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# Two-Pass Live Integration Harness')
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln(
      '- Pass 1: `callFirstPassCorrection` — the simple, narrow '
      '`corrected_text`-only first-pass client (issue #68/#65), not the '
      'old broad `runStagedCorrectionPipeline`.',
    )
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixture count: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(pricing.pricingSection([firstPassModel, naturalnessModel]));

  for (final result in results) {
    if (result.isError) {
      buffer
        ..writeln('## ${result.fixture.id}')
        ..writeln()
        ..writeln('- Input text: `${result.fixture.text}`')
        ..writeln('- Note: ${result.fixture.note}')
        ..writeln('- Language point: ${result.fixture.languagePoint}')
        ..writeln(
          '- Operation type: ${result.fixture.operationType.name}',
        )
        ..writeln('- Expected owner: ${result.fixture.expectedOwner.name}')
        ..writeln(
          '- Expected corrected text: '
          '`${result.fixture.expectedCorrectedText}`',
        )
        ..writeln('- Score: ${scoreFixtureResult(result).reportLabel}')
        ..writeln('- **ERROR**: ${result.errorMessage}');
      if (result.totalStats.totalTokens > 0) {
        buffer.writeln(
          '- Spent before the failure: '
          '${result.totalStats.wallClockMs} ms, '
          '${result.totalStats.totalTokens} tokens, '
          '${_formatCost(result.totalStats.costUsd)}',
        );
      }
      buffer.writeln();
      continue;
    }

    buffer
      ..writeln('## ${result.fixture.id}')
      ..writeln()
      ..writeln('- Input text: `${result.fixture.text}`')
      ..writeln('- Note: ${result.fixture.note}')
      ..writeln('- Language point: ${result.fixture.languagePoint}')
      ..writeln('- Operation type: ${result.fixture.operationType.name}')
      ..writeln('- Expected owner: ${result.fixture.expectedOwner.name}')
      ..writeln(
        '- Expected corrected text: '
        '`${result.fixture.expectedCorrectedText}`',
      );
    if (result.fixture.acceptableAlternatives.isNotEmpty) {
      buffer.writeln(
        '- Acceptable alternatives: '
        '${result.fixture.acceptableAlternatives.map((a) => '`$a`').join(', ')}',
      );
    }
    buffer
      ..writeln(
        '- First-pass corrected text: `${result.firstPassCorrectedText}`',
      )
      ..writeln(
        '- Naturalness on original text: '
        '${_describeReview(result.naturalnessOnOriginal)}',
      )
      ..writeln(
        '- Naturalness on first-pass corrected text: '
        '${_describeReview(result.naturalnessOnFirstPass)}',
      )
      ..writeln('- Conflict (parallel merge had a skipped edit): '
          '${result.hadConflict}')
      ..writeln('- Fallback used: ${result.usedFallback}')
      ..writeln('- Final merged output: `${result.finalCorrectedText}`')
      ..writeln('- Final correction count: ${result.finalCorrectionCount}')
      ..writeln('- Score: ${scoreFixtureResult(result).reportLabel}')
      ..writeln()
      ..writeln(
        '| Phase | Latency (ms) | Total tokens | Est. cost (USD) |',
      )
      ..writeln('| --- | --- | --- | --- |')
      ..writeln(
        '| First pass | ${result.firstPassStats.wallClockMs} | '
        '${result.firstPassStats.totalTokens} | '
        '${_formatCost(result.firstPassStats.costUsd)} |',
      )
      ..writeln(
        '| Naturalness (original) | '
        '${result.naturalnessOnOriginalStats.wallClockMs} | '
        '${result.naturalnessOnOriginalStats.totalTokens} | '
        '${_formatCost(result.naturalnessOnOriginalStats.costUsd)} |',
      )
      ..writeln(
        '| Naturalness (first-pass corrected) | '
        '${result.naturalnessOnFirstPassStats.wallClockMs} | '
        '${result.naturalnessOnFirstPassStats.totalTokens} | '
        '${_formatCost(result.naturalnessOnFirstPassStats.costUsd)} |',
      )
      ..writeln(
        '| **Total** | ${result.totalStats.wallClockMs} | '
        '${result.totalStats.totalTokens} | '
        '${_formatCost(result.totalStats.costUsd)} |',
      )
      ..writeln();
  }

  final errorCount = results.where((r) => r.isError).length;
  final conflictCount = results.where((r) => r.hadConflict).length;
  final fallbackCount = results.where((r) => r.usedFallback).length;
  final totalLatencyMs = results.fold<int>(
    0,
    (sum, r) => sum + r.totalStats.wallClockMs,
  );
  final totalTokens = results.fold<int>(
    0,
    (sum, r) => sum + r.totalStats.totalTokens,
  );
  // Applies uniformly to error and non-error results alike: a result
  // whose partial spend used a model with no verified pricing is
  // "unknown", not $0 — regardless of whether that fixture went on to
  // fail.
  final anyUnknownCost = results.any((r) => r.totalStats.costUsd == null);
  final totalCostUsd = anyUnknownCost
      ? null
      : results.fold<double>(0, (sum, r) => sum + (r.totalStats.costUsd ?? 0));

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Fixtures | Errors | Conflicts | Fallbacks used | '
        'Total latency (ms) | Total tokens | Total est. cost (USD) |')
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |')
    ..writeln(
      '| ${results.length} | $errorCount | $conflictCount | $fallbackCount | '
      '$totalLatencyMs | $totalTokens | ${_formatCost(totalCostUsd)} |',
    )
    ..writeln()
    ..writeln('### Score summary')
    ..writeln()
    ..writeln('| Score | Count |')
    ..writeln('| --- | --- |');

  final scoreCounts = <TwoPassScoreLabel, int>{};
  for (final result in results) {
    final label = scoreFixtureResult(result);
    scoreCounts[label] = (scoreCounts[label] ?? 0) + 1;
  }
  for (final label in TwoPassScoreLabel.values) {
    final count = scoreCounts[label] ?? 0;
    if (count > 0) {
      buffer.writeln('| ${label.reportLabel} | $count |');
    }
  }

  return buffer.toString();
}

/// Builds a minimal, all-zero-stats [FixtureResult] for [fixture] whose
/// only fixture-scoring-relevant field is [finalCorrectedText] — a test
/// helper for [scoreFixtureResult], not a stand-in for [runFixture]'s own
/// real behavior.
FixtureResult _fakeResult(
  TwoPassFixture fixture, {
  required String finalCorrectedText,
}) {
  const emptyReview = NaturalnessReview(hasNaturalnessIssue: false, issues: []);
  return FixtureResult(
    fixture: fixture,
    firstPassCorrectedText: finalCorrectedText,
    firstPassStats: CallStats.zero,
    naturalnessOnOriginal: emptyReview,
    naturalnessOnOriginalStats: CallStats.zero,
    naturalnessOnFirstPass: emptyReview,
    naturalnessOnFirstPassStats: CallStats.zero,
    hadConflict: false,
    usedFallback: false,
    finalCorrectedText: finalCorrectedText,
    finalCorrectionCount: 0,
  );
}

void main() {
  group('offline sanity (no API calls)', () {
    test('fixture ids are unique', () {
      final ids = allTwoPassFixtures.map((f) => f.id).toSet();
      expect(ids.length, allTwoPassFixtures.length);
    });

    test(
      'every language-point group has exactly five fixtures (issue #82)',
      () {
        final byLanguagePoint = <String, int>{};
        for (final fixture in languagePointBenchmarkFixtures) {
          byLanguagePoint[fixture.languagePoint] =
              (byLanguagePoint[fixture.languagePoint] ?? 0) + 1;
        }
        for (final entry in byLanguagePoint.entries) {
          expect(
            entry.value,
            5,
            reason:
                '"${entry.key}" has ${entry.value} fixtures, expected 5',
          );
        }
      },
    );

    test(
      'the language-point benchmark represents every operation type '
      '(issue #82)',
      () {
        final represented = languagePointBenchmarkFixtures
            .map((f) => f.operationType)
            .toSet();
        expect(represented, TwoPassOperationType.values.toSet());
      },
    );

    test(
      'every fixture carries required benchmark metadata (issue #81)',
      () {
        for (final fixture in allTwoPassFixtures) {
          expect(
            fixture.languagePoint,
            isNotEmpty,
            reason: '${fixture.id} is missing a languagePoint',
          );
          expect(
            fixture.note,
            isNotEmpty,
            reason: '${fixture.id} is missing a note',
          );
          expect(
            fixture.expectedCorrectedText,
            isNotEmpty,
            reason: '${fixture.id} is missing an expectedCorrectedText',
          );
        }
      },
    );

    test(
      'a noChange operation type always expects the input text unchanged '
      '(issue #81)',
      () {
        for (final fixture in allTwoPassFixtures) {
          if (fixture.operationType == TwoPassOperationType.noChange) {
            expect(
              fixture.expectedCorrectedText,
              fixture.text,
              reason:
                  '${fixture.id} is tagged noChange but expects a '
                  'different corrected text',
            );
          }
        }
      },
    );

    test(
      'TwoPassOperationType distinguishes replacement, insertion, '
      'deletion, mixed, and no-change (issue #81)',
      () {
        expect(TwoPassOperationType.values.toSet(), {
          TwoPassOperationType.replacement,
          TwoPassOperationType.insertion,
          TwoPassOperationType.deletion,
          TwoPassOperationType.mixed,
          TwoPassOperationType.noChange,
        });
      },
    );

    test(
      'TwoPassExpectedOwner distinguishes first pass, naturalness, '
      'either, and no-change (issue #81)',
      () {
        expect(TwoPassExpectedOwner.values.toSet(), {
          TwoPassExpectedOwner.firstPass,
          TwoPassExpectedOwner.naturalness,
          TwoPassExpectedOwner.either,
          TwoPassExpectedOwner.noChange,
        });
      },
    );

    group('scoreFixtureResult (issue #83)', () {
      test('correctFix: final text matches expectedCorrectedText exactly', () {
        final fixture = languagePointBenchmarkFixtures.firstWhere(
          (f) => f.id == 'accent-manana',
        );
        final result = _fakeResult(
          fixture,
          finalCorrectedText: fixture.expectedCorrectedText,
        );
        expect(scoreFixtureResult(result), TwoPassScoreLabel.correctFix);
      });

      test(
        'correctFix: final text matches an acceptable alternative, not '
        'the primary expected text',
        () {
          const fixture = TwoPassFixture(
            id: 'score-test-alternative',
            text: 'Ella tomó una reunión.',
            note: 'Synthetic fixture for scorer unit test.',
            languagePoint: 'Test',
            operationType: TwoPassOperationType.replacement,
            expectedOwner: TwoPassExpectedOwner.either,
            expectedCorrectedText: 'Ella tuvo una reunión.',
            acceptableAlternatives: ['Ella se reunió.'],
          );
          final result = _fakeResult(
            fixture,
            finalCorrectedText: 'Ella se reunió.',
          );
          expect(scoreFixtureResult(result), TwoPassScoreLabel.correctFix);
        },
      );

      test(
        'missedIssue: a fix was expected but the final text is identical '
        'to the input',
        () {
          final fixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'accent-manana',
          );
          final result = _fakeResult(fixture, finalCorrectedText: fixture.text);
          expect(scoreFixtureResult(result), TwoPassScoreLabel.missedIssue);
        },
      );

      test(
        'acceptableNoChange: no fix was expected and the final text is '
        'unchanged',
        () {
          final fixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'estar-contento',
          );
          final result = _fakeResult(fixture, finalCorrectedText: fixture.text);
          expect(
            scoreFixtureResult(result),
            TwoPassScoreLabel.acceptableNoChange,
          );
        },
      );

      test(
        'overcorrection: no fix was expected but the final text changed '
        'anyway',
        () {
          final fixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'estar-contento',
          );
          final result = _fakeResult(
            fixture,
            finalCorrectedText: 'Estoy contentísimo con el resultado.',
          );
          expect(scoreFixtureResult(result), TwoPassScoreLabel.overcorrection);
        },
      );

      test(
        'partialFix: the final text is strictly closer to the expected '
        'text than the original input was',
        () {
          // Expected fixes both "niño" -> "niños" and "manzana" ->
          // "manzanas" (and "come" -> "comen"); this final text only
          // fixes the noun/article agreement, leaving the verb
          // unfixed — a real but incomplete improvement, strictly closer
          // to expectedCorrectedText than the original input was.
          final fixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'agreement-ninos-manzanas',
          );
          final result = _fakeResult(
            fixture,
            finalCorrectedText: 'Los niños come muchas manzanas.',
          );
          expect(scoreFixtureResult(result), TwoPassScoreLabel.partialFix);
        },
      );

      test(
        'ambiguous: the final text changed but is not measurably closer '
        'to the expected text than the original input was',
        () {
          // Synthetic short strings, chosen so the edit distance is exact
          // and easy to verify by hand: 'abc' -> expected 'xyz' is
          // distance 3 (all three positions differ); 'qqc' -> 'xyz' is
          // also distance 3 (three substitutions) — not strictly closer.
          const fixture = TwoPassFixture(
            id: 'score-test-ambiguous',
            text: 'abc',
            note: 'Synthetic fixture for scorer unit test.',
            languagePoint: 'Test',
            operationType: TwoPassOperationType.replacement,
            expectedOwner: TwoPassExpectedOwner.firstPass,
            expectedCorrectedText: 'xyz',
          );
          final result = _fakeResult(fixture, finalCorrectedText: 'qqc');
          expect(scoreFixtureResult(result), TwoPassScoreLabel.ambiguous);
        },
      );

      test(
        'error: a failed fixture is scored as a benchmark outcome, not a '
        'crash',
        () {
          final fixture = languagePointBenchmarkFixtures.first;
          final result = FixtureResult.error(fixture, 'boom');
          expect(scoreFixtureResult(result), TwoPassScoreLabel.error);
        },
      );
    });

    test(
      'callDelayMsFrom reads a real environment variable, not just '
      '--dart-define',
      () {
        expect(
          callDelayMsFrom(const {'TWO_PASS_CALL_DELAY_MS': '2000'}),
          2000,
        );
        expect(callDelayMsFrom(const {}), 750);
        expect(
          callDelayMsFrom(const {'TWO_PASS_CALL_DELAY_MS': 'not-a-number'}),
          750,
        );
      },
    );

    test(
      '_trackedCall records stats via onStats even when the call throws '
      'after usage was already logged — the exact failure mode this '
      'harness\'s live runs hit: a valid, billed API response that only '
      'fails to parse afterward',
      () async {
        final usageLog = <ChatCompletionsUsage>[];
        CallStats? captured;

        await expectLater(
          () => _trackedCall(
            usageLog,
            () async {
              usageLog.add(
                const ChatCompletionsUsage(
                  stageLabel: 'naturalness_review',
                  model: 'gpt-5.1',
                  latencyMs: 500,
                  promptTokens: 200,
                  completionTokens: 100,
                  totalTokens: 300,
                ),
              );
              throw const FormatException(
                'Naturalness review is missing "has_naturalness_issue".',
              );
            },
            onStats: (stats) => captured = stats,
          ),
          throwsFormatException,
        );

        expect(captured, isNotNull);
        expect(captured!.totalTokens, 300);
        expect(captured!.costUsd, isNotNull);
      },
    );

    test(
      '_trackedCall records stats on success too, unaffected by adding '
      'failure-path support',
      () async {
        final usageLog = <ChatCompletionsUsage>[];
        CallStats? captured;

        final result = await _trackedCall(
          usageLog,
          () async {
            usageLog.add(
              const ChatCompletionsUsage(
                stageLabel: 'naturalness_review',
                model: 'gpt-5.1',
                latencyMs: 500,
                promptTokens: 10,
                completionTokens: 5,
                totalTokens: 15,
              ),
            );
            return 'ok';
          },
          onStats: (stats) => captured = stats,
        );

        expect(result, 'ok');
        expect(captured, isNotNull);
        expect(captured!.totalTokens, 15);
      },
    );

    test('statsFor sums tokens and computes verified cost from the '
        'phase\'s own model', () {
      final stats = statsFor(
        const [
          ChatCompletionsUsage(
            stageLabel: 'stage1_dialect',
            model: 'gpt-4.1',
            latencyMs: 500,
            promptTokens: 100,
            completionTokens: 20,
            totalTokens: 120,
          ),
          ChatCompletionsUsage(
            stageLabel: 'stage2_categorization',
            model: 'gpt-4.1',
            latencyMs: 700,
            promptTokens: 200,
            completionTokens: 40,
            totalTokens: 240,
          ),
        ],
        wallClockMs: 900,
      );

      expect(stats.wallClockMs, 900);
      expect(stats.totalTokens, 360);
      expect(stats.costUsd, isNotNull);
    });

    test('statsFor returns unknown cost for an unverified model', () {
      final stats = statsFor(
        const [
          ChatCompletionsUsage(
            stageLabel: 'naturalness_review',
            model: 'not-a-real-model',
            latencyMs: 500,
            promptTokens: 100,
            completionTokens: 20,
            totalTokens: 120,
          ),
        ],
        wallClockMs: 500,
      );

      expect(stats.costUsd, isNull);
    });

    test('CallStats addition sums fields, propagating an unknown cost', () {
      const a = CallStats(wallClockMs: 100, totalTokens: 10, costUsd: 0.01);
      const b = CallStats(wallClockMs: 200, totalTokens: 20, costUsd: null);
      final sum = a + b;

      expect(sum.wallClockMs, 300);
      expect(sum.totalTokens, 30);
      expect(sum.costUsd, isNull);
    });

    test('buildReport includes every fixture id and the overall summary '
        'table', () {
      final report = buildReport(
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        results: [
          FixtureResult(
            fixture: twoPassIntegrationFixtures.first,
            firstPassCorrectedText: 'Vi mucho tráfico ayer.',
            firstPassStats: CallStats.zero,
            naturalnessOnOriginal: const NaturalnessReview(
              hasNaturalnessIssue: false,
              issues: [],
            ),
            naturalnessOnOriginalStats: CallStats.zero,
            naturalnessOnFirstPass: const NaturalnessReview(
              hasNaturalnessIssue: false,
              issues: [],
            ),
            naturalnessOnFirstPassStats: CallStats.zero,
            hadConflict: false,
            usedFallback: false,
            finalCorrectedText: 'Vi mucho tráfico ayer.',
            finalCorrectionCount: 1,
          ),
        ],
        generatedAt: DateTime.utc(2026, 1, 1),
      );

      expect(report, contains('## clean-grammar-only'));
      expect(report, contains('## Overall summary'));
      expect(report, contains('| 1 | 0 | 0 | 0 |'));
      // Score labels must render as the documented snake_case benchmark
      // vocabulary (issue #83's "Required labels" / the language-point
      // test map's "Scoring Labels" table), not this enum's own Dart
      // identifier casing.
      expect(report, contains('Score: correct_fix'));
      expect(report, contains('| correct_fix | 1 |'));
      expect(report, isNot(contains('correctFix')));
    });

    test(
      'buildReport renders a fixture error without a data table, and '
      'counts it in the overall summary — one fixture\'s failure must '
      'still produce a complete, readable report for every other fixture',
      () {
        final report = buildReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [
            FixtureResult.error(
              twoPassIntegrationFixtures.first,
              'FormatException: Naturalness review is missing '
              '"has_naturalness_issue".',
            ),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(report, contains('## clean-grammar-only'));
        expect(
          report,
          contains(
            '**ERROR**: FormatException: Naturalness review is missing '
            '"has_naturalness_issue".',
          ),
        );
        expect(report, isNot(contains('| Phase | Latency (ms)')));
        expect(report, contains('| 1 | 1 | 0 | 0 |'));
      },
    );

    test(
      'buildReport shows tokens/cost already spent before a fixture '
      'failed partway through, instead of a misleading zero in the totals',
      () {
        const partialStats = CallStats(
          wallClockMs: 2500,
          totalTokens: 500,
          costUsd: 0.002,
        );
        final report = buildReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [
            FixtureResult.error(
              twoPassIntegrationFixtures.first,
              'FormatException: boom',
              partialStats: partialStats,
            ),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(
          report,
          contains('Spent before the failure: 2500 ms, 500 tokens'),
        );
        // The overall summary's totals include it too, not just the
        // per-fixture note.
        expect(report, contains('| 1 | 1 | 0 | 0 | 2500 | 500 |'));
      },
    );
  });

  test('two-pass live integration experiment', tags: 'live', () async {
    final environment = Platform.environment;
    if (!_liveRunOptIn(environment)) {
      // ignore: avoid_print
      print('Skipping live two-pass integration harness. Set '
          'TWO_PASS_LIVE=true to opt in.');
      return;
    }

    final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      fail(
        'Set OPENAI_API_KEY to run the two-pass integration harness. This '
        'script does NOT fall back to any hardcoded/default key.',
      );
    }

    final firstPassModel = _runtimeString(
      environment: environment,
      key: 'FIRST_PASS_MODEL',
      defaultValue: _defaultFirstPassModel,
    );
    final naturalnessModel = _runtimeString(
      environment: environment,
      key: 'NATURALNESS_MODEL',
      defaultValue: _defaultNaturalnessModel,
    );
    final outputPath = _runtimeString(
      environment: environment,
      key: 'TWO_PASS_OUTPUT',
      defaultValue: defaultTwoPassOutputPath,
    );
    final callDelayMs = callDelayMsFrom(environment);

    final usageLog = <ChatCompletionsUsage>[];
    final client = OpenAiChatCompletionsClient(
      apiKey: apiKey,
      httpClient: HttpClient(),
      onUsage: usageLog.add,
    );

    final results = <FixtureResult>[];
    for (final fixture in allTwoPassFixtures) {
      // runFixture already catches its own failures and returns a
      // FixtureResult.error rather than throwing; this try/catch is a
      // defensive second layer only, in case something outside runFixture
      // itself (e.g. a bug in the print line below) throws — either way,
      // one fixture's failure must never lose the data already gathered
      // for every other fixture.
      try {
        final result = await runFixture(
          client: client,
          usageLog: usageLog,
          firstPassModel: firstPassModel,
          naturalnessModel: naturalnessModel,
          fixture: fixture,
        );
        results.add(result);
        // ignore: avoid_print
        print(
          result.isError
              ? '=== ${fixture.id} === ERROR: ${result.errorMessage}'
              : '=== ${fixture.id} ===\n'
                    'conflict=${result.hadConflict} '
                    'fallback=${result.usedFallback} '
                    'final="${result.finalCorrectedText}"',
        );
      } catch (error) {
        results.add(FixtureResult.error(fixture, error.toString()));
        // ignore: avoid_print
        print('=== ${fixture.id} === ERROR: $error');
      }
      await Future<void>.delayed(Duration(milliseconds: callDelayMs));
    }

    final report = buildReport(
      firstPassModel: firstPassModel,
      naturalnessModel: naturalnessModel,
      results: results,
      generatedAt: DateTime.now(),
    );

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(report);
    // ignore: avoid_print
    print('Wrote two-pass integration report to $outputPath');
  });
}
