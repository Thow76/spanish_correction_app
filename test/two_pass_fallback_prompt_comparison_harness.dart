// Fallback naturalness prompt comparison harness (issue #110).
//
// Purpose: gather evidence for the fallback-prompt evaluation issue #110
// asks for — compare the CURRENT design (the fallback naturalness call
// reuses `naturalnessReviewSpanish` verbatim, with no signal that it's a
// rerun over already-corrected text) against a CANDIDATE fallback-specific
// prompt (explicitly told the text has already been corrected once, and
// told to restrain itself to only a clear remaining issue) — on the exact
// fixtures already identified as fallback over-rewrite cases in
// `docs/two_pass_prompt_contract_audit.md` §7a/§7d and
// `docs/two_pass_live_language_point_benchmark_issue_log.md`.
//
// Deliberately narrow and standalone, not an extension of the (already
// very large) `test/two_pass_integration_harness.dart`: this evaluates
// ONE isolated call (the fallback naturalness call alone, against a known
// already-correct first-pass output), not the whole two-pass pipeline.
// Calls `OpenAiChatCompletionsClient.complete()` directly with each
// candidate system prompt, rather than going through
// `callNaturalnessReview` (which always uses the fixed production
// `naturalnessReviewSpanish` constant) — the prompt text is exactly the
// variable under test here.
//
// This harness does NOT decide production behavior on its own — issue
// #110 asks for a documented recommendation informed by this harness's
// results, not an automatic prompt swap. No production code is changed by
// this file.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_fallback_prompt_comparison_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls — 5 fixtures x 2 prompt
// variants = 10 calls):
//   OPENAI_API_KEY=sk-... \
//   FALLBACK_PROMPT_COMPARISON_LIVE=true \
//   flutter test test/two_pass_fallback_prompt_comparison_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - FALLBACK_COMPARISON_MODEL: defaults to gpt-5.1 (the production
//   naturalness model).
// - FALLBACK_COMPARISON_OUTPUT: report path, defaults to
//   docs/two_pass_fallback_prompt_comparison.md.
// - FALLBACK_COMPARISON_CALL_DELAY_MS: delay between calls, defaults to
//   750.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';

/// The candidate fallback-specific system prompt (issue #110) — everything
/// `naturalnessReviewSpanish` (v4, issue #108) already establishes (narrow
/// naturalness-only scope, regional-variety restraint, exactly one
/// replacement) stays, plus new framing specific to what the fallback call
/// actually is: a second look at text a prior pass already corrected, not
/// a first look at raw learner text.
const String candidateFallbackPrompt =
    'You are a Spanish tutor doing a final naturalness check on text that '
    'has already been corrected for grammar, spelling, and punctuation, '
    'and already reviewed once for naturalness.\n'
    '\n'
    'Only flag wording that is still clearly unnatural — a calque, idiom, '
    'or collocation a native Spanish speaker would not use. Do not flag '
    'anything you are not confident about.\n'
    '\n'
    'Do not restructure the sentence. Do not add new information, new '
    'clauses, or new ideas that were not in the original text. Do not '
    'change the meaning.\n'
    '\n'
    'Do not report spelling, punctuation, or grammatical errors.\n'
    'If the only problem is grammar, spelling, or punctuation, return no '
    'issue.\n'
    '\n'
    'Do not normalise wording that is natural in an established variety of '
    'Spanish. A form is not a naturalness issue merely because another '
    'form is more widespread, more neutral, or preferred by the '
    'reviewer\'s own regional variety.\n'
    '\n'
    'Ignore spelling, punctuation, or grammar errors even if they appear '
    'in the same sentence as a naturalness issue.\n'
    '\n'
    'Give exactly one natural replacement for each issue — never more '
    'than one option, and never join alternatives with a slash, "or", or '
    'a list. If more than one wording would work, choose the single best '
    'one yourself.\n'
    '\n'
    'Return JSON only.';

/// Which system prompt a comparison run used.
enum FallbackPromptVariant {
  /// The current design: the fallback call reuses `naturalnessReviewSpanish`
  /// verbatim, exactly as `callNaturalnessReview` does today.
  currentReused,

