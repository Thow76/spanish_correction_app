# Two-Pass Live Language-Point Benchmark: Findings

Issue: [#87](https://github.com/Thow76/spanish_correction_app/issues/87)

Branch base: `correction_pipeline_refactor`

Scope: run the live benchmark built by #81-#86 and record findings. No
prompt, merge/fallback, or production behavior changes.

## What Was Run

Two live runs, in sequence, per this issue's own scope ("run a small
live sample first... if the sample is stable, run the full
language-point benchmark"), both using `gpt-4.1` (first pass) /
`gpt-5.1` (naturalness):

1. **Sample** — one fixture per language point (issue #85's `sample`
   selection mode, `TWO_PASS_SAMPLE_SIZE=1`), 19 fixtures, ~57 API calls:

   ```bash
   OPENAI_API_KEY=*** TWO_PASS_LIVE=true \
     TWO_PASS_FIXTURE_SET=sample TWO_PASS_SAMPLE_SIZE=1 \
     TWO_PASS_OUTPUT=docs/two_pass_language_point_benchmark_sample.md \
     flutter test test/two_pass_integration_harness.dart --tags live --timeout none
   ```

   Report: `docs/two_pass_language_point_benchmark_sample.md`.

2. **Full benchmark** — every fixture (issue #82's full language-point
   matrix plus the original smoke set), 85 fixtures, ~255 API calls,
   run after the sample came back with 0 errors:

   ```bash
   OPENAI_API_KEY=*** TWO_PASS_LIVE=true \
     flutter test test/two_pass_integration_harness.dart --tags live --timeout none
   ```

   Report: `docs/two_pass_integration_harness.md` (this harness's usual
   output path — overwritten with this run's data, per that file's own
   long-standing convention of reflecting the most recent run).

## Reliability

**0 errors across both runs (19/19, then 85/85)** — every first-pass and
naturalness call returned valid, schema-conformant JSON. No parse
failures, no transport errors. This is the same clean reliability record
the 5-fixture confirmation runs (`docs/two_pass_live_harness_simple_first_pass_confirmation.md`,
issue #72) already established, now confirmed across a benchmark 17x
larger and covering many more distinct grammatical/lexical patterns.

## Score Summary (Full Run, 85 Fixtures)

| Score | Count | Rate |
| --- | --- | --- |
| correct_fix | 56 | 65.9% |
| acceptable_no_change | 11 | 12.9% |
| ambiguous | 11 | 12.9% |
| partial_fix | 4 | 4.7% |
| overcorrection | 3 | 3.5% |
| missed_issue | 0 | 0% |
| error | 0 | 0% |

Combining the two unambiguous "success" labels (`correct_fix` +
`acceptable_no_change`): **67/85 fixtures (78.8%) fully succeeded.**
Combining the two unambiguous "failure" labels (`overcorrection` +
`missed_issue`): **3/85 (3.5%) unambiguously failed.** The remaining
15/85 (17.6%, `partial_fix` + `ambiguous`) are the cases that need a
closer look — see "A Scoring Caveat" below before reading these as pure
pipeline defects.

## Weak Language Points

Scoring each language-point group by its "fully succeeded" rate
(`correct_fix` + `acceptable_no_change`, out of that group's fixture
count — see the full per-group table in `docs/two_pass_integration_harness.md`'s
"Language point summary"):

| Language point | Fully succeeded | Rate |
| --- | --- | --- |
| False Friends / Word Choice | 2/5 | 40% |
| Phrase-Level Naturalness | 2/5 | 40% |
| Mixed Operations | 2/5 | 40% |
| Valid Regional / Should Not Flag | 4/5 | 80% |
| Already Correct / Do Not Tinker | 4/5 | 80% |
| Articles / Determiners | 3/5 | 60% |
| Unnecessary Extras / Deletions | 3/5 | 60% |
| Subjunctive / Mood | 4/5 | 80% |
| *(remaining 8 language points)* | 5/5 each | 100% |

The 10 purely mechanical first-pass categories (accents, gender/number
agreement, verb agreement, prepositions, required additions/omissions,
ser/estar/haber, impersonal haber/se, collocations, plus the 3 original
combined smoke fixtures) all scored at or near 100%. The weak spots are
concentrated in exactly the categories this two-pass split was designed
around: lexical/naturalness judgment calls, and fixtures that require
more than one correction at once.

## Recurring Failure Modes

Two concrete, reproducible defects — not one-off model noise — surfaced
in **both** the sample and the full run:

### 1. First pass overcorrects text it should leave alone

`regional-voy-para-casa` (`Voy para casa ahora mismo.` — valid regional
Spanish, expected unchanged) came back as `Voy para **la** casa ahora
mismo.` in the sample run — the *first pass itself* inserted an
unnecessary article into grammatically valid regional Spanish. This is
a real boundary violation: the first-pass prompt (`firstPassCorrectionSpanish`)
says to correct only objective grammar/spelling/punctuation and
explicitly "not [to] change valid regional Spanish," but nothing
stops it from doing so on some inputs. The `Valid Regional / Should Not
Flag` and `Already Correct / Do Not Tinker` groups each had exactly one
`overcorrection` in the full run (4/5 correctly left alone, 1/5 not) —
consistent with a real, if infrequent, failure mode rather than a fluke.

### 2. Naturalness sometimes re-edits text the first pass already fixed correctly

`false-friend-atendio-universidad` in the sample run: the first pass
correctly produced `Asistió a la universidad en Madrid.` — an exact
match to the expected output — but the naturalness pass then flagged
that *already-correct* text anyway and rewrote it to `Estudió en la
universidad en Madrid.`, a different (and arguably less precise)
correction. The merge/fallback mechanics did exactly what they're
supposed to here (there was a genuine second-pass suggestion to
evaluate), but the naturalness prompt itself has no signal that a span
is already a confirmed-correct fix rather than raw input needing review.

Both failure modes point at prompt-level restraint, not at the two-pass
orchestration, merge, or fallback logic — none of which needed a single
change to produce these results.

## A Scoring Caveat: `ambiguous`/`partial_fix` Likely Overstates Real Defects

11 `ambiguous` and 4 `partial_fix` results (15/85, 17.6%) is the largest
non-success bucket — larger than the two confirmed overcorrection
failures combined. Spot-checking several of these against the actual
generated report (`docs/two_pass_integration_harness.md`) shows a mix of
two distinct things, not one:

- **Genuinely valid alternative phrasing**, which a stricter benchmark
  would credit as correct: `naturalness-corriendo-tarde` produced `Voy a
  llegar tarde a la reunión.` against an expected `Voy tarde a la
  reunión.` — both mean "I'm going to be late to the meeting."
  `delete-repeated-ellos-visitaron` produced `Viajaron a México y
  visitaron varias ciudades.` (dropping the subject pronoun entirely,
  relying on verb conjugation) against an expected `Ellos viajaron a
  México y visitaron varias ciudades.` (keeping the first "Ellos," only
  removing the redundant second one) — Spanish's pro-drop grammar makes
  the produced version equally correct, just a different stylistic
  choice. Neither of these fixtures has `acceptableAlternatives`
  populated (issue #81/#82 deliberately left this empty rather than
  fabricate unverified alternatives — see those issues' own doc
  comments), so `scoreFixtureResult` (issue #83) has no way to credit a
  valid-but-different phrasing as `correct_fix`.
- **A genuine, if minor, partial miss**: `article-cita-medico`
  (`Tengo cita con médico mañana.`, expecting two article insertions —
  `una cita` and `el médico`) came back as `Tengo cita con el médico
  mañana.` — the first pass caught the second missing article but not
  the first, in the same sentence. This is a real (small) reliability
  gap in a sentence needing more than one insertion, not a scoring
  artifact.

This means the true defect rate is likely somewhere between the 3.5%
`overcorrection` rate and the 21% (`ambiguous` + `partial_fix` +
`overcorrection`) headline number — closer to the low end, based on
this spot-check, but confirming that precisely would mean manually
reviewing each of the 15 cases, which this issue's scope (record
findings, not adjudicate every fixture by hand) doesn't call for.

## Comparison Against Prior Baselines

| Run | Fixtures | Errors | Conflict rate | Avg latency/fixture | Avg tokens/fixture | Avg cost/fixture |
| --- | --- | --- | --- | --- | --- | --- |
| Staged-pipeline baseline (pre-#64) | 5 | 0 | 80% | 7,030 ms | 3,524 | $0.008732 |
| Simple first-pass, 5-fixture (#72) | 5 | 0 | 80% | 5,516 ms | 911 | $0.002948 |
| Simple first-pass, 85-fixture (this run) | 85 | 0 | 56.5% | 3,906 ms | 869 | $0.002554 |

The per-fixture cost/token/latency wins from swapping in the simple
first-pass client (#64-#68) hold up — and improve slightly further —
across a benchmark 17x larger than the original 5-fixture smoke set,
not just on the small set that originally measured them. The conflict/
fallback rate is meaningfully *lower* on the full, more diverse fixture
set (56.5%) than on the original 5-fixture set (80%, both before and
after the first-pass swap — see `docs/two_pass_live_harness_simple_first_pass_confirmation.md`)
— the original smoke set was disproportionately built from
conflict-triggering scenarios by design, so this isn't a regression;
if anything it's a more representative fallback-rate estimate than the
smoke set alone ever gave.

Total spend across both runs (sample + full): **$0.0498 + $0.2171 =
$0.2669**.

## Recommendation: Continue, With Two Targeted Follow-Ups

**The POC should continue** — reliability is excellent (0 errors across
104 total fixture-runs), the token/cost/latency wins are confirmed at
scale, and the unambiguous failure rate (3.5%) is low. This is not a
rejection case, and the evidence doesn't point at a fundamental
architecture problem serious enough to warrant redesigning the two-pass
split itself.

It also isn't a "continue with zero further work" case: the two
recurring failure modes above are concrete and specific enough to act
on. Per this issue's own out-of-scope note ("do not redesign prompts
unless the benchmark evidence creates a follow-up issue"), this
document recommends — but does not itself implement — two follow-ups:

1. Tighten `firstPassCorrectionSpanish`'s restraint language around
   valid regional Spanish and already-correct input, since the prompt
   already states this rule but the benchmark shows it isn't always
   followed.
2. Give the naturalness prompt a way to recognize (or simply be told to
   leave alone) a span the first pass has already handled, to stop it
   re-editing already-correct text with a different, unrequested fix.

Both are narrow, prompt-level changes with a clear before/after
benchmark (this document) to validate against — not a case for
redesigning the pipeline itself.

## Files In Scope For This Run

```text
docs/two_pass_integration_harness.md (regenerated, full 85-fixture run)
docs/two_pass_language_point_benchmark_sample.md (new, 19-fixture sample run)
```

No prompt, merge/fallback, or production behavior changes were made as
part of this issue — measurement only, per its own acceptance criteria.
