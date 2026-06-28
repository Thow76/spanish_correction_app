import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/learn/domain/game_question.dart';
import 'package:spanish_correction_app/features/learn/domain/game_session.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';

SavedCorrection _savedCorrection(String id) => SavedCorrection(
  id: id,
  category: ErrorCategory.grammar,
  shortExplanation: 'Watch the past tense.',
  originalSentence: 'Ayer hubo mucho tráfico',
  explanation: const SavedExplanation(
    whyItsWrong: 'why',
    inContext: 'context',
    alternatives: ['alt'],
  ),
  savedAt: DateTime(2026, 6, 21),
  correctedPhrase: 'había',
  originalPhrase: 'hubo',
  correctedSentence: 'Ayer había mucho tráfico',
  promptPhrase: 'Yesterday there was a lot of traffic',
  language: Language.spanish,
);

GameQuestion _question(String id) => GameQuestion(
  source: _savedCorrection(id),
  promptPhrase: 'prompt-$id',
  expectedAnswer: 'expected-$id',
);

GameSession _session({int count = 3}) => GameSession(
  questions: List.generate(count, (i) => _question('q$i')),
);

void main() {
  group('GameSession points model (recordPoints)', () {
    test('a fresh session starts at score 0 / maxScore 0', () {
      final session = _session();

      expect(session.score, 0);
      expect(session.maxScore, 0);
      expect(session.currentIndex, 0);
    });

    test('recordPoints(points: 2) yields score 2, maxScore 2', () {
      final session = _session().recordPoints(points: 2);

      expect(session.score, 2);
      expect(session.maxScore, 2);
      expect(session.currentIndex, 1);
    });

    test('answers of 2 then 1 accumulate to score 3, maxScore 4', () {
      final session = _session()
          .recordPoints(points: 2)
          .recordPoints(points: 1);

      expect(session.score, 3);
      expect(session.maxScore, 4);
      expect(session.currentIndex, 2);
    });

    test('recordPoints(points: 0) advances the index and adds nothing', () {
      final session = _session().recordPoints(points: 0);

      expect(session.score, 0);
      expect(session.maxScore, 2);
      expect(session.currentIndex, 1);
    });

    test('recordPoints does not mutate the original session', () {
      final original = _session();
      original.recordPoints(points: 2);

      expect(original.score, 0);
      expect(original.maxScore, 0);
      expect(original.currentIndex, 0);
    });

    test('recordPoints leaves the legacy correct/incorrect counts untouched', () {
      final session = _session().recordPoints(points: 2);

      expect(session.correctCount, 0);
      expect(session.incorrectCount, 0);
    });
  });
}
