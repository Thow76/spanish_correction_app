import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../application/correction_service.dart';
import '../application/correction_service_exception.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';

class GeminiCorrectionService implements CorrectionService {
  GeminiCorrectionService({
    required String apiKey,
    required String model,
    HttpClient? httpClient,
  }) : _apiKey = apiKey.trim(),
       _model = _normaliseModel(model),
       _httpClient = httpClient ?? HttpClient();

  final String _apiKey;
  final String _model;
  final HttpClient _httpClient;

  @override
  Future<CorrectionResponse> correctText(String text) async {
    _ensureConfigured();

    final responseText = await _generateContent(
      systemInstruction: _correctionSystemInstruction,
      userText: 'Review this Spanish text:\n\n$text',
    );

    try {
      final jsonObject = jsonDecode(_extractJsonObject(responseText));
      if (jsonObject is! Map<String, Object?>) {
        throw const FormatException('Root value is not an object.');
      }

      final response = CorrectionResponse.fromJson(jsonObject);
      _validateCorrectionResponse(response);
      return response;
    } on FormatException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.invalidResponse,
        'Gemini returned an invalid correction response: $error',
      );
    }
  }

  @override
  Future<String> generateLongExplanation(CorrectionItem correction) async {
    _ensureConfigured();

    return _generateContent(
      systemInstruction: _longExplanationSystemInstruction,
      userText:
          '''
Original phrase: ${correction.originalPhrase}
Corrected phrase: ${correction.correctedPhrase}
Category: ${correction.category.label}
Short explanation: ${correction.shortExplanation}
''',
      responseMimeType: 'text/plain',
    );
  }

  Future<String> _generateContent({
    required String systemInstruction,
    required String userText,
    String responseMimeType = 'application/json',
  }) async {
    try {
      final request = await _openRequest().timeout(const Duration(seconds: 10));

      request.headers
        ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType)
        ..set('x-goog-api-key', _apiKey);

      request.write(
        jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemInstruction},
            ],
          },
          'contents': [
            {
              'parts': [
                {'text': userText},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'responseMimeType': responseMimeType,
          },
        }),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CorrectionServiceException(
          CorrectionFailureReason.apiFailure,
          'Gemini request failed with HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Gemini response root is not an object.');
      }

      final candidates = decoded['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        throw const FormatException('Gemini response has no candidates.');
      }

      final candidate = candidates.first;
      if (candidate is! Map<String, Object?>) {
        throw const FormatException('Gemini candidate is not an object.');
      }

      final content = candidate['content'];
      if (content is! Map<String, Object?>) {
        throw const FormatException('Gemini candidate has no content.');
      }

      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        throw const FormatException('Gemini content has no text parts.');
      }

      final text = parts
          .whereType<Map<String, Object?>>()
          .map((part) => part['text'])
          .whereType<String>()
          .join()
          .trim();

      if (text.isEmpty) {
        throw const FormatException('Gemini response text is empty.');
      }

      return text;
    } on SocketException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.networkUnavailable,
        'No internet available: $error',
      );
    } on TimeoutException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.apiFailure,
        'Gemini request timed out: $error',
      );
    } on FormatException catch (error) {
      throw CorrectionServiceException(
        CorrectionFailureReason.invalidResponse,
        'Gemini returned an invalid API response: $error',
      );
    }
  }

  Future<HttpClientRequest> _openRequest() {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );
    return _httpClient.postUrl(uri);
  }

  void _ensureConfigured() {
    if (_apiKey.isEmpty) {
      throw const CorrectionServiceException(
        CorrectionFailureReason.missingConfiguration,
        'Missing GEMINI_API_KEY.',
      );
    }
    if (_model.isEmpty) {
      throw const CorrectionServiceException(
        CorrectionFailureReason.missingConfiguration,
        'Missing GEMINI_MODEL.',
      );
    }
  }

  static String _normaliseModel(String model) {
    return model.trim().replaceFirst(RegExp('^models/'), '');
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

  static void _validateCorrectionResponse(CorrectionResponse response) {
    if (response.originalText.isEmpty || response.correctedText.isEmpty) {
      throw const FormatException('Missing original_text or corrected_text.');
    }
  }
}

const _correctionSystemInstruction = '''
You are a Spanish correction engine for a mobile language-learning app.

Return only valid JSON with this exact shape:
{
  "original_text": "string",
  "corrected_text": "string",
  "corrections": [
    {
      "original_phrase": "string",
      "corrected_phrase": "string",
      "category": "string",
      "short_explanation": "string"
    }
  ]
}

Rules:
- Preserve the user's original text in original_text.
- corrected_text must contain a polished corrected version of the whole text.
- category must be exactly one of: Grammar, Natural Language, Spelling, Word Choice, Other.
- Punctuation and preposition errors must be returned as Grammar.
- short_explanation must be one informal but technically accurate sentence.
- If there are no corrections, return an empty corrections array and keep corrected_text equal to original_text.
- Do not include Markdown, code fences, commentary, or keys outside the requested JSON.
''';

const _longExplanationSystemInstruction = '''
You explain Spanish corrections to learners.

Write a concise but useful longer explanation for the saved correction.
Include:
- why the original phrase was wrong or unnatural
- how the corrected phrase works in context
- one or two alternative phrasings if useful

Return plain text only, not JSON or Markdown.
''';
