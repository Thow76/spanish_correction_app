import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

void main() {
  test('maps legacy punctuation and preposition categories to grammar', () {
    expect(ErrorCategory.fromLabel('Punctuation'), ErrorCategory.grammar);
    expect(ErrorCategory.fromLabel('Preposition'), ErrorCategory.grammar);
  });

  test('parses supported category labels', () {
    expect(ErrorCategory.fromLabel('Grammar'), ErrorCategory.grammar);
    expect(
      ErrorCategory.fromLabel('Natural Language'),
      ErrorCategory.naturalLanguage,
    );
    expect(ErrorCategory.fromLabel('Spelling'), ErrorCategory.spelling);
    expect(ErrorCategory.fromLabel('Word Choice'), ErrorCategory.wordChoice);
    expect(ErrorCategory.fromLabel('Other'), ErrorCategory.other);
  });

  test('falls back to other for unknown labels', () {
    expect(ErrorCategory.fromLabel('Style'), ErrorCategory.other);
  });
}
