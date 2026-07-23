import 'dart:convert';

import '../../../core/services/prompts/correction_prompt.dart';
import '../domain/staged_correction_candidate.dart';
import '../domain/staged_correction_span_scope.dart';
import '../domain/staged_correction_verdict.dart';
import 'openai_chat_completions_client.dart';

/// Calls Stage 2 (`stage2CategorizationSpanish`) with the learner's full
/// text and the flagged phrases Stage 1/1B produced, and parses the reply
/// into one [StagedCorrectionCandidate] per flagged phrase.
Future<List<StagedCorrectionCandidate>> callStage2Categorization({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String fullText,
  required List<String> flaggedPhrases,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: stage2CategorizationSpanish,
    userText: buildStage2UserContent(
      fullText: fullText,
      flaggedPhrases: flaggedPhrases,
    ),
  );
  return parseStage2CategorizationArray(replyText);
}

/// Builds Stage 2's user message: the learner's full text plus the flagged
/// phrases Stage 1/1B produced, as a JSON array.
String buildStage2UserContent({
  required String fullText,
  required List<String> flaggedPhrases,
}) {
  return '''
Learner's text:
$fullText

Flagged phrases:
${jsonEncode(flaggedPhrases)}
''';
}

/// The three verdict strings Stage 2 is allowed to return — anything else
/// is a sign of prompt drift and is surfaced as a [FormatException] rather
/// than silently dropped or miscategorized.
const Set<String> _validVerdicts = {'error', 'dialectal', 'not_an_error'};

/// Parses a Stage 2 reply into one [StagedCorrectionCandidate] per returned
/// object.
///
/// Tolerates the model wrapping the array in Markdown code fences or
/// trailing commentary by extracting the substring between the first `[`
/// and the last `]` before decoding, same defensive approach as
/// `parseStage1DetectionArray`. Throws a [FormatException] on anything that
/// doesn't match the expected object shape once extracted — including an
/// unrecognized `verdict` value or an unrecognized (non-null) `span_scope`
/// value. `span_scope` itself is otherwise optional in the reply — a
/// missing key parses to a null [StagedCorrectionCandidate.spanScope],
/// same as a missing `category`; this parser does not enforce the prompt's
/// own "only for Natural Language" instruction to the model.
///
/// Ported from `test/stage2_categorization_harness.dart`'s
/// `_parseCategorizationArray`, which already validated this shape
/// independently.
List<StagedCorrectionCandidate> parseStage2CategorizationArray(
  String replyText,
) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 2 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException(
      'Stage 2 reply array did not decode to a List.',
    );
  }

  return decoded.map((element) {
    if (element is! Map<String, Object?>) {
      throw FormatException(
        'Stage 2 reply array contained a non-object element: $element',
      );
    }

    final originalPhrase = element['original_phrase'];
    final correctedPhrase = element['corrected_phrase'];
    final occurrence = element['occurrence'];
    final category = element['category'];
    final verdictValue = element['verdict'];
    final spanScopeValue = element['span_scope'];

    if (originalPhrase is! String || originalPhrase.isEmpty) {
      throw FormatException(
        'Stage 2 result missing/invalid original_phrase: $element',
      );
    }
    if (correctedPhrase is! String) {
      throw FormatException(
        'Stage 2 result missing/invalid corrected_phrase: $element',
      );
    }
    if (occurrence is! num || occurrence != occurrence.roundToDouble()) {
      throw FormatException(
        'Stage 2 result missing/invalid occurrence: $element',
      );
    }
    if (category != null && category is! String) {
      throw FormatException(
        'Stage 2 result has a non-string category: $element',
      );
    }
    if (verdictValue is! String || !_validVerdicts.contains(verdictValue)) {
      throw FormatException(
        'Stage 2 result has an invalid verdict: $element',
      );
    }
    StagedCorrectionSpanScope? spanScope;
    if (spanScopeValue != null) {
      if (spanScopeValue is! String) {
        throw FormatException(
          'Stage 2 result has a non-string span_scope: $element',
        );
      }
      spanScope = StagedCorrectionSpanScope.fromApiValue(spanScopeValue);
      if (spanScope == null) {
        throw FormatException(
          'Stage 2 result has an invalid span_scope: $element',
        );
      }
    }

    return StagedCorrectionCandidate(
      originalPhrase: originalPhrase,
      correctedPhrase: correctedPhrase,
      occurrence: occurrence.round(),
      category: category as String?,
      verdict: StagedCorrectionVerdict.fromApiValue(verdictValue)!,
      spanScope: spanScope,
    );
  }).toList();
}
