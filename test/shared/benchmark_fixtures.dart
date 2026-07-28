// Shared Spanish correction benchmark fixture set.
//
// Issue: "Define richer Spanish correction benchmark fixture strategy"
// (closes spanish_correction_app#11). Purpose: a small, shared set of
// representative natural-language inputs for latency/request-count/
// token-usage/cost/model-comparison benchmarking — not a language-quality
// regression suite, and not a change to prompts, model behavior, UI flow, or
// the staged pipeline. This complements (does not duplicate) the
// observability work in spanish_correction_app#6: that issue records
// latency/tokens/cost (see `test/pipeline_baseline_harness.dart`'s `onUsage`
// wiring); this file only supplies the inputs such harnesses can run against.
//
// Audit summary (see the issue for the full audit scope):
// - `test/model_comparison_harness.dart`'s `_TestCase` battery and
//   `test/correction_consistency_harness.dart`'s `_Phrase` battery already
//   contain small, well-chosen single-sentence inputs (grammar/spelling/
//   punctuation errors, a voseo dialectal control, an already-correct
//   control, and calque/anglicism cases such as `ES-4-calque` /
//   `PT-4-calque` — "¿Puedo tener una cerveza? Quiero pasar un buen tiempo
//   con mis amigos..." is exactly the CALCS-style content this fixture set
//   needs). Those are reused/adapted below rather than re-invented.
// - Neither battery had a paragraph-length, two-paragraph, or near-600-
//   character case (the app's input limit — see
//   `lib/features/write/presentation/write_screen.dart`'s
//   `_characterLimit`), because they were built for stage-specific
//   language-point regression, not for exercising input-length-driven
//   staged-pipeline behavior. Those bands are added fresh here.
// - The large language-point suites (`stage1_detection_harness.dart`,
//   `stage2_categorization_harness.dart`, `verdict_battery_merged.dart`,
//   `peninsular_norms_battery.dart`, etc. — see
//   `docs/model-research-index.md`'s "Active regression tests" list) are
//   deliberately left untouched and NOT folded into this fixture set: they
//   exist to catch correction-quality regressions across many small,
//   narrow language points, which is the opposite goal from a small,
//   routine latency/cost battery.
// - This file intentionally carries no expected-correction-output
//   assertions — only input text plus metadata describing what each case is
//   for. Any harness that wants pass/fail correction-quality checks should
//   keep using the dedicated suites above; this set is inputs only.
//
// Fixtures are plain data (no live API calls, no Flutter dependency beyond
// `dart:core`), so any harness — the staged pipeline baseline harness, the
// model-comparison harness, or a future one — can import this file and
// filter `benchmarkFixtures` by [BenchmarkLengthBand] or by tag without
// re-declaring the inputs.

/// Approximate input-length band a [BenchmarkFixture] falls into, used to
/// make sure the benchmark battery actually spans the lengths that can
/// change staged-pipeline latency/cost (more text generally means more
/// input tokens per stage, not a different number of stages).
enum BenchmarkLengthBand {
  /// A few words — well under one full sentence.
  shortPhrase,

  /// One sentence, or a very short (one- to two-sentence) paragraph.
  sentenceOrShortParagraph,

  /// A single natural-language paragraph of several sentences.
  paragraph,

  /// Two natural-language paragraphs (a blank line apart).
  twoParagraph,

  /// Close to (but never over) the app's 600-character input limit — see
  /// `lib/features/write/presentation/write_screen.dart`'s
  /// `_characterLimit` and `lib/features/learn/presentation/
  /// prompt_translation_game_screen.dart`'s `_answerLimit`.
  nearLimit,
}

/// The app's character limit for a single correction input, duplicated here
/// (not imported from `lib/`) for the same reason
/// `test/pipeline_baseline_harness.dart` duplicates its pricing table: a
/// small, explicit, test-local constant that a fixture-invariant test can
/// check every case against, independent of any future UI refactor.
const int appCharacterLimit = 600;

/// One shared benchmark input, with explicit metadata instead of an
/// expected-correction-output assertion (per the issue's implementation
/// guidance: "Avoid adding expected correction-output assertions unless
/// they are needed for a specific offline test").
class BenchmarkFixture {
  const BenchmarkFixture({
    required this.id,
    required this.description,
    required this.text,
    required this.lengthBand,
    required this.purpose,
    required this.containsKnownErrors,
    required this.isAccentSensitive,
    this.isCalcsStyle = false,
  });

