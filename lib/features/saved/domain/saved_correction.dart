import '../../corrections/domain/error_category.dart';

class SavedCorrection {
  const SavedCorrection({
    required this.id,
    required this.category,
    required this.shortExplanation,
    required this.originalSentence,
    required this.longExplanation,
    required this.savedAt,
    required this.correctedPhrase,
  });

  final String id;
  final ErrorCategory category;
  final String shortExplanation;
  final String originalSentence;
  final String longExplanation;
  final DateTime savedAt;
  final String correctedPhrase;

  factory SavedCorrection.fromJson(Map<String, Object?> json) {
    return SavedCorrection(
      id: json['id'] as String? ?? '',
      category: ErrorCategory.fromLabel(json['category'] as String? ?? ''),
      shortExplanation: json['short_explanation'] as String? ?? '',
      originalSentence: json['original_sentence'] as String? ?? '',
      longExplanation: json['long_explanation'] as String? ?? '',
      savedAt:
          DateTime.tryParse(json['saved_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      correctedPhrase: json['corrected_phrase'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'category': category.label,
      'short_explanation': shortExplanation,
      'original_sentence': originalSentence,
      'long_explanation': longExplanation,
      'saved_at': savedAt.toIso8601String(),
      'corrected_phrase': correctedPhrase,
    };
  }
}
