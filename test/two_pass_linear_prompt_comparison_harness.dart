// Serial/linear two-pass pipeline comparison harness (issue #125).
//
// Purpose: prototype and evaluate a LINEAR (serial) two-pass execution
// order — the first pass completes fully, then naturalness reviews the
// first pass's OWN corrected text directly, sequentially — against
// production's PARALLEL execution
// (`runTwoPassCorrectionPipeline`,
// lib/features/corrections/data/two_pass_correction_pipeline.dart),
// which starts the first pass and naturalness-on-original concurrently
// and only reruns naturalness sequentially (the "fallback") when the
// parallel merge finds a conflict.
//
// The linear pipeline never needs a fallback at all: naturalness always
// reviews the exact text it is about to be merged into, so the merge's
// span can only fail to match because of a genuine model discrepancy
// (the model misquoting its own input), never because the text changed
// out from under it mid-flight the way the parallel path's
// naturalness-on-original call can. This harness measures whether that
// architectural simplicity also produces better (or worse, or slower)
// final output quality than production's parallel+conditional-fallback
// design — a question about pipeline ARCHITECTURE (serial vs parallel
// execution order), not about fallback PROMPT text, which is what
// `test/two_pass_fallback_pipeline_comparison_harness.dart` (issues
// #117/#122/#124) already investigates. The two questions are
// orthogonal, so this is deliberately a separate, self-contained
// harness rather than a mode added to that one — matching this issue's
// own "keep it separate" requirement. Both harnesses happen to draw
// fixtures from the same canonical source (`allTwoPassFixtures`,
// `test/two_pass_integration_harness.dart`, issue #82) but choose their
// own curated subset independently; this file does not import from or
// modify `two_pass_fallback_pipeline_comparison_harness.dart`.
//
// Does NOT call production's `runTwoPassCorrectionPipeline` directly
// for the "parallel" side of the comparison — instead it reimplements
// that exact call sequence inline, using the same underlying
// `callFirstPassCorrection`/`callNaturalnessReview`/
// `mergeNaturalnessReview`/`mapNaturalnessEditsIntoCorrectionResponse`
// production already composes it from. No production code is called or
// modified; this file only touches `lib/` via ordinary imports of the
// same pure functions the production pipeline itself imports.
//
// Issue #126: the linear (serial) side's first pass now uses
// [linearFirstPassPrompt] — a REVISED first-pass prompt sourced from a
// design review, not production's `firstPassCorrectionSpanish` — while
// the parallel (production-equivalent) side continues using production's
// current, unmodified prompt. See [linearFirstPassPrompt]'s own doc
// comment for the exact source and why the two sides no longer share a
// first-pass call: once the linear side started using a different
// prompt, sharing one first-pass call would silently make both sides
// measure the same prompt, which defeats the point of a "revised
// prompt + serial architecture" vs. "current prompt + parallel
// architecture" comparison — exactly the comparison the design review
// that produced this prompt asked for. This also means the parallel
// path's conditional fallback can no longer reuse the linear path's
// naturalness call (they now review two different first-pass outputs),
// so a genuine fallback call happens again when the parallel merge has
// a conflict, same as production.
//
// Issue #127: the linear side's second pass now uses
// [linearSecondPassPrompt] — a REVISED, narrower LEXICAL TRANSFER review
// (calques, false friends, incorrect collocations, transferred idioms,
// and other objectively incorrect lexical constructions), not production's
// broader `naturalnessReviewSpanish` — while the parallel side's
// naturalness-on-original and fallback calls continue using production's
// unchanged prompt. See [linearSecondPassPrompt]'s own doc comment for
// the exact source. Same JSON contract as production's naturalness
// review (`{"has_naturalness_issue", "issues": [{"span",
// "natural_replacement", "explanation"}]}`), so it plugs directly into
// the same `mergeNaturalnessReview`/`mapNaturalnessEditsIntoCorrectionResponse`
// machinery with no changes there.
//
// Run offline (fixture/logic sanity only, no API calls):
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls — default 17-fixture
// curated set: 2 first-pass calls (one per architecture, since they use
// different prompts) + 2 second-pass calls always (linear's lexical
// review + parallel's naturalness-on-original), plus a conditional 3rd
// naturalness call only when the parallel merge genuinely conflicts —
// expect on the order of 70-90 total calls for the default set):
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LINEAR_COMPARISON_LIVE=true \
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --tags live --timeout none
//
// Run the standalone serial execution flow live (issue #128 — no
// parallel/fallback calls at all, so just 2 calls per run: 1 first pass
// + 1 lexical review):
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LINEAR_EXECUTION_LIVE=true \
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --tags live --timeout none
//
// Run the standalone execution flow's all-fixtures, 5x-repeated-run
// sweep (issue #131) — every fixture in allTwoPassFixtures (85 as of
// this writing), 5 runs each, so live model variance is visible rather
// than trusting a single-run result; up to 85 * 5 * 2 = 850 calls.
// buildLinearExecutionReport (issues #128-130) already carries every
// field this sweep needs per run — benchmark group, fixture id, run
// number, original/expected/first-pass/final phrases, score taxonomy,
// pass/fail, and per-pass latency/cost — laid out the same way
// two_pass_fallback_pipeline_comparison_harness.dart's own 5x sweep is,
// so the two stay directly comparable:
//   OPENAI_API_KEY=sk-... \
//   TWO_PASS_LINEAR_EXECUTION_LIVE=true \
//   TWO_PASS_LINEAR_FIXTURE_SET=all \
//   TWO_PASS_LINEAR_RUNS_PER_FIXTURE=5 \
//   TWO_PASS_LINEAR_EXECUTION_OUTPUT=docs/two_pass_linear_prompt_comparison_all_5x.md \
//   flutter test test/two_pass_linear_prompt_comparison_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - TWO_PASS_LINEAR_FIRST_PASS_MODEL: defaults to gpt-4.1 (issue #126's
//   own "use this prompt with gpt-4.1 unless the harness configuration
//   overrides it").
// - TWO_PASS_LINEAR_NATURALNESS_MODEL: defaults to gpt-5.1 (issue #127's
//   own "use this prompt with gpt-5.1 unless the harness configuration
//   overrides it" — used for both linear's lexical review and
//   parallel's naturalness calls).
// - TWO_PASS_LINEAR_OUTPUT: linear-vs-parallel comparison report path
//   (issues #125-127), defaults to docs/two_pass_linear_prompt_comparison.md.
// - TWO_PASS_LINEAR_EXECUTION_OUTPUT: standalone execution flow report
//   path (issues #128-131), defaults to docs/two_pass_linear_execution.md.
//   Set to docs/two_pass_linear_prompt_comparison_all_5x.md for the
//   named 5x sweep above.
// - TWO_PASS_LINEAR_CALL_DELAY_MS: delay between fixtures, defaults to
//   750.
// - TWO_PASS_LINEAR_FIXTURE_SET (issue #162 adds the last two values):
//   "comparison" (default — the curated 17-fixture set below), "all"
//   (every fixture in allTwoPassFixtures), "fixture_id" (exactly the
//   fixture named by TWO_PASS_LINEAR_FIXTURE_ID), or "language_point"
//   (every fixture whose languagePoint matches
//   TWO_PASS_LINEAR_LANGUAGE_POINT exactly).
// - TWO_PASS_LINEAR_FIXTURE_ID (issue #162): the fixture id to run when
//   TWO_PASS_LINEAR_FIXTURE_SET=fixture_id.
// - TWO_PASS_LINEAR_LANGUAGE_POINT (issue #162): the language-point
//   group to run when TWO_PASS_LINEAR_FIXTURE_SET=language_point, e.g.
//   "Unnecessary Extras / Deletions".
// - TWO_PASS_LINEAR_RUNS_PER_FIXTURE (issue #128): how many times to run
//   each selected fixture through the standalone execution flow with
//   the exact same submitted text. Defaults to 1; set to 5 for the named
//   5x sweep above.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';
import 'package:spanish_correction_app/features/corrections/data/first_pass_correction_client.dart';
import 'package:spanish_correction_app/features/corrections/data/naturalness_review_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
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
        scoreFixtureResult,
        statsFor;

/// The revised first-pass prompt (issue #126), used as the linear
/// (serial) pipeline's grammar/spelling/punctuation pass in this harness
/// only — it does not replace or modify production's
/// `firstPassCorrectionSpanish`
/// (`lib/core/services/prompts/correction_prompt.dart`), which the
/// parallel (production-equivalent) side of this harness continues to
/// use unchanged.
///
/// **Source**: `Two-Pass_Prompt_Revision_Summary.docx`, section "Revised
/// First Pass Prompt" — a design-review document external to this repo
/// (not version-controlled here). Transcribed verbatim, including line
/// breaks, by unzipping the `.docx` and reading `word/document.xml`
/// directly (`<w:t>` runs and `<w:br/>` breaks), since no diffable
/// plain-text export of the source document exists to diff against.
/// Confirmed the source uses plain straight quotes/apostrophes
/// throughout (not Word's smart-quote autocorrect), so nothing here was
/// normalized or altered from what the document contains. Not
/// paraphrased or reworded in any way — issue #126's own "do not
/// silently rewrite the correction rules" requirement.
///
/// The design review's own stated goal for this revision: replace
/// subjective concepts ("naturalness", "word choice") with an objective
/// standard — "recognised as correct by authoritative Spanish language
/// references" — as the boundary between what the first pass may correct
/// (objective grammar/spelling/punctuation errors) and what it must
/// leave alone (word choice, style, fluency, general naturalness, valid
/// regional Spanish — all covered by the prompt's own "do not rewrite
/// wording solely because another expression would be more common, more
/// idiomatic, more fluent, or stylistically preferable" and "do not
/// treat awkward but grammatically valid Spanish as an error" lines).
///
/// The same document also contains a "Revised Second Pass Prompt
/// (Draft)" — deliberately out of scope for issue #126, which asks only
/// for the first-pass prompt. The linear pipeline's naturalness
/// (second-pass) step still uses production's unchanged
/// `naturalnessReviewSpanish`.
const String linearFirstPassPrompt =
    'You are a Spanish language tutor reviewing a student\'s writing.\n'
    '\n'
    'Your task is to correct only objective Spanish grammar, spelling, '
    'and punctuation errors.\n'
    '\n'
    'Do not rewrite wording solely because another expression would be '
    'more common, more idiomatic, more fluent, or stylistically '
    'preferable.\n'
    'Do not add, remove, or replace words in a phrase that is '
    'recognised as correct by authoritative Spanish language '
    'references, even when the result would also be correct.\n'
    'Do not treat awkward but grammatically valid Spanish as an error.\n'
    '\n'
    'Correct every objective grammar, spelling, and punctuation error '
    'that you find.\n'
    '\n'
    'When a sentence contains more than one objective grammar error, '
    'correct every instance, not only the first one. For example:\n'
    '\n'
    '"Tengo cita con médico mañana."\n'
    '\n'
    'is missing both "una" before "cita" and "el" before "médico", so '
    'correct it to:\n'
    '\n'
    '"Tengo una cita con el médico mañana."\n'
    '\n'
    'Alongside the corrected text, list each change you made as a JSON '
    'object with the text as it was before the change, the text as it '
    'is after the change, and a short label of your own choosing for '
    'what kind of change it was. Where you removed words, give enough '
    'surrounding text on both sides that the change is clear. If you '
    'made no changes, return an empty list.\n'
    '\n'
    'Return JSON only. Do not include Markdown or commentary.';

/// The JSON shape [linearFirstPassPrompt] now requires (issue #156):
/// `{"corrected_text": "string", "corrections": [{"original_phrase",
/// "corrected_phrase", "category"}, ...]}`. **Not**
/// [firstPassCorrectionResponseFormat] (`correction_prompt.dart`) — that
/// schema is production's own, used directly by production's
/// `callFirstPassCorrection`, and its `additionalProperties: false`
/// means a model constrained to it literally cannot return a
/// `corrections` field at all. This is a harness-local schema, not a
/// modification of the production one. `category` is deliberately left
/// as an unconstrained string in the schema (no enum) — issue #156's own
/// "observe what vocabulary the model naturally produces... do not add
/// a category list to the prompt" — and `occurrence`/position data is
/// deliberately not requested at all (also issue #156, "explicitly out
/// of scope").
const Map<String, Object?> _linearFirstPassResponseFormat = {
  'type': 'json_schema',
  'json_schema': {
    'name': 'linear_first_pass_correction_response',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['corrected_text', 'corrections'],
      'properties': {
        'corrected_text': {'type': 'string'},
        'corrections': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['original_phrase', 'corrected_phrase', 'category'],
            'properties': {
              'original_phrase': {'type': 'string'},
              'corrected_phrase': {'type': 'string'},
              'category': {'type': 'string'},
            },
          },
        },
      },
    },
  },
};

/// One correction as [linearFirstPassPrompt]'s reply reports it, before
/// validation (issue #156) — [category] is the model's own raw,
/// unconstrained label, not yet mapped to [ErrorCategory].
class _LinearFirstPassRawCorrection {
  const _LinearFirstPassRawCorrection({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.category,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final String category;
}

/// A parsed (not yet validated) [_linearFirstPassResponseFormat] reply.
class _LinearFirstPassParsedReply {
  const _LinearFirstPassParsedReply({
    required this.correctedText,
    required this.corrections,
  });

  final String correctedText;
  final List<_LinearFirstPassRawCorrection> corrections;
}

/// Parses a [linearFirstPassPrompt] reply into [_LinearFirstPassParsedReply]
/// — same defensive brace-extraction approach as production's
/// `parseFirstPassCorrectionResponse` (tolerates Markdown fences or
/// trailing commentary around the JSON object), extended to also read
/// the `corrections` array this harness-local schema adds. Throws a
/// [FormatException] under the same conditions
/// `parseFirstPassCorrectionResponse` does — no object found, doesn't
/// decode to one, or `corrected_text` missing/not a string. A missing or
/// malformed `corrections` array is tolerated as empty rather than
/// thrown on, since `additionalProperties: false` plus `required`
/// already makes the API itself enforce the field's presence and shape
/// under `strict: true` — this fallback is defense in depth, not the
/// primary guarantee.
_LinearFirstPassParsedReply _parseLinearFirstPassResponse(
  String replyText,
) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException(
      'No JSON object found in linear first-pass correction reply.',
    );
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'Linear first-pass correction reply did not decode to an object.',
    );
  }

  final correctedText = decoded['corrected_text'];
  if (correctedText is! String) {
    throw const FormatException(
      'Linear first-pass correction reply is missing "corrected_text".',
    );
  }

  final rawCorrections = decoded['corrections'];
  final corrections = rawCorrections is List
      ? rawCorrections
            .whereType<Map<String, Object?>>()
            .map(
              (item) => _LinearFirstPassRawCorrection(
                originalPhrase: item['original_phrase'] as String? ?? '',
                correctedPhrase: item['corrected_phrase'] as String? ?? '',
                category: item['category'] as String? ?? '',
              ),
            )
            .toList()
      : const <_LinearFirstPassRawCorrection>[];

  return _LinearFirstPassParsedReply(
    correctedText: correctedText,
    corrections: corrections,
  );
}

