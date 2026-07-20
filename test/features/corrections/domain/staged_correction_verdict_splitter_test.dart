import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_candidate.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict_splitter.dart';

void main() {
  StagedCorrectionCandidate candidate({
    required String originalPhrase,
    required String correctedPhrase,
    required StagedCorrectionVerdict verdict,
    String? category,
    int startIndex = 0,
    int endIndex = 1,
  }) {
    return StagedCorrectionCandidate(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      occurrence: 1,
      category: category,
      verdict: verdict,
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }

  test(
    'splits error, dialectal, and not_an_error correctly — the end-to-end '
    'guard: no dialectal or not_an_error candidate ever produces a '
    'CorrectionItem, and not_an_error produces nothing at all',
    () {
      final errorCandidate = candidate(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        verdict: StagedCorrectionVerdict.error,
        category: 'Spelling',
        startIndex: 9,
        endIndex: 16,
      );
      final dialectalCandidate = candidate(
        originalPhrase: 'coger el autobús',
        correctedPhrase: 'coger el autobús',
        verdict: StagedCorrectionVerdict.dialectal,
        category: 'Other',
        startIndex: 20,
        endIndex: 37,
      );
      final notAnErrorCandidate = candidate(
        originalPhrase: 'coche',
        correctedPhrase: 'coche',
        verdict: StagedCorrectionVerdict.notAnError,
        category: null,
        startIndex: 40,
        endIndex: 45,
      );

      final split = splitStagedCorrections([
        errorCandidate,
        dialectalCandidate,
        notAnErrorCandidate,
      ]);

      expect(split.errorItems, hasLength(1));
      expect(split.errorItems.single.originalPhrase, 'trafico');
      expect(split.errorItems.single.correctedPhrase, 'tráfico');
      expect(split.errorItems.single.category, ErrorCategory.spelling);

      expect(split.dialectalCandidates, hasLength(1));
      expect(split.dialectalCandidates.single, same(dialectalCandidate));

      // not_an_error must not appear anywhere in either output.
      expect(
        split.errorItems.any(
          (item) => item.originalPhrase == 'coche',
        ),
        isFalse,
      );
      expect(
        split.dialectalCandidates.any(
          (item) => item.originalPhrase == 'coche',
        ),
        isFalse,
      );
    },
  );

  test('an error CorrectionItem carries a placeholder shortExplanation and '
      'the candidate\'s resolved position, with no corrected-side position '
      'yet', () {
    final result = splitStagedCorrections([
      candidate(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        verdict: StagedCorrectionVerdict.error,
        category: 'Spelling',
        startIndex: 9,
        endIndex: 16,
      ),
    ]);

    final item = result.errorItems.single;
    expect(item.shortExplanation, isEmpty);
    expect(item.startIndex, 9);
    expect(item.endIndex, 16);
    expect(item.correctedStartIndex, isNull);
    expect(item.correctedEndIndex, isNull);
  });

  test('converts each of the five category labels correctly', () {
    final labelsToCategories = {
      'Grammar': ErrorCategory.grammar,
      'Natural Language': ErrorCategory.naturalLanguage,
      'Spelling': ErrorCategory.spelling,
      'Word Choice': ErrorCategory.wordChoice,
      'Other': ErrorCategory.other,
    };

    for (final entry in labelsToCategories.entries) {
      final result = splitStagedCorrections([
        candidate(
          originalPhrase: 'x',
          correctedPhrase: 'y',
          verdict: StagedCorrectionVerdict.error,
          category: entry.key,
        ),
      ]);

      expect(result.errorItems.single.category, entry.value);
    }
  });

  test('drops an error candidate with a null category', () {
    final result = splitStagedCorrections([
      candidate(
        originalPhrase: 'x',
        correctedPhrase: 'y',
        verdict: StagedCorrectionVerdict.error,
        category: null,
      ),
    ]);

    expect(result.errorItems, isEmpty);
  });

  test('drops an error candidate with an unrecognized category label', () {
    final result = splitStagedCorrections([
      candidate(
        originalPhrase: 'x',
        correctedPhrase: 'y',
        verdict: StagedCorrectionVerdict.error,
        category: 'Preposition', // legacy label, not accepted by fromApiLabel
      ),
    ]);

    expect(result.errorItems, isEmpty);
  });

  test('preserves order within each verdict bucket', () {
    final result = splitStagedCorrections([
      candidate(
        originalPhrase: 'a',
        correctedPhrase: 'A',
        verdict: StagedCorrectionVerdict.error,
        category: 'Grammar',
        startIndex: 0,
        endIndex: 1,
      ),
      candidate(
        originalPhrase: 'b',
        correctedPhrase: 'B',
        verdict: StagedCorrectionVerdict.error,
        category: 'Spelling',
        startIndex: 2,
        endIndex: 3,
      ),
      candidate(
        originalPhrase: 'c',
        correctedPhrase: 'c',
        verdict: StagedCorrectionVerdict.dialectal,
        category: 'Other',
        startIndex: 4,
        endIndex: 5,
      ),
      candidate(
        originalPhrase: 'd',
        correctedPhrase: 'd',
        verdict: StagedCorrectionVerdict.dialectal,
        category: 'Other',
        startIndex: 6,
        endIndex: 7,
      ),
    ]);

    expect(
      result.errorItems.map((item) => item.originalPhrase),
      ['a', 'b'],
    );
    expect(
      result.dialectalCandidates.map((c) => c.originalPhrase),
      ['c', 'd'],
    );
  });

  test('an empty input returns empty buckets', () {
    final result = splitStagedCorrections(const []);

    expect(result.errorItems, isEmpty);
    expect(result.dialectalCandidates, isEmpty);
  });
}
