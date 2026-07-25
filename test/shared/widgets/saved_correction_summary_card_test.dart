import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/shared/widgets/saved_correction_summary_card.dart';

const _explanation = SavedExplanation(
  whyItsWrong: 'why',
  inContext: 'context',
  alternatives: [],
);

SavedCorrection _buildCorrection({
  required String originalPhrase,
  required String correctedPhrase,
}) {
  return SavedCorrection(
    id: 'sc-1',
    category: ErrorCategory.grammar,
    shortExplanation: 'Redundant subject pronoun.',
    originalSentence: 'Yo yo quiero ir.',
    explanation: _explanation,
    savedAt: DateTime(2026, 1, 1),
    correctedPhrase: correctedPhrase,
    originalPhrase: originalPhrase,
    correctedSentence: 'Yo quiero ir.',
    promptPhrase: 'I want to go.',
    language: Language.spanish,
  );
}

Future<void> pumpCard(WidgetTester tester, SavedCorrection correction) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SavedCorrectionSummaryCard(correction: correction, onTap: () {}),
      ),
    ),
  );
}

void main() {
  group('SavedCorrectionSummaryCard', () {
    testWidgets('shows correctedPhrase as the headline for a normal correction', (
      tester,
    ) async {
      await pumpCard(
        tester,
        _buildCorrection(originalPhrase: 'hubo', correctedPhrase: 'había'),
      );

      expect(find.text('había'), findsOneWidget);
    });

    testWidgets(
      'falls back to originalPhrase, underlined, for a pure-deletion '
      'correction (empty correctedPhrase)',
      (tester) async {
        await pumpCard(
          tester,
          _buildCorrection(originalPhrase: 'yo', correctedPhrase: ''),
        );

        // The headline is never blank — it shows the word being removed.
        expect(find.text('yo'), findsOneWidget);

        final headline = tester.widget<Text>(find.text('yo'));
        expect(headline.style?.decoration, TextDecoration.underline);
      },
    );
  });
}
