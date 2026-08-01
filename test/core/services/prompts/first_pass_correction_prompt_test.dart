import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

import '../../../model_comparison_harness.dart' as harness;

// Pins the production first-pass prompt constants (issue #64) to the
// harness constants they were copied from — same precedent as
// naturalness_review_client_test.dart's prompt/schema pinning tests — so
// the production and harness copies can never silently drift apart.
void main() {
  test(
    'firstPassCorrectionSpanish is unchanged from the harness-validated '
    'system prompt',
    () {
      expect(firstPassCorrectionSpanish, harness.systemPrompt);
    },
  );

  test(
    'buildFirstPassCorrectionUserContent matches the harness-validated '
    'user prompt template',
    () {
      const text = 'Los niño come muchas manzana en el jardín.';
      expect(
        buildFirstPassCorrectionUserContent(text),
        harness.buildUserPrompt(text),
      );
    },
  );

  test(
    'firstPassCorrectionResponseFormat matches the harness-validated '
    'schema',
    () {
      expect(
        firstPassCorrectionResponseFormat,
        harness.correctedTextResponseFormat,
      );
    },
  );
}
