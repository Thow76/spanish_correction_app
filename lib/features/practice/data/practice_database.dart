/// The practice database: the games' own data, kept in one small database
/// file on the phone (practice track, step P.5; decisions G2, G3 and G4).
///
/// This is the app's first database. It holds practice data only. Saved and
/// History stay in their JSON files, and nothing here changes
/// `SavedCorrection` (G4, "two tracks").
///
/// The tables:
/// - [PracticeItems]: the games' copy of one saved mistake, with where it
///   stands on the stage ladder.
/// - [PracticeQuestions]: the questions built for a mistake, in step P.1's
///   format.
/// - [PracticeAttempts]: every answer the learner gives.
/// - [PracticeGroups] and [PracticeGroupItems]: Guided groups, the mistakes
///   in each, and when a group's next stage opens.
/// - [PracticeRules]: the rule bank that Matching rounds are checked
///   against.
///
/// Every row has a stable text id and a changed-at time, so that keeping two
/// devices in step could be added later without reshaping the data (G2).
/// The changed-at time is filled in when a row is first written; whoever
/// changes a row afterwards sets it again ([PracticeDatabase.now] gives the
/// time to use).
///
/// Removing a practice item removes its questions, its attempts and its
/// places in groups with it (G4, point 5).
///
/// The file `practice_database.g.dart` beside this one is written by a tool
/// from the tables below (`dart run build_runner build`). It is kept in the
/// repository so the app builds without running the tool. Run the tool again
/// after changing a table, and add a migration and a test for the change
/// (G3, point 4; see `drift_schemas/README.md`).
// The rules on a column (for example "not below 0") name the column inside
// its own definition, which is how the database package asks for them to be
// written; it only looks like a getter calling itself.
// ignore_for_file: recursive_getters
library;

import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/practice_subcategory.dart';

part 'practice_database.g.dart';

