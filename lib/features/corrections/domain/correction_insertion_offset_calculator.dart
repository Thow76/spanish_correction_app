import 'package:characters/characters.dart';

/// Where, within an anchor's `originalPhrase`, a pure insertion lands —
/// see [calculateInsertionOffset].
class InsertionOffset {
  const InsertionOffset({required this.offset, required this.insertedText});

  /// Grapheme-cluster offset, relative to the start of `originalPhrase`,
  /// at which [insertedText] should be inserted.
  final int offset;

  /// The text present in `correctedPhrase` but not in `originalPhrase`.
  final String insertedText;
}

/// Determines whether `correctedPhrase` is `originalPhrase` with something
/// purely added (nothing removed or changed), and if so, where.
///
/// This is the piece the "Positioning" doc section describes for the
/// omission case: an anchor covers the point in the original text where
/// something is missing, but the insertion point for the corrected text
/// isn't necessarily the very start of the anchor (e.g. a missing "¿" goes
/// before the anchor's first character, but a missing "que" goes after
/// "Creo " and before "está bien" within a longer anchor). Locating that
/// relative offset is this function's only job; swap-type corrections
/// (where `originalPhrase` itself is also changed) don't need or use this
/// function's output and always resolve to null here.
///
/// Algorithm: the longest common grapheme-cluster prefix and the longest
/// common grapheme-cluster suffix between [originalPhrase] and
/// [correctedPhrase] are found (the suffix search is capped so it cannot
/// re-consume graphemes already claimed by the prefix, which matters when
/// one phrase is a substring of the other). If together they account for
/// the whole of [originalPhrase] — i.e. `prefixLength + suffixLength >=
/// originalPhrase`'s grapheme length — then every grapheme in
/// [originalPhrase] is matched by the prefix or the suffix, meaning nothing
/// in it was changed or removed and [correctedPhrase] only has new content
/// spliced in between: a pure insertion. [offset] is the prefix length;
/// [insertedText] is the middle segment of [correctedPhrase] between the
/// prefix and the suffix.
///
/// Two cases return null (not a pure insertion) rather than guessing:
///   - The prefix+suffix match does not account for all of
///     [originalPhrase] — some grapheme inside it was itself changed or
///     removed, i.e. a normal swap-type correction (e.g. "trafico" ->
///     "tráfico": same length, but the changed character isn't a pure
///     insertion).
///   - [originalPhrase] and [correctedPhrase] are identical (or the
///     "insertion" would be empty) — a `not_an_error`/`dialectal`
///     correction with no substitution has nothing to insert.
InsertionOffset? calculateInsertionOffset({
  required String originalPhrase,
  required String correctedPhrase,
}) {
  final originalGraphemes = originalPhrase.characters.toList();
  final correctedGraphemes = correctedPhrase.characters.toList();
  final originalLength = originalGraphemes.length;
  final correctedLength = correctedGraphemes.length;

  final maxPrefixLength = originalLength < correctedLength ? originalLength : correctedLength;
  var prefixLength = 0;
  while (prefixLength < maxPrefixLength &&
      originalGraphemes[prefixLength] == correctedGraphemes[prefixLength]) {
    prefixLength++;
  }

  final maxSuffixLength = maxPrefixLength - prefixLength;
  var suffixLength = 0;
  while (suffixLength < maxSuffixLength &&
      originalGraphemes[originalLength - 1 - suffixLength] ==
          correctedGraphemes[correctedLength - 1 - suffixLength]) {
    suffixLength++;
  }

  if (prefixLength + suffixLength < originalLength) {
    return null;
  }

  final insertedText = correctedGraphemes
      .sublist(prefixLength, correctedLength - suffixLength)
      .join();
  if (insertedText.isEmpty) {
    return null;
  }

  return InsertionOffset(offset: prefixLength, insertedText: insertedText);
}
