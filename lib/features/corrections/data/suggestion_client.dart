import 'dart:convert';

import 'package:characters/characters.dart';

import '../../../core/services/prompts/correction_prompt.dart';
import '../domain/correction_item.dart';
import '../domain/correction_span_trim_calculator.dart';
import '../domain/correction_response.dart';
import '../domain/error_category.dart';
import 'openai_chat_completions_client.dart';

/// The model for step 1 (Issues), decision P3.
const String defaultSuggestionIssuesModel = 'gpt-6-luna';

/// The model for step 2 (Suggestions), decision P3.
const String defaultSuggestionSuggestionsModel = 'gpt-6-sol';

/// Which of the two groups a point belongs to (decision C1). Fixed by the
/// step that found it, never by the model: step 1 finds Issues, step 2
/// finds Suggestions.
enum SuggestionGroup { issue, suggestion }

/// The shape of [OpenAiChatCompletionsClient.complete], so tests can hand
/// in canned replies without a network.
typedef SuggestionChatCall =
    Future<String> Function({
      required String model,
      required String systemPrompt,
      required String userText,
      String stageLabel,
      Map<String, Object?>? responseFormat,
    });

/// One four-part item exactly as a step returned it (decision P4).
class SuggestionStepItem {
  const SuggestionStepItem({
    required this.written,
    required this.suggestion,
    required this.category,
    required this.reason,
  });

  final String written;
  final String suggestion;
  final String category;
  final String reason;
}

/// Parses one step's reply into its items. Tolerates Markdown fences or
/// commentary around the JSON object. Throws [FormatException] when there
/// is no object or no "items" list; skips an item with a missing or
/// non-string field. The prompts ask for the items only; the app builds the
/// suggested version from them, so every change the learner sees has an
/// item explaining it. Any other field in the reply is ignored.
List<SuggestionStepItem> parseSuggestionStepReply(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end <= start) {
    throw const FormatException('No JSON object found in the check reply.');
  }
  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Check reply JSON is not an object.');
  }
  final items = decoded['items'];
  if (items is! List) {
    throw const FormatException('Check reply has no "items" list.');
  }
  final result = <SuggestionStepItem>[];
  for (final raw in items) {
    if (raw is! Map<String, Object?>) continue;
    final written = raw['written'];
    final suggestion = raw['suggestion'];
    final category = raw['category'];
    final reason = raw['reason'];
    if (written is! String ||
        suggestion is! String ||
        category is! String ||
        reason is! String) {
      continue;
    }
    result.add(
      SuggestionStepItem(
        written: written,
        suggestion: suggestion,
        category: category,
        reason: reason,
      ),
    );
  }
  return result;
}

/// The app's category for a category name the two steps use.
///
/// Returns null for any other name, and the item is then left out.
ErrorCategory? suggestionCategoryFor(String name) {
  switch (name.trim()) {
    case 'Spelling':
      return ErrorCategory.spelling;
    case 'Grammar':
      return ErrorCategory.grammar;
    case 'Word Choice':
    case 'Word meaning': // the prompt's name before build step 2.2c
      return ErrorCategory.wordChoice;
    case 'Natural phrasing':
      return ErrorCategory.naturalPhrasing;
  }
  return null;
}

/// What the two-step check returns for one text.
class SuggestionCheckResult {
  const SuggestionCheckResult({
    required this.originalText,
    required this.textAfterIssues,
    required this.suggestedText,
    required this.issues,
    required this.suggestions,
  });

  /// The text as the learner wrote or spoke it.
  final String originalText;

  /// The text with step 1's Issues applied; what step 2 read.
  final String textAfterIssues;

  /// The text with every Issue and Suggestion applied.
  final String suggestedText;

  /// Points found by step 1 (Spelling, Grammar, Word Choice).
  final List<CorrectionItem> issues;

  /// Points found by step 2 (Natural phrasing).
  final List<CorrectionItem> suggestions;

  bool get hasPoints => issues.isNotEmpty || suggestions.isNotEmpty;

  /// The group of [item], which must be one of this result's items.
  SuggestionGroup groupOf(CorrectionItem item) =>
      suggestions.any((s) => identical(s, item))
      ? SuggestionGroup.suggestion
      : SuggestionGroup.issue;

