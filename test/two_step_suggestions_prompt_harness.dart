// Two-step suggestions prompt harness (build step E.3; decisions P4, P5,
// C1, C3, C4).
//
// Purpose: try the REWORKED two-step check in the test harness only. No
// app code is changed or called. Each step makes ONE call and returns a
// list of four-part items: what was written, the suggestion, a category,
// and a one-line reason.
//
// - Step 1 runs on GPT-6 Luna and returns only Issue categories:
//   Spelling, Grammar, Word meaning.
// - Step 2 runs on GPT-6 Sol, reads the text AFTER step 1's suggestions
//   have been applied, and returns only Natural phrasing. The
//   unnecessary-pronoun instruction lives in this step's prompt.
//
// Wording rules (C1): a reason line never says "wrong", "error" or
// "incorrect"; forms common in speech but avoided in careful writing are
// acknowledged as such. Regional forms are flagged in neither step
// (C3, C4).
//
// The harness MEASURES; it does not gate (P5). The report lists the pass
// rate against the same 84 test sentences as the baseline
// (`test/two_pass_linear_prompt_comparison_harness.dart`), speed and cost
// per call, and how often a reason line broke the wording rule.
//
// Run offline (no API calls):
//   flutter test test/two_step_suggestions_prompt_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls: 2 per run; all 84 sentences
// five times each is up to 850 calls):
//   OPENAI_API_KEY=sk-... \
//   TWO_STEP_LIVE=true \
//   TWO_STEP_FIXTURE_SET=all \
//   TWO_STEP_RUNS_PER_FIXTURE=5 \
//   TWO_STEP_OUTPUT=docs/two_step_suggestions_all_5x.md \
//   flutter test test/two_step_suggestions_prompt_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - TWO_STEP_ISSUES_MODEL: defaults to gpt-6-luna.
// - TWO_STEP_SUGGESTIONS_MODEL: defaults to gpt-6-sol.
// - TWO_STEP_FIXTURE_SET: "all" (default), "comparison", "fixture_id"
//   (with TWO_STEP_FIXTURE_ID) or "language_point" (with
//   TWO_STEP_LANGUAGE_POINT).
// - TWO_STEP_RUNS_PER_FIXTURE: defaults to 1.
// - TWO_STEP_CALL_DELAY_MS: pause between runs, defaults to 750.
// - TWO_STEP_OUTPUT: report path, defaults to docs/two_step_suggestions.md.
// - TWO_STEP_ONE_PROMPT: "full" (default) or "lean": the lean one-call
//   prompt has only the categories, item shape, wording rules and the
//   regional line, and never touches commas. For isolating the model.
// - TWO_STEP_MODE: "two" (default) or "one". In "one" mode the merged
//   prompt (oneStepPrompt) runs once per sentence on TWO_STEP_ONE_MODEL
//   (defaults to gpt-6-luna) and returns all four categories; the report
//   then has one cost row. Run it once per model to compare them:
//     TWO_STEP_LIVE=true TWO_STEP_MODE=one TWO_STEP_ONE_MODEL=gpt-6-luna \
//     TWO_STEP_FIXTURE_SET=all TWO_STEP_RUNS_PER_FIXTURE=5 \
//     TWO_STEP_OUTPUT=docs/one_step_luna_5x.md \
//     flutter test test/two_step_suggestions_prompt_harness.dart --tags live --timeout none

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_review.dart';

import 'two_pass_integration_harness.dart'
    show
        CallStats,
        FixtureResult,
        TwoPassFixture,
        TwoPassScoreLabel,
        TwoPassScoreLabelReportName,
        allTwoPassFixtures,
        isPassingScore,
        scoreFixtureResult,
        statsFor;
import 'two_pass_linear_prompt_comparison_harness.dart'
    show linearFixturesFor;

// ---------------------------------------------------------------------------
// Categories, prompts and response format
// ---------------------------------------------------------------------------

/// Categories step 1 may return (Issues).
const List<String> issueCategories = ['Spelling', 'Grammar', 'Word meaning'];

/// The only category step 2 may return (Suggestions).
const List<String> suggestionCategories = ['Natural phrasing'];

const String _itemShape =
    'Return a JSON object with one field, "items": a list. Each item has '
    'exactly four fields:\n'
    '- "written": the words exactly as the learner wrote them, copied '
    'character for character from the text. Keep it as short as it can be '
    'while still being unique in the text. Where you remove words, include '
    'enough neighbouring words that the change is clear.\n'
    '- "suggestion": what to put in their place. Give exactly one '
    'suggestion, never a list of alternatives and never "or". Use an empty '
    'string only when the right suggestion is to delete the words.\n'
    '- "category": one of the allowed categories named above.\n'
    '- "reason": one short plain-English sentence for a learner of '
    'Spanish.\n';

const String _reasonRules =
    'Rules for the reason line:\n'
    '- Never use the words "wrong", "error" or "incorrect" (or "mistake").\n'
    '- Be neutral and kind. Say what the suggested form does, for example '
    '"Spanish needs the accent mark here" or "In Spanish this verb goes '
    'with a different noun".\n'
    '- If the learner\'s form is common in speech but avoided in careful '
    'writing, say so, for example "Common in speech; careful writing '
    'usually avoids it".\n';

/// Step 1 (GPT-6 Luna): Issues only.
const String issuesStepPrompt =
    'You are a Spanish tutor checking a learner\'s writing for issues. '
    'The text may be typed or transcribed.\n'
    '\n'
    'Report only these categories:\n'
    '- Spelling: misspelled words, missing or wrong accent marks, missing '
    'ñ, missing opening question or exclamation marks, capitalisation and '
    'punctuation that Spanish writing requires.\n'
    '- Grammar: agreement of gender, number and person, verb forms and '
    'tenses, mood (including the subjunctive), articles, required '
    'prepositions, the personal "a", required pronouns such as "le" or '
    '"se", ser/estar/haber, and missing words that Spanish grammar needs.\n'
    '- Word meaning: a real Spanish word used with the wrong meaning, such '
    'as a false friend, or a word or verb that does not combine with its '
    'noun the way Spanish does.\n'
    '\n'
    'Do not report anything else. In particular do not suggest more '
    'natural, more idiomatic or more fluent wording, and do not remove '
    'words only because they are repeated or unnecessary; another step '
    'handles those.\n'
    '\n'
    'Do not flag regional forms. Forms used in some Spanish-speaking '
    'regions but not others, including regional pronouns, verb forms, '
    'vocabulary and tense preferences, are valid and must be left alone.\n'
    '\n'
    'Most text needs few changes, and some needs none. If there is '
    'nothing to report, return an empty list. If a sentence has several '
    'separate issues, report each one as its own item.\n'
    '\n'
    'The allowed categories are: Spelling, Grammar, Word meaning.\n'
    '\n'
    '$_itemShape'
    '\n'
    '$_reasonRules'
    '\n'
    'Return JSON only, with no Markdown and no commentary.';

