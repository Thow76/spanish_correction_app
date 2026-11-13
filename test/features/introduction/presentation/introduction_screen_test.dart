import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/introduction/content/introduction_content.dart';
import 'package:spanish_correction_app/features/introduction/presentation/answer_recorder.dart';
import 'package:spanish_correction_app/features/introduction/presentation/introduction_screen.dart';
import 'package:spanish_correction_app/features/profile/application/profile_repository.dart';
import 'package:spanish_correction_app/features/profile/domain/learner_profile.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service_exception.dart';
import 'package:spanish_correction_app/shared/widgets/mic_control.dart';
import 'package:spanish_correction_app/shared/widgets/primary_action_button.dart';

class _InMemoryProfileRepository implements ProfileRepository {
  LearnerProfile profile = LearnerProfile.empty();

  @override
  Future<LearnerProfile> getProfile() async => profile;

  @override
  Future<void> saveProfile(LearnerProfile next) async {
    profile = next;
  }

  @override
  Future<LearnerProfile> updateProfile(
    LearnerProfile Function(LearnerProfile profile) change,
  ) async {
    profile = change(profile);
    return profile;
  }

  @override
  Future<void> clear() async {
    profile = LearnerProfile.empty();
  }
}

class _FakeTranscriptionService implements TranscriptionService {
  _FakeTranscriptionService({this.error});

  static const transcript = 'Soy de Londres.';
  final TranscriptionServiceException? error;
  final List<String> paths = [];
  final List<Language> languages = [];

  @override
  Future<String> transcribeAudio(String audioPath, Language language) async {
    paths.add(audioPath);
    languages.add(language);
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return transcript;
  }
}

class _FakeAnswerRecorder implements AnswerRecorder {
  _FakeAnswerRecorder({this.permitted = true});

  final bool permitted;
  int starts = 0;
  int stops = 0;
  bool disposed = false;

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<void> start() async {
    starts++;
  }

