// Full-pipeline fallback prompt comparison harness (issue #117).
//
// Purpose: answer the actual product question issue #110's isolated,
// forced-call comparison could not: "when the full two-pass pipeline
// naturally triggers fallback, does a fallback-specific prompt improve
// the final output?" Issue #110 called the naturalness endpoint directly
// against known first-pass output, bypassing conflict detection entirely
// — useful exploratory evidence, but not proof about real pipeline
// behavior. This harness runs the REAL sequence: pass 1
// (`callFirstPassCorrection`) and pass 2 (`callNaturalnessReview`,
// parallel) exactly as production calls them, the real
// `mergeNaturalnessReview` conflict detection, and — only when that
// merge genuinely has a skipped edit — a fallback naturalness call,
// compared side by side under two system prompts.
//
// Pass 1 and the parallel naturalness call are run ONCE per fixture and
// shared between both variants: which fallback prompt is under test can
// never affect either of those calls, so sharing them is both cheaper and
// more scientifically valid (both variants see an identical fallback
// trigger decision and an identical `firstPassCorrectedText` to fall back
// against). Only the fallback call itself — run once per variant, and
// only when the real conflict logic actually triggers it — differs.
//
// Self-contained: does not import anything from the (unmerged) issue #110
// branch. `candidateFallbackPrompt` is redefined here by value, same text.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_fallback_pipeline_comparison_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls — 10 fixtures, first pass +
// naturalness-on-original always (20 calls), plus up to 2 fallback calls
// per fixture only when a conflict is genuinely triggered — expect on the
// order of 30-40 total calls, well under a full benchmark run):
//   OPENAI_API_KEY=sk-... \
//   FALLBACK_PIPELINE_COMPARISON_LIVE=true \
//   flutter test test/two_pass_fallback_pipeline_comparison_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - FALLBACK_PIPELINE_FIRST_PASS_MODEL: defaults to gpt-4.1.
// - FALLBACK_PIPELINE_NATURALNESS_MODEL: defaults to gpt-5.1.
// - FALLBACK_PIPELINE_OUTPUT: report path, defaults to
//   docs/two_pass_fallback_pipeline_comparison.md.
// - FALLBACK_PIPELINE_CALL_DELAY_MS: delay between fixtures, defaults to
//   750.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_correction_mapper.dart';
import 'package:spanish_correction_app/features/corrections/domain/naturalness_merge.dart';
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
        scoreFixtureResult;

/// The candidate fallback-specific prompt evaluated in issue #110,
/// redefined here by value (this file does not depend on the unmerged
/// #110 branch). Keeps every restraint `naturalnessReviewSpanish` (v4,
/// issue #108) already has, plus explicit "this text was already
/// corrected; only flag a clear remaining issue; do not restructure or
/// add content" framing.
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

/// The curated test set (issue #117's own "Test Set" section) — ids drawn
/// from the real language-point benchmark (`allTwoPassFixtures`,
/// issue #82), chosen for known, previously-observed fallback behavior:
/// clean grammar-only cases that triggered fallback, already-correct
/// do-not-touch cases, true naturalness cases, mixed/coherence cases
/// (reported separately, per the issue's own instruction — see each
/// fixture's `languagePoint`), a false-friend re-edit case, and a
/// subjunctive/mood case. Reusing real fixtures (not hand-typed inputs)
/// means expected outputs and language-point grouping stay identical to
/// every other benchmark report.
const List<String> fallbackPipelineComparisonFixtureIds = [
  'clean-grammar-only',
  'correct-tomar-foto',
  'correct-buenos-dias',
  'regional-voy-para-casa',
  'naturalness-buen-tiempo',
  'naturalness-corriendo-tarde',
  'mixed-personal-a-and-subjunctive',
  'mixed-verb-agreement-and-missing-que',
  'false-friend-atendio-universidad',
  'subj-enviara',
];

List<TwoPassFixture> get fallbackPipelineComparisonFixtures =>
    fallbackPipelineComparisonFixtureIds
        .map(
          (id) => allTwoPassFixtures.firstWhere(
            (f) => f.id == id,
            orElse: () => throw StateError(
              'No fixture with id "$id" in allTwoPassFixtures.',
            ),
          ),
        )
        .toList();

