import 'correction_span_trim_calculator.dart';
import 'staged_correction_candidate.dart';
import 'staged_correction_span_scope.dart';

/// Trims a Natural Language candidate's span down to the shared-affix core
/// computed by [calculateSharedAffixTrim], but only for the narrow case
/// Stage 2 has explicitly signalled needs it: `category == 'Natural
/// Language'` and `spanScope == StagedCorrectionSpanScope.exact` (see
/// `stage2CategorizationSpanish`'s `span_scope` bullet,
/// `correction_prompt.dart`). Every other candidate — every other
/// category, `spanScope == full`, and `spanScope == null` (not requested,
/// or the "only for Natural Language" prompt instruction wasn't followed)
/// — passes through completely unchanged. This is deliberately narrower
/// than "trim whenever there's a shared affix": `spanScope` is the signal
/// that separates a genuinely over-wide anchor (cerveza-shape, trim it)
/// from a case where the whole quoted phrase has to stay together (a
/// fixed collocation, or a clause-wide restructure — `full`) — this
/// resolver only ever acts on the former.
///
/// Runs after `resolveInsertionOffsets` (staged_correction_insertion_
/// resolver.dart) — which must have already resolved every candidate's
/// `endIndex`, and for pure insertions already collapsed `originalPhrase`
/// to `''` — and before `resolveOverlappingCandidates`
/// (staged_correction_overlap_resolver.dart), whose narrowest-width tie-
/// break needs to see the already-trimmed width, not the model's
/// possibly over-wide original anchor: trimming after dedup would mean
/// the tie-break compares stale widths and could keep the wrong
/// candidate. See `staged_correction_pipeline.dart` for the call site.
///
/// A pure-insertion candidate (`originalPhrase == ''`, already collapsed
/// by `resolveInsertionOffsets`) is skipped outright, never handed to
/// [calculateSharedAffixTrim]: there is no anchor left to trim — the
/// insertion resolver already narrowed it down to a zero-length point.
///
/// [calculateSharedAffixTrim] always returns a result, never null; a
/// `prefixLength == 0 && suffixLength == 0` result (nothing shared at
/// either end) is a no-op and the candidate is returned unchanged.
///
/// Edge case: when the computed core would leave `trimmedCorrectedPhrase`
/// empty (the "tengo tengo" -> "tengo" repetition shape — see
/// `correction_span_trim_calculator_test.dart`), the trim is skipped and
/// the candidate's original, wider span is kept intact rather than
/// applied. Deliberately conservative: an empty `trimmedCorrectedPhrase`
/// means the shared-affix walk has reinterpreted a same-length-or-longer
/// substitution Stage 2 reported (`correctedPhrase` was non-empty) as a
/// pure deletion — a materially different correction shape than the one
/// this resolver exists to narrow (cerveza-shape: both sides keep a real,
/// non-empty core). That reinterpretation is a product decision this
/// narrowly-scoped step isn't the place to make silently; skipping and
/// keeping the original span is the same "leave it alone unless it's
/// exactly the designed-for shape" default every other gate here applies.
List<StagedCorrectionCandidate> resolveSpanScopeTrim(
  List<StagedCorrectionCandidate> candidates,
) {
  return candidates.map(_trimIfEligible).toList();
}

StagedCorrectionCandidate _trimIfEligible(StagedCorrectionCandidate candidate) {
  if (candidate.category != 'Natural Language') {
    return candidate;
  }
  if (candidate.spanScope != StagedCorrectionSpanScope.exact) {
    return candidate;
  }
  if (candidate.originalPhrase.isEmpty) {
    return candidate;
  }

  final trim = calculateSharedAffixTrim(
    originalPhrase: candidate.originalPhrase,
    correctedPhrase: candidate.correctedPhrase,
  );

  if (trim.prefixLength == 0 && trim.suffixLength == 0) {
    return candidate;
  }
  if (trim.trimmedCorrectedPhrase.isEmpty) {
    return candidate;
  }

  return candidate.copyWith(
    originalPhrase: trim.trimmedOriginalPhrase,
    correctedPhrase: trim.trimmedCorrectedPhrase,
    startIndex: candidate.startIndex! + trim.prefixLength,
    endIndex: candidate.endIndex! - trim.suffixLength,
  );
}
