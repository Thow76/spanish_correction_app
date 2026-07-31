# Live Two-Pass Integration Harness: Summary

Issue: [#42](https://github.com/Thow76/spanish_correction_app/issues/42)

Branch base: `correction_pipeline_refactor`

## What This Adds

`test/two_pass_integration_harness.dart` — a live harness that measures the
real, already-built two-pass pipeline (`runStagedCorrectionPipeline` +
`callNaturalnessReview` + `mergeNaturalnessReview` +
`mapNaturalnessEditsIntoCorrectionResponse`, the same production functions
`runTwoPassCorrectionPipeline` itself calls) across 5 fixtures chosen to
exercise: a grammar-only fix, a naturalness-only fix, grammar and
naturalness in independent spans, grammar overlapping a naturalness span
(the case the fallback exists for), and an ambiguous naturalness span. For
every fixture it calls naturalness on both the original text and the first
pass's own corrected text, unconditionally, so the two can be compared
directly — unlike production, which only calls the second one on conflict.

Run offline (no API calls): `flutter test test/two_pass_integration_harness.dart --exclude-tags live`
Run live: see the file's own header comment for the full command and env vars.

## Result: A Real Production Reliability Finding

The live run did not produce the intended comparison data, because
**every single naturalness call — 5/5 fixtures, reproduced twice in a row
— failed to parse**, with `FormatException: Naturalness review is missing
"has_naturalness_issue".`

### Root Cause

Confirmed with one isolated diagnostic call (`client.complete()` directly,
bypassing all parsing) against gpt-5.1 with the exact production prompt
and transport: the raw model reply was

```json
{"issues":[{"original":"Vi mucho trafico ayer.","suggestions":["...","...","..."],"explanation":"..."}]}
```

— not the required `{"has_naturalness_issue": bool, "issues":
[{"span", "natural_replacement", "explanation"}]}` shape at all. The model
invented its own reasonable-looking field names (`original`/`suggestions`
instead of `span`/`natural_replacement`) and omitted
`has_naturalness_issue` entirely.

This is because **`naturalnessReviewSpanish`, the production system
prompt, never states the required JSON key names anywhere in its own
text** — it only says "Return JSON only." The naturalness *harness*
(`naturalness_model_comparison_harness.dart`, issue #41's target) uses the
exact same prompt text but additionally sends `response_format:
json_schema` with `strict: true`, which is what actually constrains the
model's output to the right shape — not the prompt. The *production*
client (`callNaturalnessReview`, issue #31) deliberately does **not** set
`response_format`, matching every other stage client in the staged
pipeline (none of which use structured outputs). That choice is safe for
Stage 1/1B/1C/2/3, whose prompts DO spell out the exact JSON shape in their
own text — but the naturalness prompt never got that same treatment, so
without `response_format` backing it up, gpt-5.1 has nothing constraining
it to the specific field names the parser requires.

**This means `callNaturalnessReview`, as currently built, does not
reliably work against the live API today** — every call in this
experiment failed the same way. This is a pre-existing gap from issue
#31, not something introduced by this issue's own work; #42's job was to
measure the real integration, and this is what that measurement found.

### What Was Verified, Not Just Asserted

- Reproduced twice independently (a full 5-fixture run, then confirmed via
  one isolated diagnostic call) — not a one-off flake.
- The harness's own error handling was hardened twice as part of this
  work. First pass: it originally let one fixture's failure crash the
  whole run and silently reported $0 spent; it was changed to catch
  failures per fixture and keep data for every other fixture. Second
  pass, after review: that first fix still under-reported spend for the
  *failing* call itself — `naturalOriginalStats`/etc. were only folded
  into the running total *after* their `await` succeeded, so a call that
  got a valid, billed HTTP response and only then threw while *parsing*
  it (exactly what every failure in this run was) never had its own
  tokens counted. Fixed by recording each phase's stats in a `finally`
  block (`_trackedCall`) instead, so that happens on success or failure
  alike. See the file's `FixtureResult.error` and the `_trackedCall`
  offline tests covering both paths.

### Cost Note

The generated `docs/two_pass_integration_harness.md` (from the run made
with the original, doubly-unfixed harness) shows `$0.000000` in its
totals — a known reporting gap from that point in time, now fixed (see
above), not a claim that nothing was spent. Based on the visible token
usage during both live attempts plus the one diagnostic call, actual
spend was on the order of **$0.05-0.08** (mostly gpt-4.1 first-pass
Stage 2 calls, which are the most token-heavy part of each fixture). A
future run with the now-fully-fixed harness will report this accurately.

## Recommendation

File a follow-up issue: give `callNaturalnessReview` the same
`response_format: json_schema` structured-output enforcement the
exploratory harness already uses (or equivalently, make
`naturalnessReviewSpanish` explicitly state the required field names in
its own text) — until one of those lands, the two-pass pipeline's
naturalness pass cannot be trusted in production. Not fixed here: #42's
scope is measurement, and this finding needs its own review.

## Acceptance Criteria

- "A live harness can run the complete two-pass experiment." — Yes: it ran
  all 5 fixtures, start to finish, without crashing (after the resilience
  fix), and produced a report.
- "Results are written to docs or console output in the existing benchmark
  style." — Yes: `docs/two_pass_integration_harness.md`, in the same
  per-fixture-detail-plus-aggregate-summary style as this repo's other
  harness reports.

No naturalness prompt or `callNaturalnessReview` changes were made as part
of this issue — only the new harness itself.