  /// Both groups as one [CorrectionResponse], Issues first, in the shape
  /// today's results screen, History and Saved already read.
  CorrectionResponse toCorrectionResponse() => CorrectionResponse(
    originalText: originalText,
    correctedText: suggestedText,
    corrections: [...issues, ...suggestions],
  );
}

/// The app's one Spanish check (decisions P4 and C1): GPT-6 Luna reads the
/// text for Issues, then GPT-6 Sol reads the text with those Issues applied
/// for Suggestions. One call per model; no re-runs and no fallbacks. A
/// failed call throws ([ChatCompletionsException] from the client, or
/// [FormatException] for a reply that cannot be read).
class SuggestionClient {
  SuggestionClient({
    required SuggestionChatCall call,
    this.issuesModel = defaultSuggestionIssuesModel,
    this.suggestionsModel = defaultSuggestionSuggestionsModel,
  }) : _call = call;

  /// The check over OpenAI's chat completions service.
  factory SuggestionClient.openAi(
    OpenAiChatCompletionsClient client, {
    String issuesModel = defaultSuggestionIssuesModel,
    String suggestionsModel = defaultSuggestionSuggestionsModel,
  }) => SuggestionClient(
    call: client.complete,
    issuesModel: issuesModel,
    suggestionsModel: suggestionsModel,
  );

  final SuggestionChatCall _call;
  final String issuesModel;
  final String suggestionsModel;

  Future<SuggestionCheckResult> check(String text) async {
    final issuesReply = await _call(
      model: issuesModel,
      systemPrompt: twoStepIssuesPromptSpanish,
      userText: buildTwoStepUserContent(text),
      stageLabel: 'suggestion_check_issues',
      responseFormat: twoStepResponseFormat(twoStepIssueCategories),
    );
    final issueEdits = placeSuggestionEdits(
      text,
      parseSuggestionStepReply(issuesReply),
      twoStepIssueCategories,
    );
    final textAfterIssues = applySuggestionEdits(text, issueEdits);

    final suggestionsReply = await _call(
      model: suggestionsModel,
      systemPrompt: twoStepSuggestionsPromptSpanish,
      userText: buildTwoStepUserContent(textAfterIssues),
      stageLabel: 'suggestion_check_suggestions',
      responseFormat: twoStepResponseFormat(twoStepSuggestionCategories),
    );
    final suggestionEdits = placeSuggestionEdits(
      textAfterIssues,
      parseSuggestionStepReply(suggestionsReply),
      twoStepSuggestionCategories,
    );
    final suggestedText = applySuggestionEdits(
      textAfterIssues,
      suggestionEdits,
    );

    return buildSuggestionCheckResult(
      originalText: text,
      textAfterIssues: textAfterIssues,
      suggestedText: suggestedText,
      issueEdits: issueEdits,
      suggestionEdits: suggestionEdits,
    );
  }
}

/// The user message each step receives, as the E.3 test program sent it.
String buildTwoStepUserContent(String text) => 'Text to review:\n$text';

/// One item placed in the text it was read from: [start] and [end] are
/// positions (in UTF-16 code units, Dart's string positions) of
/// [SuggestionStepItem.written] in that text.
class PlacedSuggestionEdit {
  const PlacedSuggestionEdit({
    required this.item,
    required this.category,
    required this.start,
    required this.end,
    SuggestionStepItem? source,
  }) : source = source ?? item;

  /// The item as applied: trimmed to the words that change (2.2b).
  final SuggestionStepItem item;

  /// The item exactly as the model returned it, before any trim. The test
  /// program uses this to tell which of the model's items were applied.
  final SuggestionStepItem source;
  final ErrorCategory category;
  final int start;
  final int end;

  int get delta => item.suggestion.length - (end - start);
}

/// Keeps the items that can be placed in [text] without guessing: an
/// allowed category, a non-empty "written" found exactly once as a whole
/// word or phrase, and not overlapping an item already kept. Sorted by
/// position. Every item is looked for in [text] itself, the text the step
/// read. Shared with the E.3 test program, which scores the text these
/// edits build.
List<PlacedSuggestionEdit> placeSuggestionEdits(
  String text,
  List<SuggestionStepItem> items,
  List<String> allowedCategories,
) {
  final kept = <PlacedSuggestionEdit>[];
  for (final item in items) {
    if (!allowedCategories.contains(item.category)) continue;
    final category = suggestionCategoryFor(item.category);
    if (category == null) continue;
    if (item.written == item.suggestion) continue;
    final matches = wholeWordMatches(text, item.written);
    if (matches.length != 1) continue;
    final edit = _trimToChangedWords(
      item: item,
      category: category,
      start: matches.single,
    );
    if (kept.any((k) => _rangesOverlap(edit.start, edit.end, k.start, k.end))) {
      continue;
    }
    kept.add(edit);
  }
  kept.sort((a, b) => a.start.compareTo(b.start));
  return kept;
}

