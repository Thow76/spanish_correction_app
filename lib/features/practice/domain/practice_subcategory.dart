/// The fixed list of subcategories a practice item can carry (practice
/// track, step P.5; decision G4, point 3).
///
/// Each mistake gets exactly one subcategory from this list, or none. The
/// list is closed: nothing outside it is ever stored, so the games' filter
/// cannot grow one new name at a time as it did on the sheet. Natural
/// phrasing has no subcategories for now.
///
/// Plain Dart with no storage: the practice database (`data/`) turns this
/// list into the rule its table enforces.
library;

/// The four category names, written as the rest of the app writes them
/// (`ErrorCategory.label`). Kept here as plain text so this folder does not
/// depend on the screens' colours; a test checks the two lists agree.
abstract final class PracticeCategory {
  static const String spelling = 'Spelling';
  static const String grammar = 'Grammar';
  static const String wordChoice = 'Word Choice';
  static const String naturalPhrasing = 'Natural phrasing';

  /// All four, in the order the app shows them.
  static const List<String> all = [
    spelling,
    grammar,
    wordChoice,
    naturalPhrasing,
  ];
}

/// One subcategory from G4's list.
///
/// [storedValue] is what the database keeps. It never changes once in use,
/// even if [label] is reworded.
enum PracticeSubcategory {
  // Grammar (8).
  prepositions(
    'prepositions',
    'Prepositions',
    PracticeCategory.grammar,
    'Including personal a, por and para, and verbs that need a particular '
        'preposition.',
  ),
  agreement(
    'agreement',
    'Agreement',
    PracticeCategory.grammar,
    'Gender and number across nouns, articles, adjectives and verbs.',
  ),
  verbFormsAndTenses(
    'verb_forms_and_tenses',
    'Verb forms and tenses',
    PracticeCategory.grammar,
    'Wrong tense or form, infinitive versus conjugated verb, gerunds.',
  ),
  subjunctive(
    'subjunctive',
    'Subjunctive',
    PracticeCategory.grammar,
    'The subjunctive where it is needed, or used where it is not.',
  ),
  serAndEstar(
    'ser_and_estar',
    'Ser and estar',
    PracticeCategory.grammar,
    'Ser where estar is needed, or the other way round.',
  ),
  articles(
    'articles',
    'Articles',
    PracticeCategory.grammar,
    'El, la, un, a missing or extra article, al and del.',
  ),
  pronouns(
    'pronouns',
    'Pronouns',
    PracticeCategory.grammar,
    'Lo, la, le, their placement, reflexive verbs, se.',
  ),
  sentenceStructure(
    'sentence_structure',
    'Sentence structure',
    PracticeCategory.grammar,
    'Word order, question words, que, quien, donde, comparisons, and any '
        'other grammar point that fits none of the seven above.',
  ),

  // Spelling (3).
  writtenAccents(
    'written_accents',
    'Written accents',
    PracticeCategory.spelling,
    'A written accent missing, extra or on the wrong letter.',
  ),
  letters(
    'letters',
    'Letters',
    PracticeCategory.spelling,
    'Any other spelling slip.',
  ),
  punctuationAndCapitals(
    'punctuation_and_capitals',
    'Punctuation and capitals',
    PracticeCategory.spelling,
    'Including the opening question and exclamation marks.',
  ),

  // Word Choice (2).
  falseFriends(
    'false_friends',
    'False friends',
    PracticeCategory.wordChoice,
    'A Spanish word that looks like an English one but means something '
        'else.',
  ),
  mixedUpPairs(
    'mixed_up_pairs',
    'Mixed-up pairs',
    PracticeCategory.wordChoice,
    'Two Spanish words for one English word, such as saber and conocer.',
  );

  const PracticeSubcategory(
    this.storedValue,
    this.label,
    this.category,
    this.covers,
  );

  /// What the database keeps for this subcategory.
  final String storedValue;

  /// The name shown to the learner.
  final String label;

  /// The category this subcategory sits under, one of [PracticeCategory.all].
  final String category;

  /// What the subcategory takes in, in a few words (G4's own wording).
  final String covers;

  /// What the database keeps when a mistake has no subcategory.
  static const String noneStoredValue = '';

  /// The subcategory for a stored value, or `null` for the empty value.
  ///
  /// Throws a [FormatException] for anything else: a value that is not on
  /// the list is a fault, never a new subcategory.
  static PracticeSubcategory? fromStoredValue(String value) {
    if (value == noneStoredValue) return null;
    for (final subcategory in PracticeSubcategory.values) {
      if (subcategory.storedValue == value) return subcategory;
    }
    throw FormatException('"$value" is not a subcategory on the fixed list.');
  }

  /// The subcategories of one category, in list order. Empty for Natural
  /// phrasing and for any name that is not a category.
  static List<PracticeSubcategory> forCategory(String category) => [
    for (final subcategory in PracticeSubcategory.values)
      if (subcategory.category == category) subcategory,
  ];
}
