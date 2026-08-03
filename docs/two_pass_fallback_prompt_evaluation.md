# Two-Pass Fallback Naturalness Prompt: Evaluation and Recommendation

Issue: [#110](https://github.com/Thow76/spanish_correction_app/issues/110)

Branch base: `correction_pipeline_refactor`

Scope: evaluate the fallback naturalness call's prompt design against a
candidate alternative, on known fallback over-rewrite cases, and
recommend a direction. No production code changed as part of this issue.

## What Was Built And Run

`test/two_pass_fallback_prompt_comparison_harness.dart` — a small,
standalone harness (not an extension of the already-large
`test/two_pass_integration_harness.dart`) that calls the naturalness
review endpoint directly against a known-correct first-pass output,
under two system prompts:

- **Current (reused)**: `naturalnessReviewSpanish` (v4, issue #108) —
  the exact same prompt and client (`callNaturalnessReview`) production
  uses for both the parallel and fallback naturalness calls today. It
  carries no signal that a fallback call is a *second* look at
  already-corrected text.
- **Candidate (fallback-specific)**: a new prompt (`candidateFallbackPrompt`
  in the harness) that keeps every restraint `naturalnessReviewSpanish`
  already has (naturalness-only scope, regional-variety restraint,
  exactly-one-replacement), and adds explicit framing: the text has
  *already* been corrected once; only flag a clear remaining issue; do
  not restructure the sentence or add new content.

Five fixtures — the exact known fallback over-rewrite cases recorded in
`docs/two_pass_prompt_contract_audit.md` §7a/§7d and
`docs/two_pass_live_language_point_benchmark_issue_log.md` — each with a
repeatedly-observed, already-correct `firstPassCorrectedText` as input.
Both variants were called against the *same* input for each fixture, so
the system prompt is the only variable. Live run: 10 calls total
(`gpt-5.1`), full report in `docs/two_pass_fallback_prompt_comparison.md`.

## Results

| Fixture | Current outcome | Candidate outcome | Candidate improved? |
| --- | --- | --- | --- |
| `clean-grammar-only-overrewrite` | Changed (`Había mucho tráfico ayer.`) | **No issue flagged** — text stayed correct | **Yes, clearly** |
| `false-friend-atendio-overrewrite` | Changed (`Estudió en la universidad...`) | Changed — identical wrong output | No |
| `mixed-personal-a-subjunctive-overrewrite` | Changed (split into two sentences) | Changed — added a *new* clause (`me recordó que`) | **Arguably worse** |
| `mixed-verb-agreement-que-overrewrite` | Changed (reordered/subjunctive shift) | Changed — near-identical reordering/shift | No (tie) |
| `subjunctive-su-parte-overrewrite` | Changed (`su informe`) | Changed — identical wrong output | No |

**Aggregate unwanted-change rate on already-correct text**: current
5/5 (100%), candidate 4/5 (80%).

## Analysis

The candidate prompt produced a **modest, non-zero improvement** — one
clear win, not a wash across the board — but it did not come close to
solving the problem. In 3 of 5 cases the candidate reproduced the
*exact same* wrong output as the current prompt, word for word,
despite the added "this text is already corrected; do not restructure
or add content" framing. In one case
(`mixed-personal-a-subjunctive-overrewrite`) the candidate's rewrite
was arguably *more* invasive than the current prompt's own (it added a
whole new clause, `me recordó que`, where the current prompt's rewrite
only split a sentence).

This matches `docs/two_pass_test_change_notes.md`'s own earlier
speculation for several of these exact fixtures: the mixed-operation
fixtures in particular are "semantically odd... Naturalness may be
trying to repair a coherence gap" — a tendency that framing the prompt
around "don't restructure" doesn't reliably suppress, at least not on
its own. Prompt wording alone is not a sufficient fix here.

A pattern worth flagging for any mechanical follow-up: in every case
where the candidate prompt still changed the text, the flagged `span`
covered most or all of the sentence — never a small, targeted phrase.
A "final naturalness check" on already-correct text plausibly has no
legitimate reason to need a near-whole-sentence span; a first pass
already handled objective correctness, so anything genuinely left for
naturalness to fix should be narrow. This is a testable, code-level
heuristic distinct from prompt wording — see Recommendation below.

## Recommendation

**Add the fallback-specific prompt, and additionally investigate a
mechanical span-size guard as a follow-up — this is not a case for
"retain as-is" or a full redesign.**

- **Retain as-is: rejected.** The current prompt has a 100% unwanted-
  change rate on this fixture set; there's a free, no-downside
  improvement available (same call count, same latency/cost shape) by
  simply telling the model the text has already been corrected.
- **Add fallback-specific prompt: recommended, but only a partial fix.**
  The evidence supports adopting `candidateFallbackPrompt` (or a
  refined version of it) as the fallback's own prompt, replacing the
  reused `naturalnessReviewSpanish`. It measurably helps in at least
  one case and never used more tokens or calls than the current
  design. It should not be oversold as solving the over-rewrite
  problem, though — 80% is still a high unwanted-change rate on
  already-correct text.
- **Mechanize part of fallback: recommended as a follow-up, not
  redesign.** The span-size observation above is worth its own scoped
  follow-up issue: a deterministic guard (analogous to
  `mergeNaturalnessReview`'s existing `NaturalnessMergeSkipReason`
  "never guess" pattern) that skips a fallback edit whose flagged span
  covers more than some threshold share of the input — since a
  legitimate remaining naturalness issue on already-corrected text
  should be narrow, not sentence-spanning. This is not implemented
  here; issue #110's own scope is evaluation and recommendation, not
  implementation.
- **Redesign: not supported by this evidence.** Nothing here points at
  a problem with the two-pass architecture, the merge, or the fallback
  *trigger* condition (conditional on conflict) — every finding traces
  to what the naturalness call is told to do, once conflict already
  triggered a fallback that should have been safe.

## What This Evaluation Does Not Do

- Does not change `naturalnessReviewSpanish`, `callNaturalnessReview`,
  or `runTwoPassCorrectionPipeline`'s fallback call — the candidate
  prompt exists only in the comparison harness.
- Does not implement the span-size mechanical guard suggested above —
  flagged as a follow-up, not started here.
- Is a 5-fixture, single-run comparison, not a statistically large
  sample — issue #107's repeated-run mode would be the natural next
  step before committing to the fallback-specific prompt in
  production, to confirm the 1-clear-win/3-ties/1-arguable-regression
  pattern isn't itself a one-off draw from model non-determinism.

## Files In Scope

```text
test/two_pass_fallback_prompt_comparison_harness.dart (new)
docs/two_pass_fallback_prompt_comparison.md (new, live run output)
```

No production behavior changes were made as part of this issue.
