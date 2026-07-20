import 'package:characters/characters.dart';

import 'correction_insertion_offset_calculator.dart';
import 'staged_correction_candidate.dart';

/// Finalizes each candidate's original-side span, given candidates that have
/// already been through [resolveCandidatePositions] and so carry a non-null
/// `startIndex`.
///
/// For each candidate, [calculateInsertionOffset] decides whether the
/// correction is a pure insertion — something purely added, nothing in
/// `originalPhrase` itself changed:
///   - If it is: the candidate's anchor (which may span more than just the
///     insertion point — e.g. a missing "que" is anchored to a longer
///     surrounding phrase) is narrowed down to the actual zero-length
///     insertion point, `originalPhrase` becomes `''`, and `correctedPhrase`
///     becomes only the inserted text — not the whole corrected phrase.
///   - If it isn't (an ordinary swap, or a `dialectal`/`not_an_error`
///     candidate with no textual change at all): the candidate's `startIndex`
///     and phrases are left as they are, and `endIndex` is computed as the
///     normal anchored span, `startIndex + originalPhrase`'s grapheme length.
List<StagedCorrectionCandidate> resolveInsertionOffsets(
  List<StagedCorrectionCandidate> candidates,
) {
  return candidates.map((candidate) {
    final resolvedStart = candidate.startIndex!;
    final insertion = calculateInsertionOffset(
      originalPhrase: candidate.originalPhrase,
      correctedPhrase: candidate.correctedPhrase,
    );

    if (insertion == null) {
      final endIndex =
          resolvedStart + candidate.originalPhrase.characters.length;
      return candidate.copyWith(endIndex: endIndex);
    }

    final insertionPoint = resolvedStart + insertion.offset;
    return candidate.copyWith(
      originalPhrase: '',
      correctedPhrase: insertion.insertedText,
      startIndex: insertionPoint,
      endIndex: insertionPoint,
    );
  }).toList();
}
