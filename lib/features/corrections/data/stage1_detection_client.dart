import 'dart:convert';

import '../../../core/services/prompts/correction_prompt.dart';
import 'openai_chat_completions_client.dart';

/// Calls one Stage 1 detection-shaped prompt — either
/// `stage1DetectionDialectSpanish` (general detection) or
/// `stage1RedundancyDetectionSpanish` (Stage 1B, the dedicated redundant-
/// pronoun pass) — and parses its reply into the flagged-phrase list. Both
/// prompts instruct the model to return a bare JSON array of quoted phrases
/// and differ only in what they look for, so one function serves both
/// rather than two near-duplicates.
Future<List<String>> callStage1Detection({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String systemPrompt,
  required String submittedText,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: systemPrompt,
    userText: submittedText,
  );
  return parseStage1DetectionArray(replyText);
}

/// Runs Stage 1 and Stage 1B against [submittedText] concurrently and
/// merges their flagged-phrase lists.
///
/// Merging is simple concatenation — Stage 2 examines each flagged phrase
/// independently against the full text, so neither the merge order nor any
/// overlap between the two lists needs to be resolved here. Overlap between
/// what the two stages flag is resolved later, after both stages' output has
/// been through Stage 2 and positioned (see the dedup step of the staged
/// pipeline), not at merge time.
Future<List<String>> callStage1AndMergeFlaggedPhrases({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String submittedText,
}) async {
  final results = await Future.wait([
    callStage1Detection(
      client: client,
      model: model,
      systemPrompt: stage1DetectionDialectSpanish,
      submittedText: submittedText,
    ),
    callStage1Detection(
      client: client,
      model: model,
      systemPrompt: stage1RedundancyDetectionSpanish,
      submittedText: submittedText,
    ),
  ]);

  return mergeStage1FlaggedPhrases(
    stage1DetectionFlagged: results[0],
    stage1RedundancyFlagged: results[1],
  );
}

/// Concatenates Stage 1's and Stage 1B's flagged-phrase lists, Stage 1's
/// phrases first. Pure and order-preserving; duplicates (a phrase both
/// stages happen to flag) are left as-is — deduping is a later pipeline
/// concern, not this function's.
List<String> mergeStage1FlaggedPhrases({
  required List<String> stage1DetectionFlagged,
  required List<String> stage1RedundancyFlagged,
}) {
  return [...stage1DetectionFlagged, ...stage1RedundancyFlagged];
}

/// Parses a Stage 1-shaped reply — a JSON array of quoted flagged phrases —
/// tolerating the model wrapping it in Markdown fences or trailing
/// commentary by extracting the substring between the first `[` and the
/// last `]` before decoding. Throws a [FormatException] on anything that
/// doesn't match the expected shape once extracted.
///
/// Ported from the array-of-quoted-strings parser every Stage 1 harness
/// (`test/stage1_detection_dialect_harness.dart`,
/// `test/stage1_redundancy_pass_harness.dart`) already validated
/// independently.
List<String> parseStage1DetectionArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 1 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException(
      'Stage 1 reply array did not decode to a List.',
    );
  }

  return decoded.map((element) {
    if (element is! String) {
      throw FormatException(
        'Stage 1 reply array contained a non-string element: $element',
      );
    }
    return element;
  }).toList();
}
