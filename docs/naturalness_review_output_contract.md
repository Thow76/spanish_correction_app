# Naturalness Review Output Contract

Issue: [#29](https://github.com/Thow76/spanish_correction_app/issues/29)

Branch base: `correction_pipeline_refactor`

Scope: confirm the existing contract and capture gaps against production
needs. Prompt wording unchanged; no behavior changes.

## The Contract

The gpt-5.1 naturalness pass (`test/naturalness_model_comparison_harness.dart`)
returns:

```json
{
  "has_naturalness_issue": true,
  "issues": [
    {
      "span": "string",
      "natural_replacement": "string",
      "explanation": "string"
    }
  ]
}
```

For no issue: `{"has_naturalness_issue": false, "issues": []}`. Confirmed
against the API-level schema (`naturalnessResponseFormat`, line 119) and the
local double-check parser (`parseNaturalnessResponse`, line 407), both in
`test/naturalness_model_comparison_harness.dart`. The parser additionally
cross-checks the boolean against the array — `has_naturalness_issue: false`
with a non-empty `issues`, or `true` with an empty `issues`, is rejected as
invalid (lines 465-470) — so the two fields can't disagree.

As with the first-pass contract (`docs/first_pass_corrected_text_output_contract.md`,
issue #28), this exists only in the test harness today. No `lib/` production
code consumes it yet — issue #30 ("Add typed naturalness review domain
models") is the tracked follow-up for that.

## Can The Harness Output Be Consumed By Production Code As-Is?

Not without a gap. Comparing this contract against how the app's *existing*
first-pass anchoring already works surfaces two mismatches:

### 1. No `occurrence` field — can't disambiguate a repeated span

Every existing anchoring mechanism in this app depends on knowing which
instance of a flagged phrase is meant when it appears more than once in the
text:

- Stage 2's own contract requires it explicitly:
  `stage2CategorizationSpanish` (`correction_prompt.dart:308`) — *"occurrence
  is which instance of this exact original_phrase in the learner's text you
  are correcting... If the phrase appears only once, occurrence is 1."*
- `resolveOccurrenceCorrections` (`domain/correction_original_range_resolver.dart:72`)
  is built entirely around that: it finds every grapheme-safe match of a
  phrase and picks the one at `occurrence - 1`, and silently drops the
  correction if `occurrence` doesn't correspond to an existing match.

The naturalness contract's `issues[].span` has no equivalent field. If the
same span text appears more than once in the reviewed text (a common case —
short calques like `hacer una decisión` or `llamar para atrás` can recur),
there is nothing in the contract that says which occurrence the model means.
Production code following the app's own established anchoring pattern would
have no way to resolve `span` to a single position without guessing (e.g.
always taking the first match), which is a real risk of anchoring the
naturalness note to the wrong occurrence.

### 2. No `span_scope` — can't tell how much of the span to highlight

Stage 2's Natural Language category carries a `span_scope` of `exact` or
`full` (`StagedCorrectionSpanScope`, `domain/staged_correction_span_scope.dart`) —
whether only the changed words within the quoted phrase should stay
highlighted, or the entire phrase must, because it's a fixed
collocation/clause that doesn't decompose. Naturalness issues are exactly
this same kind of correction (calques, idioms, collocations — the category
the two-pass handoff doc explicitly hands to the naturalness pass), but the
harness contract has no equivalent field. Production code would have no
signal for this and would have to either guess a default or add its own
heuristic.

## What This Means (without touching the prompt)

Both gaps are about the contract's *shape*, not the naturalness judgment
itself — the prompt's naturalness detection logic is out of scope here per
the issue's acceptance criteria, and neither gap is fixed in this change.
Captured for follow-up (likely landing in issue #30's domain modeling or a
prompt-versioning follow-up, not this issue):

- Production anchoring needs either an `occurrence` field added to the
  contract, or a documented fallback rule (e.g. "always the first
  occurrence") accepted as a known limitation.
- Production highlighting needs either a `span_scope`-equivalent field, or a
  documented default (e.g. always treat the whole `span` as `full`).

## Files In Scope For This Confirmation

```text
test/naturalness_model_comparison_harness.dart
lib/core/services/prompts/correction_prompt.dart
lib/features/corrections/domain/correction_original_range_resolver.dart
lib/features/corrections/domain/staged_correction_span_scope.dart
docs/spanish_two_pass_prompt_handoff.md
docs/first_pass_corrected_text_output_contract.md
```

No behavior changes were made as part of this issue.
