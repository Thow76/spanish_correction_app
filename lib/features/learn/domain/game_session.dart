import 'game_question.dart';

class GameSession {
  const GameSession({
    required this.questions,
    this.currentIndex = 0,
    this.score = 0,
  });

  final List<GameQuestion> questions;
  final int currentIndex;

  /// Running points total for the session (X in the X/Y summary). Each answered
  /// question contributes its AI tier's weight (Excelente = 2, Bien hecho = 1,
  /// Sigue practicando / unavailable = 0), accumulated by [recordPoints].
  final int score;

  int get totalCount => questions.length;

  /// The score denominator (Y) — two points per answered question. Derived from
  /// [currentIndex], which advances by exactly one per answer (see
  /// [recordPoints]), so this equals 2 × answered.
  int get maxScore => currentIndex * 2;

  bool get isComplete => currentIndex >= questions.length;
  GameQuestion get currentQuestion => questions[currentIndex];

  /// Records [points] for the current answer and advances to the next question.
  /// Callers map the AI tier to a weight (0/1/2) and pass it here. Advances
  /// [currentIndex] by one (so [maxScore] grows by two per answer) and adds
  /// [points] to [score].
  GameSession recordPoints({required int points}) {
    return GameSession(
      questions: questions,
      currentIndex: currentIndex + 1,
      score: score + points,
    );
  }
}
