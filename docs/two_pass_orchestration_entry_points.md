# Two-Pass Correction Pipeline: Entry Points

Issue: [#27](https://github.com/Thow76/spanish_correction_app/issues/27)

Branch base: `correction_pipeline_refactor`

Scope: mapping only. No behavior changes.

## Current Call Chain (Spanish)

```text
SubmitCorrectionUseCase.execute(...)
  -> CorrectionService.correctText(text, Language.spanish)   [interface, application/correction_service.dart]
  -> OpenAiCorrectionService.correctText(...)                [data/open_ai_correction_service.dart:43]
  -> OpenAiCorrectionService._correctSpanishTextViaStagedPipeline(text)  [:97]
  -> runStagedCorrectionPipeline(...)                        [data/staged_correction_pipeline.dart:32]
```

`runStagedCorrectionPipeline` already runs Stage 1/1B/1C detection, Stage 2
categorization, local positioning/reconstruction, and Stage 3 feedback, then
returns a single `CorrectionResponse`. This whole chain is the first pass
referenced throughout the two-pass design docs
(`docs/spanish_two_pass_prompt_handoff.md`).

Note: `staged_correction_pipeline.dart`'s own doc comment (lines 29-31) says
it is "not called from `correctText()`... wiring the staged pipeline into the
app is separate, later work." That is now stale — `correctText()` calls it
directly for Spanish via `_correctSpanishTextViaStagedPipeline`. Worth fixing
that comment separately; not touched here to keep this issue mapping-only.

## Where Two-Pass Orchestration Should Live

`_correctSpanishTextViaStagedPipeline` is the seam. Today it only forwards to
`runStagedCorrectionPipeline` and translates exceptions
(`ChatCompletionsException` / `FormatException`) into
`CorrectionServiceException`. It is the single call site between the stable
`CorrectionService` interface and the staged pipeline, so it's the natural —
and only — place that needs to change to add a second pass:

```text
_correctSpanishTextViaStagedPipeline(text)
  -> runStagedCorrectionPipeline(...)        // first pass, unchanged (issue #37)
  -> <naturalness review client>(correctedText)   // new, issue #31
  -> <two-pass merge component>(firstPass, naturalness)  // new, issue #32
  -> CorrectionResponse                       // merged result
```

Recommendation: add a new orchestrator (e.g.
`runTwoPassCorrectionPipeline` in a new `data/two_pass_correction_pipeline.dart`,
mirroring how `staged_correction_pipeline.dart` itself composes the Stage
1-3 clients) rather than growing `runStagedCorrectionPipeline` in place. That
keeps the first-pass function callable and testable on its own (it already
has its own tests/fixtures), and keeps the merge/conflict logic in one place
that `_correctSpanishTextViaStagedPipeline` calls instead of
`runStagedCorrectionPipeline` once the second pass is ready. Until that
switch is made, `_correctSpanishTextViaStagedPipeline` keeps calling
`runStagedCorrectionPipeline` directly — today's behavior is unchanged.

## Affected Domain Types

- `CorrectionResponse` (`domain/correction_response.dart`) — the merge
  result's shape. It already has a `notes` field (`List<CorrectionNote>`)
  separate from `corrections` (`List<CorrectionItem>`), which is the existing
  precedent for carrying non-error feedback (currently used for dialectal
  notes from Stage 2/3) — naturalness output may fit the same slot, or may
  need its own list depending on how issue #36 (map naturalness edits into
  unified correction items) resolves.
- `CorrectionItem` (`domain/correction_item.dart`) — whatever the merge
  produces has to end up as `CorrectionItem`s anchored to the first-pass
  `correctedText`, since that's what the app's save/highlight/reconstruction
  code already consumes.
- New types needed for the naturalness side (issues #29, #30): domain models
  for the naturalness client's response shape documented in
  `docs/spanish_two_pass_prompt_handoff.md` (`has_naturalness_issue`,
  `issues[].{span, natural_replacement, explanation}`) — these don't exist
  in `domain/` yet.
- Existing span/overlap resolvers (`staged_correction_overlap_resolver.dart`,
  `staged_correction_span_scope.dart` and friends) are candidates to reuse
  for merge-conflict detection (issue #34), since they already solve
  "does this span overlap with an already-decided one" for the first pass.

## Files In Scope For This Mapping

```text
lib/features/corrections/data/staged_correction_pipeline.dart
lib/features/corrections/data/stage1_detection_client.dart
lib/features/corrections/data/open_ai_correction_service.dart
lib/features/corrections/domain/correction_response.dart
lib/features/corrections/application/correction_service.dart
lib/features/corrections/application/submit_correction_use_case.dart
```

No behavior changes were made as part of this issue.
