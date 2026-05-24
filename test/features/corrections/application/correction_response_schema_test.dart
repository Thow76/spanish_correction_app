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

    expect(
      required,
      containsAll(['start_index', 'end_index', 'original_phrase']),
    );
    expect(itemProperties, containsPair('start_index', isA<Map>()));
    expect(itemProperties, containsPair('end_index', isA<Map>()));
    expect(itemProperties, containsPair('original_phrase', isA<Map>()));
    expect(
      correctionResponseIndexingRules,
      contains(
        'For insertions, start_index and end_index are the same cursor position.',
      ),
    );
    expect(
      correctionResponseIndexingRules,
      contains(
        'original_phrase must equal the exact substring of the submitted text between start_index and end_index, character-for-character.',
      ),
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
