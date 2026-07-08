// Diagnostic only — NOT a fix, NOT part of the app. Disposable.
//
// Calls the real production correctText() path twice with the exact same
// input and prints both raw CorrectionResponse outputs side by side, to
// check whether the same input produces different corrections on repeat
// calls against the current production model/config.
//
// Run:
//   OPENAI_API_KEY=sk-... dart run scratch/tools/check_determinism.dart

import 'dart:io';

import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';

Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  final apiKey = Platform.environment['OPENAI_API_KEY']?.trim().isNotEmpty == true
      ? Platform.environment['OPENAI_API_KEY']!.trim()
      : config.openAiApiKey;
  final model = Platform.environment['OPENAI_CORRECTION_MODEL']?.trim().isNotEmpty == true
      ? Platform.environment['OPENAI_CORRECTION_MODEL']!.trim()
      : config.openAiCorrectionModel;

  stdout.writeln('Model in use: $model');
  stdout.writeln('---');

  final service = OpenAiCorrectionService(apiKey: apiKey, model: model);

  const text =
      'Posso ter uma cerveja? Quero passar um bom tempo com meus amigos essa noite.';

  final first = await service.correctText(text, Language.portuguese);
  final second = await service.correctText(text, Language.portuguese);

  stdout.writeln('=== CALL 1 ===');
  stdout.writeln('corrected_text: ${first.correctedText}');
  stdout.writeln('corrections (${first.corrections.length}):');
  for (final c in first.corrections) {
    stdout.writeln(
      '  - "${c.originalPhrase}" -> "${c.correctedPhrase}" '
      '[${c.category.label}] ${c.shortExplanation}',
    );
  }

  stdout.writeln();
  stdout.writeln('=== CALL 2 ===');
  stdout.writeln('corrected_text: ${second.correctedText}');
  stdout.writeln('corrections (${second.corrections.length}):');
  for (final c in second.corrections) {
    stdout.writeln(
      '  - "${c.originalPhrase}" -> "${c.correctedPhrase}" '
      '[${c.category.label}] ${c.shortExplanation}',
    );
  }

  stdout.writeln();
  final identical =
      first.correctedText == second.correctedText &&
      first.corrections.length == second.corrections.length;
  stdout.writeln('=== VERDICT ===');
  stdout.writeln(identical ? 'IDENTICAL' : 'DIFFERENT');
}
