import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/profile/domain/introduction_progress.dart';
import 'package:spanish_correction_app/features/profile/domain/language_profile.dart';
import 'package:spanish_correction_app/features/profile/domain/learner_profile.dart';

void main() {
  group('LearnerProfile', () {
    test('an empty profile has no interests and an unstarted introduction', () {
      final profile = LearnerProfile.empty();

      expect(profile.interestIds, isEmpty);
      expect(profile.hasInterests, isFalse);
      expect(profile.introduction.hasStarted, isFalse);
      expect(profile.introduction.isComplete, isFalse);
      expect(profile.languages, isEmpty);
      expect(
        profile.languageProfile(Language.spanish),
        const LanguageProfile(),
      );
    });

    test('interests can be added and removed without duplicates', () {
      final profile = LearnerProfile.empty()
          .withInterestAdded('travel')
          .withInterestAdded('music')
          .withInterestAdded('travel');

      expect(profile.interestIds, ['travel', 'music']);
      expect(profile.hasInterest('music'), isTrue);

      final fewer = profile.withInterestRemoved('travel');
      expect(fewer.interestIds, ['music']);
      expect(fewer.withInterestRemoved('no-such').interestIds, ['music']);
    });

    test('withInterestIds keeps order, drops duplicates and blanks', () {
      final profile = LearnerProfile.empty().withInterestIds([
        'sport',
        '',
        'travel',
        'sport',
      ]);

      expect(profile.interestIds, ['sport', 'travel']);
    });

    test('the interest list cannot be changed from outside', () {
      final profile = LearnerProfile(interestIds: ['travel']);

      expect(() => profile.interestIds.add('music'), throwsUnsupportedError);
    });

    test('survives a round trip through JSON', () {
      final profile = LearnerProfile(
        interestIds: const ['travel', 'food'],
        introduction: IntroductionProgress(
          language: Language.spanish,
          answeredWarmUpIds: const ['warm-up-typed', 'warm-up-spoken'],
          interestsChosen: true,
          fullerQuestionIds: const ['travel-1', 'food-2', 'travel-3'],
          fullerAnswers: const [
            FullerAnswer(questionId: 'travel-1', submissionId: 'sub-1'),
            FullerAnswer(questionId: 'food-2'),
          ],
          isComplete: true,
          completedAt: DateTime(2026, 11, 12, 9, 30),
        ),
        languages: const {Language.spanish: LanguageProfile()},
      );

      final restored = LearnerProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, Object?>,
      );

      expect(restored.interestIds, ['travel', 'food']);
      expect(restored.introduction.language, Language.spanish);
      expect(restored.introduction.answeredWarmUpIds, [
        'warm-up-typed',
        'warm-up-spoken',
      ]);
      expect(restored.introduction.interestsChosen, isTrue);
      expect(restored.introduction.fullerQuestionIds, [
        'travel-1',
        'food-2',
        'travel-3',
      ]);
      expect(restored.introduction.fullerAnswers, const [
        FullerAnswer(questionId: 'travel-1', submissionId: 'sub-1'),
        FullerAnswer(questionId: 'food-2'),
      ]);
      expect(restored.introduction.isComplete, isTrue);
      expect(restored.introduction.completedAt, DateTime(2026, 11, 12, 9, 30));
      expect(restored.languages.keys, [Language.spanish]);
      expect(restored.languageProfile(Language.portuguese), isNotNull);
    });

    test('writes the file keys the store will be read by', () {
      final json = LearnerProfile.empty()
          .withInterestAdded('travel')
          .withLanguageProfile(Language.portuguese, const LanguageProfile())
          .toJson();

      expect(json.keys, ['interest_ids', 'introduction', 'languages']);
      expect(json['interest_ids'], ['travel']);
      expect(json['languages'], {'portuguese': <String, Object?>{}});
      expect(
        (json['introduction'] as Map<String, Object?>).keys,
        containsAll([
          'language',
          'answered_warm_up_ids',
          'interests_chosen',
          'fuller_question_ids',
          'fuller_answers',
          'is_complete',
          'completed_at',
        ]),
      );
    });

    test('reads an empty map as an empty profile', () {
      final profile = LearnerProfile.fromJson(const {});

      expect(profile.interestIds, isEmpty);
      expect(profile.introduction.hasStarted, isFalse);
      expect(profile.languages, isEmpty);
    });

    test('ignores malformed fields rather than failing', () {
      final profile = LearnerProfile.fromJson(const {
        'interest_ids': ['travel', 7, null, 'travel', 'music'],
        'introduction': 'not a map',
        'languages': {
          'spanish': <String, Object?>{},
          'klingon': <String, Object?>{},
          'portuguese': 'not a map',
        },
      });

      expect(profile.interestIds, ['travel', 'music']);
      expect(profile.introduction.hasStarted, isFalse);
      expect(profile.languages.keys, [Language.spanish]);
    });

    test('keeps unknown introduction fields out and bad ones harmless', () {
      final profile = LearnerProfile.fromJson(const {
        'introduction': {
          'language': 'spanish',
          'answered_warm_up_ids': ['warm-up-typed', 3],
          'interests_chosen': 'yes',
          'fuller_question_ids': 'travel-1',
          'fuller_answers': [
            {'question_id': 'travel-1', 'submission_id': 'sub-1'},
            {'submission_id': 'orphan'},
            'junk',
          ],
          'is_complete': null,
          'completed_at': 'not a date',
        },
      });

      final progress = profile.introduction;
      expect(progress.language, Language.spanish);
      expect(progress.answeredWarmUpIds, ['warm-up-typed']);
      expect(progress.interestsChosen, isFalse);
      expect(progress.fullerQuestionIds, isEmpty);
      expect(progress.fullerAnswers, const [
        FullerAnswer(questionId: 'travel-1', submissionId: 'sub-1'),
      ]);
      expect(progress.isComplete, isFalse);
      expect(progress.completedAt, isNull);
    });
  });

  group('IntroductionProgress', () {
    const warmUpCount = 2;

    test('starts at the warm-ups', () {
      const progress = IntroductionProgress.notStarted();

      expect(progress.hasStarted, isFalse);
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.warmUps,
      );
    });

    test('moves through the stages as steps are recorded', () {
      var progress = const IntroductionProgress.notStarted().started(
        Language.spanish,
      );
      expect(progress.hasStarted, isTrue);
      expect(progress.language, Language.spanish);
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.warmUps,
      );

      progress = progress.withWarmUpAnswered('typed');
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.warmUps,
      );

      progress = progress.withWarmUpAnswered('spoken');
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.interests,
      );

      progress = progress.withInterestsChosen(
        fullerQuestionIds: ['travel-1', 'music-2'],
      );
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.fullerQuestions,
      );
      expect(progress.hasFullerAnswer, isFalse);
      expect(progress.unansweredFullerQuestionIds, ['travel-1', 'music-2']);

      progress = progress.withFullerAnswer(
        const FullerAnswer(questionId: 'travel-1'),
      );
      expect(progress.hasFullerAnswer, isTrue);
      expect(progress.unansweredFullerQuestionIds, ['music-2']);
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.fullerQuestions,
      );

      progress = progress.withFullerAnswer(
        const FullerAnswer(questionId: 'music-2', submissionId: 'sub-2'),
      );
      expect(progress.allFullerQuestionsAnswered, isTrue);
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.endScreen,
      );

      progress = progress.completed(DateTime(2026, 11, 12));
      expect(progress.isComplete, isTrue);
      expect(progress.completedAt, DateTime(2026, 11, 12));
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.complete,
      );
    });

    test('a completed introduction stays complete whatever else is set', () {
      final progress = const IntroductionProgress.notStarted().completed(
        DateTime(2026, 11, 12),
      );

      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.complete,
      );
    });

    test('the language is recorded once', () {
      final progress = const IntroductionProgress.notStarted()
          .started(Language.spanish)
          .started(Language.portuguese);

      expect(progress.language, Language.spanish);
    });

    test('answering the same warm-up twice records it once', () {
      final progress = const IntroductionProgress.notStarted()
          .withWarmUpAnswered('typed')
          .withWarmUpAnswered('typed');

      expect(progress.answeredWarmUpIds, ['typed']);
    });

    test('answering a fuller question again replaces the earlier record', () {
      final progress = const IntroductionProgress.notStarted()
          .withInterestsChosen(fullerQuestionIds: ['travel-1'])
          .withFullerAnswer(const FullerAnswer(questionId: 'travel-1'))
          .withFullerAnswer(
            const FullerAnswer(questionId: 'travel-1', submissionId: 'sub-1'),
          );

      expect(progress.fullerAnswers, const [
        FullerAnswer(questionId: 'travel-1', submissionId: 'sub-1'),
      ]);
    });

    test('with no questions drawn there is nothing to answer', () {
      final progress = const IntroductionProgress.notStarted()
          .withWarmUpAnswered('typed')
          .withWarmUpAnswered('spoken')
          .withInterestsChosen(fullerQuestionIds: const []);

      expect(progress.allFullerQuestionsAnswered, isFalse);
      expect(
        progress.stageFor(warmUpCount: warmUpCount),
        IntroductionStage.fullerQuestions,
      );
    });
  });
}
