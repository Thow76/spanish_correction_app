/// Outcome tier for a finished walkthrough, derived from the score.
///
/// Thresholds (on the rounded percentage): [success] only at a perfect 100%,
/// [satisfactory] at 50–99%, [poor] below 50%.
enum WalkthroughTier { success, satisfactory, poor }

/// Pure score model for the walkthrough results screen.
///
/// Turns a raw tally into a rounded [percentage] and a [tier]. No Flutter
/// dependency — the widget layer renders from this. [totalCount] is always ≥ 1
/// in practice (the walkthrough has 3–5 questions), but the math is guarded so a
/// zero total yields 0% rather than dividing by zero.
class WalkthroughResult {
  const WalkthroughResult({
    required this.correctCount,
    required this.totalCount,
  });

  final int correctCount;
  final int totalCount;

  /// Correct answers as a rounded percentage of the total. Returns 0 when
  /// [totalCount] is 0 (zero-guard) rather than dividing by zero.
  int get percentage {
    if (totalCount <= 0) {
      return 0;
    }
    return (correctCount / totalCount * 100).round();
  }

  /// The tier derived from [percentage]: 100 → [WalkthroughTier.success],
  /// 50–99 → [WalkthroughTier.satisfactory], below 50 → [WalkthroughTier.poor].
  WalkthroughTier get tier {
    final value = percentage;
    if (value == 100) {
      return WalkthroughTier.success;
    }
    if (value >= 50) {
      return WalkthroughTier.satisfactory;
    }
    return WalkthroughTier.poor;
  }
}
