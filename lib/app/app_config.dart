class AppConfig {
  const AppConfig({
    required this.correctionProvider,
    required this.geminiApiKey,
    required this.geminiModel,
    required this.openAiApiKey,
    required this.openAiCorrectionModel,
    required this.openAiWalkthroughModel,
    this.useStagedSpanishPipeline = false,
  });

  factory AppConfig.fromEnvironment() {
    const correctionProvider = String.fromEnvironment(
      'CORRECTION_PROVIDER',
      defaultValue: 'openai',
    );
    const openAiCorrectionModel = String.fromEnvironment(
      'OPENAI_CORRECTION_MODEL',
      defaultValue: 'gpt-5.5',
    );

    return AppConfig(
      correctionProvider: CorrectionProvider.fromEnvironmentValue(
        correctionProvider,
      ),
      geminiApiKey: const String.fromEnvironment(
        'GEMINI_API_KEY',
        defaultValue: 'AIzaSyAUvJWQIwOikRY_kKYeCOGDGJZ39BD4jBI',
      ),
      geminiModel: const String.fromEnvironment(
        'GEMINI_MODEL',
        defaultValue: 'gemini-3.1-flash-lite',
      ),
      openAiApiKey: const String.fromEnvironment(
        'OPENAI_API_KEY',
        defaultValue:
            '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',
      ),
      openAiCorrectionModel: openAiCorrectionModel,
      // Falls back to the correction model when unset, mirroring the prompt
      // validation harness (OPENAI_WALKTHROUGH_MODEL -> OPENAI_CORRECTION_MODEL).
      openAiWalkthroughModel: const String.fromEnvironment(
        'OPENAI_WALKTHROUGH_MODEL',
        defaultValue: openAiCorrectionModel,
      ),
      // Off by default: a deliberate product decision. The staged pipeline
      // (Stage 1/1B/2/3, see staged_correction_pipeline.dart) only takes
      // effect for OpenAI + Spanish when this is explicitly turned on;
      // nothing changes for real users until it's flipped.
      useStagedSpanishPipeline: const bool.fromEnvironment(
        'USE_STAGED_SPANISH_PIPELINE',
      ),
    );
  }

  final CorrectionProvider correctionProvider;
  final String geminiApiKey;
  final String geminiModel;
  final String openAiApiKey;
  final String openAiCorrectionModel;
  final String openAiWalkthroughModel;
  final bool useStagedSpanishPipeline;
}

enum CorrectionProvider {
  gemini,
  openAi;

  static CorrectionProvider fromEnvironmentValue(String value) {
    return switch (value.trim().toLowerCase()) {
      'openai' || 'open_ai' || 'open-ai' => CorrectionProvider.openAi,
      'gemini' || _ => CorrectionProvider.gemini,
    };
  }
}
