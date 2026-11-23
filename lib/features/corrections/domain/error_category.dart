import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';

/// The two groups a feedback point can belong to (decision C1): Issues are
/// the clear mistakes the first step of the check finds; Suggestions are the
/// natural-phrasing points the second step finds. The results screen shows
/// the points under one heading per group.
enum FeedbackGroup {
  issue('Issue', 'Issues'),
  suggestion('Suggestion', 'Suggestions');

  const FeedbackGroup(this.label, this.heading);

  /// The name of one point of this group ("Issue").
  final String label;

  /// The heading over the group's points ("Issues").
  final String heading;
}

/// The four kinds of feedback point (decision C3, revised 21 Nov 2026).
///
/// Spelling, Grammar and Word Choice are Issues (the first step of the
/// check); Natural phrasing is the one Suggestion category (the second step).
/// The order here is the order the filters in Saved and the game show them.
enum ErrorCategory {
  spelling('Spelling', AppColors.spelling, legacyPromptLabel: 'Spelling'),
  grammar('Grammar', AppColors.grammar, legacyPromptLabel: 'Grammar'),
  wordChoice(
    'Word Choice',
    AppColors.wordChoice,
    legacyPromptLabel: 'Word Choice',
  ),
  naturalPhrasing(
    'Natural phrasing',
    AppColors.naturalPhrasing,
    legacyPromptLabel: 'Natural Language',
  );

  const ErrorCategory(
    this.label,
    this.color, {
    required this.legacyPromptLabel,
  });

  final String label;
  final Color color;

  /// The group this category belongs to. Fixed here, not by the AI: the
  /// two-step check's first step returns only Issue categories and its
  /// second step only Natural phrasing, so the category says the group.
  FeedbackGroup get group => this == ErrorCategory.naturalPhrasing
      ? FeedbackGroup.suggestion
      : FeedbackGroup.issue;

  /// The name the older prompts still use for this category: the old
  /// one-call check, the Portuguese check, the explanation written when a
  /// point is saved, and the game's grader. Those prompts are left as they
  /// are, so they are sent the old name and their replies are read back with
  /// [fromApiLabel], which understands both the old and the new names.
  final String legacyPromptLabel;

  /// Other names for these categories, and the category each belongs to:
  /// names kept on the phone by earlier versions, names the older prompts
  /// still return, and the name the two-step check's prompt uses for Word
  /// Choice until build step 2.2c brings it into line.
  ///
  /// "Other" is gone as a category (C3). A point that was filed under it is
  /// kept and filed under Natural phrasing, the Suggestions group, since it
  /// was a point the older check could not place as a clear mistake.
  static const Map<String, ErrorCategory> renamedLabels = {
    'Natural Language': ErrorCategory.naturalPhrasing,
    'Other': ErrorCategory.naturalPhrasing,
    'Word meaning': ErrorCategory.wordChoice,
  };

  /// Reads a category kept on the phone. Never fails: old names are renamed,
  /// and anything not recognised is filed under Natural phrasing.
  static ErrorCategory fromLabel(String value) {
    final normalizedValue = value.trim();

    if (normalizedValue == 'Punctuation' || normalizedValue == 'Preposition') {
      return ErrorCategory.grammar;
    }

    final renamed = renamedLabels[normalizedValue];
    if (renamed != null) {
      return renamed;
    }

    return ErrorCategory.values.firstWhere(
      (category) => category.label == normalizedValue,
      orElse: () => ErrorCategory.naturalPhrasing,
    );
  }

  /// Reads a category returned by an AI call. Accepts the four names and the
  /// other names in [renamedLabels]; anything else is refused.
  static ErrorCategory fromApiLabel(String value) {
    final normalizedValue = value.trim();

    for (final category in ErrorCategory.values) {
      if (category.label == normalizedValue) {
        return category;
      }
    }

    final renamed = renamedLabels[normalizedValue];
    if (renamed != null) {
      return renamed;
    }

    throw FormatException('Unsupported correction category "$value".');
  }

  /// True when [value] is one of the old names that the one-time rename on
  /// the phone replaces.
  static bool isLegacyLabel(String value) =>
      renamedLabels.containsKey(value.trim());
}
