import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/practice/domain/ordering_window.dart';

// Step P.3: one test for each case in the comment on `orderWindow_` in the
// Spanish Games sheet script (docs/games_port_source/test_review.gs.txt).

// Thirteen words; "fui" is word 5.
const corrected =
    'Ayer por la tarde fui al mercado con mi hermana y compré fruta.';
const written =
    'Ayer por la tarde fue al mercado con mi hermana y compré fruta.';

void main() {
  group('the whole sentence is shuffled (no window)', () {
    test('a sentence of 8 words: no window', () {
      const eight = 'Ayer fui al mercado con mi hermana pequeña.';
      expect(eight.split(' ').length, orderWindowSize);
      expect(
        orderWindow(eight, [eight], 'Ayer fue al mercado con mi hermana pequeña.'),
        isNull,
      );
    });

    test('a shorter sentence: no window', () {
      expect(orderWindow('Ayer fui al mercado.', [], 'Ayer fue al mercado.'), isNull);
    });

    test('a long sentence with no original: no window', () {
      expect(orderWindow(corrected, [corrected], ''), isNull);
      expect(orderWindow(corrected, [corrected], '   '), isNull);
    });

    test('a long sentence where nothing changed: no window', () {
      expect(orderWindow(corrected, [corrected], corrected), isNull);
    });

    test('a difference only in capitals or final punctuation is not a '
        'change', () {
      expect(
        orderWindow(
          corrected,
          [corrected],
          'ayer por la tarde fui al mercado con mi hermana y compré fruta',
        ),
        isNull,
      );
    });
  });

  group('the 8-word window', () {
    test('a sentence of 9 words gets a window', () {
      final window = orderWindow(
        'Ayer fui al mercado con mi hermana pequeña Ana.',
        [],
        'Ayer fue al mercado con mi hermana pequeña Ana.',
      )!;
      expect(window.prompt, 'Ayer fui al mercado con mi hermana pequeña');
      expect(window.fixedStart, isNull);
      expect(window.fixedEnd, 'Ana.');
    });

    test('the corrected word sits in the middle of 8 words, with the rest '
        'as fixed text', () {
      final window = orderWindow(corrected, [corrected], written)!;
      expect(window.prompt, 'por la tarde fui al mercado con mi');
      expect(window.prompt.split(' ').length, orderWindowSize);
      expect(window.fixedStart, 'Ayer');
      expect(window.fixedEnd, 'hermana y compré fruta.');
      expect(window.answers, ['por la tarde fui al mercado con mi']);
    });

    test('fixed start, window and fixed end put back together give the '
        'corrected sentence', () {
      final window = orderWindow(corrected, [corrected], written)!;
      expect(
        '${window.fixedStart} ${window.prompt} ${window.fixedEnd}',
        corrected,
      );
    });

    test('a change at the start: the window is the first 8 words, with no '
        'fixed start', () {
      final window = orderWindow(
        corrected,
        [corrected],
        'Anoche por la tarde fui al mercado con mi hermana y compré fruta.',
      )!;
      expect(window.prompt, 'Ayer por la tarde fui al mercado con');
      expect(window.fixedStart, isNull);
      expect(window.fixedEnd, 'mi hermana y compré fruta.');
    });

    test('a change at the end: the window is the last 8 words, with no '
        'fixed end', () {
      final window = orderWindow(
        corrected,
        [corrected],
        'Ayer por la tarde fui al mercado con mi hermana y compré pan.',
      )!;
      expect(window.prompt, 'al mercado con mi hermana y compré fruta.');
      expect(window.fixedStart, 'Ayer por la tarde fui');
      expect(window.fixedEnd, isNull);
    });

    test('two changes close together are both inside the window', () {
      final window = orderWindow(
        corrected,
        [corrected],
        'Ayer por la tarde fue en mercado con mi hermana y compré fruta.',
      )!;
      expect(window.prompt, 'por la tarde fui al mercado con mi');
    });

    test('changed words spanning more than 8: the window is the first 8 '
        'of them', () {
      final window = orderWindow(
        corrected,
        [corrected],
        'Ayer en el día fue en tienda de su hermano e compró fruta.',
      )!;
      // Words 2 to 12 changed (por … compré); the window starts at "por".
      expect(window.prompt, 'por la tarde fui al mercado con mi');
      expect(window.fixedStart, 'Ayer');
      expect(window.fixedEnd, 'hermana y compré fruta.');
    });

    test('a word added by the correction counts as the change', () {
      final window = orderWindow(
        'Mañana por la mañana tengo que ir al médico con mi madre.',
        [],
        'Mañana por la mañana tengo ir al médico con mi madre.',
      )!;
      expect(window.prompt, 'la mañana tengo que ir al médico con');
      expect(window.fixedStart, 'Mañana por');
      expect(window.fixedEnd, 'mi madre.');
    });
  });

  group('alternative answers', () {
    test('an alternative that shares the fixed start and end is kept, cut '
        'to its window', () {
      final window = orderWindow(corrected, [
        corrected,
        'Ayer fui por la tarde al mercado con mi hermana y compré fruta.',
      ], written)!;
      expect(window.answers, [
        'por la tarde fui al mercado con mi',
        'fui por la tarde al mercado con mi',
      ]);
    });

    test('an alternative with a different fixed start is dropped', () {
      final window = orderWindow(corrected, [
        corrected,
        'Anoche por la tarde fui al mercado con mi hermana y compré fruta.',
      ], written)!;
      expect(window.answers, ['por la tarde fui al mercado con mi']);
    });

    test('an alternative with a different fixed end is dropped', () {
      final window = orderWindow(corrected, [
        corrected,
        'Ayer por la tarde fui al mercado con mi hermana y compré pan.',
      ], written)!;
      expect(window.answers, ['por la tarde fui al mercado con mi']);
    });

    test('the fixed text must match word for word, capitals and '
        'punctuation included', () {
      final window = orderWindow(corrected, [
        corrected,
        'ayer por la tarde fui al mercado con mi hermana y compré fruta.',
        'Ayer por la tarde fui al mercado con mi hermana y compré fruta',
      ], written)!;
      expect(window.answers, ['por la tarde fui al mercado con mi']);
    });

    test('an alternative too short to hold the fixed text is dropped', () {
      final window = orderWindow(corrected, [
        corrected,
        'Ayer hermana y compré fruta.',
      ], written)!;
      expect(window.answers, ['por la tarde fui al mercado con mi']);
    });

    test('an alternative may have a longer or shorter window', () {
      final window = orderWindow(corrected, [
        corrected,
        'Ayer por la tarde me fui al mercado con mi hermana y compré fruta.',
      ], written)!;
      expect(window.answers, [
        'por la tarde fui al mercado con mi',
        'por la tarde me fui al mercado con mi',
      ]);
    });

    test('the same window is never listed twice', () {
      final window = orderWindow(corrected, [
        corrected,
        corrected,
      ], written)!;
      expect(window.answers, ['por la tarde fui al mercado con mi']);
    });

    test('with no answers given, the corrected window is the one answer', () {
      final window = orderWindow(corrected, const [], written)!;
      expect(window.answers, [window.prompt]);
    });
  });
}
