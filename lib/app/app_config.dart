class AppConfig {
  const AppConfig({required this.geminiApiKey, required this.geminiModel});

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
    );
  }

  final String geminiApiKey;
  final String geminiModel;
}
