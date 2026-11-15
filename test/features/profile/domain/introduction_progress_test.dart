import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/profile/domain/introduction_progress.dart';

void main() {
  group('IntroductionProgress', () {
    test('starts at the interest chips', () {
      const progress = IntroductionProgress.notStarted();

      expect(progress.hasStarted, isFalse);
      expect(progress.hasAnswer, isFalse);
      expect(progress.nextStage, IntroductionStage.interests);
    });

    test('after the chips comes the choice', () {
      final progress = const IntroductionProgress.notStarted()
          .started(Language.spanish)
          .withInterestsChosen();

      expect(progress.hasStarted, isTrue);
      expect(progress.language, Language.spanish);
      expect(progress.interestsChosen, isTrue);
      expect(progress.choice, isNull);
      expect(progress.nextStage, IntroductionStage.choice);
    });

    test('Try it moves through the opener, the question, the card and the end '
        'screen', () {
      var progress = const IntroductionProgress.notStarted()
          .started(Language.spanish)
          .withInterestsChosen()
          .withChoice(IntroductionChoice.tryIt);
      expect(progress.nextStage, IntroductionStage.friendlyOpener);

      progress = progress.withOpenerShown('opener-how-are-you');
      expect(
        progress.opener,
        const StepAnswer(contentId: 'opener-how-are-you'),
      );
      expect(progress.hasAnsweredOpener, isFalse);
      expect(progress.hasAnswer, isFalse);
      expect(progress.nextStage, IntroductionStage.friendlyOpener);

      progress = progress.withOpenerAnswered();
      expect(progress.hasAnsweredOpener, isTrue);
      expect(progress.hasAnswer, isTrue);
      expect(progress.nextStage, IntroductionStage.interestQuestion);

      progress = progress.withInterestQuestionShown(
        interestId: 'travel',
        questionId: 'travel-question-1',
      );
      expect(progress.interestQuestion?.interestId, 'travel');
      expect(progress.interestQuestion?.contentId, 'travel-question-1');
      expect(progress.nextStage, IntroductionStage.interestQuestion);

      progress = progress.withInterestQuestionAnswered(submissionId: 'sub-2');
      expect(progress.hasAnsweredInterestQuestion, isTrue);
      expect(progress.interestQuestion?.submissionId, 'sub-2');
      expect(progress.nextStage, IntroductionStage.recommendation);

      progress = progress.withRecommendationShown('music');
      expect(progress.recommendation?.interestId, 'music');
      expect(progress.hasDecidedRecommendation, isFalse);
      expect(progress.nextStage, IntroductionStage.recommendation);

      progress = progress.withRecommendationOpened();
      expect(progress.recommendation?.outcome, RecommendationOutcome.opened);
      expect(progress.hasDecidedRecommendation, isTrue);
      expect(progress.hasFinishedChosenPath, isTrue);
      expect(progress.nextStage, IntroductionStage.endScreen);

      progress = progress.completed(DateTime(2026, 11, 15));
      expect(progress.isComplete, isTrue);
      expect(progress.completedAt, DateTime(2026, 11, 15));
      expect(progress.nextStage, IntroductionStage.complete);
    });

    test('Skip on the recommendation card also finishes Try it', () {
      final progress = const IntroductionProgress.notStarted()
          .withInterestsChosen()
          .withChoice(IntroductionChoice.tryIt)
          .withOpenerShown('opener-how-are-you')
          .withOpenerAnswered()
          .withInterestQuestionShown(
            interestId: 'food',
            questionId: 'food-question-1',
          )
          .withInterestQuestionAnswered()
          .withRecommendationShown('food')
          .withRecommendationSkipped();

      expect(progress.recommendation?.outcome, RecommendationOutcome.skipped);
      expect(progress.nextStage, IntroductionStage.endScreen);
    });

    test(
      'Show me moves through the demo to the end screen with no answers',
      () {
        var progress = const IntroductionProgress.notStarted()
            .started(Language.spanish)
            .withInterestsChosen()
            .withChoice(IntroductionChoice.showMe);
        expect(progress.nextStage, IntroductionStage.showMeDemo);

        progress = progress.withDemoShown('sport');
        expect(progress.demo, const DemoStep(interestId: 'sport'));
        expect(progress.hasWatchedDemo, isFalse);
        expect(progress.nextStage, IntroductionStage.showMeDemo);

        progress = progress.withDemoWatched();
        expect(progress.hasWatchedDemo, isTrue);
        expect(progress.hasFinishedChosenPath, isTrue);
        expect(progress.hasAnswer, isFalse);
        expect(progress.answers, isEmpty);
        expect(progress.nextStage, IntroductionStage.endScreen);
      },
    );

    test('the answers list gives the opener first, then the question', () {
      final progress = const IntroductionProgress.notStarted()
          .withInterestsChosen()
          .withChoice(IntroductionChoice.tryIt)
          .withOpenerShown('opener-how-are-you')
          .withOpenerAnswered(submissionId: 'sub-1')
          .withInterestQuestionShown(
            interestId: 'travel',
            questionId: 'travel-question-1',
          )
          .withInterestQuestionAnswered(submissionId: 'sub-2');

      expect(progress.answers.map((answer) => answer.submissionId), [
        'sub-1',
        'sub-2',
      ]);
    });

    test('the History entry id can be added after the answer', () {
      final answered = const IntroductionProgress.notStarted()
          .withOpenerShown('opener-how-are-you')
          .withOpenerAnswered();
      expect(answered.opener?.isAnswered, isTrue);
      expect(answered.opener?.submissionId, isNull);

      final sent = answered.withOpenerAnswered(submissionId: 'sub-1');
      expect(sent.opener?.submissionId, 'sub-1');

      final again = sent.withOpenerAnswered();
      expect(again.opener?.submissionId, 'sub-1');
    });

    test('a step cannot be answered before it has been shown', () {
      const progress = IntroductionProgress.notStarted();

      expect(progress.withOpenerAnswered(), progress);
      expect(progress.withInterestQuestionAnswered(), progress);
      expect(progress.withRecommendationOpened(), progress);
      expect(progress.withRecommendationSkipped(), progress);
      expect(progress.withDemoWatched(), progress);
      expect(progress.hasStarted, isFalse);
    });

    test('showing a step again keeps the one first shown', () {
      final progress = const IntroductionProgress.notStarted()
          .withOpenerShown('opener-how-are-you')
          .withOpenerShown('opener-weekend')
          .withInterestQuestionShown(
            interestId: 'travel',
            questionId: 'travel-question-1',
          )
          .withInterestQuestionShown(
            interestId: 'music',
            questionId: 'music-question-1',
          )
          .withRecommendationShown('food')
          .withRecommendationShown('sport')
          .withDemoShown('history')
          .withDemoShown('art');

      expect(progress.opener?.contentId, 'opener-how-are-you');
      expect(progress.interestQuestion?.contentId, 'travel-question-1');
      expect(progress.recommendation?.interestId, 'food');
      expect(progress.demo?.interestId, 'history');
    });

    test('a completed introduction stays complete whatever else is set', () {
      final progress = const IntroductionProgress.notStarted().completed(
        DateTime(2026, 11, 15),
      );

      expect(progress.nextStage, IntroductionStage.complete);
      expect(progress.hasStarted, isTrue);
    });

    test('the language is recorded once', () {
      final progress = const IntroductionProgress.notStarted()
          .started(Language.spanish)
          .started(Language.portuguese);

      expect(progress.language, Language.spanish);
    });

    test('Stop for now has an answer to show only once one is given', () {
      var progress = const IntroductionProgress.notStarted()
          .withInterestsChosen()
          .withChoice(IntroductionChoice.tryIt)
          .withOpenerShown('opener-how-are-you');
      expect(progress.hasAnswer, isFalse);

      progress = progress.withOpenerAnswered();
      expect(progress.hasAnswer, isTrue);
    });

    test('survives a round trip through JSON', () {
      final progress = const IntroductionProgress.notStarted()
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
          .withRecommendationShown('music')
          .withRecommendationSkipped()
          .withDemoShown('travel')
          .completed(DateTime(2026, 11, 15, 9, 30));

      final restored = IntroductionProgress.fromJson(
        jsonDecode(jsonEncode(progress.toJson())) as Map<String, Object?>,
      );

      expect(restored.language, Language.spanish);
      expect(restored.interestsChosen, isTrue);
      expect(restored.choice, IntroductionChoice.tryIt);
      expect(
        restored.opener,
        const StepAnswer(
          contentId: 'opener-how-are-you',
          isAnswered: true,
          submissionId: 'sub-1',
        ),
      );
      expect(
        restored.interestQuestion,
        const StepAnswer(
          contentId: 'travel-question-1',
          interestId: 'travel',
          isAnswered: true,
        ),
      );
      expect(
        restored.recommendation,
        const RecommendationStep(
          interestId: 'music',
          outcome: RecommendationOutcome.skipped,
        ),
      );
      expect(restored.demo, const DemoStep(interestId: 'travel'));
      expect(restored.isComplete, isTrue);
      expect(restored.completedAt, DateTime(2026, 11, 15, 9, 30));
      expect(restored.nextStage, IntroductionStage.complete);
    });

    test('writes the file keys the store will be read by', () {
      final json = const IntroductionProgress.notStarted().toJson();

      expect(json.keys, [
        'language',
        'interests_chosen',
        'choice',
        'opener',
        'interest_question',
        'recommendation',
        'demo',
        'is_complete',
        'completed_at',
      ]);

      final shown = const IntroductionProgress.notStarted()
          .withChoice(IntroductionChoice.showMe)
          .withOpenerShown('opener-how-are-you')
          .withRecommendationShown('music')
          .withDemoShown('sport')
          .toJson();
      expect(shown['choice'], 'show_me');
      expect(shown['opener'], {
        'content_id': 'opener-how-are-you',
        'interest_id': null,
        'is_answered': false,
        'submission_id': null,
      });
      expect(shown['recommendation'], {
        'interest_id': 'music',
        'outcome': null,
      });
      expect(shown['demo'], {'interest_id': 'sport', 'is_watched': false});
    });

    test('a file written by the 1.2 version still reads', () {
      // The 1.2 version recorded warm-ups and fuller questions (decision A1).
      // Those fields are ignored; what the two versions share is kept.
      final progress = IntroductionProgress.fromJson(const {
        'language': 'spanish',
        'answered_warm_up_ids': ['warm-up-typed', 'warm-up-spoken'],
        'interests_chosen': true,
        'fuller_question_ids': ['travel-1', 'food-2', 'travel-3'],
        'fuller_answers': [
          {'question_id': 'travel-1', 'submission_id': 'sub-1'},
        ],
        'is_complete': false,
        'completed_at': null,
      });

      expect(progress.language, Language.spanish);
      expect(progress.interestsChosen, isTrue);
      expect(progress.choice, isNull);
      expect(progress.opener, isNull);
      expect(progress.interestQuestion, isNull);
      expect(progress.recommendation, isNull);
      expect(progress.demo, isNull);
      expect(progress.isComplete, isFalse);
      expect(progress.hasAnswer, isFalse);
      expect(progress.nextStage, IntroductionStage.choice);
    });

    test('a 1.2 file marked complete stays complete', () {
      final progress = IntroductionProgress.fromJson(const {
        'language': 'spanish',
        'answered_warm_up_ids': ['warm-up-typed'],
        'interests_chosen': true,
        'fuller_question_ids': <String>[],
        'fuller_answers': <Object?>[],
        'is_complete': true,
        'completed_at': '2026-11-12T10:00:00.000',
      });

      expect(progress.isComplete, isTrue);
      expect(progress.completedAt, DateTime(2026, 11, 12, 10));
      expect(progress.nextStage, IntroductionStage.complete);
    });

    test('reads an empty map as not started', () {
      final progress = IntroductionProgress.fromJson(const {});

      expect(progress.hasStarted, isFalse);
      expect(progress.nextStage, IntroductionStage.interests);
    });

    test('ignores malformed fields rather than failing', () {
      final progress = IntroductionProgress.fromJson(const {
        'language': 'spanish',
        'interests_chosen': 'yes',
        'choice': 'watch',
        'opener': 'not a map',
        'interest_question': {'interest_id': 'travel', 'is_answered': true},
        'recommendation': {'interest_id': 'music', 'outcome': 'read'},
        'demo': {'is_watched': true},
        'is_complete': null,
        'completed_at': 'not a date',
      });

      expect(progress.language, Language.spanish);
      expect(progress.interestsChosen, isFalse);
      expect(progress.choice, isNull);
      expect(progress.opener, isNull);
      expect(progress.interestQuestion, isNull, reason: 'no question id');
      expect(
        progress.recommendation,
        const RecommendationStep(interestId: 'music'),
        reason: 'an unknown outcome reads as not yet decided',
      );
      expect(progress.demo, isNull, reason: 'no interest id');
      expect(progress.isComplete, isFalse);
      expect(progress.completedAt, isNull);
      expect(progress.nextStage, IntroductionStage.interests);
    });

    test('the choice and the outcome have fixed file words', () {
      expect(IntroductionChoice.tryIt.toJson(), 'try_it');
      expect(IntroductionChoice.showMe.toJson(), 'show_me');
      expect(IntroductionChoice.fromJson('try_it'), IntroductionChoice.tryIt);
      expect(IntroductionChoice.fromJson(null), isNull);
      expect(RecommendationOutcome.opened.toJson(), 'opened');
      expect(RecommendationOutcome.skipped.toJson(), 'skipped');
      expect(
        RecommendationOutcome.fromJson('skipped'),
        RecommendationOutcome.skipped,
      );
      expect(RecommendationOutcome.fromJson(3), isNull);
    });
  });
}
