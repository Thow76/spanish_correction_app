import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  Future<CorrectionResponse> correctText(String text) async {
    _ensureConfigured();

    final responseText = await _createChatCompletion(
      systemInstruction: _correctionSystemInstruction,
      userText: 'Review this Spanish text:\n\n$text',
      responseFormat: const {'type': 'json_object'},
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
  Future<String> generateLongExplanation(CorrectionItem correction) {
    _ensureConfigured();

    return _createChatCompletion(
      systemInstruction: _longExplanationSystemInstruction,
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
  ) async {
    _ensureConfigured();

    final responseText = await _createChatCompletion(
      systemInstruction: _structuredExplanationSystemInstruction,
      userText:
          '''
Original phrase: ${correction.originalPhrase}
Corrected phrase: ${correction.correctedPhrase}
Category: ${correction.category.label}
Short explanation: ${correction.shortExplanation}
''',
      responseFormat: const {'type': 'json_object'},
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

  Future<String> _createChatCompletion({
    required String systemInstruction,
    required String userText,
    Map<String, Object?>? responseFormat,
  }) async {
    try {
      final request = await _httpClient
          .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
          .timeout(const Duration(seconds: 10));

      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $_apiKey')
        ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

      request.write(
        jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemInstruction},
            {'role': 'user', 'content': userText},
          ],
          'temperature': 0.2,
          'response_format': ?responseFormat,
        }),
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

      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        throw const FormatException('OpenAI response has no choices.');
      }

      final choice = choices.first;
      if (choice is! Map<String, Object?>) {
        throw const FormatException('OpenAI choice is not an object.');
      }

      final message = choice['message'];
      if (message is! Map<String, Object?>) {
        throw const FormatException('OpenAI choice has no message.');
      }

      final content = message['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const FormatException('OpenAI message content is empty.');
      }

      return content.trim();
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

  static void _validateCorrectionResponse(CorrectionResponse response) {
    if (response.originalText.isEmpty || response.correctedText.isEmpty) {
      throw const FormatException('Missing original_text or corrected_text.');
    }
  }
}

final _correctionSystemInstruction =
    '''
You are a Spanish correction engine for a mobile language-learning app.

Return only valid JSON with this exact shape:
$correctionResponseJsonShape

Rules:
- Preserve the user's original text in original_text.
- corrected_text must contain a polished corrected version of the whole text.
- Each correction must identify the text being corrected with start_index and end_index only.
- Do not include original_phrase in any correction.
- start_index is zero-based and inclusive.
- end_index is zero-based and exclusive.
- Indexes must refer only to the submitted Spanish text, not the instruction text or labels.
- Indexes are measured in user-perceived characters, not bytes.
- Accented letters, ñ, inverted punctuation, emoji, and combining-accent sequences each count as one user-perceived character.
- The app will derive the original phrase from the submitted text range, so the ranges must anchor to the exact submitted text.
- category must be exactly one of: Grammar, Natural Language, Spelling, Word Choice, Other.
- short_explanation must be one informal but technically accurate sentence.
- If there are no corrections, return an empty corrections array and keep corrected_text equal to original_text.
- Do not include Markdown, code fences, commentary, or keys outside the requested JSON.
- Do not create Spelling corrections for accents or Spanish characters that are already present in the submitted text.

Category rules:
- Grammar: grammatical structure, verb conjugation, agreement, tense, pronoun use, preposition use, and punctuation.
- Natural Language: phrasing that is technically understandable but unnatural, awkward, overly literal, or not how a native speaker would normally write it.
- Spelling: misspellings, missing or incorrect written accents/diacritics, and orthographic errors.
- Word Choice: incorrect or suboptimal vocabulary choice where grammar and spelling are otherwise acceptable.
- Other: only use this for genuine edge cases that do not fit the categories above.

Punctuation handling:
- Always inspect punctuation separately, even if the sentence has other errors.
- Missing or incorrect Spanish opening question marks (¿), closing question marks (?), opening exclamation marks (¡), closing exclamation marks (!), commas, periods, colons, semicolons, or quotation marks are Grammar.
- Examples:
  - "Como estas?" -> "¿Cómo estás?" includes Grammar for missing opening question mark and Spelling for missing accents.
  - "Que bonito!" -> "¡Qué bonito!" includes Grammar for missing opening exclamation mark and Spelling for missing accent.
  - "Hola como estas" -> "Hola, ¿cómo estás?" includes Grammar for missing comma/question punctuation and Spelling for missing accents.

Important category boundaries:
- Missing accents are Spelling, not Grammar.
- Incorrect prepositions are Grammar.
- Punctuation is Grammar, not Other.
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

const _structuredExplanationSystemInstruction = '''
You explain Spanish corrections to learners.

Return only valid JSON with this exact shape:
{
  "why_its_wrong": "string",
  "in_context": "string",
  "alternatives": ["string"]
}

Rules:
- why_its_wrong explains why the original phrase is incorrect or unnatural.
- in_context gives one corrected example sentence using the corrected phrase naturally.
- alternatives contains one to three alternative phrasings. Use an empty array if there are no useful alternatives.
- Keep every field concise and learner-friendly.
- Do not include Markdown, code fences, commentary, or keys outside the requested JSON.
''';
