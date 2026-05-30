import '../../../core/enums/language.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';
import '../../saved/domain/saved_explanation.dart';

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
}
