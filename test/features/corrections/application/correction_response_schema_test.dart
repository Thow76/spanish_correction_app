import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_response_schema.dart';

void main() {
  test('defines corrections as anchored ranges instead of echoed phrases', () {
    final properties =
        correctionResponseJsonSchema['properties'] as Map<String, Object?>;
    final corrections = properties['corrections'] as Map<String, Object?>;
    final item = corrections['items'] as Map<String, Object?>;
    final required = item['required'] as List<Object?>;
    final itemProperties = item['properties'] as Map<String, Object?>;

    expect(required, containsAll(['start_index', 'end_index']));
    expect(required, isNot(contains('original_phrase')));
    expect(itemProperties, containsPair('start_index', isA<Map>()));
    expect(itemProperties, containsPair('end_index', isA<Map>()));
    expect(itemProperties, isNot(contains('original_phrase')));
    expect(
      correctionResponseIndexingRules,
      contains('Correction items must not include an original_phrase field.'),
    );
  });

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
