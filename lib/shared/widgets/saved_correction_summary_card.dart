import 'package:flutter/material.dart';

import '../../features/saved/domain/saved_correction.dart';
import '../design/app_colors.dart';
import '../design/app_spacing.dart';

/// Compact card summarizing one [SavedCorrection]: a left bar in the
/// category's color, the bold `correctedPhrase` as the primary label, and a
/// short-explanation preview underneath — the same content the Saved list
/// has always shown.
///
/// [trailing] is caller-supplied so the same layout can serve different
/// screens: `SavedScreen` passes a formatted save date, a selection picker
/// might pass a check indicator or nothing. [selected] adds a
/// category-colored border + soft glow (matching `CategorySquareChip`'s own
/// selected treatment) for screens where tapping the card toggles a
/// selection rather than opening a detail view.
class SavedCorrectionSummaryCard extends StatelessWidget {
  const SavedCorrectionSummaryCard({
    required this.correction,
    required this.onTap,
    this.trailing,
    this.selected = false,
    super.key,
  });

  final SavedCorrection correction;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final categoryColor = correction.category.color;
    // A pure-deletion correction (e.g. removing a redundant pronoun) has an
    // empty correctedPhrase by design — there's no replacement text, the fix
    // IS the removal. Falling back to originalPhrase (the word being
    // removed), underlined the same way _SavedErrorLabel marks a flagged
    // original phrase, keeps the headline from going blank while still
    // reading as "this is what's flagged," not "this is the suggested fix."
    final isDeletion = correction.correctedPhrase.isEmpty;
    final headline = isDeletion
        ? correction.originalPhrase
        : correction.correctedPhrase;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? categoryColor
                  : AppColors.cyan.withValues(alpha: 0.14),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: categoryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(color: categoryColor),
                  child: const SizedBox(width: 2),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                decoration: isDeletion
                                    ? TextDecoration.underline
                                    : null,
                                decorationColor: categoryColor,
                              ),
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        correction.shortExplanation,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 21 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
