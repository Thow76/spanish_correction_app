import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/features/saved/presentation/saved_detail_screen.dart';

const _explanation = SavedExplanation(
  whyItsWrong: 'Redundant subject pronoun.',
  inContext: 'Yo quiero ir.',
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

void main() {
  group('SavedDetailScreen', () {
    testWidgets('shows correctedPhrase in the title for a normal correction', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SavedDetailScreen(
            correction: _buildCorrection(
              originalPhrase: 'hubo',
              correctedPhrase: 'había',
            ),
          ),
        ),
      );

      expect(find.text('"había"'), findsOneWidget);
    });

    testWidgets(
      'falls back to originalPhrase in the title for a pure-deletion '
      'correction, instead of empty quotes',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SavedDetailScreen(
              correction: _buildCorrection(
                originalPhrase: 'yo',
                correctedPhrase: '',
              ),
            ),
          ),
        );

        expect(find.text('""'), findsNothing);
        expect(find.text('"yo"'), findsOneWidget);

        final title = tester.widget<Text>(find.text('"yo"'));
        expect(title.style?.decoration, TextDecoration.underline);
      },
    );
  });
}
