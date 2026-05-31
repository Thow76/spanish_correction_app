import '../../../core/enums/language.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/domain/correction_item.dart';
import '../domain/saved_correction.dart';

class SaveCorrectionUseCase {
  const SaveCorrectionUseCase({
    required CorrectionService correctionService,
    required CorrectionRepositoryController repositoryController,
  }) : _correctionService = correctionService,
       _repositoryController = repositoryController;

  final CorrectionService _correctionService;
  final CorrectionRepositoryController _repositoryController;

  Future<SavedCorrection> call({
    required CorrectionItem correction,
    required String originalSentence,
    required String correctedSentence,
    required Language language,
  }) async {
    final explanation = await _correctionService.generateStructuredExplanation(
      correction,
      language,
    );
    var promptPhrase = '';
    try {
      promptPhrase = await _correctionService.generatePromptPhrase(
        correctedSentence: correctedSentence,
        language: language,
      );
    } catch (_) {
      promptPhrase = '';
    }

    final savedCorrection = SavedCorrection(
      id: 'saved-${DateTime.now().microsecondsSinceEpoch}',
      category: correction.category,
      shortExplanation: correction.shortExplanation,
      originalSentence: originalSentence,
      explanation: explanation,
      savedAt: DateTime.now(),
      correctedPhrase: correction.correctedPhrase,
      originalPhrase: correction.originalPhrase,
      correctedSentence: correctedSentence,
      promptPhrase: promptPhrase,
      language: language,
    );

    await _repositoryController.addSavedCorrection(savedCorrection);
    return savedCorrection;
  }
}
