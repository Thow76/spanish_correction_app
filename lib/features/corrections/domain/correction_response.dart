import 'package:characters/characters.dart';

import 'correction_corrected_range_calculator.dart';
import 'correction_item.dart';
import 'correction_note.dart';
import 'correction_overlap_resolver.dart';

class CorrectionResponse {
  const CorrectionResponse({
    required this.originalText,
    required this.correctedText,
    required this.corrections,
    this.notes = const [],
  });

  final String originalText;
  final String correctedText;

  /// Error-verdict corrections only. Dialectal and not-an-error items never
  /// become `CorrectionItem`s — they are represented separately in [notes]
  /// (dialectal) or dropped entirely (not-an-error), never mixed into this
  /// list. `correctedText` and the highlighted spans are both built from
  /// this list, so anything added here is treated as a real error.
  final List<CorrectionItem> corrections;
  final List<CorrectionNote> notes;

  /// Whether the submitted text had any real (error-verdict) corrections.
  bool get hasCorrections => corrections.isNotEmpty;

  factory CorrectionResponse.fromJson(
    Map<String, Object?> json, {
    bool allowLegacyCategories = true,
  }) {
    final rawCorrections = json['corrections'];

    final parsedCorrections = rawCorrections is List
        ? rawCorrections
              .whereType<Map<String, Object?>>()
              .map(
                (json) => CorrectionItem.fromJson(
                  json,
                  allowLegacyCategories: allowLegacyCategories,
                ),
              )
              .toList()
        : const <CorrectionItem>[];

    return CorrectionResponse(
      originalText: json['original_text'] as String? ?? '',
      correctedText: json['corrected_text'] as String? ?? '',
      corrections: _recomputeMissingCorrectedRanges(parsedCorrections),
    );
  }

  /// `CorrectionItem.toJson()` has never serialized `corrected_start_index`/
  /// `corrected_end_index` (see its definition), so every correction reloaded
  /// from persisted history parses those back as null via
  /// `CorrectionItem.fromJson`. This recomputes them from the original-side
  /// data that *is* persisted (`startIndex`, `originalPhrase`,
  /// `correctedPhrase`) — the same way `fromAnchoredJson` computes them for a
  /// fresh response — but only for the specific items missing them, mirroring
  /// `SavedCorrection`'s fallback-for-legacy-nulls approach rather than
  /// touching every item unconditionally.
  ///
  /// Gated two ways:
  /// - Only items with a null corrected range *and* a non-null original range
  ///   are recomputed. Items with no original-side range at all (data saved
  ///   before anchored parsing existed) are left untouched instead of being
  ///   handed to [computeCorrectedRanges], which throws on any item missing
  ///   `startIndex`/`endIndex`.
  /// - The "needs recompute" subset is deduped via
  ///   [resolveOverlappingCorrections] before ranges are computed, since
  ///   dedup was added well after the app started persisting history —
  ///   already-saved corrections cannot be assumed non-overlapping, and
  ///   [computeCorrectedRanges] requires non-overlapping input.
  static List<CorrectionItem> _recomputeMissingCorrectedRanges(
    List<CorrectionItem> corrections,
  ) {
    final needsRecompute = <CorrectionItem>[];
    for (final item in corrections) {
      final hasCorrectedRange =
          item.correctedStartIndex != null && item.correctedEndIndex != null;
      final hasOriginalRange = item.startIndex != null && item.endIndex != null;
      if (!hasCorrectedRange && hasOriginalRange) {
        needsRecompute.add(item);
      }
    }

    if (needsRecompute.isEmpty) {
      return corrections;
    }

    // Two duplicate corrections can carry identical startIndex/endIndex
    // values, so the surviving-vs-dropped distinction has to be tracked by
    // object identity, not by range value. resolveOverlappingCorrections
    // only filters/reorders its input (same instances survive), so identity
    // still lines up here; computeCorrectedRanges then rebuilds fresh
    // instances in that same order (it neither drops nor adds items), which
    // is why the two lists can be zipped positionally below.
    final deduped = resolveOverlappingCorrections(needsRecompute);
    final recomputed = computeCorrectedRanges(deduped);
    final recomputedByOriginal = <CorrectionItem, CorrectionItem>{
      for (var i = 0; i < deduped.length; i++) deduped[i]: recomputed[i],
    };
    final needsRecomputeSet = needsRecompute.toSet();

    final merged = <CorrectionItem>[];
    for (final item in corrections) {
      if (!needsRecomputeSet.contains(item)) {
        merged.add(item);
        continue;
      }
      final replacement = recomputedByOriginal[item];
      if (replacement != null) {
        merged.add(replacement);
      }
      // Otherwise this item was an overlapping duplicate that
      // resolveOverlappingCorrections dropped in favor of another item
      // covering the same span.
    }

    return merged;
  }