/// Step 2 (GPT-6 Sol): Natural phrasing only. Includes the
/// unnecessary-pronoun line.
const String suggestionsStepPrompt =
    'You are a Spanish tutor reading a learner\'s writing that has '
    'already been checked for spelling, grammar and word meaning. Your '
    'job is to suggest more natural phrasing where a native writer would '
    'clearly say it differently.\n'
    '\n'
    'Report only one category: Natural phrasing. Do not report spelling, '
    'grammar or word meaning; leave those alone even if you notice them.\n'
    '\n'
    'Things to look for:\n'
    '- Unnecessary subject pronouns. Spanish usually drops the subject '
    'pronoun when the verb already shows who is acting. When the same '
    'pronoun is repeated for no reason in a second clause, suggest '
    'removing the repeated one and keep the first. Keep any pronoun that '
    'adds contrast, emphasis or clarity.\n'
    '- Repeated words or phrases that add nothing.\n'
    '- Literal translations from English that are understandable but that '
    'a Spanish speaker would not say.\n'
    '\n'
    'Leave alone anything that Spanish speakers commonly say, even if '
    'another wording is also possible. Do not flag regional forms: forms '
    'used in some Spanish-speaking regions but not others are valid. '
    'Do not change the meaning, add information, or rewrite the whole '
    'sentence. Make the smallest change that fixes the phrasing.\n'
    '\n'
    'Most text needs no suggestions. If there is nothing to report, '
    'return an empty list.\n'
    '\n'
    'The only allowed category is: Natural phrasing.\n'
    '\n'
    '$_itemShape'
    '\n'
    '$_reasonRules'
    '\n'
    'Return JSON only, with no Markdown and no commentary.';

/// All four categories, for the one-call mode.
const List<String> allCategories = [
  ...issueCategories,
  ...suggestionCategories,
];

/// One-call mode: the two step prompts merged into a single prompt that may
/// return all four categories. Run once with each model to compare it with
/// the two-step check. Same item shape, same wording rules, same "do not
/// flag regional forms" line; adds "go word by word and report every
/// instance", since one call has no second look.
const String oneStepPrompt =
    'You are a Spanish tutor checking a learner\'s writing. The text may '
    'be typed or transcribed. Read it word by word, from the first word '
    'to the last, and report every point you find; a sentence often has '
    'more than one, so do not stop after the first.\n'
    '\n'
    'Report these categories:\n'
    '- Spelling: misspelled words, missing or wrong accent marks, missing '
    'ñ, missing opening question or exclamation marks, capitalisation and '
    'punctuation that Spanish writing requires.\n'
    '- Grammar: agreement of gender, number and person, verb forms and '
    'tenses, mood (including the subjunctive), articles, required '
    'prepositions, the personal "a", required pronouns such as "le" or '
    '"se", ser/estar/haber, and missing words that Spanish grammar needs.\n'
    '- Word meaning: a real Spanish word used with the wrong meaning, such '
    'as a false friend, or a word or verb that does not combine with its '
    'noun the way Spanish does.\n'
    '- Natural phrasing: wording a native writer would clearly say '
    'differently. This includes unnecessary subject pronouns (Spanish '
    'usually drops the pronoun when the verb already shows who is acting; '
    'when the same pronoun is repeated for no reason in a second clause, '
    'suggest removing the repeated one and keep the first; keep a pronoun '
    'that adds contrast or emphasis), repeated words that add nothing, '
    'and literal translations from English that a Spanish speaker would '
    'not say.\n'
    '\n'
    'Check every accent mark and every article in the text, not only the '
    'first one you notice. Do not add or remove a comma before "y" unless '
    'Spanish punctuation requires it.\n'
    '\n'
    'Leave alone anything that Spanish speakers commonly say, even if '
    'another wording is also possible. Do not change the meaning, add '
    'information, or rewrite the whole sentence. Make the smallest change '
    'that fixes each point.\n'
    '\n'
    'Do not flag regional forms. Forms used in some Spanish-speaking '
    'regions but not others, including regional pronouns, verb forms, '
    'vocabulary and tense preferences, are valid and must be left alone.\n'
    '\n'
    'Most text needs few changes, and some needs none. If there is '
    'nothing to report, return an empty list.\n'
    '\n'
    'The allowed categories are: Spelling, Grammar, Word meaning, Natural '
    'phrasing.\n'
    '\n'
    '$_itemShape'
    '\n'
    '$_reasonRules'
    '\n'
    'Return JSON only, with no Markdown and no commentary.';

/// Lean one-call prompt, for isolating the model from the prompt: the same
/// four categories and item shape, the wording rules and the regional line,
/// and nothing else. No accent or article reminders, no example sentences,
/// and commas are simply never touched. Pick it with TWO_STEP_ONE_PROMPT=lean.
const String oneStepLeanPrompt =
    'You are a Spanish tutor checking a learner\'s writing. Report every '
    'point you find, each as its own item.\n'
    '\n'
    'Categories:\n'
    '- Spelling: misspellings, missing accent marks or ñ, missing opening '
    '¿ or ¡.\n'
    '- Grammar: agreement, verb forms and moods, articles, required '
    'prepositions and pronouns, ser/estar/haber, missing words.\n'
    '- Word meaning: a word used with the wrong meaning, or a verb that '
    'does not go with its noun in Spanish.\n'
    '- Natural phrasing: wording a native writer would clearly say '
    'differently, including a subject pronoun repeated for no reason in a '
    'second clause (suggest removing the repeated one, keep the first).\n'
    '\n'
    'Never add or remove commas. Do not flag regional forms. Leave alone '
    'anything Spanish speakers commonly say. Make the smallest change that '
    'fixes each point. If there is nothing to report, return an empty '
    'list.\n'
    '\n'
    'The allowed categories are: Spelling, Grammar, Word meaning, Natural '
    'phrasing.\n'
    '\n'
    '$_itemShape'
    '\n'
    '$_reasonRules'
    '\n'
    'Return JSON only, with no Markdown and no commentary.';

/// Strict JSON schema for one step's reply. [categories] is the closed
/// list of values that step may use.
Map<String, Object?> suggestionResponseFormat(List<String> categories) => {
  'type': 'json_schema',
  'json_schema': {
    'name': 'suggestion_items_response',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['items'],
      'properties': {
        'items': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['written', 'suggestion', 'category', 'reason'],
            'properties': {
              'written': {'type': 'string'},
              'suggestion': {'type': 'string'},
              'category': {'type': 'string', 'enum': categories},
              'reason': {'type': 'string'},
            },
          },
        },
      },
    },
  },
};

// ---------------------------------------------------------------------------
// Items: parsing, checking and applying
// ---------------------------------------------------------------------------

/// One four-part item as a step returns it.
class SuggestionItem {
  const SuggestionItem({
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

/// Parses a step's reply. Tolerates Markdown fences or commentary around
/// the JSON object. Throws [FormatException] when there is no object or no
/// "items" list; skips (rather than throws on) an item with a missing or
/// non-string field.
List<SuggestionItem> parseSuggestionItems(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end <= start) {
    throw const FormatException('No JSON object found in the reply.');
  }
  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Reply JSON is not an object.');
  }
  final items = decoded['items'];
  if (items is! List) {
    throw const FormatException('Reply has no "items" list.');
  }
  final result = <SuggestionItem>[];
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
      SuggestionItem(
        written: written,
        suggestion: suggestion,
        category: category,
        reason: reason,
      ),
    );
  }
  return result;
}

