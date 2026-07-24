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
      correctedStartIndex: _optionalInt(json['corrected_start_index']),
      correctedEndIndex: _optionalInt(json['corrected_end_index']),
    );
  }

  /// Parses one correction from the retranslation-grading response, anchoring
  /// on `start_index` against [attempt] (the text the grading call graded) the
  /// same way [tryFromAnchoredJson] does for the main correction flow: trust
  /// the model's index only if the slice at that position matches the echoed
  /// `original_phrase` exactly, otherwise fall back to the nearest substring
  /// match. `end_index` is not requested from the model — it is always
  /// `start_index` + the phrase length, exactly as [_anchorRange] already
  /// derives it elsewhere.
  ///
  /// Leaves startIndex/endIndex null (the shared highlight resolver's own
  /// substring-search fallback, [buildHighlightedSpans]) when `start_index` is
  /// absent or no match is found at all — never throws, since a grading
  /// response with an unanchorable phrase should still render, just without
  /// exact-position anchoring.
  factory CorrectionItem.fromGradingJson(
    Map<String, Object?> json, {
    required String attempt,
  }) {
    final originalPhrase = json['original_phrase'] as String? ?? '';
    final modelStartIndex = json['start_index'];

    final anchored = modelStartIndex is int
        ? _anchorRange(
            submittedText: attempt,
            modelStartIndex: modelStartIndex,
            echoedOriginalPhrase: originalPhrase,
          )
        : null;

    return CorrectionItem(
      originalPhrase: originalPhrase,
      correctedPhrase: json['corrected_phrase'] as String? ?? '',
      category: ErrorCategory.fromLabel(json['category'] as String? ?? ''),
      shortExplanation: json['short_explanation'] as String? ?? '',
      startIndex: anchored?.start,
      endIndex: anchored?.end,
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
      correctedStartIndex: _optionalInt(json['corrected_start_index']),
      correctedEndIndex: _optionalInt(json['corrected_end_index']),
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
    if (modelStartIndex is! int) {
      return null;
    }

    final anchored = _anchorRange(
      submittedText: submittedText,
      modelStartIndex: modelStartIndex,
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

    // correctedStartIndex/correctedEndIndex are intentionally left unset here:
    // the schema no longer asks the model for corrected_start_index/
    // corrected_end_index, and even if a non-conforming response included
    // them, CorrectionResponse.fromAnchoredJson unconditionally recomputes
    // both via computeCorrectedRanges immediately after this — so reading
    // them here would be dead code that could never affect the result.
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
    required String echoedOriginalPhrase,
  }) {
    final graphemes = submittedText.characters.toList();
    final phraseGraphemes = echoedOriginalPhrase.characters.toList();

    // end_index is no longer supplied by the model — it is always derived
    // from start_index + the length of the (already-validated) phrase.
    final modelEndIndex = modelStartIndex + phraseGraphemes.length;
    if (modelStartIndex >= 0 && modelEndIndex <= graphemes.length) {
      final slice = graphemes.sublist(modelStartIndex, modelEndIndex).join();
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
      (a, b) =>
          (a - modelStartIndex).abs() <= (b - modelStartIndex).abs() ? a : b,
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
      if (correctedStartIndex != null)
        'corrected_start_index': correctedStartIndex,
      if (correctedEndIndex != null) 'corrected_end_index': correctedEndIndex,
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

  // Defensively reads an integer field from parsed JSON. Returns null when the
  // field is absent or not an integer (e.g. an older cached response that
  // predates corrected_start_index/corrected_end_index), rather than throwing.
  static int? _optionalInt(Object? value) => value is int ? value : null;

  static bool _containsSpanishCharacters(String value) {
    return RegExp(r'[áéíóúüñÁÉÍÓÚÜÑ¿¡]').hasMatch(value);
  }
}

class _Range {
  const _Range(this.start, this.end);

  final int start;
  final int end;
}