/// Validates each raw correction against [submittedText]/[correctedText]
/// (issue #156's own "model-reported spans can't be trusted blindly" —
/// `mergeNaturalnessReview` already drops a non-matching span silently
/// elsewhere in this harness, and the same risk applies here) and builds
/// real [CorrectionItem]s for the ones that pass. A correction is kept
/// only if [_LinearFirstPassRawCorrection.originalPhrase] is a genuine,
/// non-empty substring of [submittedText] AND
/// [_LinearFirstPassRawCorrection.correctedPhrase] is a genuine,
/// non-empty substring of [correctedText] — the empty-string checks
/// matter because `''.contains('')` and `x.contains('')` are always
/// true in Dart, so an empty phrase would otherwise pass a bare
/// `.contains` check on any text. Anything that fails is dropped and
/// logged (printed), never silently discarded, per issue #156's own
/// explicit requirement.
///
/// [CorrectionItem.category] requires an [ErrorCategory] enum value,
/// but this harness's own [category] input is deliberately unconstrained
/// free text (issue #156) — there is no list to map against yet ("map
/// to the project's seven categories mechanically in the service layer
/// later" is explicitly out of scope here). `ErrorCategory.fromLabel`
/// (not the stricter `fromApiLabel`, which throws on an unrecognized
/// label) is used so an unmapped raw category never crashes the
/// harness, falling back to [ErrorCategory.other] — and the raw label
/// itself is preserved in [CorrectionItem.shortExplanation] rather than
/// silently lost to that fallback, so the actual vocabulary the model
/// produced stays observable on the item, not just the mapped bucket.
List<CorrectionItem> _validateLinearFirstPassCorrections({
  required String submittedText,
  required String correctedText,
  required List<_LinearFirstPassRawCorrection> raw,
}) {
  final validated = <CorrectionItem>[];
  for (final correction in raw) {
    final originalFound =
        correction.originalPhrase.isNotEmpty &&
        submittedText.contains(correction.originalPhrase);
    final correctedFound =
        correction.correctedPhrase.isNotEmpty &&
        correctedText.contains(correction.correctedPhrase);
    if (!originalFound || !correctedFound) {
      // ignore: avoid_print
      print(
        '[linear_first_pass_correction] dropped unverifiable correction: '
        'original_phrase="${correction.originalPhrase}" (found in '
        'submitted text: $originalFound), corrected_phrase='
        '"${correction.correctedPhrase}" (found in corrected text: '
        '$correctedFound), category="${correction.category}"',
      );
      continue;
    }
    validated.add(
      CorrectionItem(
        originalPhrase: correction.originalPhrase,
        correctedPhrase: correction.correctedPhrase,
        category: ErrorCategory.fromLabel(correction.category),
        shortExplanation: correction.category,
      ),
    );
  }
  return validated;
}

/// Calls [linearFirstPassPrompt] against [submittedText] and parses the
/// reply, mirroring `callFirstPassCorrection`'s exact call shape
/// (`first_pass_correction_client.dart`) — same `stageLabel`, same
/// [buildFirstPassCorrectionUserContent] user-content builder (unaffected
/// by issue #156 — it carries no schema, just the plain instruction/text
/// pair) — with only the system prompt text swapped for
/// [linearFirstPassPrompt], and (issue #156) the response format and
/// parser swapped for this harness's own
/// [_linearFirstPassResponseFormat]/[_parseLinearFirstPassResponse]/
/// [_validateLinearFirstPassCorrections], since production's
/// `firstPassCorrectionResponseFormat`/`parseFirstPassCorrectionResponse`
/// have no `corrections` field to give. Cannot call
/// `callFirstPassCorrection` directly, since that function hardcodes
/// production's `firstPassCorrectionSpanish` as its system prompt with
/// no override parameter.
Future<CorrectionResponse> _callLinearFirstPassCorrection({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String submittedText,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: linearFirstPassPrompt,
    userText: buildFirstPassCorrectionUserContent(submittedText),
    stageLabel: 'linear_first_pass_correction',
    responseFormat: _linearFirstPassResponseFormat,
  );
  final parsed = _parseLinearFirstPassResponse(replyText);
  final corrections = _validateLinearFirstPassCorrections(
    submittedText: submittedText,
    correctedText: parsed.correctedText,
    raw: parsed.corrections,
  );

  return CorrectionResponse(
    originalText: submittedText,
    correctedText: parsed.correctedText,
    corrections: corrections,
  );
}

/// The revised second-pass prompt (issue #127), used as the linear
/// (serial) pipeline's second-pass review in this harness only — it
/// does not replace or modify production's `naturalnessReviewSpanish`
/// (`lib/core/services/prompts/correction_prompt.dart`), which the
/// parallel (production-equivalent) side of this harness continues to
/// use unchanged for both its naturalness-on-original and (when
/// triggered) fallback calls.
///
/// **Source**: `Two-Pass_Prompt_Revision_Summary.docx`, section "Revised
/// Second Pass Prompt (Draft)" — the same external, non-version-
/// controlled design-review document [linearFirstPassPrompt] (issue
/// #126) was sourced from. Transcribed verbatim, including line breaks
/// and literal `•`/`-` bullet characters (plain text runs, not Word's
/// auto-numbered list feature — confirmed by inspecting the underlying
/// XML directly), the same way as [linearFirstPassPrompt]. Not
/// paraphrased or reworded.
///
/// Deliberately narrower than production's `naturalnessReviewSpanish`:
/// where that prompt's operational instruction is broad ("identify
/// wording... unlikely to use naturally"), this one names objective
/// LEXICAL TRANSFER categories explicitly — calques, false friends,
/// incorrect collocations from language transfer, transferred
/// idiomatic expressions, and other objectively incorrect lexical
/// constructions — the same "replace subjective concepts... with
/// objective decision criteria" goal the design review states for the
/// first-pass revision, applied to the second pass. Also states a
/// minimal-intervention policy explicitly (replace only the identified
/// issue, preserve meaning, no paraphrasing, smallest change necessary)
/// that production's current prompt does not spell out to this degree —
/// the design review's own stated reason: "the current second pass
/// frequently rewrites or paraphrases complete sentences instead of
/// repairing only the lexical issue."
const String linearSecondPassPrompt =
    'You are a Spanish language tutor reviewing text that has already '
    'been checked for grammar, spelling, and punctuation.\n'
    '\n'
    'Most text you review will contain no lexical issue at all. '
    'Returning no issue is the expected outcome. Only report a phrase '
    'when you are confident it is not recognised as correct by '
    'authoritative Spanish language references.\n'
    '\n'
    'Before reporting anything, apply this test:\n'
    '\n'
    'Is the phrase recognised as correct by authoritative Spanish '
    'language references?\n'
    '\n'
    'If yes, return no issue for that phrase — even if another '
    'phrasing is more common, more idiomatic, more regionally typical, '
    'or would read better. The existence of a preferable alternative '
    'is not grounds for reporting an issue.\n'
    '\n'
    'Only if the phrase fails that test, consider whether it is one of '
    'the following:\n'
    '\n'
    '- a lexical issue resulting from cross-linguistic interference, '
    'including:\n'
    '  - lexical calques (literal translations),\n'
    '  - false friends (semantic transfer),\n'
    '  - incorrect collocations resulting from language transfer,\n'
    '  - transferred idiomatic expressions.\n'
    '\n'
    '- another objectively incorrect lexical construction.\n'
    '\n'
    'Do not report spelling, punctuation, or grammatical errors. If '
    'the only problem is grammar, spelling, or punctuation, return no '
    'issue. Ignore them even when they appear in the same sentence as '
    'a lexical issue.\n'
    '\n'
    'When you have identified a genuine lexical issue:\n'
    '\n'
    '- Replace only that lexical issue.\n'
    '- Limit your changes to it, plus any unavoidable grammatical '
    'adjustments required by the replacement.\n'
    '- Preserve the original meaning. Do not substitute a verb or '
    'noun whose meaning differs from the original, even slightly.\n'
    '- Do not add new information, new clauses, or new ideas.\n'
    '- Do not remove information unless it forms part of the lexical '
    'issue being corrected.\n'
    '- Do not paraphrase or otherwise rewrite the sentence.\n'
    '- Make only the smallest change necessary to eliminate the '
    'lexical issue.\n'
    '\n'
    'Give exactly one replacement for each issue.\n'
    'Never provide more than one replacement.\n'
    'Never join alternatives with a slash, "or", or a list.\n'
    'If more than one replacement is possible, choose the one that '
    'requires the smallest change while fully resolving the lexical '
    'issue.\n'
    '\n'
    'Return JSON only.';

/// Calls [linearSecondPassPrompt] against [text] and parses the reply,
/// mirroring `callNaturalnessReview`'s exact call shape
/// (`naturalness_review_client.dart`) — same `stageLabel` convention,
/// same [naturalnessReviewResponseFormat] JSON schema (reused unchanged:
/// issue #127's own "target objective lexical transfer issues" is a
/// scope instruction, not a contract change — the schema is still
/// exactly `{"has_naturalness_issue": bool, "issues": [{"span",
/// "natural_replacement", "explanation"}]}`), and the same
/// [buildNaturalnessUserContent]/[parseNaturalnessReviewResponse]
/// helpers — with only the system prompt text swapped for
/// [linearSecondPassPrompt]. Cannot call `callNaturalnessReview`
/// directly, since that function hardcodes production's
/// `naturalnessReviewSpanish` as its system prompt with no override
/// parameter. Returns [NaturalnessReview] unchanged — the existing
/// domain type already matches this prompt's own contract, so no new
/// type is needed.
Future<NaturalnessReview> _callLinearLexicalReview({
  required OpenAiChatCompletionsClient client,
  required String model,
  required String text,
}) async {
  final replyText = await client.complete(
    model: model,
    systemPrompt: linearSecondPassPrompt,
    userText: buildNaturalnessUserContent(text),
    stageLabel: 'linear_lexical_review',
    responseFormat: naturalnessReviewResponseFormat,
  );
  return parseNaturalnessReviewResponse(replyText);
}

/// Curated subset of `allTwoPassFixtures` (issue #82) this harness
/// exercises by default — a representative sample across language
/// points. Chosen independently of (and incidentally overlapping with,
/// since both draw ids from the same canonical fixture list) the
/// fallback comparison harness's own curated set (issue #117) — this
/// harness does not import that set.
const List<String> linearComparisonFixtureIds = [
  'clean-grammar-only',
  'correct-buenos-dias',
  'regional-voy-para-casa',
  'naturalness-buen-tiempo',
  'naturalness-corriendo-tarde',
  'mixed-personal-a-and-subjunctive',
  'mixed-verb-agreement-and-missing-que',
  'false-friend-atendio-universidad',
  'false-friend-aplico-trabajo',
  'subj-enviara',
  'ambiguous-naturalness-span',
  'article-la-tienda',
  'grammar-overlaps-naturalness',
  'collocation-hacer-paseo',
  'collocation-hace-sentido',
  'prep-empresa-en-la-que',
  'delete-repeated-yo-estudio',
];

List<TwoPassFixture> get linearComparisonFixtures => linearComparisonFixtureIds
    .map(
      (id) => allTwoPassFixtures.firstWhere(
        (f) => f.id == id,
        orElse: () =>
            throw StateError('No fixture with id "$id" in allTwoPassFixtures.'),
      ),
    )
    .toList();

/// Default `TWO_PASS_LINEAR_FIXTURE_SET` value — the curated 17-fixture
/// set above, unchanged from before this option existed.
const String defaultLinearFixtureSet = 'comparison';

/// Which fixtures `fixtureSet` selects (issue #162 extends the original
/// `"comparison"`/`"all"` pair): `"comparison"` (the curated set above),
/// `"all"` (every fixture in [allTwoPassFixtures]), `"fixture_id"`
/// (exactly the one fixture whose id equals [fixtureId]), or
/// `"language_point"` (every fixture whose
/// [TwoPassFixture.languagePoint] equals [languagePoint] exactly).
///
/// Mirrors `two_pass_integration_harness.dart`'s own `selectFixtures`
/// structure and error messages exactly (same fail-fast-on-missing-
/// parameter, fail-fast-on-empty-match-set precedent — issue #162's own
/// "a silently-empty live run producing a valid-looking report with
/// zero fixtures is a worse failure mode than an immediate error") —
/// this is a deliberate mirror, not a shared import, per this file's own
/// "keep it separate" convention already applied to
/// [_trackedLinearCall]/[_describeReview]/[_formatCost].
///
/// Throws [ArgumentError] for an unrecognized [fixtureSet], a
/// `fixture_id`/`language_point` selection that matches nothing, or a
/// missing/empty required parameter for the chosen [fixtureSet].
List<TwoPassFixture> linearFixturesFor(
  String fixtureSet, {
  String? fixtureId,
  String? languagePoint,
}) {
  switch (fixtureSet) {
    case 'comparison':
      return linearComparisonFixtures;
    case 'all':
      return allTwoPassFixtures;
    case 'fixture_id':
      if (fixtureId == null || fixtureId.isEmpty) {
        throw ArgumentError(
          'TWO_PASS_LINEAR_FIXTURE_SET "fixture_id" requires a non-empty '
          'TWO_PASS_LINEAR_FIXTURE_ID.',
        );
      }
      final matches = allTwoPassFixtures.where((f) => f.id == fixtureId);
      if (matches.isEmpty) {
        throw ArgumentError('No fixture with id "$fixtureId".');
      }
      return [matches.single];
    case 'language_point':
      if (languagePoint == null || languagePoint.isEmpty) {
        throw ArgumentError(
          'TWO_PASS_LINEAR_FIXTURE_SET "language_point" requires a '
          'non-empty TWO_PASS_LINEAR_LANGUAGE_POINT.',
        );
      }
      final matches = allTwoPassFixtures
          .where((f) => f.languagePoint == languagePoint)
          .toList();
      if (matches.isEmpty) {
        throw ArgumentError(
          'No fixtures with languagePoint "$languagePoint".',
        );
      }
      return matches;
    default:
      throw ArgumentError(
        'Unknown TWO_PASS_LINEAR_FIXTURE_SET "$fixtureSet" — expected '
        'one of: comparison, all, fixture_id, language_point.',
      );
  }
}

/// Reads `TWO_PASS_LINEAR_FIXTURE_SET` (plus, for the two selectors
/// issue #162 adds, its companion `TWO_PASS_LINEAR_FIXTURE_ID`/
/// `TWO_PASS_LINEAR_LANGUAGE_POINT`) from a real environment, same
/// real-environment-variable convention as [linearCallDelayMsFrom].
List<TwoPassFixture> linearFixturesFrom(Map<String, String> environment) {
  return linearFixturesFor(
    _runtimeString(
      environment: environment,
      key: 'TWO_PASS_LINEAR_FIXTURE_SET',
      defaultValue: defaultLinearFixtureSet,
    ),
    fixtureId: environment['TWO_PASS_LINEAR_FIXTURE_ID']?.trim(),
    languagePoint: environment['TWO_PASS_LINEAR_LANGUAGE_POINT']?.trim(),
  );
}

const String _defaultFirstPassModel = 'gpt-4.1';
const String _defaultNaturalnessModel = 'gpt-5.1';
const String defaultLinearOutputPath =
    'docs/two_pass_linear_prompt_comparison.md';

/// Default report path for the standalone serial execution flow (issue
/// #128) — distinct from [defaultLinearOutputPath], which is the
/// linear-vs-parallel *comparison* report's own path.
const String defaultLinearExecutionOutputPath =
    'docs/two_pass_linear_execution.md';

const bool _liveRunOptInFromDefine = bool.fromEnvironment(
  'TWO_PASS_LINEAR_COMPARISON_LIVE',
  defaultValue: false,
);

