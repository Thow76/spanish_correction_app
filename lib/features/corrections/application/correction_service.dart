import '../../../core/enums/language.dart';
import '../domain/correction_input_mode.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';
import '../domain/error_category.dart';
import '../../saved/domain/saved_explanation.dart';
import 'prompt_phrase_translation.dart';
import 'retranslation_grade_response.dart';

abstract interface class CorrectionService {
  /// Checks [text]. [inputMode] says whether the learner typed it or spoke
  /// it; spoken Spanish text gets no Spelling items (build step 2.3).
  Future<CorrectionResponse> correctText(
    String text,
    Language language, {
    CorrectionInputMode inputMode = CorrectionInputMode.typed,
  });

  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  );

  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  );

  Future<PromptPhraseTranslation> generatePromptPhrase({
    required String correctedSentence,
    required String correctedPhrase,
    required Language language,
  });

  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  });
}
