import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/category_pill.dart';
import '../../../shared/widgets/collapsible_section.dart';
import '../../../shared/widgets/highlighted_sentence.dart';
import '../../../shared/widgets/text_body.dart';
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
                  // A pure-deletion correction (e.g. removing a redundant
                  // pronoun) has an empty correctedPhrase by design — the fix
                  // IS the removal, there's no replacement text. Falling back
                  // to originalPhrase (the word being removed) keeps this
                  // headline from rendering as empty quotes.
                  '"${correction.correctedPhrase.isEmpty ? correction.originalPhrase : correction.correctedPhrase}"',
                  style: TextStyle(
                    color: correction.category.color,
                    fontFamily: 'Sora',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 36 / 28,
                    decoration: correction.correctedPhrase.isEmpty
                        ? TextDecoration.underline
                        : null,
                    decorationColor: correction.category.color,
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
                CategoryPill(
                  label: correction.category.label,
                  color: correction.category.color,
                ),
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
    // Bridge the single saved record to the shared highlight resolver
    // (buildHighlightedSpans) by rebuilding the CorrectionItem it was saved
    // from, so each highlight anchors on the stored range — the correct
    // occurrence of a repeated word — instead of a first-occurrence indexOf.
    final item = correction.toCorrectionItem();

    final sections = <(_DetailSection, Widget)>[
      (
        _DetailSection.whyItsWrong,
        TextBody(
          text: _fallbackText(correction.explanation.whyItsWrong),
        ),
      ),
      (
        _DetailSection.inContext,
        TextBody(text: _fallbackText(correction.explanation.inContext)),
      ),
      (
        _DetailSection.alternatives,
        TextBody(
          text: correction.explanation.alternatives.isEmpty
              ? 'No alternatives saved for this correction.'
              : correction.explanation.alternatives.join('\n'),
        ),
      ),
      (
        _DetailSection.originalText,
        correction.originalSentence.isEmpty
            ? const TextBody(text: 'No original text saved for this correction.')
            : HighlightedSentence(
                sentence: correction.originalSentence,
                item: item,
                color: correction.category.color,
                // Original side: anchor on the persisted original range; for old
                // records with no saved range, fall back to substring matching.
                rangeSelector: (item) => (item.startIndex, item.endIndex),
                phraseSelector: (item) => item.originalPhrase,
              ),
      ),
      (
        _DetailSection.correctedText,
        correction.correctedSentence.isEmpty
            ? const TextBody(
                text: 'No corrected text saved for this correction.',
              )
            : HighlightedSentence(
                sentence: correction.correctedSentence,
                item: item,
                color: correction.category.color,
                // Corrected side: the persisted range is the model's own index
                // into the corrected text; trust only an exact slice match and
                // drop the highlight on a miss (null/invalid) rather than
                // mis-placing it.
                rangeSelector: (item) =>
                    (item.correctedStartIndex, item.correctedEndIndex),
                phraseSelector: (item) => item.correctedPhrase,
                requireExactRange: true,
              ),
      ),
    ];

    final widgets = <Widget>[];
    for (var index = 0; index < sections.length; index++) {
      final (section, body) = sections[index];
      widgets.add(
        CollapsibleSection(
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