  @override
  Future<String?> stop() async {
    stops++;
    return '/tmp/introduction-recording-$stops.wav';
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  late _InMemoryProfileRepository repository;
  late _FakeTranscriptionService transcription;
  late _FakeAnswerRecorder recorder;
  late int leaveCount;

  setUp(() {
    repository = _InMemoryProfileRepository();
    transcription = _FakeTranscriptionService();
    recorder = _FakeAnswerRecorder();
    leaveCount = 0;
  });

  /// A phone-sized surface, so every chip is on screen.
  void usePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Language language = Language.spanish,
  }) async {
    usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: IntroductionScreen(
          language: language,
          profileRepository: repository,
          transcriptionService: transcription,
          createRecorder: () => recorder,
          onLeave: () => leaveCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder sendButton() => find.widgetWithText(PrimaryActionButton, 'Send');

  bool buttonEnabled(Finder finder) {
    final button =
        find
                .descendant(of: finder, matching: find.byType(FilledButton))
                .evaluate()
                .single
                .widget
            as FilledButton;
    return button.onPressed != null;
  }

  Future<void> typeAndSend(WidgetTester tester, String answer) async {
    await tester.enterText(find.byType(TextField), answer);
    await tester.pump();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
  }

  Future<void> speakAndSend(WidgetTester tester) async {
    await tester.tap(find.byType(MicControl));
    await tester.pump();
    await tester.tap(find.byType(MicControl));
    await tester.pumpAndSettle();
    await tester.tap(sendButton());
    await tester.pumpAndSettle();
  }

  Future<void> reachInterests(WidgetTester tester) async {
    await typeAndSend(tester, 'Bien, gracias.');
    await speakAndSend(tester);
  }

  Future<void> reachFullerQuestions(WidgetTester tester) async {
    await reachInterests(tester);
    await tester.tap(find.text('Los viajes'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryActionButton, 'Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the typed warm-up with its hint and no microphone', (
    tester,
  ) async {
    await pumpScreen(tester);

    final warmUp = IntroductionContent.warmUpQuestions.first;
    expect(find.text('Warm-up 1 of 2'), findsOneWidget);
    expect(find.text(warmUp.text), findsOneWidget);
    expect(find.text(warmUp.hint), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(MicControl), findsNothing);
    expect(find.text('Stop for now'), findsOneWidget);
    expect(buttonEnabled(sendButton()), isFalse);
    expect(repository.profile.introduction.language, Language.spanish);
  });

  testWidgets('Send wakes up once something is typed', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Bien');
    await tester.pump();

    expect(buttonEnabled(sendButton()), isTrue);
  });

  testWidgets(
    'sending the typed warm-up shows the spoken one with a clear box',
    (tester) async {
      await pumpScreen(tester);

      await typeAndSend(tester, 'Bien, gracias.');

      final spoken = IntroductionContent.warmUpQuestions[1];
      expect(find.text('Warm-up 2 of 2'), findsOneWidget);
      expect(find.text(spoken.text), findsOneWidget);
      expect(find.text(spoken.hint), findsOneWidget);
      expect(find.byType(MicControl), findsOneWidget);
      expect(find.text('or'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(buttonEnabled(sendButton()), isFalse);
    },
  );

  testWidgets('the spoken warm-up records, transcribes and sends', (
    tester,
  ) async {
    await pumpScreen(tester);
    await typeAndSend(tester, 'Bien, gracias.');

    await tester.tap(find.byType(MicControl));
    await tester.pump();
    expect(recorder.starts, 1);
    expect(find.text('Tap to stop'), findsOneWidget);

    await tester.tap(find.byType(MicControl));
    await tester.pumpAndSettle();
    expect(recorder.stops, 1);
    expect(transcription.paths, ['/tmp/introduction-recording-1.wav']);
    expect(transcription.languages, [Language.spanish]);
    expect(find.text('Soy de Londres.'), findsOneWidget);
    expect(buttonEnabled(sendButton()), isTrue);

    await tester.tap(sendButton());
    await tester.pumpAndSettle();

    expect(find.text('Your interests'), findsOneWidget);
    expect(find.text(IntroductionContent.interestsQuestion), findsOneWidget);
    expect(find.text(IntroductionContent.interestsHint), findsOneWidget);
    expect(repository.profile.introduction.answeredWarmUpIds.length, 2);
  });

  testWidgets('a failed transcription shows a message and stays on the step', (
    tester,
  ) async {
    transcription = _FakeTranscriptionService(
      error: const TranscriptionServiceException(
        TranscriptionFailureReason.networkUnavailable,
        'offline',
      ),
    );
    await pumpScreen(tester);
    await typeAndSend(tester, 'Bien, gracias.');

    await tester.tap(find.byType(MicControl));
    await tester.pump();
    await tester.tap(find.byType(MicControl));
    await tester.pump();

    expect(
      find.text('No internet available. Please check your connection.'),
      findsOneWidget,
    );
    expect(find.text('Warm-up 2 of 2'), findsOneWidget);
    expect(buttonEnabled(sendButton()), isFalse);
  });

  testWidgets('without microphone permission nothing is recorded', (
    tester,
  ) async {
    recorder = _FakeAnswerRecorder(permitted: false);
    await pumpScreen(tester);
    await typeAndSend(tester, 'Bien, gracias.');

    await tester.tap(find.byType(MicControl));
    await tester.pump();

    expect(recorder.starts, 0);
    expect(
      find.text('Microphone permission is required to record audio.'),
      findsOneWidget,
    );
  });

  testWidgets('the chips show the Spanish labels and keep the taps', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachInterests(tester);

    for (final interest in IntroductionContent.interests) {
      expect(find.text(interest.spanish), findsOneWidget);
      expect(find.text(interest.english), findsNothing);
    }

    await tester.tap(find.text('La música'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Los viajes'));
    await tester.pumpAndSettle();
    expect(repository.profile.interestIds, ['music', 'travel']);

    await tester.tap(find.text('La música'));
    await tester.pumpAndSettle();
    expect(repository.profile.interestIds, ['travel']);
  });

  testWidgets('Continue after the chips shows the first fuller question', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachFullerQuestions(tester);

    final questionIds = repository.profile.introduction.fullerQuestionIds;
    expect(questionIds.length, 3);
    final first = IntroductionContent.fullerQuestionById(questionIds.first)!;
    expect(first.interestId, 'travel');
    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text(first.text), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(MicControl), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
  });

  testWidgets('answering all three fuller questions reaches the end screen', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachFullerQuestions(tester);

    await typeAndSend(tester, 'Fui a Lisboa con mi hermana.');
    expect(find.text('Question 2 of 3'), findsOneWidget);
    await speakAndSend(tester);
    expect(find.text('Question 3 of 3'), findsOneWidget);
    await typeAndSend(tester, 'Quiero ir a Japón.');

    expect(find.text('All done'), findsOneWidget);
    expect(find.text(IntroductionContent.endScreenLine), findsOneWidget);
    expect(find.text('Stop for now'), findsNothing);
    expect(repository.profile.introduction.fullerAnswers.length, 3);
    expect(repository.profile.introduction.isComplete, isFalse);
    expect(leaveCount, 0);

    await tester.tap(
      find.widgetWithText(PrimaryActionButton, 'Continue to the app'),
    );
    await tester.pumpAndSettle();

    expect(repository.profile.introduction.isComplete, isTrue);
    expect(leaveCount, 1);
  });

  testWidgets('Stop for now before any fuller answer leaves for the app', (
    tester,
  ) async {
    await pumpScreen(tester);
    await typeAndSend(tester, 'Bien, gracias.');

    await tester.tap(find.text('Stop for now'));
    await tester.pumpAndSettle();

    expect(leaveCount, 1);
    expect(repository.profile.introduction.isComplete, isFalse);
    expect(repository.profile.introduction.answeredWarmUpIds.length, 1);
  });

  testWidgets('Stop for now after a fuller answer shows the end screen first', (
    tester,
  ) async {
    await pumpScreen(tester);
    await reachFullerQuestions(tester);
    await typeAndSend(tester, 'Fui a Lisboa.');

    await tester.tap(find.text('Stop for now'));
    await tester.pumpAndSettle();

    expect(leaveCount, 0);
    expect(find.text(IntroductionContent.endScreenLine), findsOneWidget);

    await tester.tap(
      find.widgetWithText(PrimaryActionButton, 'Continue to the app'),
    );
    await tester.pumpAndSettle();

    expect(leaveCount, 1);
    expect(repository.profile.introduction.isComplete, isTrue);
  });

  testWidgets('a stopped introduction resumes where it was', (tester) async {
    await pumpScreen(tester);
    await reachInterests(tester);
    await tester.tap(find.text('El deporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop for now'));
    await tester.pumpAndSettle();
    expect(leaveCount, 1);

    await tester.pumpWidget(const SizedBox());
    await pumpScreen(tester);

    expect(find.text('Your interests'), findsOneWidget);
    final chip = tester.widget<FilterChip>(
      find.ancestor(
        of: find.text('El deporte'),
        matching: find.byType(FilterChip),
      ),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('a completed introduction leaves straight away', (tester) async {
    repository.profile = repository.profile.withIntroduction(
      repository.profile.introduction
          .started(Language.spanish)
          .completed(DateTime(2026, 11, 12)),
    );

    await pumpScreen(tester);

    expect(leaveCount, 1);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the recorder is released when the screen goes', (tester) async {
    await pumpScreen(tester);
    await typeAndSend(tester, 'Bien, gracias.');
    await tester.tap(find.byType(MicControl));
    await tester.pump();
    await tester.tap(find.byType(MicControl));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());

    expect(recorder.disposed, isTrue);
  });
}