/// Splits [items] into the ones this step may use and the ones it may not:
/// a category outside [allowedCategories], an empty "written", or a
/// "written" that is not found in [text].
class CheckedItems {
  const CheckedItems({required this.kept, required this.dropped});
  final List<SuggestionItem> kept;
  final List<SuggestionItem> dropped;
}

CheckedItems checkItems({
  required String text,
  required List<SuggestionItem> items,
  required List<String> allowedCategories,
}) {
  final kept = <SuggestionItem>[];
  final dropped = <SuggestionItem>[];
  for (final item in items) {
    final ok =
        allowedCategories.contains(item.category) &&
        item.written.isNotEmpty &&
        text.contains(item.written);
    (ok ? kept : dropped).add(item);
  }
  return CheckedItems(kept: kept, dropped: dropped);
}

/// The result of applying items to a text.
class AppliedItems {
  const AppliedItems({
    required this.text,
    required this.applied,
    required this.notApplied,
  });
  final String text;
  final List<SuggestionItem> applied;

  /// Items whose "written" no longer matched exactly once, so they were
  /// left out rather than guessed at.
  final List<SuggestionItem> notApplied;
}

final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

/// Where [written] occurs in [text] as a whole word (or whole phrase): not
/// inside a longer word, so "cafe" does not match inside "cafeteria" and
/// "estudia" does not match inside "estudiar". The boundary check applies
/// only at an end of [written] that is itself a letter or digit, so a
/// written span that starts or ends with a space or punctuation (", y")
/// still matches.
List<int> wholeWordMatches(String text, String written) {
  if (written.isEmpty) return const [];
  final matches = <int>[];
  var from = 0;
  while (true) {
    final i = text.indexOf(written, from);
    if (i == -1) break;
    final end = i + written.length;
    final startOk = !_wordChar.hasMatch(written[0]) ||
        i == 0 ||
        !_wordChar.hasMatch(text[i - 1]);
    final endOk = !_wordChar.hasMatch(written[written.length - 1]) ||
        end == text.length ||
        !_wordChar.hasMatch(text[end]);
    if (startOk && endOk) matches.add(i);
    from = i + 1;
  }
  return matches;
}

/// Applies [items] to [text] one after another. An item is applied when its
/// "written" occurs exactly once in the text as a whole word or phrase; an
/// item that matches nowhere, or as a whole word in more than one place, is
/// left out rather than guessed at.
AppliedItems applyItems(String text, List<SuggestionItem> items) {
  var current = text;
  final applied = <SuggestionItem>[];
  final notApplied = <SuggestionItem>[];
  for (final item in items) {
    final matches = wholeWordMatches(current, item.written);
    if (matches.length != 1) {
      notApplied.add(item);
      continue;
    }
    final first = matches.single;
    current = current.replaceRange(
      first,
      first + item.written.length,
      item.suggestion,
    );
    applied.add(item);
  }
  return AppliedItems(text: current, applied: applied, notApplied: notApplied);
}

final RegExp _bannedReasonWords = RegExp(
  r'\b(wrong|wrongly|errors?|incorrect|incorrectly|mistakes?)\b',
  caseSensitive: false,
);

/// Whether [reason] uses a word the wording rules (C1) forbid.
bool reasonBreaksWordingRule(String reason) =>
    _bannedReasonWords.hasMatch(reason);

// ---------------------------------------------------------------------------
// Running the two steps
// ---------------------------------------------------------------------------

const String defaultIssuesModel = 'gpt-6-luna';
const String defaultSuggestionsModel = 'gpt-6-sol';
const String defaultTwoStepOutputPath = 'docs/two_step_suggestions.md';

String _userContent(String text) => 'Text to review:\n$text';

/// Everything one run of the two steps produced for one sentence.
class TwoStepResult {
  const TwoStepResult({
    required this.fixture,
    required this.runIndex,
    required this.issueItems,
    required this.issuesDropped,
    required this.issuesNotApplied,
    required this.textAfterIssues,
    required this.suggestionItems,
    required this.suggestionsDropped,
    required this.suggestionsNotApplied,
    required this.finalText,
    required this.issuesStats,
    required this.suggestionsStats,
    required this.score,
    this.error,
  });

  final TwoPassFixture fixture;
  final int runIndex;
  final List<SuggestionItem> issueItems;
  final List<SuggestionItem> issuesDropped;
  final List<SuggestionItem> issuesNotApplied;
  final String textAfterIssues;
  final List<SuggestionItem> suggestionItems;
  final List<SuggestionItem> suggestionsDropped;
  final List<SuggestionItem> suggestionsNotApplied;
  final String finalText;
  final CallStats issuesStats;
  final CallStats suggestionsStats;
  final TwoPassScoreLabel score;

  /// The service's failure message when every retry failed and this run is
  /// scored [TwoPassScoreLabel.error]; null otherwise.
  final String? error;

  bool get passed => isPassingScore(score);

  List<SuggestionItem> get allShownItems => [...issueItems, ...suggestionItems];

  int get reasonsBreakingWordingRule =>
      allShownItems.where((i) => reasonBreaksWordingRule(i.reason)).length;

  CallStats get totalStats => issuesStats + suggestionsStats;
}

/// Scores [finalText] against [fixture] with the same scorer the baseline
/// harness uses, so the pass rates are directly comparable.
TwoPassScoreLabel scoreFinalText(TwoPassFixture fixture, String finalText) {
  const emptyReview = NaturalnessReview(hasNaturalnessIssue: false, issues: []);
  return scoreFixtureResult(
    FixtureResult(
      fixture: fixture,
      firstPassCorrectedText: finalText,
      firstPassStats: CallStats.zero,
      naturalnessOnOriginal: emptyReview,
      naturalnessOnOriginalStats: CallStats.zero,
      naturalnessOnFirstPass: emptyReview,
      naturalnessOnFirstPassStats: CallStats.zero,
      parallelPhaseWallClockMs: 0,
      hadConflict: false,
      usedFallback: false,
      finalCorrectedText: finalText,
      finalCorrectionCount: 0,
    ),
  );
}

Future<({List<SuggestionItem> items, CallStats stats})> _callStep({
  required String apiKey,
  required HttpClient httpClient,
  required String model,
  required String systemPrompt,
  required List<String> categories,
  required String stageLabel,
  required String text,
}) async {
  final usage = <ChatCompletionsUsage>[];
  final client = OpenAiChatCompletionsClient(
    apiKey: apiKey,
    httpClient: httpClient,
    onUsage: usage.add,
  );
  final stopwatch = Stopwatch()..start();
  final reply = await _withRetries(
    () => client.complete(
      model: model,
      systemPrompt: systemPrompt,
      userText: _userContent(text),
      stageLabel: stageLabel,
      responseFormat: suggestionResponseFormat(categories),
    ),
  );
  stopwatch.stop();
  return (
    items: parseSuggestionItems(reply),
    stats: statsFor(usage, wallClockMs: stopwatch.elapsedMilliseconds),
  );
}

