import 'package:characters/characters.dart';

import 'correction_item.dart';

/// Computes each correction's position within the code-reconstructed
/// corrected text, by arithmetic — not by searching the corrected text.
///
/// The corrected text is code's own output (built by reconstructing the
/// original text with each correction's edit applied), so code already knows
/// exactly where every edit lands: each correction's corrected-side start is
/// its original-side `startIndex` shifted by the cumulative length delta
/// (`correctedPhrase.length - originalPhrase.length`, in grapheme clusters)
/// of every correction strictly to its left. No searching, no positional
/// hint, and no repeated-phrase disambiguation is needed or applicable here
/// — unlike `_anchorRange`, which locates an edit inside text it does not
/// control.
///
/// Preconditions: every [corrections] item must already be anchored (a
/// non-null `startIndex`/`endIndex`) and the list must already be
/// non-overlapping (see `resolveOverlappingCorrections` — this function does
/// not itself check for or resolve overlaps; overlapping input would double
/// count, or miscount, the shift at the overlap). The non-null part of this
/// precondition is enforced explicitly below (throws [ArgumentError]) rather
/// than left to fail as a bare force-unwrap crash; the non-overlapping part
/// is not re-verified here — that's `resolveOverlappingCorrections`'s job,
/// and callers are expected to run it first (see the chained pipeline test).
///
/// Returns a new list of [CorrectionItem]s, sorted ascending by `startIndex`,
/// each carrying its computed `correctedStartIndex`/`correctedEndIndex`
/// (all other fields copied unchanged). The input list is not mutated.
///
/// [submittedText], when supplied, is the untouched original text the
/// corrections are anchored against. It is only consulted for a pure-
/// deletion correction (empty `correctedPhrase`) — to check whether that
/// deletion also consumes one adjacent whitespace character, exactly as
/// `_reconstructCorrectedText` does when building the actual corrected text
/// (see its doc comment for why: deleting a word without its neighbouring
/// space leaves a double space behind). When a deletion does absorb a
/// space, the corrected text ends up one character shorter than the naive
/// `correctedPhrase.length - originalPhrase.length` delta predicts, so that
/// extra character must be counted here too — otherwise every correction
/// after such a deletion would get a `correctedStartIndex` one position too
/// high, which the corrected-panel highlighting
/// (`corrections_screen.dart`'s `requireExactRange: true`) would then
/// silently fail to match and drop. Omitting [submittedText] keeps the old,
/// non-absorbing arithmetic — safe for any caller that never produces
/// empty-`correctedPhrase` items.
///
/// Preconditions: every [corrections] item must already be anchored (a
/// non-null `startIndex`/`endIndex`) and the list must already be
/// non-overlapping (see `resolveOverlappingCorrections` — this function does
/// not itself check for or resolve overlaps; overlapping input would double
/// count, or miscount, the shift at the overlap). The non-null part of this
/// precondition is enforced explicitly below (throws [ArgumentError]) rather
/// than left to fail as a bare force-unwrap crash; the non-overlapping part
/// is not re-verified here — that's `resolveOverlappingCorrections`'s job,
/// and callers are expected to run it first (see the chained pipeline test).
List<CorrectionItem> computeCorrectedRanges(
  List<CorrectionItem> corrections, {
  String? submittedText,
}) {
  for (final item in corrections) {
    if (item.startIndex == null || item.endIndex == null) {
      throw ArgumentError.value(
        item,
        'corrections',
        'computeCorrectedRanges requires every correction to already be '
            'anchored (non-null startIndex/endIndex). This item has '
            'startIndex=${item.startIndex}, endIndex=${item.endIndex}. '
            'Unranged corrections carry no original-side position to shift '
            'from, so this function has nothing to compute for them — '
            'callers must filter them out (or never produce them) before '
            'calling this function.',
      );
    }
  }

  final originalCharacters = submittedText?.characters.toList();

  final sorted = [...corrections]
    ..sort((left, right) => left.startIndex!.compareTo(right.startIndex!));

  var cumulativeDelta = 0;
  final result = <CorrectionItem>[];
  for (final item in sorted) {
    final correctedStart = item.startIndex! + cumulativeDelta;
    final correctedPhraseLength = item.correctedPhrase.characters.length;
    final correctedEnd = correctedStart + correctedPhraseLength;

    result.add(
      CorrectionItem(
        originalPhrase: item.originalPhrase,
        correctedPhrase: item.correctedPhrase,
        category: item.category,
        shortExplanation: item.shortExplanation,
        startIndex: item.startIndex,
        endIndex: item.endIndex,
        correctedStartIndex: correctedStart,
        correctedEndIndex: correctedEnd,
      ),
    );

    final originalPhraseLength = item.originalPhrase.characters.length;
    var delta = correctedPhraseLength - originalPhraseLength;
    if (item.correctedPhrase.isEmpty &&
        originalCharacters != null &&
        _deletionAbsorbsAdjacentWhitespace(
          originalCharacters,
          item.startIndex!,
          item.endIndex!,
        )) {
      delta -= 1;
    }
    cumulativeDelta += delta;
  }

  return result;
}

/// Whether a pure-deletion correction spanning `[start, end)` in
/// [characters] (the untouched submitted text) has an adjacent space that
/// `_reconstructCorrectedText` will also remove: the trailing character
/// (right after the deleted span) if it's a space, else the leading
/// character (right before it) if that's a space — same preference order,
/// so this always agrees with what the text-splicing side actually does.
bool _deletionAbsorbsAdjacentWhitespace(
  List<String> characters,
  int start,
  int end,
) {
  if (end < characters.length && characters[end] == ' ') {
    return true;
  }
  return start > 0 && characters[start - 1] == ' ';
}
