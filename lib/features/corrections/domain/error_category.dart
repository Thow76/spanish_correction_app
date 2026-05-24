import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';

enum ErrorCategory {
  grammar('Grammar', AppColors.grammar),
  naturalLanguage('Natural Language', AppColors.naturalLanguage),
  spelling('Spelling', AppColors.spelling),
  wordChoice('Word Choice', AppColors.wordChoice),
  other('Other', AppColors.other);

  const ErrorCategory(this.label, this.color);

  final String label;
  final Color color;

  static ErrorCategory fromLabel(String value) {
    final normalizedValue = value.trim();

    if (normalizedValue == 'Punctuation' || normalizedValue == 'Preposition') {
      return ErrorCategory.grammar;
    }

    return ErrorCategory.values.firstWhere(
      (category) => category.label == normalizedValue,
      orElse: () => ErrorCategory.other,
    );
  }

  static ErrorCategory fromApiLabel(String value) {
    final normalizedValue = value.trim();

    for (final category in ErrorCategory.values) {
      if (category.label == normalizedValue) {
        return category;
      }
    }

    throw FormatException('Unsupported correction category "$value".');
  }
}
