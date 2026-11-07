/// Candidate model for the staged Spanish correction pipeline
/// (`runStagedCorrectionPipeline`, wired in via
/// `OpenAiCorrectionService._correctSpanishTextViaStagedPipeline`). Not yet
/// used by [AppConfig.openAiCorrectionModel] itself, so grading/retranslation
/// and every other `OpenAiCorrectionService` call keep using the GPT-5.5
/// default below.
const openAiCorrectionPipelineModelTerra = 'gpt-5.6-terra';

class AppConfig {
  const AppConfig({
    required this.openAiApiKey,
    required this.openAiCorrectionModel,
    required this.openAiWalkthroughModel,
  });

  factory AppConfig.fromEnvironment() {
    const openAiCorrectionModel = String.fromEnvironment(
      'OPENAI_CORRECTION_MODEL',
      defaultValue: 'gpt-5.5',
    );

    return AppConfig(
      openAiApiKey: const String.fromEnvironment(
        'OPENAI_API_KEY',
        defaultValue: '',
      ),
      openAiCorrectionModel: openAiCorrectionModel,
      // Falls back to the correction model when unset, mirroring the prompt
      // validation harness (OPENAI_WALKTHROUGH_MODEL -> OPENAI_CORRECTION_MODEL).
      openAiWalkthroughModel: const String.fromEnvironment(
        'OPENAI_WALKTHROUGH_MODEL',
        defaultValue: openAiCorrectionModel,
      ),
    );
  }

  final String openAiApiKey;
  final String openAiCorrectionModel;
  final String openAiWalkthroughModel;
}
