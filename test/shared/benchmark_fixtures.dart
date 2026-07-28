// Shared Spanish correction benchmark fixture set.
//
// Purpose: a small, shared set of representative natural-language inputs for
// latency/token-usage/cost/model-comparison benchmarking. This is fixture
// data only: it does not change prompts, model behavior, UI flow, production
// correction code, spans, categories, or explanations, and it intentionally
// carries no expected-output scoring.
//
// This file also defines a separate, harder second-pass fixture set (see
// `SecondPassFixture`/`secondPassFixtures`/`harderSecondPassFixtures` below)
// for scored first-pass comparison runs targeting objective B1-C1 Spanish
// grammar, spelling, and punctuation error families. It is additive: it does
// not replace or modify the fixtures above.

/// Approximate input-length band a [BenchmarkFixture] falls into.
enum BenchmarkLengthBand {
  /// A few words, well under one full sentence.
  shortPhrase,

  /// One sentence, or a very short one- to two-sentence paragraph.
  sentenceOrShortParagraph,

  /// A single natural-language paragraph of several sentences.
  paragraph,

  /// Two natural-language paragraphs with a blank line between them.
  twoParagraph,

  /// Close to, but never over, the app's 600-character input limit.
  nearLimit,
}

/// Whether a fixture contains objective correction targets or is a control
/// that should remain unchanged by a grammar/spelling/punctuation-only prompt.
enum BenchmarkFixtureKind {
  /// Contains at least one objective grammar, spelling, or punctuation error.
  correction,

  /// Already valid Spanish for this prompt's narrow correction scope.
  control,
}

/// The app's correction input character limit, duplicated here so fixture
/// tests can enforce the benchmark invariant without importing production UI.
const int appCharacterLimit = 600;

/// One shared benchmark input plus metadata for filtering/reporting.
class BenchmarkFixture {
  const BenchmarkFixture({
    required this.id,
    required this.text,
    required this.note,
    required this.lengthBand,
    required this.kind,
    this.isAccentSensitive = false,
    this.isCalcsStyle = false,
    this.isValidRegionalSpanish = false,
  });

  /// Short, unique, stable identifier for reports and harness filters.
  final String id;

  /// The Spanish input text itself. Never longer than [appCharacterLimit].
  final String text;

  /// What this fixture is intended to exercise. This is not an expected output.
  final String note;

  /// Approximate input-length bucket.
  final BenchmarkLengthBand lengthBand;

  /// Whether this is an objective correction case or a control case.
  final BenchmarkFixtureKind kind;

  /// Whether this case specifically exercises accents, diacritics, ñ, or
  /// inverted punctuation that should survive the model round trip.
  final bool isAccentSensitive;

  /// Whether this is CALCS-style bilingual-contact natural language, such as
  /// a calque or English-influenced construction.
  final bool isCalcsStyle;

  /// Whether this control uses valid regional Spanish that the prompt must not
  /// normalize away.
  final bool isValidRegionalSpanish;

  bool get isCorrectionCase => kind == BenchmarkFixtureKind.correction;

  bool get isControlCase => kind == BenchmarkFixtureKind.control;
}

const BenchmarkFixture shortPhraseMissingAccent = BenchmarkFixture(
  id: 'short-phrase-missing-accent',
  text: 'Voy al parque manana por la tarde.',
  note:
      'Short correction case: missing accent on "mañana". Exercises the '
      'shortest-input latency/cost floor with one objective spelling fix.',
  lengthBand: BenchmarkLengthBand.shortPhrase,
  kind: BenchmarkFixtureKind.correction,
  isAccentSensitive: true,
);

const BenchmarkFixture shortPhraseAlreadyCorrect = BenchmarkFixture(
  id: 'short-phrase-already-correct',
  text: 'Buenos días, ¿cómo estás?',
  note:
      'Short control case: already-correct Spanish with accents and inverted '
      'question punctuation that should survive unchanged.',
  lengthBand: BenchmarkLengthBand.shortPhrase,
  kind: BenchmarkFixtureKind.control,
  isAccentSensitive: true,
);

