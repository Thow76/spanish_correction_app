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

    final responseText = await _createResponse(
      systemInstruction: _correctionSystemInstruction,
      userText: 'Review this Spanish text:\n\n$text',
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
  Future<String> generateLongExplanation(CorrectionItem correction) {
    _ensureConfigured();

    return _createResponse(
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

    final responseText = await _createResponse(
      systemInstruction: _structuredExplanationSystemInstruction,
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
- The threshold for a Natural Language flag is: would a native speaker find this phrasing unnatural, jarring, or foreign-sounding? Not: is there a more polished or concise alternative? If the phrasing is something a native speaker would say without hesitation, do not flag it.
- Flag anglicisms and false friends where Spanish strongly prefers a different word (e.g. "memorias" used to mean "memories" should be "recuerdos"; "realizar" used to mean "to notice" should be "darse cuenta"; "atender" used to mean "to attend a class" should be "asistir").
- Flag overly literal English-style constructions that a native speaker would not use (e.g. "una juventud con la naturaleza alrededor" → "una infancia rodeada de naturaleza"; "hice un error" → "cometí un error").
- Flag awkward circumlocutions when a single idiomatic word or expression exists and the original would sound odd to a native speaker.
- When a word does not make sense in context but a phonetically similar word would (likely a speech-to-text or typing slip, e.g. "fruta y colas así" → "fruta y cosas así"), correct it as Natural Language and note in short_explanation that the original looks like a transcription slip.
- Do not flag colloquial but established Spanish expressions just because a more formal equivalent exists (e.g. "finde" for "fin de semana" is natural colloquial Spanish — do not expand it).
- Do not flag a construction simply because a shorter or terser version exists (e.g. "por causa de" is correct and natural — do not flag it just because "por" alone would also work).
- Do not flag possessives or other grammatically correct additions just because omitting them is also valid (e.g. "volver a mi casa" is natural — do not flag it as less idiomatic than "volver a casa").

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
