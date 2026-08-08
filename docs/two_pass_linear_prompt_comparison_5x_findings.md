# Live 5x Linear Prompt Benchmark: Findings (issue #135)

Findings for the live run of `docs/two_pass_linear_prompt_comparison_all_5x.md`
(85 fixtures × 5 runs = 425 runs, generated 2026-08-08, models `gpt-4.1` /
`gpt-5.1`). This is a proof-of-concept evaluation of the standalone SERIAL
two-pass architecture (issue #128) against the question issues #125-134
built the harness to answer: is this simpler architecture as reliable, as
fast, and as cheap as production's parallel + conditional-fallback design?

**Live run cost**: $0.657 total (a preliminary 17-fixture smoke check plus
this full sweep — both charged to the API key provided for this run).
**Live run time**: 17m13s for the full 425-run sweep.

## Headline numbers

| Metric | Value |
| --- | --- |
| Overall pass rate, all 85 fixtures (425 runs) | 359/425 = 84.5% |
| Fixtures perfectly reliable (5/5 or a run-limited comparable rate) | 68/85 = 80.0% |
| Fixtures with at least one failing run | 17/85 = 20.0% |
| Total cost, full sweep | $0.657 |
| Total latency, full sweep (sum of all 425 runs' Pass 1 + Pass 2) | 712,656 ms |
| Average latency per run (Pass 1 + Pass 2) | ~1,677 ms |
| `error` scores (harness/infrastructure failures) | 0/425 |

Zero infrastructure failures: every one of the 425 runs produced a
well-formed response the harness could score. Every "failure" below is a
correction-quality outcome, not a crash or malformed call.

## The headline number is misleading on its own — a fairer comparison

**84.5% is not directly comparable to the existing fallback/parallel
report's 51.9%** (`docs/two_pass_fallback_pipeline_comparison.md`, issue
#117, 27 curated fixtures, single run: 14/27 pass). The 85-fixture set
this sweep used includes many fixtures the fallback harness's own curated
27-fixture "hard case" set doesn't — mostly fixtures that were already
easy for the pipeline, inflating the linear side's raw number.

Restricting the linear results to the **exact same 27 fixtures** the
fallback comparison used (`fallbackPipelineComparisonFixtureIds`, issue
#117) gives the fair, apples-to-apples number:

| Approach | Fixtures | Runs | Pass rate |
| --- | --- | --- | --- |
| Linear (serial), this sweep | 27 | 135 (5x) | 69/135 = **51.1%** |
| Parallel + fallback (existing report) | 27 | 27 (1x) | 14/27 = **51.9%** |

**These are statistically indistinguishable.** On the cases that actually
stress the pipeline, the simpler serial architecture is neither better nor
worse than production's parallel + conditional-fallback design. The
original design-review hypothesis — that removing the fallback/merge-
conflict machinery might hurt reliability — is **not supported** by this
data; reliability held up on the hard subset.

## Latency and cost: no fallback baseline exists to compare against

`two_pass_fallback_pipeline_comparison_harness.dart` has never tracked
real per-call latency or cost (documented gap, issue #124's own
investigation note: `_score` there always uses `CallStats.zero`). There is
**no existing fallback/parallel number to compare this sweep's $0.657 /
17m13s against** — this is a real limitation of what this comparison can
say, not something this issue's scope can fix. The linear harness's own
absolute numbers (from this report):

| Phase | Total latency | Total cost | Share of total cost |
| --- | --- | --- | --- |
| Pass 1 (first pass, `gpt-4.1`) | 267,214 ms | $0.255 | 38.8% |
| Pass 2 (lexical review, `gpt-5.1`) | 445,442 ms | $0.402 | 61.2% |
| **Total** | 712,656 ms | $0.657 | 100% |

Pass 2 costs and takes noticeably longer than Pass 1 (`gpt-5.1` is the
pricier, slower model of the two) — expected given the model choice, not
a serial-architecture-specific finding.

## Root-cause breakdown of the 17 non-perfect fixtures

Four distinct, evidence-backed patterns account for essentially every
failure. None of them are infrastructure/harness bugs — all are
correction-quality issues in the prompts or the benchmark's expectations.

### 1. Second-pass false-positive / over-eager lexical flagging (largest cluster — 9 fixtures)

Pass 2 sometimes flags text that has no actual lexical-transfer issue and
rewrites it anyway — occasionally reverting a Pass 1 fix that was already
correct, occasionally swapping in a different valid synonym that doesn't
match the fixture's specific expected wording, occasionally altering
meaning. Concrete evidence:

- `mixed-verb-agreement-and-missing-que` (0/5): Pass 1's output is
  **already correct** every run (`...que está bien terminar de estudiar
  hoy.`), but Pass 2 unprompted-ly substitutes `terminar` → `dejar` in
  all 5 runs — a synonym swap with no lexical-transfer justification.
- `mixed-personal-a-and-subjunctive` (0/5): Pass 1 correctly applies the
  subjunctive (`que estudie`), but Pass 2 downgrades it to the infinitive
  (`estudiar`) — an actual **grammar regression** introduced by the
  "lexical" pass.
- `correct-tomar-foto` (4/5): an "Already Correct / Do Not Tinker"
  fixture — Pass 1 correctly leaves it unchanged 5/5 times, but Pass 2
  spuriously flags `tomar una foto` → `hacer una foto` once, turning a
  passing run into an `overcorrection`.
- `ambiguous-naturalness-span` (4/5): same pattern — a correct,
  unmodified Pass 1 output gets an unprompted Pass 2 rewrite once out of
  5 runs.
- `subj-enviara` (3/5): Pass 2 sometimes swaps `su parte` → `su informe`,
  changing the sentence's meaning with no lexical-transfer basis —
  directly against the revised prompt's own "preserve the original
  meaning" rule.
- `false-friend-aplico-trabajo`, `prep-empresa-en-la-que`,
  `regional-voy-para-casa` show the same signature (a correct or
  near-correct intermediate text gets an inconsistent, unprompted Pass 2
  rewrite across repeated runs).

This is the same underlying defect surfacing as "stochastic" failures:
whether Pass 2 spuriously flags a given text is itself inconsistent run
to run, which is why these fixtures show partial (1/5-4/5) rather than
uniform pass rates.

### 2. "Phrase-Level Naturalness" category is structurally incompatible with the revised prompt's minimal-intervention design (5 fixtures, 100% consistent failure — not stochastic)

All 5 fixtures in this language-point group fail **every single run**,
with the model converging on the *same* output repeatedly (e.g.
`naturalness-pasar-buen-tiempo` and `naturalness-puedo-tener-cerveza`
each produce one identical output across all 5 runs). This is not model
unreliability — it's a direct, predictable consequence of the revised
second-pass prompt's own explicit design principle: "Make only the
smallest change necessary... Do not paraphrase or otherwise rewrite the
sentence." These fixtures' expected outputs (e.g. `Tuvimos un buen
tiempo.` → `Lo pasamos bien.`; `¿Puedo tener una cerveza?` → `¿Me pones
una cerveza?`) require a full idiomatic reformulation, not a minimal
lexical substitution — the two are fundamentally in tension for this
fixture category. The model's actual outputs (`Tuvimos un buen rato.`,
`¿Puedo tomar una cerveza?`) are reasonable, minimally-invasive lexical
fixes; they just can't satisfy fixtures written for a more aggressive
naturalness pass.

### 3. Redundant-pronoun deletion falls in a scope gap between both revised prompts (3 fixtures)

`delete-repeated-yo-estudio` (0/5), `delete-repeated-yo-compre` (0/5),
`mixed-preposition-and-redundant-pronoun` (2/5). Removing a redundant
repeated subject pronoun (`Yo fui... y yo compré...` → `Yo fui... y
compré...`) is neither an objective grammar/spelling/punctuation error
(the revised first-pass prompt's stated scope) nor a lexical-transfer
issue (the revised second-pass prompt's stated scope) — it's a style/
redundancy cleanup that belonged to production's broader "naturalness"
review, which the revision deliberately narrowed away. Pass 2
inconsistently half-attempts it anyway (sometimes removing one of two
redundant pronouns, never both), which is worse than either cleanly
attempting or cleanly declining the task.

### 4. First-pass introduces an unrequested edit to valid regional Spanish (1 fixture)

`regional-voy-para-casa` (1/5) — a "should not flag" fixture testing that
valid regional Spanish (`voy para casa`, no article) is left alone. Pass
1 itself inserts an unrequested `la` (`voy para casa` → `voy para la
casa`) in every run, despite the revised first-pass prompt's own explicit
"do not treat awkward but grammatically valid Spanish as an error" rule.
Pass 2 then inconsistently reverts it (1/5 runs) or overcorrects further
into `a casa`, losing the "para" construction the fixture is specifically
protecting.

## Answering issue #135's questions directly

**Is the linear approach as reliable as parallel/fallback?** On the same
hard-case subset, yes — statistically tied (51.1% vs. 51.9%). The
architecture change (removing concurrency, conflict detection, and the
fallback branch) does not, by itself, appear to cost reliability.

**Is it faster / cheaper?** Cannot be answered from existing data — the
fallback/parallel harness has never tracked real latency or cost
(documented, pre-existing gap). The linear harness's own absolute numbers
($0.657 / 17m13s for 425 runs, ~$0.0015 and ~1.7s per run) are now
available for a future comparison once/if the fallback harness gains the
same instrumentation.

**Is it easier to reason about?** Qualitatively yes, by construction — no
concurrent calls, no conflict detection, no fallback branch to reason
about (issues #125-130's own design). This benchmark doesn't measure that
directly, but it's a structural property, not something that needs a
live run to establish.

## Is the linear approach promising enough to continue?

**Yes, conditionally.** The core architectural bet (serial > parallel +
fallback, reliability-wise) held up under the fairest test available. But
this run also surfaced concrete, evidence-backed prompt-design defects
that should be fixed before adopting this architecture outright — none of
them are inherent to "going serial"; all are fixable in the prompts
themselves. Filed as follow-up issues (evidence above, not speculative):

- **[#147](https://github.com/Thow76/spanish_correction_app/issues/147)** —
  Second-pass lexical review sometimes flags and rewrites text with no
  actual lexical-transfer issue, occasionally reverting correct Pass 1
  grammar or changing sentence meaning (root cause #1 above, the largest
  cluster).
- **[#148](https://github.com/Thow76/spanish_correction_app/issues/148)** —
  The revised second-pass prompt's minimal-intervention design cannot
  satisfy the "Phrase-Level Naturalness" fixture category's fully-
  idiomatic expected outputs; the fixtures and/or the prompt's scope need
  reconciling (root cause #2).
- **[#149](https://github.com/Thow76/spanish_correction_app/issues/149)** —
  Redundant repeated-pronoun deletion has no owning pass under the
  revised two-prompt scope split (root cause #3).
- **[#150](https://github.com/Thow76/spanish_correction_app/issues/150)** —
  The revised first-pass prompt inserts an unrequested article into at
  least one "valid regional Spanish, should not flag" fixture,
  contradicting its own stated rule (root cause #4).

No follow-up issue was opened for the fixtures whose failures were purely
run-to-run variance with no identifiable systematic cause beyond root
cause #1 above — that pattern already explains them.
