import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_candidate.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  test('exposes the fields it was constructed with, startIndex null by default', () {
    const candidate = StagedCorrectionCandidate(
      originalPhrase: 'trafico',
      correctedPhrase: 'tráfico',
      occurrence: 1,
      category: 'Spelling',
      verdict: StagedCorrectionVerdict.error,
    );

    expect(candidate.originalPhrase, 'trafico');
    expect(candidate.correctedPhrase, 'tráfico');
    expect(candidate.occurrence, 1);
    expect(candidate.category, 'Spelling');
    expect(candidate.verdict, StagedCorrectionVerdict.error);
    expect(candidate.startIndex, isNull);
  });

  test('accepts a null category, for not_an_error', () {
    const candidate = StagedCorrectionCandidate(
      originalPhrase: 'coche',
      correctedPhrase: 'coche',
      occurrence: 1,
      category: null,
      verdict: StagedCorrectionVerdict.notAnError,
    );

    expect(candidate.category, isNull);
  });

  test('carries an explicit startIndex when given one', () {
    const candidate = StagedCorrectionCandidate(
      originalPhrase: 'trafico',
      correctedPhrase: 'tráfico',
      occurrence: 1,
      category: 'Spelling',
      verdict: StagedCorrectionVerdict.error,
      startIndex: 12,
    );

    expect(candidate.startIndex, 12);
  });

  test('carries an explicit endIndex when given one', () {
    const candidate = StagedCorrectionCandidate(
      originalPhrase: 'trafico',
      correctedPhrase: 'tráfico',
      occurrence: 1,
      category: 'Spelling',
      verdict: StagedCorrectionVerdict.error,
      startIndex: 9,
      endIndex: 16,
    );

    expect(candidate.endIndex, 16);
  });

  group('copyWith', () {
    const candidate = StagedCorrectionCandidate(
      originalPhrase: 'trafico',
      correctedPhrase: 'tráfico',
      occurrence: 1,
      category: 'Spelling',
      verdict: StagedCorrectionVerdict.error,
    );

    test('sets startIndex and carries every other field over unchanged', () {
      final withPosition = candidate.copyWith(startIndex: 9);

      expect(withPosition.startIndex, 9);
      expect(withPosition.endIndex, isNull);
      expect(withPosition.originalPhrase, candidate.originalPhrase);
      expect(withPosition.correctedPhrase, candidate.correctedPhrase);
      expect(withPosition.occurrence, candidate.occurrence);
      expect(withPosition.category, candidate.category);
      expect(withPosition.verdict, candidate.verdict);
    });

    test('sets originalPhrase, correctedPhrase, startIndex, and endIndex '
        'together, for the pure-insertion case', () {
      final withPosition = candidate.copyWith(
        originalPhrase: '',
        correctedPhrase: '¿',
        startIndex: 0,
        endIndex: 0,
      );

      expect(withPosition.originalPhrase, '');
      expect(withPosition.correctedPhrase, '¿');
      expect(withPosition.startIndex, 0);
      expect(withPosition.endIndex, 0);
      expect(withPosition.occurrence, candidate.occurrence);
      expect(withPosition.category, candidate.category);
      expect(withPosition.verdict, candidate.verdict);
    });

    test('leaves every field unchanged when called with no arguments', () {
      const positioned = StagedCorrectionCandidate(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        occurrence: 1,
        category: 'Spelling',
        verdict: StagedCorrectionVerdict.error,
        startIndex: 9,
        endIndex: 16,
      );

      final copy = positioned.copyWith();

      expect(copy.originalPhrase, positioned.originalPhrase);
      expect(copy.correctedPhrase, positioned.correctedPhrase);
      expect(copy.startIndex, positioned.startIndex);
      expect(copy.endIndex, positioned.endIndex);
    });
  });
}
