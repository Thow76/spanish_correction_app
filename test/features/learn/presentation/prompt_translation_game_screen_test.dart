import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/models/walkthrough_question.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/application/retranslation_grade_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/learn/presentation/prompt_translation_game_screen.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/answer_view.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/walkthrough_question_view.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/walkthrough_result_view.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/shared/design/app_colors.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';
import 'package:spanish_correction_app/core/models/walkthrough_activity.dart';
import 'package:spanish_correction_app/core/services/walkthrough_service.dart';

/// Default walkthrough questions returned by the fake service.
final _defaultWalkthroughQuestions = <WalkthroughQuestion>[
  const WalkthroughQuestion(
    englishStem: 'Yesterday',
    correctTranslation: 'Ayer',
    distractors: Distractors(first: 'Hoy', second: 'Mañana'),
    chunkPosition: 0,
  ),
  const WalkthroughQuestion(
    englishStem: 'there was',
    correctTranslation: 'había',
    distractors: Distractors(first: 'hubo', second: 'estaba'),
    chunkPosition: 1,
  ),
  const WalkthroughQuestion(
    englishStem: 'a lot of traffic',
    correctTranslation: 'mucho tráfico',
    distractors: Distractors(first: 'mucho ruido', second: 'mucha gente'),
    chunkPosition: 2,
  ),
];

SavedExplanation _explanation() => const SavedExplanation(
  whyItsWrong: 'why',
  inContext: 'context',
  alternatives: ['alt'],
);

SavedCorrection buildSavedCorrection({
  String id = 'sc-1',
  ErrorCategory category = ErrorCategory.grammar,
  String promptPhrase = 'Yesterday there was a lot of traffic',
  String correctedSentence = 'Ayer había mucho tráfico',
}) {
  return SavedCorrection(
    id: id,
    category: category,
    shortExplanation: 'Watch the past tense.',
    originalSentence: 'Ayer hubo mucho tráfico',
    explanation: _explanation(),
    savedAt: DateTime(2026, 6, 21),
    correctedPhrase: 'había',
    originalPhrase: 'hubo',
    correctedSentence: correctedSentence,
    promptPhrase: promptPhrase,
    language: Language.spanish,
  );
}

CorrectionItem _grammarError() => const CorrectionItem(
  originalPhrase: 'hubo',
  correctedPhrase: 'había',
  category: ErrorCategory.grammar,
  shortExplanation: 'Use the imperfect.',
);

/// Returns a CorrectionService whose grade keeps a grammar error present, so a
/// grammar-category saved correction grades KEEP PRACTICING.
class _FakeCorrectionService implements CorrectionService {
  _FakeCorrectionService({List<CorrectionItem>? corrections, this.isRelated = true})
    : _corrections = corrections ?? [_grammarError()];

  final List<CorrectionItem> _corrections;
  final bool isRelated;

  @override
  Future<CorrectionResponse> correctText(String text, Language language) async =>
      throw UnimplementedError();

  @override
  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<String> generatePromptPhrase({
    required String correctedSentence,
    required Language language,
  }) async => throw UnimplementedError();

  @override
  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  }) async {
    return RetranslationGradeResponse(
      isRelated: isRelated,
      correctedText: attempt,
      corrections: _corrections,
    );
  }
}

/// A WalkthroughService that returns canned questions without any network call.
class _FakeWalkthroughService extends WalkthroughService {
  _FakeWalkthroughService({List<WalkthroughQuestion>? questions})
    : _questions = questions ?? _defaultWalkthroughQuestions,
      super(apiKey: 'test-key', model: 'test-model');

  final List<WalkthroughQuestion> _questions;

  @override
  Future<List<WalkthroughQuestion>> fetchQuestions({
    required String targetSentence,
    required String userAttempt,
    required String englishSource,
    required List<CorrectionItem> corrections,
    required Language language,
  }) async {
    return _questions;
  }
}

/// A CorrectionService whose grade always throws, so the re-translation grade is
/// unavailable (the screen's `_grade` stays null) — exercising the agreed
/// null-grade scoring fallback (counts as a miss, no walkthrough).
class _ThrowingCorrectionService implements CorrectionService {
  @override
  Future<CorrectionResponse> correctText(String text, Language language) async =>
      throw UnimplementedError();

