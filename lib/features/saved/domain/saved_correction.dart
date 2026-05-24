import '../../corrections/domain/error_category.dart';
import 'saved_explanation.dart';

class SavedCorrection {
  const SavedCorrection({
    required this.id,
    required this.category,
    required this.shortExplanation,
    required this.originalSentence,
    required this.explanation,
    required this.savedAt,
    required this.correctedPhrase,
    required this.originalPhrase,
    required this.correctedSentence,
  });

  final String id;
  final ErrorCategory category;
  final String shortExplanation;
  final String originalSentence;
  final SavedExplanation explanation;
  final DateTime savedAt;
  final String correctedPhrase;
  final String originalPhrase;
  final String correctedSentence;

  factory SavedCorrection.fromJson(Map<String, Object?> json) {
    final rawExplanation = json['explanation'];
    final legacyLongExplanation = json['long_explanation'] as String? ?? '';

    return SavedCorrection(
      id: json['id'] as String? ?? '',
      category: ErrorCategory.fromLabel(json['category'] as String? ?? ''),
      shortExplanation: json['short_explanation'] as String? ?? '',
      originalSentence: json['original_sentence'] as String? ?? '',
      explanation: rawExplanation is Map<String, Object?>
          ? SavedExplanation.fromJson(rawExplanation)
          : SavedExplanation.fromLegacyLongExplanation(legacyLongExplanation),
      savedAt:
          DateTime.tryParse(json['saved_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      correctedPhrase: json['corrected_phrase'] as String? ?? '',
      originalPhrase: json['original_phrase'] as String? ?? '',
      correctedSentence: json['corrected_sentence'] as String? ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'category': category.label,
      'short_explanation': shortExplanation,
      'original_sentence': originalSentence,
      'explanation': explanation.toJson(),
      'saved_at': savedAt.toIso8601String(),
      'corrected_phrase': correctedPhrase,
      'original_phrase': originalPhrase,
      'corrected_sentence': correctedSentence,
    };
  }
}