/// A new id for a row: 32 letters and digits chosen at random, so two
/// devices would never make the same one (G2).
String newPracticeId() {
  final random = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Whether the learner typed or spoke the text a mistake came from. The
/// games never ask for the spelling of something only ever said aloud (G4,
/// point 4).
enum PracticeInputMode { typed, spoken }

/// How a Guided group was put together (G6, point 5; step P.9).
enum PracticeGroupKind {
  /// All of one category or one subcategory.
  oneKind,

  /// Suggested by the app across categories.
  mixed,

  /// Picked by hand by the learner; never changed by the app.
  handPicked,
}

/// Whether an answer was given in a Guided group or in Free play. Free play
/// records attempts but never moves a stage, a lock or a group (G6, point 3).
enum PracticeMode { guided, free }

/// Keeps a subcategory as its stored value, and no subcategory as the empty
/// text. Anything that is not on G4's list is refused when read.
class PracticeSubcategoryConverter
    extends TypeConverter<PracticeSubcategory?, String> {
  const PracticeSubcategoryConverter();

  @override
  PracticeSubcategory? fromSql(String fromDb) =>
      PracticeSubcategory.fromStoredValue(fromDb);

  @override
  String toSql(PracticeSubcategory? value) =>
      value?.storedValue ?? PracticeSubcategory.noneStoredValue;
}

/// The rule the database itself enforces on a subcategory: it is empty, or
/// it is one of G4's list for the row's category. The tables below repeat
/// this text word for word, because the tool that writes the generated file
/// only reads a rule written out in place; a test checks that the tables
/// carry this text, and checks it against [PracticeSubcategory], so the
/// list and the rule cannot drift apart.
const String practiceSubcategoryRule =
    "CHECK (subcategory = '' "
    "OR (category = 'Grammar' AND subcategory IN ('prepositions', "
    "'agreement', 'verb_forms_and_tenses', 'subjunctive', 'ser_and_estar', "
    "'articles', 'pronouns', 'sentence_structure')) "
    "OR (category = 'Spelling' AND subcategory IN ('written_accents', "
    "'letters', 'punctuation_and_capitals')) "
    "OR (category = 'Word Choice' AND subcategory IN ('false_friends', "
    "'mixed_up_pairs')))";

/// The same rule for a group, whose category may be empty (a mixed or
/// hand-picked group has none).
const String practiceGroupKindRule =
    "CHECK (category IN ('', 'Spelling', 'Grammar', 'Word Choice', "
    "'Natural phrasing'))";

/// The games' copy of one saved mistake (G4).
@DataClassName('PracticeItem')
class PracticeItems extends Table {
  /// Stable id of this practice item.
  TextColumn get id => text().clientDefault(newPracticeId)();

  /// When this row was last changed (G2).
  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the games' copy was made.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// The language of the mistake, as `Language.name` ("spanish").
  TextColumn get language => text()();

  /// The sentence as the learner wrote it.
  TextColumn get originalSentence => text()();

  /// The sentence as suggested.
  TextColumn get correctedSentence => text()();

  /// The phrase as written.
  TextColumn get originalPhrase => text()();

  /// The phrase as suggested.
  TextColumn get correctedPhrase => text()();

  /// Where the phrase sits in [originalSentence], when known.
  IntColumn get originalStart => integer().nullable()();
  IntColumn get originalEnd => integer().nullable()();

  /// Where the phrase sits in [correctedSentence], when known.
  IntColumn get correctedStart => integer().nullable()();
  IntColumn get correctedEnd => integer().nullable()();

  /// The short explanation of the point.
  TextColumn get explanation => text().withDefault(const Constant(''))();

  /// The English version of the sentence; empty when there is none.
  TextColumn get englishSentence => text().withDefault(const Constant(''))();

  /// Where the matching part sits in [englishSentence], when known.
  IntColumn get englishHighlightStart => integer().nullable()();
  IntColumn get englishHighlightEnd => integer().nullable()();

  /// One of the four category names (`ErrorCategory.label`).
  TextColumn get category => text().check(
    category.isIn(const [
      'Spelling',
      'Grammar',
      'Word Choice',
      'Natural phrasing',
    ]),
  )();

  /// One of G4's fixed list for [category], or none. Never free text.
  TextColumn get subcategory => text()
      .map(const PracticeSubcategoryConverter())
      .withDefault(const Constant(''))();

  /// The learner's whole message or checked text, kept as a copy so "Show
  /// context" still works after the chat has gone (G4, point 4).
  TextColumn get contextText => text().withDefault(const Constant(''))();

  /// The chat the mistake came from, or none.
  TextColumn get chatId => text().nullable()();

  /// Whether the text was typed or spoken.
  TextColumn get inputMode => textEnum<PracticeInputMode>()();

  /// The id of the Saved point this copy was made from, or none (a mistake
  /// brought in from the old sheet has no Saved point). One copy per Saved
  /// point.
  TextColumn get savedCorrectionId => text().nullable().unique()();

  /// Where the mistake stands on the stage ladder, as step P.2's rank
  /// (0 = not on the ladder yet).
  IntColumn get ladderStage => integer()
      .withDefault(const Constant(0))
      .check(ladderStage.isBiggerOrEqualValue(0))();

  /// The stage the mistake dropped back from and has to win back, as a
  /// rank, or 0 when nothing is locked.
  IntColumn get lockedStage => integer()
      .withDefault(const Constant(0))
      .check(lockedStage.isBiggerOrEqualValue(0))();

  /// Whether the mistake is finished: every step passed, nothing left to
  /// play.
  BoolColumn get retired => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    // The same text as [practiceSubcategoryRule].
    // ignore: lines_longer_than_80_chars
    "CHECK (subcategory = '' OR (category = 'Grammar' AND subcategory IN ('prepositions', 'agreement', 'verb_forms_and_tenses', 'subjunctive', 'ser_and_estar', 'articles', 'pronouns', 'sentence_structure')) OR (category = 'Spelling' AND subcategory IN ('written_accents', 'letters', 'punctuation_and_capitals')) OR (category = 'Word Choice' AND subcategory IN ('false_friends', 'mixed_up_pairs')))",
  ];
}

