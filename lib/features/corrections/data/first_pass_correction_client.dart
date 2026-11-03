import 'dart:convert';

import '../../../core/services/prompts/correction_prompt.dart';
import '../domain/correction_response.dart';
import 'openai_chat_completions_client.dart';

/// Calls the narrow first-pass correction prompt
/// (`firstPassCorrectionSpanish`, issue #64) against [submittedText] and
/// parses the reply into a [CorrectionResponse].
///
/// POC scope (issue #65): the narrow contract is `{"corrected_text":
/// "string"}` only — no positions, categories, or explanations — so the
/// returned [CorrectionResponse] always has an empty `corrections` list.
/// Deriving first-pass highlights or explanations from this contract is
/// explicitly out of scope here; this POC is measuring final text
/// quality, reliability, latency, fallback rate, token use, and cost, not
/// per-correction UI data. See `docs/first_pass_correction_poc_scope.md`
/// (issue #71) for the full POC boundary and success criteria — an empty
/// `corrections` list here is expected, not an accidental omission.
///
/// Uses [firstPassCorrectionResponseFormat] as `response_format`, same
/// reasoning as `callNaturalnessReview`'s own use of `response_format`
/// (issue #42/#63): prompt-only JSON compliance was confirmed unreliable
/// live for the naturalness pass, and nothing about that risk is specific
/// to that prompt — this call gets the same protection from the start
/// rather than repeating that discovery.
Future<CorrectionResponse> callFirstPassCorrection({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String submittedText,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: firstPassCorrectionSpanish,
    userText: buildFirstPassCorrectionUserContent(submittedText),
    stageLabel: 'first_pass_correction',
    responseFormat: firstPassCorrectionResponseFormat,
  );
  final correctedText = parseFirstPassCorrectionResponse(replyText);

  return CorrectionResponse(
    originalText: submittedText,
    correctedText: correctedText,
    corrections: const [],
  );
}

/// Parses a first-pass reply into its `corrected_text` string.
///
/// Tolerates the model wrapping the JSON object in Markdown code fences or
/// trailing commentary by extracting the substring between the first `{`
/// and the last `}` before decoding, same defensive approach as every
/// other stage parser in this pipeline (e.g.
/// `parseNaturalnessReviewResponse`). Throws a [FormatException] when no
/// object is found, the reply doesn't decode to one, or `corrected_text`
/// is missing or not a string.
String parseFirstPassCorrectionResponse(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException(
      'No JSON object found in first-pass correction reply.',
    );
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'First-pass correction reply did not decode to an object.',
    );
  }

  final correctedText = decoded['corrected_text'];
  if (correctedText is! String) {
    throw const FormatException(
      'First-pass correction reply is missing "corrected_text".',
    );
  }

  return correctedText;
}
