// Offline tests for the practice database (practice track, step P.5), on a
// database held in memory: nothing is written to disk and nothing is sent
// anywhere.
import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/practice/data/practice_database.dart';
import 'package:spanish_correction_app/features/practice/domain/practice_subcategory.dart';
import 'package:spanish_correction_app/features/practice/domain/question.dart';
import 'package:spanish_correction_app/features/practice/domain/question_parser.dart';

PracticeItemsCompanion item({
  String? id,
  String category = PracticeCategory.grammar,
  PracticeSubcategory? subcategory = PracticeSubcategory.prepositions,
  String? savedCorrectionId,
}) => PracticeItemsCompanion.insert(
  id: id == null ? const Value.absent() : Value(id),
  language: 'spanish',
  originalSentence: 'Estoy pensando de cambiar de trabajo.',
  correctedSentence: 'Estoy pensando en cambiar de trabajo.',
  originalPhrase: 'de',
  correctedPhrase: 'en',
  originalStart: const Value(15),
  originalEnd: const Value(17),
  correctedStart: const Value(15),
  correctedEnd: const Value(17),
  explanation: const Value('pensar en + infinitive'),
  englishSentence: const Value("I'm thinking of changing jobs."),
  englishHighlightStart: const Value(13),
  englishHighlightEnd: const Value(15),
  category: category,
  subcategory: Value(subcategory),
  contextText: const Value(
    'Hola. Estoy pensando de cambiar de trabajo. ¿Qué opinas?',
  ),
  chatId: const Value('chat-1'),
  inputMode: PracticeInputMode.typed,
  savedCorrectionId: Value(savedCorrectionId),
);

final refused = throwsA(isA<SqliteException>());

