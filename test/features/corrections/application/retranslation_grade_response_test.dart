import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service_exception.dart';
import 'package:spanish_correction_app/features/corrections/application/retranslation_grade_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

void main() {
  test('parses an is_related: true payload with corrections', () {
    final response = RetranslationGradeResponse.fromJson({
      'is_related': true,
      'corrected_text': 'Fui al mercado ayer.',
      'corrections': [
        {
          'start_index': 0,
          'original_phrase': 'voy',
          'corrected_phrase': 'fui',
          'category': 'Grammar',
          'short_explanation': 'Use the preterite for a completed past action.',
        },
      ],
    }, attempt: 'voy al mercado ayer.');

    expect(response.isRelated, isTrue);
    expect(response.correctedText, 'Fui al mercado ayer.');
    expect(response.corrections, hasLength(1));
    expect(response.corrections.single.originalPhrase, 'voy');
    expect(response.corrections.single.correctedPhrase, 'fui');
    expect(response.corrections.single.category, ErrorCategory.grammar);
    expect(
      response.corrections.single.shortExplanation,
      'Use the preterite for a completed past action.',
    );
  });

  test(
    'anchors a correction on start_index against attempt, not corrected_text',
    () {
      const attempt = 'Voy a el mercado ayer.';
      final response = RetranslationGradeResponse.fromJson({
        'is_related': true,
        'corrected_text': 'Fui al mercado ayer.',
        'corrections': [
          {
            'start_index': 4,
            'original_phrase': 'a el',
            'corrected_phrase': 'al',
            'category': 'Grammar',
            'short_explanation': 'Spanish contracts "a" + "el" into "al".',
          },
        ],
      }, attempt: attempt);

      final correction = response.corrections.single;
      expect(correction.startIndex, 4);
      expect(correction.endIndex, 8);
      expect(attempt.substring(4, 8), 'a el');
    },
  );

  test(
    'falls back to null indexes when start_index does not match attempt at that position',
    () {
      final response = RetranslationGradeResponse.fromJson({
        'is_related': true,
        'corrected_text': 'Fui al mercado ayer.',
        'corrections': [
          {
            // Wrong index: "voy" is not at position 3 in "Voy a el mercado".
            'start_index': 3,
            'original_phrase': 'voy',
            'corrected_phrase': 'fui',
            'category': 'Grammar',
            'short_explanation': 'x',
          },
        ],
      }, attempt: 'Voy a el mercado.');

      // No case-sensitive exact match at any position ("voy" lowercase vs
      // "Voy" capitalised) — falls back to null rather than guessing.
      final correction = response.corrections.single;
      expect(correction.startIndex, isNull);
      expect(correction.endIndex, isNull);
    },
  );

  test('parses an is_related: false payload with no corrections', () {
    final response = RetranslationGradeResponse.fromJson({
      'is_related': false,
      'corrected_text': 'Tomé el autobús a casa.',
      'corrections': <Object?>[],
    }, attempt: 'Tomo el autobus a casa.');

    expect(response.isRelated, isFalse);
    expect(response.correctedText, 'Tomé el autobús a casa.');
    expect(response.corrections, isEmpty);
  });

  test('throws when is_related is missing', () {
    expect(
      () => RetranslationGradeResponse.fromJson({
        'corrected_text': 'x',
        'corrections': <Object?>[],
      }, attempt: 'x'),
      throwsA(
        isA<CorrectionServiceException>().having(
          (exception) => exception.reason,
          'reason',
          CorrectionFailureReason.invalidResponse,
        ),
      ),
    );
  });

  test('throws when is_related is null', () {
    expect(
      () => RetranslationGradeResponse.fromJson({
        'is_related': null,
        'corrected_text': 'x',
        'corrections': <Object?>[],
      }, attempt: 'x'),
      throwsA(isA<CorrectionServiceException>()),
    );
  });

  test('throws when is_related is not a boolean', () {
    expect(
      () => RetranslationGradeResponse.fromJson({
        'is_related': 'true',
        'corrected_text': 'x',
        'corrections': <Object?>[],
      }, attempt: 'x'),
      throwsA(isA<CorrectionServiceException>()),
    );
  });
}
