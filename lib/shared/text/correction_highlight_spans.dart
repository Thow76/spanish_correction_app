import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../features/corrections/domain/correction_item.dart';

/// Anchors a highlight on the *submitted/original* text range/phrase. This is
/// the common case (the corrections screen's "Original" panel and the game's
/// attempt highlight); the "Corrected" panel overrides it via [rangeSelector] /
/// [phraseSelector].
(int?, int?) _originalRange(CorrectionItem item) =>
    (item.startIndex, item.endIndex);
String _originalPhrase(CorrectionItem item) => item.originalPhrase;

/// Builds the inline spans for [text] with each correction in [corrections]
/// rendered in a highlight colour.
///
/// Range resolution is model-range-first with a substring then
/// case-insensitive fallback, and overlapping highlights are de-duplicated —
/// ported verbatim from the corrections screen so both call sites resolve
/// ranges identically.
///
/// [color] is the highlight colour for every span unless [colorOf] is provided,
/// in which case it overrides per item (the corrections screen colours by error
/// category; the game passes a single accent colour and no [colorOf]).
/// [decoration] is applied to every highlighted span (e.g. the reveal screen's
/// underlined diff); it defaults to none so existing call sites are unchanged.
/// [recognizerOf], when provided, attaches a tap recognizer to each highlighted
/// span (the corrections screen opens a detail sheet); the game passes none.
/// [rangeSelector] / [phraseSelector] choose which stored range/phrase to anchor
/// on (original vs corrected text); they default to the original-text values.
///
/// [requireExactRange] trusts only the model-reported range: if the grapheme
/// slice at that range does not equal the phrase (or the range is null /
/// out-of-range), the highlight is dropped (rendered as plain text) rather than
/// falling back to a substring/case-insensitive search. The corrected panel
/// uses this so a wrong index can never produce a highlight on the wrong span.
List<InlineSpan> buildHighlightedSpans({
  required String text,
  required List<CorrectionItem> corrections,
  required Color color,
  FontWeight fontWeight = FontWeight.w700,
  TextDecoration? decoration,
  (int?, int?) Function(CorrectionItem item) rangeSelector = _originalRange,
  String Function(CorrectionItem item) phraseSelector = _originalPhrase,
  Color Function(CorrectionItem item)? colorOf,
  GestureRecognizer Function(CorrectionItem item)? recognizerOf,
  bool requireExactRange = false,
}) {
  final graphemes = text.characters.toList();
  final highlights = _resolveHighlights(
    graphemes,
    corrections,
    rangeSelector,
    phraseSelector,
    requireExactRange,
  );
  final spans = <InlineSpan>[];
  var cursor = 0;

  for (final highlight in highlights) {
    if (highlight.start > cursor) {
      spans.add(
        TextSpan(text: graphemes.sublist(cursor, highlight.start).join()),
      );
    }
    spans.add(
      TextSpan(
        text: graphemes.sublist(highlight.start, highlight.end).join(),
        style: TextStyle(
          color: colorOf?.call(highlight.item) ?? color,
          fontWeight: fontWeight,
          decoration: decoration,
        ),
        recognizer: recognizerOf?.call(highlight.item),
      ),
    );
    cursor = highlight.end;
  }

  if (cursor < graphemes.length) {
    spans.add(TextSpan(text: graphemes.sublist(cursor).join()));
  }

  return spans;
}

List<_Highlight> _resolveHighlights(
  List<String> graphemes,
  List<CorrectionItem> corrections,
  (int?, int?) Function(CorrectionItem item) rangeSelector,
  String Function(CorrectionItem item) phraseSelector,
  bool requireExactRange,
) {
  final highlights = <_Highlight>[];

  for (final item in corrections) {
    final phrase = phraseSelector(item);
    final range = _locateRange(
      item,
      graphemes,
      phrase,
      rangeSelector,
      requireExactRange,
    );
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
  (int?, int?) Function(CorrectionItem item) rangeSelector,
  bool requireExactRange,
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

  // Corrected side: trust only the model's reported range. If the slice did not
  // match above (wrong, null, or out-of-range indices), drop this highlight
  // rather than search — a dropped highlight shows plain text, never the wrong
  // span. No substring or case-insensitive fallback.
  if (requireExactRange) {
    return null;
  }

  if (phrase.isEmpty) {
    return null;
  }

  final phraseGraphemes = phrase.characters.toList();
  final exactMatches = _findMatches(graphemes, phraseGraphemes);
  if (exactMatches.isNotEmpty) {
    final anchor = modelStart ?? 0;
    final best = exactMatches.reduce(
      (a, b) => (a - anchor).abs() <= (b - anchor).abs() ? a : b,
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

List<int> _findMatches(List<String> haystack, List<String> needle) {
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

class _Highlight {
  const _Highlight({required this.item, required this.start, required this.end});

  final CorrectionItem item;
  final int start;
  final int end;
}