  /// Short, unique, kebab-case identifier — stable across harnesses so a
  /// report can refer to "case X" the same way in every harness that reuses
  /// this fixture set.
  final String id;

  /// One-line human-readable summary of what the text represents.
  final String description;

  /// The Spanish input text itself. Never longer than [appCharacterLimit].
  final String text;

  /// Which [BenchmarkLengthBand] this case represents.
  final BenchmarkLengthBand lengthBand;

  /// What this case is intended to exercise in a latency/cost/model
  /// benchmark (e.g. "shortest-input latency/cost floor", "near-limit
  /// staged-pipeline cost ceiling") — deliberately not a correction-quality
  /// claim.
  final String purpose;

  /// Whether the text contains at least one objective grammar, spelling, or
  /// punctuation error (independent of dialectal/calque content, which is
  /// tracked separately via [isCalcsStyle]). `false` means the text is
  /// already-correct Spanish as written.
  final bool containsKnownErrors;

  /// Whether this case specifically exercises accented-character handling
  /// (either already-correct accents that must survive round-trip, or a
  /// missing-accent spelling error).
  final bool isAccentSensitive;

  /// Whether this case is CALCS-style natural language: a calque or overly
  /// literal English-influenced construction (per CALCS — Computational
  /// Approaches to Linguistic Code-Switching — style bilingual-contact
  /// content), rather than a plain grammar/spelling/punctuation error. See
  /// `lib/core/services/prompts/correction_prompt.dart`'s calque guidance
  /// for how the app's own prompt treats this content.
  final bool isCalcsStyle;
}

