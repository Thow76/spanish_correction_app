import 'package:characters/characters.dart';

import 'correction_item.dart';
import 'correction_overlap_resolver.dart';
import 'correction_response.dart';
import 'error_category.dart';
import 'naturalness_merge.dart';

/// Combines the first pass's own [CorrectionResponse] with a
/// [NaturalnessMergeResult] (issue #32) into one unified [CorrectionResponse]
/// — naturalness edits represented as ordinary [CorrectionItem]s alongside
/// the first pass's own corrections, so the existing correction UI, save,
/// and practice flows can consume a two-pass result exactly like a
/// single-pass one.
///
/// [CorrectionResponse.correctedText] on the result is
/// [NaturalnessMergeResult.finalCorrectedText] verbatim — already the
/// authoritative final text the merge component built by splicing
/// naturalness edits directly into the first pass's corrected text, not
/// recomputed here from the original text plus the combined correction
/// list. Recomputing it that way would require every naturalness-derived
/// item to carry a verified original-side position, which isn't always
/// possible (see below); relying on the already-correct string instead
/// means a failed lookup can only ever cost one correction's highlighting,
/// never the correctness of the text itself.
///
/// Each applied naturalness edit becomes a [CorrectionItem]:
/// - `category` is [ErrorCategory.naturalLanguage], not
///   [ErrorCategory.wordChoice] — despite issue #36's own tentative
///   suggestion of Word Choice, the *existing* categorization model that
///   issue asks to defer to (`stage2CategorizationSpanish` in
///   `correction_prompt.dart`) draws exactly this line: Word Choice is "a
///   single wrong or suboptimal word... fixing it means swapping one word
///   for another," while Natural Language is "a phrase or construction
///   that is unnatural, awkward, overly literal... fixing it means
///   restructuring a phrase, not swapping a single word." Naturalness
///   spans are calques/idioms/collocations —
///   `naturalnessReviewSpanish`'s own definition — squarely the Natural
///   Language case.
/// - `originalPhrase`/`correctedPhrase`/`shortExplanation` come directly
///   from the edit's `NaturalnessIssue`.
/// - `startIndex`/`endIndex` are populated only when the issue's `span`
///   can be found, unambiguously (exactly once), in
///   [firstPassResponse]'s own `originalText` — the same original text the
///   first pass's own corrections are anchored against, not the first
///   pass's *corrected* text, since a UI diffing original vs. corrected
///   text needs every correction anchored to the same original. Left null
///   otherwise ("preserve ranges for highlighting where possible" — the
///   app's existing substring-search highlight fallback already handles a
///   [CorrectionItem] with no precomputed range, the same as any other
///   unanchored correction; see `CorrectionItem.fromGradingJson`).
/// - `correctedStartIndex`/`correctedEndIndex` are always computable and
///   always computed: unlike the original-side lookup above, this one can
///   never fail to find anything — every entry in
///   [NaturalnessMergeResult.appliedEdits] already carries its own
///   verified `startIndex`/`endIndex` *within `firstPassCorrectedText`*,
///   the exact same coordinate space the first pass's own
///   `correctedStartIndex`/`correctedEndIndex` were computed in. Shifting
///   both edit sets into `finalCorrectedText`'s coordinate space is pure
///   arithmetic (see [_cumulativeNaturalnessDeltaBefore]), the same
///   cumulative-delta technique `computeCorrectedRanges` already uses for
///   the original-to-corrected shift, just applied a second time here for
///   the corrected-to-final shift.
///
/// The first pass's own corrections keep their `correctedStartIndex`/
/// `correctedEndIndex` too, but shifted by that same cumulative delta —
/// left unshifted, they would silently point at the wrong offsets in
/// `finalCorrectedText` the moment any naturalness edit lands earlier in
/// the text and changes length, since `firstPassCorrectedText` and
/// `finalCorrectedText` are no longer the same string.
///
/// The combined list (the first pass's own corrections, then the
/// naturalness ones just described) is deduplicated with
/// [resolveOverlappingCorrections] before being returned, in case a
/// naturalness span's independently-resolved original-text position
/// overlaps a first-pass correction's — first-pass corrections are listed
/// first, so they win any such tie.
///
/// Skipped naturalness edits ([NaturalnessMergeResult.skippedEdits]) are
/// not represented here at all — they were never applied to the text, so
/// presenting one as a correction would misrepresent what actually
/// changed.
CorrectionResponse mapNaturalnessEditsIntoCorrectionResponse({
  required CorrectionResponse firstPassResponse,
  required NaturalnessMergeResult naturalnessMerge,
}) {
  final originalGraphemes = firstPassResponse.originalText.characters
      .toList();
  final sortedEdits = [...naturalnessMerge.appliedEdits]
    ..sort((left, right) => left.startIndex.compareTo(right.startIndex));

  final naturalnessItems = [
    for (final edit in sortedEdits)
      _naturalnessEditToCorrectionItem(edit, sortedEdits, originalGraphemes),
  ];

  final shiftedFirstPassCorrections = [
    for (final item in firstPassResponse.corrections)
      _shiftCorrectedRange(item, sortedEdits),
  ];

  final combined = resolveOverlappingCorrections([
    ...shiftedFirstPassCorrections,
    ...naturalnessItems,
  ]);

  return CorrectionResponse(
    originalText: firstPassResponse.originalText,
    correctedText: naturalnessMerge.finalCorrectedText,
    corrections: combined,
    notes: firstPassResponse.notes,
  );
}

