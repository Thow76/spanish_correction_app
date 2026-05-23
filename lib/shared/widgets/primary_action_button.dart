import 'package:flutter/material.dart';

import '../design/app_colors.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final borderColor = isEnabled ? AppColors.cyan : AppColors.textDisabled;
    final fillColor = isEnabled
        ? AppColors.cyan.withValues(alpha: 0.12)
        : AppColors.textDisabled.withValues(alpha: 0.12);

    return SizedBox(
      height: 52,
      width: double.infinity,
      child: FilledButton(
        onPressed: isEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          disabledBackgroundColor: fillColor,
          backgroundColor: fillColor,
          foregroundColor: isEnabled
              ? AppColors.textPrimary
              : AppColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 2),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox.square(
                  key: ValueKey('loader'),
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cyan,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
