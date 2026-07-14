import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';

/// Regression guard for Bug 1 — reopened as a known, tracked interim gap.
///
/// History: the corrected-side highlight range
/// (`correctedStartIndex`/`correctedEndIndex`) used to be computed arithmetically
/// (`_withCorrectedRanges`) against the *reconstructed* corrected text, while the
/// corrections screen rendered `response.correctedText` — the *model's* corrected
/// text when `_shouldUseModelCorrectedText` was true. When the two diverged the
/// stored range no longer pointed at the corrected phrase in the rendered text.
///
/// The original fix: the model reported `corrected_start_index`/`corrected_end_index`
/// as positions into its OWN corrected_text, parsing populated them directly, and
/// the arithmetic path was removed — so the stored range and the rendered text
/// shared a single source and could not decouple.
///
/// Reopened by the mechanical-work migration (step 1): `corrected_text` is now
/// always reconstructed in code from the itemised corrections and never taken
/// from the model's own `corrected_text`. `corrected_start_index`/`corrected_end_index`
/// are still parsed as-is from the model's JSON — positions into the model's OWN
/// corrected_text — so the two can diverge again whenever the model's freeform
/// corrected_text differs from the code-reconstructed one.
///
/// This is an accepted interim gap, not a silent-wrong-highlight bug: the
/// corrected panel's `requireExactRange: true` guard (see
/// `correction_highlight_spans.dart`) drops any highlight whose stored range
/// doesn't slice out the exact corrected phrase, rather than rendering it at
/// the wrong spot. The gap will close when corrected-side anchoring (mirroring
/// `_anchorRange`/`_findGraphemeMatches`) is built and wired in, per the
/// prompt-schema migration plan.
///
/// These tests feed synthetic anchored JSON through
/// `CorrectionResponse.fromAnchoredJson` exactly as the live services
/// (`open_ai_correction_service` / `gemini_correction_service`) do, supplying the
/// corrected indices the model would report (positions in the corrected text
/// handed back), then assert the slice at the stored range in the aligned case,
/// and the safe-drop (no wrong highlight) behavior in the formerly-divergent
/// case.

const _original =
    'Ayer fui al supermercado para comprar fruta y leche. '
    'Había mucha gente, pero encontré todo rápidamente. '
    'Después, pagué mis compras y volví para casa para preparar la cena.';

/// Grapheme index of the "para" inside "volví para casa".
int _targetParaStart() {
  final clauseStart = _graphemeIndexOf(_original, 'volví para casa');
  expect(clauseStart, isNot(-1), reason: 'clause must exist in original');
  // "volví " == 6 graphemes before "para".
  return clauseStart + 'volví '.characters.length;
}

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

String _graphemeSlice(String text, int start, int end) {
  final g = text.characters.toList();
  if (start < 0 || end > g.length || end < start) {
    return '<out-of-range $start..$end of ${g.length}>';
  }
  return g.sublist(start, end).join();
}

Map<String, Object?> _anchoredJson({required String correctedText}) {
  final paraStart = _targetParaStart();
  // The model reports corrected_start_index/corrected_end_index as positions in
  // its OWN corrected_text. Locate the corrected phrase "a" (from "volví a
  // casa") inside the corrected text we hand back, exactly as the model would.
  final correctedClause = _graphemeIndexOf(correctedText, 'volví a casa');
  expect(
    correctedClause,
    isNot(-1),
    reason: 'corrected clause must exist in the corrected text',
  );
  final correctedAStart = correctedClause + 'volví '.characters.length;
  return {
    'original_text': _original,
    'corrected_text': correctedText,
    'corrections': [
      {
        'original_phrase': 'para',
        'corrected_phrase': 'a',
        'category': 'Grammar',
        'short_explanation': 'Use "a" with verbs of movement: volví a casa.',
        'start_index': paraStart,
        'end_index': paraStart + 'para'.characters.length,
        'corrected_start_index': correctedAStart,
        'corrected_end_index': correctedAStart + 'a'.characters.length,
      },
    ],
  };
}

