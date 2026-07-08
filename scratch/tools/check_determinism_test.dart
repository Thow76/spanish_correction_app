// Diagnostic only — NOT a fix, NOT part of the app. Disposable.
//
// Calls the real production correctText() path twice with the exact same
// input and prints both raw CorrectionResponse outputs side by side, to
// check whether the same input produces different corrections on repeat
// calls against the current production model/config.
//
// Run (same pattern as test/retranslation_grade_validation.dart):
//   OPENAI_API_KEY=sk-... flutter test scratch/tools/check_determinism_test.dart --timeout none

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';

void main() {
  test('correctText() determinism check', () async {
    final config = AppConfig.fromEnvironment();
    final apiKey = _readEnvironment('OPENAI_API_KEY', defaultValue: config.openAiApiKey);
    final model = _readEnvironment(
      'OPENAI_CORRECTION_MODEL',
      defaultValue: config.openAiCorrectionModel,
    );

    // ignore: avoid_print
    print('Model in use: $model');

    final service = OpenAiCorrectionService(apiKey: apiKey, model: model);

    const text =
        'Posso ter uma cerveja? Quero passar um bom tempo com meus amigos essa noite.';

    final first = await service.correctText(text, Language.portuguese);
    final second = await service.correctText(text, Language.portuguese);

    // ignore: avoid_print
    print('=== CALL 1 ===');
    // ignore: avoid_print
    print('corrected_text: ${first.correctedText}');
    // ignore: avoid_print
    print('corrections (${first.corrections.length}):');
    for (final c in first.corrections) {
      // ignore: avoid_print
      print(
        '  - "${c.originalPhrase}" -> "${c.correctedPhrase}" '
        '[${c.category.label}] ${c.shortExplanation}',
      );
    }

    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('=== CALL 2 ===');
    // ignore: avoid_print
    print('corrected_text: ${second.correctedText}');
    // ignore: avoid_print
    print('corrections (${second.corrections.length}):');
    for (final c in second.corrections) {
      // ignore: avoid_print
      print(
        '  - "${c.originalPhrase}" -> "${c.correctedPhrase}" '
        '[${c.category.label}] ${c.shortExplanation}',
      );
    }

    final identical =
        first.correctedText == second.correctedText &&
        first.corrections.length == second.corrections.length;

    // ignore: avoid_print
    print('');
    // ignore: avoid_print
    print('=== VERDICT: ${identical ? 'IDENTICAL' : 'DIFFERENT'} ===');
  }, timeout: const Timeout(Duration(minutes: 2)));
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}
