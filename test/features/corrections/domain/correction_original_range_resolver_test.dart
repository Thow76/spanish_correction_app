import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_original_range_resolver.dart';

const String _es1Text =
    'Ayer fui al supermercado para comprar pan y después volví para casa '
    'para preparar la cena.';

void main() {
  test('empty corrections list returns empty list', () {
    expect(resolveOccurrenceCorrections(_es1Text, const []), isEmpty);
  });

  test(
    'ES-1 canonical case: occurrence 2 resolves to the "para" before '
    '"casa", not the ones before "comprar" or "preparar"',
    () {
      // "para" appears 4 times left to right in _es1Text: before "comprar"
      // (occurrence 1), before "casa" (occurrence 2), before "preparar"
      // (occurrence 3, standalone word), and embedded inside "preparar"
      // itself (occurrence 4, "pre-PARA-r"). occurrence: 2 must land on
      // the second of these — the one before "casa" — regardless of that
      // 4th embedded match existing further right in the text.
      final expectedStart = _es1Text.indexOf('para casa');
      expect(expectedStart, isNot(-1));

      final result = resolveOccurrenceCorrections(_es1Text, const [
        OccurrenceCorrection(originalPhrase: 'para', occurrence: 2),
      ]);

      expect(result, hasLength(1));
      expect(result.single.startIndex, expectedStart);

      // Sanity check this is genuinely the "casa" one and not "comprar" or
      // "preparar".
      expect(_es1Text.substring(expectedStart, expectedStart + 9), 'para casa');
    },
  );

  test(
    'multiple corrections with duplicate phrase text at different '
    'occurrence values resolve independently, not dependent on order',
    () {
      const text = 'yo fui, yo comí, y yo dormí.';
      final firstYo = text.indexOf('yo');
      final secondYo = text.indexOf('yo', firstYo + 1);
      final thirdYo = text.indexOf('yo', secondYo + 1);

      // Deliberately out of occurrence order in the input list — result
      // must not depend on processing order.
      final result = resolveOccurrenceCorrections(text, const [
        OccurrenceCorrection(originalPhrase: 'yo', occurrence: 3),
        OccurrenceCorrection(originalPhrase: 'yo', occurrence: 1),
        OccurrenceCorrection(originalPhrase: 'yo', occurrence: 2),
      ]);

      expect(result, hasLength(3));
      final byOccurrence = {for (final r in result) r.occurrence: r.startIndex};
      expect(byOccurrence[3], thirdYo);
      expect(byOccurrence[1], firstYo);
      expect(byOccurrence[2], secondYo);
    },
  );

  test('occurrence 1 on a phrase that only appears once resolves correctly', () {
    const text = 'Vivo en España desde hace tres años.';
    final expectedStart = text.indexOf('España');

    final result = resolveOccurrenceCorrections(text, const [
      OccurrenceCorrection(originalPhrase: 'España', occurrence: 1),
    ]);

    expect(result, hasLength(1));
    expect(result.single.startIndex, expectedStart);
  });

  test(
    'occurrence requested higher than the number of actual matches is '
    'dropped silently, not thrown',
    () {
      const text = 'para uno, para dos.'; // "para" appears twice.

      final result = resolveOccurrenceCorrections(text, const [
        OccurrenceCorrection(originalPhrase: 'para', occurrence: 3),
      ]);

      expect(result, isEmpty);
    },
  );

  test('a phrase that does not appear in the text at all is dropped silently', () {
    const text = 'Compré pan y leche esta mañana.';

    final result = resolveOccurrenceCorrections(text, const [
      OccurrenceCorrection(originalPhrase: 'trafico', occurrence: 1),
    ]);

    expect(result, isEmpty);
  });

  test('dropping unresolvable corrections does not affect resolvable ones in the same call', () {
    const text = 'Compré pan y leche esta mañana.';

    final result = resolveOccurrenceCorrections(text, const [
      OccurrenceCorrection(originalPhrase: 'trafico', occurrence: 1),
      OccurrenceCorrection(originalPhrase: 'pan', occurrence: 1),
      OccurrenceCorrection(originalPhrase: 'leche', occurrence: 5),
    ]);

    expect(result, hasLength(1));
    expect(result.single.originalPhrase, 'pan');
    expect(result.single.startIndex, text.indexOf('pan'));
  });

  test('accented characters and ñ in both the surrounding text and the phrase resolve correctly', () {
    const text = 'Mi cumpleaños es en otoño, y el cumpleaños de mi hermana es en verano.';
    final firstCumple = text.indexOf('cumpleaños');
    final secondCumple = text.indexOf('cumpleaños', firstCumple + 1);
    expect(firstCumple, isNot(secondCumple));

    final result = resolveOccurrenceCorrections(text, const [
      OccurrenceCorrection(originalPhrase: 'cumpleaños', occurrence: 2),
    ]);

    expect(result, hasLength(1));
    expect(result.single.startIndex, secondCumple);
  });
}
