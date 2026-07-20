import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_note.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/presentation/corrections_screen.dart';

/// Step 5: the one state step 3 and step 4 could each pass in isolation
/// while still getting wrong together — `hasCorrections == false` (advisory
/// shown) and `notes` non-empty (Notes panel shown) at the same time. The
/// two conditionals are independent `if`s in `corrections_screen.dart`
/// (never `if`/`else if`), so neither should suppress the other.
void main() {
  testWidgets(
    'renders the advisory text and the Notes panel together when there are '
    'no corrections but there are notes, in the correct order',
    (tester) async {
      const response = CorrectionResponse(
        originalText: 'Vosotros coméis paella.',
        correctedText: 'Vosotros coméis paella.',
        corrections: [],
        notes: [
          CorrectionNote(
            phrase: 'vosotros coméis',
            note: 'Standard in Spain; not used in Latin America.',
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: CorrectionsScreen(response: response, onSaveCorrection: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Both surfaces are present — neither conditional suppressed the other.
      expect(find.text('No corrections required'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('vosotros coméis'), findsOneWidget);
      expect(
        find.text('Standard in Spain; not used in Latin America.'),
        findsOneWidget,
      );

      // Layout order: advisory -> Notes panel -> copy button.
      final advisoryY = tester
          .getTopLeft(find.text('No corrections required'))
          .dy;
      final notesTitleY = tester.getTopLeft(find.text('Notes')).dy;
      final copyButtonY = tester
          .getTopLeft(find.text('Copy corrected text'))
          .dy;

      expect(advisoryY, lessThan(notesTitleY));
      expect(notesTitleY, lessThan(copyButtonY));
    },
  );
}
