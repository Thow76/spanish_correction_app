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
    // corrected_text is always built from the submitted text plus the anchored
    // corrections, never taken from the model's own corrected_text — this is
    // the sole source of truth so the corrected-side text can never diverge
    // from what the app itself constructed.
    return CorrectionResponse(
      originalText: submittedText,
      correctedText: parsedCorrections.isEmpty
          ? submittedText
          : _reconstructCorrectedText(submittedText, parsedCorrections),
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
}
