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

**Revision note**: an earlier version of this document, based on a
10-fixture run, recommended adopting the candidate prompt. That fixture
set omitted several known fallback-changed/fail cases from the prior
live benchmark (`docs/two_pass_live_language_point_benchmark_issue_log.md`)
— repeated-span rewrite, article duplication, two of three false-friend
fails, both slash-alternative naturalness fails, and one mixed-operation
fail — so it did not actually cover what issue #117 asked for ("use the
previous live benchmark as the base, including all phrases where
fallback triggered, changed text, or caused a fail"). The fixture set
below adds all of those back in (17 fixtures total), and the conclusion
has changed as a result: **this document no longer recommends adopting
the candidate prompt.** See "What Changed From The First Run" below.

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

Seventeen fixtures, drawn from the real language-point benchmark
(`allTwoPassFixtures`, issue #82) rather than hand-typed, chosen to cover
every case type issue #117 asked for: clean grammar-only, already-correct
do-not-touch, valid-regional, true-naturalness, mixed/coherence
(reported separately), false-friend, and subjunctive/mood cases — **plus
every known fallback-changed or fallback-caused-fail case from the prior
live benchmark log**: repeated-span rewrite (`ambiguous-naturalness-span`),
article duplication (`article-la-tienda`), the two previously-omitted
false-friend fails (`false-friend-aplico-trabajo`,
`false-friend-embarazado`), both slash-alternative naturalness fails
(`naturalness-pasar-buen-tiempo`, `naturalness-puedo-tener-cerveza`), and
the previously-omitted mixed-operation fail
(`mixed-preposition-and-redundant-pronoun`). All 17 ids were verified to
resolve to exactly one fixture in `allTwoPassFixtures` before the live
run.

Full per-fixture detail: `docs/two_pass_fallback_pipeline_comparison.md`.

## Results

**Fallback genuinely triggered on 6 of the 17 fixtures.** The other 11
share an identical result for both variants (no fallback call was made
for either) — expected, since those fixtures never exercise the
fallback prompt at all. Per your instruction, the two groups are kept
separate rather than blended into one pass rate.

### Fallback-triggered fixtures (the only ones that test the two prompts)

| Fixture | Current outcome | Candidate outcome | Winner |
| --- | --- | --- | --- |
| `clean-grammar-only` | `ambiguous` ("Había...") | `ambiguous` (identical: "Había...") | Tie (both wrong) |
| `mixed-personal-a-and-subjunctive` | `ambiguous` (added "me dijo que") | `ambiguous` (split into two sentences, dropped a clause) | Tie (both wrong, differently) |
| `mixed-verb-agreement-and-missing-que` | `ambiguous` (dropped subject "Ellos", reworded "por hoy") | `ambiguous` (kept "Ellos", reworded "hoy" only) | Tie (both wrong, candidate closer but still not exact) |
| `mixed-preposition-and-redundant-pronoun` | `partial_fix` (changed "y" to ";") | `partial_fix` (kept "y", dropped only the repeated "yo") | Tie (both partial, candidate arguably tidier) |
| `false-friend-aplico-trabajo` | `ambiguous` ("Se postuló a un trabajo.") | **`correct_fix`** (exact match: "Solicitó un trabajo.") | **Candidate** |
| `subj-enviara` | `ambiguous` ("su informe") | `ambiguous` (identical: "su informe") | Tie (both wrong, identical) |

**Fallback-triggered pass rate**: current **0/6**, candidate **1/6**.
**Zero regressions**: no fixture where the candidate scored worse than
the current prompt. But only one clear win, and it is the only passing
result either variant achieves on this subset.

### Non-triggered fixtures (fallback never runs — not informative about the prompt)

Current and candidate are identical on all 11, as expected: **6/11**
pass rate for both. Failures here (`correct-tomar-foto`,
`naturalness-corriendo-tarde`, `false-friend-atendio-universidad`,
`ambiguous-naturalness-span`, `article-la-tienda`) are all first-pass or
parallel-naturalness-pass behavior, out of scope for this comparison.

### All fixtures (diluted — not the number that answers this question)

Current 6/17, candidate 7/17 — included only for completeness; per the
note in the generated report, this number is diluted by the 11 shared
non-triggered results and should not be read as evidence about the
fallback prompt.

## What Changed From The First Run

The first version of this evaluation ran only 10 fixtures and found the
candidate winning 2 of 4 triggered cases outright
(`mixed-personal-a-and-subjunctive` and
`mixed-verb-agreement-and-missing-que` both became exact matches). This
expanded, 17-fixture run includes the same two fixtures — **and this
time, both of them came back as ties, with both variants failing** (the
candidate no longer produces an exact match for either). Nothing about
the harness or the fixtures changed between the two observations of
these two cases; only the live model call did.

This is a materially different — and more informative — result than
simply "more coverage." It demonstrates directly that **a single live
run of either variant is not a stable measurement**, for the same reason
the original #110 isolated-call comparison shouldn't have been treated
as proof: gpt-5.1's naturalness/fallback output is not deterministic
run to run for at least some of these inputs, and a prompt that "wins"
in one run can tie-in-failure in the next. The one new, previously
untested case — `false-friend-aplico-trabajo` — did produce a clear,
single-run candidate win this time, but given what just happened with
the other two mixed cases, it would be a mistake to treat that as
settled without a repeat.

## Recommendation

**Do not adopt the candidate fallback-specific prompt yet.** Per your
instruction not to recommend adoption unless the fallback-triggered
results clearly support it: they don't. Zero regressions across 6
triggered fixtures is a genuinely good sign — the candidate has never
been observed to make a fallback-triggered case worse than the current
prompt, across either this run or the first 10-fixture run (10 total
triggered observations, 0 losses) — but a 1/6 pass rate, combined with
direct evidence that two "wins" from the previous run didn't reproduce,
is not enough to say the candidate reliably improves final outputs.

This does not mean the candidate is a bad prompt or that the project
should quietly forget it — it means **this issue's evidence bar
("improves final outputs without introducing meaningful regressions")
isn't met by a single run**, in either direction. The honest state of
the evidence is: promising (no downside seen anywhere yet), unproven
(only one clear upside, and no case has yet been observed to repeat a
win across two runs).

### Suggested follow-up (not done here, to keep this issue's own live cost bounded)

1. Run issue #107's repeated-run mode (e.g. 5x) specifically on the 6
   fallback-triggered fixtures identified here, for both variants, to
   get a stable per-fixture pass rate instead of a single noisy sample.
2. Only recommend a production prompt change once a repeated-run result
   shows the candidate winning (or tying) on a clear majority of runs
   per fixture, with continued zero regressions.
3. If repeated runs confirm the pattern above, implement as a dedicated
   fallback-specific system prompt (not a reuse of
   `naturalnessReviewSpanish`) in `two_pass_correction_pipeline.dart`,
   pinned to its own harness-validated source per this codebase's
   existing prompt convention.

## Caveats

- **Non-determinism is now the headline finding, not a footnote.** Two
  of six fallback-triggered fixtures changed outcome class between this
  run and the previous one for the exact same inputs and prompts. Any
  future comparison should assume single-run results are unreliable
  signal until repeated-run data says otherwise.
- **Non-fallback-triggered fixtures remain silent on this question** —
  11 of 17 fixtures never exercised the fallback prompt this run. A
  different run could see a different subset trigger fallback, since
  which fixtures trigger a conflict depends on the parallel naturalness
  pass's own (also non-deterministic) output.
- **This is still a curated fixture set** (17, chosen from the prior
  live benchmark's known-relevant cases), not the full 85-fixture
  benchmark — proportionate to a decision-support run, not a full
  confirmation study.

## Files In Scope

```text
test/two_pass_fallback_pipeline_comparison_harness.dart (new)
docs/two_pass_fallback_pipeline_comparison.md (new, live run output)
```

No production behavior changes were made as part of this issue.
