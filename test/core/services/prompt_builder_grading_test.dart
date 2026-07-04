import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/prompt_builder.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

void main() {
  test('grading prompts differ between Spanish and Portuguese', () {
    expect(
      PromptBuilder.gradingSystemPrompt(Language.spanish),
      isNot(equals(PromptBuilder.gradingSystemPrompt(Language.portuguese))),
    );
  });

  test('gradingSystemPrompt dispatches on language', () {
    final spanish = PromptBuilder.gradingSystemPrompt(Language.spanish);
    final portuguese = PromptBuilder.gradingSystemPrompt(Language.portuguese);

    expect(spanish, contains('Spanish-language student'));
    expect(portuguese, contains('Brazilian Portuguese student'));
  });

  test('gradingSystemPrompt is stable across repeated calls', () {
    expect(
      PromptBuilder.gradingSystemPrompt(Language.spanish),
      PromptBuilder.gradingSystemPrompt(Language.spanish),
    );
    expect(
      PromptBuilder.gradingSystemPrompt(Language.portuguese),
      PromptBuilder.gradingSystemPrompt(Language.portuguese),
    );
  });

  test('gradingUserContent interpolates attempt, expectedAnswer, and category', () {
    final content = PromptBuilder.gradingUserContent(
      attempt: 'Fui al mercado ayer',
      expectedAnswer: 'Fui al mercado la semana pasada',
      targetCategory: ErrorCategory.grammar,
    );

    expect(content, contains('expectedAnswer: "Fui al mercado la semana pasada"'));
    expect(content, contains('targetCategory: Grammar'));
    expect(content, contains('attempt: "Fui al mercado ayer"'));
  });
}
