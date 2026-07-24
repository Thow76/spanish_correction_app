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
    );
  }

  final String openAiApiKey;
  final String openAiCorrectionModel;
  final String openAiWalkthroughModel;
}
