// Suggestion two-step harness (build step E.3).
//
// Purpose: try out the reworked two-step prompts that the new check will
// use, WITHOUT touching the app. Nothing under lib/ is changed; this file
// is a test program only, and it does not gate anything (decision P5): it
// measures and reports.
//
// How it differs from test/two_pass_linear_prompt_comparison_harness.dart
// (the harness that produced the E.2 baseline):
// - Each step makes ONE call and returns a list of four-part items: what
//   was written, the suggestion, a category, and a one-line reason.
// - Step 1 runs on GPT-6 Luna and may only use the categories Spelling,
//   Grammar and Word meaning.
// - Step 2 runs on GPT-6 Sol and may only use the category Natural
//   phrasing. The unnecessary-pronoun line lives in this prompt.
// - Wording rules (C1): a reason never says "wrong", "error" or
//   "incorrect"; forms common in speech but avoided in careful writing
//   are acknowledged as such. Regional forms are flagged in neither step
//   (C3, C4).
// - Both steps read the submitted text as the learner wrote it, so each
//   item quotes the original. The harness then applies the items to the
//   original to get one suggested version, and scores that version with
//   the same fixtures and the same scoring as the baseline run, so the
//   two runs can be compared directly.
//
// Run the offline checks (no AI calls):
//   flutter test test/suggestion_two_step_harness.dart --exclude-tags live
//
// Run live (costs real money; only with Andrew's say-so). The key in
// lib/app/app_config.dart is used if OPENAI_API_KEY is not set:
//   SUGGESTION_LIVE=true flutter test test/suggestion_two_step_harness.dart \
//     --tags live --timeout none
//
// Optional settings (environment variables):
// - SUGGESTION_RUNS_PER_FIXTURE: runs per sentence, default 5.
// - SUGGESTION_FIXTURE_SET: "all" (default, the 85 sentences),
//   "fixture_id" (with SUGGESTION_FIXTURE_ID) or "language_point" (with
//   SUGGESTION_LANGUAGE_POINT).
// - SUGGESTION_ISSUES_MODEL: default gpt-6-luna.
// - SUGGESTION_PHRASING_MODEL: default gpt-6-sol.
// - SUGGESTION_OUTPUT: report path, default docs/suggestion_two_step_e3.md.
// - SUGGESTION_CALL_DELAY_MS: pause between runs, default 250.

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

// ---------------------------------------------------------------------------
// The two prompts
// ---------------------------------------------------------------------------

/// The categories step 1 may use.
const List<String> issueCategories = ['Spelling', 'Grammar', 'Word meaning'];

/// The one category step 2 may use.
const List<String> phrasingCategories = ['Natural phrasing'];

/// Words a reason line must never contain (wording rule C1).
const List<String> forbiddenReasonWords = ['wrong', 'error', 'incorrect'];

/// Step 1 (GPT-6 Luna): Issues only.
const String issuesStepPrompt =
    'You are a friendly Spanish tutor reading a learner\'s writing. The '
    'learner is a native English speaker.\n'
    '\n'
    'Your job in this step is to find ISSUES only: places where the '
    'Spanish does not work as written. Report an item only if it falls '
    'into one of these three categories:\n'
    '- Spelling: a misspelt word or a missing or wrong accent mark.\n'
    '- Grammar: agreement, verb forms and tenses, mood, articles, '
    'prepositions, missing or extra words that the grammar requires or '
    'forbids, and punctuation.\n'
    '- Word meaning: a word that means something different from what '
    'the learner plainly intended, such as a false friend '
    '("embarazada" for "embarrassed").\n'
    '\n'
    'Leave everything else alone. In particular:\n'
    '- Do not report wording that is correct but could sound more '
    'natural. Another step handles that.\n'
    '- Do not report subject pronouns that are merely unnecessary, such '
    'as a repeated "yo".\n'
    '- Do not report forms that are normal in any major variety of '
    'Spanish, including regional vocabulary, regional grammar and '
    'regional spelling. Spain and Latin America are both fine.\n'
    '- Do not report a phrase that authoritative Spanish references '
    'recognise as correct, even if you would have written it '
    'differently. If nothing needs reporting, return an empty list. '
    'Most short texts contain few items.\n'
    '\n'
    'Each item has four parts:\n'
    '- written: the exact words as the learner wrote them, copied '
    'character for character from the text. Include enough surrounding '
    'words that the place is clear, but keep it short. Never include '
    'the same words twice.\n'
    '- suggestion: what to write there instead. Give exactly one '
    'suggestion, with no alternatives, no slash and no "or". Make the '
    'smallest change that fixes the point, and keep the learner\'s '
    'meaning. If the suggestion is to delete words, give the shorter '
    'text without them.\n'
    '- category: exactly one of Spelling, Grammar, Word meaning.\n'
    '- reason: one short sentence in English saying why. Be kind and '
    'matter of fact. Never use the words "wrong", "error" or '
    '"incorrect". Where a form is common in everyday speech but '
    'usually avoided in careful writing, say so in the reason.\n'
    '\n'
    'Return JSON only, with no Markdown and no commentary.';

