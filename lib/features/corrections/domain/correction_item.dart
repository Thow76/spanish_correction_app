import 'error_category.dart';

class CorrectionItem {
  const CorrectionItem({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.category,
    required this.shortExplanation,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final ErrorCategory category;
  final String shortExplanation;

  factory CorrectionItem.fromJson(Map<String, Object?> json) {
    return CorrectionItem(
      originalPhrase: json['original_phrase'] as String? ?? '',
      correctedPhrase: json['corrected_phrase'] as String? ?? '',
      category: ErrorCategory.fromLabel(json['category'] as String? ?? ''),
      shortExplanation: json['short_explanation'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'original_phrase': originalPhrase,
      'corrected_phrase': correctedPhrase,
      'category': category.label,
      'short_explanation': shortExplanation,
    };
  }
}
