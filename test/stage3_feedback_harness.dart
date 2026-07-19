// Stage 3 feedback harness.
//
// Tests `stage3FeedbackSpanish` (lib/core/services/prompts/correction_prompt.dart)
// — an experimental third-stage prompt that takes a list of already-
// categorized corrections (start_index, original_phrase, corrected_phrase,
// category, verdict) and writes one short_explanation per correction,
// joined back to its input by start_index — against a set of fixed,
// hand-written categorized-correction inputs.
//
// ISOLATED, not chained to a live Stage 2 call: every fixture's correction
// list is hand-written, standing in for whatever Stage 2 would have
// produced. This keeps Stage 3's explanation quality separable from Stage
// 2's — a Stage 3 regression can't be a Stage 2 regression in disguise, and
// vice versa. See test/stage2_categorization_harness.dart for the
// categorization-only harness this one is modeled on (same fixtures -> run
// records -> aggregation -> golden-tested report -> gated live test shape,
// same direct `/v1/chat/completions` call, env-only OPENAI_API_KEY, GPT-5.5
// default).
//
// Explanation text is open-ended, so this scores checkable properties
// rather than exact string match: exactly one sentence (always), absence of
// error-language for dialectal-verdict corrections ("wrong"/"error"/
// "incorrect"/"mal"/"incorrecto" — the prompt explicitly forbids these for
// dialectal), whether specific cases mention the linguistic feature they're
// meant to name (calque, tilde, "que"), absence of hedging where asked, and
// join-key integrity (every start_index round-trips, none dropped or
// duplicated) for the multi-correction case. The full explanation text is
// always recorded per run regardless of what's scored, so quality is
// eyeballable even where there's no hard pass/fail.
//
// Deliberately does NOT receive the full submission text as input — only
// the correction list. Whether explanations read well from the phrase
// pattern alone (original_phrase/corrected_phrase/category/verdict, no
// surrounding sentence) is one of the open questions this harness exists to
// surface, not something assumed settled.
//
// Does NOT touch `correctText()`, existing prompt constants, or any live
// path.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage3_feedback_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/stage3_feedback_harness.dart --timeout none
//
// Writes a report to docs/stage3_feedback_harness.md (override with
// --dart-define=STAGE3_FEEDBACK_OUTPUT=...). Override run count per case
// with --dart-define=STAGE3_RUNS_PER_CASE=... (default 10). Override the
// model with --dart-define=STAGE3_FEEDBACK_MODEL=... (default 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerCase = int.fromEnvironment(
  'STAGE3_RUNS_PER_CASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'STAGE3_FEEDBACK_OUTPUT',
  defaultValue: 'docs/stage3_feedback_harness.md',
);

/// Model used for the live run. Override with
/// `--dart-define=STAGE3_FEEDBACK_MODEL=...`, same override pattern as the
/// other harnesses in this repo.
const String stage3Model = String.fromEnvironment(
  'STAGE3_FEEDBACK_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'STAGE3_CALL_DELAY_MS',
  defaultValue: 750,
);

/// Which battery a case belongs to, so the report can print them under
/// separate headings.
enum _CaseGroup { errorVerdict, dialectalVerdict, joinKeyIntegrity }

String _groupHeading(_CaseGroup group) => switch (group) {
  _CaseGroup.errorVerdict =>
    'Error-verdict cases (explanation must read as a correction)',
  _CaseGroup.dialectalVerdict =>
    'Dialectal-verdict cases (must not call it wrong)',
  _CaseGroup.joinKeyIntegrity => 'Join-key integrity',
};

/// One already-categorized correction, exactly the shape Stage 3 receives —
/// no full submission text, by design (see file header).
class _Correction {
  const _Correction({
    required this.startIndex,
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.category,
    required this.verdict,
  });

  final int startIndex;
  final String originalPhrase;
  final String correctedPhrase;
  final String category;
  final String verdict;

  Map<String, Object?> toJson() => {
    'start_index': startIndex,
    'original_phrase': originalPhrase,
    'corrected_phrase': correctedPhrase,
    'category': category,
    'verdict': verdict,
  };
}

/// What's checked of Stage 3's explanation for one correction.
///
/// "Exactly one sentence" is always checked (Stage 3's own instruction is
/// universal, not case-specific). Everything else here is null/false unless
/// the case explicitly calls it out — matching every other harness in this
/// set, only what's actually specified gets scored as pass/fail; everything
/// else is still visible via the recorded explanation text.
class _ExpectedExplanation {
  const _ExpectedExplanation({
    required this.startIndex,
    this.mustMentionAny,
    this.mustNotContainErrorLanguage = false,
    this.mustNotHedge = false,
  });

  final int startIndex;

  /// If set, the explanation must contain at least one of these keywords
  /// (case-insensitive substring match) — e.g. the calque case expects
  /// "calque" or "literal" to appear somewhere.
  final List<String>? mustMentionAny;

  /// The prompt explicitly forbids "wrong"/"error"/"incorrect" (or Spanish
  /// "mal"/"incorrecto") for verdict `dialectal` — this is THE key check for
  /// the dialectal-verdict cases.
  final bool mustNotContainErrorLanguage;

  /// The prompt says "no hedging" generally; only scored where a case calls
  /// it out explicitly.
  final bool mustNotHedge;
}

/// One test case: a fixed, hand-written list of categorized corrections
/// (standing in for Stage 2 output) and one [_ExpectedExplanation] per
/// correction, same order. [checkJoinKeyIntegrity] additionally verifies
/// every correction's start_index round-trips through Stage 3's response
/// exactly once — no drops, no duplicates, no extras.
class _Case {
  const _Case({
    required this.id,
    required this.group,
    required this.corrections,
    required this.expectations,
    required this.note,
    this.checkJoinKeyIntegrity = false,
  });

  final String id;
  final _CaseGroup group;
  final List<_Correction> corrections;
  final List<_ExpectedExplanation> expectations;
  final String note;
  final bool checkJoinKeyIntegrity;
}

