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
        introduction: const IntroductionProgress.notStarted()
            .started(Language.spanish)
            .withInterestsChosen()
            .withChoice(IntroductionChoice.tryIt)
            .withOpenerShown('opener-how-are-you')
            .withOpenerAnswered(submissionId: 'sub-1')
            .withInterestQuestionShown(
              interestId: 'travel',
              questionId: 'travel-question-1',
            )
            .withInterestQuestionAnswered()
            .withRecommendationShown('food')
            .withRecommendationOpened()
            .completed(DateTime(2026, 11, 15, 9, 30)),
        languages: const {Language.spanish: LanguageProfile()},
      );

      final restored = LearnerProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())) as Map<String, Object?>,
      );

      expect(restored.interestIds, ['travel', 'food']);
      expect(restored.introduction.language, Language.spanish);
      expect(restored.introduction.interestsChosen, isTrue);
      expect(restored.introduction.choice, IntroductionChoice.tryIt);
      expect(
        restored.introduction.opener,
        const StepAnswer(
          contentId: 'opener-how-are-you',
          isAnswered: true,
          submissionId: 'sub-1',
        ),
      );
      expect(
        restored.introduction.interestQuestion,
        const StepAnswer(
          contentId: 'travel-question-1',
          interestId: 'travel',
          isAnswered: true,
        ),
      );
      expect(
        restored.introduction.recommendation,
        const RecommendationStep(
          interestId: 'food',
          outcome: RecommendationOutcome.opened,
        ),
      );
      expect(restored.introduction.demo, isNull);
      expect(restored.introduction.isComplete, isTrue);
      expect(restored.introduction.completedAt, DateTime(2026, 11, 15, 9, 30));
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
          'interests_chosen',
          'choice',
          'opener',
          'interest_question',
          'recommendation',
          'demo',
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
          'interests_chosen': 'yes',
          'choice': 'try_it',
          'opener': {
            'content_id': 'opener-how-are-you',
            'is_answered': true,
            'submission_id': 'sub-1',
          },
          'interest_question': 'travel-question-1',
          'recommendation': {'interest_id': 'music', 'outcome': 7},
          'demo': ['sport'],
          'is_complete': null,
          'completed_at': 'not a date',
          'answered_warm_up_ids': ['warm-up-typed'],
          'fuller_question_ids': ['travel-1'],
        },
      });

      final progress = profile.introduction;
      expect(progress.language, Language.spanish);
      expect(progress.interestsChosen, isFalse);
      expect(progress.choice, IntroductionChoice.tryIt);
      expect(
        progress.opener,
        const StepAnswer(
          contentId: 'opener-how-are-you',
          isAnswered: true,
          submissionId: 'sub-1',
        ),
      );
      expect(progress.interestQuestion, isNull);
      expect(
        progress.recommendation,
        const RecommendationStep(interestId: 'music'),
      );
      expect(progress.demo, isNull);
      expect(progress.isComplete, isFalse);
      expect(progress.completedAt, isNull);
    });
  });
}