  /// The candidate fallback-specific prompt (issue #110), told explicitly
  /// that the text has already been corrected.
  candidateFallbackSpecific,
}

/// One known fallback over-rewrite case (issue #110) — the fixture's
/// [firstPassCorrectedText] is not a guess: it is the exact, repeatedly
/// observed first-pass output for [originalText] across every live run in
/// `docs/two_pass_integration_harness.md` and
/// `docs/two_pass_live_language_point_benchmark_issue_log.md` (the first
/// pass reliably gets these right) — [knownOverRewriteOutput] is the
/// fallback's own already-observed, incorrect rewrite of that same
/// already-correct text.
class FallbackComparisonFixture {
  const FallbackComparisonFixture({
    required this.id,
    required this.originalText,
    required this.firstPassCorrectedText,
    required this.knownOverRewriteOutput,
    required this.note,
  });

  final String id;
  final String originalText;
  final String firstPassCorrectedText;
  final String knownOverRewriteOutput;
  final String note;
}

const List<FallbackComparisonFixture> fallbackComparisonFixtures = [
  FallbackComparisonFixture(
    id: 'clean-grammar-only-overrewrite',
    originalText: 'Vi mucho trafico ayer.',
    firstPassCorrectedText: 'Vi mucho tráfico ayer.',
    knownOverRewriteOutput: 'Había mucho tráfico ayer.',
    note:
        'The first pass correctly fixes the accent; the currently-reused '
        'prompt has repeatedly rewritten the whole sentence into a '
        'different one ("I saw" -> "there was") on the fallback rerun.',
  ),
  FallbackComparisonFixture(
    id: 'false-friend-atendio-overrewrite',
    originalText: 'Atendió la universidad en Madrid.',
    firstPassCorrectedText: 'Asistió a la universidad en Madrid.',
    knownOverRewriteOutput: 'Estudió en la universidad en Madrid.',
    note:
        'The first pass already produces the exact expected fix; the '
        'currently-reused prompt has repeatedly re-edited it anyway to a '
        'different, less precise wording on the fallback rerun.',
  ),
  FallbackComparisonFixture(
    id: 'mixed-personal-a-subjunctive-overrewrite',
    originalText:
        'Vi mi profesor en la estación, y es importante que estudias.',
    firstPassCorrectedText:
        'Vi a mi profesor en la estación, y es importante que estudies.',
    knownOverRewriteOutput:
        'Vi a mi profesor en la estación, y me dijo que era importante que '
        'estudiara.',
    note:
        'The first pass already produces the exact expected fix; the '
        'currently-reused prompt has repeatedly added a new clause '
        '("me dijo que...") not present anywhere in the original on the '
        'fallback rerun.',
  ),
  FallbackComparisonFixture(
    id: 'mixed-verb-agreement-que-overrewrite',
    originalText:
        'Ellos estudia todas las noches, y creo está bien terminar hoy.',
    firstPassCorrectedText:
        'Ellos estudian todas las noches, y creo que está bien terminar '
        'hoy.',
    knownOverRewriteOutput:
        'Estudian todas las noches, y creo que podemos terminar hoy.',
    note:
        'The first pass already produces the exact expected fix; the '
        'currently-reused prompt has repeatedly dropped the subject '
        '"Ellos" and changed the second clause\'s modality on the '
        'fallback rerun.',
  ),
  FallbackComparisonFixture(
    id: 'subjunctive-su-parte-overrewrite',
    originalText: 'Era necesario que enviaba su parte.',
    firstPassCorrectedText: 'Era necesario que enviara su parte.',
    knownOverRewriteOutput: 'Era necesario que enviara su informe.',
    note:
        'The first pass already produces the exact expected fix; the '
        'currently-reused prompt has repeatedly replaced "su parte" with '
        'the more specific, uninvited "su informe" on the fallback rerun.',
  ),
];

const String _defaultModel = 'gpt-5.1';
const String defaultFallbackComparisonOutputPath =
    'docs/two_pass_fallback_prompt_comparison.md';

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'FALLBACK_PROMPT_COMPARISON_LIVE',
  defaultValue: false,
);

bool _liveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      (environment['FALLBACK_PROMPT_COMPARISON_LIVE']?.trim().toLowerCase() ==
          'true');
}

