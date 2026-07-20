import '../../../core/enums/language.dart';
import '../../../core/models/walkthrough_activity.dart';
import '../../history/domain/correction_submission.dart';
import '../../saved/domain/saved_correction.dart';

abstract interface class CorrectionRepository {
  Future<List<CorrectionSubmission>> getRecentSubmissions({Language? language});

  Future<void> addSubmission(CorrectionSubmission submission);

  Future<void> removeSubmission(String id);

  Future<List<SavedCorrection>> getSavedCorrections({Language? language});

  Future<void> addSavedCorrection(SavedCorrection correction);

  Future<void> removeSavedCorrection(String id);

  Future<List<WalkthroughActivity>> getWalkthroughActivities({
    Language? language,
  });

  Future<void> addWalkthroughActivity(WalkthroughActivity activity);

  Future<void> removeWalkthroughActivity(String sourcePhraseId);

  Future<void> clear();
}
