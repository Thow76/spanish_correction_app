import '../../../core/enums/language.dart';
import '../../corrections/domain/correction_item.dart';
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
    this.startIndex,
    this.endIndex,
    this.correctedStartIndex,
    this.correctedEndIndex,
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

  /// Character offsets of the error within [originalSentence] /
  /// [correctedSentence], carried over from the live `CorrectionItem` at save
  /// time so the span can be re-highlighted precisely. Null for records saved
  /// before these fields existed (and for any save where the range was absent);
  /// those fall back to substring matching at render time.
  final int? startIndex;
  final int? endIndex;
  final int? correctedStartIndex;
  final int? correctedEndIndex;

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
    int? startIndex,
    int? endIndex,
    int? correctedStartIndex,
    int? correctedEndIndex,
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
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      correctedStartIndex: correctedStartIndex ?? this.correctedStartIndex,
      correctedEndIndex: correctedEndIndex ?? this.correctedEndIndex,
    );
  }

  /// Rebuilds the `CorrectionItem` this record was saved from — its phrases,
  /// category, and persisted character ranges — so the shared highlight resolver
  /// ([buildHighlightedSpans]) can anchor on the stored range (the correct
  /// occurrence of a repeated word) instead of a first-occurrence search.
  CorrectionItem toCorrectionItem() {
    return CorrectionItem(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      category: category,
      shortExplanation: shortExplanation,
      startIndex: startIndex,
      endIndex: endIndex,
      correctedStartIndex: correctedStartIndex,
      correctedEndIndex: correctedEndIndex,
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
      startIndex: json['start_index'] as int?,
      endIndex: json['end_index'] as int?,
      correctedStartIndex: json['corrected_start_index'] as int?,
      correctedEndIndex: json['corrected_end_index'] as int?,
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
      if (startIndex != null) 'start_index': startIndex,
      if (endIndex != null) 'end_index': endIndex,
      if (correctedStartIndex != null)
        'corrected_start_index': correctedStartIndex,
      if (correctedEndIndex != null) 'corrected_end_index': correctedEndIndex,
    };
  }
}
