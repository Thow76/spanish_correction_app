import 'game_question.dart';

class GameSession {
  const GameSession({
    required this.questions,
    this.currentIndex = 0,
    this.correctCount = 0,
    this.incorrectCount = 0,
  });

  final List<GameQuestion> questions;
  final int currentIndex;
  final int correctCount;
  final int incorrectCount;

  int get totalCount => questions.length;
  bool get isComplete => currentIndex >= questions.length;
  GameQuestion get currentQuestion => questions[currentIndex];

  GameSession recordAnswer({required bool isCorrect}) {
    return GameSession(
      questions: questions,
      currentIndex: currentIndex + 1,
      correctCount: correctCount + (isCorrect ? 1 : 0),
      incorrectCount: incorrectCount + (isCorrect ? 0 : 1),
    );
  }
}
