import 'package:characters/characters.dart';

import 'naturalness_issue.dart';
import 'naturalness_review.dart';

/// Why a naturalness issue was not applied — see [SkippedNaturalnessEdit].
enum NaturalnessMergeSkipReason {
  /// `NaturalnessIssue.span` does not occur anywhere in the first-pass
  /// corrected text — the naturalness pass and the first pass disagree
  /// about what the text says at that point.
  spanNotFound,

  /// `NaturalnessIssue.span` occurs more than once in the first-pass
  /// corrected text. The naturalness contract has no `occurrence` field
  /// (see `docs/naturalness_review_output_contract.md`, issue #29), so
  /// there is no safe way to know which instance the model meant — guessing
  /// risks editing the wrong one, so neither is applied.
  ambiguousSpan,

  /// `NaturalnessIssue.span` resolves to a range that overlaps an edit
  /// already accepted from an earlier (leftmost) issue in the same review.
  overlapsAnotherEdit,
}

/// One [NaturalnessIssue] the merge did not apply, with why.
class SkippedNaturalnessEdit {
  const SkippedNaturalnessEdit({required this.issue, required this.reason});

  final NaturalnessIssue issue;
  final NaturalnessMergeSkipReason reason;
}

/// One [NaturalnessIssue] the merge did apply, anchored to the
/// grapheme-cluster range in the first-pass corrected text it replaced.
class AppliedNaturalnessEdit {
  const AppliedNaturalnessEdit({
    required this.issue,
    required this.startIndex,
    required this.endIndex,
  });

  final NaturalnessIssue issue;

  /// Grapheme-cluster start index within the first-pass corrected text.
  final int startIndex;

  /// Grapheme-cluster end index (exclusive) within the first-pass
  /// corrected text.
  final int endIndex;
}

/// The result of [mergeNaturalnessReview]: the first pass's corrected text
/// plus the naturalness pass's issues, combined into one final text.
class NaturalnessMergeResult {
  const NaturalnessMergeResult({
    required this.originalText,
    required this.firstPassCorrectedText,
    required this.finalCorrectedText,
    required this.appliedEdits,
    required this.skippedEdits,
  });

  final String originalText;
  final String firstPassCorrectedText;

  /// [firstPassCorrectedText] with every entry in [appliedEdits] applied.
  /// Identical to [firstPassCorrectedText] when [appliedEdits] is empty.
  final String finalCorrectedText;

  /// Left to right by position in [firstPassCorrectedText].
  final List<AppliedNaturalnessEdit> appliedEdits;

  /// In the same order as the input [NaturalnessReview.issues].
  final List<SkippedNaturalnessEdit> skippedEdits;
}

