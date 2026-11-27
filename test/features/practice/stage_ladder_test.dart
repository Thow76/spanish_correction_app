import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/practice/domain/question.dart';
import 'package:spanish_correction_app/features/practice/domain/stage_ladder.dart';

// Step P.2: one test for each rule in the comment on `nextStage_` in the
// Spanish Games sheet script (docs/games_port_source/test_review.gs.txt).

LadderPosition at(int stage, {int locked = 0}) =>
    LadderPosition(stage: stage, lockedStage: locked);

const numbered = [
  LadderStage.one,
  LadderStage.two,
  LadderStage.three,
  LadderStage.four,
  LadderStage.five,
];

void main() {
  group('stageRank', () {
    test('stages 1 to 5 are ranks 1 to 5 and consolidation is 6', () {
      expect(numbered.map(stageRank), [1, 2, 3, 4, 5]);
      expect(stageRank(LadderStage.consolidation), consolidationRank);
      expect(consolidationRank, 6);
      expect(retiredRank, 7);
    });
  });

  group('right at stage N', () {
    test('moves to stage N+1, for every stage from 1 to 4', () {
      for (final stage in numbered.take(4)) {
        final n = stageRank(stage);
        expect(
          nextStage(at(n), at: stage, right: true),
          at(n + 1),
          reason: 'right at stage $n',
        );
      }
    });

    test('right at stage 5 moves to consolidation', () {
      expect(
        nextStage(at(5), at: LadderStage.five, right: true),
        at(consolidationRank),
      );
    });

    test('never moves a mistake back: right at a stage below its own '
        'leaves it where it is', () {
      expect(nextStage(at(4), at: LadderStage.one, right: true), at(4));
      expect(
        nextStage(at(consolidationRank), at: LadderStage.two, right: true),
        at(consolidationRank),
      );
    });

    test('a mistake not on the ladder yet joins it at N+1', () {
      expect(
        nextStage(at(notOnLadderRank), at: LadderStage.one, right: true),
        at(2),
      );
    });

    test('right at N−1 while stage N is locked: back to stage N, lock '
        'cleared', () {
      expect(
        nextStage(at(3, locked: 4), at: LadderStage.three, right: true),
        at(4),
      );
    });

    test('right at the locked stage itself clears the lock too', () {
      expect(
        nextStage(at(3, locked: 4), at: LadderStage.four, right: true),
        at(5),
      );
    });

    test('a lock above N+1 is kept', () {
      expect(
        nextStage(at(2, locked: 5), at: LadderStage.two, right: true),
        at(3, locked: 5),
      );
    });
  });

  group('wrong at stage N', () {
    test('from 2 to 5: drops to stage N−1 with stage N locked', () {
      for (final stage in numbered.skip(1)) {
        final n = stageRank(stage);
        expect(
          nextStage(at(n), at: stage, right: false),
          at(n - 1, locked: n),
          reason: 'wrong at stage $n',
        );
      }
    });

    test('wrong at stage 1: stays at stage 1 with no lock', () {
      expect(nextStage(at(1), at: LadderStage.one, right: false), at(1));
    });

    test('wrong at stage 1 after a drop from stage 2 clears the lock, as '
        'the script does', () {
      expect(
        nextStage(at(1, locked: 2), at: LadderStage.one, right: false),
        at(1),
      );
    });

    test('wrong again at N−1 after a drop: drops one more, and the lock '
        'moves down with it', () {
      expect(
        nextStage(at(3, locked: 4), at: LadderStage.three, right: false),
        at(2, locked: 3),
      );
    });

    test('a full drop and climb back: wrong at 4, right at 3, right at 4', () {
      var position = at(4);
      position = nextStage(position, at: LadderStage.four, right: false);
      expect(position, at(3, locked: 4));
      expect(position.hasLock, isTrue);
      position = nextStage(position, at: LadderStage.three, right: true);
      expect(position, at(4));
      expect(position.hasLock, isFalse);
      position = nextStage(position, at: LadderStage.four, right: true);
      expect(position, at(5));
    });
  });

  group('consolidation', () {
    test('right or wrong, the mistake is at consolidation with no lock', () {
      for (final right in [true, false]) {
        expect(
          nextStage(
            at(consolidationRank),
            at: LadderStage.consolidation,
            right: right,
          ),
          at(consolidationRank),
          reason: 'right: $right',
        );
      }
    });

    test('a consolidation answer never retires the mistake by itself', () {
      final position = nextStage(
        at(consolidationRank),
        at: LadderStage.consolidation,
        right: true,
      );
      expect(position.isRetired, isFalse);
    });

    test('retired once one consolidation question is passed and none is '
        'left', () {
      expect(
        afterConsolidationRound(
          at(consolidationRank),
          passedOne: true,
          anyLeft: false,
        ),
        at(retiredRank),
      );
    });

    test('not retired while a consolidation question is still to pass', () {
      expect(
        afterConsolidationRound(
          at(consolidationRank),
          passedOne: true,
          anyLeft: true,
        ),
        at(consolidationRank),
      );
    });

    test('not retired when none has been passed', () {
      expect(
        afterConsolidationRound(
          at(consolidationRank),
          passedOne: false,
          anyLeft: false,
        ),
        at(consolidationRank),
      );
    });

    test('a mistake below consolidation is never retired', () {
      expect(
        afterConsolidationRound(at(5), passedOne: true, anyLeft: false),
        at(5),
      );
    });
  });

  group('retired', () {
    test('a retired mistake stays retired, whatever is answered', () {
      for (final stage in LadderStage.values) {
        for (final right in [true, false]) {
          final position = nextStage(at(retiredRank), at: stage, right: right);
          expect(position, at(retiredRank), reason: '$stage, right: $right');
          expect(position.isRetired, isTrue);
        }
      }
    });
  });
}
