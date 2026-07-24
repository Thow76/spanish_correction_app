import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../enums/language.dart';
import '../models/walkthrough_exceptions.dart';
import '../models/walkthrough_question.dart';
import '../text/phrase_chunker.dart';
import '../../features/corrections/domain/correction_item.dart';
import 'prompt_builder.dart';

/// Generates the multiple-choice walkthrough questions for a wrong translation.
///
/// Mirrors [OpenAiCorrectionService]: same OpenAI `/v1/responses` stack, same
/// constructor shape (`apiKey` / `model` / injectable [HttpClient]), and the
/// same two-phase split — [_createResponse] owns the transport and surfaces
/// transport failures as [WalkthroughApiException]; [fetchQuestions] owns the
/// content schema and surfaces parse/schema failures as
/// [WalkthroughSchemaException].
///
/// The target sentence's chunks are computed mechanically by [chunkSentence]
/// before the prompt is ever built — the model is never asked to decompose the
/// sentence or echo a "correct" chunk back, only to write an english_stem and
/// two distractors per (already-correct) chunk. That removes the sentence
/// -reconstruction failure mode entirely: since a chunk's text always comes
/// from [chunkSentence], concatenating them trivially reproduces the sentence
/// and there is nothing to validate or retry on that front.
class WalkthroughService {
  WalkthroughService({
    required String apiKey,
    required String model,
    HttpClient? httpClient,
  }) : _apiKey = apiKey.trim(),
       _model = model.trim(),
       _httpClient = httpClient ?? HttpClient();

  final String _apiKey;
  final String _model;
  final HttpClient _httpClient;

  Future<List<WalkthroughQuestion>> fetchQuestions({
    required String targetSentence,
    required String userAttempt,
    required String englishSource,
    required List<CorrectionItem> corrections,
    required Language language,
  }) async {
    _ensureConfigured();

    // Chunking is mechanical and deterministic (no LLM, no retry needed on its
    // own account) — computed once up front and reused across both attempts
    // below, rather than redone per attempt.
    final chunks = chunkSentence(targetSentence, language);
    if (chunks.isEmpty) {
      throw const WalkthroughSchemaException(
        'No chunks could be derived from the target sentence.',
      );
    }

    // Schema and validation failures are intermittent: retry the whole fetch
    // -> parse -> validate pipeline ONCE, which catches most of them. If the
    // retry also fails, its exception surfaces — so at most two API calls per
    // fetchQuestions, no loop and no backoff. The whole response is
    // re-fetched; individual questions are never re-rolled or repaired.
    //
    // WalkthroughApiException is deliberately NOT retried here: transport retry
    // (if any) belongs to the shared API layer, and is not doubled on top.
    Future<List<WalkthroughQuestion>> attempt() => _fetchOnce(
      targetSentence: targetSentence,
      chunks: chunks,
      userAttempt: userAttempt,
      englishSource: englishSource,
      corrections: corrections,
      language: language,
    );

    try {
      return await attempt();
    } on WalkthroughSchemaException {
      return await attempt();
    } on WalkthroughValidationException {
      return await attempt();
    }
  }

  /// One full attempt: build the prompt, call the API, parse, then validate.
  ///
  /// Stages run in order: transport (WalkthroughApiException, in
  /// [_createResponse]) -> parse/schema (WalkthroughSchemaException, in
  /// [_parseQuestions]) -> validate (WalkthroughValidationException, in
  /// [_validateQuestions]).
  Future<List<WalkthroughQuestion>> _fetchOnce({
    required String targetSentence,
    required List<String> chunks,
    required String userAttempt,
    required String englishSource,
    required List<CorrectionItem> corrections,
    required Language language,
  }) async {
    final responseText = await _createResponse(
      systemInstruction: _buildPrompt(
        targetSentence: targetSentence,
        chunks: chunks,
        userAttempt: userAttempt,
        englishSource: englishSource,
        corrections: corrections,
        language: language,
      ),
      userText: 'Produce the walkthrough question JSON for the inputs above.',
    );

    final questions = _parseQuestions(responseText, chunks);
    _validateQuestions(questions);
    return questions;
  }

