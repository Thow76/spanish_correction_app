import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/category_square_chip.dart';
import '../../../shared/widgets/collapsible_category_section.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../../shared/widgets/saved_correction_summary_card.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/domain/error_category.dart';
import '../domain/saved_correction.dart';
import 'saved_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({
    required this.repositoryController,
    required this.language,
    super.key,
  });

  final CorrectionRepositoryController repositoryController;
  final Language language;

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  ErrorCategory? _selectedCategory;
  final Set<ErrorCategory> _collapsedCategories = {};

  @override
  void initState() {
    super.initState();
    widget.repositoryController.addListener(_handleRepositoryChanged);
    widget.repositoryController.setActiveLanguage(widget.language);
  }

  @override
  void dispose() {
    widget.repositoryController.removeListener(_handleRepositoryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedCorrections = widget.repositoryController.savedCorrections;
    final filteredCorrections = _selectedCategory == null
        ? savedCorrections
        : savedCorrections
              .where((correction) => correction.category == _selectedCategory)
              .toList();
    final groupedCorrections = _groupCorrections(filteredCorrections);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: [
              const AppHeader(title: 'Saved'),
              const SizedBox(height: AppSpacing.xl),
              if (savedCorrections.isNotEmpty) ...[
                _FilterBar(
                  selectedCategory: _selectedCategory,
                  categories: _availableCategories(savedCorrections),
                  onSelected: (category) {
                    setState(() => _selectedCategory = category);
                  },
                  onClear: () {
                    setState(() => _selectedCategory = null);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (savedCorrections.isEmpty)
                EmptyStatePanel(
                  icon: Icons.bookmark_border,
                  title: switch (widget.language) {
                    Language.spanish => 'No saved corrections',
                    Language.portuguese => 'No saved corrections',
                  },
                  message: switch (widget.language) {
                    Language.spanish =>
                      'Tap a highlighted correction and save it to build your review list.',
                    Language.portuguese =>
                      'Tap a highlighted correction and save it to build your review list.',
                  },
                )
              else if (groupedCorrections.isEmpty)
                EmptyStatePanel(
                  icon: Icons.filter_alt_off_outlined,
                  title: 'Nothing in this category',
                  message: 'Clear the filter to see all saved corrections.',
                )
              else
                ...groupedCorrections.entries.map(
                  (entry) => _CategorySection(
                    category: entry.key,
                    corrections: entry.value,
                    isCollapsed: _collapsedCategories.contains(entry.key),
                    onToggle: () => _toggleCategory(entry.key),
                    onOpenCorrection: _openDetail,
                    onConfirmDelete: _confirmDelete,
                    onDeleteCorrection: _deleteSavedCorrection,
                  ),
                ),
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

  void _toggleCategory(ErrorCategory category) {
    setState(() {
      if (_collapsedCategories.contains(category)) {
        _collapsedCategories.remove(category);
      } else {
        _collapsedCategories.add(category);
      }
    });
  }

  void _openDetail(SavedCorrection correction) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SavedDetailScreen(correction: correction),
      ),
    );
  }

  Future<bool> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete saved correction?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'This will remove the correction from your saved list. This cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _deleteSavedCorrection(SavedCorrection correction) async {
    try {
      await widget.repositoryController.removeSavedCorrection(correction.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved correction deleted')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete correction. Please try again.'),
        ),
      );
    }
  }

  List<ErrorCategory> _availableCategories(List<SavedCorrection> corrections) {
    final categories = corrections
        .map((correction) => correction.category)
        .toSet();
    return ErrorCategory.values
        .where((category) => categories.contains(category))
        .toList();
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

    return {
      for (final category in ErrorCategory.values)
        if (grouped.containsKey(category)) category: grouped[category]!,
    };
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedCategory,
    required this.categories,
    required this.onSelected,
    required this.onClear,
  });

  final ErrorCategory? selectedCategory;
  final List<ErrorCategory> categories;
  final ValueChanged<ErrorCategory> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ClearFilterChip(
              isSelected: selectedCategory == null,
              onTap: onClear,
            );
          }

          final category = categories[index - 1];
          return CategorySquareChip(
            category: category,
            isSelected: selectedCategory == category,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.corrections,
    required this.isCollapsed,
    required this.onToggle,
    required this.onOpenCorrection,
    required this.onConfirmDelete,
    required this.onDeleteCorrection,
  });

  final ErrorCategory category;
  final List<SavedCorrection> corrections;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final ValueChanged<SavedCorrection> onOpenCorrection;
  final Future<bool> Function() onConfirmDelete;
  final ValueChanged<SavedCorrection> onDeleteCorrection;

  @override
  Widget build(BuildContext context) {
    return CollapsibleCategorySection(
      category: category,
      itemCount: corrections.length,
      isCollapsed: isCollapsed,
      onToggle: onToggle,
      child: Column(
        children: corrections
            .map(
              (correction) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Dismissible(
                  key: ValueKey(correction.id),
                  direction: DismissDirection.endToStart,
                  background: const _SavedDismissBackground(),
                  confirmDismiss: (_) => onConfirmDelete(),
                  onDismissed: (_) => onDeleteCorrection(correction),
                  child: SavedCorrectionSummaryCard(
                    correction: correction,
                    onTap: () => onOpenCorrection(correction),
                    trailing: Text(
                      _formatSavedDate(correction.savedAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SavedDismissBackground extends StatelessWidget {
  const _SavedDismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delete',
            style: TextStyle(
              color: AppColors.coral,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Icon(Icons.delete_outline, color: AppColors.coral),
        ],
      ),
    );
  }
}

String _formatSavedDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
