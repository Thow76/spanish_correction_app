# Two-Pass Live Harness: Simple First-Pass Client Confirmation

Issue: [#72](https://github.com/Thow76/spanish_correction_app/issues/72)

Branch base: `correction_pipeline_refactor`

Scope: run the live two-pass integration harness after the simple
first-pass client swap (#65/#67/#68) and record/compare results. No
behavior changes.

## What Was Run

```bash
OPENAI_API_KEY=*** TWO_PASS_LIVE=true \
  flutter test test/two_pass_integration_harness.dart --tags live --timeout none
```

Same 5 fixtures as every prior run of this harness
(`clean-grammar-only`, `naturalness-only`,
`grammar-and-naturalness-independent`, `grammar-overlaps-naturalness`,
`ambiguous-naturalness-span`), same models (`gpt-4.1` first pass,
`gpt-5.1` naturalness). Pass 1 is now `callFirstPassCorrection` (issue
#65/#67), not the old `runStagedCorrectionPipeline`. Full per-fixture
detail is in the regenerated `docs/two_pass_integration_harness.md`
(same file this harness has always written to — not a new report format).

## Baseline: Prior Staged-Pipeline Run

The only prior *successful* (non-parse-failing) live run of this exact
harness against the *old* `runStagedCorrectionPipeline` first pass is
documented in `docs/naturalness_response_format_fix_live_confirmation.md`
(the post-`response_format`-fix confirmation, done immediately before
issue #64 started this POC chain):

| Fixtures | Errors | Conflicts | Fallbacks used | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 5 | 0 | 4 | 4 | 35152 | 17619 | $0.043661 |

(The original issue #42 run before that is not usable as a baseline —
100% of its naturalness calls failed to parse, so it produced no
conflict/fallback/cost data at all; see
`docs/two_pass_integration_harness_summary.md`.)

## This Run: Simple First-Pass Client

| Fixtures | Errors | Conflicts | Fallbacks used | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 5 | 0 | 4 | 4 | 27581 | 4553 | $0.014741 |

## Comparison

| Metric | Staged-pipeline baseline | Simple first-pass client | Change |
| --- | --- | --- | --- |
| Errors | 0/5 | 0/5 | unchanged — both fully reliable |
| Conflicts / fallbacks | 4/5 | 4/5 | **unchanged** — see "Fallback rate" below |
| Total tokens | 17619 | 4553 | **-74%** |
| Total est. cost | $0.043661 | $0.014741 | **-66%** |
| Total wall-clock latency | 35152 ms | 27581 ms | **-22%** |

Token and cost reductions are large and in the expected direction: one
narrow `corrected_text`-only call per fixture instead of the staged
pipeline's three-to-five calls (Stage 1/1B/1C detection, Stage 2
categorization, Stage 3 feedback) across longer, multi-concern prompts.
Latency improved too, though by a smaller margin than tokens/cost —
naturalness (`gpt-5.1`, called twice per fixture either way) dominates
wall-clock time in both runs, so shrinking the first pass to one call
helps less on latency than on tokens/cost.

First-pass-only latency isn't directly comparable phase-for-phase
against the baseline: the baseline confirmation doc only recorded the
aggregate summary row shown above, not a per-phase breakdown, and this
harness's generated report (`docs/two_pass_integration_harness.md`) is
overwritten on every run rather than archived per-run. Per-fixture
first-pass latency for *this* run is in that file's own tables (e.g.
682-3056 ms per fixture, one call each); qualitatively this is what one
`gpt-4.1` call is expected to cost versus the baseline's 3-5 calls.

### Fallback rate: unchanged, and why

Issue #72's own hypothesis was that "the previously artificial fallback
cases caused by the broad staged pipeline pre-fixing naturalness wording
should disappear or reduce substantially." That did **not** happen here —
both runs hit conflicts/fallbacks on 4 of 5 fixtures. But the baseline
confirmation doc already flagged the reason this run reproduces almost
exactly: **`gpt-5.1`'s naturalness pass itself is non-deterministic and
prone to whole-sentence rewrites**, independent of what pass 1 did.

Concretely, this run's `clean-grammar-only` fixture (`Vi mucho trafico
ayer.`, expected to have "no naturalness issue anywhere" per the fixture's
own note) got flagged by naturalness on *both* the original and
first-pass-corrected text as `Vi mucho tráfico ayer. -> Había mucho
tráfico ayer.` — the identical rewording the staged-pipeline baseline run
independently produced for the same fixture (see that doc's "One
Observation, Not A Bug" section). Same model, same non-determinism, same
outcome, regardless of which pipeline supplied pass 1 — direct evidence
that the pre-#64 investigation's root-cause hypothesis (the *staged
pipeline* pre-fixing naturalness wording) explains only part of the
historical fallback rate. The other part is the naturalness model's own
willingness to flag entire sentences as "naturalness issues," which no
first-pass swap can fix on its own.

The one fixture this harness specifically designed to conflict
(`grammar-overlaps-naturalness`, `Ayer iso una decisión importante.`)
still worked exactly as intended in this run: parallel naturalness
flagged the pre-correction span (not present in `firstPassCorrectedText`,
correctly triggering the fallback), the fallback rerun against the
corrected text found `hizo una decisión` and resolved cleanly, producing
`Ayer tomó una decisión importante.` — same as the baseline run.

## Final Corrected Text Quality

Spot-checking this run's final outputs against each fixture's intent:

- `grammar-and-naturalness-independent` and `grammar-overlaps-naturalness`
  produced exactly the expected corrected text (accent/spelling fixes
  plus the intended calque replacement, nothing extraneous).
- `naturalness-only` correctly resolved the calque
  (`hacer` -> `tomar una decisión`) with no first-pass changes, as
  expected.
- `clean-grammar-only` and `ambiguous-naturalness-span` both ended up with
  `gpt-5.1`'s broader "Había..." rewrites layered on top of the intended
  narrow fix — a naturalness-model behavior, not a two-pass wiring defect
  (see above), and identical to what the baseline run already showed for
  the same two fixtures.

## Conclusion

Reliability (0 errors), tokens (-74%), and cost (-66%) all improved or
held steady; latency improved by a smaller margin. Fallback rate did not
improve, but this run supplies direct live evidence for *why*: it isn't
solely (or even primarily, for this fixture set) the old staged pipeline
pre-fixing naturalness wording — `gpt-5.1`'s own naturalness pass
independently produces the same broad, whole-sentence rewrites regardless
of which first pass supplies its input. Reducing the fallback rate
further would need work on the naturalness pass itself (e.g. narrower
prompt guidance against whole-sentence rewrites), which is out of this
POC's scope.

No behavior changes were made as part of this issue — this was a
measurement-only live run, per its own acceptance criteria and out-of-
scope notes.