String _runtimeString({
  required Map<String, String> environment,
  required String key,
  required String defaultValue,
}) {
  final fromEnvironment = environment[key]?.trim() ?? '';
  return fromEnvironment.isNotEmpty ? fromEnvironment : defaultValue;
}

int callDelayMsFrom(Map<String, String> environment) {
  final raw = _runtimeString(
    environment: environment,
    key: 'FALLBACK_COMPARISON_CALL_DELAY_MS',
    defaultValue: '750',
  );
  return int.tryParse(raw) ?? 750;
}

/// What happened when a candidate prompt reviewed an already-correct
/// first-pass output (issue #110) — ordered from best to worst so a
/// reader can scan straight down a comparison table and see which variant
/// skews toward the top.
enum FallbackComparisonOutcome {
  /// No naturalness issue was flagged at all — the ideal outcome for text
  /// that's already correct.
  noIssueFlagged('no_issue_flagged'),

  /// An issue was flagged, but the merge could not safely apply it (span
  /// not found, ambiguous, or a slash-joined multi-option replacement) —
  /// the text is unchanged either way, but the model still flagged
  /// something spurious.
  issueFlaggedNotApplied('issue_flagged_not_applied'),

  /// An issue was flagged and applied, but the resulting text is
  /// unchanged from the input (e.g. the replacement equals the span) —
  /// harmless in practice.
  issueAppliedNoChange('issue_applied_no_change'),

  /// An issue was flagged, applied, and the text actually changed — the
  /// over-rewrite behavior this evaluation exists to measure.
  issueAppliedTextChanged('issue_applied_text_changed'),

  /// The call itself failed (network/parse error).
  error('error');

  const FallbackComparisonOutcome(this.reportLabel);

  final String reportLabel;
}

/// One variant's result for one fixture.
class FallbackComparisonResult {
  const FallbackComparisonResult({
    required this.fixture,
    required this.variant,
    required this.outcome,
    required this.resultingText,
    this.errorMessage,
  });

  final FallbackComparisonFixture fixture;
  final FallbackPromptVariant variant;
  final FallbackComparisonOutcome outcome;

  /// The text after this variant's review is merged in — identical to
  /// [FallbackComparisonFixture.firstPassCorrectedText] unless the
  /// outcome is [FallbackComparisonOutcome.issueAppliedTextChanged].
  final String resultingText;

  final String? errorMessage;
}

/// Runs one comparison call: [systemPrompt] against [fixture]'s own
/// already-correct [FallbackComparisonFixture.firstPassCorrectedText],
/// then merges whatever naturalness review comes back the same way
/// production's fallback merge does ([mergeNaturalnessReview]) — so a
/// "changed" outcome here means the same thing it would mean in
/// production: this variant's review, if it were live, would actually
/// alter already-correct text.
Future<FallbackComparisonResult> runComparisonCall({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String systemPrompt,
  required FallbackComparisonFixture fixture,
  required FallbackPromptVariant variant,
}) async {
  try {
    final replyText = await client.complete(
      model: model,
      systemPrompt: systemPrompt,
      userText: buildNaturalnessUserContent(fixture.firstPassCorrectedText),
      stageLabel: 'fallback_prompt_comparison',
      responseFormat: naturalnessReviewResponseFormat,
    );
    final review = parseNaturalnessReviewResponse(replyText);

    if (!review.hasNaturalnessIssue || review.issues.isEmpty) {
      return FallbackComparisonResult(
        fixture: fixture,
        variant: variant,
        outcome: FallbackComparisonOutcome.noIssueFlagged,
        resultingText: fixture.firstPassCorrectedText,
      );
    }

    final merge = mergeNaturalnessReview(
      originalText: fixture.firstPassCorrectedText,
      firstPassCorrectedText: fixture.firstPassCorrectedText,
      naturalnessReview: review,
    );

    if (merge.appliedEdits.isEmpty) {
      return FallbackComparisonResult(
        fixture: fixture,
        variant: variant,
        outcome: FallbackComparisonOutcome.issueFlaggedNotApplied,
        resultingText: fixture.firstPassCorrectedText,
      );
    }

    final outcome = merge.finalCorrectedText == fixture.firstPassCorrectedText
        ? FallbackComparisonOutcome.issueAppliedNoChange
        : FallbackComparisonOutcome.issueAppliedTextChanged;

    return FallbackComparisonResult(
      fixture: fixture,
      variant: variant,
      outcome: outcome,
      resultingText: merge.finalCorrectedText,
    );
  } catch (error) {
    return FallbackComparisonResult(
      fixture: fixture,
      variant: variant,
      outcome: FallbackComparisonOutcome.error,
      resultingText: '',
      errorMessage: error.toString(),
    );
  }
}