  /// Substitutes the prompt inputs into the language's walkthrough template.
  /// [chunks] (already computed by [chunkSentence]) is passed as a JSON array
  /// so the model annotates them rather than inventing its own decomposition.
  String _buildPrompt({
    required String targetSentence,
    required List<String> chunks,
    required String userAttempt,
    required String englishSource,
    required List<CorrectionItem> corrections,
    required Language language,
  }) {
    return PromptBuilder.walkthroughQuestionPromptTemplate(language)
        .replaceAll('{{targetSentence}}', targetSentence)
        .replaceAll('{{chunks}}', jsonEncode(chunks))
        .replaceAll('{{userAttempt}}', userAttempt)
        .replaceAll('{{englishSource}}', englishSource)
        .replaceAll('{{corrections}}', _serialiseCorrections(corrections));
  }

  /// Serialises corrections as the compact JSON array the prompt expects:
  /// `[{original_phrase, corrected_phrase, category, short_explanation}, ...]`.
  static String _serialiseCorrections(List<CorrectionItem> corrections) {
    return jsonEncode([
      for (final c in corrections)
        {
          'original_phrase': c.originalPhrase,
          'corrected_phrase': c.correctedPhrase,
          'category': c.category.label,
          'short_explanation': c.shortExplanation,
        },
    ]);
  }

  /// Parses the response envelope into the list of questions, zipping each
  /// entry with [chunks] by position: the model supplies only `english_stem`
  /// and `distractors` per entry, while `correctTranslation` and
  /// `chunkPosition` come from [chunks] itself, not from the response — the
  /// chunk text is already known and correct before this prompt ever runs.
  /// Every parse/schema failure is surfaced as [WalkthroughSchemaException].
  List<WalkthroughQuestion> _parseQuestions(
    String responseText,
    List<String> chunks,
  ) {
    final Object? decoded;
    try {
      decoded = jsonDecode(_extractJsonObject(responseText));
    } on FormatException catch (error) {
      throw WalkthroughSchemaException(
        'Walkthrough response was not valid JSON: $error',
      );
    }

    if (decoded is! Map<String, Object?>) {
      throw const WalkthroughSchemaException(
        'Walkthrough response root is not an object.',
      );
    }

    final rawQuestions = decoded['questions'];
    if (rawQuestions is! List) {
      throw const WalkthroughSchemaException(
        'Expected questions to be a list.',
      );
    }
    if (rawQuestions.length != chunks.length) {
      throw WalkthroughSchemaException(
        'Expected ${chunks.length} questions (one per chunk), got '
        '${rawQuestions.length}.',
      );
    }

    return [
      for (var i = 0; i < rawQuestions.length; i++)
        _parseOneQuestion(
          rawQuestions[i],
          correctTranslation: chunks[i],
          chunkPosition: i,
        ),
    ];
  }

  /// Parses one `{english_stem, distractors}` entry, pairing it with the
  /// already-known [correctTranslation]/[chunkPosition] for that position.
  WalkthroughQuestion _parseOneQuestion(
    Object? entry, {
    required String correctTranslation,
    required int chunkPosition,
  }) {
    if (entry is! Map<String, Object?>) {
      throw WalkthroughSchemaException(
        'Expected each question to be an object, got ${entry.runtimeType}.',
      );
    }

    final englishStem = entry['english_stem'];
    if (englishStem is! String) {
      throw const WalkthroughSchemaException(
        'Expected english_stem to be a string.',
      );
    }

    return WalkthroughQuestion(
      englishStem: englishStem,
      correctTranslation: correctTranslation,
      distractors: Distractors.fromJson(entry['distractors']),
      chunkPosition: chunkPosition,
    );
  }

