import '../../../core/enums/language.dart';
import '../../../shared/network/network_status_service.dart';
import '../../history/domain/correction_submission.dart';
import '../domain/correction_response.dart';
import '../domain/queued_submission.dart';
import 'correction_repository_controller.dart';
import 'correction_service.dart';
import 'correction_service_exception.dart';

class SubmitCorrectionUseCase {
  const SubmitCorrectionUseCase({
    required CorrectionService correctionService,
    required CorrectionRepositoryController repositoryController,
    required NetworkStatusService networkStatusService,
  }) : _correctionService = correctionService,
       _repositoryController = repositoryController,
       _networkStatusService = networkStatusService;

  final CorrectionService _correctionService;
  final CorrectionRepositoryController _repositoryController;
  final NetworkStatusService _networkStatusService;

  Future<SubmitCorrectionResult> call(String text, Language language) async {
    final trimmedText = text.trim();
    final hasConnection = await _networkStatusService.hasConnection;

    if (!hasConnection) {
      await _queueSubmission(trimmedText, language);
      return const SubmitCorrectionResult.queued();
    }

    try {
      final response = await _correctionService.correctText(
        trimmedText,
        language,
      );
      await _repositoryController.addSubmission(
        CorrectionSubmission(
          id: _createId('submission'),
          response: response,
          createdAt: DateTime.now(),
          language: language,
        ),
      );
      return SubmitCorrectionResult.completed(response);
    } on CorrectionServiceException catch (error) {
      if (error.reason == CorrectionFailureReason.networkUnavailable) {
        await _queueSubmission(trimmedText, language);
        return const SubmitCorrectionResult.queued();
      }

      rethrow;
    }
  }

  Future<void> _queueSubmission(String text, Language language) {
    return _repositoryController.enqueueSubmission(
      QueuedSubmission(
        id: _createId('queued'),
        text: text,
        createdAt: DateTime.now(),
        language: language,
      ),
    );
  }

  String _createId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}

class SubmitCorrectionResult {
  const SubmitCorrectionResult._({required this.wasQueued, this.response});

  const SubmitCorrectionResult.completed(CorrectionResponse response)
    : this._(wasQueued: false, response: response);

  const SubmitCorrectionResult.queued() : this._(wasQueued: true);

  final bool wasQueued;
  final CorrectionResponse? response;
}
