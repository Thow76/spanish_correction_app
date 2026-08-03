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

**Revision note (second)**: two earlier versions of this document (10
and 17 fixtures) recommended, respectively, adopting and not-yet-adopting
the candidate prompt, each based on partial coverage of the prior live
benchmark log. Code review caught that both still omitted rows —
including `grammar-overlaps-naturalness`, the fixture whose own doc
comment calls it "the case the fallback exists for." The fixture set
below is complete: **it includes every row in
`docs/two_pass_live_language_point_benchmark_issue_log.md` marked
`Fallback pass: Changed`** (both `Pass` and `Fail` outcomes), plus two
`Unchanged` baseline rows kept for already-correct/regional coverage —
27 fixtures total, 11 of which triggered fallback in this run. The
conclusion is unchanged from the previous revision (do not adopt), but
the evidence behind it is now materially different and, if anything,
weaker for the candidate: see "Results" and "Cross-Run Volatility"
below.

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

Full per-fixture detail: `docs/two_pass_fallback_pipeline_comparison.md`.

## Results

**Fallback genuinely triggered on 11 of the 27 fixtures.** The other 16
share an identical result for both variants (no fallback call was made
for either) — 9/16 pass for both, out of scope for this comparison since
neither variant's fallback prompt ever runs on them.

### Fallback-triggered fixtures (the only ones that test the two prompts)

| Fixture | Current outcome | Candidate outcome | Winner |
| --- | --- | --- | --- |
| `clean-grammar-only` | `ambiguous` ("Había...") | `ambiguous` (identical) | Tie (both wrong) |
| `mixed-personal-a-and-subjunctive` | `ambiguous` (added "me dijo que era") | **`correct_fix`** (left correct first-pass text alone) | **Candidate** |
| `mixed-verb-agreement-and-missing-que` | `ambiguous` (reworded, added "ya") | `ambiguous` (reworded differently) | Tie (both wrong) |
| `mixed-preposition-and-redundant-pronoun` | `partial_fix` | `partial_fix` (identical) | Tie (both partial) |
| `mixed-gender-agreement-and-redundant-pronoun` | `correct_fix` | `correct_fix` | Tie (both correct) |
| `false-friend-aplico-trabajo` | **`correct_fix`** (exact match: "Solicitó un trabajo.") | `ambiguous` ("Se postuló a un trabajo.") | **Current** |
| `subj-enviara` | `ambiguous` ("su informe") | `ambiguous` (identical) | Tie (both wrong) |
| `grammar-overlaps-naturalness` | `correct_fix` | `correct_fix` | Tie (both correct — the flagship case; both prompts handle it) |
| `collocation-hace-sentido` | `correct_fix` (fallback found no issue) | `correct_fix` (fallback found no issue) | Tie (both correct) |
| `prep-empresa-en-la-que` | `ambiguous` | `ambiguous` (identical) | Tie (both wrong) |
| `delete-repeated-ellos-visitaron` | `correct_fix` (fallback found no issue) | `correct_fix` (fallback found no issue) | Tie (both correct) |

**Fallback-triggered pass rate: current 5/11, candidate 5/11 — exactly
tied.** One win each: the candidate wins `mixed-personal-a-and-subjunctive`
(correctly declining to re-edit an already-correct first-pass fix); the
current prompt wins `false-friend-aplico-trabajo` (the candidate
introduces a wording drift the current prompt this run did not). **This
is the first run of this evaluation to show the candidate prompt
producing a worse output than the current prompt on a genuinely
triggered fixture** — the "zero regressions" finding from the two
earlier, partial-coverage runs of this same evaluation does not hold
once the fixture set covers every known `Changed` row.

## Cross-Run Volatility

This is now the third live run of a comparison over some or all of
these fixtures, and specific fixtures have flipped outcome class between
runs with no code, prompt, or fixture changes in between:

| Fixture | Run 1 (10 fixtures) | Run 2 (17 fixtures) | Run 3 (27 fixtures, this doc) |
| --- | --- | --- | --- |
| `mixed-personal-a-and-subjunctive` | Candidate wins (exact match) | Tie (both `ambiguous`) | Candidate wins (exact match) |
| `mixed-verb-agreement-and-missing-que` | Candidate wins (exact match) | Tie (both `ambiguous`) | Tie (both `ambiguous`) |
| `false-friend-aplico-trabajo` | *(not in fixture set)* | Candidate wins (exact match) | **Current wins** (candidate regresses) |

The `false-friend-aplico-trabajo` flip is the most important row in that
table: run 2 showed it as the single clearest evidence for adopting the
candidate; run 3, on the identical fixture and identical prompts, shows
the current prompt winning instead. Neither run's result should be
treated as the "true" one — both are single, independent live samples of
a non-deterministic model, and this evaluation's own data across three
runs now shows that any individual fixture's outcome can flip in either
direction from one run to the next.

## Recommendation

**Do not adopt the candidate fallback-specific prompt.** The
fallback-triggered pass rate is now exactly tied (5/11 each) on the most
complete fixture set run so far, with one win apiece — and the win that
had been the strongest single data point for the candidate
(`false-friend-aplico-trabajo`) did not reproduce; it reversed. Combined
with the cross-run volatility observed on two other fixtures, the honest
conclusion is that **this evaluation, across three live runs, has not
produced evidence that the candidate prompt is either better or worse
than the current prompt** — the two are statistically indistinguishable
at this sample size and this level of run-to-run noise.

This does not rule out the candidate prompt working better in practice —
it means **single-run (or even triple-single-run) live comparisons of a
non-deterministic model are not a reliable way to decide this question**,
and no further single run should be expected to settle it either.

### Suggested follow-up (not done here, to keep this issue's own live cost bounded)

1. Run issue #107's repeated-run mode (e.g. 5-10x) on the 11
   fallback-triggered fixtures identified here, for both variants, and
   compare aggregate pass rates with a large enough sample that
   fixture-level noise averages out.
2. Only recommend a production prompt change if a repeated-run result
   shows the candidate winning on a clear, consistent majority of runs,
   with no more losses than the current prompt.
3. If that bar is met, implement as a dedicated fallback-specific system
   prompt in `two_pass_correction_pipeline.dart`, pinned to its own
   harness-validated source per this codebase's existing prompt
   convention.

## Caveats

- **Non-determinism is the dominant finding of this evaluation**, not a
  minor caveat. Three separate fixtures have now been observed to flip
  outcome class across runs with nothing else changing. Any future
  fallback-prompt comparison should assume single-run results are
  unreliable until repeated-run data says otherwise.
- **Fixture coverage is now complete against the "Changed" filter**:
  every row in the prior live benchmark log marked
  `Fallback pass: Changed` (25 rows, both `Pass` and `Fail`) is
  represented among these 27 fixtures, plus two `Unchanged` baseline
  rows kept for already-correct/regional coverage. This document no
  longer claims partial coverage as if it were complete, and no longer
  needs to, since coverage is complete.
- **Non-fallback-triggered fixtures remain silent on this question** —
  16 of 27 fixtures never exercised the fallback prompt this run, and
  which fixtures trigger a conflict can itself vary run to run, since it
  depends on the parallel naturalness pass's own non-deterministic
  output.
- **This is a curated 27-fixture set** drawn from the prior live
  benchmark's specific phrases, not the full 85-fixture benchmark —
  proportionate to a decision-support run, not a full confirmation
  study.

## Files In Scope

```text
test/two_pass_fallback_pipeline_comparison_harness.dart (new)
docs/two_pass_fallback_pipeline_comparison.md (new, live run output)
```

No production behavior changes were made as part of this issue.