const List<_Case> _cases = [
  // ── Error-verdict cases (explanation must read as a correction) ─────────
  _Case(
    id: 'ES-3-calque',
    group: _CaseGroup.errorVerdict,
    corrections: [
      _Correction(
        startIndex: 30,
        originalPhrase: 'llamaron para atrás',
        correctedPhrase: 'volvieron a llamar',
        category: 'Natural Language',
        verdict: 'error',
      ),
    ],
    expectations: [
      _ExpectedExplanation(
        startIndex: 30,
        mustMentionAny: ['calque', 'literal'],
        mustNotHedge: true,
      ),
    ],
    note:
        'One sentence, must name the calque/literal-translation nature '
        '(not just restate the fix), and must not hedge.',
  ),
  _Case(
    id: 'ES-5-accent',
    group: _CaseGroup.errorVerdict,
    corrections: [
      _Correction(
        startIndex: 8,
        originalPhrase: 'Espana',
        correctedPhrase: 'España',
        category: 'Spelling',
        verdict: 'error',
      ),
    ],
    expectations: [
      _ExpectedExplanation(startIndex: 8, mustMentionAny: ['tilde', 'ñ']),
    ],
    note: 'One sentence, must name the missing tilde/ñ.',
  ),
  _Case(
    id: 'ST-O2',
    group: _CaseGroup.errorVerdict,
    corrections: [
      _Correction(
        startIndex: 0,
        originalPhrase: 'Creo está bien',
        correctedPhrase: 'Creo que está bien',
        category: 'Grammar',
        verdict: 'error',
      ),
    ],
    expectations: [
      _ExpectedExplanation(startIndex: 0, mustMentionAny: ['que']),
    ],
    note: 'One sentence, must explain the missing "que".',
  ),

  // ── Dialectal-verdict cases (must not call it wrong) ─────────────────────
  _Case(
    id: 'coger',
    group: _CaseGroup.dialectalVerdict,
    corrections: [
      _Correction(
        startIndex: 6,
        originalPhrase: 'coger el autobús',
        correctedPhrase: 'tomar el autobús',
        category: 'Other',
        verdict: 'dialectal',
      ),
    ],
    expectations: [
      _ExpectedExplanation(startIndex: 6, mustNotContainErrorLanguage: true),
    ],
    note:
        'THE KEY CHECK: explanation must not contain "wrong"/"error"/'
        '"incorrect"/"mal"/"incorrecto" — it should explain the regional '
        'split instead. Full text always recorded for eyeballing.',
  ),
  _Case(
    id: 'ES-2',
    group: _CaseGroup.dialectalVerdict,
    corrections: [
      _Correction(
        startIndex: 27,
        originalPhrase: 'voy para casa',
        correctedPhrase: 'voy para casa',
        category: 'Other',
        verdict: 'dialectal',
      ),
    ],
    expectations: [
      _ExpectedExplanation(startIndex: 27, mustNotContainErrorLanguage: true),
    ],
    note:
        'Same check as coger. corrected_phrase == original_phrase here — '
        'dialectal often has no substitution. Read the recorded text to '
        'confirm the explanation handles that gracefully rather than '
        'inventing a fix (not itself a scored dimension, no reliable way '
        'to check that programmatically).',
  ),

  // ── Join-key integrity ────────────────────────────────────────────────
  _Case(
    id: 'multi-correction-join-key',
    group: _CaseGroup.joinKeyIntegrity,
    corrections: [
      _Correction(
        startIndex: 0,
        originalPhrase: 'trafico',
        correctedPhrase: 'tráfico',
        category: 'Spelling',
        verdict: 'error',
      ),
      _Correction(
        startIndex: 20,
        originalPhrase: 'llamaron para atrás',
        correctedPhrase: 'volvieron a llamar',
        category: 'Natural Language',
        verdict: 'error',
      ),
      _Correction(
        startIndex: 50,
        originalPhrase: 'voy para casa',
        correctedPhrase: 'voy para casa',
        category: 'Other',
        verdict: 'dialectal',
      ),
    ],
    expectations: [
      _ExpectedExplanation(startIndex: 0),
      _ExpectedExplanation(startIndex: 20),
      _ExpectedExplanation(startIndex: 50),
    ],
    note:
        'Three corrections with distinct start_index values (0, 20, 50). '
        'Confirms every returned object\'s start_index matches an input '
        'start_index, one explanation per correction, none dropped or '
        'duplicated — content quality isn\'t re-scored here (already '
        'covered by the single-correction cases above).',
    checkJoinKeyIntegrity: true,
  ),
];

/// Builds the user-message content sent alongside `stage3FeedbackSpanish`: a
/// JSON array of the correction objects, in the exact shape Stage 3 expects
/// (start_index/original_phrase/corrected_phrase/category/verdict). Pure —
/// no network, golden-testable on its own.
String _buildStage3UserContent(List<_Correction> corrections) {
  return jsonEncode(corrections.map((c) => c.toJson()).toList());
}

/// One correction's explanation, as returned by Stage 3.
class _ExplanationResult {
  const _ExplanationResult({
    required this.startIndex,
    required this.shortExplanation,
  });

  final int startIndex;
  final String shortExplanation;
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call. No `response_format` — Stage 3's JSON-array instruction lives
/// entirely in the prompt text, same approach as the other harnesses'
/// `buildChatCompletionsBody`.
Map<String, Object?> buildChatCompletionsBody({
  required String model,
  required String systemPrompt,
  required String userText,
}) {
  return {
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userText},
    ],
  };
}

/// Extracts the assistant's reply text from a decoded chat completions
/// response body: `choices[0].message.content`, trimmed. Copied by value
/// from the other harnesses' `extractReplyText`.
String extractReplyText(Map<String, Object?> decodedBody) {
  final choices = decodedBody['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException(
      'Chat completions response has no choices.',
    );
  }

  final firstChoice = choices.first;
  if (firstChoice is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice is not an object.');
  }

  final message = firstChoice['message'];
  if (message is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice has no message.');
  }

  final content = message['content'];
  if (content is! String || content.trim().isEmpty) {
    throw const FormatException('Chat completions message has no content.');
  }

  return content.trim();
}

/// Parses a Stage 3 reply into one [_ExplanationResult] per returned object.
///
/// Tolerates the model wrapping the array in Markdown code fences or
/// trailing commentary by extracting the substring between the first `[`
/// and the last `]` before decoding, same defensive approach as the other
/// harnesses' parse functions. Throws a [FormatException] on anything that
/// doesn't match the expected object shape once extracted.
List<_ExplanationResult> _parseExplanationArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 3 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('Stage 3 reply array did not decode to a List.');
  }

  return decoded.map((element) {
    if (element is! Map<String, Object?>) {
      throw FormatException(
        'Stage 3 reply array contained a non-object element: $element',
      );
    }

    final startIndex = element['start_index'];
    final shortExplanation = element['short_explanation'];

    if (startIndex is! num || startIndex != startIndex.roundToDouble()) {
      throw FormatException(
        'Stage 3 result missing/invalid start_index: $element',
      );
    }
    if (shortExplanation is! String || shortExplanation.trim().isEmpty) {
      throw FormatException(
        'Stage 3 result missing/invalid short_explanation: $element',
      );
    }

    return _ExplanationResult(
      startIndex: startIndex.round(),
      shortExplanation: shortExplanation.trim(),
    );
  }).toList();
}

