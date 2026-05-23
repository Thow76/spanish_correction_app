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
  });
}
