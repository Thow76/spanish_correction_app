import 'package:characters/characters.dart';

import '../domain/correction_corrected_range_calculator.dart';
import '../domain/correction_item.dart';
import '../domain/correction_response.dart';
import '../domain/staged_correction_insertion_resolver.dart';
import '../domain/staged_correction_overlap_resolver.dart';
import '../domain/staged_correction_position_resolver.dart';
import '../domain/staged_correction_verdict_splitter.dart';
import 'openai_chat_completions_client.dart';
import 'stage1_detection_client.dart';
import 'stage2_categorization_client.dart';
import 'stage3_feedback_client.dart';

/// Runs the full staged correction pipeline against Spanish text — Stage 1 +
/// Stage 1B detection, Stage 2 categorization, positioning, insertion
/// narrowing, dedup, verdict splitting, and Stage 3 feedback — and returns
/// a finished [CorrectionResponse].
///
/// This is the first place all of those pieces run together; every one of
/// them was already built and tested independently against hand-built
/// fixtures. Spanish-only: the staged prompts (`stage1DetectionDialectSpanish`
/// etc., in `correction_prompt.dart`) only exist for Spanish today — there
/// is no `stage1DetectionDialectPortuguese` or equivalent to call, so this
/// function takes no `language` parameter rather than one that could only
/// ever do one thing.
///
/// Deliberately not part of the `CorrectionService` interface and not
/// called from `correctText()`, `SubmitCorrectionUseCase`, or any live
/// route — wiring the staged pipeline into the app is separate, later work.
Future<CorrectionResponse> runStagedCorrectionPipeline({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String submittedText,
}) async {
  final flaggedPhrases = await callStage1AndMergeFlaggedPhrases(
    client: client,
    model: model,
    submittedText: submittedText,
  );

  if (flaggedPhrases.isEmpty) {
    return CorrectionResponse(
      originalText: submittedText,
      correctedText: submittedText,
      corrections: const [],
    );
  }

  final categorized = await callStage2Categorization(
    client: client,
    model: model,
    fullText: submittedText,
    flaggedPhrases: flaggedPhrases,
  );

  final positioned = resolveCandidatePositions(
    originalText: submittedText,
    candidates: categorized,
  );
  final withSpans = resolveInsertionOffsets(positioned);
  final deduped = resolveOverlappingCandidates(withSpans);
  final split = splitStagedCorrections(deduped);

  if (split.errorItems.isEmpty && split.dialectalCandidates.isEmpty) {
    return CorrectionResponse(
      originalText: submittedText,
      correctedText: submittedText,
      corrections: const [],
    );
  }

  final explanations = await callStage3Feedback(
    client: client,
    model: model,
    errorItems: split.errorItems,
    dialectalCandidates: split.dialectalCandidates,
  );
  final explained = joinStage3Explanations(
    errorItems: split.errorItems,
    dialectalCandidates: split.dialectalCandidates,
    explanations: explanations,
  );

  // computeCorrectedRanges requires non-overlapping input — already
  // guaranteed here, since resolveOverlappingCandidates deduped the full
  // candidate set (errors and dialectal together) before the verdict split
  // ever separated them.
  final rangedErrorItems = computeCorrectedRanges(explained.errorItems);
  final correctedText = rangedErrorItems.isEmpty
      ? submittedText
      : _reconstructCorrectedText(submittedText, rangedErrorItems);

  return CorrectionResponse(
    originalText: submittedText,
    correctedText: correctedText,
    corrections: rangedErrorItems,
    notes: explained.notes,
  );
}

/// Rebuilds the corrected text by applying each ranged correction's edit to
/// [submittedText], rightmost edit first so earlier edits' indexes stay
/// valid as the text is rewritten.
///
/// Copied by value from `CorrectionResponse`'s own private
/// `_reconstructCorrectedText` — same precedent as every other copied
/// helper in this staged pipeline (e.g.
/// `staged_correction_overlap_resolver.dart`'s `_rangesOverlap`): the
/// original is private to its file, and this pipeline's own boundary
/// condition is additive-only, so the existing single-call pipeline that
/// already depends on the original is never touched.
String _reconstructCorrectedText(
  String submittedText,
  List<CorrectionItem> corrections,
) {
  final characters = submittedText.characters.toList();
  final sortedCorrections = [...corrections]
    ..sort((left, right) => right.startIndex!.compareTo(left.startIndex!));

  for (final correction in sortedCorrections) {
    characters.replaceRange(
      correction.startIndex!,
      correction.endIndex!,
      correction.correctedPhrase.characters,
    );
  }

  return characters.join();
}
