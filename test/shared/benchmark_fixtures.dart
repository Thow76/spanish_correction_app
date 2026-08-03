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

/// CEFR target band the fixture is intended to approximate.
enum BenchmarkCefrTargetLevel { b1, b2, c1 }

/// Objective error families used by scored comparison fixtures.
enum ObjectiveSpanishErrorFamily {
  accentMarksDiacritics,
  genderNumberAgreement,
  prepositionGovernment,
  verbMorphologySubjectVerbAgreement,
  articlesDeterminers,
  subjunctiveMood,
  objectPronounsClitics,
  serEstarHaber,
  personalA,
  relativeClauseRequiredPreposition,
  impersonalHaberPassiveImpersonalSe,
  sentenceBoundariesPunctuation,
}

/// Boundary-control fixture groups for restraint-focused first-pass runs.
enum BoundaryFixtureGroup {
  unchangedBoundaryControl('unchanged_boundary_control'),
  wordChoiceBoundaryControl('word_choice_boundary_control'),
  grammarBoundaryCorrection('grammar_boundary_correction');

  const BoundaryFixtureGroup(this.reportLabel);

  final String reportLabel;
}

/// Narrow boundary type exercised by a boundary-control fixture.
enum BoundaryType {
  redundantPronoun('redundant_pronoun'),
  regionalUsage('regional_usage'),
  tensePreference('tense_preference'),
  calque('calque'),
  collocation('collocation'),
  agreement('agreement'),
  omission('omission'),
  serEstar('ser/estar'),
  // Issue #109: a word that looks like an English cognate but means
  // something else (e.g. "atender" vs "attend") — word choice, same as
  // calque/collocation, but a distinct enough pattern (no calqued phrase,
  // no wrong verb-noun pairing — just the wrong single word) to name on
  // its own rather than folding into calque.
  falseFriend('false_friend');

  const BoundaryType(this.reportLabel);

  final String reportLabel;
}

/// Expected behavior for a boundary-control fixture under the first-pass prompt.
enum BoundaryExpectedBehavior {
  unchanged('unchanged'),
  corrected('corrected');

  const BoundaryExpectedBehavior(this.reportLabel);

  final String reportLabel;
}

/// Expected behavior for lexical-collocation fixture runs.
enum LexicalCollocationFixtureRole {
  unchangedControl('unchanged control'),
  expectedCorrection('expected correction');

  const LexicalCollocationFixtureRole(this.reportLabel);

  final String reportLabel;
}

/// Expected behavior for naturalness-only fixture runs.
enum NaturalnessFixtureRole {
  unchangedControl('unchanged control'),
  expectedIssue('expected naturalness issue'),
  grammarTrap('grammar trap');

  const NaturalnessFixtureRole(this.reportLabel);

  final String reportLabel;
}

/// Naturalness issue type intentionally present in a fixture.
enum NaturalnessIssueType {
  naturalness('naturalness'),
  calque('calque'),
  collocation('collocation'),
  wordChoice('word choice'),
  idiom('idiom');

  const NaturalnessIssueType(this.reportLabel);

  final String reportLabel;
}

/// A scored benchmark fixture for exact corrected-text comparison.
class ScoredBenchmarkFixture extends BenchmarkFixture {
  const ScoredBenchmarkFixture({
    required super.id,
    required super.text,
    required super.note,
    required super.lengthBand,
    required this.expectedCorrectedText,
    required this.cefrTargetLevel,
    required this.errorFamilies,
    required this.intendedErrorCount,
    super.isAccentSensitive = false,
  }) : assert(intendedErrorCount > 0),
       super(kind: BenchmarkFixtureKind.correction);

  /// Exact expected output for narrow grammar/spelling/punctuation scoring.
  final String expectedCorrectedText;

  /// Approximate CEFR level represented by the text.
  final BenchmarkCefrTargetLevel cefrTargetLevel;

  /// Objective error categories intentionally present in [text].
  final Set<ObjectiveSpanishErrorFamily> errorFamilies;

  /// Number of intended objective corrections in [expectedCorrectedText].
  final int intendedErrorCount;
}

/// A restraint-focused scored fixture for boundary-control runs.
class BoundaryControlBenchmarkFixture extends BenchmarkFixture {
  const BoundaryControlBenchmarkFixture({
    required String id,
    required String text,
    required String note,
    required this.expectedCorrectedText,
    required this.fixtureGroup,
    required this.boundaryType,
    required this.expectedBehavior,
    required this.isOverCorrectionSensitive,
    BenchmarkLengthBand lengthBand =
        BenchmarkLengthBand.sentenceOrShortParagraph,
    bool isAccentSensitive = false,
    bool isCalcsStyle = false,
    bool isValidRegionalSpanish = false,
  }) : assert(
         (expectedBehavior == BoundaryExpectedBehavior.unchanged &&
                 expectedCorrectedText == text) ||
             (expectedBehavior == BoundaryExpectedBehavior.corrected &&
                 expectedCorrectedText != text),
       ),
       super(
         id: id,
         text: text,
         note: note,
         lengthBand: lengthBand,
         kind: expectedBehavior == BoundaryExpectedBehavior.corrected
             ? BenchmarkFixtureKind.correction
             : BenchmarkFixtureKind.control,
         isAccentSensitive: isAccentSensitive,
         isCalcsStyle: isCalcsStyle,
         isValidRegionalSpanish: isValidRegionalSpanish,
       );