const String _defaultFirstPassModel = 'gpt-4.1';
const String _defaultNaturalnessModel = 'gpt-5.1';
const String defaultFallbackPipelineOutputPath =
    'docs/two_pass_fallback_pipeline_comparison.md';

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'FALLBACK_PIPELINE_COMPARISON_LIVE',
  defaultValue: false,
);

bool _liveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      (environment['FALLBACK_PIPELINE_COMPARISON_LIVE']
              ?.trim()
              .toLowerCase() ==
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
    key: 'FALLBACK_PIPELINE_CALL_DELAY_MS',
    defaultValue: '750',
  );
  return int.tryParse(raw) ?? 750;
}

/// One prompt variant's outcome for one fixture, within the real pipeline.
class FallbackVariantOutcome {
  const FallbackVariantOutcome({
    required this.fallbackTriggered,
    required this.fallbackReviewDescription,
    required this.finalCorrectedText,
    required this.score,
    required this.reason,
  });

  final bool fallbackTriggered;

  /// Description of what the fallback call itself flagged, or `null` when
  /// fallback was never triggered (real conflict logic said no).
  final String? fallbackReviewDescription;
  final String finalCorrectedText;
  final TwoPassScoreLabel score;
  final String reason;
}

/// Both variants' results for one fixture, sharing the real pass 1 /
/// parallel-naturalness-pass 2 results and the real conflict decision.
class FallbackPipelineComparisonResult {
  const FallbackPipelineComparisonResult({
    required this.fixture,
    required this.firstPassCorrectedText,
    required this.naturalnessOnOriginalDescription,
    required this.hadConflict,
    required this.current,
    required this.candidate,
  });

  final TwoPassFixture fixture;
  final String firstPassCorrectedText;
  final String naturalnessOnOriginalDescription;

  /// Whether the real `mergeNaturalnessReview` conflict logic triggered
  /// fallback at all — identical for both variants, since the trigger
  /// condition depends only on the parallel merge, never on which
  /// fallback prompt exists.
  final bool hadConflict;

  final FallbackVariantOutcome current;
  final FallbackVariantOutcome candidate;
}

String _describeReview(NaturalnessReview review) {
  if (!review.hasNaturalnessIssue) {
    return '(none)';
  }
  return review.issues
      .map((issue) => '${issue.span} -> ${issue.naturalReplacement}')
      .join('<br>');
}

TwoPassScoreLabel _score(TwoPassFixture fixture, String finalCorrectedText) {
  const emptyReview = NaturalnessReview(hasNaturalnessIssue: false, issues: []);
  final result = FixtureResult(
    fixture: fixture,
    firstPassCorrectedText: finalCorrectedText,
    firstPassStats: CallStats.zero,
    naturalnessOnOriginal: emptyReview,
    naturalnessOnOriginalStats: CallStats.zero,
    naturalnessOnFirstPass: emptyReview,
    naturalnessOnFirstPassStats: CallStats.zero,
    parallelPhaseWallClockMs: 0,
    hadConflict: false,
    usedFallback: false,
    finalCorrectedText: finalCorrectedText,
    finalCorrectionCount: 0,
  );
  return scoreFixtureResult(result);
}

String _reasonFor({
  required TwoPassFixture fixture,
  required String finalCorrectedText,
  required String firstPassCorrectedText,
  required bool fallbackTriggered,
}) {
  final score = _score(fixture, finalCorrectedText);
  if (isPassingScore(score)) {
    return finalCorrectedText == firstPassCorrectedText
        ? 'Matches expected output; already-correct first-pass text was '
              'left unchanged.'
        : 'Matches expected output after the fallback edit was applied.';
  }
  if (!fallbackTriggered) {
    return 'Fallback was never triggered (no conflict), but the parallel '
        'merge alone still did not produce the expected output.';
  }
  if (finalCorrectedText == firstPassCorrectedText) {
    return 'Fallback flagged something, but the merge could not safely '
        'apply it (or the model reported no issue) — already-correct '
        'first-pass text was preserved regardless.';
  }
  return 'Fallback changed the first-pass text to something that does '
      'not match the expected output.';
}