/// Builds the comparison report: one row per fixture, one column per
/// variant, plus an aggregate "changed already-correct text" rate per
/// variant — the single number issue #110's recommendation should weigh
/// most heavily, since an unwanted text change on already-correct input is
/// exactly the failure mode under evaluation.
String buildFallbackComparisonReport({
  required String model,
  required List<FallbackComparisonResult> currentResults,
  required List<FallbackComparisonResult> candidateResults,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# Fallback Naturalness Prompt Comparison (issue #110)')
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- Naturalness model: `$model`')
    ..writeln('- Fixture count: `${fallbackComparisonFixtures.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(
      'Each fixture below is called once under each variant, against the '
      'exact same already-correct `firstPassCorrectedText` — the only '
      'thing that differs between the two calls for the same fixture is '
      'the system prompt.',
    )
    ..writeln()
    ..writeln(
      '| Fixture | Current-reused outcome | Current-reused result | '
      'Candidate outcome | Candidate result |',
    )
    ..writeln('| --- | --- | --- | --- | --- |');

  final currentByFixtureId = {
    for (final r in currentResults) r.fixture.id: r,
  };
  final candidateByFixtureId = {
    for (final r in candidateResults) r.fixture.id: r,
  };

  for (final fixture in fallbackComparisonFixtures) {
    final current = currentByFixtureId[fixture.id];
    final candidate = candidateByFixtureId[fixture.id];
    buffer.writeln(
      '| ${fixture.id} | ${current?.outcome.reportLabel ?? '(not run)'} | '
      '`${current?.resultingText ?? ''}` | '
      '${candidate?.outcome.reportLabel ?? '(not run)'} | '
      '`${candidate?.resultingText ?? ''}` |',
    );
  }

  buffer
    ..writeln()
    ..writeln('## Aggregate: unwanted change rate on already-correct text')
    ..writeln()
    ..writeln('| Variant | Changed already-correct text | Rate |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| Current (reused naturalness prompt) | '
      '${_changedCount(currentResults)}/${currentResults.length} | '
      '${_formatRate(_changedCount(currentResults), currentResults.length)} |',
    )
    ..writeln(
      '| Candidate (fallback-specific prompt) | '
      '${_changedCount(candidateResults)}/${candidateResults.length} | '
      '${_formatRate(_changedCount(candidateResults), candidateResults.length)} |',
    );

  return buffer.toString();
}

int _changedCount(List<FallbackComparisonResult> results) => results
    .where((r) => r.outcome == FallbackComparisonOutcome.issueAppliedTextChanged)
    .length;

String _formatRate(int count, int total) {
  if (total == 0) {
    return 'n/a';
  }
  return '${(count / total * 100).toStringAsFixed(1)}%';
}

void main() {
  group('offline sanity (no API calls)', () {
    test('fixture ids are unique', () {
      final ids = fallbackComparisonFixtures.map((f) => f.id).toSet();
      expect(ids.length, fallbackComparisonFixtures.length);
    });

    test(
      'every fixture carries a known-correct first-pass output distinct '
      'from its own known over-rewrite output',
      () {
        for (final fixture in fallbackComparisonFixtures) {
          expect(fixture.originalText, isNotEmpty, reason: fixture.id);
          expect(
            fixture.firstPassCorrectedText,
            isNotEmpty,
            reason: fixture.id,
          );
          expect(
            fixture.knownOverRewriteOutput,
            isNot(fixture.firstPassCorrectedText),
            reason:
                '${fixture.id}: the known over-rewrite output should '
                'differ from the known-correct first-pass output — '
                'otherwise it is not evidence of an over-rewrite at all',
          );
        }
      },
    );

    test(
      'candidateFallbackPrompt keeps every naturalness-scope restraint '
      'from naturalnessReviewSpanish, and adds fallback-specific framing',
      () {
        for (final sharedRestraint in [
          'Do not report spelling, punctuation, or grammatical errors.',
          'Do not normalise wording that is natural in an established '
              'variety of Spanish.',
          'Give exactly one natural replacement for each issue',
        ]) {
          expect(candidateFallbackPrompt, contains(sharedRestraint));
        }
        expect(
          candidateFallbackPrompt,
          contains('has already been corrected for grammar'),
        );
        expect(
          candidateFallbackPrompt,
          contains('Do not restructure the sentence'),
        );
        expect(
          candidateFallbackPrompt,
          contains('Do not add new information'),
        );
      },
    );

    test(
      'runComparisonCall classifies noIssueFlagged when the model finds '
      'nothing wrong',
      () async {
        final fixture = fallbackComparisonFixtures.first;
        final client = _FakeHttpClient(
          replyBody: _envelope(
            '{"has_naturalness_issue": false, "issues": []}',
          ),
        );
        final result = await runComparisonCall(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: _defaultModel,
          systemPrompt: candidateFallbackPrompt,
          fixture: fixture,
          variant: FallbackPromptVariant.candidateFallbackSpecific,
        );

        expect(result.outcome, FallbackComparisonOutcome.noIssueFlagged);
        expect(result.resultingText, fixture.firstPassCorrectedText);
      },
    );

    test(
      'runComparisonCall classifies issueAppliedTextChanged when the '
      'flagged issue is applied and the text actually changes — '
      'reproducing a known over-rewrite case',
      () async {
        final fixture = fallbackComparisonFixtures.firstWhere(
          (f) => f.id == 'subjunctive-su-parte-overrewrite',
        );
        final client = _FakeHttpClient(
          replyBody: _envelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "su parte", "natural_replacement": "su informe", '
            '"explanation": "More concrete noun."}'
            ']}',
          ),
        );
        final result = await runComparisonCall(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: _defaultModel,
          systemPrompt: naturalnessReviewSpanish,
          fixture: fixture,
          variant: FallbackPromptVariant.currentReused,
        );

        expect(
          result.outcome,
          FallbackComparisonOutcome.issueAppliedTextChanged,
        );
        expect(result.resultingText, fixture.knownOverRewriteOutput);
      },
    );

    test(
      'runComparisonCall classifies issueFlaggedNotApplied when the span '
      'cannot be safely merged',
      () async {
        final fixture = fallbackComparisonFixtures.first;
        final client = _FakeHttpClient(
          replyBody: _envelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "no existe en el texto", '
            '"natural_replacement": "reemplazo", '
            '"explanation": "Never actually present."}'
            ']}',
          ),
        );
        final result = await runComparisonCall(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: _defaultModel,
          systemPrompt: candidateFallbackPrompt,
          fixture: fixture,
          variant: FallbackPromptVariant.candidateFallbackSpecific,
        );

        expect(
          result.outcome,
          FallbackComparisonOutcome.issueFlaggedNotApplied,
        );
        expect(result.resultingText, fixture.firstPassCorrectedText);
      },
    );

    test(
      'runComparisonCall classifies error rather than throwing when the '
      'call fails',
      () async {
        final fixture = fallbackComparisonFixtures.first;
        final client = _FakeHttpClient(replyBody: 'not json at all');
        final result = await runComparisonCall(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: _defaultModel,
          systemPrompt: candidateFallbackPrompt,
          fixture: fixture,
          variant: FallbackPromptVariant.candidateFallbackSpecific,
        );

        expect(result.outcome, FallbackComparisonOutcome.error);
        expect(result.errorMessage, isNotNull);
      },
    );

    test(
      'buildFallbackComparisonReport renders both variants per fixture '
      'and an aggregate change rate',
      () {
        final fixture = fallbackComparisonFixtures.firstWhere(
          (f) => f.id == 'subjunctive-su-parte-overrewrite',
        );
        final report = buildFallbackComparisonReport(
          model: _defaultModel,
          currentResults: [
            FallbackComparisonResult(
              fixture: fixture,
              variant: FallbackPromptVariant.currentReused,
              outcome: FallbackComparisonOutcome.issueAppliedTextChanged,
              resultingText: fixture.knownOverRewriteOutput,
            ),
          ],
          candidateResults: [
            FallbackComparisonResult(
              fixture: fixture,
              variant: FallbackPromptVariant.candidateFallbackSpecific,
              outcome: FallbackComparisonOutcome.noIssueFlagged,
              resultingText: fixture.firstPassCorrectedText,
            ),
          ],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(report, contains('subjunctive-su-parte-overrewrite'));
        expect(report, contains('issue_applied_text_changed'));
        expect(report, contains('no_issue_flagged'));
        expect(report, contains('| Current (reused naturalness prompt) | 1/1 | 100.0% |'));
        expect(
          report,
          contains('| Candidate (fallback-specific prompt) | 0/1 | 0.0% |'),
        );
      },
    );

    test('callDelayMsFrom reads a real environment variable', () {
      expect(
        callDelayMsFrom(const {'FALLBACK_COMPARISON_CALL_DELAY_MS': '2000'}),
        2000,
      );
      expect(callDelayMsFrom(const {}), 750);
    });
  });

  test(
    'fallback prompt comparison: current-reused vs candidate '
    'fallback-specific prompt',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!_liveRunOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live fallback prompt comparison. Set '
          'FALLBACK_PROMPT_COMPARISON_LIVE=true to opt in.',
        );
        return;
      }

      final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the fallback prompt comparison '
          'harness. This script does NOT fall back to any hardcoded/'
          'default key.',
        );
      }

      final model = _runtimeString(
        environment: environment,
        key: 'FALLBACK_COMPARISON_MODEL',
        defaultValue: _defaultModel,
      );
      final outputPath = _runtimeString(
        environment: environment,
        key: 'FALLBACK_COMPARISON_OUTPUT',
        defaultValue: defaultFallbackComparisonOutputPath,
      );
      final callDelayMs = callDelayMsFrom(environment);
      final httpClient = HttpClient();
      final client = OpenAiChatCompletionsClient(
        apiKey: apiKey,
        httpClient: httpClient,
      );

      final currentResults = <FallbackComparisonResult>[];
      final candidateResults = <FallbackComparisonResult>[];

      for (final fixture in fallbackComparisonFixtures) {
        final current = await runComparisonCall(
          client: client,
          model: model,
          systemPrompt: naturalnessReviewSpanish,
          fixture: fixture,
          variant: FallbackPromptVariant.currentReused,
        );
        currentResults.add(current);
        // ignore: avoid_print
        print(
          '=== ${fixture.id} (current) === '
          '${current.outcome.reportLabel}: "${current.resultingText}"',
        );
        await Future<void>.delayed(Duration(milliseconds: callDelayMs));

        final candidate = await runComparisonCall(
          client: client,
          model: model,
          systemPrompt: candidateFallbackPrompt,
          fixture: fixture,
          variant: FallbackPromptVariant.candidateFallbackSpecific,
        );
        candidateResults.add(candidate);
        // ignore: avoid_print
        print(
          '=== ${fixture.id} (candidate) === '
          '${candidate.outcome.reportLabel}: "${candidate.resultingText}"',
        );
        await Future<void>.delayed(Duration(milliseconds: callDelayMs));
      }

      final report = buildFallbackComparisonReport(
        model: model,
        currentResults: currentResults,
        candidateResults: candidateResults,
        generatedAt: DateTime.now(),
      );

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote fallback prompt comparison report to $outputPath');
    },
  );
}

String _envelope(String content) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': content},
    },
  ],
});

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient({required this.replyBody});

  final String replyBody;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _FakeHttpClientRequest(replyBody: replyBody);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest({required this.replyBody});

  final String replyBody;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) {}

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(replyBody: replyBody);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse({required String replyBody}) : _body = replyBody;

  final String _body;

  @override
  final int statusCode = 200;

  late final Stream<List<int>> _inner = Stream.fromIterable([
    utf8.encode(_body),
  ]);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _inner.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}
