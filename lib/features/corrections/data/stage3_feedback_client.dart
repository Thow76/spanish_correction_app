import 'dart:convert';

import '../../../core/services/prompts/correction_prompt.dart';
import '../domain/correction_item.dart';
import '../domain/correction_note.dart';
import '../domain/staged_correction_candidate.dart';
import '../domain/staged_correction_verdict.dart';
import 'openai_chat_completions_client.dart';

/// The final result of Stage 3's explanation pass: `error` items with a
/// real `shortExplanation` in place of Step 7's placeholder, and finished
/// [CorrectionNote]s for whichever `dialectal` candidates got an
/// explanation.
///
/// An item or candidate Stage 3 didn't return a matching explanation for is
/// dropped from its bucket entirely — the same silent-drop precedent used
/// throughout this pipeline (an unresolved position isn't something the app
/// can safely act on) rather than surfacing it with a missing/placeholder
/// explanation.
class StagedCorrectionExplanations {
  const StagedCorrectionExplanations({
    required this.errorItems,
    required this.notes,
  });

  final List<CorrectionItem> errorItems;
  final List<CorrectionNote> notes;
}

/// Calls Stage 3 (`stage3FeedbackSpanish`) for both `error` items and
/// `dialectal` candidates — Stage 3's verdict-branching already produces the
/// right tone for both, so this is never scoped to error-only — and parses
/// the reply into one [Stage3ExplanationResult] per returned object.
Future<List<Stage3ExplanationResult>> callStage3Feedback({
  required OpenAiChatCompletionsClient client,
  required String model,
  required List<CorrectionItem> errorItems,
  required List<StagedCorrectionCandidate> dialectalCandidates,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: stage3FeedbackSpanish,
    userText: buildStage3UserContent(
      errorItems: errorItems,
      dialectalCandidates: dialectalCandidates,
    ),
  );
  return parseStage3ExplanationArray(replyText);
}

/// Builds Stage 3's user message: a JSON array with one object per `error`
/// item and `dialectal` candidate, each carrying `start_index` (assigned by
/// the app, per Stage 3's own prompt contract), `original_phrase`,
/// `corrected_phrase`, `category`, and `verdict` — the shape
/// `test/stage3_feedback_harness.dart`'s `_buildStage3UserContent` already
/// validated independently.
///
/// A `dialectal` candidate's `category` is sent as `'Other'` if it's null:
/// Stage 2's own prompt guarantees dialectal candidates always get category
/// `Other`, so a null here only means Stage 2 didn't fully comply — sending
/// the value the spec guarantees is a reasonable default rather than
/// dropping an otherwise-valid candidate over it.
String buildStage3UserContent({
  required List<CorrectionItem> errorItems,
  required List<StagedCorrectionCandidate> dialectalCandidates,
}) {
  final entries = [
    for (final item in errorItems)
      {
        'start_index': item.startIndex,
        'original_phrase': item.originalPhrase,
        'corrected_phrase': item.correctedPhrase,
        'category': item.category.label,
        'verdict': StagedCorrectionVerdict.error.apiValue,
      },
    for (final candidate in dialectalCandidates)
      {
        'start_index': candidate.startIndex,
        'original_phrase': candidate.originalPhrase,
        'corrected_phrase': candidate.correctedPhrase,
        'category': candidate.category ?? 'Other',
        'verdict': StagedCorrectionVerdict.dialectal.apiValue,
      },
  ];
  return jsonEncode(entries);
}

/// One correction's explanation, as returned by Stage 3.
class Stage3ExplanationResult {
  const Stage3ExplanationResult({
    required this.startIndex,
    required this.shortExplanation,
  });

  final int startIndex;
  final String shortExplanation;
}

/// Parses a Stage 3 reply into one [Stage3ExplanationResult] per returned
/// object.
///
/// Tolerates the model wrapping the array in Markdown code fences or
/// trailing commentary, same defensive approach as the other stages'
/// parsers. Throws a [FormatException] on anything that doesn't match the
/// expected object shape once extracted.
///
/// Ported from `test/stage3_feedback_harness.dart`'s
/// `_parseExplanationArray`, which already validated this shape
/// independently.
List<Stage3ExplanationResult> parseStage3ExplanationArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 3 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException(
      'Stage 3 reply array did not decode to a List.',
    );
  }

  return decoded.map((element) {
    if (element is! Map<String, Object?>) {
      throw FormatException(
        'Stage 3 reply array contained a non-object element: $element',
      );
    }

    final startIndex = element['start_index'];
    final shortExplanation = element['short_explanation'];

    if (startIndex is! num || startIndex != startIndex.roundToDouble()) {
      throw FormatException(
        'Stage 3 result missing/invalid start_index: $element',
      );
    }
    if (shortExplanation is! String || shortExplanation.trim().isEmpty) {
      throw FormatException(
        'Stage 3 result missing/invalid short_explanation: $element',
      );
    }

    return Stage3ExplanationResult(
      startIndex: startIndex.round(),
      shortExplanation: shortExplanation.trim(),
    );
  }).toList();
}

/// Joins Stage 3's parsed explanations back onto [errorItems] and
/// [dialectalCandidates] by `start_index`. After Step 6's dedup, no two
/// candidates share a `start_index`, so this join is unambiguous.
///
/// `error` items get a new [CorrectionItem] with the placeholder
/// `shortExplanation` from Step 7 replaced by the real one (`CorrectionItem`
/// has no `copyWith`, so this reconstructs the item — the same pattern
/// `correction_corrected_range_calculator.dart` already uses). `dialectal`
/// candidates finally become [CorrectionNote]s here, now that the one field
/// they were missing (`note`) is available.
StagedCorrectionExplanations joinStage3Explanations({
  required List<CorrectionItem> errorItems,
  required List<StagedCorrectionCandidate> dialectalCandidates,
  required List<Stage3ExplanationResult> explanations,
}) {
  final explanationByStartIndex = <int, String>{
    for (final explanation in explanations)
      explanation.startIndex: explanation.shortExplanation,
  };

  final explainedErrorItems = <CorrectionItem>[];
  for (final item in errorItems) {
    final explanation = explanationByStartIndex[item.startIndex];
    if (explanation == null) {
      continue;
    }
    explainedErrorItems.add(
      CorrectionItem(
        originalPhrase: item.originalPhrase,
        correctedPhrase: item.correctedPhrase,
        category: item.category,
        shortExplanation: explanation,
        startIndex: item.startIndex,
        endIndex: item.endIndex,
        correctedStartIndex: item.correctedStartIndex,
        correctedEndIndex: item.correctedEndIndex,
      ),
    );
  }

  final notes = <CorrectionNote>[];
  for (final candidate in dialectalCandidates) {
    final explanation = explanationByStartIndex[candidate.startIndex];
    if (explanation == null) {
      continue;
    }
    notes.add(
      CorrectionNote(phrase: candidate.originalPhrase, note: explanation),
    );
  }

  return StagedCorrectionExplanations(
    errorItems: explainedErrorItems,
    notes: notes,
  );
}
