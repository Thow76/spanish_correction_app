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
}
