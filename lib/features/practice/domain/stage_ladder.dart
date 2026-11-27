/// The stage ladder: where a mistake goes after one answer (practice track,
/// step P.2; decisions G1 and G6).
///
/// Ported from `nextStage_` in the Spanish Games sheet script
/// (`docs/games_port_source/test_review.gs.txt`), with the same rules and
/// the same numbers. A mistake's place is kept as a rank:
/// 0 = not on the ladder yet, 1 to 5 = the five stages, 6 = consolidation,
/// 7 = retired (finished).
///
/// Logic only: nothing here stores anything. The practice database (P.5)
/// keeps each mistake's stage and locked stage, and the Guided rules (P.9)
/// decide when an answer is allowed to move a mistake at all.
library;

import 'question.dart';

/// The rank of a mistake that is not on the ladder yet, and the value of
/// [LadderPosition.lockedStage] when nothing is locked.
const int notOnLadderRank = 0;

/// The rank of the first stage.
const int firstStageRank = 1;

/// The rank of the last numbered stage.
const int lastStageRank = 5;

/// The rank of consolidation, the rounds after stage 5.
const int consolidationRank = 6;

/// The rank of a retired mistake: every step passed, nothing left to play.
const int retiredRank = 7;

/// The ladder rank of a question's stage: 1 to 5, consolidation 6.
int stageRank(LadderStage stage) => stage.number ?? consolidationRank;

/// Where one mistake stands on the ladder.
class LadderPosition {
  const LadderPosition({
    required this.stage,
    this.lockedStage = notOnLadderRank,
  }) : assert(stage >= notOnLadderRank && stage <= retiredRank),
       assert(lockedStage >= notOnLadderRank && lockedStage <= lastStageRank);

  /// The stage the mistake is at, as a rank (see the library comment).
  final int stage;

  /// The stage the mistake dropped back from and has to win back, as a
  /// rank from 2 to 5, or [notOnLadderRank] (0) when nothing is locked.
  final int lockedStage;

  /// Whether a stage is waiting to be won back.
  bool get hasLock => lockedStage != notOnLadderRank;

  /// Whether the mistake is finished.
  bool get isRetired => stage == retiredRank;

  @override
  bool operator ==(Object other) =>
      other is LadderPosition &&
      other.stage == stage &&
      other.lockedStage == lockedStage;

  @override
  int get hashCode => Object.hash(stage, lockedStage);

  @override
  String toString() => 'LadderPosition(stage: $stage, locked: $lockedStage)';
}

/// Where a mistake goes after one answer to a question at stage [at].
///
/// - **Right at stage N (1 to 5):** the mistake moves to stage N+1 (after
///   stage 5, consolidation). It never moves back: a right answer at a
///   stage below the mistake's own leaves it where it is. A lock at or
///   below N+1 is cleared, which covers "right at N−1 while stage N is
///   locked: back to stage N, lock cleared".
/// - **Wrong at stage N (2 to 5):** the mistake drops to stage N−1 and
///   stage N is locked.
/// - **Wrong at stage 1:** it stays at stage 1 with no lock, because there
///   is nothing below to drop back to.
/// - **Consolidation:** the mistake is at consolidation, right or wrong,
///   with no lock. Retiring is decided separately, once every
///   consolidation question of the mistake has been passed (see
///   [afterConsolidationRound]).
/// - **A retired mistake stays retired.**
LadderPosition nextStage(
  LadderPosition position, {
  required LadderStage at,
  required bool right,
}) {
  if (position.isRetired) return const LadderPosition(stage: retiredRank);
  final rank = stageRank(at);
  if (rank == consolidationRank) {
    return const LadderPosition(stage: consolidationRank);
  }
  if (right) {
    final reached = rank + 1;
    final locked = position.lockedStage;
    return LadderPosition(
      stage: position.stage > reached ? position.stage : reached,
      lockedStage: locked != notOnLadderRank && locked <= reached
          ? notOnLadderRank
          : locked,
    );
  }
  return rank >= 2
      ? LadderPosition(stage: rank - 1, lockedStage: rank)
      : const LadderPosition(stage: firstStageRank);
}

/// Retires a mistake once its consolidation is finished, as the script did
/// when it saved a batch of answers: a mistake at consolidation with at
/// least one consolidation question answered right ([passedOne]) and no
/// consolidation question still to pass ([anyLeft] false) is retired.
/// Anything else is returned unchanged.
LadderPosition afterConsolidationRound(
  LadderPosition position, {
  required bool passedOne,
  required bool anyLeft,
}) {
  if (position.stage == consolidationRank && passedOne && !anyLeft) {
    return const LadderPosition(stage: retiredRank);
  }
  return position;
}
