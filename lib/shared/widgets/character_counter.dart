import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';

/// A 4px pill progress bar over a "count / limit" readout. The progress bar and
/// the text both shift from cyan to coral as the count nears the limit (within
/// the last 40 characters), matching the write screen's original behaviour.
class CharacterCounter extends StatelessWidget {
  const CharacterCounter({required this.count, required this.limit, super.key});

  final int count;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final progress = count / limit;
    final isNearLimit = count >= limit - 40;
    final color = isNearLimit ? AppColors.coral : AppColors.cyan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress.clamp(0, 1),
            backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$count / $limit',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
