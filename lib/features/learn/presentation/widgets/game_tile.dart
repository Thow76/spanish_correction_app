import 'package:flutter/material.dart';

import '../../../../shared/design/app_colors.dart';
import '../../../../shared/design/app_spacing.dart';

class GameTile extends StatelessWidget {
  const GameTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.disabledLabel = 'Coming soon',
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String disabledLabel;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: enabled ? 0.16 : 0.08),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.cyan.withValues(
                  alpha: enabled ? 0.12 : 0.06,
                ),
                child: Icon(
                  icon,
                  color: enabled ? AppColors.cyan : AppColors.textDisabled,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontFamily: 'Sora',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (enabled)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 22,
                )
              else
                _DisabledLabel(label: disabledLabel),
            ],
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.58,
      duration: const Duration(milliseconds: 140),
      child: content,
    );
  }
}

class _DisabledLabel extends StatelessWidget {
  const _DisabledLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.textDisabled.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textDisabled.withValues(alpha: 0.6),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
