import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_response_schema.dart';

void main() {
  test('requires anchored ranges and an echoed original_phrase', () {
    final properties =
        correctionResponseJsonSchema['properties'] as Map<String, Object?>;
    final corrections = properties['corrections'] as Map<String, Object?>;
    final item = corrections['items'] as Map<String, Object?>;
    final required = item['required'] as List<Object?>;
    final itemProperties = item['properties'] as Map<String, Object?>;

    expect(required, containsAll(['start_index', 'original_phrase']));
    expect(required, isNot(contains('end_index')));
    expect(itemProperties, containsPair('start_index', isA<Map>()));
    expect(itemProperties, isNot(containsPair('end_index', anything)));
    expect(itemProperties, containsPair('original_phrase', isA<Map>()));
    expect(
      correctionResponseIndexingRules,
      contains(
        'For an inserted phrase, start_index is the insertion point and original_phrase is empty.',
      ),
    );
    expect(
      correctionResponseIndexingRules,
      contains(
        'original_phrase must equal the exact substring of the submitted text starting at start_index, character-for-character.',
      ),
    );
    expect(
      correctionResponseIndexingRules.any(
        (rule) => rule.contains('end_index'),
      ),
      isFalse,
    );
  });

  test(
    'does not ask the model for corrected_text, corrected_start_index, or '
    'corrected_end_index — those are computed in code, never model-provided',
    () {
      final required = correctionResponseJsonSchema['required'] as List<Object?>;
      final properties =
          correctionResponseJsonSchema['properties'] as Map<String, Object?>;
      final corrections = properties['corrections'] as Map<String, Object?>;
      final item = corrections['items'] as Map<String, Object?>;
      final itemRequired = item['required'] as List<Object?>;
      final itemProperties = item['properties'] as Map<String, Object?>;

      expect(required, isNot(contains('corrected_text')));
      expect(properties, isNot(containsPair('corrected_text', anything)));
      expect(itemRequired, isNot(contains('corrected_start_index')));
      expect(itemRequired, isNot(contains('corrected_end_index')));
      expect(
        itemProperties,
        isNot(containsPair('corrected_start_index', anything)),
      );
      expect(
        itemProperties,
        isNot(containsPair('corrected_end_index', anything)),
      );
      expect(correctionResponseJsonShape, isNot(contains('corrected_text')));
      expect(
        correctionResponseJsonShape,
        isNot(contains('corrected_start_index')),
      );
      expect(
        correctionResponseJsonShape,
        isNot(contains('corrected_end_index')),
      );
    },
  );

  test('keeps the supported correction categories in the schema', () {
    final properties =
        correctionResponseJsonSchema['properties'] as Map<String, Object?>;
    final corrections = properties['corrections'] as Map<String, Object?>;
    final item = corrections['items'] as Map<String, Object?>;
    final itemProperties = item['properties'] as Map<String, Object?>;
    final category = itemProperties['category'] as Map<String, Object?>;

    expect(category['enum'], [
      'Grammar',
      'Natural Language',
      'Spelling',
      'Word Choice',
      'Other',
    ]);
  });
}
