import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';

class DividerLabel extends StatelessWidget {
  const DividerLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.textDisabled)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        const Expanded(child: Divider(color: AppColors.textDisabled)),
      ],
    );
  }
}
