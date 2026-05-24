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

  CorrectionResponse copyWith({
    String? originalText,
    String? correctedText,
    List<CorrectionItem>? corrections,
  }) {
    return CorrectionResponse(
      originalText: originalText ?? this.originalText,
      correctedText: correctedText ?? this.correctedText,
      corrections: corrections ?? this.corrections,
    );
  }

  factory CorrectionResponse.fromJson(
    Map<String, Object?> json, {
    bool allowLegacyCategories = true,
  }) {
    final rawCorrections = json['corrections'];

    return CorrectionResponse(
      originalText: json['original_text'] as String? ?? '',
      correctedText: json['corrected_text'] as String? ?? '',
      corrections: rawCorrections is List
          ? rawCorrections
                .whereType<Map<String, Object?>>()
                .map(
                  (json) => CorrectionItem.fromJson(
                    json,
                    allowLegacyCategories: allowLegacyCategories,
                  ),
                )
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