  /// Exact expected output for narrow grammar/spelling/punctuation scoring.
  final String expectedCorrectedText;

  /// Which restraint/correction boundary this fixture belongs to.
  final BoundaryFixtureGroup fixtureGroup;

  /// More specific linguistic boundary under test.
  final BoundaryType boundaryType;

  /// Whether the prompt should leave this input alone or correct it.
  final BoundaryExpectedBehavior expectedBehavior;

  /// Whether changed output should be interpreted as an over-correction signal.
  final bool isOverCorrectionSensitive;
}

/// A targeted verb-noun lexical-collocation fixture.
///
/// These fixtures deliberately exercise lexical selection rather than broad
/// naturalness. Controls assert that valid verb-noun collocations stay
/// unchanged; correction cases assert the conventional verb for the noun.
class LexicalCollocationBenchmarkFixture extends BenchmarkFixture {
  const LexicalCollocationBenchmarkFixture({
    required String id,
    required String text,
    required String note,
    required this.expectedCorrectedText,
    required this.role,
    BenchmarkLengthBand lengthBand =
        BenchmarkLengthBand.sentenceOrShortParagraph,
    bool isAccentSensitive = false,
  }) : assert(
         (role == LexicalCollocationFixtureRole.unchangedControl &&
                 expectedCorrectedText == text) ||
             (role == LexicalCollocationFixtureRole.expectedCorrection &&
                 expectedCorrectedText != text),
       ),
       super(
         id: id,
         text: text,
         note: note,
         lengthBand: lengthBand,
         kind: role == LexicalCollocationFixtureRole.expectedCorrection
             ? BenchmarkFixtureKind.correction
             : BenchmarkFixtureKind.control,
         isAccentSensitive: isAccentSensitive,
       );

  /// Exact expected output for lexical-collocation comparison.
  final String expectedCorrectedText;

  /// Whether this fixture should remain unchanged or receive a correction.
  final LexicalCollocationFixtureRole role;
}

/// One expected naturalness issue in a fixture.
class ExpectedNaturalnessIssue {
  const ExpectedNaturalnessIssue({
    required this.span,
    required this.naturalReplacement,
    required this.issueType,
  });

  /// Smallest problematic span expected to be identified.
  final String span;

  /// A natural replacement that represents the intended correction.
  final String naturalReplacement;

  /// Linguistic type represented by this issue.
  final NaturalnessIssueType issueType;
}

/// A fixture for the naturalness-only model comparison harness.
///
/// These fixtures deliberately ask a model to identify wording that is
/// grammatical and understandable but unlikely to be used naturally. Controls
/// and grammar traps should return no naturalness issues.
class NaturalnessBenchmarkFixture extends BenchmarkFixture {
  const NaturalnessBenchmarkFixture({
    required String id,
    required String text,
    required String note,
    required this.role,
    required this.expectedIssues,
    this.ignoredSpans = const [],
    BenchmarkLengthBand lengthBand =
        BenchmarkLengthBand.sentenceOrShortParagraph,
    bool isAccentSensitive = false,
    bool isCalcsStyle = false,
    bool isValidRegionalSpanish = false,
  }) : super(
         id: id,
         text: text,
         note: note,
         lengthBand: lengthBand,
         kind: role == NaturalnessFixtureRole.expectedIssue
             ? BenchmarkFixtureKind.correction
             : BenchmarkFixtureKind.control,
         isAccentSensitive: isAccentSensitive,
         isCalcsStyle: isCalcsStyle,
         isValidRegionalSpanish: isValidRegionalSpanish,
       );

  /// Expected behavior for the naturalness-only prompt.
  final NaturalnessFixtureRole role;

  /// Naturalness issues that should be returned. Empty for controls and
  /// grammar traps.
  final List<ExpectedNaturalnessIssue> expectedIssues;

  /// Spans that are deliberately present but should not be reported by a
  /// naturalness-only prompt, such as spelling or grammar traps.
  final List<String> ignoredSpans;
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

const BoundaryControlBenchmarkFixture boundaryRedundantYo =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-redundant-yo',
      text: 'Yo trabajo mucho y yo también estudio por las noches.',
      expectedCorrectedText:
          'Yo trabajo mucho y yo también estudio por las noches.',
      note:
          'Pure unchanged boundary control: tests whether the model removes '
          'redundant but grammatical subject pronouns.',
      fixtureGroup: BoundaryFixtureGroup.unchangedBoundaryControl,
      boundaryType: BoundaryType.redundantPronoun,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
    );

const BoundaryControlBenchmarkFixture boundaryRedundantEllos =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-redundant-ellos',
      text: 'Ellos viajaron a México y ellos visitaron varias ciudades.',
      expectedCorrectedText:
          'Ellos viajaron a México y ellos visitaron varias ciudades.',
      note:
          'Pure unchanged boundary control: tests whether the model removes '
          'repeated but grammatical subject pronouns.',
      fixtureGroup: BoundaryFixtureGroup.unchangedBoundaryControl,
      boundaryType: BoundaryType.redundantPronoun,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
    );

const BoundaryControlBenchmarkFixture boundaryParaCasa =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-para-casa',
      text: 'Está lloviendo, así que voy para casa ahora mismo.',
      expectedCorrectedText:
          'Está lloviendo, así que voy para casa ahora mismo.',
      note:
          'Pure unchanged boundary control: tests whether the model '
          'incorrectly normalizes valid "para casa" usage.',
      fixtureGroup: BoundaryFixtureGroup.unchangedBoundaryControl,
      boundaryType: BoundaryType.regionalUsage,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
      isValidRegionalSpanish: true,
    );

