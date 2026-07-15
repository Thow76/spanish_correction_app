import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_corrected_range_calculator.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_overlap_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

CorrectionItem _item({
  required String original,
  required String corrected,
  required int start,
  required int end,
}) {
  return CorrectionItem(
    originalPhrase: original,
    correctedPhrase: corrected,
    category: ErrorCategory.grammar,
    shortExplanation: 'because',
    startIndex: start,
    endIndex: end,
  );
}

void main() {
  // Regression guard for the real production order:
  // `resolveOverlappingCorrections` MUST run before `computeCorrectedRanges`
  // ever sees the corrections list — the offset arithmetic assumes each
  // surviving correction's length delta is counted exactly once, which is
  // only true once overlaps have been resolved away. This test proves the
  // two functions are correct *chained*, not just independently correct in
  // isolation: it deliberately gives the dropped correction a length delta
  // that, if wrongly counted, would shift a later, unrelated correction's
  // computed corrected-side position to a detectably wrong value.
  test(
    'resolveOverlappingCorrections then computeCorrectedRanges: the '
    'overlap is resolved before the arithmetic ever sees it',
    () {
      // Same overlap shape validated in
      // correction_overlap_resolver_test.dart's "drops a later correction
      // that partially overlaps an earlier one" ([10,17) / [14,20)).
      final kept1 = _item(
        original: 'trafico', // 7 graphemes
        corrected: 'mal', // 3 graphemes -> delta -4
        start: 10,
        end: 17,
      );
      final droppedOverlap = _item(
        original: 'fico y', // 6 graphemes, overlaps kept1's [10,17)
        corrected: 'XXXXXXXXXX', // 10 graphemes -> delta +4, if wrongly
        // counted this would cancel out kept1's -4 delta and corrupt
        // everything computed after it.
        start: 14,
        end: 20,
      );
      final kept2 = _item(
        original: 'pan', // 3 graphemes, well clear of the overlap
        corrected: 'panes', // 5 graphemes -> delta +2
        start: 25,
        end: 28,
      );

      final resolved = resolveOverlappingCorrections([
        kept1,
        droppedOverlap,
        kept2,
      ]);

      // The overlap must already be gone before arithmetic runs.
      expect(resolved, hasLength(2));
      expect(resolved, [kept1, kept2]);

      final result = computeCorrectedRanges(resolved);

      expect(result, hasLength(2));
      // kept1: nothing to its left -> correctedStart == its own startIndex.
      expect(result[0].correctedStartIndex, 10);
      expect(result[0].correctedEndIndex, 13);
      // kept2: shifted ONLY by kept1's delta (-4), never by
      // droppedOverlap's (+4) — 25 + (-4) = 21. If droppedOverlap's delta
      // had leaked into the arithmetic (order reversed, or dedup skipped),
      // this would instead compute 25 (deltas cancelling) or 30 (both
      // deltas applied) — either way, not 21.
      expect(result[1].correctedStartIndex, 21);
      expect(result[1].correctedEndIndex, 26);
    },
  );
}
