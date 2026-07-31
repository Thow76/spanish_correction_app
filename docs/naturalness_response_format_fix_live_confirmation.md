# `response_format` Fix: Live Confirmation

Confirms the fix in this PR against the exact scenario that found the bug:
issue #42's live two-pass integration harness
(`test/two_pass_integration_harness.dart`, PR #62).

## Before This Fix

Every naturalness call — 5/5 fixtures, reproduced twice independently —
failed to parse live:
`FormatException: Naturalness review is missing "has_naturalness_issue".`
See `docs/two_pass_integration_harness_summary.md` on the #62 branch for
the full root-cause writeup.

## After This Fix

Re-ran the identical 5-fixture harness with this PR's `response_format`
change applied on top of #62's branch (verified locally by merging both
branches; not a commit that lives anywhere permanent — the fix stands on
this PR alone).

```text
| Fixtures | Errors | Conflicts | Fallbacks used | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 5 | 0 | 4 | 4 | 35152 | 17619 | $0.043661 |
```

**Zero parse errors, 5/5 fixtures.** Every naturalness call returned the
exact required shape this time. The `grammar-overlaps-naturalness`
fixture — the scenario the fallback mechanism specifically exists for —
worked exactly as designed: the parallel naturalness call flagged the
pre-correction wording (`iso una decisión importante`, not present in
`firstPassCorrectedText`), triggering a conflict; the fallback rerun
against the corrected text found `hizo una decisión` and resolved cleanly,
producing `Ayer tomó una decisión importante.`

## One Observation, Not A Bug

4 of 5 fixtures hit a conflict (triggering the fallback), more than the
per-fixture notes in the harness predicted (only 1 of 5 was designed to
conflict). Looking at the per-fixture detail
(`docs/two_pass_integration_harness.md`), this is model non-determinism,
not a code defect: gpt-5.1's phrasing of a flagged span isn't always
byte-identical between two separate calls on the same input (e.g. it
independently chose `Había mucho tráfico ayer.` as a more natural
rewording on both the original and first-pass-corrected text for the
`clean-grammar-only` fixture — a real naturalness suggestion neither
fixture note anticipated, not an error). The merge component's "don't
guess" behavior (#34) handled every one of these correctly regardless —
this is exactly the kind of live nuance #42's harness exists to surface.

## Cost

$0.0437 total for this confirmation run (5 fixtures, first pass +
naturalness ×2 each). Combined with the two earlier (pre-fix, all-failing)
attempts and one diagnostic call from #62's investigation, total spend
across this whole investigation is on the order of $0.10-0.15.
