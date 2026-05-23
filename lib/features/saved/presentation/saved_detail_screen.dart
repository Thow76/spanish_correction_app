import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../domain/saved_correction.dart';

class SavedDetailScreen extends StatelessWidget {
  const SavedDetailScreen({required this.correction, super.key});

  final SavedCorrection correction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
              children: [
                AppHeader(
                  title: 'Saved',
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  '"${correction.correctedPhrase}"',
                  style: TextStyle(
                    color: correction.category.color,
                    fontFamily: 'Sora',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 36 / 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Saved ${_formatDate(correction.savedAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _CategoryPill(correction: correction),
                const SizedBox(height: AppSpacing.xl),
                _Section(
                  title: 'Short explanation',
                  body: correction.shortExplanation,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Original sentence',
                  body: correction.originalSentence,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'Detailed explanation',
                  body: correction.explanation.whyItsWrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.correction});

  final SavedCorrection correction;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: correction.category.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: correction.category.color.withValues(alpha: 0.7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            correction.category.label,
            style: TextStyle(
              color: correction.category.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              height: 24 / 15,
            ),
          ),
        ],
      ),
    );
  }
}
