import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/presentation/corrections_screen.dart';

/// Build step 2.4 (decisions C1 and C5): the results screen's wording. No
/// "Corrections", "Corrected" or "error" anywhere; the improved text is the
/// suggested version; the points sit under the headings Issues and
/// Suggestions; one standing line; Save is the only action.
void main() {
  const issue = CorrectionItem(
    originalPhrase: 'fue',
    correctedPhrase: 'fui',
    category: ErrorCategory.grammar,
    shortExplanation: 'With "yo" the preterite of ir is "fui".',
    startIndex: 8,
    endIndex: 11,
    correctedStartIndex: 8,
    correctedEndIndex: 11,
  );
  const suggestion = CorrectionItem(
    originalPhrase: 'hice una decisión',
    correctedPhrase: 'tomé una decisión',
    category: ErrorCategory.naturalPhrasing,
    shortExplanation: 'In Spanish a decision is taken, not made.',
    startIndex: 26,
    endIndex: 43,
    correctedStartIndex: 26,
    correctedEndIndex: 43,
  );
  const original = 'Ayer yo fue al mercado y hice una decisión.';
  const suggested = 'Ayer yo fui al mercado y tomé una decisión.';

  Future<void> pumpScreen(
    WidgetTester tester,
    CorrectionResponse response, {
    ValueChanged<CorrectionItem>? onSave,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CorrectionsScreen(
          response: response,
          onSaveCorrection: onSave ?? (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ErrorCategory.group', () {
    test('Spelling, Grammar and Word Choice are Issues', () {
      expect(ErrorCategory.spelling.group, FeedbackGroup.issue);
      expect(ErrorCategory.grammar.group, FeedbackGroup.issue);
      expect(ErrorCategory.wordChoice.group, FeedbackGroup.issue);
    });

    test('Natural phrasing is a Suggestion', () {
      expect(ErrorCategory.naturalPhrasing.group, FeedbackGroup.suggestion);
    });
  });

  testWidgets(
    'shows the title, the standing line, the suggested version and the two '
    'headings with each point under its own group',
    (tester) async {
      const response = CorrectionResponse(
        originalText: original,
        correctedText: suggested,
        corrections: [issue, suggestion],
      );

      await pumpScreen(tester, response);

      expect(find.text('Feedback'), findsOneWidget);
      expect(
        find.text(
          'These are AI suggestions. Check anything that surprises you.',
        ),
        findsOneWidget,
      );
      expect(find.text('Original'), findsOneWidget);
      expect(find.text('Suggested version'), findsOneWidget);
      expect(find.text(suggested), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);
      expect(find.text('Suggestions'), findsOneWidget);
      expect(find.text('Copy suggested version'), findsOneWidget);

      // Each point is listed under its group, in order down the screen:
      // the suggested version, then Issues, then Suggestions.
      final suggestedY = tester.getTopLeft(find.text('Suggested version')).dy;
      final issuesY = tester.getTopLeft(find.text('Issues')).dy;
      final issueRowY = tester
          .getTopLeft(find.text('With "yo" the preterite of ir is "fui".'))
          .dy;
      final suggestionsY = tester.getTopLeft(find.text('Suggestions')).dy;
      final suggestionRowY = tester
          .getTopLeft(find.text('In Spanish a decision is taken, not made.'))
          .dy;
      expect(suggestedY, lessThan(issuesY));
      expect(issuesY, lessThan(issueRowY));
      expect(issueRowY, lessThan(suggestionsY));
      expect(suggestionsY, lessThan(suggestionRowY));

      // Each row names the category.
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('Natural phrasing'), findsOneWidget);

      // The old words are gone.
      expect(find.textContaining('Correct'), findsNothing);
      expect(find.textContaining('error'), findsNothing);
      expect(find.text('None'), findsNothing);
    },
  );

  testWidgets('an empty group still shows its heading, with "None"', (
    tester,
  ) async {
    const response = CorrectionResponse(
      originalText: 'Ayer yo fue al mercado.',
      correctedText: 'Ayer yo fui al mercado.',
      corrections: [issue],
    );

    await pumpScreen(tester, response);

    expect(find.text('Issues'), findsOneWidget);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.text('None'), findsOneWidget);
    final suggestionsY = tester.getTopLeft(find.text('Suggestions')).dy;
    final noneY = tester.getTopLeft(find.text('None')).dy;
    expect(suggestionsY, lessThan(noneY));
  });

  testWidgets('with nothing found there are no group headings', (tester) async {
    const response = CorrectionResponse(
      originalText: 'Hola, ¿cómo estás?',
      correctedText: 'Hola, ¿cómo estás?',
      corrections: [],
    );

    await pumpScreen(tester, response);

    expect(find.text('Suggested version'), findsOneWidget);
    expect(find.text('Nothing to suggest for this text.'), findsOneWidget);
    expect(find.text('Issues'), findsNothing);
    expect(find.text('Suggestions'), findsNothing);
    expect(find.text('None'), findsNothing);
    expect(find.textContaining('Correct'), findsNothing);
  });

  testWidgets(
    'tapping a listed point opens the sheet with its group and category, '
    'and Save for Later is the only action',
    (tester) async {
      const response = CorrectionResponse(
        originalText: original,
        correctedText: suggested,
        corrections: [issue, suggestion],
      );
      final saved = <CorrectionItem>[];

      await pumpScreen(tester, response, onSave: saved.add);
      await tester.tap(find.text('In Spanish a decision is taken, not made.'));
      await tester.pumpAndSettle();

      // The sheet: the suggested phrase large, then the pills.
      expect(find.text('Suggestion'), findsOneWidget);
      expect(find.text('Natural phrasing'), findsNWidgets(2));
      expect(find.text('Save for Later'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Save for Later'),
        findsOneWidget,
      );
      expect(find.textContaining('Not useful'), findsNothing);
      expect(find.textContaining('Ignore'), findsNothing);

      await tester.tap(find.text('Save for Later'));
      await tester.pumpAndSettle();

      expect(saved, [suggestion]);
      expect(find.text('Save for Later'), findsNothing);
    },
  );

  testWidgets('an Issue opened from the sheet says Issue', (tester) async {
    const response = CorrectionResponse(
      originalText: original,
      correctedText: suggested,
      corrections: [issue, suggestion],
    );

    await pumpScreen(tester, response);
    await tester.tap(find.text('With "yo" the preterite of ir is "fui".'));
    await tester.pumpAndSettle();

    expect(find.text('Issue'), findsOneWidget);
    expect(find.text('Suggestion'), findsNothing);
  });
}
