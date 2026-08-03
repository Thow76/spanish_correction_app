# Two-Pass Prompt & Contract Audit: First Pass, Naturalness, and Fallback

Investigation note, not a prompt change. Scope: lay out exactly what prompt, input text, and output contract each pass in the two-pass pipeline uses, in production and in the diagnostic/live harness, and connect that to concrete benchmark failures already recorded elsewhere. No prompts or production code were touched to produce this document.

Sources reviewed:

- `lib/core/services/prompts/correction_prompt.dart` — prompt text and response-format constants.
- `lib/features/corrections/data/first_pass_correction_client.dart`, `naturalness_review_client.dart` — the two API-calling clients.
- `lib/features/corrections/data/two_pass_correction_pipeline.dart` — production orchestration (`runTwoPassCorrectionPipeline`).
- `lib/features/corrections/domain/naturalness_merge.dart`, `naturalness_correction_mapper.dart` — the deterministic merge/mapping layer between the two passes.
- `test/two_pass_integration_harness.dart` — the diagnostic/live harness (`runFixture`, `runTwoPassCorrectionPipeline`'s own call pattern mirrored by hand for measurement).
- `docs/two_pass_live_language_point_benchmark_issue_log.md` — diagnostic-mode live run findings (issue #87).
- The production-style benchmark issue-log-format report generated for issues #97/#98/#101 (`Two-Pass Production-Style Benchmark`, 85/85 fixtures, generated 2026-08-02T22:29:36Z) — referenced below as "the production-style report."

## Summary table

| Pass | Prompt source | Input text | Output contract | When it runs | Notes / risks |
| --- | --- | --- | --- | --- | --- |
| First pass | `firstPassCorrectionSpanish`, [correction_prompt.dart:463-474](lib/core/services/prompts/correction_prompt.dart:463) | The original submitted text, always — `buildFirstPassCorrectionUserContent(submittedText)` ([correction_prompt.dart:479-485](lib/core/services/prompts/correction_prompt.dart:479)) | `{"corrected_text": "string"}` only — strict `json_schema`, `additionalProperties: false`, no positions/categories/explanations ([correction_prompt.dart:499-513](lib/core/services/prompts/correction_prompt.dart:499)) | Production: started concurrently with naturalness-on-original ([two_pass_correction_pipeline.dart:47-52](lib/features/corrections/data/two_pass_correction_pipeline.dart:47)). Harness: same, via `_awaitBothSettled` since #98 ([two_pass_integration_harness.dart:1696-1701](test/two_pass_integration_harness.dart:1696)) | 8-line prompt, all blanket "do not" statements, zero worked examples or boundary tests — thin compared to the old staged-pipeline prompts (see §7c) |
| Second pass / naturalness (parallel, on original) | `naturalnessReviewSpanish`, [correction_prompt.dart:418-430](lib/core/services/prompts/correction_prompt.dart:418) | The original submitted text — `buildNaturalnessUserContent(text)` where `text = submittedText` ([naturalness_review_client.dart:10-15](lib/features/corrections/data/naturalness_review_client.dart:10)); called via `two_pass_correction_pipeline.dart:53-57` | `{"has_naturalness_issue": bool, "issues": [{"span", "natural_replacement", "explanation"}]}` — strict `json_schema` ([naturalness_review_client.dart:36-63](lib/features/corrections/data/naturalness_review_client.dart:36)) | Production: started concurrently with the first pass, always runs ([two_pass_correction_pipeline.dart:53-57](lib/features/corrections/data/two_pass_correction_pipeline.dart:53)). Harness: same, concurrently since #98 | No scope-limiting instruction on how much of the sentence `natural_replacement` may rewrite, and no instruction that it must be a single candidate, not several (see §7a, §7b) |
| Fallback naturalness | **Same constant**, `naturalnessReviewSpanish` — no dedicated fallback prompt exists (confirms the assumption below) | The first pass's own corrected text, not the original — same `callNaturalnessReview`, `text: firstPassResponse.correctedText` ([two_pass_correction_pipeline.dart:75-79](lib/features/corrections/data/two_pass_correction_pipeline.dart:75)) | Identical schema to the parallel naturalness call | Production: **conditional** — only when `parallelMerge.skippedEdits.isNotEmpty` ([two_pass_correction_pipeline.dart:68-79](lib/features/corrections/data/two_pass_correction_pipeline.dart:68)). Harness: **unconditional**, called for every fixture regardless of conflict, purely for diagnostic comparison ([two_pass_integration_harness.dart:1711-1719](test/two_pass_integration_harness.dart:1711)) | The prompt has no idea it's a fallback rerun — no framing telling the model it's re-checking already-corrected text and should not restructure or add new content (see §7d) |

## 1. Where is the first-pass prompt defined?

`firstPassCorrectionSpanish` in [lib/core/services/prompts/correction_prompt.dart:463-474](lib/core/services/prompts/correction_prompt.dart:463):

```
You are a Spanish correction engine.

Correct only objective Spanish grammar, spelling, and punctuation errors.

Do not correct word choice.
Do not improve naturalness.
Do not rewrite for style, fluency, tone, or elegance.
Do not change valid regional Spanish.
Do not treat awkward but grammatically valid Spanish as an error.

Return JSON only. Do not include Markdown or commentary.
```

That's the entire prompt — 8 lines, all restraint-only ("do not..."), no positive worked example of what a correct fix looks like, and no example distinguishing "grammar/spelling/punctuation" from "word choice/naturalness" the way the Portuguese prompt's `_ptLabelingBoundaryRules` section does for its own pass (e.g. "if fixing the error changes a single word, it is Word Choice; if fixing it restructures a phrase... it is Natural Language" — [correction_prompt.dart:146](lib/core/services/prompts/correction_prompt.dart:146)). No equivalent boundary test exists anywhere in `firstPassCorrectionSpanish`.

## 2. Where is the second-pass / naturalness prompt defined?

`naturalnessReviewSpanish` in [lib/core/services/prompts/correction_prompt.dart:418-430](lib/core/services/prompts/correction_prompt.dart:418):

```
You are a Spanish tutor reviewing a text that has been checked for grammar, spelling, and punctuation.

Your task is to identify wording that a native Spanish speaker would be unlikely to use naturally in this context. This includes calques, idioms, and collocations.

Do not report spelling, punctuation, or grammatical errors.
If the only problem is grammar, spelling, or punctuation, return no issue.

Do not normalise wording that is natural in an established variety of Spanish. A form is not a naturalness issue merely because another form is more widespread, more neutral, or preferred by the reviewer's own regional variety.This includes established regional uses of para with verbs of movement to express direction or destination, such as ir para + place, where another variety may prefer ir a + place.

Ignore spelling, punctuation, or grammar errors even if they appear in the same sentence as a naturalness issue.

Return JSON only.
```

Note the file's own comment above this constant ([correction_prompt.dart:399-405](lib/core/services/prompts/correction_prompt.dart:399)) flags a known typo — "variety.This includes" is missing a space — carried over unchanged from the harness that originally validated this wording; not fixed here, consistent with this document's own scope.

## 3. Does the fallback pass have its own prompt, or does it reuse the naturalness prompt?

**Confirmed: the assumption in the task is correct.** There is no dedicated fallback prompt. Production's fallback call ([two_pass_correction_pipeline.dart:75-79](lib/features/corrections/data/two_pass_correction_pipeline.dart:75)) is:

```dart
final fallbackNaturalnessReview = await callNaturalnessReview(
  client: client,
  model: naturalnessModel,
  text: firstPassResponse.correctedText,
);
```

— the exact same `callNaturalnessReview` function, same `naturalnessReviewSpanish` system prompt, same `naturalnessReviewResponseFormat` schema, as the parallel call at line 53. The *only* difference between "second pass" and "fallback" is which string gets passed as `text`: the original submission for the parallel call, the first pass's own corrected text for the fallback call. The model receives no signal whatsoever that this is a re-check rather than a first look — no system-prompt branch, no extra instruction, nothing in the user message either (`buildNaturalnessUserContent` just says "Review this Spanish text for naturalness only.\n\nText:\n$text").

## 4. What exact input text does each pass receive?

- **First pass**: always the original submitted text, unmodified — `buildFirstPassCorrectionUserContent(submittedText)`.
- **Second pass (parallel naturalness)**: also the original submitted text, unmodified — run concurrently with the first pass, so it never sees the first pass's output.
- **Fallback naturalness**: the first pass's own `correctedText` — never the original text, and never anything from the parallel naturalness call's own output (that call's result is discarded once fallback triggers; see §6).

## 5. What output schema / response contract does each pass use?

- **First pass**: `{"corrected_text": "string"}`, nothing else, enforced by a strict `json_schema` `response_format` ([correction_prompt.dart:499-513](lib/core/services/prompts/correction_prompt.dart:499)). `parseFirstPassCorrectionResponse` ([first_pass_correction_client.dart:57-82](lib/features/corrections/data/first_pass_correction_client.dart:57)) throws `FormatException` if `corrected_text` is missing or not a string. Deliberately no positions, categories, or explanations — `callFirstPassCorrection` always returns an empty `corrections` list on the resulting `CorrectionResponse` (documented as an explicit POC boundary, `docs/first_pass_correction_poc_scope.md`, issue #71).
- **Naturalness (both parallel and fallback, same schema)**: `{"has_naturalness_issue": bool, "issues": [{"span": string, "natural_replacement": string, "explanation": string}]}`, also a strict `json_schema` ([naturalness_review_client.dart:36-63](lib/features/corrections/data/naturalness_review_client.dart:36)). `NaturalnessReview.fromJson` additionally cross-checks that `has_naturalness_issue` agrees with whether `issues` is non-empty, throwing if they disagree. **No `occurrence` field** — unlike Stage 2's categorization contract, which has one — so a `span` that appears more than once in the text can't be disambiguated by the model at all; that's handled downstream instead (see next point).
- **Merge layer** (`mergeNaturalnessReview`, [naturalness_merge.dart](lib/features/corrections/domain/naturalness_merge.dart)): purely mechanical, not a model call. For each issue, finds `span` in the corrected text by exact grapheme match. Skips (does not apply) an issue when: the span isn't found at all (`spanNotFound`), it's found more than once (`ambiguousSpan`), or its resolved range overlaps an edit already accepted from an earlier-starting issue (`overlapsAnotherEdit`). Everything that survives gets spliced directly into the text. **Important limit**: this safety net is entirely about whether a span can be *safely located and applied* — it has no concept of whether the edit is a reasonable-scope naturalness fix versus, say, replacing an entire sentence. A full-sentence `span`/`natural_replacement` pair that matches exactly once passes through with no objection at all (see §7a).
- **Final unified contract**: `mapNaturalnessEditsIntoCorrectionResponse` ([naturalness_correction_mapper.dart:96-129](lib/features/corrections/domain/naturalness_correction_mapper.dart:96)) folds applied naturalness edits into ordinary `CorrectionItem`s (category always `ErrorCategory.naturalLanguage`) alongside the first pass's own (empty) list, and sets `correctedText` to the merge's `finalCorrectedText` verbatim — so the app-facing `CorrectionResponse` contract is unchanged regardless of which pass produced which edit.

## 6. When does each pass run in production vs in the diagnostic/live harness?

**Production** (`runTwoPassCorrectionPipeline`, [two_pass_correction_pipeline.dart:41-91](lib/features/corrections/data/two_pass_correction_pipeline.dart:41)):

1. First pass and naturalness-on-original: both futures created before either is awaited — genuinely concurrent (lines 47-57).
2. Parallel merge computed against the first pass's corrected text (lines 62-66).
3. If the merge has **no** skipped edits, return immediately using that merge — **fallback is never called** (line 68).
4. Only if the merge has at least one skipped edit: call fallback naturalness on the first pass's corrected text, merge again, and use *that* merge instead, discarding the parallel merge's result entirely — even any edits from it that did apply cleanly (lines 75-90).

**Diagnostic/live harness** (`runFixture`, [two_pass_integration_harness.dart:1648](test/two_pass_integration_harness.dart:1648)):

1. First pass and naturalness-on-original: also concurrent, via `_awaitBothSettled` (added in issue #98 — sequential before that).
2. Fallback naturalness: called **unconditionally, every fixture**, regardless of whether the parallel merge conflicted (line 1711) — purely so the diagnostic report can compare naturalness-on-original against naturalness-on-first-pass-corrected-text side by side.
3. The production-style report (`buildProductionModeReport`, issue #97/#101) doesn't re-run anything live — it reinterprets this same harness run's data through production's conditional-fallback rule after the fact (only counting the fallback call's cost/latency, and only trusting its merge result, when `hadConflict` was actually true), so a single live run produces both a diagnostic view and an accurate production-style view.

## 7. Prompt instructions that plausibly explain the recorded benchmark failures

Cross-checked against both `docs/two_pass_live_language_point_benchmark_issue_log.md` (diagnostic run) and the production-style report — the same failure patterns recur in **both** runs, which is useful signal: it means these are prompt/schema-level issues, not artifacts of the diagnostic harness's now-fixed sequential-timing bug (#98) or its unconditional-fallback-call behavior.

### 7a. Naturalness over-rewriting correct first-pass output

Example, present in both reports: `Vi mucho trafico ayer.` → first pass correctly fixes the accent (`Vi mucho tráfico ayer.`) → fallback naturalness rewrites the *entire sentence* to `Había mucho tráfico ayer.` ("there was a lot of traffic" instead of "I saw a lot of traffic") — a full-sentence restructure with a genuine meaning shift, not a naturalness tweak, scored `fail` in both runs.

Root cause: `naturalnessReviewSpanish` has no restraint instruction analogous to the first pass's own "Do not treat awkward but grammatically valid Spanish as an error," and no scope limit on what `natural_replacement` may cover — nothing tells the model a `span`/`natural_replacement` pair should be as small as possible, or that it should prefer leaving text alone when a smaller fix isn't obviously available. And per §5, `mergeNaturalnessReview`'s safety net only rejects an edit for *span-matching* reasons (not found, ambiguous, overlapping) — a full-sentence span that resolves cleanly and uniquely sails straight through with no semantic check at all.

### 7b. Slash-separated alternatives

Example, present in both reports (worse in the production-style run — 4/5 fail in the Phrase-Level Naturalness group there vs. 3/5 in the diagnostic run): `¿Puedo tener una cerveza?` → `¿Me pones una cerveza? / ¿Me traes una cerveza? / ¿Me das una cerveza?`; `Quiero pasar un buen tiempo.` → `Quiero pasarlo bien / pasar un buen rato.`

Root cause: the `natural_replacement` field is `"type": "string"` with no further constraint, and neither the prompt nor the schema ever states it must contain exactly one proposed replacement. The model is evidently treating "suggest a more natural way to say this" as license to offer several candidates joined by `/` inside that single string field — an output-control gap, not a language-quality one, matching the issue log's own diagnosis.

**Status update (issue #108)**: fixed, via the follow-up this section itself recommended — `naturalnessReviewSpanish` (v4) now explicitly requires exactly one replacement, and `mergeNaturalnessReview` gained a deterministic code-level backstop (`NaturalnessMergeSkipReason.multiOptionReplacement`) that skips any issue whose `naturalReplacement` still looks like a slash-joined menu of options, regardless of whether the prompt change alone is enough. Covered by both the "beer" and `pasar un buen tiempo` patterns cited above.

### 7c. First pass correcting word choice / naturalness-style issues

Example, present in both reports: `Estoy corriendo tarde para la reunión.` → first pass changes `corriendo tarde` to `llegando tarde`, a genuine word-choice/naturalness edit, despite `firstPassCorrectionSpanish` explicitly saying "Do not correct word choice" and "Do not improve naturalness." Also `Voy para casa ahora mismo.` (valid regional Spanish) → first pass inserts `la`, despite "Do not change valid regional Spanish."

Root cause: as noted in §1, the first-pass prompt gives zero worked examples of the grammar/spelling/punctuation-vs-word-choice boundary, unlike the older staged-pipeline's `stage2CategorizationSpanish`, which has an entire "Boundary rules" section with worked examples for exactly this distinction. It also gives no example of what counts as "valid regional Spanish" to calibrate against — contrast with the naturalness prompt, which *does* give one concrete regional example (`ir para + place` vs `ir a + place`) even though that example lives in the wrong prompt for this particular failure (the first pass is the one that needs it here).

**Status update (issue #109)**: fixed — `firstPassCorrectionSpanish` (v2) now includes a worked-examples paragraph covering exactly the `corriendo tarde` calque and `Voy para casa` regional cases cited above, plus a false-friend example (`atendió`) and a multiple-missing-articles instruction. Added as offline `BoundaryControlBenchmarkFixture` regression tests (`boundary-corriendo-tarde-calque`, `boundary-atendio-universidad-false-friend`, `boundary-cita-medico-multi-article` in `test/shared/benchmark_fixtures.dart`) and prompt-content pinning tests in `test/model_comparison_harness.dart`, so this boundary is checked without needing a live model call every time.

### 7d. Fallback changing meaning after first pass already fixed objective errors

Examples from the Mixed Operations group, both reports: `mixed-personal-a-and-subjunctive` — first pass alone already produces the exact expected output, then fallback appends `me dijo que...`, introducing a new idea not present anywhere in the original. `mixed-verb-agreement-and-missing-que` — fallback changes `está bien terminar hoy` to `podemos terminar hoy` (or similar, varies by run), a modality shift.

Root cause: per §3, the fallback call is textually identical to the parallel naturalness call — same prompt, same schema, no framing that tells the model "this text was already corrected by a prior pass; only flag something if it's still clearly unnatural, and do not restructure or add content." The issue log's own breakdown additionally notes these particular fixtures are semantically odd to begin with (two loosely-connected clauses), which may be inviting the model to "repair coherence" — behavior the wide-open "identify wording... unlikely to use naturally in this context" instruction does nothing to rule out, since nothing in the prompt limits "natural" to lexical/collocational fixes rather than broader coherence.

## What this document does not do

Per the task's own scope, this is investigation and documentation only:

- No prompt wording was changed.
- No production code was changed.
- No new benchmark run was performed — every example above is cited from the two existing reports listed at the top.

The four root causes above (§7a-d) are candidate explanations grounded in the actual prompt text and schema, not confirmed via a controlled experiment — a natural follow-up, if this analysis holds up on review, would be a scoped prompt-change proposal for one of the four (most likely 7b, since "return exactly one replacement" is a narrow, low-risk schema/prompt tightening compared to the others) — but that is out of scope here and deferred to a separate, explicit follow-up issue.
