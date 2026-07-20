import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_candidate.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_position_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  StagedCorrectionCandidate candidate({
    required String originalPhrase,
    required int occurrence,
    String correctedPhrase = 'x',
    String? category = 'Grammar',
    StagedCorrectionVerdict verdict = StagedCorrectionVerdict.error,
  }) {
    return StagedCorrectionCandidate(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      occurrence: occurrence,
      category: category,
      verdict: verdict,
    );
  }

  test('resolves a single-occurrence candidate to its position', () {
    final resolved = resolveCandidatePositions(
      originalText: 'Vi mucho trafico ayer.',
      candidates: [candidate(originalPhrase: 'trafico', occurrence: 1)],
    );

    expect(resolved, hasLength(1));
    expect(resolved.single.startIndex, 9);
  });

  test('resolves occurrence 2 to the second match', () {
    final resolved = resolveCandidatePositions(
      originalText: 'para mí y para ti',
      candidates: [candidate(originalPhrase: 'para', occurrence: 2)],
    );

    expect(resolved, hasLength(1));
    expect(resolved.single.startIndex, 10);
  });

  test('drops a candidate whose occurrence exceeds the available matches', () {
    final resolved = resolveCandidatePositions(
      originalText: 'para mí',
      candidates: [candidate(originalPhrase: 'para', occurrence: 2)],
    );

    expect(resolved, isEmpty);
  });

  test('drops a candidate whose phrase does not occur at all', () {
    final resolved = resolveCandidatePositions(
      originalText: 'Todo está bien.',
      candidates: [candidate(originalPhrase: 'trafico', occurrence: 1)],
    );

    expect(resolved, isEmpty);
  });

  test('preserves every other field unchanged', () {
    final resolved = resolveCandidatePositions(
      originalText: 'trafico',
      candidates: [
        candidate(
          originalPhrase: 'trafico',
          occurrence: 1,
          correctedPhrase: 'tráfico',
          category: 'Spelling',
          verdict: StagedCorrectionVerdict.error,
        ),
      ],
    );

    final result = resolved.single;
    expect(result.originalPhrase, 'trafico');
    expect(result.correctedPhrase, 'tráfico');
    expect(result.occurrence, 1);
    expect(result.category, 'Spelling');
    expect(result.verdict, StagedCorrectionVerdict.error);
  });

  test('preserves input order, skipping drops', () {
    final resolved = resolveCandidatePositions(
      originalText: 'Vi mucho trafico ayer.',
      candidates: [
        candidate(originalPhrase: 'trafico', occurrence: 1),
        candidate(originalPhrase: 'no aparece', occurrence: 1),
        candidate(originalPhrase: 'ayer', occurrence: 1),
      ],
    );

    expect(resolved, hasLength(2));
    expect(resolved[0].originalPhrase, 'trafico');
    expect(resolved[1].originalPhrase, 'ayer');
  });

  test(
    'resolves two candidates sharing the same (originalPhrase, occurrence) '
    'independently, without ambiguity — e.g. Stage 1 and Stage 1B both '
    'flagging the same phrase',
    () {
      final resolved = resolveCandidatePositions(
        originalText: 'Yo fui y yo comí.',
        candidates: [
          candidate(
            originalPhrase: 'Yo',
            occurrence: 1,
            correctedPhrase: 'Yo fui',
          ),
          candidate(
            originalPhrase: 'Yo',
            occurrence: 1,
            correctedPhrase: 'redundant pronoun',
          ),
        ],
      );

      expect(resolved, hasLength(2));
      expect(resolved[0].startIndex, 0);
      expect(resolved[1].startIndex, 0);
      expect(resolved[0].correctedPhrase, 'Yo fui');
      expect(resolved[1].correctedPhrase, 'redundant pronoun');
    },
  );
}