const BenchmarkFixture sentenceGrammarAgreement = BenchmarkFixture(
  id: 'sentence-grammar-agreement',
  text: 'Los niño come muchas manzana en el jardín.',
  note:
      'Sentence correction case: objective plural agreement errors in noun '
      'phrases and verb agreement.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  kind: BenchmarkFixtureKind.correction,
);

const BenchmarkFixture sentencePunctuationQuestion = BenchmarkFixture(
  id: 'sentence-punctuation-question',
  text: 'Como estas hoy Necesito saber si vienes a la fiesta',
  note:
      'Sentence correction case: missing accents, question punctuation, and '
      'sentence-final punctuation.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  kind: BenchmarkFixtureKind.correction,
  isAccentSensitive: true,
);

const BenchmarkFixture sentenceCorrectVoseo = BenchmarkFixture(
  id: 'sentence-correct-voseo',
  text: 'Vos tenés razón, che, así que dale nomás.',
  note:
      'Regional control case: valid Argentine voseo/regional Spanish. The '
      'first-pass prompt must not normalize it to "tú tienes".',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  kind: BenchmarkFixtureKind.control,
  isAccentSensitive: true,
  isValidRegionalSpanish: true,
);

const BenchmarkFixture sentenceRegionalWordChoice = BenchmarkFixture(
  id: 'sentence-regional-word-choice',
  text: 'Voy a coger el autobús para ir al trabajo.',
  note:
      'Regional/word-choice control case: valid Spanish for this prompt. '
      '"coger" must not be rewritten as a grammar/spelling/punctuation fix.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  kind: BenchmarkFixtureKind.control,
  isAccentSensitive: true,
  isValidRegionalSpanish: true,
);

const BenchmarkFixture paragraphCalcsNatural = BenchmarkFixture(
  id: 'paragraph-calcs-natural',
  text:
      '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos '
      'esta noche porque llevamos mucho tiempo sin vernos y tenemos que '
      'ponernos al día con todo lo que ha pasado este año.',
  note:
      'Paragraph control case: CALCS-style natural language with English-like '
      'calques. Useful for over-correction observation without expected-output '
      'scoring.',
  lengthBand: BenchmarkLengthBand.paragraph,
  kind: BenchmarkFixtureKind.control,
  isAccentSensitive: true,
  isCalcsStyle: true,
);

const BenchmarkFixture paragraphMixedErrors = BenchmarkFixture(
  id: 'paragraph-mixed-errors',
  text:
      'Ayer fui a la tienda y compre pan, leche y unas manzana. Cuando llegue '
      'a casa mi hermano me pregunto si queria ayudarlo con la tarea, pero yo '
      'estaba muy cansado despues del trabajo',
  note:
      'Paragraph correction case: several independent grammar, spelling, and '
      'punctuation errors across a natural paragraph.',
  lengthBand: BenchmarkLengthBand.paragraph,
  kind: BenchmarkFixtureKind.correction,
  isAccentSensitive: true,
);

const BenchmarkFixture twoParagraphAlreadyCorrect = BenchmarkFixture(
  id: 'two-paragraph-already-correct',
  text:
      'Mañana visitaré a mi abuela en su pequeño pueblo junto al río. Ella '
      'siempre prepara una comida deliciosa y me cuenta historias de cuando '
      'era joven.\n\n'
      'Después de la visita, pienso caminar por el bosque cercano antes de que '
      'oscurezca, porque me encanta escuchar el sonido de los pájaros al '
      'atardecer.',
  note:
      'Two-paragraph control case: already-correct Spanish at a longer input '
      'length, isolating length-driven token growth from objective fixes.',
  lengthBand: BenchmarkLengthBand.twoParagraph,
  kind: BenchmarkFixtureKind.control,
  isAccentSensitive: true,
);

