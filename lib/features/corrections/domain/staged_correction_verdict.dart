/// Stage 2's classification of a flagged phrase — see
/// `stage2CategorizationSpanish` in `correction_prompt.dart`.
enum StagedCorrectionVerdict {
  /// Not standard, idiomatic usage in any established variety.
  error('error'),

  /// Standard and idiomatic in at least one established variety, but
  /// carrying a materially different status in another.
  dialectal('dialectal'),

  /// Standard across varieties generally — not actually an error.
  notAnError('not_an_error');

  const StagedCorrectionVerdict(this.apiValue);

  /// The exact string Stage 2 returns for this verdict.
  final String apiValue;

  /// Looks up the verdict matching Stage 2's raw `verdict` string, or null
  /// if it doesn't match any of the three known values.
  static StagedCorrectionVerdict? fromApiValue(String value) {
    for (final verdict in StagedCorrectionVerdict.values) {
      if (verdict.apiValue == value) {
        return verdict;
      }
    }
    return null;
  }
}