  /// Semantic validation run after the schema parse. Rejects the whole
  /// response on the first violation — questions are never dropped or
  /// repaired. Scope is distractor distinctness and the cross-language
  /// disallowlist; chunk identity/position/reconstruction need no validation
  /// here since both come from [chunkSentence], not the model.
  ///
  /// Distinctness compares after whitespace normalisation only (trim + collapse
  /// internal whitespace runs to a single space); comparison is
  /// case-sensitive, since case-differing distractors may be legitimate.
  void _validateQuestions(List<WalkthroughQuestion> questions) {
    for (final question in questions) {
      final correct = _normaliseWhitespace(question.correctTranslation);
      final first = _normaliseWhitespace(question.distractors.first);
      final second = _normaliseWhitespace(question.distractors.second);

      if (first == correct) {
        throw WalkthroughValidationException(
          'Question at chunk_position ${question.chunkPosition}: distractor 1 '
          'equals the chunk text (rule 1).',
        );
      }
      if (second == correct) {
        throw WalkthroughValidationException(
          'Question at chunk_position ${question.chunkPosition}: distractor 2 '
          'equals the chunk text (rule 2).',
        );
      }
      if (first == second) {
        throw WalkthroughValidationException(
          'Question at chunk_position ${question.chunkPosition}: the two '
          'distractors are identical (rule 3).',
        );
      }

      _rejectDisallowlistedDistractor(
        question.chunkPosition,
        question.distractors.first,
      );
      _rejectDisallowlistedDistractor(
        question.chunkPosition,
        question.distractors.second,
      );
    }
  }

  /// Trims and collapses internal whitespace runs to a single space, so
  /// " la casa" and "la  casa" compare equal. Does not change case.
  static String _normaliseWhitespace(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Known bare cross-language leakage words that must never appear as a
  /// distractor. This is a bounded, intentional disallowlist (pass 5c-i) — not
  /// language detection. New entries get added here as failure modes surface.
  ///
  /// Only BARE cross-language words belong here. Portuñol-style hybrids (e.g.
  /// "cojer") are legitimate learner-error distractors and are NOT listed.
  static const Set<String> _crossLanguageDisallowlist = {
    // Italian
    'Domani', 'Oggi', 'Ieri',
    // English
    'Tomorrow', 'Yesterday', 'Today',
    // Spanish (in a Portuguese context)
    'Mañana', 'Ayer', 'Hoy',
  };

  /// The disallowlist normalised for matching: whitespace-collapsed and
  /// lower-cased, so comparison is case-insensitive and whitespace-insensitive.
  static final Set<String> _disallowlistNormalised = {
    for (final entry in _crossLanguageDisallowlist)
      _normaliseWhitespace(entry).toLowerCase(),
  };

  /// Rejects the whole response if [distractor] is a disallowlisted bare
  /// cross-language word. Matching is on the WHOLE normalised value (set
  /// membership / equality), never a substring — a longer phrase that merely
  /// contains a listed word is not rejected.
  void _rejectDisallowlistedDistractor(int chunkPosition, String distractor) {
    final normalised = _normaliseWhitespace(distractor).toLowerCase();
    if (_disallowlistNormalised.contains(normalised)) {
      throw WalkthroughValidationException(
        'Question at chunk_position $chunkPosition: distractor "$distractor" is '
        'a disallowlisted cross-language word.',
      );
    }
  }

  Future<String> _createResponse({
    required String systemInstruction,
    required String userText,
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
          }),
        ),
      );

      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw WalkthroughApiException(
          'Walkthrough request failed with HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('OpenAI response root is not an object.');
      }

      return _extractOutputText(decoded);
    } on SocketException catch (error) {
      throw WalkthroughApiException('No internet available: $error');
    } on TimeoutException catch (error) {
      throw WalkthroughApiException('Walkthrough request timed out: $error');
    } on FormatException catch (error) {
      throw WalkthroughApiException(
        'OpenAI returned an invalid API response: $error',
      );
    }
  }

  void _ensureConfigured() {
    if (_apiKey.isEmpty) {
      throw const WalkthroughApiException('Missing OPENAI_API_KEY.');
    }
    if (_model.isEmpty) {
      throw const WalkthroughApiException('Missing walkthrough model.');
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
}
