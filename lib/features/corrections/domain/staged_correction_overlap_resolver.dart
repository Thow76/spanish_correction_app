import 'staged_correction_candidate.dart';

/// Removes duplicate/overlapping candidates from an already-positioned
/// [candidates] list (every candidate must carry non-null `startIndex` and
/// `endIndex` — i.e. this runs after `resolveCandidatePositions` and
/// `resolveInsertionOffsets`).
///
/// This is deliberately a new function operating on
/// [StagedCorrectionCandidate], not a call into the existing
/// `resolveOverlappingCorrections` (which operates on `CorrectionItem`): a
/// candidate isn't a `CorrectionItem` at this pipeline stage (no
/// `shortExplanation` yet, `category` still a raw nullable label, no
/// `ErrorCategory` — see `StagedCorrectionCandidate`'s own docstring for
/// why forcing that conversion early would mean faking fields that don't
/// exist yet), so reusing that function's signature isn't type-safe here.
/// The overlap test itself ([_rangesOverlap]) is copied by value from
/// `correction_overlap_resolver.dart` rather than shared or extracted —
/// same precedent already established by
/// `correction_original_range_resolver.dart` copying
/// `CorrectionItem`'s private `_findGraphemeMatches` for the same reason:
/// the helper is private to its file, and this pipeline's own boundary
/// condition is additive-only. `resolveOverlappingCorrections` itself is
/// untouched by this file and keeps its existing earliest-start-wins
/// behavior for the single-call pipeline that still depends on it.
///
/// The tie-break differs from `resolveOverlappingCorrections`'s on purpose:
/// among overlapping/duplicate candidates, the NARROWEST span wins, not the
/// earliest-starting one. This matters because Stage 1 and Stage 1B can
/// both flag overlapping text for the same underlying issue with anchors of
/// very different width (e.g. Stage 1 flagging a whole clause, Stage 1B
/// flagging just the one redundant pronoun within it) — an earliest-start
/// tie-break would keep whichever one happens to start first, which is not
/// necessarily the more precisely-targeted one. Width is the primary sort
/// key; candidates of equal width fall back to earliest start, then
/// original list order, matching `resolveOverlappingCorrections`'s own
/// fallback ordering.
///
/// The result is sorted by ascending `startIndex` — after dedup, no two
/// surviving candidates can share a `startIndex` (two ranges starting at
/// the same point always overlap under [_rangesOverlap], so at most one of
/// them can survive), so this ordering is unambiguous.
List<StagedCorrectionCandidate> resolveOverlappingCandidates(
  List<StagedCorrectionCandidate> candidates,
) {
  final order = List<int>.generate(candidates.length, (index) => index)
    ..sort((a, b) {
      final widthA = _width(candidates[a]);
      final widthB = _width(candidates[b]);
      final byWidth = widthA.compareTo(widthB);
      if (byWidth != 0) {
        return byWidth;
      }
      final byStart = candidates[a].startIndex!.compareTo(
        candidates[b].startIndex!,
      );
      return byStart != 0 ? byStart : a.compareTo(b);
    });

  final kept = <StagedCorrectionCandidate>[];
  for (final index in order) {
    final candidate = candidates[index];
    final overlapsKept = kept.any(
      (existing) => _rangesOverlap(
        candidate.startIndex!,
        candidate.endIndex!,
        existing.startIndex!,
        existing.endIndex!,
      ),
    );
    if (!overlapsKept) {
      kept.add(candidate);
    }
  }

  kept.sort((a, b) => a.startIndex!.compareTo(b.startIndex!));
  return kept;
}

int _width(StagedCorrectionCandidate candidate) =>
    candidate.endIndex! - candidate.startIndex!;

/// Whether half-open ranges `[aStart, aEnd)` and `[bStart, bEnd)` overlap.
/// Zero-length ranges (insertions, where start == end) are handled
/// specially: two insertions overlap only if they sit at the exact same
/// point, and an insertion overlaps a non-empty range if its point falls
/// strictly inside that range.
///
/// Copied by value from `correction_overlap_resolver.dart`'s private
/// `_rangesOverlap` — see this file's top-level doc comment for why.
bool _rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) {
  final aIsInsertion = aStart == aEnd;
  final bIsInsertion = bStart == bEnd;

  if (aIsInsertion && bIsInsertion) {
    return aStart == bStart;
  }
  if (aIsInsertion) {
    return aStart >= bStart && aStart < bEnd;
  }
  if (bIsInsertion) {
    return bStart >= aStart && bStart < aEnd;
  }
  return aStart < bEnd && bStart < aEnd;
}