/// Finds the result in [results] whose `startIndex` exactly matches
/// [startIndex] (the join key), or null if Stage 3 didn't return one.
_ExplanationResult? _matchResultFor(
  List<_ExplanationResult> results,
  int startIndex,
) {
  for (final result in results) {
    if (result.startIndex == startIndex) {
      return result;
    }
  }
  return null;
}

/// Reports whether every `start_index` in [inputStartIndexes] round-trips
/// through [results] exactly once: nothing missing, nothing duplicated, and
/// no extra start_index values that don't correspond to an input.
class _JoinKeyReport {
  const _JoinKeyReport({
    required this.missingStartIndexes,
    required this.duplicateStartIndexes,
    required this.extraStartIndexes,
  });

  final List<int> missingStartIndexes;
  final List<int> duplicateStartIndexes;
  final List<int> extraStartIndexes;

  bool get isIntact =>
      missingStartIndexes.isEmpty &&
      duplicateStartIndexes.isEmpty &&
      extraStartIndexes.isEmpty;
}

_JoinKeyReport _checkJoinKeyIntegrity(
  List<int> inputStartIndexes,
  List<_ExplanationResult> results,
) {
  final resultCounts = <int, int>{};
  for (final result in results) {
    resultCounts[result.startIndex] = (resultCounts[result.startIndex] ?? 0) + 1;
  }
  final inputSet = inputStartIndexes.toSet();

  final missing = inputStartIndexes
      .where((index) => (resultCounts[index] ?? 0) == 0)
      .toList();
  final duplicates = inputStartIndexes
      .where((index) => (resultCounts[index] ?? 0) > 1)
      .toList();
  final extras = resultCounts.keys.where((index) => !inputSet.contains(index)).toList()
    ..sort();

  return _JoinKeyReport(
    missingStartIndexes: missing,
    duplicateStartIndexes: duplicates,
    extraStartIndexes: extras,
  );
}

/// Interior sentence boundary: terminal punctuation followed by whitespace
/// and more text. Used by [_isOneSentence] after the string's own trailing
/// terminator has been stripped, so a normal one-sentence explanation
/// ending in "." doesn't trip its own check.
final RegExp _interiorSentenceBoundary = RegExp(r'[.!?]+\s+\S');

/// Heuristic "is this exactly one sentence" check: strip one trailing
/// terminator run (`.`/`!`/`?`, optionally followed by a closing quote),
/// then fail if the remainder still contains a terminator followed by more
/// text — that's a second sentence. Not perfect NLP (doesn't special-case
/// abbreviations like "Sr."), but sufficient for scoring short, single-idea
/// tutor asides.
bool _isOneSentence(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final withoutTrailingTerminator = trimmed.replaceFirst(
    RegExp('["’”]?[.!?]+\$'),
    '',
  );
  return !_interiorSentenceBoundary.hasMatch(withoutTrailingTerminator);
}

/// Case-insensitive substring containment against any of [keywords]. Used
/// for "mentions the expected linguistic feature" checks (calque/tilde/
/// "que") where the keywords are either multi-character (low false-positive
/// risk) or, for single accented characters like "ñ", not worth the
/// complexity of word-boundary matching.
bool _containsAny(String text, List<String> keywords) {
  final lower = text.toLowerCase();
  return keywords.any((keyword) => lower.contains(keyword.toLowerCase()));
}

/// Words the prompt explicitly forbids for verdict `dialectal`. Matched on
/// word boundaries (not plain substring) because several of these are
/// common substrings of unrelated words — "mal" inside "formal"/"animal",
/// "error" inside "terror" — and a false positive here would wrongly fail
/// an explanation that never actually called anything wrong.
const List<String> _errorLanguageWords = [
  'wrong',
  'error',
  'incorrect',
  'mal',
  'incorrecto',
];

bool _containsErrorLanguage(String text) {
  final lower = text.toLowerCase();
  return _errorLanguageWords.any((word) {
    final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b');
    return pattern.hasMatch(lower);
  });
}

/// Hedging phrases the prompt's "no hedging" instruction forbids. All
/// multi-word, so plain substring containment carries negligible
/// false-positive risk.
const List<String> _hedgingPhrases = [
  'maybe',
  'perhaps',
  'possibly',
  'might be',
  'could be',
  'i think',
  'sort of',
  'kind of',
  'not sure',
  'probably',
];

bool _containsHedging(String text) {
  final lower = text.toLowerCase();
  return _hedgingPhrases.any((phrase) => lower.contains(phrase));
}

/// One run's outcome for one case: one matched result per correction (null
/// entries mean Stage 3 didn't return anything for that start_index), in
/// `case.corrections` order, plus a [_JoinKeyReport] when the case checks
/// join-key integrity. A transient API failure is recorded via [error]
/// rather than dropped, same as the other harnesses.
class _RunRecord {
  const _RunRecord({
    required this.caseId,
    required this.runIndex,
    this.matchedResults = const [],
    this.joinKeyReport,
    this.error,
  });

  final String caseId;
  final int runIndex;
  final List<_ExplanationResult?> matchedResults;
  final _JoinKeyReport? joinKeyReport;
  final Object? error;

  bool get isError => error != null;
}

_RunRecord _buildRunRecord({
  required _Case testCase,
  required int runIndex,
  required List<_ExplanationResult> results,
}) {
  return _RunRecord(
    caseId: testCase.id,
    runIndex: runIndex,
    matchedResults: testCase.corrections
        .map((c) => _matchResultFor(results, c.startIndex))
        .toList(),
    joinKeyReport: testCase.checkJoinKeyIntegrity
        ? _checkJoinKeyIntegrity(
            testCase.corrections.map((c) => c.startIndex).toList(),
            results,
          )
        : null,
  );
}