bool _liveRunOptIn(Map<String, String> environment) {
  return _liveRunOptInFromDefine ||
      (environment['TWO_PASS_LINEAR_COMPARISON_LIVE']?.trim().toLowerCase() ==
          'true');
}

/// Opt-in flag for the standalone serial execution flow's own live test
/// (issue #128) — distinct from [_liveRunOptIn], which gates the
/// linear-vs-parallel *comparison* live test. Kept separate so running
/// one never accidentally triggers the other's real API calls.
const bool _executionLiveRunOptInFromDefine = bool.fromEnvironment(
  'TWO_PASS_LINEAR_EXECUTION_LIVE',
  defaultValue: false,
);

bool _executionLiveRunOptIn(Map<String, String> environment) {
  return _executionLiveRunOptInFromDefine ||
      (environment['TWO_PASS_LINEAR_EXECUTION_LIVE']?.trim().toLowerCase() ==
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

int linearCallDelayMsFrom(Map<String, String> environment) {
  final raw = _runtimeString(
    environment: environment,
    key: 'TWO_PASS_LINEAR_CALL_DELAY_MS',
    defaultValue: '750',
  );
  return int.tryParse(raw) ?? 750;
}

/// Default number of times to run each selected fixture through the
/// standalone serial execution flow (issue #128) — unchanged single-run
/// behavior from before this option existed.
const int defaultLinearRunsPerFixture = 1;

/// Reads `TWO_PASS_LINEAR_RUNS_PER_FIXTURE` from a real environment
/// (issue #128) — how many times to run each selected fixture through
/// [runLinearExecution] with the exact same submitted text, so a
/// repeated live result can be told apart from a one-off stochastic one.
/// Same convention as `two_pass_fallback_pipeline_comparison_harness.dart`'s
/// `FALLBACK_PIPELINE_RUNS_PER_FIXTURE` (issue #122) and
/// `two_pass_integration_harness.dart`'s `TWO_PASS_RUNS_PER_FIXTURE`
/// (issue #107), including throwing [ArgumentError] for a zero or
/// negative value rather than silently running every selected fixture
/// zero times.
int linearRunsPerFixtureFrom(Map<String, String> environment) {
  final raw = environment['TWO_PASS_LINEAR_RUNS_PER_FIXTURE']?.trim() ?? '';
  final runsPerFixture = int.tryParse(raw) ?? defaultLinearRunsPerFixture;
  if (runsPerFixture < 1) {
    throw ArgumentError(
      'TWO_PASS_LINEAR_RUNS_PER_FIXTURE must be >= 1 (was $runsPerFixture) '
      '— 0 or negative would silently run every selected fixture zero '
      'times.',
    );
  }
  return runsPerFixture;
}

/// Runs [call], recording its [CallStats] (wall-clock latency plus every
/// [ChatCompletionsUsage] logged to [usageLog] during the call) via
/// [onStats] — always, whether [call] completes normally or throws.
/// Local copy of `two_pass_integration_harness.dart`'s own private
/// `_trackedCall` (issue #98) — kept separate per this harness's own
/// "keep it separate" convention rather than a shared import. Unlike
/// that function, [usageLog] here is always a phase-local list built
/// fresh per call (see [_runLinearSteps]), not a shared log sliced by
/// start index — safe because this harness's Pass 1 and Pass 2 calls are
/// never concurrent with each other, unlike the parallel pipeline's own
/// first-pass/naturalness-on-original phase.
Future<T> _trackedLinearCall<T>(
  List<ChatCompletionsUsage> usageLog,
  Future<T> Function() call, {
  required void Function(CallStats stats) onStats,
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    return await call();
  } finally {
    stopwatch.stop();
    onStats(statsFor(usageLog, wallClockMs: stopwatch.elapsedMilliseconds));
  }
}

/// The intermediate values one serial Pass 1 -> Pass 2 execution
/// produces, shared by [runLinearTwoPassPipeline] and
/// [runLinearExecution] (issue #128) so the two never drift apart on
/// what "the serial flow" actually does. [firstPassStats]/[secondPassStats]
/// (issue #130) are real latency/token/cost, one [CallStats] per pass,
/// captured the same way `two_pass_integration_harness.dart`'s own
/// `runFixture` captures its phases' stats — no fallback stats field
/// exists here at all, since this harness has no fallback call to
/// measure (issue #130's own "do not include fallback latency or cost"
/// scope, satisfied by construction rather than by an unused/zeroed
/// field).
class _LinearSteps {
  const _LinearSteps({
    required this.response,
    required this.firstPassCorrectedText,
    required this.firstPassCorrections,
    required this.lexicalReview,
    required this.firstPassStats,
    required this.secondPassStats,
  });

  final CorrectionResponse response;
  final String firstPassCorrectedText;

  /// Pass 1's own reported corrections (issue #156's schema change),
  /// already validated (issue #156's substring checks) — what Pass 2
  /// receives no visibility into today, but this harness now can
  /// observe. Kept raw here, same precedent as [lexicalReview]; only a
  /// formatted description of it reaches [LinearExecutionResult]
  /// (issue #160).
  final List<CorrectionItem> firstPassCorrections;
  final NaturalnessReview lexicalReview;
  final CallStats firstPassStats;
  final CallStats secondPassStats;
}

/// Runs the two-pass pipeline SERIALLY (issue #125, execution flow
/// finalized by issue #128): Pass 1 (using [linearFirstPassPrompt],
/// issue #126 — not production's `firstPassCorrectionSpanish`) completes
/// fully; its corrected text — never the original submitted text — is
/// sent to Pass 2, a lexical transfer review (using
/// [linearSecondPassPrompt], issue #127 — not production's broader
/// `naturalnessReviewSpanish`); Pass 2's output becomes the final
/// corrected text. Issue #128's own scope, satisfied by construction
/// rather than by a branch that could be gotten wrong: this function
/// never calls `callFirstPassCorrection` or `callNaturalnessReview` (the
/// production-prompt clients the *parallel* side of this harness uses),
/// never runs a naturalness-on-original call, and has no fallback/retry
/// branch of any kind — there is nothing here that could "invoke a
/// parallel merge or fallback path", because no code path to one exists
/// in this function at all. The one deterministic step,
/// `mergeNaturalnessReview`, is not that excluded conflict-resolution
/// path — it is the same span-splicing step that applies ANY single
/// naturalness/lexical review's edits onto a base text (used
/// identically by production's own pipeline for its own single
/// naturalness call), not a mechanism for choosing between competing
/// pass results the way the parallel path's fallback decision is.
///
/// Builds one [OpenAiChatCompletionsClient] per pass (issue #130), each
/// wrapping the same underlying [httpClient] transport but with its own
/// isolated usage log — the same "one wrapper per phase, one shared
/// transport" shape `two_pass_integration_harness.dart`'s own
/// `runFixture` uses for its concurrent phase, needed here too so a
/// call's [CallStats] never mixes in the other pass's tokens.
Future<_LinearSteps> _runLinearSteps({
  required String apiKey,
  required HttpClient httpClient,
  required String firstPassModel,
  required String naturalnessModel,
  required String submittedText,
}) async {
  var firstPassStats = CallStats.zero;
  final firstPassUsage = <ChatCompletionsUsage>[];
  final firstPassClient = OpenAiChatCompletionsClient(
    apiKey: apiKey,
    httpClient: httpClient,
    onUsage: firstPassUsage.add,
  );
  final firstPassResponse = await _trackedLinearCall(
    firstPassUsage,
    () => _callLinearFirstPassCorrection(
      client: firstPassClient,
      model: firstPassModel,
      submittedText: submittedText,
    ),
    onStats: (stats) => firstPassStats = stats,
  );

  var secondPassStats = CallStats.zero;
  final secondPassUsage = <ChatCompletionsUsage>[];
  final secondPassClient = OpenAiChatCompletionsClient(
    apiKey: apiKey,
    httpClient: httpClient,
    onUsage: secondPassUsage.add,
  );
  final lexicalReview = await _trackedLinearCall(
    secondPassUsage,
    () => _callLinearLexicalReview(
      client: secondPassClient,
      model: naturalnessModel,
      text: firstPassResponse.correctedText,
    ),
    onStats: (stats) => secondPassStats = stats,
  );

  final merge = mergeNaturalnessReview(
    originalText: submittedText,
    firstPassCorrectedText: firstPassResponse.correctedText,
    naturalnessReview: lexicalReview,
  );

  final response = mapNaturalnessEditsIntoCorrectionResponse(
    firstPassResponse: firstPassResponse,
    naturalnessMerge: merge,
  );

  return _LinearSteps(
    response: response,
    firstPassCorrectedText: firstPassResponse.correctedText,
    firstPassCorrections: firstPassResponse.corrections,
    lexicalReview: lexicalReview,
    firstPassStats: firstPassStats,
    secondPassStats: secondPassStats,
  );
}

/// A pure prototype of the serial two-pass flow — not called by or
/// wired into production code anywhere. Driven across the fixture set
/// by [runLinearExecution] (issue #128) for standalone (non-comparison)
/// live runs, and by [runLinearPipelineComparison] (issues #125-127)
/// when compared side-by-side against the parallel/production-equivalent
/// path. See [_runLinearSteps] for what "serially" means here.
Future<CorrectionResponse> runLinearTwoPassPipeline({
  required String apiKey,
  required HttpClient httpClient,
  required String firstPassModel,
  required String naturalnessModel,
  required String submittedText,
}) async {
  final steps = await _runLinearSteps(
    apiKey: apiKey,
    httpClient: httpClient,
    firstPassModel: firstPassModel,
    naturalnessModel: naturalnessModel,
    submittedText: submittedText,
  );
  return steps.response;
}

/// One fixture's one run through the standalone serial execution flow
/// (issue #128) — deliberately lean, with no parallel/fallback fields
/// at all, unlike [LinearPipelineComparisonResult] (issues #125-127),
/// which exists specifically to compare the linear path against the
/// parallel one.
class LinearExecutionResult {
  const LinearExecutionResult({
    required this.fixture,
    required this.runIndex,
    required this.firstPassCorrectedText,
    required this.firstPassCorrectionsDescription,
    required this.lexicalReviewDescription,
    required this.finalCorrectedText,
    required this.score,
    required this.reason,
    required this.firstPassStats,
    required this.secondPassStats,
  });

  final TwoPassFixture fixture;

  /// 1-based index of this run among a fixture's repeated runs (issue
  /// #128) — same convention as
  /// `two_pass_fallback_pipeline_comparison_harness.dart`'s
  /// `FallbackPipelineComparisonResult.runIndex` (issue #122). Defaults
  /// to 1 for a single run.
  final int runIndex;

  /// Pass 1's own corrected text — what Pass 2 received (issue #128's
  /// own "Pass 2 receives Pass 1 output, not original text" acceptance
  /// criterion).
  final String firstPassCorrectedText;

  /// What Pass 1 reported changing (issue #156's schema change,
  /// surfaced here per issue #160) — same "formatted description only,
  /// raw data stays on `_LinearSteps`" precedent
  /// [lexicalReviewDescription] already established. `(none)` when
  /// Pass 1 reported no corrections; `original_phrase -> corrected_phrase
  /// (category)` per entry otherwise, joined with `<br>` for multiple —
  /// see [_describeCorrections].
  final String firstPassCorrectionsDescription;
  final String lexicalReviewDescription;

  /// Pass 2's output, treated as the final corrected text directly
  /// (issue #128's own "treat Pass 2 output as the final corrected
  /// text" scope) — identical to [runLinearTwoPassPipeline]'s own
  /// return value for this fixture/run, with no further processing.
  final String finalCorrectedText;
  final TwoPassScoreLabel score;
  final String reason;

  /// Real latency/tokens/cost for Pass 1 only (issue #130).
  final CallStats firstPassStats;

  /// Real latency/tokens/cost for Pass 2 (the lexical review) only
  /// (issue #130).
  final CallStats secondPassStats;

  /// Pass 1 + Pass 2 only (issue #130's own "latency/cost totals equal
  /// Pass 1 + Pass 2 only" acceptance criterion) — there is no fallback
  /// stats field to add in, unlike
  /// `two_pass_integration_harness.dart`'s `FixtureResult.totalStats`,
  /// which also sums a (possibly zero) fallback phase.
  CallStats get totalStats => firstPassStats + secondPassStats;
}

/// Runs [fixture] once (or once per call — see [runIndex]) through the
/// standalone serial execution flow (issue #128): the exact same steps
/// [runLinearTwoPassPipeline] runs (via the shared [_runLinearSteps]),
/// wrapped with scoring. No parallel call, no fallback call, no
/// comparison — for that, see [runLinearPipelineComparison].
Future<LinearExecutionResult> runLinearExecution({
  required String apiKey,
  required HttpClient httpClient,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
  int runIndex = 1,
}) async {
  final steps = await _runLinearSteps(
    apiKey: apiKey,
    httpClient: httpClient,
    firstPassModel: firstPassModel,
    naturalnessModel: naturalnessModel,
    submittedText: fixture.text,
  );

  return LinearExecutionResult(
    fixture: fixture,
    runIndex: runIndex,
    firstPassCorrectedText: steps.firstPassCorrectedText,
    firstPassCorrectionsDescription: _describeCorrections(
      steps.firstPassCorrections,
    ),
    lexicalReviewDescription: _describeReview(steps.lexicalReview),
    firstPassStats: steps.firstPassStats,
    secondPassStats: steps.secondPassStats,
    finalCorrectedText: steps.response.correctedText,
    score: _score(fixture, steps.response.correctedText),
    reason: _reasonFor(fixture, steps.response.correctedText),
  );
}

/// One fixture's side-by-side result: the linear (serial) pipeline
/// (using [linearFirstPassPrompt], issue #126) vs. the parallel
/// (production-equivalent) pipeline (using production's unmodified
/// `firstPassCorrectionSpanish`). The two architectures use different
/// first-pass prompts, so — unlike issue #125's original design — they
/// no longer share a first-pass call; see [linearFirstPassCorrectedText]
/// and [parallelFirstPassCorrectedText].
class LinearPipelineComparisonResult {
  const LinearPipelineComparisonResult({
    required this.fixture,
    required this.linearFirstPassCorrectedText,
    required this.linearLexicalReviewDescription,
    required this.linearCorrectedText,
    required this.linearScore,
    required this.linearReason,
    required this.parallelFirstPassCorrectedText,
    required this.parallelNaturalnessOnOriginalDescription,
    required this.parallelUsedFallback,
    required this.parallelCorrectedText,
    required this.parallelScore,
    required this.parallelReason,
  });

  final TwoPassFixture fixture;

  /// First-pass output from [linearFirstPassPrompt] (issue #126) — NOT
  /// the same call or necessarily the same text as
  /// [parallelFirstPassCorrectedText], since the two architectures now
  /// use different first-pass prompts and can no longer share one
  /// first-pass call (see this file's own header comment).
  final String linearFirstPassCorrectedText;

  /// What [linearSecondPassPrompt] (issue #127) flagged, if anything —
  /// a lexical transfer review, not general naturalness, despite the
  /// field name matching [parallelNaturalnessOnOriginalDescription]'s
  /// shape for symmetry in the generated report.
  final String linearLexicalReviewDescription;
  final String linearCorrectedText;
  final TwoPassScoreLabel linearScore;
  final String linearReason;

  /// First-pass output from production's unchanged
  /// `firstPassCorrectionSpanish`.
  final String parallelFirstPassCorrectedText;
  final String parallelNaturalnessOnOriginalDescription;

  /// Whether the parallel path's merge on naturalness-on-original had a
  /// skipped edit, i.e. whether production's real pipeline would trigger
  /// its sequential fallback here. Since issue #126, this fallback's own
  /// naturalness call IS genuinely re-issued when triggered — it can no
  /// longer reuse the linear path's naturalness call, which reviews a
  /// different (revised-prompt) first-pass output.
  final bool parallelUsedFallback;
  final String parallelCorrectedText;
  final TwoPassScoreLabel parallelScore;
  final String parallelReason;
}

String _describeReview(NaturalnessReview review) {
  if (!review.hasNaturalnessIssue) {
    return '(none)';
  }
  return review.issues
      .map((issue) => '${issue.span} -> ${issue.naturalReplacement}')
      .join('<br>');
}

/// Formats Pass 1's own reported corrections (issue #156's schema
/// change) for the report (issue #160) — same `(none)`-when-empty,
/// `<br>`-joined-when-multiple convention [_describeReview] already
/// established for Pass 2's signal. `category` here is the raw label
/// Pass 1 reported, preserved in [CorrectionItem.shortExplanation]
/// (issue #156's own "observe what vocabulary the model naturally
/// produces" — [CorrectionItem.category] itself is the [ErrorCategory]
/// enum a raw, unconstrained label like this maps onto, usually
/// [ErrorCategory.other], which isn't the informative value to show
/// here). Omitted from an entry when Pass 1 reported an empty category.
String _describeCorrections(List<CorrectionItem> corrections) {
  if (corrections.isEmpty) {
    return '(none)';
  }
  return corrections
      .map((correction) {
        final category = correction.shortExplanation;
        final edit =
            '${correction.originalPhrase} -> ${correction.correctedPhrase}';
        return category.isEmpty ? edit : '$edit ($category)';
      })
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

String _reasonFor(TwoPassFixture fixture, String finalCorrectedText) {
  final score = _score(fixture, finalCorrectedText);
  if (isPassingScore(score)) {
    return finalCorrectedText == fixture.text
        ? 'Matches expected output; already-correct text was left '
              'unchanged.'
        : 'Matches expected output.';
  }
  return finalCorrectedText == fixture.text
      ? 'Left the text unchanged, but that did not match the expected '
            'output.'
      : 'Changed the text to something that does not match the expected '
            'output.';
}

/// Local copy of `two_pass_integration_harness.dart`'s own private
/// `_formatCost` — same "unknown" fallback for a `null` estimate (a
/// model with no verified pricing entry), kept separate per this
/// harness's own "keep it separate" convention.
String _formatCost(double? usd) =>
    usd == null ? 'unknown' : '\$${usd.toStringAsFixed(6)}';

/// Local copy of `two_pass_fallback_pipeline_comparison_harness.dart`'s
/// own private `_formatOutputList` (issue #131) — same
/// backtick-wrapped, semicolon-joined shape, so the two harnesses'
/// summary tables read the same way side by side.
String _formatOutputList(List<String> outputs) {
  return outputs.map((text) => '`$text`').join('; ');
}

/// Renders a one-row-per-[rowLabel] markdown table counting [labels] by
/// every [TwoPassScoreLabel] value (issue #129) — the full benchmark
/// taxonomy (`correct_fix`, `partial_fix`, `missed_issue`,
/// `overcorrection`, `acceptable_no_change`, `ambiguous`, `error`), not
/// only pass/fail, so a linear-harness report stays comparable against
/// `two_pass_integration_harness.dart`'s own `_groupedScoreTable`-style
/// breakdowns rather than collapsing detail an existing benchmark report
/// would show. Every column is always present, even at zero, so column
/// sets never differ between reports/calls.
String _scoreLabelBreakdownTable({
  required Map<String, Iterable<TwoPassScoreLabel>> rows,
}) {
  final columns = TwoPassScoreLabel.values.map((l) => l.reportLabel).toList();
  final separatorCells = List.filled(2 + columns.length, '---').join(' | ');
  final buffer = StringBuffer()
    ..writeln('| | Total | ${columns.join(' | ')} |')
    ..writeln('| $separatorCells |');
  for (final entry in rows.entries) {
    final counts = {for (final label in TwoPassScoreLabel.values) label: 0};
    for (final label in entry.value) {
      counts[label] = counts[label]! + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final cells = TwoPassScoreLabel.values
        .map((label) => counts[label].toString())
        .join(' | ');
    buffer.writeln('| ${entry.key} | $total | $cells |');
  }
  return buffer.toString();
}

/// Runs both pipeline architectures against [fixture] and scores each.
///
/// Since issue #126, the linear side's first pass uses
/// [linearFirstPassPrompt] and the parallel side's uses production's
/// unchanged `firstPassCorrectionSpanish` — two different prompts, so
/// (unlike this function's original #125 design) they can no longer
/// share a single first-pass call, and the parallel path's conditional
/// fallback can no longer reuse the linear path's naturalness call
/// either, since that call now reviews a different first-pass output.
/// Both first-pass calls and, when triggered, the fallback call, are
/// now genuinely independent — the same shape production's own pipeline
/// has, just with the linear side's first pass swapped for the revised
/// prompt. Since issue #127, the linear side's second-pass call also
/// uses a different (narrower, lexical-transfer-only) prompt than the
/// parallel side's naturalness calls — the two second-pass prompts were
/// already never shared (linear reviews the first-pass output, parallel
/// reviews the original text), so this changes what the linear side's
/// call finds, not the calls' independence.
Future<LinearPipelineComparisonResult> runLinearPipelineComparison({
  required OpenAiChatCompletionsClient client,
  required String firstPassModel,
  required String naturalnessModel,
  required TwoPassFixture fixture,
}) async {
  // Linear: revised first-pass prompt (issue #126), then a lexical
  // transfer review (issue #127) reviews the first pass's own corrected
  // text, sequentially, no fallback possible.
  final linearFirstPassResponse = await _callLinearFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: fixture.text,
  );
  final linearLexicalReview = await _callLinearLexicalReview(
    client: client,
    model: naturalnessModel,
    text: linearFirstPassResponse.correctedText,
  );
  final linearMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: linearFirstPassResponse.correctedText,
    naturalnessReview: linearLexicalReview,
  );
  final linearResponse = mapNaturalnessEditsIntoCorrectionResponse(
    firstPassResponse: linearFirstPassResponse,
    naturalnessMerge: linearMerge,
  );

  // Parallel: production's current, unmodified first-pass prompt, then
  // naturalness reviews the ORIGINAL text — production's own "started
  // concurrently with the first pass" call. Reproducing the exact
  // wall-clock concurrency isn't necessary for comparing final output
  // quality, only awaiting it after the first pass instead of alongside
  // it.
  final parallelFirstPassResponse = await callFirstPassCorrection(
    client: client,
    model: firstPassModel,
    submittedText: fixture.text,
  );
  final parallelNaturalnessOnOriginal = await callNaturalnessReview(
    client: client,
    model: naturalnessModel,
    text: fixture.text,
  );
  final parallelMerge = mergeNaturalnessReview(
    originalText: fixture.text,
    firstPassCorrectedText: parallelFirstPassResponse.correctedText,
    naturalnessReview: parallelNaturalnessOnOriginal,
  );

  final parallelUsedFallback = parallelMerge.skippedEdits.isNotEmpty;
  final CorrectionResponse parallelResponse;
  if (!parallelUsedFallback) {
    parallelResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: parallelFirstPassResponse,
      naturalnessMerge: parallelMerge,
    );
  } else {
    // Genuine fallback call (issue #126) — can no longer reuse the
    // linear path's naturalness call, since that reviewed a different
    // (revised-prompt) first-pass output than this (production-prompt)
    // one.
    final fallbackNaturalnessReview = await callNaturalnessReview(
      client: client,
      model: naturalnessModel,
      text: parallelFirstPassResponse.correctedText,
    );
    final fallbackMerge = mergeNaturalnessReview(
      originalText: fixture.text,
      firstPassCorrectedText: parallelFirstPassResponse.correctedText,
      naturalnessReview: fallbackNaturalnessReview,
    );
    parallelResponse = mapNaturalnessEditsIntoCorrectionResponse(
      firstPassResponse: parallelFirstPassResponse,
      naturalnessMerge: fallbackMerge,
    );
  }

  return LinearPipelineComparisonResult(
    fixture: fixture,
    linearFirstPassCorrectedText: linearFirstPassResponse.correctedText,
    linearLexicalReviewDescription: _describeReview(linearLexicalReview),
    linearCorrectedText: linearResponse.correctedText,
    linearScore: _score(fixture, linearResponse.correctedText),
    linearReason: _reasonFor(fixture, linearResponse.correctedText),
    parallelFirstPassCorrectedText: parallelFirstPassResponse.correctedText,
    parallelNaturalnessOnOriginalDescription: _describeReview(
      parallelNaturalnessOnOriginal,
    ),
    parallelUsedFallback: parallelUsedFallback,
    parallelCorrectedText: parallelResponse.correctedText,
    parallelScore: _score(fixture, parallelResponse.correctedText),
    parallelReason: _reasonFor(fixture, parallelResponse.correctedText),
  );
}

/// Which pipeline "won" one fixture, by pass/fail score comparison.
enum _PipelineOutcome { linearWin, parallelWin, tie }

_PipelineOutcome _classify(LinearPipelineComparisonResult result) {
  final linearPass = isPassingScore(result.linearScore);
  final parallelPass = isPassingScore(result.parallelScore);
  if (linearPass && !parallelPass) {
    return _PipelineOutcome.linearWin;
  }
  if (parallelPass && !linearPass) {
    return _PipelineOutcome.parallelWin;
  }
  return _PipelineOutcome.tie;
}

/// Builds the comparison report, grouped by language point (same
/// convention every other benchmark report in this project uses).
String buildLinearPipelineComparisonReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<LinearPipelineComparisonResult> results,
  required DateTime generatedAt,
}) {
  final buffer = StringBuffer()
    ..writeln(
      '# Two-Pass Pipeline Architecture Comparison: Linear vs. Parallel '
      '(issues #125, #126)',
    )
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixture count: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln()
    ..writeln(
      '"Linear" uses the revised first-pass prompt (issue #126, '
      '`linearFirstPassPrompt`) and the revised, narrower lexical-'
      'transfer-only second-pass prompt (issue #127, '
      '`linearSecondPassPrompt`) — both sourced from '
      '`Two-Pass_Prompt_Revision_Summary.docx` — reviewing that first '
      'pass\'s own corrected text once, sequentially, with no fallback '
      'concept. "Parallel" uses production\'s current, unmodified '
      'first-pass and naturalness prompts throughout, reviewing the '
      'original text (production\'s own concurrent call) and — only '
      'when that merge has a conflict — falling back to a genuine '
      'second naturalness call, same as production. The two '
      'architectures no longer share a first-pass call, since they now '
      'use different prompts throughout both passes.',
    )
    ..writeln();

  final byLanguagePoint = <String, List<LinearPipelineComparisonResult>>{};
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
          '- Pass 1, linear (revised prompt): '
          '`${result.linearFirstPassCorrectedText}`',
        )
        ..writeln(
          '- Pass 1, parallel (current prompt): '
          '`${result.parallelFirstPassCorrectedText}`',
        )
        ..writeln('- Parallel used fallback: ${result.parallelUsedFallback}')
        ..writeln()
        ..writeln(
          '| Architecture | Pass 2 signal | Final output | Score | '
          'Reason |',
        )
        ..writeln('| --- | --- | --- | --- | --- |')
        ..writeln(
          '| Linear (serial) — lexical review | '
          '${result.linearLexicalReviewDescription} | '
          '`${result.linearCorrectedText}` | '
          '${result.linearScore.reportLabel} | ${result.linearReason} |',
        )
        ..writeln(
          '| Parallel (production-equivalent) | '
          '${result.parallelNaturalnessOnOriginalDescription} | '
          '`${result.parallelCorrectedText}` | '
          '${result.parallelScore.reportLabel} | '
          '${result.parallelReason} |',
        )
        ..writeln();
    }
  }

  final linearPassCount = results
      .where((r) => isPassingScore(r.linearScore))
      .length;
  final parallelPassCount = results
      .where((r) => isPassingScore(r.parallelScore))
      .length;
  final fallbackCount = results.where((r) => r.parallelUsedFallback).length;
  final outcomes = results.map(_classify).toList();
  final linearWins = outcomes
      .where((o) => o == _PipelineOutcome.linearWin)
      .length;
  final parallelWins = outcomes
      .where((o) => o == _PipelineOutcome.parallelWin)
      .length;
  final ties = outcomes.where((o) => o == _PipelineOutcome.tie).length;

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Fixtures | ${results.length} |')
    ..writeln('| Fixtures where parallel would use fallback | $fallbackCount |')
    ..writeln('| Linear pass rate | $linearPassCount/${results.length} |')
    ..writeln('| Parallel pass rate | $parallelPassCount/${results.length} |')
    ..writeln('| Linear wins | $linearWins |')
    ..writeln('| Parallel wins | $parallelWins |')
    ..writeln('| Ties | $ties |')
    ..writeln()
    ..writeln(
      '### Score breakdown (issue #129 — full taxonomy, not only '
      'pass/fail)',
    )
    ..writeln()
    ..write(
      _scoreLabelBreakdownTable(
        rows: {
          'Linear': results.map((r) => r.linearScore),
          'Parallel': results.map((r) => r.parallelScore),
        },
      ),
    );

  return buffer.toString();
}

