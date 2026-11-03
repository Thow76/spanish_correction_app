# First-Pass `corrected_text` Output Contract

Issue: [#28](https://github.com/Thow76/spanish_correction_app/issues/28)

Branch base: `correction_pipeline_refactor`

Scope: confirm the existing contract and how it's handled today. Prompt
wording unchanged; no behavior changes.

**Status update (issue #71)**: the "no `lib/` production code implementing
this narrow first-pass call yet" note below is now stale. Issues #64-#70
added a production client for this exact contract
(`callFirstPassCorrection`, `lib/features/corrections/data/first_pass_correction_client.dart`)
and wired it into `runTwoPassCorrectionPipeline` as a proof of concept. See
`docs/first_pass_correction_poc_scope.md` for what that POC is and isn't
measuring, and why an empty `corrections` list from that client is expected,
not a bug.

## The Contract

The narrow gpt-4.1-family first pass (grammar/spelling/punctuation only —
see `docs/spanish_two_pass_prompt_handoff.md`) returns exactly one field:

```json
{ "corrected_text": "string" }
```

No categories, explanations, spans, error counts, confidence scores, or
alternative rewrites — confirmed by the harness's own header comment in
`test/model_comparison_harness.dart:13-17`.

This contract currently exists only in `test/model_comparison_harness.dart`.
There is no `lib/` production code implementing this narrow first-pass call
yet — the live Spanish path is still the broader staged pipeline
(`runStagedCorrectionPipeline`, see `docs/two_pass_orchestration_entry_points.md`,
issue #27). Whatever eventually wires this contract into production (the
future two-pass orchestrator) will need its own handling; the harness's
handling described below is a reference, not a production implementation.

## Where It's Enforced Today

Two layers, both in `test/model_comparison_harness.dart`:

1. **API-level**: `correctedTextResponseFormat` (line 179) is passed as
   `response_format: json_schema` with `strict: true`,
   `additionalProperties: false`, and `required: ['corrected_text']` —
   OpenAI itself is asked to guarantee the shape.
2. **Local double-check**: `_parseCorrectedTextResponse` (line 475)
   re-validates independently of the API's own guarantee — it requires the
   reply to decode as a JSON object with *exactly* one key,
   `corrected_text`, whose value is a `String`. This exists because the
   harness is explicitly measuring JSON reliability across models, some of
   which may not honor `strict` mode (or may not support structured outputs
   at all).

## How Malformed Or Missing `corrected_text` Is Handled Today

Two distinct failure paths, kept separate on purpose:

- **Transport-level failure** (non-2xx HTTP status, non-JSON response root,
  missing `choices`/`message`/`content`): raised as an exception inside
  `_runOnce`'s try block (`extractReplyText`, line 433, throws
  `FormatException` for these), caught by the surrounding try/catch, and
  recorded via `_errorResult` (line 648) as `_ReviewStatus.error`.
- **Schema-level failure** (reply is valid transport-wise but not the
  required JSON shape — not JSON at all, `corrected_text` missing, extra
  fields present, or `corrected_text` present but not a string):
  `_parseCorrectedTextResponse` never throws; it returns
  `_ParsedResponse(validJson: false)`. `_classifyFirstPassOutput` (line 564)
  then maps `!validJson || correctedText == null` to
  `_ReviewStatus.invalidJson`, which rolls up into the harness's
  `validJsonRate` aggregate metric per model.

Both paths are already covered by existing tests (`test/model_comparison_harness.dart`,
the `_parseCorrectedTextResponse` test group, ~line 1560 onward): not-JSON
replies, missing `corrected_text`, extra fields, non-string `corrected_text`,
and empty reply text are all asserted to produce `validJson: false`.

## Parser Gap Found (for follow-up)

`{"corrected_text": ""}` — a schema-valid JSON object whose `corrected_text`
is an empty string — is **not** covered by any existing test, and currently
parses as `validJson: true`, `correctedText: ''`. For any fixture with
non-empty input, an empty `corrected_text` almost certainly means the model
discarded the text rather than corrected it, but nothing in
`_parseCorrectedTextResponse` or `_classifyFirstPassOutput` treats this as
suspect: it either falls through to `_ReviewStatus.unexpectedCorrection`
(scored fixtures) or `_ReviewStatus.unscored` (unscored fixtures) — the
latter silently passes through with no flag at all.

Follow-up recommendation: either the harness parser or the eventual
production consumer of this contract should treat an empty `corrected_text`
against non-empty input as invalid/suspect rather than an ordinary miss.
Not fixed here — this issue is confirm-and-document only, per its
acceptance criteria.

## Files In Scope For This Confirmation

```text
test/model_comparison_harness.dart
docs/spanish_two_pass_prompt_handoff.md
docs/two_pass_orchestration_entry_points.md
```

No behavior changes were made as part of this issue.