const BenchmarkFixture twoParagraphMixedErrors = BenchmarkFixture(
  id: 'two-paragraph-mixed-errors',
  text:
      'El sabado pasado fuimos al cine con mis amigos y vimos una pelicula '
      'muy interesante sobre un viaje al espacio. Despues cenamos en un '
      'restaurante cerca del centro comercial.\n\n'
      'Mi amigo Carlos penso que la pelicula fue aburrida, pero yo creo que '
      'fue emocionante. Vamos a repetir el plan el proximo fin de semana si '
      'todos estan libres',
  note:
      'Two-paragraph correction case: accent and punctuation errors spread '
      'across both paragraphs.',
  lengthBand: BenchmarkLengthBand.twoParagraph,
  kind: BenchmarkFixtureKind.correction,
  isAccentSensitive: true,
);

const BenchmarkFixture nearLimitFullText = BenchmarkFixture(
  id: 'near-limit-full-text',
  text:
      'El fin de semana pasado decidimos hacer un viaje corto a la montaña '
      'para descansar del trabajo y de la ciudad. Salimos muy temprano, antes '
      'de que saliera el sol, y llegamos al pequeño pueblo justo a tiempo para '
      'desayunar en un cafe que mi hermano habia recomendado. Durante la tarde '
      'caminamos por un sendero cerca del rio, sacamos muchas foto y hablamos '
      'de nuestros planes para el proximo año. Cuando volvimos al hotel, todos '
      'estabamos muy cansados pero contentos, y decidimos que teniamos que '
      'regresar pronto porque el lugar nos habia gustado mucho a todos.',
  note:
      'Near-600-character correction case: a realistic full-text input with '
      'accent, agreement, and spelling errors spread throughout.',
  lengthBand: BenchmarkLengthBand.nearLimit,
  kind: BenchmarkFixtureKind.correction,
  isAccentSensitive: true,
);

/// The shared fixture pool. Small and fixed on purpose: this is for routine
/// live benchmark runs, not exhaustive language-quality regression testing.
const List<BenchmarkFixture> benchmarkFixtures = [
  shortPhraseMissingAccent,
  shortPhraseAlreadyCorrect,
  sentenceGrammarAgreement,
  sentencePunctuationQuestion,
  sentenceCorrectVoseo,
  sentenceRegionalWordChoice,
  paragraphCalcsNatural,
  paragraphMixedErrors,
  twoParagraphAlreadyCorrect,
  twoParagraphMixedErrors,
  nearLimitFullText,
];

/// The deliberate first-pass subset used by `test/model_comparison_harness.dart`.
///
/// It keeps live model comparison runs reasonably small while covering short,
/// paragraph, two-paragraph, near-limit/full-text, CALCS-style, accent-sensitive,
/// already-correct, and valid regional Spanish control scenarios.
const List<BenchmarkFixture> firstPassModelComparisonFixtures = [
  shortPhraseMissingAccent,
  sentenceGrammarAgreement,
  sentencePunctuationQuestion,
  sentenceCorrectVoseo,
  sentenceRegionalWordChoice,
  paragraphCalcsNatural,
  paragraphMixedErrors,
  twoParagraphAlreadyCorrect,
  nearLimitFullText,
];

BenchmarkFixture benchmarkFixtureById(String id) {
  return benchmarkFixtures.firstWhere(
    (fixture) => fixture.id == id,
    orElse: () => throw StateError(
      'No benchmark fixture with id "$id". Available ids: '
      '${benchmarkFixtures.map((fixture) => fixture.id).join(', ')}.',
    ),
  );
}

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
// Purpose: a harder, scored fixture set for the same bare first-pass prompt
// (see `test/model_comparison_harness.dart`), focused systematically on
// objective B1-C1 Spanish grammar, spelling, and punctuation error families.
// This is fixture data only: it does not change the first-pass prompt, the
// JSON response contract, model defaults/pricing, scoring/classification
// logic, or the live benchmark runner. It is intentionally separate from
// [benchmarkFixtures]/[firstPassModelComparisonFixtures], which remain
// unchanged, and is not wired into the live model-comparison harness.
//
// Fixture language stays clear and ordinary. Every fixture targets one
// primary error family (or, for mixed paragraphs and the near-limit case,
// two or more) and avoids naturalness, style, tone, calque, collocation, or
// regional-preference traps.
// ---------------------------------------------------------------------------

