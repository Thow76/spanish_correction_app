import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/text/phrase_chunker.dart';

/// Target sentences (and the LLM decomposition's expected chunks, for
/// reference only) lifted from the walkthrough prompt validation battery
/// (test/walkthrough_prompt_validation.dart) so the chunker is exercised
/// against real target sentences from that corpus, not invented ones. The
/// chunker is a heuristic and is not expected to reproduce [expectedChunks]
/// exactly — see the "sanity" group below for what it IS expected to
/// guarantee (contiguity, exact reconstruction, chunk count in range).
class _Case {
  const _Case(this.language, this.targetSentence, this.expectedChunks);

  final Language language;
  final String targetSentence;
  final List<String> expectedChunks;
}

const _battery = [
  _Case(Language.spanish, 'Voy al banco el viernes.', ['Voy', 'al banco', 'el viernes']),
  _Case(Language.spanish, 'Quiero estudiar español este año.', ['Quiero', 'estudiar español', 'este año']),
  _Case(Language.spanish, 'Quiero solicitar ese trabajo.', ['Quiero', 'solicitar', 'ese trabajo']),
  _Case(Language.spanish, 'Quiero asistir a la clase mañana.', ['Quiero', 'asistir a la clase', 'mañana']),
  _Case(Language.spanish, 'Cociné pasta para la cena.', ['Cociné', 'pasta', 'para la cena']),
  _Case(Language.spanish, 'Mañana voy a visitar a mi abuela.', ['Mañana', 'voy a visitar', 'a mi abuela']),
  _Case(Language.spanish, 'El tren llega a las ocho.', ['El tren', 'llega', 'a las ocho']),
  _Case(Language.spanish, 'Compré tres manzanas en el mercado.', ['Compré', 'tres manzanas', 'en el mercado']),
  _Case(Language.spanish, 'Voy al gimnasio.', ['Voy', 'al gimnasio']),
  _Case(Language.portuguese, 'Vou ao banco na sexta.', ['Vou', 'ao banco', 'na sexta']),
  _Case(Language.portuguese, 'Quero estudar português este ano.', ['Quero', 'estudar português', 'este ano']),
  _Case(Language.portuguese, 'Vou cortar o cabelo amanhã.', ['Vou cortar', 'o cabelo', 'amanhã']),
  _Case(Language.portuguese, 'Quero verificar os dados amanhã.', ['Quero', 'verificar os dados', 'amanhã']),
  _Case(Language.portuguese, 'Cozinhei macarrão para o jantar.', ['Cozinhei', 'macarrão', 'para o jantar']),
  _Case(Language.portuguese, 'Amanhã vou visitar a minha avó.', ['Amanhã', 'vou visitar', 'a minha avó']),
  _Case(Language.portuguese, 'O trem chega às oito.', ['O trem', 'chega', 'às oito']),
  _Case(Language.portuguese, 'Comprei três maçãs no mercado.', ['Comprei', 'três maçãs', 'no mercado']),
  _Case(Language.portuguese, 'Vou ao mercado.', ['Vou', 'ao mercado']),
];

void main() {
  group('chunkSentence — sanity guarantees over the validation battery', () {
    for (final testCase in _battery) {
      test('"${testCase.targetSentence}" (${testCase.language.name})', () {
        final chunks = chunkSentence(testCase.targetSentence, testCase.language);

        expect(chunks, isNotEmpty);
        expect(chunks.length, lessThanOrEqualTo(5));

        // Concatenation reproduces the sentence (modulo trailing punctuation
        // and single-space joins) — guaranteed by construction, not just for
        // this battery.
        final reconstructed = chunks.join(' ');
        final normalizedTarget = testCase.targetSentence
            .trim()
            .replaceAll(RegExp(r'[.?!¡¿]+$'), '')
            .trim();
        expect(reconstructed, normalizedTarget);
      });
    }
  });

  group('chunkSentence — exact matches against the reference decomposition', () {
    // Cases where the closed function-word list happens to produce exactly
    // the same phrase boundaries the LLM chose — a nice signal the heuristic
    // is on the right track for the common "verb + [prep/article + noun]..."
    // shape, without claiming it matches every case (it doesn't group a verb
    // with its direct object or a demonstrative with its noun).
    const exactMatchSentences = {
      'Voy al banco el viernes.',
      'Voy al gimnasio.',
      'Vou ao banco na sexta.',
      'Vou ao mercado.',
    };

    for (final testCase in _battery.where(
      (c) => exactMatchSentences.contains(c.targetSentence),
    )) {
      test('"${testCase.targetSentence}"', () {
        expect(
          chunkSentence(testCase.targetSentence, testCase.language),
          testCase.expectedChunks,
        );
      });
    }
  });

  group('chunkSentence — edge cases', () {
    test('empty sentence returns no chunks', () {
      expect(chunkSentence('', Language.spanish), isEmpty);
    });

    test('a single word returns one chunk', () {
      expect(chunkSentence('Hola.', Language.spanish), ['Hola']);
    });

    test('a run of more than 5 content words merges down to 5 chunks', () {
      final chunks = chunkSentence(
        'Compré manzanas peras naranjas uvas fresas kiwis mangos.',
        Language.spanish,
      );
      expect(chunks.length, 5);
      expect(
        chunks.join(' '),
        'Compré manzanas peras naranjas uvas fresas kiwis mangos',
      );
    });

    test('a trailing bare preposition does not crash or get dropped', () {
      final chunks = chunkSentence('Fui a', Language.spanish);
      expect(chunks.join(' '), 'Fui a');
    });

    test('chained function words bind through to the noun', () {
      // "a la" chains: "a" (preposition) binds to "la" (article) binds to
      // "clase" (noun) -> a single three-word chunk.
      final chunks = chunkSentence('Quiero asistir a la clase.', Language.spanish);
      expect(chunks, contains('a la clase'));
    });
  });
}
