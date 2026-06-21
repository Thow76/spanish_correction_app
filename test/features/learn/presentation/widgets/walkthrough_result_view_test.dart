import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/learn/presentation/widgets/walkthrough_result_view.dart';
import 'package:spanish_correction_app/shared/design/app_colors.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required int correct,
    required int total,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughResultView(correctCount: correct, totalCount: total),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

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
}
