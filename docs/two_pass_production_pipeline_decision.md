# Two-Pass Correction Pipeline: Production Decision Record

Issue: [#44](https://github.com/Thow76/spanish_correction_app/issues/44)

Branch base: `correction_pipeline_refactor`

Scope: document the chosen implementation behavior for future work — no
prompt, merge/fallback, or production behavior changes.

## Status

**The two-pass architecture (parallel first-pass + naturalness calls,
deterministic merge, conflict-triggered fallback) is the chosen
production decision.** It is fully built, tested, and benchmarked
(issues #27-#87). It is **not yet wired into the live app** —
`OpenAiCorrectionService.correctText()` still calls the old, broader
`runStagedCorrectionPipeline` for Spanish (see
`lib/features/corrections/data/open_ai_correction_service.dart:47`).
Wiring it in is a separate, later decision, gated on the two targeted
prompt fixes this document's "Known Limitations" section recommends —
not on any further architectural change.

This document is the single canonical reference for how the pipeline
works. Everything below (final pipeline shape, merge rules, fallback
behavior) is the **settled mechanics** — changing any of it is an
architectural decision needing its own issue and its own update to this
document. Prompt wording tuning (e.g. the two follow-ups recommended
below) is separate, ongoing work that does **not** require revisiting
this document — see "Separating Prompt Work From This Decision" at the
end.

## Final Pipeline Shape

Entry point: `runTwoPassCorrectionPipeline` (`lib/features/corrections/data/two_pass_correction_pipeline.dart`).

```text
runTwoPassCorrectionPipeline(client, firstPassModel, naturalnessModel, submittedText)
  |
  |-- (parallel) callFirstPassCorrection(...)       -> firstPassResponse
  |-- (parallel) callNaturalnessReview(submittedText) -> parallelNaturalnessReview
  |
  v
mergeNaturalnessReview(originalText, firstPassResponse.correctedText, parallelNaturalnessReview)
  |
  |-- no skipped edits -> mapNaturalnessEditsIntoCorrectionResponse(...) -> done
  |
  |-- any skipped edits (conflict) -> fallback:
        callNaturalnessReview(firstPassResponse.correctedText)  -> fallbackNaturalnessReview
        mergeNaturalnessReview(originalText, firstPassResponse.correctedText, fallbackNaturalnessReview)
        mapNaturalnessEditsIntoCorrectionResponse(...) -> done (supersedes the parallel attempt entirely)
```

- **Pass 1** (`callFirstPassCorrection`, `lib/features/corrections/data/first_pass_correction_client.dart`,
  issues #64/#65): the narrow `{"corrected_text": "string"}` client —
  grammar/spelling/accents/punctuation only, no categories, spans, or
  explanations. Always returns a `CorrectionResponse` with an **empty
  `corrections` list** — see "Known Limitations" below.
- **Naturalness pass** (`callNaturalnessReview`,
  `lib/features/corrections/data/naturalness_review_client.dart`, issue
  #31): flags calques/idioms/collocations/regional-variety issues,
  returning `{span, natural_replacement, explanation}` entries. Called
  **twice per correction, at most**: once in parallel against the raw
  submitted text (fast path), and — only if that parallel merge
  conflicts — once more, sequentially, against the first pass's own
  corrected text (the fallback).
- **Merge** (`mergeNaturalnessReview`,
  `lib/features/corrections/domain/naturalness_merge.dart`, issue #32):
  see "Merge Rules" below.
- **Unification** (`mapNaturalnessEditsIntoCorrectionResponse`,
  `lib/features/corrections/domain/naturalness_correction_mapper.dart`,
  issue #36): combines the first pass's own `CorrectionItem`s (none,
  currently — see below) with naturalness-derived ones into a single
  `CorrectionResponse` — the same shape every other correction path in
  the app already returns, so no caller needs to special-case a two-pass
  result.

## Merge Rules

`mergeNaturalnessReview` is a deterministic, transport-free pure function
(no API client, no I/O) with one governing principle: **never guess**.
For each naturalness issue:

1. Locate `issue.span` in the first pass's corrected text by exact
   grapheme-cluster match (not UTF-16 code units — Spanish accents/ñ are
   each one match position, same convention the rest of the app uses).
2. **Not found anywhere** → skipped (`NaturalnessMergeSkipReason.spanNotFound`)
   — the naturalness pass and the first pass disagree about what the
   text says at that point (typically because the first pass already
   changed that exact wording).
3. **Found more than once** → skipped (`.ambiguousSpan`) — the
   naturalness contract has no `occurrence` field (issue #29), so there
   is no safe way to know which instance was meant.
4. **Found exactly once**, but its range overlaps an edit already
   accepted from an earlier, leftmost-starting issue in the same review
   → skipped (`.overlapsAnotherEdit`). Two candidates that start at the
   *exact same* position are both treated as conflicting (never
   guessed), since `List.sort` isn't stable and there's no principled
   winner between them.
5. Otherwise → applied.

This is deliberately the *minimum safe* merge, not full conflict
analysis (see issue #34) — it resolves ambiguity by skipping, never by
picking. `mapNaturalnessEditsIntoCorrectionResponse` layers first-pass
`CorrectionItem`s and naturalness-derived ones together the same way:
an overlap demotes the losing item's position data to null rather than
dropping it outright, since the edit still genuinely happened to the
text even if its highlight can't be shown.

## Fallback Behavior

The fallback is a **sequential rerun of the naturalness pass, called at
most once**, and only when the *parallel* merge left any skipped edits
at all:

1. Rerun `callNaturalnessReview` directly against the first pass's own
   corrected text (not the original) — this guarantees every span the
   model reports this time refers to the exact text being merged into,
   eliminating `spanNotFound` conflicts caused by the first pass having
   changed that wording.
2. Merge that fallback naturalness review the same way (same rules
   above).
3. The fallback's result **supersedes the parallel attempt entirely** —
   it is not combined with the parallel merge's own applied edits.

If the fallback naturalness review is *still* ambiguous or unresolvable
against the same text (the "still unsafe after a rerun" case, issue
#37) — the edit is never applied. A rerun earns another chance to
become safe; it is not a bypass of the same safety rules that
originally skipped it.

## Known Limitations

- **No first-pass `CorrectionItem`s.** `callFirstPassCorrection`'s bare
  `{"corrected_text": "string"}` contract carries no spans, categories,
  or explanations, so the unified response's `corrections` list only
  ever contains naturalness-derived items. Final corrected text is the
  current production output; correction cards/highlights are a later
  product step, gated on this POC's results — not solved here. See
  `docs/first_pass_correction_poc_scope.md` (issue #71) for the full
  boundary.
- **First pass sometimes overcorrects text it should leave alone.** The
  live benchmark (issue #87, `docs/two_pass_live_language_point_benchmark_findings.md`)
  found the first pass inserting an unnecessary article into valid
  regional Spanish (`Voy para casa` → `Voy para la casa`) despite its
  own prompt explicitly saying not to change valid regional Spanish.
  Reproduced identically across two separate live runs. 1/5 in the
  `Valid Regional / Should Not Flag` benchmark group (`regional-voy-para-casa`).
  The `Already Correct / Do Not Tinker` group's own single overcorrection
  (`correct-tomar-foto`) is a *different* fixture with a different
  cause — the first pass left it unchanged, correctly; naturalness is
  what overcorrected it — see the next two bullets, not this one.
- **Naturalness sometimes re-edits text the first pass already fixed
  correctly**, producing an unwanted second, unrequested change (e.g.
  `Atendió la universidad` → first pass correctly produces `Asistió a la
  universidad`, matching the expected fix exactly — naturalness then
  rewrites it again to `Estudió en la universidad`, a different and less
  precise correction). Reproduced identically across two separate live
  runs. See `docs/two_pass_live_language_point_benchmark_key_findings_by_group.md`
  for every group this affected (Accents / Diacritics, Subjunctive /
  Mood, False Friends / Word Choice, Mixed Operations, and Ambiguous /
  Repeated Span Safety all show this same pattern).
- **Naturalness sometimes returns multiple slash-separated alternatives
  instead of one corrected text** (e.g. `Quiero pasarlo bien / pasar un
  buen rato.`) — a real output-format defect distinct from the two
  restraint issues above, found while manually reviewing the
  `Phrase-Level Naturalness` and `Already Correct / Do Not Tinker`
  benchmark groups (`docs/two_pass_live_language_point_benchmark_issue_log.md`).
  The app needs one unified corrected text; this needs its own fix.
- **The benchmark's exact-match scoring likely overstates the true
  defect rate.** Of the 85-fixture live run's 15 non-`correct_fix`/
  `acceptable_no_change` results, several spot-checked cases turned out
  to be genuinely valid alternative phrasing (Spanish's pro-drop
  grammar, equally natural synonym choices) that the benchmark has no
  `acceptableAlternatives` entry to credit — not real pipeline defects.
  See the "Scoring Caveat" section of `docs/two_pass_live_language_point_benchmark_findings.md`.
- **Article insertion with more than one missing article in the same
  sentence is unreliable.** `article-cita-medico` (needing both `una
  cita` and `el médico` inserted) only got one of the two fixes.

## Benchmark Results

Full detail lives in three documents (not duplicated here):

- `docs/two_pass_live_language_point_benchmark_findings.md` (issue #87)
  — the primary results doc: score-label totals, language-point
  breakdowns, latency/token/cost/conflict/fallback data, baseline
  comparison, and the continue/fix/reject recommendation.
- `docs/two_pass_live_language_point_benchmark_key_findings_by_group.md`
  — a per-language-point-group pass/fail breakdown with a first-pass vs.
  naturalness/fallback signal for each group.
- `docs/two_pass_live_language_point_benchmark_issue_log.md` — a
  per-fixture log of every case that didn't clearly pass, with what
  happened and a specific follow-up for each.

Headline numbers, for convenience: **0 errors across 104 total live
fixture-runs** (a 19-fixture sample plus the full 85-fixture benchmark),
**78.8% unambiguous success** (`correct_fix` + `acceptable_no_change`),
**3.5% unambiguous failure** (`overcorrection`; 0 `missed_issue`), and
per-fixture cost/token/latency all improved versus both the pre-#64
staged-pipeline baseline and the original 5-fixture confirmation run —
holding up (and improving slightly) at 17x the fixture count. Full
comparison table in the findings doc.

## Recommendation

**Continue the two-pass POC as the production direction.** The evidence
does not support rejecting it (reliability and cost/latency wins are
strong and reproducible) or redesigning the architecture (every finding
above traces to prompt-level restraint, not to the merge, fallback, or
orchestration mechanics). It also isn't a "continue with zero further
work" case — see the targeted follow-ups below.

## Separating Prompt Work From This Decision

This document's "Final Pipeline Shape," "Merge Rules," and "Fallback
Behavior" sections describe **mechanics that are settled** — they were
exercised, unchanged, across the entire benchmark and every finding
above. The recommended next steps are deliberately **prompt-wording
changes only**, tracked as their own follow-ups, and none of them
require touching this document's settled sections:

1. Tighten `firstPassCorrectionSpanish`'s restraint language around
   valid regional Spanish and already-correct input.
2. Tighten `naturalnessReviewSpanish` so it does not re-edit a span the
   first pass already fixed correctly.
3. Prohibit slash-separated alternatives in the naturalness pass's
   `natural_replacement`/final corrected text.
4. Add `acceptableAlternatives` to specific benchmark fixtures where
   manual review confirms the pipeline's output was a valid Spanish
   variant, not a defect.

If a future prompt change turns out to need a mechanics change too (e.g.
a new merge rule, a different fallback trigger condition) — that's a new
architectural decision, and this document should be updated to reflect
it. Until then, prompt iteration and this document's settled sections
are independent: a prompt-only PR should never need to touch "Final
Pipeline Shape," "Merge Rules," or "Fallback Behavior" above.

## Files In Scope For This Documentation

```text
lib/features/corrections/data/two_pass_correction_pipeline.dart
lib/features/corrections/data/first_pass_correction_client.dart
lib/features/corrections/data/naturalness_review_client.dart
lib/features/corrections/domain/naturalness_merge.dart
lib/features/corrections/domain/naturalness_correction_mapper.dart
docs/two_pass_live_language_point_benchmark_findings.md
docs/two_pass_live_language_point_benchmark_key_findings_by_group.md
docs/two_pass_live_language_point_benchmark_issue_log.md
docs/first_pass_correction_poc_scope.md
```

No behavior changes were made as part of this issue.
