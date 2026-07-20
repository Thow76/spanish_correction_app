import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_candidate.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_overlap_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  StagedCorrectionCandidate ranged({
    required String originalPhrase,
    required int startIndex,
    required int endIndex,
  }) {
    return StagedCorrectionCandidate(
      originalPhrase: originalPhrase,
      correctedPhrase: 'x',
      occurrence: 1,
      category: 'Grammar',
      verdict: StagedCorrectionVerdict.error,
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }

  test(
    'a narrower span starting LATER survives over a wider span starting '
    'EARLIER, when they overlap — the case the old earliest-start tie-break '
    'would get wrong',
    () {
      // Wide span [0, 20) starts first; narrow span [8, 10) starts later
      // but is fully contained within it. Earliest-start-wins (the old
      // resolveOverlappingCorrections tie-break) would keep the wide one;
      // narrowest-wins must keep the narrow one instead.
      final wide = ranged(originalPhrase: 'quiero que tú vengas', startIndex: 0, endIndex: 20);
      final narrow = ranged(originalPhrase: 'tú', startIndex: 8, endIndex: 10);

      final resolved = resolveOverlappingCandidates([wide, narrow]);

      expect(resolved, hasLength(1));
      expect(resolved.single, same(narrow));
    },
  );

  test(
    'the same outcome holds regardless of which one appears first in the '
    'input list',
    () {
      final wide = ranged(originalPhrase: 'quiero que tú vengas', startIndex: 0, endIndex: 20);
      final narrow = ranged(originalPhrase: 'tú', startIndex: 8, endIndex: 10);

      final resolved = resolveOverlappingCandidates([narrow, wide]);

      expect(resolved, hasLength(1));
      expect(resolved.single, same(narrow));
    },
  );

  test(
    'models the real Stage 1 / Stage 1B scenario: a whole-clause anchor '
    'and a narrower redundant-pronoun anchor overlapping',
    () {
      final stage1Wide = ranged(
        originalPhrase: 'yo fui y yo comí',
        startIndex: 0,
        endIndex: 16,
      );
      final stage1bNarrow = ranged(originalPhrase: 'yo', startIndex: 9, endIndex: 11);

      final resolved = resolveOverlappingCandidates([stage1Wide, stage1bNarrow]);

      expect(resolved, hasLength(1));
      expect(resolved.single, same(stage1bNarrow));
    },
  );

  test('equal-width overlapping candidates fall back to earliest start', () {
    final earlier = ranged(originalPhrase: 'ab', startIndex: 0, endIndex: 2);
    final later = ranged(originalPhrase: 'bc', startIndex: 1, endIndex: 3);

    final resolved = resolveOverlappingCandidates([later, earlier]);

    expect(resolved, hasLength(1));
    expect(resolved.single, same(earlier));
  });

  test(
    'equal-width, equal-start candidates fall back to original list order',
    () {
      final first = ranged(originalPhrase: 'a', startIndex: 0, endIndex: 2);
      final second = ranged(originalPhrase: 'b', startIndex: 0, endIndex: 2);

      final resolved = resolveOverlappingCandidates([first, second]);

      expect(resolved, hasLength(1));
      expect(resolved.single, same(first));
    },
  );

  test('non-overlapping candidates all survive, sorted by startIndex', () {
    final second = ranged(originalPhrase: 'b', startIndex: 10, endIndex: 12);
    final first = ranged(originalPhrase: 'a', startIndex: 0, endIndex: 2);

    final resolved = resolveOverlappingCandidates([second, first]);

    expect(resolved, [first, second]);
  });

  test('two zero-length insertions at the same point overlap; one survives', () {
    final a = ranged(originalPhrase: '', startIndex: 5, endIndex: 5);
    final b = ranged(originalPhrase: '', startIndex: 5, endIndex: 5);

    final resolved = resolveOverlappingCandidates([a, b]);

    expect(resolved, hasLength(1));
  });

  test(
    'an insertion point falling strictly inside a wider range overlaps it, '
    'and — being narrower (zero-width) — survives',
    () {
      final wideRange = ranged(originalPhrase: 'trafico', startIndex: 5, endIndex: 12);
      final insertion = ranged(originalPhrase: '', startIndex: 8, endIndex: 8);

      final resolved = resolveOverlappingCandidates([wideRange, insertion]);

      expect(resolved, hasLength(1));
      expect(resolved.single, same(insertion));
    },
  );

  test(
    'an insertion point exactly at the edge of a range does not overlap it '
    '(half-open range semantics)',
    () {
      final range = ranged(originalPhrase: 'trafico', startIndex: 5, endIndex: 12);
      final insertionAtEnd = ranged(originalPhrase: '', startIndex: 12, endIndex: 12);

      final resolved = resolveOverlappingCandidates([range, insertionAtEnd]);

      expect(resolved, hasLength(2));
    },
  );

  test('resolves a three-way overlap chain, keeping only the narrowest', () {
    final wide = ranged(originalPhrase: 'abcdefghij', startIndex: 0, endIndex: 10);
    final medium = ranged(originalPhrase: 'cdefg', startIndex: 2, endIndex: 7);
    final narrow = ranged(originalPhrase: 'de', startIndex: 3, endIndex: 5);

    final resolved = resolveOverlappingCandidates([wide, medium, narrow]);

    expect(resolved, hasLength(1));
    expect(resolved.single, same(narrow));
  });

  test('an empty input returns an empty result', () {
    expect(resolveOverlappingCandidates(const []), isEmpty);
  });
}
