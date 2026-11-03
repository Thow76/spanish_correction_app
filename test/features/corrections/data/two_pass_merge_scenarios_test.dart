// Issue #38: proves the two-pass merge behavior against a fixed matrix of
// deterministic scenarios, with no live OpenAI API access — every scenario
// here either calls the merge/mapper domain functions directly against
// hand-built inputs, or builds a first-pass `CorrectionResponse` fixture
// directly (via `computeCorrectedRanges`/`resolveOccurrenceCorrections`,
// the same domain arithmetic any first-pass client's own corrections would
// go through) rather than driving a real client. Each test below
// corresponds to exactly one bullet in issue #38's "Test cases" list.
//
// Deliberately does NOT drive `runStagedCorrectionPipeline` (or any other
// first-pass client) via a fake HTTP client to produce these fixtures
// (issue #70): this file tests merge-domain behavior — how a first pass's
// own `CorrectionResponse` combines with a naturalness review — which is
// orthogonal to which client production actually uses for pass 1. Building
// fixtures directly means this file can never accidentally validate the
// old staged pipeline as the two-pass first pass, and can never drift out
// of sync when pass 1's real source changes again.

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_corrected_range_calculator.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_original_range_resolver.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_issue.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

void main() {
  test('grammar-only correction: no naturalness issue at all', () {
    const submittedText = 'Vi mucho trafico ayer.';
    final traficoIndex = submittedText.indexOf('trafico');

    final firstPassCorrections = computeCorrectedRanges([
      CorrectionItem(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        category: ErrorCategory.spelling,
        shortExplanation: 'Trafico needs an accent on the a: tráfico.',
        startIndex: traficoIndex,
        endIndex: traficoIndex + 'trafico'.length,
      ),
    ], submittedText: submittedText);

    final firstPassResponse = CorrectionResponse(
      originalText: submittedText,
      correctedText: 'Vi mucho tráfico ayer.',
      corrections: firstPassCorrections,
    );

    final merge = mergeNaturalnessReview(
      originalText: submittedText,
      firstPassCorrectedText: firstPassResponse.correctedText,
      naturalnessReview: const NaturalnessReview(
        hasNaturalnessIssue: false,
        issues: [],
      ),
    );
    final result = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: merge,
    );

    expect(result.correctedText, 'Vi mucho tráfico ayer.');
    expect(result.corrections, hasLength(1));
    expect(result.corrections.single.category, ErrorCategory.spelling);
    expect(result.corrections.single.correctedPhrase, 'tráfico');
  });

  test(
    'naturalness-only correction: the first pass flags nothing at all',
    () {
      const submittedText = 'Voy a hacer una decisión importante.';

      final firstPassResponse = CorrectionResponse(
        originalText: submittedText,
        correctedText: submittedText,
        corrections: const [],
      );
      expect(firstPassResponse.correctedText, submittedText);
      expect(firstPassResponse.corrections, isEmpty);

      const issue = NaturalnessIssue(
        span: 'hacer una decisión',
        naturalReplacement: 'tomar una decisión',
        explanation: 'Wrong collocation for "decisión".',
      );
      final merge = mergeNaturalnessReview(
        originalText: submittedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );
      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );

      expect(result.correctedText, 'Voy a tomar una decisión importante.');
      expect(result.corrections, hasLength(1));
      expect(result.corrections.single.category, ErrorCategory.naturalLanguage);
      expect(result.corrections.single.correctedPhrase, 'tomar una decisión');
    },
  );

  test(
    'grammar and naturalness corrections in different (non-overlapping) '
    'spans',
    () {
      const submittedText =
          'El profesor dijo que devia estudiar más, y ella hizo una '
          'decisión importante.';
      final deviaIndex = submittedText.indexOf('devia');

      final firstPassCorrections = computeCorrectedRanges([
        CorrectionItem(
          originalPhrase: 'devia',
          correctedPhrase: 'debía',
          category: ErrorCategory.spelling,
          shortExplanation: 'Devia is missing its accent: debía.',
          startIndex: deviaIndex,
          endIndex: deviaIndex + 'devia'.length,
        ),
      ], submittedText: submittedText);

      final firstPassResponse = CorrectionResponse(
        originalText: submittedText,
        correctedText:
            'El profesor dijo que debía estudiar más, y ella hizo una '
            'decisión importante.',
        corrections: firstPassCorrections,
      );

      const issue = NaturalnessIssue(
        span: 'hizo una decisión',
        naturalReplacement: 'tomó una decisión',
        explanation: '"Hacer una decisión" is a calque.',
      );
      final merge = mergeNaturalnessReview(
        originalText: submittedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );
      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );

      expect(
        result.correctedText,
        'El profesor dijo que debía estudiar más, y ella tomó una '
        'decisión importante.',
      );
      expect(result.corrections, hasLength(2));
      expect(
        result.corrections.any(
          (item) =>
              item.correctedPhrase == 'debía' &&
              item.category == ErrorCategory.spelling,
        ),
        isTrue,
      );
      expect(
        result.corrections.any(
          (item) =>
              item.correctedPhrase == 'tomó una decisión' &&
              item.category == ErrorCategory.naturalLanguage,
        ),
        isTrue,
      );
    },
  );

  test(
    'pronoun deletion (empty corrected_phrase, whitespace-absorbing) plus '
    'a naturalness edit later in the text',
    () {
      const submittedText =
          'Yo fui a casa, y yo hice una decisión importante.';
      // Case-sensitive match: "Yo" (capitalized, sentence-initial) is a
      // different string from "yo", so the lowercase "yo" after the comma
      // is occurrence 1 of "yo", not occurrence 2.
      final resolvedDeletion = resolveOccurrenceCorrections(submittedText, [
        const OccurrenceCorrection(originalPhrase: 'yo', occurrence: 1),
      ]).single;
      final deletionStart = resolvedDeletion.startIndex!;
      final deletionEnd = deletionStart + 'yo'.length;

      final firstPassCorrections = computeCorrectedRanges([
        CorrectionItem(
          originalPhrase: 'yo',
          correctedPhrase: '',
          category: ErrorCategory.grammar,
          shortExplanation: 'Redundant subject pronoun.',
          startIndex: deletionStart,
          endIndex: deletionEnd,
        ),
      ], submittedText: submittedText);

      final firstPassResponse = CorrectionResponse(
        originalText: submittedText,
        correctedText: 'Yo fui a casa, y hice una decisión importante.',
        corrections: firstPassCorrections,
      );
      // Confirms the fixture is genuinely a pronoun deletion (empty
      // correctedPhrase) before layering naturalness on top of it.
      expect(firstPassResponse.corrections.single.correctedPhrase, isEmpty);

      const issue = NaturalnessIssue(
        span: 'hice una decisión',
        naturalReplacement: 'tomé una decisión',
        explanation: 'Wrong collocation for "decisión".',
      );
      final merge = mergeNaturalnessReview(
        originalText: submittedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );
      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );

      expect(
        result.correctedText,
        'Yo fui a casa, y tomé una decisión importante.',
      );
      expect(result.corrections, hasLength(2));
      final deletionItem = result.corrections.firstWhere(
        (item) => item.originalPhrase == 'yo',
      );
      expect(deletionItem.correctedPhrase, isEmpty);
      final naturalnessItem = result.corrections.firstWhere(
        (item) => item.category == ErrorCategory.naturalLanguage,
      );
      expect(naturalnessItem.correctedPhrase, 'tomé una decisión');
    },
  );

  test(
    'missing naturalness span after the first pass changed that exact '
    'wording',
    () {
      const originalText = 'Ayer iso una decisión importante.';
      const firstPassCorrectedText = 'Ayer hizo una decisión importante.';

      final firstPassResponse = CorrectionResponse(
        originalText: originalText,
        correctedText: firstPassCorrectedText,
        corrections: const [],
      );

      // Span reflects the pre-first-pass (typo'd) wording — the parallel
      // naturalness pass reviewed originalText, which still had "iso", not
      // "hizo". That exact substring no longer exists in
      // firstPassCorrectedText at all.
      const issue = NaturalnessIssue(
        span: 'iso una decisión',
        naturalReplacement: 'tomó una decisión',
        explanation: '"Hacer una decisión" is a calque.',
      );
      final merge = mergeNaturalnessReview(
        originalText: originalText,
        firstPassCorrectedText: firstPassCorrectedText,
        naturalnessReview: const NaturalnessReview(
          hasNaturalnessIssue: true,
          issues: [issue],
        ),
      );

      expect(merge.appliedEdits, isEmpty);
      expect(merge.skippedEdits, hasLength(1));
      expect(
        merge.skippedEdits.single.reason,
        NaturalnessMergeSkipReason.spanNotFound,
      );
      // The merge still returns the unmodified first-pass text — a
      // conflict never means losing the safe first-pass corrections.
      expect(merge.finalCorrectedText, firstPassCorrectedText);

      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: merge,
      );
      expect(result.corrections, isEmpty);
      expect(result.correctedText, firstPassCorrectedText);
    },
  );

  test('overlapping naturalness edits: only the leftmost is applied', () {
    const firstPassCorrectedText = 'Voy a hacer una decisión importante hoy.';

    const issueEarly = NaturalnessIssue(
      span: 'hacer una decisión',
      naturalReplacement: 'tomar una decisión',
      explanation: 'Wrong collocation for "decisión".',
    );
    const issueLate = NaturalnessIssue(
      span: 'una decisión importante',
      naturalReplacement: 'una decisión clave',
      explanation: 'Overlaps the other candidate.',
    );

    final merge = mergeNaturalnessReview(
      originalText: 'placeholder',
      firstPassCorrectedText: firstPassCorrectedText,
      naturalnessReview: const NaturalnessReview(
        hasNaturalnessIssue: true,
        issues: [issueEarly, issueLate],
      ),
    );

    expect(
      merge.finalCorrectedText,
      'Voy a tomar una decisión importante hoy.',
    );
    expect(merge.appliedEdits, hasLength(1));
    expect(merge.appliedEdits.single.issue, same(issueEarly));
    expect(merge.skippedEdits, hasLength(1));
    expect(merge.skippedEdits.single.issue, same(issueLate));
    expect(
      merge.skippedEdits.single.reason,
      NaturalnessMergeSkipReason.overlapsAnotherEdit,
    );
  });

  test('no naturalness issue: the first-pass text passes through unchanged', () {
    const firstPassCorrectedText = 'Todo está muy bien.';

    final merge = mergeNaturalnessReview(
      originalText: firstPassCorrectedText,
      firstPassCorrectedText: firstPassCorrectedText,
      naturalnessReview: const NaturalnessReview(
        hasNaturalnessIssue: false,
        issues: [],
      ),
    );

    expect(merge.finalCorrectedText, firstPassCorrectedText);
    expect(merge.appliedEdits, isEmpty);
    expect(merge.skippedEdits, isEmpty);
  });

  group('malformed naturalness response', () {
    test('throws when has_naturalness_issue is missing', () {
      expect(
        () => NaturalnessReview.fromJson({
          'issues': [],
        }),
        throwsFormatException,
      );
    });

    test('throws when an issue is missing a required field', () {
      expect(
        () => NaturalnessReview.fromJson({
          'has_naturalness_issue': true,
          'issues': [
            {'span': 'x'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
