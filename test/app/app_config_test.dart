import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/app/spanish_correction_app.dart';
import 'package:spanish_correction_app/features/corrections/data/gemini_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';

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

  test('default config uses OpenAI as the active correction provider', () {
    final config = AppConfig.fromEnvironment();

    expect(config.correctionProvider, CorrectionProvider.openAi);
    expect(config.openAiCorrectionModel, 'gpt-4.1-mini');
  });

  test('builds Gemini correction service for Gemini provider', () {
    final service = buildCorrectionService(
      const AppConfig(
        correctionProvider: CorrectionProvider.gemini,
        geminiApiKey: 'gemini-key',
        geminiModel: 'gemini-model',
        openAiApiKey: 'openai-key',
        openAiCorrectionModel: 'openai-model',
      ),
    );

    expect(service, isA<GeminiCorrectionService>());
  });

  test('builds OpenAI correction service for OpenAI provider', () {
    final service = buildCorrectionService(
      const AppConfig(
        correctionProvider: CorrectionProvider.openAi,
        geminiApiKey: 'gemini-key',
        geminiModel: 'gemini-model',
        openAiApiKey: 'openai-key',
        openAiCorrectionModel: 'openai-model',
      ),
    );

    expect(service, isA<OpenAiCorrectionService>());
  });
}
