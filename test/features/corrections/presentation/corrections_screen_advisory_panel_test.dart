import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/presentation/corrections_screen.dart';

/// Covers step 3's conditional Corrected panel: real highlighted text when
/// `hasCorrections` is true (regression coverage for existing behaviour),
/// advisory text in its place when false.
void main() {
  Future<void> pumpScreen(WidgetTester tester, CorrectionResponse response) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CorrectionsScreen(response: response, onSaveCorrection: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'renders the real Corrected panel text when corrections is non-empty',
    (tester) async {
      const response = CorrectionResponse(
        originalText: 'Hola bien',
        correctedText: 'Hola bueno',
        corrections: [
          CorrectionItem(
            originalPhrase: 'bien',
            correctedPhrase: 'bueno',
            category: ErrorCategory.wordChoice,
            shortExplanation: 'Bueno fits the noun being described.',
            startIndex: 5,
            endIndex: 9,
            correctedStartIndex: 5,
            correctedEndIndex: 10,
          ),
        ],
      );

      await pumpScreen(tester, response);

      // Text.rich flattens its TextSpan children to plain text, so this
      // confirms the Corrected panel actually rendered the highlighted
      // corrected text, not just that the string exists somewhere.
      expect(find.text('Hola bueno'), findsOneWidget);
      expect(find.text('No corrections required'), findsNothing);
    },
  );

  testWidgets(
    'renders advisory text in place of the Corrected panel when corrections '
    'is empty',
    (tester) async {
      const response = CorrectionResponse(
        originalText: 'Hola, ¿cómo estás?',
        correctedText: 'Hola, ¿cómo estás?',
        corrections: [],
      );

      await pumpScreen(tester, response);

      expect(find.text('No corrections required'), findsOneWidget);
      // correctedText is identical to originalText here (as it always is
      // when corrections is empty), so this confirms the Corrected panel's
      // own Text.rich was replaced by the advisory — not just that the
      // string happens to appear once from the Original panel and once from
      // an unreplaced Corrected panel.
      expect(find.text('Hola, ¿cómo estás?'), findsOneWidget);
    },
  );
}
