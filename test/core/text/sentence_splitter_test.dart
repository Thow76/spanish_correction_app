import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/text/sentence_splitter.dart';

void main() {
  group('splitIntoSentences', () {
    test('splits a multi-sentence paragraph on . ! ?', () {
      final spans = splitIntoSentences(
        'Fui al mercado. ¿Compraste pan? ¡Qué bien!',
      );

      expect(spans.map((s) => s.text).toList(), [
        'Fui al mercado.',
        '¿Compraste pan?',
        '¡Qué bien!',
      ]);
    });

    test('returns the whole text as one sentence when there is no punctuation', () {
      final spans = splitIntoSentences('Fui al mercado');

      expect(spans, hasLength(1));
      expect(spans.single.text, 'Fui al mercado');
    });

    test('drops empty fragments from consecutive terminators and whitespace', () {
      final spans = splitIntoSentences('Hola...   Adiós!!');

      expect(spans.map((s) => s.text).toList(), ['Hola...', 'Adiós!!']);
    });

    test('offsets are grapheme-indexed and round-trip via substring', () {
      const text = 'Fui al mercado. Compré pan.';
      final spans = splitIntoSentences(text);

      final graphemes = text.characters.toList();
      for (final span in spans) {
        expect(graphemes.sublist(span.start, span.end).join(), span.text);
      }
    });

    test('handles empty input', () {
      expect(splitIntoSentences(''), isEmpty);
    });

    test('handles a string that is only whitespace and punctuation', () {
      expect(splitIntoSentences('   ... '), isEmpty);
    });
  });
}
