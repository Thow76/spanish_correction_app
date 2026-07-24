import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';

void main() {
  test('parses structured saved explanation JSON', () {
    final correction = SavedCorrection.fromJson({
      'id': 'saved-1',
      'category': 'Natural Language',
      'short_explanation': 'This phrasing sounds unnatural.',
      'original_sentence': 'Hace calor de perros.',
      'corrected_phrase': 'mucho calor',
      'corrected_sentence': 'Hace mucho calor.',
      'prompt_phrase': 'It is very hot.',
      'saved_at': '2026-05-24T12:30:00.000',
      'explanation': {
        'why_its_wrong': 'The original expression is a literal calque.',
        'in_context': 'Ayer hacía mucho calor.',
        'alternatives': ['hacía mucho calor', 'hacía un calor sofocante'],
      },
    });

    expect(correction.category, ErrorCategory.naturalLanguage);
    expect(
      correction.explanation.whyItsWrong,
      'The original expression is a literal calque.',
    );
    expect(correction.explanation.inContext, 'Ayer hacía mucho calor.');
    expect(correction.explanation.alternatives, [
      'hacía mucho calor',
      'hacía un calor sofocante',
    ]);
    expect(correction.promptPhrase, 'It is very hot.');
    expect(correction.toJson()['prompt_phrase'], 'It is very hot.');
  });

  test('parses legacy long_explanation JSON', () {
    final correction = SavedCorrection.fromJson({
      'id': 'saved-legacy',
      'category': 'Preposition',
      'short_explanation': 'Use en with this location.',
      'original_sentence': 'Estoy a casa.',
      'corrected_phrase': 'en casa',
      'saved_at': '2026-05-24T12:30:00.000',
      'long_explanation': 'The old saved explanation is preserved.',
    });

    expect(correction.category, ErrorCategory.grammar);
    expect(
      correction.explanation.whyItsWrong,
      'The old saved explanation is preserved.',
    );
    expect(correction.explanation.inContext, isEmpty);
    expect(correction.explanation.alternatives, isEmpty);
    expect(correction.promptPhrase, isEmpty);
  });

  test(
    'round-trips promptHighlightStartIndex/EndIndex through fromJson/toJson '
    'when present',
    () {
      final correction = SavedCorrection.fromJson({
        'id': 'saved-1',
        'category': 'Grammar',
        'short_explanation': 'x',
        'original_sentence': 'Fui al mercado.',
        'corrected_phrase': 'Fui',
        'corrected_sentence': 'Fui al mercado.',
        'prompt_phrase': 'I went to the market.',
        'saved_at': '2026-05-24T12:30:00.000',
        'explanation': {
          'why_its_wrong': 'x',
          'in_context': 'x',
          'alternatives': [],
        },
        'prompt_highlight_start_index': 2,
        'prompt_highlight_end_index': 6,
      });

      expect(correction.promptHighlightStartIndex, 2);
      expect(correction.promptHighlightEndIndex, 6);
      expect(correction.toJson()['prompt_highlight_start_index'], 2);
      expect(correction.toJson()['prompt_highlight_end_index'], 6);
    },
  );

  test(
    'promptHighlightStartIndex/EndIndex default to null when absent, and '
    'toJson omits them entirely rather than writing null',
    () {
      final correction = SavedCorrection.fromJson({
        'id': 'saved-1',
        'category': 'Grammar',
        'short_explanation': 'x',
        'original_sentence': 'Fui al mercado.',
        'corrected_phrase': 'Fui',
        'corrected_sentence': 'Fui al mercado.',
        'prompt_phrase': 'I went to the market.',
        'saved_at': '2026-05-24T12:30:00.000',
        'explanation': {
          'why_its_wrong': 'x',
          'in_context': 'x',
          'alternatives': [],
        },
      });

      expect(correction.promptHighlightStartIndex, isNull);
      expect(correction.promptHighlightEndIndex, isNull);
      expect(
        correction.toJson().containsKey('prompt_highlight_start_index'),
        isFalse,
      );
      expect(
        correction.toJson().containsKey('prompt_highlight_end_index'),
        isFalse,
      );
    },
  );
}
