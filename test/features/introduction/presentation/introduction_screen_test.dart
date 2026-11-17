import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/introduction/application/introduction_feedback.dart';
import 'package:spanish_correction_app/features/introduction/application/link_opener.dart';
import 'package:spanish_correction_app/features/introduction/application/voice_recorder.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_content.dart';
import 'package:spanish_correction_app/features/introduction/presentation/introduction_screen.dart';
import 'package:spanish_correction_app/features/profile/domain/introduction_progress.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';

import '../fake_introduction_feedback.dart';
import '../fake_profile_repository.dart';

class _FakeRecorder implements VoiceRecorder {
  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<void> start() async {}

  @override
  Future<String?> stop() async => '/tmp/fake.wav';

  @override
  Future<void> dispose() async {}
}

class _FakeTranscription implements TranscriptionService {
  @override
  Future<String> transcribeAudio(String audioPath, Language language) async =>
      'Me gusta mucho el jazz.';
}

class _FakeLinkOpener implements LinkOpener {
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

void main() {
  late FakeProfileRepository repository;
  late _FakeLinkOpener linkOpener;
  bool? doneWith;

  Future<void> pumpIntroduction(
    WidgetTester tester, {
    IntroductionFeedback? feedback,
  }) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: IntroductionScreen(
          language: Language.spanish,
          profileRepository: repository,
          transcriptionService: _FakeTranscription(),
          recorderFactory: _FakeRecorder.new,
          linkOpener: linkOpener,
          onDone: (completed) => doneWith = completed,
          feedback: feedback,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  String spanishLabel(String id) =>
      IntroductionContent.interestById(id)!.spanish;

  setUp(() {
    repository = FakeProfileRepository();
    linkOpener = _FakeLinkOpener();
    doneWith = null;
  });

  testWidgets('the chips come first, in Spanish, with Stop for now', (
    tester,
  ) async {
    await pumpIntroduction(tester);

    expect(find.text(IntroductionContent.interestsQuestion), findsOneWidget);
    expect(find.text('YOUR INTERESTS'), findsOneWidget);
    expect(find.text('Stop for now'), findsOneWidget);
    for (final interest in IntroductionContent.interests) {
      expect(find.text(interest.spanish), findsOneWidget);
    }
  });

  testWidgets('Start now runs the three labelled steps to the end screen', (
    tester,
  ) async {
    await pumpIntroduction(tester);

    await tapAndSettle(tester, find.text(spanishLabel('music')));
    await tapAndSettle(tester, find.text(spanishLabel('travel')));
    await tapAndSettle(tester, find.text('Continue'));

    expect(find.text(IntroductionContent.choiceQuestion), findsOneWidget);
    await tapAndSettle(tester, find.text('Start now'));

    // Friendly opener, typed.
    expect(find.text('CHAT ABOUT YOUR DAY'), findsOneWidget);
    expect(find.text('¿Qué tal estás hoy?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Estoy bien, gracias.');
    await tester.pump();
    await tapAndSettle(tester, find.text('Send'));

    // Something you're into, spoken.
    expect(find.text('CHAT ABOUT YOUR INTERESTS'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.mic_none));
    await tester.tap(find.byIcon(Icons.mic_none));
    // The recording counts down once a second, so pump rather than settle.
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Tap to stop'), findsOneWidget);
    await tapAndSettle(tester, find.byIcon(Icons.stop));
    expect(find.text('Me gusta mucho el jazz.'), findsOneWidget);
    await tapAndSettle(tester, find.text('Send'));

    // A recommendation, for the second chip.
    expect(find.text('CHAT ABOUT A RECOMMENDATION'), findsOneWidget);
    expect(find.byKey(const ValueKey('recommendation-card')), findsOneWidget);
    await tapAndSettle(tester, find.text('Open now'));
    final travelItem = IntroductionContent.recommendationsForInterest(
      'travel',
      Language.spanish,
    ).first;
    expect(linkOpener.opened, [Uri.parse(travelItem.url)]);

    // The end screen, with no Stop for now.
    expect(find.text(IntroductionContent.endScreenLine), findsOneWidget);
    expect(find.text('Stop for now'), findsNothing);
    await tapAndSettle(tester, find.text('Not now'));

    expect(doneWith, isTrue);
    expect(repository.stored.introduction.isComplete, isTrue);
    expect(repository.stored.interestIds, ['music', 'travel']);
  });

  testWidgets(
    'Show me how it works walks through each kind of chat, then your turn',
    (tester) async {
      await pumpIntroduction(tester);

      await tapAndSettle(tester, find.text(spanishLabel('sport')));
      await tapAndSettle(tester, find.text('Continue'));
      await tapAndSettle(tester, find.text('Show me how it works'));

      // Part 1: the friendly opener and a sample typed answer.
      expect(find.text('CHAT ABOUT YOUR DAY'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('walkthrough-progress')),
        findsOneWidget,
      );
      expect(
        find.text(IntroductionContent.walkthroughOpenerAnswer),
        findsOneWidget,
      );
      await tapAndSettle(tester, find.text('Next'));

      // Part 2: the question about the chip and the sample answer.
      final demo = IntroductionContent.demoForInterest(
        'sport',
        Language.spanish,
      )!;
      expect(find.text('CHAT ABOUT YOUR INTERESTS'), findsOneWidget);
      expect(find.text(demo.question), findsOneWidget);
      expect(find.text(demo.sampleAnswer), findsOneWidget);
      await tapAndSettle(tester, find.text('Next'));

      // Part 3: three examples under Read, Watch and Listen, none opened.
      expect(find.text('CHAT ABOUT A RECOMMENDATION'), findsOneWidget);
      expect(
        find.text(IntroductionContent.walkthroughReadTitle),
        findsOneWidget,
      );
      expect(
        find.text(IntroductionContent.walkthroughWatchTitle),
        findsOneWidget,
      );
      expect(
        find.text(IntroductionContent.walkthroughListenTitle),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('walkthrough-example-walkthrough-watch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('walkthrough-example-walkthrough-listen')),
        findsOneWidget,
      );
      expect(find.text('Open now'), findsNothing);
      await tapAndSettle(tester, find.text('Next'));

      // Part 4: tap a highlighted phrase, see the suggestion, save it.
      expect(find.text('FEEDBACK'), findsOneWidget);
      final yourTurn = find.widgetWithText(
        FilledButton,
        IntroductionContent.walkthroughYourTurnButton,
      );
      expect(tester.widget<FilledButton>(yourTurn).onPressed, isNull);

      final answer = find.byKey(
        const ValueKey('walkthrough-highlighted-answer'),
      );
      final firstPoint = demo.points.first;
      final rich = tester.widget<RichText>(
        find.descendant(of: answer, matching: find.byType(RichText)),
      );
      var tapped = false;
      rich.text.visitChildren((span) {
        if (!tapped &&
            span is TextSpan &&
            span.text == firstPoint.originalPhrase &&
            span.recognizer is TapGestureRecognizer) {
          (span.recognizer! as TapGestureRecognizer).onTap!();
          tapped = true;
        }
        return true;
      });
      expect(tapped, isTrue);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('walkthrough-point-card')),
        findsOneWidget,
      );
      expect(find.text(firstPoint.correctedPhrase), findsOneWidget);
      expect(find.text(firstPoint.shortExplanation), findsOneWidget);
      await tapAndSettle(tester, find.text('Save'));
      expect(find.text('Saved'), findsOneWidget);

      await tapAndSettle(tester, yourTurn);

      // Then the learner's own turn.
      expect(repository.stored.introduction.hasWatchedDemo, isTrue);
      expect(find.text('CHAT ABOUT YOUR DAY'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(linkOpener.opened, isEmpty);
    },
  );

  testWidgets('Stop for now with no answer goes to the app', (tester) async {
    await pumpIntroduction(tester);
    await tapAndSettle(tester, find.text(spanishLabel('history')));
    await tapAndSettle(tester, find.text('Stop for now'));

    expect(doneWith, isFalse);
    expect(repository.stored.introduction.isComplete, isFalse);
    expect(repository.stored.interestIds, ['history']);
  });

  testWidgets('a stopped introduction resumes at the same step', (
    tester,
  ) async {
    repository.stored = repository.stored
        .withInterestIds(['music'])
        .withIntroduction(
          const IntroductionProgress.notStarted()
              .started(Language.spanish)
              .withInterestsChosen()
              .withChoice(IntroductionChoice.tryIt)
              .withOpenerShown('opener-how-are-you')
              .withOpenerAnswered(),
        );
    await pumpIntroduction(tester);

    expect(find.text('CHAT ABOUT YOUR INTERESTS'), findsOneWidget);
    expect(find.text(spanishLabel('music')), findsOneWidget);
  });

  testWidgets('Stop for now after an answer goes to the end screen', (
    tester,
  ) async {
    repository.stored = repository.stored
        .withInterestIds(['music'])
        .withIntroduction(
          const IntroductionProgress.notStarted()
              .started(Language.spanish)
              .withInterestsChosen()
              .withChoice(IntroductionChoice.tryIt)
              .withOpenerShown('opener-how-are-you')
              .withOpenerAnswered(),
        );
    await pumpIntroduction(tester);
    await tapAndSettle(tester, find.text('Stop for now'));

    expect(doneWith, isNull);
    expect(find.text(IntroductionContent.endScreenLine), findsOneWidget);
  });

  group('the end screen (task 1.4)', () {
    late FakeIntroductionFeedback feedback;

    setUp(() => feedback = FakeIntroductionFeedback());

    /// Picks one chip, answers both questions and skips the card.
    Future<void> answerBoth(WidgetTester tester) async {
      await pumpIntroduction(tester, feedback: feedback);
      await tapAndSettle(tester, find.text(spanishLabel('music')));
      await tapAndSettle(tester, find.text('Continue'));
      await tapAndSettle(tester, find.text('Start now'));
      await tester.enterText(find.byType(TextField), 'Estoy bien, gracias.');
      await tester.pump();
      await tapAndSettle(tester, find.text('Send'));
      await tester.ensureVisible(find.byIcon(Icons.mic_none));
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tapAndSettle(tester, find.byIcon(Icons.stop));
      await tapAndSettle(tester, find.text('Send'));
      await tapAndSettle(tester, find.text('Skip'));
    }

    void tapFirstHighlight(WidgetTester tester) {
      var tapped = false;
      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        rich.text.visitChildren((span) {
          if (!tapped &&
              span is TextSpan &&
              span.recognizer is TapGestureRecognizer) {
            (span.recognizer! as TapGestureRecognizer).onTap!();
            tapped = true;
          }
          return !tapped;
        });
        if (tapped) {
          break;
        }
      }
      expect(tapped, isTrue);
    }

    testWidgets('both answers are sent as soon as they are given', (
      tester,
    ) async {
      await answerBoth(tester);

      expect(feedback.sent, [
        'Estoy bien, gracias.',
        'Me gusta mucho el jazz.',
      ]);
      expect(find.text('See suggestions'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('Stop for now'), findsNothing);
    });

    testWidgets(
      'See suggestions walks through each answer, with Save on each point',
      (tester) async {
        await answerBoth(tester);
        await tapAndSettle(tester, find.text('See suggestions'));

        // The opener's answer first.
        expect(find.text('Corrections 1 of 2'), findsOneWidget);
        expect(find.text('Estoy bien, gracias.'), findsWidgets);
        tapFirstHighlight(tester);
        await tester.pumpAndSettle();
        await tapAndSettle(tester, find.text('Save for Later'));
        expect(feedback.saved, hasLength(1));
        expect(
          feedback.saved.single.$2.response.originalText,
          'Estoy bien, gracias.',
        );
        await tapAndSettle(tester, find.text('Next answer'));

        // Then the interest answer; moving on without saving ignores it.
        expect(find.text('Corrections 2 of 2'), findsOneWidget);
        expect(find.text('Me gusta mucho el jazz.'), findsWidgets);
        await tapAndSettle(tester, find.text('Done'));

        expect(feedback.saved, hasLength(1));
        expect(doneWith, isTrue);
        expect(repository.stored.introduction.isComplete, isTrue);
      },
    );

    testWidgets('Not now finishes and leaves the answers in History', (
      tester,
    ) async {
      await answerBoth(tester);
      await tapAndSettle(tester, find.text('Not now'));

      expect(find.textContaining('Corrections'), findsNothing);
      expect(doneWith, isTrue);
      expect(feedback.history, hasLength(2));
      expect(repository.stored.introduction.isComplete, isTrue);
    });

    testWidgets('when nothing could be fetched, it says so and stays put', (
      tester,
    ) async {
      feedback.failuresLeft = 10;
      await answerBoth(tester);
      await tapAndSettle(tester, find.text('See suggestions'));

      expect(
        find.textContaining('could not be fetched just now'),
        findsOneWidget,
      );
      expect(find.text('Not now'), findsOneWidget);
      expect(doneWith, isNull);
      expect(repository.stored.introduction.isComplete, isFalse);
    });
  });
}
