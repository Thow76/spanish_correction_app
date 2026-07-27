# First-Pass Spanish Correction Architecture Review

Issue: [#4](https://github.com/Thow76/spanish_correction_app/issues/4)

Branch base: `correction_pipeline_refactor`

Scope: architecture review only. This document does not change prompts, model
behavior, pipeline flow, UI, or span/highlighting logic.

## Recommendation

Move toward a simplified first-pass correction architecture, but do not replace
the current staged pipeline with a `corrected_text`-only call.

The best target architecture is a single first-pass candidate-generation call
that returns structured correction candidates, with explanations generated later
only when needed. The current staged pipeline should remain as the reference
implementation and fallback until the simplified path is benchmarked against the
same fixtures and observability data.

In short:

- Do not keep the current staged pipeline as the long-term first-pass default if
  latency and cost are priority constraints.
- Do not switch production to a bare `{"corrected_text": "string"}` response by
  itself, because that throws away the range, category, note, and save-flow data
  the app currently depends on.
- Do prototype a smaller first-pass candidate call that preserves the local
  anchoring/reconstruction safeguards and moves feedback text out of the hot
  correction path.

## Current Architecture

The app's Spanish correction path is:

1. `OpenAiCorrectionService.correctText(text, Language.spanish)`
2. `_correctSpanishTextViaStagedPipeline(text)`
3. `runStagedCorrectionPipeline(...)`
4. Stage 1, Stage 1B, and Stage 1C detection, called concurrently
5. Stage 2 categorization, only if detection returns flagged phrases
6. local position/range/reconstruction steps
7. Stage 3 feedback, only if Stage 2 leaves error or dialectal candidates

The current first-pass path always makes three detection requests for Spanish.
If anything is flagged, it then makes a Stage 2 request. If Stage 2 leaves an
`error` or `dialectal` candidate, it then makes a Stage 3 request.

That means:

- clean input: three API requests, with no Stage 2 or Stage 3
- Stage 2 early exit: four API requests
- full pipeline: five API requests

The first three requests are concurrent, so their latency cost is closer to one
parallel network round than three sequential rounds. The token/cost impact is
still multiplied, because the submitted text is sent to three different
detection prompts.

## Why The Current Pipeline Exists

The staged design buys control:

- Stage 1 can over-detect suspicious spans.
- Stage 1B protects redundant-pronoun detection without broadening the general
  detection prompt.
- Stage 1C protects missing-reflexive detection without broadening the general
  detection prompt.
- Stage 2 can reject false positives as `not_an_error`, distinguish dialectal
  notes from real corrections, categorize errors, and provide `span_scope`.
- local code handles occurrence resolution, range anchoring, insertion
  narrowing, overlap resolution, corrected text reconstruction, and corrected-
  side highlight positions.
- Stage 3 isolates user-facing explanation wording from correction detection.

This is a sensible reliability architecture, especially given the trial-and-
error history in the active harnesses and archived reports. The problem is that
it is expensive for first-pass correction, because it pays for detection,
adjudication, and explanation before the user has necessarily asked for
explanation-level detail.

## Architecture Options

### Option A: Keep The Current Staged Pipeline

This has the lowest implementation risk and preserves the most known behavior.
It is also the most expensive default.

Pros:

- existing hard-won behavior is preserved
- current UI receives complete `CorrectionItem`s with explanations
- dialectal notes are supported
- local range safeguards are already wired and tested

Cons:

- every Spanish correction pays for three detection calls
- full-pipeline corrections pay for up to five calls
- Stage 2 carries a long policy prompt with category, dialectal, calque, and
  span-scope rules
- Stage 3 explanation generation happens before the user necessarily opens a
  correction detail or saves anything

Conclusion: keep as the reference/fallback path, but do not treat it as the
likely long-term latency/cost answer.

### Option B: Remove One Or More Detection Stages

This reduces request count, but it directly targets the pieces that appear to
have been added after specific failures.

Pros:

- fewer calls than the current staged pipeline
- smaller change than a full architecture replacement
- UI and downstream response shape can remain unchanged

Cons:

- Stage 1B and Stage 1C exist because folding those concerns into general
  detection previously caused regressions or needed narrower span control
- fewer detection stages may reduce recall for redundant-pronoun and missing-
  reflexive cases
- broadening the remaining Stage 1 prompt could increase false positives, which
  still pushes work into Stage 2

Conclusion: possible, but not the first simplification to try. It risks
removing the most targeted fixes while leaving the Stage 2 and Stage 3 cost
structure largely intact.

### Option C: Single Candidate-Generation First Pass

This is the recommended direction.

Instead of detecting phrases in Stage 1 and adjudicating them in Stage 2, a
single first-pass model call would return structured correction candidates. It
should still avoid model-provided character offsets.

Candidate shape should be close to the data the local pipeline already knows how
to process:

```json
[
  {
    "original_phrase": "string",
    "corrected_phrase": "string",
    "occurrence": 1,
    "category": "Grammar",
    "verdict": "error",
    "span_scope": "exact"
  }
]
```

Depending on the chosen first-pass scope, this can be narrower:

- if the first pass is grammar, spelling, and punctuation only, `verdict` may be
  unnecessary and `span_scope` may usually be unnecessary
- if dialectal notes and Natural Language/Word Choice corrections remain in the
  first pass, keep `verdict` and `span_scope`

Pros:

- reduces first-pass request count from three-to-five calls to one call
- sends the learner text once rather than to three detection prompts plus Stage
  2
- preserves occurrence-based local anchoring and corrected-text reconstruction
- allows explanation generation to move out of the hot path
- can be benchmarked directly against the staged pipeline

Cons:

- may reintroduce misses that Stage 1B and Stage 1C were created to catch
- a single prompt has to balance recall, restraint, category assignment, and
  exact-phrase quoting
- current UI expects `shortExplanation` to be present when opening the
  correction sheet and saving a correction
- dialectal notes need a product decision: first-pass notes, lazy notes, or no
  first-pass dialectal feature

Conclusion: best balance of latency/cost reduction and implementation safety,
provided it keeps the local range safeguards.

### Option D: `corrected_text`-Only First Pass

This is useful for model comparison and proof-of-concept prompting, but it is
not enough for production first-pass correction on its own.

Pros:

- smallest response contract
- easiest model comparison across model families
- lowest prompt complexity

Cons:

- no correction spans
- no categories
- no explanations
- no dialectal notes
- no direct save-flow data
- mechanical diffing from `original_text` to `corrected_text` would need a new
  reliability layer and would be fragile around repeated phrases, insertions,
  deletions, accents, and reordered text

Conclusion: keep using this for model/prompt comparison, but do not wire it into
production unless a separate diff-and-classification strategy is designed and
validated.

## Safeguards To Preserve

Any replacement first-pass architecture should preserve these existing
safeguards:

- submitted text remains the source of truth for `originalText`
- the model should not be trusted to provide final character offsets
- model output should identify `original_phrase` and `occurrence`, not
  `start_index`, for first-pass correction candidates
- occurrence resolution should remain local and grapheme-aware
- unresolvable model claims should be dropped rather than rendered
- pure insertions should be narrowed locally to zero-length insertion points
- overlapping candidates should be resolved locally before reconstruction
- corrected text should be reconstructed locally from anchored corrections, not
  accepted wholesale from the model
- corrected-side highlight ranges should be computed by local arithmetic
- pure deletion should continue absorbing adjacent whitespace consistently
- Spanish accents, diacritics, `ñ`, and combining-accent sequences must be
  handled as user-perceived characters

These safeguards are more important than the current stage boundaries. The
architecture can change, but these mechanics should remain.

## Explanation And UI Implications

Moving Stage 3 out of first pass has product impact.

The current corrections screen shows the corrected/original highlights first,
but the correction detail sheet displays `shortExplanation`, and saved
correction cards also show the saved explanation. So explanations can be moved
on demand, but the UI and save flow need to support one of these states:

- explanation is loaded lazily when a correction is tapped
- explanation is generated when a correction is saved
- first-pass correction shows categories/highlights immediately, with
  explanation text marked as unavailable until requested

The cleanest migration is lazy explanation on tap, with save either waiting for
that explanation or generating it as part of the save action.

## Latency And Cost Tradeoffs

No generated live baseline report was present in `docs/` at the time of this
review, so this section is structural rather than numeric.

Current staged pipeline:

- minimum successful Spanish correction: three API requests
- full correction with feedback: five API requests
- latency shape: one parallel detection round, then sequential Stage 2, then
  sequential Stage 3
- cost shape: learner text is sent repeatedly; Stage 2 and Stage 3 add long
  prompt/output costs

Single candidate first pass:

- first-pass correction: one API request
- explanation path: one additional request only when the user asks for detail or
  saves a correction
- latency shape: one round trip for first visible result
- cost shape: learner text is sent once for first-pass correction; explanation
  cost is paid only for engaged corrections

The biggest likely win is moving Stage 3 out of the default path. The second
biggest win is collapsing Stage 1 plus Stage 2 into one candidate-generation
call. Removing only Stage 1B or Stage 1C is less attractive because it saves
some request overhead but risks removing narrowly targeted fixes.

## Implementation Risk

Main risks:

- missed redundant-pronoun or missing-reflexive corrections
- over-correction of valid regional Spanish
- loss of dialectal-note behavior
- candidate objects that cannot be anchored back to the submitted text
- category drift if the simplified prompt tries to classify too much
- UI regressions if explanations become asynchronous

Mitigations:

- keep the current staged pipeline behind a feature flag or fallback switch
- benchmark simplified first-pass candidates against the same shared fixtures
- keep the existing domain-level range/resolution tests
- compare output against current `pipeline_baseline_harness.dart`
- use `model_comparison_harness.dart` only as a prompt/model signal, not as
  proof that production spans are solved
- gate rollout on valid JSON, anchoring success, correction precision, and
  Spanish-character round-trip checks

## Minimal Migration Path

1. Keep the current staged pipeline as production default.
2. Add a standalone candidate-first-pass harness that returns structured
   candidates, not only `corrected_text`.
3. Reuse existing local resolvers to turn those candidates into a
   `CorrectionResponse`.
4. Benchmark against the shared fixture strategy and the current staged
   baseline.
5. Add lazy explanation generation behind a UI/service boundary, without
   removing the existing Stage 3 path.
6. Add a feature flag or runtime switch between staged and simplified first
   pass.
7. Promote the simplified path only if it matches correction quality while
   materially reducing latency/request count/token usage.
8. Keep the staged pipeline available as fallback until saved-correction,
   dialectal-note, and explanation flows are proven stable.

## Final Decision

The staged pipeline should be simplified for first-pass correction, but replaced
carefully.

The recommended next implementation is not a production swap to the current
`corrected_text` model-comparison harness. It is a new candidate-generation
proof of concept that preserves local anchoring and reconstruction while
removing Stage 3 from the default first-pass path. If that proof of concept
performs well, it can become the new first-pass pipeline and the existing staged
pipeline can remain as a fallback or richer-review path.
