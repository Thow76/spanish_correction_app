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
// Run live deliberately (costs real API calls). By default the live test
// iterates allTwoPassFixtures — as of issue #82, that's the original
// 5-fixture smoke subset (twoPassIntegrationFixtures) PLUS the full
// 80-fixture language-point benchmark (languagePointBenchmarkFixtures, 16
// groups x 5, converted from docs/two_pass_language_point_test_map.md), so
// 85 fixtures total, first pass (1 call each) + 2 naturalness calls each —
// expect on the order of 255 total API calls for a full run. Use
// TWO_PASS_FIXTURE_SET (issue #85, see below) to run a small, cheap slice
// first before committing to that.
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LIVE=true \
//   flutter test test/two_pass_integration_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - FIRST_PASS_MODEL: defaults to gpt-4.1.
// - NATURALNESS_MODEL: defaults to gpt-5.1.
// - TWO_PASS_OUTPUT: diagnostic report path, defaults to
//   docs/two_pass_integration_harness.md.
// - TWO_PASS_PRODUCTION_OUTPUT (issue #97 POC): production-style report
//   path, defaults to
//   docs/two_pass_production_mode_language_point_benchmark.md. Written
//   from the same run as TWO_PASS_OUTPUT — no extra API calls. The
//   diagnostic report always calls naturalness on both the original and
//   first-pass corrected text, for comparison; the production-style report
//   instead only counts the second (fallback) call for a fixture when
//   runTwoPassCorrectionPipeline would actually have made it (i.e. the
//   parallel merge had a skipped edit). The first pass and
//   naturalness-on-original calls themselves are started concurrently
//   (issue #98), mirroring runTwoPassCorrectionPipeline's own parallel
//   phase, so both reports' latency figures reflect the real measured
//   concurrent-phase wall-clock time rather than a sequential-call sum.
// - TWO_PASS_CALL_DELAY_MS: delay between fixtures, defaults to 750.
// - TWO_PASS_FIXTURE_SET (issue #85): which fixtures to run, defaults to
//   `all`. One of:
//   - `all`: every fixture (~255 API calls — see above).
//   - `smoke`: just the original 5-fixture smoke subset (~15 API calls).
//   - `fixture_id`: exactly one fixture — also set TWO_PASS_FIXTURE_ID.
//   - `language_point`: every fixture in one language-point group — also
//     set TWO_PASS_LANGUAGE_POINT to its exact name (e.g. "Accents /
//     Diacritics"; see docs/two_pass_language_point_test_map.md).
//   - `operation_type`: every fixture with one operation type — also set
//     TWO_PASS_OPERATION_TYPE (one of replacement, insertion, deletion,
//     mixed, no_change).
//   - `sample`: up to TWO_PASS_SAMPLE_SIZE fixtures (defaults to 1) from
//     *each* language-point group — a cheap cross-section covering every
//     language point without the full per-group fixture count.
//   An unrecognized value, or a selection that matches no fixtures at
//   all, fails fast with a clear error rather than silently running an
//   empty (or the wrong) set — see selectFixtures's own doc comment.

import 'dart:async' show runZonedGuarded;
import 'dart:io';
import 'dart:math' show min;

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_issue.dart';
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

extension TwoPassOperationTypeReportName on TwoPassOperationType {
  /// The external operation-type label from
  /// `docs/two_pass_language_point_test_map.md`'s "Operation Types" table —
  /// snake_case (`no_change`), not this enum's own Dart identifier name
  /// (`.name` would render `noChange`). Reports must use this, matching
  /// the same reasoning as `TwoPassScoreLabel.reportLabel` (issue #83).
  String get reportLabel {
    switch (this) {
      case TwoPassOperationType.replacement:
        return 'replacement';
      case TwoPassOperationType.insertion:
        return 'insertion';
      case TwoPassOperationType.deletion:
        return 'deletion';
      case TwoPassOperationType.mixed:
        return 'mixed';
      case TwoPassOperationType.noChange:
        return 'no_change';
    }
  }
}

/// Which pass a fixture expects to be responsible for its fix, or that no
/// fix is expected at all (issue #81). [either] covers both "either pass
/// alone would be an acceptable source of the fix" (e.g. a collocation
/// either pass might catch) and "both passes contribute independently, in
/// separate spans" (a fixture combining two language points) — the
/// distinction that matters for reading a report is that no single pass
/// is the sole expected owner, not which of those two shapes applies.
enum TwoPassExpectedOwner { firstPass, naturalness, either, noChange }

extension TwoPassExpectedOwnerReportName on TwoPassExpectedOwner {
  /// A snake_case owner label, consistent with the same reporting
  /// convention as [TwoPassOperationTypeReportName.reportLabel] and
  /// `TwoPassScoreLabel.reportLabel` (issue #83) — `.name` would render
  /// `firstPass`/`noChange` instead of `first_pass`/`no_change`.
  String get reportLabel {
    switch (this) {
      case TwoPassExpectedOwner.firstPass:
        return 'first_pass';
      case TwoPassExpectedOwner.naturalness:
        return 'naturalness';
      case TwoPassExpectedOwner.either:
        return 'either';
      case TwoPassExpectedOwner.noChange:
        return 'no_change';
    }
  }
}

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

/// Default for [selectFixtures]'s `fixtureSet` — the full 85-fixture
/// benchmark. See that function's doc comment for every other value.
const String defaultFixtureSet = 'all';

/// Default fixtures-per-language-point cap for the `sample` fixture set.
const int defaultSampleSizePerLanguagePoint = 1;

/// Selects which fixtures a live run should exercise (issue #85) — lets a
/// proof-of-concept run start with a small, cheap live sample before
/// committing to the full ~85-fixture benchmark's ~255-call spend (see
/// this file's own header comment). [fixtureSet] is one of:
///
/// - `all` (default): every fixture in [allTwoPassFixtures].
/// - `smoke`: just [twoPassIntegrationFixtures] — the original 5-fixture
///   smoke subset.
/// - `fixture_id`: exactly the one fixture whose id equals [fixtureId].
/// - `language_point`: every fixture whose [TwoPassFixture.languagePoint]
///   equals [languagePoint] exactly.
/// - `operation_type`: every fixture whose
///   [TwoPassOperationTypeReportName.reportLabel] equals
///   [operationTypeLabel] exactly (e.g. `"replacement"`, `"no_change"`).
/// - `sample`: up to [sampleSizePerLanguagePoint] fixtures from *each*
///   distinct language point in [allTwoPassFixtures] (in the order they
///   already appear there) — cross-section coverage of every language
///   point without the full per-group fixture count.
///
/// Throws [ArgumentError] for an unrecognized [fixtureSet], a
/// `fixture_id`/`language_point`/`operation_type` selection that matches
/// nothing, or a missing required parameter for the chosen [fixtureSet] —
/// a silently-empty live run (0 fixtures, 0 API calls, an empty report)
/// would be a much more confusing failure mode than an immediate, clear
/// error explaining exactly what didn't match.
List<TwoPassFixture> selectFixtures({
  String fixtureSet = defaultFixtureSet,
  String? fixtureId,
  String? languagePoint,
  String? operationTypeLabel,
  int sampleSizePerLanguagePoint = defaultSampleSizePerLanguagePoint,
}) {
  switch (fixtureSet) {
    case 'all':
      return allTwoPassFixtures;
    case 'smoke':
      return twoPassIntegrationFixtures;
    case 'fixture_id':
      if (fixtureId == null || fixtureId.isEmpty) {
        throw ArgumentError(
          'fixtureSet "fixture_id" requires a non-empty fixtureId.',
        );
      }
      final matches = allTwoPassFixtures.where((f) => f.id == fixtureId);
      if (matches.isEmpty) {
        throw ArgumentError('No fixture with id "$fixtureId".');
      }
      return [matches.single];
    case 'language_point':
      if (languagePoint == null || languagePoint.isEmpty) {
        throw ArgumentError(
          'fixtureSet "language_point" requires a non-empty languagePoint.',
        );
      }
      final matches = allTwoPassFixtures
          .where((f) => f.languagePoint == languagePoint)
          .toList();
      if (matches.isEmpty) {
        throw ArgumentError(
          'No fixtures with languagePoint "$languagePoint".',
        );
      }
      return matches;
    case 'operation_type':
      if (operationTypeLabel == null || operationTypeLabel.isEmpty) {
        throw ArgumentError(
          'fixtureSet "operation_type" requires a non-empty '
          'operationTypeLabel.',
        );
      }
      final matches = allTwoPassFixtures
          .where((f) => f.operationType.reportLabel == operationTypeLabel)
          .toList();
      if (matches.isEmpty) {
        throw ArgumentError(
          'No fixtures with operation type "$operationTypeLabel".',
        );
      }
      return matches;
    case 'sample':
      if (sampleSizePerLanguagePoint < 1) {
        throw ArgumentError(
          'fixtureSet "sample" requires sampleSizePerLanguagePoint >= 1 '
          '(was $sampleSizePerLanguagePoint) — 0 or negative would '
          'silently select zero fixtures from every language point, '
          'producing a valid-looking report with no fixtures and no API '
          'calls at all.',
        );
      }
      final byLanguagePoint = <String, List<TwoPassFixture>>{};
      for (final fixture in allTwoPassFixtures) {
        (byLanguagePoint[fixture.languagePoint] ??= []).add(fixture);
      }
      return [
        for (final group in byLanguagePoint.values)
          ...group.take(sampleSizePerLanguagePoint),
      ];
    default:
      throw ArgumentError(
        'Unknown fixtureSet "$fixtureSet" — expected one of: all, smoke, '
        'fixture_id, language_point, operation_type, sample.',
      );
  }
}

