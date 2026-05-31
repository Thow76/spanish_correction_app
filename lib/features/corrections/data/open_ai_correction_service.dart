import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/enums/language.dart';
import '../../../core/services/prompt_builder.dart';
import '../application/correction_response_schema.dart';
import '../application/correction_service.dart';
import '../application/correction_service_exception.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';
import '../../saved/domain/saved_explanation.dart';

class OpenAiCorrectionService implements CorrectionService {
  OpenAiCorrectionService({
    required String apiKey,
    required String model,
    HttpClient? httpClient,
  }) : _apiKey = apiKey.trim(),
       _model = model.trim(),
       _httpClient = httpClient ?? HttpClient();

  final String _apiKey;
  final String _model;
  final HttpClient _httpClient;

  @override
  Future<CorrectionResponse> correctText(String text, Language language) async {
    _ensureConfigured();

    final responseText = await _createResponse(
      systemInstruction: PromptBuilder.correctionSystemPrompt(language),
      userText: PromptBuilder.correctionUserContent(language, text),
      textFormat: _correctionResponseFormat,
    );

    try {
      final jsonObject = jsonDecode(_extractJsonObject(responseText));
      if (jsonObject is! Map<String, Object?>) {
        throw const FormatException('Root value is not an object.');
      }

      final response = CorrectionResponse.fromAnchoredJson(
        jsonObject,
        submittedText: text,
        allowLegacyCategories: false,
      );
      _validateCorrectionResponse(response);
      return response;
    } on FormatException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.invalidResponse,
        'OpenAI returned an invalid correction response: $error',
      );
    }
  }

  @override
  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  ) {
    _ensureConfigured();

    return _createResponse(
      systemInstruction: PromptBuilder.longExplanationSystemPrompt(language),
      userText:
          '''
Original phrase: ${correction.originalPhrase}
Corrected phrase: ${correction.correctedPhrase}
Category: ${correction.category.label}
Short explanation: ${correction.shortExplanation}
''',
    );
  }

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async {
    _ensureConfigured();

    final responseText = await _createResponse(
      systemInstruction: PromptBuilder.structuredExplanationSystemPrompt(
        language,
      ),
      userText:
          '''
Original phrase: ${correction.originalPhrase}
Corrected phrase: ${correction.correctedPhrase}
Category: ${correction.category.label}
Short explanation: ${correction.shortExplanation}
''',
      textFormat: _structuredExplanationResponseFormat,
    );

    try {
      final jsonObject = jsonDecode(_extractJsonObject(responseText));
      if (jsonObject is! Map<String, Object?>) {
        throw const FormatException('Root value is not an object.');
      }

      return SavedExplanation.fromJson(jsonObject);
    } on FormatException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.invalidResponse,
        'OpenAI returned an invalid structured explanation: $error',
      );
    }
  }

  @override
  Future<String> generatePromptPhrase({
    required String correctedSentence,
    required Language language,
  }) async {
    _ensureConfigured();

    final responseText = await _createResponse(
      systemInstruction: PromptBuilder.promptPhraseSystemPrompt(language),
      userText: correctedSentence,
    );
    return responseText.trim();
  }

  Future<String> _createResponse({
    required String systemInstruction,
    required String userText,
    Map<String, Object?>? textFormat,
  }) async {
    try {
      final request = await _httpClient
          .postUrl(Uri.https('api.openai.com', '/v1/responses'))
          .timeout(const Duration(seconds: 10));

      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey')
        ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

      request.add(
        utf8.encode(
          jsonEncode({
            'model': _model,
            'input': [
              {'role': 'system', 'content': systemInstruction},
              {'role': 'user', 'content': userText},
            ],
            if (textFormat != null) 'text': {'format': textFormat},
          }),
        ),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CorrectionServiceException(
          CorrectionFailureReason.apiFailure,
          'OpenAI correction failed with HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('OpenAI response root is not an object.');
      }

      return _extractOutputText(decoded);
    } on SocketException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.networkUnavailable,
        'No internet available: $error',
      );
    } on TimeoutException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.apiFailure,
        'OpenAI correction timed out: $error',
      );
    } on FormatException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.invalidResponse,
        'OpenAI returned an invalid API response: $error',
      );
    }
  }

  void _ensureConfigured() {
    if (_apiKey.isEmpty) {
      throw const CorrectionServiceException(
        CorrectionFailureReason.missingConfiguration,
        'Missing OPENAI_API_KEY.',
      );
    }
    if (_model.isEmpty) {
      throw const CorrectionServiceException(
        CorrectionFailureReason.missingConfiguration,
        'Missing OPENAI_CORRECTION_MODEL.',
      );
    }
  }

  static String _extractJsonObject(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw const FormatException('No JSON object found.');
    }
    return trimmed.substring(start, end + 1);
  }

  static String _extractOutputText(Map<String, Object?> decoded) {
    final outputText = decoded['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    final output = decoded['output'];
    if (output is! List) {
      throw const FormatException('OpenAI response has no output.');
    }

    final buffer = StringBuffer();
    for (final item in output) {
      if (item is! Map<String, Object?>) {
        continue;
      }

      final content = item['content'];
      if (content is! List) {
        continue;
      }

      for (final part in content) {
        if (part is! Map<String, Object?>) {
          continue;
        }

        final text = part['text'];
        if (text is String) {
          buffer.write(text);
        }
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw const FormatException('OpenAI response has no output text.');
    }
    return text;
  }

  static void _validateCorrectionResponse(CorrectionResponse response) {
    if (response.originalText.isEmpty || response.correctedText.isEmpty) {
      throw const FormatException('Missing original_text or corrected_text.');
    }
  }
}

const _correctionResponseFormat = {
  'type': 'json_schema',
  'name': 'spanish_correction_response',
  'strict': true,
  'schema': correctionResponseJsonSchema,
};

const _structuredExplanationResponseFormat = {
  'type': 'json_schema',
  'name': 'saved_correction_explanation',
  'strict': true,
  'schema': _structuredExplanationJsonSchema,
};

const _structuredExplanationJsonSchema = <String, Object?>{
  'type': 'object',
  'additionalProperties': false,
  'required': ['why_its_wrong', 'in_context', 'alternatives'],
  'properties': {
    'why_its_wrong': {
      'type': 'string',
      'description':
          'Why the original phrase is incorrect or unnatural, in concise learner-friendly language.',
    },
    'in_context': {
      'type': 'string',
      'description':
          'One corrected example sentence using the corrected phrase naturally.',
    },
    'alternatives': {
      'type': 'array',
      'description':
          'One to three alternative phrasings, or an empty array when none are useful.',
      'items': {'type': 'string'},
    },
  },
};
