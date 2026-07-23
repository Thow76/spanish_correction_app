import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_span_trim_calculator.dart';

void main() {
  test('cerveza-shape: trims the shared trailing context, leaving only the '
      'actual predicate swap', () {
    final result = calculateSharedAffixTrim(
      originalPhrase: '¿Puedo tener una cerveza?',
      correctedPhrase: '¿Me da una cerveza?',
    );

    expect(
      result.prefixLength,
      1,
      reason: 'shared "¿" only — "P" vs "M" diverge right after',
    );
    expect(
      result.suffixLength,
      13,
      reason: '" una cerveza?" is shared verbatim at the end',
    );
    expect(result.trimmedOriginalPhrase, 'Puedo tener');
    expect(result.trimmedCorrectedPhrase, 'Me da');
  });

  test('repetition case ("tengo tengo" -> "tengo"): the overlap-capping guard '
      'stops the suffix walk from re-claiming graphemes the prefix walk '
      'already consumed', () {
    final result = calculateSharedAffixTrim(
      originalPhrase: 'tengo tengo',
      correctedPhrase: 'tengo',
    );

    // Without the cap, the trailing "tengo" would match as a suffix too
    // (both phrases end in "tengo"), pushing prefixLength + suffixLength
    // to 10 against a 5-grapheme correctedPhrase — an out-of-range,
    // negative-length slice on the corrected side. The cap forces
    // suffixLength to stop at 0 once the prefix walk has already spent
    // the whole budget — prefixLength/suffixLength together never exceed
    // the shorter phrase's length.
    expect(
      result.prefixLength,
      5,
      reason: 'prefix walk consumes the whole shorter phrase ("tengo")',
    );
    expect(
      result.suffixLength,
      0,
      reason: 'no budget left for the suffix walk after the cap',
    );
    expect(result.trimmedOriginalPhrase, ' tengo');
    expect(result.trimmedCorrectedPhrase, '');
  });

  test('no shared affix at either end is a no-op', () {
    final result = calculateSharedAffixTrim(
      originalPhrase: 'azul',
      correctedPhrase: 'rojo',
    );

    expect(result.prefixLength, 0);
    expect(result.suffixLength, 0);
    expect(result.trimmedOriginalPhrase, 'azul');
    expect(result.trimmedCorrectedPhrase, 'rojo');
  });

  test('a coincidental shared trailing letter that is not a real word boundary '
      'is not trimmed, even though the raw grapheme walk would match it', () {
    // "el finde siguiente" vs "el finde que viene": the shared leading
    // "el finde " is a real word boundary (ends in a space) and gets
    // trimmed as before, but the two phrases also happen to both end in
    // "e" (from "siguiente" and "viene") purely by coincidence — not a
    // real shared suffix. Trimming that "e" would cut both phrases
    // mid-word, producing "siguient" / "que vien".
    final result = calculateSharedAffixTrim(
      originalPhrase: 'el finde siguiente',
      correctedPhrase: 'el finde que viene',
    );

    expect(
      result.prefixLength,
      9,
      reason: '"el finde " is a real, space-terminated shared prefix',
    );
    expect(
      result.suffixLength,
      0,
      reason:
          'the shared trailing "e" is mid-word in both phrases, so it must not be trimmed',
    );
    expect(result.trimmedOriginalPhrase, 'siguiente');
    expect(result.trimmedCorrectedPhrase, 'que viene');
  });

  test('a coincidental shared leading letter that is not a real word boundary '
      'is not trimmed on the prefix side either', () {
    // "andar" vs "antes ese camino": both start with "an", but that's a
    // coincidental letter match mid-word in "andar", not a real shared
    // prefix word — trimming it would cut "andar" into "dar" while
    // leaving the rest of the corrected phrase untouched, an
    // unrelated-looking result.
    final result = calculateSharedAffixTrim(
      originalPhrase: 'andar',
      correctedPhrase: 'antes ese camino',
    );

    expect(
      result.prefixLength,
      0,
      reason:
          'the shared leading "an" is mid-word in "andar", so it must not be trimmed',
    );
    expect(result.trimmedOriginalPhrase, 'andar');
    expect(result.trimmedCorrectedPhrase, 'antes ese camino');
  });
}
