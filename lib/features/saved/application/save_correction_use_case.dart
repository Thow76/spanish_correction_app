import '../../../core/enums/language.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/application/prompt_phrase_translation.dart';
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
    var promptPhraseTranslation = const PromptPhraseTranslation(text: '');
    try {
      promptPhraseTranslation = await _correctionService.generatePromptPhrase(
        correctedSentence: correctedSentence,
        correctedPhrase: correction.correctedPhrase,
        language: language,
      );
    } catch (_) {
      promptPhraseTranslation = const PromptPhraseTranslation(text: '');
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
      promptPhrase: promptPhraseTranslation.text,
      language: language,
      startIndex: correction.startIndex,
      endIndex: correction.endIndex,
      correctedStartIndex: correction.correctedStartIndex,
      correctedEndIndex: correction.correctedEndIndex,
      promptHighlightStartIndex: promptPhraseTranslation.highlightStartIndex,
      promptHighlightEndIndex: promptPhraseTranslation.highlightEndIndex,
    );

    await _repositoryController.addSavedCorrection(savedCorrection);
    return savedCorrection;
  }
}