/// Step 2 (GPT-6 Sol): Natural phrasing only.
const String phrasingStepPrompt =
    'You are a friendly Spanish tutor reading a learner\'s writing. The '
    'learner is a native English speaker. Another step has already '
    'looked for spelling, grammar and word-meaning problems, so you '
    'must not report those.\n'
    '\n'
    'Your job in this step is NATURAL PHRASING only: the Spanish is '
    'understood, but it is not how a Spanish speaker would put it. '
    'This covers:\n'
    '- literal translations and calques from English;\n'
    '- idiomatic expressions the learner has translated word for '
    'word;\n'
    '- word partnerships, such as "hacer una decisión" where Spanish '
    'says "tomar una decisión";\n'
    '- a better word, where the learner\'s word is understood but not '
    'the usual choice;\n'
    '- unnecessary subject pronouns. Spanish usually leaves the '
    'subject pronoun out when the verb already shows the subject, so '
    'when a pronoun is repeated or adds nothing ("Yo trabajo mucho y '
    'yo estudio...", "Ellos viajaron a México y ellos visitaron...", '
    '"Nosotros salimos temprano y nosotros llegamos..."), suggest the '
    'version without it. Keep a pronoun that adds contrast or '
    'emphasis, or that stops the sentence being unclear.\n'
    '\n'
    'Leave everything else alone. In particular:\n'
    '- Do not report a phrase that authoritative Spanish references '
    'recognise as natural, even if another phrasing is more common '
    'or you would have written it differently.\n'
    '- Do not report forms that are normal in any major variety of '
    'Spanish, including regional vocabulary, regional grammar and '
    'regional spelling. Spain and Latin America are both fine. '
    '("Voy para casa" and "Voy a casa" are both fine.)\n'
    '- Do not report spelling, grammar or punctuation.\n'
    '- Do not rewrite whole sentences. Make the smallest change that '
    'fixes the point, and keep the learner\'s meaning.\n'
    'If nothing needs reporting, return an empty list. Most short '
    'texts contain few items, and a text that is already natural '
    'should return none.\n'
    '\n'
    'Each item has four parts:\n'
    '- written: the exact words as the learner wrote them, copied '
    'character for character from the text. Include enough surrounding '
    'words that the place is clear, but keep it short. Never include '
    'the same words twice.\n'
    '- suggestion: what to write there instead. Give exactly one '
    'suggestion, with no alternatives, no slash and no "or". If the '
    'suggestion is to delete words, give the shorter text without '
    'them.\n'
    '- category: exactly "Natural phrasing".\n'
    '- reason: one short sentence in English saying why. Be kind and '
    'matter of fact. Never use the words "wrong", "error" or '
    '"incorrect". Where a form is common in everyday speech but '
    'usually avoided in careful writing, say so in the reason.\n'
    '\n'
    'Return JSON only, with no Markdown and no commentary.';

