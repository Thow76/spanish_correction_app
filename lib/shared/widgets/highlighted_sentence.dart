import 'package:flutter/material.dart';

import '../../features/corrections/domain/correction_item.dart';
import '../design/app_colors.dart';
import '../text/correction_highlight_spans.dart';

/// Renders [sentence] with the error phrase from [item] highlighted in [color].
///
/// Range resolution is delegated to the shared [buildHighlightedSpans] helper,
/// so this anchors on the persisted range exactly as the live corrections screen
/// does. When nothing resolves the helper emits the sentence as plain spans (no
/// highlight) — the original side after a substring miss, or the corrected side
/// dropping an invalid range when [requireExactRange] is set.
class HighlightedSentence extends StatelessWidget {
  const HighlightedSentence({
    required this.sentence,
    required this.item,
    required this.color,
    required this.rangeSelector,
    required this.phraseSelector,
    this.requireExactRange = false,
    this.decoration,
    super.key,
  });

  final String sentence;
  final CorrectionItem item;
  final Color color;
  final (int?, int?) Function(CorrectionItem item) rangeSelector;
  final String Function(CorrectionItem item) phraseSelector;
  final bool requireExactRange;

  /// Optional decoration applied to the highlighted phrase (e.g. an underline on
  /// the answer screen). Defaults to none, so existing call sites (the
  /// saved-detail screen) keep their colour-and-weight-only highlight.
  final TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 24 / 15,
        ),
        children: buildHighlightedSpans(
          text: sentence,
          corrections: [item],
          color: color,
          decoration: decoration,
          rangeSelector: rangeSelector,
          phraseSelector: phraseSelector,
          requireExactRange: requireExactRange,
        ),
      ),
    );
  }
}
