import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_issue.dart';

void main() {
  test('parses a valid issue', () {
    final issue = NaturalnessIssue.fromJson({
      'span': 'llamo para atrás',
      'natural_replacement': 'te devuelvo la llamada',
      'explanation': '"Llamar para atrás" is a calque of "call back".',
    });

    expect(issue.span, 'llamo para atrás');
    expect(issue.naturalReplacement, 'te devuelvo la llamada');
    expect(
      issue.explanation,
      '"Llamar para atrás" is a calque of "call back".',
    );
  });

  test('throws when span is missing', () {
    expect(
      () => NaturalnessIssue.fromJson({
        'natural_replacement': 'x',
        'explanation': 'y',
      }),
      throwsFormatException,
    );
  });

  test('throws when natural_replacement is missing', () {
    expect(
      () => NaturalnessIssue.fromJson({'span': 'x', 'explanation': 'y'}),
      throwsFormatException,
    );
  });

  test('throws when explanation is missing', () {
    expect(
      () => NaturalnessIssue.fromJson({
        'span': 'x',
        'natural_replacement': 'y',
      }),
      throwsFormatException,
    );
  });

  test('throws when a required field is not a string', () {
    expect(
      () => NaturalnessIssue.fromJson({
        'span': 5,
        'natural_replacement': 'y',
        'explanation': 'z',
      }),
      throwsFormatException,
    );
  });
}