/// The reply shape both steps share: a list of four-part items. The
/// category list differs by step, so it is passed in.
Map<String, Object?> suggestionResponseFormat({
  required String name,
  required List<String> categories,
}) => {
  'type': 'json_schema',
  'json_schema': {
    'name': name,
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

/// What both steps are sent as the user message.
String buildSuggestionUserContent(String text) =>
    'Review this text written by the learner. Return the items as JSON.\n'
    '\n'
    'Text:\n$text';

// ---------------------------------------------------------------------------
// Items, parsing and checking
// ---------------------------------------------------------------------------

/// One four-part item as a step reports it.
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

  @override
  String toString() => '$written -> $suggestion ($category)';
}

/// Parses a step's reply. Tolerates Markdown fences or commentary around
/// the JSON. Throws a [FormatException] if no object with an "items" list
/// can be found. Entries missing a text part are skipped.
List<SuggestionItem> parseSuggestionItems(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end <= start) {
    throw const FormatException('No JSON object found in the reply.');
  }
  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! Map<String, Object?> || decoded['items'] is! List) {
    throw const FormatException('The reply has no "items" list.');
  }
  final items = <SuggestionItem>[];
  for (final entry in (decoded['items'] as List).whereType<Map>()) {
    final written = entry['written'];
    final suggestion = entry['suggestion'];
    if (written is! String || suggestion is! String) continue;
    items.add(
      SuggestionItem(
        written: written,
        suggestion: suggestion,
        category: entry['category'] as String? ?? '',
        reason: entry['reason'] as String? ?? '',
      ),
    );
  }
  return items;
}

/// True when [reason] uses one of the words the wording rules forbid.
bool reasonBreaksWordingRule(String reason) {
  final lower = reason.toLowerCase();
  return forbiddenReasonWords.any(
    (word) => RegExp('\\b$word\\w*').hasMatch(lower),
  );
}

/// True when [item] has a category that [allowed] does not list.
bool categoryIsOutsideList(SuggestionItem item, List<String> allowed) =>
    !allowed.contains(item.category);

/// The result of applying items to the submitted text.
class AppliedSuggestions {
  const AppliedSuggestions({
    required this.suggestedText,
    required this.applied,
    required this.dropped,
  });

  final String suggestedText;
  final List<SuggestionItem> applied;

  /// Items that could not be placed: the words were not found in the text,
  /// the item changed nothing, or it overlapped an earlier item. Issues
  /// come before suggestions in [applyItems], so an Issue wins an overlap.
  final List<SuggestionItem> dropped;
}

/// Applies [items], in order, to [text]. Each item's "written" words are
/// found in the original text (the first stretch not already claimed by an
/// earlier item), and all replacements are then made at once, so no item
/// can disturb where another one points.
AppliedSuggestions applyItems(String text, List<SuggestionItem> items) {
  final claimed = <({int start, int end, String replacement})>[];
  final applied = <SuggestionItem>[];
  final dropped = <SuggestionItem>[];

  for (final item in items) {
    if (item.written.isEmpty || item.written == item.suggestion) {
      dropped.add(item);
      continue;
    }
    var from = 0;
    int? found;
    while (true) {
      final index = text.indexOf(item.written, from);
      if (index == -1) break;
      final end = index + item.written.length;
      final overlaps = claimed.any((c) => index < c.end && end > c.start);
      if (!overlaps) {
        found = index;
        break;
      }
      from = index + 1;
    }
    if (found == null) {
      dropped.add(item);
      continue;
    }
    claimed.add((
      start: found,
      end: found + item.written.length,
      replacement: item.suggestion,
    ));
    applied.add(item);
  }

  claimed.sort((a, b) => b.start.compareTo(a.start));
  var result = text;
  for (final c in claimed) {
    result = result.replaceRange(c.start, c.end, c.replacement);
  }
  return AppliedSuggestions(
    suggestedText: result,
    applied: applied,
    dropped: dropped,
  );
}

// ---------------------------------------------------------------------------
// Running and scoring
// ---------------------------------------------------------------------------

/// One sentence, one run, through both steps.
class SuggestionRunResult {
  const SuggestionRunResult({
    required this.fixture,
    required this.runIndex,
    required this.issues,
    required this.phrasing,
    required this.suggestedText,
    required this.dropped,
    required this.score,
    required this.issuesStats,
    required this.phrasingStats,
    required this.wordingBreaches,
    required this.categoryBreaches,
    this.errorMessage,
  });

