# Local Verification: Two-Pass Linear Prompt Harness (issue #134)

Verification run for the linear (serial) two-pass harness work built across
issues #125-#133, all of it in a single file:
`test/two_pass_linear_prompt_comparison_harness.dart`. No production code
(anything under `lib/`) was touched by any of that work, so no other file
needed verification here.

Run against `correction_pipeline_refactor` at commit `45639a2` (PR #145,
issue #133's merge — the most recent linear-harness change at the time of
this verification).

## Formatting

```
dart format --output=none --set-exit-if-changed test/two_pass_linear_prompt_comparison_harness.dart
```

Found the file was not `dart format`-clean — manual line-wrapping applied by
hand across nine PRs (#125-#133) had drifted from the formatter's own
wrapping choices (mostly: lines the formatter collapses onto one line once
under its width limit, that had been hand-wrapped onto several). Ran
`dart format` to apply the fix — a purely cosmetic diff (no string literal
content, logic, or test assertions changed, confirmed by the offline suite
still passing identically afterward). Re-running the check afterward
reports `0 changed`, confirming the file is now stable under the
formatter.

**Result: pass** (after applying the formatter's own fix).

## Offline tests

```
flutter test test/two_pass_linear_prompt_comparison_harness.dart --exclude-tags live
```

**Result: pass — 30/30 tests, 0 failures.** Covers every offline group:
fixture-id sanity, both revised prompts' exact wording (issues #126/#127),
fixture-set selection, run-count validation (issue #128), the serial
execution flow itself (issues #125/#128), real per-pass latency/cost
capture (issue #130), the fallback/conflict-reintroduction guard and 5x
report-rendering coverage (issue #133), the linear-vs-parallel comparison
path (issues #125-127), both report builders (issues #125-132), and the
score taxonomy/pass-fail mapping (issue #129).

(A prior PR description in this backlog stated "36 offline tests" for this
file — that number was a miscount at the time; 30 is the actual, directly
observed total as of this verification pass.)

## Static analysis

```
flutter analyze test/two_pass_linear_prompt_comparison_harness.dart
```

**Result: pass — no issues found.**

## Live tests

**Not run.** This harness has two separate live entry points
(`TWO_PASS_LINEAR_COMPARISON_LIVE`, issue #125; `TWO_PASS_LINEAR_EXECUTION_LIVE`,
issue #128), both opt-in and both requiring a real `OPENAI_API_KEY` — real
API cost. Per this issue's own scope ("do not run the live harness unless
explicitly instructed or the repo convention clearly allows it with an
available API key") and standing project policy, neither was run as part of
this verification pass.

## Summary

| Check | Result |
| --- | --- |
| `dart format` | Pass (after applying the formatter's own fix) |
| Offline tests | Pass — 30/30 |
| `flutter analyze` | Pass — no issues |
| Live tests | Not run |