/// Combines [firstPassCorrectedText] (the objective grammar/spelling/
/// punctuation pass's output) with [naturalnessReview] (the naturalness
/// pass run against that same text) into one final corrected text.
///
/// Deterministic and isolated from any API client — a pure function over
/// already-parsed inputs, with no knowledge of `OpenAiChatCompletionsClient`
/// or any other transport. [originalText] is carried through on the result
/// for callers that need to anchor back to it later (e.g. building
/// `CorrectionItem`s, issue #36); the merge itself only ever reads and
/// edits [firstPassCorrectedText].
///
/// Each issue's `span` is located in [firstPassCorrectedText] by exact
/// grapheme-cluster match, the same approach
/// `resolveOccurrenceCorrections`/`CorrectionItem._anchorRange` use
/// elsewhere in this app. An issue is applied only when its span is
/// unambiguous (found exactly once) and its resolved range does not
/// overlap an edit already accepted from an earlier (leftmost-starting)
/// issue — see [NaturalnessMergeSkipReason] for why every other case is
/// skipped rather than guessed. This is deliberately the minimum safe
/// merge, not full conflict analysis — see issue #34 for anything more
/// involved.
NaturalnessMergeResult mergeNaturalnessReview({
  required String originalText,
  required String firstPassCorrectedText,
  required NaturalnessReview naturalnessReview,
}) {
  final graphemes = firstPassCorrectedText.characters.toList();

  final resolvedByIssue = <NaturalnessIssue, (int, int)>{};
  final skipReasonByIssue = <NaturalnessIssue, NaturalnessMergeSkipReason>{};

  for (final issue in naturalnessReview.issues) {
    final spanGraphemes = issue.span.characters.toList();
    final matches = _findGraphemeMatches(graphemes, spanGraphemes);
    if (matches.isEmpty) {
      skipReasonByIssue[issue] = NaturalnessMergeSkipReason.spanNotFound;
      continue;
    }
    if (matches.length > 1) {
      skipReasonByIssue[issue] = NaturalnessMergeSkipReason.ambiguousSpan;
      continue;
    }
    resolvedByIssue[issue] = (
      matches.single,
      matches.single + spanGraphemes.length,
    );
  }

  // Leftmost-starting span wins a conflict, regardless of the issues'
  // order in the review — sorting by resolved position (not list order)
  // is what makes that deterministic.
  final orderedByPosition = resolvedByIssue.entries.toList()
    ..sort((a, b) => a.value.$1.compareTo(b.value.$1));

  final appliedEdits = <AppliedNaturalnessEdit>[];
  int? lastAppliedEnd;
  for (final entry in orderedByPosition) {
    final (start, end) = entry.value;
    if (lastAppliedEnd != null && start < lastAppliedEnd) {
      skipReasonByIssue[entry.key] =
          NaturalnessMergeSkipReason.overlapsAnotherEdit;
      continue;
    }
    appliedEdits.add(
      AppliedNaturalnessEdit(issue: entry.key, startIndex: start, endIndex: end),
    );
    lastAppliedEnd = end;
  }

  final skippedEdits = <SkippedNaturalnessEdit>[
    for (final issue in naturalnessReview.issues)
      if (skipReasonByIssue.containsKey(issue))
        SkippedNaturalnessEdit(issue: issue, reason: skipReasonByIssue[issue]!),
  ];

  final finalCorrectedText = appliedEdits.isEmpty
      ? firstPassCorrectedText
      : _applyEdits(graphemes, appliedEdits);

  return NaturalnessMergeResult(
    originalText: originalText,
    firstPassCorrectedText: firstPassCorrectedText,
    finalCorrectedText: finalCorrectedText,
    appliedEdits: List.unmodifiable(appliedEdits),
    skippedEdits: List.unmodifiable(skippedEdits),
  );
}

/// Every grapheme-cluster-safe start position where [needle] occurs in
/// [haystack], left to right, including overlapping matches.
///
/// Copied by value from `CorrectionItem`'s private `_findGraphemeMatches`
/// (already copied once before, in `correction_original_range_resolver.dart`)
/// — same established precedent in this codebase of copying a small pure
/// helper by value rather than reaching into another file's private
/// implementation.
List<int> _findGraphemeMatches(List<String> haystack, List<String> needle) {
  if (needle.isEmpty || needle.length > haystack.length) {
    return const [];
  }

  final matches = <int>[];
  for (var start = 0; start <= haystack.length - needle.length; start++) {
    var matched = true;
    for (var offset = 0; offset < needle.length; offset++) {
      if (haystack[start + offset] != needle[offset]) {
        matched = false;
        break;
      }
    }
    if (matched) {
      matches.add(start);
    }
  }
  return matches;
}

/// Applies [edits] to [graphemes] (the first-pass corrected text's
/// grapheme clusters), rightmost edit first so earlier edits' indexes stay
/// valid as the text is rewritten — same approach as
/// `CorrectionResponse._reconstructCorrectedText`.
String _applyEdits(
  List<String> graphemes,
  List<AppliedNaturalnessEdit> edits,
) {
  final characters = [...graphemes];
  final sortedEdits = [...edits]
    ..sort((left, right) => right.startIndex.compareTo(left.startIndex));

  for (final edit in sortedEdits) {
    characters.replaceRange(
      edit.startIndex,
      edit.endIndex,
      edit.issue.naturalReplacement.characters,
    );
  }

  return characters.join();
}