/// How many times one call is attempted before the run is given up: the
/// first try plus [callRetries] more, with a pause of 2, 4 and 8 seconds
/// between tries. A dropped connection or a 5xx from the service is a
/// passing fault, not a result, and one of those must not throw away a
/// fifteen-minute sweep.
const int callRetries = 3;

Duration _retryPause(int attempt) => Duration(seconds: 1 << attempt);

Future<T> _withRetries<T>(
  Future<T> Function() call, {
  Duration Function(int attempt) pauseFor = _retryPause,
}) async {
  var attempt = 0;
  while (true) {
    try {
      return await call();
    } on ChatCompletionsException catch (e) {
      attempt++;
      if (attempt > callRetries) rethrow;
      final pause = pauseFor(attempt);
      // ignore: avoid_print
      print('    call failed (${e.message.split('\n').first}); retrying '
          'in ${pause.inSeconds}s (try ${attempt + 1} of ${callRetries + 1})');
      await Future<void>.delayed(pause);
    }
  }
}

/// Runs [body] and, if every retry has failed, returns a result scored as
/// [TwoPassScoreLabel.error] for [fixture] instead of aborting the sweep.
Future<TwoStepResult> _orErrorResult(
  TwoPassFixture fixture,
  int runIndex,
  Future<TwoStepResult> Function() body,
) async {
  try {
    return await body();
  } on ChatCompletionsException catch (e) {
    return TwoStepResult(
      fixture: fixture,
      runIndex: runIndex,
      issueItems: const [],
      issuesDropped: const [],
      issuesNotApplied: const [],
      textAfterIssues: fixture.text,
      suggestionItems: const [],
      suggestionsDropped: const [],
      suggestionsNotApplied: const [],
      finalText: fixture.text,
      issuesStats: CallStats.zero,
      suggestionsStats: CallStats.zero,
      score: TwoPassScoreLabel.error,
      error: e.message.split('\n').first,
    );
  }
}

/// Runs both steps, one after the other, on [fixture]'s sentence.
Future<TwoStepResult> runTwoStep({
  required String apiKey,
  required HttpClient httpClient,
  required String issuesModel,
  required String suggestionsModel,
  required TwoPassFixture fixture,
  int runIndex = 1,
}) => _orErrorResult(fixture, runIndex, () async {
  final step1 = await _callStep(
    apiKey: apiKey,
    httpClient: httpClient,
    model: issuesModel,
    systemPrompt: issuesStepPrompt,
    categories: issueCategories,
    stageLabel: 'two_step_issues',
    text: fixture.text,
  );
  final checked1 = checkItems(
    text: fixture.text,
    items: step1.items,
    allowedCategories: issueCategories,
  );
  final applied1 = applyItems(fixture.text, checked1.kept);

  final step2 = await _callStep(
    apiKey: apiKey,
    httpClient: httpClient,
    model: suggestionsModel,
    systemPrompt: suggestionsStepPrompt,
    categories: suggestionCategories,
    stageLabel: 'two_step_suggestions',
    text: applied1.text,
  );
  final checked2 = checkItems(
    text: applied1.text,
    items: step2.items,
    allowedCategories: suggestionCategories,
  );
  final applied2 = applyItems(applied1.text, checked2.kept);

  return TwoStepResult(
    fixture: fixture,
    runIndex: runIndex,
    issueItems: applied1.applied,
    issuesDropped: checked1.dropped,
    issuesNotApplied: applied1.notApplied,
    textAfterIssues: applied1.text,
    suggestionItems: applied2.applied,
    suggestionsDropped: checked2.dropped,
    suggestionsNotApplied: applied2.notApplied,
    finalText: applied2.text,
    issuesStats: step1.stats,
    suggestionsStats: step2.stats,
    score: scoreFinalText(fixture, applied2.text),
  );
});

/// One-call mode: runs [oneStepPrompt] once on [model]. The reply's Issue
/// items are recorded as step 1 items and its Natural phrasing items as
/// step 2 items, so the same report and scorer apply; the one call's time
/// and cost are recorded under step 1 and step 2 is zero.
Future<TwoStepResult> runOneStep({
  required String apiKey,
  required HttpClient httpClient,
  required String model,
  required TwoPassFixture fixture,
  int runIndex = 1,
  String prompt = oneStepPrompt,
}) => _orErrorResult(fixture, runIndex, () async {
  final step = await _callStep(
    apiKey: apiKey,
    httpClient: httpClient,
    model: model,
    systemPrompt: prompt,
    categories: allCategories,
    stageLabel: 'one_step_check',
    text: fixture.text,
  );
  final checked = checkItems(
    text: fixture.text,
    items: step.items,
    allowedCategories: allCategories,
  );
  final applied = applyItems(fixture.text, checked.kept);
  bool isIssue(SuggestionItem i) => issueCategories.contains(i.category);

  return TwoStepResult(
    fixture: fixture,
    runIndex: runIndex,
    issueItems: applied.applied.where(isIssue).toList(),
    issuesDropped: checked.dropped,
    issuesNotApplied: applied.notApplied,
    textAfterIssues: applied.text,
    suggestionItems: applied.applied.where((i) => !isIssue(i)).toList(),
    suggestionsDropped: const [],
    suggestionsNotApplied: const [],
    finalText: applied.text,
    issuesStats: step.stats,
    suggestionsStats: CallStats.zero,
    score: scoreFinalText(fixture, applied.text),
  );
});

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

/// The baseline this rework is measured against (build step E.2).
const String baselineSummary =
    'Baseline (step E.2, GPT-4.1 then GPT-5.1): 386 of 425 runs passed '
    '(90.8 per cent), about 2.0 seconds and 0.21 cents per check. The '
    'August reference was 84.5 per cent.';

String _cost(double? usd) =>
    usd == null ? 'unknown' : '\$${usd.toStringAsFixed(6)}';

String _items(List<SuggestionItem> items) => items.isEmpty
    ? '(none)'
    : items
          .map((i) => '${i.written} -> ${i.suggestion} [${i.category}: '
              '${i.reason}]')
          .join('<br>');

String _percent(int part, int whole) =>
    whole == 0 ? 'n/a' : '${(part * 100 / whole).toStringAsFixed(1)} per cent';

