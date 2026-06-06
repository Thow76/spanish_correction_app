import '../../saved/domain/saved_correction.dart';

class GameQuestion {
  const GameQuestion({
    required this.source,
    required this.promptPhrase,
    required this.expectedAnswer,
  });

  final SavedCorrection source;
  final String promptPhrase;
  final String expectedAnswer;
}
