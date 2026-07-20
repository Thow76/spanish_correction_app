import 'correction_original_range_resolver.dart';
import 'staged_correction_candidate.dart';

/// Resolves each candidate's [StagedCorrectionCandidate.occurrence] into a
/// concrete [StagedCorrectionCandidate.startIndex] against [originalText],
/// by delegating to the existing, unmodified [resolveOccurrenceCorrections].
///
/// Each candidate is resolved one at a time rather than as a single batch
/// call. [resolveOccurrenceCorrections] itself documents that every
/// correction is resolved against a fresh full search with no shared cursor
/// state between corrections — so resolving one at a time is behaviorally
/// identical to a batch call, but sidesteps a real ambiguity a batch call
/// would have: two candidates can share the exact same (originalPhrase,
/// occurrence) pair (Stage 1 and Stage 1B can both flag the same phrase,
/// and `mergeStage1FlaggedPhrases` deliberately preserves such duplicates
/// rather than deduping them), and `OccurrenceCorrection`'s output carries
/// no identity to safely match a batch result back to the right candidate
/// in that case. Resolving one at a time needs no such matching at all.
///
/// A candidate whose `originalPhrase` doesn't occur `occurrence` times in
/// [originalText] is dropped — the same silent-drop precedent
/// [resolveOccurrenceCorrections] itself already documents. The input list
/// is not mutated; a new list (only the resolvable candidates, each now
/// carrying its resolved `startIndex`) is returned, in input order.
List<StagedCorrectionCandidate> resolveCandidatePositions({
  required String originalText,
  required List<StagedCorrectionCandidate> candidates,
}) {
  final resolved = <StagedCorrectionCandidate>[];

  for (final candidate in candidates) {
    final result = resolveOccurrenceCorrections(originalText, [
      OccurrenceCorrection(
        originalPhrase: candidate.originalPhrase,
        occurrence: candidate.occurrence,
      ),
    ]);

    if (result.isEmpty) {
      continue;
    }

    resolved.add(candidate.copyWith(startIndex: result.single.startIndex!));
  }

  return resolved;
}