  @override
  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<String> generatePromptPhrase({
    required String correctedSentence,
    required Language language,
  }) async => throw UnimplementedError();

  @override
  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  }) async => throw Exception('grade unavailable');
}

class _FakeTranscriptionService implements TranscriptionService {
  @override
  Future<String> transcribeAudio(String audioPath, Language language) async =>
      throw UnimplementedError();
}

class _FakeCorrectionRepository implements CorrectionRepository {
  _FakeCorrectionRepository(this._saved);

  final List<SavedCorrection> _saved;

  @override
  Future<List<SavedCorrection>> getSavedCorrections({Language? language}) async =>
      _saved;

  @override
  Future<List<CorrectionSubmission>> getRecentSubmissions({
    Language? language,
  }) async => const [];

  @override
  Future<List<WalkthroughActivity>> getWalkthroughActivities({
    Language? language,
  }) async => const [];

  @override
  Future<void> addSubmission(CorrectionSubmission submission) async {}

  @override
  Future<void> removeSubmission(String id) async {}

  @override
  Future<void> addSavedCorrection(SavedCorrection correction) async {}

  @override
  Future<void> removeSavedCorrection(String id) async {}

  @override
  Future<void> addWalkthroughActivity(WalkthroughActivity activity) async {}

  @override
  Future<void> removeWalkthroughActivity(String sourcePhraseId) async {}

  @override
  Future<void> clear() async {}
}

