import '../../../core/enums/language.dart';
import '../../history/domain/correction_submission.dart';
import '../domain/correction_input_mode.dart';
import '../domain/correction_response.dart';
import 'correction_repository_controller.dart';
import 'correction_service.dart';

class SubmitCorrectionUseCase {
  const SubmitCorrectionUseCase({
    required CorrectionService correctionService,
    required CorrectionRepositoryController repositoryController,
  }) : _correctionService = correctionService,
       _repositoryController = repositoryController;

  final CorrectionService _correctionService;
  final CorrectionRepositoryController _repositoryController;

  /// Submits [text] for correction. On failure (network or service), the
  /// underlying `CorrectionServiceException` propagates directly — no
  /// queueing, no background retry. The caller is expected to show an
  /// immediate error and let the user retry manually. [inputMode] says
  /// whether the text was typed or spoken (build step 2.3).
  Future<CorrectionResponse> call(
    String text,
    Language language, {
    CorrectionInputMode inputMode = CorrectionInputMode.typed,
  }) async {
    final submission = await submit(text, language, inputMode: inputMode);
    return submission.response;
  }

  /// The same as [call], but returns the whole History entry, so the caller
  /// knows its id (the introduction records it, task 1.4).
  Future<CorrectionSubmission> submit(
    String text,
    Language language, {
    CorrectionInputMode inputMode = CorrectionInputMode.typed,
  }) async {
    final trimmedText = text.trim();

    final response = await _correctionService.correctText(
      trimmedText,
      language,
      inputMode: inputMode,
    );
    final submission = CorrectionSubmission(
      id: _createId('submission'),
      response: response,
      createdAt: DateTime.now(),
      language: language,
    );
    await _repositoryController.addSubmission(submission);
    return submission;
  }

  String _createId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