/// The shared benchmark fixture set. Small and fixed on purpose — this is
/// meant for routine live latency/cost/model-comparison runs, not for
/// exhaustive language-quality coverage (see the large suites listed in
/// `docs/model-research-index.md` for that).
const List<BenchmarkFixture> benchmarkFixtures = [
  BenchmarkFixture(
    id: 'short-phrase-correct-greeting',
    description: 'Short, already-correct greeting with two accents.',
    text: 'Buenos días, ¿cómo estás?',
    lengthBand: BenchmarkLengthBand.shortPhrase,
    purpose:
        'Shortest-input latency/cost floor for a clean case; confirms '
        'accented characters and inverted question marks survive '
        'round-trip untouched.',
    containsKnownErrors: false,
    isAccentSensitive: true,
  ),
  BenchmarkFixture(
    id: 'short-phrase-missing-accent',
    description: 'Short phrase missing one required accent.',
    text: 'Voy al parque manana por la tarde.',
    lengthBand: BenchmarkLengthBand.shortPhrase,
    purpose:
        'Shortest-input latency/cost floor for a case expected to reach '
        'Stage 1 spelling detection ("manana" -> "mañana").',
    containsKnownErrors: true,
    isAccentSensitive: true,
  ),
  BenchmarkFixture(
    id: 'sentence-grammar-error',
    description: 'Single sentence with objective plural-agreement errors.',
    text: 'Los niño come muchas manzana en el jardín ayer.',
    lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
    purpose:
        'Reused from `pipeline_baseline_harness.dart`\'s '
        '"full-pipeline-grammar-error" case: expected to reach Stage 2/3, '
        'so it exercises a "full pipeline" latency/cost run at a short '
        'single-sentence length.',
    containsKnownErrors: true,
    isAccentSensitive: false,
  ),
  BenchmarkFixture(
    id: 'sentence-correct-voseo',
    description: 'Single sentence of correct Argentine voseo Spanish.',
    text: 'Vos tenés razón, che, así que dale nomás.',
    lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
    purpose:
        'Reused from `model_comparison_harness.dart`\'s "control-voseo" '
        'case: dialectal, not an error, so it exercises the dialectal '
        'verdict path (Stage 1 flags it, Stage 2 categorizes it as '
        'dialectal, Stage 3 still runs) at a short length.',
    containsKnownErrors: false,
    isAccentSensitive: true,
  ),
  BenchmarkFixture(
    id: 'paragraph-calcs-natural',
    description:
        'CALCS-style natural paragraph built around English calques.',
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche porque llevamos mucho tiempo sin vernos y '
        'tenemos que ponernos al día con todo lo que ha pasado este año.',
    lengthBand: BenchmarkLengthBand.paragraph,
    purpose:
        'Paragraph-length CALCS-style case, expanding '
        '`correction_consistency_harness.dart`\'s "ES-4-calque" phrase '
        '("Puedo tener una cerveza" / "pasar un buen tiempo" as calques '
        'of "can I have a beer" / "have a good time") into a full natural '
        'paragraph, to see how staged detection/categorization latency '
        'and cost behave on realistic bilingual-contact prose rather '
        'than an isolated sentence.',
    containsKnownErrors: false,
    isAccentSensitive: true,
    isCalcsStyle: true,
  ),
  BenchmarkFixture(
    id: 'paragraph-mixed-errors',
    description:
        'Natural paragraph with several grammar, spelling, and '
        'punctuation errors and no closing punctuation.',
    text:
        'Ayer fui a la tienda y compre pan, leche y unas manzana. Cuando '
        'llegue a casa mi hermano me pregunto si queria ayudarlo con la '
        'tarea, pero yo estaba muy cansado despues del trabajo',
    lengthBand: BenchmarkLengthBand.paragraph,
    purpose:
        'Paragraph-length case with several independent objective errors '
        '(missing accents on "compré"/"llegué"/"preguntó"/"quería"/'
        '"después", plural agreement on "manzana", missing final '
        'punctuation) — a realistic multi-error paragraph expected to '
        'reach the full staged pipeline.',
    containsKnownErrors: true,
    isAccentSensitive: true,
  ),
  BenchmarkFixture(
    id: 'two-paragraph-correct',
    description: 'Two already-correct natural-language paragraphs.',
    text:
        'Mañana visitaré a mi abuela en su pequeño pueblo junto al río. '
        'Ella siempre prepara una comida deliciosa y me cuenta historias '
        'de cuando era joven.\n\n'
        'Después de la visita, pienso caminar por el bosque cercano antes '
        'de que oscurezca, porque me encanta escuchar el sonido de los '
        'pájaros al atardecer.',
    lengthBand: BenchmarkLengthBand.twoParagraph,
    purpose:
        'Two-paragraph, already-correct case (first paragraph reused from '
        '`model_comparison_harness.dart`\'s "control-already-correct" '
        'case) — expected Stage 1 early exit even at roughly double the '
        'single-paragraph input length, to isolate length-driven token/'
        'cost growth from staged-pipeline branching.',
    containsKnownErrors: false,
    isAccentSensitive: true,
  ),
  BenchmarkFixture(
    id: 'two-paragraph-mixed-errors',
    description:
        'Two natural-language paragraphs with several accent, spelling, '
        'and agreement errors spread across both.',
    text:
        'El sabado pasado fuimos al cine con mis amigos y vimos una '
        'pelicula muy interesante sobre un viaje al espacio. Despues '
        'cenamos en un restaurante cerca del centro comercial.\n\n'
        'Mi amigo Carlos penso que la pelicula fue aburrida pero yo creo '
        'que fue emocionante. Vamos a repetir el plan el proximo fin de '
        'semana si todos estan libres',
    lengthBand: BenchmarkLengthBand.twoParagraph,
    purpose:
        'Two-paragraph case with errors distributed across both '
        'paragraphs (missing accents on "sábado"/"película"/"Después"/'
        '"pensó"/"próximo"/"están", missing final punctuation) — exercises '
        'the full staged pipeline at roughly double single-paragraph '
        'length.',
    containsKnownErrors: true,
    isAccentSensitive: true,
  ),
  BenchmarkFixture(
    id: 'near-limit-full-text',
    description:
        'Near the app\'s 600-character input limit: a single long, '
        'natural-language paragraph recounting a weekend trip, with '
        'several accent/spelling errors spread throughout.',
    text:
        'El fin de semana pasado decidimos hacer un viaje corto a la '
        'montaña para descansar del trabajo y de la ciudad. Salimos muy '
        'temprano, antes de que saliera el sol, y llegamos al pequeño '
        'pueblo justo a tiempo para desayunar en un cafe que mi hermano '
        'habia recomendado. Durante la tarde caminamos por un sendero '
        'cerca del rio, sacamos muchas foto y hablamos de nuestros planes '
        'para el proximo año. Cuando volvimos al hotel, todos estabamos '
        'muy cansados pero contentos, y decidimos que teniamos que '
        'regresar pronto porque el lugar nos habia gustado mucho a '
        'todos.',
    lengthBand: BenchmarkLengthBand.nearLimit,
    purpose:
        'Near-limit/full-text case (close to but under '
        '`appCharacterLimit`) to measure the latency/token/cost ceiling '
        'for the longest input the app\'s write screen allows, at a '
        'realistic natural-language length rather than padded filler '
        'text.',
    containsKnownErrors: true,
    isAccentSensitive: true,
  ),
];

