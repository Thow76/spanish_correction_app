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

  /// [attempt] is the text the grading call graded — the corrections' own
  /// `start_index` anchors against it (see [CorrectionItem.fromGradingJson]),
  /// since `original_phrase` is always a substring of the attempt, never of
  /// [correctedText].
  factory RetranslationGradeResponse.fromJson(
    Map<String, Object?> json, {
    required String attempt,
  }) {
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
                .map((item) => CorrectionItem.fromGradingJson(item, attempt: attempt))
                .toList()
          : const [],
    );
  }
}
