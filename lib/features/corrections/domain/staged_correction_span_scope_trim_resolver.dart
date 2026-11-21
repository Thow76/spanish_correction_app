import 'correction_span_trim_calculator.dart';
import 'staged_correction_candidate.dart';
import 'staged_correction_span_scope.dart';

/// Trims a candidate's span down to the words that actually change, using
/// [calculateSharedAffixTrim] (whole words only), so the highlight covers
/// "fue" rather than "yo fue" when the model quoted more than it corrected.
///
/// Build step 2.2b (21 Nov 2026): this now runs on every category. From
/// 23 July 2026 it had been gated to `category == 'Natural Language'` with
/// `spanScope == exact`, on the reading that the model would quote single
/// words for every other category; by November it no longer did, and the
/// gate was letting whole phrases through to the screen.
///
/// The one exception the other way: a Natural Language candidate the model
/// marked `full` (a fixed collocation, or a clause-wide restructure, where
/// no smaller piece makes sense on its own) keeps its whole span. See
/// `stage2CategorizationSpanish`'s `span_scope` bullet in
/// `correction_prompt.dart`.
///
/// Runs after `resolveInsertionOffsets` (which has already resolved every
/// candidate's `endIndex`, and collapsed pure insertions to an empty
/// `originalPhrase`, which are skipped here) and before
/// `resolveOverlappingCandidates`, whose narrowest-width tie-break needs to
/// see the trimmed width. Stage 3 runs after this, so the start positions it
/// is given, and matches its explanations on, are the trimmed ones.
///
/// When the trim would leave either side empty (words removed, the "tengo
/// tengo" -> "tengo" shape, or words added) the candidate's quoted span is
/// kept: the shared-affix walk would be reinterpreting a substitution as a
/// pure deletion or insertion, and that is not this step's call to make.
List<StagedCorrectionCandidate> resolveSpanScopeTrim(
  List<StagedCorrectionCandidate> candidates,
) {
  return candidates.map(_trimIfEligible).toList();
}

StagedCorrectionCandidate _trimIfEligible(StagedCorrectionCandidate candidate) {
  if (candidate.originalPhrase.isEmpty) {
    return candidate;
  }
  if (candidate.category == 'Natural Language' &&
      candidate.spanScope == StagedCorrectionSpanScope.full) {
    return candidate;
  }

  final trim = calculateSharedAffixTrim(
    originalPhrase: candidate.originalPhrase,
    correctedPhrase: candidate.correctedPhrase,
  );

  if (trim.prefixLength == 0 && trim.suffixLength == 0) {
    return candidate;
  }
  if (trim.trimmedOriginalPhrase.isEmpty ||
      trim.trimmedCorrectedPhrase.isEmpty) {
    return candidate;
  }

  return candidate.copyWith(
    originalPhrase: trim.trimmedOriginalPhrase,
    correctedPhrase: trim.trimmedCorrectedPhrase,
    startIndex: candidate.startIndex! + trim.prefixLength,
    endIndex: candidate.endIndex! - trim.suffixLength,
  );
}
