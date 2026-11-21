import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';

/// The four kinds of feedback point (decision C3).
///
/// Spelling, Grammar and Word meaning are Issues (the first step of the
/// check); Natural phrasing is the one Suggestion category (the second step).
/// The order here is the order the filters in Saved and the game show them.
enum ErrorCategory {
  spelling('Spelling', AppColors.spelling, legacyPromptLabel: 'Spelling'),
  grammar('Grammar', AppColors.grammar, legacyPromptLabel: 'Grammar'),
  wordMeaning(
    'Word meaning',
    AppColors.wordMeaning,
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

  /// The name the older prompts still use for this category: the old
  /// one-call check, the Portuguese check, the explanation written when a
  /// point is saved, and the game's grader. Those prompts are left as they
  /// are, so they are sent the old name and their replies are read back with
  /// [fromApiLabel], which understands both the old and the new names.
  final String legacyPromptLabel;

  /// Old names, kept on the phone by earlier versions or returned by the
  /// older prompts, and the category each now belongs to.
  ///
  /// "Other" is gone as a category (C3). A point that was filed under it is
  /// kept and filed under Natural phrasing, the Suggestions group, since it
  /// was a point the older check could not place as a clear mistake.
  static const Map<String, ErrorCategory> legacyLabels = {
    'Word Choice': ErrorCategory.wordMeaning,
    'Natural Language': ErrorCategory.naturalPhrasing,
    'Other': ErrorCategory.naturalPhrasing,
  };

  /// Reads a category kept on the phone. Never fails: old names are renamed,
  /// and anything not recognised is filed under Natural phrasing.
  static ErrorCategory fromLabel(String value) {
    final normalizedValue = value.trim();

    if (normalizedValue == 'Punctuation' || normalizedValue == 'Preposition') {
      return ErrorCategory.grammar;
    }

    final legacy = legacyLabels[normalizedValue];
    if (legacy != null) {
      return legacy;
    }

    return ErrorCategory.values.firstWhere(
      (category) => category.label == normalizedValue,
      orElse: () => ErrorCategory.naturalPhrasing,
    );
  }

  /// Reads a category returned by an AI call. Accepts the four names and the
  /// old names the older prompts still ask for; anything else is refused.
  static ErrorCategory fromApiLabel(String value) {
    final normalizedValue = value.trim();

    for (final category in ErrorCategory.values) {
      if (category.label == normalizedValue) {
        return category;
      }
    }

    final legacy = legacyLabels[normalizedValue];
    if (legacy != null) {
      return legacy;
    }

    throw FormatException('Unsupported correction category "$value".');
  }

  /// True when [value] is one of the old names that the one-time rename on
  /// the phone replaces.
  static bool isLegacyLabel(String value) =>
      legacyLabels.containsKey(value.trim());
}
