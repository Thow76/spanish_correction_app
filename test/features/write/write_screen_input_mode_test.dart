import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/application/prompt_phrase_translation.dart';
import 'package:spanish_correction_app/features/corrections/application/retranslation_grade_response.dart';
import 'package:spanish_correction_app/features/corrections/application/submit_correction_use_case.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_input_mode.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/saved/application/save_correction_use_case.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';
import 'package:spanish_correction_app/features/write/presentation/write_screen.dart';
import 'package:spanish_correction_app/shared/widgets/primary_action_button.dart';

import '../navigation/in_memory_correction_repository.dart';

/// Records how each check was asked for, and finds nothing.
class _RecordingCorrectionService implements CorrectionService {
  final checks = <(String, CorrectionInputMode)>[];

  @override
  Future<CorrectionResponse> correctText(
    String text,
    Language language, {
    CorrectionInputMode inputMode = CorrectionInputMode.typed,
  }) async {
    checks.add((text, inputMode));
    return CorrectionResponse(
      originalText: text,
      correctedText: text,
      corrections: const [],
    );
  }

  @override
  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  ) async => '';

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async =>
      const SavedExplanation(whyItsWrong: '', inContext: '', alternatives: []);

  @override
  Future<PromptPhraseTranslation> generatePromptPhrase({
    required String correctedSentence,
    required String correctedPhrase,
    required Language language,
  }) async => const PromptPhraseTranslation(text: '');

  @override
  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  }) async => throw UnimplementedError();
}

class _UnusedTranscriptionService implements TranscriptionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Build step 2.3: the Check a phrase page tells the check how the text was
/// given. The spoken path needs the phone's microphone, so it is tried on
/// the phone; this covers the typed path.
void main() {
  testWidgets('typed text is checked as typed', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final service = _RecordingCorrectionService();
    final controller = CorrectionRepositoryController(
      InMemoryCorrectionRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WriteScreen(
            submitCorrectionUseCase: SubmitCorrectionUseCase(
              correctionService: service,
              repositoryController: controller,
            ),
            saveCorrectionUseCase: SaveCorrectionUseCase(
              correctionService: service,
              repositoryController: controller,
            ),
            transcriptionService: _UnusedTranscriptionService(),
            language: Language.spanish,
            keyboardVisible: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Donde esta el baño?');
    await tester.pump();
    // The page's header says "Correct" too; the button is the one to tap.
    await tester.tap(find.widgetWithText(PrimaryActionButton, 'Correct'));
    await tester.pumpAndSettle();

    expect(service.checks, [
      ('Donde esta el baño?', CorrectionInputMode.typed),
    ]);
  });
}
