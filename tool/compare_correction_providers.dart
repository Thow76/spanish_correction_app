import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service_exception.dart';
import 'package:spanish_correction_app/features/corrections/data/gemini_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';

const _comparisonPhrases = [
  'Cómo estás? Qué tal?',
  '¿Cómo estás? ¿Qué tal?',
  'Mañana iré al médico.',
  'Como estas? Que tal?',
  'Hola como estas',
];

void main() {
  test(
    'compares Gemini and OpenAI Spanish correction behavior',
    () async {
      final config = AppConfig.fromEnvironment();
      final geminiApiKey = _readEnvironment(
        'GEMINI_API_KEY',
        defaultValue: config.geminiApiKey,
      );
      final openAiApiKey = _readEnvironment(
        'OPENAI_API_KEY',
        defaultValue: config.openAiApiKey,
      );
      final geminiModel = _readEnvironment(
        'GEMINI_MODEL',
        defaultValue: config.geminiModel,
      );
      final openAiModel = _readEnvironment(
        'OPENAI_CORRECTION_MODEL',
        defaultValue: config.openAiCorrectionModel,
      );

      if (geminiApiKey.isEmpty || openAiApiKey.isEmpty) {
        fail(
          'Set GEMINI_API_KEY and OPENAI_API_KEY, or configure defaults in AppConfig.',
        );
      }

      final providers = [
        _ProviderRun(
          name: 'Gemini',
          model: geminiModel,
          service: GeminiCorrectionService(
            apiKey: geminiApiKey,
            model: geminiModel,
          ),
        ),
        _ProviderRun(
          name: 'OpenAI',
          model: openAiModel,
          service: OpenAiCorrectionService(
            apiKey: openAiApiKey,
            model: openAiModel,
          ),
        ),
      ];

      _printComparisonHeader(
        geminiModel: geminiModel,
        openAiModel: openAiModel,
      );

      for (final phrase in _comparisonPhrases) {
        // ignore: avoid_print
        print('Input: "$phrase"');
        for (final provider in providers) {
          final result = await provider.run(phrase);
          // ignore: avoid_print
          print(result.summary);
          if (result.response != null) {
            // ignore: avoid_print
            print('  corrected: "${result.response!.correctedText}"');
            // ignore: avoid_print
            print('  corrections: ${_formatCorrections(result.response!)}');
            // ignore: avoid_print
            print(
              '  usage proxy: inputChars=${phrase.length}, '
              'outputChars=${result.response!.correctedText.length}',
            );
          }
        }
        // ignore: avoid_print
        print('');
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}

void _printComparisonHeader({
  required String geminiModel,
  required String openAiModel,
}) {
  // ignore: avoid_print
  print('Spanish correction provider comparison');
  // ignore: avoid_print
  print('Gemini model: $geminiModel');
  // ignore: avoid_print
  print('OpenAI model: $openAiModel');
  // ignore: avoid_print
  print('');
}

String _formatCorrections(CorrectionResponse response) {
  if (response.corrections.isEmpty) {
    return 'none';
  }

  return response.corrections
      .map(
        (correction) =>
            '[${correction.category.label}] '
            '"${correction.originalPhrase}" -> "${correction.correctedPhrase}"',
      )
      .join('; ');
}

class _ProviderRun {
  const _ProviderRun({
    required this.name,
    required this.model,
    required this.service,
  });

  final String name;
  final String model;
  final CorrectionService service;

  Future<_ComparisonResult> run(String phrase) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await service.correctText(phrase);
      stopwatch.stop();
      return _ComparisonResult.success(
        provider: name,
        model: model,
        elapsed: stopwatch.elapsed,
        response: response,
      );
    } on CorrectionServiceException catch (error) {
      stopwatch.stop();
      return _ComparisonResult.failure(
        provider: name,
        model: model,
        elapsed: stopwatch.elapsed,
        reason: error.reason.name,
        message: error.message,
      );
    } catch (error) {
      stopwatch.stop();
      return _ComparisonResult.failure(
        provider: name,
        model: model,
        elapsed: stopwatch.elapsed,
        reason: 'unexpected',
        message: error.toString(),
      );
    }
  }
}

class _ComparisonResult {
  const _ComparisonResult._({
    required this.provider,
    required this.model,
    required this.elapsed,
    required this.response,
    required this.reason,
    required this.message,
  });

  factory _ComparisonResult.success({
    required String provider,
    required String model,
    required Duration elapsed,
    required CorrectionResponse response,
  }) {
    return _ComparisonResult._(
      provider: provider,
      model: model,
      elapsed: elapsed,
      response: response,
      reason: null,
      message: null,
    );
  }

  factory _ComparisonResult.failure({
    required String provider,
    required String model,
    required Duration elapsed,
    required String reason,
    required String message,
  }) {
    return _ComparisonResult._(
      provider: provider,
      model: model,
      elapsed: elapsed,
      response: null,
      reason: reason,
      message: message,
    );
  }

  final String provider;
  final String model;
  final Duration elapsed;
  final CorrectionResponse? response;
  final String? reason;
  final String? message;

  String get summary {
    final milliseconds = elapsed.inMilliseconds;
    if (response == null) {
      return '- $provider ($model): failed in ${milliseconds}ms '
          '[$reason] $message';
    }

    final correctionCount = response!.corrections.length;
    return '- $provider ($model): ok in ${milliseconds}ms, '
        '$correctionCount correction${correctionCount == 1 ? '' : 's'}';
  }
}
