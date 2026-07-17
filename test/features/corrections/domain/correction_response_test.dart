import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

void main() {
  test('strict parsing accepts the five supported API categories', () {
    final response = CorrectionResponse.fromJson({
      'original_text': 'Ayer yo fue al mercado.',
      'corrected_text': 'Ayer fui al mercado.',
      'corrections': [
        {
          'original_phrase': 'fue',
          'corrected_phrase': 'fui',
          'category': 'Grammar',
          'short_explanation': 'Use fui with yo in the preterite.',
        },
        {
          'original_phrase': 'calor de perros',
          'corrected_phrase': 'mucho calor',
          'category': 'Natural Language',
          'short_explanation': 'That expression sounds unnatural.',
        },
        {
          'original_phrase': 'haver',
          'corrected_phrase': 'haber',
          'category': 'Spelling',
          'short_explanation': 'Haber is spelled with b.',
        },
        {
          'original_phrase': 'realizar una pregunta',
          'corrected_phrase': 'hacer una pregunta',
          'category': 'Word Choice',
          'short_explanation': 'Hacer is the natural verb here.',
        },
        {
          'original_phrase': '???',
          'corrected_phrase': '...',
          'category': 'Other',
          'short_explanation': 'This is an edge case.',
        },
      ],
    }, allowLegacyCategories: false);

    expect(response.corrections.map((correction) => correction.category), [
      ErrorCategory.grammar,
      ErrorCategory.naturalLanguage,
      ErrorCategory.spelling,
      ErrorCategory.wordChoice,
      ErrorCategory.other,
    ]);
  });

  test('strict parsing rejects legacy Gemini categories', () {
    expect(
      () => CorrectionResponse.fromJson({
        'original_text': 'Estoy a casa.',
        'corrected_text': 'Estoy en casa.',
        'corrections': [
          {
            'original_phrase': 'a',
            'corrected_phrase': 'en',
            'category': 'Preposition',
            'short_explanation': 'Use en with location.',
          },
        ],
      }, allowLegacyCategories: false),
      throwsFormatException,
    );
  });

  test('default parsing remains backward compatible for stored data', () {
    final response = CorrectionResponse.fromJson({
      'original_text': 'Estoy a casa.',
      'corrected_text': 'Estoy en casa.',
      'corrections': [
        {
          'original_phrase': 'a',
          'corrected_phrase': 'en',
          'category': 'Preposition',
          'short_explanation': 'Use en with location.',
        },
      ],
    });

    expect(response.corrections.single.category, ErrorCategory.grammar);
  });

  test('anchored parsing derives original phrases from submitted text', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'C mo est s? Qu tal?',
        // The model's own corrected_text fixes both sentences, but only the
        // first is itemised in corrections — corrected_text is now built
        // solely from itemised corrections, so the second sentence stays
        // unfixed. This is deliberate: the model's freeform corrected_text is
        // no longer trusted as a source of un-itemised fixes.
        'corrected_text': '¿Cómo estás? ¿Qué tal?',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 11,
            'original_phrase': 'Cómo estás?',
            'corrected_phrase': '¿Cómo estás?',
            'category': 'Grammar',
            'short_explanation': 'Spanish questions need an opening mark.',
          },
        ],
      },
      submittedText: 'Cómo estás? Qué tal?',
      allowLegacyCategories: false,
    );

    expect(response.originalText, 'Cómo estás? Qué tal?');
    expect(response.correctedText, '¿Cómo estás? Qué tal?');
    expect(response.corrections.single.originalPhrase, 'Cómo estás?');
    expect(response.corrections.single.startIndex, 0);
    expect(response.corrections.single.endIndex, 11);
  });

  test(
    'anchored parsing derives endIndex from start_index + phrase length '
    'when end_index is absent from the model JSON',
    () {
      // end_index is no longer part of the schema the model is sent — this
      // confirms anchoring still works correctly using only start_index.
      final response = CorrectionResponse.fromAnchoredJson(
        {
          'original_text': 'Cómo estás? Qué tal?',
          'corrected_text': '¿Cómo estás? Qué tal?',
          'corrections': [
            {
              'start_index': 0,
              'original_phrase': 'Cómo estás?',
              'corrected_phrase': '¿Cómo estás?',
              'category': 'Grammar',
              'short_explanation': 'Spanish questions need an opening mark.',
            },
          ],
        },
        submittedText: 'Cómo estás? Qué tal?',
        allowLegacyCategories: false,
      );

      expect(response.corrections.single.originalPhrase, 'Cómo estás?');
      expect(response.corrections.single.startIndex, 0);
      expect(response.corrections.single.endIndex, 11);
    },
  );

  test(
    'anchored parsing ignores a stray end_index value in the model JSON, '
    'since it is no longer read',
    () {
      // Even if a client/model sent a wrong or stale end_index, it must have
      // zero effect: endIndex is always derived from start_index + phrase
      // length, never from the model's end_index value.
      final response = CorrectionResponse.fromAnchoredJson(
        {
          'original_text': 'Cómo estás? Qué tal?',
          'corrected_text': '¿Cómo estás? Qué tal?',
          'corrections': [
            {
              'start_index': 0,
              'end_index': 999,
              'original_phrase': 'Cómo estás?',
              'corrected_phrase': '¿Cómo estás?',
              'category': 'Grammar',
              'short_explanation': 'Spanish questions need an opening mark.',
            },
          ],
        },
        submittedText: 'Cómo estás? Qué tal?',
        allowLegacyCategories: false,
      );

      expect(response.corrections.single.originalPhrase, 'Cómo estás?');
      expect(response.corrections.single.startIndex, 0);
      expect(response.corrections.single.endIndex, 11);
    },
  );

  test('anchored parsing reconstructs corrected text from anchored edits', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'Como estas? Que tal?',
        'corrected_text': 'This model value should not be trusted.',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 11,
            'original_phrase': 'Como estas?',
            'corrected_phrase': '¿Cómo estás?',
            'category': 'Grammar',
            'short_explanation': 'Spanish questions need an opening mark.',
          },
          {
            'start_index': 12,
            'end_index': 20,
            'original_phrase': 'Que tal?',
            'corrected_phrase': '¿Qué tal?',
            'category': 'Grammar',
            'short_explanation': 'Spanish questions need an opening mark.',
          },
        ],
      },
      submittedText: 'Como estas? Que tal?',
      allowLegacyCategories: false,
    );

    expect(response.correctedText, '¿Cómo estás? ¿Qué tal?');
  });

  test('anchored parsing supports zero-length insertion ranges', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'Cómo estás? Qué tal?',
        'corrected_text': 'This model value should not be trusted.',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 0,
            'original_phrase': '',
            'corrected_phrase': '¿',
            'category': 'Grammar',
            'short_explanation': 'Spanish questions need an opening mark.',
          },
          {
            'start_index': 12,
            'end_index': 12,
            'original_phrase': '',
            'corrected_phrase': '¿',
            'category': 'Grammar',
            'short_explanation': 'Spanish questions need an opening mark.',
          },
        ],
      },
      submittedText: 'Cómo estás? Qué tal?',
      allowLegacyCategories: false,
    );

    expect(response.correctedText, '¿Cómo estás? ¿Qué tal?');
    expect(response.corrections.first.originalPhrase, isEmpty);
    expect(response.corrections.first.startIndex, 0);
    expect(response.corrections.first.endIndex, 0);
  });

  test(
    'anchored parsing reconstructs literally from itemised insertions, '
    'even when the model corrected_text disagrees',
    () {
      // corrected_text is no longer a trusted fallback: the model's own
      // corrected_text here is the coherent, intended fix ("bienvenido" ->
      // "bienvenidos"), but it is not itemised as a correction, so it is
      // ignored. Only the two itemised (if odd) insertions are applied.
      final response = CorrectionResponse.fromAnchoredJson(
        {
          'original_text':
              'Hola a todos y bienvenido a Escocia, un gran país con una cultura muy profunda y famosa por todo el mundo.',
          'corrected_text':
              'Hola a todos y bienvenidos a Escocia, un gran país con una cultura muy profunda y famosa por todo el mundo.',
          'corrections': [
            {
              'start_index': 0,
              'end_index': 0,
              'original_phrase': '',
              'corrected_phrase': 'i',
              'category': 'Spelling',
              'short_explanation': 'Itemised insertion at the start.',
            },
            {
              'start_index': 81,
              'end_index': 81,
              'original_phrase': '',
              'corrected_phrase': '!',
              'category': 'Grammar',
              'short_explanation': 'Itemised insertion mid-sentence.',
            },
          ],
        },
        submittedText:
            'Hola a todos y bienvenido a Escocia, un gran país con una cultura muy profunda y famosa por todo el mundo.',
        allowLegacyCategories: false,
      );

      expect(
        response.correctedText,
        'iHola a todos y bienvenido a Escocia, un gran país con una cultura muy profunda y !famosa por todo el mundo.',
      );
    },
  );

  test('anchored parsing rejects unrelated model corrected text', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'Como estas? Que tal?',
        'corrected_text': 'This model value should not be trusted.',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 11,
            'original_phrase': 'Como estas?',
            'corrected_phrase': '¿Cómo estás?',
            'category': 'Grammar',
            'short_explanation': 'Spanish questions need an opening mark.',
          },
        ],
      },
      submittedText: 'Como estas? Que tal?',
      allowLegacyCategories: false,
    );

    expect(response.correctedText, '¿Cómo estás? Que tal?');
  });

  test('anchored parsing slices user-perceived characters', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'Café bien',
        'corrected_text': 'Café bueno',
        'corrections': [
          {
            'start_index': 5,
            'end_index': 9,
            'original_phrase': 'bien',
            'corrected_phrase': 'bueno',
            'category': 'Word Choice',
            'short_explanation': 'Bueno fits the noun being described.',
          },
        ],
      },
      submittedText: 'Café bien',
      allowLegacyCategories: false,
    );

    expect(response.corrections.single.originalPhrase, 'bien');
  });

  test('anchored parsing drops invalid ranges', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'Hola',
        'corrected_text': 'Hola',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 8,
            'corrected_phrase': 'Hola',
            'category': 'Other',
            'short_explanation': 'Invalid range.',
          },
        ],
      },
      submittedText: 'Hola',
      allowLegacyCategories: false,
    );

    expect(response.corrections, isEmpty);
    expect(response.correctedText, 'Hola');
  });

  test('anchored parsing drops unchanged corrections', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': '¿Cómo estás?',
        'corrected_text': '¿Cómo estás?',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 12,
            'corrected_phrase': '¿Cómo estás?',
            'category': 'Spelling',
            'short_explanation': 'No correction is needed.',
          },
        ],
      },
      submittedText: '¿Cómo estás?',
      allowLegacyCategories: false,
    );

    expect(response.corrections, isEmpty);
    expect(response.correctedText, '¿Cómo estás?');
  });

  test(
    'anchored parsing keeps fully correct Spanish question text unchanged',
    () {
      final response = CorrectionResponse.fromAnchoredJson(
        {
          'original_text': '¿Cómo estás? ¿Qué tal?',
          'corrected_text': 'C mo est s? Qu tal?',
          'corrections': [
            {
              'start_index': 0,
              'end_index': 22,
              'corrected_phrase': '¿Cómo estás? ¿Qué tal?',
              'category': 'Spelling',
              'short_explanation': 'No correction is actually needed.',
            },
          ],
        },
        submittedText: '¿Cómo estás? ¿Qué tal?',
        allowLegacyCategories: false,
      );

      expect(response.originalText, '¿Cómo estás? ¿Qué tal?');
      expect(response.correctedText, '¿Cómo estás? ¿Qué tal?');
      expect(response.corrections, isEmpty);
    },
  );

  test('anchored parsing keeps accented medical sentence unchanged', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'Ma ana ir al m dico.',
        'corrected_text': 'Mañana iré al médico.',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 21,
            'corrected_phrase': 'Mañana iré al médico.',
            'category': 'Spelling',
            'short_explanation': 'The accents are already present.',
          },
        ],
      },
      submittedText: 'Mañana iré al médico.',
      allowLegacyCategories: false,
    );

    expect(response.correctedText, 'Mañana iré al médico.');
    expect(response.corrections, isEmpty);
  });

  test('anchored parsing drops garbled correction text for accented input', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'C mo est s?',
        'corrected_text': 'C mo est s?',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 11,
            'corrected_phrase': 'C mo est s?',
            'category': 'Spelling',
            'short_explanation': 'The response lost Spanish characters.',
          },
        ],
      },
      submittedText: 'Cómo estás?',
      allowLegacyCategories: false,
    );

    expect(response.correctedText, 'Cómo estás?');
    expect(response.corrections, isEmpty);
  });

  test('anchored parsing re-anchors when the model indexes drift off the echoed phrase', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text':
            'Hola, me llamo Andrew y soy de Escocia. Estoy 50 años.',
        'corrected_text':
            'Hola, me llamo Andrew y soy de Escocia. Tengo 50 años.',
        'corrections': [
          {
            'start_index': 5,
            'end_index': 10,
            'original_phrase': 'Estoy',
            'corrected_phrase': 'Tengo',
            'category': 'Word Choice',
            'short_explanation': 'Use tener to express age in Spanish.',
          },
        ],
      },
      submittedText:
          'Hola, me llamo Andrew y soy de Escocia. Estoy 50 años.',
      allowLegacyCategories: false,
    );

    final correction = response.corrections.single;
    expect(correction.originalPhrase, 'Estoy');
    expect(correction.correctedPhrase, 'Tengo');
    expect(correction.startIndex, 40);
    expect(correction.endIndex, 45);
  });

  test('anchored parsing drops corrections without an echoed original_phrase', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'Cómo estás?',
        'corrected_text': '¿Cómo estás?',
        'corrections': [
          {
            'start_index': 0,
            'end_index': 11,
            'corrected_phrase': '¿Cómo estás?',
            'category': 'Grammar',
            'short_explanation': 'Missing opening question mark.',
          },
        ],
      },
      submittedText: 'Cómo estás?',
      allowLegacyCategories: false,
    );

    expect(response.corrections, isEmpty);
  });

  test('anchored parsing drops stale echoed original phrases', () {
    final response = CorrectionResponse.fromAnchoredJson(
      {
        'original_text': 'C mo est s?',
        'corrected_text': '¿Cómo estás?',
        'corrections': [
          {
            'original_phrase': 'C mo est s?',
            'start_index': 0,
            'end_index': 11,
            'corrected_phrase': '¿Cómo estás?',
            'category': 'Spelling',
            'short_explanation': 'Accents are missing.',
          },
        ],
      },
      submittedText: 'Cómo estás?',
      allowLegacyCategories: false,
    );

    expect(response.corrections, isEmpty);
  });

  test(
    'anchored parsing does not crash on a response shaped like the reduced '
    'schema — no corrected_text, corrected_start_index, or '
    'corrected_end_index anywhere in the JSON',
    () {
      // Shaped exactly like what correctionResponseJsonSchema now produces:
      // no top-level corrected_text, and no per-item corrected_start_index/
      // corrected_end_index. fromAnchoredJson must not throw, must still
      // build a correct, code-reconstructed correctedText, and must compute
      // (not read from JSON) the corrected-side range via
      // computeCorrectedRanges.
      final response = CorrectionResponse.fromAnchoredJson(
        {
          'original_text': 'Como estas? Que tal?',
          'corrections': [
            {
              'start_index': 0,
              'original_phrase': 'Como estas?',
              'corrected_phrase': '¿Cómo estás?',
              'category': 'Grammar',
              'short_explanation': 'Spanish questions need an opening mark.',
            },
          ],
        },
        submittedText: 'Como estas? Que tal?',
        allowLegacyCategories: false,
      );

      expect(response.originalText, 'Como estas? Que tal?');
      expect(response.correctedText, '¿Cómo estás? Que tal?');
      expect(response.corrections.single.originalPhrase, 'Como estas?');
      expect(response.corrections.single.correctedPhrase, '¿Cómo estás?');
      // Computed by computeCorrectedRanges: nothing to its left, so
      // correctedStartIndex == its own startIndex (0), and correctedEndIndex
      // is 0 + "¿Cómo estás?".length (12 graphemes).
      expect(response.corrections.single.correctedStartIndex, 0);
      expect(response.corrections.single.correctedEndIndex, 12);
    },
  );

  test(
    'anchored parsing does not crash on a completely empty JSON object '
    '(no keys at all)',
    () {
      expect(
        () => CorrectionResponse.fromAnchoredJson(
          const {},
          submittedText: 'Cómo estás?',
          allowLegacyCategories: false,
        ),
        returnsNormally,
      );

      final response = CorrectionResponse.fromAnchoredJson(
        const {},
        submittedText: 'Cómo estás?',
        allowLegacyCategories: false,
      );

      expect(response.originalText, 'Cómo estás?');
      expect(response.correctedText, 'Cómo estás?');
      expect(response.corrections, isEmpty);
    },
  );
}