const BoundaryControlBenchmarkFixture boundaryRegionalCoger =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-regional-coger',
      text: 'Cada mañana cojo el autobús para llegar a la oficina.',
      expectedCorrectedText:
          'Cada mañana cojo el autobús para llegar a la oficina.',
      note:
          'Pure unchanged boundary control: tests whether the model rewrites '
          'valid Peninsular Spanish because a word is dialectally sensitive.',
      fixtureGroup: BoundaryFixtureGroup.unchangedBoundaryControl,
      boundaryType: BoundaryType.regionalUsage,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
      isValidRegionalSpanish: true,
    );

const BoundaryControlBenchmarkFixture boundaryRegionalPreterite =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-regional-preterite',
      text: 'Esta mañana hablé con mi jefe sobre el proyecto nuevo.',
      expectedCorrectedText:
          'Esta mañana hablé con mi jefe sobre el proyecto nuevo.',
      note:
          'Pure unchanged boundary control: tests whether the model changes a '
          'valid preterite/present-perfect regional tense preference.',
      fixtureGroup: BoundaryFixtureGroup.unchangedBoundaryControl,
      boundaryType: BoundaryType.tensePreference,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
      isValidRegionalSpanish: true,
    );

const BoundaryControlBenchmarkFixture boundaryCalqueLlamarParaAtras =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-calque-llamar-para-atras',
      text: 'Te llamo para atrás cuando termine la reunión.',
      expectedCorrectedText: 'Te llamo para atrás cuando termine la reunión.',
      note:
          'Word-choice/naturalness boundary control: tests whether the model '
          'rewrites a calque as a naturalness improvement.',
      fixtureGroup: BoundaryFixtureGroup.wordChoiceBoundaryControl,
      boundaryType: BoundaryType.calque,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
      isCalcsStyle: true,
    );

const BoundaryControlBenchmarkFixture boundaryCorriendoTarde =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-corriendo-tarde-calque',
      text: 'Estoy corriendo tarde para la reunión.',
      expectedCorrectedText: 'Estoy corriendo tarde para la reunión.',
      note:
          'Word-choice/naturalness boundary control (issue #109): '
          '"corriendo tarde" is a phrase-level calque whose minimal edit '
          'looks like a single word ("corriendo" -> "llegando"), which is '
          'exactly why this pattern is easy for the first pass to '
          'mistake for a grammar/spelling fix rather than naturalness — '
          'see docs/two_pass_prompt_contract_audit.md §7c.',
      fixtureGroup: BoundaryFixtureGroup.wordChoiceBoundaryControl,
      boundaryType: BoundaryType.calque,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isCalcsStyle: true,
    );

const BoundaryControlBenchmarkFixture boundaryAtendioUniversidad =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-atendio-universidad-false-friend',
      text: 'Atendió la universidad en Madrid.',
      expectedCorrectedText: 'Atendió la universidad en Madrid.',
      note:
          'Word-choice/naturalness boundary control (issue #109): '
          '"atendió" is a false friend for "attend" (the correct word is '
          '"asistió"), but choosing the right word is word choice, not '
          'grammar, spelling, or punctuation — this fixture asserts the '
          'first pass leaves it for a later pass rather than fixing it '
          'itself.',
      fixtureGroup: BoundaryFixtureGroup.wordChoiceBoundaryControl,
      boundaryType: BoundaryType.falseFriend,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
    );

const BoundaryControlBenchmarkFixture boundaryCitaMedicoMultiArticle =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-cita-medico-multi-article',
      text: 'Tengo cita con médico mañana.',
      expectedCorrectedText: 'Tengo una cita con el médico mañana.',
      note:
          'Grammar-boundary correction (issue #109): two articles are '
          'missing in the same sentence ("una" before "cita", "el" before '
          '"médico") — asserts the first pass corrects every missing '
          'article it finds, not only the first one.',
      fixtureGroup: BoundaryFixtureGroup.grammarBoundaryCorrection,
      boundaryType: BoundaryType.omission,
      expectedBehavior: BoundaryExpectedBehavior.corrected,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
    );

const BoundaryControlBenchmarkFixture boundaryCollocationHacerDecision =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-collocation-hacer-decision',
      text: 'Necesito hacer una decisión importante antes del viernes.',
      expectedCorrectedText:
          'Necesito hacer una decisión importante antes del viernes.',
      note:
          'Word-choice/naturalness boundary control: tests whether the model '
          'rewrites an unnatural collocation such as "hacer una decisión" to '
          '"tomar una decisión".',
      fixtureGroup: BoundaryFixtureGroup.wordChoiceBoundaryControl,
      boundaryType: BoundaryType.collocation,
      expectedBehavior: BoundaryExpectedBehavior.unchanged,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
      isCalcsStyle: true,
    );

const BoundaryControlBenchmarkFixture boundaryGustarAgreement =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-gustar-agreement',
      text: 'Me gusta las películas de acción los fines de semana.',
      expectedCorrectedText:
          'Me gustan las películas de acción los fines de semana.',
      note:
          'Grammar-boundary correction: tests true verb agreement in a '
          'construction learners often experience as lexical or idiomatic.',
      fixtureGroup: BoundaryFixtureGroup.grammarBoundaryCorrection,
      boundaryType: BoundaryType.agreement,
      expectedBehavior: BoundaryExpectedBehavior.corrected,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
    );

