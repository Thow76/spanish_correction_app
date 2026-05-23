import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/domain/error_category.dart';
import '../domain/saved_correction.dart';
import 'saved_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({required this.repositoryController, super.key});

  final CorrectionRepositoryController repositoryController;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  @override
  void initState() {
    super.initState();
    widget.repositoryController.addListener(_handleRepositoryChanged);
    widget.repositoryController.loadSavedCorrections();
  }

  @override
  void dispose() {
    widget.repositoryController.removeListener(_handleRepositoryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedCorrections = _groupCorrections(
      widget.repositoryController.savedCorrections,
    );

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: [
              const AppHeader(title: 'Saved'),
              const SizedBox(height: AppSpacing.xl),
              if (groupedCorrections.isEmpty)
                const EmptyStatePanel(
                  icon: Icons.bookmark_border,
                  title: 'No saved corrections',
                  message:
                      'Tap a highlighted correction and save it to build your review list.',
                )
              else
                ...groupedCorrections.entries.expand((entry) {
                  return [
                    _CategoryHeader(category: entry.key),
                    const SizedBox(height: AppSpacing.sm),
                    ...entry.value.map(
                      (correction) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _SavedCorrectionCard(
                          correction: correction,
                          onTap: () => _openDetail(correction),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ];
                }),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openDetail(SavedCorrection correction) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SavedDetailScreen(correction: correction),
      ),
    );
  }

  Map<ErrorCategory, List<SavedCorrection>> _groupCorrections(
    List<SavedCorrection> corrections,
  ) {
    final grouped = <ErrorCategory, List<SavedCorrection>>{};
    for (final correction in corrections) {
      grouped.putIfAbsent(correction.category, () => []).add(correction);
    }

    for (final values in grouped.values) {
      values.sort((left, right) => right.savedAt.compareTo(left.savedAt));
    }

    return grouped;
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final ErrorCategory category;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          category.label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Sora',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SavedCorrectionCard extends StatelessWidget {
  const _SavedCorrectionCard({required this.correction, required this.onTap});

  final SavedCorrection correction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: correction.category.color.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      correction.correctedPhrase,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: correction.category.color,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(correction.savedAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
