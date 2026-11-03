# Simple First-Pass Correction: POC Scope And Deferred Work

Issue: [#71](https://github.com/Thow76/spanish_correction_app/issues/71)

Branch base: `correction_pipeline_refactor`

Scope: documentation only. No behavior changes.

## Why This Document Exists

Issues #64-#70 wired a narrow, `corrected_text`-only first-pass client
(`callFirstPassCorrection`, `lib/features/corrections/data/first_pass_correction_client.dart`)
into the live two-pass orchestrator (`runTwoPassCorrectionPipeline`,
`lib/features/corrections/data/two_pass_correction_pipeline.dart`), replacing
the old broad `runStagedCorrectionPipeline` as pass 1.

That client's contract is intentionally minimal:

```json
{ "corrected_text": "string" }
```

No spans, categories, explanations, or dialectal notes — so
`callFirstPassCorrection` always returns a `CorrectionResponse` with an
**empty `corrections` list**, even when the corrected text visibly differs
from the original. A future reader who notices this — e.g. while looking at
`two_pass_correction_pipeline_test.dart`'s assertions, or at a live
two-pass response with no first-pass correction cards — should not read it
as a bug or an accidental regression. This document says so plainly, and
records what the POC is and isn't trying to prove.

This intentionally narrows (does not contradict) the earlier architecture
review in `docs/first_pass_correction_architecture_review.md` (issue #4).
That review recommended against wiring a bare `corrected_text`-only first
pass into *production* without a separate diff-and-classification strategy,
and recommended a richer single candidate-generation call (its "Option C")
as the eventual production target instead. Issues #64-#70 do not attempt
that — they wire the bare contract in behind the existing
`runTwoPassCorrectionPipeline` orchestrator specifically to measure it, not
to ship it as the final first-pass design. See "What This POC Is Not" below.

## What This POC Is Measuring

The POC's success criteria — what issues #64-#70 exist to gather evidence
for — are:

- **Reliability**: does the model return valid, schema-conformant JSON
  consistently (`response_format` + `strict: true`, same protection added to
  the naturalness pass after issue #42's live failure)?
- **Latency**: how much faster is one narrow call than the old pipeline's
  three-to-five staged calls (Stage 1/1B/1C detection, Stage 2
  categorization, Stage 3 feedback)?
- **Fallback rate**: with a genuinely narrow first pass (not the staged
  pipeline's broader Stage 2/3 behavior, which already does naturalness-style
  rewrites — the root cause identified in the pre-#64 investigation), does
  the two-pass merge's conflict/fallback rate drop to something closer to
  "only when the first pass touches naturalness-relevant wording," instead of
  triggering on ordinary first-pass corrections?
- **Token use and cost**: one call and one prompt versus the staged
  pipeline's multiple calls and longer, multi-concern prompts.

`test/two_pass_integration_harness.dart` (issue #42, updated for the simple
first pass in issue #68) is the instrument for gathering this evidence: it
records latency/tokens/cost per phase per fixture, and reports
conflict/fallback counts across the fixture set.

**Final corrected text quality** is the other primary measurement output —
whether the merged `correctedText` a learner would see is at least as good
as the staged pipeline's, even without any first-pass correction cards to
show alongside it.

## What This POC Is Not

- **Not** a decision to ship first-pass correction cards/highlights with no
  data behind them. The live app's correction UI (highlight spans, the
  correction detail sheet, saved-correction cards) still expects
  `CorrectionItem`s with `shortExplanation`, `category`, and anchored
  ranges — none of which `callFirstPassCorrection` produces. Wiring this POC
  further into `OpenAiCorrectionService.correctText(...)` (the real live
  app path) is explicitly out of scope for #64-#71 alike; see each issue's
  own "Out of scope" section.
- **Not** an attempt to reconstruct first-pass `CorrectionItem`s by diffing
  `originalText` against `correctedText` after the fact. The earlier
  architecture review (issue #4) already flagged mechanical diffing as
  "fragile around repeated phrases, insertions, deletions, accents, and
  reordered text" — that risk hasn't been re-evaluated or resolved here, so
  reconstruction stays deferred rather than attempted with a fragile diff.
- **Not** a replacement decision. The staged pipeline
  (`runStagedCorrectionPipeline`) is untouched, still fully tested
  (`staged_correction_pipeline_test.dart` and friends), and still the only
  path actually wired into `OpenAiCorrectionService.correctText(...)` for
  live Spanish corrections today.

## If The POC Succeeds

Producing first-pass correction cards/highlights, wiring this path into
`OpenAiCorrectionService.correctText(...)`, and any resulting UI changes are
later product steps, gated on this POC's measured results (reliability,
latency, fallback rate, cost, and text quality) actually looking better than
the staged pipeline's — not assumed in advance. Candidate approaches for
that later step, if it happens, were already sketched in
`docs/first_pass_correction_architecture_review.md`'s "Option C" (a richer
single candidate-generation call, returning `original_phrase` /
`corrected_phrase` / `occurrence` / `category` rather than diffing raw text) —
revisit that document rather than starting from scratch.

## Files In Scope For This Documentation

```text
lib/features/corrections/data/first_pass_correction_client.dart
lib/features/corrections/data/two_pass_correction_pipeline.dart
docs/first_pass_corrected_text_output_contract.md
```

No behavior changes were made as part of this issue.
