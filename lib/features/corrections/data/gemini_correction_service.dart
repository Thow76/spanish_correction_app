import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../application/correction_service.dart';
import '../application/correction_service_exception.dart';
import '../application/correction_response_schema.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';
import '../../saved/domain/saved_explanation.dart';

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

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
  ) async {
    _ensureConfigured();

    final responseText = await _generateContent(
      systemInstruction: _structuredExplanationSystemInstruction,
      userText:
          '''
Original phrase: ${correction.originalPhrase}
Corrected phrase: ${correction.correctedPhrase}
Category: ${correction.category.label}
Short explanation: ${correction.shortExplanation}
''',
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
        'Gemini returned an invalid structured explanation: $error',
      );
    }
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

final _correctionSystemInstruction =
    '''
You are a Spanish correction engine for a mobile language-learning app.

Return only valid JSON with this exact shape:
$correctionResponseJsonShape

Rules:
- Preserve the user's original text in original_text.
- corrected_text must contain a polished corrected version of the whole text.
- Each correction must identify the text being corrected with start_index, end_index, and original_phrase.
- original_phrase must be the exact substring of the submitted text between start_index and end_index, copied character-for-character including accents, ñ, and Spanish punctuation.
- For zero-length insertion ranges, original_phrase must be an empty string.
- Before returning each correction, verify that original_phrase matches the slice your indexes point to; if it does not, fix the indexes so they do. The app rejects any correction where they disagree.
- start_index is zero-based and inclusive.
- end_index is zero-based and exclusive.
- For missing punctuation or any other inserted text, use an empty range where start_index equals end_index at the insertion point.
- Insertion points must fall on a word boundary (start of text, end of text, or next to whitespace or punctuation). Never insert in the middle of a word.
- Do not replace a neighboring character just to add missing punctuation.
- Indexes must refer only to the submitted Spanish text, not the instruction text or labels.
- Indexes are measured in user-perceived characters, not bytes.
- Accented letters, ñ, inverted punctuation, emoji, and combining-accent sequences each count as one user-perceived character.
- category must be exactly one of: Grammar, Natural Language, Spelling, Word Choice, Other.
- short_explanation must be one informal but technically accurate sentence.
- If there are no corrections, return an empty corrections array and keep corrected_text equal to original_text.
- Do not include Markdown, code fences, commentary, or keys outside the requested JSON.
- Do not create Spelling corrections for accents or Spanish characters that are already present in the submitted text.

Category rules:
- Grammar: grammatical structure, verb conjugation, agreement, tense, pronoun use, preposition use, and punctuation.
- Natural Language: phrasing that is technically understandable but unnatural, awkward, overly literal, an anglicism or false friend, or not how a native speaker would normally write it. Flag these actively, even when the meaning is clear — naturalness is one of the main things learners need to learn.
- Spelling: misspellings, missing or incorrect written accents/diacritics, and orthographic errors.
- Word Choice: incorrect or suboptimal vocabulary choice where grammar and spelling are otherwise acceptable.
- Other: only use this for genuine edge cases that do not fit the categories above.

Natural language handling:
- Actively look for phrasing that is technically valid Spanish but not how a native speaker would express the idea. Do not skip these because the meaning is understandable.
- Flag anglicisms and false friends where Spanish prefers a different word (e.g. "memorias" used to mean "memories" should be "recuerdos"; "realizar" used to mean "to notice" should be "darse cuenta"; "atender" used to mean "to attend a class" should be "asistir").
- Flag overly literal English-style constructions where Spanish phrases the idea differently (e.g. "una juventud con la naturaleza alrededor" -> "una infancia rodeada de naturaleza"; "tomar una decisión sobre" -> "decidir sobre").
- Flag awkward circumlocutions when a single idiomatic word or expression exists.
- When a word does not make sense in context but a phonetically similar word would (likely a speech-to-text or typing slip, e.g. "fruta y colas así" -> "fruta y cosas así"), correct it as Natural Language and note in short_explanation that the original looks like a transcription slip.

Punctuation handling:
- Always inspect punctuation separately, even if the sentence has other errors.
- Missing or incorrect Spanish opening question marks (¿), closing question marks (?), opening exclamation marks (¡), closing exclamation marks (!), commas, periods, colons, semicolons, or quotation marks are Grammar.
- Insertion points for punctuation must sit on a word boundary. Opening marks like "¿" and "¡" go before a word; closing marks like "?", "!", ",", ".", ";", and ":" go immediately after a word, never inside one.
- Examples:
  - "Como estas?" -> "¿Cómo estás?" includes Grammar insertion of "¿" at start_index 0, end_index 0, original_phrase "" and Spelling edits for missing accents.
  - "Que bonito!" -> "¡Qué bonito!" includes Grammar insertion of "¡" at start_index 0, end_index 0, original_phrase "" and Spelling edit for missing accent.
  - "Hola como estas" -> "Hola, ¿cómo estás?" includes Grammar insertions for comma/question punctuation and Spelling edits for missing accents.

Important category boundaries:
- Missing accents are Spelling, not Grammar.
- Incorrect prepositions are Grammar.
- Punctuation is Grammar, not Other.
- Anglicisms, false friends, and overly literal English-style constructions are Natural Language, not Word Choice. Use Word Choice only when the user picked a real Spanish synonym that is grammatical and idiomatic but slightly suboptimal in register or precision.
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
