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
    expect(config.openAiCorrectionModel, 'gpt-5.5');
    // Falls back to the correction model when OPENAI_WALKTHROUGH_MODEL is unset.
    expect(config.openAiWalkthroughModel, 'gpt-5.5');
  });

  test(
    'the staged Spanish pipeline toggle defaults to off, both on the '
    'AppConfig constructor and on AppConfig.fromEnvironment()',
    () {
      const config = AppConfig(
        correctionProvider: CorrectionProvider.openAi,
        geminiApiKey: 'gemini-key',
        geminiModel: 'gemini-model',
        openAiApiKey: 'openai-key',
        openAiCorrectionModel: 'openai-model',
        openAiWalkthroughModel: 'walkthrough-model',
      );
      expect(config.useStagedSpanishPipeline, isFalse);

      expect(AppConfig.fromEnvironment().useStagedSpanishPipeline, isFalse);
    },
  );

  test(
    'buildCorrectionService passes the staged Spanish pipeline toggle '
    'through to the constructed OpenAiCorrectionService',
    () {
      final serviceWithDefault = buildCorrectionService(
        const AppConfig(
          correctionProvider: CorrectionProvider.openAi,
          geminiApiKey: 'gemini-key',
          geminiModel: 'gemini-model',
          openAiApiKey: 'openai-key',
          openAiCorrectionModel: 'openai-model',
          openAiWalkthroughModel: 'walkthrough-model',
        ),
      );
      expect(
        (serviceWithDefault as OpenAiCorrectionService).useStagedSpanishPipeline,
        isFalse,
      );

      final serviceWithToggleOn = buildCorrectionService(
        const AppConfig(
          correctionProvider: CorrectionProvider.openAi,
          geminiApiKey: 'gemini-key',
          geminiModel: 'gemini-model',
          openAiApiKey: 'openai-key',
          openAiCorrectionModel: 'openai-model',
          openAiWalkthroughModel: 'walkthrough-model',
          useStagedSpanishPipeline: true,
        ),
      );
      expect(
        (serviceWithToggleOn as OpenAiCorrectionService).useStagedSpanishPipeline,
        isTrue,
      );
    },
  );

  test('builds Gemini correction service for Gemini provider', () {
    final service = buildCorrectionService(
      const AppConfig(
        correctionProvider: CorrectionProvider.gemini,
        geminiApiKey: 'gemini-key',
        geminiModel: 'gemini-model',
        openAiApiKey: 'openai-key',
        openAiCorrectionModel: 'openai-model',
        openAiWalkthroughModel: 'walkthrough-model',
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
        openAiWalkthroughModel: 'walkthrough-model',
      ),
    );

    expect(service, isA<OpenAiCorrectionService>());
  });
}