Future<void> pumpGame(
  WidgetTester tester, {
  List<SavedCorrection>? savedCorrections,
  List<CorrectionItem>? corrections,
  List<WalkthroughQuestion>? walkthroughQuestions,
  CorrectionService? correctionService,
}) async {
  final controller = CorrectionRepositoryController(
    _FakeCorrectionRepository(savedCorrections ?? [buildSavedCorrection()]),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: PromptTranslationGameScreen(
        repositoryController: controller,
        transcriptionService: _FakeTranscriptionService(),
        correctionService:
            correctionService ?? _FakeCorrectionService(corrections: corrections),
        walkthroughService: _FakeWalkthroughService(
          questions: walkthroughQuestions,
        ),
        language: Language.spanish,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Drives a fresh prompt phase through to the walkthrough question phase:
/// type an answer, reveal (grades KEEP PRACTICING), advance off the AI tier,
/// accept the intro, fetch questions.
Future<void> driveToWalkthroughQuestions(WidgetTester tester) async {
  await answerCurrentPhraseToIntro(tester);
  await _tap(tester, find.text('Sí, vamos'));
}

/// Types an answer, reveals (grades keep-practicing via the fake), and taps the
/// reveal primary advance — landing on the walkthrough intro, which the AI tier
/// (siguePracticando) triggers on its own.
Future<void> answerCurrentPhraseToIntro(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Ayer hubo mucho tráfico');
  await tester.pump();

  await _tap(tester, find.text('Ver respuesta'));
  await _advanceFromReveal(tester);
}

/// Types an answer, reveals (awaiting the AI verdict), and taps the reveal
/// primary advance. Unlike [answerCurrentPhraseToIntro] this makes no claim
/// about where it lands — the tier decides (summary for a hit, walkthrough
/// intro for a miss).
Future<void> _answerAndAdvance(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Ayer había mucho tráfico');
  await tester.pump();

  await _tap(tester, find.text('Ver respuesta'));
  await _advanceFromReveal(tester);
}

/// Taps the reveal screen's primary forward button, whichever tier is shown:
/// `reveal-continue` for the satisfied tiers (and the unavailable-grade
/// fallback), `reveal-walkthrough` for Sigue practicando.
Future<void> _advanceFromReveal(WidgetTester tester) async {
  final hasContinue = find
      .byKey(const Key('reveal-continue'))
      .evaluate()
      .isNotEmpty;
  final key = hasContinue
      ? const Key('reveal-continue')
      : const Key('reveal-walkthrough');
  await _tap(tester, find.byKey(key));
}

/// Types an answer and reveals, stopping on the reveal screen (the AI verdict
/// has resolved) WITHOUT advancing — so the verdict panel can be inspected.
Future<void> _answerToReveal(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Ayer había mucho tráfico');
  await tester.pump();

  await _tap(tester, find.text('Ver respuesta'));
}

/// Scrolls the target into view (the game screen is a tall ListView, so bottom
/// controls sit below the fold) and taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Answers every walkthrough question with its correct option, letting the
/// auto-advance pause carry each step forward.
Future<void> answerAllWalkthroughCorrectly(WidgetTester tester) async {
  for (final question in _defaultWalkthroughQuestions) {
    await _tap(tester, find.text(question.correctTranslation));
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    await tester.pumpAndSettle();
  }
}

/// Answers every walkthrough question with a distractor (wrong), tapping the
/// manual continue each time (wrong answers do not auto-advance).
Future<void> answerAllWalkthroughWrongly(WidgetTester tester) async {
  for (final question in _defaultWalkthroughQuestions) {
    await _tap(tester, find.text(question.distractors.first));
    await _tap(tester, find.byKey(const Key('walkthrough-advance')));
  }
}

void main() {
  testWidgets(
    'prompt phase shows the saved error category label and the ORIGINAL wrong '
    'phrase (not the corrected one)',
    (tester) async {
      // wordChoice (not the default grammar) proves the label is dynamic — it
      // reflects the saved correction's category, not a hardcoded string.
      await pumpGame(
        tester,
        savedCorrections: [
          buildSavedCorrection(category: ErrorCategory.wordChoice),
        ],
      );

      // Dynamic category label.
      expect(
        find.textContaining('Word Choice', findRichText: true),
        findsOneWidget,
      );
      // The ORIGINAL (wrong) phrase is shown...
      expect(find.textContaining('hubo', findRichText: true), findsOneWidget);
      // ...and the corrected phrase is NOT — showing it would give away the
      // answer to this recall exercise.
      expect(find.textContaining('había', findRichText: true), findsNothing);
    },
  );

  testWidgets('drives the funnel into the real WalkthroughQuestionView', (
    tester,
  ) async {
    await pumpGame(tester);

    // The session loaded and the first prompt is shown.
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Yesterday there was a lot of traffic'), findsOneWidget);

    await driveToWalkthroughQuestions(tester);

    // The fetched questions render in the real question view (first stem shown),
    // not the old stub.
    expect(find.byType(WalkthroughQuestionView), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.textContaining('Repaso preparado'), findsNothing);
  });

  testWidgets('completing the walkthrough shows the result view with the score', (
    tester,
  ) async {
    await pumpGame(tester);
    await driveToWalkthroughQuestions(tester);
    await answerAllWalkthroughCorrectly(tester);

    // onCompleted fired -> the real result view renders the 3/3 = 100% score.
    expect(find.byType(WalkthroughResultView), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.byType(WalkthroughQuestionView), findsNothing);
  });

  testWidgets('Continue from the result advances the game (to summary)', (
    tester,
  ) async {
    await pumpGame(tester);
    await driveToWalkthroughQuestions(tester);
    await answerAllWalkthroughCorrectly(tester);

    await _tap(tester, find.text('Continuar'));

    // The single-phrase session is complete -> summary phase.
    expect(find.byType(WalkthroughResultView), findsNothing);
    expect(find.text('Resultado'), findsOneWidget);
  });

  testWidgets('See Answer opens the answer screen from the walkthrough result', (
    tester,
  ) async {
    await pumpGame(tester);
    await driveToWalkthroughQuestions(tester);
    await answerAllWalkthroughWrongly(tester);

    // Poor tier (0/3) surfaces "Ver respuesta".
    expect(find.text('0%'), findsOneWidget);
    await _tap(tester, find.text('Ver respuesta'));

    // Navigates to the answer screen; the result view is gone. The score was
    // already recorded at walkthrough entry, so this is the last (single)
    // question -> "Terminar" forward.
    expect(find.byType(AnswerView), findsOneWidget);
    expect(find.byType(WalkthroughResultView), findsNothing);
    expect(find.text('Terminar'), findsOneWidget);

    // Forward advances to the summary WITHOUT re-recording (still 0 / 2).
    await _tap(tester, find.byKey(const Key('answer-forward')));
    expect(find.text('Resultado'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
  });

  testWidgets('Try again returns to the SAME phrase as a fresh prompt', (
    tester,
  ) async {
    await pumpGame(tester);
    await driveToWalkthroughQuestions(tester);
    await answerAllWalkthroughWrongly(tester); // 0/3 -> poor tier (Try-again)

    await _tap(tester, find.text('Intentar la traducción completa otra vez'));

    // Back on the prompt for the SAME phrase (same index, same prompt text).
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Yesterday there was a lot of traffic'), findsOneWidget);

    // Fresh attempt: empty input, and no walkthrough/result widgets linger.
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    expect(find.byType(WalkthroughResultView), findsNothing);
    expect(find.byType(WalkthroughQuestionView), findsNothing);
  });

  testWidgets('retry leaves no stale walkthrough / grade / answer state', (
    tester,
  ) async {
    await pumpGame(tester);
    await driveToWalkthroughQuestions(tester);
    await answerAllWalkthroughWrongly(tester); // poor tier -> Try-again visible

    await _tap(tester, find.text('Intentar la traducción completa otra vez'));

    // Clean prompt: empty input, and NONE of the prior-attempt state lingers.
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '');
    // No reveal/grade ghosts.
    expect(find.text('Sigue practicando'), findsNothing);
    expect(find.text('Respuesta esperada'), findsNothing);
    expect(find.text('Tu respuesta'), findsNothing);
    // No walkthrough intro / question / result ghosts.
    expect(find.text('Sí, vamos'), findsNothing);
    expect(find.byType(WalkthroughQuestionView), findsNothing);
    expect(find.byType(WalkthroughResultView), findsNothing);
  });

  testWidgets('retry returns to the SAME phrase index (no skip)', (
    tester,
  ) async {
    await pumpGame(tester);
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);

    await driveToWalkthroughQuestions(tester);
    await answerAllWalkthroughWrongly(tester);
    await _tap(tester, find.text('Intentar la traducción completa otra vez'));

    // Same phrase, not advanced and not the summary.
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Resultado'), findsNothing);
  });

  testWidgets('a re-failed retry re-offers the walkthrough (loop)', (
    tester,
  ) async {
    await pumpGame(tester);
    await driveToWalkthroughQuestions(tester);
    await answerAllWalkthroughWrongly(tester);
    await _tap(tester, find.text('Intentar la traducción completa otra vez'));

    // Re-attempt the same phrase; the fake grader keeps it keep-practicing, so
    // the walkthrough intro must be offered again — proving the loop works with
    // a freshly captured snapshot and no special "second failure" branch.
    await answerCurrentPhraseToIntro(tester);

    expect(find.text('¿Lo trabajamos paso a paso?'), findsOneWidget);
    expect(find.text('Sí, vamos'), findsOneWidget);
  });

  group('AI-tier scoring (X/Y sourced from grade.tier)', () {
    testWidgets(
      'excelente scores 2: a clean attempt advances straight to a 2/2 '
      'summary with no walkthrough',
      (tester) async {
        // No corrections at all -> target fixed AND sentence clean -> excelente.
        await pumpGame(tester, corrections: const []);

        await _answerAndAdvance(tester);

        // A well-done tier never offers the walkthrough; the single-phrase
        // session is complete -> summary, scored at the top weight (2 of 2).
        expect(find.text('¿Lo trabajamos paso a paso?'), findsNothing);
        expect(find.text('Resultado'), findsOneWidget);
        expect(find.text('2 / 2'), findsOneWidget);
      },
    );

    testWidgets(
      'bienHecho scores 1 (distinct from excelente): target fixed but an '
      'other-category error remains -> 1/2 summary, still no walkthrough',
      (tester) async {
        // Only a spelling error (the saved category is grammar): the target is
        // fixed but the sentence is not clean -> bienHecho (weight 1, not 2).
        await pumpGame(
          tester,
          corrections: const [
            CorrectionItem(
              originalPhrase: 'traffico',
              correctedPhrase: 'tráfico',
              category: ErrorCategory.spelling,
              shortExplanation: 'Spelling.',
            ),
          ],
        );

        await _answerAndAdvance(tester);

        expect(find.text('¿Lo trabajamos paso a paso?'), findsNothing);
        expect(find.text('Resultado'), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);
      },
    );

    testWidgets(
      'siguePracticando scores 0: 0/2 summary after declining the '
      'walkthrough',
      (tester) async {
        // The default fake keeps a grammar error -> siguePracticando (miss).
        await pumpGame(tester);

        await _answerAndAdvance(tester);

        // The miss tier offers the walkthrough; decline it to reach the summary.
        expect(find.text('¿Lo trabajamos paso a paso?'), findsOneWidget);
        await _tap(tester, find.text('Ahora no'));

        expect(find.text('Resultado'), findsOneWidget);
        expect(find.text('0 / 2'), findsOneWidget);
      },
    );

    testWidgets(
      'an unavailable grade scores 0: 0/2 summary and no walkthrough',
      (tester) async {
        // Grading throws -> _grade stays null. Per the agreed fallback a null
        // grade scores as a miss, and the walkthrough guard (grade != null)
        // keeps the intro from showing.
        await pumpGame(tester, correctionService: _ThrowingCorrectionService());

        await _answerAndAdvance(tester);

        expect(find.text('¿Lo trabajamos paso a paso?'), findsNothing);
        expect(find.text('Resultado'), findsOneWidget);
        expect(find.text('0 / 2'), findsOneWidget);
      },
    );
  });

  group('Verdict panel renders all three tiers', () {
    testWidgets(
      'excelente -> "¡Excelente!" verdict (success state) on the reveal screen',
      (tester) async {
        // No corrections -> target fixed AND sentence clean -> excelente.
        await pumpGame(tester, corrections: const []);

        await _answerToReveal(tester);

        // The reveal heading now also shows "¡Excelente!", so the text appears
        // twice (heading + interim verdict card) until Step 7 removes the card.
        expect(find.text('¡Excelente!'), findsWidgets);
        expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
        // Distinct from the bienHecho state.
        expect(find.text('Bien hecho'), findsNothing);
        expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      },
    );

    testWidgets(
      'bienHecho -> "Bien hecho" verdict, NOT Excelente (non-regression)',
      (tester) async {
        // Only a spelling error (the saved category is grammar): target fixed
        // but the sentence is not clean -> bienHecho.
        await pumpGame(
          tester,
          corrections: const [
            CorrectionItem(
              originalPhrase: 'traffico',
              correctedPhrase: 'tráfico',
              category: ErrorCategory.spelling,
              shortExplanation: 'Spelling.',
            ),
          ],
        );

        await _answerToReveal(tester);

        expect(find.text('Bien hecho'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        // The Excelente state must NOT leak into bienHecho.
        expect(find.text('¡Excelente!'), findsNothing);
        expect(find.byIcon(Icons.verified_outlined), findsNothing);
      },
    );

    testWidgets(
      'siguePracticando -> "Sigue practicando" verdict (practice state)',
      (tester) async {
        // The default fake keeps a grammar error -> siguePracticando.
        await pumpGame(tester);

        await _answerToReveal(tester);

        // Heading + interim verdict card both render "Sigue practicando" until
        // Step 7 removes the card.
        expect(find.text('Sigue practicando'), findsWidgets);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('¡Excelente!'), findsNothing);
        expect(find.text('Bien hecho'), findsNothing);
      },
    );

    testWidgets(
      'off-topic (isRelated: false) -> "Sigue practicando" verdict with the '
      'distinct off-topic explanation, not the "category not fixed" message',
      (tester) async {
        await pumpGame(
          tester,
          correctionService: _FakeCorrectionService(isRelated: false),
        );

        await _answerToReveal(tester);

        expect(find.text('Sigue practicando'), findsWidgets);
        expect(
          find.text('Esto no aborda la frase objetivo — inténtalo de nuevo.'),
          findsOneWidget,
        );
        // The normal "target category not fixed" reasoning must not appear.
        expect(find.textContaining('La IA marcó en tu categoría'), findsNothing);
      },
    );
  });

  group('reveal action bar surfaces the per-tier buttons', () {
    final spellingOnly = [
      const CorrectionItem(
        originalPhrase: 'traffico',
        correctedPhrase: 'tráfico',
        category: ErrorCategory.spelling,
        shortExplanation: 'Spelling.',
      ),
    ];

    testWidgets('excelente -> continue only', (tester) async {
      // No corrections -> target fixed AND sentence clean -> excelente.
      await pumpGame(tester, corrections: const []);
      await _answerToReveal(tester);

      expect(find.byKey(const Key('reveal-continue')), findsOneWidget);
      expect(find.byKey(const Key('reveal-try-again')), findsNothing);
      expect(find.byKey(const Key('reveal-walkthrough')), findsNothing);
      expect(find.byKey(const Key('reveal-see-answer')), findsNothing);
    });

    testWidgets('bienHecho -> continue + try again', (tester) async {
      // Saved category is grammar; only a spelling error remains -> bienHecho.
      await pumpGame(tester, corrections: spellingOnly);
      await _answerToReveal(tester);

      expect(find.byKey(const Key('reveal-continue')), findsOneWidget);
      expect(find.byKey(const Key('reveal-try-again')), findsOneWidget);
      expect(find.byKey(const Key('reveal-walkthrough')), findsNothing);
      expect(find.byKey(const Key('reveal-see-answer')), findsNothing);
    });

    testWidgets(
      'siguePracticando -> walkthrough + see answer, no continue',
      (tester) async {
        // The default fake keeps a grammar error -> siguePracticando.
        await pumpGame(tester);
        await _answerToReveal(tester);

        expect(find.byKey(const Key('reveal-walkthrough')), findsOneWidget);
        expect(find.byKey(const Key('reveal-see-answer')), findsOneWidget);
        expect(find.byKey(const Key('reveal-continue')), findsNothing);
        expect(find.byKey(const Key('reveal-try-again')), findsNothing);
      },
    );

    testWidgets(
      'Bien hecho "Intentar de nuevo" returns to the same phrase fresh',
      (tester) async {
        await pumpGame(tester, corrections: spellingOnly);
        await _answerToReveal(tester);

        await _tap(tester, find.byKey(const Key('reveal-try-again')));

        // Back on the SAME phrase as a clean prompt, score dropped (not a skip
        // to the summary), exercising the all-tier snapshot.
        expect(find.text('Pregunta 1 de 1'), findsOneWidget);
        expect(find.text('Yesterday there was a lot of traffic'), findsOneWidget);
        expect(find.text('Resultado'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '',
        );
      },
    );
  });

  group('answer screen routing (Ver respuesta)', () {
    testWidgets(
      'reveal See answer opens the answer screen; forward records once and '
      'advances',
      (tester) async {
        // Default fake keeps a grammar error -> siguePracticando (the only tier
        // with a See answer button).
        await pumpGame(tester);
        await _answerToReveal(tester);

        await _tap(tester, find.byKey(const Key('reveal-see-answer')));

        // The answer screen is shown; the reveal action bar is gone.
        expect(find.byType(AnswerView), findsOneWidget);
        // Single-question session, not yet recorded -> last question -> Terminar.
        expect(find.text('Terminar'), findsOneWidget);

        await _tap(tester, find.byKey(const Key('answer-forward')));

        // Scored exactly once as a miss (siguePracticando = 0 of 2) and advanced
        // to the summary — no double/missed record.
        expect(find.text('Resultado'), findsOneWidget);
        expect(find.text('0 / 2'), findsOneWidget);
      },
    );

    testWidgets(
      'See answer on every question: non-last -> "Siguiente pregunta" -> next '
      'prompt, last -> "Terminar" -> summary, each miss recorded',
      (tester) async {
        await pumpGame(
          tester,
          savedCorrections: [
            buildSavedCorrection(id: 'sc-1', promptPhrase: 'Prompt one'),
            buildSavedCorrection(id: 'sc-2', promptPhrase: 'Prompt two'),
          ],
        );

        expect(find.text('Pregunta 1 de 2'), findsOneWidget);

        // Q1 via See answer: NOT the last question -> "Siguiente pregunta".
        await _answerToReveal(tester);
        await _tap(tester, find.byKey(const Key('reveal-see-answer')));
        expect(find.byType(AnswerView), findsOneWidget);
        expect(find.text('Siguiente pregunta'), findsOneWidget);
        expect(find.text('Terminar'), findsNothing);

        // Forward advances to the NEXT prompt, not the summary.
        await _tap(tester, find.byKey(const Key('answer-forward')));
        expect(find.text('Pregunta 2 de 2'), findsOneWidget);
        expect(find.text('Resultado'), findsNothing);

        // Q2 via See answer: the last question -> "Terminar" -> summary.
        await _answerToReveal(tester);
        await _tap(tester, find.byKey(const Key('reveal-see-answer')));
        expect(find.text('Terminar'), findsOneWidget);
        await _tap(tester, find.byKey(const Key('answer-forward')));

        // Both answered via See answer and scored as a miss (0 each); the
        // denominator is 2 per answered question -> 0 / 4.
        expect(find.text('Resultado'), findsOneWidget);
        expect(find.text('0 / 4'), findsOneWidget);
      },
    );
  });

  group('reveal heading and answer block (Phase 5 redesign)', () {
    final spellingOnly = [
      const CorrectionItem(
        originalPhrase: 'traffico',
        correctedPhrase: 'tráfico',
        category: ErrorCategory.spelling,
        shortExplanation: 'Spelling.',
      ),
    ];

    Text headingOf(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const Key('reveal-heading')));

    testWidgets('excelente -> green "¡Excelente!" heading', (tester) async {
      await pumpGame(tester, corrections: const []);
      await _answerToReveal(tester);

      final heading = headingOf(tester);
      expect(heading.data, '¡Excelente!');
      expect(heading.style?.color, AppColors.success);
    });

    testWidgets('bienHecho -> cyan "¡Bien hecho!" heading', (tester) async {
      await pumpGame(tester, corrections: spellingOnly);
      await _answerToReveal(tester);

      final heading = headingOf(tester);
      expect(heading.data, '¡Bien hecho!');
      expect(heading.style?.color, AppColors.cyan);
    });

    testWidgets('siguePracticando -> amber "Sigue practicando" heading', (
      tester,
    ) async {
      await pumpGame(tester);
      await _answerToReveal(tester);

      final heading = headingOf(tester);
      expect(heading.data, 'Sigue practicando');
      expect(heading.style?.color, AppColors.amber);
    });

    testWidgets(
      'siguePracticando underlines the still-present phrase in Tu respuesta',
      (tester) async {
        // The default fake keeps the grammar error 'hubo'; type an attempt that
        // contains it so the diff can locate and underline it.
        await pumpGame(tester);
        await tester.enterText(
          find.byType(TextField),
          'Ayer hubo mucho tráfico',
        );
        await tester.pump();
        await _tap(tester, find.text('Ver respuesta'));

        expect(_underlinedDiffPhrases(tester), contains('hubo'));
      },
    );

    testWidgets('excelente renders no diff underline (clean attempt)', (
      tester,
    ) async {
      await pumpGame(tester, corrections: const []);
      await _answerToReveal(tester);

      expect(_underlinedDiffPhrases(tester), isEmpty);
    });
  });
}

/// The text of every span rendered with the reveal diff treatment — an
/// underline in the highlight yellow ([AppColors.naturalLanguage]).
List<String> _underlinedDiffPhrases(WidgetTester tester) {
  final phrases = <String>[];
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    void visit(InlineSpan span) {
      if (span is TextSpan) {
        if (span.text != null &&
            span.style?.decoration == TextDecoration.underline &&
            span.style?.color == AppColors.naturalLanguage) {
          phrases.add(span.text!);
        }
        span.children?.forEach(visit);
      }
    }

    visit(rich.text);
  }
  return phrases;
}