/// One fixture's repeated runs (issue #128, [linearRunsPerFixtureFrom])
/// through the standalone serial execution flow — mirrors
/// `two_pass_fallback_pipeline_comparison_harness.dart`'s
/// `_FixtureGroup` (issues #122/#124), kept as this harness's own
/// separate copy per issue #125's "keep it separate" requirement rather
/// than a shared import.
class _LinearFixtureGroup {
  _LinearFixtureGroup(List<LinearExecutionResult> runs)
    : runs = [...runs]..sort((a, b) => a.runIndex.compareTo(b.runIndex));

  final List<LinearExecutionResult> runs;

  TwoPassFixture get fixture => runs.first.fixture;
  int get passCount => runs.where((r) => isPassingScore(r.score)).length;

  List<String> get distinctFinalOutputs {
    final seen = <String>[];
    for (final run in runs) {
      if (!seen.contains(run.finalCorrectedText)) {
        seen.add(run.finalCorrectedText);
      }
    }
    return seen;
  }
}

/// Groups a flat [LinearExecutionResult] list by fixture id then by
/// language point, both in first-seen order — same purpose as
/// `_GroupedFallbackResults`, kept separate per fixture/harness
/// convention.
class _GroupedLinearExecutionResults {
  factory _GroupedLinearExecutionResults(List<LinearExecutionResult> results) {
    final byFixtureId = <String, List<LinearExecutionResult>>{};
    final fixtureIdOrder = <String>[];
    for (final result in results) {
      final key = result.fixture.id;
      if (!byFixtureId.containsKey(key)) {
        fixtureIdOrder.add(key);
      }
      (byFixtureId[key] ??= []).add(result);
    }
    final groups = {
      for (final entry in byFixtureId.entries)
        entry.key: _LinearFixtureGroup(entry.value),
    };

    final byLanguagePoint = <String, List<String>>{};
    final languagePointOrder = <String>[];
    for (final fixtureId in fixtureIdOrder) {
      final languagePoint = groups[fixtureId]!.fixture.languagePoint;
      if (!byLanguagePoint.containsKey(languagePoint)) {
        languagePointOrder.add(languagePoint);
      }
      (byLanguagePoint[languagePoint] ??= []).add(fixtureId);
    }

    return _GroupedLinearExecutionResults._(
      fixtureIdOrder: fixtureIdOrder,
      groups: groups,
      languagePointOrder: languagePointOrder,
      byLanguagePoint: byLanguagePoint,
    );
  }

