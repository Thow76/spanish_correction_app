import 'package:flutter/material.dart';

import '../../features/corrections/domain/error_category.dart';
import '../design/app_colors.dart';

/// A compact 44×40 colored square representing one [ErrorCategory] in a
/// filter row — the category's own color as the fill, a tooltip carrying the
/// label (so no text needs to fit inside the square), and a widened
/// white border + soft glow when [isSelected].
///
/// Purely presentational: callers own whatever selection model fits their
/// screen (single-select via a nullable current category, as in
/// `SavedScreen`, or multi-select via a `Set<ErrorCategory>`).
class CategorySquareChip extends StatelessWidget {
  const CategorySquareChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final ErrorCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: category.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 44,
          height: 40,
          decoration: BoxDecoration(
            color: category.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.textPrimary : category.color,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

/// A compact 44×40 chip matching [CategorySquareChip]'s footprint, but for an
/// action represented by an icon rather than a category color — e.g. the
/// session builder's review-mode toggle. The label lives in a [Tooltip], the
/// same way [CategorySquareChip] keeps its category name out of the chip
/// itself, so the chip stays exactly as narrow as the colored squares next to
/// it instead of widening the filter row with a spelled-out word.
class IconFilterChip extends StatelessWidget {
  const IconFilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cyan.withValues(alpha: 0.16)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.cyan
                  : AppColors.textDisabled.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.cyan : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A text pill that sits alongside a row of [CategorySquareChip]s for an
/// action that isn't itself a category — "Clear" (the default), used by both
/// `SavedScreen` and the session builder. Callers decide what
/// [isSelected]/[onTap] mean for their own filter model.
class ClearFilterChip extends StatelessWidget {
  const ClearFilterChip({
    required this.isSelected,
    required this.onTap,
    this.label = 'Clear',
    super.key,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.16)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : AppColors.textDisabled.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
