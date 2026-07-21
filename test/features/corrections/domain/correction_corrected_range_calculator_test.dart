import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_corrected_range_calculator.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
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
  test('empty corrections list returns empty list', () {
    expect(computeCorrectedRanges(const []), isEmpty);
  });

  test('single correction: correctedStart equals original start (nothing to its left)', () {
    // "Café bien" -> "Café bueno"; "bien" (4 chars) at 5..9 -> "bueno" (5 chars).
    final item = _item(original: 'bien', corrected: 'bueno', start: 5, end: 9);

    final result = computeCorrectedRanges([item]);

    expect(result, hasLength(1));
    expect(result.single.correctedStartIndex, 5);
    expect(result.single.correctedEndIndex, 10);
  });

  test(
    'shortening edit: a later correction shifts left by the earlier '
    'correction\'s negative delta',
    () {
      // "AAAA BBBB CCCC": correction1 "AAAA"(4)->"A"(1) at 0..4 (delta -3);
      // correction2 "CCCC"(4)->"CCCCCC"(6) at 10..14 (delta +2, lengthening).
      // correction2's correctedStart must be shifted by correction1's -3
      // delta only (nothing else is to its left): 10 + (-3) = 7.
      final shortening = _item(
        original: 'AAAA',
        corrected: 'A',
        start: 0,
        end: 4,
      );
      final lengthening = _item(
        original: 'CCCC',
        corrected: 'CCCCCC',
        start: 10,
        end: 14,
      );

      final result = computeCorrectedRanges([shortening, lengthening]);

      expect(result, hasLength(2));
      expect(result[0].correctedStartIndex, 0);
      expect(result[0].correctedEndIndex, 1);
      expect(result[1].correctedStartIndex, 7);
      expect(result[1].correctedEndIndex, 13);
    },
  );

  test(
    'multiple corrections: cumulative shift compounds across three edits, '
    'regardless of input order',
    () {
      // "trafico y volvi para casa para siempre":
      // c1: "trafico"(7) -> "tráfico"(7) at 0..7 (delta 0, same length).
      // c2: "para casa"(9) -> "a casa"(6) at 17..26 (delta -3, shortening).
      // c3: "siempre"(7) -> "para siempre"(12) at 31..38 (delta +5, lengthening).
      // Passed out of order to confirm internal sorting.
      final c1 = _item(
        original: 'trafico',
        corrected: 'tráfico',
        start: 0,
        end: 7,
      );
      final c2 = _item(
        original: 'para casa',
        corrected: 'a casa',
        start: 17,
        end: 26,
      );
      final c3 = _item(
        original: 'siempre',
        corrected: 'para siempre',
        start: 31,
        end: 38,
      );

      final result = computeCorrectedRanges([c3, c1, c2]);

      expect(result, hasLength(3));
      // c1: nothing to its left.
      expect(result[0].correctedStartIndex, 0);
      expect(result[0].correctedEndIndex, 7);
      // c2: shifted by c1's delta (0): 17 + 0 = 17.
      expect(result[1].correctedStartIndex, 17);
      expect(result[1].correctedEndIndex, 23);
      // c3: shifted by c1's + c2's cumulative delta (0 + -3 = -3): 31 - 3 = 28.
      expect(result[2].correctedStartIndex, 28);
      expect(result[2].correctedEndIndex, 40);
    },
  );

  test('zero-length insertion: delta is correctedPhrase.length - 0', () {
    // Insertion of an opening question mark at position 0 (empty
    // original_phrase), followed by a later correction that must be shifted
    // right by the insertion's delta.
    final invertedQuestionMark = String.fromCharCode(0xBF); // U+00BF '¿'
    final insertion = _item(
      original: '',
      corrected: invertedQuestionMark,
      start: 0,
      end: 0,
    );
    // Same-length replacement (delta 0) so the only shift in play is the
    // insertion's.
    final later = _item(original: 'b', corrected: 'B', start: 5, end: 6);

    final result = computeCorrectedRanges([insertion, later]);

    expect(result, hasLength(2));
    expect(result[0].correctedStartIndex, 0);
    expect(result[0].correctedEndIndex, 1);
    // later's correctedStart is shifted right by 1 (the inserted mark).
    expect(result[1].correctedStartIndex, 6);
    expect(result[1].correctedEndIndex, 7);
  });

  test(
    'grapheme clusters are counted, not UTF-16 code units '
    '(combining accent vs. precomposed character)',
    () {
      // Base "e" + combining acute accent (U+0301) is ONE grapheme cluster
      // but TWO UTF-16 code units (String.length == 2). Built via explicit
      // char codes so the exact codepoints are unambiguous. A precomposed
      // accented "e" (U+00E9) would not exercise the bug this test guards
      // against: it is already a single UTF-16 code unit, so .length and
      // .characters.length would agree. If .length were used instead of
      // .characters.length, this correction's delta would be wrong (1
      // instead of 0).
      final combiningE =
          String.fromCharCode(0x65) + String.fromCharCode(0x0301);
      expect(combiningE.length, 2, reason: 'two UTF-16 code units');
      expect(
        combiningE.characters.length,
        1,
        reason: 'one grapheme cluster',
      );

      final combining = _item(
        original: 'e',
        corrected: combiningE,
        start: 0,
        end: 1,
      );
      final later = _item(original: 'b', corrected: 'B', start: 1, end: 2);

      final result = computeCorrectedRanges([combining, later]);

      // delta = 1 grapheme (combiningE) - 1 grapheme ("e") = 0, not
      // 2 code units - 1 code unit = 1.
      expect(result[0].correctedStartIndex, 0);
      expect(result[0].correctedEndIndex, 1);
      expect(result[1].correctedStartIndex, 1);
      expect(result[1].correctedEndIndex, 2);
    },
  );

  test('all other CorrectionItem fields are preserved unchanged', () {
    final item = _item(
      original: 'trafico',
      corrected: 'tráfico',
      start: 0,
      end: 7,
      category: ErrorCategory.spelling,
    );

    final result = computeCorrectedRanges([item]).single;

    expect(result.originalPhrase, item.originalPhrase);
    expect(result.correctedPhrase, item.correctedPhrase);
    expect(result.category, item.category);
    expect(result.shortExplanation, item.shortExplanation);
    expect(result.startIndex, item.startIndex);
    expect(result.endIndex, item.endIndex);
  });

  test(
    'throws a clear ArgumentError (not a bare force-unwrap crash) when '
    'given an unranged correction',
    () {
      // Nothing in the current pipeline produces an unranged item by the
      // time it reaches this function, but the precondition must fail loudly
      // and specifically if that ever changes, not with a generic
      // "Null check operator used on a null value" crash.
      final unranged = CorrectionItem(
        originalPhrase: 'a',
        correctedPhrase: 'A',
        category: ErrorCategory.other,
        shortExplanation: 'no range',
      );

      expect(
        () => computeCorrectedRanges([unranged]),
        throwsA(isA<ArgumentError>()),
      );
    },
  );

  test(
    'throws ArgumentError for an unranged item even when other items in '
    'the list are properly anchored',
    () {
      final ranged = _item(original: 'a', corrected: 'A', start: 0, end: 1);
      final unranged = CorrectionItem(
        originalPhrase: 'b',
        correctedPhrase: 'B',
        category: ErrorCategory.other,
        shortExplanation: 'no range',
      );

      expect(
        () => computeCorrectedRanges([ranged, unranged]),
        throwsA(isA<ArgumentError>()),
      );
    },
  );

  group('pure-deletion corrections absorb one adjacent whitespace', () {
    test(
      'a later correction is shifted by the deletion\'s word length PLUS '
      'the absorbed trailing space, when submittedText is supplied',
      () {
        // "AAAA BBBB CCCC": "AAAA" (4 graphemes) deleted at 0..4, trailing
        // space at index 4 absorbed -> corrected text is "BBBB CCCC", 5
        // characters shorter than "AAAA BBBB CCCC", not 4.
        const text = 'AAAA BBBB CCCC';
        final deletion = _item(original: 'AAAA', corrected: '', start: 0, end: 4);
        final later = _item(original: 'CCCC', corrected: 'X', start: 10, end: 14);

        final result = computeCorrectedRanges(
          [deletion, later],
          submittedText: text,
        );

        expect(result[0].correctedStartIndex, 0);
        expect(result[0].correctedEndIndex, 0);
        // Naive delta would be -4 (10 - 4 = 6); with the absorbed space it's
        // -5 (10 - 5 = 5).
        expect(result[1].correctedStartIndex, 5);
        expect(result[1].correctedEndIndex, 6);
      },
    );

    test(
      'falls back to leading-space absorption when there is no trailing '
      'space to absorb (deletion directly followed by punctuation)',
      () {
        // "AAAA BBBB, CCCC": "BBBB" (5..9) is directly followed by ',' (no
        // trailing space), so it falls back to its leading space (index 4).
        // Absorbing that widens the removed span to " BBBB" (5 characters),
        // not just "BBBB" (4) -> the later correction shifts by 5.
        const text = 'AAAA BBBB, CCCC';
        final deletion = _item(
          original: 'BBBB',
          corrected: '',
          start: 5,
          end: 9,
        );
        final later = _item(
          original: 'CCCC',
          corrected: 'X',
          start: 11,
          end: 15,
        );

        final result = computeCorrectedRanges(
          [deletion, later],
          submittedText: text,
        );

        // Own range is unaffected (still empty at its own corrected start,
        // which is unchanged since nothing to its own left moved).
        expect(result[0].correctedStartIndex, 5);
        expect(result[0].correctedEndIndex, 5);
        // Naive delta would be -4 (11 - 4 = 7); with the absorbed leading
        // space it's -5 (11 - 5 = 6).
        expect(result[1].correctedStartIndex, 6);
      },
    );

    test(
      'no absorption when the deletion has no adjacent space at all '
      '(sits at index 0 directly before punctuation)',
      () {
        const text = 'AAAA,BBBB';
        final deletion = _item(
          original: 'AAAA',
          corrected: '',
          start: 0,
          end: 4,
        );
        final later = _item(original: 'BBBB', corrected: 'X', start: 5, end: 9);

        final result = computeCorrectedRanges(
          [deletion, later],
          submittedText: text,
        );

        // Naive delta (-4) applies unchanged: nothing adjacent to absorb.
        expect(result[1].correctedStartIndex, 1);
      },
    );

    test(
      'multiple deletions in the same call each resolve their own '
      'absorption independently and compound correctly',
      () {
        // "AAAA BBBB CCCC DDDD": "AAAA" and "CCCC" both deleted, each with a
        // trailing space to absorb (5 characters removed each), "DDDD"
        // survives and must shift left by 10 (5 + 5), not 8 (4 + 4).
        const text = 'AAAA BBBB CCCC DDDD';
        final firstDeletion = _item(
          original: 'AAAA',
          corrected: '',
          start: 0,
          end: 4,
        );
        final secondDeletion = _item(
          original: 'CCCC',
          corrected: '',
          start: 10,
          end: 14,
        );
        final later = _item(
          original: 'DDDD',
          corrected: 'X',
          start: 15,
          end: 19,
        );

        final result = computeCorrectedRanges(
          [firstDeletion, secondDeletion, later],
          submittedText: text,
        );

        expect(result[2].correctedStartIndex, 5);
      },
    );

    test(
      'without submittedText, absorption is skipped and the naive delta is '
      'used (backward-compatible default)',
      () {
        final deletion = _item(original: 'AAAA', corrected: '', start: 0, end: 4);
        final later = _item(original: 'CCCC', corrected: 'X', start: 10, end: 14);

        final result = computeCorrectedRanges([deletion, later]);

        expect(result[1].correctedStartIndex, 6);
      },
    );

    test(
      'a swap-type (non-empty correctedPhrase) correction is completely '
      'unaffected by submittedText being supplied',
      () {
        final item = _item(
          original: 'para',
          corrected: 'a',
          start: 10,
          end: 14,
        );
        final later = _item(original: 'b', corrected: 'B', start: 20, end: 21);

        final withText = computeCorrectedRanges(
          [item, later],
          submittedText: 'volví para casa para siempre.',
        );
        final withoutText = computeCorrectedRanges([item, later]);

        expect(withText[0].correctedStartIndex, withoutText[0].correctedStartIndex);
        expect(withText[1].correctedStartIndex, withoutText[1].correctedStartIndex);
        expect(withText[1].correctedStartIndex, 17);
      },
    );
  });
}