/// Runs the real pipeline sequence once (pass 1 + parallel naturalness +
/// merge + conflict check), then — only if the real conflict logic
/// triggers it — runs the fallback call once per prompt variant, against
/// the exact same `firstPassCorrectedText`, so the system prompt is the
/// only variable between the two variants' fallback calls.
Future<FallbackPipelineComparisonResult> runFallbackPipelineComparison({
  required OpenAiChatCompletionsClient client,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
}) async {
  final firstPassFuture = callFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: fixture.text,
  );
  final parallelNaturalnessFuture = callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: fixture.text,
  );
  final firstPassResponse = await firstPassFuture;
  final parallelNaturalnessReview = await parallelNaturalnessFuture;

  final parallelMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: parallelNaturalnessReview,
  );
  final hadConflict = parallelMerge.skippedEdits.isNotEmpty;

  Future<FallbackVariantOutcome> runVariant(String fallbackSystemPrompt) async {
    if (!hadConflict) {
      final response = mapNaturalnessEditsIntoCorrectionResponse(
        firstPassResponse: firstPassResponse,
        naturalnessMerge: parallelMerge,
      );
      return FallbackVariantOutcome(
        fallbackTriggered: false,
        fallbackReviewDescription: null,
        finalCorrectedText: response.correctedText,
        score: _score(fixture, response.correctedText),
        reason: _reasonFor(
          fixture: fixture,
          finalCorrectedText: response.correctedText,
          firstPassCorrectedText: firstPassResponse.correctedText,
          fallbackTriggered: false,
        ),
      );
    }

    final replyText = await client.complete(
      model: naturalnessModel,
      systemPrompt: fallbackSystemPrompt,
      userText: buildNaturalnessUserContent(firstPassResponse.correctedText),
      stageLabel: 'fallback_pipeline_comparison',
      responseFormat: naturalnessReviewResponseFormat,
    );
    final fallbackReview = parseNaturalnessReviewResponse(replyText);
    final fallbackMerge = mergeNaturalnessReview(
      originalText: fixture.text,
      firstPassCorrectedText: firstPassResponse.correctedText,
      naturalnessReview: fallbackReview,
    );
    final response = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: firstPassResponse,
      naturalnessMerge: fallbackMerge,
    );
    return FallbackVariantOutcome(
      fallbackTriggered: true,
      fallbackReviewDescription: _describeReview(fallbackReview),
      finalCorrectedText: response.correctedText,
      score: _score(fixture, response.correctedText),
      reason: _reasonFor(
        fixture: fixture,
        finalCorrectedText: response.correctedText,
        firstPassCorrectedText: firstPassResponse.correctedText,
        fallbackTriggered: true,
      ),
    );
  }

  final currentOutcome = await runVariant(naturalnessReviewSpanish);
  final candidateOutcome = await runVariant(candidateFallbackPrompt);

  return FallbackPipelineComparisonResult(
    fixture: fixture,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessOnOriginalDescription: _describeReview(
      parallelNaturalnessReview,
    ),
    hadConflict: hadConflict,
    current: currentOutcome,
    candidate: candidateOutcome,
  );
}

