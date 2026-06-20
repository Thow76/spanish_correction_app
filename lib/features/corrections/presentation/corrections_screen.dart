import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/text/correction_highlight_spans.dart';
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
                  rangeSelector: (item) => (item.startIndex, item.endIndex),
                  phraseSelector: (item) => item.originalPhrase,
                  onTapCorrection: (item) =>
                      _showCorrectionSheet(context, item),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TextPanel(
                  title: 'Corrected',
                  text: response.correctedText,
                  corrections: response.corrections,
                  rangeSelector: (item) =>
                      (item.correctedStartIndex, item.correctedEndIndex),
                  phraseSelector: (item) => item.correctedPhrase,
                  // The corrected indices are reported by the model against its
                  // own corrected text; trust only an exact slice match and drop
                  // any highlight that does not validate (never a wrong span).
                  requireExactRange: true,
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
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final sheetHeight = mediaQuery.size.height - mediaQuery.padding.top;

        return SizedBox(
          height: sheetHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  24 + mediaQuery.padding.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onSaveCorrection(item);
                    },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('Save for Later'),
                  ),
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
    required this.rangeSelector,
    required this.phraseSelector,
    required this.onTapCorrection,
    this.requireExactRange = false,
  });

  final String title;
  final String text;
  final List<CorrectionItem> corrections;
  final (int?, int?) Function(CorrectionItem item) rangeSelector;
  final String Function(CorrectionItem item) phraseSelector;
  final ValueChanged<CorrectionItem> onTapCorrection;
  final bool requireExactRange;

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
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 24 / 15,
              ),
              children: _buildSpans(),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildSpans() {
    // Range resolution and span assembly are shared with the Traducir frases
    // walkthrough (buildHighlightedSpans). This screen keeps its two distinct
    // behaviours by passing them in: per-error-category colours and a
    // tap-to-open-detail recognizer.
    return buildHighlightedSpans(
      text: text,
      corrections: corrections,
      color: AppColors.textPrimary,
      rangeSelector: rangeSelector,
      phraseSelector: phraseSelector,
      requireExactRange: requireExactRange,
      colorOf: (item) => item.category.color,
      recognizerOf: (item) =>
          TapGestureRecognizerFactory.build(() => onTapCorrection(item)),
    );
  }
}

class TapGestureRecognizerFactory {
  static TapGestureRecognizer build(VoidCallback onTap) {
    return TapGestureRecognizer()..onTap = onTap;
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
