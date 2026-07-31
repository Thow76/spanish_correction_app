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
      'into one response, both anchored to the original text',
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
        final naturalnessSpanIndex = originalText.indexOf(
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
          appliedEdits: const [
            AppliedNaturalnessEdit(issue: issue, startIndex: 0, endIndex: 0),
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
          appliedEdits: const [
            AppliedNaturalnessEdit(issue: issue, startIndex: 0, endIndex: 0),
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
      },
    );

    test(
      'leaves startIndex/endIndex null when the naturalness span occurs '
      'more than once in the original text',
      () {
        const originalText = 'Vi tráfico y vi tráfico otra vez.';

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
          appliedEdits: const [
            AppliedNaturalnessEdit(issue: issue, startIndex: 0, endIndex: 0),
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
      'keeps the first-pass correction when its range overlaps a '
      'naturalness item\'s independently-resolved range',
      () {
        const originalText = 'Voy a hacer una decisión importante hoy.';
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
          finalCorrectedText:
              'Voy a tomar una decisión importante hoy.',
          appliedEdits: const [
            AppliedNaturalnessEdit(issue: issue, startIndex: 0, endIndex: 0),
          ],
          skippedEdits: const [],
        );

        final result = mapNaturalnessEditsIntoCorrectionResponse(
          firstPassResponse: firstPassResponse,
          naturalnessMerge: naturalnessMerge,
        );

        expect(result.corrections, hasLength(1));
        expect(result.corrections.single.category, ErrorCategory.other);
        expect(
          result.corrections.single.shortExplanation,
          'Placeholder first-pass correction.',
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
