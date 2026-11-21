import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/shared/design/app_colors.dart';

void main() {
  test('the four categories of decision C3, Issues first', () {
    expect(ErrorCategory.values, [
      ErrorCategory.spelling,
      ErrorCategory.grammar,
      ErrorCategory.wordMeaning,
      ErrorCategory.naturalPhrasing,
    ]);
    expect(ErrorCategory.values.map((category) => category.label), [
      'Spelling',
      'Grammar',
      'Word meaning',
      'Natural phrasing',
    ]);
  });

  test('Word meaning has a colour of its own', () {
    expect(ErrorCategory.wordMeaning.color, AppColors.wordMeaning);
    final colours = ErrorCategory.values.map((c) => c.color).toSet();
    expect(colours, hasLength(4));
    expect(colours, isNot(contains(AppColors.success)));
  });

  test('maps legacy punctuation and preposition categories to grammar', () {
    expect(ErrorCategory.fromLabel('Punctuation'), ErrorCategory.grammar);
    expect(ErrorCategory.fromLabel('Preposition'), ErrorCategory.grammar);
  });

  test('parses the four category labels', () {
    expect(ErrorCategory.fromLabel('Grammar'), ErrorCategory.grammar);
    expect(ErrorCategory.fromLabel('Spelling'), ErrorCategory.spelling);
    expect(ErrorCategory.fromLabel('Word meaning'), ErrorCategory.wordMeaning);
    expect(
      ErrorCategory.fromLabel('Natural phrasing'),
      ErrorCategory.naturalPhrasing,
    );
  });

  test('renames the old labels kept on the phone', () {
    expect(ErrorCategory.fromLabel('Word Choice'), ErrorCategory.wordMeaning);
    expect(
      ErrorCategory.fromLabel('Natural Language'),
      ErrorCategory.naturalPhrasing,
    );
    expect(ErrorCategory.fromLabel('Other'), ErrorCategory.naturalPhrasing);
  });

  test('files unknown labels under Natural phrasing', () {
    expect(ErrorCategory.fromLabel('Style'), ErrorCategory.naturalPhrasing);
  });

  test('the older prompts are sent the old names', () {
    expect(ErrorCategory.spelling.legacyPromptLabel, 'Spelling');
    expect(ErrorCategory.grammar.legacyPromptLabel, 'Grammar');
    expect(ErrorCategory.wordMeaning.legacyPromptLabel, 'Word Choice');
    expect(
      ErrorCategory.naturalPhrasing.legacyPromptLabel,
      'Natural Language',
    );
  });

  test('isLegacyLabel spots only the old names', () {
    expect(ErrorCategory.isLegacyLabel('Word Choice'), isTrue);
    expect(ErrorCategory.isLegacyLabel('Natural Language'), isTrue);
    expect(ErrorCategory.isLegacyLabel('Other'), isTrue);
    expect(ErrorCategory.isLegacyLabel('Word meaning'), isFalse);
    expect(ErrorCategory.isLegacyLabel('Grammar'), isFalse);
  });

  test('strict API parser accepts new and old names, rejects others', () {
    expect(ErrorCategory.fromApiLabel('Grammar'), ErrorCategory.grammar);
    expect(
      ErrorCategory.fromApiLabel('Word meaning'),
      ErrorCategory.wordMeaning,
    );
    expect(
      ErrorCategory.fromApiLabel('Word Choice'),
      ErrorCategory.wordMeaning,
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
    expect(
      () => ErrorCategory.fromApiLabel('Preposition'),
      throwsFormatException,
    );
    expect(() => ErrorCategory.fromApiLabel('Style'), throwsFormatException);
  });
}
