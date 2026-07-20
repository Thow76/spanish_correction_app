import 'package:characters/characters.dart';

/// One Stage 2 correction (`stage2CategorizationSpanish` in
/// `correction_prompt.dart`) awaiting its original-side position, or —
/// once [resolveOccurrenceCorrections] has run — already carrying it.
///
/// Deliberately not `CorrectionItem`: Stage 2's output supplies
/// `original_phrase`, `corrected_phrase`, `occurrence`, `category`, and
/// `verdict`, but no `short_explanation` (that's Stage 3's job, which runs
/// after this) and no resolved position yet. Forcing this shape into
/// `CorrectionItem` would mean faking a `shortExplanation` that doesn't
/// exist at this pipeline stage. This type carries only what
/// [resolveOccurrenceCorrections] itself needs; merging the resolved
/// `startIndex` into a richer type once Stage 3 has run is later wiring
/// work, not this session's.
class OccurrenceCorrection {
  const OccurrenceCorrection({
    required this.originalPhrase,
    required this.occurrence,
    this.startIndex,
  });

  /// The exact substring Stage 2 flagged, to be located in the original
  /// submitted text.
  final String originalPhrase;

  /// Which instance of [originalPhrase] this is, 1-based, left to right —
  /// Stage 2's own disambiguator for a phrase that appears more than once
  /// (e.g. the second "para" in a text where it appears three times).
  final int occurrence;

  /// Resolved grapheme-cluster start position within the original text, or
  /// null before resolution.
  final int? startIndex;

  OccurrenceCorrection _withStartIndex(int value) {
    return OccurrenceCorrection(
      originalPhrase: originalPhrase,
      occurrence: occurrence,
      startIndex: value,
    );
  }
}

/// Resolves each correction's `occurrence` into a concrete grapheme-cluster
/// `startIndex` by searching [originalText] — the piece the "Positioning"
/// doc section describes for turning Stage 2's `occurrence` count into a
/// real index, now that Stage 2 no longer receives or reports character
/// positions itself.
///
/// For each correction, every grapheme-cluster-safe exact match of
/// `originalPhrase` in [originalText] is found (left to right, including
/// overlapping matches, same as `CorrectionItem`'s internal
/// `_findGraphemeMatches`), and the match at index `occurrence - 1` is
/// taken as the resolved `startIndex`. Each correction is resolved against
/// a fresh full search of [originalText] — there is no shared cursor state
/// between corrections, and result order therefore does not depend on
/// processing order, since `occurrence` already disambiguates each
/// correction on its own.
///
/// A correction is dropped (omitted from the result, no exception) when
/// `originalPhrase` has fewer than `occurrence` matches in [originalText]
/// — including zero matches. This mirrors the existing precedent in
/// `CorrectionItem._anchorRange`/`tryFromAnchoredJson`: a correction that
/// cannot be verified against the source text is silently discarded rather
/// than surfaced as an error, since a model claim that doesn't check out
/// against the text it was supposedly reading is not information the app
/// can safely act on.
///
/// The input list is not mutated; a new list (only the resolvable
/// corrections, each carrying its resolved `startIndex`) is returned.
List<OccurrenceCorrection> resolveOccurrenceCorrections(
  String originalText,
  List<OccurrenceCorrection> corrections,
) {
  final textGraphemes = originalText.characters.toList();
  final result = <OccurrenceCorrection>[];

  for (final correction in corrections) {
    final phraseGraphemes = correction.originalPhrase.characters.toList();
    final matches = _findGraphemeMatches(textGraphemes, phraseGraphemes);
    final matchIndex = correction.occurrence - 1;
    if (matchIndex < 0 || matchIndex >= matches.length) {
      continue;
    }
    result.add(correction._withStartIndex(matches[matchIndex]));
  }

  return result;
}

/// Every grapheme-cluster-safe start position where [needle] occurs in
/// [haystack], left to right, including overlapping matches.
///
/// Copied by value from `CorrectionItem`'s private `_findGraphemeMatches`
/// rather than shared/extracted: that helper is private to
/// `correction_item.dart`, and this session's boundary condition is
/// additive-only (new files only, no edits to existing domain files) —
/// consistent with how every test harness in this repo already copies
/// small pure helpers by value instead of reaching into another file's
/// private implementation.
List<int> _findGraphemeMatches(List<String> haystack, List<String> needle) {
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