  final TwoPassFixture fixture;
  final int runIndex;
  final List<SuggestionItem> issues;
  final List<SuggestionItem> phrasing;
  final String suggestedText;
  final List<SuggestionItem> dropped;
  final TwoPassScoreLabel score;
  final CallStats issuesStats;
  final CallStats phrasingStats;

  /// Reasons that used a forbidden word.
  final int wordingBreaches;

  /// Items whose category was not on their step's list.
  final int categoryBreaches;
  final String? errorMessage;

  bool get passed => errorMessage == null && isPassingScore(score);
  CallStats get totalStats => issuesStats + phrasingStats;
}

TwoPassScoreLabel _scoreText(TwoPassFixture fixture, String finalText) {
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

Future<(List<SuggestionItem>, CallStats)> _runStep({
  required String apiKey,
  required HttpClient httpClient,
  required String model,
  required String prompt,
  required String stageLabel,
  required List<String> categories,
  required String text,
}) async {
  final usage = <ChatCompletionsUsage>[];
  final client = OpenAiChatCompletionsClient(
    apiKey: apiKey,
    httpClient: httpClient,
    onUsage: usage.add,
  );
  final stopwatch = Stopwatch()..start();
  try {
    final reply = await client.complete(
      model: model,
      systemPrompt: prompt,
      userText: buildSuggestionUserContent(text),
      stageLabel: stageLabel,
      responseFormat: suggestionResponseFormat(
        name: stageLabel,
        categories: categories,
      ),
    );
    return (parseSuggestionItems(reply), statsFor(usage, wallClockMs: stopwatch.elapsedMilliseconds));
  } finally {
    stopwatch.stop();
  }
}

/// Runs both steps on [fixture] once. The steps run one after the other,
/// so each call's speed is its own. A failure in either step is recorded
/// on the result instead of being thrown.
Future<SuggestionRunResult> runSuggestionFixture({
  required String apiKey,
  required HttpClient httpClient,
  required String issuesModel,
  required String phrasingModel,
  required TwoPassFixture fixture,
  int runIndex = 1,
}) async {
  var issues = <SuggestionItem>[];
  var phrasing = <SuggestionItem>[];
  var issuesStats = CallStats.zero;
  var phrasingStats = CallStats.zero;
  try {
    final first = await _runStep(
      apiKey: apiKey,
      httpClient: httpClient,
      model: issuesModel,
      prompt: issuesStepPrompt,
      stageLabel: 'suggestion_issues',
      categories: issueCategories,
      text: fixture.text,
    );
    issues = first.$1;
    issuesStats = first.$2;
    final second = await _runStep(
      apiKey: apiKey,
      httpClient: httpClient,
      model: phrasingModel,
      prompt: phrasingStepPrompt,
      stageLabel: 'suggestion_phrasing',
      categories: phrasingCategories,
      text: fixture.text,
    );
    phrasing = second.$1;
    phrasingStats = second.$2;
  } catch (error) {
    return SuggestionRunResult(
      fixture: fixture,
      runIndex: runIndex,
      issues: issues,
      phrasing: phrasing,
      suggestedText: fixture.text,
      dropped: const [],
      score: TwoPassScoreLabel.error,
      issuesStats: issuesStats,
      phrasingStats: phrasingStats,
      wordingBreaches: 0,
      categoryBreaches: 0,
      errorMessage: '$error',
    );
  }
  return scoreSuggestionRun(
    fixture: fixture,
    runIndex: runIndex,
    issues: issues,
    phrasing: phrasing,
    issuesStats: issuesStats,
    phrasingStats: phrasingStats,
  );
}

/// Builds a scored result from the two steps' items. Separate from the
/// live calls so it can be tested without them.
SuggestionRunResult scoreSuggestionRun({
  required TwoPassFixture fixture,
  required int runIndex,
  required List<SuggestionItem> issues,
  required List<SuggestionItem> phrasing,
  required CallStats issuesStats,
  required CallStats phrasingStats,
}) {
  final applied = applyItems(fixture.text, [...issues, ...phrasing]);
  final all = [...issues, ...phrasing];
  return SuggestionRunResult(
    fixture: fixture,
    runIndex: runIndex,
    issues: issues,
    phrasing: phrasing,
    suggestedText: applied.suggestedText,
    dropped: applied.dropped,
    score: _scoreText(fixture, applied.suggestedText),
    issuesStats: issuesStats,
    phrasingStats: phrasingStats,
    wordingBreaches: all.where((i) => reasonBreaksWordingRule(i.reason)).length,
    categoryBreaches:
        issues.where((i) => categoryIsOutsideList(i, issueCategories)).length +
        phrasing
            .where((i) => categoryIsOutsideList(i, phrasingCategories))
            .length,
  );
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

/// The E.2 baseline (recorded in the build plan): 386 of 425 runs passed.
const int baselinePassed = 386;
const int baselineRuns = 425;
const double baselineSecondsPerCheck = 2.0;
const double baselineCentsPerCheck = 0.21;

String _percent(int part, int whole) =>
    whole == 0 ? 'n/a' : '${(part * 100 / whole).toStringAsFixed(1)} per cent';

String _cost(double? usd) =>
    usd == null ? 'unknown' : '\$${usd.toStringAsFixed(4)}';

String _describe(List<SuggestionItem> items) => items.isEmpty
    ? '(none)'
    : items.map((i) => '`${i.written}` -> `${i.suggestion}` (${i.category}: ${i.reason})').join('<br>');

String buildSuggestionReport({
  required String issuesModel,
  required String phrasingModel,
  required List<SuggestionRunResult> results,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# Suggestion two-step run (build step E.3)')
    ..writeln()
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln('- Step 1 (Issues): `$issuesModel`')
    ..writeln('- Step 2 (Natural phrasing): `$phrasingModel`')
    ..writeln();

  final total = results.length;
  final passed = results.where((r) => r.passed).length;
  final errors = results.where((r) => r.errorMessage != null).length;
  final totalCost = results.fold<double?>(
    0,
    (sum, r) =>
        sum == null || r.totalStats.costUsd == null ? null : sum + r.totalStats.costUsd!,
  );
  final step1Ms = results.fold<int>(0, (s, r) => s + r.issuesStats.wallClockMs);
  final step2Ms = results.fold<int>(0, (s, r) => s + r.phrasingStats.wallClockMs);
  final callable = results.where((r) => r.errorMessage == null).length;

  buffer
    ..writeln('## Result against the baseline')
    ..writeln()
    ..writeln('| | This run | E.2 baseline |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| Passed | $passed of $total (${_percent(passed, total)}) | '
      '$baselinePassed of $baselineRuns (${_percent(baselinePassed, baselineRuns)}) |',
    )
    ..writeln(
      '| Average time per check | '
      '${callable == 0 ? 'n/a' : ((step1Ms + step2Ms) / callable / 1000).toStringAsFixed(1)} seconds | '
      '$baselineSecondsPerCheck seconds |',
    )
    ..writeln(
      '| Average cost per check | '
      '${totalCost == null || total == 0 ? 'unknown' : '${(totalCost * 100 / total).toStringAsFixed(3)} cents'} | '
      '$baselineCentsPerCheck cents |',
    )
    ..writeln('| Total cost | ${_cost(totalCost)} | \$0.892 |')
    ..writeln()
    ..writeln('## Speed per call')
    ..writeln()
    ..writeln('| Step | Model | Average seconds per call |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| 1 Issues | `$issuesModel` | '
      '${callable == 0 ? 'n/a' : (step1Ms / callable / 1000).toStringAsFixed(2)} |',
    )
    ..writeln(
      '| 2 Natural phrasing | `$phrasingModel` | '
      '${callable == 0 ? 'n/a' : (step2Ms / callable / 1000).toStringAsFixed(2)} |',
    )
    ..writeln()
    ..writeln('## Outcomes')
    ..writeln();
  final labelCounts = <TwoPassScoreLabel, int>{
    for (final l in TwoPassScoreLabel.values) l: 0,
  };
  for (final r in results) {
    labelCounts[r.score] = labelCounts[r.score]! + 1;
  }
  for (final l in TwoPassScoreLabel.values) {
    buffer.writeln('- ${l.reportLabel}: ${labelCounts[l]}');
  }
  buffer
    ..writeln()
    ..writeln('## Wording and category rules')
    ..writeln()
    ..writeln(
      '- Reasons using "wrong", "error" or "incorrect": '
      '${results.fold<int>(0, (s, r) => s + r.wordingBreaches)}',
    )
    ..writeln(
      '- Items with a category outside their step\'s list: '
      '${results.fold<int>(0, (s, r) => s + r.categoryBreaches)}',
    )
    ..writeln(
      '- Items that could not be placed in the text: '
      '${results.fold<int>(0, (s, r) => s + r.dropped.length)}',
    )
    ..writeln('- Runs that errored: $errors')
    ..writeln();

  final groups = <String, List<SuggestionRunResult>>{};
  for (final r in results) {
    groups.putIfAbsent(r.fixture.languagePoint, () => []).add(r);
  }
  buffer
    ..writeln('## Per language point')
    ..writeln()
    ..writeln('| Language point | Passed | Runs |')
    ..writeln('| --- | --- | --- |');
  for (final entry in groups.entries) {
    buffer.writeln(
      '| ${entry.key} | ${entry.value.where((r) => r.passed).length} | ${entry.value.length} |',
    );
  }
  buffer.writeln();

  final byFixture = <String, List<SuggestionRunResult>>{};
  for (final r in results) {
    byFixture.putIfAbsent(r.fixture.id, () => []).add(r);
  }
  buffer
    ..writeln('## Per sentence')
    ..writeln()
    ..writeln('| Sentence id | Language point | Passed | Runs |')
    ..writeln('| --- | --- | --- | --- |');
  for (final entry in byFixture.entries) {
    buffer.writeln(
      '| ${entry.key} | ${entry.value.first.fixture.languagePoint} | '
      '${entry.value.where((r) => r.passed).length} | ${entry.value.length} |',
    );
  }
  buffer
    ..writeln()
    ..writeln('## Every run that did not pass')
    ..writeln();
  for (final r in results.where((r) => !r.passed)) {
    buffer
      ..writeln('### ${r.fixture.id}, run ${r.runIndex}')
      ..writeln()
      ..writeln('- Score: ${r.score.reportLabel}')
      ..writeln('- Written: `${r.fixture.text}`')
      ..writeln('- Expected: `${r.fixture.expectedCorrectedText}`')
      ..writeln('- Suggested version: `${r.suggestedText}`');
    if (r.errorMessage != null) {
      buffer.writeln('- ERROR: ${r.errorMessage}');
    }
    buffer
      ..writeln('- Issues: ${_describe(r.issues)}')
      ..writeln('- Natural phrasing: ${_describe(r.phrasing)}')
      ..writeln();
  }
  return buffer.toString();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

String _env(String key, String fallback) {
  final value = Platform.environment[key]?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

void main() {
  group('offline checks (no AI calls)', () {
    test('step 1 names only its three categories and keeps the other '
        'steps\' jobs out', () {
      for (final c in issueCategories) {
        expect(issuesStepPrompt, contains(c));
      }
      expect(issuesStepPrompt, isNot(contains('Natural phrasing')));
      expect(issuesStepPrompt, contains('unnecessary'));
      expect(issuesStepPrompt, contains('major variety'));
    });

    test('step 2 asks only for Natural phrasing and carries the '
        'unnecessary-pronoun line', () {
      expect(phrasingStepPrompt, contains('exactly "Natural phrasing"'));
      expect(phrasingStepPrompt, contains('unnecessary subject pronouns'));
      expect(phrasingStepPrompt, contains('Yo trabajo mucho y yo estudio'));
      expect(phrasingStepPrompt, contains('major variety'));
    });

    test('both prompts carry the wording rules', () {
      for (final prompt in [issuesStepPrompt, phrasingStepPrompt]) {
        expect(
          prompt,
          contains('Never use the words "wrong", "error" or "incorrect"'),
        );
        expect(prompt, contains('common in everyday speech'));
        expect(prompt, contains('four parts'));
        expect(prompt, contains('Return JSON only'));
      }
    });

    test('the reply format lists the four parts and the step\'s categories',
        () {
      final format = suggestionResponseFormat(
        name: 'x',
        categories: phrasingCategories,
      );
      final schema =
          (format['json_schema'] as Map)['schema'] as Map<String, Object?>;
      final item =
          ((schema['properties'] as Map)['items'] as Map)['items'] as Map;
      expect(item['required'], ['written', 'suggestion', 'category', 'reason']);
      expect(
        ((item['properties'] as Map)['category'] as Map)['enum'],
        ['Natural phrasing'],
      );
    });

    test('parseSuggestionItems reads four-part items, even inside fences',
        () {
      final items = parseSuggestionItems(
        '```json\n{"items":[{"written":"yo estudio","suggestion":"estudio",'
        '"category":"Natural phrasing","reason":"Spanish drops it."}]}\n```',
      );
      expect(items, hasLength(1));
      expect(items.single.written, 'yo estudio');
      expect(items.single.category, 'Natural phrasing');
    });

    test('parseSuggestionItems accepts an empty list and rejects junk', () {
      expect(parseSuggestionItems('{"items":[]}'), isEmpty);
      expect(() => parseSuggestionItems('nothing'), throwsFormatException);
      expect(() => parseSuggestionItems('{"x":1}'), throwsFormatException);
    });

    test('reasonBreaksWordingRule catches the forbidden words only', () {
      expect(reasonBreaksWordingRule('This is wrong.'), isTrue);
      expect(reasonBreaksWordingRule('A common Error.'), isTrue);
      expect(reasonBreaksWordingRule('That is incorrect here.'), isTrue);
      expect(reasonBreaksWordingRule('Spanish usually drops it.'), isFalse);
      expect(reasonBreaksWordingRule('Heard in speech, avoided in writing.'),
          isFalse);
    });

    test('applyItems makes every replacement against the original text', () {
      const text = 'Yo trabajo mucho y yo estudio en la universidad.';
      final result = applyItems(text, const [
        SuggestionItem(
          written: 'y yo estudio',
          suggestion: 'y estudio',
          category: 'Natural phrasing',
          reason: 'r',
        ),
        SuggestionItem(
          written: 'Yo trabajo',
          suggestion: 'Trabajo',
          category: 'Natural phrasing',
          reason: 'r',
        ),
      ]);
      expect(result.suggestedText, 'Trabajo mucho y estudio en la universidad.');
      expect(result.dropped, isEmpty);
    });

    test('applyItems drops items it cannot place, and lets the earlier '
        'item win an overlap', () {
      const text = 'Voy a la escuela mañana.';
      final result = applyItems(text, const [
        SuggestionItem(
          written: 'la escuela',
          suggestion: 'el colegio',
          category: 'Grammar',
          reason: 'r',
        ),
        SuggestionItem(
          written: 'a la escuela',
          suggestion: 'al colegio',
          category: 'Natural phrasing',
          reason: 'r',
        ),
        SuggestionItem(
          written: 'no está en el texto',
          suggestion: 'x',
          category: 'Grammar',
          reason: 'r',
        ),
        SuggestionItem(
          written: 'Voy',
          suggestion: 'Voy',
          category: 'Grammar',
          reason: 'r',
        ),
      ]);
      expect(result.suggestedText, 'Voy a el colegio mañana.');
      expect(result.applied, hasLength(1));
      expect(result.dropped, hasLength(3));
    });

    test('applyItems uses a later copy of repeated words when the first is '
        'already taken', () {
      const text = 'casa y casa';
      final result = applyItems(text, const [
        SuggestionItem(
            written: 'casa', suggestion: 'hogar', category: 'g', reason: 'r'),
        SuggestionItem(
            written: 'casa', suggestion: 'piso', category: 'g', reason: 'r'),
      ]);
      expect(result.suggestedText, 'hogar y piso');
    });

    test('an already-correct sentence with no items scores as left alone',
        () {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.expectedCorrectedText == f.text,
      );
      final run = scoreSuggestionRun(
        fixture: fixture,
        runIndex: 1,
        issues: const [],
        phrasing: const [],
        issuesStats: CallStats.zero,
        phrasingStats: CallStats.zero,
      );
      expect(run.passed, isTrue);
      expect(run.suggestedText, fixture.text);
    });

    test('the report shows the baseline, speed per call and every miss', () {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.expectedCorrectedText != f.text,
      );
      final miss = scoreSuggestionRun(
        fixture: fixture,
        runIndex: 1,
        issues: const [],
        phrasing: const [
          SuggestionItem(
            written: 'zzz',
            suggestion: 'yyy',
            category: 'Natural phrasing',
            reason: 'That is wrong.',
          ),
        ],
        issuesStats: const CallStats(
            wallClockMs: 900, totalTokens: 10, costUsd: 0.0001),
        phrasingStats: const CallStats(
            wallClockMs: 1100, totalTokens: 10, costUsd: 0.0002),
      );
      final report = buildSuggestionReport(
        issuesModel: 'gpt-6-luna',
        phrasingModel: 'gpt-6-sol',
        results: [miss],
        generatedAt: DateTime.utc(2026, 11, 7),
      );
      expect(report, contains('386 of 425'));
      expect(report, contains('## Speed per call'));
      expect(report, contains('| 1 Issues | `gpt-6-luna` | 0.90 |'));
      expect(report, contains('| 2 Natural phrasing | `gpt-6-sol` | 1.10 |'));
      expect(report, contains('Reasons using "wrong", "error" or "incorrect": 1'));
      expect(report, contains('### ${fixture.id}, run 1'));
    });
  });

  test(
    'reworked two-step prompts on the 85 sentences (GPT-6 Luna then Sol)',
    tags: 'live',
    () async {
      if (Platform.environment['SUGGESTION_LIVE']?.toLowerCase() != 'true') {
        // ignore: avoid_print
        print('Skipping the live run. Set SUGGESTION_LIVE=true to opt in.');
        return;
      }
      final envKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';
      final apiKey = envKey.isNotEmpty
          ? envKey
          : AppConfig.fromEnvironment().openAiApiKey.trim();
      if (apiKey.isEmpty) {
        fail('No API key. Set OPENAI_API_KEY or put one in app_config.dart.');
      }
      final issuesModel = _env('SUGGESTION_ISSUES_MODEL', 'gpt-6-luna');
      final phrasingModel = _env('SUGGESTION_PHRASING_MODEL', 'gpt-6-sol');
      final runs = int.tryParse(_env('SUGGESTION_RUNS_PER_FIXTURE', '5')) ?? 5;
      final delayMs = int.tryParse(_env('SUGGESTION_CALL_DELAY_MS', '250')) ?? 250;
      final outputPath = _env(
        'SUGGESTION_OUTPUT',
        'docs/suggestion_two_step_e3.md',
      );

      final set = _env('SUGGESTION_FIXTURE_SET', 'all');
      final fixtures = switch (set) {
        'fixture_id' => allTwoPassFixtures
            .where((f) => f.id == _env('SUGGESTION_FIXTURE_ID', ''))
            .toList(),
        'language_point' => allTwoPassFixtures
            .where((f) => f.languagePoint == _env('SUGGESTION_LANGUAGE_POINT', ''))
            .toList(),
        _ => allTwoPassFixtures,
      };
      if (fixtures.isEmpty) fail('No sentences matched the chosen set.');

      final httpClient = HttpClient();
      final results = <SuggestionRunResult>[];
      for (final fixture in fixtures) {
        for (var run = 1; run <= runs; run++) {
          final result = await runSuggestionFixture(
            apiKey: apiKey,
            httpClient: httpClient,
            issuesModel: issuesModel,
            phrasingModel: phrasingModel,
            fixture: fixture,
            runIndex: run,
          );
          results.add(result);
          // ignore: avoid_print
          print('${fixture.id} run $run: ${result.score.reportLabel}');
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }
      }

      final report = buildSuggestionReport(
        issuesModel: issuesModel,
        phrasingModel: phrasingModel,
        results: results,
        generatedAt: DateTime.now(),
      );
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote the report to $outputPath');
    },
  );
}