/// [text] with every edit in [sortedEdits] put in place.
/// Build step 2.2b: an Issue's highlight covers only the words that change.
/// Unchanged words the model quoted at either end ("yo" in "yo fue" -> "yo
/// fui") are trimmed off, whole words only, with the positions moved to
/// match. A Natural phrasing point is never trimmed: the two-step prompt has
/// no "full" marker, and a phrase-level suggestion ("hacer una decisión" ->
/// "tomar una decisión") is meant to be read as a whole. When trimming would
/// leave either side empty (words added or removed, rather than changed) the
/// quoted span is kept as it is.
PlacedSuggestionEdit _trimToChangedWords({
  required SuggestionStepItem item,
  required ErrorCategory category,
  required int start,
}) {
  final end = start + item.written.length;
  final untrimmed = PlacedSuggestionEdit(
    item: item,
    category: category,
    start: start,
    end: end,
  );
  if (category == ErrorCategory.naturalPhrasing) return untrimmed;

  final trim = calculateSharedAffixTrim(
    originalPhrase: item.written,
    correctedPhrase: item.suggestion,
  );
  if (trim.prefixLength == 0 && trim.suffixLength == 0) return untrimmed;
  if (trim.trimmedOriginalPhrase.isEmpty ||
      trim.trimmedCorrectedPhrase.isEmpty) {
    return untrimmed;
  }
  return PlacedSuggestionEdit(
    item: SuggestionStepItem(
      written: trim.trimmedOriginalPhrase,
      suggestion: trim.trimmedCorrectedPhrase,
      category: item.category,
      reason: item.reason,
    ),
    source: item,
    category: category,
    start: start + trim.prefixLength,
    end: end - trim.suffixLength,
  );
}

String applySuggestionEdits(
  String text,
  List<PlacedSuggestionEdit> sortedEdits,
) {
  final out = StringBuffer();
  var from = 0;
  for (final edit in sortedEdits) {
    out
      ..write(text.substring(from, edit.start))
      ..write(edit.item.suggestion);
    from = edit.end;
  }
  out.write(text.substring(from));
  return out.toString();
}

