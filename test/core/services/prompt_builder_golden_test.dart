import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/prompt_builder.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_response_schema.dart';

// Golden fixture captured from the correction-path outputs before the
// grading-prompt feature was added. The grading feature must not alter any
// of these values — see boundary A of the retranslation-grading rollout.
void main() {
  test(
    'correction-path outputs remain byte-for-byte unchanged by the grading feature',
    () {
      final fixtureFile = File(
        'test/core/services/golden_correction_prompts.json',
      );
      final golden =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, Object?>;

      expect(
        PromptBuilder.correctionSystemPrompt(Language.portuguese),
        golden['correctionSystemPromptPortuguese'],
      );
      expect(
        PromptBuilder.correctionUserContent(Language.spanish, 'SAMPLE_TEXT'),
        golden['correctionUserContentSpanish'],
      );
      expect(
        PromptBuilder.correctionUserContent(
          Language.portuguese,
          'SAMPLE_TEXT',
        ),
        golden['correctionUserContentPortuguese'],
      );
      expect(
        correctionResponseJsonShape,
        golden['correctionResponseJsonShape'],
      );
    },
  );
}
