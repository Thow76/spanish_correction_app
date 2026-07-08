// Spanish correction stability A/B probe.
//
// MANUAL harness — makes live correction-API calls through the REAL,
// unmodified `OpenAiCorrectionService.correctText()` (no prompt injection).
// Same file is placed identically in both the `main` worktree and this
// branch's worktree so the only variable between runs is the checked-out
// commit (and therefore whatever `_correctionPromptSpanish` reads as on that
// commit — confirmed byte-identical between the two via direct diff before
// this harness was written).
//
// Run:
//   OPENAI_API_KEY=sk-... flutter test test/spanish_ab_stability.dart --timeout none
//
// Writes a report to docs/spanish_ab_stability.md (override with
// --dart-define=AB_OUTPUT=...). Fails (not skips) when no API key is
// configured.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';

const String outputPath = String.fromEnvironment(
  'AB_OUTPUT',
  defaultValue: 'docs/spanish_ab_stability.md',
);

const int runsPerPhrase = 5;

class _Phrase {
  const _Phrase({required this.id, required this.text});

  final String id;
  final String text;
}

const List<_Phrase> _phrases = [
  _Phrase(id: 's1-cafe', text: '¿Puedo tener un café?'),
  _Phrase(id: 's2-para-atras', text: 'Llamé para atrás a mi amigo.'),
  _Phrase(id: 's3-buen-tiempo', text: 'Pasé un buen tiempo con mis amigos.'),
  _Phrase(id: 's4-realice', text: 'Realicé que había olvidado mis llaves.'),
  _Phrase(id: 's5-final-del-dia-paces', text: 'Al final del día, hicimos las paces.'),
  _Phrase(
    id: 's6-final-del-dia-cansados',
    text: 'Llegamos al final del día muy cansados.',
  ),
];

void main() {
  test('spanish correction stability A/B probe', () async {
    final config = AppConfig.fromEnvironment();
    final apiKey = _readEnvironment(
      'OPENAI_API_KEY',
      defaultValue: config.openAiApiKey,
    );
    final model = _readEnvironment(
      'OPENAI_CORRECTION_MODEL',
      defaultValue: config.openAiCorrectionModel,
    );

    if (apiKey.isEmpty) {
      fail(
        'Set OPENAI_API_KEY (or a default in AppConfig) to run the Spanish '
        'A/B stability harness.',
      );
    }

    final service = OpenAiCorrectionService(apiKey: apiKey, model: model);

    final report = StringBuffer()
      ..writeln('# Spanish Correction Stability A/B Probe')
      ..writeln()
      ..writeln('Model: `$model`  ')
      ..writeln('Commit: `${_gitHead()}`  ')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}  ')
      ..writeln('Runs per phrase: $runsPerPhrase')
      ..writeln();

    for (final phrase in _phrases) {
      report
        ..writeln('## ${phrase.id}')
        ..writeln()
        ..writeln('- Text: `${phrase.text}`')
        ..writeln();

      // ignore: avoid_print
      print('=== ${phrase.id} ===');

      for (var run = 1; run <= runsPerPhrase; run++) {
        report.writeln('### Run $run/$runsPerPhrase');
        report.writeln();

        try {
          final response = await service.correctText(
            phrase.text,
            Language.spanish,
          );
          _writeRun(report, response);
          // ignore: avoid_print
          print('[run $run] ${_summarize(response)}');
        } catch (error) {
          report
            ..writeln('- ERROR: $error')
            ..writeln();
          // ignore: avoid_print
          print('[run $run] ERROR: $error');
        }
      }
    }

    File(outputPath).writeAsStringSync(report.toString());
    // ignore: avoid_print
    print('Wrote $outputPath');
  }, timeout: const Timeout(Duration(minutes: 20)));
}

void _writeRun(StringBuffer report, CorrectionResponse response) {
  report
    ..writeln('- corrected_text: `${response.correctedText}`')
    ..writeln('- corrections (${response.corrections.length}):');
  if (response.corrections.isEmpty) {
    report.writeln('  - (none)');
  } else {
    for (final correction in response.corrections) {
      report.writeln('  - ${_describeItem(correction)}');
    }
  }
  report.writeln();
}

String _describeItem(CorrectionItem item) {
  return '[${item.category.label}] "${item.originalPhrase}" -> '
      '"${item.correctedPhrase}" — ${item.shortExplanation}';
}

String _summarize(CorrectionResponse response) {
  if (response.corrections.isEmpty) {
    return 'corrected="${response.correctedText}" corrections=(none)';
  }
  final list = response.corrections
      .map(
        (c) => '${c.category.label}:"${c.originalPhrase}"->"${c.correctedPhrase}"',
      )
      .join('; ');
  return 'corrected="${response.correctedText}" corrections=[$list]';
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}
