import '../../../core/enums/language.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/submit_correction_use_case.dart';
import '../../corrections/domain/correction_input_mode.dart';
import '../../corrections/domain/correction_item.dart';
import '../../history/domain/correction_submission.dart';
import '../../saved/application/save_correction_use_case.dart';
import '../application/introduction_feedback.dart';

/// The introduction's feedback through the app's own check, History and
/// Saved (task 1.4). Since build step 2.3 the check is the two-step check,
/// the same path as the Check a phrase page.
class HistoryIntroductionFeedback implements IntroductionFeedback {
  const HistoryIntroductionFeedback({
    required SubmitCorrectionUseCase submitCorrectionUseCase,
    required SaveCorrectionUseCase saveCorrectionUseCase,
    required CorrectionRepositoryController repositoryController,
  }) : _submit = submitCorrectionUseCase,
       _save = saveCorrectionUseCase,
       _repositoryController = repositoryController;

  final SubmitCorrectionUseCase _submit;
  final SaveCorrectionUseCase _save;
  final CorrectionRepositoryController _repositoryController;

  @override
  Future<CorrectionSubmission> send(
    String answer,
    Language language, {
    CorrectionInputMode inputMode = CorrectionInputMode.typed,
  }) => _submit.submit(answer, language, inputMode: inputMode);

  @override
  Future<CorrectionSubmission?> find(
    String submissionId,
    Language language,
  ) async {
    await _repositoryController.setActiveLanguage(language);
    for (final submission in _repositoryController.recentSubmissions) {
      if (submission.id == submissionId) {
        return submission;
      }
    }
    return null;
  }

  @override
  Future<void> save(CorrectionItem point, CorrectionSubmission submission) =>
      _save(
        correction: point,
        originalSentence: submission.response.originalText,
        correctedSentence: submission.response.correctedText,
        language: submission.language,
      );
}
