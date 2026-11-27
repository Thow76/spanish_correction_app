import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/practice/domain/sentence_diff.dart';

// Step P.4: the sentence comparison moved out of the Spanish Games app's
// SentenceText helper (docs/games_port_source/sentence_text.dart.txt). The
// games had no tests for it, so these are new.

List<String> changedIn(String target, String other) => [
  for (final w in sentenceDiff(target, other))
    if (w.changed) w.word,
];

void main() {
  group('sentenceWords', () {
    test('splits on any white space and drops the empty ends', () {
      expect(sentenceWords('  Hola,   ¿qué\ttal?\n'), ['Hola,', '¿qué', 'tal?']);
    });

    test('an empty or blank sentence has no words', () {
      expect(sentenceWords(''), isEmpty);
      expect(sentenceWords('   '), isEmpty);
    });
  });

  group('wordKey', () {
    test('ignores case and the punctuation on a word\'s edges', () {
      expect(wordKey('¿Qué'), 'qué');
      expect(wordKey('tal?'), 'tal');
      expect(wordKey('«Hola»,'), 'hola');
      expect(wordKey('(bien).'), 'bien');
    });

    test('keeps accents and punctuation inside a word', () {
      expect(wordKey('está'), isNot(wordKey('esta')));
      expect(wordKey('3,5'), '3,5');
    });
  });

  group('sentenceDiff', () {
    test('one word replaced: only that word is marked, in each direction', () {
      const written = 'Estoy pensando de cambiar de trabajo.';
      const suggested = 'Estoy pensando en cambiar de trabajo.';
      expect(changedIn(written, suggested), ['de']);
      expect(changedIn(suggested, written), ['en']);
    });

    test('it marks the right "de" when the word appears twice', () {
      final diff = sentenceDiff(
        'Estoy pensando de cambiar de trabajo.',
        'Estoy pensando en cambiar de trabajo.',
      );
      expect(diff.map((w) => w.changed), [
        false,
        false,
        true,
        false,
        false,
        false,
      ]);
    });

    test('keeps every word of the target, in order, as written', () {
      final diff = sentenceDiff('Ayer yo fue al mercado.', 'Ayer fui al mercado.');
      expect(diff.map((w) => w.word), ['Ayer', 'yo', 'fue', 'al', 'mercado.']);
    });

    test('identical sentences: nothing changed', () {
      expect(changedIn('Me gusta el café.', 'Me gusta el café.'), isEmpty);
    });

    test('a difference only in capitals or edge punctuation is no change', () {
      expect(changedIn('hola, ¿qué tal', 'Hola. ¿Qué tal?'), isEmpty);
    });

    test('an accent is a change', () {
      expect(changedIn('Donde esta el baño?', '¿Dónde está el baño?'), [
        'Donde',
        'esta',
      ]);
      expect(changedIn('¿Dónde está el baño?', 'Donde esta el baño?'), [
        '¿Dónde',
        'está',
      ]);
    });

    test('a word the suggestion adds shows only in the suggestion', () {
      const written = 'Tengo ir al médico.';
      const suggested = 'Tengo que ir al médico.';
      expect(changedIn(written, suggested), isEmpty);
      expect(changedIn(suggested, written), ['que']);
    });

    test('a word the suggestion removes shows only in what was written', () {
      const written = 'Yo me lo comí la manzana.';
      const suggested = 'Yo me comí la manzana.';
      expect(changedIn(written, suggested), ['lo']);
      expect(changedIn(suggested, written), isEmpty);
    });

    test('two separate changes are both marked', () {
      expect(
        changedIn(
          'Ayer yo fue al mercado y hice una decisión.',
          'Ayer yo fui al mercado y tomé una decisión.',
        ),
        ['fue', 'hice'],
      );
    });

    test('completely different sentences: every word changed', () {
      expect(changedIn('uno dos tres', 'cuatro cinco'), ['uno', 'dos', 'tres']);
    });

    test('an empty other sentence: every word changed; an empty target: '
        'nothing', () {
      expect(changedIn('uno dos', ''), ['uno', 'dos']);
      expect(sentenceDiff('', 'uno dos'), isEmpty);
    });
  });

  group('changedRuns', () {
    test('a single changed word is one run', () {
      expect(
        changedRuns(
          'Estoy pensando en cambiar de trabajo.',
          'Estoy pensando de cambiar de trabajo.',
        ),
        ['en'],
      );
    });

    test('neighbouring changed words come first as a run, then each word '
        'on its own', () {
      expect(changedRuns('Yo me llamo Andrew.', 'Yo soy Andrew.'), [
        'me llamo',
        'me',
        'llamo',
      ]);
    });

    test('separate runs come in sentence order, all runs before the single '
        'words', () {
      expect(
        changedRuns(
          'Ayer fui al mercado y tomé una decisión importante.',
          'Ayer yo fue en mercado y hice una decisión importante.',
        ),
        ['fui al', 'tomé', 'fui', 'al'],
      );
    });

    test('no repeats: a word changed twice is listed once', () {
      expect(changedRuns('Voy a casa y a clase.', 'Voy en casa y en clase.'), [
        'a',
      ]);
    });

    test('repeats are judged without case or edge punctuation, and the '
        'first spelling is kept', () {
      expect(changedRuns('Sí, claro. Sí.', 'No, claro. No.'), ['Sí,']);
    });

    test('a changed word keeps its punctuation as written', () {
      expect(changedRuns('Vivo en Madrid.', 'Vivo en Londres.'), ['Madrid.']);
    });

    test('nothing changed: an empty list', () {
      expect(changedRuns('Me gusta el café.', 'me gusta el café'), isEmpty);
    });

    test('a changed word that is only punctuation is left out', () {
      expect(changedRuns('Hola . Adiós', 'Hola Adiós'), isEmpty);
    });
  });
}
