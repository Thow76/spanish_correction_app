import 'package:characters/characters.dart';

/// Result of trimming the shared leading/trailing grapheme clusters off a
/// correction's `originalPhrase`/`correctedPhrase` pair — see
/// [calculateSharedAffixTrim].
class SharedAffixTrim {
  const SharedAffixTrim({
    required this.prefixLength,
    required this.suffixLength,
    required this.trimmedOriginalPhrase,
    required this.trimmedCorrectedPhrase,
  });

  /// Grapheme-cluster length of the shared leading text removed from both
  /// phrases. Add this to a resolved `startIndex` to get the trimmed span's
  /// start.
  final int prefixLength;

  /// Grapheme-cluster length of the shared trailing text removed from both
  /// phrases. Subtract this from a resolved `endIndex` to get the trimmed
  /// span's end.
  final int suffixLength;

  /// `originalPhrase` with the shared prefix and suffix removed.
  final String trimmedOriginalPhrase;

  /// `correctedPhrase` with the shared prefix and suffix removed.
  final String trimmedCorrectedPhrase;
}

/// Finds the longest common grapheme-cluster prefix and suffix shared by
/// [originalPhrase] and [correctedPhrase], and returns both phrases with
/// that shared text trimmed off both ends.
///
/// This is [calculateInsertionOffset]'s own prefix/suffix walk
/// (`correction_insertion_offset_calculator.dart`), generalized: that
/// function only reports a result when the prefix and suffix together
/// cover every grapheme of [originalPhrase] (a pure insertion). This
/// function has no such gate — it fires on *partial* coverage too, which is
/// the case a swap-type correction (e.g. "¿Puedo tener una cerveza?" ->
/// "¿Me da una cerveza?", where "Puedo tener"/"Me da" is the actual swap and
/// " una cerveza?" is unchanged context the model over-quoted around it)
/// needs — [calculateInsertionOffset] itself always returns null for that
/// shape, since the middle of the phrase changed rather than just having
/// something inserted.
///
/// Always returns a non-null result, unlike [calculateInsertionOffset]:
/// when nothing is shared at either end, [prefixLength] and [suffixLength]
/// are both 0 and the trimmed phrases equal the inputs unchanged — a no-op,
/// not a signal to fall back to something else. Trimming is symmetric: the
/// same shared substring is removed from both phrases, so the two phrases'
/// length delta (`correctedPhrase.length - originalPhrase.length`) is
/// unchanged by trimming — a caller that shifts a resolved span by
/// `startIndex + prefixLength` / `endIndex - suffixLength` keeps that span
/// consistent with `computeCorrectedRanges`'s own delta arithmetic
/// (`correction_corrected_range_calculator.dart`).
///
/// Same overlap-capping guard as [calculateInsertionOffset]
/// (`maxSuffixLength = maxPrefixLength - prefixLength`), for the same
/// reason: without it, a phrase with internal repetition (e.g.
/// `"tengo tengo"` -> `"tengo"`) would let the prefix and suffix walks
/// independently match the same trailing "tengo" from both ends, double-
/// claiming graphemes the prefix already consumed and producing a
/// nonsensical (or, on the shorter side, out-of-range) trimmed result.
/// Capping means the suffix walk only ever spends what the prefix walk left
/// in the budget, so `prefixLength + suffixLength` never exceeds the
/// shorter of the two phrases' lengths.
///
/// Purely textual — this function does not know about, and does not touch,
/// any resolved `startIndex`/`endIndex`. Not wired into the pipeline yet:
/// nothing calls this outside its own unit tests.
SharedAffixTrim calculateSharedAffixTrim({
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

  return SharedAffixTrim(
    prefixLength: prefixLength,
    suffixLength: suffixLength,
    trimmedOriginalPhrase: originalGraphemes
        .sublist(prefixLength, originalLength - suffixLength)
        .join(),
    trimmedCorrectedPhrase: correctedGraphemes
        .sublist(prefixLength, correctedLength - suffixLength)
        .join(),
  );
}
