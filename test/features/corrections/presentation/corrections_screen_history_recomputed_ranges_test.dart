import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/presentation/corrections_screen.dart';

/// Regression test for the History-screen corrected-panel highlighting bug:
/// `CorrectionItem.toJson()` never serializes `corrected_start_index`/
/// `corrected_end_index`, so every submission reloaded from history via
/// `CorrectionSubmission.fromJson` -> `CorrectionResponse.fromJson` used to
/// carry null corrected ranges, which `CorrectionsScreen`'s
/// `requireExactRange: true` Corrected panel then silently dropped.
///
/// This pumps the REAL `CorrectionsScreen` — the widget `history_screen.dart`
/// navigates to for a tapped submission — with a `CorrectionResponse` built
/// via the REAL `fromJson` (not `fromAnchoredJson`) from JSON shaped exactly
/// like real stored history: `start_index`/`end_index` present,
/// `corrected_start_index`/`corrected_end_index` absent. No mocking of the
/// domain layer, matching the pattern in
/// `corrections_screen_live_pipeline_test.dart` for the live path.
const _originalText = 'Como estas? Que tal?';
const _correctedText = '¿Como estás? Que tal?';

Map<String, Object?> _historyShapedJson() {
  return {
    'original_text': _originalText,
    'corrected_text': _correctedText,
    'corrections': [
      {
        'start_index': 0,
        'end_index': 0,
        'original_phrase': '',
        'corrected_phrase': '¿',
        'category': 'Grammar',
        'short_explanation': 'Spanish questions need an opening mark.',
      },
      {
        'start_index': 5,
        'end_index': 10,
        'original_phrase': 'estas',
        'corrected_phrase': 'estás',
        'category': 'Spelling',
        'short_explanation': 'Missing accent.',
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
  testWidgets('Corrections screen renders the corrected panel highlight for a '
      'response reloaded via the history fromJson path, with no persisted '
      'corrected_start_index/corrected_end_index in the source JSON', (
    tester,
  ) async {
    final response = CorrectionResponse.fromJson(
      _historyShapedJson(),
      allowLegacyCategories: false,
    );

    // Sanity on the domain layer: corrected ranges must have been
    // recomputed even though the source JSON never carried them.
    expect(response.corrections, hasLength(2));
    expect(response.corrections[1].correctedStartIndex, isNotNull);
    expect(response.corrections[1].correctedEndIndex, isNotNull);

    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CorrectionsScreen(response: response, onSaveCorrection: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    // Original panel: "estas" (Spelling-coloured) highlighted correctly —
    // this side was never broken, since startIndex/endIndex are persisted.
    final originalParts = _highlightParts(
      _richTextFor(tester, _originalText),
      ErrorCategory.spelling.color,
    );
    expect(
      originalParts,
      isNotNull,
      reason: 'original panel must highlight "estas"',
    );
    expect(originalParts!.highlight, 'estas');

    // Corrected panel: "estás" must be highlighted at its shifted
    // position — this is the assertion that only passes once
    // CorrectionResponse.fromJson recomputes corrected ranges from the
    // persisted original-side data. Before the fix this highlight was
    // silently dropped (null range, requireExactRange: true, no
    // fallback).
    final correctedParts = _highlightParts(
      _richTextFor(tester, _correctedText),
      ErrorCategory.spelling.color,
    );
    expect(
      correctedParts,
      isNotNull,
      reason:
          'corrected panel must highlight "estás" — this is the History '
          'highlighting gap the fix closes',
    );
    expect(correctedParts!.highlight, 'estás');
    expect(correctedParts.prefix, '¿Como ');
    expect(correctedParts.suffix, '? Que tal?');
  });
}
