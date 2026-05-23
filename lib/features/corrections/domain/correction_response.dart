import 'correction_item.dart';

class CorrectionResponse {
  const CorrectionResponse({
    required this.originalText,
    required this.correctedText,
    required this.corrections,
  });

  final String originalText;
  final String correctedText;
  final List<CorrectionItem> corrections;

  factory CorrectionResponse.fromJson(Map<String, Object?> json) {
    final rawCorrections = json['corrections'];

    return CorrectionResponse(
      originalText: json['original_text'] as String? ?? '',
      correctedText: json['corrected_text'] as String? ?? '',
      corrections: rawCorrections is List
          ? rawCorrections
                .whereType<Map<String, Object?>>()
                .map(CorrectionItem.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, Object?> toJson() {
    return {
      'original_text': originalText,
      'corrected_text': correctedText,
      'corrections': corrections.map((item) => item.toJson()).toList(),
    };
  }
}