/// Looks up a [BenchmarkFixture] by its [BenchmarkFixture.id].
///
/// Throws a [StateError] (via [Iterable.firstWhere]'s default `orElse`
/// behavior) if [id] isn't present, so a typo in a harness fails loudly
/// instead of silently skipping a case.
BenchmarkFixture benchmarkFixtureById(String id) {
  return benchmarkFixtures.firstWhere(
    (fixture) => fixture.id == id,
    orElse: () => throw StateError(
      'No benchmark fixture with id "$id". Available ids: '
      '${benchmarkFixtures.map((fixture) => fixture.id).join(', ')}.',
    ),
  );
}

/// Returns every [BenchmarkFixture] in [benchmarkFixtures] matching
/// [lengthBand], in declaration order.
List<BenchmarkFixture> benchmarkFixturesForBand(
  BenchmarkLengthBand lengthBand,
) {
  return benchmarkFixtures
      .where((fixture) => fixture.lengthBand == lengthBand)
      .toList(growable: false);
}

// ---------------------------------------------------------------------------
// Harder second-pass first-pass comparison fixtures.
//
// Issue: "Add harder second-pass first-pass comparison fixtures" (closes
// spanish_correction_app#21). Purpose: a second, harder named fixture
// subset for the SAME bare first-pass model comparison harness described
// above — testing whether smaller/cheaper models stay restrained (no
// word-choice/naturalness/style rewrites) once the objective grammar,
// spelling, and punctuation errors get harder, systematically organized
// around the CEFR B1-C1 learner-error families identified in the issue
// (prepositions, verb morphology/agreement, past tense/aspect, gender/
// number agreement, articles, mood selection, object pronouns/clitics,
// ser/estar/haber, personal `a`, relative clauses, impersonal haber/se,
// and accents/punctuation/sentence boundaries).
//
// Unlike [BenchmarkFixture] above (inputs only, no expected-output
// assertion), each [SecondPassFixture] carries an `expectedCorrectedText`
// because this subset needs deterministic scoring against a specific
// grammar/spelling/punctuation fix, not just latency/cost measurement.
// This is a distinct, additive fixture set — [benchmarkFixtures] above is
// left completely unchanged.
//
// Fixture design deliberately avoids naturalness, word-choice, style,
// tone, calque, collocation, and regional-preference traps: every
// expected correction here is an objective grammar, spelling, or
// punctuation fix from the error families below.

/// One CEFR proficiency level a [SecondPassFixture] targets.
enum CefrLevel {
  /// Common European Framework of Reference level B1.
  b1,

  /// Common European Framework of Reference level B2.
  b2,

  /// Common European Framework of Reference level C1.
  c1,
}

/// One objective Spanish grammar/spelling/punctuation error family a
/// [SecondPassFixture] is designed to exercise. These are exactly the
/// "Required Coverage" families from spanish_correction_app#21 (excluding
/// the "mixed"/"near-limit" rows, which combine several of these rather
/// than introducing a new family).
enum ErrorFamily {
  /// Missing or incorrect accent marks/diacritics.
  accentDiacritics,

  /// Article/noun/adjective gender or number agreement.
  genderNumberAgreement,

  /// A verb, adjective, or noun used with the wrong required preposition.
  prepositionGovernment,

  /// Verb morphology / subject-verb agreement.
  verbMorphologySubjectAgreement,

  /// Article/determiner selection.
  articlesDeterminers,

  /// Subjunctive, indicative, or conditional mood selection.
  subjunctiveMood,

  /// Object pronouns, clitic placement, or pronominal verbs.
  objectPronounsClitics,

  /// `ser`, `estar`, or `haber` selection.
  serEstarHaber,

