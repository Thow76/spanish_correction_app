import '../domain/correction_item.dart';
import '../domain/correction_response.dart';
import '../../saved/domain/saved_explanation.dart';

abstract interface class CorrectionService {
  Future<CorrectionResponse> correctText(String text);

  Future<String> generateLongExplanation(CorrectionItem correction);

  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
  );
}
