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
    this.correctedStartIndex,
    this.correctedEndIndex,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final ErrorCategory category;
  final String shortExplanation;
  final int? startIndex;
  final int? endIndex;
  final int? correctedStartIndex;
  final int? correctedEndIndex;

  CorrectionItem withCorrectedRange({
    required int correctedStartIndex,
    required int correctedEndIndex,
  }) {
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
    final echoedOriginalPhrase = json['original_phrase'];
    if (echoedOriginalPhrase is! String) {
      return null;
    }

    final correctedPhrase = json['corrected_phrase'] as String? ?? '';
    if (correctedPhrase.isEmpty) {
      return null;
    }

    final modelStartIndex = json['start_index'];
    final modelEndIndex = json['end_index'];
    if (modelStartIndex is! int || modelEndIndex is! int) {
      return null;
    }

    final anchored = _anchorRange(
      submittedText: submittedText,
      modelStartIndex: modelStartIndex,
      modelEndIndex: modelEndIndex,
      echoedOriginalPhrase: echoedOriginalPhrase,
    );
    if (anchored == null) {
      return null;
    }

    final ErrorCategory category;
    try {
      category = allowLegacyCategories
          ? ErrorCategory.fromLabel(json['category'] as String? ?? '')
          : ErrorCategory.fromApiLabel(json['category'] as String? ?? '');
    } on FormatException {
      return null;
    }

    final item = CorrectionItem(
      originalPhrase: echoedOriginalPhrase,
      correctedPhrase: correctedPhrase,
      category: category,
      shortExplanation: json['short_explanation'] as String? ?? '',
      startIndex: anchored.start,
      endIndex: anchored.end,
    );

    if (!item.isInsertion && item.correctedPhrase == item.originalPhrase) {
      return null;
    }

    if (item.category == ErrorCategory.spelling &&
        _containsSpanishCharacters(item.originalPhrase) &&
        !_containsSpanishCharacters(item.correctedPhrase)) {
      return null;
    }

    return item;
  }

  static _Range? _anchorRange({
    required String submittedText,
    required int modelStartIndex,
    required int modelEndIndex,
    required String echoedOriginalPhrase,
  }) {
    final graphemes = submittedText.characters.toList();
    final phraseGraphemes = echoedOriginalPhrase.characters.toList();

    if (modelStartIndex >= 0 &&
        modelEndIndex >= modelStartIndex &&
        modelEndIndex <= graphemes.length) {
      final slice = graphemes
          .sublist(modelStartIndex, modelEndIndex)
          .join();
      if (slice == echoedOriginalPhrase) {
        return _Range(modelStartIndex, modelEndIndex);
      }
    }

    if (phraseGraphemes.isEmpty) {
      final clampedStart = modelStartIndex.clamp(0, graphemes.length);
      return _Range(clampedStart, clampedStart);
    }

    final matches = _findGraphemeMatches(graphemes, phraseGraphemes);
    if (matches.isEmpty) {
      return null;
    }

    final best = matches.reduce(
      (a, b) => (a - modelStartIndex).abs() <= (b - modelStartIndex).abs()
          ? a
          : b,
    );
    return _Range(best, best + phraseGraphemes.length);
  }

  static List<int> _findGraphemeMatches(
    List<String> haystack,
    List<String> needle,
  ) {
    if (needle.isEmpty || needle.length > haystack.length) {
      return const [];
    }

    final matches = <int>[];
    for (var start = 0; start <= haystack.length - needle.length; start++) {
      var matched = true;
      for (var offset = 0; offset < needle.length; offset++) {
        if (haystack[start + offset] != needle[offset]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        matches.add(start);
      }
    }
    return matches;
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

  bool get isInsertion =>
      startIndex != null && endIndex != null && startIndex == endIndex;

  static String _sliceSubmittedText(
    String submittedText, {
    required int startIndex,
    required int endIndex,
  }) {
    final characters = submittedText.characters;
    if (startIndex < 0 ||
        endIndex < startIndex ||
        endIndex > characters.length) {
      throw FormatException('Invalid correction range $startIndex..$endIndex.');
    }

    return characters.skip(startIndex).take(endIndex - startIndex).toString();
  }

  static bool _containsSpanishCharacters(String value) {
    return RegExp(r'[áéíóúüñÁÉÍÓÚÜÑ¿¡]').hasMatch(value);
  }
}

class _Range {
  const _Range(this.start, this.end);

  final int start;
  final int end;
}
