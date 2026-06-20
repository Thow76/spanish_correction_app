import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/features/saved/presentation/saved_detail_screen.dart';

/// Regression guard for Bug 2 (now fixed).
///
/// History: the saved/detail screen highlighted the saved phrase with a
/// first-occurrence `sentence.indexOf(highlight)`. When the corrected word
/// appears more than once in the sentence, that lands on the WRONG occurrence.
///
/// The fix: the screen rebuilds the saved record into a `CorrectionItem` and
/// resolves spans via the shared `buildHighlightedSpans`, anchoring on the
/// persisted character range — the original range on the original side (with a
/// substring fallback for old records that have no range), and the model's
/// corrected range on the corrected side (dropping the highlight on a miss
/// rather than mis-placing it).
///
/// These tests pump the real `SavedDetailScreen` with synthetic records and
/// inspect the rendered spans, asserting the highlighted slice equals the
/// intended phrase at the intended occurrence.

// A sentence where "para" appears three times. The saved correction targets the
// SECOND one (in "volví para casa"), so a first-occurrence indexOf would wrongly
// highlight the first ("supermercado para comprar").
const _original =
    'Fui al supermercado para comprar pan y volví para casa para preparar la cena.';
// Corrected text: "volví para casa" -> "volví a casa". The corrected phrase "a"
// occurs many times over, so only an exact model range lands it correctly.
const _corrected =
    'Fui al supermercado para comprar pan y volví a casa para preparar la cena.';

