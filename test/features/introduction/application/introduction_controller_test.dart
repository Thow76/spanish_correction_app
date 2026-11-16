import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/introduction/application/introduction_controller.dart';
import 'package:spanish_correction_app/features/introduction/application/introduction_step.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_content.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_step_kind.dart';
import 'package:spanish_correction_app/features/profile/domain/introduction_progress.dart';

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
      await controller.answerOpener();

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
      await controller.answerOpener();
      await controller.answerInterestQuestion();

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
      await controller.answerOpener();
      await controller.answerInterestQuestion();
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
      await controller.answerOpener();
      await controller.answerInterestQuestion();
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

        await controller.finishDemo();
        expect(controller.stage, IntroductionStage.friendlyOpener);

        await controller.answerOpener();
        await controller.answerInterestQuestion();
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
      await controller.answerOpener();

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
      await first.answerOpener();
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
      await first.answerOpener();
      await first.answerInterestQuestion();
      await first.openRecommendation();

      final second = await loaded();
      expect(second.stage, IntroductionStage.endScreen);
    });
  });

  group('finishing', () {
    test('Continue on the end screen marks it complete', () async {
      final controller = await loaded();
      controller.toggleInterest('music');
      await controller.confirmInterests();
      await controller.choose(IntroductionChoice.showMe);
      await controller.finishDemo();
      await controller.answerOpener();
      await controller.answerInterestQuestion();
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
}
