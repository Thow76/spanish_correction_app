import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_note.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/presentation/corrections_screen.dart';

/// Covers step 4's Notes panel: absent when `notes` is empty, renders every
/// phrase/note pair when non-empty. Uses a response with real corrections so
/// this stays independent of step 3's `hasCorrections` conditional — the
/// combined "no corrections AND has notes" state is covered separately in
/// step 5.
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

  const correction = CorrectionItem(
    originalPhrase: 'bien',
    correctedPhrase: 'bueno',
    category: ErrorCategory.wordChoice,
    shortExplanation: 'Bueno fits the noun being described.',
    startIndex: 5,
    endIndex: 9,
    correctedStartIndex: 5,
    correctedEndIndex: 10,
  );

  testWidgets('does not render a Notes panel when notes is empty', (
    tester,
  ) async {
    const response = CorrectionResponse(
      originalText: 'Hola bien',
      correctedText: 'Hola bueno',
      corrections: [correction],
    );

    await pumpScreen(tester, response);

    expect(find.text('Notes'), findsNothing);
  });

  testWidgets('renders every phrase/note pair when notes is non-empty', (
    tester,
  ) async {
    const response = CorrectionResponse(
      originalText: 'Hola bien',
      correctedText: 'Hola bueno',
      corrections: [correction],
      notes: [
        CorrectionNote(
          phrase: 'coger el autobús',
          note: 'Standard in Spain; avoided in parts of Latin America.',
        ),
        CorrectionNote(
          phrase: 'vosotros coméis',
          note: 'Standard in Spain; not used in Latin America.',
        ),
      ],
    );

    await pumpScreen(tester, response);

    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('coger el autobús'), findsOneWidget);
    expect(
      find.text('Standard in Spain; avoided in parts of Latin America.'),
      findsOneWidget,
    );
    expect(find.text('vosotros coméis'), findsOneWidget);
    expect(
      find.text('Standard in Spain; not used in Latin America.'),
      findsOneWidget,
    );
  });
}
