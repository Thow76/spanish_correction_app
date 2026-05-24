import 'package:flutter/gestures.dart';
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
  });

  final String title;
  final String text;
  final List<CorrectionItem> corrections;
  final (int?, int?) Function(CorrectionItem item) rangeSelector;
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
    final graphemes = text.characters.toList();
    final highlights = _resolveHighlights(graphemes);
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final highlight in highlights) {
      if (highlight.start > cursor) {
        spans.add(
          TextSpan(text: graphemes.sublist(cursor, highlight.start).join()),
        );
      }
      final highlightedText = graphemes
          .sublist(highlight.start, highlight.end)
          .join();
      spans.add(
        TextSpan(
          text: highlightedText,
          style: TextStyle(
            color: highlight.item.category.color,
            fontWeight: FontWeight.w700,
          ),
          recognizer: TapGestureRecognizerFactory.build(
            () => onTapCorrection(highlight.item),
          ),
        ),
      );
      cursor = highlight.end;
    }

    if (cursor < graphemes.length) {
      spans.add(TextSpan(text: graphemes.sublist(cursor).join()));
    }

    return spans;
  }

  List<_Highlight> _resolveHighlights(List<String> graphemes) {
    final highlights = <_Highlight>[];

    for (final item in corrections) {
      final phrase = phraseSelector(item);
      final range = _locateRange(item, graphemes, phrase);
      if (range == null) {
        continue;
      }
      highlights.add(_Highlight(item: item, start: range.$1, end: range.$2));
    }

    highlights.sort((a, b) => a.start.compareTo(b.start));

    final resolved = <_Highlight>[];
    var lastEnd = 0;
    for (final highlight in highlights) {
      if (highlight.start < lastEnd) {
        continue;
      }
      resolved.add(highlight);
      lastEnd = highlight.end;
    }
    return resolved;
  }

  (int, int)? _locateRange(
    CorrectionItem item,
    List<String> graphemes,
    String phrase,
  ) {
    final (modelStart, modelEnd) = rangeSelector(item);

    if (modelStart != null &&
        modelEnd != null &&
        modelStart >= 0 &&
        modelEnd >= modelStart &&
        modelEnd <= graphemes.length) {
      final slice = graphemes.sublist(modelStart, modelEnd).join();
      if (slice == phrase) {
        return (modelStart, modelEnd);
      }
    }

    if (phrase.isEmpty) {
      return null;
    }

    final phraseGraphemes = phrase.characters.toList();
    final exactMatches = _findMatches(graphemes, phraseGraphemes);
    if (exactMatches.isNotEmpty) {
      final anchor = modelStart ?? 0;
      final best = exactMatches.reduce(
        (a, b) =>
            (a - anchor).abs() <= (b - anchor).abs() ? a : b,
      );
      return (best, best + phraseGraphemes.length);
    }

    final lowerHaystack = graphemes
        .map((grapheme) => grapheme.toLowerCase())
        .toList();
    final lowerNeedle = phraseGraphemes
        .map((grapheme) => grapheme.toLowerCase())
        .toList();
    final fallbackMatches = _findMatches(lowerHaystack, lowerNeedle);
    if (fallbackMatches.isEmpty) {
      return null;
    }

    final anchor = modelStart ?? 0;
    final best = fallbackMatches.reduce(
      (a, b) => (a - anchor).abs() <= (b - anchor).abs() ? a : b,
    );
    return (best, best + phraseGraphemes.length);
  }

  static List<int> _findMatches(List<String> haystack, List<String> needle) {
    if (needle.isEmpty || needle.length > haystack.length) {
      return const [];
    }
    final matches = <int>[];
    for (var start = 0; start <= haystack.length - needle.length; start++) {
      var matched = true;
      for (var offset = 0; offset < needle.length; offset++) {
        if (haystack[start + offset] != needle[offset]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        matches.add(start);
      }
    }
    return matches;
  }
}

class _Highlight {
  const _Highlight({
    required this.item,
    required this.start,
    required this.end,
  });

  final CorrectionItem item;
  final int start;
  final int end;
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
