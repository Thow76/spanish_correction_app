import '../../../core/enums/language.dart';
import '../../history/domain/correction_submission.dart';
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
  /// immediate error and let the user retry manually.
  Future<CorrectionResponse> call(String text, Language language) async {
    final trimmedText = text.trim();

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
    return response;
  }

  String _createId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}
