import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF0D1B2A);
  static const surface = Color(0xFF1A2E42);
  static const cyan = Color(0xFF00D9FF);
  static const coral = Color(0xFFFF6B4A);
  static const mint = Color(0xFFA8E6CF);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFE8E8E8);
  static const textDisabled = Color(0xFF4A5568);

  /// Correct-answer green used by the walkthrough question states.
  static const success = Color(0xFF5DE4A0);

  /// Amber heading accent for the "Sigue practicando" result tier
  /// (Figma 596:1358, heading fill #F59E0B). A distinct semantic token rather
  /// than reusing the [naturalLanguage] error-category colour.
  static const amber = Color(0xFFF59E0B);

  static const grammar = Color(0xFF5B8DEF);
  static const spelling = Color(0xFFEF5B5B);
  static const wordChoice = Color(0xFF5BEF8D);
  static const naturalLanguage = Color(0xFFEFDC5B);
  static const other = Color(0xFF8B95A8);
}
