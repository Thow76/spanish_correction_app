import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service_exception.dart';
import '../../corrections/presentation/corrections_screen.dart';
import '../../saved/application/save_correction_use_case.dart';
import '../domain/correction_submission.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.repositoryController,
    required this.saveCorrectionUseCase,
    required this.language,
    super.key,
  });

  final CorrectionRepositoryController repositoryController;
  final SaveCorrectionUseCase saveCorrectionUseCase;
  final Language language;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<_HistoryGroup> _collapsedGroups = {};

  @override
  void initState() {
    super.initState();
    widget.repositoryController.addListener(_handleRepositoryChanged);
    widget.repositoryController.loadHistory();
  }

  @override
  void dispose() {
    widget.repositoryController.removeListener(_handleRepositoryChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submissions = widget.repositoryController.recentSubmissions;
    final isLoading = widget.repositoryController.isLoadingHistory;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            children: [
              const AppHeader(title: 'History'),
              const SizedBox(height: AppSpacing.xl),
              if (isLoading && submissions.isEmpty)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.cyan),
                )
              else if (submissions.isEmpty)
                const EmptyStatePanel(
                  icon: Icons.history,
                  title: 'No reviewed text yet',
                  message:
                      'Recent submissions will appear here after you review Spanish text.',
                )
              else
                ..._groupSubmissions(submissions).entries.map(
                  (entry) => _HistoryGroupSection(
                    group: entry.key,
                    submissions: entry.value,
                    isCollapsed: _collapsedGroups.contains(entry.key),
                    onToggle: () => _toggleGroup(entry.key),
                    onOpenSubmission: _openSubmission,
                    onConfirmDelete: _confirmDelete,
                    onDeleteSubmission: _deleteSubmission,
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

  void _toggleGroup(_HistoryGroup group) {
    setState(() {
      if (_collapsedGroups.contains(group)) {
        _collapsedGroups.remove(group);
      } else {
        _collapsedGroups.add(group);
      }
    });
  }

  Map<_HistoryGroup, List<CorrectionSubmission>> _groupSubmissions(
    List<CorrectionSubmission> submissions,
  ) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(const Duration(days: 6));

    final grouped = <_HistoryGroup, List<CorrectionSubmission>>{};
    for (final submission in submissions) {
      final group = !submission.createdAt.isBefore(startOfToday)
          ? _HistoryGroup.today
          : !submission.createdAt.isBefore(startOfWeek)
              ? _HistoryGroup.thisWeek
              : _HistoryGroup.older;
      grouped.putIfAbsent(group, () => []).add(submission);
    }

    return {
      for (final group in _HistoryGroup.values)
        if (grouped.containsKey(group)) group: grouped[group]!,
    };
  }

  void _openSubmission(CorrectionSubmission submission) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return CorrectionsScreen(
            response: submission.response,
            onSaveCorrection: (correction) async {
              try {
                await widget.saveCorrectionUseCase(
                  correction: correction,
                  originalSentence: submission.response.originalText,
                  correctedSentence: submission.response.correctedText,
                );
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved for later')),
                );
              } on CorrectionServiceException catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_messageForCorrectionError(error))),
                );
              } catch (_) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Something went wrong. Please try again.'),
                  ),
                );
              }
            },
          );
        },
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
            'Delete entry?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'This will remove the submission from your history. This cannot be undone.',
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

  Future<void> _deleteSubmission(CorrectionSubmission submission) async {
    try {
      await widget.repositoryController.removeSubmission(submission.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete entry. Please try again.')),
      );
    }
  }

  String _messageForCorrectionError(CorrectionServiceException error) {
    return switch (error.reason) {
      CorrectionFailureReason.missingConfiguration =>
        'Gemini API key is missing.',
      CorrectionFailureReason.networkUnavailable =>
        'No internet available. Please check your connection.',
      CorrectionFailureReason.apiFailure ||
      CorrectionFailureReason.invalidResponse =>
        'Something went wrong. Please try again.',
    };
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.submission, required this.onTap});

  final CorrectionSubmission submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final correctionCount = submission.response.corrections.length;

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
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(submission.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _CountPill(correctionCount: correctionCount),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                submission.response.correctedText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 24 / 15,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                submission.response.originalText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 18 / 13,
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
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}

enum _HistoryGroup {
  today('Today'),
  thisWeek('This Week'),
  older('Older');

  const _HistoryGroup(this.label);

  final String label;
}

class _HistoryGroupSection extends StatelessWidget {
  const _HistoryGroupSection({
    required this.group,
    required this.submissions,
    required this.isCollapsed,
    required this.onToggle,
    required this.onOpenSubmission,
    required this.onConfirmDelete,
    required this.onDeleteSubmission,
  });

  final _HistoryGroup group;
  final List<CorrectionSubmission> submissions;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final ValueChanged<CorrectionSubmission> onOpenSubmission;
  final Future<bool> Function() onConfirmDelete;
  final ValueChanged<CorrectionSubmission> onDeleteSubmission;

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
                  Expanded(
                    child: Text(
                      group.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Sora',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    submissions.length.toString(),
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
            secondChild: Column(
              children: submissions
                  .map(
                    (submission) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Dismissible(
                        key: ValueKey(submission.id),
                        direction: DismissDirection.endToStart,
                        background: const _DismissBackground(),
                        confirmDismiss: (_) => onConfirmDelete(),
                        onDismissed: (_) => onDeleteSubmission(submission),
                        child: _HistoryCard(
                          submission: submission,
                          onTap: () => onOpenSubmission(submission),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
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

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

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

class _CountPill extends StatelessWidget {
  const _CountPill({required this.correctionCount});

  final int correctionCount;

  @override
  Widget build(BuildContext context) {
    final label = correctionCount == 1 ? '1 error' : '$correctionCount errors';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.cyan,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
