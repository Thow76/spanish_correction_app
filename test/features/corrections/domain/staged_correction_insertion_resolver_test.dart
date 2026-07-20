import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_candidate.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_insertion_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  StagedCorrectionCandidate positioned({
    required String originalPhrase,
    required String correctedPhrase,
    required int startIndex,
    String? category = 'Grammar',
    StagedCorrectionVerdict verdict = StagedCorrectionVerdict.error,
  }) {
    return StagedCorrectionCandidate(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      occurrence: 1,
      category: category,
      verdict: verdict,
      startIndex: startIndex,
    );
  }

  test(
    'narrows an insertion at the start of the anchor to a zero-length '
    'insertion point',
    () {
      final resolved = resolveInsertionOffsets([
        positioned(
          originalPhrase: 'Cómo estás',
          correctedPhrase: '¿Cómo estás',
          startIndex: 5,
        ),
      ]);

      final result = resolved.single;
      expect(result.originalPhrase, isEmpty);
      expect(result.correctedPhrase, '¿');
      expect(result.startIndex, 5);
      expect(result.endIndex, 5);
    },
  );

  test('narrows a mid-anchor insertion to its actual offset', () {
    final resolved = resolveInsertionOffsets([
      positioned(originalPhrase: 'ab', correctedPhrase: 'aXb', startIndex: 5),
    ]);

    final result = resolved.single;
    expect(result.originalPhrase, isEmpty);
    expect(result.correctedPhrase, 'X');
    expect(result.startIndex, 6);
    expect(result.endIndex, 6);
  });

  test(
    'leaves an ordinary swap-type correction as its normal anchored span',
    () {
      // Same example the calculator's own docstring cites: same length, but
      // the changed character isn't a pure insertion.
      final resolved = resolveInsertionOffsets([
        positioned(
          originalPhrase: 'trafico',
          correctedPhrase: 'tráfico',
          startIndex: 9,
        ),
      ]);

      final result = resolved.single;
      expect(result.originalPhrase, 'trafico');
      expect(result.correctedPhrase, 'tráfico');
      expect(result.startIndex, 9);
      expect(result.endIndex, 16);
    },
  );

  test(
    'computes a normal anchored span for a dialectal/not_an_error candidate '
    'with no textual change',
    () {
      final resolved = resolveInsertionOffsets([
        positioned(
          originalPhrase: 'coche',
          correctedPhrase: 'coche',
          startIndex: 3,
          category: null,
          verdict: StagedCorrectionVerdict.notAnError,
        ),
      ]);

      final result = resolved.single;
      expect(result.originalPhrase, 'coche');
      expect(result.correctedPhrase, 'coche');
      expect(result.startIndex, 3);
      expect(result.endIndex, 8);
    },
  );

  test('preserves occurrence, category, and verdict unchanged', () {
    final resolved = resolveInsertionOffsets([
      positioned(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        startIndex: 9,
        category: 'Spelling',
        verdict: StagedCorrectionVerdict.error,
      ),
    ]);

    final result = resolved.single;
    expect(result.occurrence, 1);
    expect(result.category, 'Spelling');
    expect(result.verdict, StagedCorrectionVerdict.error);
  });

  test('processes multiple candidates independently, in order', () {
    final resolved = resolveInsertionOffsets([
      positioned(
        originalPhrase: 'Cómo estás',
        correctedPhrase: '¿Cómo estás',
        startIndex: 0,
      ),
      positioned(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        startIndex: 20,
      ),
    ]);

    expect(resolved, hasLength(2));
    expect(resolved[0].correctedPhrase, '¿');
    expect(resolved[0].startIndex, 0);
    expect(resolved[1].correctedPhrase, 'tráfico');
    expect(resolved[1].startIndex, 20);
    expect(resolved[1].endIndex, 27);
  });
}
