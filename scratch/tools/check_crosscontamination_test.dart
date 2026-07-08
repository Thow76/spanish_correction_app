// Diagnostic only — NOT a fix, NOT part of the app. Disposable.
//
// Question 4 of the "why did Spanish correction stability change" investigation.
// Run 1: correctText() 5x in a row, same Spanish input, in total isolation.
// Run 2: correctText() 5x again, same input, but with a gradeRetranslation()
// call interleaved between each one, to check whether grading calls
// cross-contaminate subsequent correction calls on the same shared service
// instance / HttpClient.
//
// Run:
//   OPENAI_API_KEY=sk-... flutter test scratch/tools/check_crosscontamination_test.dart --timeout none

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service_exception.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

const String spanishInput = 'Quiero desayunar tenprano mañana';

void main() {
  test('correctText() isolated vs interleaved with gradeRetranslation()', () async {
    final config = AppConfig.fromEnvironment();
    final apiKey = _readEnvironment('OPENAI_API_KEY', defaultValue: config.openAiApiKey);
    final model = _readEnvironment(
      'OPENAI_CORRECTION_MODEL',
      defaultValue: config.openAiCorrectionModel,
    );

    // ignore: avoid_print
    print('Model in use: $model');
    // Single shared service instance, exactly as the real app uses it
    // (one instance built once in spanish_correction_app.dart, reused for
    // every correctText() and gradeRetranslation() call).
    final service = OpenAiCorrectionService(apiKey: apiKey, model: model);

    // ignore: avoid_print
    print('\n================ RUN 1: ISOLATED (5x correctText only) ================');
    final isolatedResults = <CorrectionResponse>[];
    for (var i = 1; i <= 5; i++) {
      final result = await _callWithRetry(() => service.correctText(spanishInput, Language.spanish), 'correctText $i');
      if (result != null) {
        isolatedResults.add(result);
        _printResult(i, result);
      }
    }

    // ignore: avoid_print
    print('\n================ RUN 2: INTERLEAVED (correctText + gradeRetranslation between each) ================');
    final interleavedResults = <CorrectionResponse>[];
    for (var i = 1; i <= 5; i++) {
      final result = await _callWithRetry(() => service.correctText(spanishInput, Language.spanish), 'correctText $i');
      if (result != null) {
        interleavedResults.add(result);
        _printResult(i, result);
      }

      // Interleave a grading call using the same shared service/HttpClient,
      // before the next correctText() call.
      final grade = await _callWithRetry(
        () => service.gradeRetranslation(
          attempt: 'Voy al supermercado a comprar pan',
          expectedAnswer: 'Fui al supermercado a comprar pan.',
          targetCategory: ErrorCategory.grammar,
          language: Language.spanish,
        ),
        'gradeRetranslation $i',
      );
      if (grade != null) {
        // ignore: avoid_print
        print(
          '  [interleaved gradeRetranslation call $i] isRelated=${grade.isRelated}, '
          'corrected_text="${grade.correctedText}"',
        );
      }
    }

    // ignore: avoid_print
    print('\n================ SUMMARY ================');
    final isolatedTexts = isolatedResults.map((r) => r.correctedText).toSet();
    final interleavedTexts = interleavedResults.map((r) => r.correctedText).toSet();
    // ignore: avoid_print
    print('Isolated run: ${isolatedTexts.length} distinct corrected_text value(s) across 5 calls');
    // ignore: avoid_print
    print('Interleaved run: ${interleavedTexts.length} distinct corrected_text value(s) across 5 calls');
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<T?> _callWithRetry<T>(Future<T> Function() call, String label, {int attempts = 3}) async {
  for (var attempt = 1; attempt <= attempts; attempt++) {
    try {
      return await call();
    } on CorrectionServiceException catch (e) {
      // ignore: avoid_print
      print('  [$label] attempt $attempt/$attempts FAILED: ${e.reason} — ${e.message}');
      if (attempt == attempts) {
        // ignore: avoid_print
        print('  [$label] giving up after $attempts attempts.');
        return null;
      }
    }
  }
  return null;
}

void _printResult(int index, CorrectionResponse result) {
  // ignore: avoid_print
  print('--- correctText call $index ---');
  // ignore: avoid_print
  print('corrected_text: ${result.correctedText}');
  // ignore: avoid_print
  print('corrections (${result.corrections.length}):');
  for (final c in result.corrections) {
    // ignore: avoid_print
    print(
      '  - "${c.originalPhrase}" -> "${c.correctedPhrase}" '
      '[${c.category.label}] ${c.shortExplanation}',
    );
  }
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}
