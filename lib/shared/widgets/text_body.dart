import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// Body copy in the standard primary-text style (15/24), used inside detail and
/// answer-screen sections.
class TextBody extends StatelessWidget {
  const TextBody({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 24 / 15,
      ),
    );
  }
}
