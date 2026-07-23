import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_candidate.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_overlap_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_span_scope.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_span_scope_trim_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/staged_correction_verdict.dart';

void main() {
  group('resolveSpanScopeTrim', () {
    test(
      'trims a Natural Language + exact candidate down to its shared-affix '
      'core (cerveza-shape)',
      () {
        final candidate = StagedCorrectionCandidate(
          originalPhrase: 'Puedo tener una cerveza',
          correctedPhrase: 'Me da una cerveza',
          occurrence: 1,
          category: 'Natural Language',
          verdict: StagedCorrectionVerdict.error,
          spanScope: StagedCorrectionSpanScope.exact,
          startIndex: 10,
          endIndex: 33,
        );

        final result = resolveSpanScopeTrim([candidate]).single;

        expect(result.originalPhrase, 'Puedo tener');
        expect(result.correctedPhrase, 'Me da');
        expect(result.startIndex, 10, reason: 'no shared prefix, so start is unchanged');
        expect(result.endIndex, 21, reason: '33 - 12 (shared " una cerveza" suffix)');
        expect(result.category, 'Natural Language');
        expect(result.spanScope, StagedCorrectionSpanScope.exact);
      },
    );

    test('does not trim a Natural Language + full candidate', () {
      final candidate = StagedCorrectionCandidate(
        originalPhrase: 'Puedo tener una cerveza',
        correctedPhrase: 'Me da una cerveza',
        occurrence: 1,
        category: 'Natural Language',
        verdict: StagedCorrectionVerdict.error,
        spanScope: StagedCorrectionSpanScope.full,
        startIndex: 10,
        endIndex: 33,
      );

      final result = resolveSpanScopeTrim([candidate]).single;

      expect(result, same(candidate));
    });

    test(
      'does not trim a non-Natural-Language candidate regardless of span_scope',
      () {
        final candidate = StagedCorrectionCandidate(
          originalPhrase: 'Puedo tener una cerveza',
          correctedPhrase: 'Me da una cerveza',
          occurrence: 1,
          category: 'Grammar',
          verdict: StagedCorrectionVerdict.error,
          spanScope: StagedCorrectionSpanScope.exact,
          startIndex: 10,
          endIndex: 33,
        );

        final result = resolveSpanScopeTrim([candidate]).single;

        expect(result, same(candidate));
      },
    );

    test('does not trim a Natural Language candidate with a null span_scope', () {
      final candidate = StagedCorrectionCandidate(
        originalPhrase: 'Puedo tener una cerveza',
        correctedPhrase: 'Me da una cerveza',
        occurrence: 1,
        category: 'Natural Language',
        verdict: StagedCorrectionVerdict.error,
        startIndex: 10,
        endIndex: 33,
      );

      final result = resolveSpanScopeTrim([candidate]).single;

      expect(result, same(candidate));
    });

    test(
      'does not trim an already-collapsed pure-insertion candidate '
      '(originalPhrase already narrowed to empty by resolveInsertionOffsets)',
      () {
        final candidate = StagedCorrectionCandidate(
          originalPhrase: '',
          correctedPhrase: 'que',
          occurrence: 1,
          category: 'Natural Language',
          verdict: StagedCorrectionVerdict.error,
          spanScope: StagedCorrectionSpanScope.exact,
          startIndex: 5,
          endIndex: 5,
        );

        final result = resolveSpanScopeTrim([candidate]).single;

        expect(result, same(candidate));
      },
    );

    test(
      'is a no-op when calculateSharedAffixTrim finds no shared prefix or suffix',
      () {
        final candidate = StagedCorrectionCandidate(
          originalPhrase: 'azul',
          correctedPhrase: 'rojo',
          occurrence: 1,
          category: 'Natural Language',
          verdict: StagedCorrectionVerdict.error,
          spanScope: StagedCorrectionSpanScope.exact,
          startIndex: 3,
          endIndex: 7,
        );

        final result = resolveSpanScopeTrim([candidate]).single;

        expect(result, same(candidate));
      },
    );

    test(
      'skips the trim when it would leave corrected_phrase empty '
      '(the "tengo tengo" -> "tengo" repetition-collapse shape), leaving '
      'the original wider span intact',
      () {
        final candidate = StagedCorrectionCandidate(
          originalPhrase: 'tengo tengo',
          correctedPhrase: 'tengo',
          occurrence: 1,
          category: 'Natural Language',
          verdict: StagedCorrectionVerdict.error,
          spanScope: StagedCorrectionSpanScope.exact,
          startIndex: 0,
          endIndex: 11,
        );

        final result = resolveSpanScopeTrim([candidate]).single;

        expect(result, same(candidate));
        expect(result.originalPhrase, 'tengo tengo');
        expect(result.correctedPhrase, 'tengo');
      },
    );
  });

  group('ordering: resolveSpanScopeTrim before resolveOverlappingCandidates', () {
    test(
      "the narrowest-width tie-break picks a different candidate depending "
      "on whether resolveSpanScopeTrim ran first -- proving the trim step's "
      'position in the pipeline is load-bearing, not incidental',
      () {
        // Width 23 before trim, width 11 after (trims to "Puedo tener").
        final trimmable = StagedCorrectionCandidate(
          originalPhrase: 'Puedo tener una cerveza',
          correctedPhrase: 'Me da una cerveza',
          occurrence: 1,
          category: 'Natural Language',
          verdict: StagedCorrectionVerdict.error,
          spanScope: StagedCorrectionSpanScope.exact,
          startIndex: 0,
          endIndex: 23,
        );
        // Width 15, overlapping [0, 23), never eligible for trimming.
        final untrimmable = StagedCorrectionCandidate(
          originalPhrase: 'placeholder',
          correctedPhrase: 'placeholder-fix',
          occurrence: 1,
          category: 'Grammar',
          verdict: StagedCorrectionVerdict.error,
          startIndex: 5,
          endIndex: 20,
        );

        // Dedup on the untrimmed candidates: 15 < 23, the untrimmable one wins.
        final dedupedWithoutTrim = resolveOverlappingCandidates([
          trimmable,
          untrimmable,
        ]);
        expect(dedupedWithoutTrim, hasLength(1));
        expect(dedupedWithoutTrim.single.startIndex, 5);

        // Trim first (the real pipeline order), then dedup: 11 < 15, the
        // trimmed candidate now wins instead -- the outcome flips.
        final trimmedFirst = resolveSpanScopeTrim([trimmable, untrimmable]);
        final dedupedWithTrim = resolveOverlappingCandidates(trimmedFirst);
        expect(dedupedWithTrim, hasLength(1));
        expect(dedupedWithTrim.single.startIndex, 0);
        expect(dedupedWithTrim.single.originalPhrase, 'Puedo tener');
      },
    );
  });
}
