import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/walkthrough_result_view.dart';
import 'package:spanish_correction_app/shared/design/app_colors.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required int correct,
    required int total,
    VoidCallback? onContinue,
    VoidCallback? onTryAgain,
    VoidCallback? onSeeAnswer,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughResultView(
            correctCount: correct,
            totalCount: total,
            onContinue: onContinue ?? () {},
            onTryAgain: onTryAgain ?? () {},
            onSeeAnswer: onSeeAnswer ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final tryAgain = find.text('Intentar la traducción completa otra vez');
  final seeAnswer = find.text('Ver respuesta');

  Color percentColor(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style!.color!;

  testWidgets('satisfactory: 2/3 shows 67% in cyan with mid copy', (
    tester,
  ) async {
    await pump(tester, correct: 2, total: 3);

    expect(find.text('67%'), findsOneWidget);
    expect(percentColor(tester, '67%'), AppColors.cyan);
    expect(find.text('Buen esfuerzo — mejorará con la práctica.'), findsOneWidget);
  });

  testWidgets('success: 3/3 shows 100% in green with success copy', (
    tester,
  ) async {
    await pump(tester, correct: 3, total: 3);

    expect(find.text('100%'), findsOneWidget);
    expect(percentColor(tester, '100%'), AppColors.success);
    expect(find.text('El patrón ya te sale — excelente trabajo.'), findsOneWidget);
  });

  testWidgets('poor: 1/3 shows 33% in coral with poor copy', (tester) async {
    await pump(tester, correct: 1, total: 3);

    expect(find.text('33%'), findsOneWidget);
    expect(percentColor(tester, '33%'), AppColors.coral);
    expect(find.text('Difícil — cada repaso lo refuerza.'), findsOneWidget);
  });

  testWidgets('Continuar is shown and invokes onContinue on tap', (
    tester,
  ) async {
    var calls = 0;
    await pump(tester, correct: 3, total: 3, onContinue: () => calls++);

    expect(find.text('Continuar'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('success tier shows only Continuar', (tester) async {
    await pump(tester, correct: 3, total: 3);

    expect(find.text('Continuar'), findsOneWidget);
    expect(tryAgain, findsNothing);
    expect(seeAnswer, findsNothing);
  });

  testWidgets('satisfactory tier shows Continuar + Try-again', (tester) async {
    var tryAgainCalls = 0;
    await pump(tester, correct: 2, total: 3, onTryAgain: () => tryAgainCalls++);

    expect(find.text('Continuar'), findsOneWidget);
    expect(tryAgain, findsOneWidget);
    expect(seeAnswer, findsNothing);

    await tester.tap(tryAgain);
    await tester.pump();
    expect(tryAgainCalls, 1);
  });

  testWidgets('poor tier shows Continuar + See-Answer + Try-again', (
    tester,
  ) async {
    var tryAgainCalls = 0;
    var seeAnswerCalls = 0;
    await pump(
      tester,
      correct: 1,
      total: 3,
      onTryAgain: () => tryAgainCalls++,
      onSeeAnswer: () => seeAnswerCalls++,
    );

    expect(find.text('Continuar'), findsOneWidget);
    expect(seeAnswer, findsOneWidget);
    expect(tryAgain, findsOneWidget);

    await tester.tap(seeAnswer);
    await tester.pump();
    expect(seeAnswerCalls, 1);

    await tester.tap(tryAgain);
    await tester.pump();
    expect(tryAgainCalls, 1);
  });
}