_RunRecord _errorRunRecord({
  required _Case testCase,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(caseId: testCase.id, runIndex: runIndex, error: error);
}

/// Aggregated results for one correction (one "target") within a case,
/// across all its non-error runs. Nullable counts mean "not scored" — the
/// corresponding dimension wasn't specified for this target.
class _TargetAggregate {
  const _TargetAggregate({
    required this.total,
    required this.missingCount,
    required this.oneSentenceCount,
    this.mentionsCount,
    this.noErrorLanguageCount,
    this.noHedgingCount,
  });

  final int total;
  final int missingCount;
  final int oneSentenceCount;
  final int? mentionsCount;
  final int? noErrorLanguageCount;
  final int? noHedgingCount;
}

/// Aggregated results for one case across all its runs.
class _CaseAggregate {
  const _CaseAggregate({
    required this.caseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.targets,
    required this.fullyCaughtCount,
    required this.okRunCount,
    this.joinKeyIntactCount,
  });

  final String caseId;
  final int totalRuns;
  final int errorRuns;
  final List<_TargetAggregate> targets;
  final int fullyCaughtCount;
  final int okRunCount;

  /// Null unless the case checks join-key integrity.
  final int? joinKeyIntactCount;
}

bool _targetPasses(_ExpectedExplanation expected, _ExplanationResult? result) {
  if (result == null) {
    return false;
  }
  final text = result.shortExplanation;
  if (!_isOneSentence(text)) {
    return false;
  }
  if (expected.mustMentionAny != null && !_containsAny(text, expected.mustMentionAny!)) {
    return false;
  }
  if (expected.mustNotContainErrorLanguage && _containsErrorLanguage(text)) {
    return false;
  }
  if (expected.mustNotHedge && _containsHedging(text)) {
    return false;
  }
  return true;
}

_CaseAggregate _aggregateCase(_Case testCase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  final errorCount = records.length - okRecords.length;

  final targets = <_TargetAggregate>[];
  for (var i = 0; i < testCase.corrections.length; i++) {
    final expected = testCase.expectations[i];
    var missing = 0;
    var oneSentence = 0;
    var mentions = 0;
    var noErrorLanguage = 0;
    var noHedging = 0;

    for (final record in okRecords) {
      final result = record.matchedResults[i];
      if (result == null) {
        missing++;
        continue;
      }
      final text = result.shortExplanation;
      if (_isOneSentence(text)) {
        oneSentence++;
      }
      if (expected.mustMentionAny != null && _containsAny(text, expected.mustMentionAny!)) {
        mentions++;
      }
      if (expected.mustNotContainErrorLanguage && !_containsErrorLanguage(text)) {
        noErrorLanguage++;
      }
      if (expected.mustNotHedge && !_containsHedging(text)) {
        noHedging++;
      }
    }

    targets.add(
      _TargetAggregate(
        total: okRecords.length,
        missingCount: missing,
        oneSentenceCount: oneSentence,
        mentionsCount: expected.mustMentionAny == null ? null : mentions,
        noErrorLanguageCount: expected.mustNotContainErrorLanguage ? noErrorLanguage : null,
        noHedgingCount: expected.mustNotHedge ? noHedging : null,
      ),
    );
  }

  final joinKeyIntactCount = testCase.checkJoinKeyIntegrity
      ? okRecords.where((r) => r.joinKeyReport?.isIntact == true).length
      : null;

  final fullyCaughtCount = okRecords.where((record) {
    for (var i = 0; i < testCase.corrections.length; i++) {
      if (!_targetPasses(testCase.expectations[i], record.matchedResults[i])) {
        return false;
      }
    }
    if (testCase.checkJoinKeyIntegrity && record.joinKeyReport?.isIntact != true) {
      return false;
    }
    return true;
  }).length;

  return _CaseAggregate(
    caseId: testCase.id,
    totalRuns: records.length,
    errorRuns: errorCount,
    targets: targets,
    fullyCaughtCount: fullyCaughtCount,
    okRunCount: okRecords.length,
    joinKeyIntactCount: joinKeyIntactCount,
  );
}

String _percentLabel(int count, int total) {
  if (total == 0) {
    return '0.0% (0/0)';
  }
  final pct = (count / total * 100).toStringAsFixed(1);
  return '$pct% ($count/$total)';
}

String _describeError(Object error) => error.toString();

String _describeJoinKeyReport(_JoinKeyReport report) {
  if (report.isIntact) {
    return 'intact';
  }
  final parts = <String>[];
  if (report.missingStartIndexes.isNotEmpty) {
    parts.add('missing ${report.missingStartIndexes}');
  }
  if (report.duplicateStartIndexes.isNotEmpty) {
    parts.add('duplicated ${report.duplicateStartIndexes}');
  }
  if (report.extraStartIndexes.isNotEmpty) {
    parts.add('extra ${report.extraStartIndexes}');
  }
  return parts.join(', ');
}

String _describeRun(_Case testCase, _RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }

  final parts = <String>[];
  for (var i = 0; i < testCase.corrections.length; i++) {
    final startIndex = testCase.corrections[i].startIndex;
    final result = record.matchedResults[i];
    if (result == null) {
      parts.add('start_index=$startIndex -> (no matching result returned)');
    } else {
      parts.add('start_index=$startIndex -> "${result.shortExplanation}"');
    }
  }
  if (record.joinKeyReport != null) {
    parts.add('join-key: ${_describeJoinKeyReport(record.joinKeyReport!)}');
  }

  return '- $prefix: ${parts.join(' | ')}';
}

