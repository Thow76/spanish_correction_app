import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/models/walkthrough_question.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/walkthrough_question_view.dart';
import 'package:spanish_correction_app/shared/design/app_colors.dart';

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

  testWidgets('renders the progress label for the first question', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Paso 1 de 3'), findsOneWidget);
  });

  testWidgets('the progress label advances with the cursor', (tester) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Voy'));
    await tester.pump();
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    await tester.pumpAndSettle();

    expect(find.text('Paso 2 de 3'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsNothing);
  });

  testWidgets('the stem is rendered inside the cyan card', (tester) async {
    await pump(tester);

    final stem = find.text('I am going');
    expect(stem, findsOneWidget);

    // The stem sits inside a Container decorated with the cyan-tinted fill.
    final card = tester
        .widgetList<Container>(
          find.ancestor(of: stem, matching: find.byType(Container)),
        )
        .firstWhere(
          (container) =>
              (container.decoration as BoxDecoration?)?.color ==
              AppColors.cyan.withValues(alpha: 0.06),
        );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.cyan.withValues(alpha: 0.06));
  });

  testWidgets('option buttons render badge letters a, b, c', (tester) async {
    await pump(tester, random: Random(1));

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    expect(find.text('c'), findsOneWidget);
  });

  testWidgets('a default option has the neutral decoration', (tester) async {
    await pump(tester, random: Random(1));

    final optionText = find.text('Voy');
    final button = tester
        .widgetList<Container>(
          find.ancestor(of: optionText, matching: find.byType(Container)),
        )
        .firstWhere(
          (container) => (container.decoration as BoxDecoration?)?.color ==
              AppColors.textDisabled.withValues(alpha: 0.12),
        );
    final decoration = button.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.textDisabled.withValues(alpha: 0.12));
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

    // 'Voy' is correct, which schedules an auto-advance timer; drain it so the
    // test ends with no pending timer.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
  });

  testWidgets('a second tap on a different option is ignored (locked)', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    // Commit a distractor (wrong) so the lock is proven without scheduling an
    // auto-advance timer — correctness is orthogonal to locking.
    await tester.tap(find.text('Va'));
    await tester.pump();
    expect(committedOption(tester), 'Va');

    // Lock holds: tapping a different option does not change the committed one.
    await tester.tap(find.text('Vamos'));
    await tester.pump();
    expect(committedOption(tester), 'Va');
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

    // Drain the correct-answer auto-advance timer.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
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

    // Drain the correct-answer auto-advance timer.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
  });

  final correctHighlight = find.byKey(
    const Key('walkthrough-correct-highlight'),
  );

  testWidgets('a wrong answer highlights the correct option', (tester) async {
    await pump(tester, random: Random(1));

    // 'Va' is a distractor; 'Voy' is the stored correct answer.
    await tester.tap(find.text('Va'));
    await tester.pump();

    expect(correctHighlight, findsOneWidget);
    // The highlighted option is the stored correct translation, not the tapped
    // distractor.
    expect(tester.widget<Text>(correctHighlight).data, 'Voy');
  });

  testWidgets('a correct answer shows no correct-option highlight', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Voy'));
    await tester.pump();

    expect(correctHighlight, findsNothing);

    // Drain the correct-answer auto-advance timer.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
  });

  final advance = find.byKey(const Key('walkthrough-advance'));
  final finished = find.byKey(const Key('walkthrough-finished'));

  testWidgets('a correct answer auto-advances after the pause and resets per-question state', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    // Answer Q0 correctly — no manual tap; the pause drives the advance.
    await tester.tap(find.text('Voy'));
    await tester.pump();
    expect(correctIndicator, findsOneWidget);

    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    await tester.pumpAndSettle();

    // Q1 is now shown, Q0 gone.
    expect(find.text('to get my hair cut'), findsOneWidget);
    expect(find.text('I am going'), findsNothing);

    // Per-question state is fresh: nothing committed, no correctness indicator.
    expect(committedOption(tester), isNull);
    expect(correctIndicator, findsNothing);
    expect(incorrectIndicator, findsNothing);
  });

  testWidgets('a correct answer does not advance before the pause elapses', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Voy'));
    await tester.pump();

    // Well under the delay: still on Q0, not finished.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('I am going'), findsOneWidget);
    expect(find.text('to get my hair cut'), findsNothing);
    expect(finished, findsNothing);

    // Drain the remaining time so the test ends clean.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
  });

  testWidgets('the correct path shows no manual advance control', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Voy'));
    await tester.pump();

    expect(advance, findsNothing);

    // Drain the auto-advance timer.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
  });

  testWidgets('the wrong path does not auto-advance and waits for the tap', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    await tester.tap(find.text('Va'));
    await tester.pump();

    // No timer on the wrong path: waiting past the delay stays on Q0.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    expect(find.text('I am going'), findsOneWidget);
    expect(find.text('to get my hair cut'), findsNothing);

    // The manual control is present and advances on tap.
    expect(advance, findsOneWidget);
    await tester.tap(advance);
    await tester.pumpAndSettle();
    expect(find.text('to get my hair cut'), findsOneWidget);
  });

  testWidgets('advancing past the last question shows the finished placeholder', (
    tester,
  ) async {
    await pump(tester, random: Random(1));

    // Walk all three questions: commit the correct option, then let the pause
    // auto-advance each.
    for (var i = 0; i < questions.length; i++) {
      await tester.tap(find.text(questions[i].correctTranslation));
      await tester.pump();
      await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
      await tester.pumpAndSettle();
    }

    // The finished marker is shown; no out-of-range crash occurred.
    expect(finished, findsOneWidget);
    // No question body remains.
    expect(find.text('on Saturday'), findsNothing);
  });

  testWidgets('onCompleted fires once with the running tally', (tester) async {
    var calls = 0;
    int? reportedCorrect;
    int? reportedTotal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            random: Random(1),
            onCompleted: ({required correctCount, required totalCount}) {
              calls++;
              reportedCorrect = correctCount;
              reportedTotal = totalCount;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Known mix: Q0 correct (auto), Q1 distractor/wrong (manual tap), Q2 correct
    // (auto) -> 2/3.
    // Q0 correct: pause auto-advances.
    await tester.tap(find.text(questions[0].correctTranslation));
    await tester.pump();
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    await tester.pumpAndSettle();

    // Q1 wrong: waits for the manual control.
    await tester.tap(find.text(questions[1].distractors.first));
    await tester.pump();
    await tester.tap(advance);
    await tester.pumpAndSettle();

    // Q2 correct: pause auto-advances and finishes.
    await tester.tap(find.text(questions[2].correctTranslation));
    await tester.pump();
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(reportedCorrect, 2);
    expect(reportedTotal, 3);
  });

  testWidgets('onCompleted does not fire before the last question', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            random: Random(1),
            onCompleted: ({required correctCount, required totalCount}) {
              calls++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Answer and advance only the first question (correct -> auto-advance).
    await tester.tap(find.text(questions[0].correctTranslation));
    await tester.pump();
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    await tester.pumpAndSettle();

    expect(calls, 0);
  });

  testWidgets('disposing during the pause cancels the auto-advance', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            random: Random(1),
            onCompleted: ({required correctCount, required totalCount}) {
              calls++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Commit a correct answer (schedules the auto-advance), then dispose the
    // widget mid-pause by pumping a replacement tree.
    await tester.tap(find.text(questions[0].correctTranslation));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());

    // Advance the clock past the delay: the cancelled timer must not fire, so
    // completion never runs and no pending-timer exception is thrown.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);

    expect(calls, 0);
  });

  testWidgets('interacting during the pause does not double-advance', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            random: Random(1),
            onCompleted: ({required correctCount, required totalCount}) {
              calls++;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Commit Q0 correctly, then tap the locked options during the pause.
    await tester.tap(find.text('Voy'));
    await tester.pump();
    await tester.tap(find.text('Va'));
    await tester.tap(find.text('Vamos'));
    await tester.pump();

    // After the pause, exactly one advance occurred: now on Q1, not Q2.
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    await tester.pumpAndSettle();

    expect(find.text('to get my hair cut'), findsOneWidget);
    expect(find.text('on Saturday'), findsNothing);
    expect(calls, 0);
  });

  testWidgets('a correct final answer auto-advances and fires onCompleted once', (
    tester,
  ) async {
    var calls = 0;
    int? reportedCorrect;
    int? reportedTotal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            random: Random(1),
            onCompleted: ({required correctCount, required totalCount}) {
              calls++;
              reportedCorrect = correctCount;
              reportedTotal = totalCount;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Q0 and Q1 correct (auto-advance), then Q2 correct (auto-advance -> finish).
    for (var i = 0; i < questions.length; i++) {
      await tester.tap(find.text(questions[i].correctTranslation));
      await tester.pump();
      await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
      await tester.pumpAndSettle();
    }

    expect(finished, findsOneWidget);
    expect(calls, 1);
    expect(reportedCorrect, 3);
    expect(reportedTotal, 3);
  });

  testWidgets('a wrong final answer waits for the tap, then fires onCompleted once', (
    tester,
  ) async {
    var calls = 0;
    int? reportedCorrect;
    int? reportedTotal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            random: Random(1),
            onCompleted: ({required correctCount, required totalCount}) {
              calls++;
              reportedCorrect = correctCount;
              reportedTotal = totalCount;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Q0 and Q1 correct (auto-advance) -> 2 banked, now on the final question.
    for (var i = 0; i < questions.length - 1; i++) {
      await tester.tap(find.text(questions[i].correctTranslation));
      await tester.pump();
      await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
      await tester.pumpAndSettle();
    }

    // Final question answered wrongly: it must wait for the manual tap.
    await tester.tap(find.text(questions.last.distractors.first));
    await tester.pump();
    await tester.pump(WalkthroughQuestionView.autoAdvanceDelay);
    expect(finished, findsNothing);
    expect(calls, 0);

    // Tapping the manual control finishes and fires completion exactly once.
    await tester.tap(advance);
    await tester.pumpAndSettle();

    expect(finished, findsOneWidget);
    expect(calls, 1);
    expect(reportedCorrect, 2);
    expect(reportedTotal, 3);
  });
}