  const _GroupedLinearExecutionResults._({
    required this.fixtureIdOrder,
    required this.groups,
    required this.languagePointOrder,
    required this.byLanguagePoint,
  });

  final List<String> fixtureIdOrder;
  final Map<String, _LinearFixtureGroup> groups;
  final List<String> languagePointOrder;
  final Map<String, List<String>> byLanguagePoint;

  int get fixtureCount => fixtureIdOrder.length;
}

/// Builds a report for the standalone serial execution flow (issue
/// #128), grouped by language point then by fixture, with each
/// fixture's repeated runs ([linearRunsPerFixtureFrom]) rolled up into a
/// pass count and a distinct-outputs list. Unlike
/// [buildLinearPipelineComparisonReport], there is no parallel/production
/// side and so no win/tie/regression comparison here — this reports
/// only what the serial flow itself produced.
String buildLinearExecutionReport({
  required String firstPassModel,
  required String naturalnessModel,
  required List<LinearExecutionResult> results,
  required DateTime generatedAt,
}) {
  final grouped = _GroupedLinearExecutionResults(results);

  final buffer = StringBuffer()
    ..writeln('# Two-Pass Linear (Serial) Execution Flow (issue #128)')
    ..writeln()
    ..writeln('## Methodology (issue #132)')
    ..writeln()
    ..writeln(
      '**This is a proof-of-concept report for a SERIAL two-pass '
      'architecture, not the production parallel/fallback pipeline.** '
      'Numbers here describe a prototype under evaluation, not '
      'production behavior — for the production-equivalent pipeline\'s '
      'own report, see `buildLinearPipelineComparisonReport` (linear '
      'vs. parallel, side by side) or '
      '`two_pass_fallback_pipeline_comparison_harness.dart`\'s reports.',
    )
    ..writeln()
    ..writeln(
      '- **Pass 1** corrects grammar, spelling, and punctuation using '
      'the revised first-pass prompt (issue #126, '
      '`linearFirstPassPrompt`, sourced from '
      '`Two-Pass_Prompt_Revision_Summary.docx`) with model '
      '`$firstPassModel`.',
    )
    ..writeln(
      '- **Pass 2** is a lexical-transfer review using the revised '
      'second-pass prompt (issue #127, `linearSecondPassPrompt`, same '
      'source document) with model `$naturalnessModel`. Pass 2 '
      'reviews Pass 1\'s OWN corrected text, never the original '
      'submitted text.',
    )
    ..writeln(
      '- **No fallback path**: production\'s parallel pipeline re-runs '
      'naturalness against the first-pass output only when its '
      'concurrent merge conflicts. This serial flow never needs that '
      '— Pass 2 always reviews the exact text it will be merged into, '
      'so there is nothing left to fall back from.',
    )
    ..writeln(
      '- **No parallel merge step**: Pass 1 and Pass 2 run one after '
      'another, never concurrently, so there are never two independent '
      'naturalness calls to reconcile the way production\'s pipeline '
      'has.',
    )
    ..writeln(
      '- **Purpose**: measure whether this simpler serial architecture '
      'is as reliable, as fast, and as cheap as production\'s parallel '
      '+ conditional-fallback design.',
    )
    ..writeln()
    ..writeln('## Run configuration')
    ..writeln()
    ..writeln('- First-pass model: `$firstPassModel`')
    ..writeln('- Naturalness model: `$naturalnessModel`')
    ..writeln('- Fixture count: `${grouped.fixtureCount}`')
    ..writeln('- Total runs: `${results.length}`')
    ..writeln('- Generated: ${generatedAt.toUtc().toIso8601String()}')
    ..writeln();

  // Issue #131: a top-level per-fixture rollup, same shape as
  // `two_pass_fallback_pipeline_comparison_harness.dart`'s own "Per-
  // fixture summary" section (issues #117/#122), so a 5x sweep here
  // reads side by side with that harness's own 5x sweep.
  buffer
    ..writeln('## Fixture summary')
    ..writeln()
    ..writeln(
      'Pass rate is `passed/runs`; "distinct outputs" lists every '
      'unique final output produced across a fixture\'s runs — more '
      'than one entry means the model was not stable for that fixture.',
    )
    ..writeln()
    ..writeln(
      '| Fixture | Language point | Runs | Pass rate | Distinct final '
      'outputs | Total latency (ms) | Total cost |',
    )
    ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
  for (final fixtureId in grouped.fixtureIdOrder) {
    final group = grouped.groups[fixtureId]!;
    final totalLatencyMs = group.runs.fold<int>(
      0,
      (sum, r) => sum + r.totalStats.wallClockMs,
    );
    final anyUnknownCost = group.runs.any((r) => r.totalStats.costUsd == null);
    final totalCostUsd = anyUnknownCost
        ? null
        : group.runs.fold<double>(0, (sum, r) => sum + r.totalStats.costUsd!);
    buffer.writeln(
      '| $fixtureId | ${group.fixture.languagePoint} | '
      '${group.runs.length} | ${group.passCount}/${group.runs.length} | '
      '${_formatOutputList(group.distinctFinalOutputs)} | '
      '$totalLatencyMs | ${_formatCost(totalCostUsd)} |',
    );
  }
  buffer.writeln();

  for (final languagePoint in grouped.languagePointOrder) {
    buffer
      ..writeln('## $languagePoint')
      ..writeln();
    for (final fixtureId in grouped.byLanguagePoint[languagePoint]!) {
      final group = grouped.groups[fixtureId]!;
      final fixture = group.fixture;
      buffer
        ..writeln('### ${fixture.id}')
        ..writeln()
        ..writeln('- Original text: `${fixture.text}`')
        ..writeln(
          '- Expected corrected text: `${fixture.expectedCorrectedText}`',
        )
        ..writeln('- Pass rate: ${group.passCount}/${group.runs.length}')
        ..writeln('- Distinct final outputs:');
      for (final output in group.distinctFinalOutputs) {
        buffer.writeln('  - `$output`');
      }
      buffer.writeln();

      if (group.runs.length > 1) {
        buffer
          ..writeln(
            '| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal '
            '| Final output | Score | Pass/fail | Reason |',
          )
          ..writeln('| --- | --- | --- | --- | --- | --- | --- | --- |');
        for (final run in group.runs) {
          buffer.writeln(
            '| ${run.runIndex} | `${run.firstPassCorrectedText}` | '
            '${run.firstPassCorrectionsDescription} | '
            '${run.lexicalReviewDescription} | `${run.finalCorrectedText}` '
            '| ${run.score.reportLabel} | '
            '${isPassingScore(run.score) ? 'Pass' : 'Fail'} | '
            '${run.reason} |',
          );
        }
      } else {
        final run = group.runs.single;
        buffer
          ..writeln('- Pass 1 output: `${run.firstPassCorrectedText}`')
          ..writeln(
            '- Pass 1 corrections: ${run.firstPassCorrectionsDescription}',
          )
          ..writeln('- Pass 2 signal: ${run.lexicalReviewDescription}')
          ..writeln('- Score: ${run.score.reportLabel}')
          ..writeln(
            '- Pass/fail: ${isPassingScore(run.score) ? 'Pass' : 'Fail'}',
          )
          ..writeln('- Reason: ${run.reason}');
      }
      buffer.writeln();

      // Issue #130: per-run latency/cost by pass, so a slow or expensive
      // run stays diagnosable even after the pass/fail rollup above
      // discards it. No fallback column — this harness has none.
      buffer
        ..writeln(
          '| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency '
          '(ms) | Pass 2 cost | Total latency (ms) | Total cost |',
        )
        ..writeln('| --- | --- | --- | --- | --- | --- | --- |');
      for (final run in group.runs) {
        buffer.writeln(
          '| ${run.runIndex} | ${run.firstPassStats.wallClockMs} | '
          '${_formatCost(run.firstPassStats.costUsd)} | '
          '${run.secondPassStats.wallClockMs} | '
          '${_formatCost(run.secondPassStats.costUsd)} | '
          '${run.totalStats.wallClockMs} | '
          '${_formatCost(run.totalStats.costUsd)} |',
        );
      }
      buffer.writeln();
    }
  }

  final totalPassCount = results.where((r) => isPassingScore(r.score)).length;
  final totalFirstPassLatencyMs = results.fold<int>(
    0,
    (sum, r) => sum + r.firstPassStats.wallClockMs,
  );
  final totalSecondPassLatencyMs = results.fold<int>(
    0,
    (sum, r) => sum + r.secondPassStats.wallClockMs,
  );
  final totalLatencyMs = results.fold<int>(
    0,
    (sum, r) => sum + r.totalStats.wallClockMs,
  );
  final anyUnknownFirstPassCost = results.any(
    (r) => r.firstPassStats.costUsd == null,
  );
  final anyUnknownSecondPassCost = results.any(
    (r) => r.secondPassStats.costUsd == null,
  );
  final totalFirstPassCostUsd = anyUnknownFirstPassCost
      ? null
      : results.fold<double>(0, (sum, r) => sum + r.firstPassStats.costUsd!);
  final totalSecondPassCostUsd = anyUnknownSecondPassCost
      ? null
      : results.fold<double>(0, (sum, r) => sum + r.secondPassStats.costUsd!);
  final totalCostUsd = anyUnknownFirstPassCost || anyUnknownSecondPassCost
      ? null
      : totalFirstPassCostUsd! + totalSecondPassCostUsd!;

  buffer
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Fixtures | ${grouped.fixtureCount} |')
    ..writeln('| Total runs | ${results.length} |')
    ..writeln('| Pass rate | $totalPassCount/${results.length} |')
    ..writeln()
    ..writeln(
      '### Score breakdown (issue #129 — full taxonomy, not only '
      'pass/fail)',
    )
    ..writeln()
    ..write(
      _scoreLabelBreakdownTable(
        rows: {'All runs': results.map((r) => r.score)},
      ),
    )
    ..writeln()
    ..writeln(
      '### Latency / cost by pass (issue #130 — no fallback phase '
      'exists in this harness, so totals equal Pass 1 + Pass 2 only)',
    )
    ..writeln()
    ..writeln('| Phase | Total latency (ms) | Total est. cost (USD) |')
    ..writeln('| --- | --- | --- |')
    ..writeln(
      '| Pass 1 (first pass) | $totalFirstPassLatencyMs | '
      '${_formatCost(totalFirstPassCostUsd)} |',
    )
    ..writeln(
      '| Pass 2 (lexical review) | $totalSecondPassLatencyMs | '
      '${_formatCost(totalSecondPassCostUsd)} |',
    )
    ..writeln(
      '| **Total (Pass 1 + Pass 2)** | $totalLatencyMs | '
      '${_formatCost(totalCostUsd)} |',
    );

  return buffer.toString();
}

