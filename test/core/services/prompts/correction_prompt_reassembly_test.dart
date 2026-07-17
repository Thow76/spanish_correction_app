import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

// Proves the section-constant decomposition in correction_prompt.dart
// reassembles to exactly the pre-refactor prompt text. Reuses the existing
// golden fixture (captured from the code before this decomposition) rather
// than pasting a second copy of the same giant string.
void main() {
  test(
    'correctionPromptSpanish/correctionPromptPortuguese reassemble byte-for-byte '
    'from their section constants',
    () {
      final fixtureFile = File(
        'test/core/services/golden_correction_prompts.json',
      );
      final golden =
          jsonDecode(fixtureFile.readAsStringSync()) as Map<String, Object?>;

      expect(
        correctionPromptSpanish,
        golden['correctionSystemPromptSpanish'],
      );
      expect(
        correctionPromptPortuguese,
        golden['correctionSystemPromptPortuguese'],
      );
    },
  );
}
