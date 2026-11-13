import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/introduction/application/introduction_controller.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_content.dart';
import 'package:spanish_correction_app/features/introduction/domain/introduction_step.dart';
import 'package:spanish_correction_app/features/profile/application/profile_repository.dart';
import 'package:spanish_correction_app/features/profile/domain/introduction_progress.dart';
import 'package:spanish_correction_app/features/profile/domain/learner_profile.dart';

/// Keeps the profile in memory, the way the file store keeps it on the phone.
class InMemoryProfileRepository implements ProfileRepository {
  InMemoryProfileRepository([LearnerProfile? profile])
    : _profile = profile ?? LearnerProfile.empty();

  LearnerProfile _profile;
  int saveCount = 0;

  LearnerProfile get profile => _profile;

  @override
  Future<LearnerProfile> getProfile() async => _profile;

  @override
  Future<void> saveProfile(LearnerProfile profile) async {
    saveCount++;
    _profile = profile;
  }

  @override
  Future<LearnerProfile> updateProfile(
    LearnerProfile Function(LearnerProfile profile) change,
  ) async {
    await saveProfile(change(_profile));
    return _profile;
  }

  @override
  Future<void> clear() async {
    await saveProfile(LearnerProfile.empty());
  }
}

void main() {
  final fixedNow = DateTime(2026, 11, 13, 9, 30);

  late InMemoryProfileRepository repository;
  late IntroductionController controller;

  Future<IntroductionController> newController({
    Language language = Language.spanish,
  }) async {
    final created = IntroductionController(
      profileRepository: repository,
      language: language,
      now: () => fixedNow,
    );
    addTearDown(created.dispose);
    await created.load();
    return created;
  }

  /// Answers both warm-ups and passes the chips with [interestIds] tapped.
  Future<void> reachFullerQuestions(
    IntroductionController controller, {
    List<String> interestIds = const ['travel'],
  }) async {
    await controller.answerWarmUp('Bien, gracias.');
    await controller.answerWarmUp('Soy de Londres.');
    for (final id in interestIds) {
      await controller.toggleInterest(id);
    }
    await controller.continueFromInterests();
  }

  setUp(() async {
    repository = InMemoryProfileRepository();
    controller = await newController();
  });

  group('whether the introduction runs', () {
    test('it runs for Spanish and not for Portuguese in slice 1', () {
      expect(IntroductionController.canRunFor(Language.spanish), isTrue);
      expect(IntroductionController.canRunFor(Language.portuguese), isFalse);
    });

    test('a new install needs it; a completed one does not', () {
      final fresh = LearnerProfile.empty();
      final done = fresh.withIntroduction(
        fresh.introduction.started(Language.spanish).completed(fixedNow),
      );

      expect(IntroductionController.isNeeded(fresh, Language.spanish), isTrue);
      expect(IntroductionController.isNeeded(done, Language.spanish), isFalse);
      expect(
        IntroductionController.isNeeded(fresh, Language.portuguese),
        isFalse,
      );
    });

    test('a completed profile is skipped after a language switch too', () {
      final fresh = LearnerProfile.empty();
      final done = fresh.withIntroduction(
        fresh.introduction.started(Language.portuguese).completed(fixedNow),
      );

      expect(IntroductionController.isNeeded(done, Language.spanish), isFalse);
    });
  });

  group('loading', () {
    test('records the language it started in and saves it', () async {
      expect(controller.isLoaded, isTrue);
      expect(repository.profile.introduction.language, Language.spanish);
      expect(repository.saveCount, 1);
    });

    test('does not record the language again on a later load', () async {
      final again = await newController();

      expect(again.step, controller.step);
      expect(repository.saveCount, 1);
    });

    test('gives no step once the introduction is complete', () async {
      await repository.saveProfile(
        repository.profile.withIntroduction(
          repository.profile.introduction.completed(fixedNow),
        ),
      );
      final again = await newController();

      expect(again.isLoaded, isTrue);
      expect(again.step, isNull);
    });
  });

  group('warm-ups', () {
    test('starts on the first warm-up, which is typed', () {
      final step = controller.step!;
      final warmUp = IntroductionContent.warmUpQuestions.first;

      expect(step.kind, IntroductionStepKind.warmUp);
      expect(step.id, warmUp.id);
      expect(step.text, warmUp.text);
      expect(step.hint, warmUp.hint);
      expect(step.answerMode, AnswerMode.typed);
      expect(step.number, 1);
      expect(step.count, 2);
      expect(step.showsTextBox, isTrue);
      expect(step.showsMicrophone, isFalse);
    });

    test('a blank answer is refused and nothing moves', () async {
      final before = controller.step;

      expect(await controller.answerWarmUp('   '), isFalse);
      expect(controller.step, before);
      expect(repository.profile.introduction.answeredWarmUpIds, isEmpty);
    });

    test('answering the first warm-up shows the spoken one', () async {
      expect(await controller.answerWarmUp('Bien, gracias.'), isTrue);

      final step = controller.step!;
      expect(step.kind, IntroductionStepKind.warmUp);
      expect(step.id, IntroductionContent.warmUpQuestions[1].id);
      expect(step.answerMode, AnswerMode.spoken);
      expect(step.number, 2);
      expect(step.showsMicrophone, isTrue);
      expect(repository.profile.introduction.answeredWarmUpIds, [
        IntroductionContent.warmUpQuestions.first.id,
      ]);
    });

    test('the warm-up answers themselves are not kept', () async {
      await controller.answerWarmUp('Bien, gracias.');

      final json = repository.profile.toJson().toString();
      expect(json, isNot(contains('Bien, gracias')));
    });

    test('after both warm-ups the chips are shown', () async {
      await controller.answerWarmUp('Bien, gracias.');
      await controller.answerWarmUp('Soy de Londres.');

      final step = controller.step!;
      expect(step.kind, IntroductionStepKind.interests);
      expect(step.text, IntroductionContent.interestsQuestion);
      expect(step.hint, IntroductionContent.interestsHint);
      expect(step.answerMode, AnswerMode.chips);
      expect(step.showsTextBox, isFalse);
    });
  });

  group('interests', () {
    setUp(() async {
      await controller.answerWarmUp('Bien, gracias.');
      await controller.answerWarmUp('Soy de Londres.');
    });

    test('the chips are the content interests in order', () {
      expect(controller.interests, IntroductionContent.interests);
    });

    test('tapping a chip saves it at once; tapping again removes it', () async {
      await controller.toggleInterest('music');
      await controller.toggleInterest('travel');

      expect(controller.chosenInterestIds, ['music', 'travel']);
      expect(controller.isInterestChosen('music'), isTrue);
      expect(repository.profile.interestIds, ['music', 'travel']);

      await controller.toggleInterest('music');

      expect(controller.chosenInterestIds, ['travel']);
      expect(repository.profile.interestIds, ['travel']);
    });

    test('continuing draws three questions from the chosen chips', () async {
      await controller.toggleInterest('travel');
      await controller.toggleInterest('food');
      await controller.toggleInterest('music');
      await controller.continueFromInterests();

      final progress = repository.profile.introduction;
      expect(progress.interestsChosen, isTrue);
      expect(progress.fullerQuestionIds.length, 3);
      expect(controller.fullerQuestions.map((q) => q.interestId), [
        'travel',
        'food',
        'music',
      ]);

      final step = controller.step!;
      expect(step.kind, IntroductionStepKind.fullerQuestion);
      expect(step.id, progress.fullerQuestionIds.first);
      expect(step.text, controller.fullerQuestions.first.text);
      expect(step.answerMode, AnswerMode.typedOrSpoken);
      expect(step.number, 1);
      expect(step.count, 3);
    });

    test('continuing with no chip tapped still draws questions', () async {
      await controller.continueFromInterests();

      expect(repository.profile.interestIds, isEmpty);
      expect(repository.profile.introduction.interestsChosen, isTrue);
      expect(controller.fullerQuestions.length, 3);
      expect(controller.step!.kind, IntroductionStepKind.fullerQuestion);
    });

    test('continuing is ignored on any other step', () async {
      final fresh = InMemoryProfileRepository();
      repository = fresh;
      final atWarmUp = await newController();

      await atWarmUp.continueFromInterests();

      expect(atWarmUp.step!.kind, IntroductionStepKind.warmUp);
      expect(fresh.profile.introduction.interestsChosen, isFalse);
    });
  });

  group('fuller questions', () {
    setUp(() => reachFullerQuestions(controller));

    test('a blank answer is refused', () async {
      expect(await controller.answerFullerQuestion(''), isFalse);
      expect(controller.hasFullerAnswer, isFalse);
    });

    test('each answer is recorded and the next question shown', () async {
      final questions = controller.fullerQuestions;

      expect(await controller.answerFullerQuestion('Fui a Lisboa.'), isTrue);

      expect(controller.hasFullerAnswer, isTrue);
      expect(repository.profile.introduction.fullerAnswers, [
        FullerAnswer(questionId: questions[0].id),
      ]);
      expect(controller.step!.id, questions[1].id);
      expect(controller.step!.number, 2);
    });

    test('the fuller answers themselves are not kept yet', () async {
      await controller.answerFullerQuestion('Fui a Lisboa con mi hermana.');

      final json = repository.profile.toJson().toString();
      expect(json, isNot(contains('Lisboa')));
    });

    test('after the last answer the end screen is shown', () async {
      await controller.answerFullerQuestion('Uno.');
      await controller.answerFullerQuestion('Dos.');
      await controller.answerFullerQuestion('Tres.');

      final step = controller.step!;
      expect(step.kind, IntroductionStepKind.endScreen);
      expect(step.text, IntroductionContent.endScreenLine);
      expect(step.answerMode, AnswerMode.none);
      expect(repository.profile.introduction.isComplete, isFalse);
    });

    test(
      'a drawn id that no longer matches a question is passed over',
      () async {
        final current = repository.profile;
        await repository.saveProfile(
          current.withIntroduction(
            current.introduction.withInterestsChosen(
              fullerQuestionIds: ['no-such-question', 'music-2'],
            ),
          ),
        );
        final again = await newController();

        expect(again.fullerQuestions.map((q) => q.id), ['music-2']);
        expect(again.step!.id, 'music-2');
        expect(again.step!.count, 1);

        await again.answerFullerQuestion('Fue en 2010.');

        expect(again.step!.kind, IntroductionStepKind.endScreen);
      },
    );
  });

  group('the end screen', () {
    test(
      'finishing marks the introduction complete and gives no step',
      () async {
        await reachFullerQuestions(controller);
        await controller.answerFullerQuestion('Uno.');
        await controller.answerFullerQuestion('Dos.');
        await controller.answerFullerQuestion('Tres.');

        await controller.finish();

        final progress = repository.profile.introduction;
        expect(progress.isComplete, isTrue);
        expect(progress.completedAt, fixedNow);
        expect(controller.step, isNull);
        expect(
          IntroductionController.isNeeded(repository.profile, Language.spanish),
          isFalse,
        );
      },
    );
  });

  group('stop for now', () {
    test(
      'with no fuller answer it goes to the app and keeps progress',
      () async {
        await controller.answerWarmUp('Bien, gracias.');

        expect(controller.stopForNow(), StopOutcome.app);
        expect(repository.profile.introduction.isComplete, isFalse);
        expect(repository.profile.introduction.answeredWarmUpIds.length, 1);
      },
    );

    test('a new controller resumes where it stopped', () async {
      await controller.answerWarmUp('Bien, gracias.');
      await controller.answerWarmUp('Soy de Londres.');
      await controller.toggleInterest('sport');
      controller.stopForNow();

      final resumed = await newController();

      expect(resumed.step!.kind, IntroductionStepKind.interests);
      expect(resumed.chosenInterestIds, ['sport']);
    });

    test('a resumed introduction asks the same drawn questions', () async {
      await reachFullerQuestions(controller, interestIds: ['history', 'art']);
      final drawn = controller.fullerQuestions.map((q) => q.id).toList();
      await controller.answerFullerQuestion('Uno.');

      final resumed = await newController();

      expect(resumed.fullerQuestions.map((q) => q.id), drawn);
      expect(resumed.step!.id, drawn[1]);
      expect(resumed.step!.number, 2);
    });

    test('with a fuller answer it goes to the end screen first', () async {
      await reachFullerQuestions(controller);
      await controller.answerFullerQuestion('Uno.');

      expect(controller.stopForNow(), StopOutcome.endScreen);
      expect(controller.step!.kind, IntroductionStepKind.endScreen);
      expect(repository.profile.introduction.isComplete, isFalse);

      await controller.finish();

      expect(repository.profile.introduction.isComplete, isTrue);
      expect(controller.step, isNull);
    });

    test(
      'stopping at the end screen without finishing resumes the questions',
      () async {
        await reachFullerQuestions(controller);
        await controller.answerFullerQuestion('Uno.');
        controller.stopForNow();

        final resumed = await newController();

        expect(resumed.step!.kind, IntroductionStepKind.fullerQuestion);
        expect(resumed.step!.number, 2);
      },
    );
  });
}
