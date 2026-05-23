import '../domain/correction_item.dart';
import '../domain/correction_response.dart';

abstract interface class CorrectionService {
  Future<CorrectionResponse> correctText(String text);

  Future<String> generateLongExplanation(CorrectionItem correction);
}
