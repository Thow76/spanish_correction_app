import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/answer_view.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/shared/widgets/collapsible_section.dart';
import 'package:spanish_correction_app/shared/widgets/highlighted_sentence.dart';

SavedCorrection _correction({
  String originalPhrase = 'llamaron de vuelta',
  String originalSentence = 'Ayer me llamaron de vuelta del banco.',
  ErrorCategory category = ErrorCategory.naturalLanguage,
  String shortExplanation = 'A more natural phrasing exists.',
  String inContext = 'Spanish prefers "devolver la llamada" here.',
  String whyItsWrong = 'The phrase is a calque from English and sounds unnatural.',
  int? startIndex = 8,
  int? endIndex = 26,
}) {
  return SavedCorrection(
    id: 'sc-1',
    category: category,
    shortExplanation: shortExplanation,
    originalSentence: originalSentence,
    explanation: SavedExplanation(
      whyItsWrong: whyItsWrong,
      inContext: inContext,
      alternatives: const [],
    ),
    savedAt: DateTime(2026, 6, 21),
    correctedPhrase: 'devolvieron la llamada',
    originalPhrase: originalPhrase,
    correctedSentence: 'Ayer me devolvieron la llamada del banco.',
    promptPhrase: 'Yesterday they called me back from the bank.',
    language: Language.spanish,
    startIndex: startIndex,
    endIndex: endIndex,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required SavedCorrection correction,
  bool isLastQuestion = false,
  VoidCallback? onForward,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            AnswerView(
              correction: correction,
              isLastQuestion: isLastQuestion,
              onForward: onForward ?? () {},
              str: (es, pt) => es,
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the five content fields', (tester) async {
    await _pump(tester, correction: _correction());

    // Wrong phrase, in the category colour.
    final phrase = tester.widget<Text>(find.text('llamaron de vuelta'));
    expect(phrase.style?.color, ErrorCategory.naturalLanguage.color);

    // Category pill label.
    expect(find.text('Natural Language'), findsOneWidget);

    // Intro paragraph (in-context).
    expect(
      find.text('Spanish prefers "devolver la llamada" here.'),
      findsOneWidget,
    );

    // Detailed "why it's wrong".
    expect(
      find.text('The phrase is a calque from English and sounds unnatural.'),
      findsOneWidget,
    );

    // Original sentence section is present.
    expect(find.byType(HighlightedSentence), findsOneWidget);
  });

  testWidgets('intro falls back to shortExplanation when inContext is empty', (
    tester,
  ) async {
    await _pump(
      tester,
      correction: _correction(
        inContext: '   ',
        shortExplanation: 'Short fallback explanation.',
      ),
    );

    expect(find.text('Short fallback explanation.'), findsOneWidget);
  });

  testWidgets('underlines the wrong phrase in the original sentence', (
    tester,
  ) async {
    await _pump(tester, correction: _correction());

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(HighlightedSentence),
        matching: find.byType(RichText),
      ),
    );

    final underlined = <String>[];
    (richText.text as TextSpan).visitChildren((span) {
      if (span is TextSpan &&
          span.style?.decoration == TextDecoration.underline) {
        underlined.add(span.text ?? '');
      }
      return true;
    });

    expect(underlined.join(), contains('llamaron de vuelta'));
  });

  testWidgets('underlines via substring fallback when the span is null', (
    tester,
  ) async {
    // Older records saved without character ranges: the shared helper must fall
    // back to substring matching so the phrase still underlines.
    await _pump(
      tester,
      correction: _correction(startIndex: null, endIndex: null),
    );

    final richText = tester.widget<RichText>(
      find.descendant(
        of: find.byType(HighlightedSentence),
        matching: find.byType(RichText),
      ),
    );

    final underlined = <String>[];
    (richText.text as TextSpan).visitChildren((span) {
      if (span is TextSpan &&
          span.style?.decoration == TextDecoration.underline) {
        underlined.add(span.text ?? '');
      }
      return true;
    });

    expect(underlined.join(), contains('llamaron de vuelta'));
  });

  testWidgets('forward button label flips on isLastQuestion', (tester) async {
    await _pump(tester, correction: _correction(), isLastQuestion: false);
    expect(find.text('Siguiente pregunta'), findsOneWidget);
    expect(find.text('Terminar'), findsNothing);

    await _pump(tester, correction: _correction(), isLastQuestion: true);
    expect(find.text('Terminar'), findsOneWidget);
    expect(find.text('Siguiente pregunta'), findsNothing);
  });

  testWidgets('forward button invokes onForward', (tester) async {
    var tapped = 0;
    await _pump(
      tester,
      correction: _correction(),
      onForward: () => tapped++,
    );

    await tester.tap(find.byKey(const Key('answer-forward')));
    await tester.pump();

    expect(tapped, 1);
  });

  testWidgets('tapping a section header toggles its collapsed state', (
    tester,
  ) async {
    await _pump(tester, correction: _correction());

    CollapsibleSection whySection() => tester.widget<CollapsibleSection>(
      find.byKey(const Key('answer-why-section')),
    );

    expect(whySection().isCollapsed, isFalse);

    await tester.tap(find.text('Por qué está mal'));
    await tester.pumpAndSettle();

    expect(whySection().isCollapsed, isTrue);
  });
}