const BoundaryControlBenchmarkFixture boundaryMissingQue =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-missing-que',
      text: 'Creo está bien terminar el proyecto esta semana.',
      expectedCorrectedText:
          'Creo que está bien terminar el proyecto esta semana.',
      note:
          'Grammar-boundary correction: tests whether the model corrects an '
          'omitted complementizer without rewriting the sentence.',
      fixtureGroup: BoundaryFixtureGroup.grammarBoundaryCorrection,
      boundaryType: BoundaryType.omission,
      expectedBehavior: BoundaryExpectedBehavior.corrected,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
    );

const BoundaryControlBenchmarkFixture boundarySerEstarProfesor =
    BoundaryControlBenchmarkFixture(
      id: 'boundary-ser-estar-profesor',
      text: 'Mi hermano está profesor en una escuela secundaria.',
      expectedCorrectedText:
          'Mi hermano es profesor en una escuela secundaria.',
      note:
          'Grammar-boundary correction: tests objective ser/estar correction '
          'without changing wording beyond the verb.',
      fixtureGroup: BoundaryFixtureGroup.grammarBoundaryCorrection,
      boundaryType: BoundaryType.serEstar,
      expectedBehavior: BoundaryExpectedBehavior.corrected,
      isOverCorrectionSensitive: true,
      isAccentSensitive: true,
    );

/// Boundary-control fixture subset for first-pass model comparison runs.
///
/// These cases test whether models leave valid or borderline-valid Spanish
/// alone under the narrow grammar/spelling/punctuation-only prompt, while
/// still correcting nearby objective grammar errors.
const List<BoundaryControlBenchmarkFixture> boundaryControlFirstPassFixtures = [
  boundaryRedundantYo,
  boundaryRedundantEllos,
  boundaryParaCasa,
  boundaryRegionalCoger,
  boundaryRegionalPreterite,
  boundaryCalqueLlamarParaAtras,
  boundaryCorriendoTarde,
  boundaryAtendioUniversidad,
  boundaryCitaMedicoMultiArticle,
  boundaryCollocationHacerDecision,
  boundaryGustarAgreement,
  boundaryMissingQue,
  boundarySerEstarProfesor,
];

/// Exact expected outputs for the boundary-control fixture subset.
final Map<String, String> boundaryControlFirstPassExpectedCorrectedText =
    Map.unmodifiable({
      for (final fixture in boundaryControlFirstPassFixtures)
        fixture.id: fixture.expectedCorrectedText,
    });

const LexicalCollocationBenchmarkFixture lexicalControlHacerPregunta =
    LexicalCollocationBenchmarkFixture(
      id: 'lexical-control-hacer-pregunta',
      text: 'Voy a hacer una pregunta al profesor después de clase.',
      expectedCorrectedText:
          'Voy a hacer una pregunta al profesor después de clase.',
      role: LexicalCollocationFixtureRole.unchangedControl,
      note:
          'Valid hacer + pregunta collocation. Ensures the model does not '
          'blindly replace hacer.',
      isAccentSensitive: true,
    );

const LexicalCollocationBenchmarkFixture lexicalControlTomarFoto =
    LexicalCollocationBenchmarkFixture(
      id: 'lexical-control-tomar-foto',
      text: 'Necesito tomar una foto del documento antes de enviarlo.',
      expectedCorrectedText:
          'Necesito tomar una foto del documento antes de enviarlo.',
      role: LexicalCollocationFixtureRole.unchangedControl,
      note:
          'Valid tomar + foto collocation. Ensures the model does not blindly '
          'replace tomar.',
    );

const LexicalCollocationBenchmarkFixture lexicalControlDarPaseo =
    LexicalCollocationBenchmarkFixture(
      id: 'lexical-control-dar-paseo',
      text: 'Vamos a dar un paseo por el parque esta tarde.',
      expectedCorrectedText: 'Vamos a dar un paseo por el parque esta tarde.',
      role: LexicalCollocationFixtureRole.unchangedControl,
      note: 'Valid dar + paseo collocation.',
    );

const LexicalCollocationBenchmarkFixture
lexicalHacerPaseo = LexicalCollocationBenchmarkFixture(
  id: 'lexical-hacer-paseo',
  text: 'Ella hizo un paseo por el parque después del trabajo.',
  expectedCorrectedText: 'Ella dio un paseo por el parque después del trabajo.',
  role: LexicalCollocationFixtureRole.expectedCorrection,
  note: 'Wrong verb-noun collocation: hacer un paseo should be dar un paseo.',
  isAccentSensitive: true,
);

const LexicalCollocationBenchmarkFixture lexicalHacerAtencion =
    LexicalCollocationBenchmarkFixture(
      id: 'lexical-hacer-atencion',
      text: 'Tenemos que hacer atención a los detalles del contrato.',
      expectedCorrectedText:
          'Tenemos que prestar atención a los detalles del contrato.',
      role: LexicalCollocationFixtureRole.expectedCorrection,
      note:
          'Wrong verb-noun collocation: hacer atención should be prestar '
          'atención.',
      isAccentSensitive: true,
    );

const LexicalCollocationBenchmarkFixture lexicalTomarReunion =
    LexicalCollocationBenchmarkFixture(
      id: 'lexical-tomar-reunion',
      text: 'El equipo tomó una reunión para hablar del problema.',
      expectedCorrectedText:
          'El equipo tuvo una reunión para hablar del problema.',
      role: LexicalCollocationFixtureRole.expectedCorrection,
      note:
          'Wrong verb-noun collocation: tomar una reunión should be tener una '
          'reunión.',
      isAccentSensitive: true,
    );

