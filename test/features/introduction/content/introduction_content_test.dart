import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/introduction/content/fuller_question.dart';
import 'package:spanish_correction_app/features/introduction/content/interest.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_content.dart';
import 'package:spanish_correction_app/features/introduction/content/warm_up_question.dart';

void main() {
  group('interests', () {
    test(
      'every interest has a unique id and a label in all three languages',
      () {
        final ids = IntroductionContent.interests.map((i) => i.id).toSet();

        expect(IntroductionContent.interests, isNotEmpty);
        expect(ids.length, IntroductionContent.interests.length);
        for (final interest in IntroductionContent.interests) {
          expect(interest.id.trim(), isNotEmpty);
          expect(interest.english.trim(), isNotEmpty, reason: interest.id);
          expect(interest.spanish.trim(), isNotEmpty, reason: interest.id);
          expect(interest.portuguese.trim(), isNotEmpty, reason: interest.id);
        }
      },
    );

    test('labelFor gives the label in the language being learnt', () {
      const interest = Interest(
        id: 'travel',
        english: 'Travel',
        spanish: 'Los viajes',
        portuguese: 'As viagens',
      );

      expect(interest.labelFor(Language.spanish), 'Los viajes');
      expect(interest.labelFor(Language.portuguese), 'As viagens');
    });

    test(
      'interestById finds a known id and returns null for an unknown one',
      () {
        expect(IntroductionContent.interestById('travel')?.english, 'Travel');
        expect(IntroductionContent.interestById('no-such-interest'), isNull);
      },
    );
  });

  group('warm-up questions', () {
    test('there are two: one typed, then one spoken, each with a hint', () {
      final warmUps = IntroductionContent.warmUpQuestionsFor(Language.spanish);

      expect(warmUps.length, 2);
      expect(warmUps[0].input, WarmUpInput.typed);
      expect(warmUps[1].input, WarmUpInput.spoken);
      for (final warmUp in warmUps) {
        expect(warmUp.text.trim(), isNotEmpty, reason: warmUp.id);
        expect(warmUp.hint.trim(), isNotEmpty, reason: warmUp.id);
      }
      expect(warmUps.map((w) => w.id).toSet().length, 2);
    });

    test('there are none for Portuguese in slice 1', () {
      expect(
        IntroductionContent.warmUpQuestionsFor(Language.portuguese),
        isEmpty,
      );
    });
  });

  group('fuller questions', () {
    test('every question has a unique id, text and a known interest', () {
      final interestIds = IntroductionContent.interests
          .map((i) => i.id)
          .toSet();
      final questionIds = IntroductionContent.fullerQuestions.map((q) => q.id);

      expect(questionIds.toSet().length, questionIds.length);
      for (final question in IntroductionContent.fullerQuestions) {
        expect(question.text.trim(), isNotEmpty, reason: question.id);
        expect(
          interestIds,
          contains(question.interestId),
          reason: '${question.id} points at an interest that does not exist',
        );
      }
    });

    test(
      'every interest has three Spanish questions with different structures',
      () {
        for (final interest in IntroductionContent.interests) {
          final questions = IntroductionContent.fullerQuestionsForInterest(
            interest.id,
            Language.spanish,
          );
          final structures = questions.map((q) => q.structure).toSet();

          expect(questions.length, 3, reason: interest.id);
          expect(structures.length, 3, reason: interest.id);
        }
      },
    );

    test('there are no Portuguese questions in slice 1', () {
      expect(
        IntroductionContent.fullerQuestionsFor(Language.portuguese),
        isEmpty,
      );
      expect(IntroductionContent.hasContentFor(Language.spanish), isTrue);
      expect(IntroductionContent.hasContentFor(Language.portuguese), isFalse);
    });
  });

  group('drawFullerQuestions', () {
    test('one chosen interest gives its three questions', () {
      final drawn = IntroductionContent.drawFullerQuestions(
        chosenInterestIds: ['music'],
        language: Language.spanish,
      );

      expect(drawn.map((q) => q.id), ['music-1', 'music-2', 'music-3']);
    });

    test(
      'three chosen interests give one question each, in the order chosen',
      () {
        final drawn = IntroductionContent.drawFullerQuestions(
          chosenInterestIds: ['sport', 'travel', 'art'],
          language: Language.spanish,
        );

        expect(drawn.length, 3);
        expect(drawn.map((q) => q.interestId), ['sport', 'travel', 'art']);
        expect(drawn.map((q) => q.structure).toSet().length, 3);
      },
    );

    test(
      'two chosen interests alternate and keep the structures different',
      () {
        final drawn = IntroductionContent.drawFullerQuestions(
          chosenInterestIds: ['travel', 'food'],
          language: Language.spanish,
        );

        expect(drawn.map((q) => q.interestId), ['travel', 'food', 'travel']);
        expect(drawn.map((q) => q.structure).toSet().length, 3);
      },
    );

    test('prefers an unused structure over file order within an interest', () {
      // music-1 and books-1 both pull present habits; books should skip to a
      // question with a structure not yet used.
      final drawn = IntroductionContent.drawFullerQuestions(
        chosenInterestIds: ['music', 'books'],
        language: Language.spanish,
      );

      expect(drawn[0].id, 'music-1');
      expect(drawn[1].interestId, 'books');
      expect(drawn[1].structure, isNot(QuestionStructure.presentHabits));
      expect(drawn.map((q) => q.structure).toSet().length, 3);
    });

    test('many chosen interests still give only three questions', () {
      final drawn = IntroductionContent.drawFullerQuestions(
        chosenInterestIds: IntroductionContent.interests
            .map((i) => i.id)
            .toList(),
        language: Language.spanish,
      );

      expect(drawn.length, IntroductionContent.fullerQuestionCount);
      expect(drawn.map((q) => q.interestId).toSet().length, 3);
    });

    test('ignores unknown and repeated ids', () {
      final drawn = IntroductionContent.drawFullerQuestions(
        chosenInterestIds: ['no-such-interest', 'work', 'work'],
        language: Language.spanish,
      );

      expect(drawn.map((q) => q.id), ['work-1', 'work-2', 'work-3']);
    });

    test('with nothing chosen, draws from every interest in list order', () {
      final drawn = IntroductionContent.drawFullerQuestions(
        chosenInterestIds: const [],
        language: Language.spanish,
      );

      expect(drawn.map((q) => q.interestId), ['travel', 'food', 'music']);
      expect(drawn.map((q) => q.structure).toSet().length, 3);
    });

    test('returns nothing for a language with no content', () {
      final drawn = IntroductionContent.drawFullerQuestions(
        chosenInterestIds: ['travel'],
        language: Language.portuguese,
      );

      expect(drawn, isEmpty);
    });

    test('count can be changed', () {
      final drawn = IntroductionContent.drawFullerQuestions(
        chosenInterestIds: ['travel'],
        language: Language.spanish,
        count: 2,
      );

      expect(drawn.length, 2);
    });
  });

  group('end screen', () {
    test('has a closing line for Spanish and none for Portuguese', () {
      expect(IntroductionContent.endScreenLine.trim(), isNotEmpty);
      expect(
        IntroductionContent.endScreenLineFor(Language.spanish),
        IntroductionContent.endScreenLine,
      );
      expect(IntroductionContent.endScreenLineFor(Language.portuguese), isNull);
    });
  });
}
