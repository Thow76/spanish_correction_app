class AppConfig {
  const AppConfig({
    required this.geminiApiKey,
    required this.geminiModel,
    required this.openAiApiKey,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      geminiApiKey: String.fromEnvironment(
        'GEMINI_API_KEY',
        defaultValue: 'AIzaSyAUvJWQIwOikRY_kKYeCOGDGJZ39BD4jBI',
      ),
      geminiModel: String.fromEnvironment(
        'GEMINI_MODEL',
        defaultValue: 'gemini-3.1-flash-lite',
      ),
      openAiApiKey: String.fromEnvironment(
        'OPENAI_API_KEY',
        defaultValue:
            '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',
      ),
    );
  }

  final String geminiApiKey;
  final String geminiModel;
  final String openAiApiKey;
}