const LexicalCollocationBenchmarkFixture lexicalHacerDecision =
    LexicalCollocationBenchmarkFixture(
      id: 'lexical-hacer-decision',
      text: 'Quiero hacer una decisión antes de mañana.',
      expectedCorrectedText: 'Quiero tomar una decisión antes de mañana.',
      role: LexicalCollocationFixtureRole.expectedCorrection,
      note:
          'Wrong verb-noun collocation: hacer una decisión should be tomar '
          'una decisión.',
      isAccentSensitive: true,
    );

const LexicalCollocationBenchmarkFixture lexicalTomarFiesta =
    LexicalCollocationBenchmarkFixture(
      id: 'lexical-tomar-fiesta',
      text: 'Mi hermana tomó una fiesta para celebrar su cumpleaños.',
      expectedCorrectedText:
          'Mi hermana hizo una fiesta para celebrar su cumpleaños.',
      role: LexicalCollocationFixtureRole.expectedCorrection,
      note:
          'Wrong verb-noun collocation: tomar una fiesta should be hacer una '
          'fiesta.',
      isAccentSensitive: true,
    );

/// Targeted lexical-collocation fixture subset for model comparison runs.
const List<LexicalCollocationBenchmarkFixture>
lexicalCollocationFirstPassFixtures = [
  lexicalControlHacerPregunta,
  lexicalControlTomarFoto,
  lexicalControlDarPaseo,
  lexicalHacerPaseo,
  lexicalHacerAtencion,
  lexicalTomarReunion,
  lexicalHacerDecision,
  lexicalTomarFiesta,
];

/// Exact expected outputs for the lexical-collocation fixture subset.
final Map<String, String> lexicalCollocationFirstPassExpectedCorrectedText =
    Map.unmodifiable({
      for (final fixture in lexicalCollocationFirstPassFixtures)
        fixture.id: fixture.expectedCorrectedText,
    });

const NaturalnessBenchmarkFixture naturalnessCalqueLlamarParaAtras =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-calque-llamar-para-atras',
      text: 'Te llamo para atrás cuando termine la reunión.',
      note:
          'Naturalness/calque issue: literal English-influenced phrasing that '
          'should be identified without treating it as grammar.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'llamo para atrás',
          naturalReplacement: 'llamo después',
          issueType: NaturalnessIssueType.calque,
        ),
      ],
      isCalcsStyle: true,
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessHacerDecisionLong =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-collocation-necesito-hacer-decision',
      text: 'Necesito hacer una decisión importante antes del viernes.',
      note:
          'Collocation overlap case: tests whether the naturalness pass also '
          'detects hacer una decisión as a lexical-selection issue.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'hacer una decisión',
          naturalReplacement: 'tomar una decisión',
          issueType: NaturalnessIssueType.collocation,
        ),
      ],
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessHacerDecisionShort =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-collocation-quiero-hacer-decision',
      text: 'Quiero hacer una decisión antes de mañana.',
      note:
          'Short collocation overlap case: hacer una decisión should be '
          'identified as unnatural lexical selection.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'hacer una decisión',
          naturalReplacement: 'tomar una decisión',
          issueType: NaturalnessIssueType.collocation,
        ),
      ],
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessHacerAtencion =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-collocation-hacer-atencion',
      text: 'Tenemos que hacer atención a los detalles del contrato.',
      note:
          'Collocation overlap case: hacer atención should be identified as '
          'unnatural lexical selection.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'hacer atención',
          naturalReplacement: 'prestar atención',
          issueType: NaturalnessIssueType.collocation,
        ),
      ],
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessTomarReunion =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-collocation-tomar-reunion',
      text: 'El equipo tomó una reunión para hablar del problema.',
      note:
          'Collocation overlap case: tomar una reunión should be identified '
          'as unnatural lexical selection.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'tomó una reunión',
          naturalReplacement: 'tuvo una reunión',
          issueType: NaturalnessIssueType.collocation,
        ),
      ],
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessHacerPaseo =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-collocation-hacer-paseo',
      text: 'Ella hizo un paseo por el parque después del trabajo.',
      note:
          'Collocation overlap case: hacer un paseo should be identified as '
          'unnatural lexical selection.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'hizo un paseo',
          naturalReplacement: 'dio un paseo',
          issueType: NaturalnessIssueType.collocation,
        ),
      ],
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessControlHacerPregunta =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-control-hacer-pregunta',
      text: 'Voy a hacer una pregunta al profesor después de clase.',
      note:
          'Valid collocation control: hacer una pregunta should not be '
          'reported as a naturalness issue.',
      role: NaturalnessFixtureRole.unchangedControl,
      expectedIssues: [],
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessControlTomarFoto =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-control-tomar-foto',
      text: 'Necesito tomar una foto del documento antes de enviarlo.',
      note:
          'Valid collocation control: tomar una foto should not be reported '
          'as a naturalness issue.',
      role: NaturalnessFixtureRole.unchangedControl,
      expectedIssues: [],
    );

const NaturalnessBenchmarkFixture naturalnessControlParaCasa =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-control-para-casa',
      text: 'Está lloviendo, así que voy para casa ahora mismo.',
      note:
          'Valid regional/ordinary phrasing control: voy para casa should not '
          'be normalized away.',
      role: NaturalnessFixtureRole.unchangedControl,
      expectedIssues: [],
      isAccentSensitive: true,
      isValidRegionalSpanish: true,
    );