void main() {
  group('offline sanity (no API calls)', () {
    test('linearComparisonFixtureIds all resolve to real fixtures', () {
      expect(
        linearComparisonFixtures.map((f) => f.id).toList(),
        linearComparisonFixtureIds,
      );
    });

    test('fixture ids are unique', () {
      final ids = linearComparisonFixtureIds.toSet();
      expect(ids.length, linearComparisonFixtureIds.length);
    });

    group('linearFirstPassPrompt (issue #126)', () {
      test('matches the source document\'s exact wording (with two '
          'deliberate, recorded divergences — see below) — pinned so an '
          'accidental future edit is caught rather than silently drifting '
          'further from Two-Pass_Prompt_Revision_Summary.docx', () {
        expect(
          linearFirstPassPrompt,
          'You are a Spanish language tutor reviewing a student\'s '
          'writing.\n'
          '\n'
          'Your task is to correct only objective Spanish grammar, '
          'spelling, and punctuation errors.\n'
          '\n'
          'Do not rewrite wording solely because another expression '
          'would be more common, more idiomatic, more fluent, or '
          'stylistically preferable.\n'
          // Issue #154: deliberately diverges from the source document
          // here. The original "do not replace" line only forbade
          // swapping in an alternative — it said nothing about adding
          // to a phrase that's already correct, which is exactly what
          // #150's live evidence showed the first pass doing (inserting
          // an unrequested article into valid regional Spanish,
          // "voy para casa" -> "voy para la casa"). This line now
          // forbids adding, removing, or replacing words in an
          // already-correct phrase, not just replacing them.
          'Do not add, remove, or replace words in a phrase that is '
          'recognised as correct by authoritative Spanish language '
          'references, even when the result would also be correct.\n'
          'Do not treat awkward but grammatically valid Spanish as an '
          'error.\n'
          '\n'
          'Correct every objective grammar, spelling, and punctuation '
          'error that you find.\n'
          '\n'
          'When a sentence contains more than one objective grammar '
          'error, correct every instance, not only the first one. For '
          'example:\n'
          '\n'
          '"Tengo cita con médico mañana."\n'
          '\n'
          'is missing both "una" before "cita" and "el" before '
          '"médico", so correct it to:\n'
          '\n'
          '"Tengo una cita con el médico mañana."\n'
          '\n'
          // Issue #156: a second deliberate divergence from the source
          // document. Pass 1's response contract has grown a
          // "corrections" array (harness-local schema, issue #156's own
          // "not production's firstPassCorrectionResponseFormat") so
          // Pass 2 can eventually see what Pass 1 actually changed,
          // rather than one clean sentence indistinguishable from
          // untouched text — the #135 evidence behind follow-up #147's
          // largest failure cluster.
          //
          // Issue #164: reframed this same paragraph — still a
          // divergence from the source document, not a new one. The
          // original wording ("each correction... the original phrase
          // you changed... the kind of error it was") framed every
          // change as a substitution-of-one-phrase-for-another and as
          // an "error". A deletion (removing a redundant repeated
          // subject pronoun — grammatically correct Spanish, just
          // unnecessary) is neither: #164's own probe evidence showed
          // Pass 1 simply stopped making that edit once the reporting
          // requirement excluded it from the frame. Reworded to "each
          // change... the text as it was before/after... what kind of
          // change" so a deletion fits, with an explicit removal
          // instruction (give enough surrounding text that the change
          // is clear) making explicit what the one still-passing
          // control fixture already did spontaneously.
          'Alongside the corrected text, list each change you made as '
          'a JSON object with the text as it was before the change, '
          'the text as it is after the change, and a short label of '
          'your own choosing for what kind of change it was. Where '
          'you removed words, give enough surrounding text on both '
          'sides that the change is clear. If you made no changes, '
          'return an empty list.\n'
          '\n'
          'Return JSON only. Do not include Markdown or commentary.',
        );
      });

      test('says only objective grammar/spelling/punctuation are in scope, '
          'and explicitly excludes word choice, style, fluency, general '
          'naturalness, and valid regional Spanish (acceptance criteria)', () {
        expect(
          linearFirstPassPrompt,
          contains(
            'correct only objective Spanish grammar, spelling, and '
            'punctuation errors',
          ),
        );
        expect(
          linearFirstPassPrompt,
          contains(
            'Do not rewrite wording solely because another expression '
            'would be more common, more idiomatic, more fluent, or '
            'stylistically preferable',
          ),
        );
        expect(
          linearFirstPassPrompt,
          contains(
            'Do not treat awkward but grammatically valid Spanish as '
            'an error',
          ),
        );
      });

      test('requests a plain JSON reply with no wrapper commentary', () {
        expect(
          linearFirstPassPrompt,
          contains('Return JSON only. Do not include Markdown or commentary.'),
        );
      });
    });

    group('linearSecondPassPrompt (issue #127)', () {
      test('matches the source document\'s exact wording (with one '
          'deliberate, recorded divergence — see below) — pinned so an '
          'accidental future edit is caught rather than silently '
          'drifting further from Two-Pass_Prompt_Revision_Summary.docx', () {
        expect(
          linearSecondPassPrompt,
          'You are a Spanish language tutor reviewing text that has '
          'already been checked for grammar, spelling, and '
          'punctuation.\n'
          '\n'
          // Issue #158: deliberately diverges from the source document
          // starting here. The original prompt stated the "recognised
          // as correct" standard only as a description of what to hunt
          // for (inside "your task is to identify..."), never as a
          // prohibition on acting — restraint sat entirely in the "how
          // to edit" block, which only applies once the model has
          // already decided to make a change, with no gate on the
          // firing decision itself. The #135 5x-sweep evidence behind
          // follow-up #147 showed Pass 2 damaging already-correct
          // Spanish (e.g. "Vi" -> "Había", "terminar de" -> "dejar
          // de") despite passing every existing scope rule — what
          // those failures actually failed was this standard, which
          // was never checked before acting. Restructured so restraint
          // comes before scope: an explicit go/no-go test now sits
          // between the task statement and the category list.
          'Most text you review will contain no lexical issue at all. '
          'Returning no issue is the expected outcome. Only report a '
          'phrase when you are confident it is not recognised as '
          'correct by authoritative Spanish language references.\n'
          '\n'
          'Before reporting anything, apply this test:\n'
          '\n'
          'Is the phrase recognised as correct by authoritative '
          'Spanish language references?\n'
          '\n'
          'If yes, return no issue for that phrase — even if another '
          'phrasing is more common, more idiomatic, more regionally '
          'typical, or would read better. The existence of a '
          'preferable alternative is not grounds for reporting an '
          'issue.\n'
          '\n'
          'Only if the phrase fails that test, consider whether it is '
          'one of the following:\n'
          '\n'
          '- a lexical issue resulting from cross-linguistic '
          'interference, including:\n'
          '  - lexical calques (literal translations),\n'
          '  - false friends (semantic transfer),\n'
          '  - incorrect collocations resulting from language '
          'transfer,\n'
          '  - transferred idiomatic expressions.\n'
          '\n'
          '- another objectively incorrect lexical construction.\n'
          '\n'
          'Do not report spelling, punctuation, or grammatical '
          'errors. If the only problem is grammar, spelling, or '
          'punctuation, return no issue. Ignore them even when they '
          'appear in the same sentence as a lexical issue.\n'
          '\n'
          'When you have identified a genuine lexical issue:\n'
          '\n'
          '- Replace only that lexical issue.\n'
          '- Limit your changes to it, plus any unavoidable '
          'grammatical adjustments required by the replacement.\n'
          '- Preserve the original meaning. Do not substitute a verb '
          'or noun whose meaning differs from the original, even '
          'slightly.\n'
          '- Do not add new information, new clauses, or new ideas.\n'
          '- Do not remove information unless it forms part of the '
          'lexical issue being corrected.\n'
          '- Do not paraphrase or otherwise rewrite the sentence.\n'
          '- Make only the smallest change necessary to eliminate the '
          'lexical issue.\n'
          '\n'
          'Give exactly one replacement for each issue.\n'
          'Never provide more than one replacement.\n'
          'Never join alternatives with a slash, "or", or a list.\n'
          'If more than one replacement is possible, choose the one '
          'that requires the smallest change while fully resolving '
          'the lexical issue.\n'
          '\n'
          'Return JSON only.',
        );
      });

      test('ignores grammar, spelling, and punctuation as its own '
          'categories (acceptance criteria)', () {
        expect(
          linearSecondPassPrompt,
          contains(
            'Do not report spelling, punctuation, or grammatical errors',
          ),
        );
        expect(
          linearSecondPassPrompt,
          contains(
            'If the only problem is grammar, spelling, or punctuation, '
            'return no issue',
          ),
        );
        expect(
          linearSecondPassPrompt,
          contains(
            'Ignore them even when they appear in the same sentence as '
            'a lexical issue',
          ),
        );
      });

      test('is constrained to minimal lexical intervention (acceptance '
          'criteria)', () {
        expect(
          linearSecondPassPrompt,
          contains('Replace only that lexical issue'),
        );
        expect(
          linearSecondPassPrompt,
          contains('Preserve the original meaning'),
        );
        expect(
          linearSecondPassPrompt,
          contains('Do not paraphrase or otherwise rewrite the sentence'),
        );
        expect(
          linearSecondPassPrompt,
          contains(
            'Make only the smallest change necessary to eliminate the '
            'lexical issue',
          ),
        );
      });

      test('requires exactly one replacement, never multiple or '
          'slash-separated alternatives (acceptance criteria)', () {
        expect(
          linearSecondPassPrompt,
          contains('Give exactly one replacement for each issue'),
        );
        expect(
          linearSecondPassPrompt,
          contains('Never provide more than one replacement'),
        );
        expect(
          linearSecondPassPrompt,
          contains('Never join alternatives with a slash, "or", or a list'),
        );
      });

      test('targets the named objective lexical transfer categories', () {
        expect(linearSecondPassPrompt, contains('lexical calques'));
        expect(linearSecondPassPrompt, contains('false friends'));
        expect(
          linearSecondPassPrompt,
          contains('incorrect collocations resulting from language transfer'),
        );
        expect(
          linearSecondPassPrompt,
          contains('transferred idiomatic expressions'),
        );
        expect(
          linearSecondPassPrompt,
          contains('another objectively incorrect lexical construction'),
        );
      });

      test('gates reporting on the "recognised as correct" test before '
          'considering scope (issue #158)', () {
        expect(
          linearSecondPassPrompt,
          contains('Returning no issue is the expected outcome'),
        );
        expect(
          linearSecondPassPrompt,
          contains(
            'Is the phrase recognised as correct by authoritative '
            'Spanish language references?',
          ),
        );
        expect(
          linearSecondPassPrompt,
          contains(
            'The existence of a preferable alternative is not grounds '
            'for reporting an issue',
          ),
        );
        expect(
          linearSecondPassPrompt,
          contains(
            'Do not substitute a verb or noun whose meaning differs '
            'from the original, even slightly',
          ),
        );
      });

      test('requests a plain JSON reply with no wrapper commentary', () {
        expect(linearSecondPassPrompt, contains('Return JSON only.'));
      });
    });

    group('fixture-set selection', () {
      test('"comparison" returns the curated 17-fixture comparison set', () {
        expect(linearFixturesFor('comparison'), linearComparisonFixtures);
      });

      test('"all" returns every fixture in allTwoPassFixtures', () {
        expect(linearFixturesFor('all'), allTwoPassFixtures);
      });

      test('an unrecognized fixture set throws', () {
        expect(() => linearFixturesFor('bogus'), throwsArgumentError);
      });

      test('linearFixturesFrom reads TWO_PASS_LINEAR_FIXTURE_SET from a '
          'real environment, defaulting to "comparison" when unset', () {
        expect(linearFixturesFrom(const {}), linearComparisonFixtures);
        expect(
          linearFixturesFrom(const {'TWO_PASS_LINEAR_FIXTURE_SET': 'all'}),
          allTwoPassFixtures,
        );
      });

      group('"fixture_id" (issue #162)', () {
        test('returns exactly the one matching fixture', () {
          final fixture = allTwoPassFixtures.firstWhere(
            (f) => f.id == 'clean-grammar-only',
          );
          expect(
            linearFixturesFor(
              'fixture_id',
              fixtureId: 'clean-grammar-only',
            ),
            [fixture],
          );
        });

        test('throws when the id is unknown', () {
          expect(
            () => linearFixturesFor(
              'fixture_id',
              fixtureId: 'no-such-fixture',
            ),
            throwsArgumentError,
          );
        });

        test('throws when no id is supplied', () {
          expect(
            () => linearFixturesFor('fixture_id'),
            throwsArgumentError,
          );
        });
      });

      group('"language_point" (issue #162)', () {
        test('returns every fixture in that group', () {
          final expected = allTwoPassFixtures
              .where((f) => f.languagePoint == 'Unnecessary Extras / Deletions')
              .toList();
          expect(expected, isNotEmpty);
          expect(
            linearFixturesFor(
              'language_point',
              languagePoint: 'Unnecessary Extras / Deletions',
            ),
            expected,
          );
        });

        test('throws for an unknown group', () {
          expect(
            () => linearFixturesFor(
              'language_point',
              languagePoint: 'No Such Language Point',
            ),
            throwsArgumentError,
          );
        });

        test('throws when no group is supplied', () {
          expect(
            () => linearFixturesFor('language_point'),
            throwsArgumentError,
          );
        });
      });

      test('linearFixturesFrom reads the new fixture_id/language_point '
          'environment variables (issue #162)', () {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        expect(
          linearFixturesFrom(const {
            'TWO_PASS_LINEAR_FIXTURE_SET': 'fixture_id',
            'TWO_PASS_LINEAR_FIXTURE_ID': 'clean-grammar-only',
          }),
          [fixture],
        );

        final languagePointFixtures = allTwoPassFixtures
            .where((f) => f.languagePoint == 'Unnecessary Extras / Deletions')
            .toList();
        expect(
          linearFixturesFrom(const {
            'TWO_PASS_LINEAR_FIXTURE_SET': 'language_point',
            'TWO_PASS_LINEAR_LANGUAGE_POINT':
                'Unnecessary Extras / Deletions',
          }),
          languagePointFixtures,
        );
      });
    });

    group('linearRunsPerFixtureFrom (issue #128)', () {
      test('defaults to 1 when unset', () {
        expect(linearRunsPerFixtureFrom(const {}), 1);
      });

      test('reads a valid override from a real environment', () {
        expect(
          linearRunsPerFixtureFrom(const {
            'TWO_PASS_LINEAR_RUNS_PER_FIXTURE': '5',
          }),
          5,
        );
      });

      test('throws for zero', () {
        expect(
          () => linearRunsPerFixtureFrom(const {
            'TWO_PASS_LINEAR_RUNS_PER_FIXTURE': '0',
          }),
          throwsArgumentError,
        );
      });

      test('throws for a negative value', () {
        expect(
          () => linearRunsPerFixtureFrom(const {
            'TWO_PASS_LINEAR_RUNS_PER_FIXTURE': '-2',
          }),
          throwsArgumentError,
        );
      });
    });

    test('linearCallDelayMsFrom reads a real environment variable', () {
      expect(
        linearCallDelayMsFrom(const {'TWO_PASS_LINEAR_CALL_DELAY_MS': '2000'}),
        2000,
      );
      expect(linearCallDelayMsFrom(const {}), 750);
    });

    group('_callLinearFirstPassCorrection corrections reporting (issue #156)', () {
      test('a valid corrections array parses correctly into '
          'CorrectionResponse.corrections', () async {
        const submittedText = 'Vi mucho trafico ayer.';
        final client = _RoutingHttpClient(
          linearFirstPassReply: _linearFirstPassEnvelope(
            correctedText: 'Vi mucho tráfico ayer.',
            corrections: const [
              {
                'original_phrase': 'trafico',
                'corrected_phrase': 'tráfico',
                'category': 'accent',
              },
            ],
          ),
          parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
          originalText: submittedText,
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            'unused in this test',
          ),
          parallelFallbackReply: _naturalnessEnvelope('unused in this test'),
          linearLexicalReviewReply: _naturalnessEnvelope(
            'unused in this test',
          ),
        );

        final response = await _callLinearFirstPassCorrection(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: 'gpt-4.1',
          submittedText: submittedText,
        );

        expect(response.correctedText, 'Vi mucho tráfico ayer.');
        expect(response.corrections, hasLength(1));
        final correction = response.corrections.single;
        expect(correction.originalPhrase, 'trafico');
        expect(correction.correctedPhrase, 'tráfico');
        // The raw, unconstrained category label is preserved via
        // shortExplanation even though it doesn't map onto a known
        // ErrorCategory (falls back to .other) — issue #156's own
        // "observe what vocabulary the model naturally produces".
        expect(correction.shortExplanation, 'accent');
        expect(correction.category, ErrorCategory.other);
      });

      test('an empty corrections array parses correctly into an empty '
          'CorrectionResponse.corrections list', () async {
        const submittedText = 'Buenos días, ¿cómo estás?';
        final client = _RoutingHttpClient(
          linearFirstPassReply: _linearFirstPassEnvelope(
            correctedText: submittedText,
          ),
          parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
          originalText: submittedText,
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            'unused in this test',
          ),
          parallelFallbackReply: _naturalnessEnvelope('unused in this test'),
          linearLexicalReviewReply: _naturalnessEnvelope(
            'unused in this test',
          ),
        );

        final response = await _callLinearFirstPassCorrection(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: 'gpt-4.1',
          submittedText: submittedText,
        );

        expect(response.correctedText, submittedText);
        expect(response.corrections, isEmpty);
      });

      test('a correction whose phrases don\'t appear in the submitted/'
          'corrected text is dropped by validation, not passed downstream '
          'unverified', () async {
        const submittedText = 'Vi mucho trafico ayer.';
        final client = _RoutingHttpClient(
          linearFirstPassReply: _linearFirstPassEnvelope(
            correctedText: 'Vi mucho tráfico ayer.',
            corrections: const [
              // Genuine, verifiable correction — should survive.
              {
                'original_phrase': 'trafico',
                'corrected_phrase': 'tráfico',
                'category': 'accent',
              },
              // original_phrase never appears in the submitted text —
              // an unverifiable, hallucinated span — should be dropped.
              {
                'original_phrase': 'palabra inventada',
                'corrected_phrase': 'tráfico',
                'category': 'accent',
              },
              // corrected_phrase never appears in the corrected text —
              // also unverifiable — should be dropped.
              {
                'original_phrase': 'trafico',
                'corrected_phrase': 'palabra inventada',
                'category': 'accent',
              },
            ],
          ),
          parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
          originalText: submittedText,
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            'unused in this test',
          ),
          parallelFallbackReply: _naturalnessEnvelope('unused in this test'),
          linearLexicalReviewReply: _naturalnessEnvelope(
            'unused in this test',
          ),
        );

        final response = await _callLinearFirstPassCorrection(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          model: 'gpt-4.1',
          submittedText: submittedText,
        );

        // Only the genuine, verifiable correction survives — the two
        // unverifiable ones were dropped, not passed downstream.
        expect(response.corrections, hasLength(1));
        expect(response.corrections.single.originalPhrase, 'trafico');
      });
    });

    test('runLinearTwoPassPipeline uses linearFirstPassPrompt (issue #126) '
        'for its first pass and linearSecondPassPrompt (issue #127) for '
        'its lexical review — never production\'s prompts — and makes '
        'exactly two calls total', () async {
      const fixtureText = 'Vi mucho trafico ayer.';
      final client = _RoutingHttpClient(
        linearFirstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
        parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
        originalText: fixtureText,
        naturalnessOnOriginalReply: _naturalnessEnvelope('unused in this test'),
        parallelFallbackReply: _naturalnessEnvelope('unused in this test'),
        linearLexicalReviewReply: _naturalnessEnvelope(
          '{"has_naturalness_issue": true, "issues": ['
          '{"span": "Vi mucho tráfico ayer.", '
          '"natural_replacement": "Había mucho tráfico ayer.", '
          '"explanation": "Calque."}'
          ']}',
        ),
      );

      final response = await runLinearTwoPassPipeline(
        apiKey: 'test-key',
        httpClient: client,
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        submittedText: fixtureText,
      );

      // Applied the linear lexical review reply.
      expect(response.correctedText, 'Había mucho tráfico ayer.');
      expect(client.linearFirstPassCallCount, 1);
      expect(client.parallelFirstPassCallCount, 0);
      expect(client.linearLexicalReviewCallCount, 1);
      // Never touches production's naturalnessReviewSpanish at all.
      expect(client.naturalnessCallCount, 0);
      // Issue #127's own "run the second pass on the first-pass
      // corrected text, not on the original text" requirement: the
      // lexical review call targeted the first-pass output ("Vi mucho
      // tráfico ayer.", with accent), not the original submitted text
      // ("Vi mucho trafico ayer.", without one).
      expect(
        client.capturedLinearLexicalReviewUserText,
        buildNaturalnessUserContent('Vi mucho tráfico ayer.'),
      );
    });

    test('runLinearExecution (issue #128) runs the serial flow with no '
        'parallel call and no fallback call, and its Pass 2 receives Pass '
        '1\'s output, not the original text', () async {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final client = _RoutingHttpClient(
        linearFirstPassReply: _linearFirstPassEnvelope(
          correctedText: fixture.expectedCorrectedText,
          corrections: const [
            {
              'original_phrase': 'trafico',
              'corrected_phrase': 'tráfico',
              'category': 'accent',
            },
          ],
        ),
        parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
        originalText: fixture.text,
        naturalnessOnOriginalReply: _naturalnessEnvelope('unused in this test'),
        parallelFallbackReply: _naturalnessEnvelope('unused in this test'),
        linearLexicalReviewReply: _naturalnessEnvelope(
          '{"has_naturalness_issue": false, "issues": []}',
        ),
      );

      final result = await runLinearExecution(
        apiKey: 'test-key',
        httpClient: client,
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        fixture: fixture,
        runIndex: 3,
      );

      expect(result.fixture, fixture);
      expect(result.runIndex, 3);
      expect(result.firstPassCorrectedText, fixture.expectedCorrectedText);
      expect(result.finalCorrectedText, fixture.expectedCorrectedText);
      expect(result.score, TwoPassScoreLabel.correctFix);
      // Issue #160: Pass 1's own reported corrections (issue #156) flow
      // through runLinearExecution end to end, formatted the same way
      // Pass 2's signal already is.
      expect(
        result.firstPassCorrectionsDescription,
        'trafico -> tráfico (accent)',
      );
      // Issue #130: each pass's own stats are captured, and the total
      // is exactly their sum — no fallback contribution exists.
      expect(
        result.totalStats.wallClockMs,
        result.firstPassStats.wallClockMs + result.secondPassStats.wallClockMs,
      );

      // Issue #128's own acceptance criteria: Pass 2 receives Pass 1's
      // output, not the original text.
      expect(
        client.capturedLinearLexicalReviewUserText,
        buildNaturalnessUserContent(fixture.expectedCorrectedText),
      );

      // No parallel merge path and no fallback call are ever invoked
      // by the standalone serial execution flow.
      expect(client.parallelFirstPassCallCount, 0);
      expect(client.naturalnessCallCount, 0);
      expect(client.linearFirstPassCallCount, 1);
      expect(client.linearLexicalReviewCallCount, 1);
    });

    test('runLinearExecution (issue #130) captures real per-pass latency '
        'and cost, isolated per pass, with the total equal to exactly '
        'Pass 1 + Pass 2', () async {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final client = _RoutingHttpClient(
        linearFirstPassReply: jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': jsonEncode({
                  'corrected_text': fixture.expectedCorrectedText,
                }),
              },
            },
          ],
          'usage': {
            'prompt_tokens': 100,
            'completion_tokens': 20,
            'total_tokens': 120,
          },
        }),
        parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
        originalText: fixture.text,
        naturalnessOnOriginalReply: _naturalnessEnvelope('unused in this test'),
        parallelFallbackReply: _naturalnessEnvelope('unused in this test'),
        linearLexicalReviewReply: jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': '{"has_naturalness_issue": false, "issues": []}',
              },
            },
          ],
          'usage': {
            'prompt_tokens': 40,
            'completion_tokens': 10,
            'total_tokens': 50,
          },
        }),
      );

      final result = await runLinearExecution(
        apiKey: 'test-key',
        httpClient: client,
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        fixture: fixture,
      );

      // Each pass's own tokens are captured in isolation — never mixed
      // with the other pass's usage.
      expect(result.firstPassStats.totalTokens, 120);
      expect(result.secondPassStats.totalTokens, 50);
      expect(result.totalStats.totalTokens, 170);

      // Real cost estimated from known gpt-4.1/gpt-5.1 pricing (never
      // null here), and the total is exactly Pass 1 + Pass 2 — there
      // is no fallback contribution to add in.
      expect(result.firstPassStats.costUsd, isNotNull);
      expect(result.secondPassStats.costUsd, isNotNull);
      expect(
        result.totalStats.costUsd,
        result.firstPassStats.costUsd! + result.secondPassStats.costUsd!,
      );
    });

    test('runLinearExecution (issue #133) never retries, falls back, or '
        'touches the parallel path even when Pass 2 proposes an edit that '
        'does not match Pass 1\'s own output — a scenario that would '
        'trigger the parallel pipeline\'s fallback/conflict-resolution '
        'path, but has no equivalent branch here at all', () async {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final client = _RoutingHttpClient(
        linearFirstPassReply: _firstPassEnvelope(fixture.expectedCorrectedText),
        parallelFirstPassReply: _firstPassEnvelope('unused in this test'),
        originalText: fixture.text,
        naturalnessOnOriginalReply: _naturalnessEnvelope('unused in this test'),
        parallelFallbackReply: _naturalnessEnvelope('unused in this test'),
        // Flags a span that only exists in the ORIGINAL text, not in
        // Pass 1's own corrected output — the same kind of mismatch
        // that makes the parallel pipeline's merge conflict and
        // rerun naturalness as a fallback (see the
        // runLinearPipelineComparison conflict test above). The
        // merge here just skips the edit (spanNotFound); there is no
        // retry/fallback code path in _runLinearSteps to trigger.
        linearLexicalReviewReply: _naturalnessEnvelope(
          '{"has_naturalness_issue": true, "issues": ['
          '{"span": "${fixture.text}", '
          '"natural_replacement": "Something else entirely.", '
          '"explanation": "Does not match Pass 1 output."}'
          ']}',
        ),
      );

      final result = await runLinearExecution(
        apiKey: 'test-key',
        httpClient: client,
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        fixture: fixture,
      );

      // The mismatched edit was skipped, not retried or escalated —
      // the final text is exactly Pass 1's own output, unchanged.
      expect(result.finalCorrectedText, fixture.expectedCorrectedText);

      // Exactly one call per pass — no retry of either.
      expect(client.linearFirstPassCallCount, 1);
      expect(client.linearLexicalReviewCallCount, 1);

      // No parallel merge/conflict/fallback path was ever invoked —
      // protects the serial architecture from an accidental
      // reintroduction of that branch.
      expect(client.parallelFirstPassCallCount, 0);
      expect(client.naturalnessCallCount, 0);
    });

    test(
      'runLinearPipelineComparison (issues #126, #127) makes two '
      'independent first-pass calls, a lexical review call for the '
      'linear side (linearSecondPassPrompt), and genuinely re-issues the '
      'parallel path\'s fallback naturalness call (production\'s '
      'naturalnessReviewSpanish) when the parallel merge conflicts',
      () async {
        final fixture = allTwoPassFixtures.firstWhere(
          (f) => f.id == 'clean-grammar-only',
        );
        final client = _RoutingHttpClient(
          linearFirstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          parallelFirstPassReply: _firstPassEnvelope('Vi mucho tráfico ayer.'),
          originalText: fixture.text,
          // Flags the whole sentence against the ORIGINAL text — this
          // won't match the parallel first pass's own corrected text
          // exactly, so the parallel merge conflicts and triggers a
          // fallback.
          naturalnessOnOriginalReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": true, "issues": ['
            '{"span": "Vi mucho trafico ayer.", '
            '"natural_replacement": "Había mucho tráfico ayer.", '
            '"explanation": "Sounds more natural."}'
            ']}',
          ),
          parallelFallbackReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": false, "issues": []}',
          ),
          linearLexicalReviewReply: _naturalnessEnvelope(
            '{"has_naturalness_issue": false, "issues": []}',
          ),
        );

        final result = await runLinearPipelineComparison(
          client: OpenAiChatCompletionsClient(
            apiKey: 'test-key',
            httpClient: client,
          ),
          firstPassModel: 'gpt-4.1',
          naturalnessModel: 'gpt-5.1',
          fixture: fixture,
        );

        expect(result.parallelUsedFallback, isTrue);
        expect(result.linearCorrectedText, 'Vi mucho tráfico ayer.');
        expect(result.parallelCorrectedText, 'Vi mucho tráfico ayer.');
        // One first-pass call per architecture, one lexical review call
        // for linear, and two naturalness calls for parallel (its
        // naturalness-on-original call, plus a genuine fallback call).
        expect(client.linearFirstPassCallCount, 1);
        expect(client.parallelFirstPassCallCount, 1);
        expect(client.linearLexicalReviewCallCount, 1);
        expect(client.naturalnessCallCount, 2);
      },
    );

    test('buildLinearPipelineComparisonReport groups fixtures by language '
        'point and renders both architectures', () {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final result = LinearPipelineComparisonResult(
        fixture: fixture,
        linearFirstPassCorrectedText: fixture.expectedCorrectedText,
        linearLexicalReviewDescription: '(none)',
        linearCorrectedText: fixture.expectedCorrectedText,
        linearScore: TwoPassScoreLabel.correctFix,
        linearReason: 'Matches expected output.',
        parallelFirstPassCorrectedText: fixture.expectedCorrectedText,
        parallelNaturalnessOnOriginalDescription: '(none)',
        parallelUsedFallback: false,
        parallelCorrectedText: fixture.expectedCorrectedText,
        parallelScore: TwoPassScoreLabel.correctFix,
        parallelReason: 'Matches expected output.',
      );

      final report = buildLinearPipelineComparisonReport(
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        results: [result],
        generatedAt: DateTime.utc(2026, 1, 1),
      );

      expect(report, contains('## ${fixture.languagePoint}'));
      expect(report, contains('### clean-grammar-only'));
      expect(report, contains('Linear (serial)'));
      expect(report, contains('Parallel (production-equivalent)'));
      expect(report, contains('| Linear pass rate | 1/1 |'));
      expect(report, contains('| Parallel pass rate | 1/1 |'));

      // Issue #129: the full benchmark taxonomy is preserved in the
      // overall summary, not collapsed to only pass/fail.
      expect(report, contains('### Score breakdown'));
      expect(
        report,
        contains(
          '| | Total | correct_fix | partial_fix | missed_issue | '
          'overcorrection | acceptable_no_change | ambiguous | error |',
        ),
      );
      expect(report, contains('| Linear | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |'));
      expect(report, contains('| Parallel | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |'));
    });

    test('buildLinearExecutionReport (issue #128) groups fixtures by '
        'language point and rolls up repeated runs into a pass count and '
        'distinct outputs', () {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final results = [
        LinearExecutionResult(
          fixture: fixture,
          runIndex: 1,
          firstPassCorrectedText: fixture.expectedCorrectedText,
          // Issue #160: non-empty on this run, so the new column is
          // exercised with real content, not just the "(none)" case.
          firstPassCorrectionsDescription: 'trafico -> tráfico (accent)',
          lexicalReviewDescription: '(none)',
          finalCorrectedText: fixture.expectedCorrectedText,
          score: TwoPassScoreLabel.correctFix,
          reason: 'Matches expected output.',
          firstPassStats: const CallStats(
            wallClockMs: 100,
            totalTokens: 50,
            costUsd: 0.001,
          ),
          secondPassStats: const CallStats(
            wallClockMs: 200,
            totalTokens: 80,
            costUsd: 0.002,
          ),
        ),
        LinearExecutionResult(
          fixture: fixture,
          runIndex: 2,
          firstPassCorrectedText: fixture.text,
          firstPassCorrectionsDescription: '(none)',
          lexicalReviewDescription: '(none)',
          finalCorrectedText: fixture.text,
          score: TwoPassScoreLabel.missedIssue,
          reason: 'Did not match expected output.',
          firstPassStats: const CallStats(
            wallClockMs: 150,
            totalTokens: 60,
            costUsd: 0.0015,
          ),
          secondPassStats: const CallStats(
            wallClockMs: 250,
            totalTokens: 90,
            costUsd: 0.0025,
          ),
        ),
      ];

      final report = buildLinearExecutionReport(
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        results: results,
        generatedAt: DateTime.utc(2026, 1, 1),
      );

      // Issue #132: methodology notes appear at the top, in plain
      // English, explicitly distinguishing this from the production
      // parallel/fallback report, and naming both the prompt source
      // and the model configuration.
      expect(report, contains('## Methodology'));
      expect(
        report,
        contains(
          'This is a proof-of-concept report for a SERIAL two-pass '
          'architecture, not the production parallel/fallback '
          'pipeline.',
        ),
      );
      expect(
        report,
        contains('Pass 1\'s OWN corrected text, never the original'),
      );
      expect(report, contains('No fallback path'));
      expect(report, contains('No parallel merge step'));
      expect(
        report,
        contains(
          'measure whether this simpler serial architecture is as '
          'reliable, as fast, and as cheap as production\'s parallel '
          '+ conditional-fallback design',
        ),
      );
      expect(report, contains('Two-Pass_Prompt_Revision_Summary.docx'));
      expect(report, contains('model `gpt-4.1`'));
      expect(report, contains('model `gpt-5.1`'));
      // Methodology appears before Run configuration, which appears
      // before the per-fixture detail — "at the top" per the issue.
      expect(
        report.indexOf('## Methodology'),
        lessThan(report.indexOf('## Run configuration')),
      );
      expect(
        report.indexOf('## Run configuration'),
        lessThan(report.indexOf('## Fixture summary')),
      );

      expect(report, contains('## ${fixture.languagePoint}'));
      expect(report, contains('### clean-grammar-only'));
      expect(report, contains('- Pass rate: 1/2'));

      // Issue #131 review finding: each run needs an explicit
      // Pass/fail value alongside its Score, not just the fixture's
      // rolled-up pass rate.
      expect(
        report,
        contains(
          '| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal | '
          'Final output | Score | Pass/fail | Reason |',
        ),
      );
      // Issue #160: Pass 1's own reported corrections now appear as
      // their own column, between "Pass 1 output" and "Pass 2 signal".
      expect(
        report,
        contains(
          '| 1 | `${fixture.expectedCorrectedText}` | trafico -> '
          'tráfico (accent) | (none) | '
          '`${fixture.expectedCorrectedText}` | correct_fix | Pass | '
          'Matches expected output.',
        ),
      );
      expect(
        report,
        contains(
          '| 2 | `${fixture.text}` | (none) | (none) | `${fixture.text}` '
          '| missed_issue | Fail | Did not match expected output.',
        ),
      );

      // Issue #130: per-run latency/cost by pass, plus overall totals
      // equal to Pass 1 + Pass 2 only (no fallback phase).
      expect(
        report,
        contains(
          '| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency '
          '(ms) | Pass 2 cost | Total latency (ms) | Total cost |',
        ),
      );
      expect(
        report,
        contains(
          '| 1 | 100 | \$0.001000 | 200 | \$0.002000 | 300 | \$0.003000 |',
        ),
      );
      expect(
        report,
        contains(
          '| 2 | 150 | \$0.001500 | 250 | \$0.002500 | 400 | \$0.004000 |',
        ),
      );
      expect(report, contains('| Pass 1 (first pass) | 250 | \$0.002500 |'));
      expect(
        report,
        contains('| Pass 2 (lexical review) | 450 | \$0.004500 |'),
      );
      expect(
        report,
        contains('| **Total (Pass 1 + Pass 2)** | 700 | \$0.007000 |'),
      );

      // Issue #131: a top-level fixture summary row rolls up runs,
      // pass rate, distinct outputs, and total latency/cost — same
      // shape as the fallback harness's own "Per-fixture summary".
      expect(report, contains('## Fixture summary'));
      expect(
        report,
        contains(
          '| Fixture | Language point | Runs | Pass rate | Distinct '
          'final outputs | Total latency (ms) | Total cost |',
        ),
      );
      expect(
        report,
        contains(
          '| clean-grammar-only | ${fixture.languagePoint} | 2 | 1/2 | '
          '`${fixture.expectedCorrectedText}`; `${fixture.text}` | 700 '
          '| \$0.007000 |',
        ),
      );
      expect(report, contains('`${fixture.expectedCorrectedText}`'));
      expect(report, contains('`${fixture.text}`'));
      expect(report, contains('| Fixtures | 1 |'));
      expect(report, contains('| Total runs | 2 |'));
      expect(report, contains('| Pass rate | 1/2 |'));

      // Issue #129: one correct_fix run and one missed_issue run stay
      // distinguishable in the overall summary, not merged into a
      // single pass/fail count.
      expect(report, contains('### Score breakdown'));
      expect(report, contains('| All runs | 2 | 1 | 0 | 1 | 0 | 0 | 0 | 0 |'));
    });

    test('buildLinearExecutionReport (issue #133) renders all five runs '
        'for a fixture run through the 5x sweep — a regression that '
        'silently dropped or truncated runs would be caught here', () {
      final fixture = allTwoPassFixtures.firstWhere(
        (f) => f.id == 'clean-grammar-only',
      );
      final results = [
        for (var runIndex = 1; runIndex <= 5; runIndex++)
          LinearExecutionResult(
            fixture: fixture,
            runIndex: runIndex,
            firstPassCorrectedText: fixture.expectedCorrectedText,
            firstPassCorrectionsDescription: '(none)',
            lexicalReviewDescription: '(none)',
            finalCorrectedText: fixture.expectedCorrectedText,
            score: TwoPassScoreLabel.correctFix,
            reason: 'Matches expected output.',
            firstPassStats: const CallStats(
              wallClockMs: 10,
              totalTokens: 5,
              costUsd: 0.0001,
            ),
            secondPassStats: const CallStats(
              wallClockMs: 20,
              totalTokens: 10,
              costUsd: 0.0002,
            ),
          ),
      ];

      final report = buildLinearExecutionReport(
        firstPassModel: 'gpt-4.1',
        naturalnessModel: 'gpt-5.1',
        results: results,
        generatedAt: DateTime.utc(2026, 1, 1),
      );

      expect(report, contains('- Pass rate: 5/5'));
      expect(report, contains('| Fixtures | 1 |'));
      expect(report, contains('| Total runs | 5 |'));
      expect(report, contains('| Pass rate | 5/5 |'));
      // Every run row is present in both per-run tables — none
      // dropped or truncated.
      for (var runIndex = 1; runIndex <= 5; runIndex++) {
        expect(
          report,
          contains(
            '| $runIndex | `${fixture.expectedCorrectedText}` | (none) '
            '| (none) | `${fixture.expectedCorrectedText}` | correct_fix '
            '| Pass | Matches expected output.',
          ),
        );
        expect(
          report,
          contains(
            '| $runIndex | 10 | \$0.000100 | 20 | \$0.000200 | 30 | \$0.000300 |',
          ),
        );
      }
      expect(
        report,
        contains(
          '| clean-grammar-only | ${fixture.languagePoint} | 5 | 5/5 | '
          '`${fixture.expectedCorrectedText}` | 150 | \$0.001500 |',
        ),
      );
    });

    test('_scoreLabelBreakdownTable (issue #129) always shows every '
        'taxonomy column, even at zero, and pass/fail is not the only '
        'signal it reports', () {
      final table = _scoreLabelBreakdownTable(
        rows: {
          'Row A': [TwoPassScoreLabel.correctFix],
          'Row B': [
            TwoPassScoreLabel.partialFix,
            TwoPassScoreLabel.overcorrection,
            TwoPassScoreLabel.ambiguous,
          ],
        },
      );

      for (final label in TwoPassScoreLabel.values) {
        expect(table, contains(label.reportLabel));
      }
      expect(table, contains('| Row A | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |'));
      expect(table, contains('| Row B | 3 | 0 | 1 | 0 | 1 | 0 | 1 | 0 |'));
    });

    test('isPassingScore (issue #129) matches this harness\'s own pass/fail '
        'mapping: pass is exactly correct_fix or acceptable_no_change', () {
      expect(isPassingScore(TwoPassScoreLabel.correctFix), isTrue);
      expect(isPassingScore(TwoPassScoreLabel.acceptableNoChange), isTrue);
      expect(isPassingScore(TwoPassScoreLabel.partialFix), isFalse);
      expect(isPassingScore(TwoPassScoreLabel.missedIssue), isFalse);
      expect(isPassingScore(TwoPassScoreLabel.overcorrection), isFalse);
      expect(isPassingScore(TwoPassScoreLabel.ambiguous), isFalse);
      expect(isPassingScore(TwoPassScoreLabel.error), isFalse);
    });
  });

  test(
    'two-pass pipeline architecture comparison: linear vs. parallel',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!_liveRunOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live linear/parallel pipeline comparison. Set '
          'TWO_PASS_LINEAR_COMPARISON_LIVE=true to opt in.',
        );
        return;
      }

      final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the linear pipeline comparison '
          'harness. This script does NOT fall back to any hardcoded/'
          'default key.',
        );
      }

      final firstPassModel = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_FIRST_PASS_MODEL',
        defaultValue: _defaultFirstPassModel,
      );
      final naturalnessModel = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_NATURALNESS_MODEL',
        defaultValue: _defaultNaturalnessModel,
      );
      final outputPath = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_OUTPUT',
        defaultValue: defaultLinearOutputPath,
      );
      final callDelayMs = linearCallDelayMsFrom(environment);
      final fixtures = linearFixturesFrom(environment);
      final httpClient = HttpClient();
      final client = OpenAiChatCompletionsClient(
        apiKey: apiKey,
        httpClient: httpClient,
      );

      final results = <LinearPipelineComparisonResult>[];
      for (final fixture in fixtures) {
        final result = await runLinearPipelineComparison(
          client: client,
          firstPassModel: firstPassModel,
          naturalnessModel: naturalnessModel,
          fixture: fixture,
        );
        results.add(result);
        // ignore: avoid_print
        print(
          '=== ${fixture.id} === fallback=${result.parallelUsedFallback} '
          'linear="${result.linearCorrectedText}" '
          '(${result.linearScore.reportLabel}) '
          'parallel="${result.parallelCorrectedText}" '
          '(${result.parallelScore.reportLabel})',
        );
        await Future<void>.delayed(Duration(milliseconds: callDelayMs));
      }

      final report = buildLinearPipelineComparisonReport(
        firstPassModel: firstPassModel,
        naturalnessModel: naturalnessModel,
        results: results,
        generatedAt: DateTime.now(),
      );

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote linear pipeline comparison report to $outputPath');
    },
  );

  test(
    'two-pass linear (serial) execution flow (issue #128)',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!_executionLiveRunOptIn(environment)) {
        // ignore: avoid_print
        print(
          'Skipping live linear execution flow run. Set '
          'TWO_PASS_LINEAR_EXECUTION_LIVE=true to opt in.',
        );
        return;
      }

      final apiKey = environment['OPENAI_API_KEY']?.trim() ?? '';
      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the linear execution flow harness. '
          'This script does NOT fall back to any hardcoded/default key.',
        );
      }

      final firstPassModel = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_FIRST_PASS_MODEL',
        defaultValue: _defaultFirstPassModel,
      );
      final naturalnessModel = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_NATURALNESS_MODEL',
        defaultValue: _defaultNaturalnessModel,
      );
      final outputPath = _runtimeString(
        environment: environment,
        key: 'TWO_PASS_LINEAR_EXECUTION_OUTPUT',
        defaultValue: defaultLinearExecutionOutputPath,
      );
      final callDelayMs = linearCallDelayMsFrom(environment);
      final fixtures = linearFixturesFrom(environment);
      final runsPerFixture = linearRunsPerFixtureFrom(environment);
      final httpClient = HttpClient();

      final results = <LinearExecutionResult>[];
      for (final fixture in fixtures) {
        for (var runIndex = 1; runIndex <= runsPerFixture; runIndex++) {
          final result = await runLinearExecution(
            apiKey: apiKey,
            httpClient: httpClient,
            firstPassModel: firstPassModel,
            naturalnessModel: naturalnessModel,
            fixture: fixture,
            runIndex: runIndex,
          );
          results.add(result);
          // ignore: avoid_print
          print(
            '=== ${fixture.id} (run $runIndex/$runsPerFixture) === '
            'final="${result.finalCorrectedText}" '
            '(${result.score.reportLabel}) '
            'latency=${result.totalStats.wallClockMs}ms '
            'cost=${_formatCost(result.totalStats.costUsd)}',
          );
          await Future<void>.delayed(Duration(milliseconds: callDelayMs));
        }
      }

      final report = buildLinearExecutionReport(
        firstPassModel: firstPassModel,
        naturalnessModel: naturalnessModel,
        results: results,
        generatedAt: DateTime.now(),
      );

      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote linear execution flow report to $outputPath');
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

