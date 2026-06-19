import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';

/// Read-only experiment for Bug 1.
///
/// Theory: the corrected-side highlight range
/// (`correctedStartIndex`/`correctedEndIndex`) is computed by
/// `_withCorrectedRanges` against the *reconstructed* corrected text (original
/// with the reported corrections spliced in), but the corrections screen
/// renders `response.correctedText`, which is the *model's* corrected text when
/// `_shouldUseModelCorrectedText` is true. When the two diverge, the stored
/// corrected range no longer points at the corrected phrase in the rendered
/// text, the range-first `slice == phrase` check in the highlight resolver
/// fails, and the highlight falls back to substring-matching the single
/// character "a".
///
/// These tests change no production code. They feed synthetic anchored JSON
/// through `CorrectionResponse.fromAnchoredJson` exactly as the live services
/// (`open_ai_correction_service` / `gemini_correction_service`) do, then print
/// and assert the computed indices and the slice of the *rendered* text.

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
      },
    ],
  };
}

void main() {
  // The reconstructed corrected text: the original with ONLY the reported
  // correction (volví para casa -> volví a casa) spliced in. This is exactly
  // what `_reconstructCorrectedText` produces, and what the corrected-range
  // math in `_withCorrectedRanges` assumes the rendered text will be.
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

  test('DIVERGENT — model silently also fixed an earlier phrase', () {
    // Realistic divergence: the model returns a corrected_text that ALSO
    // tidied up the earlier "para comprar" -> "a comprar" WITHOUT itemising it
    // in the corrections list (LLMs routinely fix more than they report). The
    // reported correction is still only "volví para casa" -> "volví a casa".
    //
    // Result: everything after "...supermercado a comprar..." shifts left by 3
    // graphemes in the MODEL text, but `_withCorrectedRanges` computed the
    // corrected range from the reconstruction, where that earlier shift does
    // not exist.
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
    print('--- DIVERGENT (model text rendered) ---');
    // ignore: avoid_print
    print('correctedStartIndex/End : $cs..$ce  (from reconstruction)');
    // ignore: avoid_print
    print('rendered corrected text  : $rendered');
    // ignore: avoid_print
    print('renders model text?      : $rendersModel');
    // ignore: avoid_print
    print('true "a" index in rendered: $trueAIndex '
        '(stored start is $cs)');
    // ignore: avoid_print
    print('slice at stored range    : "$slice"  (NOT "a" at the right spot '
        'would confirm Bug 1)');

    // Document the rendered path explicitly. If the model text is NOT rendered
    // here, divergence cannot manifest and the report must say so.
    expect(
      rendersModel,
      isTrue,
      reason: 'this scenario only exercises Bug 1 if _shouldUseModelCorrectedText '
          'selects the model text',
    );

    // The confirmation: when the model text is rendered, the stored corrected
    // range (computed from the reconstruction) no longer slices "a" at the
    // intended "volví a casa" position.
    final slicesCorrectPhraseAtIntendedSpot = (cs == trueAIndex) && slice == 'a';
    // ignore: avoid_print
    print('stored range still correct? : $slicesCorrectPhraseAtIntendedSpot');

    expect(
      slicesCorrectPhraseAtIntendedSpot,
      isFalse,
      reason: 'CONFIRMS Bug 1: divergence between reconstructed and rendered '
          'text leaves the stored corrected range pointing at the wrong place',
    );
  });
}
