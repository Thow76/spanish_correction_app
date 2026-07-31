import '../domain/correction_response.dart';
import '../domain/naturalness_correction_mapper.dart';
import '../domain/naturalness_merge.dart';
import 'naturalness_review_client.dart';
import 'openai_chat_completions_client.dart';
import 'staged_correction_pipeline.dart';

/// Runs the two-pass correction pipeline: the first pass
/// (`runStagedCorrectionPipeline`) and the naturalness review
/// (`callNaturalnessReview`) concurrently against [submittedText] — the
/// fast parallel path — merges the naturalness review into the first
/// pass's corrected text via `mergeNaturalnessReview` (issue #32), and maps
/// the result into a single unified [CorrectionResponse] via
/// `mapNaturalnessEditsIntoCorrectionResponse` (issue #36) — the same
/// shape `CorrectionService.correctText()` already returns for every other
/// path, so a caller never needs to special-case a two-pass result.
///
/// The parallel naturalness review's spans are resolved against
/// [submittedText] itself, since it runs before the first pass's own
/// output is known. The merge, however, is against the first pass's
/// *corrected* text — if the first pass changed wording the naturalness
/// pass flagged, its spans may no longer match: either missing outright
/// ([NaturalnessMergeSkipReason.spanNotFound]) or newly ambiguous
/// ([NaturalnessMergeSkipReason.ambiguousSpan]). When the parallel merge
/// leaves any `skippedEdits` at all, a sequential fallback reruns
/// naturalness review directly against the first pass's own corrected
/// text — guaranteeing its spans refer to the exact text being merged
/// into — and merges *that* review instead, superseding the parallel
/// attempt entirely. The fallback is called at most once: if the parallel
/// merge is already clean (no skipped edits), it is never called.
Future<CorrectionResponse> runTwoPassCorrectionPipeline({
  required OpenAiChatCompletionsClient client,
  required String firstPassModel,
  required String naturalnessModel,
  required String submittedText,
}) async {
  // Both started before either is awaited — the "fast parallel path".
  final firstPassFuture = runStagedCorrectionPipeline(
    client: client,
    model: firstPassModel,
    submittedText: submittedText,
  );
  final parallelNaturalnessFuture = callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: submittedText,
  );

  final firstPassResponse = await firstPassFuture;
  final parallelNaturalnessReview = await parallelNaturalnessFuture;

  final parallelMerge = mergeNaturalnessReview(
    originalText: submittedText,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: parallelNaturalnessReview,
  );

  if (parallelMerge.skippedEdits.isEmpty) {
    return mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: parallelMerge,
    );
  }

  final fallbackNaturalnessReview = await callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: firstPassResponse.correctedText,
  );

  final fallbackMerge = mergeNaturalnessReview(
    originalText: submittedText,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: fallbackNaturalnessReview,
  );

  return mapNaturalnessEditsIntoCorrectionResponse(
    firstPassResponse: firstPassResponse,
    naturalnessMerge: fallbackMerge,
  );
}
