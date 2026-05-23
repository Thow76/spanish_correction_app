import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';

class CorrectionsScreen extends StatelessWidget {
  const CorrectionsScreen({
    required this.response,
    required this.onSaveCorrection,
    super.key,
  });

  final CorrectionResponse response;
  final ValueChanged<CorrectionItem> onSaveCorrection;

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
                  title: 'Corrections',
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TextPanel(
                  title: 'Original',
                  text: response.originalText,
                  corrections: response.corrections,
                  phraseSelector: (item) => item.originalPhrase,
                  onTapCorrection: (item) =>
                      _showCorrectionSheet(context, item),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TextPanel(
                  title: 'Corrected',
                  text: response.correctedText,
                  corrections: response.corrections,
                  phraseSelector: (item) => item.correctedPhrase,
                  onTapCorrection: (item) =>
                      _showCorrectionSheet(context, item),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: response.correctedText),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Corrected text copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy corrected text'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCorrectionSheet(BuildContext context, CorrectionItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.correctedPhrase,
                style: TextStyle(
                  color: item.category.color,
                  fontFamily: 'Sora',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _CategoryPill(item: item),
              const SizedBox(height: AppSpacing.lg),
              Text(
                item.shortExplanation,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 24 / 15,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSaveCorrection(item);
                  },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save for Later'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({
    required this.title,
    required this.text,
    required this.corrections,
    required this.phraseSelector,
    required this.onTapCorrection,
  });

  final String title;
  final String text;
  final List<CorrectionItem> corrections;
  final String Function(CorrectionItem item) phraseSelector;
  final ValueChanged<CorrectionItem> onTapCorrection;

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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(spacing: 4, runSpacing: 8, children: _buildPhraseRuns()),
        ],
      ),
    );
  }

  List<Widget> _buildPhraseRuns() {
    final remaining = StringBuffer(text);
    final widgets = <Widget>[];

    for (final item in corrections) {
      final phrase = phraseSelector(item);
      final source = remaining.toString();
      final index = source.indexOf(phrase);
      if (index == -1) {
        continue;
      }

      final before = source.substring(0, index);
      if (before.isNotEmpty) {
        widgets.add(_PlainTextRun(before));
      }

      widgets.add(
        _HighlightedRun(
          text: phrase,
          color: item.category.color,
          onTap: () => onTapCorrection(item),
        ),
      );
      remaining
        ..clear()
        ..write(source.substring(index + phrase.length));
    }

    if (remaining.isNotEmpty) {
      widgets.add(_PlainTextRun(remaining.toString()));
    }

    return widgets;
  }
}

class _PlainTextRun extends StatelessWidget {
  const _PlainTextRun(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 24 / 15,
      ),
    );
  }
}

class _HighlightedRun extends StatelessWidget {
  const _HighlightedRun({
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 24 / 15,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.item});

  final CorrectionItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: item.category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: item.category.color.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          item.category.label,
          style: TextStyle(
            color: item.category.color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
