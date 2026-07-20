import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_insertion_offset_calculator.dart';

void main() {
  test('"Creo está bien" -> "Creo que está bien": pure insertion of "que " after "Creo "', () {
    final result = calculateInsertionOffset(
      originalPhrase: 'Creo está bien',
      correctedPhrase: 'Creo que está bien',
    );

    expect(result, isNotNull);
    expect(result!.offset, 'Creo '.length);
    expect(result.insertedText, 'que ');
  });

  test('"Voy la playa" -> "Voy a la playa": pure insertion of "a " after "Voy "', () {
    final result = calculateInsertionOffset(
      originalPhrase: 'Voy la playa',
      correctedPhrase: 'Voy a la playa',
    );

    expect(result, isNotNull);
    expect(result!.offset, 'Voy '.length);
    expect(result.insertedText, 'a ');
  });

  test('"Cómo estás" -> "¿Cómo estás": pure insertion of "¿" at offset 0 (prefix insertion)', () {
    final result = calculateInsertionOffset(
      originalPhrase: 'Cómo estás',
      correctedPhrase: '¿Cómo estás',
    );

    expect(result, isNotNull);
    expect(result!.offset, 0);
    expect(result.insertedText, '¿');
  });

  test(
    '"trafico" -> "tráfico": same length, a character change not a pure '
    'insertion — must report null, not a bogus offset',
    () {
      final result = calculateInsertionOffset(
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
      );

      expect(result, isNull);
    },
  );

  test(
    'original_phrase == corrected_phrase (e.g. a not_an_error/dialectal '
    'correction with no substitution) reports null, not an error',
    () {
      final result = calculateInsertionOffset(
        originalPhrase: 'coche',
        correctedPhrase: 'coche',
      );

      expect(result, isNull);
    },
  );

  test('a swap where the corrected phrase is shorter is not a pure insertion', () {
    final result = calculateInsertionOffset(
      originalPhrase: 'pasé un buen tiempo',
      correctedPhrase: 'lo pasé bien',
    );

    expect(result, isNull);
  });

  test('a pure deletion (corrected is a strict prefix+suffix subset, nothing added) reports null', () {
    // Nothing is inserted here — corrected is shorter, so this cannot be a
    // pure insertion by definition (insertedText would be empty or
    // negative-length), and must not be reported as one.
    final result = calculateInsertionOffset(
      originalPhrase: 'muy muy bien',
      correctedPhrase: 'muy bien',
    );

    expect(result, isNull);
  });

  test('empty original_phrase inserts the whole corrected phrase at offset 0', () {
    final result = calculateInsertionOffset(originalPhrase: '', correctedPhrase: 'nuevo');

    expect(result, isNotNull);
    expect(result!.offset, 0);
    expect(result.insertedText, 'nuevo');
  });
}
