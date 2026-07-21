import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';

/// Regression guard for Bug 1 — now permanently closed by construction.
///
/// History: the corrected-side highlight range
/// (`correctedStartIndex`/`correctedEndIndex`) used to be computed arithmetically
/// (`_withCorrectedRanges`) against the *reconstructed* corrected text, while the
/// corrections screen rendered `response.correctedText` — the *model's* corrected
/// text when `_shouldUseModelCorrectedText` was true. When the two diverged the
/// stored range no longer pointed at the corrected phrase in the rendered text.
///
/// An interim fix made the model report `corrected_start_index`/`corrected_end_index`
/// as positions into its OWN corrected_text, which avoided the divergence as long
/// as the model's corrected_text was what got rendered. That created a *different*
/// gap when step 1 of the mechanical-work migration made `corrected_text` always
/// the code-reconstructed text: the model's reported corrected indices (positions
/// in its own, no-longer-rendered corrected_text) could once again miss the
/// rendered text.
///
/// The permanent fix (step 9): `corrected_start_index`/`corrected_end_index` are no
/// longer requested from the model at all (dropped from the schema), and
/// `computeCorrectedRanges` computes them by pure arithmetic directly from the
/// same anchored corrections and the same code-built `correctedText` — both
/// derived from a single source (the deduped corrections list against
/// `submittedText`). There is no longer a second, independent source of truth
/// that could disagree, so this class of bug cannot recur structurally, not just
/// "usually" — it doesn't matter what a model claims about corrected_text or
/// corrected indices; the app never reads them for this purpose.
///
/// These tests feed synthetic anchored JSON through
/// `CorrectionResponse.fromAnchoredJson` exactly as the live service
/// (`open_ai_correction_service`) does.

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

/// Builds anchored JSON for the "volví para casa" -> "volví a casa"
/// correction. [staleModelCorrectedText], [staleCorrectedStartIndex], and
/// [staleCorrectedEndIndex] simulate a non-conforming or legacy response that
/// still includes the now-dropped model-reported fields — the app must
/// ignore all three and compute its own values regardless.
Map<String, Object?> _anchoredJson({
  String? staleModelCorrectedText,
  int? staleCorrectedStartIndex,
  int? staleCorrectedEndIndex,
}) {
  final paraStart = _targetParaStart();
  return {
    'original_text': _original,
    'corrected_text': ?staleModelCorrectedText,
    'corrections': [
      {
        'original_phrase': 'para',
        'corrected_phrase': 'a',
        'category': 'Grammar',
        'short_explanation': 'Use "a" with verbs of movement: volví a casa.',
        'start_index': paraStart,
        'corrected_start_index': ?staleCorrectedStartIndex,
        'corrected_end_index': ?staleCorrectedEndIndex,
      },
    ],
  };
}

void main() {
  // The code-reconstructed corrected text: the original with ONLY the
  // reported correction (volví para casa -> volví a casa) spliced in. This is
  // exactly what `_reconstructCorrectedText` produces, and it is always what
  // `response.correctedText` equals now, regardless of any model input.
  final reconstructed = _original.replaceAll(
    'volví para casa',
    'volví a casa',
  );

  test(
    'corrected-side range is computed correctly against the code-built '
    'corrected text (no model input for it at all)',
    () {
      final response = CorrectionResponse.fromAnchoredJson(
        _anchoredJson(),
        submittedText: _original,
      );

      expect(response.correctedText, reconstructed);
      expect(response.corrections, hasLength(1));

      final item = response.corrections.single;
      expect(item.correctedStartIndex, isNotNull);
      expect(item.correctedEndIndex, isNotNull);

      final slice = _graphemeSlice(
        response.correctedText,
        item.correctedStartIndex!,
        item.correctedEndIndex!,
      );
      expect(
        slice,
        'a',
        reason:
            'the computed range must point at the corrected phrase in the '
            'code-built corrected text',
      );
    },
  );

  test(
    'a stale/divergent corrected_text, corrected_start_index, and '
    'corrected_end_index in the JSON have zero effect — the app computes '
    'its own consistent values regardless',
    () {
      // Simulates exactly the scenario that used to reopen this bug: a model
      // response whose corrected_text silently also fixed an earlier phrase
      // ("para comprar" -> "a comprar") without itemising it, plus
      // corrected_start_index/corrected_end_index pointing at "a" inside
      // THAT (divergent) corrected_text. None of these fields exist in the
      // schema anymore, but nothing stops a non-conforming response from
      // including them — the app must not be fooled by them.
      final staleModelText = reconstructed.replaceAll(
        'supermercado para comprar',
        'supermercado a comprar',
      );
      expect(
        staleModelText,
        isNot(reconstructed),
        reason: 'stale model text must differ from the reconstruction',
      );
      // Position of "a" (from "volví a casa") inside the STALE model text —
      // shifted 3 graphemes left of where it sits in the real reconstruction,
      // because of the un-itemised fix baked into staleModelText.
      final staleClause = _graphemeIndexOf(staleModelText, 'volví a casa');
      expect(staleClause, isNot(-1));
      final staleAStart = staleClause + 'volví '.characters.length;

      final response = CorrectionResponse.fromAnchoredJson(
        _anchoredJson(
          staleModelCorrectedText: staleModelText,
          staleCorrectedStartIndex: staleAStart,
          staleCorrectedEndIndex: staleAStart + 'a'.characters.length,
        ),
        submittedText: _original,
      );

      // corrected_text is always the code reconstruction, never the stale
      // model value, and never influenced by it.
      expect(response.correctedText, reconstructed);
      expect(response.correctedText, isNot(staleModelText));

      expect(response.corrections, hasLength(1));
      final item = response.corrections.single;

      // The computed range does NOT equal the stale corrected_start_index
      // supplied in the JSON — it is computed fresh, ignoring that value.
      expect(item.correctedStartIndex, isNot(staleAStart));

      final slice = _graphemeSlice(
        response.correctedText,
        item.correctedStartIndex!,
        item.correctedEndIndex!,
      );
      expect(
        slice,
        'a',
        reason:
            'the app computes its own correct range against the real '
            'reconstruction, regardless of whatever the (now nonexistent) '
            'model-reported corrected_text/corrected_start_index/'
            'corrected_end_index fields claimed',
      );
    },
  );
}
