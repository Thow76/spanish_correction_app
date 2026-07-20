import 'staged_correction_verdict.dart';

/// One flagged phrase as categorized by Stage 2
/// (`stage2CategorizationSpanish`), awaiting the rest of the staged
/// pipeline: its original-side position (resolved from [occurrence] by a
/// later pipeline step), any pure-insertion offset adjustment, dedup
/// against overlapping candidates, and — once split by [verdict] — Stage
/// 3's explanation text.
///
/// [category] is kept as Stage 2's raw label (or null, for
/// [StagedCorrectionVerdict.notAnError], which gets no category) rather
/// than an [ErrorCategory] — converting it is a later step's job, once a
/// candidate is known to actually become a `CorrectionItem`.
class StagedCorrectionCandidate {
  const StagedCorrectionCandidate({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.occurrence,
    required this.category,
    required this.verdict,
    this.startIndex,
    this.endIndex,
  });

  /// The exact substring Stage 2 was asked to categorize.
  final String originalPhrase;

  /// What [originalPhrase] should become. Identical to [originalPhrase]
  /// when [verdict] is [StagedCorrectionVerdict.notAnError].
  final String correctedPhrase;

  /// Which instance of [originalPhrase] in the submitted text this is,
  /// 1-based, left to right — Stage 2's own disambiguator, not yet resolved
  /// into a character position.
  final int occurrence;

  /// Stage 2's raw category label, or null for
  /// [StagedCorrectionVerdict.notAnError].
  final String? category;

  final StagedCorrectionVerdict verdict;

  /// Resolved grapheme-cluster start position within the original text, or
  /// null before resolution.
  final int? startIndex;

  /// Resolved grapheme-cluster end position (exclusive) within the original
  /// text, or null before resolution. Equal to [startIndex] for a
  /// zero-length insertion point.
  final int? endIndex;

  /// A copy of this candidate with the given fields replaced. [occurrence],
  /// [category], and [verdict] are never overridden — they're fixed once
  /// Stage 2 assigns them and every later pipeline step only ever adjusts
  /// phrases and position, never identity.
  StagedCorrectionCandidate copyWith({
    String? originalPhrase,
    String? correctedPhrase,
    int? startIndex,
    int? endIndex,
  }) {
    return StagedCorrectionCandidate(
      originalPhrase: originalPhrase ?? this.originalPhrase,
      correctedPhrase: correctedPhrase ?? this.correctedPhrase,
      occurrence: occurrence,
      category: category,
      verdict: verdict,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
    );
  }
}