  /// Missing personal `a` before an animate direct object.
  personalA,

  /// A relative clause missing its required preposition.
  relativeClausePreposition,

  /// Impersonal `haber`, or impersonal/passive `se`.
  impersonalHaberOrSe,

  /// Sentence boundaries, run-ons, commas, or missing question/exclamation
  /// marks.
  punctuationSentenceBoundaries,
}

/// One fixture in the harder second-pass first-pass comparison subset (see
/// spanish_correction_app#21). Unlike [BenchmarkFixture], this always
/// carries an [expectedCorrectedText] so a harness can score the model's
/// `corrected_text` output deterministically.
class SecondPassFixture {
  const SecondPassFixture({
    required this.id,
    required this.inputText,
    required this.expectedCorrectedText,
    required this.cefrLevel,
    required this.errorFamilies,
    required this.intendedErrorCount,
    required this.note,
  });

  /// Short, unique, kebab-case identifier.
  final String id;

  /// The Spanish input text containing the intended error(s). Never longer
  /// than [appCharacterLimit].
  final String inputText;

  /// The single objectively-correct fix for [inputText] under the exact
  /// first-pass prompt/contract (grammar, spelling, and punctuation only —
  /// no word-choice, naturalness, style, tone, or regional rewrites).
  final String expectedCorrectedText;

  /// The CEFR level this fixture primarily targets.
  final CefrLevel cefrLevel;

  /// Which [ErrorFamily] value(s) this fixture exercises. A fixture may
  /// cover more than one family (e.g. a paragraph combining an accent
  /// error with an agreement error), in which case every family it
  /// actually exercises must be listed here.
  final List<ErrorFamily> errorFamilies;

  /// How many distinct objective errors [inputText] contains relative to
  /// [expectedCorrectedText].
  final int intendedErrorCount;

  /// Human-readable note describing the fixture's purpose and intended
  /// fix(es), for report/debugging use.
  final String note;
}