  factory CorrectionResponse.fromAnchoredJson(
    Map<String, Object?> json, {
    required String submittedText,
    bool allowLegacyCategories = true,
  }) {
    final rawCorrections = json['corrections'];
    final anchoredCorrections = rawCorrections is List
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
    // Duplicate/overlapping corrections (e.g. the model reporting the same
    // edit twice) must be resolved before corrected_text is built and before
    // the list is handed out — every downstream position (including the
    // corrected-side offset arithmetic) assumes each edit's length delta is
    // counted exactly once.
    final resolvedCorrections = resolveOverlappingCorrections(
      anchoredCorrections,
    );
    // corrected_text is always built from the submitted text plus the anchored
    // corrections, never taken from the model's own corrected_text — this is
    // the sole source of truth so the corrected-side text can never diverge
    // from what the app itself constructed.
    final correctedText = resolvedCorrections.isEmpty
        ? submittedText
        : _reconstructCorrectedText(submittedText, resolvedCorrections);
    // Corrected-side highlight ranges are computed by arithmetic against that
    // same code-built corrected_text (see computeCorrectedRanges), never
    // taken from the model — the schema no longer even asks for
    // corrected_start_index/corrected_end_index. The stored range and the
    // rendered corrected text share a single source and can no longer
    // decouple.
    final corrections = computeCorrectedRanges(
      resolvedCorrections,
      submittedText: submittedText,
    );

    return CorrectionResponse(
      originalText: submittedText,
      correctedText: correctedText,
      corrections: corrections,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'original_text': originalText,
      'corrected_text': correctedText,
      'corrections': corrections.map((item) => item.toJson()).toList(),
    };
  }

  /// [corrections] is processed rightmost edit first so earlier edits'
  /// indexes stay valid as the text is rewritten. A pure-deletion correction
  /// (empty `correctedPhrase`) additionally absorbs one adjacent whitespace
  /// character — the trailing character if it's a space, else the leading
  /// character if that's a space, else nothing — so removing a word doesn't
  /// leave a double space (or a leading/trailing stray space) behind. That
  /// absorption decision is always made against [originalCharacters], an
  /// untouched snapshot of [submittedText] kept separate from the list being
  /// mutated: consulting the in-progress (already-spliced) list instead
  /// could see a neighbour correction's edit rather than the real original
  /// character, since corrections at higher indexes are already applied by
  /// the time an earlier one is processed.
  static String _reconstructCorrectedText(
    String submittedText,
    List<CorrectionItem> corrections,
  ) {
    final originalCharacters = submittedText.characters.toList();
    final characters = [...originalCharacters];
    final sortedCorrections = [...corrections]
      ..sort((left, right) => right.startIndex!.compareTo(left.startIndex!));

    for (final correction in sortedCorrections) {
      final (start, end) = correction.correctedPhrase.isEmpty
          ? _deletionRangeAbsorbingWhitespace(
              originalCharacters,
              correction.startIndex!,
              correction.endIndex!,
            )
          : (correction.startIndex!, correction.endIndex!);
      characters.replaceRange(
        start,
        end,
        correction.correctedPhrase.characters,
      );
    }

    return characters.join();
  }

  /// Widens a pure-deletion correction's `[start, end)` span by one
  /// adjacent space in [originalCharacters] — see [_reconstructCorrectedText].
  static (int, int) _deletionRangeAbsorbingWhitespace(
    List<String> originalCharacters,
    int start,
    int end,
  ) {
    if (end < originalCharacters.length && originalCharacters[end] == ' ') {
      return (start, end + 1);
    }
    if (start > 0 && originalCharacters[start - 1] == ' ') {
      return (start - 1, end);
    }
    return (start, end);
  }
}