/// Reads [selectFixtures]'s parameters from a real environment (e.g.
/// `TWO_PASS_FIXTURE_SET=smoke flutter test ...`), same
/// real-environment-variable convention as [callDelayMsFrom].
List<TwoPassFixture> selectedFixturesFrom(Map<String, String> environment) {
  final sampleSizeRaw = environment['TWO_PASS_SAMPLE_SIZE']?.trim() ?? '';
  return selectFixtures(
    fixtureSet: _runtimeString(
      environment: environment,
      key: 'TWO_PASS_FIXTURE_SET',
      defaultValue: defaultFixtureSet,
    ),
    fixtureId: environment['TWO_PASS_FIXTURE_ID']?.trim(),
    languagePoint: environment['TWO_PASS_LANGUAGE_POINT']?.trim(),
    operationTypeLabel: environment['TWO_PASS_OPERATION_TYPE']?.trim(),
    sampleSizePerLanguagePoint:
        int.tryParse(sampleSizeRaw) ?? defaultSampleSizePerLanguagePoint,
  );
}

/// A one-line, human-readable description of a fixture selection — recorded
/// in the generated report's "Run configuration" section (issue #85's own
/// acceptance criterion) so a report never leaves a reader guessing which
/// slice of the benchmark it actually covers.
String describeFixtureSelection({
  required String fixtureSet,
  String? fixtureId,
  String? languagePoint,
  String? operationTypeLabel,
  required int sampleSizePerLanguagePoint,
  required int selectedCount,
}) {
  switch (fixtureSet) {
    case 'smoke':
      return 'smoke — the original small smoke subset ($selectedCount '
          'fixtures)';
    case 'fixture_id':
      return 'fixture_id = "$fixtureId" ($selectedCount fixture)';
    case 'language_point':
      return 'language_point = "$languagePoint" ($selectedCount fixtures)';
    case 'operation_type':
      return 'operation_type = "$operationTypeLabel" ($selectedCount '
          'fixtures)';
    case 'sample':
      return 'sample — up to $sampleSizePerLanguagePoint per language '
          'point ($selectedCount fixtures total)';
    case 'all':
    default:
      return 'all ($selectedCount fixtures)';
  }
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
    required this.parallelPhaseWallClockMs,
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
  ///
  /// [parallelPhaseWallClockMs] defaults to [partialStats]'s own
  /// wall-clock time (issue #98) — a failure can happen before the
  /// concurrent first-pass/naturalness-on-original phase ever finishes
  /// timing itself, so there's no real measured parallel-phase duration to
  /// report; falling back to whatever partial latency was already spent
  /// keeps [totalStats] on an error result numerically identical to what
  /// it always reported (the partial spend), rather than silently
  /// dropping it.
  factory FixtureResult.error(
    TwoPassFixture fixture,
    String message, {
    CallStats partialStats = CallStats.zero,
    int? parallelPhaseWallClockMs,
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
      parallelPhaseWallClockMs:
          parallelPhaseWallClockMs ?? partialStats.wallClockMs,
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

  /// Measured wall-clock time for the concurrent first-pass +
  /// naturalness-on-original phase (issue #98) — from starting both calls
  /// to both completing, not [firstPassStats.wallClockMs] +
  /// [naturalnessOnOriginalStats.wallClockMs]. Those two per-call fields
  /// stay available unchanged for per-call debugging (e.g. spotting which
  /// of the two calls is the slower one); this field is what [totalStats]
  /// and `productionStatsFor` use instead of naively summing them, since
  /// summing sequential-looking latencies for two calls that actually ran
  /// concurrently overstates real elapsed time.
  final int parallelPhaseWallClockMs;
  final bool hadConflict;
  final bool usedFallback;
  final String finalCorrectedText;
  final int finalCorrectionCount;
  final String? errorMessage;

  bool get isError => errorMessage != null;

  /// Total latency/tokens/cost for this fixture's diagnostic run. Latency
  /// is [parallelPhaseWallClockMs] (the real concurrent-phase wall-clock)
  /// plus [naturalnessOnFirstPassStats.wallClockMs] — not a naive sum of
  /// every per-call latency, since the first two calls overlap in real
  /// time (issue #98). Tokens and cost are unaffected by call scheduling,
  /// so those stay a straightforward sum across all three calls.
  CallStats get totalStats {
    final tokensAndCost =
        firstPassStats + naturalnessOnOriginalStats + naturalnessOnFirstPassStats;
    return CallStats(
      wallClockMs: parallelPhaseWallClockMs + naturalnessOnFirstPassStats.wallClockMs,
      totalTokens: tokensAndCost.totalTokens,
      costUsd: tokensAndCost.costUsd,
    );
  }
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
/// #68) and naturalness on the original text — *concurrently*, matching
/// `runTwoPassCorrectionPipeline`'s own parallel phase (issue #98; both
/// futures are created before either is awaited, same shape as production)
/// — then naturalness on the first pass's own corrected text, the parallel
/// merge (to determine whether a conflict exists), and — only when a
/// conflict exists, matching production's own fallback-trigger condition —
/// the fallback merge using the naturalness-on-first-pass result already
/// fetched above.
///
/// Each of the three calls gets its own isolated [OpenAiChatCompletionsClient]
/// (sharing [httpClient] for connection reuse, but each with its own
/// private usage-collecting list) rather than one shared client/log pair.
/// This matters specifically for the first two calls: they run
/// concurrently, and [_trackedCall]'s "everything logged since I started"
/// bookkeeping only gives each call the right [ChatCompletionsUsage]
/// entries when nothing *else* can log into the same list while it's in
/// flight — true for a private list, not guaranteed for one shared across
/// concurrent calls. The fallback call isn't concurrent with anything, so
/// isolating its list too is for consistency, not correctness.
///
/// If any call fails partway through (a malformed model response, a
/// network error), whatever latency/tokens/cost was spent before the
/// failure is preserved — see [FixtureResult.error]'s `partialStats` —
/// rather than silently discarded, so the report's totals still reflect
/// real money spent even on a fixture that ultimately failed. Critically,
/// this includes the *failing* call's own spend, not just earlier calls
/// that fully succeeded: a naturalness call can get a valid, billed HTTP
/// response (recorded the moment it arrives) and only then throw while
/// parsing that response's JSON — see [_trackedCall], which records a
/// phase's stats in a `finally` block so that always happens, on success
/// or failure alike, rather than only after an `await` expression that
/// might never finish normally. The two parallel-phase calls themselves
/// are awaited via [_awaitBothSettled] rather than two bare sequential
/// `await`s — see that function's own doc comment for why.
Future<FixtureResult> runFixture({
  required String apiKey,
  required HttpClient httpClient,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
}) async {
  var firstPassStats = CallStats.zero;
  var naturalOriginalStats = CallStats.zero;
  var naturalFirstPassStats = CallStats.zero;
  var parallelPhaseWallClockMs = 0;

  try {
    final firstPassUsage = <ChatCompletionsUsage>[];
    final naturalOriginalUsage = <ChatCompletionsUsage>[];
    final firstPassClient = OpenAiChatCompletionsClient(
      apiKey: apiKey,
      httpClient: httpClient,
      onUsage: firstPassUsage.add,
    );
    final naturalOriginalClient = OpenAiChatCompletionsClient(
      apiKey: apiKey,
      httpClient: httpClient,
      onUsage: naturalOriginalUsage.add,
    );

    final parallelPhaseStopwatch = Stopwatch()..start();
    // Both futures created before either is awaited — the same "start
    // both, then await both" shape runTwoPassCorrectionPipeline itself
    // uses for its own parallel phase.
    final firstPassFuture = _trackedCall(
      firstPassUsage,
      () => callFirstPassCorrection(
        client: firstPassClient,
        model: firstPassModel,
        submittedText: fixture.text,
      ),
      onStats: (stats) => firstPassStats = stats,
    );
    final naturalnessOriginalFuture = _trackedCall(
      naturalOriginalUsage,
      () => callNaturalnessReview(
        client: naturalOriginalClient,
        model: naturalnessModel,
        text: fixture.text,
      ),
      onStats: (stats) => naturalOriginalStats = stats,
    );
    // See _awaitBothSettled's own doc comment for why this can't be two
    // bare sequential `await`s (review finding on #98's PR).
    final (firstPassResponse, naturalnessOnOriginal) = await _awaitBothSettled(
      firstPassFuture,
      naturalnessOriginalFuture,
    );
    parallelPhaseStopwatch.stop();
    parallelPhaseWallClockMs = parallelPhaseStopwatch.elapsedMilliseconds;

    final fallbackUsage = <ChatCompletionsUsage>[];
    final fallbackClient = OpenAiChatCompletionsClient(
      apiKey: apiKey,
      httpClient: httpClient,
      onUsage: fallbackUsage.add,
    );
    final naturalnessOnFirstPass = await _trackedCall(
      fallbackUsage,
      () => callNaturalnessReview(
        client: fallbackClient,
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
      parallelPhaseWallClockMs: parallelPhaseWallClockMs,
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

/// Awaits [first] and [second] until *both* have fully settled — success
/// or failure — before this function itself either returns their two
/// results or throws, unlike two bare sequential `await`s (`await first;
/// await second;`), which abandon whichever future is still pending the
/// instant the other one throws.
///
/// That abandonment matters for [runFixture]'s own concurrent
/// first-pass/naturalness-on-original phase (issue #98's own review
/// finding): a still-pending sibling future left un-awaited both risks
/// dropping its eventual latency/tokens/cost from [FixtureResult.error]'s
/// `partialStats` (its [_trackedCall]'s `finally` block, which records
/// those stats, hasn't run yet), and leaves a dangling future whose later
/// rejection — if that call also fails — nothing ever observes: Dart
/// reports that as an unhandled async error against whatever happens to
/// be running when it surfaces, not against this fixture.
///
/// Implemented by wrapping each future in `.then(onValue, onError:)` so
/// neither branch passed to `Future.wait` ever itself rejects — that's
/// what lets `Future.wait` unconditionally wait for both to finish rather
/// than short-circuiting on the first rejection the way it normally
/// would. If both fail, [first]'s error is what gets thrown, matching the
/// priority order of the two bare sequential awaits this replaces (first
/// pass was always awaited, and so reported, before
/// naturalness-on-original).
Future<(A, B)> _awaitBothSettled<A, B>(Future<A> first, Future<B> second) async {
  A? firstValue;
  B? secondValue;
  Object? firstError;
  Object? secondError;
  await Future.wait<void>([
    first.then(
      (value) => firstValue = value,
      onError: (Object error) => firstError = error,
    ),
    second.then(
      (value) => secondValue = value,
      onError: (Object error) => secondError = error,
    ),
  ]);
  if (firstError != null) {
    throw firstError!;
  }
  if (secondError != null) {
    throw secondError!;
  }
  return (firstValue as A, secondValue as B);
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

String _formatRate(int count, int total) {
  if (total == 0) {
    return 'n/a';
  }
  return '${(count / total * 100).toStringAsFixed(1)}%';
}

/// Builds a markdown table breaking [results] down by a grouping key (via
/// [keyOf] — e.g. language point, operation type, expected owner) crossed
/// with score label — so a reader can spot a specific weak spot (e.g.
/// "Subjunctive / Mood: 1 correct_fix, 4 missed_issue") instead of only a
/// single aggregate pass rate (issue #84's own acceptance criterion).
/// Group rows appear in first-encountered order, not sorted, since
/// [results] is already grouped by construction (fixtures of the same
/// language point/operation type/owner are declared together).
String _groupedScoreTable({
  required String groupHeader,
  required List<FixtureResult> results,
  required String Function(TwoPassFixture) keyOf,
}) {
  final order = <String>[];
  final counts = <String, Map<TwoPassScoreLabel, int>>{};
  for (final result in results) {
    final key = keyOf(result.fixture);
    final labelCounts = counts.putIfAbsent(key, () {
      order.add(key);
      return {for (final label in TwoPassScoreLabel.values) label: 0};
    });
    final label = scoreFixtureResult(result);
    labelCounts[label] = labelCounts[label]! + 1;
  }

  final columns = TwoPassScoreLabel.values.map((l) => l.reportLabel).toList();
  final separatorCells = List.filled(2 + columns.length, '---').join(' | ');
  final buffer = StringBuffer()
    ..writeln('| $groupHeader | Fixtures | ${columns.join(' | ')} |')
    ..writeln('| $separatorCells |');
  for (final key in order) {
    final labelCounts = counts[key]!;
    final total = labelCounts.values.fold<int>(0, (a, b) => a + b);
    final cells = TwoPassScoreLabel.values
        .map((label) => labelCounts[label].toString())
        .join(' | ');
    buffer.writeln('| $key | $total | $cells |');
  }
  return buffer.toString();
}

/// Flags fixtures whose total latency or (when known) total cost exceeds
/// [outlierMultiplier] times the average over every non-error result in
/// [results] — a cheap, deterministic way to satisfy "latency and cost
/// outliers" (issue #84) without a fragile or overbuilt statistics model.
/// Excludes errored results from the average itself (their stats are a
/// partial spend by construction, not comparable to a full run — see
/// [FixtureResult.error]'s own doc comment), though an errored result
/// could still, in principle, be flagged if [results] is ever mixed with
/// externally-computed averages; this function only ever computes and
/// checks against non-error results.
String _outliersSection(
  List<FixtureResult> results, {
  double outlierMultiplier = 1.5,
}) {
  final nonError = results.where((r) => !r.isError).toList();
  if (nonError.isEmpty) {
    return 'Not enough non-error fixtures to compute outliers.\n';
  }

  final avgLatency =
      nonError.fold<int>(0, (sum, r) => sum + r.totalStats.wallClockMs) /
      nonError.length;
  final knownCosts = [
    for (final r in nonError)
      if (r.totalStats.costUsd != null) r.totalStats.costUsd!,
  ];
  final avgCost = knownCosts.isEmpty
      ? null
      : knownCosts.reduce((a, b) => a + b) / knownCosts.length;

  final outliers = nonError.where((r) {
    final isLatencyOutlier =
        r.totalStats.wallClockMs > avgLatency * outlierMultiplier;
    final cost = r.totalStats.costUsd;
    final isCostOutlier =
        avgCost != null && cost != null && cost > avgCost * outlierMultiplier;
    return isLatencyOutlier || isCostOutlier;
  }).toList();

  final buffer = StringBuffer()
    ..writeln(
      '- Average latency: ${avgLatency.round()} ms; average cost: '
      '${avgCost == null ? 'unknown' : _formatCost(avgCost)} '
      '(over ${nonError.length} non-error fixture(s)).',
    )
    ..writeln(
      '- Outlier threshold: ${outlierMultiplier}x the average latency or '
      'cost.',
    );
  if (outliers.isEmpty) {
    buffer.writeln('- No latency or cost outliers.');
  } else {
    buffer
      ..writeln()
      ..writeln('| Fixture | Latency (ms) | Est. cost (USD) |')
      ..writeln('| --- | --- | --- |');
    for (final result in outliers) {
      buffer.writeln(
        '| ${result.fixture.id} | ${result.totalStats.wallClockMs} | '
        '${_formatCost(result.totalStats.costUsd)} |',
      );
    }
  }
  return buffer.toString();
}

/// Builds the full markdown report for [results], in the same style as
/// this repo's other harness reports.
String buildReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<FixtureResult> results,
  required DateTime generatedAt,
  String fixtureSelection = 'all',
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
    ..writeln('- Fixture selection: $fixtureSelection (issue #85)')
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
          '- Operation type: ${result.fixture.operationType.reportLabel}',
        )
        ..writeln(
          '- Expected owner: ${result.fixture.expectedOwner.reportLabel}',
        )
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
      ..writeln(
        '- Operation type: ${result.fixture.operationType.reportLabel}',
      )
      ..writeln(
        '- Expected owner: ${result.fixture.expectedOwner.reportLabel}',
      )
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
        '| Parallel phase wall-clock (first pass + naturalness, '
        'concurrent — issue #98) | ${result.parallelPhaseWallClockMs} | '
        '— | — |',
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

  buffer
    ..writeln()
    ..writeln('### Language point summary')
    ..writeln()
    ..write(
      _groupedScoreTable(
        groupHeader: 'Language point',
        results: results,
        keyOf: (fixture) => fixture.languagePoint,
      ),
    )
    ..writeln()
    ..writeln('### Operation type summary')
    ..writeln()
    ..write(
      _groupedScoreTable(
        groupHeader: 'Operation type',
        results: results,
        keyOf: (fixture) => fixture.operationType.reportLabel,
      ),
    )
    ..writeln()
    ..writeln('### Expected owner summary')
    ..writeln()
    ..write(
      _groupedScoreTable(
        groupHeader: 'Expected owner',
        results: results,
        keyOf: (fixture) => fixture.expectedOwner.reportLabel,
      ),
    )
    ..writeln()
    ..writeln('### Fallback / conflict summary')
    ..writeln()
    ..writeln('| Metric | Count | Rate |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| Conflicts | $conflictCount | '
      '${_formatRate(conflictCount, results.length)} |',
    )
    ..writeln(
      '| Fallbacks used | $fallbackCount | '
      '${_formatRate(fallbackCount, results.length)} |',
    )
    ..writeln()
    ..writeln('### Latency / cost outliers')
    ..writeln()
    ..write(_outliersSection(results));

  return buffer.toString();
}

/// Default output path for [buildProductionModeReport] (issue #97's POC).
const String defaultTwoPassProductionOutputPath =
    'docs/two_pass_production_mode_language_point_benchmark.md';

/// Classifies whether the fallback naturalness pass would have run in
/// production for [result], and if so what happened — derived entirely
/// from data [runFixture] already collects for the diagnostic report, not
/// from a second live run (issue #97's POC scope). [runFixture] still only
/// calls this fallback naturalness pass unconditionally for diagnostic
/// comparison purposes; issue #98 changed *how* the first two calls are
/// timed and attributed (concurrently, with isolated usage collectors),
/// not whether this third call happens.
enum TwoPassFallbackOutcome {
  /// The parallel merge had no skipped edits — production would never call
  /// fallback for this fixture (`runTwoPassCorrectionPipeline`'s own
  /// short-circuit at `parallelMerge.skippedEdits.isEmpty`).
  notNeeded,

  /// Fallback would have run, and it changed the final text relative to
  /// the first pass's own output.
  calledChangedText,

  /// Fallback would have run, found nothing to flag on the first pass's
  /// corrected text, and left it unchanged — a clean resolution.
  calledUnchangedClean,

  /// Fallback would have run, still flagged an issue, but the second merge
  /// attempt still could not safely apply it — the "still unsafe after a
  /// rerun" case (see `ambiguous-naturalness-span`'s own fixture note).
  calledStillUnsafe,
}

extension TwoPassFallbackOutcomeReportName on TwoPassFallbackOutcome {
  /// Snake_case report label, same convention as every other `reportLabel`
  /// in this file.
  String get reportLabel {
    switch (this) {
      case TwoPassFallbackOutcome.notNeeded:
        return 'not_needed';
      case TwoPassFallbackOutcome.calledChangedText:
        return 'called_changed_text';
      case TwoPassFallbackOutcome.calledUnchangedClean:
        return 'called_unchanged_clean';
      case TwoPassFallbackOutcome.calledStillUnsafe:
        return 'called_still_unsafe';
    }
  }
}

/// Classifies [result]'s fallback outcome for the production-mode report.
/// Requires a non-error result — callers must check [FixtureResult.isError]
/// first, same convention [scoreFixtureResult]'s own callers already follow.
TwoPassFallbackOutcome classifyFallbackOutcome(FixtureResult result) {
  assert(
    !result.isError,
    'classifyFallbackOutcome requires a non-error result',
  );
  if (!result.hadConflict) {
    return TwoPassFallbackOutcome.notNeeded;
  }
  if (result.finalCorrectedText != result.firstPassCorrectedText) {
    return TwoPassFallbackOutcome.calledChangedText;
  }
  return result.naturalnessOnFirstPass.hasNaturalnessIssue
      ? TwoPassFallbackOutcome.calledStillUnsafe
      : TwoPassFallbackOutcome.calledUnchangedClean;
}

/// Derives the production-equivalent [CallStats] for [result]: the first
/// pass and naturalness-on-original are always spent (production runs
/// both, concurrently — see `runTwoPassCorrectionPipeline`), but the
/// fallback naturalness-on-first-pass call is only counted when
/// [FixtureResult.hadConflict] is true, matching production's own
/// conditional fallback trigger exactly.
///
/// Latency uses [FixtureResult.parallelPhaseWallClockMs] — the real
/// measured wall-clock time for the concurrent first-pass +
/// naturalness-on-original phase [runFixture] times directly (issue #98)
/// — plus the fallback call's own latency when it was needed, rather than
/// summing every per-call latency as if the calls ran one after another.
/// Tokens and cost are unaffected by call scheduling, so those stay a
/// straightforward sum.
CallStats productionStatsFor(FixtureResult result) {
  final tokensAndCost = result.hadConflict
      ? result.firstPassStats + result.naturalnessOnOriginalStats + result.naturalnessOnFirstPassStats
      : result.firstPassStats + result.naturalnessOnOriginalStats;
  return CallStats(
    wallClockMs: result.parallelPhaseWallClockMs +
        (result.hadConflict ? result.naturalnessOnFirstPassStats.wallClockMs : 0),
    totalTokens: tokensAndCost.totalTokens,
    costUsd: tokensAndCost.costUsd,
  );
}

/// The number of API calls production would have made for [result]: 2
/// (first pass + naturalness-on-original) when no conflict, 3 when
/// fallback was needed too.
int productionApiCallCount(FixtureResult result) =>
    result.hadConflict ? 3 : 2;

/// Whether [label] counts as a benchmark "pass" (issue #101) — the same
/// pass/fail convention already established by hand in
/// `docs/two_pass_live_language_point_benchmark_issue_log.md`: `pass`
/// means [TwoPassScoreLabel.correctFix] or
/// [TwoPassScoreLabel.acceptableNoChange]; every other label (including
/// [TwoPassScoreLabel.error]) counts as a fail.
bool isPassingScore(TwoPassScoreLabel label) =>
    label == TwoPassScoreLabel.correctFix ||
    label == TwoPassScoreLabel.acceptableNoChange;

/// Groups [results] by [TwoPassFixture.languagePoint] ("benchmark group",
/// issue #101), preserving first-encountered order — the same convention
/// [_groupedScoreTable] already uses, so a group's section order matches
/// its summary-table row order.
Map<String, List<FixtureResult>> _groupByLanguagePoint(
  List<FixtureResult> results,
) {
  final grouped = <String, List<FixtureResult>>{};
  for (final result in results) {
    (grouped[result.fixture.languagePoint] ??= []).add(result);
  }
  return grouped;
}

/// Builds the production-style report for [results] (issue #97's POC,
/// timing fixed by issue #98, shaped into per-benchmark-group sections by
/// issue #101): the same fixture run [buildReport] already reports on,
/// reinterpreted through production's own call-skipping rule instead of
/// the diagnostic harness's always-call-both-naturalness-passes behavior.
/// Emitted from the same live run as [buildReport] — no extra API calls.
///
/// Sectioned by [TwoPassFixture.languagePoint] ("benchmark group") rather
/// than one flat per-fixture list (issue #101's own acceptance
/// criterion): each group gets a short readable pass/fail + fallback
/// summary line, then a per-phrase table with the columns issue #101
/// asks for (phrase, first-pass/final corrected phrase, fallback
/// outcome, pass/fail, per-call and production-total latency, production
/// cost) — see [_groupByLanguagePoint].
String buildProductionModeReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<FixtureResult> results,
  required DateTime generatedAt,
  String fixtureSelection = 'all',
}) {
  final buffer = StringBuffer()
    ..writeln('# Two-Pass Production-Style Benchmark (issues #97/#98/#101 POC)')
    ..writeln()
    ..writeln(
      'Derived from the same live run as `docs/two_pass_integration_harness.md` '
      '(diagnostic mode) — no extra API calls. Every fixture below still had '
      'naturalness run on both the original and first-pass corrected text so '
      'the diagnostic report could compare them; this report instead only '
      'counts the second (fallback) naturalness call when '
      '`runTwoPassCorrectionPipeline` would actually have made it — i.e. '
      '**fallback is conditional here**, only triggered when the parallel '
      'merge had a skipped edit, exactly matching production behavior.',
    )
    ..writeln()
    ..writeln(
      '**Latency methodology (issue #98)**: the first pass and '
      'naturalness-on-original calls are started concurrently — mirroring '
      '`runTwoPassCorrectionPipeline`\'s own parallel phase. Each '
      'per-phrase table below shows "First-pass latency" and "Naturalness '
      '(parallel) latency" as each call\'s own individual latency, for '
      'debugging which call is slower — but "Production total latency" '
      'uses the real measured concurrent-phase wall-clock time (plus '
      'fallback latency, only when fallback actually ran), not a sum of '
      'those two per-call figures.',
    )
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixture selection: $fixtureSelection (issue #85)')
    ..writeln('- Fixture count: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln(
      '- Report layout: one section per benchmark group (language point), '
      'each with a readable pass/fail + fallback summary and a per-phrase '
      'table (issue #101)',
    )
    ..writeln();

  // Sectioned by benchmark group (language point, issue #101) rather than
  // one flat per-fixture list — each group gets a short readable summary
  // plus a per-phrase table, so a reader can judge one group's production
  // reliability without scanning every fixture in the whole benchmark.
  final groupedByLanguagePoint = _groupByLanguagePoint(results);
  final orderedOutcomeLabels = [
    ...TwoPassFallbackOutcome.values.map((o) => o.reportLabel),
    'error',
  ];
  for (final entry in groupedByLanguagePoint.entries) {
    final languagePoint = entry.key;
    final groupResults = entry.value;
    final groupPassCount = groupResults
        .where((r) => isPassingScore(scoreFixtureResult(r)))
        .length;
    final groupFailCount = groupResults.length - groupPassCount;

    final groupOutcomeCounts = <String, int>{};
    for (final result in groupResults) {
      final label = result.isError
          ? 'error'
          : classifyFallbackOutcome(result).reportLabel;
      groupOutcomeCounts[label] = (groupOutcomeCounts[label] ?? 0) + 1;
    }
    final outcomeSummary = [
      for (final label in orderedOutcomeLabels)
        if ((groupOutcomeCounts[label] ?? 0) > 0)
          '${groupOutcomeCounts[label]} $label',
    ].join(', ');

    buffer
      ..writeln('## $languagePoint')
      ..writeln()
      ..writeln(
        '${groupResults.length} '
        'fixture${groupResults.length == 1 ? '' : 's'} — $groupPassCount '
        'pass / $groupFailCount fail. Fallback: $outcomeSummary.',
      )
      ..writeln()
      ..writeln(
        '| Phrase | First-pass corrected phrase | Final corrected phrase | '
        'Fallback outcome | Pass/fail | First-pass latency (ms) | '
        'Naturalness (parallel) latency (ms) | Fallback latency (ms) | '
        'Production total latency (ms) | Production cost (USD) |',
      )
      ..writeln(
        '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
      );

    for (final result in groupResults) {
      final productionStats = productionStatsFor(result);
      final passFail = isPassingScore(scoreFixtureResult(result))
          ? 'pass'
          : 'fail';
      final fallbackOutcomeLabel = result.isError
          ? 'error'
          : classifyFallbackOutcome(result).reportLabel;
      final firstPassCorrected = result.isError
          ? '—'
          : '`${result.firstPassCorrectedText}`';
      final finalCorrected = result.isError
          ? '—'
          : '`${result.finalCorrectedText}`';
      buffer.writeln(
        '| `${result.fixture.text}` | $firstPassCorrected | '
        '$finalCorrected | $fallbackOutcomeLabel | $passFail | '
        '${result.firstPassStats.wallClockMs} | '
        '${result.naturalnessOnOriginalStats.wallClockMs} | '
        '${result.hadConflict ? result.naturalnessOnFirstPassStats.wallClockMs : 0} | '
        '${productionStats.wallClockMs} | '
        '${_formatCost(productionStats.costUsd)} |',
      );
    }
    buffer.writeln();
  }

  final nonError = results.where((r) => !r.isError).toList();
  final errorCount = results.length - nonError.length;

  final outcomeCounts = <TwoPassFallbackOutcome, int>{};
  for (final result in nonError) {
    final outcome = classifyFallbackOutcome(result);
    outcomeCounts[outcome] = (outcomeCounts[outcome] ?? 0) + 1;
  }

  final overallPassCount = results
      .where((r) => isPassingScore(scoreFixtureResult(r)))
      .length;
  final overallFailCount = results.length - overallPassCount;

  final productionTotalLatencyMs = results.fold<int>(
    0,
    (sum, r) => sum + productionStatsFor(r).wallClockMs,
  );
  final productionTotalTokens = results.fold<int>(
    0,
    (sum, r) => sum + productionStatsFor(r).totalTokens,
  );
  final anyUnknownCost = results.any(
    (r) => productionStatsFor(r).costUsd == null,
  );
  final productionTotalCostUsd = anyUnknownCost
      ? null
      : results.fold<double>(
          0,
          (sum, r) => sum + (productionStatsFor(r).costUsd ?? 0),
        );

  final diagnosticTotalLatencyMs = results.fold<int>(
    0,
    (sum, r) => sum + r.totalStats.wallClockMs,
  );
  final diagnosticTotalCostUsd = results.any((r) => r.totalStats.costUsd == null)
      ? null
      : results.fold<double>(0, (sum, r) => sum + (r.totalStats.costUsd ?? 0));

  final latencySavingsMs = diagnosticTotalLatencyMs - productionTotalLatencyMs;
  final latencySavingsPct = diagnosticTotalLatencyMs == 0
      ? 0.0
      : latencySavingsMs / diagnosticTotalLatencyMs * 100;
  final costSavingsUsd =
      (diagnosticTotalCostUsd != null && productionTotalCostUsd != null)
      ? diagnosticTotalCostUsd - productionTotalCostUsd
      : null;
  final costSavingsPct =
      (costSavingsUsd != null &&
          diagnosticTotalCostUsd != null &&
          diagnosticTotalCostUsd != 0)
      ? costSavingsUsd / diagnosticTotalCostUsd * 100
      : null;
  final costSavingsText = costSavingsUsd == null || costSavingsPct == null
      ? 'unknown'
      : '${_formatCost(costSavingsUsd)} (${costSavingsPct.toStringAsFixed(1)}%)';

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Fixtures | Errors | Production total latency (ms) | '
        'Production total tokens | Production total est. cost (USD) |')
    ..writeln('| --- | --- | --- | --- | --- |')
    ..writeln(
      '| ${results.length} | $errorCount | $productionTotalLatencyMs | '
      '$productionTotalTokens | ${_formatCost(productionTotalCostUsd)} |',
    )
    ..writeln()
    ..writeln('### Pass/fail summary')
    ..writeln()
    ..writeln('| Metric | Count | Rate |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| Pass | $overallPassCount | '
      '${_formatRate(overallPassCount, results.length)} |',
    )
    ..writeln(
      '| Fail | $overallFailCount | '
      '${_formatRate(overallFailCount, results.length)} |',
    )
    ..writeln()
    ..writeln('### Diagnostic vs. production-style totals')
    ..writeln()
    ..writeln('| Metric | Diagnostic (both naturalness calls always) | '
        'Production-style (conditional fallback) | Estimated savings |')
    ..writeln('| --- | --- | --- | --- |')
    ..writeln(
      '| Latency (ms) | $diagnosticTotalLatencyMs | '
      '$productionTotalLatencyMs | $latencySavingsMs ms '
      '(${latencySavingsPct.toStringAsFixed(1)}%) |',
    )
    ..writeln(
      '| Est. cost (USD) | ${_formatCost(diagnosticTotalCostUsd)} | '
      '${_formatCost(productionTotalCostUsd)} | $costSavingsText |',
    )
    ..writeln()
    ..writeln('### Fallback outcome summary')
    ..writeln()
    ..writeln('| Outcome | Count | Rate |')
    ..writeln('| --- | --- | --- |');
  for (final outcome in TwoPassFallbackOutcome.values) {
    final count = outcomeCounts[outcome] ?? 0;
    buffer.writeln(
      '| ${outcome.reportLabel} | $count | '
      '${_formatRate(count, nonError.length)} |',
    );
  }

  buffer
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

  buffer
    ..writeln()
    ..writeln('### Language point summary')
    ..writeln()
    ..write(
      _groupedScoreTable(
        groupHeader: 'Language point',
        results: results,
        keyOf: (fixture) => fixture.languagePoint,
      ),
    );

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
    parallelPhaseWallClockMs: 0,
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

    test(
      'two concurrent _trackedCall invocations, each given its own '
      'isolated usage list, do not cross-contaminate each other\'s usage '
      'attribution — the pattern runFixture now relies on for its '
      'concurrent first-pass/naturalness-on-original phase (issue #98). '
      'A single *shared* list here would let the slower call\'s '
      'sublist(start) slice pick up entries the faster, already-finished '
      'call logged after the slower one had already captured its start '
      'index — this proves isolated lists avoid that.',
      () async {
        final firstPassUsage = <ChatCompletionsUsage>[];
        final naturalnessUsage = <ChatCompletionsUsage>[];
        CallStats? firstPassCaptured;
        CallStats? naturalnessCaptured;

        // Deliberately finishes *second* despite being awaited *first*
        // below, forcing real interleaving: by the time the naturalness
        // call's usage is logged, the first-pass call is still in flight.
        final firstPassFuture = _trackedCall(
          firstPassUsage,
          () async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            firstPassUsage.add(
              const ChatCompletionsUsage(
                stageLabel: 'first_pass_correction',
                model: 'gpt-4.1',
                latencyMs: 30,
                promptTokens: 40,
                completionTokens: 10,
                totalTokens: 50,
              ),
            );
            return 'first-pass-response';
          },
          onStats: (stats) => firstPassCaptured = stats,
        );
        final naturalnessFuture = _trackedCall(
          naturalnessUsage,
          () async {
            naturalnessUsage.add(
              const ChatCompletionsUsage(
                stageLabel: 'naturalness_review',
                model: 'gpt-5.1',
                latencyMs: 5,
                promptTokens: 5,
                completionTokens: 5,
                totalTokens: 10,
              ),
            );
            return 'naturalness-response';
          },
          onStats: (stats) => naturalnessCaptured = stats,
        );

        final firstPassResult = await firstPassFuture;
        final naturalnessResult = await naturalnessFuture;

        expect(firstPassResult, 'first-pass-response');
        expect(naturalnessResult, 'naturalness-response');
        // Each call's own captured stats reflect only its own usage entry
        // — not the other concurrent call's, and not both combined.
        expect(firstPassCaptured!.totalTokens, 50);
        expect(naturalnessCaptured!.totalTokens, 10);
      },
    );

    group("_awaitBothSettled (review finding on #98's PR)", () {
      test('returns both values when both futures succeed', () async {
        final result = await _awaitBothSettled(
          Future.value('a'),
          Future.value(1),
        );
        expect(result, ('a', 1));
      });

      test(
        'still fully awaits the second future even when the first one '
        'throws immediately — a bare sequential "await first; await '
        'second;" would jump straight to the catch block here and leave '
        'second un-awaited',
        () async {
          var secondCompleted = false;
          final second = Future<int>.delayed(const Duration(milliseconds: 20), () {
            secondCompleted = true;
            return 1;
          });

          await expectLater(
            () => _awaitBothSettled(
              Future<String>.error(StateError('first failed')),
              second,
            ),
            throwsA(isA<StateError>()),
          );

          // If this were false, _awaitBothSettled would have returned
          // (thrown) before the second future — still in flight when the
          // first one failed — ever got the chance to finish.
          expect(secondCompleted, isTrue);
        },
      );

      test(
        'still fully awaits the first future even when the second one '
        'throws immediately',
        () async {
          var firstCompleted = false;
          final first = Future<String>.delayed(const Duration(milliseconds: 20), () {
            firstCompleted = true;
            return 'a';
          });

          await expectLater(
            () => _awaitBothSettled(
              first,
              Future<int>.error(StateError('second failed')),
            ),
            throwsA(isA<StateError>()),
          );

          expect(firstCompleted, isTrue);
        },
      );

      test(
        "when both futures fail, the first future's error is what gets "
        'thrown — matching the priority order of the two sequential '
        'awaits this helper replaces (first pass was always awaited, and '
        'so reported, before naturalness-on-original)',
        () async {
          await expectLater(
            () => _awaitBothSettled(
              Future<String>.error(StateError('first failed')),
              Future<int>.error(StateError('second failed')),
            ),
            throwsA(
              isA<StateError>().having((e) => e.message, 'message', 'first failed'),
            ),
          );
        },
      );

      test(
        'a rejection from the un-awaited-in-the-old-code sibling future '
        'never becomes an unhandled async error — regression coverage '
        'for exactly the failure mode a bare sequential await would '
        'introduce',
        () async {
          // If _awaitBothSettled left the second future's rejection
          // unobserved (the bug this helper fixes), Dart would report it
          // as an unhandled async error via the current Zone — which
          // runZonedGuarded below would catch and record here, failing
          // this test. Reaching the end of the awaited block with the
          // recorded list still empty is the proof nothing leaked.
          final unhandledErrors = <Object>[];
          await runZonedGuarded(() async {
            try {
              await _awaitBothSettled(
                Future<String>.error(StateError('first failed')),
                Future<int>.delayed(
                  const Duration(milliseconds: 20),
                  () => throw StateError('second failed too'),
                ),
              );
            } on StateError {
              // Expected — first's error surfaces as this call's own
              // throw. The second future's later rejection is the one
              // under test here.
            }
            // Give the second future's already-scheduled rejection a
            // chance to surface as an unhandled error if it were ever
            // going to.
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }, (error, stackTrace) => unhandledErrors.add(error));

          expect(unhandledErrors, isEmpty);
        },
      );
    });

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
            parallelPhaseWallClockMs: 0,
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

    test(
      'buildReport groups results by language point, operation type, and '
      'expected owner, using snake_case labels not enum .name (issue #84)',
      () {
        final accentFixture = languagePointBenchmarkFixtures.firstWhere(
          (f) => f.id == 'accent-manana',
        );
        final noChangeFixture = languagePointBenchmarkFixtures.firstWhere(
          (f) => f.id == 'estar-contento',
        );
        final collocationFixture = languagePointBenchmarkFixtures.firstWhere(
          (f) => f.id == 'collocation-hacer-decision',
        );

        final report = buildReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [
            _fakeResult(
              accentFixture,
              finalCorrectedText: accentFixture.expectedCorrectedText,
            ),
            _fakeResult(
              noChangeFixture,
              finalCorrectedText: noChangeFixture.text,
            ),
            FixtureResult.error(collocationFixture, 'FormatException: boom'),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(report, contains('### Language point summary'));
        expect(report, contains('| Accents / Diacritics | 1 |'));
        expect(report, contains('| Ser / Estar / Haber | 1 |'));
        expect(report, contains('| Collocations / Strong Calques | 1 |'));

        expect(report, contains('### Operation type summary'));
        expect(report, contains('| replacement |'));
        expect(report, contains('| no_change |'));

        expect(report, contains('### Expected owner summary'));
        expect(report, contains('| first_pass |'));
        expect(report, contains('| either |'));

        // Locks in the snake_case fix for operation type / expected owner
        // report labels — the same casing bug class already found and
        // fixed for score labels (issue #83's review).
        expect(report, contains('Operation type: no_change'));
        expect(report, contains('Expected owner: first_pass'));
        expect(report, isNot(contains('noChange')));
        expect(report, isNot(contains('firstPass')));

        expect(report, contains('### Fallback / conflict summary'));
        expect(report, contains('| Conflicts | 0 | 0.0% |'));

        expect(report, contains('### Latency / cost outliers'));
      },
    );

    test(
      'buildReport flags a fixture whose latency is well above the '
      'average as an outlier, and reports none when all are similar '
      '(issue #84)',
      () {
        final fixtureA = languagePointBenchmarkFixtures[0];
        final fixtureB = languagePointBenchmarkFixtures[1];
        final fixtureC = languagePointBenchmarkFixtures[2];

        FixtureResult resultWithLatency(TwoPassFixture fixture, int latencyMs) {
          return FixtureResult(
            fixture: fixture,
            firstPassCorrectedText: fixture.expectedCorrectedText,
            firstPassStats: CallStats(
              wallClockMs: latencyMs,
              totalTokens: 100,
              costUsd: 0.001,
            ),
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
            parallelPhaseWallClockMs: latencyMs,
            hadConflict: false,
            usedFallback: false,
            finalCorrectedText: fixture.expectedCorrectedText,
            finalCorrectionCount: 0,
          );
        }

        final noOutliersReport = buildReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [
            resultWithLatency(fixtureA, 1000),
            resultWithLatency(fixtureB, 1100),
            resultWithLatency(fixtureC, 900),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );
        expect(noOutliersReport, contains('No latency or cost outliers.'));

        final withOutlierReport = buildReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [
            resultWithLatency(fixtureA, 1000),
            resultWithLatency(fixtureB, 1000),
            resultWithLatency(fixtureC, 10000),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );
        expect(withOutlierReport, contains('| ${fixtureC.id} |'));
      },
    );

    group('selectFixtures (issue #85)', () {
      test('"all" (the default) returns every fixture', () {
        expect(selectFixtures(), allTwoPassFixtures);
        expect(
          selectFixtures(fixtureSet: 'all'),
          allTwoPassFixtures,
        );
      });

      test('"smoke" returns only the original smoke subset', () {
        expect(
          selectFixtures(fixtureSet: 'smoke'),
          twoPassIntegrationFixtures,
        );
      });

      test('"fixture_id" returns exactly the one matching fixture', () {
        final selected = selectFixtures(
          fixtureSet: 'fixture_id',
          fixtureId: 'accent-manana',
        );
        expect(selected, hasLength(1));
        expect(selected.single.id, 'accent-manana');
      });

      test('"fixture_id" throws for an unknown id', () {
        expect(
          () => selectFixtures(
            fixtureSet: 'fixture_id',
            fixtureId: 'not-a-real-fixture',
          ),
          throwsArgumentError,
        );
      });

      test('"fixture_id" throws when no id is supplied', () {
        expect(
          () => selectFixtures(fixtureSet: 'fixture_id'),
          throwsArgumentError,
        );
      });

      test(
        '"language_point" returns exactly the fixtures in that group',
        () {
          final selected = selectFixtures(
            fixtureSet: 'language_point',
            languagePoint: 'Subjunctive / Mood',
          );
          expect(selected, hasLength(5));
          expect(
            selected.every((f) => f.languagePoint == 'Subjunctive / Mood'),
            isTrue,
          );
        },
      );

      test('"language_point" throws for an unknown language point', () {
        expect(
          () => selectFixtures(
            fixtureSet: 'language_point',
            languagePoint: 'Not A Real Language Point',
          ),
          throwsArgumentError,
        );
      });

      test(
        '"operation_type" returns only fixtures with that operation type',
        () {
          final selected = selectFixtures(
            fixtureSet: 'operation_type',
            operationTypeLabel: 'no_change',
          );
          expect(selected, isNotEmpty);
          expect(
            selected.every(
              (f) => f.operationType == TwoPassOperationType.noChange,
            ),
            isTrue,
          );
          // Every no_change fixture across the whole benchmark, not just
          // one group's worth.
          expect(
            selected.length,
            allTwoPassFixtures
                .where((f) => f.operationType == TwoPassOperationType.noChange)
                .length,
          );
        },
      );

      test('"operation_type" throws for an unrecognized label', () {
        expect(
          () => selectFixtures(
            fixtureSet: 'operation_type',
            operationTypeLabel: 'not-a-real-operation-type',
          ),
          throwsArgumentError,
        );
      });

      test(
        '"sample" caps every language-point group at sampleSizePerLanguagePoint '
        'while still covering every group',
        () {
          final selected = selectFixtures(
            fixtureSet: 'sample',
            sampleSizePerLanguagePoint: 1,
          );

          final countByLanguagePoint = <String, int>{};
          for (final fixture in selected) {
            countByLanguagePoint[fixture.languagePoint] =
                (countByLanguagePoint[fixture.languagePoint] ?? 0) + 1;
          }
          expect(countByLanguagePoint.values.every((count) => count <= 1), isTrue);

          final everyLanguagePoint = allTwoPassFixtures
              .map((f) => f.languagePoint)
              .toSet();
          expect(countByLanguagePoint.keys.toSet(), everyLanguagePoint);
        },
      );

      test(
        '"sample" with a larger size still never exceeds a group\'s own '
        'fixture count',
        () {
          final selected = selectFixtures(
            fixtureSet: 'sample',
            sampleSizePerLanguagePoint: 3,
          );
          final countByLanguagePoint = <String, int>{};
          for (final fixture in selected) {
            countByLanguagePoint[fixture.languagePoint] =
                (countByLanguagePoint[fixture.languagePoint] ?? 0) + 1;
          }
          final groupSizes = <String, int>{};
          for (final fixture in allTwoPassFixtures) {
            groupSizes[fixture.languagePoint] =
                (groupSizes[fixture.languagePoint] ?? 0) + 1;
          }
          for (final entry in countByLanguagePoint.entries) {
            expect(entry.value, min(3, groupSizes[entry.key]!));
          }
        },
      );

      test(
        '"sample" throws for a zero or negative sampleSizePerLanguagePoint '
        'instead of silently selecting zero fixtures',
        () {
          expect(
            () => selectFixtures(
              fixtureSet: 'sample',
              sampleSizePerLanguagePoint: 0,
            ),
            throwsArgumentError,
          );
          expect(
            () => selectFixtures(
              fixtureSet: 'sample',
              sampleSizePerLanguagePoint: -1,
            ),
            throwsArgumentError,
          );
        },
      );

      test('an unrecognized fixtureSet throws', () {
        expect(
          () => selectFixtures(fixtureSet: 'not-a-real-set'),
          throwsArgumentError,
        );
      });

      test(
        'selectedFixturesFrom reads TWO_PASS_FIXTURE_SET and friends from '
        'a real environment, defaulting to "all" when unset',
        () {
          expect(selectedFixturesFrom(const {}), allTwoPassFixtures);
          expect(
            selectedFixturesFrom(const {'TWO_PASS_FIXTURE_SET': 'smoke'}),
            twoPassIntegrationFixtures,
          );
          expect(
            selectedFixturesFrom(const {
              'TWO_PASS_FIXTURE_SET': 'fixture_id',
              'TWO_PASS_FIXTURE_ID': 'accent-manana',
            }).map((f) => f.id),
            ['accent-manana'],
          );
        },
      );

      test(
        'describeFixtureSelection records the selection choice for the '
        'report',
        () {
          expect(
            describeFixtureSelection(
              fixtureSet: 'all',
              sampleSizePerLanguagePoint: 1,
              selectedCount: 85,
            ),
            contains('all'),
          );
          expect(
            describeFixtureSelection(
              fixtureSet: 'language_point',
              languagePoint: 'Subjunctive / Mood',
              sampleSizePerLanguagePoint: 1,
              selectedCount: 5,
            ),
            contains('Subjunctive / Mood'),
          );
        },
      );

      test(
        'buildReport records the fixture selection in its run '
        'configuration',
        () {
          final fixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'accent-manana',
          );
          final report = buildReport(
            firstPassModel: 'gpt-4.1',
            naturalnessModel: 'gpt-5.1',
            results: [
              _fakeResult(
                fixture,
                finalCorrectedText: fixture.expectedCorrectedText,
              ),
            ],
            generatedAt: DateTime.utc(2026, 1, 1),
            fixtureSelection: 'smoke — the original small smoke subset '
                '(1 fixtures)',
          );
          expect(
            report,
            contains(
              '- Fixture selection: smoke — the original small smoke '
              'subset (1 fixtures)',
            ),
          );
        },
      );
    });

    // Issue #86: consolidates coverage guarantees for the benchmark
    // fixtures and the scoring/reporting logic, so a future accidental
    // deletion or narrowing (a whole language-point group removed, one
    // operation type or expected owner quietly stops being exercised, a
    // score label stops rendering) fails a test rather than silently
    // shrinking what the benchmark actually proves. Several of #86's
    // bullets are already covered by tests added alongside the features
    // that needed them (fixture id uniqueness and the five-per-group
    // check: issue #82's tests above; scoring every case correct_fix
    // through error: issue #83's `scoreFixtureResult` group above) — this
    // group covers the remaining gaps: the *exact* set of language points
    // (not just "however many groups happen to exist"), every expected
    // owner value actually being used by real data (not just declared in
    // the enum), well-formed acceptable alternatives, and every score
    // label rendering end-to-end through a real report, not just being
    // assigned by the scorer.
    group('benchmark coverage guarantees (issue #86)', () {
      test(
        'every agreed language point is present, and no unexpected one '
        'has been added — catches an entire group silently disappearing '
        'or being renamed',
        () {
          // Keep in sync with docs/two_pass_language_point_test_map.md's
          // 15 categories, plus the "Mixed Operations" group issue #82
          // added for genuine TwoPassOperationType.mixed coverage.
          // Intentionally adding a new language point group later means
          // updating this set too — that's the point: an *unintentional*
          // change (typo, accidental deletion) fails here; a deliberate
          // one requires a matching, reviewable one-line change.
          const agreedLanguagePoints = {
            'Accents / Diacritics',
            'Gender / Number Agreement',
            'Verb Agreement / Morphology',
            'Required Prepositions',
            'Articles / Determiners',
            'Subjunctive / Mood',
            'Required Additions / Omissions',
            'Unnecessary Extras / Deletions',
            'Ser / Estar / Haber',
            'Impersonal Haber / Se',
            'Collocations / Strong Calques',
            'False Friends / Word Choice',
            'Phrase-Level Naturalness',
            'Valid Regional / Should Not Flag',
            'Already Correct / Do Not Tinker',
            'Mixed Operations',
          };
          final actualLanguagePoints = languagePointBenchmarkFixtures
              .map((f) => f.languagePoint)
              .toSet();
          expect(actualLanguagePoints, agreedLanguagePoints);
        },
      );

      test(
        'every TwoPassExpectedOwner value is actually used by at least '
        'one fixture, not just declared in the enum',
        () {
          final usedOwners = allTwoPassFixtures
              .map((f) => f.expectedOwner)
              .toSet();
          expect(usedOwners, TwoPassExpectedOwner.values.toSet());
        },
      );

      test(
        'acceptable alternatives, where present, are non-empty and '
        'distinct from the primary expected corrected text',
        () {
          for (final fixture in allTwoPassFixtures) {
            for (final alternative in fixture.acceptableAlternatives) {
              expect(
                alternative,
                isNotEmpty,
                reason: '${fixture.id} has an empty acceptable alternative',
              );
              expect(
                alternative,
                isNot(fixture.expectedCorrectedText),
                reason:
                    '${fixture.id} lists its own expectedCorrectedText as '
                    'an acceptable alternative — redundant, and probably '
                    'a copy-paste mistake',
              );
            }
          }
        },
      );

      test(
        'every TwoPassScoreLabel renders end-to-end in a generated '
        'report, not just as a scoreFixtureResult return value',
        () {
          final accentFixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'accent-manana',
          );
          final noChangeFixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'estar-contento',
          );
          final agreementFixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'agreement-ninos-manzanas',
          );
          const ambiguousFixture = TwoPassFixture(
            id: 'coverage-test-ambiguous',
            text: 'abc',
            note: 'Synthetic fixture for report-rendering coverage.',
            languagePoint: 'Test',
            operationType: TwoPassOperationType.replacement,
            expectedOwner: TwoPassExpectedOwner.firstPass,
            expectedCorrectedText: 'xyz',
          );

          final report = buildReport(
            firstPassModel: 'gpt-4.1',
            naturalnessModel: 'gpt-5.1',
            results: [
              // correctFix
              _fakeResult(
                accentFixture,
                finalCorrectedText: accentFixture.expectedCorrectedText,
              ),
              // missedIssue
              _fakeResult(accentFixture, finalCorrectedText: accentFixture.text),
              // acceptableNoChange
              _fakeResult(
                noChangeFixture,
                finalCorrectedText: noChangeFixture.text,
              ),
              // overcorrection
              _fakeResult(
                noChangeFixture,
                finalCorrectedText: 'Estoy contentísimo con el resultado.',
              ),
              // partialFix — fixes only the article/noun agreement,
              // leaving the verb unfixed: a real but incomplete
              // improvement, strictly closer to expected than the
              // original input.
              _fakeResult(
                agreementFixture,
                finalCorrectedText: 'Los niños come muchas manzanas.',
              ),
              // ambiguous — changed, but not measurably closer to
              // expected than the original input was.
              _fakeResult(ambiguousFixture, finalCorrectedText: 'qqc'),
              // error
              FixtureResult.error(accentFixture, 'FormatException: boom'),
            ],
            generatedAt: DateTime.utc(2026, 1, 1),
          );

          // Scoped to the Score summary section specifically (not the
          // whole report) — the Language/Operation/Owner summary tables
          // also list every label's reportLabel as a column header
          // regardless of whether it occurs, so a whole-report substring
          // check could pass even if the Score summary table itself never
          // rendered a label.
          final scoreSummarySection = report.substring(
            report.indexOf('### Score summary'),
            report.indexOf('### Language point summary'),
          );
          for (final label in TwoPassScoreLabel.values) {
            expect(
              scoreSummarySection,
              contains('| ${label.reportLabel} | 1 |'),
              reason:
                  '${label.reportLabel} did not appear in the score '
                  'summary table with its expected count of 1',
            );
          }
        },
      );
    });

    group('production-mode report (issue #97 POC)', () {
      FixtureResult resultWith({
        required TwoPassFixture fixture,
        required bool hadConflict,
        required String firstPassCorrectedText,
        required String finalCorrectedText,
        bool naturalnessOnFirstPassHasIssue = false,
        // Deliberately less than firstPassStats.wallClockMs (500) +
        // naturalnessOnOriginalStats.wallClockMs (700) = 1200 — issue #98's
        // whole point is that the real parallel-phase wall-clock is not
        // that sum, so a default equal to the sum would mask the fix
        // rather than exercise it.
        int parallelPhaseWallClockMs = 650,
      }) {
        return FixtureResult(
          fixture: fixture,
          firstPassCorrectedText: firstPassCorrectedText,
          firstPassStats: const CallStats(
            wallClockMs: 500,
            totalTokens: 100,
            costUsd: 0.001,
          ),
          naturalnessOnOriginal: const NaturalnessReview(
            hasNaturalnessIssue: false,
            issues: [],
          ),
          naturalnessOnOriginalStats: const CallStats(
            wallClockMs: 700,
            totalTokens: 150,
            costUsd: 0.0015,
          ),
          naturalnessOnFirstPass: NaturalnessReview(
            hasNaturalnessIssue: naturalnessOnFirstPassHasIssue,
            issues: naturalnessOnFirstPassHasIssue
                ? [
                    const NaturalnessIssue(
                      span: 'x',
                      naturalReplacement: 'y',
                      explanation: 'test',
                    ),
                  ]
                : [],
          ),
          naturalnessOnFirstPassStats: const CallStats(
            wallClockMs: 900,
            totalTokens: 200,
            costUsd: 0.002,
          ),
          parallelPhaseWallClockMs: parallelPhaseWallClockMs,
          hadConflict: hadConflict,
          usedFallback: hadConflict,
          finalCorrectedText: finalCorrectedText,
          finalCorrectionCount: 0,
        );
      }

      final fixture = languagePointBenchmarkFixtures.firstWhere(
        (f) => f.id == 'accent-manana',
      );

      test('classifyFallbackOutcome: notNeeded when there was no conflict', () {
        final result = resultWith(
          fixture: fixture,
          hadConflict: false,
          firstPassCorrectedText: 'a',
          finalCorrectedText: 'a',
        );
        expect(
          classifyFallbackOutcome(result),
          TwoPassFallbackOutcome.notNeeded,
        );
      });

      test(
        'classifyFallbackOutcome: calledChangedText when fallback altered '
        'the first-pass text',
        () {
          final result = resultWith(
            fixture: fixture,
            hadConflict: true,
            firstPassCorrectedText: 'a',
            finalCorrectedText: 'b',
          );
          expect(
            classifyFallbackOutcome(result),
            TwoPassFallbackOutcome.calledChangedText,
          );
        },
      );

      test(
        'classifyFallbackOutcome: calledUnchangedClean when fallback found '
        'no issue and left the text unchanged',
        () {
          final result = resultWith(
            fixture: fixture,
            hadConflict: true,
            firstPassCorrectedText: 'a',
            finalCorrectedText: 'a',
            naturalnessOnFirstPassHasIssue: false,
          );
          expect(
            classifyFallbackOutcome(result),
            TwoPassFallbackOutcome.calledUnchangedClean,
          );
        },
      );

      test(
        'classifyFallbackOutcome: calledStillUnsafe when fallback still '
        'flagged an issue but nothing could be safely merged',
        () {
          final result = resultWith(
            fixture: fixture,
            hadConflict: true,
            firstPassCorrectedText: 'a',
            finalCorrectedText: 'a',
            naturalnessOnFirstPassHasIssue: true,
          );
          expect(
            classifyFallbackOutcome(result),
            TwoPassFallbackOutcome.calledStillUnsafe,
          );
        },
      );

      test(
        'productionStatsFor excludes the fallback call when no conflict '
        'occurred, and uses the measured parallel-phase wall-clock rather '
        'than summing the first-pass and naturalness-on-original '
        'latencies (issue #98)',
        () {
          final result = resultWith(
            fixture: fixture,
            hadConflict: false,
            firstPassCorrectedText: 'a',
            finalCorrectedText: 'a',
            parallelPhaseWallClockMs: 650,
          );
          final stats = productionStatsFor(result);
          // Not 500 + 700 (the naive sequential-sum figure this issue
          // replaces) — the real measured concurrent-phase time instead.
          expect(stats.wallClockMs, 650);
          expect(stats.totalTokens, 100 + 150);
          expect(productionApiCallCount(result), 2);
        },
      );

      test(
        'productionStatsFor includes the fallback call when a conflict '
        'occurred, adding fallback latency on top of the parallel-phase '
        'wall-clock rather than the naive per-call sum (issue #98)',
        () {
          final result = resultWith(
            fixture: fixture,
            hadConflict: true,
            firstPassCorrectedText: 'a',
            finalCorrectedText: 'b',
            parallelPhaseWallClockMs: 650,
          );
          final stats = productionStatsFor(result);
          // Not 500 + 700 + 900 — parallel-phase wall-clock (650) plus
          // fallback latency (900) only.
          expect(stats.wallClockMs, 650 + 900);
          expect(stats.totalTokens, 100 + 150 + 200);
          expect(productionApiCallCount(result), 3);
        },
      );

      test(
        'parallel-phase wall-clock can be shorter than either individual '
        'call\'s own latency would suggest when summed — proving '
        'productionStatsFor and totalStats really do use the measured '
        'concurrent-phase time, not first-pass-latency + '
        'naturalness-latency (issue #98)',
        () {
          // firstPassStats.wallClockMs=500 and naturalnessOnOriginalStats.
          // wallClockMs=700 (resultWith's fixed values) sum to 1200; a
          // parallel-phase figure below the *smaller* of the two (500)
          // would be physically impossible for two calls that really ran
          // concurrently, so 300 here is deliberately implausible — it
          // exists purely to prove the formula reads
          // parallelPhaseWallClockMs directly rather than deriving
          // anything from the per-call CallStats.
          final result = resultWith(
            fixture: fixture,
            hadConflict: false,
            firstPassCorrectedText: 'a',
            finalCorrectedText: 'a',
            parallelPhaseWallClockMs: 300,
          );
          expect(productionStatsFor(result).wallClockMs, 300);
          expect(result.totalStats.wallClockMs, 300 + 900);
          // Per-call timing must still be available for debugging,
          // unchanged by the parallel-phase figure existing alongside it.
          expect(result.firstPassStats.wallClockMs, 500);
          expect(result.naturalnessOnOriginalStats.wallClockMs, 700);
        },
      );

      test(
        'buildProductionModeReport labels itself as production-style, '
        'sections by benchmark group (issue #101), and renders a '
        'per-phrase row with the fixture\'s own phrase text, fallback '
        'outcome, and pass/fail',
        () {
          final report = buildProductionModeReport(
            firstPassModel: 'gpt-4.1',
            naturalnessModel: 'gpt-5.1',
            results: [
              resultWith(
                fixture: fixture,
                hadConflict: false,
                firstPassCorrectedText: fixture.expectedCorrectedText,
                finalCorrectedText: fixture.expectedCorrectedText,
              ),
            ],
            generatedAt: DateTime.utc(2026, 1, 1),
          );

          expect(report, contains('Production-Style Benchmark'));
          // Sectioned by benchmark group (language point), not per-fixture
          // id — issue #101's own restructuring.
          expect(report, contains('## ${fixture.languagePoint}'));
          expect(report, contains('1 pass / 0 fail'));
          expect(report, contains('| `${fixture.text}` |'));
          expect(
            report,
            contains('| not_needed | pass |'),
          );
          expect(report, contains('### Pass/fail summary'));
          expect(report, contains('### Fallback outcome summary'));
          expect(report, contains('### Diagnostic vs. production-style totals'));
          expect(report, contains('Estimated savings'));
        },
      );

      test(
        'buildProductionModeReport fallback outcome counts sum to the '
        'non-error fixture count',
        () {
          final otherFixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'agreement-ninos-manzanas',
          );
          final report = buildProductionModeReport(
            firstPassModel: 'gpt-4.1',
            naturalnessModel: 'gpt-5.1',
            results: [
              resultWith(
                fixture: fixture,
                hadConflict: false,
                firstPassCorrectedText: 'a',
                finalCorrectedText: 'a',
              ),
              resultWith(
                fixture: otherFixture,
                hadConflict: true,
                firstPassCorrectedText: 'a',
                finalCorrectedText: 'b',
              ),
              FixtureResult.error(fixture, 'FormatException: boom'),
            ],
            generatedAt: DateTime.utc(2026, 1, 1),
          );

          expect(report, contains('| not_needed | 1 |'));
          expect(report, contains('| called_changed_text | 1 |'));
          // The error fixture is excluded from the fallback-outcome rate
          // denominator (classifyFallbackOutcome requires a non-error
          // result), but still counted in the overall fixture/error totals.
          expect(report, contains('| 3 | 1 |'));
        },
      );

      test(
        'isPassingScore matches the pass/fail convention already '
        'established in docs/two_pass_live_language_point_benchmark_'
        'issue_log.md: correct_fix and acceptable_no_change pass, '
        'everything else — including error — fails',
        () {
          expect(isPassingScore(TwoPassScoreLabel.correctFix), isTrue);
          expect(isPassingScore(TwoPassScoreLabel.acceptableNoChange), isTrue);
          expect(isPassingScore(TwoPassScoreLabel.partialFix), isFalse);
          expect(isPassingScore(TwoPassScoreLabel.missedIssue), isFalse);
          expect(isPassingScore(TwoPassScoreLabel.overcorrection), isFalse);
          expect(isPassingScore(TwoPassScoreLabel.ambiguous), isFalse);
          expect(isPassingScore(TwoPassScoreLabel.error), isFalse);
        },
      );

      test(
        'buildProductionModeReport (issue #101) sections results by '
        'benchmark group — two fixtures from different language points '
        'get two distinct group headings, each with its own per-phrase '
        'table containing only that group\'s own phrase',
        () {
          final otherFixture = languagePointBenchmarkFixtures.firstWhere(
            (f) => f.id == 'agreement-ninos-manzanas',
          );
          final report = buildProductionModeReport(
            firstPassModel: 'gpt-4.1',
            naturalnessModel: 'gpt-5.1',
            results: [
              resultWith(
                fixture: fixture,
                hadConflict: false,
                firstPassCorrectedText: fixture.expectedCorrectedText,
                finalCorrectedText: fixture.expectedCorrectedText,
              ),
              resultWith(
                fixture: otherFixture,
                hadConflict: false,
                firstPassCorrectedText: otherFixture.expectedCorrectedText,
                finalCorrectedText: otherFixture.expectedCorrectedText,
              ),
            ],
            generatedAt: DateTime.utc(2026, 1, 1),
          );

          expect(report, contains('## ${fixture.languagePoint}'));
          expect(report, contains('## ${otherFixture.languagePoint}'));

          final accentsSection = report.substring(
            report.indexOf('## ${fixture.languagePoint}'),
            report.indexOf('## ${otherFixture.languagePoint}'),
          );
          expect(accentsSection, contains('| `${fixture.text}` |'));
          expect(accentsSection, isNot(contains('| `${otherFixture.text}` |')));
        },
      );

      test(
        'buildProductionModeReport (issue #101) still renders an errored '
        'fixture as a row inside its own group\'s table — phrase and '
        '"error"/"fail" cells, not a crash or a dropped fixture',
        () {
          final report = buildProductionModeReport(
            firstPassModel: 'gpt-4.1',
            naturalnessModel: 'gpt-5.1',
            results: [FixtureResult.error(fixture, 'FormatException: boom')],
            generatedAt: DateTime.utc(2026, 1, 1),
          );

          expect(report, contains('## ${fixture.languagePoint}'));
          expect(report, contains('1 fixture — 0 pass / 1 fail'));
          expect(report, contains('Fallback: 1 error'));
          expect(report, contains('| `${fixture.text}` | — | — | error | fail |'));
        },
      );

      test(
        'production-style totals never exceed the diagnostic totals for '
        'the same underlying results',
        () {
          final results = [
            resultWith(
              fixture: fixture,
              hadConflict: false,
              firstPassCorrectedText: 'a',
              finalCorrectedText: 'a',
            ),
            resultWith(
              fixture: languagePointBenchmarkFixtures.firstWhere(
                (f) => f.id == 'agreement-ninos-manzanas',
              ),
              hadConflict: true,
              firstPassCorrectedText: 'a',
              finalCorrectedText: 'b',
            ),
          ];

          final diagnosticTotalMs = results.fold<int>(
            0,
            (sum, r) => sum + r.totalStats.wallClockMs,
          );
          final productionTotalMs = results.fold<int>(
            0,
            (sum, r) => sum + productionStatsFor(r).wallClockMs,
          );
          expect(productionTotalMs, lessThanOrEqualTo(diagnosticTotalMs));
        },
      );

      test(
        'defaultTwoPassProductionOutputPath has a stable, documented '
        'default distinct from the diagnostic report path',
        () {
          expect(
            defaultTwoPassProductionOutputPath,
            'docs/two_pass_production_mode_language_point_benchmark.md',
          );
          expect(
            defaultTwoPassProductionOutputPath,
            isNot(defaultTwoPassOutputPath),
          );
        },
      );
    });
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
    final productionOutputPath = _runtimeString(
      environment: environment,
      key: 'TWO_PASS_PRODUCTION_OUTPUT',
      defaultValue: defaultTwoPassProductionOutputPath,
    );
    final callDelayMs = callDelayMsFrom(environment);
    final selectedFixtures = selectedFixturesFrom(environment);
    final fixtureSelectionDescription = describeFixtureSelection(
      fixtureSet: _runtimeString(
        environment: environment,
        key: 'TWO_PASS_FIXTURE_SET',
        defaultValue: defaultFixtureSet,
      ),
      fixtureId: environment['TWO_PASS_FIXTURE_ID']?.trim(),
      languagePoint: environment['TWO_PASS_LANGUAGE_POINT']?.trim(),
      operationTypeLabel: environment['TWO_PASS_OPERATION_TYPE']?.trim(),
      sampleSizePerLanguagePoint:
          int.tryParse(environment['TWO_PASS_SAMPLE_SIZE']?.trim() ?? '') ??
          defaultSampleSizePerLanguagePoint,
      selectedCount: selectedFixtures.length,
    );

    // Issue #98: one shared HttpClient (connection reuse is fine — it's
    // designed for concurrent requests), but no shared usage-collecting
    // list or client instance — runFixture builds its own isolated
    // per-call clients so its concurrent first-pass/naturalness-on-original
    // phase can't cross-contaminate usage attribution between them.
    final httpClient = HttpClient();

    final results = <FixtureResult>[];
    for (final fixture in selectedFixtures) {
      // runFixture already catches its own failures and returns a
      // FixtureResult.error rather than throwing; this try/catch is a
      // defensive second layer only, in case something outside runFixture
      // itself (e.g. a bug in the print line below) throws — either way,
      // one fixture's failure must never lose the data already gathered
      // for every other fixture.
      try {
        final result = await runFixture(
          apiKey: apiKey,
          httpClient: httpClient,
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
      fixtureSelection: fixtureSelectionDescription,
    );

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(report);
    // ignore: avoid_print
    print('Wrote two-pass integration report to $outputPath');

    // Issue #97 POC: production-style report, derived from the exact same
    // run above — no extra API calls, no change to runFixture's own call
    // pattern. See buildProductionModeReport's doc comment.
    final productionReport = buildProductionModeReport(
      firstPassModel: firstPassModel,
      naturalnessModel: naturalnessModel,
      results: results,
      generatedAt: DateTime.now(),
      fixtureSelection: fixtureSelectionDescription,
    );
    final productionFile = File(productionOutputPath);
    await productionFile.parent.create(recursive: true);
    await productionFile.writeAsString(productionReport);
    // ignore: avoid_print
    print(
      'Wrote two-pass production-style report to $productionOutputPath',
    );
  });
}