/// The objective B1-C1 Spanish grammar/spelling/punctuation error families
/// this harder second-pass fixture set is organised around.
enum SecondPassErrorFamily {
  /// Missing or incorrect accent marks, diacritics, or homophone spelling.
  accentsDiacritics,

  /// Article/noun/adjective gender or number agreement.
  genderNumberAgreement,

  /// A verb, adjective, or noun used with the wrong required preposition.
  prepositionGovernment,

  /// Subject-verb agreement or other verb morphology errors.
  verbMorphologyAgreement,

  /// Missing or incorrect article/determiner, including contractions.
  articlesDeterminers,

  /// Subjunctive, indicative, or conditional mood selection.
  subjunctiveMood,

  /// Object pronoun choice, clitic placement, or pronominal verb errors.
  objectPronounsClitics,

  /// `ser`, `estar`, or `haber` selection.
  serEstarHaber,

  /// Missing personal `a` before an animate direct object.
  personalA,

  /// A relative clause missing its required preposition.
  relativeClausePreposition,

  /// Impersonal/existential `haber` or passive/impersonal `se` agreement.
  impersonalHaberOrSe,

  /// Sentence boundaries, commas, or opening question/exclamation marks.
  sentenceBoundariesPunctuation,
}

/// Approximate shape of a [SecondPassFixture], for reporting/coverage checks
/// only. Not the same enum as [BenchmarkLengthBand]: this fixture set is
/// scored, sentence/paragraph oriented, and deliberately smaller in scope.
enum SecondPassFixtureShape { shortPhrase, sentence, paragraph, nearLimit }

/// One harder second-pass fixture: an input plus the exact expected
/// corrected text for deterministic scoring, and metadata describing which
/// objective error family or families it targets.
class SecondPassFixture {
  const SecondPassFixture({
    required this.id,
    required this.inputText,
    required this.expectedCorrectedText,
    required this.cefrLevel,
    required this.errorFamilies,
    required this.errorCount,
    required this.note,
    required this.shape,
    this.isHarderSecondPassSubset = true,
  }) : assert(errorCount > 0, 'errorCount must be positive');

  /// Short, unique, stable identifier for reports and harness filters.
  final String id;

  /// The Spanish input text, containing the intended objective error(s).
  final String inputText;

  /// The exact expected corrected text for deterministic scoring.
  final String expectedCorrectedText;

  /// CEFR target level, such as `B1`, `B2`, `C1`, or a range like `B1-B2`.
  final String cefrLevel;

  /// The objective error family or families this fixture targets.
  final List<SecondPassErrorFamily> errorFamilies;

  /// The number of intended objective corrections in [expectedCorrectedText].
  final int errorCount;

  /// What this fixture is intended to exercise, and why.
  final String note;

  /// Approximate shape: short phrase, sentence, paragraph, or near-limit.
  final SecondPassFixtureShape shape;

  /// Whether this fixture is part of the named harder second-pass subset
  /// used for the required-coverage comparison run.
  final bool isHarderSecondPassSubset;
}

const SecondPassFixture secondPassAccentDiacritics = SecondPassFixture(
  id: 'second-pass-accent-diacritics',
  inputText: 'Mi numero de telefono es facil de recordar.',
  expectedCorrectedText: 'Mi número de teléfono es fácil de recordar.',
  cefrLevel: 'B1-B2',
  errorFamilies: [SecondPassErrorFamily.accentsDiacritics],
  errorCount: 3,
  note:
      'Short phrase: missing accents only ("número", "teléfono", "fácil"). '
      'No vocabulary rewrite required.',
  shape: SecondPassFixtureShape.shortPhrase,
);

