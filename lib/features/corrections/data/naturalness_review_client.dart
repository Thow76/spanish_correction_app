import 'dart:convert';

import '../../../core/services/prompts/correction_prompt.dart';
import '../domain/naturalness_review.dart';
import 'openai_chat_completions_client.dart';

/// Builds the naturalness pass's user message: the text to review, in the
/// same shape `buildNaturalnessUserPrompt` in
/// `test/naturalness_model_comparison_harness.dart` already validated.
String buildNaturalnessUserContent(String text) {
  return 'Review this Spanish text for naturalness only.\n'
      '\n'
      'Text:\n'
      '$text';
}

/// Calls the naturalness review pass (`naturalnessReviewSpanish`) against
/// [text] and parses the reply into a [NaturalnessReview].
///
/// Uses the same shared transport ([OpenAiChatCompletionsClient.complete])
/// and prompt-only JSON contract as every other stage client in this
/// pipeline — no `response_format`; the model is asked for JSON via the
/// prompt text itself, same as Stage 1/1B/1C/2/3.
Future<NaturalnessReview> callNaturalnessReview({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String text,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: naturalnessReviewSpanish,
    userText: buildNaturalnessUserContent(text),
    stageLabel: 'naturalness_review',
  );
  return parseNaturalnessReviewResponse(replyText);
}

/// Parses a naturalness-pass reply into a [NaturalnessReview].
///
/// Tolerates the model wrapping the JSON object in Markdown code fences or
/// trailing commentary by extracting the substring between the first `{`
/// and the last `}` before decoding, same defensive approach as every
/// other stage parser in this pipeline (e.g.
/// `OpenAiCorrectionService._extractJsonObject`). Throws a
/// [FormatException] when no object is found or the reply doesn't decode
/// to one, and propagates whatever [FormatException]
/// [NaturalnessReview.fromJson] itself throws for a malformed contract.
NaturalnessReview parseNaturalnessReviewResponse(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException(
      'No JSON object found in naturalness review reply.',
    );
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'Naturalness review reply did not decode to an object.',
    );
  }

  return NaturalnessReview.fromJson(decoded);
}
