import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/practice/domain/match_round_check.dart';

// Step P.3: one test for each case in the comment on `checkMatchRound_` in
// the Spanish Games sheet script (docs/games_port_source/test_review.gs.txt).

// A rule with a fixed answer in every slot: which preposition a verb takes.
final prepositions = MatchRule(
  name: 'Verbs and their prepositions',
  slots: [
    MatchSlot(slot: '1', starts: ['pensar', 'confiar'], fixed: 'en'),
    MatchSlot(slot: '2', starts: ['soñar', 'contar'], fixed: 'con'),
    MatchSlot(slot: '3', starts: ['acordarse', 'tratar'], fixed: 'de'),
  ],
);

// A rule whose answers are free: a subject and any verb form for it.
final free = MatchRule(
  name: 'Subjects',
  slots: [
    MatchSlot(slot: 'yo', needs: 'a first person form', starts: ['yo']),
    MatchSlot(slot: 'tú', needs: 'a second person form', starts: ['tú']),
  ],
);

// A rule with two slots that accept the same starts.
final twoAlike = MatchRule(
  slots: [
    MatchSlot(slot: 'A', starts: ['ser', 'estar']),
    MatchSlot(slot: 'B', starts: ['ser', 'estar']),
  ],
);

final rules = {'R1': prepositions, 'R2': free, 'R3': twoAlike};

String? check(String ruleId, List<List<String>> pairs) =>
    checkMatchRound(ruleId, pairs, rules);

void main() {
  group('a round that passes', () {
    test('one pair for every slot, each with its fixed answer', () {
      expect(
        check('R1', [
          ['pensar', 'en'],
          ['soñar', 'con'],
          ['tratar', 'de'],
        ]),
        isNull,
      );
    });

    test('the pairs may come in any order', () {
      expect(
        check('R1', [
          ['acordarse', 'de'],
          ['confiar', 'en'],
          ['contar', 'con'],
        ]),
        isNull,
      );
    });

    test('starts and answers are compared without case or extra spaces', () {
      expect(
        check('R1', [
          ['  Pensar ', 'EN'],
          ['Soñar', ' con'],
          ['tratar', 'De '],
        ]),
        isNull,
      );
    });

    test('a slot with no fixed answer takes any answer', () {
      expect(
        check('R2', [
          ['yo', 'hablo'],
          ['tú', 'hablas'],
        ]),
        isNull,
      );
    });

    test('two slots that accept the same starts take one pair each', () {
      expect(
        check('R3', [
          ['ser', 'soy'],
          ['estar', 'estoy'],
        ]),
        isNull,
      );
    });
  });

  group('a round that fails', () {
    test('unknown rule', () {
      expect(
        check('R9', [
          ['pensar', 'en'],
        ]),
        'rule "R9" is not in the rule bank',
      );
    });

    test('no pairs', () {
      expect(check('R1', []), 'it has no pairs');
    });

    test('bad pair: not two parts', () {
      expect(
        check('R1', [
          ['pensar', 'en'],
          ['soñar'],
        ]),
        'pair 2 is not "start = answer"',
      );
      expect(
        check('R1', [
          ['pensar', 'en', 'de'],
        ]),
        'pair 1 is not "start = answer"',
      );
    });

    test('bad pair: an empty start or answer', () {
      expect(
        check('R1', [
          ['pensar', '  '],
        ]),
        'pair 1 is not "start = answer"',
      );
      expect(
        check('R1', [
          ['', 'en'],
        ]),
        'pair 1 is not "start = answer"',
      );
    });

    test('unknown start: in no slot\'s list', () {
      expect(
        check('R1', [
          ['pensar', 'en'],
          ['bailar', 'con'],
          ['tratar', 'de'],
        ]),
        '"bailar" is not an approved start for R1',
      );
    });

    test('accents are kept, so a start without its accent is unknown', () {
      expect(
        check('R1', [
          ['sonar', 'con'],
        ]),
        '"sonar" is not an approved start for R1',
      );
    });

    test('two pairs for a slot', () {
      expect(
        check('R1', [
          ['pensar', 'en'],
          ['confiar', 'en'],
          ['soñar', 'con'],
        ]),
        'two pairs use slot 1 ("confiar")',
      );
    });

    test('a third pair where two slots accept the same starts', () {
      expect(
        check('R3', [
          ['ser', 'soy'],
          ['estar', 'estoy'],
          ['ser', 'eres'],
        ]),
        'two pairs use slot A ("ser")',
      );
    });

    test('empty slot: a slot with no pair', () {
      expect(
        check('R1', [
          ['pensar', 'en'],
          ['soñar', 'con'],
        ]),
        'no pair for slot 3',
      );
      expect(
        check('R1', [
          ['pensar', 'en'],
        ]),
        'no pair for slot 2, 3',
      );
    });

    test('wrong fixed answer', () {
      expect(
        check('R1', [
          ['pensar', 'de'],
          ['soñar', 'con'],
          ['tratar', 'de'],
        ]),
        '"pensar" should be matched with "en", not "de"',
      );
    });

    test('duplicate answers', () {
      expect(
        check('R2', [
          ['yo', 'habla'],
          ['tú', 'Habla'],
        ]),
        'the answer "Habla" appears twice',
      );
    });
  });

  group('ruleKey', () {
    test('trims, collapses spaces and ignores case, and keeps accents', () {
      expect(ruleKey('  Tener   QUE '), 'tener que');
      expect(ruleKey('Soñar'), isNot(ruleKey('sonar')));
      expect(ruleKey(null), '');
    });
  });
}
