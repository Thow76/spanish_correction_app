import 'naturalness_issue.dart';

/// A full naturalness-pass response — the
/// `{"has_naturalness_issue": bool, "issues": [...]}` shape confirmed in
/// `docs/naturalness_review_output_contract.md` against
/// `test/naturalness_model_comparison_harness.dart`.
class NaturalnessReview {
  const NaturalnessReview({
    required this.hasNaturalnessIssue,
    required this.issues,
  });

  /// Whether the reviewed text has any naturalness issue at all. Always
  /// consistent with whether [issues] is empty — [fromJson] rejects any
  /// response where the two disagree.
  final bool hasNaturalnessIssue;

  final List<NaturalnessIssue> issues;

  /// Parses a naturalness-pass response. Throws [FormatException] when
  /// `has_naturalness_issue` or `issues` is missing or malformed, when any
  /// entry in `issues` fails [NaturalnessIssue.fromJson], or when
  /// `has_naturalness_issue` disagrees with whether `issues` is empty — the
  /// same cross-check `parseNaturalnessResponse` in
  /// `test/naturalness_model_comparison_harness.dart` already validates.
  factory NaturalnessReview.fromJson(Map<String, Object?> json) {
    final hasNaturalnessIssue = json['has_naturalness_issue'];
    if (hasNaturalnessIssue is! bool) {
      throw const FormatException(
        'Naturalness review is missing "has_naturalness_issue".',
      );
    }

    final rawIssues = json['issues'];
    if (rawIssues is! List) {
      throw const FormatException('Naturalness review is missing "issues".');
    }

    final issues = <NaturalnessIssue>[];
    for (final rawIssue in rawIssues) {
      if (rawIssue is! Map<String, Object?>) {
        throw const FormatException(
          'Naturalness review "issues" entry is not an object.',
        );
      }
      issues.add(NaturalnessIssue.fromJson(rawIssue));
    }

    if (hasNaturalnessIssue != issues.isNotEmpty) {
      throw FormatException(
        'Naturalness review "has_naturalness_issue" ($hasNaturalnessIssue) '
        'disagrees with whether "issues" is empty (${issues.length} issues).',
      );
    }

    return NaturalnessReview(
      hasNaturalnessIssue: hasNaturalnessIssue,
      issues: List.unmodifiable(issues),
    );
  }
}
