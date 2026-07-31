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

/// The exact JSON shape `parseNaturalnessReviewResponse`/
/// `NaturalnessReview.fromJson` require, sent as `response_format` so the
/// API constrains the model's own output to it — copied by value from
/// `naturalnessResponseFormat` in
/// `test/naturalness_model_comparison_harness.dart` (issue #41), which
/// already validated this exact schema live.
///
/// Required: unlike Stage 1/1B/1C/2/3's prompts, `naturalnessReviewSpanish`
/// never states its required field names anywhere in its own text — it
/// only says "Return JSON only." Confirmed live (issue #42's integration
/// harness, `docs/two_pass_integration_harness_summary.md`): without this
/// schema constraining the response, gpt-5.1 reliably invents its own
/// differently-shaped JSON instead (observed:
/// `{"issues":[{"original":..., "suggestions":[...], "explanation":...}]}`,
/// missing `has_naturalness_issue` entirely) — every one of 5 live test
/// fixtures failed to parse without this, reproduced twice.
const Map<String, Object?> naturalnessReviewResponseFormat = {
  'type': 'json_schema',
  'json_schema': {
    'name': 'spanish_naturalness_response',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['has_naturalness_issue', 'issues'],
      'properties': {
        'has_naturalness_issue': {'type': 'boolean'},
        'issues': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['span', 'natural_replacement', 'explanation'],
            'properties': {
              'span': {'type': 'string'},
              'natural_replacement': {'type': 'string'},
              'explanation': {'type': 'string'},
            },
          },
        },
      },
    },
  },
};

/// Calls the naturalness review pass (`naturalnessReviewSpanish`) against
/// [text] and parses the reply into a [NaturalnessReview].
///
/// Uses the same shared transport ([OpenAiChatCompletionsClient.complete])
/// as every other stage client in this pipeline, but — unlike Stage
/// 1/1B/1C/2/3 — also sends [naturalnessReviewResponseFormat] as
/// `response_format`, so the API itself constrains the model's output to
/// the required shape rather than relying solely on the prompt's own
/// wording. See that constant's doc comment for why this one call needs
/// it when the others don't.
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
    responseFormat: naturalnessReviewResponseFormat,
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