/// Builds the comparison report, grouped by language point (issue #117's
/// own "grouped by case type" requirement) so mixed/coherence cases don't
/// distort clean do-not-touch cases in the reader's impression.
String buildFallbackPipelineComparisonReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<FallbackPipelineComparisonResult> results,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln('# Two-Pass Fallback Prompt Comparison: Full Pipeline (issue #117)')
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixture count: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(
      'Pass 1 and the parallel naturalness call are run once per fixture '
      'and shared between both variants below — only the fallback call '
      'itself (run once per variant, only when the real conflict logic '
      'in `mergeNaturalnessReview` actually triggers it) differs.',
    )
    ..writeln();

  final byLanguagePoint = <String, List<FallbackPipelineComparisonResult>>{};
  final order = <String>[];
  for (final result in results) {
    final key = result.fixture.languagePoint;
    if (!byLanguagePoint.containsKey(key)) {
      order.add(key);
    }
    (byLanguagePoint[key] ??= []).add(result);
  }

  for (final languagePoint in order) {
    buffer
      ..writeln('## $languagePoint')
      ..writeln();
    for (final result in byLanguagePoint[languagePoint]!) {
      buffer
        ..writeln('### ${result.fixture.id}')
        ..writeln()
        ..writeln('- Original text: `${result.fixture.text}`')
        ..writeln(
          '- Expected corrected text: '
          '`${result.fixture.expectedCorrectedText}`',
        )
        ..writeln(
          '- Pass 1 (first-pass corrected text): '
          '`${result.firstPassCorrectedText}`',
        )
        ..writeln(
          '- Pass 2 (naturalness on original): '
          '${result.naturalnessOnOriginalDescription}',
        )
        ..writeln('- Fallback triggered: ${result.hadConflict}')
        ..writeln()
        ..writeln('| Variant | Fallback output | Final output | Score | Reason |')
        ..writeln('| --- | --- | --- | --- | --- |')
        ..writeln(
          '| Current (reused prompt) | '
          '${result.current.fallbackReviewDescription ?? '(fallback not triggered)'} | '
          '`${result.current.finalCorrectedText}` | '
          '${result.current.score.reportLabel} | ${result.current.reason} |',
        )
        ..writeln(
          '| Candidate (fallback-specific) | '
          '${result.candidate.fallbackReviewDescription ?? '(fallback not triggered)'} | '
          '`${result.candidate.finalCorrectedText}` | '
          '${result.candidate.score.reportLabel} | '
          '${result.candidate.reason} |',
        )
        ..writeln();
    }
  }

  final triggeredResults = results.where((r) => r.hadConflict).toList();
  final currentPassCount = results
      .where((r) => isPassingScore(r.current.score))
      .length;
  final candidatePassCount = results
      .where((r) => isPassingScore(r.candidate.score))
      .length;

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Fixtures | ${results.length} |')
    ..writeln('| Fixtures where fallback triggered | '
        '${triggeredResults.length} |')
    ..writeln(
      '| Current pass rate (correct_fix + acceptable_no_change) | '
      '$currentPassCount/${results.length} |',
    )
    ..writeln(
      '| Candidate pass rate (correct_fix + acceptable_no_change) | '
      '$candidatePassCount/${results.length} |',
    );

  return buffer.toString();
}

