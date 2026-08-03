# Two-Pass Fallback Prompt: Full-Pipeline Validation and Recommendation

Issue: [#117](https://github.com/Thow76/spanish_correction_app/issues/117)

Branch base: `correction_pipeline_refactor`

Scope: validate the fallback-specific prompt (issue #110) inside the real
two-pass pipeline — pass 1, pass 2, real conflict detection, and
fallback only when genuinely triggered — rather than as an isolated,
forced call. **This supersedes #110 as the decision point for fallback
prompt design.** No production prompt change is made as part of this
issue; this document is the evidence and recommendation issue #117 asks
for.

## What Was Built And Run

`test/two_pass_fallback_pipeline_comparison_harness.dart` — a small,
self-contained harness (does not depend on the unmerged #110 branch)
that runs the *real* pipeline sequence:

1. Pass 1 (`callFirstPassCorrection`) and pass 2
   (`callNaturalnessReview`, parallel) — run **once** per fixture,
   shared between both variants, since neither call can be affected by
   which fallback prompt is under test.
2. The real `mergeNaturalnessReview` conflict check — identical for
   both variants, since the trigger condition depends only on the
   parallel merge.
3. **Only when that merge genuinely has a skipped edit**: one fallback
   naturalness call per variant (current-reused `naturalnessReviewSpanish`
   vs. the candidate fallback-specific prompt from #110), against the
   exact same `firstPassCorrectedText`.

Ten fixtures (issue #117's own "Test Set" section), drawn from the real
language-point benchmark (`allTwoPassFixtures`, issue #82) rather than
hand-typed: a clean grammar-only case known to have triggered fallback
before, two already-correct do-not-touch cases, a valid-regional case, two
true-naturalness cases, two mixed/coherence cases, a false-friend case, and
a subjunctive/mood case — the same specific cases #110's isolated
evaluation used, so the two methodologies are directly comparable.

Full per-fixture detail: `docs/two_pass_fallback_pipeline_comparison.md`.

## Results

**Fallback genuinely triggered on 4 of the 10 fixtures** — the other 6
share an identical result for both variants (no fallback call was made
for either), which is expected and correct: those 6 fixtures aren't
testing the fallback prompt at all in this run, only the first pass and
parallel naturalness pass, which are unaffected by this evaluation.

| Fixture | Fallback triggered | Current outcome | Candidate outcome | Winner |
| --- | --- | --- | --- | --- |
| `clean-grammar-only` | Yes | `ambiguous` (rewrote to "Había...") | `ambiguous` (rewrote differently, also wrong) | Tie (both wrong) |
| `mixed-personal-a-and-subjunctive` | Yes | `partial_fix` (wrong subjunctive form: "estudie") | **`correct_fix`** (exact match: "estudies") | **Candidate** |
| `mixed-verb-agreement-and-missing-que` | Yes | `ambiguous` (reworded modality: "podemos terminar") | **`correct_fix`** (exact match) | **Candidate** |
| `subj-enviara` | Yes | `ambiguous` ("su informe") | `ambiguous` (identical: "su informe") | Tie (both wrong, identical) |

**Overall pass rate** (`correct_fix` + `acceptable_no_change`, all 10
fixtures): **current 4/10 (40%) vs. candidate 6/10 (60%)** — a clean,
meaningful improvement, entirely explained by the two fallback-triggered
wins above. **Zero regressions**: no fixture where the candidate scored
worse than the current prompt.

## Why This Result Differs From #110's Isolated Evaluation

This is the central finding this issue exists to surface. #110's isolated,
forced-call test of the *same underlying case*
(`mixed-personal-a-subjunctive-overrewrite`) found the candidate prompt
producing a *worse* result than the current one — it added a new clause
(`me recordó que`) not present in the original. Run inside the real
pipeline here, the candidate prompt instead produced an **exact match** to
the expected output, with no added clause.

Two candidate explanations, not fully disambiguated by a single run of
either evaluation:

- **Genuine model non-determinism** — gpt-5.1 not returning the same
  output for the same prompt/input across separate calls (already
  documented elsewhere in this benchmark chain, e.g. the "Había mucho
  tráfico ayer." rewrite recurring identically across multiple
  *unrelated* live runs, while other cases vary run to run).
- **A real difference in call context** between #110's isolated harness
  and the actual pipeline — e.g. subtle timing/concurrency differences
  from the parallel pass 1/pass 2 phase, or something about how the
  fallback call is reached in practice vs. forced directly — though
  nothing in the request itself (system prompt, user text, model,
  schema) actually differs between the two setups, which makes pure
  non-determinism the more likely explanation.

Either way, this is exactly the risk #117's own problem statement named:
**an isolated forced call is not proof of real pipeline behavior**, and a
single run of either methodology is not proof of anything on its own —
see "Caveats" below.

## Recommendation

**Adopt the fallback-specific prompt as `naturalnessReviewSpanish`'s
fallback-call replacement.** This run's evidence clears the bar issue
#117's own acceptance criteria sets: the candidate improved final outputs
(2 of 4 fallback-triggered cases, both to an exact match) **without
introducing any meaningful regression** (0 of 4 cases where it scored
worse; the 2 remaining cases were identical or equivalently wrong for
both variants).

This is not implemented in this issue — issue #117's own scope is
validation and recommendation, matching #110's. A follow-up
implementation issue should:

1. Replace the fallback call's system prompt in
   `two_pass_correction_pipeline.dart` (or add a dedicated
   `callFallbackNaturalnessReview` alongside `callNaturalnessReview`,
   since the parallel call must keep using `naturalnessReviewSpanish`
   unchanged — only the fallback call's prompt changes).
2. Pin the new fallback prompt constant to its own harness-validated
   source, same convention as every other prompt in this codebase.
3. Confirm with a repeated-run comparison (issue #107's repeated-run
   mode) before treating a single 10-fixture, single-run comparison as
   final — see Caveats below.

## Caveats

- **Sample size and run count**: 10 fixtures, one run each. The
  `clean-grammar-only` and `subj-enviara` ties, and the
  `mixed-personal-a-and-subjunctive` result differing from #110's own
  finding for the same case, both point at real run-to-run variance.
  Issue #107's repeated-run mode (5x per fixture) would meaningfully
  strengthen this recommendation before a production change ships —
  not done here, to keep this evaluation's own live cost proportionate
  to a decision-support run, not a full confirmation study.
- **Non-fallback-triggered fixtures are silent on this question.** 6 of
  10 fixtures never exercised the fallback prompt at all this run (some
  due to genuine pipeline health — first pass and parallel naturalness
  alone already produced the right answer — and at least one,
  `false-friend-atendio-universidad`, because naturalness-on-original
  didn't flag anything this run, unlike prior runs where it reliably
  did). A different sample, or the same sample on a different run,
  could see a different subset actually exercise fallback.
- **This remains a 10-fixture curated set**, not the full 85-fixture
  benchmark — chosen to match #110's own test set exactly for direct
  comparability, per this issue's "Test Set" instructions, not to
  re-run the entire benchmark under both variants (which would
  meaningfully multiply live cost for marginal additional evidence
  beyond what these known-relevant cases already show).

## Files In Scope

```text
test/two_pass_fallback_pipeline_comparison_harness.dart (new)
docs/two_pass_fallback_pipeline_comparison.md (new, live run output)
```

No production behavior changes were made as part of this issue.