/// indexOf over grapheme clusters (so accented characters count as one).
int _graphemeIndexOf(String haystack, String needle) {
  final h = haystack.characters.toList();
  final n = needle.characters.toList();
  for (var i = 0; i + n.length <= h.length; i++) {
    var ok = true;
    for (var j = 0; j < n.length; j++) {
      if (h[i + j] != n[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}

int _targetParaStart() {
  final clause = _graphemeIndexOf(_original, 'volví para casa');
  expect(clause, isNot(-1), reason: 'clause must exist in original');
  return clause + 'volví '.characters.length;
}

int _correctedAStart() {
  final clause = _graphemeIndexOf(_corrected, 'volví a casa');
  expect(clause, isNot(-1), reason: 'clause must exist in corrected text');
  return clause + 'volví '.characters.length;
}

SavedCorrection _saved({
  int? startIndex,
  int? endIndex,
  int? correctedStartIndex,
  int? correctedEndIndex,
}) {
  return SavedCorrection(
    id: 'test-1',
    category: ErrorCategory.grammar,
    shortExplanation: 'Use "a" with verbs of movement: volví a casa.',
    originalSentence: _original,
    explanation: const SavedExplanation(
      whyItsWrong: 'why',
      inContext: 'context',
      alternatives: ['alt'],
    ),
    savedAt: DateTime(2026, 6, 19),
    correctedPhrase: 'a',
    originalPhrase: 'para',
    correctedSentence: _corrected,
    promptPhrase: 'I went home to make dinner.',
    language: Language.spanish,
    startIndex: startIndex,
    endIndex: endIndex,
    correctedStartIndex: correctedStartIndex,
    correctedEndIndex: correctedEndIndex,
  );
}

Future<void> _pump(WidgetTester tester, SavedCorrection correction) async {
  // The screen renders inside a lazy ListView; size the surface tall enough that
  // every section (incl. the Corrected text at the bottom) is built.
  await tester.binding.setSurfaceSize(const Size(390, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: SavedDetailScreen(correction: correction)),
  );
  await tester.pumpAndSettle();
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

/// Finds the rendered RichText whose flattened text equals [sentence].
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

/// Splits the rendered sentence into (prefix, highlight, suffix) around the one
/// leaf span coloured with [highlightColor]. Returns null when nothing is
/// highlighted (the whole sentence rendered as plain text).
///
/// Walks leaf spans via [InlineSpan.visitChildren] because `Text.rich` nests the
/// supplied span under an outer default-style span, so the highlighted leaf is
/// not a direct child of the RichText's root.
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
  final color = ErrorCategory.grammar.color;

  testWidgets(
    'original side highlights the CORRECT repeated-word occurrence (Bug 2)',
    (tester) async {
      final start = _targetParaStart();
      await _pump(
        tester,
        _saved(
          startIndex: start,
          endIndex: start + 'para'.characters.length,
          correctedStartIndex: _correctedAStart(),
          correctedEndIndex: _correctedAStart() + 1,
        ),
      );

      final parts = _highlightParts(_richTextFor(tester, _original), color);
      expect(parts, isNotNull, reason: 'the original phrase must be highlighted');

      // ignore: avoid_print
      print('original highlight: prefix="...${parts!.prefix.characters.takeLast(8)}" '
          'highlight="${parts.highlight}" suffix="${parts.suffix.characters.take(6)}..."');

      // The highlighted slice is exactly "para"...
      expect(parts.highlight, 'para');
      // ...and it is the "volví para casa" occurrence, not the first
      // ("supermercado para comprar"): the text right after it is " casa".
      expect(parts.suffix, startsWith(' casa'));
      expect(parts.prefix, endsWith('volví '));
      // Sanity: reassembling the parts reproduces the sentence.
      expect('${parts.prefix}${parts.highlight}${parts.suffix}', _original);

      // Sanity that this genuinely exercises the bug: a naive indexOf would have
      // picked an EARLIER "para" (the one in "supermercado para comprar").
      final naive = _original.indexOf('para');
      expect(
        _original.substring(naive).startsWith('para comprar'),
        isTrue,
        reason: 'first-occurrence indexOf points at the wrong "para"',
      );
    },
  );

  testWidgets('corrected side lands on the model-reported "a" among many', (
    tester,
  ) async {
    final start = _targetParaStart();
    final aStart = _correctedAStart();
    await _pump(
      tester,
      _saved(
        startIndex: start,
        endIndex: start + 'para'.characters.length,
        correctedStartIndex: aStart,
        correctedEndIndex: aStart + 1,
      ),
    );

    final parts = _highlightParts(_richTextFor(tester, _corrected), color);
    expect(parts, isNotNull, reason: 'the corrected phrase must be highlighted');

    expect(parts!.highlight, 'a');
    // The "volví a casa" occurrence, not one of the many other "a"s.
    expect(parts.prefix, endsWith('volví '));
    expect(parts.suffix, startsWith(' casa'));
    expect('${parts.prefix}${parts.highlight}${parts.suffix}', _corrected);
  });

  testWidgets('corrected side DROPS the highlight on a null range', (
    tester,
  ) async {
    final start = _targetParaStart();
    await _pump(
      tester,
      _saved(
        startIndex: start,
        endIndex: start + 'para'.characters.length,
        // Old record: no model corrected range persisted.
        correctedStartIndex: null,
        correctedEndIndex: null,
      ),
    );

    final parts = _highlightParts(_richTextFor(tester, _corrected), color);
    // No highlight at all — the corrected sentence renders as plain text rather
    // than risk mis-placing the "a".
    expect(
      parts,
      isNull,
      reason: 'a null corrected range must drop the highlight, not guess',
    );
  });

  testWidgets('corrected side DROPS the highlight on an invalid range', (
    tester,
  ) async {
    final start = _targetParaStart();
    await _pump(
      tester,
      _saved(
        startIndex: start,
        endIndex: start + 'para'.characters.length,
        // Points at "F" (index 0), whose slice != "a": must be rejected.
        correctedStartIndex: 0,
        correctedEndIndex: 1,
      ),
    );

    final parts = _highlightParts(_richTextFor(tester, _corrected), color);
    expect(
      parts,
      isNull,
      reason: 'an invalid corrected range (slice != phrase) must drop the '
          'highlight',
    );
  });

  testWidgets(
    'old records (null original range) fall back to substring matching',
    (tester) async {
      await _pump(
        tester,
        _saved(
          // Old record: no original range persisted.
          startIndex: null,
          endIndex: null,
          correctedStartIndex: null,
          correctedEndIndex: null,
        ),
      );

      final parts = _highlightParts(_richTextFor(tester, _original), color);
      expect(
        parts,
        isNotNull,
        reason: 'original side still highlights via substring fallback',
      );

      // With no range the original side falls back to first-occurrence
      // substring matching, exactly as before the fix: the first "para"
      // ("supermercado para comprar").
      expect(parts!.highlight, 'para');
      expect(parts.suffix, startsWith(' comprar'));
    },
  );
}
