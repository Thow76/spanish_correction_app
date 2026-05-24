import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';

void main() {
  test('correction provider defaults to Gemini for unknown values', () {
    expect(
      CorrectionProvider.fromEnvironmentValue('gemini'),
      CorrectionProvider.gemini,
    );
    expect(
      CorrectionProvider.fromEnvironmentValue('something-else'),
      CorrectionProvider.gemini,
    );
  });

  test('correction provider accepts OpenAI aliases', () {
    expect(
      CorrectionProvider.fromEnvironmentValue('openai'),
      CorrectionProvider.openAi,
    );
    expect(
      CorrectionProvider.fromEnvironmentValue('open_ai'),
      CorrectionProvider.openAi,
    );
    expect(
      CorrectionProvider.fromEnvironmentValue('open-ai'),
      CorrectionProvider.openAi,
    );
  });

  test('default config keeps Gemini as the active correction provider', () {
    final config = AppConfig.fromEnvironment();

    expect(config.correctionProvider, CorrectionProvider.gemini);
    expect(config.openAiCorrectionModel, 'gpt-4.1-mini');
  });
}