const NaturalnessBenchmarkFixture naturalnessGrammarTrapGustar =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-grammar-trap-gustar-agreement',
      text: 'Me gusta las películas de acción los fines de semana.',
      note:
          'Grammar trap: the naturalness-only prompt should ignore ordinary '
          'grammar errors such as gustar agreement.',
      role: NaturalnessFixtureRole.grammarTrap,
      expectedIssues: [],
      ignoredSpans: ['Me gusta las películas'],
      isAccentSensitive: true,
    );

const NaturalnessBenchmarkFixture naturalnessEs3MultiCorrection =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-es3-multi-correction',
      text:
          'Ayer había mucho trafico y mis amigos llamaron para atrás para '
          'confirmar la cena.',
      note:
          'ES-3 naturalness case with a spelling trap: report llamaron para '
          'atrás, but ignore trafico without an accent.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'llamaron para atrás',
          naturalReplacement: 'devolvieron la llamada',
          issueType: NaturalnessIssueType.calque,
        ),
      ],
      ignoredSpans: ['trafico'],
      isCalcsStyle: true,
    );

const NaturalnessBenchmarkFixture naturalnessEs4CalquePair =
    NaturalnessBenchmarkFixture(
      id: 'naturalness-es4-calque-pair',
      text:
          '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
          'amigos esta noche.',
      note:
          'ES-4 naturalness case with two calque issues in one input: a '
          'literal request form and pasar un buen tiempo.',
      role: NaturalnessFixtureRole.expectedIssue,
      expectedIssues: [
        ExpectedNaturalnessIssue(
          span: 'Puedo tener una cerveza',
          naturalReplacement: 'Me pones una cerveza',
          issueType: NaturalnessIssueType.calque,
        ),
        ExpectedNaturalnessIssue(
          span: 'pasar un buen tiempo',
          naturalReplacement: 'pasarlo bien',
          issueType: NaturalnessIssueType.calque,
        ),
      ],
      isCalcsStyle: true,
      isAccentSensitive: true,
    );

/// Targeted naturalness-only fixture subset for model comparison runs.
const List<NaturalnessBenchmarkFixture> naturalnessModelComparisonFixtures = [
  naturalnessCalqueLlamarParaAtras,
  naturalnessHacerDecisionLong,
  naturalnessHacerDecisionShort,
  naturalnessHacerAtencion,
  naturalnessTomarReunion,
  naturalnessHacerPaseo,
  naturalnessControlHacerPregunta,
  naturalnessControlTomarFoto,
  naturalnessControlParaCasa,
  naturalnessGrammarTrapGustar,
  naturalnessEs3MultiCorrection,
  naturalnessEs4CalquePair,
];

const ScoredBenchmarkFixture harderAccentMarksDiacritics =
    ScoredBenchmarkFixture(
      id: 'harder-accent-marks-diacritics',
      text: 'El medico llego despues de la reunion.',
      expectedCorrectedText: 'El médico llegó después de la reunión.',
      note:
          'Harder scored B1 sentence: missing written accents only, useful for '
          'checking diacritic recovery without wording changes.',
      lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
      cefrTargetLevel: BenchmarkCefrTargetLevel.b1,
      errorFamilies: {ObjectiveSpanishErrorFamily.accentMarksDiacritics},
      intendedErrorCount: 4,
      isAccentSensitive: true,
    );

const ScoredBenchmarkFixture harderGenderNumberAgreement =
    ScoredBenchmarkFixture(
      id: 'harder-gender-number-agreement',
      text: 'Las ventanas estaban abierto, pero una puerta estaba cerrado.',
      expectedCorrectedText:
          'Las ventanas estaban abiertas, pero una puerta estaba cerrada.',
      note:
          'Harder scored B1 sentence: adjective/participle agreement with '
          'nearby feminine singular and plural nouns.',
      lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
      cefrTargetLevel: BenchmarkCefrTargetLevel.b1,
      errorFamilies: {ObjectiveSpanishErrorFamily.genderNumberAgreement},
      intendedErrorCount: 2,
    );

const ScoredBenchmarkFixture harderPrepositionGovernment =
    ScoredBenchmarkFixture(
      id: 'harder-preposition-government',
      text: 'Insisto que revises el contrato antes de firmarlo.',
      expectedCorrectedText:
          'Insisto en que revises el contrato antes de firmarlo.',
      note:
          'Harder scored B2 sentence: required preposition after "insistir" '
          'without adding any style or word-choice target.',
      lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
      cefrTargetLevel: BenchmarkCefrTargetLevel.b2,
      errorFamilies: {ObjectiveSpanishErrorFamily.prepositionGovernment},
      intendedErrorCount: 1,
    );

const ScoredBenchmarkFixture harderVerbAgreement = ScoredBenchmarkFixture(
  id: 'harder-verb-morphology-agreement',
  text: 'Mis compañeros y yo fue a la biblioteca después de clase.',
  expectedCorrectedText:
      'Mis compañeros y yo fuimos a la biblioteca después de clase.',
  note:
      'Harder scored B1 sentence: first-person plural subject requires '
      'matching preterite verb morphology.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.b1,
  errorFamilies: {
    ObjectiveSpanishErrorFamily.verbMorphologySubjectVerbAgreement,
  },
  intendedErrorCount: 1,
  isAccentSensitive: true,
);