void main() {
  group('offline sanity (no API calls)', () {
    test('fallbackPipelineComparisonFixtureIds all resolve to real fixtures', () {
      expect(
        fallbackPipelineComparisonFixtures.map((f) => f.id).toList(),
        fallbackPipelineComparisonFixtureIds,
      );
    });

    test('fixture ids are unique', () {
      final ids = fallbackPipelineComparisonFixtureIds.toSet();
      expect(ids.length, fallbackPipelineComparisonFixtureIds.length);
    });

    test(
      'candidateFallbackPrompt keeps every naturalness-scope restraint '
      'and adds fallback-specific framing',
      () {
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
          contains('Give exactly one natural replacement'),
        );
      },
    );

    test('callDelayMsFrom reads a real environment variable', () {
      expect(
        callDelayMsFrom(const {'FALLBACK_PIPELINE_CALL_DELAY_MS': '2000'}),
        2000,
      );
      expect(callDelayMsFrom(const {}), 750);
    });

    test(
      'buildFallbackPipelineComparisonReport groups fixtures by language '
      'point and renders both variants',
      () {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        final result = FallbackPipelineComparisonResult(
          fixture: fixture,
          firstPassCorrectedText: fixture.expectedCorrectedText,
          naturalnessOnOriginalDescription: '(none)',
          hadConflict: false,
          current: FallbackVariantOutcome(
            fallbackTriggered: false,
            fallbackReviewDescription: null,
            finalCorrectedText: fixture.expectedCorrectedText,
            score: TwoPassScoreLabel.correctFix,
            reason: 'Matches expected output.',
          ),
          candidate: FallbackVariantOutcome(
            fallbackTriggered: false,
            fallbackReviewDescription: null,
            finalCorrectedText: fixture.expectedCorrectedText,
            score: TwoPassScoreLabel.correctFix,
            reason: 'Matches expected output.',
          ),
        );

        final report = buildFallbackPipelineComparisonReport(
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          results: [result],
          generatedAt: DateTime.utc(2026, 1, 1),
        );

        expect(report, contains('## ${fixture.languagePoint}'));
        expect(report, contains('### clean-grammar-only'));
        expect(report, contains('Current (reused prompt)'));
        expect(report, contains('Candidate (fallback-specific)'));
        expect(report, contains('| Current pass rate'));
      },
    );

    test(
      'runFallbackPipelineComparison never calls the fallback endpoint '
      'for either variant when the real conflict logic finds no conflict',
      () async {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'correct-buenos-dias',
        );
        final client = _RoutingHttpClient(
          firstPassReply: _firstPassEnvelope(fixture.text),
          originalText: fixture.text,
          firstPassCorrectedText: fixture.text,
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": false, "issues": []}',
          ),
        );

        final result = await runFallbackPipelineComparison(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          fixture: fixture,
        );

        expect(result.hadConflict, isFalse);
        expect(result.current.fallbackTriggered, isFalse);
        expect(result.candidate.fallbackTriggered, isFalse);
        expect(result.current.finalCorrectedText, fixture.text);
        expect(result.candidate.finalCorrectedText, fixture.text);
        expect(client.fallbackCallCount, 0);
      },
    );

    test(
      'runFallbackPipelineComparison calls the fallback endpoint once per '
      'variant, with each variant\'s own system prompt, when the real '
      'conflict logic triggers fallback',
      () async {
        const fixtureText = 'Vi mucho trafico ayer.';
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        expect(fixture.text, fixtureText);

        final client = _RoutingHttpClient(
          firstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          originalText: fixtureText,
          firstPassCorrectedText: 'Vi mucho tráfico ayer.',
          // Flags the whole sentence against the ORIGINAL text -- this
          // won't match the first pass's own corrected text exactly
          // (accent added), so the parallel merge conflicts and fallback
          // triggers, for both variants.
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "Vi mucho trafico ayer.", '
            '"natural_replacement": "Había mucho tráfico ayer.", '
            '"explanation": "Sounds more natural."}'
            ']}',
          ),
          fallbackReplyByVariant: {
            naturalnessReviewSpanish: _naturalnessEnvelope(
              '{"has_naturalness_issue": true, "issues": ['
              '{"span": "Vi mucho tráfico ayer.", '
              '"natural_replacement": "Había mucho tráfico ayer.", '
              '"explanation": "Sounds more natural."}'
              ']}',
            ),
            candidateFallbackPrompt: _naturalnessEnvelope(
              '{"has_naturalness_issue": false, "issues": []}',
            ),
          },
        );

        final result = await runFallbackPipelineComparison(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          fixture: fixture,
        );

        expect(result.hadConflict, isTrue);
        expect(result.current.fallbackTriggered, isTrue);
        expect(result.candidate.fallbackTriggered, isTrue);
        expect(client.fallbackCallCount, 2);
        // Current variant's fallback still over-rewrites.
        expect(result.current.finalCorrectedText, 'Había mucho tráfico ayer.');
        // Candidate variant's fallback correctly finds no remaining issue.
        expect(
          result.candidate.finalCorrectedText,
          'Vi mucho tráfico ayer.',
        );
      },
    );
  });

  test(
    'two-pass fallback prompt comparison: full pipeline',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!_liveRunOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live fallback pipeline comparison. Set '
          'FALLBACK_PIPELINE_COMPARISON_LIVE=true to opt in.',
        );
        return;
      }

      final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the fallback pipeline comparison '
          'harness. This script does NOT fall back to any hardcoded/'
          'default key.',
        );
      }

      final firstPassModel = _runtimeString(
        environment: environment,
        key: 'FALLBACK_PIPELINE_FIRST_PASS_MODEL',
        defaultValue: _defaultFirstPassModel,
      );
      final naturalnessModel = _runtimeString(
        environment: environment,
        key: 'FALLBACK_PIPELINE_NATURALNESS_MODEL',
        defaultValue: _defaultNaturalnessModel,
      );
      final outputPath = _runtimeString(
        environment: environment,
        key: 'FALLBACK_PIPELINE_OUTPUT',
        defaultValue: defaultFallbackPipelineOutputPath,
      );
      final callDelayMs = callDelayMsFrom(environment);
      final httpClient = HttpClient();
      final client = OpenAiChatCompletionsClient(
        apiKey: apiKey,
        httpClient: httpClient,
      );

      final results = <FallbackPipelineComparisonResult>[];
      for (final fixture in fallbackPipelineComparisonFixtures) {
        final result = await runFallbackPipelineComparison(
          client: client,
          firstPassModel: firstPassModel,
          naturalnessModel: naturalnessModel,
          fixture: fixture,
        );
        results.add(result);
        // ignore: avoid_print
        print(
          '=== ${fixture.id} === conflict=${result.hadConflict} '
          'current="${result.current.finalCorrectedText}" '
          '(${result.current.score.reportLabel}) '
          'candidate="${result.candidate.finalCorrectedText}" '
          '(${result.candidate.score.reportLabel})',
        );
        await Future<void>.delayed(Duration(milliseconds: callDelayMs));
      }

      final report = buildFallbackPipelineComparisonReport(
        firstPassModel: firstPassModel,
        naturalnessModel: naturalnessModel,
        results: results,
        generatedAt: DateTime.now(),
      );

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote fallback pipeline comparison report to $outputPath');
    },
  );
}

