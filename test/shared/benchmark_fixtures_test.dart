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

  group('boundaryControlFirstPassFixtures', () {
    test('exists with the required stable fixture ids', () {
      expect(boundaryControlFirstPassFixtures, hasLength(10));
      expect(boundaryControlFirstPassFixtures.map((fixture) => fixture.id), [
        'boundary-redundant-yo',
        'boundary-redundant-ellos',
        'boundary-para-casa',
        'boundary-regional-coger',
        'boundary-regional-preterite',
        'boundary-calque-llamar-para-atras',
        'boundary-collocation-hacer-decision',
        'boundary-gustar-agreement',
        'boundary-missing-que',
        'boundary-ser-estar-profesor',
      ]);
    });

    test('has unique ids across all addressable fixtures', () {
      final ids = addressableBenchmarkFixtures
          .map((fixture) => fixture.id)
          .toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'All addressable fixture ids must be unique.',
      );
    });

    test('covers each boundary fixture group', () {
      final groups = boundaryControlFirstPassFixtures
          .map((fixture) => fixture.fixtureGroup)
          .toSet();

      expect(
        groups,
        containsAll({
          BoundaryFixtureGroup.unchangedBoundaryControl,
          BoundaryFixtureGroup.wordChoiceBoundaryControl,
          BoundaryFixtureGroup.grammarBoundaryCorrection,
        }),
      );
    });

    test('has expected corrected text for every fixture', () {
      expect(
        boundaryControlFirstPassExpectedCorrectedText.keys.toSet(),
        boundaryControlFirstPassFixtures.map((fixture) => fixture.id).toSet(),
      );

      for (final fixture in boundaryControlFirstPassFixtures) {
        expect(fixture.text.trim(), isNotEmpty, reason: fixture.id);
        expect(fixture.note.trim(), isNotEmpty, reason: fixture.id);
        expect(
          fixture.expectedCorrectedText.trim(),
          isNotEmpty,
          reason: fixture.id,
        );
        expect(
          fixture.text.length,
          lessThanOrEqualTo(appCharacterLimit),
          reason: '${fixture.id} is ${fixture.text.length} chars',
        );
      }
    });

    test('unchanged and word-choice controls expect input unchanged', () {
      final unchangedFixtures = boundaryControlFirstPassFixtures.where(
        (fixture) =>
            fixture.fixtureGroup ==
                BoundaryFixtureGroup.unchangedBoundaryControl ||
            fixture.fixtureGroup ==
                BoundaryFixtureGroup.wordChoiceBoundaryControl,
      );

      expect(unchangedFixtures, hasLength(7));
      for (final fixture in unchangedFixtures) {
        expect(fixture.expectedBehavior, BoundaryExpectedBehavior.unchanged);
        expect(fixture.isControlCase, isTrue, reason: fixture.id);
        expect(fixture.isOverCorrectionSensitive, isTrue, reason: fixture.id);
        expect(fixture.expectedCorrectedText, fixture.text, reason: fixture.id);
      }
    });

    test('grammar-boundary corrections expect changed output', () {
      final correctionFixtures = boundaryControlFirstPassFixtures.where(
        (fixture) =>
            fixture.fixtureGroup ==
            BoundaryFixtureGroup.grammarBoundaryCorrection,
      );

      expect(correctionFixtures, hasLength(3));
      for (final fixture in correctionFixtures) {
        expect(fixture.expectedBehavior, BoundaryExpectedBehavior.corrected);
        expect(fixture.isCorrectionCase, isTrue, reason: fixture.id);
        expect(
          fixture.expectedCorrectedText,
          isNot(fixture.text),
          reason: fixture.id,
        );
      }
    });

    test(
      'metadata identifies boundary type, group, and expected behaviour',
      () {
        final boundaryTypes = boundaryControlFirstPassFixtures
            .map((fixture) => fixture.boundaryType)
            .toSet();

        expect(
          boundaryTypes,
          containsAll({
            BoundaryType.redundantPronoun,
            BoundaryType.regionalUsage,
            BoundaryType.tensePreference,
            BoundaryType.calque,
            BoundaryType.collocation,
            BoundaryType.agreement,
            BoundaryType.omission,
            BoundaryType.serEstar,
          }),
        );

        for (final fixture in boundaryControlFirstPassFixtures) {
          expect(fixture.fixtureGroup.reportLabel, contains('_'));
          expect(fixture.boundaryType.reportLabel.trim(), isNotEmpty);
          expect(fixture.expectedBehavior.reportLabel.trim(), isNotEmpty);
        }
      },
    );
  });

  group('lexicalCollocationFirstPassFixtures', () {
    test('exists with the required stable fixture ids', () {
      expect(lexicalCollocationFirstPassFixtures, hasLength(8));
      expect(lexicalCollocationFirstPassFixtures.map((fixture) => fixture.id), [
        'lexical-control-hacer-pregunta',
        'lexical-control-tomar-foto',
        'lexical-control-dar-paseo',
        'lexical-hacer-paseo',
        'lexical-hacer-atencion',
        'lexical-tomar-reunion',
        'lexical-hacer-decision',
        'lexical-tomar-fiesta',
      ]);
    });

    test('has unique ids across all addressable fixtures', () {
      final ids = addressableBenchmarkFixtures
          .map((fixture) => fixture.id)
          .toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'All addressable fixture ids must be unique.',
      );
    });

    test('registers inputs, expected outputs, notes, and roles exactly', () {
      final expectedById = {
        'lexical-control-hacer-pregunta': (
          input: 'Voy a hacer una pregunta al profesor después de clase.',
          expected: 'Voy a hacer una pregunta al profesor después de clase.',
          role: LexicalCollocationFixtureRole.unchangedControl,
          note:
              'Valid hacer + pregunta collocation. Ensures the model does '
              'not blindly replace hacer.',
        ),
        'lexical-control-tomar-foto': (
          input: 'Necesito tomar una foto del documento antes de enviarlo.',
          expected: 'Necesito tomar una foto del documento antes de enviarlo.',
          role: LexicalCollocationFixtureRole.unchangedControl,
          note:
              'Valid tomar + foto collocation. Ensures the model does not '
              'blindly replace tomar.',
        ),
        'lexical-control-dar-paseo': (
          input: 'Vamos a dar un paseo por el parque esta tarde.',
          expected: 'Vamos a dar un paseo por el parque esta tarde.',
          role: LexicalCollocationFixtureRole.unchangedControl,
          note: 'Valid dar + paseo collocation.',
        ),
        'lexical-hacer-paseo': (
          input: 'Ella hizo un paseo por el parque después del trabajo.',
          expected: 'Ella dio un paseo por el parque después del trabajo.',
          role: LexicalCollocationFixtureRole.expectedCorrection,
          note:
              'Wrong verb-noun collocation: hacer un paseo should be dar un '
              'paseo.',
        ),
        'lexical-hacer-atencion': (
          input: 'Tenemos que hacer atención a los detalles del contrato.',
          expected: 'Tenemos que prestar atención a los detalles del contrato.',
          role: LexicalCollocationFixtureRole.expectedCorrection,
          note:
              'Wrong verb-noun collocation: hacer atención should be prestar '
              'atención.',
        ),
        'lexical-tomar-reunion': (
          input: 'El equipo tomó una reunión para hablar del problema.',
          expected: 'El equipo tuvo una reunión para hablar del problema.',
          role: LexicalCollocationFixtureRole.expectedCorrection,
          note:
              'Wrong verb-noun collocation: tomar una reunión should be tener '
              'una reunión.',
        ),
        'lexical-hacer-decision': (
          input: 'Quiero hacer una decisión antes de mañana.',
          expected: 'Quiero tomar una decisión antes de mañana.',
          role: LexicalCollocationFixtureRole.expectedCorrection,
          note:
              'Wrong verb-noun collocation: hacer una decisión should be '
              'tomar una decisión.',
        ),
        'lexical-tomar-fiesta': (
          input: 'Mi hermana tomó una fiesta para celebrar su cumpleaños.',
          expected: 'Mi hermana hizo una fiesta para celebrar su cumpleaños.',
          role: LexicalCollocationFixtureRole.expectedCorrection,
          note:
              'Wrong verb-noun collocation: tomar una fiesta should be hacer '
              'una fiesta.',
        ),
      };

      expect(
        lexicalCollocationFirstPassExpectedCorrectedText.keys.toSet(),
        expectedById.keys.toSet(),
      );

      for (final fixture in lexicalCollocationFirstPassFixtures) {
        final expected = expectedById[fixture.id]!;
        expect(fixture.text, expected.input, reason: fixture.id);
        expect(
          fixture.expectedCorrectedText,
          expected.expected,
          reason: fixture.id,
        );
        expect(
          lexicalCollocationFirstPassExpectedCorrectedText[fixture.id],
          expected.expected,
          reason: fixture.id,
        );
        expect(fixture.note, expected.note, reason: fixture.id);
        expect(fixture.role, expected.role, reason: fixture.id);
      }
    });

    test(
      'controls are unchanged and correction cases expect changed output',
      () {
        final controls = lexicalCollocationFirstPassFixtures.where(
          (fixture) =>
              fixture.role == LexicalCollocationFixtureRole.unchangedControl,
        );
        expect(controls, hasLength(3));
        for (final fixture in controls) {
          expect(fixture.isControlCase, isTrue, reason: fixture.id);
          expect(
            fixture.expectedCorrectedText,
            fixture.text,
            reason: fixture.id,
          );
        }

        final corrections = lexicalCollocationFirstPassFixtures.where(
          (fixture) =>
              fixture.role == LexicalCollocationFixtureRole.expectedCorrection,
        );
        expect(corrections, hasLength(5));
        for (final fixture in corrections) {
          expect(fixture.isCorrectionCase, isTrue, reason: fixture.id);
          expect(
            fixture.expectedCorrectedText,
            isNot(fixture.text),
            reason: fixture.id,
          );
        }
      },
    );

    test('each lexical fixture is addressable by stable id', () {
      for (final fixture in lexicalCollocationFirstPassFixtures) {
        expect(benchmarkFixtureById(fixture.id), same(fixture));
      }
    });
  });

  group('naturalnessModelComparisonFixtures', () {
    test('exists with the required stable fixture ids', () {
      expect(naturalnessModelComparisonFixtures, hasLength(12));
      expect(naturalnessModelComparisonFixtures.map((fixture) => fixture.id), [
        'naturalness-calque-llamar-para-atras',
        'naturalness-collocation-necesito-hacer-decision',
        'naturalness-collocation-quiero-hacer-decision',
        'naturalness-collocation-hacer-atencion',
        'naturalness-collocation-tomar-reunion',
        'naturalness-collocation-hacer-paseo',
        'naturalness-control-hacer-pregunta',
        'naturalness-control-tomar-foto',
        'naturalness-control-para-casa',
        'naturalness-grammar-trap-gustar-agreement',
        'naturalness-es3-multi-correction',
        'naturalness-es4-calque-pair',
      ]);
    });

    test('registers controls, expected issues, and traps correctly', () {
      final byId = {
        for (final fixture in naturalnessModelComparisonFixtures)
          fixture.id: fixture,
      };

      expect(
        byId['naturalness-calque-llamar-para-atras']!
            .expectedIssues
            .single
            .span,
        'llamo para atrás',
      );
      expect(
        byId['naturalness-collocation-necesito-hacer-decision']!
            .expectedIssues
            .single
            .naturalReplacement,
        'tomar una decisión',
      );
      expect(
        byId['naturalness-collocation-hacer-atencion']!
            .expectedIssues
            .single
            .issueType,
        NaturalnessIssueType.collocation,
      );
      expect(
        byId['naturalness-control-hacer-pregunta']!.expectedIssues,
        isEmpty,
      );
      expect(
        byId['naturalness-control-tomar-foto']!.role,
        NaturalnessFixtureRole.unchangedControl,
      );
      expect(
        byId['naturalness-grammar-trap-gustar-agreement']!.ignoredSpans,
        contains('Me gusta las películas'),
      );
      expect(
        byId['naturalness-es3-multi-correction']!.text,
        contains('trafico'),
      );
      expect(
        byId['naturalness-es3-multi-correction']!.ignoredSpans,
        contains('trafico'),
      );
      expect(
        byId['naturalness-es4-calque-pair']!.expectedIssues.map(
          (issue) => issue.span,
        ),
        ['Puedo tener una cerveza', 'pasar un buen tiempo'],
      );
    });

    test('has unique ids across all addressable fixtures', () {
      final ids = addressableBenchmarkFixtures
          .map((fixture) => fixture.id)
          .toList();
      expect(
        ids.toSet().length,
        ids.length,
        reason: 'All addressable fixture ids must be unique.',
      );
    });

    test('controls and grammar traps expect no naturalness issues', () {
      for (final fixture in naturalnessModelComparisonFixtures.where(
        (fixture) => fixture.role != NaturalnessFixtureRole.expectedIssue,
      )) {
        expect(fixture.expectedIssues, isEmpty, reason: fixture.id);
      }
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
