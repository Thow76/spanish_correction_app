import '../domain/correction_item.dart';
import 'correction_service_exception.dart';

class RetranslationGradeResponse {
  const RetranslationGradeResponse({
    required this.isRelated,
    required this.correctedText,
    required this.corrections,
  });

  final bool isRelated;
  final String correctedText;
  final List<CorrectionItem> corrections;

  factory RetranslationGradeResponse.fromJson(Map<String, Object?> json) {
    final rawIsRelated = json['is_related'];
    if (rawIsRelated is! bool) {
      throw const CorrectionServiceException(
        CorrectionFailureReason.invalidResponse,
        'Grading response missing or invalid "is_related" field.',
      );
    }

    final rawCorrections = json['corrections'];

    return RetranslationGradeResponse(
      isRelated: rawIsRelated,
      correctedText: json['corrected_text'] as String? ?? '',
      corrections: rawCorrections is List
          ? rawCorrections
                .whereType<Map<String, Object?>>()
                .map(CorrectionItem.fromJson)
                .toList()
          : const [],
    );
  }
}
