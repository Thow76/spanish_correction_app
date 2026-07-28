// Shared Spanish correction benchmark fixture set.
//
// Purpose: a small, shared set of representative natural-language inputs for
// latency/token-usage/cost/model-comparison benchmarking. This is fixture
// data only: it does not change prompts, model behavior, UI flow, production
// correction code, spans, categories, or explanations, and it intentionally
// carries no expected-output scoring.

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