/// Builds the result's [CorrectionItem]s, with positions in graphemes
/// (letters as the learner sees them), which is what [CorrectionItem]
/// uses:
/// - an Issue's position in the original text is exact; its position in
///   the suggested text is shifted past any earlier Suggestion, and left
///   empty if a Suggestion rewrote the words the Issue produced;
/// - a Suggestion's position in the suggested text is exact; its position
///   in the original text is worked back past any earlier Issue, and left
///   empty if it covers words an Issue changed (those words are not in the
///   original). An item with no position is still listed; the results
///   screen then finds the words by searching.
SuggestionCheckResult buildSuggestionCheckResult({
  required String originalText,
  required String textAfterIssues,
  required String suggestedText,
  required List<PlacedSuggestionEdit> issueEdits,
  required List<PlacedSuggestionEdit> suggestionEdits,
}) {
  // Where each Issue landed in textAfterIssues.
  final issueRangesAfter = <(int, int)>[];
  var issueShift = 0;
  for (final edit in issueEdits) {
    final start = edit.start + issueShift;
    issueRangesAfter.add((start, start + edit.item.suggestion.length));
    issueShift += edit.delta;
  }

  // Where each Suggestion landed in suggestedText.
  final suggestionRangesFinal = <(int, int)>[];
  var suggestionShift = 0;
  for (final edit in suggestionEdits) {
    final start = edit.start + suggestionShift;
    suggestionRangesFinal.add((start, start + edit.item.suggestion.length));
    suggestionShift += edit.delta;
  }

  final issues = <CorrectionItem>[];
  for (var i = 0; i < issueEdits.length; i++) {
    final edit = issueEdits[i];
    final (afterStart, afterEnd) = issueRangesAfter[i];
    final rewritten = suggestionEdits.any(
      (s) => _rangesOverlap(afterStart, afterEnd, s.start, s.end),
    );
    int? finalStart;
    int? finalEnd;
    if (!rewritten) {
      final shift = suggestionEdits
          .where((s) => s.end <= afterStart)
          .fold<int>(0, (sum, s) => sum + s.delta);
      finalStart = afterStart + shift;
      finalEnd = afterEnd + shift;
    }
    issues.add(
      CorrectionItem(
        originalPhrase: edit.item.written,
        correctedPhrase: edit.item.suggestion,
        category: edit.category,
        shortExplanation: edit.item.reason,
        startIndex: _graphemeIndex(originalText, edit.start),
        endIndex: _graphemeIndex(originalText, edit.end),
        correctedStartIndex: finalStart == null
            ? null
            : _graphemeIndex(suggestedText, finalStart),
        correctedEndIndex: finalEnd == null
            ? null
            : _graphemeIndex(suggestedText, finalEnd),
      ),
    );
  }

  final suggestions = <CorrectionItem>[];
  for (var i = 0; i < suggestionEdits.length; i++) {
    final edit = suggestionEdits[i];
    final (finalStart, finalEnd) = suggestionRangesFinal[i];
    final touchesIssue = issueRangesAfter.any(
      (r) => _rangesOverlap(edit.start, edit.end, r.$1, r.$2),
    );
    int? originalStart;
    int? originalEnd;
    if (!touchesIssue) {
      var shift = 0;
      for (var j = 0; j < issueEdits.length; j++) {
        if (issueRangesAfter[j].$2 <= edit.start) shift += issueEdits[j].delta;
      }
      originalStart = edit.start - shift;
      originalEnd = edit.end - shift;
    }
    suggestions.add(
      CorrectionItem(
        originalPhrase: edit.item.written,
        correctedPhrase: edit.item.suggestion,
        category: edit.category,
        shortExplanation: edit.item.reason,
        startIndex: originalStart == null
            ? null
            : _graphemeIndex(originalText, originalStart),
        endIndex: originalEnd == null
            ? null
            : _graphemeIndex(originalText, originalEnd),
        correctedStartIndex: _graphemeIndex(suggestedText, finalStart),
        correctedEndIndex: _graphemeIndex(suggestedText, finalEnd),
      ),
    );
  }

  return SuggestionCheckResult(
    originalText: originalText,
    textAfterIssues: textAfterIssues,
    suggestedText: suggestedText,
    issues: issues,
    suggestions: suggestions,
  );
}

final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Where [written] occurs in [text] as a whole word or phrase: not inside a
/// longer word, so "cafe" does not match inside "cafeteria". The check
/// applies only at an end of [written] that is itself a letter or digit,
/// so a span that starts or ends with a space or punctuation (", y") still
/// matches. Same rule as the E.3 test program.
List<int> wholeWordMatches(String text, String written) {
  if (written.isEmpty) return const [];
  final matches = <int>[];
  var from = 0;
  while (true) {
    final i = text.indexOf(written, from);
    if (i == -1) break;
    final end = i + written.length;
    final startOk =
        !_wordChar.hasMatch(written[0]) ||
        i == 0 ||
        !_wordChar.hasMatch(text[i - 1]);
    final endOk =
        !_wordChar.hasMatch(written[written.length - 1]) ||
        end == text.length ||
        !_wordChar.hasMatch(text[end]);
    if (startOk && endOk) matches.add(i);
    from = i + 1;
  }
  return matches;
}

int _graphemeIndex(String text, int codeUnitIndex) =>
    text.substring(0, codeUnitIndex).characters.length;

/// Whether half-open ranges `[aStart, aEnd)` and `[bStart, bEnd)` overlap.
/// An empty range (an insertion point) overlaps another range only when it
/// sits strictly inside it, or at the same point as another empty range.
bool _rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) {
  final aEmpty = aStart == aEnd;
  final bEmpty = bStart == bEnd;
  if (aEmpty && bEmpty) return aStart == bStart;
  if (aEmpty) return aStart > bStart && aStart < bEnd;
  if (bEmpty) return bStart > aStart && bStart < aEnd;
  return aStart < bEnd && bStart < aEnd;
}
