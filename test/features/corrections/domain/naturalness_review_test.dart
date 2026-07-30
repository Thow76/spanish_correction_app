import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

void main() {
  test('parses a valid no-issue response', () {
    final review = NaturalnessReview.fromJson({
      'has_naturalness_issue': false,
      'issues': [],
    });

    expect(review.hasNaturalnessIssue, isFalse);
    expect(review.issues, isEmpty);
  });

  test('parses a valid response with issues', () {
    final review = NaturalnessReview.fromJson({
      'has_naturalness_issue': true,
      'issues': [
        {
          'span': 'llamo para atrás',
          'natural_replacement': 'te devuelvo la llamada',
          'explanation': 'Calque of "call back".',
        },
        {
          'span': 'hacer una decisión',
          'natural_replacement': 'tomar una decisión',
          'explanation': 'Wrong collocation for "decisión".',
        },
      ],
    });

    expect(review.hasNaturalnessIssue, isTrue);
    expect(review.issues, hasLength(2));
    expect(review.issues.first.span, 'llamo para atrás');
    expect(review.issues.last.naturalReplacement, 'tomar una decisión');
  });

  test('throws when has_naturalness_issue is missing', () {
    expect(
      () => NaturalnessReview.fromJson({'issues': []}),
      throwsFormatException,
    );
  });

  test('throws when has_naturalness_issue is not a bool', () {
    expect(
      () => NaturalnessReview.fromJson({
        'has_naturalness_issue': 'false',
        'issues': [],
      }),
      throwsFormatException,
    );
  });

  test('throws when issues is missing', () {
    expect(
      () => NaturalnessReview.fromJson({'has_naturalness_issue': false}),
      throwsFormatException,
    );
  });

  test('throws when issues is not a list', () {
    expect(
      () => NaturalnessReview.fromJson({
        'has_naturalness_issue': false,
        'issues': 'none',
      }),
      throwsFormatException,
    );
  });

  test('throws when an issues entry is not an object', () {
    expect(
      () => NaturalnessReview.fromJson({
        'has_naturalness_issue': true,
        'issues': ['not an object'],
      }),
      throwsFormatException,
    );
  });

  test('throws when an issues entry is malformed', () {
    expect(
      () => NaturalnessReview.fromJson({
        'has_naturalness_issue': true,
        'issues': [
          {'span': 'x'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('throws when has_naturalness_issue is false but issues is non-empty', () {
    expect(
      () => NaturalnessReview.fromJson({
        'has_naturalness_issue': false,
        'issues': [
          {
            'span': 'x',
            'natural_replacement': 'y',
            'explanation': 'z',
          },
        ],
      }),
      throwsFormatException,
    );
  });

  test('throws when has_naturalness_issue is true but issues is empty', () {
    expect(
      () => NaturalnessReview.fromJson({
        'has_naturalness_issue': true,
        'issues': [],
      }),
      throwsFormatException,
    );
  });
}
