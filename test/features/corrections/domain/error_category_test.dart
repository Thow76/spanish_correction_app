import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/shared/design/app_colors.dart';

void main() {
  test('the four categories of decision C3 as revised, Issues first', () {
    expect(ErrorCategory.values, [
      ErrorCategory.spelling,
      ErrorCategory.grammar,
      ErrorCategory.wordChoice,
      ErrorCategory.naturalPhrasing,
    ]);
    expect(ErrorCategory.values.map((category) => category.label), [
      'Spelling',
      'Grammar',
      'Word Choice',
      'Natural phrasing',
    ]);
  });

  test('Word Choice keeps its green', () {
    expect(ErrorCategory.wordChoice.color, AppColors.wordChoice);
    expect(ErrorCategory.values.map((c) => c.color).toSet(), hasLength(4));
  });

  test('maps legacy punctuation and preposition categories to grammar', () {
    expect(ErrorCategory.fromLabel('Punctuation'), ErrorCategory.grammar);
    expect(ErrorCategory.fromLabel('Preposition'), ErrorCategory.grammar);
  });

  test('parses the four category labels', () {
    expect(ErrorCategory.fromLabel('Grammar'), ErrorCategory.grammar);
    expect(ErrorCategory.fromLabel('Spelling'), ErrorCategory.spelling);
    expect(ErrorCategory.fromLabel('Word Choice'), ErrorCategory.wordChoice);
    expect(
      ErrorCategory.fromLabel('Natural phrasing'),
      ErrorCategory.naturalPhrasing,
    );
  });

  test('renames the old labels kept on the phone', () {
    expect(
      ErrorCategory.fromLabel('Natural Language'),
      ErrorCategory.naturalPhrasing,
    );
    expect(ErrorCategory.fromLabel('Other'), ErrorCategory.naturalPhrasing);
    expect(ErrorCategory.fromLabel('Word meaning'), ErrorCategory.wordChoice);
  });

  test('files unknown labels under Natural phrasing', () {
    expect(ErrorCategory.fromLabel('Style'), ErrorCategory.naturalPhrasing);
  });

  test('the older prompts are sent the old names', () {
    expect(ErrorCategory.spelling.legacyPromptLabel, 'Spelling');
    expect(ErrorCategory.grammar.legacyPromptLabel, 'Grammar');
    expect(ErrorCategory.wordChoice.legacyPromptLabel, 'Word Choice');
    expect(ErrorCategory.naturalPhrasing.legacyPromptLabel, 'Natural Language');
  });

  test('isLegacyLabel spots only the names the one-time rename replaces', () {
    expect(ErrorCategory.isLegacyLabel('Natural Language'), isTrue);
    expect(ErrorCategory.isLegacyLabel('Other'), isTrue);
    expect(ErrorCategory.isLegacyLabel('Word Choice'), isFalse);
    expect(ErrorCategory.isLegacyLabel('Grammar'), isFalse);
  });

  test('strict API parser accepts new and old names, rejects others', () {
    expect(ErrorCategory.fromApiLabel('Grammar'), ErrorCategory.grammar);
    expect(ErrorCategory.fromApiLabel('Word Choice'), ErrorCategory.wordChoice);
    expect(
      ErrorCategory.fromApiLabel('Word meaning'),
      ErrorCategory.wordChoice,
    );
    expect(
      ErrorCategory.fromApiLabel('Natural Language'),
      ErrorCategory.naturalPhrasing,
    );
    expect(ErrorCategory.fromApiLabel('Other'), ErrorCategory.naturalPhrasing);
    expect(
      () => ErrorCategory.fromApiLabel('Punctuation'),
      throwsFormatException,
    );
    expect(() => ErrorCategory.fromApiLabel('Style'), throwsFormatException);
  });
}
