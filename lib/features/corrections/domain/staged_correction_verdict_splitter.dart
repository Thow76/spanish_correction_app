import 'correction_item.dart';
import 'error_category.dart';
import 'staged_correction_candidate.dart';
import 'staged_correction_verdict.dart';

/// The result of splitting a deduped [StagedCorrectionCandidate] list by
/// [StagedCorrectionVerdict] — see [splitStagedCorrections].
class StagedCorrectionSplit {
  const StagedCorrectionSplit({
    required this.errorItems,
    required this.dialectalCandidates,
  });

  /// `error`-verdict candidates, converted to [CorrectionItem].
  /// `shortExplanation` is a placeholder (`''`) — Stage 3 hasn't run yet;
  /// filling it in with a real explanation, and computing
  /// `correctedStartIndex`/`correctedEndIndex` against the final
  /// `correctedText`, are later pipeline steps' jobs, not this split's.
  final List<CorrectionItem> errorItems;

  /// `dialectal`-verdict candidates, carried through unconverted. Kept as
  /// [StagedCorrectionCandidate] rather than a new intermediate type: Stage
  /// 3's call needs `start_index`/`original_phrase`/`corrected_phrase`/
  /// `category`/`verdict` per item, and the eventual `CorrectionNote` needs
  /// `originalPhrase` as its `phrase` plus Stage 3's returned text as its
  /// `note` — a `StagedCorrectionCandidate` already carries everything both
  /// of those later steps need, so there's nothing a dedicated type would
  /// add here.
  final List<StagedCorrectionCandidate> dialectalCandidates;
}

/// Splits [candidates] three ways by [StagedCorrectionCandidate.verdict]:
///   - `error` candidates become [CorrectionItem]s (see
///     [StagedCorrectionSplit.errorItems]) — this is also where each
///     candidate's raw `category` label is converted to a real
///     [ErrorCategory] for the first time.
///   - `dialectal` candidates are carried through unconverted (see
///     [StagedCorrectionSplit.dialectalCandidates]).
///   - `not_an_error` candidates are dropped entirely — never constructed as
///     either type, matching Stage 2's own definition of the verdict
///     ("standard across varieties generally... not actually an error").
///
/// An `error` candidate whose `category` doesn't convert to a real
/// [ErrorCategory] (null, or a label [ErrorCategory.fromApiLabel] doesn't
/// recognize) is also dropped, silently — the same precedent used
/// throughout this pipeline (and by `CorrectionItem.tryFromAnchoredJson`
/// before it) for a model claim that doesn't check out against what the app
/// can safely act on.
StagedCorrectionSplit splitStagedCorrections(
  List<StagedCorrectionCandidate> candidates,
) {
  final errorItems = <CorrectionItem>[];
  final dialectalCandidates = <StagedCorrectionCandidate>[];

  for (final candidate in candidates) {
    switch (candidate.verdict) {
      case StagedCorrectionVerdict.error:
        final item = _toErrorCorrectionItem(candidate);
        if (item != null) {
          errorItems.add(item);
        }
      case StagedCorrectionVerdict.dialectal:
        dialectalCandidates.add(candidate);
      case StagedCorrectionVerdict.notAnError:
        break;
    }
  }

  return StagedCorrectionSplit(
    errorItems: errorItems,
    dialectalCandidates: dialectalCandidates,
  );
}

CorrectionItem? _toErrorCorrectionItem(StagedCorrectionCandidate candidate) {
  final rawCategory = candidate.category;
  if (rawCategory == null) {
    return null;
  }

  final ErrorCategory category;
  try {
    category = ErrorCategory.fromApiLabel(rawCategory);
  } on FormatException {
    return null;
  }

  return CorrectionItem(
    originalPhrase: candidate.originalPhrase,
    correctedPhrase: candidate.correctedPhrase,
    category: category,
    shortExplanation: '',
    startIndex: candidate.startIndex,
    endIndex: candidate.endIndex,
  );
}
