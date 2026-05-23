import '../../history/domain/correction_submission.dart';
import 'correction_repository_controller.dart';
import 'correction_service.dart';
import 'correction_service_exception.dart';

class SyncQueuedSubmissionsUseCase {
  const SyncQueuedSubmissionsUseCase({
    required CorrectionService correctionService,
    required CorrectionRepositoryController repositoryController,
  }) : _correctionService = correctionService,
       _repositoryController = repositoryController;

  final CorrectionService _correctionService;
  final CorrectionRepositoryController _repositoryController;

  Future<int> call() async {
    await _repositoryController.loadQueuedSubmissions();
    final queuedSubmissions = [..._repositoryController.queuedSubmissions];
    var syncedCount = 0;

    for (final queuedSubmission in queuedSubmissions) {
      try {
        final response = await _correctionService.correctText(
          queuedSubmission.text,
        );
        await _repositoryController.addSubmission(
          CorrectionSubmission(
            id: 'submission-${DateTime.now().microsecondsSinceEpoch}',
            response: response,
            createdAt: DateTime.now(),
          ),
        );
        await _repositoryController.removeQueuedSubmission(queuedSubmission.id);
        syncedCount += 1;
      } on CorrectionServiceException catch (error) {
        if (error.reason == CorrectionFailureReason.networkUnavailable) {
          break;
        }

        rethrow;
      }
    }

    return syncedCount;
  }
}