/// Same shape as [_firstPassEnvelope], but for
/// [_linearFirstPassResponseFormat]'s own schema (issue #156), which adds
/// a `corrections` array `_firstPassEnvelope` knows nothing about. Kept
/// as its own helper rather than adding an optional parameter to
/// `_firstPassEnvelope`, since that one is also used to fake the
/// PARALLEL path's first-pass reply (production's own narrower
/// contract), which must stay exactly `{"corrected_text": "string"}`.
String _linearFirstPassEnvelope({
  required String correctedText,
  List<Map<String, String>> corrections = const [],
}) => jsonEncode({
  'choices': [
    {
      'message': {
        'role': 'assistant',
        'content': jsonEncode({
          'corrected_text': correctedText,
          'corrections': corrections,
        }),
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

/// Fake HTTP client routing by request shape: a first-pass call is
/// routed by *system prompt* — [linearFirstPassPrompt] (issue #126) vs.
/// production's `firstPassCorrectionSpanish` — since issue #126 the two
/// architectures no longer share one first-pass call. A naturalness
/// call is routed by *user text* — whether it targets [originalText]
/// (the parallel path's concurrent call) or anything else (a call
/// reviewing a first-pass output, whether the linear path's own call or
/// the parallel path's genuine fallback call). Unlike the fallback
/// comparison harness's fake client (issue #117), there is only ever
/// one naturalness system prompt in play here, so no per-variant
/// naturalness system-prompt routing is needed. All routing state lives
/// on this client instance (constructed fresh per test), never a static
/// field.
class _RoutingHttpClient implements HttpClient {
  _RoutingHttpClient({
    required this.linearFirstPassReply,
    required this.parallelFirstPassReply,
    required this.originalText,
    required this.naturalnessOnOriginalReply,
    required this.parallelFallbackReply,
    required this.linearLexicalReviewReply,
  });

  /// Reply for a first-pass call using [linearFirstPassPrompt] (issue
  /// #126).
  final String linearFirstPassReply;

  /// Reply for a first-pass call using production's
  /// `firstPassCorrectionSpanish`.
  final String parallelFirstPassReply;
  final String originalText;

  /// Reply for the parallel path's naturalness-on-original call
  /// (production's `naturalnessReviewSpanish`, reviewing [originalText]).
  final String naturalnessOnOriginalReply;

  /// Reply for the parallel path's genuine fallback call (production's
  /// `naturalnessReviewSpanish`, reviewing the parallel first-pass
  /// output) — unambiguous since issue #127: the linear path's own
  /// second-pass call now uses an entirely different system prompt
  /// ([linearSecondPassPrompt]), with its own reply slot below, so this
  /// slot is never shared between the two architectures.
  final String parallelFallbackReply;

  /// Reply for the linear path's own second-pass call
  /// ([linearSecondPassPrompt], issue #127).
  final String linearLexicalReviewReply;

  int linearFirstPassCallCount = 0;
  int parallelFirstPassCallCount = 0;
  int linearLexicalReviewCallCount = 0;

  /// The user text sent with the most recent [linearSecondPassPrompt]
  /// call, captured so a test can assert it targeted the first-pass
  /// output rather than the original text (issue #127's own "run the
  /// second pass on the first-pass corrected text, not on the original
  /// text" requirement) — otherwise unverifiable here, since this fake
  /// routes that system prompt to [linearLexicalReviewReply]
  /// unconditionally.
  String? capturedLinearLexicalReviewUserText;

  /// Count of calls using production's `naturalnessReviewSpanish` — the
  /// parallel path's naturalness-on-original call plus, when triggered,
  /// its fallback call. Never incremented by the linear path since
  /// issue #127, which gave it its own distinct system prompt.
  int naturalnessCallCount = 0;

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

    if (systemPrompt == linearFirstPassPrompt) {
      client.linearFirstPassCallCount++;
      return _FakeHttpClientResponse(replyBody: client.linearFirstPassReply);
    }
    if (systemPrompt == firstPassCorrectionSpanish) {
      client.parallelFirstPassCallCount++;
      return _FakeHttpClientResponse(replyBody: client.parallelFirstPassReply);
    }
    if (systemPrompt == linearSecondPassPrompt) {
      client.linearLexicalReviewCallCount++;
      client.capturedLinearLexicalReviewUserText = userText;
      return _FakeHttpClientResponse(
        replyBody: client.linearLexicalReviewReply,
      );
    }

    // Only production's naturalnessReviewSpanish reaches here since
    // issue #127 — the parallel path's naturalness-on-original call or
    // its genuine fallback call.
    client.naturalnessCallCount++;
    final isOnOriginal =
        userText == buildNaturalnessUserContent(client.originalText);
    return _FakeHttpClientResponse(
      replyBody: isOnOriginal
          ? client.naturalnessOnOriginalReply
          : client.parallelFallbackReply,
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