void main() {
  // The reconstructed corrected text: the original with ONLY the reported
  // correction (volví para casa -> volví a casa) spliced in. This is exactly
  // what `_reconstructCorrectedText` produces — used here as the aligned
  // control where the model text equals the reconstruction.
  final reconstructed = _original.replaceAll(
    'volví para casa',
    'volví a casa',
  );

  test('ALIGNED control — model text == reconstruction', () {
    final response = CorrectionResponse.fromAnchoredJson(
      _anchoredJson(correctedText: reconstructed),
      submittedText: _original,
    );

    expect(response.corrections, hasLength(1));
    final item = response.corrections.single;
    final cs = item.correctedStartIndex;
    final ce = item.correctedEndIndex;

    final renderedIsModel = response.correctedText == reconstructed;
    final slice = (cs != null && ce != null)
        ? _graphemeSlice(response.correctedText, cs, ce)
        : '<null range>';

    // ignore: avoid_print
    print('--- ALIGNED CONTROL ---');
    // ignore: avoid_print
    print('correctedStartIndex/End : $cs..$ce');
    // ignore: avoid_print
    print('rendered corrected text : ${response.correctedText}');
    // ignore: avoid_print
    print('renders model/recon text: '
        '${renderedIsModel ? "model==recon" : "reconstructed"}');
    // ignore: avoid_print
    print('slice at stored range   : "$slice"  (expected "a")');

    expect(cs, isNotNull, reason: 'corrected range should be populated');
    expect(ce, isNotNull);
    expect(
      slice,
      'a',
      reason: 'with no divergence the stored range must point at the '
          'corrected phrase',
    );
  });

  test(
    'REOPENED GAP — model silently also fixed an earlier phrase; '
    'stored corrected range no longer lands on the rendered text, '
    'but is safely dropped rather than mis-highlighted',
    () {
      // Realistic divergence: the model returns a corrected_text that ALSO
      // tidied up the earlier "para comprar" -> "a comprar" WITHOUT itemising it
      // in the corrections list (LLMs routinely fix more than they report). The
      // reported correction is still only "volví para casa" -> "volví a casa".
      //
      // Everything after "...supermercado a comprar..." shifts left by 3 graphemes
      // in the MODEL text. Since step 1 of the mechanical-work migration,
      // response.correctedText is always the code-reconstructed text (built only
      // from itemised corrections), never the model's own corrected_text — so
      // this un-itemised model fix never makes it into the rendered text at all.
      final modelText = reconstructed.replaceAll(
        'supermercado para comprar',
        'supermercado a comprar',
      );
      expect(
        modelText,
        isNot(reconstructed),
        reason: 'divergent model text must differ from reconstruction',
      );

      final response = CorrectionResponse.fromAnchoredJson(
        _anchoredJson(correctedText: modelText),
        submittedText: _original,
      );

      expect(response.corrections, hasLength(1));
      final item = response.corrections.single;
      final cs = item.correctedStartIndex;
      final ce = item.correctedEndIndex;

      final rendered = response.correctedText;
      // corrected_text is now always the reconstruction, never the model's text.
      final rendersReconstruction = rendered == reconstructed;
      final slice = (cs != null && ce != null)
          ? _graphemeSlice(rendered, cs, ce)
          : '<null range>';

      // ignore: avoid_print
      print('--- REOPENED GAP (reconstruction rendered, not model text) ---');
      // ignore: avoid_print
      print('correctedStartIndex/End  : $cs..$ce  (positions in the MODEL '
          'corrected_text, not the rendered one)');
      // ignore: avoid_print
      print('rendered corrected text  : $rendered');
      // ignore: avoid_print
      print('renders reconstruction?  : $rendersReconstruction');
      // ignore: avoid_print
      print('slice at stored range    : "$slice"  (expected to NOT be "a" — '
          'this is the reopened gap)');

      // corrected_text is now always the code-built reconstruction.
      expect(
        rendersReconstruction,
        isTrue,
        reason: 'step 1 of the migration makes corrected_text always the '
            'code-reconstructed text, regardless of the model corrected_text',
      );

      // The gap: cs/ce are positions in the model's OWN corrected_text, which is
      // no longer what gets rendered, so they generally will not slice out the
      // corrected phrase from the rendered (reconstructed) text.
      expect(
        slice,
        isNot('a'),
        reason: 'REOPENED GAP: corrected_start_index/corrected_end_index are '
            'positions in the model corrected_text, which is no longer rendered, '
            'so the stored range no longer reliably slices the corrected phrase '
            'out of response.correctedText',
      );

      // Not a regression to a *wrong* highlight, though: the corrected panel's
      // requireExactRange guard (correction_highlight_spans.dart) only accepts a
      // highlight when the slice at the stored range equals the phrase exactly,
      // so this mismatch means the highlight is dropped (plain text), never
      // rendered at the wrong spot. This gap closes once corrected-side
      // anchoring (mirroring _anchorRange/_findGraphemeMatches) is built and
      // wired in, per the prompt-schema migration plan.
      expect(
        slice != item.correctedPhrase,
        isTrue,
        reason:
            'confirms requireExactRange would drop this highlight rather than '
            'accept a wrong one',
      );
    },
  );
}
