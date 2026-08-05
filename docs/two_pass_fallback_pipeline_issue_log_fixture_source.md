# Fixture Source Behind the Fallback Comparison Issue Log (issue #124)

Investigation + build note. Scope: identify where the benchmark phrases,
groups, expected outputs, scoring taxonomy, latency/cost helpers, and
report-generation patterns behind a fallback-comparison "issue log"
report come from, and make that style generatable from the existing
harness instead of hand-typed.

## What was actually found

Issue #124 asked to locate `docs/two_pass_fallback_pipeline_comparison_all_5x.md`.
That exact file does not exist anywhere in this repository — not
tracked, not untracked, not in git history, not on any branch. What
does exist, and what the issue turned out to actually be about (per
direct confirmation), is `docs/two_pass_fallback_prompt_comparison_issue_log.md`
— an untracked file already sitting in this repo before this issue was
picked up.

That file is a hand-written reformat of
`docs/two_pass_fallback_pipeline_comparison.md` (issue #117's raw,
27-fixture, single-run comparison report) into the plain-English
"issue log" narrative style established by
`docs/two_pass_live_language_point_benchmark_issue_log.md`. Confirmed
by exact timestamp match: both files carry
`2026-08-03T21:01:20.0972...Z` as their "Generated" time, and the
per-fixture data (phrases, expected outputs, pass/fail results) is
identical between them, just restyled from dense Markdown tables into
Item/Finding tables plus narrative sentences. It is not a "5x" report —
it reflects one run per fixture, same as the raw report it was built
from.

This means the issue-log file duplicated benchmark text (phrases,
expected outputs, scores) that already had a real, non-duplicated
source — exactly the situation issue #124's "avoid manually duplicating
benchmark text unless no local source exists" requirement is about.

## Fixture source (already existed, reused as-is)

