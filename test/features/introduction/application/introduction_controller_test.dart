import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/introduction/application/introduction_controller.dart';
import 'package:spanish_correction_app/features/introduction/application/introduction_step.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_content.dart';
import 'package:spanish_correction_app/features/introduction/content/recommendation_item.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_step_kind.dart';
import 'package:spanish_correction_app/features/profile/domain/introduction_progress.dart';

import '../fake_introduction_feedback.dart';
import '../fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  IntroductionController newController() => IntroductionController(
    repository: repository,
    language: Language.spanish,
    clock: () => DateTime.utc(2026, 11, 16, 9),
  );

  Future<IntroductionController> loaded() async {
    final controller = newController();
    await controller.load();
    return controller;
  }

  setUp(() => repository = FakeProfileRepository());

  group('starting', () {
    test('a fresh profile starts on the chips, in Spanish', () async {
      final controller = await loaded();

      expect(controller.stage, IntroductionStage.interests);
      expect(controller.currentStep.mode, IntroductionAnswerMode.chips);
      expect(
        controller.currentStep.questionText,
        IntroductionContent.interestsQuestion,
      );
      expect(repository.saved?.introduction.language, Language.spanish);
    });

    test('chips already on the profile are shown as tapped', () async {
      repository.stored = repository.stored.withInterestIds(['music']);
      final controller = await loaded();

      expect(controller.isSelected('music'), isTrue);
    });
  });

  group('the chips', () {
    test('one to five chips can be tapped; a sixth is refused', () async {
      final controller = await loaded();
      expect(controller.canConfirmInterests, isFalse);

      final ids = IntroductionContent.interests.map((i) => i.id).toList();
      for (final id in ids.take(5)) {
        expect(controller.toggleInterest(id), isTrue);
      }
      expect(controller.canConfirmInterests, isTrue);
      expect(controller.toggleInterest(ids[5]), isFalse);
      expect(controller.selectedInterestIds, ids.take(5).toList());

      controller.toggleInterest(ids[0]);
      expect(controller.isSelected(ids[0]), isFalse);
    });

    test('Continue saves the chips and moves to the choice', () async {
      final controller = await loaded();
      controller
        ..toggleInterest('music')
        ..toggleInterest('travel');
      await controller.confirmInterests();

      expect(controller.stage, IntroductionStage.choice);
      expect(repository.saved?.interestIds, ['music', 'travel']);
      expect(repository.saved?.introduction.interestsChosen, isTrue);
    });
  });

  group('Try it', () {
    Future<IntroductionController> atTryIt() async {
      final controller = await loaded();
      controller
        ..toggleInterest('music')
        ..toggleInterest('travel');
      await controller.confirmInterests();
      await controller.choose(IntroductionChoice.tryIt);
      return controller;
    }

    test('the opener comes first, typed, with its label', () async {
      final controller = await atTryIt();

      expect(controller.stage, IntroductionStage.friendlyOpener);
      final step = controller.currentStep;
      expect(step.mode, IntroductionAnswerMode.type);
      expect(step.label, IntroductionStepKind.friendlyOpener.label);
      expect(step.questionText, '¿Qué tal estás hoy?');
      expect(step.hint, IntroductionContent.typingHint);
      expect(repository.saved?.introduction.opener?.contentId, isNotEmpty);
    });

    test('then the question about the first chip, spoken', () async {
      final controller = await atTryIt();
      await controller.answerOpener('Estoy bien.');

      expect(controller.stage, IntroductionStage.interestQuestion);
      final step = controller.currentStep;
      expect(step.mode, IntroductionAnswerMode.microphone);
      expect(step.label, IntroductionStepKind.somethingYoureInto.label);
      expect(step.hint, IntroductionContent.speakingHint);
      expect(controller.currentQuestionInterest?.id, 'music');
      expect(
        step.questionText,
        IntroductionContent.interestQuestionsForInterest(
          'music',
          Language.spanish,
        ).first.text,
      );
    });

    test('then the recommendation card for the second chip', () async {
      final controller = await atTryIt();
      await controller.answerOpener('Estoy bien.');
      await controller.answerInterestQuestion('Me gusta el jazz.');

      expect(controller.stage, IntroductionStage.recommendation);
      expect(
        controller.currentStep.mode,
        IntroductionAnswerMode.recommendationCard,
      );
      expect(controller.currentRecommendationInterest?.id, 'travel');
      expect(controller.currentRecommendation?.interestId, 'travel');
    });

    test('Open now is saved before the link opens, then the end', () async {
      final controller = await atTryIt();
      await controller.answerOpener('Estoy bien.');
      await controller.answerInterestQuestion('Me gusta el jazz.');
      final item = await controller.openRecommendation();

      expect(item?.interestId, 'travel');
      expect(
        repository.saved?.introduction.recommendation?.outcome,
        RecommendationOutcome.opened,
      );
      expect(controller.stage, IntroductionStage.endScreen);
      expect(controller.endScreenLine, IntroductionContent.endScreenLine);
    });

    test('Skip also leads to the end screen', () async {
      final controller = await atTryIt();
      await controller.answerOpener('Estoy bien.');
      await controller.answerInterestQuestion('Me gusta el jazz.');
      await controller.skipRecommendation();

      expect(
        repository.saved?.introduction.recommendation?.outcome,
        RecommendationOutcome.skipped,
      );
      expect(controller.stage, IntroductionStage.endScreen);
    });
  });

  group('Show me how it works', () {
    test(
      'plays the walk-through on the first chip, then the Try it steps',
      () async {
        final controller = await loaded();
        controller.toggleInterest('sport');
        await controller.confirmInterests();
        await controller.choose(IntroductionChoice.showMe);

        expect(controller.stage, IntroductionStage.showMeDemo);
        expect(controller.currentStep.mode, IntroductionAnswerMode.demo);
        expect(controller.currentDemo?.interestId, 'sport');
        expect(
          controller.currentOpenerForWalkthrough?.text,
          '¿Qué tal estás hoy?',
        );
        expect(controller.walkthroughRecommendation?.interestId, 'sport');
        expect(controller.walkthroughReadExample?.interestId, 'sport');
        expect(
          controller.walkthroughReadExample?.type,
          RecommendationType.article,
        );

        await controller.finishDemo();
        expect(controller.stage, IntroductionStage.friendlyOpener);

        await controller.answerOpener('Estoy bien.');
        await controller.answerInterestQuestion('Me gusta el jazz.');
        await controller.skipRecommendation();
        expect(controller.stage, IntroductionStage.endScreen);
        expect(controller.endScreenLine, IntroductionContent.endScreenLine);
      },
    );
  });

  group('Stop for now', () {
    test('with no answer, goes to the app and keeps tapped chips', () async {
      final controller = await loaded();
      controller.toggleInterest('history');

      expect(await controller.stopForNow(), StopDestination.app);
      expect(repository.saved?.interestIds, ['history']);
      expect(repository.saved?.introduction.isComplete, isFalse);
    });

    test('with an answer, goes to the end screen', () async {
      final controller = await loaded();
      controller.toggleInterest('music');
      await controller.confirmInterests();
      await controller.choose(IntroductionChoice.tryIt);
      await controller.answerOpener('Estoy bien.');

      expect(await controller.stopForNow(), StopDestination.endScreen);
      expect(controller.stage, IntroductionStage.endScreen);
      expect(controller.currentStep.mode, IntroductionAnswerMode.end);
    });

    test('after Show me, there is no answer, so it goes to the app', () async {
      final controller = await loaded();
      controller.toggleInterest('music');
      await controller.confirmInterests();
      await controller.choose(IntroductionChoice.showMe);

      expect(await controller.stopForNow(), StopDestination.app);
    });
  });

  group('resuming', () {
    test('a new controller carries on at the same step and question', () async {
      final first = await loaded();
      first
        ..toggleInterest('food')
        ..toggleInterest('books');
      await first.confirmInterests();
      await first.choose(IntroductionChoice.tryIt);
      await first.answerOpener('Estoy bien.');
      final questionId = first.currentInterestQuestion?.id;
      await first.stopForNow();

      final second = await loaded();
      expect(second.stage, IntroductionStage.interestQuestion);
      expect(second.currentInterestQuestion?.id, questionId);
      expect(second.currentQuestionInterest?.id, 'food');
    });

    test('after Open now, a relaunch shows the end screen', () async {
      final first = await loaded();
      first.toggleInterest('music');
      await first.confirmInterests();
      await first.choose(IntroductionChoice.tryIt);
      await first.answerOpener('Estoy bien.');
      await first.answerInterestQuestion('Me gusta el jazz.');
      await first.openRecommendation();

      final second = await loaded();
      expect(second.stage, IntroductionStage.endScreen);
    });
  });

  group('finishing', () {
    test('Not now on the end screen marks it complete', () async {
      final controller = await loaded();
      controller.toggleInterest('music');
      await controller.confirmInterests();
      await controller.choose(IntroductionChoice.showMe);
      await controller.finishDemo();
      await controller.answerOpener('Estoy bien.');
      await controller.answerInterestQuestion('Me gusta el jazz.');
      await controller.skipRecommendation();
      await controller.finish();

      expect(repository.saved?.introduction.isComplete, isTrue);
      expect(
        repository.saved?.introduction.completedAt,
        DateTime.utc(2026, 11, 16, 9),
      );
      expect(controller.stage, IntroductionStage.complete);
    });
  });

  group('feedback on the two answers (task 1.4)', () {
    late FakeIntroductionFeedback feedback;

    setUp(() => feedback = FakeIntroductionFeedback());

    IntroductionController withFeedback() => IntroductionController(
      repository: repository,
      language: Language.spanish,
      feedback: feedback,
      clock: () => DateTime.utc(2026, 11, 16, 9),
    );

    Future<IntroductionController> atEndScreen(
      IntroductionController controller,
    ) async {
      await controller.load();
      controller
        ..toggleInterest('music')
        ..toggleInterest('travel');
      await controller.confirmInterests();
      await controller.choose(IntroductionChoice.tryIt);
      await controller.answerOpener('Estoy bien, gracias.');
      await controller.answerInterestQuestion('Me gusta mucho el jazz.');
      await controller.skipRecommendation();
      return controller;
    }

    test('both answers are sent and their History ids recorded', () async {
      final controller = await atEndScreen(withFeedback());
      final suggestions = await controller.suggestionsToShow();

      expect(feedback.sent, [
        'Estoy bien, gracias.',
        'Me gusta mucho el jazz.',
      ]);
      expect(suggestions.map((s) => s.response.originalText), [
        'Estoy bien, gracias.',
        'Me gusta mucho el jazz.',
      ]);
      final saved = repository.saved!.introduction;
      expect(saved.opener?.submissionId, suggestions[0].id);
      expect(saved.interestQuestion?.submissionId, suggestions[1].id);
    });

    test('a failed send is tried once more from See suggestions', () async {
      feedback.failuresLeft = 1;
      final controller = await atEndScreen(withFeedback());
      final suggestions = await controller.suggestionsToShow();

      expect(feedback.sent, [
        'Estoy bien, gracias.',
        'Me gusta mucho el jazz.',
        'Estoy bien, gracias.',
      ]);
      expect(suggestions, hasLength(2));
      expect(suggestions.first.response.originalText, 'Estoy bien, gracias.');
    });

    test('when nothing could be sent, there is nothing to show', () async {
      feedback.failuresLeft = 10;
      final controller = await atEndScreen(withFeedback());

      expect(await controller.suggestionsToShow(), isEmpty);
    });

    test('after a relaunch, the answers are found in History by id', () async {
      final first = await atEndScreen(withFeedback());
      await first.suggestionsToShow();

      final second = withFeedback();
      await second.load();
      expect(second.stage, IntroductionStage.endScreen);
      final suggestions = await second.suggestionsToShow();
      expect(suggestions, hasLength(2));
      expect(feedback.sent, hasLength(2));
    });

    test('Save on a point goes through the save path', () async {
      final controller = await atEndScreen(withFeedback());
      final suggestions = await controller.suggestionsToShow();
      final point = suggestions.first.response.corrections.single;

      await controller.savePoint(point, suggestions.first);

      expect(feedback.saved.single.$1, point);
      expect(feedback.saved.single.$2.id, suggestions.first.id);
    });

    test('with no feedback connected, nothing is sent', () async {
      final controller = await atEndScreen(newController());

      expect(await controller.suggestionsToShow(), isEmpty);
      expect(feedback.sent, isEmpty);
    });
  });
}
