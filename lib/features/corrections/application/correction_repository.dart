import '../../history/domain/correction_submission.dart';
import '../../saved/domain/saved_correction.dart';
import '../domain/queued_submission.dart';

abstract interface class CorrectionRepository {
  Future<List<CorrectionSubmission>> loadRecentSubmissions();

  Future<void> addSubmission(CorrectionSubmission submission);

  Future<void> removeSubmission(String id);

  Future<List<SavedCorrection>> loadSavedCorrections();

  Future<void> addSavedCorrection(SavedCorrection correction);

  Future<void> removeSavedCorrection(String id);

  Future<List<QueuedSubmission>> loadQueuedSubmissions();

  Future<void> enqueueSubmission(QueuedSubmission submission);

  Future<void> removeQueuedSubmission(String id);

  Future<void> clear();
}
