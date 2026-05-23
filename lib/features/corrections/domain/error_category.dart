import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';

enum ErrorCategory {
  grammar('Grammar', AppColors.grammar),
  spelling('Spelling', AppColors.spelling),
  punctuation('Punctuation', AppColors.naturalLanguage),
  wordChoice('Word Choice', AppColors.wordChoice),
  preposition('Preposition', AppColors.mint),
  naturalLanguage('Natural Language', AppColors.naturalLanguage),
  other('Other', AppColors.other);

  const ErrorCategory(this.label, this.color);

  final String label;
  final Color color;

  static ErrorCategory fromLabel(String value) {
    return ErrorCategory.values.firstWhere(
      (category) => category.label == value,
      orElse: () => ErrorCategory.other,
    );
  }
}
