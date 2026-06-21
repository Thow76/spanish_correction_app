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

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WalkthroughQuestionView(
            questions: questions,
            onCompleted: ({required correctCount, required totalCount}) {},
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
}
