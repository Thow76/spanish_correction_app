import 'package:characters/characters.dart';

import 'error_category.dart';

class CorrectionItem {
  const CorrectionItem({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.category,
    required this.shortExplanation,
    this.startIndex,
    this.endIndex,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final ErrorCategory category;
  final String shortExplanation;
  final int? startIndex;
  final int? endIndex;

  factory CorrectionItem.fromJson(
    Map<String, Object?> json, {
    bool allowLegacyCategories = true,
  }) {
    return CorrectionItem(
      originalPhrase: json['original_phrase'] as String? ?? '',
      correctedPhrase: json['corrected_phrase'] as String? ?? '',
      category: allowLegacyCategories
          ? ErrorCategory.fromLabel(json['category'] as String? ?? '')
          : ErrorCategory.fromApiLabel(json['category'] as String? ?? ''),
      shortExplanation: json['short_explanation'] as String? ?? '',
      startIndex: json['start_index'] as int?,
      endIndex: json['end_index'] as int?,
    );
  }

  factory CorrectionItem.fromAnchoredJson(
    Map<String, Object?> json, {
    required String submittedText,
    bool allowLegacyCategories = true,
  }) {
    final startIndex = json['start_index'];
    final endIndex = json['end_index'];
    if (startIndex is! int || endIndex is! int) {
      throw const FormatException('Missing correction range indexes.');
    }

    return CorrectionItem(
      originalPhrase: _sliceSubmittedText(
        submittedText,
        startIndex: startIndex,
        endIndex: endIndex,
      ),
      correctedPhrase: json['corrected_phrase'] as String? ?? '',
      category: allowLegacyCategories
          ? ErrorCategory.fromLabel(json['category'] as String? ?? '')
          : ErrorCategory.fromApiLabel(json['category'] as String? ?? ''),
      shortExplanation: json['short_explanation'] as String? ?? '',
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }

  static CorrectionItem? tryFromAnchoredJson(
    Map<String, Object?> json, {
    required String submittedText,
    bool allowLegacyCategories = true,
  }) {
    try {
      final item = CorrectionItem.fromAnchoredJson(
        json,
        submittedText: submittedText,
        allowLegacyCategories: allowLegacyCategories,
      );

      if (item.originalPhrase.isEmpty ||
          item.correctedPhrase == item.originalPhrase) {
        return null;
      }

      if (item.category == ErrorCategory.spelling &&
          _containsSpanishCharacters(item.originalPhrase) &&
          !_containsSpanishCharacters(item.correctedPhrase)) {
        return null;
      }

      final echoedOriginalPhrase = json['original_phrase'];
      if (echoedOriginalPhrase is String &&
          echoedOriginalPhrase != item.originalPhrase) {
        return null;
      }

      return item;
    } on FormatException {
      return null;
    }
  }

  Map<String, Object?> toJson() {
    return {
      'original_phrase': originalPhrase,
      if (startIndex != null) 'start_index': startIndex,
      if (endIndex != null) 'end_index': endIndex,
      'corrected_phrase': correctedPhrase,
      'category': category.label,
      'short_explanation': shortExplanation,
    };
  }

  static String _sliceSubmittedText(
    String submittedText, {
    required int startIndex,
    required int endIndex,
  }) {
    final characters = submittedText.characters;
    if (startIndex < 0 ||
        endIndex <= startIndex ||
        endIndex > characters.length) {
      throw FormatException('Invalid correction range $startIndex..$endIndex.');
    }

    return characters.skip(startIndex).take(endIndex - startIndex).toString();
  }

  static bool _containsSpanishCharacters(String value) {
    return RegExp(r'[áéíóúüñÁÉÍÓÚÜÑ¿¡]').hasMatch(value);
  }
}
