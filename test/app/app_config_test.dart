import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';

void main() {
  test('default config reads the OpenAI models from environment', () {
    final config = AppConfig.fromEnvironment();

    expect(config.openAiCorrectionModel, 'gpt-5.5');
    // Falls back to the correction model when OPENAI_WALKTHROUGH_MODEL is unset.
    expect(config.openAiWalkthroughModel, 'gpt-5.5');
  });
}