const ScoredBenchmarkFixture harderArticlesDeterminers = ScoredBenchmarkFixture(
  id: 'harder-articles-determiners',
  text: 'Abrió puerta principal porque hacía mucho calor.',
  expectedCorrectedText: 'Abrió la puerta principal porque hacía mucho calor.',
  note:
      'Harder scored B1 sentence: missing definite article in an ordinary '
      'specific noun phrase.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.b1,
  errorFamilies: {ObjectiveSpanishErrorFamily.articlesDeterminers},
  intendedErrorCount: 1,
  isAccentSensitive: true,
);

const ScoredBenchmarkFixture harderSubjunctiveMood = ScoredBenchmarkFixture(
  id: 'harder-subjunctive-mood',
  text: 'Es importante que estudias antes del examen final.',
  expectedCorrectedText: 'Es importante que estudies antes del examen final.',
  note:
      'Harder scored B1-B2 sentence: impersonal expression requires present '
      'subjunctive, with no lexical improvement target.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.b2,
  errorFamilies: {ObjectiveSpanishErrorFamily.subjunctiveMood},
  intendedErrorCount: 1,
);

const ScoredBenchmarkFixture harderObjectPronounsClitics =
    ScoredBenchmarkFixture(
      id: 'harder-object-pronouns-clitics',
      text: 'A los niños expliqué la regla con paciencia.',
      expectedCorrectedText: 'A los niños les expliqué la regla con paciencia.',
      note:
          'Harder scored B2 sentence: preposed indirect object requires the '
          'matching clitic pronoun.',
      lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
      cefrTargetLevel: BenchmarkCefrTargetLevel.b2,
      errorFamilies: {ObjectiveSpanishErrorFamily.objectPronounsClitics},
      intendedErrorCount: 1,
      isAccentSensitive: true,
    );

const ScoredBenchmarkFixture harderSerEstarHaber = ScoredBenchmarkFixture(
  id: 'harder-ser-estar-haber',
  text: 'En la sala son veinte personas esperando la reunión.',
  expectedCorrectedText: 'En la sala hay veinte personas esperando la reunión.',
  note:
      'Harder scored B1 sentence: existential "haber" is required for a '
      'there-is/there-are meaning.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.b1,
  errorFamilies: {ObjectiveSpanishErrorFamily.serEstarHaber},
  intendedErrorCount: 1,
  isAccentSensitive: true,
);

const ScoredBenchmarkFixture harderPersonalA = ScoredBenchmarkFixture(
  id: 'harder-personal-a',
  text: 'Vi mi profesor en la estación esta mañana.',
  expectedCorrectedText: 'Vi a mi profesor en la estación esta mañana.',
  note:
      'Harder scored B1 sentence: direct object referring to a specific person '
      'requires personal "a".',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.b1,
  errorFamilies: {ObjectiveSpanishErrorFamily.personalA},
  intendedErrorCount: 1,
  isAccentSensitive: true,
);

const ScoredBenchmarkFixture harderRelativeClausePreposition =
    ScoredBenchmarkFixture(
      id: 'harder-relative-clause-preposition',
      text: 'La empresa que trabajo está cerca de mi casa.',
      expectedCorrectedText:
          'La empresa en la que trabajo está cerca de mi casa.',
      note:
          'Harder scored B2 sentence: relative clause requires the preposition '
          'governed by "trabajar en".',
      lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
      cefrTargetLevel: BenchmarkCefrTargetLevel.b2,
      errorFamilies: {
        ObjectiveSpanishErrorFamily.relativeClauseRequiredPreposition,
      },
      intendedErrorCount: 1,
      isAccentSensitive: true,
    );

const ScoredBenchmarkFixture harderImpersonalHaberSe = ScoredBenchmarkFixture(
  id: 'harder-impersonal-haber-se',
  text: 'Habían muchas personas en la entrada del museo.',
  expectedCorrectedText: 'Había muchas personas en la entrada del museo.',
  note:
      'Harder scored B2 sentence: impersonal "haber" remains singular before '
      'a plural noun phrase.',
  lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.b2,
  errorFamilies: {
    ObjectiveSpanishErrorFamily.impersonalHaberPassiveImpersonalSe,
  },
  intendedErrorCount: 1,
  isAccentSensitive: true,
);

const ScoredBenchmarkFixture harderSentenceBoundariesPunctuation =
    ScoredBenchmarkFixture(
      id: 'harder-sentence-boundaries-punctuation',
      text: 'Terminé el informe llegué a casa muy tarde.',
      expectedCorrectedText: 'Terminé el informe. Llegué a casa muy tarde.',
      note:
          'Harder scored B1-B2 sentence: run-on sentence needs a boundary '
          'without changing the words.',
      lengthBand: BenchmarkLengthBand.sentenceOrShortParagraph,
      cefrTargetLevel: BenchmarkCefrTargetLevel.b2,
      errorFamilies: {
        ObjectiveSpanishErrorFamily.sentenceBoundariesPunctuation,
      },
      intendedErrorCount: 1,
      isAccentSensitive: true,
    );

