import '../../../core/enums/language.dart';
import '../../corrections/domain/correction_input_mode.dart';
import '../../corrections/domain/correction_item.dart';
import '../../history/domain/correction_submission.dart';

/// How the introduction gets feedback on the learner's two answers (build
/// plan task 1.4). Behind an interface so the introduction can be tested
/// without the AI.
abstract interface class IntroductionFeedback {
  /// Sends [answer] through the app's check, so it lands in History, and
  /// returns the History entry. [inputMode] says whether the answer was
  /// typed or spoken (build step 2.3). Throws when the check fails (for
  /// example with no internet).
  Future<CorrectionSubmission> send(
    String answer,
    Language language, {
    CorrectionInputMode inputMode = CorrectionInputMode.typed,
  });

  /// Finds a History entry by its id, or null when it is no longer there
  /// (History keeps 20 cards). Used when the introduction resumes at the end
  /// screen after a relaunch.
  Future<CorrectionSubmission?> find(String submissionId, Language language);

  /// Saves one point into Saved through the existing save path.
  Future<void> save(CorrectionItem point, CorrectionSubmission submission);
}
