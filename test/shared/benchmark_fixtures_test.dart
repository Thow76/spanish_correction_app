// Offline tests for the shared Spanish correction benchmark fixture set
// (`test/shared/benchmark_fixtures.dart`).
//
// Issue: "Define richer Spanish correction benchmark fixture strategy"
// (closes spanish_correction_app#11). These are pure fixture-loading/
// fixture-selection checks — no live API calls, no `live` tag — verifying
// the fixture set's own invariants (unique ids, character-limit compliance,
// length-band coverage, CALCS-style/accent/correctness mix) rather than any
// correction-quality claim about the texts themselves.
//
// Run with: flutter test test/shared/benchmark_fixtures_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'benchmark_fixtures.dart';

void main() {
  group('benchmarkFixtures', () {
    test('is non-empty and small enough for routine live runs', () {
      expect(benchmarkFixtures, isNotEmpty);
      // "Small enough for routine live benchmarking" per the issue — not a
      // hard technical limit, just a guard against this set silently
      // growing back into a large exhaustive suite.
      expect(benchmarkFixtures.length, lessThanOrEqualTo(15));
    });

    test('every fixture has a unique id', () {
      final ids = benchmarkFixtures.map((f) => f.id).toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'Fixture ids must be unique.',
      );
    });

    test('every fixture has non-empty description, text, and purpose', () {
      for (final fixture in benchmarkFixtures) {
        expect(fixture.description.trim(), isNotEmpty, reason: fixture.id);
        expect(fixture.text.trim(), isNotEmpty, reason: fixture.id);
        expect(fixture.purpose.trim(), isNotEmpty, reason: fixture.id);
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

    test('every required length band is represented', () {
      final bands = benchmarkFixtures.map((f) => f.lengthBand).toSet();
      expect(bands, containsAll(BenchmarkLengthBand.values));
    });

    test('the near-limit case is actually close to the character limit', () {
      final nearLimitCases = benchmarkFixturesForBand(
        BenchmarkLengthBand.nearLimit,
      );
      expect(nearLimitCases, isNotEmpty);
      for (final fixture in nearLimitCases) {
        expect(
          fixture.text.length,
          greaterThanOrEqualTo((appCharacterLimit * 0.8).round()),
          reason:
              '${fixture.id} (${fixture.text.length} chars) should be '
              'close to the ${appCharacterLimit}-char limit, not merely '
              'under it.',
        );
      }
    });

    test('includes at least one CALCS-style case', () {
      expect(benchmarkFixtures.where((f) => f.isCalcsStyle), isNotEmpty);
    });

    test('includes a mix of already-correct and erroneous Spanish', () {
      expect(
        benchmarkFixtures.where((f) => f.containsKnownErrors == true),
        isNotEmpty,
        reason: 'Need at least one case with known errors.',
      );
      expect(
        benchmarkFixtures.where((f) => f.containsKnownErrors == false),
        isNotEmpty,
        reason: 'Need at least one already-correct case.',
      );
    });

    test('includes at least one accent-sensitive case', () {
      expect(benchmarkFixtures.where((f) => f.isAccentSensitive), isNotEmpty);
    });

    test('two-paragraph fixtures actually contain two paragraphs', () {
      final twoParagraphCases = benchmarkFixturesForBand(
        BenchmarkLengthBand.twoParagraph,
      );
      expect(twoParagraphCases, isNotEmpty);
      for (final fixture in twoParagraphCases) {
        expect(
          fixture.text.split('\n\n').length,
          greaterThanOrEqualTo(2),
          reason: '${fixture.id} should contain a blank-line paragraph break.',
        );
      }
    });

    test('short-phrase fixtures are meaningfully shorter than paragraphs', () {
      final shortPhrases = benchmarkFixturesForBand(
        BenchmarkLengthBand.shortPhrase,
      );
      final paragraphs = benchmarkFixturesForBand(
        BenchmarkLengthBand.paragraph,
      );
      expect(shortPhrases, isNotEmpty);
      expect(paragraphs, isNotEmpty);
      final longestShortPhrase = shortPhrases
          .map((f) => f.text.length)
          .reduce((a, b) => a > b ? a : b);
      final shortestParagraph = paragraphs
          .map((f) => f.text.length)
          .reduce((a, b) => a < b ? a : b);
      expect(longestShortPhrase, lessThan(shortestParagraph));
    });
  });

  group('benchmarkFixtureById', () {
    test('returns the matching fixture', () {
      final fixture = benchmarkFixtureById('sentence-grammar-error');
      expect(fixture.id, 'sentence-grammar-error');
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
