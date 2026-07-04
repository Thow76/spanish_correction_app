import '../../../core/enums/language.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';
import '../domain/error_category.dart';
import '../../saved/domain/saved_explanation.dart';
import 'retranslation_grade_response.dart';

abstract interface class CorrectionService {
  Future<CorrectionResponse> correctText(String text, Language language);

  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  );

  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  );

  Future<String> generatePromptPhrase({
    required String correctedSentence,
    required Language language,
  });

  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  });
}
