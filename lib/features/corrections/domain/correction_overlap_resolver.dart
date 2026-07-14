import 'correction_item.dart';

/// Removes duplicate/overlapping corrections from an anchored [corrections]
/// list (e.g. the model reporting the same edit as two separate correction
/// objects — see the ES-1-repeated-word harness case). Pure function, not yet
/// wired into the live correction pipeline.
///
/// Corrections without a resolved range (`startIndex`/`endIndex` null) are
/// left untouched and returned as-is, since there is nothing to compare them
/// against.
///
/// Ranged corrections are sorted by `startIndex` (ties broken by original
/// list order) and swept in that order, keeping a correction only if it does
/// not overlap any correction already kept. Among a group of
/// overlapping/duplicate corrections, the earliest-starting one wins — the
/// same policy `correction_highlight_spans.dart` already applies when
/// resolving overlapping highlights, kept consistent here.
///
/// The result preserves ascending `startIndex` order for ranged corrections,
/// followed by any unranged ones in their original order.
List<CorrectionItem> resolveOverlappingCorrections(
  List<CorrectionItem> corrections,
) {
  final ranged = <CorrectionItem>[];
  final unranged = <CorrectionItem>[];
  for (final item in corrections) {
    if (item.startIndex != null && item.endIndex != null) {
      ranged.add(item);
    } else {
      unranged.add(item);
    }
  }

  final order = List<int>.generate(ranged.length, (index) => index)..sort((
    a,
    b,
  ) {
    final byStart = ranged[a].startIndex!.compareTo(ranged[b].startIndex!);
    return byStart != 0 ? byStart : a.compareTo(b);
  });

  final kept = <CorrectionItem>[];
  for (final index in order) {
    final candidate = ranged[index];
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

  return [...kept, ...unranged];
}

/// Whether half-open ranges `[aStart, aEnd)` and `[bStart, bEnd)` overlap.
/// Zero-length ranges (insertions, where start == end) are handled
/// specially: two insertions overlap only if they sit at the exact same
/// point, and an insertion overlaps a non-empty range if its point falls
/// strictly inside that range.
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
