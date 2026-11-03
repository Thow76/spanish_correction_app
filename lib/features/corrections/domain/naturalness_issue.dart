/// One flagged phrase from the naturalness review pass (gpt-5.1) — the
/// `{"span": "...", "natural_replacement": "...", "explanation": "..."}`
/// shape confirmed in `docs/naturalness_review_output_contract.md` against
/// `test/naturalness_model_comparison_harness.dart`.
///
/// Deliberately has no position or occurrence field of its own — the
/// naturalness contract doesn't supply one. See
/// `docs/naturalness_review_output_contract.md` for the anchoring gap that
/// leaves for production code; this type only represents what the model
/// itself returns.
class NaturalnessIssue {
  const NaturalnessIssue({
    required this.span,
    required this.naturalReplacement,
    required this.explanation,
  });

  /// The exact substring the naturalness pass flagged as unnatural.
  final String span;

  /// A more natural replacement for [span].
  final String naturalReplacement;

  /// Why [span] is unnatural, for learner-facing feedback.
  final String explanation;

  /// Parses one issue from the naturalness pass's `issues[]` array. Throws
  /// [FormatException] when `span`, `natural_replacement`, or `explanation`
  /// is missing or not a string, rather than guessing — the same
  /// fail-predictably precedent as `CorrectionItem.fromAnchoredJson`.
  factory NaturalnessIssue.fromJson(Map<String, Object?> json) {
    final span = json['span'];
    if (span is! String) {
      throw const FormatException('Naturalness issue is missing "span".');
    }

    final naturalReplacement = json['natural_replacement'];
    if (naturalReplacement is! String) {
      throw const FormatException(
        'Naturalness issue is missing "natural_replacement".',
      );
    }

    final explanation = json['explanation'];
    if (explanation is! String) {
      throw const FormatException(
        'Naturalness issue is missing "explanation".',
      );
    }

    return NaturalnessIssue(
      span: span,
      naturalReplacement: naturalReplacement,
      explanation: explanation,
    );
  }
}
