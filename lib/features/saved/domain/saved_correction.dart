import '../../../core/enums/language.dart';
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
    required this.promptPhrase,
    required this.language,
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
  final String promptPhrase;
  final Language language;

  SavedCorrection copyWith({
    String? id,
    ErrorCategory? category,
    String? shortExplanation,
    String? originalSentence,
    SavedExplanation? explanation,
    DateTime? savedAt,
    String? correctedPhrase,
    String? originalPhrase,
    String? correctedSentence,
    String? promptPhrase,
    Language? language,
  }) {
    return SavedCorrection(
      id: id ?? this.id,
      category: category ?? this.category,
      shortExplanation: shortExplanation ?? this.shortExplanation,
      originalSentence: originalSentence ?? this.originalSentence,
      explanation: explanation ?? this.explanation,
      savedAt: savedAt ?? this.savedAt,
      correctedPhrase: correctedPhrase ?? this.correctedPhrase,
      originalPhrase: originalPhrase ?? this.originalPhrase,
      correctedSentence: correctedSentence ?? this.correctedSentence,
      promptPhrase: promptPhrase ?? this.promptPhrase,
      language: language ?? this.language,
    );
  }

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
      promptPhrase: json['prompt_phrase'] as String? ?? '',
      language: Language.fromJson(json['language'] as String?),
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
      'prompt_phrase': promptPhrase,
      'language': language.toJson(),
    };
  }
}