/// Builds the markdown report. Measures only; it passes no judgement.
String buildTwoStepReport({
  required String issuesModel,
  required String suggestionsModel,
  required List<TwoStepResult> results,
  required DateTime generatedAt,
  bool oneStep = false,
}) {
  final b = StringBuffer()
    ..writeln('# Two-step suggestions harness (build step E.3)')
    ..writeln()
    ..writeln(
      oneStep
          ? 'One-call mode: a single prompt returning all four categories '
                '(Spelling, Grammar, Word meaning, Natural phrasing) on '
                '`$issuesModel`. This report measures; it does not gate.'
          : 'Step 1 (Issues: Spelling, Grammar, Word meaning) on '
                '`$issuesModel`; step 2 (Suggestions: Natural phrasing) on '
                '`$suggestionsModel`, reading the text after step 1\'s '
                'suggestions were applied. This report measures; it does '
                'not gate.',
    )
    ..writeln()
    ..writeln(baselineSummary)
    ..writeln()
    ..writeln('- Total runs: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln();

  final passed = results.where((r) => r.passed).length;
  b
    ..writeln('## Overall')
    ..writeln()
    ..writeln(
      '**Pass rate: $passed of ${results.length} '
      '(${_percent(passed, results.length)}).**',
    )
    ..writeln();

  // Score breakdown.
  b
    ..writeln('| Score | Runs |')
    ..writeln('| --- | --- |');
  for (final label in TwoPassScoreLabel.values) {
    b.writeln(
      '| ${label.reportLabel} | '
      '${results.where((r) => r.score == label).length} |',
    );
  }
  b.writeln();

  // Per language point.
  final points = <String>[];
  for (final r in results) {
    if (!points.contains(r.fixture.languagePoint)) {
      points.add(r.fixture.languagePoint);
    }
  }
  b
    ..writeln('## Pass rate per language point')
    ..writeln()
    ..writeln('| Language point | Passed | Runs | Pass rate |')
    ..writeln('| --- | --- | --- | --- |');
  for (final point in points) {
    final rows = results.where((r) => r.fixture.languagePoint == point);
    final ok = rows.where((r) => r.passed).length;
    b.writeln('| $point | $ok | ${rows.length} | ${_percent(ok, rows.length)} |');
  }
  b.writeln();

  // Speed and cost per call.
  CallStats sum(Iterable<CallStats> all) =>
      all.fold<CallStats>(CallStats.zero, (a, c) => a + c);
  final s1 = sum(results.map((r) => r.issuesStats));
  final s2 = sum(results.map((r) => r.suggestionsStats));
  final n = results.isEmpty ? 1 : results.length;
  b
    ..writeln('## Speed and cost per call')
    ..writeln()
    ..writeln('| Step | Model | Average time (ms) | Average cost | Total cost |')
    ..writeln('| --- | --- | --- | --- | --- |');
  if (oneStep) {
    b.writeln(
      '| One call | `$issuesModel` | ${(s1.wallClockMs / n).round()} | '
      '${_cost(s1.costUsd == null ? null : s1.costUsd! / n)} | '
      '${_cost(s1.costUsd)} |',
    );
  } else {
    b
      ..writeln(
        '| 1 Issues | `$issuesModel` | ${(s1.wallClockMs / n).round()} | '
        '${_cost(s1.costUsd == null ? null : s1.costUsd! / n)} | '
        '${_cost(s1.costUsd)} |',
      )
      ..writeln(
        '| 2 Suggestions | `$suggestionsModel` | '
        '${(s2.wallClockMs / n).round()} | '
        '${_cost(s2.costUsd == null ? null : s2.costUsd! / n)} | '
        '${_cost(s2.costUsd)} |',
      )
      ..writeln(
        '| Both | | ${((s1.wallClockMs + s2.wallClockMs) / n).round()} | '
        '${_cost(s1.costUsd == null || s2.costUsd == null ? null : (s1.costUsd! + s2.costUsd!) / n)} | '
        '${_cost(s1.costUsd == null || s2.costUsd == null ? null : s1.costUsd! + s2.costUsd!)} |',
      );
  }
  b.writeln();

  // Wording and housekeeping counts.
  final shown = results.fold<int>(0, (a, r) => a + r.allShownItems.length);
  final badReasons = results.fold<int>(
    0,
    (a, r) => a + r.reasonsBreakingWordingRule,
  );
  final dropped = results.fold<int>(
    0,
    (a, r) => a + r.issuesDropped.length + r.suggestionsDropped.length,
  );
  final notApplied = results.fold<int>(
    0,
    (a, r) => a + r.issuesNotApplied.length + r.suggestionsNotApplied.length,
  );
  b
    ..writeln('## Wording and housekeeping')
    ..writeln()
    ..writeln('- Items shown: `$shown`')
    ..writeln(
      '- Reason lines using "wrong", "error", "incorrect" or "mistake": '
      '`$badReasons`',
    )
    ..writeln(
      '- Items dropped (category not allowed for the step, or the written '
      'words were not in the text): `$dropped`',
    )
    ..writeln(
      '- Items that could not be applied (the written words were not '
      'found exactly once): `$notApplied`',
    )
    ..writeln();

  // Per-sentence detail.
  b
    ..writeln('## Every run')
    ..writeln()
    ..writeln(
      '| Sentence | Run | Original | Step 1 items | Step 2 items | Final '
      '| Score |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  for (final r in results) {
    b.writeln(
      '| ${r.fixture.id} | ${r.runIndex} | `${r.fixture.text}` | '
      '${_items(r.issueItems)} | ${_items(r.suggestionItems)} | '
      '`${r.finalText}` | ${r.passed ? 'Pass' : 'Fail'} '
      '(${r.score.reportLabel}${r.error == null ? '' : ': ${r.error}'}) |',
    );
  }
  return b.toString();
}

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

String _setting(Map<String, String> env, String key, String fallback) {
  final value = env[key]?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

bool twoStepLiveOptIn(Map<String, String> env) =>
    env['TWO_STEP_LIVE']?.trim().toLowerCase() == 'true';

/// `TWO_STEP_ONE_PROMPT`: "full" (default, [oneStepPrompt]) or "lean"
/// ([oneStepLeanPrompt]).
String oneStepPromptFrom(Map<String, String> env) {
  final variant = env['TWO_STEP_ONE_PROMPT']?.trim().toLowerCase() ?? '';
  if (variant.isEmpty || variant == 'full') return oneStepPrompt;
  if (variant == 'lean') return oneStepLeanPrompt;
  throw ArgumentError(
    'TWO_STEP_ONE_PROMPT must be "full" or "lean" (was "$variant").',
  );
}

/// `TWO_STEP_MODE`: "two" (default) runs the two steps; "one" runs
/// [oneStepPrompt] once on `TWO_STEP_ONE_MODEL`.
bool twoStepOneCallMode(Map<String, String> env) {
  final mode = env['TWO_STEP_MODE']?.trim().toLowerCase() ?? '';
  if (mode.isEmpty || mode == 'two') return false;
  if (mode == 'one') return true;
  throw ArgumentError('TWO_STEP_MODE must be "two" or "one" (was "$mode").');
}

int twoStepRunsPerFixtureFrom(Map<String, String> env) {
  final runs = int.tryParse(env['TWO_STEP_RUNS_PER_FIXTURE']?.trim() ?? '');
  if (runs == null) return 1;
  if (runs < 1) {
    throw ArgumentError('TWO_STEP_RUNS_PER_FIXTURE must be >= 1 (was $runs).');
  }
  return runs;
}

List<TwoPassFixture> twoStepFixturesFrom(Map<String, String> env) =>
    linearFixturesFor(
      _setting(env, 'TWO_STEP_FIXTURE_SET', 'all'),
      fixtureId: env['TWO_STEP_FIXTURE_ID']?.trim(),
      languagePoint: env['TWO_STEP_LANGUAGE_POINT']?.trim(),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('step prompts', () {
    test('step 1 names only the three Issue categories', () {
      expect(issuesStepPrompt, contains('Spelling'));
      expect(issuesStepPrompt, contains('Grammar'));
      expect(issuesStepPrompt, contains('Word meaning'));
      expect(issuesStepPrompt, isNot(contains('Natural phrasing')));
    });

    test('step 2 names only Natural phrasing', () {
      expect(suggestionsStepPrompt, contains('Natural phrasing'));
      expect(suggestionsStepPrompt, isNot(contains('Word meaning.')));
      expect(
        suggestionsStepPrompt,
        contains('The only allowed category is: Natural phrasing.'),
      );
    });

    test('the unnecessary-pronoun line is in step 2 and not in step 1', () {
      expect(suggestionsStepPrompt, contains('Unnecessary subject pronouns'));
      expect(suggestionsStepPrompt, contains('keep the first'));
      expect(issuesStepPrompt, isNot(contains('Unnecessary subject pronouns')));
    });

    test('both prompts forbid flagging regional forms', () {
      expect(issuesStepPrompt, contains('Do not flag regional forms'));
      expect(suggestionsStepPrompt, contains('Do not flag regional forms'));
    });

    test('both prompts carry the reason-line wording rules', () {
      for (final prompt in [issuesStepPrompt, suggestionsStepPrompt]) {
        expect(prompt, contains('Never use the words "wrong", "error"'));
        expect(prompt, contains('common in speech'));
        expect(prompt, contains('one short plain-English sentence'));
      }
    });

    test('both prompts ask for the four-part items', () {
      for (final prompt in [issuesStepPrompt, suggestionsStepPrompt]) {
        for (final field in ['written', 'suggestion', 'category', 'reason']) {
          expect(prompt, contains('"$field"'));
        }
      }
    });
  });

  group('prompts do not quote the test sentences', () {
    // Any run of four consecutive words from a test sentence appearing in
    // a prompt means the prompt is telling the model the answer, and the
    // score for that sentence measures nothing. Keep examples out of the
    // prompts, or invent ones that are not in the test set.
    String normalise(String text) => text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final prompts = {
      'issuesStepPrompt': normalise(issuesStepPrompt),
      'suggestionsStepPrompt': normalise(suggestionsStepPrompt),
      'oneStepPrompt': normalise(oneStepPrompt),
      'oneStepLeanPrompt': normalise(oneStepLeanPrompt),
    };

    test('no four-word run from any test sentence appears in any prompt', () {
      final offences = <String>[];
      for (final fixture in allTwoPassFixtures) {
        final words = normalise(fixture.text).split(' ');
        for (var i = 0; i + 4 <= words.length; i++) {
          final run = words.sublist(i, i + 4).join(' ');
          for (final entry in prompts.entries) {
            if (entry.value.contains(run)) {
              offences.add('${entry.key} quotes "${run}" (${fixture.id})');
            }
          }
        }
      }
      expect(offences, isEmpty, reason: offences.join('\n'));
    });

    test('no short test sentence appears whole in any prompt', () {
      final offences = <String>[];
      for (final fixture in allTwoPassFixtures) {
        final whole = normalise(fixture.text);
        for (final entry in prompts.entries) {
          if (entry.value.contains(whole)) {
            offences.add('${entry.key} quotes "${fixture.text}"');
          }
        }
      }
      expect(offences, isEmpty, reason: offences.join('\n'));
    });
  });

  group('response format', () {
    test('is strict and limits the category to the step\'s list', () {
      final format = suggestionResponseFormat(issueCategories);
      final schema = (format['json_schema']! as Map)['schema']! as Map;
      expect((format['json_schema']! as Map)['strict'], isTrue);
      final itemProps =
          (((schema['properties']! as Map)['items']! as Map)['items']!
                  as Map)['properties']!
              as Map;
      expect((itemProps['category']! as Map)['enum'], issueCategories);
      expect(
        (suggestionResponseFormat(suggestionCategories)['json_schema']!
                    as Map)['schema']
                .toString(),
        contains('Natural phrasing'),
      );
    });
  });

  group('parseSuggestionItems', () {
    test('reads four-part items and an empty list', () {
      final items = parseSuggestionItems(
        '{"items":[{"written":"trafico","suggestion":"tráfico",'
        '"category":"Spelling","reason":"Spanish needs the accent mark."}]}',
      );
      expect(items, hasLength(1));
      expect(items.single.written, 'trafico');
      expect(items.single.category, 'Spelling');
      expect(parseSuggestionItems('{"items":[]}'), isEmpty);
    });

    test('tolerates Markdown fences around the JSON', () {
      final items = parseSuggestionItems(
        '```json\n{"items":[{"written":"a","suggestion":"b",'
        '"category":"Grammar","reason":"r"}]}\n```',
      );
      expect(items, hasLength(1));
    });

    test('skips an item with a missing field', () {
      final items = parseSuggestionItems(
        '{"items":[{"written":"a","suggestion":"b","category":"Grammar"}]}',
      );
      expect(items, isEmpty);
    });

    test('throws when there is no JSON object or no items list', () {
      expect(() => parseSuggestionItems('nothing'), throwsFormatException);
      expect(() => parseSuggestionItems('{"x":1}'), throwsFormatException);
    });
  });

  group('checkItems and applyItems', () {
    const item = SuggestionItem(
      written: 'trafico',
      suggestion: 'tráfico',
      category: 'Spelling',
      reason: 'Spanish needs the accent mark.',
    );

    test('checkItems drops a category the step may not use', () {
      const natural = SuggestionItem(
        written: 'trafico',
        suggestion: 'x',
        category: 'Natural phrasing',
        reason: 'r',
      );
      final checked = checkItems(
        text: 'Vi mucho trafico ayer.',
        items: [item, natural],
        allowedCategories: issueCategories,
      );
      expect(checked.kept, [item]);
      expect(checked.dropped, [natural]);
    });

    test('checkItems drops written words that are not in the text', () {
      final checked = checkItems(
        text: 'Hola.',
        items: [item],
        allowedCategories: issueCategories,
      );
      expect(checked.kept, isEmpty);
      expect(checked.dropped, [item]);
    });

    test('applyItems replaces text and handles a deletion', () {
      const del = SuggestionItem(
        written: 'y ellos visitaron',
        suggestion: 'y visitaron',
        category: 'Natural phrasing',
        reason: 'r',
      );
      final applied = applyItems(
        'Ellos viajaron a México y ellos visitaron varias ciudades.',
        [del],
      );
      expect(
        applied.text,
        'Ellos viajaron a México y visitaron varias ciudades.',
      );
      expect(applied.applied, [del]);
    });

    test('applyItems matches whole words, so "cafe" is not "cafeteria"', () {
      const cafe = SuggestionItem(
        written: 'cafe',
        suggestion: 'café',
        category: 'Spelling',
        reason: 'r',
      );
      final applied = applyItems(
        'Compre cafe en una cafeteria pequena.',
        [cafe],
      );
      expect(applied.text, 'Compre café en una cafeteria pequena.');
      expect(applied.notApplied, isEmpty);
    });

    test('applyItems matches "estudia" without touching "estudiar"', () {
      const verb = SuggestionItem(
        written: 'estudia',
        suggestion: 'estudian',
        category: 'Grammar',
        reason: 'r',
      );
      final applied = applyItems(
        'Ellos estudia todas las noches, y creo que está bien estudiar hoy.',
        [verb],
      );
      expect(
        applied.text,
        'Ellos estudian todas las noches, y creo que está bien estudiar hoy.',
      );
    });

    test('a written span ending in punctuation or a space still matches', () {
      const comma = SuggestionItem(
        written: 'tráfico, y',
        suggestion: 'tráfico y',
        category: 'Spelling',
        reason: 'r',
      );
      final applied = applyItems('Vi mucho tráfico, y luego vi más.', [comma]);
      expect(applied.text, 'Vi mucho tráfico y luego vi más.');
    });

    test('applyItems leaves out an item that matches more than once', () {
      const twice = SuggestionItem(
        written: 'casa',
        suggestion: 'hogar',
        category: 'Word meaning',
        reason: 'r',
      );
      final applied = applyItems('casa y casa', [twice]);
      expect(applied.text, 'casa y casa');
      expect(applied.notApplied, [twice]);
    });

    test('applyItems applies items in order on the updated text', () {
      const first = SuggestionItem(
        written: 'iso',
        suggestion: 'hizo',
        category: 'Spelling',
        reason: 'r',
      );
      const second = SuggestionItem(
        written: 'hizo una decisión',
        suggestion: 'tomó una decisión',
        category: 'Word meaning',
        reason: 'r',
      );
      final applied = applyItems('Ayer iso una decisión importante.', [
        first,
        second,
      ]);
      expect(applied.text, 'Ayer tomó una decisión importante.');
    });
  });

  group('wording rule', () {
    test('flags wrong, error, incorrect and mistake in any form', () {
      for (final reason in [
        'This is wrong.',
        'An error in agreement.',
        'Incorrect verb.',
        'A common mistake.',
        'Errors like this are common.',
      ]) {
        expect(reasonBreaksWordingRule(reason), isTrue, reason: reason);
      }
    });

    test('allows neutral wording', () {
      expect(
        reasonBreaksWordingRule(
          'Spanish needs the accent mark here. Common in speech.',
        ),
        isFalse,
      );
    });
  });

  group('scoring', () {
    test('uses the baseline scorer on the final text', () {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      expect(
        isPassingScore(scoreFinalText(fixture, fixture.expectedCorrectedText)),
        isTrue,
      );
      expect(isPassingScore(scoreFinalText(fixture, fixture.text)), isFalse);
    });
  });

  group('settings', () {
    test('live runs are opt-in', () {
      expect(twoStepLiveOptIn({}), isFalse);
      expect(twoStepLiveOptIn({'TWO_STEP_LIVE': 'true'}), isTrue);
    });

    test('runs per sentence defaults to 1 and rejects less than 1', () {
      expect(twoStepRunsPerFixtureFrom({}), 1);
      expect(twoStepRunsPerFixtureFrom({'TWO_STEP_RUNS_PER_FIXTURE': '5'}), 5);
      expect(
        () => twoStepRunsPerFixtureFrom({'TWO_STEP_RUNS_PER_FIXTURE': '0'}),
        throwsArgumentError,
      );
    });

    test('the default sentence set is all of them', () {
      expect(twoStepFixturesFrom({}), hasLength(allTwoPassFixtures.length));
    });

    test('the default models are GPT-6 Luna and GPT-6 Sol', () {
      expect(defaultIssuesModel, 'gpt-6-luna');
      expect(defaultSuggestionsModel, 'gpt-6-sol');
    });

    test('the mode defaults to two steps and accepts "one"', () {
      expect(twoStepOneCallMode({}), isFalse);
      expect(twoStepOneCallMode({'TWO_STEP_MODE': 'two'}), isFalse);
      expect(twoStepOneCallMode({'TWO_STEP_MODE': 'one'}), isTrue);
      expect(
        () => twoStepOneCallMode({'TWO_STEP_MODE': 'three'}),
        throwsArgumentError,
      );
    });
  });

  group('one-call mode', () {
    test('the merged prompt names all four categories and the key rules', () {
      for (final category in allCategories) {
        expect(oneStepPrompt, contains(category));
      }
      expect(allCategories, hasLength(4));
      expect(oneStepPrompt, contains('report every point you find'));
      expect(oneStepPrompt, contains('Check every accent mark and every article'));
      expect(oneStepPrompt, contains('comma before "y"'));
      expect(oneStepPrompt, contains('keep the first'));
      expect(oneStepPrompt, contains('Do not flag regional forms'));
      expect(oneStepPrompt, contains('Never use the words "wrong", "error"'));
    });

    test('the lean prompt has the categories and never touches commas', () {
      for (final category in allCategories) {
        expect(oneStepLeanPrompt, contains(category));
      }
      expect(oneStepLeanPrompt, contains('Never add or remove commas'));
      expect(oneStepLeanPrompt, contains('Do not flag regional forms'));
      expect(oneStepLeanPrompt, contains('Never use the words "wrong", "error"'));
      expect(oneStepLeanPrompt, contains('keep the first'));
      expect(oneStepLeanPrompt.length, lessThan(oneStepPrompt.length));
    });

    test('the prompt variant defaults to full and accepts lean', () {
      expect(oneStepPromptFrom({}), oneStepPrompt);
      expect(oneStepPromptFrom({'TWO_STEP_ONE_PROMPT': 'full'}), oneStepPrompt);
      expect(
        oneStepPromptFrom({'TWO_STEP_ONE_PROMPT': 'lean'}),
        oneStepLeanPrompt,
      );
      expect(
        () => oneStepPromptFrom({'TWO_STEP_ONE_PROMPT': 'short'}),
        throwsArgumentError,
      );
    });

    test('the schema for one-call mode allows all four categories', () {
      final schema = suggestionResponseFormat(allCategories).toString();
      for (final category in allCategories) {
        expect(schema, contains(category));
      }
    });

    test('the one-call report names the mode and shows one cost row', () {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final report = buildTwoStepReport(
        issuesModel: 'gpt-6-sol',
        suggestionsModel: 'gpt-6-sol',
        oneStep: true,
        generatedAt: DateTime.utc(2026, 11, 7),
        results: [
          TwoStepResult(
            fixture: fixture,
            runIndex: 1,
            issueItems: const [],
            issuesDropped: const [],
            issuesNotApplied: const [],
            textAfterIssues: fixture.expectedCorrectedText,
            suggestionItems: const [],
            suggestionsDropped: const [],
            suggestionsNotApplied: const [],
            finalText: fixture.expectedCorrectedText,
            issuesStats: const CallStats(
              wallClockMs: 1500,
              totalTokens: 100,
              costUsd: 0.002,
            ),
            suggestionsStats: CallStats.zero,
            score: scoreFinalText(fixture, fixture.expectedCorrectedText),
          ),
        ],
      );
      expect(report, contains('One-call mode'));
      expect(report, contains('| One call | `gpt-6-sol` | 1500 |'));
      expect(report, isNot(contains('| 2 Suggestions |')));
      expect(report, contains('**Pass rate: 1 of 1 (100.0 per cent).**'));
    });
  });

  group('retries', () {
    test('a call that fails then succeeds is retried and returns', () async {
      var calls = 0;
      final result = await _withRetries(() async {
        calls++;
        if (calls < 3) {
          throw const ChatCompletionsException('HTTP 503: upstream reset');
        }
        return 'ok';
      }, pauseFor: (_) => Duration.zero);
      expect(result, 'ok');
      expect(calls, 3);
    });

    test('a call that keeps failing is given up after the retries', () async {
      var calls = 0;
      await expectLater(
        _withRetries(() async {
          calls++;
          throw const ChatCompletionsException('HTTP 503');
        }, pauseFor: (_) => Duration.zero),
        throwsA(isA<ChatCompletionsException>()),
      );
      expect(calls, callRetries + 1);
    });

    test('a run whose calls all fail is scored as an error, not thrown', () async {
      final fixture = allTwoPassFixtures.first;
      final result = await _orErrorResult(
        fixture,
        2,
        () async => throw const ChatCompletionsException('HTTP 503: reset'),
      );
      expect(result.score, TwoPassScoreLabel.error);
      expect(result.passed, isFalse);
      expect(result.runIndex, 2);
      expect(result.finalText, fixture.text);
      expect(result.error, 'HTTP 503: reset');
    });
  });

  group('report', () {
    TwoStepResult result({
      required String id,
      required String finalText,
      required List<SuggestionItem> issues,
      List<SuggestionItem> suggestions = const [],
    }) {
      final fixture = allTwoPassFixtures.firstWhere((f) => f.id == id);
      return TwoStepResult(
        fixture: fixture,
        runIndex: 1,
        issueItems: issues,
        issuesDropped: const [],
        issuesNotApplied: const [],
        textAfterIssues: finalText,
        suggestionItems: suggestions,
        suggestionsDropped: const [],
        suggestionsNotApplied: const [],
        finalText: finalText,
        issuesStats: const CallStats(
          wallClockMs: 1000,
          totalTokens: 100,
          costUsd: 0.001,
        ),
        suggestionsStats: const CallStats(
          wallClockMs: 3000,
          totalTokens: 100,
          costUsd: 0.003,
        ),
        score: scoreFinalText(fixture, finalText),
      );
    }

    test('states the baseline, pass rate, speed, cost and wording count', () {
      final good = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final report = buildTwoStepReport(
        issuesModel: 'gpt-6-luna',
        suggestionsModel: 'gpt-6-sol',
        generatedAt: DateTime.utc(2026, 11, 7),
        results: [
          result(
            id: 'clean-grammar-only',
            finalText: good.expectedCorrectedText,
            issues: const [
              SuggestionItem(
                written: 'trafico',
                suggestion: 'tráfico',
                category: 'Spelling',
                reason: 'This is an error.',
              ),
            ],
          ),
          result(
            id: 'delete-repeated-yo-estudio',
            finalText: 'Yo trabajo mucho y yo estudio por las noches.',
            issues: const [],
          ),
        ],
      );
      expect(report, contains('386 of 425'));
      expect(report, contains('**Pass rate: 1 of 2 (50.0 per cent).**'));
      expect(report, contains('`gpt-6-luna`'));
      expect(report, contains('`gpt-6-sol`'));
      expect(report, contains('| 1 Issues |'));
      expect(report, contains('| 2 Suggestions |'));
      expect(report, contains('| Both | | 4000 |'));
      expect(report, contains('"wrong", "error", "incorrect" or "mistake": `1`'));
      expect(report, contains('Unnecessary Extras / Deletions'));
    });
  });

  test(
    'two-step suggestions run against the test sentences',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!twoStepLiveOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live two-step run. Set TWO_STEP_LIVE=true to opt in.',
        );
        return;
      }

      final envKey = environment['OPENAI_API_KEY']?.trim() ?? '';
      final apiKey = envKey.isNotEmpty
          ? envKey
          : AppConfig.fromEnvironment().openAiApiKey.trim();
      if (apiKey.isEmpty) {
        fail(
          'No API key found. Set OPENAI_API_KEY, or put one in '
          'lib/app/app_config.dart.',
        );
      }

      final issuesModel = _setting(
        environment,
        'TWO_STEP_ISSUES_MODEL',
        defaultIssuesModel,
      );
      final suggestionsModel = _setting(
        environment,
        'TWO_STEP_SUGGESTIONS_MODEL',
        defaultSuggestionsModel,
      );
      final outputPath = _setting(
        environment,
        'TWO_STEP_OUTPUT',
        defaultTwoStepOutputPath,
      );
      final delayMs =
          int.tryParse(environment['TWO_STEP_CALL_DELAY_MS']?.trim() ?? '') ??
          750;
      final fixtures = twoStepFixturesFrom(environment);
      final runsPerFixture = twoStepRunsPerFixtureFrom(environment);
      final oneCall = twoStepOneCallMode(environment);
      final onePrompt = oneStepPromptFrom(environment);
      final oneModel = _setting(
        environment,
        'TWO_STEP_ONE_MODEL',
        defaultIssuesModel,
      );
      final httpClient = HttpClient();

      final results = <TwoStepResult>[];
      for (final fixture in fixtures) {
        for (var run = 1; run <= runsPerFixture; run++) {
          final result = oneCall
              ? await runOneStep(
                  apiKey: apiKey,
                  httpClient: httpClient,
                  model: oneModel,
                  fixture: fixture,
                  runIndex: run,
                  prompt: onePrompt,
                )
              : await runTwoStep(
                  apiKey: apiKey,
                  httpClient: httpClient,
                  issuesModel: issuesModel,
                  suggestionsModel: suggestionsModel,
                  fixture: fixture,
                  runIndex: run,
                );
          results.add(result);
          // ignore: avoid_print
          print(
            '=== ${fixture.id} (run $run/$runsPerFixture) === '
            'final="${result.finalText}" (${result.score.reportLabel}'
            '${result.error == null ? '' : ': ${result.error}'})',
          );
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }
      }

      final report = buildTwoStepReport(
        issuesModel: oneCall
            ? (onePrompt == oneStepLeanPrompt ? '$oneModel, lean prompt' : oneModel)
            : issuesModel,
        suggestionsModel: suggestionsModel,
        results: results,
        generatedAt: DateTime.now(),
        oneStep: oneCall,
      );
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote two-step suggestions report to $outputPath');
    },
  );
}
