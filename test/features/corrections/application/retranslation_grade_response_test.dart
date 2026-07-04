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
          'original_phrase': 'voy',
          'corrected_phrase': 'fui',
          'category': 'Grammar',
          'short_explanation': 'Use the preterite for a completed past action.',
        },
      ],
    });

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

  test('parses an is_related: false payload with no corrections', () {
    final response = RetranslationGradeResponse.fromJson({
      'is_related': false,
      'corrected_text': 'Tomé el autobús a casa.',
      'corrections': <Object?>[],
    });

    expect(response.isRelated, isFalse);
    expect(response.correctedText, 'Tomé el autobús a casa.');
    expect(response.corrections, isEmpty);
  });

  test('throws when is_related is missing', () {
    expect(
      () => RetranslationGradeResponse.fromJson({
        'corrected_text': 'x',
        'corrections': <Object?>[],
      }),
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
      }),
      throwsA(isA<CorrectionServiceException>()),
    );
  });

  test('throws when is_related is not a boolean', () {
    expect(
      () => RetranslationGradeResponse.fromJson({
        'is_related': 'true',
        'corrected_text': 'x',
        'corrections': <Object?>[],
      }),
      throwsA(isA<CorrectionServiceException>()),
    );
  });
}
