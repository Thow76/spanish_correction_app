import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_overlap_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

CorrectionItem _item({
  required String original,
  required String corrected,
  required int start,
  required int end,
  ErrorCategory category = ErrorCategory.grammar,
}) {
  return CorrectionItem(
    originalPhrase: original,
    correctedPhrase: corrected,
    category: category,
    shortExplanation: 'because',
    startIndex: start,
    endIndex: end,
  );
}

void main() {
  test('keeps a single correction unchanged', () {
    final item = _item(original: 'para', corrected: 'a', start: 60, end: 64);

    final result = resolveOverlappingCorrections([item]);

    expect(result, [item]);
  });

  test(
    'ES-1-shaped duplicate: two identical-range corrections for the same '
    'edit collapse to one',
    () {
      // Mirrors the harness's ES-1-repeated-word bug: the model reports
      // "volví para casa" -> "volví a casa" as two separate correction
      // objects that anchor to the exact same range.
      final first = _item(original: 'para', corrected: 'a', start: 60, end: 64);
      final duplicate = _item(
        original: 'para',
        corrected: 'a',
        start: 60,
        end: 64,
        category: ErrorCategory.naturalLanguage,
      );

      final result = resolveOverlappingCorrections([first, duplicate]);

      expect(result, hasLength(1));
      expect(result.single, first);
    },
  );

  test('drops a later correction that partially overlaps an earlier one', () {
    final earlier = _item(original: 'trafico', corrected: 'tráfico', start: 10, end: 17);
    final overlapping = _item(original: 'fico y', corrected: 'fico e', start: 14, end: 20);

    final result = resolveOverlappingCorrections([earlier, overlapping]);

    expect(result, [earlier]);
  });

  test('keeps a later correction when the earlier one wins the overlap by start position, '
      'regardless of original list order', () {
    // The later-starting correction appears FIRST in the input list, but the
    // earlier-starting one must still win, since resolution is by position,
    // not input order.
    final startsAt20 = _item(original: 'b', corrected: 'B', start: 20, end: 21);
    final startsAt10 = _item(original: 'a', corrected: 'A', start: 10, end: 25);

    final result = resolveOverlappingCorrections([startsAt20, startsAt10]);

    expect(result, [startsAt10]);
  });

  test('keeps non-overlapping corrections in ascending start order', () {
    final second = _item(original: 'b', corrected: 'B', start: 20, end: 21);
    final first = _item(original: 'a', corrected: 'A', start: 5, end: 6);

    final result = resolveOverlappingCorrections([second, first]);

    expect(result, [first, second]);
  });

  test('adjacent, non-overlapping ranges (end == next start) are both kept', () {
    final first = _item(original: 'a', corrected: 'A', start: 0, end: 5);
    final second = _item(original: 'b', corrected: 'B', start: 5, end: 10);

    final result = resolveOverlappingCorrections([first, second]);

    expect(result, [first, second]);
  });

  test('two insertions at the exact same point collapse to one', () {
    final first = _item(original: '', corrected: '¿', start: 0, end: 0);
    final duplicate = _item(original: '', corrected: '¡', start: 0, end: 0);

    final result = resolveOverlappingCorrections([first, duplicate]);

    expect(result, [first]);
  });

  test('insertions at different points are both kept', () {
    final start = _item(original: '', corrected: '¿', start: 0, end: 0);
    final end = _item(original: '', corrected: '?', start: 10, end: 10);

    final result = resolveOverlappingCorrections([start, end]);

    expect(result, [start, end]);
  });

  test('an insertion strictly inside an existing range is dropped', () {
    final range = _item(original: 'hola', corrected: 'Hola', start: 0, end: 4);
    final insertionInside = _item(
      original: '',
      corrected: '-',
      start: 2,
      end: 2,
    );

    final result = resolveOverlappingCorrections([range, insertionInside]);

    expect(result, [range]);
  });

  test('an insertion at the exact boundary of a range is kept (not inside it)', () {
    final range = _item(original: 'hola', corrected: 'Hola', start: 0, end: 4);
    final insertionAtEnd = _item(original: '', corrected: '!', start: 4, end: 4);

    final result = resolveOverlappingCorrections([range, insertionAtEnd]);

    expect(result, [range, insertionAtEnd]);
  });

  test('corrections without a resolved range pass through untouched', () {
    final unranged = CorrectionItem(
      originalPhrase: 'a',
      correctedPhrase: 'A',
      category: ErrorCategory.other,
      shortExplanation: 'no range',
    );
    final ranged = _item(original: 'b', corrected: 'B', start: 0, end: 1);

    final result = resolveOverlappingCorrections([unranged, ranged]);

    expect(result, [ranged, unranged]);
  });

  test('empty input returns empty output', () {
    expect(resolveOverlappingCorrections(const []), isEmpty);
  });
}
