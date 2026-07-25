import 'dart:convert';

import '../../../core/services/prompts/correction_prompt.dart';
import 'openai_chat_completions_client.dart';

/// Calls one Stage 1 detection-shaped prompt — `stage1DetectionDialectSpanish`
/// (general detection), `stage1RedundancyDetectionSpanish` (Stage 1B, the
/// dedicated redundant-pronoun pass), or `stage1ReflexiveDetectionSpanish`
/// (Stage 1C, the dedicated missing-reflexive pass) — and parses its reply
/// into the flagged-phrase list. All three prompts instruct the model to
/// return a bare JSON array of quoted phrases and differ only in what they
/// look for, so one function serves all of them rather than several
/// near-duplicates.
Future<List<String>> callStage1Detection({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String systemPrompt,
  required String submittedText,
  String stageLabel = 'unspecified',
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: systemPrompt,
    userText: submittedText,
    stageLabel: stageLabel,
  );
  return parseStage1DetectionArray(replyText);
}

/// Runs Stage 1, Stage 1B, and Stage 1C against [submittedText] concurrently
/// and merges their flagged-phrase lists.
///
/// Merging is simple concatenation — Stage 2 examines each flagged phrase
/// independently against the full text, so neither the merge order nor any
/// overlap between the lists needs to be resolved here. Overlap between what
/// the three passes flag is resolved later, after all three passes' output
/// has been through Stage 2 and positioned (see the dedup step of the staged
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
      stageLabel: 'stage1_dialect',
    ),
    callStage1Detection(
      client: client,
      model: model,
      systemPrompt: stage1RedundancyDetectionSpanish,
      submittedText: submittedText,
      stageLabel: 'stage1b_redundancy',
    ),
    callStage1Detection(
      client: client,
      model: model,
      systemPrompt: stage1ReflexiveDetectionSpanish,
      submittedText: submittedText,
      stageLabel: 'stage1c_reflexive',
    ),
  ]);

  return mergeStage1FlaggedPhrases(
    stage1DetectionFlagged: results[0],
    stage1RedundancyFlagged: results[1],
    stage1ReflexiveFlagged: results[2],
  );
}

/// Concatenates Stage 1's, Stage 1B's, and Stage 1C's flagged-phrase lists,
/// in that order, then drops exact-string duplicates (keeping each phrase's
/// first occurrence) — a phrase more than one pass flags is billed to Stage 2
/// only once. This is distinct from the *positional* overlap resolved later
/// in the pipeline (`resolveOverlappingCandidates`), which dedupes candidates
/// whose resolved spans overlap even when the flagged text differed; this
/// step only collapses identical strings before Stage 2 ever sees them, so
/// Stage 2 isn't asked (and billed) to categorize the same exact phrase
/// twice. Safe because Stage 2 resolves how many real occurrences of a
/// phrase need correcting by searching the full text itself (its `occurrence`
/// field), not by counting how many times a phrase appears in this input
/// list — see `stage2CategorizationSpanish` in `correction_prompt.dart`.
List<String> mergeStage1FlaggedPhrases({
  required List<String> stage1DetectionFlagged,
  required List<String> stage1RedundancyFlagged,
  required List<String> stage1ReflexiveFlagged,
}) {
  return {
    ...stage1DetectionFlagged,
    ...stage1RedundancyFlagged,
    ...stage1ReflexiveFlagged,
  }.toList();
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