/// Builds the full markdown report: a header block, then each case group as
/// its own section, one subsection per case (metadata, per-target summary,
/// join-key summary where applicable, run-by-run breakdown with full
/// explanation text), then an overall-summary table.
///
/// Pure — takes already-collected [recordsByCaseId] rather than making any
/// calls itself, golden-testable against synthetic data with no live API
/// involved, same approach as the other harnesses' `_buildReport`.
String _buildReport({
  required String model,
  required int runsPerCase,
  required DateTime generatedAt,
  required List<_Case> cases,
  required Map<String, List<_RunRecord>> recordsByCaseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Stage 3 Feedback Harness')
    ..writeln()
    ..writeln('Model: `$model`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per case: $runsPerCase')
    ..writeln();

  final summaryRows = <String>[];

  for (final group in _CaseGroup.values) {
    final groupCases = cases.where((c) => c.group == group).toList();
    if (groupCases.isEmpty) {
      continue;
    }

    report
      ..writeln('## ${_groupHeading(group)}')
      ..writeln();

    for (final testCase in groupCases) {
      final records = recordsByCaseId[testCase.id] ?? const <_RunRecord>[];
      final aggregate = _aggregateCase(testCase, records);

      report
        ..writeln('### ${testCase.id}')
        ..writeln()
        ..writeln(
          '- Corrections: '
          '${jsonEncode(testCase.corrections.map((c) => c.toJson()).toList())}',
        )
        ..writeln('- Note: ${testCase.note}')
        ..writeln()
        ..writeln(
          '#### Summary (${aggregate.totalRuns} runs, '
          '${aggregate.errorRuns} error(s))',
        )
        ..writeln();

      for (var i = 0; i < testCase.corrections.length; i++) {
        final startIndex = testCase.corrections[i].startIndex;
        final expected = testCase.expectations[i];
        final target = aggregate.targets[i];

        report
          ..writeln('- Target ${i + 1} (start_index=$startIndex):')
          ..writeln(
            '  - Missing (no matching result): '
            '${_percentLabel(target.missingCount, target.total)}',
          )
          ..writeln(
            '  - Exactly one sentence: '
            '${_percentLabel(target.oneSentenceCount, target.total)}',
          );
        if (expected.mustMentionAny != null) {
          report.writeln(
            '  - Mentions ${expected.mustMentionAny}: '
            '${_percentLabel(target.mentionsCount ?? 0, target.total)}',
          );
        }
        if (expected.mustNotContainErrorLanguage) {
          report.writeln(
            '  - No error-language ("wrong"/"error"/"incorrect"/"mal"/"incorrecto"): '
            '${_percentLabel(target.noErrorLanguageCount ?? 0, target.total)}',
          );
        }
        if (expected.mustNotHedge) {
          report.writeln(
            '  - No hedging: '
            '${_percentLabel(target.noHedgingCount ?? 0, target.total)}',
          );
        }
      }

      if (aggregate.joinKeyIntactCount != null) {
        report.writeln(
          '- Join-key integrity: '
          '${_percentLabel(aggregate.joinKeyIntactCount!, aggregate.okRunCount)}',
        );
      }

      final fullyCaughtLabel = _percentLabel(
        aggregate.fullyCaughtCount,
        aggregate.okRunCount,
      );
      report
        ..writeln('- Fully caught (every scored check in one run): $fullyCaughtLabel')
        ..writeln()
        ..writeln('#### Run detail')
        ..writeln();

      for (final record in records) {
        report.writeln(_describeRun(testCase, record));
      }
      report.writeln();

      summaryRows.add(
        '| ${testCase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
        '$fullyCaughtLabel |',
      );
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Case | Runs | Errors | Fully caught |')
    ..writeln('| --- | --- | --- | --- |');
  for (final row in summaryRows) {
    report.writeln(row);
  }

  return report.toString();
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

Future<List<_ExplanationResult>> _callStage3Feedback({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required List<_Correction> corrections,
}) async {
  final request = await httpClient
      .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
      .timeout(const Duration(seconds: 10));

  request.headers
    ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
    ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

  request.add(
    utf8.encode(
      jsonEncode(
        buildChatCompletionsBody(
          model: model,
          systemPrompt: stage3FeedbackSpanish,
          userText: _buildStage3UserContent(corrections),
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Chat completions call failed with HTTP ${response.statusCode}: $body',
    );
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'Chat completions response root is not an object.',
    );
  }

  return _parseExplanationArray(extractReplyText(decoded));
}

void main() {
  test('stage3 feedback harness case fixtures are well-formed', () {
    expect(
      _cases.length,
      6,
      reason: '3 error-verdict + 2 dialectal-verdict + 1 join-key-integrity.',
    );

    final ids = _cases.map((c) => c.id).toSet();
    expect(ids.length, _cases.length, reason: 'Case ids must be unique.');

    for (final testCase in _cases) {
      expect(
        testCase.expectations.length,
        testCase.corrections.length,
        reason: '${testCase.id}: one expectation per correction.',
      );
      for (var i = 0; i < testCase.corrections.length; i++) {
        expect(
          testCase.expectations[i].startIndex,
          testCase.corrections[i].startIndex,
          reason: '${testCase.id}: expectations must line up with corrections.',
        );
      }
      final startIndexes = testCase.corrections.map((c) => c.startIndex).toSet();
      expect(
        startIndexes.length,
        testCase.corrections.length,
        reason: '${testCase.id}: start_index values must be unique within a case.',
      );
    }

    final idsByGroup = {
      for (final group in _CaseGroup.values)
        group: _cases.where((c) => c.group == group).map((c) => c.id).toList(),
    };
    expect(idsByGroup[_CaseGroup.errorVerdict], ['ES-3-calque', 'ES-5-accent', 'ST-O2']);
    expect(idsByGroup[_CaseGroup.dialectalVerdict], ['coger', 'ES-2']);
    expect(idsByGroup[_CaseGroup.joinKeyIntegrity], ['multi-correction-join-key']);

    final joinKeyCase = _cases.firstWhere((c) => c.id == 'multi-correction-join-key');
    expect(joinKeyCase.checkJoinKeyIntegrity, isTrue);
    expect(joinKeyCase.corrections, hasLength(3));
    expect(
      _cases.where((c) => c.id != 'multi-correction-join-key').every((c) => !c.checkJoinKeyIntegrity),
      isTrue,
    );

    // Every dialectal-verdict correction actually carries verdict
    // 'dialectal' and is scored on error-language absence.
    for (final testCase in _cases.where((c) => c.group == _CaseGroup.dialectalVerdict)) {
      for (var i = 0; i < testCase.corrections.length; i++) {
        expect(testCase.corrections[i].verdict, 'dialectal', reason: testCase.id);
        expect(testCase.expectations[i].mustNotContainErrorLanguage, isTrue, reason: testCase.id);
      }
    }
  });

  test(
    'stage3FeedbackSpanish prompt asks for one short_explanation per '
    'correction, joined by start_index',
    () {
      expect(stage3FeedbackSpanish, contains('Spanish tutor writing feedback'));
      expect(stage3FeedbackSpanish, contains('start_index'));
      expect(stage3FeedbackSpanish, contains('short_explanation'));
      expect(stage3FeedbackSpanish, contains('exactly one sentence'));
      expect(stage3FeedbackSpanish, contains('"wrong," "error," or "incorrect."'));
      expect(stage3FeedbackSpanish, contains('no hedging'));
    },
  );

  group('_buildStage3UserContent', () {
    test('encodes every correction field, keyed by start_index', () {
      final content = _buildStage3UserContent(const [
        _Correction(
          startIndex: 8,
          originalPhrase: 'Espana',
          correctedPhrase: 'España',
          category: 'Spelling',
          verdict: 'error',
        ),
      ]);

      final decoded = jsonDecode(content) as List<Object?>;
      expect(decoded, hasLength(1));
      final entry = decoded.single as Map<String, Object?>;
      expect(entry['start_index'], 8);
      expect(entry['original_phrase'], 'Espana');
      expect(entry['corrected_phrase'], 'España');
      expect(entry['category'], 'Spelling');
      expect(entry['verdict'], 'error');
    });

    test('encodes multiple corrections as a single array', () {
      final content = _buildStage3UserContent(const [
        _Correction(
          startIndex: 0,
          originalPhrase: 'a',
          correctedPhrase: 'b',
          category: 'Other',
          verdict: 'error',
        ),
        _Correction(
          startIndex: 5,
          originalPhrase: 'c',
          correctedPhrase: 'd',
          category: 'Other',
          verdict: 'dialectal',
        ),
      ]);

      final decoded = jsonDecode(content) as List<Object?>;
      expect(decoded, hasLength(2));
    });
  });

  group('_parseExplanationArray', () {
    test('parses a populated array', () {
      final results = _parseExplanationArray(
        '[{"start_index": 8, "short_explanation": "Missing the tilde on the n."}]',
      );

      expect(results, hasLength(1));
      expect(results.single.startIndex, 8);
      expect(results.single.shortExplanation, 'Missing the tilde on the n.');
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      final results = _parseExplanationArray(
        '```json\n[{"start_index": 0, "short_explanation": "x."}]\n```',
      );
      expect(results, hasLength(1));
    });

    test('trims whitespace from short_explanation', () {
      final results = _parseExplanationArray(
        '[{"start_index": 0, "short_explanation": "  Spaced out.  "}]',
      );
      expect(results.single.shortExplanation, 'Spaced out.');
    });

    test('throws when no array is present', () {
      expect(
        () => _parseExplanationArray('No corrections.'),
        throwsFormatException,
      );
    });

    test('throws when start_index is missing or invalid', () {
      expect(
        () => _parseExplanationArray('[{"short_explanation": "x."}]'),
        throwsFormatException,
      );
      expect(
        () => _parseExplanationArray(
          '[{"start_index": "zero", "short_explanation": "x."}]',
        ),
        throwsFormatException,
      );
    });

    test('throws when short_explanation is missing or blank', () {
      expect(
        () => _parseExplanationArray('[{"start_index": 0}]'),
        throwsFormatException,
      );
      expect(
        () => _parseExplanationArray(
          '[{"start_index": 0, "short_explanation": "   "}]',
        ),
        throwsFormatException,
      );
    });
  });

  group('_matchResultFor', () {
    test('matches by exact start_index', () {
      final result = _matchResultFor(
        const [_ExplanationResult(startIndex: 8, shortExplanation: 'x.')],
        8,
      );
      expect(result, isNotNull);
      expect(result!.shortExplanation, 'x.');
    });

    test('returns null when no start_index matches', () {
      final result = _matchResultFor(
        const [_ExplanationResult(startIndex: 8, shortExplanation: 'x.')],
        30,
      );
      expect(result, isNull);
    });

    test('returns the first match when duplicates exist', () {
      final result = _matchResultFor(
        const [
          _ExplanationResult(startIndex: 8, shortExplanation: 'first.'),
          _ExplanationResult(startIndex: 8, shortExplanation: 'second.'),
        ],
        8,
      );
      expect(result!.shortExplanation, 'first.');
    });
  });

  group('_checkJoinKeyIntegrity', () {
    test('intact when every input start_index appears exactly once', () {
      final report = _checkJoinKeyIntegrity(
        [0, 20, 50],
        const [
          _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
          _ExplanationResult(startIndex: 20, shortExplanation: 'b.'),
          _ExplanationResult(startIndex: 50, shortExplanation: 'c.'),
        ],
      );
      expect(report.isIntact, isTrue);
    });

    test('flags a missing start_index', () {
      final report = _checkJoinKeyIntegrity(
        [0, 20, 50],
        const [
          _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
          _ExplanationResult(startIndex: 20, shortExplanation: 'b.'),
        ],
      );
      expect(report.isIntact, isFalse);
      expect(report.missingStartIndexes, [50]);
    });

    test('flags a duplicated start_index', () {
      final report = _checkJoinKeyIntegrity(
        [0, 20],
        const [
          _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
          _ExplanationResult(startIndex: 0, shortExplanation: 'a again.'),
          _ExplanationResult(startIndex: 20, shortExplanation: 'b.'),
        ],
      );
      expect(report.isIntact, isFalse);
      expect(report.duplicateStartIndexes, [0]);
    });

    test('flags an extra start_index not present in the input', () {
      final report = _checkJoinKeyIntegrity(
        [0],
        const [
          _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
          _ExplanationResult(startIndex: 99, shortExplanation: 'unexpected.'),
        ],
      );
      expect(report.isIntact, isFalse);
      expect(report.extraStartIndexes, [99]);
    });
  });

  group('_isOneSentence', () {
    test('true for a simple sentence ending in a period', () {
      expect(_isOneSentence('This is missing a tilde on the n.'), isTrue);
    });

    test('true for a sentence ending in a question mark or exclamation', () {
      expect(_isOneSentence('Did you mean tráfico?'), isTrue);
      expect(_isOneSentence('Watch the accent!'), isTrue);
    });

    test('true for a sentence with no terminal punctuation at all', () {
      expect(_isOneSentence('Missing the tilde on the n'), isTrue);
    });

    test('false for two sentences joined by a space', () {
      expect(
        _isOneSentence('This is a calque from English. Use the idiom instead.'),
        isFalse,
      );
    });

    test('false when a second sentence follows an ellipsis-like run', () {
      expect(_isOneSentence('Close... but not quite the right word.'), isFalse);
    });

    test('true for a sentence ending inside a closing quote', () {
      expect(_isOneSentence('This is a calque of "to call back."'), isTrue);
    });

    test('false for an empty string', () {
      expect(_isOneSentence(''), isFalse);
      expect(_isOneSentence('   '), isFalse);
    });
  });

  group('_containsAny', () {
    test('matches case-insensitively', () {
      expect(_containsAny('This is a CALQUE from English.', ['calque']), isTrue);
    });

    test('matches any keyword in the list', () {
      expect(_containsAny('A literal translation.', ['calque', 'literal']), isTrue);
    });

    test('false when none of the keywords appear', () {
      expect(_containsAny('Missing an accent.', ['calque', 'literal']), isFalse);
    });
  });

  group('_containsErrorLanguage', () {
    test('true for "wrong"', () {
      expect(_containsErrorLanguage('This is wrong.'), isTrue);
    });

    test('true for Spanish "mal" as a standalone word', () {
      expect(_containsErrorLanguage('Esto está mal.'), isTrue);
    });

    test('false for "mal" as a substring of an unrelated word', () {
      expect(_containsErrorLanguage('This is a formal register shift.'), isFalse);
      expect(_containsErrorLanguage('It sounds a bit informal here.'), isFalse);
    });

    test('false for "error" as a substring of an unrelated word', () {
      expect(_containsErrorLanguage('This word evokes terror imagery.'), isFalse);
    });

    test('false when no banned word appears', () {
      expect(
        _containsErrorLanguage('Standard in Spain, less common elsewhere.'),
        isFalse,
      );
    });
  });

  group('_containsHedging', () {
    test('true for "maybe"', () {
      expect(_containsHedging('Maybe this should change.'), isTrue);
    });

    test('true for "i think"', () {
      expect(_containsHedging('I think this is a calque.'), isTrue);
    });

    test('false for a direct explanation', () {
      expect(_containsHedging('This is a calque of the English idiom.'), isFalse);
    });
  });

  group('_targetPasses', () {
    const expected = _ExpectedExplanation(
      startIndex: 30,
      mustMentionAny: ['calque', 'literal'],
      mustNotHedge: true,
    );

    test('true when one sentence, mentions a keyword, and doesn\'t hedge', () {
      final result = const _ExplanationResult(
        startIndex: 30,
        shortExplanation: 'This is a calque of the English idiom.',
      );
      expect(_targetPasses(expected, result), isTrue);
    });

    test('false when result is null', () {
      expect(_targetPasses(expected, null), isFalse);
    });

    test('false when it is two sentences', () {
      final result = const _ExplanationResult(
        startIndex: 30,
        shortExplanation: 'This is a calque. Use the idiom instead.',
      );
      expect(_targetPasses(expected, result), isFalse);
    });

    test('false when it never mentions the expected keyword', () {
      final result = const _ExplanationResult(
        startIndex: 30,
        shortExplanation: 'This phrasing is a bit off.',
      );
      expect(_targetPasses(expected, result), isFalse);
    });

    test('false when it hedges', () {
      final result = const _ExplanationResult(
        startIndex: 30,
        shortExplanation: 'I think this might be a calque.',
      );
      expect(_targetPasses(expected, result), isFalse);
    });

    test('dialectal case fails when it uses error-language', () {
      const dialectalExpected = _ExpectedExplanation(
        startIndex: 6,
        mustNotContainErrorLanguage: true,
      );
      final result = const _ExplanationResult(
        startIndex: 6,
        shortExplanation: 'This is wrong in most of Latin America.',
      );
      expect(_targetPasses(dialectalExpected, result), isFalse);
    });
  });

  group('_buildRunRecord / _errorRunRecord', () {
    test('matches each correction to its result by start_index, in order', () {
      final testCase = _cases.firstWhere((c) => c.id == 'multi-correction-join-key');
      final record = _buildRunRecord(
        testCase: testCase,
        runIndex: 1,
        results: const [
          _ExplanationResult(startIndex: 50, shortExplanation: 'c.'),
          _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
          _ExplanationResult(startIndex: 20, shortExplanation: 'b.'),
        ],
      );

      expect(record.matchedResults, hasLength(3));
      expect(record.matchedResults[0]!.shortExplanation, 'a.');
      expect(record.matchedResults[1]!.shortExplanation, 'b.');
      expect(record.matchedResults[2]!.shortExplanation, 'c.');
      expect(record.joinKeyReport!.isIntact, isTrue);
    });

    test('joinKeyReport is null when the case does not check it', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-3-calque');
      final record = _buildRunRecord(
        testCase: testCase,
        runIndex: 1,
        results: const [
          _ExplanationResult(startIndex: 30, shortExplanation: 'x.'),
        ],
      );
      expect(record.joinKeyReport, isNull);
    });

    test('_errorRunRecord carries the error and no data', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-3-calque');
      final record = _errorRunRecord(
        testCase: testCase,
        runIndex: 2,
        error: StateError('timed out'),
      );

      expect(record.isError, isTrue);
      expect(record.error, isA<StateError>());
      expect(record.matchedResults, isEmpty);
      expect(record.joinKeyReport, isNull);
    });
  });

  group('_aggregateCase', () {
    test('rates computed over non-error runs only', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-3-calque');

      final records = [
        _buildRunRecord(
          testCase: testCase,
          runIndex: 1,
          results: const [
            _ExplanationResult(
              startIndex: 30,
              shortExplanation: 'This is a calque of the English idiom.',
            ),
          ],
        ),
        _buildRunRecord(
          testCase: testCase,
          runIndex: 2,
          results: const [
            _ExplanationResult(
              startIndex: 30,
              shortExplanation: 'This phrasing is a bit off.',
            ),
          ],
        ),
        _errorRunRecord(testCase: testCase, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.targets, hasLength(1));

      final target = aggregate.targets.single;
      expect(target.total, 2);
      expect(target.oneSentenceCount, 2);
      expect(target.mentionsCount, 1);
      expect(target.noHedgingCount, 2);
      expect(aggregate.fullyCaughtCount, 1);
      expect(aggregate.okRunCount, 2);
    });

    test('join-key integrity is aggregated for the join-key case', () {
      final testCase = _cases.firstWhere((c) => c.id == 'multi-correction-join-key');

      final records = [
        _buildRunRecord(
          testCase: testCase,
          runIndex: 1,
          results: const [
            _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
            _ExplanationResult(startIndex: 20, shortExplanation: 'b.'),
            _ExplanationResult(startIndex: 50, shortExplanation: 'c.'),
          ],
        ),
        _buildRunRecord(
          testCase: testCase,
          runIndex: 2,
          results: const [
            _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
            _ExplanationResult(startIndex: 20, shortExplanation: 'b.'),
          ],
        ),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.joinKeyIntactCount, 1);
      expect(aggregate.okRunCount, 2);
      // Run 2 is missing start_index 50 -> not fully caught either.
      expect(aggregate.fullyCaughtCount, 1);
    });

    test('a missing match counts against fully-caught but not other targets\' counters', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-5-accent');
      final records = [
        _buildRunRecord(testCase: testCase, runIndex: 1, results: const []),
      ];

      final aggregate = _aggregateCase(testCase, records);
      final target = aggregate.targets.single;

      expect(target.missingCount, 1);
      expect(target.oneSentenceCount, 0);
      expect(aggregate.fullyCaughtCount, 0);
    });

    test('all runs erroring yields zeroed aggregates, not a crash', () {
      final testCase = _cases.firstWhere((c) => c.id == 'ES-3-calque');
      final records = [
        _errorRunRecord(testCase: testCase, runIndex: 1, error: StateError('a')),
        _errorRunRecord(testCase: testCase, runIndex: 2, error: StateError('b')),
      ];

      final aggregate = _aggregateCase(testCase, records);

      expect(aggregate.totalRuns, 2);
      expect(aggregate.errorRuns, 2);
      expect(aggregate.okRunCount, 0);
      expect(aggregate.fullyCaughtCount, 0);
      expect(aggregate.targets.single.total, 0);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, grouped sections, per-target summary, join-key summary, run detail, overall table)',
    () {
      const testCase1 = _Case(
        id: 'TEST-1-error',
        group: _CaseGroup.errorVerdict,
        corrections: [
          _Correction(
            startIndex: 8,
            originalPhrase: 'Espana',
            correctedPhrase: 'España',
            category: 'Spelling',
            verdict: 'error',
          ),
        ],
        expectations: [
          _ExpectedExplanation(startIndex: 8, mustMentionAny: ['tilde']),
        ],
        note: 'Synthetic error-verdict case for report golden test.',
      );
      const testCase2 = _Case(
        id: 'TEST-2-joinkey',
        group: _CaseGroup.joinKeyIntegrity,
        corrections: [
          _Correction(
            startIndex: 0,
            originalPhrase: 'a',
            correctedPhrase: 'b',
            category: 'Other',
            verdict: 'error',
          ),
          _Correction(
            startIndex: 10,
            originalPhrase: 'c',
            correctedPhrase: 'd',
            category: 'Other',
            verdict: 'error',
          ),
        ],
        expectations: [
          _ExpectedExplanation(startIndex: 0),
          _ExpectedExplanation(startIndex: 10),
        ],
        note: 'Synthetic join-key case for report golden test.',
        checkJoinKeyIntegrity: true,
      );

      final report = _buildReport(
        model: 'test-model',
        runsPerCase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        cases: const [testCase1, testCase2],
        recordsByCaseId: {
          'TEST-1-error': [
            _buildRunRecord(
              testCase: testCase1,
              runIndex: 1,
              results: const [
                _ExplanationResult(
                  startIndex: 8,
                  shortExplanation: 'Missing the tilde on the n.',
                ),
              ],
            ),
            _errorRunRecord(
              testCase: testCase1,
              runIndex: 2,
              error: StateError('Stage 3 call timed out'),
            ),
          ],
          'TEST-2-joinkey': [
            _buildRunRecord(
              testCase: testCase2,
              runIndex: 1,
              results: const [
                _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
                _ExplanationResult(startIndex: 10, shortExplanation: 'b.'),
              ],
            ),
            _buildRunRecord(
              testCase: testCase2,
              runIndex: 2,
              results: const [
                _ExplanationResult(startIndex: 0, shortExplanation: 'a.'),
              ],
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'stage3 feedback harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the Stage 3 feedback harness. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final recordsByCaseId = <String, List<_RunRecord>>{};

      try {
        for (final testCase in _cases) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${testCase.id} ===');

          for (var run = 1; run <= runsPerCase; run++) {
            _RunRecord record;
            try {
              final results = await _callStage3Feedback(
                httpClient: httpClient,
                apiKey: apiKey,
                model: stage3Model,
                corrections: testCase.corrections,
              );
              record = _buildRunRecord(
                testCase: testCase,
                runIndex: run,
                results: results,
              );
            } catch (error) {
              record = _errorRunRecord(testCase: testCase, runIndex: run, error: error);
            }
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(testCase, record));
            await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
          }

          recordsByCaseId[testCase.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: stage3Model,
        runsPerCase: runsPerCase,
        generatedAt: DateTime.now(),
        cases: _cases,
        recordsByCaseId: recordsByCaseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 30)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Stage 3 Feedback Harness\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per case: 2\n\n## Error-verdict cases (explanation must read as a correction)\n\n### TEST-1-error\n\n- Corrections: [{\"start_index\":8,\"original_phrase\":\"Espana\",\"corrected_phrase\":\"España\",\"category\":\"Spelling\",\"verdict\":\"error\"}]\n- Note: Synthetic error-verdict case for report golden test.\n\n#### Summary (2 runs, 1 error(s))\n\n- Target 1 (start_index=8):\n  - Missing (no matching result): 0.0% (0/1)\n  - Exactly one sentence: 100.0% (1/1)\n  - Mentions [tilde]: 100.0% (1/1)\n- Fully caught (every scored check in one run): 100.0% (1/1)\n\n#### Run detail\n\n- Run 1: start_index=8 -> \"Missing the tilde on the n.\"\n- Run 2: ERROR — Bad state: Stage 3 call timed out\n\n## Join-key integrity\n\n### TEST-2-joinkey\n\n- Corrections: [{\"start_index\":0,\"original_phrase\":\"a\",\"corrected_phrase\":\"b\",\"category\":\"Other\",\"verdict\":\"error\"},{\"start_index\":10,\"original_phrase\":\"c\",\"corrected_phrase\":\"d\",\"category\":\"Other\",\"verdict\":\"error\"}]\n- Note: Synthetic join-key case for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Target 1 (start_index=0):\n  - Missing (no matching result): 0.0% (0/2)\n  - Exactly one sentence: 100.0% (2/2)\n- Target 2 (start_index=10):\n  - Missing (no matching result): 50.0% (1/2)\n  - Exactly one sentence: 50.0% (1/2)\n- Join-key integrity: 50.0% (1/2)\n- Fully caught (every scored check in one run): 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: start_index=0 -> \"a.\" | start_index=10 -> \"b.\" | join-key: intact\n- Run 2: start_index=0 -> \"a.\" | start_index=10 -> (no matching result returned) | join-key: missing [10]\n\n---\n\n## Overall summary\n\n| Case | Runs | Errors | Fully caught |\n| --- | --- | --- | --- |\n| TEST-1-error | 2 | 1 | 100.0% (1/1) |\n| TEST-2-joinkey | 2 | 0 | 50.0% (1/2) |\n"';
