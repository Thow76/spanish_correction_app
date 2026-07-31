import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_note.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_issue.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';

void main() {
  group('mapNaturalnessEditsIntoCorrectionResponse', () {
    test(
      'combines a first-pass correction and an applied naturalness edit '
      'into one response, both anchored to the original text, with '
      'correct corrected-side ranges for both',
      () {
        const originalText =
            'El profesor dijo que devia estudiar más, y ella hizo una '
            'decisión importante.';
        const firstPassCorrectedText =
            'El profesor dijo que debía estudiar más, y ella hizo una '
            'decisión importante.';
        const finalCorrectedText =
            'El profesor dijo que debía estudiar más, y ella tomó una '
            'decisión importante.';
        final deviaIndex = originalText.indexOf('devia');
        final deviaCorrectedIndex = firstPassCorrectedText.indexOf('debía');
        final naturalnessSpanIndex = originalText.indexOf(
          'hizo una decisión',
        );
        final naturalnessSpanFirstPassIndex = firstPassCorrectedText.indexOf(
          'hizo una decisión',
        );

        final firstPassResponse = CorrectionResponse(
          originalText: originalText,
          correctedText: firstPassCorrectedText,
          corrections: [
            CorrectionItem(
              originalPhrase: 'devia',
              correctedPhrase: 'debía',
              category: ErrorCategory.spelling,
              shortExplanation: 'Devia is missing its accent: debía.',
              startIndex: deviaIndex,
              endIndex: deviaIndex + 'devia'.length,
              correctedStartIndex: deviaCorrectedIndex,
              correctedEndIndex: deviaCorrectedIndex + 'debía'.length,
            ),
          ],
        );

        const issue = NaturalnessIssue(
          span: 'hizo una decisión',
          naturalReplacement: 'tomó una decisión',
          explanation: '"Hacer una decisión" is a calque.',
        );
        final naturalnessMerge = NaturalnessMergeResult(
          originalText: originalText,
          firstPassCorrectedText: firstPassCorrectedText,
          finalCorrectedText: finalCorrectedText,
          appliedEdits: [
            AppliedNaturalnessEdit(
              issue: issue,
              startIndex: naturalnessSpanFirstPassIndex,
              endIndex:
                  naturalnessSpanFirstPassIndex +
                  'hizo una decisión'.characters.length,
            ),
          ],
          skippedEdits: const [],
        );

        final result = mapNaturalnessEditsIntoCorrectionResponse(
          firstPassResponse: firstPassResponse,
          naturalnessMerge: naturalnessMerge,
        );

        expect(result.originalText, originalText);
        expect(result.correctedText, finalCorrectedText);
        expect(result.corrections, hasLength(2));

        final grammarItem = result.corrections.firstWhere(
          (item) => item.originalPhrase == 'devia',
        );
        expect(grammarItem.correctedPhrase, 'debía');
        expect(grammarItem.category, ErrorCategory.spelling);
        // "debía" is same-length as "devia", and the naturalness edit comes
        // after it in the text, so its corrected range is unshifted — but
        // verified here by slicing the actual final text, not by trusting
        // the untouched index.
        _expectSlice(
          result.correctedText,
          grammarItem.correctedStartIndex,
          grammarItem.correctedEndIndex,
          'debía',
        );

        final naturalnessItem = result.corrections.firstWhere(
          (item) => item.originalPhrase == 'hizo una decisión',
        );
        expect(naturalnessItem.correctedPhrase, 'tomó una decisión');
        expect(naturalnessItem.category, ErrorCategory.naturalLanguage);
        expect(
          naturalnessItem.shortExplanation,
          '"Hacer una decisión" is a calque.',
        );
        expect(naturalnessItem.startIndex, naturalnessSpanIndex);
        expect(
          naturalnessItem.endIndex,
          naturalnessSpanIndex + 'hizo una decisión'.length,
        );
        _expectSlice(
          result.correctedText,
          naturalnessItem.correctedStartIndex,
          naturalnessItem.correctedEndIndex,
          'tomó una decisión',
        );
      },
    );

    test(
      'shifts a first-pass correction\'s corrected-side range when an '
      'earlier naturalness edit changes the text length (the bug this '
      'test guards against: stale corrected ranges after a two-pass merge)',
      () {
        const originalText =
            'Voy a hacer una decisión, y luego devia estudiar.';
        const firstPassCorrectedText =
            'Voy a hacer una decisión, y luego debía estudiar.';
        final deviaCorrectedIndex = firstPassCorrectedText.indexOf('debía');

        final firstPassResponse = CorrectionResponse(
          originalText: originalText,
          correctedText: firstPassCorrectedText,
          corrections: [
            CorrectionItem(
              originalPhrase: 'devia',
              correctedPhrase: 'debía',
              category: ErrorCategory.spelling,
              shortExplanation: 'Devia is missing its accent: debía.',
              startIndex: originalText.indexOf('devia'),
              endIndex: originalText.indexOf('devia') + 'devia'.length,
              correctedStartIndex: deviaCorrectedIndex,
              correctedEndIndex: deviaCorrectedIndex + 'debía'.length,
            ),
          ],
        );

        // A naturalness edit earlier in the text that shortens it
        // considerably — "hacer una decisión" (18 graphemes) ->
        // "decidir" (7 graphemes) — so "debía"'s corrected position must
        // shift left once the naturalness edit is spliced in ahead of it.
        const span = 'hacer una decisión';
        const replacement = 'decidir';
        final spanFirstPassIndex = firstPassCorrectedText.indexOf(span);
        const issue = NaturalnessIssue(
          span: span,
          naturalReplacement: replacement,
          explanation: 'Simplify the collocation.',
        );
        final naturalnessMerge = NaturalnessMergeResult(
          originalText: originalText,
          firstPassCorrectedText: firstPassCorrectedText,
          finalCorrectedText: firstPassCorrectedText.replaceFirst(
            span,
            replacement,
          ),
          appliedEdits: [
            AppliedNaturalnessEdit(
              issue: issue,
              startIndex: spanFirstPassIndex,
              endIndex: spanFirstPassIndex + span.characters.length,
            ),
          ],
          skippedEdits: const [],
        );

        final result = mapNaturalnessEditsIntoCorrectionResponse(
          firstPassResponse: firstPassResponse,
          naturalnessMerge: naturalnessMerge,
        );

        final grammarItem = result.corrections.firstWhere(
          (item) => item.originalPhrase == 'devia',
        );
        // The real assertion: slicing the ACTUAL final corrected text at
        // this item's (possibly shifted) corrected range must land exactly
        // on "debía" — not wherever the old, unshifted index used to point.
        _expectSlice(
          result.correctedText,
          grammarItem.correctedStartIndex,
          grammarItem.correctedEndIndex,
          'debía',
        );

        final expectedDelta =
            replacement.characters.length - span.characters.length;
        expect(
          grammarItem.correctedStartIndex,
          deviaCorrectedIndex + expectedDelta,
        );
      },
    );

    test(
      'computes each naturalness item\'s own corrected-side range, '
      'accounting for an earlier naturalness edit\'s length change',
      () {
        const firstPassCorrectedText =
            'Voy a hacer una decisión y luego voy a hacer un paseo.';

        const earlierSpan = 'hacer una decisión';
        const earlierReplacement = 'decidir';
        const laterSpan = 'hacer un paseo';
        const laterReplacement = 'pasear un rato más';

        final firstPassResponse = CorrectionResponse(
          originalText: firstPassCorrectedText,
          correctedText: firstPassCorrectedText,
          corrections: const [],
        );

        const earlierIssue = NaturalnessIssue(
          span: earlierSpan,
          naturalReplacement: earlierReplacement,
          explanation: 'Simplify the collocation.',
        );
        const laterIssue = NaturalnessIssue(
          span: laterSpan,
          naturalReplacement: laterReplacement,
          explanation: 'Wrong collocation for "paseo".',
        );
        final earlierStart = firstPassCorrectedText.indexOf(earlierSpan);
        final laterStart = firstPassCorrectedText.indexOf(laterSpan);

        final naturalnessMerge = NaturalnessMergeResult(
          originalText: firstPassCorrectedText,
          firstPassCorrectedText: firstPassCorrectedText,
          finalCorrectedText: firstPassCorrectedText
              .replaceFirst(earlierSpan, earlierReplacement)
              .replaceFirst(laterSpan, laterReplacement),
          appliedEdits: [
            AppliedNaturalnessEdit(
              issue: earlierIssue,
              startIndex: earlierStart,
              endIndex: earlierStart + earlierSpan.characters.length,
            ),
            AppliedNaturalnessEdit(
              issue: laterIssue,
              startIndex: laterStart,
              endIndex: laterStart + laterSpan.characters.length,
            ),
          ],
          skippedEdits: const [],
        );

        final result = mapNaturalnessEditsIntoCorrectionResponse(
          firstPassResponse: firstPassResponse,
          naturalnessMerge: naturalnessMerge,
        );

        expect(result.corrections, hasLength(2));

        final earlierItem = result.corrections.firstWhere(
          (item) => item.originalPhrase == earlierSpan,
        );
        _expectSlice(
          result.correctedText,
          earlierItem.correctedStartIndex,
          earlierItem.correctedEndIndex,
          earlierReplacement,
        );

        final laterItem = result.corrections.firstWhere(
          (item) => item.originalPhrase == laterSpan,
        );
        // The critical check: the SECOND edit's corrected range must
        // already account for the first edit's length change, or this
        // slice will land on the wrong substring.
        _expectSlice(
          result.correctedText,
          laterItem.correctedStartIndex,
          laterItem.correctedEndIndex,
          laterReplacement,
        );
      },
    );

    test(
      'leaves startIndex/endIndex null when the naturalness span cannot be '
      'found in the original text (the first pass already changed the '
      'wording there)',
      () {
        const originalText = 'Ayer iso una decisión importante.';
        const firstPassCorrectedText = 'Ayer hizo una decisión importante.';
        const finalCorrectedText = 'Ayer tomó una decisión importante.';
        final spanFirstPassIndex = firstPassCorrectedText.indexOf(
          'hizo una decisión',
        );

        final firstPassResponse = CorrectionResponse(
          originalText: originalText,
          correctedText: firstPassCorrectedText,
          corrections: const [],
        );

        const issue = NaturalnessIssue(
          span: 'hizo una decisión',
          naturalReplacement: 'tomó una decisión',
          explanation: '"Hacer una decisión" is a calque.',
        );
        final naturalnessMerge = NaturalnessMergeResult(
          originalText: originalText,
          firstPassCorrectedText: firstPassCorrectedText,
          finalCorrectedText: finalCorrectedText,
          appliedEdits: [
            AppliedNaturalnessEdit(
              issue: issue,
              startIndex: spanFirstPassIndex,
              endIndex:
                  spanFirstPassIndex + 'hizo una decisión'.characters.length,
            ),
          ],
          skippedEdits: const [],
        );

        final result = mapNaturalnessEditsIntoCorrectionResponse(
          firstPassResponse: firstPassResponse,
          naturalnessMerge: naturalnessMerge,
        );

        expect(result.corrections, hasLength(1));
        final item = result.corrections.single;
        expect(item.originalPhrase, 'hizo una decisión');
        expect(item.correctedPhrase, 'tomó una decisión');
        expect(item.category, ErrorCategory.naturalLanguage);
        expect(item.startIndex, isNull);
        expect(item.endIndex, isNull);
        expect(result.correctedText, finalCorrectedText);
        // Corrected-side range is still computed (it's always knowable),
        // even though the original-side one could not be resolved.
        _expectSlice(
          result.correctedText,
          item.correctedStartIndex,
          item.correctedEndIndex,
          'tomó una decisión',
        );
      },
    );

    test(
      'leaves startIndex/endIndex null when the naturalness span occurs '
      'more than once in the original text',
      () {
        const originalText = 'Vi tráfico y vi tráfico otra vez.';
        final spanFirstPassIndex = originalText.indexOf('tráfico');

        final firstPassResponse = CorrectionResponse(
          originalText: originalText,
          correctedText: originalText,
          corrections: const [],
        );

        const issue = NaturalnessIssue(
          span: 'tráfico',
          naturalReplacement: 'tránsito',
          explanation: 'Tráfico as traffic is an anglicism.',
        );
        final naturalnessMerge = NaturalnessMergeResult(
          originalText: originalText,
          firstPassCorrectedText: originalText,
          finalCorrectedText: 'Vi tránsito y vi tráfico otra vez.',
          appliedEdits: [
            AppliedNaturalnessEdit(
              issue: issue,
              startIndex: spanFirstPassIndex,
              endIndex: spanFirstPassIndex + 'tráfico'.characters.length,
            ),
          ],
          skippedEdits: const [],
        );

        final result = mapNaturalnessEditsIntoCorrectionResponse(
          firstPassResponse: firstPassResponse,
          naturalnessMerge: naturalnessMerge,
        );

        final item = result.corrections.single;
        expect(item.startIndex, isNull);
        expect(item.endIndex, isNull);
      },
    );

    test('does not represent skipped naturalness edits as correction items', () {
      const originalText = 'Todo está bien.';

      final firstPassResponse = CorrectionResponse(
        originalText: originalText,
        correctedText: originalText,
        corrections: const [],
      );

      const issue = NaturalnessIssue(
        span: 'no existe',
        naturalReplacement: 'reemplazo',
        explanation: 'Never actually present.',
      );
      final naturalnessMerge = NaturalnessMergeResult(
        originalText: originalText,
        firstPassCorrectedText: originalText,
        finalCorrectedText: originalText,
        appliedEdits: const [],
        skippedEdits: const [
          SkippedNaturalnessEdit(
            issue: issue,
            reason: NaturalnessMergeSkipReason.spanNotFound,
          ),
        ],
      );

      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: naturalnessMerge,
      );

      expect(result.corrections, isEmpty);
      expect(result.correctedText, originalText);
    });

    test(
      'demotes, rather than drops, a naturalness item whose '
      'independently-resolved original-side range overlaps a first-pass '
      'correction\'s — the applied edit is still real, so it must still '
      'appear as a correction item alongside the first-pass one',
      () {
        const originalText = 'Voy a hacer una decisión importante hoy.';
        const finalCorrectedText =
            'Voy a tomar una decisión importante hoy.';
        final spanIndex = originalText.indexOf('hacer una decisión');

        final firstPassResponse = CorrectionResponse(
          originalText: originalText,
          correctedText: originalText,
          corrections: [
            CorrectionItem(
              originalPhrase: 'hacer una decisión',
              correctedPhrase: 'hacer una decisión',
              category: ErrorCategory.other,
              shortExplanation: 'Placeholder first-pass correction.',
              startIndex: spanIndex,
              endIndex: spanIndex + 'hacer una decisión'.length,
            ),
          ],
        );

        const issue = NaturalnessIssue(
          span: 'hacer una decisión',
          naturalReplacement: 'tomar una decisión',
          explanation: 'Wrong collocation for "decisión".',
        );
        final naturalnessMerge = NaturalnessMergeResult(
          originalText: originalText,
          firstPassCorrectedText: originalText,
          finalCorrectedText: finalCorrectedText,
          appliedEdits: [
            AppliedNaturalnessEdit(
              issue: issue,
              startIndex: spanIndex,
              endIndex: spanIndex + 'hacer una decisión'.characters.length,
            ),
          ],
          skippedEdits: const [],
        );

        final result = mapNaturalnessEditsIntoCorrectionResponse(
          firstPassResponse: firstPassResponse,
          naturalnessMerge: naturalnessMerge,
        );

        // Both items present — the naturalness edit genuinely changed
        // finalCorrectedText, so it must still be represented.
        expect(result.corrections, hasLength(2));

        final firstPassItem = result.corrections.firstWhere(
          (item) => item.category == ErrorCategory.other,
        );
        expect(
          firstPassItem.shortExplanation,
          'Placeholder first-pass correction.',
        );

        final naturalnessItem = result.corrections.firstWhere(
          (item) => item.category == ErrorCategory.naturalLanguage,
        );
        expect(naturalnessItem.correctedPhrase, 'tomar una decisión');
        expect(naturalnessItem.shortExplanation, isNotEmpty);
        // Demoted: its original-side range collided with the first-pass
        // item's, so it can't be highlighted on the original side.
        expect(naturalnessItem.startIndex, isNull);
        expect(naturalnessItem.endIndex, isNull);
        // But its corrected-side range is untouched by that demotion, and
        // must still correctly point at its replacement in the actual
        // final text.
        _expectSlice(
          result.correctedText,
          naturalnessItem.correctedStartIndex,
          naturalnessItem.correctedEndIndex,
          'tomar una decisión',
        );
      },
    );

    test('passes the first pass\'s notes through unchanged', () {
      const originalText = 'Cogí el autobús ayer.';

      final firstPassResponse = CorrectionResponse(
        originalText: originalText,
        correctedText: originalText,
        corrections: const [],
        notes: const [
          CorrectionNote(
            phrase: 'Cogí el autobús',
            note: 'Standard in Spain; avoided in parts of Latin America.',
          ),
        ],
      );

      final naturalnessMerge = NaturalnessMergeResult(
        originalText: originalText,
        firstPassCorrectedText: originalText,
        finalCorrectedText: originalText,
        appliedEdits: const [],
        skippedEdits: const [],
      );

      final result = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: naturalnessMerge,
      );

      expect(result.notes, hasLength(1));
      expect(result.notes.single.phrase, 'Cogí el autobús');
    });
  });
}

/// Slices [text] at `[start, end)` (grapheme clusters) and asserts it
/// equals [expected] — the strongest possible check on a corrected-side
/// range: it fails if the range is stale, unshifted, or otherwise wrong,
/// not just if it's missing.
void _expectSlice(String text, int? start, int? end, String expected) {
  expect(start, isNotNull);
  expect(end, isNotNull);
  expect(
    text.characters.skip(start!).take(end! - start).toString(),
    expected,
  );
}