/// The harder second-pass first-pass comparison fixture subset (see
/// spanish_correction_app#21). Selectable independently of
/// [benchmarkFixtures] — a harness can run either set, or both, without
/// editing source, by choosing which top-level list to iterate.
const List<SecondPassFixture> secondPassFixtures = [
  SecondPassFixture(
    id: 'second-pass-accent-diacritics',
    inputText: 'Mi hermano vive en Mexico y estudia alli.',
    expectedCorrectedText: 'Mi hermano vive en México y estudia allí.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.accentDiacritics],
    intendedErrorCount: 2,
    note:
        'Missing accents only, no vocabulary rewrite required: '
        '"Mexico" -> "México", "alli" -> "allí".',
  ),
  SecondPassFixture(
    id: 'second-pass-gender-number-agreement',
    inputText: 'Ella tiene dos perro pequeño que viven en su casa.',
    expectedCorrectedText:
        'Ella tiene dos perros pequeños que viven en su casa.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.genderNumberAgreement],
    intendedErrorCount: 2,
    note:
        'Clear noun/adjective number agreement: "perro" -> "perros", '
        '"pequeño" -> "pequeños".',
  ),
  SecondPassFixture(
    id: 'second-pass-preposition-government',
    inputText: 'Ella depende en sus padres para pagar la universidad.',
    expectedCorrectedText: 'Ella depende de sus padres para pagar la universidad.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.prepositionGovernment],
    intendedErrorCount: 1,
    note:
        'Unambiguous required preposition: "depender de" (not "depender '
        'en"): "depende en" -> "depende de".',
  ),
  SecondPassFixture(
    id: 'second-pass-verb-morphology-agreement',
    inputText: 'Mis primos vive en Barcelona desde hace dos años.',
    expectedCorrectedText: 'Mis primos viven en Barcelona desde hace dos años.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.verbMorphologySubjectAgreement],
    intendedErrorCount: 1,
    note:
        'Clear plural subject with a singular verb: "primos vive" -> '
        '"primos viven".',
  ),
  SecondPassFixture(
    id: 'second-pass-articles-determiners',
    inputText: 'Tengo una problema grande con mi computadora nueva.',
    expectedCorrectedText:
        'Tengo un problema grande con mi computadora nueva.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.articlesDeterminers],
    intendedErrorCount: 1,
    note:
        '"problema" is masculine despite the -a ending, so the article '
        'must agree regardless of context: "una problema" -> "un '
        'problema".',
  ),
  SecondPassFixture(
    id: 'second-pass-subjunctive-trigger',
    inputText: 'Espero que tienes un buen día mañana.',
    expectedCorrectedText: 'Espero que tengas un buen día mañana.',
    cefrLevel: CefrLevel.b2,
    errorFamilies: [ErrorFamily.subjunctiveMood],
    intendedErrorCount: 1,
    note:
        'Unambiguous subjunctive trigger "Espero que...": "tienes" -> '
        '"tengas".',
  ),
  SecondPassFixture(
    id: 'second-pass-object-pronoun-agreement',
    inputText: 'Vi a mis hermanas ayer y lo saludé en la calle.',
    expectedCorrectedText: 'Vi a mis hermanas ayer y las saludé en la calle.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.objectPronounsClitics],
    intendedErrorCount: 1,
    note:
        'Direct object pronoun must agree in gender/number with '
        '"hermanas" (standard lo/la usage, not a leísmo/laísmo/loísmo '
        'case): "lo" -> "las".',
  ),
  SecondPassFixture(
    id: 'second-pass-ser-estar-locative',
    inputText: 'Mi oficina es en el tercer piso del edificio.',
    expectedCorrectedText: 'Mi oficina está en el tercer piso del edificio.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.serEstarHaber],
    intendedErrorCount: 1,
    note:
        'Unambiguous locative contrast: location requires "estar", not '
        '"ser": "es en" -> "está en".',
  ),
  SecondPassFixture(
    id: 'second-pass-personal-a',
    inputText: 'Vi Maria en el supermercado ayer por la tarde.',
    expectedCorrectedText: 'Vi a María en el supermercado ayer por la tarde.',
    cefrLevel: CefrLevel.b2,
    errorFamilies: [ErrorFamily.personalA, ErrorFamily.accentDiacritics],
    intendedErrorCount: 2,
    note:
        'Proper-name animate direct object requires personal "a": "Vi '
        'Maria" -> "Vi a María" (also missing accent on the name).',
  ),
  SecondPassFixture(
    id: 'second-pass-relative-clause-preposition',
    inputText: 'La empresa que trabajo está cerca de mi casa.',
    expectedCorrectedText:
        'La empresa en la que trabajo está cerca de mi casa.',
    cefrLevel: CefrLevel.b2,
    errorFamilies: [ErrorFamily.relativeClausePreposition],
    intendedErrorCount: 1,
    note:
        '"the company where/in which I work" requires the preposition '
        'inside the relative clause: "que trabajo" -> "en la que '
        'trabajo".',
  ),
  SecondPassFixture(
    id: 'second-pass-impersonal-haber',
    inputText:
        'En esta ciudad hay muchos museos, pero también habian demasiados '
        'turistas en verano.',
    expectedCorrectedText:
        'En esta ciudad hay muchos museos, pero también había demasiados '
        'turistas en verano.',
    cefrLevel: CefrLevel.b2,
    errorFamilies: [ErrorFamily.impersonalHaberOrSe],
    intendedErrorCount: 1,
    note:
        'Impersonal "haber" stays singular regardless of the following '
        'noun\'s number: "habian" -> "había".',
  ),
  SecondPassFixture(
    id: 'second-pass-sentence-boundaries',
    inputText:
        'No entendí bien la explicación del profesor era muy larga y '
        'confusa como puedo estudiar para el examen sin entender la '
        'materia',
    expectedCorrectedText:
        'No entendí bien la explicación del profesor; era muy larga y '
        'confusa. ¿Cómo puedo estudiar para el examen sin entender la '
        'materia?',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [ErrorFamily.punctuationSentenceBoundaries],
    intendedErrorCount: 2,
    note:
        'Clear run-on requiring a sentence break, plus missing opening/'
        'closing question marks around the embedded question.',
  ),
  SecondPassFixture(
    id: 'second-pass-mixed-b1-b2-paragraph',
    inputText:
        'El sabado fuimos a la playa con mis amigos, pero mi hermano no '
        'vino porque estaba enfermo. Cuando llegamos, buscamos un '
        'restaurante pero no habian mesas libres.',
    expectedCorrectedText:
        'El sábado fuimos a la playa con mis amigos, pero mi hermano no '
        'vino porque estaba enfermo. Cuando llegamos, buscamos un '
        'restaurante pero no había mesas libres.',
    cefrLevel: CefrLevel.b1,
    errorFamilies: [
      ErrorFamily.accentDiacritics,
      ErrorFamily.impersonalHaberOrSe,
    ],
    intendedErrorCount: 2,
    note:
        'Mixed B1-B2 paragraph with two independent objective errors: '
        '"sabado" -> "sábado" (accent), "habian" -> "había" (impersonal '
        'haber agreement).',
  ),
  SecondPassFixture(
    id: 'second-pass-mixed-b2-c1-paragraph',
    inputText:
        'El proyecto que trabajamos es muy interesante, y espero que lo '
        'terminamos a tiempo.',
    expectedCorrectedText:
        'El proyecto en el que trabajamos es muy interesante, y espero '
        'que lo terminemos a tiempo.',
    cefrLevel: CefrLevel.b2,
    errorFamilies: [
      ErrorFamily.relativeClausePreposition,
      ErrorFamily.subjunctiveMood,
    ],
    intendedErrorCount: 2,
    note:
        'Mixed B2-C1 paragraph involving subordination and mood: "que '
        'trabajamos" -> "en el que trabajamos" (relative clause '
        'preposition), "terminamos" -> "terminemos" (subjunctive after '
        '"espero que").',
  ),
  SecondPassFixture(
    id: 'second-pass-near-limit-mixed',
    inputText:
        'El sábado pasado fui a visitar Ana porque hacía mucho tiempo que '
        'no la veía y quería saber cómo le iba con su nuevo trabajo. Su '
        'apartamento es cerca del centro, en el quinto piso de un '
        'edificio antiguo que ella vive desde hace tres años y que le '
        'gusta mucho por la vista. Espero que ella consigue pronto un '
        'trabajo mejor, porque en su oficina actual habian demasiados '
        'problemas y ella depende en sus padres para pagar el alquiler '
        'mientras busca otra oportunidad.',
    expectedCorrectedText:
        'El sábado pasado fui a visitar a Ana porque hacía mucho tiempo '
        'que no la veía y quería saber cómo le iba con su nuevo trabajo. '
        'Su apartamento está cerca del centro, en el quinto piso de un '
        'edificio antiguo en el que ella vive desde hace tres años y que '
        'le gusta mucho por la vista. Espero que ella consiga pronto un '
        'trabajo mejor, porque en su oficina actual había demasiados '
        'problemas y ella depende de sus padres para pagar el alquiler '
        'mientras busca otra oportunidad.',
    cefrLevel: CefrLevel.b2,
    errorFamilies: [
      ErrorFamily.personalA,
      ErrorFamily.serEstarHaber,
      ErrorFamily.relativeClausePreposition,
      ErrorFamily.subjunctiveMood,
      ErrorFamily.impersonalHaberOrSe,
      ErrorFamily.prepositionGovernment,
    ],
    intendedErrorCount: 6,
    note:
        'Near-limit mixed text with six objective errors across six '
        'families: missing personal "a" before "Ana", "es" -> "está" '
        '(ser/estar), "que vive" -> "en el que vive" (relative clause '
        'preposition), "consigue" -> "consiga" (subjunctive), "habian" '
        '-> "había" (impersonal haber), "depende en" -> "depende de" '
        '(preposition government).',
  ),
];

/// Looks up a [SecondPassFixture] by its [SecondPassFixture.id].
///
/// Throws a [StateError] if [id] isn't present, so a typo in a harness
/// fails loudly instead of silently skipping a case.
SecondPassFixture secondPassFixtureById(String id) {
  return secondPassFixtures.firstWhere(
    (fixture) => fixture.id == id,
    orElse: () => throw StateError(
      'No second-pass fixture with id "$id". Available ids: '
      '${secondPassFixtures.map((fixture) => fixture.id).join(', ')}.',
    ),
  );
}

/// Returns every [SecondPassFixture] in [secondPassFixtures] that exercises
/// [family], in declaration order.
List<SecondPassFixture> secondPassFixturesForFamily(ErrorFamily family) {
  return secondPassFixtures
      .where((fixture) => fixture.errorFamilies.contains(family))
      .toList(growable: false);
}
