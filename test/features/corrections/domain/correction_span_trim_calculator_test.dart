import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_span_trim_calculator.dart';

void main() {
  test(
    'cerveza-shape: trims the shared trailing context, leaving only the '
    'actual predicate swap',
    () {
      final result = calculateSharedAffixTrim(
        originalPhrase: '¿Puedo tener una cerveza?',
        correctedPhrase: '¿Me da una cerveza?',
      );

      expect(result.prefixLength, 1, reason: 'shared "¿" only — "P" vs "M" diverge right after');
      expect(result.suffixLength, 13, reason: '" una cerveza?" is shared verbatim at the end');
      expect(result.trimmedOriginalPhrase, 'Puedo tener');
      expect(result.trimmedCorrectedPhrase, 'Me da');
    },
  );

  test(
    'repetition case ("tengo tengo" -> "tengo"): the overlap-capping guard '
    'stops the suffix walk from re-claiming graphemes the prefix walk '
    'already consumed',
    () {
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
      expect(result.prefixLength, 5, reason: 'prefix walk consumes the whole shorter phrase ("tengo")');
      expect(result.suffixLength, 0, reason: 'no budget left for the suffix walk after the cap');
      expect(result.trimmedOriginalPhrase, ' tengo');
      expect(result.trimmedCorrectedPhrase, '');
    },
  );

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
}