/// One question built for a mistake, in step P.1's format.
@DataClassName('PracticeQuestionRow')
class PracticeQuestions extends Table {
  /// Stable id of this question (the question's own `id` in P.1's format).
  TextColumn get id => text().clientDefault(newPracticeId)();

  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// The mistake this question practises. Removing the mistake removes the
  /// question.
  TextColumn get itemId =>
      text().references(PracticeItems, #id, onDelete: KeyAction.cascade)();

  /// The game, as P.1 writes it ("choose_correction", "fill_gap", ...).
  TextColumn get game => text()();

  /// The question's stage on the ladder, as step P.2's rank.
  IntColumn get stage => integer().check(stage.isBiggerOrEqualValue(0))();

  /// The whole question as one JSON object in P.1's format
  /// (`Question.toJson`), read back with P.1's parser.
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A Guided group (G6; step P.9).
@DataClassName('PracticeGroup')
class PracticeGroups extends Table {
  TextColumn get id => text().clientDefault(newPracticeId)();

  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// The language of the group's mistakes, as `Language.name`.
  TextColumn get language => text()();

  /// How the group was put together.
  TextColumn get kind => textEnum<PracticeGroupKind>()();

  /// For a group of one kind: its category name; otherwise empty.
  TextColumn get category => text().withDefault(const Constant(''))();

  /// For a group of one subcategory: that subcategory; otherwise none.
  TextColumn get subcategory => text()
      .map(const PracticeSubcategoryConverter())
      .withDefault(const Constant(''))();

  /// True for the revision group of a stage, where mistakes that stayed
  /// wrong after two retries collect (G6, points 1 and 2).
  BoolColumn get isRevision => boolean().withDefault(const Constant(false))();

  /// The stage the group is playing, as step P.2's rank.
  IntColumn get stage => integer()
      .withDefault(const Constant(1))
      .check(stage.isBiggerOrEqualValue(0))();

  /// How many retries the group has had at this stage since its last full
  /// round.
  IntColumn get retriesAtStage => integer()
      .withDefault(const Constant(0))
      .check(retriesAtStage.isBiggerOrEqualValue(0))();

  /// When the group last passed a stage, or none yet.
  DateTimeColumn get lastPassedAt => dateTime().nullable()();

  /// When the group's current stage opens (G6, point 4). None means it is
  /// open now. Kept so Learn can show it and a reminder can be set for it.
  DateTimeColumn get unlocksAt => dateTime().nullable()();

  /// True once the group has nothing left to play.
  BoolColumn get finished => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    // The same text as [practiceGroupKindRule].
    "CHECK (category IN ('', 'Spelling', 'Grammar', 'Word Choice', 'Natural phrasing'))",
    // The same text as [practiceSubcategoryRule].
    // ignore: lines_longer_than_80_chars
    "CHECK (subcategory = '' OR (category = 'Grammar' AND subcategory IN ('prepositions', 'agreement', 'verb_forms_and_tenses', 'subjunctive', 'ser_and_estar', 'articles', 'pronouns', 'sentence_structure')) OR (category = 'Spelling' AND subcategory IN ('written_accents', 'letters', 'punctuation_and_capitals')) OR (category = 'Word Choice' AND subcategory IN ('false_friends', 'mixed_up_pairs')))",
  ];
}

/// One mistake's place in one group.
@DataClassName('PracticeGroupItem')
class PracticeGroupItems extends Table {
  TextColumn get id => text().clientDefault(newPracticeId)();

  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get groupId =>
      text().references(PracticeGroups, #id, onDelete: KeyAction.cascade)();

  TextColumn get itemId =>
      text().references(PracticeItems, #id, onDelete: KeyAction.cascade)();

  /// The mistake's place in the group's order.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// True when the mistake was answered wrong in the group's latest round,
  /// so a retry holds only these (G6).
  BoolColumn get missedLastRound =>
      boolean().withDefault(const Constant(false))();

  /// How many retries in a row the mistake has stayed wrong. After two it
  /// leaves for the stage's revision group (G6, point 1).
  IntColumn get failedRetries => integer()
      .withDefault(const Constant(0))
      .check(failedRetries.isBiggerOrEqualValue(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, itemId},
  ];
}

/// One answer the learner gave.
@DataClassName('PracticeAttempt')
class PracticeAttempts extends Table {
  TextColumn get id => text().clientDefault(newPracticeId)();

  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();

  /// The mistake that was practised. Removing the mistake removes its
  /// attempts.
  TextColumn get itemId =>
      text().references(PracticeItems, #id, onDelete: KeyAction.cascade)();

  /// The question that was asked, or none once that question has gone.
  TextColumn get questionId => text().nullable().references(
    PracticeQuestions,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The group it was answered in, or none (Free play, or the group has
  /// gone).
  TextColumn get groupId => text().nullable().references(
    PracticeGroups,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Guided or Free play.
  TextColumn get mode => textEnum<PracticeMode>()();

  /// The game, as P.1 writes it.
  TextColumn get game => text()();

  /// The stage the question was at, as step P.2's rank.
  IntColumn get stage => integer().check(stage.isBiggerOrEqualValue(0))();

  /// What the learner answered, as given.
  TextColumn get answer => text().withDefault(const Constant(''))();

  /// Whether the answer was right.
  BoolColumn get correct => boolean()();

  /// When the answer was given.
  DateTimeColumn get answeredAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// One slot of one rule in the rule bank (step P.3's `MatchRule` and
/// `MatchSlot`), one row per slot as the old sheet's Rules tab had it.
@DataClassName('PracticeRuleSlot')
class PracticeRules extends Table {
  TextColumn get id => text().clientDefault(newPracticeId)();

  DateTimeColumn get changedAt => dateTime().withDefault(currentDateAndTime)();

  /// The language the rule belongs to, as `Language.name`.
  TextColumn get language => text()();

  /// The rule's id, for example "subj-esperar". Shared by its slots.
  TextColumn get ruleId => text()();

  /// The rule's name, for the person reading it.
  TextColumn get ruleName => text().withDefault(const Constant(''))();

  /// The slot's name or number.
  TextColumn get slot => text()();

  /// What the slot needs, in words.
  TextColumn get needs => text().withDefault(const Constant(''))();

  /// The starts this slot accepts, as a JSON list of text.
  TextColumn get starts => text().withDefault(const Constant('[]'))();

  /// The one answer every start in this slot must be matched with; empty
  /// when the answer is free.
  TextColumn get fixedAnswer => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {language, ruleId, slot},
  ];
}

/// The practice database.
///
/// Nothing in the app opens it yet: step P.6 is the first to write to it.
@DriftDatabase(
  tables: [
    PracticeItems,
    PracticeQuestions,
    PracticeGroups,
    PracticeGroupItems,
    PracticeAttempts,
    PracticeRules,
  ],
)
class PracticeDatabase extends _$PracticeDatabase {
  /// Opens the database on [executor]. Tests pass an in-memory database.
  PracticeDatabase(super.executor, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Opens the database file in the app's documents folder, beside the JSON
  /// files, making it on first use.
  factory PracticeDatabase.onPhone() => PracticeDatabase(
    LazyDatabase(() async {
      final folder = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File(p.join(folder.path, fileName)),
      );
    }),
  );

  /// The database file's name.
  static const String fileName = 'practice.sqlite';

  final DateTime Function() _clock;

  /// The time to write as a row's changed-at time when changing it.
  DateTime now() => _clock();

  /// The number of the current table layout. Raise it by one with every
  /// change to a table, and add the change to [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // Version 1 is the first. Each later change to a table adds its step
      // here, with a test in test/features/practice/.
    },
    beforeOpen: (details) async {
      // Without this, removing a practice item would leave its questions,
      // attempts and group places behind.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
