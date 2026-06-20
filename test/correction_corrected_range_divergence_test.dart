import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';

/// Regression guard for Bug 1 (now fixed).
///
/// History: the corrected-side highlight range
/// (`correctedStartIndex`/`correctedEndIndex`) used to be computed arithmetically
/// (`_withCorrectedRanges`) against the *reconstructed* corrected text, while the
/// corrections screen renders `response.correctedText` — the *model's* corrected
/// text when `_shouldUseModelCorrectedText` is true. When the two diverged the
/// stored range no longer pointed at the corrected phrase in the rendered text.
///
/// The fix: the model now reports `corrected_start_index`/`corrected_end_index`
/// as positions into its OWN corrected_text, parsing populates them directly,
/// and the arithmetic path was removed. So the stored range and the rendered
/// text share a single source and can no longer decouple.
///
/// These tests feed synthetic anchored JSON through
/// `CorrectionResponse.fromAnchoredJson` exactly as the live services
/// (`open_ai_correction_service` / `gemini_correction_service`) do, supplying the
/// corrected indices the model would report (positions in the corrected text
/// handed back), then assert the slice at the stored range equals the corrected
/// phrase at the intended location — in both the aligned and the (formerly
/// divergent) cases.

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

  test('FORMERLY DIVERGENT — model silently also fixed an earlier phrase', () {
    // Realistic divergence: the model returns a corrected_text that ALSO
    // tidied up the earlier "para comprar" -> "a comprar" WITHOUT itemising it
    // in the corrections list (LLMs routinely fix more than they report). The
    // reported correction is still only "volví para casa" -> "volví a casa".
    //
    // Everything after "...supermercado a comprar..." shifts left by 3 graphemes
    // in the MODEL text. Under the old arithmetic path (range computed from the
    // reconstruction) this is where Bug 1 manifested. Now the model reports the
    // corrected range as a position in this same model text, so the stored range
    // and the rendered text cannot decouple.
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
    final rendersModel = rendered == modelText;
    final slice = (cs != null && ce != null)
        ? _graphemeSlice(rendered, cs, ce)
        : '<null range>';

    // Where is the genuine "volví a casa" "a" in the rendered text?
    final trueClause = _graphemeIndexOf(rendered, 'volví a casa');
    final trueAIndex = trueClause == -1
        ? -1
        : trueClause + 'volví '.characters.length;

    // ignore: avoid_print
    print('--- FORMERLY DIVERGENT (model text rendered) ---');
    // ignore: avoid_print
    print('correctedStartIndex/End : $cs..$ce  (from model corrected text)');
    // ignore: avoid_print
    print('rendered corrected text  : $rendered');
    // ignore: avoid_print
    print('renders model text?      : $rendersModel');
    // ignore: avoid_print
    print('true "a" index in rendered: $trueAIndex '
        '(stored start is $cs)');
    // ignore: avoid_print
    print('slice at stored range    : "$slice"  (expected "a" at the right spot)');

    // Document the rendered path explicitly. If the model text is NOT rendered
    // here, the scenario the fix targets is not exercised and the report must
    // say so.
    expect(
      rendersModel,
      isTrue,
      reason: 'this scenario only exercises the fix if '
          '_shouldUseModelCorrectedText selects the model text',
    );

    // The fix: because the corrected range is reported against the model's own
    // corrected text (the same text that is rendered), the stored range slices
    // "a" exactly at the intended "volví a casa" position.
    final slicesCorrectPhraseAtIntendedSpot = (cs == trueAIndex) && slice == 'a';
    // ignore: avoid_print
    print('stored range correct?    : $slicesCorrectPhraseAtIntendedSpot');

    expect(
      slicesCorrectPhraseAtIntendedSpot,
      isTrue,
      reason: 'BUG 1 FIXED: the corrected range comes from the model corrected '
          'text, so even when the model fixes more than it reports, the stored '
          'range points at the corrected phrase in the rendered text',
    );
  });
}
