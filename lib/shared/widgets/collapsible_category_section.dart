import 'package:flutter/material.dart';

import '../../features/corrections/domain/error_category.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';

/// A collapsible section header for a group of items belonging to one
/// [ErrorCategory]: a colored dot, the category label, an item count, and a
/// chevron that rotates and cross-fades [child] in/out via [onToggle].
///
/// Shared between `SavedScreen` (grouping saved corrections) and the session
/// builder (grouping selectable phrases) so both screens navigate multiple
/// categories the same way — collapse a category you've already gone through
/// to focus on the rest, rather than scrolling one long mixed list.
class CollapsibleCategorySection extends StatelessWidget {
  const CollapsibleCategorySection({
    required this.category,
    required this.itemCount,
    required this.isCollapsed,
    required this.onToggle,
    required this.child,
    super.key,
  });

  final ErrorCategory category;
  final int itemCount;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      category.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Sora',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: isCollapsed ? 0 : 0.5,
                    duration: const Duration(milliseconds: 160),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: child,
            crossFadeState: isCollapsed
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 160),
          ),
        ],
      ),
    );
  }
}
