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

  /// `NaturalnessIssue.naturalReplacement` looks like more than one
  /// proposed replacement joined together (e.g. `"A / B / C"`) rather than
  /// a single clean replacement (issue #108). The naturalness contract
  /// requires exactly one replacement per issue; splicing a slash-joined
  /// menu of options into the corrected text would hand the app text no
  /// learner asked for and no downstream code can make sense of, so this
  /// is never applied — same "don't guess" precedent as every other skip
  /// reason here, just applied to the replacement text instead of the span.
  multiOptionReplacement,

  /// `NaturalnessIssue.span` is a short phrase wrapping exactly one
  /// content word (e.g. an article/possessive plus one noun) whose
  /// content word does not appear anywhere in `naturalReplacement` (issue
  /// #111). Observed live: `"su parte"` -> `"su informe"` — the model
  /// invented a more specific noun ("informe") that was not in the
  /// learner's text, rather than correcting how the existing content word
  /// was phrased. Deliberately narrow: a *single bare word* being swapped
  /// for a different word (e.g. a false-friend fix like `"Atendió"` ->
  /// `"Asistió"`) is exactly what naturalness is supposed to do and is
  /// not caught by this guard — only a wrapped phrase whose one content
  /// word is dropped entirely is. "Wrapping" is deliberately limited to
  /// articles and possessives (see [_spanishFunctionWords]) — an ordinary
  /// preposition can itself be part of the idiom being corrected (e.g.
  /// `"para atrás"` -> `"luego"`, a genuine calque fix), so treating every
  /// preposition as a mere wrapper would misfire on exactly the kind of
  /// replacement this guard must not catch.
  contentWordReplaced,
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
/// Each issue's `span` is located in [firstPassCorrectedText] by exact,
/// word-boundary-aware grapheme-cluster match, the same approach
/// `resolveOccurrenceCorrections`/`CorrectionItem._anchorRange` use
/// elsewhere in this app. An issue is applied only when its
/// `naturalReplacement` is a single clean replacement (not a slash-joined
/// menu of options, issue #108), its span is not a content-word
/// substitution in disguise (issue #111), its span is unambiguous (found
/// exactly once, at a real word boundary), and its resolved range does
/// not overlap an edit already accepted from an
/// earlier (leftmost-starting) issue — see [NaturalnessMergeSkipReason]
/// for why every other case is skipped rather than guessed. This is
/// deliberately the minimum safe merge, not full conflict analysis — see
/// issue #34 for anything more involved.
NaturalnessMergeResult mergeNaturalnessReview({
  required String originalText,
  required String firstPassCorrectedText,
  required NaturalnessReview naturalnessReview,
}) {
  final graphemes = firstPassCorrectedText.characters.toList();

  final resolvedByIssue = <NaturalnessIssue, (int, int)>{};
  final skipReasonByIssue = <NaturalnessIssue, NaturalnessMergeSkipReason>{};

  for (final issue in naturalnessReview.issues) {
    if (_looksLikeMultipleOptions(issue.naturalReplacement)) {
      skipReasonByIssue[issue] = NaturalnessMergeSkipReason.multiOptionReplacement;
      continue;
    }
    if (_replacesContentWordWithUnrelatedWord(
      issue.span,
      issue.naturalReplacement,
    )) {
      skipReasonByIssue[issue] = NaturalnessMergeSkipReason.contentWordReplaced;
      continue;
    }
    final spanGraphemes = issue.span.characters.toList();
    final matches = _findGraphemeMatches(
      graphemes,
      spanGraphemes,
    ).where((start) => _isWordBoundaryMatch(graphemes, start, spanGraphemes.length)).toList();
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
  // is what makes that deterministic. `List.sort` is not guaranteed
  // stable, so two candidates that start at the exact same position have
  // no principled "leftmost" winner between them — applying either one
  // would be an arbitrary guess, which this component exists specifically
  // to avoid (issue #34). Every candidate in such a tied group is treated
  // as conflicting and skipped instead, computed before sorting so tie
  // membership never depends on sort order.
  final startCounts = <int, int>{};
  for (final range in resolvedByIssue.values) {
    startCounts[range.$1] = (startCounts[range.$1] ?? 0) + 1;
  }

  final orderedByPosition = resolvedByIssue.entries.toList()
    ..sort((a, b) => a.value.$1.compareTo(b.value.$1));

  final appliedEdits = <AppliedNaturalnessEdit>[];
  int? lastAppliedEnd;
  for (final entry in orderedByPosition) {
    final (start, end) = entry.value;
    if (startCounts[start]! > 1) {
      skipReasonByIssue[entry.key] =
          NaturalnessMergeSkipReason.overlapsAnotherEdit;
      continue;
    }
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

/// Whether [naturalReplacement] looks like more than one proposed
/// replacement joined together (e.g. `"A / B"`) rather than a single clean
/// replacement (issue #108).
///
/// Checks for `" / "` — a slash with a space on both sides — rather than a
/// bare `/`: a bare slash can appear inside one legitimate Spanish
/// replacement with no surrounding spaces (e.g. `"y/o"`, "and/or"), but
/// every observed multi-option failure (e.g. `"¿Me pones una cerveza? / ¿Me
/// das una cerveza?"`, `"pasarlo bien / pasar un buen rato"`) joins its
/// alternatives with a space on each side of the slash. Narrow on purpose:
/// this only needs to catch the failure mode actually observed, not every
/// conceivable way a model could misbehave.
bool _looksLikeMultipleOptions(String naturalReplacement) {
  return naturalReplacement.contains(' / ');
}

/// Spanish articles and possessives excluded from the "content word"
/// check in [_replacesContentWordWithUnrelatedWord] — deliberately
/// limited to words that only ever wrap a noun (determiners/possessives),
/// not general function words. A review finding on this guard's own PR
/// caught an earlier, broader version of this set that also excluded
/// prepositions/conjunctions/object pronouns: that misfired on a genuine
/// preposition-anchored idiom fix like `"para atrás"` -> `"luego"`
/// (`"para"` is part of the calque being corrected, not a mere wrapper
/// around an unrelated content word), skipping a legitimate replacement.
/// Determiners and possessives don't have that problem — they only ever
/// modify the noun they precede, never carry idiomatic meaning of their
/// own.
const Set<String> _spanishFunctionWords = {
  'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
  'mi', 'mis', 'tu', 'tus', 'su', 'sus',
  'nuestro', 'nuestra', 'nuestros', 'nuestras',
  'vuestro', 'vuestra', 'vuestros', 'vuestras',
};

/// Splits [text] into lowercase words with surrounding punctuation
/// stripped, for the word-level comparisons in
/// [_replacesContentWordWithUnrelatedWord].
List<String> _wordsOf(String text) {
  return text
      .split(RegExp(r'\s+'))
      .map(
        (word) => word
            .toLowerCase()
            .replaceAll(RegExp(r'^[¿¡"“”‘’.,;:!?()]+|[¿¡"“”‘’.,;:!?()]+$'), ''),
      )
      .where((word) => word.isNotEmpty)
      .toList();
}

/// Whether [span] is a short phrase wrapping exactly one content word
/// (i.e. every other word in [span] is a function word from
/// [_spanishFunctionWords]) whose content word does not appear anywhere
/// in [naturalReplacement] (issue #111) — e.g. `"su parte"` ->
/// `"su informe"`, where the only content word, "parte", is dropped
/// entirely in favor of an unrelated, more specific noun the model
/// invented rather than corrected.
///
/// Deliberately requires [span] to have at least two words: a *single
/// bare word* being swapped for a completely different word (e.g. a
/// false-friend fix like `"Atendió"` -> `"Asistió"`, or `"hace"` ->
/// `"tiene"` inside a longer span that still shares its other content
/// word) is exactly what naturalness is supposed to do, and must not be
/// caught by this guard. Also requires exactly one content word in
/// [span] — a phrase with two or more content words (e.g. `"importante
/// hoy mismo"`) is a broader rewrite this function deliberately does not
/// attempt to judge (an earlier, broader span-size guard tried and was
/// removed — see the "Status update (issue #111)" section of
/// `docs/two_pass_test_change_notes.md` for why).
bool _replacesContentWordWithUnrelatedWord(
  String span,
  String naturalReplacement,
) {
  final spanWords = _wordsOf(span);
  if (spanWords.length < 2) {
    return false;
  }
  final spanContentWords = spanWords
      .where((word) => !_spanishFunctionWords.contains(word))
      .toList();
  if (spanContentWords.length != 1) {
    return false;
  }
  final replacementWords = _wordsOf(naturalReplacement).toSet();
  return !replacementWords.contains(spanContentWords.single);
}

/// Whether the grapheme-cluster range `[start, start + length)` in
/// [haystack] starts and ends at a word boundary — the character
/// immediately before [start] (if any) and the character at
/// `start + length` (if any) are not themselves word characters.
///
/// Fixes a specific observed failure (issue #111): `_findGraphemeMatches`
/// is a plain substring search, so a span like `"a tienda"` can match
/// starting at the trailing "a" of an unrelated word "la" (e.g. inside
/// "Fui a **la** tienda", the "a" of "la" is immediately followed by "
/// tienda"). Applying the replacement there duplicates the word instead
/// of fixing anything — "Fui a la la tienda" — the exact "la la" artifact
/// observed live. A match that starts or ends mid-word is not really a
/// match of the *word or phrase* the naturalness pass meant, so it is
/// filtered out before a span is judged found/ambiguous, same as if it
/// had never matched at all.
bool _isWordBoundaryMatch(List<String> haystack, int start, int length) {
  final end = start + length;
  final startOk = start == 0 || !_isWordChar(haystack[start - 1]);
  final endOk = end == haystack.length || !_isWordChar(haystack[end]);
  return startOk && endOk;
}

/// Whether [grapheme] is a Spanish letter — used only for the word-
/// boundary check in [_isWordBoundaryMatch]. Not a general Unicode word-
/// character classifier; deliberately scoped to the Latin/Spanish
/// alphabet this app's text is always in.
bool _isWordChar(String grapheme) {
  return RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]$').hasMatch(grapheme);
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
