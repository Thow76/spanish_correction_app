import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/presentation/corrections_screen.dart';

/// Smoke test for step 9's wiring: pumps the REAL `CorrectionsScreen` with a
/// `CorrectionResponse` built via the REAL `fromAnchoredJson` pipeline
/// (dedup -> corrected_text reconstruction -> computed corrected-side
/// ranges) from JSON shaped exactly like the reduced schema — no
/// corrected_text, corrected_start_index, or corrected_end_index anywhere in
/// the input, since the model is no longer asked for them. This is what a
/// live API response now looks like end-to-end, with no mocking of the
/// domain layer.
///
/// Three corrections are used (two insertions plus a word replacement) so
/// the corrected-side highlight for the LAST correction only lands correctly
/// if the cumulative-shift arithmetic (`computeCorrectedRanges`) is actually
/// wired in — before step 9, this would either be null (dropped) or point at
/// the wrong text entirely.
const _submittedText = 'Como estas? Que tal?';

Map<String, Object?> _liveShapedJson() {
  return {
    'original_text': _submittedText,
    'corrections': [
      {
        'start_index': 0,
        'original_phrase': '',
        'corrected_phrase': '¿',
        'category': 'Grammar',
        'short_explanation': 'Spanish questions need an opening mark.',
      },
      {
        'start_index': 5,
        'original_phrase': 'estas',
        'corrected_phrase': 'estás',
        'category': 'Spelling',
        'short_explanation': 'Missing accent.',
      },
      {
        'start_index': 12,
        'original_phrase': '',
        'corrected_phrase': '¿',
        'category': 'Grammar',
        'short_explanation': 'Spanish questions need an opening mark.',
      },
    ],
  };
}

/// All visible text of a span tree, in order.
String _flatten(InlineSpan root) {
  final buffer = StringBuffer();
  root.visitChildren((span) {
    if (span is TextSpan && span.text != null) {
      buffer.write(span.text);
    }
    return true;
  });
  return buffer.toString();
}

RichText _richTextFor(WidgetTester tester, String sentence) {
  final matches = tester
      .widgetList<RichText>(find.byType(RichText))
      .where((rt) => _flatten(rt.text) == sentence)
      .toList();
  expect(
    matches,
    hasLength(1),
    reason: 'exactly one rendered sentence should match "$sentence"',
  );
  return matches.single;
}

/// Splits the rendered sentence into (prefix, highlight, suffix) around the
/// first leaf span coloured with [highlightColor].
({String prefix, String highlight, String suffix})? _highlightParts(
  RichText rt,
  Color highlightColor,
) {
  final prefix = StringBuffer();
  final suffix = StringBuffer();
  String? highlight;

  rt.text.visitChildren((span) {
    if (span is! TextSpan || span.text == null) {
      return true;
    }
    final isHighlight = span.style?.color == highlightColor;
    if (highlight == null && isHighlight) {
      highlight = span.text;
    } else if (highlight == null) {
      prefix.write(span.text);
    } else {
      suffix.write(span.text);
    }
    return true;
  });

  if (highlight == null) {
    return null;
  }
  return (
    prefix: prefix.toString(),
    highlight: highlight!,
    suffix: suffix.toString(),
  );
}

void main() {
  testWidgets(
    'Corrections screen renders both panels correctly end-to-end via the '
    'real fromAnchoredJson pipeline (dedup + reconstruction + computed '
    'corrected ranges)',
    (tester) async {
      final response = CorrectionResponse.fromAnchoredJson(
        _liveShapedJson(),
        submittedText: _submittedText,
        allowLegacyCategories: false,
      );

      // Sanity on the domain layer itself before touching the UI at all.
      expect(response.originalText, _submittedText);
      expect(response.correctedText, '¿Como estás? ¿Que tal?');
      expect(response.corrections, hasLength(3));

      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: CorrectionsScreen(response: response, onSaveCorrection: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      // Original panel: "estas" (Spelling-coloured) must be highlighted at
      // the correct position, unaffected by the later corrections.
      final originalParts = _highlightParts(
        _richTextFor(tester, _submittedText),
        ErrorCategory.spelling.color,
      );
      expect(
        originalParts,
        isNotNull,
        reason: 'original panel must highlight "estas"',
      );
      expect(originalParts!.highlight, 'estas');
      expect(originalParts.prefix, 'Como ');
      expect(originalParts.suffix, '? Que tal?');

      // Corrected panel: "estás" must be highlighted at its SHIFTED position
      // (shifted right by 1 grapheme for the preceding "¿" insertion) — this
      // is the assertion that only passes once computeCorrectedRanges is
      // wired in; before step 9 this highlight would be dropped (null) or
      // land on the wrong text.
      final correctedParts = _highlightParts(
        _richTextFor(tester, '¿Como estás? ¿Que tal?'),
        ErrorCategory.spelling.color,
      );
      expect(
        correctedParts,
        isNotNull,
        reason:
            'corrected panel must highlight "estás" — this is the gap step '
            '9 closes',
      );
      expect(correctedParts!.highlight, 'estás');
      expect(correctedParts.prefix, '¿Como ');
      expect(correctedParts.suffix, '? ¿Que tal?');
    },
  );
}