String _firstPassEnvelope(String correctedText) => jsonEncode({
  'choices': [
    {
      'message': {
        'role': 'assistant',
        'content': jsonEncode({'corrected_text': correctedText}),
      },
    },
  ],
});

String _naturalnessEnvelope(String replyContent) => jsonEncode({
  'choices': [
    {
      'message': {'role': 'assistant', 'content': replyContent},
    },
  ],
});

/// Fake HTTP client routing by request shape: the first-pass prompt
/// always gets [firstPassReply]; the naturalness prompt against the
/// ORIGINAL fixture text gets [naturalnessOnOriginalReply]; a fallback
/// call (naturalness prompt against the first pass's own corrected text)
/// is routed by which system prompt it used, via [fallbackReplyByVariant]
/// — this is what lets the fake distinguish the current-reused-prompt
/// fallback call from the candidate-fallback-specific-prompt call, since
/// production code has no other way to tell them apart at the transport
/// level.
/// Fake HTTP client routing by request shape. The first-pass prompt
/// always gets [firstPassReply]. For the naturalness prompt, this
/// distinguishes the parallel call from a fallback call by *user text*,
/// not system prompt — since the current-reused fallback variant uses
/// the exact same system prompt (`naturalnessReviewSpanish`) as the
/// parallel call, and only its user text (reviewing the first pass's own
/// corrected text, not the original) differs: the parallel call's user
/// text always matches [originalText]; anything else is a fallback call,
/// routed by which system prompt it used via [fallbackReplyByVariant].
/// All routing state lives on this client instance (constructed fresh
/// per test), not on any per-request object or static field, so nothing
/// leaks between tests or between the multiple requests one test makes.
class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient({
    required this.firstPassReply,
    required this.originalText,
    required this.firstPassCorrectedText,
    required this.naturalnessOnOriginalReply,
    this.fallbackReplyByVariant = const {},
  });

  final String firstPassReply;
  final String originalText;
  final String firstPassCorrectedText;
  final String naturalnessOnOriginalReply;
  final Map<String, String> fallbackReplyByVariant;
  int fallbackCallCount = 0;

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _RoutingRequest(client: this);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => null;
}

class _RoutingRequest implements HttpClientRequest {
  _RoutingRequest({required this.client});

  final _RoutingHttpClient client;
  final BytesBuilder _bytes = BytesBuilder();

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  void add(List<int> data) => _bytes.add(data);

  @override
  Future<HttpClientResponse> close() async {
    final body = utf8.decode(_bytes.toBytes());
    final sent = jsonDecode(body) as Map<String, Object?>;
    final messages = sent['messages'] as List;
    final systemPrompt = (messages[0] as Map)['content'] as String;
    final userText = (messages[1] as Map)['content'] as String;

    if (systemPrompt == firstPassCorrectionSpanish) {
      return _FakeHttpClientResponse(replyBody: client.firstPassReply);
    }

    final isParallelCall =
        userText == buildNaturalnessUserContent(client.originalText);
    if (isParallelCall) {
      return _FakeHttpClientResponse(
        replyBody: client.naturalnessOnOriginalReply,
      );
    }

    // Anything else reviewing the first pass's own corrected text is a
    // fallback call — routed by which system prompt it used.
    final fallbackReply = client.fallbackReplyByVariant[systemPrompt];
    if (fallbackReply != null) {
      client.fallbackCallCount++;
      return _FakeHttpClientResponse(replyBody: fallbackReply);
    }

    throw StateError(
      'No fake reply registered for system prompt "$systemPrompt" / user '
      'text "$userText".',
    );
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
