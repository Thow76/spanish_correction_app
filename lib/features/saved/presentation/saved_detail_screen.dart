import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../domain/saved_correction.dart';

class SavedDetailScreen extends StatefulWidget {
  const SavedDetailScreen({required this.correction, super.key});

  final SavedCorrection correction;

  @override
  State<SavedDetailScreen> createState() => _SavedDetailScreenState();
}

class _SavedDetailScreenState extends State<SavedDetailScreen> {
  final Set<_DetailSection> _collapsedSections = {};

  @override
  Widget build(BuildContext context) {
    final correction = widget.correction;

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
                ..._buildSections(correction),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(SavedCorrection correction) {
    final sections = <(_DetailSection, Widget)>[
      (
        _DetailSection.whyItsWrong,
        _TextBody(
          text: _fallbackText(correction.explanation.whyItsWrong),
        ),
      ),
      (
        _DetailSection.inContext,
        _TextBody(text: _fallbackText(correction.explanation.inContext)),
      ),
      (
        _DetailSection.alternatives,
        _TextBody(
          text: correction.explanation.alternatives.isEmpty
              ? 'No alternatives saved for this correction.'
              : correction.explanation.alternatives.join('\n'),
        ),
      ),
      (
        _DetailSection.originalText,
        correction.originalSentence.isEmpty
            ? const _TextBody(text: 'No original text saved for this correction.')
            : _HighlightedSentence(
                sentence: correction.originalSentence,
                highlight: correction.originalPhrase,
                color: correction.category.color,
              ),
      ),
      (
        _DetailSection.correctedText,
        correction.correctedSentence.isEmpty
            ? const _TextBody(
                text: 'No corrected text saved for this correction.',
              )
            : _HighlightedSentence(
                sentence: correction.correctedSentence,
                highlight: correction.correctedPhrase,
                color: correction.category.color,
              ),
      ),
    ];

    final widgets = <Widget>[];
    for (var index = 0; index < sections.length; index++) {
      final (section, body) = sections[index];
      widgets.add(
        _CollapsibleSection(
          title: section.title,
          isCollapsed: _collapsedSections.contains(section),
          onToggle: () => _toggleSection(section),
          child: body,
        ),
      );
      if (index < sections.length - 1) {
        widgets.add(const SizedBox(height: AppSpacing.lg));
      }
    }
    return widgets;
  }

  void _toggleSection(_DetailSection section) {
    setState(() {
      if (_collapsedSections.contains(section)) {
        _collapsedSections.remove(section);
      } else {
        _collapsedSections.add(section);
      }
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _fallbackText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'No detail saved for this section.' : trimmed;
  }
}

enum _DetailSection {
  whyItsWrong("Why it's wrong"),
  inContext('In context'),
  alternatives('Alternatives'),
  originalText('Original text'),
  correctedText('Corrected text');

  const _DetailSection(this.title);

  final String title;
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

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.isCollapsed,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isCollapsed;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: child,
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

class _TextBody extends StatelessWidget {
  const _TextBody({required this.text});

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

class _HighlightedSentence extends StatelessWidget {
  const _HighlightedSentence({
    required this.sentence,
    required this.highlight,
    required this.color,
  });

  final String sentence;
  final String highlight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final range = _findRange(sentence, highlight);

    if (range == null) {
      return _TextBody(text: sentence);
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 24 / 15,
        ),
        children: [
          if (range.$1 > 0) TextSpan(text: sentence.substring(0, range.$1)),
          TextSpan(
            text: sentence.substring(range.$1, range.$2),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          if (range.$2 < sentence.length)
            TextSpan(text: sentence.substring(range.$2)),
        ],
      ),
    );
  }

  static (int, int)? _findRange(String sentence, String highlight) {
    if (highlight.isEmpty) {
      return null;
    }

    final exact = sentence.indexOf(highlight);
    if (exact != -1) {
      return (exact, exact + highlight.length);
    }

    final lower = sentence.toLowerCase().indexOf(highlight.toLowerCase());
    if (lower != -1) {
      return (lower, lower + highlight.length);
    }

    return null;
  }
}