CorrectionItem _naturalnessEditToCorrectionItem(
  AppliedNaturalnessEdit edit,
  List<AppliedNaturalnessEdit> sortedEdits,
  List<String> originalGraphemes,
) {
  final range = _resolveUniqueSpan(originalGraphemes, edit.issue.span);
  final correctedStart =
      edit.startIndex +
      _cumulativeNaturalnessDeltaBefore(sortedEdits, edit.startIndex);
  final correctedEnd =
      correctedStart + edit.issue.naturalReplacement.characters.length;

  return CorrectionItem(
    originalPhrase: edit.issue.span,
    correctedPhrase: edit.issue.naturalReplacement,
    category: ErrorCategory.naturalLanguage,
    shortExplanation: edit.issue.explanation,
    startIndex: range?.$1,
    endIndex: range?.$2,
    correctedStartIndex: correctedStart,
    correctedEndIndex: correctedEnd,
  );
}

/// [item] with its `correctedStartIndex`/`correctedEndIndex` shifted by
/// every naturalness edit in [sortedEdits] that starts before it — both
/// live in `firstPassCorrectedText`'s coordinate space, so the shift moves
/// [item]'s existing corrected-side position into
/// `finalCorrectedText`'s coordinate space instead. Left unchanged (still
/// null) when [item] has no corrected-side position to shift.
CorrectionItem _shiftCorrectedRange(
  CorrectionItem item,
  List<AppliedNaturalnessEdit> sortedEdits,
) {
  final correctedStartIndex = item.correctedStartIndex;
  final correctedEndIndex = item.correctedEndIndex;
  if (correctedStartIndex == null || correctedEndIndex == null) {
    return item;
  }

  final shift = _cumulativeNaturalnessDeltaBefore(
    sortedEdits,
    correctedStartIndex,
  );
  if (shift == 0) {
    return item;
  }

  return CorrectionItem(
    originalPhrase: item.originalPhrase,
    correctedPhrase: item.correctedPhrase,
    category: item.category,
    shortExplanation: item.shortExplanation,
    startIndex: item.startIndex,
    endIndex: item.endIndex,
    correctedStartIndex: correctedStartIndex + shift,
    correctedEndIndex: correctedEndIndex + shift,
  );
}

/// Cumulative grapheme-length delta (`naturalReplacement.length -
/// (endIndex - startIndex)`) of every edit in [sortedEdits] — sorted
/// ascending by `startIndex`, both within `firstPassCorrectedText` — that
/// starts strictly before [position]. The same cumulative-shift technique
/// `computeCorrectedRanges` uses for the original-to-corrected shift,
/// applied here to the corrected-to-final shift instead.
int _cumulativeNaturalnessDeltaBefore(
  List<AppliedNaturalnessEdit> sortedEdits,
  int position,
) {
  var delta = 0;
  for (final edit in sortedEdits) {
    if (edit.startIndex >= position) {
      break;
    }
    delta +=
        edit.issue.naturalReplacement.characters.length -
        (edit.endIndex - edit.startIndex);
  }
  return delta;
}

/// [needle]'s `(start, end)` grapheme-cluster range in [haystack] when it
/// occurs exactly once, or null when it's missing or ambiguous — the same
/// "don't guess" precedent as `mergeNaturalnessReview`'s own span
/// resolution (issue #34).
(int, int)? _resolveUniqueSpan(List<String> haystack, String needle) {
  final needleGraphemes = needle.characters.toList();
  final matches = _findGraphemeMatches(haystack, needleGraphemes);
  if (matches.length != 1) {
    return null;
  }
  return (matches.single, matches.single + needleGraphemes.length);
}

/// Every grapheme-cluster-safe start position where [needle] occurs in
/// [haystack], left to right, including overlapping matches.
///
/// Copied by value from `CorrectionItem`'s private `_findGraphemeMatches`
/// (already copied more than once elsewhere in this codebase, e.g.
/// `naturalness_merge.dart`) — same established precedent of copying a
/// small pure helper by value rather than reaching into another file's
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