const ScoredBenchmarkFixture harderMixedB1B2Paragraph = ScoredBenchmarkFixture(
  id: 'harder-mixed-b1-b2-paragraph',
  text:
      'El sabado visite a mi prima en Valencia. Ella me dijo que los '
      'billetes estaban caro, pero al final los compramos antes de salir',
  expectedCorrectedText:
      'El sábado visité a mi prima en Valencia. Ella me dijo que los '
      'billetes estaban caros, pero al final los compramos antes de salir.',
  note:
      'Harder scored mixed B1-B2 paragraph: accents, plural agreement, and '
      'sentence-final punctuation in ordinary narrative language.',
  lengthBand: BenchmarkLengthBand.paragraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.b2,
  errorFamilies: {
    ObjectiveSpanishErrorFamily.accentMarksDiacritics,
    ObjectiveSpanishErrorFamily.genderNumberAgreement,
    ObjectiveSpanishErrorFamily.sentenceBoundariesPunctuation,
  },
  intendedErrorCount: 4,
  isAccentSensitive: true,
);

const ScoredBenchmarkFixture harderMixedB2C1Paragraph = ScoredBenchmarkFixture(
  id: 'harder-mixed-b2-c1-paragraph',
  text:
      'Aunque el informe que hablábamos era complejo, era importante que '
      'todos entendían las conclusiones antes de la votación.',
  expectedCorrectedText:
      'Aunque el informe del que hablábamos era complejo, era importante '
      'que todos entendieran las conclusiones antes de la votación.',
  note:
      'Harder scored mixed B2-C1 paragraph: required relative preposition '
      'and subjunctive mood in a formal but plain sentence.',
  lengthBand: BenchmarkLengthBand.paragraph,
  cefrTargetLevel: BenchmarkCefrTargetLevel.c1,
  errorFamilies: {
    ObjectiveSpanishErrorFamily.relativeClauseRequiredPreposition,
    ObjectiveSpanishErrorFamily.subjunctiveMood,
  },
  intendedErrorCount: 2,
  isAccentSensitive: true,
);

const ScoredBenchmarkFixture harderNearLimitMixedText = ScoredBenchmarkFixture(
  id: 'harder-near-limit-mixed-text',
  text:
      'Durante los últimos meses, el equipo ha preparado un informe para '
      'la asociación local. Ayer revisamos los datos con la directora, '
      'pero habían varias cifras que no coincidían con los documentos '
      'originales. El resumen que dependíamos para tomar decisiones no '
      'estaba completo, y era necesario que cada responsable enviaba su '
      'parte antes del viernes. También detectamos que las fechas '
      'principales estaban escrito sin tilde en algunos archivos. Por eso '
      'acordamos corregirlas antes de entregar la versión final al comité.',
  expectedCorrectedText:
      'Durante los últimos meses, el equipo ha preparado un informe para '
      'la asociación local. Ayer revisamos los datos con la directora, '
      'pero había varias cifras que no coincidían con los documentos '
      'originales. El resumen del que dependíamos para tomar decisiones no '
      'estaba completo, y era necesario que cada responsable enviara su '
      'parte antes del viernes. También detectamos que las fechas '
      'principales estaban escritas sin tilde en algunos archivos. Por eso '
      'acordamos corregirlas antes de entregar la versión final al comité.',
  note:
      'Harder scored near-limit mixed text: objective impersonal haber, '
      'relative preposition, subjunctive mood, and agreement errors spread '
      'across a long ordinary workplace paragraph.',
  lengthBand: BenchmarkLengthBand.nearLimit,
  cefrTargetLevel: BenchmarkCefrTargetLevel.c1,
  errorFamilies: {
    ObjectiveSpanishErrorFamily.impersonalHaberPassiveImpersonalSe,
    ObjectiveSpanishErrorFamily.relativeClauseRequiredPreposition,
    ObjectiveSpanishErrorFamily.subjunctiveMood,
    ObjectiveSpanishErrorFamily.genderNumberAgreement,
  },
  intendedErrorCount: 4,
  isAccentSensitive: true,
);

/// Harder scored fixture subset for second-pass runs of the bare first-pass
/// model-comparison harness. These are correction cases only and stay scoped
/// to objective grammar, spelling, and punctuation.
const List<ScoredBenchmarkFixture> harderSecondPassFirstPassFixtures = [
  harderAccentMarksDiacritics,
  harderGenderNumberAgreement,
  harderPrepositionGovernment,
  harderVerbAgreement,
  harderArticlesDeterminers,
  harderSubjunctiveMood,
  harderObjectPronounsClitics,
  harderSerEstarHaber,
  harderPersonalA,
  harderRelativeClausePreposition,
  harderImpersonalHaberSe,
  harderSentenceBoundariesPunctuation,
  harderMixedB1B2Paragraph,
  harderMixedB2C1Paragraph,
  harderNearLimitMixedText,
];

/// Exact expected outputs for the harder scored fixture subset.
final Map<String, String> harderSecondPassFirstPassExpectedCorrectedText =
    Map.unmodifiable({
      for (final fixture in harderSecondPassFirstPassFixtures)
        fixture.id: fixture.expectedCorrectedText,
    });

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

/// All fixture ids addressable by the model-comparison harness.
const List<BenchmarkFixture> addressableBenchmarkFixtures = [
  ...benchmarkFixtures,
  ...harderSecondPassFirstPassFixtures,
  ...boundaryControlFirstPassFixtures,
  ...lexicalCollocationFirstPassFixtures,
  ...naturalnessModelComparisonFixtures,
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
  return addressableBenchmarkFixtures.firstWhere(
    (fixture) => fixture.id == id,
    orElse: () => throw StateError(
      'No benchmark fixture with id "$id". Available ids: '
      '${addressableBenchmarkFixtures.map((fixture) => fixture.id).join(', ')}.',
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