const SecondPassFixture secondPassGenderNumberAgreement = SecondPassFixture(
  id: 'second-pass-gender-number-agreement',
  inputText: 'Compré unos camisa nuevo para la fiesta.',
  expectedCorrectedText: 'Compré unas camisas nuevas para la fiesta.',
  cefrLevel: 'B1-B2',
  errorFamilies: [SecondPassErrorFamily.genderNumberAgreement],
  errorCount: 3,
  note:
      'Clear article/noun/adjective gender and number agreement: '
      '"unos camisa nuevo" should all be feminine plural.',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassPrepositionGovernment = SecondPassFixture(
  id: 'second-pass-preposition-government',
  inputText: 'Este curso consiste de seis módulos.',
  expectedCorrectedText: 'Este curso consiste en seis módulos.',
  cefrLevel: 'B1-B2',
  errorFamilies: [SecondPassErrorFamily.prepositionGovernment],
  errorCount: 1,
  note: 'Unambiguous required preposition: "consistir" takes "en", not "de".',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassVerbMorphologyAgreement = SecondPassFixture(
  id: 'second-pass-verb-morphology-agreement',
  inputText: 'Mis padres vive en Madrid desde hace diez años.',
  expectedCorrectedText: 'Mis padres viven en Madrid desde hace diez años.',
  cefrLevel: 'B1-B2',
  errorFamilies: [SecondPassErrorFamily.verbMorphologyAgreement],
  errorCount: 1,
  note:
      'Clear plural subject ("Mis padres") with a mismatched singular verb '
      '("vive" instead of "viven").',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassArticlesDeterminers = SecondPassFixture(
  id: 'second-pass-articles-determiners',
  inputText: 'Voy a mercado a comprar fruta.',
  expectedCorrectedText: 'Voy al mercado a comprar fruta.',
  cefrLevel: 'B1-B2',
  errorFamilies: [SecondPassErrorFamily.articlesDeterminers],
  errorCount: 1,
  note:
      'Clear required article/contraction: "a" + "el mercado" must become '
      '"al mercado", avoiding any context-dependent article choice.',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassSubjunctiveMood = SecondPassFixture(
  id: 'second-pass-subjunctive-mood',
  inputText: 'Espero que tú vienes a la fiesta mañana.',
  expectedCorrectedText: 'Espero que tú vengas a la fiesta mañana.',
  cefrLevel: 'B1-C1',
  errorFamilies: [SecondPassErrorFamily.subjunctiveMood],
  errorCount: 1,
  note:
      'Unambiguous subjunctive trigger "Espero que..." requires "vengas", '
      'not the indicative "vienes".',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassObjectPronounsClitics = SecondPassFixture(
  id: 'second-pass-object-pronouns-clitics',
  inputText: 'Compré las flores y se los di a mi novia.',
  expectedCorrectedText: 'Compré las flores y se las di a mi novia.',
  cefrLevel: 'B1-B2',
  errorFamilies: [SecondPassErrorFamily.objectPronounsClitics],
  errorCount: 1,
  note:
      'Direct object clitic must agree with feminine plural "las flores" '
      '("las", not "los"). Not a leísmo/laísmo/loísmo case.',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassSerEstarHaber = SecondPassFixture(
  id: 'second-pass-ser-estar-haber',
  inputText: 'En la nevera está mucha comida para la fiesta.',
  expectedCorrectedText: 'En la nevera hay mucha comida para la fiesta.',
  cefrLevel: 'B1-B2',
  errorFamilies: [SecondPassErrorFamily.serEstarHaber],
  errorCount: 1,
  note:
      'Unambiguous existential contrast: an indefinite quantity in a place '
      'requires existential "hay", not "está".',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassPersonalA = SecondPassFixture(
  id: 'second-pass-personal-a',
  inputText: 'Ayer vi María en el parque.',
  expectedCorrectedText: 'Ayer vi a María en el parque.',
  cefrLevel: 'B1-C1',
  errorFamilies: [SecondPassErrorFamily.personalA],
  errorCount: 1,
  note: 'Proper-name animate direct object requires the personal "a".',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassRelativeClausePreposition = SecondPassFixture(
  id: 'second-pass-relative-clause-preposition',
  inputText: 'La empresa que trabajo está cerca de mi casa.',
  expectedCorrectedText: 'La empresa en la que trabajo está cerca de mi casa.',
  cefrLevel: 'B2-C1',
  errorFamilies: [SecondPassErrorFamily.relativeClausePreposition],
  errorCount: 1,
  note:
      '"Trabajar en la empresa" requires the preposition to carry into the '
      'relative clause: "la empresa en la que trabajo".',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassImpersonalHaberOrSe = SecondPassFixture(
  id: 'second-pass-impersonal-haber-or-se',
  inputText: 'Se vende zapatos muy baratos en esa tienda.',
  expectedCorrectedText: 'Se venden zapatos muy baratos en esa tienda.',
  cefrLevel: 'B2-C1',
  errorFamilies: [SecondPassErrorFamily.impersonalHaberOrSe],
  errorCount: 1,
  note:
      'Passive/impersonal "se" must agree with the plural subject '
      '"zapatos": "se venden", not "se vende".',
  shape: SecondPassFixtureShape.sentence,
);

const SecondPassFixture secondPassSentenceBoundariesPunctuation =
    SecondPassFixture(
      id: 'second-pass-sentence-boundaries-punctuation',
      inputText:
          'Quiero preguntarte algo importante puedes ayudarme mañana no '
          'tengo mucho tiempo esta semana',
      expectedCorrectedText:
          'Quiero preguntarte algo importante. ¿Puedes ayudarme mañana? No '
          'tengo mucho tiempo esta semana.',
      cefrLevel: 'B1-B2',
      errorFamilies: [SecondPassErrorFamily.sentenceBoundariesPunctuation],
      errorCount: 3,
      note:
          'Run-on paragraph missing sentence boundaries and opening/closing '
          'question punctuation across three clauses.',
      shape: SecondPassFixtureShape.paragraph,
    );

const SecondPassFixture secondPassMixedB1B2Paragraph = SecondPassFixture(
  id: 'second-pass-mixed-b1-b2-paragraph',
  inputText:
      'Ayer fui a comprar unos zapato nuevo, pero cuando llegué a la '
      'tienda no había mi talla. El dependiente me dijo que la tienda '
      'consiste de tallas limitadas ese mes.',
  expectedCorrectedText:
      'Ayer fui a comprar unos zapatos nuevos, pero cuando llegué a la '
      'tienda no había mi talla. El dependiente me dijo que la tienda '
      'consiste en tallas limitadas ese mes.',
  cefrLevel: 'B1-B2',
  errorFamilies: [
    SecondPassErrorFamily.genderNumberAgreement,
    SecondPassErrorFamily.prepositionGovernment,
  ],
  errorCount: 3,
  note:
      'Mixed B1-B2 paragraph: noun/adjective number agreement plus a '
      'required-preposition error ("consiste de" -> "consiste en").',
  shape: SecondPassFixtureShape.paragraph,
);

const SecondPassFixture secondPassMixedB2C1Paragraph = SecondPassFixture(
  id: 'second-pass-mixed-b2-c1-paragraph',
  inputText:
      'La reunión que asistí ayer fue muy productiva. Espero que podemos '
      'continuar con este proyecto la próxima semana.',
  expectedCorrectedText:
      'La reunión a la que asistí ayer fue muy productiva. Espero que '
      'podamos continuar con este proyecto la próxima semana.',
  cefrLevel: 'B2-C1',
  errorFamilies: [
    SecondPassErrorFamily.relativeClausePreposition,
    SecondPassErrorFamily.subjunctiveMood,
  ],
  errorCount: 2,
  note:
      'Mixed B2-C1 paragraph: a relative clause missing its required '
      'preposition ("asistir a") plus a subjunctive-trigger mismatch.',
  shape: SecondPassFixtureShape.paragraph,
);

const SecondPassFixture secondPassNearLimitMixedText = SecondPassFixture(
  id: 'second-pass-near-limit-mixed-text',
  inputText:
      'El fin de semana pasado fui a visitar a mi amigo Carlos, que vive '
      'en una pequeño pueblo cerca de la montaña. Cuando llegué, él me '
      'dijo que esperaba que yo me quedara todo el fin de semana, pero yo '
      'le dije que solo podia quedarme dos dias porque el lunes tengo que '
      'trabajar temprano. Caminamos por el sendero que pasa cerca del '
      'rio, y hablamos mucho de nuestros planes para el proximo año. '
      'Carlos insistio en que yo pruebo la comida tipica del pueblo, y al '
      'final prometi que iba a volver pronto porque el lugar me habia '
      'gustado mucho a mi.',
  expectedCorrectedText:
      'El fin de semana pasado fui a visitar a mi amigo Carlos, que vive '
      'en un pequeño pueblo cerca de la montaña. Cuando llegué, él me '
      'dijo que esperaba que yo me quedara todo el fin de semana, pero yo '
      'le dije que solo podía quedarme dos días porque el lunes tengo que '
      'trabajar temprano. Caminamos por el sendero que pasa cerca del '
      'río, y hablamos mucho de nuestros planes para el próximo año. '
      'Carlos insistió en que yo probara la comida típica del pueblo, y '
      'al final prometí que iba a volver pronto porque el lugar me había '
      'gustado mucho a mí.',
  cefrLevel: 'B2-C1',
  errorFamilies: [
    SecondPassErrorFamily.genderNumberAgreement,
    SecondPassErrorFamily.accentsDiacritics,
    SecondPassErrorFamily.subjunctiveMood,
  ],
  errorCount: 11,
  note:
      'Near-limit mixed text: gender agreement, a subjunctive-trigger '
      'mismatch ("insistir en que" + subjunctive), and numerous missing '
      'accents, all objective and all from the required error families.',
  shape: SecondPassFixtureShape.nearLimit,
);

/// The full harder second-pass fixture pool, organised around the objective
/// B1-C1 error families this issue targets. Additive to, and independent of,
/// [benchmarkFixtures]/[firstPassModelComparisonFixtures].
const List<SecondPassFixture> secondPassFixtures = [
  secondPassAccentDiacritics,
  secondPassGenderNumberAgreement,
  secondPassPrepositionGovernment,
  secondPassVerbMorphologyAgreement,
  secondPassArticlesDeterminers,
  secondPassSubjunctiveMood,
  secondPassObjectPronounsClitics,
  secondPassSerEstarHaber,
  secondPassPersonalA,
  secondPassRelativeClausePreposition,
  secondPassImpersonalHaberOrSe,
  secondPassSentenceBoundariesPunctuation,
  secondPassMixedB1B2Paragraph,
  secondPassMixedB2C1Paragraph,
  secondPassNearLimitMixedText,
];

/// The named harder second-pass first-pass comparison subset: every fixture
/// in [secondPassFixtures] flagged as part of it. Selectable independently
/// of the original first-pass fixture set.
List<SecondPassFixture> get harderSecondPassFixtures => secondPassFixtures
    .where((fixture) => fixture.isHarderSecondPassSubset)
    .toList(growable: false);

SecondPassFixture secondPassFixtureById(String id) {
  return secondPassFixtures.firstWhere(
    (fixture) => fixture.id == id,
    orElse: () => throw StateError(
      'No second-pass fixture with id "$id". Available ids: '
      '${secondPassFixtures.map((fixture) => fixture.id).join(', ')}.',
    ),
  );
}