- **Fixture data**: `allTwoPassFixtures` in
  `test/two_pass_integration_harness.dart` (issue #82, 85 fixtures) —
  phrases, groups (`languagePoint`), and expected outputs.
- **Curated comparison subset**: `fallbackPipelineComparisonFixtureIds` /
  `fallbackPipelineComparisonFixtures` in
  `test/two_pass_fallback_pipeline_comparison_harness.dart` (issue #117)
  — the 27-fixture set the issue-log precedent actually used, itself
  pulled by id from `allTwoPassFixtures`, not hand-typed.
- **Fixture-set selection**: `fallbackPipelineFixturesFrom` /
  `FALLBACK_PIPELINE_FIXTURE_SET=comparison|all` (issue #122) — lets a
  run choose the 27-fixture curated set or the full 85-fixture
  `allTwoPassFixtures`.
- **Scoring taxonomy**: `TwoPassScoreLabel`, `scoreFixtureResult`,
  `isPassingScore` (issue #83/#97), all in
  `test/two_pass_integration_harness.dart` — reused unchanged; the
  issue-log's own "pass means `correct_fix` or `acceptable_no_change`;
  fail means everything else" legend is exactly this taxonomy's own
  `isPassingScore` rule restated in prose.
- **5x / repeated-run pattern**: `FALLBACK_PIPELINE_RUNS_PER_FIXTURE`
  (issue #122), `FallbackPipelineComparisonResult.runIndex`, and the
  per-fixture aggregation now shared via `_FixtureGroup` /
  `_GroupedFallbackResults` (issue #124's own refactor — see below).
- **Report-generation pattern**: `buildFallbackPipelineComparisonReport`
  (issues #117/#122) — the raw table-style report. Issue #124 adds
  `buildFallbackPipelineIssueLogReport`, a second report builder over
  the exact same `FallbackPipelineComparisonResult` data, in the
  issue-log's narrative structure.

## Latency/cost helpers: a real gap, not addressed here

Issue #124 also asked to identify latency/cost helpers behind the
report. `CallStats` (`two_pass_integration_harness.dart`, issue #97/#98)
is the established helper for this elsewhere in the codebase — but
`two_pass_fallback_pipeline_comparison_harness.dart`'s own `_score`
helper constructs every `FixtureResult` with `CallStats.zero`, purely to
drive `scoreFixtureResult`'s scoring logic. **The fallback comparison
harness does not currently track real latency or cost per call at all**,
unlike the diagnostic `two_pass_integration_harness.dart` live runs,
which do. Neither the original issue-log precedent nor the raw
`buildFallbackPipelineComparisonReport` report real latency/cost figures
— confirmed by inspecting both; the hand-written issue log has no
latency/cost rows either. This is a genuine, pre-existing limitation of
the fallback comparison harness, not something #124 introduced or
fixed. A future issue wiring real `CallStats` through
`runFallbackPipelineComparison` would need to change the client call
sites to capture usage, the same way `two_pass_integration_harness.dart`
already does via its `_trackedCall` wrapper.

## What issue #124 built: `buildFallbackPipelineIssueLogReport`

Added to `test/two_pass_fallback_pipeline_comparison_harness.dart`,
alongside `buildFallbackPipelineComparisonReport`. Both now share:

- `_FixtureGroup`: one fixture's runs plus its triggered/pass counts and
  distinct-output lists, computed once.
- `_GroupedFallbackResults`: groups a flat result list by fixture id
  then by language point, in first-seen order.

This refactor means the two report *styles* can never disagree about
which fixtures/runs they're summarizing — they read the same grouped
data, just render it differently.

Wired into the live test runner: `FALLBACK_PIPELINE_ISSUE_LOG_OUTPUT`
(default `docs/two_pass_fallback_pipeline_comparison_issue_log.md`,
deliberately not the same filename as the hand-written precedent so a
live run never silently overwrites it) is written alongside
`FALLBACK_PIPELINE_OUTPUT` on every live run — one run now produces both
report styles.

## Unavoidable fixture/format adaptation (documented per acceptance criteria)

Two adaptations were necessary and are not fully mechanical translations
of the hand-written precedent:

1. **Per-phrase table columns differ between single-run and
   repeated-run mode.** In single-run mode (`FALLBACK_PIPELINE_RUNS_PER_FIXTURE=1`,
   the default), the table matches the hand-written precedent almost
   exactly: `Phrase | Expected | First pass corrected phrase | Pass 2
   signal | Fallback triggered | Current final output | Current
   pass/fail | Candidate final output | Candidate pass/fail`. Under
   issue #122's repeated-run mode, "the" first-pass output or "the"
   final output is no longer a single value — a fixture run 5 times can
   produce up to 5 different outputs per variant. The table switches to
   the same aggregated shape `buildFallbackPipelineComparisonReport`'s
   own "Per-fixture summary" table already established: `Phrase |
   Expected | Fallback triggered | Current pass | Current outputs |
   Candidate pass | Candidate outputs`, with pass counts as `X/N` and
   "outputs" listing every distinct value produced. This reuses the
   #122 aggregation pattern rather than inventing a new one.
2. **"Overall group status" is a simplified, mechanical 3-way rule**
   (`Pass` only if every run of every fixture in the group passed for
   both variants; `Fail` only if every run failed for both; otherwise
   `Needs review`) — not a full reproduction of the hand-written
   precedent's labeling. Cross-checking against the precedent found one
   case (`Required Prepositions`, both variants 0/1) it labeled "Needs
   review" where this mechanical rule would say "Fail," because the
   precedent's author judged the actual output text
   (`La empresa donde trabajo...`) as a plausible alternative rather
   than a clear over-rewrite — a content judgment this report cannot
   make from pass/fail counts alone. Documented in
   `_groupStatusLabel`'s own doc comment.

Additionally, the free-text interpretive fields present in the
hand-written precedent — a "First-pass signal" sentence, a "Naturalness
/ fallback signal" sentence, and a "Practical meaning" sentence per
group, plus a closing "Main Takeaways" narrative — are **not**
generated. They are genuine analysis of *why* a result looks the way it
does, not values derivable from `FallbackPipelineComparisonResult` data.
`buildFallbackPipelineIssueLogReport`'s own generated output says this
explicitly, so a reader never mistakes the absence for "nothing to
report."

## Files in scope

```text
test/two_pass_fallback_pipeline_comparison_harness.dart (modified —
  shared _FixtureGroup/_GroupedFallbackResults grouping extracted from
  buildFallbackPipelineComparisonReport; new
  buildFallbackPipelineIssueLogReport; new
  FALLBACK_PIPELINE_ISSUE_LOG_OUTPUT wiring in the live test)
docs/two_pass_fallback_pipeline_issue_log_fixture_source.md (this file, new)
```

No fixture text was hand-typed as part of this issue. No production
code changed — this is test-harness and documentation only, matching
issue #124's own framing ("harness/reporting issue, not a prompt-change
issue").

The pre-existing untracked
`docs/two_pass_fallback_prompt_comparison_issue_log.md` was left
in place, not deleted — it's the user's own file, not something this
session created, and removing someone else's uncommitted file isn't
this issue's call to make.
