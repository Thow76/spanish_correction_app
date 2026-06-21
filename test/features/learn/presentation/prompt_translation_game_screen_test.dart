import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/models/walkthrough_question.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/learn/presentation/prompt_translation_game_screen.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';
import 'package:spanish_correction_app/core/models/walkthrough_activity.dart';
import 'package:spanish_correction_app/core/services/walkthrough_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/queued_submission.dart';

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
  _FakeCorrectionService({List<CorrectionItem>? corrections})
    : _corrections = corrections ?? [_grammarError()];

  final List<CorrectionItem> _corrections;

  @override
  Future<CorrectionResponse> correctText(String text, Language language) async {
    return CorrectionResponse(
      originalText: text,
      correctedText: text,
      corrections: _corrections,
    );
  }

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
  Future<List<QueuedSubmission>> getQueuedSubmissions({
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
  Future<void> enqueueSubmission(QueuedSubmission submission) async {}

  @override
  Future<void> removeQueuedSubmission(String id) async {}

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
}) async {
  final controller = CorrectionRepositoryController(
    _FakeCorrectionRepository(savedCorrections ?? [buildSavedCorrection()]),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: PromptTranslationGameScreen(
        repositoryController: controller,
        transcriptionService: _FakeTranscriptionService(),
        correctionService: _FakeCorrectionService(corrections: corrections),
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
/// type an answer, reveal (grades KEEP PRACTICING), self-mark "Casi" (matches
/// the AI verdict, so no override dialog), accept the intro, fetch questions.
Future<void> driveToWalkthroughQuestions(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Ayer hubo mucho tráfico');
  await tester.pump();

  await _tap(tester, find.text('Ver respuesta'));
  await _tap(tester, find.text('Casi'));
  await _tap(tester, find.text('Sí, vamos'));
}

/// Scrolls the target into view (the game screen is a tall ListView, so bottom
/// controls sit below the fold) and taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('drives the funnel end-to-end to the walkthrough question phase', (
    tester,
  ) async {
    await pumpGame(tester);

    // The session loaded and the first prompt is shown.
    expect(find.text('Pregunta 1 de 1'), findsOneWidget);
    expect(find.text('Yesterday there was a lot of traffic'), findsOneWidget);

    await driveToWalkthroughQuestions(tester);

    // The fetched questions land on the current stub placeholder.
    expect(find.textContaining('Repaso preparado'), findsOneWidget);
    expect(find.textContaining('3 preguntas'), findsOneWidget);
  });
}
