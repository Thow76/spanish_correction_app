import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/models/walkthrough_question.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/walkthrough_question_view.dart';

void main() {
  WalkthroughQuestion question(
    int chunkPosition, {
    required String stem,
    required String correct,
    required String distractor1,
    required String distractor2,
  }) {
    return WalkthroughQuestion(
      englishStem: stem,
      correctTranslation: correct,
      distractors: Distractors(first: distractor1, second: distractor2),
      chunkPosition: chunkPosition,
    );
  }

  final questions = [
    question(0, stem: 'I am going', correct: 'Voy', distractor1: 'Va', distractor2: 'Vamos'),
    question(1, stem: 'to get my hair cut', correct: 'a cortarme el pelo', distractor1: 'a cortar el pelo', distractor2: 'cortarme el pelo'),
    question(2, stem: 'on Saturday', correct: 'el sábado', distractor1: 'en sábado', distractor2: 'al sábado'),
  ];

  Future<void> pump(WidgetTester tester, {Random? random}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            onCompleted: ({required correctCount, required totalCount}) {},
            random: random,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the first question stem, cursor starts at 0', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('I am going'), findsOneWidget);
    // The cursor starts at the first question, not a later one.
    expect(find.text('to get my hair cut'), findsNothing);
    expect(find.text('on Saturday'), findsNothing);
  });

  testWidgets('renders the first question\'s three options (set membership)', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    // The three options are exactly {correct, distractor1, distractor2},
    // order-independent. The stored correct value is one of the three.
    expect(find.text('Voy'), findsOneWidget);
    expect(find.text('Va'), findsOneWidget);
    expect(find.text('Vamos'), findsOneWidget);
  });

  testWidgets('option order is stable across rebuilds', (tester) async {
    await pump(tester, random: Random(1));

    List<String> renderedOptionOrder() {
      const optionTexts = {'Voy', 'Va', 'Vamos'};
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .where(optionTexts.contains)
          .toList();
    }

    final firstOrder = renderedOptionOrder();
    expect(firstOrder, hasLength(3));

    // Re-pump the same widget tree: the framework reuses the existing State
    // (so initState/the shuffle does NOT re-run) and calls build() again. The
    // order must be identical — the shuffle is precomputed, not per-build.
    await pump(tester, random: Random(1));
    expect(renderedOptionOrder(), firstOrder);
  });

  // The data of the currently committed option, or null while unanswered.
  String? committedOption(WidgetTester tester) {
    final finder = find.byKey(const Key('walkthrough-selected-option'));
    if (finder.evaluate().isEmpty) {
      return null;
    }
    return tester.widget<Text>(finder).data;
  }

  testWidgets('tapping an option commits it', (tester) async {
    await pump(tester, random: Random(1));
    expect(committedOption(tester), isNull);

    await tester.tap(find.text('Voy'));
    await tester.pump();

    expect(committedOption(tester), 'Voy');
  });

  testWidgets('a second tap on a different option is ignored (locked)', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Voy'));
    await tester.pump();
    expect(committedOption(tester), 'Voy');

    // Lock holds: tapping a different option does not change the committed one.
    await tester.tap(find.text('Va'));
    await tester.pump();
    expect(committedOption(tester), 'Voy');
  });

  final correctIndicator = find.byKey(const Key('walkthrough-result-correct'));
  final incorrectIndicator = find.byKey(
    const Key('walkthrough-result-incorrect'),
  );

  testWidgets('no correctness indicator before an answer is committed', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    expect(correctIndicator, findsNothing);
    expect(incorrectIndicator, findsNothing);
  });

  testWidgets('committing the correct option marks it correct', (tester) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Voy'));
    await tester.pump();

    expect(correctIndicator, findsOneWidget);
    expect(incorrectIndicator, findsNothing);
  });

  testWidgets('committing a distractor marks it incorrect', (tester) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Va'));
    await tester.pump();

    expect(incorrectIndicator, findsOneWidget);
    expect(correctIndicator, findsNothing);
  });

  testWidgets('judging follows the stored value, not display position', (
    tester,
  ) async {
    // Random(1) renders the first question as [Vamos, Va, Voy]: the correct
    // answer ('Voy') is LAST, not first. Tapping it by its stored text must
    // still judge correct — proving the == follows the stored value, not the
    // shuffled display order.
    await pump(tester, random: Random(1));

    final firstRendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .firstWhere((data) => {'Voy', 'Va', 'Vamos'}.contains(data));
    expect(
      firstRendered,
      isNot('Voy'),
      reason: 'guard: the correct answer must not be first under this seed',
    );

    await tester.tap(find.text('Voy'));
    await tester.pump();
    expect(correctIndicator, findsOneWidget);
  });

  final advance = find.byKey(const Key('walkthrough-advance'));
  final finished = find.byKey(const Key('walkthrough-finished'));

  testWidgets('advancing moves to the next question and resets per-question state', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    // Answer Q0, then advance.
    await tester.tap(find.text('Voy'));
    await tester.pump();
    expect(correctIndicator, findsOneWidget);

    await tester.tap(advance);
    await tester.pumpAndSettle();

    // Q1 is now shown, Q0 gone.
    expect(find.text('to get my hair cut'), findsOneWidget);
    expect(find.text('I am going'), findsNothing);

    // Per-question state is fresh: nothing committed, no correctness indicator.
    expect(committedOption(tester), isNull);
    expect(correctIndicator, findsNothing);
    expect(incorrectIndicator, findsNothing);
  });

  testWidgets('advancing past the last question shows the finished placeholder', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    // Walk all three questions: commit any option, then advance.
    for (var i = 0; i < questions.length; i++) {
      await tester.tap(find.text(questions[i].correctTranslation));
      await tester.pump();
      await tester.tap(advance);
      await tester.pumpAndSettle();
    }

    // The finished marker is shown; no out-of-range crash occurred.
    expect(finished, findsOneWidget);
    // No question body remains.
    expect(find.text('on Saturday'), findsNothing);
  });
}
