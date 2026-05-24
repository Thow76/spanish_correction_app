class AppConfig {
  const AppConfig({
    required this.correctionProvider,
    required this.geminiApiKey,
    required this.geminiModel,
    required this.openAiApiKey,
    required this.openAiCorrectionModel,
  });

  factory AppConfig.fromEnvironment() {
    const correctionProvider = String.fromEnvironment(
      'CORRECTION_PROVIDER',
      defaultValue: 'gemini',
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
      openAiCorrectionModel: const String.fromEnvironment(
        'OPENAI_CORRECTION_MODEL',
        defaultValue: 'gpt-4.1-mini',
      ),
    );
  }

  final CorrectionProvider correctionProvider;
  final String geminiApiKey;
  final String geminiModel;
  final String openAiApiKey;
  final String openAiCorrectionModel;
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
