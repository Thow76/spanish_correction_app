import 'package:flutter/services.dart';

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

  /// Where the app looks for the OpenAI key when none was given at build
  /// time. Put the key in this file on the Mac, either on its own or as
  /// `OPENAI_API_KEY=...` (a copy of `.env` works). It goes into the app
  /// when it is built, and git ignores it, so it never reaches GitHub.
  static const keyFileAsset = 'secrets/openai_key.txt';

  /// The settings, with the key taken from the build command if one was
  /// given, otherwise from [keyFileAsset]. A plain `flutter run` then works.
  static Future<AppConfig> load({AssetBundle? bundle}) async {
    final fromBuild = AppConfig.fromEnvironment();
    if (fromBuild.openAiApiKey.trim().isNotEmpty) {
      return fromBuild;
    }
    String contents;
    try {
      contents = await (bundle ?? rootBundle).loadString(keyFileAsset);
    } catch (_) {
      return fromBuild;
    }
    return AppConfig(
      openAiApiKey: parseKeyFile(contents),
      openAiCorrectionModel: fromBuild.openAiCorrectionModel,
      openAiWalkthroughModel: fromBuild.openAiWalkthroughModel,
    );
  }

  /// The key in a key file: the `OPENAI_API_KEY=` line if there is one,
  /// otherwise the first line that is not blank or a comment.
  static String parseKeyFile(String contents) {
    final lines = contents
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    for (final line in lines) {
      if (line.startsWith('OPENAI_API_KEY=')) {
        return _unquote(line.substring('OPENAI_API_KEY='.length).trim());
      }
    }
    if (lines.isEmpty || lines.first.contains('=')) {
      return '';
    }
    return _unquote(lines.first);
  }

  static String _unquote(String value) {
    if (value.length >= 2 &&
        (value.startsWith('"') && value.endsWith('"') ||
            value.startsWith("'") && value.endsWith("'"))) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }

  final String openAiApiKey;
  final String openAiCorrectionModel;
  final String openAiWalkthroughModel;
}
