// Shared Spanish correction benchmark fixture set.
//
// Issue: "Define richer Spanish correction benchmark fixture strategy"
// (closes Thow76/spanish_correction_app#11). Purpose: a small, shared set of
// representative natural-language inputs for latency/request-count/
// token-usage/cost/model-comparison benchmarking — not a language-quality
// regression suite, and not a change to prompts, model behavior, UI flow, or
// the staged pipeline. This complements (does not duplicate) the
// observability work in Thow76/spanish_correction_app#6: that issue records
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
    orElse: () => throw StateError('No benchmark fixture with id "$id".'),
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