void main() {
  late PracticeDatabase database;

  setUpAll(() {
    // One test opens a second database with its own clock; each test's
    // database is separate and held in memory.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    database = PracticeDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  group('the subcategory list (G4)', () {
    test('has eight for Grammar, three for Spelling, two for Word Choice '
        'and none for Natural phrasing', () {
      expect(
        PracticeSubcategory.forCategory(PracticeCategory.grammar),
        hasLength(8),
      );
      expect(
        PracticeSubcategory.forCategory(PracticeCategory.spelling),
        hasLength(3),
      );
      expect(
        PracticeSubcategory.forCategory(PracticeCategory.wordChoice),
        hasLength(2),
      );
      expect(
        PracticeSubcategory.forCategory(PracticeCategory.naturalPhrasing),
        isEmpty,
      );
      expect(PracticeSubcategory.values, hasLength(13));
    });

    test('uses the same four category names as the rest of the app', () {
      expect(PracticeCategory.all, [
        for (final category in ErrorCategory.values) category.label,
      ]);
    });

    test('every stored value is different and reads back', () {
      final stored = {
        for (final s in PracticeSubcategory.values) s.storedValue,
      };
      expect(stored, hasLength(PracticeSubcategory.values.length));
      for (final s in PracticeSubcategory.values) {
        expect(PracticeSubcategory.fromStoredValue(s.storedValue), s);
      }
      expect(PracticeSubcategory.fromStoredValue(''), isNull);
    });

    test('free text is refused, never read as a new subcategory', () {
      expect(
        () => PracticeSubcategory.fromStoredValue('Noun gender'),
        throwsFormatException,
      );
    });

    test("the database's rule is written from the list", () {
      String listed(String category) => PracticeSubcategory.forCategory(
        category,
      ).map((s) => "'${s.storedValue}'").join(', ');
      final expected =
          "CHECK (subcategory = '' "
          "OR (category = 'Grammar' AND subcategory IN "
          "(${listed(PracticeCategory.grammar)})) "
          "OR (category = 'Spelling' AND subcategory IN "
          "(${listed(PracticeCategory.spelling)})) "
          "OR (category = 'Word Choice' AND subcategory IN "
          "(${listed(PracticeCategory.wordChoice)})))";
      expect(practiceSubcategoryRule, expected);
      expect(database.practiceItems.customConstraints, [
        practiceSubcategoryRule,
      ]);
      expect(database.practiceGroups.customConstraints, [
        practiceGroupKindRule,
        practiceSubcategoryRule,
      ]);
      expect(
        practiceGroupKindRule,
        "CHECK (category IN ('', "
        "${PracticeCategory.all.map((c) => "'$c'").join(', ')}))",
      );
    });
  });

  group('practice items', () {
    test('a row is written and read back with every field', () async {
      await database
          .into(database.practiceItems)
          .insert(item(id: 'item-1', savedCorrectionId: 'saved-1'));

      final row = await database.select(database.practiceItems).getSingle();
      expect(row.id, 'item-1');
      expect(row.language, 'spanish');
      expect(row.originalSentence, 'Estoy pensando de cambiar de trabajo.');
      expect(row.correctedSentence, 'Estoy pensando en cambiar de trabajo.');
      expect(row.originalPhrase, 'de');
      expect(row.correctedPhrase, 'en');
      expect([row.originalStart, row.originalEnd], [15, 17]);
      expect([row.correctedStart, row.correctedEnd], [15, 17]);
      expect(row.explanation, 'pensar en + infinitive');
      expect(row.englishSentence, "I'm thinking of changing jobs.");
      expect([row.englishHighlightStart, row.englishHighlightEnd], [13, 15]);
      expect(row.category, 'Grammar');
      expect(row.subcategory, PracticeSubcategory.prepositions);
      expect(row.contextText, contains('¿Qué opinas?'));
      expect(row.chatId, 'chat-1');
      expect(row.inputMode, PracticeInputMode.typed);
      expect(row.savedCorrectionId, 'saved-1');
      expect(row.ladderStage, 0);
      expect(row.lockedStage, 0);
      expect(row.retired, isFalse);
    });

    test('a row gets a stable id and a changed-at time by itself', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      await database.into(database.practiceItems).insert(item());
      await database.into(database.practiceItems).insert(item());

      final rows = await database.select(database.practiceItems).get();
      expect(rows, hasLength(2));
      expect(rows[0].id, hasLength(32));
      expect(rows[0].id, isNot(rows[1].id));
      for (final row in rows) {
        expect(row.changedAt.isAfter(before), isTrue);
        expect(row.createdAt.isAfter(before), isTrue);
      }
    });

    test('a change is stamped with the time the database gives', () async {
      final later = DateTime(2030, 1, 2, 3, 4, 5);
      final clocked = PracticeDatabase(
        NativeDatabase.memory(),
        clock: () => later,
      );
      addTearDown(clocked.close);
      await clocked.into(clocked.practiceItems).insert(item(id: 'item-1'));

      await (clocked.update(
        clocked.practiceItems,
      )..where((t) => t.id.equals('item-1'))).write(
        PracticeItemsCompanion(
          ladderStage: const Value(2),
          lockedStage: const Value(3),
          changedAt: Value(clocked.now()),
        ),
      );

      final row = await clocked.select(clocked.practiceItems).getSingle();
      expect(row.id, 'item-1');
      expect(row.ladderStage, 2);
      expect(row.lockedStage, 3);
      expect(row.changedAt, later);
    });

    test('no subcategory is kept as none', () async {
      await database
          .into(database.practiceItems)
          .insert(
            item(category: PracticeCategory.naturalPhrasing, subcategory: null),
          );
      final row = await database.select(database.practiceItems).getSingle();
      expect(row.subcategory, isNull);
    });

    test('every subcategory on the list is accepted under its own '
        'category', () async {
      for (final s in PracticeSubcategory.values) {
        await database
            .into(database.practiceItems)
            .insert(item(category: s.category, subcategory: s));
      }
      final rows = await database.select(database.practiceItems).get();
      expect(
        rows.map((r) => r.subcategory).toSet(),
        PracticeSubcategory.values.toSet(),
      );
    });

    test('free text as a subcategory is refused by the database', () async {
      await database.into(database.practiceItems).insert(item(id: 'item-1'));
      await expectLater(
        database.customStatement(
          "UPDATE practice_items SET subcategory = 'Noun gender' "
          "WHERE id = 'item-1'",
        ),
        refused,
      );
    });

    test('a subcategory from another category is refused', () async {
      await expectLater(
        database
            .into(database.practiceItems)
            .insert(
              item(
                category: PracticeCategory.spelling,
                subcategory: PracticeSubcategory.subjunctive,
              ),
            ),
        refused,
      );
      await expectLater(
        database
            .into(database.practiceItems)
            .insert(
              item(
                category: PracticeCategory.naturalPhrasing,
                subcategory: PracticeSubcategory.falseFriends,
              ),
            ),
        refused,
      );
    });

    test('a category that is not one of the four is refused', () async {
      await expectLater(
        database
            .into(database.practiceItems)
            .insert(item(category: 'Other', subcategory: null)),
        refused,
      );
    });

    test('one Saved point has one practice item', () async {
      await database
          .into(database.practiceItems)
          .insert(item(savedCorrectionId: 'saved-1'));
      await expectLater(
        database
            .into(database.practiceItems)
            .insert(item(savedCorrectionId: 'saved-1')),
        refused,
      );
      // Mistakes that did not come from Saved (the one-off import) have no
      // Saved id, and any number of them may sit side by side.
      await database.into(database.practiceItems).insert(item());
      await database.into(database.practiceItems).insert(item());
      expect(await database.select(database.practiceItems).get(), hasLength(3));
    });
  });

  group('questions', () {
    test("a question in the games' format is stored and read back", () async {
      await database.into(database.practiceItems).insert(item(id: 'item-1'));
      final question = Question(
        id: 'item-1-s1',
        item: 'item-1',
        game: GameType.chooseCorrection,
        category: 'Prepositions',
        type: QuestionType.grammar,
        prompt: 'Estoy pensando **de** cambiar de trabajo.',
        answers: const ['en'],
        options: const ['en', 'a', 'por'],
        explanation:
            'pensar en + infinitive = to be thinking of doing something',
      );

      await database
          .into(database.practiceQuestions)
          .insert(
            PracticeQuestionsCompanion.insert(
              id: Value(question.id),
              itemId: question.item,
              game: question.game.jsonValue,
              stage: 1,
              body: jsonEncode(question.toJson()),
            ),
          );

      final row = await database.select(database.practiceQuestions).getSingle();
      expect(row.id, 'item-1-s1');
      expect(row.itemId, 'item-1');
      expect(row.game, 'choose_correction');
      expect(row.stage, 1);
      expect(row.changedAt, isNotNull);

      final parsed = parseQuestions('[${row.body}]');
      expect(parsed.problems, isEmpty);
      final read = parsed.questions.single;
      expect(read.id, question.id);
      expect(read.item, 'item-1');
      expect(read.answers, ['en']);
      expect(read.options, ['en', 'a', 'por']);
      expect(read.stage, LadderStage.one);
    });

    test('a question for a mistake that does not exist is refused', () async {
      await expectLater(
        database
            .into(database.practiceQuestions)
            .insert(
              PracticeQuestionsCompanion.insert(
                itemId: 'no-such-item',
                game: 'repair',
                stage: 3,
                body: '{}',
              ),
            ),
        refused,
      );
    });
  });

  group('groups and unlock times', () {
    test('a group keeps its kind, stage, items and unlock time', () async {
      await database.into(database.practiceItems).insert(item(id: 'item-1'));
      await database.into(database.practiceItems).insert(item(id: 'item-2'));
      final unlocks = DateTime(2026, 12, 1, 18);

      await database
          .into(database.practiceGroups)
          .insert(
            PracticeGroupsCompanion.insert(
              id: const Value('group-1'),
              language: 'spanish',
              kind: PracticeGroupKind.oneKind,
              category: const Value(PracticeCategory.grammar),
              subcategory: const Value(PracticeSubcategory.prepositions),
              stage: const Value(2),
              unlocksAt: Value(unlocks),
            ),
          );
      for (final (index, id) in ['item-1', 'item-2'].indexed) {
        await database
            .into(database.practiceGroupItems)
            .insert(
              PracticeGroupItemsCompanion.insert(
                groupId: 'group-1',
                itemId: id,
                position: Value(index),
              ),
            );
      }

      final group = await database.select(database.practiceGroups).getSingle();
      expect(group.kind, PracticeGroupKind.oneKind);
      expect(group.category, 'Grammar');
      expect(group.subcategory, PracticeSubcategory.prepositions);
      expect(group.isRevision, isFalse);
      expect(group.stage, 2);
      expect(group.retriesAtStage, 0);
      expect(group.unlocksAt, unlocks);
      expect(group.lastPassedAt, isNull);
      expect(group.finished, isFalse);
      expect(group.changedAt, isNotNull);

      final members = await (database.select(
        database.practiceGroupItems,
      )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
      expect(members.map((m) => m.itemId), ['item-1', 'item-2']);
      expect(members.every((m) => !m.missedLastRound), isTrue);
      expect(members.every((m) => m.failedRetries == 0), isTrue);
      expect(members.map((m) => m.id).toSet(), hasLength(2));
    });

    test('groups that are open, and the next one to open, can be asked '
        'for', () async {
      final now = DateTime(2026, 12, 1, 12);
      Future<void> add(String id, DateTime? unlocksAt) => database
          .into(database.practiceGroups)
          .insert(
            PracticeGroupsCompanion.insert(
              id: Value(id),
              language: 'spanish',
              kind: PracticeGroupKind.mixed,
              unlocksAt: Value(unlocksAt),
            ),
          );
      await add('open-now', null);
      await add('opened-yesterday', now.subtract(const Duration(days: 1)));
      await add('opens-tomorrow', now.add(const Duration(days: 1)));
      await add('opens-next-week', now.add(const Duration(days: 7)));

      final open =
          await (database.select(database.practiceGroups)
                ..where(
                  (t) =>
                      t.unlocksAt.isNull() |
                      t.unlocksAt.isSmallerOrEqualValue(now),
                )
                ..orderBy([(t) => OrderingTerm(expression: t.id)]))
              .get();
      expect(open.map((g) => g.id), ['open-now', 'opened-yesterday']);

      final next =
          await (database.select(database.practiceGroups)
                ..where((t) => t.unlocksAt.isBiggerThanValue(now))
                ..orderBy([(t) => OrderingTerm(expression: t.unlocksAt)])
                ..limit(1))
              .getSingle();
      expect(next.id, 'opens-tomorrow');
      expect(next.unlocksAt, now.add(const Duration(days: 1)));
    });

    test('a mistake sits in a group only once', () async {
      await database.into(database.practiceItems).insert(item(id: 'item-1'));
      await database
          .into(database.practiceGroups)
          .insert(
            PracticeGroupsCompanion.insert(
              id: const Value('group-1'),
              language: 'spanish',
              kind: PracticeGroupKind.handPicked,
            ),
          );
      PracticeGroupItemsCompanion place() => PracticeGroupItemsCompanion.insert(
        groupId: 'group-1',
        itemId: 'item-1',
      );
      await database.into(database.practiceGroupItems).insert(place());
      await expectLater(
        database.into(database.practiceGroupItems).insert(place()),
        refused,
      );
    });

    test('a revision group is marked as one', () async {
      await database
          .into(database.practiceGroups)
          .insert(
            PracticeGroupsCompanion.insert(
              language: 'spanish',
              kind: PracticeGroupKind.mixed,
              isRevision: const Value(true),
              stage: const Value(3),
            ),
          );
      final group = await database.select(database.practiceGroups).getSingle();
      expect(group.isRevision, isTrue);
      expect(group.stage, 3);
      expect(group.category, '');
      expect(group.subcategory, isNull);
    });

    test('a group cannot name a subcategory without its category', () async {
      await expectLater(
        database
            .into(database.practiceGroups)
            .insert(
              PracticeGroupsCompanion.insert(
                language: 'spanish',
                kind: PracticeGroupKind.oneKind,
                subcategory: const Value(PracticeSubcategory.articles),
              ),
            ),
        refused,
      );
    });
  });

  group('attempts', () {
    Future<void> itemQuestionAndGroup() async {
      await database.into(database.practiceItems).insert(item(id: 'item-1'));
      await database
          .into(database.practiceQuestions)
          .insert(
            PracticeQuestionsCompanion.insert(
              id: const Value('q-1'),
              itemId: 'item-1',
              game: 'fill_gap',
              stage: 2,
              body: '{}',
            ),
          );
      await database
          .into(database.practiceGroups)
          .insert(
            PracticeGroupsCompanion.insert(
              id: const Value('group-1'),
              language: 'spanish',
              kind: PracticeGroupKind.mixed,
            ),
          );
    }

    test('a Guided and a Free play answer are both kept', () async {
      await itemQuestionAndGroup();
      final answeredAt = DateTime(2026, 12, 1, 18, 30);

      await database
          .into(database.practiceAttempts)
          .insert(
            PracticeAttemptsCompanion.insert(
              id: const Value('a-1'),
              itemId: 'item-1',
              questionId: const Value('q-1'),
              groupId: const Value('group-1'),
              mode: PracticeMode.guided,
              game: 'fill_gap',
              stage: 2,
              answer: const Value('en'),
              correct: true,
              answeredAt: Value(answeredAt),
            ),
          );
      await database
          .into(database.practiceAttempts)
          .insert(
            PracticeAttemptsCompanion.insert(
              id: const Value('a-2'),
              itemId: 'item-1',
              questionId: const Value('q-1'),
              mode: PracticeMode.free,
              game: 'fill_gap',
              stage: 2,
              answer: const Value('de'),
              correct: false,
            ),
          );

      final attempts = await (database.select(
        database.practiceAttempts,
      )..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
      expect(attempts, hasLength(2));
      expect(attempts[0].mode, PracticeMode.guided);
      expect(attempts[0].groupId, 'group-1');
      expect(attempts[0].correct, isTrue);
      expect(attempts[0].answer, 'en');
      expect(attempts[0].answeredAt, answeredAt);
      expect(attempts[0].changedAt, isNotNull);
      expect(attempts[1].mode, PracticeMode.free);
      expect(attempts[1].groupId, isNull);
      expect(attempts[1].correct, isFalse);
    });

    test('an attempt outlives its question and its group', () async {
      await itemQuestionAndGroup();
      await database
          .into(database.practiceAttempts)
          .insert(
            PracticeAttemptsCompanion.insert(
              itemId: 'item-1',
              questionId: const Value('q-1'),
              groupId: const Value('group-1'),
              mode: PracticeMode.guided,
              game: 'fill_gap',
              stage: 2,
              correct: true,
            ),
          );

      await database.delete(database.practiceQuestions).go();
      await database.delete(database.practiceGroups).go();

      final attempt = await database
          .select(database.practiceAttempts)
          .getSingle();
      expect(attempt.itemId, 'item-1');
      expect(attempt.questionId, isNull);
      expect(attempt.groupId, isNull);
    });
  });

  group('the rule bank', () {
    test('a rule is kept one row per slot and read back', () async {
      await database.batch((batch) {
        batch.insertAll(database.practiceRules, [
          PracticeRulesCompanion.insert(
            language: 'spanish',
            ruleId: 'prep-verbs',
            ruleName: const Value('Verbs and their prepositions'),
            slot: '1',
            needs: const Value('a verb that takes en'),
            starts: Value(jsonEncode(['pensar', 'confiar'])),
            fixedAnswer: const Value('en'),
          ),
          PracticeRulesCompanion.insert(
            language: 'spanish',
            ruleId: 'prep-verbs',
            ruleName: const Value('Verbs and their prepositions'),
            slot: '2',
            needs: const Value('a verb that takes de'),
            starts: Value(jsonEncode(['depender'])),
            fixedAnswer: const Value('de'),
          ),
        ]);
      });

      final slots =
          await (database.select(database.practiceRules)
                ..where((t) => t.ruleId.equals('prep-verbs'))
                ..orderBy([(t) => OrderingTerm(expression: t.slot)]))
              .get();
      expect(slots, hasLength(2));
      expect(slots[0].ruleName, 'Verbs and their prepositions');
      expect(jsonDecode(slots[0].starts), ['pensar', 'confiar']);
      expect(slots[0].fixedAnswer, 'en');
      expect(slots[1].needs, 'a verb that takes de');
      expect(slots.map((s) => s.id).toSet(), hasLength(2));
      expect(slots[0].changedAt, isNotNull);
    });

    test('a rule cannot have the same slot twice', () async {
      PracticeRulesCompanion slot() => PracticeRulesCompanion.insert(
        language: 'spanish',
        ruleId: 'prep-verbs',
        slot: '1',
      );
      await database.into(database.practiceRules).insert(slot());
      await expectLater(
        database.into(database.practiceRules).insert(slot()),
        refused,
      );
    });
  });

  test('removing a practice item removes everything under it, and nothing '
      'else', () async {
    await database.into(database.practiceItems).insert(item(id: 'goes'));
    await database.into(database.practiceItems).insert(item(id: 'stays'));
    await database
        .into(database.practiceGroups)
        .insert(
          PracticeGroupsCompanion.insert(
            id: const Value('group-1'),
            language: 'spanish',
            kind: PracticeGroupKind.mixed,
          ),
        );
    for (final id in ['goes', 'stays']) {
      await database
          .into(database.practiceQuestions)
          .insert(
            PracticeQuestionsCompanion.insert(
              id: Value('$id-s1'),
              itemId: id,
              game: 'choose_correction',
              stage: 1,
              body: '{}',
            ),
          );
      await database
          .into(database.practiceGroupItems)
          .insert(
            PracticeGroupItemsCompanion.insert(groupId: 'group-1', itemId: id),
          );
      await database
          .into(database.practiceAttempts)
          .insert(
            PracticeAttemptsCompanion.insert(
              itemId: id,
              questionId: Value('$id-s1'),
              groupId: const Value('group-1'),
              mode: PracticeMode.guided,
              game: 'choose_correction',
              stage: 1,
              correct: false,
            ),
          );
    }

    await (database.delete(
      database.practiceItems,
    )..where((t) => t.id.equals('goes'))).go();

    final items = await database.select(database.practiceItems).get();
    final questions = await database.select(database.practiceQuestions).get();
    final members = await database.select(database.practiceGroupItems).get();
    final attempts = await database.select(database.practiceAttempts).get();
    final groups = await database.select(database.practiceGroups).get();
    expect(items.map((r) => r.id), ['stays']);
    expect(questions.map((r) => r.itemId), ['stays']);
    expect(members.map((r) => r.itemId), ['stays']);
    expect(attempts.map((r) => r.itemId), ['stays']);
    expect(groups.map((r) => r.id), ['group-1']);
  });

  test('the database file is named beside the JSON files', () {
    expect(PracticeDatabase.fileName, 'practice.sqlite');
  });
}
