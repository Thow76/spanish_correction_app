import 'package:characters/characters.dart';

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

  factory CorrectionResponse.fromAnchoredJson(
    Map<String, Object?> json, {
    required String submittedText,
    bool allowLegacyCategories = true,
  }) {
    final rawCorrections = json['corrections'];
    final parsedCorrections = rawCorrections is List
        ? rawCorrections
              .whereType<Map<String, Object?>>()
              .map(
                (json) => CorrectionItem.tryFromAnchoredJson(
                  json,
                  submittedText: submittedText,
                  allowLegacyCategories: allowLegacyCategories,
                ),
              )
              .whereType<CorrectionItem>()
              .toList()
        : const <CorrectionItem>[];
    final modelCorrectedText = json['corrected_text'] as String? ?? '';
    final reconstructedCorrectedText = parsedCorrections.isEmpty
        ? submittedText
        : _reconstructCorrectedText(submittedText, parsedCorrections);

    // Corrected-side highlight ranges come solely from the model's reported
    // corrected_start_index/corrected_end_index (parsed onto each CorrectionItem
    // and validated by the slice-check guard in the highlight resolver). The old
    // arithmetic path computed them against the reconstructed text, which
    // diverged from the rendered model text — the source of Bug 1.
    return CorrectionResponse(
      originalText: submittedText,
      correctedText:
          _shouldUseModelCorrectedText(
            submittedText: submittedText,
            modelCorrectedText: modelCorrectedText,
            hasCorrections: parsedCorrections.isNotEmpty,
          )
          ? modelCorrectedText.trim()
          : reconstructedCorrectedText,
      corrections: parsedCorrections,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'original_text': originalText,
      'corrected_text': correctedText,
      'corrections': corrections.map((item) => item.toJson()).toList(),
    };
  }

  static String _reconstructCorrectedText(
    String submittedText,
    List<CorrectionItem> corrections,
  ) {
    final characters = submittedText.characters.toList();
    final sortedCorrections = [...corrections]
      ..sort((left, right) => right.startIndex!.compareTo(left.startIndex!));

    for (final correction in sortedCorrections) {
      characters.replaceRange(
        correction.startIndex!,
        correction.endIndex!,
        correction.correctedPhrase.characters,
      );
    }

    return characters.join();
  }

  static bool _shouldUseModelCorrectedText({
    required String submittedText,
    required String modelCorrectedText,
    required bool hasCorrections,
  }) {
    final trimmed = modelCorrectedText.trim();
    if (trimmed.isEmpty) {
      return false;
    }

    if (!hasCorrections) {
      return trimmed == submittedText;
    }

    final submittedLength = submittedText.characters.length;
    final correctedLength = trimmed.characters.length;
    if (submittedLength == 0 || correctedLength == 0) {
      return false;
    }

    final upperBound = submittedLength + 40;
    if (correctedLength > upperBound || correctedLength * 3 < submittedLength) {
      return false;
    }

    final submittedWords = _normalisedWords(submittedText);
    if (submittedWords.isEmpty) {
      return true;
    }

    final correctedWords = _normalisedWords(trimmed);
    final sharedWords = submittedWords.intersection(correctedWords).length;
    return sharedWords / submittedWords.length >= 0.5;
  }

  static Set<String> _normalisedWords(String text) {
    return RegExp(r'[\p{L}\p{N}]+', unicode: true)
        .allMatches(_removeSpanishDiacritics(text.toLowerCase()))
        .map((match) => match.group(0)!)
        .where((word) => word.length >= 3)
        .toSet();
  }

  static String _removeSpanishDiacritics(String text) {
    return text
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }
}
