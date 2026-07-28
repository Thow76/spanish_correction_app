// Offline tests for the shared Spanish correction benchmark fixture set.
//
// Run with:
//   flutter test test/shared/benchmark_fixtures_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'benchmark_fixtures.dart';

void main() {
  group('benchmarkFixtures', () {
    test('is non-empty and small enough for routine live runs', () {
      expect(benchmarkFixtures, isNotEmpty);
      expect(benchmarkFixtures.length, lessThanOrEqualTo(15));
    });

    test('every fixture has a unique id', () {
      final ids = benchmarkFixtures.map((fixture) => fixture.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'Fixture ids must be unique.',
      );
    });

    test('every fixture has required metadata', () {
      for (final fixture in benchmarkFixtures) {
        expect(fixture.id.trim(), isNotEmpty);
        expect(fixture.text.trim(), isNotEmpty, reason: fixture.id);
        expect(fixture.note.trim(), isNotEmpty, reason: fixture.id);
      }
    });

    test('no fixture exceeds the app character limit', () {
      for (final fixture in benchmarkFixtures) {
        expect(
          fixture.text.length,
          lessThanOrEqualTo(appCharacterLimit),
          reason: '${fixture.id} is ${fixture.text.length} chars',
        );
      }
    });

    test('required length bands are present', () {
      final bands = benchmarkFixtures.map((fixture) => fixture.lengthBand);
      expect(
        bands,
        containsAll([
          BenchmarkLengthBand.shortPhrase,
          BenchmarkLengthBand.paragraph,
          BenchmarkLengthBand.twoParagraph,
          BenchmarkLengthBand.nearLimit,
        ]),
      );
    });

    test('the near-limit fixture is close to the character limit', () {
      final nearLimitFixtures = benchmarkFixturesForBand(
        BenchmarkLengthBand.nearLimit,
      );
      expect(nearLimitFixtures, isNotEmpty);

      for (final fixture in nearLimitFixtures) {
        expect(
          fixture.text.length,
          greaterThanOrEqualTo((appCharacterLimit * 0.8).round()),
          reason:
              '${fixture.id} (${fixture.text.length} chars) should be close '
              'to the $appCharacterLimit-character limit.',
        );
      }
    });

    test('includes correction and control cases', () {
      expect(
        benchmarkFixtures.where((fixture) => fixture.isCorrectionCase),
        isNotEmpty,
      );
      expect(
        benchmarkFixtures.where((fixture) => fixture.isControlCase),
        isNotEmpty,
      );
    });

    test('includes CALCS-style, accent-sensitive, and regional controls', () {
      expect(
        benchmarkFixtures.where((fixture) => fixture.isCalcsStyle),
        isNotEmpty,
      );
      expect(
        benchmarkFixtures.where((fixture) => fixture.isAccentSensitive),
        isNotEmpty,
      );
      expect(
        benchmarkFixtures.where(
          (fixture) => fixture.isControlCase && fixture.isValidRegionalSpanish,
        ),
        isNotEmpty,
      );
    });

    test('two-paragraph fixtures contain a blank-line paragraph break', () {
      final twoParagraphFixtures = benchmarkFixturesForBand(
        BenchmarkLengthBand.twoParagraph,
      );
      expect(twoParagraphFixtures, isNotEmpty);

      for (final fixture in twoParagraphFixtures) {
        expect(
          fixture.text.split('\n\n').length,
          greaterThanOrEqualTo(2),
          reason: fixture.id,
        );
      }
    });
  });

  group('harderSecondPassFirstPassFixtures', () {
    test('exists and has unique ids across all addressable fixtures', () {
      expect(harderSecondPassFirstPassFixtures, isNotEmpty);

      final ids = addressableBenchmarkFixtures
          .map((fixture) => fixture.id)
          .toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'All addressable fixture ids must be unique.',
      );
    });

    test('covers the required objective error families', () {
      final families = harderSecondPassFirstPassFixtures
          .expand((fixture) => fixture.errorFamilies)
          .toSet();

      expect(
        families,
        containsAll({
          ObjectiveSpanishErrorFamily.accentMarksDiacritics,
          ObjectiveSpanishErrorFamily.genderNumberAgreement,
          ObjectiveSpanishErrorFamily.prepositionGovernment,
          ObjectiveSpanishErrorFamily.verbMorphologySubjectVerbAgreement,
          ObjectiveSpanishErrorFamily.articlesDeterminers,
          ObjectiveSpanishErrorFamily.subjunctiveMood,
          ObjectiveSpanishErrorFamily.objectPronounsClitics,
          ObjectiveSpanishErrorFamily.serEstarHaber,
          ObjectiveSpanishErrorFamily.personalA,
          ObjectiveSpanishErrorFamily.relativeClauseRequiredPreposition,
          ObjectiveSpanishErrorFamily.impersonalHaberPassiveImpersonalSe,
          ObjectiveSpanishErrorFamily.sentenceBoundariesPunctuation,
        }),
      );
    });

    test(
      'has expected corrected text and intended counts for every fixture',
      () {
        expect(
          harderSecondPassFirstPassExpectedCorrectedText.keys.toSet(),
          harderSecondPassFirstPassFixtures
              .map((fixture) => fixture.id)
              .toSet(),
        );

        for (final fixture in harderSecondPassFirstPassFixtures) {
          expect(fixture.text.trim(), isNotEmpty, reason: fixture.id);
          expect(
            fixture.expectedCorrectedText.trim(),
            isNotEmpty,
            reason: fixture.id,
          );
          expect(
            fixture.expectedCorrectedText,
            isNot(fixture.text),
            reason: fixture.id,
          );
          expect(fixture.note.trim(), isNotEmpty, reason: fixture.id);
          expect(fixture.errorFamilies, isNotEmpty, reason: fixture.id);
          expect(
            fixture.intendedErrorCount,
            greaterThan(0),
            reason: fixture.id,
          );
          expect(fixture.cefrTargetLevel, isA<BenchmarkCefrTargetLevel>());
          expect(
            fixture.text.length,
            lessThanOrEqualTo(appCharacterLimit),
            reason: '${fixture.id} is ${fixture.text.length} chars',
          );
        }
      },
    );

    test('keeps paragraph and near-limit fixture difficulty intentional', () {
      final paragraphFixtures = harderSecondPassFirstPassFixtures.where(
        (fixture) => fixture.lengthBand == BenchmarkLengthBand.paragraph,
      );
      expect(paragraphFixtures, isNotEmpty);

      for (final fixture in paragraphFixtures) {
        expect(
          fixture.intendedErrorCount,
          greaterThanOrEqualTo(2),
          reason: fixture.id,
        );
      }

      final nearLimit = harderSecondPassFirstPassFixtures.singleWhere(
        (fixture) => fixture.lengthBand == BenchmarkLengthBand.nearLimit,
      );
      expect(nearLimit.intendedErrorCount, greaterThanOrEqualTo(4));
      expect(
        nearLimit.text.length,
        greaterThanOrEqualTo((appCharacterLimit * 0.8).round()),
      );
    });
  });

  group('firstPassModelComparisonFixtures', () {
    test('is a small subset of the shared benchmark fixtures', () {
      final allIds = benchmarkFixtures.map((fixture) => fixture.id).toSet();
      final subsetIds = firstPassModelComparisonFixtures
          .map((fixture) => fixture.id)
          .toList();

      expect(firstPassModelComparisonFixtures.length, lessThanOrEqualTo(10));
      expect(subsetIds.toSet().length, subsetIds.length);
      expect(allIds, containsAll(subsetIds));
    });

    test('keeps the original first-pass subset unchanged', () {
      expect(firstPassModelComparisonFixtures.map((fixture) => fixture.id), [
        'short-phrase-missing-accent',
        'sentence-grammar-agreement',
        'sentence-punctuation-question',
        'sentence-correct-voseo',
        'sentence-regional-word-choice',
        'paragraph-calcs-natural',
        'paragraph-mixed-errors',
        'two-paragraph-already-correct',
        'near-limit-full-text',
      ]);
    });

    test('covers the required first-pass benchmark scenarios', () {
      final bands = firstPassModelComparisonFixtures
          .map((fixture) => fixture.lengthBand)
          .toSet();

      expect(
        bands,
        containsAll([
          BenchmarkLengthBand.shortPhrase,
          BenchmarkLengthBand.paragraph,
          BenchmarkLengthBand.twoParagraph,
          BenchmarkLengthBand.nearLimit,
        ]),
      );
      expect(
        firstPassModelComparisonFixtures.where(
          (fixture) => fixture.isCorrectionCase,
        ),
        isNotEmpty,
      );
      expect(
        firstPassModelComparisonFixtures.where(
          (fixture) => fixture.isControlCase,
        ),
        isNotEmpty,
      );
      expect(
        firstPassModelComparisonFixtures.where(
          (fixture) => fixture.isCalcsStyle,
        ),
        isNotEmpty,
      );
      expect(
        firstPassModelComparisonFixtures.where(
          (fixture) => fixture.isAccentSensitive,
        ),
        isNotEmpty,
      );
      expect(
        firstPassModelComparisonFixtures.where(
          (fixture) => fixture.isControlCase && fixture.isValidRegionalSpanish,
        ),
        isNotEmpty,
      );
    });
  });

  group('benchmarkFixtureById', () {
    test('returns the matching fixture', () {
      final fixture = benchmarkFixtureById('sentence-grammar-agreement');
      expect(fixture.id, 'sentence-grammar-agreement');
    });

    test('throws for an unknown id', () {
      expect(() => benchmarkFixtureById('does-not-exist'), throwsStateError);
    });
  });

  group('benchmarkFixturesForBand', () {
    test('returns only fixtures matching the requested band', () {
      final results = benchmarkFixturesForBand(BenchmarkLengthBand.shortPhrase);
      expect(results, isNotEmpty);
      for (final fixture in results) {
        expect(fixture.lengthBand, BenchmarkLengthBand.shortPhrase);
      }
    });
  });
}
