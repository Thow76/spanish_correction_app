# Two-Pass Test Change Notes

Working notes for follow-up changes to the two-pass correction tests and live benchmark harnesses.

## Smoke tests: repeated single-phrase runs

First change to make:

- Update the smoke tests so each smoke-test phrase can be run five times individually with the same phrase.
- Record each run separately instead of only keeping one result.
- Use the repeated runs to estimate how frequent each observed error is, rather than treating a single live failure as fully representative.

Why:

- Several reported issues may be stochastic model behavior rather than deterministic pipeline failures.
- Repeating the exact same phrase five times should make it easier to distinguish common failures from rare outliers.
- This will also help decide whether a fix belongs in deterministic code, prompt wording, benchmark scoring, or manual review.

Suggested output fields:

| Field | Purpose |
| --- | --- |
| `phrase_id` | Stable smoke-test case id |
| `run_index` | 1 through 5 for the repeated phrase run |
| `submitted_text` | Exact phrase sent to the pipeline |
| `first_pass_corrected_text` | Output after first pass |
| `final_corrected_text` | Output after naturalness/fallback path |
| `pass_fail` | Per-run benchmark result |
| `failure_label` | `partial_fix`, `overcorrection`, `ambiguous`, `missed_issue`, `error`, or blank |
| `notes` | Short manual review note when needed |

Suggested summary:

- Show per-phrase pass count, for example `4/5 pass`.
- Show the distinct final outputs produced across the five runs.
- Highlight phrases where the same failure appears more than once.
- Separate deterministic-looking failures from one-off output variance.

Open question:

- Should the five-run loop apply to every smoke-test phrase by default, or should it be enabled by a flag so normal smoke tests stay cheap and quick?

## Report tables: show fallback usage per phrase

Add a reporting change for the benchmark tables:

- Insert a column immediately after `Second pass corrected phrase`.
- Suggested column name: `Fallback used`.
- Values should show whether the fallback naturalness pass was used for that phrase, for example `Yes` / `No`.
- If useful, include the fallback corrected phrase or fallback naturalness replacement in a separate column, but the first priority is simply making fallback usage visible.

Why:

- The current table makes it look like there is only a first pass and second pass.
- Some failures depend on whether the parallel naturalness merge conflicted and triggered fallback.
- Without a fallback column, it is harder to tell whether the final output came from the original naturalness pass or from naturalness rerun against the first-pass corrected text.

Suggested table position:

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback used | Pass/fail | ... |
| --- | --- | --- | --- | --- | --- |

Follow-up:

- Update the live harness report writer so every phrase table includes `Fallback used`.
- For repeated five-run smoke tests, record fallback usage per run, not just per phrase.
- Consider adding a grouped summary such as `fallback used in X/Y failed cases` to help identify whether fallback is correlated with over-rewrites.

## Articles / Determiners: review the two failed cases separately

Add a focused note for the two Articles / Determiners failures:

| Case | Observed result | Working interpretation |
| --- | --- | --- |
| `Fui a tienda después del trabajo.` | `Fui a la la tienda después del trabajo.` | This may be mechanical rather than linguistic. The first pass already produced `Fui a la tienda después del trabajo.`, so the duplicate `la la` looks like a merge/replacement/fallback artifact or a one-off formatting issue. |
| `Tengo cita con médico mañana.` | `Tengo cita con el médico mañana.` | This is stranger. The system added `el` before `médico` but did not add `una` before `cita`. The naturalness pass also did not change it, which could mean it is correctly avoiding grammar-style edits, or that `Tengo cita` may be acceptable in some contexts or varieties. |

Follow-up:

- Do not group these as one generic article failure.
- Run both cases repeatedly in the five-run smoke-test mode to see whether either failure is stable.
- For `Fui a la la tienda`, check whether the failure comes from deterministic merge/replacement logic before changing the prompt.
- For `Tengo cita con médico mañana`, do manual language review before deciding whether the expected output must require `Tengo una cita...`.
- If `Tengo cita` is acceptable in some contexts, update the benchmark scoring or notes rather than forcing the naturalness pass to make grammatical article additions.

## Subjunctive / Mood: investigate `su parte` -> `su informe`

Highlight this failed case for manual review:

| Input | First pass | Final output |
| --- | --- | --- |
| `Era necesario que enviaba su parte.` | `Era necesario que enviara su parte.` | `Era necesario que enviara su informe.` |

Question to answer:

- Why did the final pass change `parte` to `informe` after the first pass had already fixed the subjunctive correctly?

Working hypotheses:

- `Su parte` may have been treated as vague or less natural without context, so the naturalness/fallback pass guessed a more concrete noun.
- The model may have inferred that the intended meaning was "his/her report" because `enviar` commonly collocates with documents such as `informe`.
- There may be something about `parte` in Spanish that made the model read it as report-like or context-dependent, but this needs review rather than assumption.

Current interpretation:

- `Era necesario que enviara su parte.` appears to be a valid correction if the intended meaning is "send his/her part/contribution."
- Changing `parte` to `informe` adds specificity that was not present in the submitted text.
- Treat this as a likely naturalness over-rewrite or meaning-preservation issue unless manual review finds that `su parte` is actually unacceptable in this context.

Follow-up:

- Add this phrase to the repeated five-run smoke-test set and record whether `parte` changes to `informe` consistently.
- Compare naturalness-on-original and naturalness-on-first-pass outputs for this case.
- If the model repeatedly changes `parte`, tighten the naturalness prompt or merge acceptance rules so naturalness cannot replace a valid content noun with an inferred noun unless the original noun is clearly wrong.

## False Friends / Word Choice: separate overwrites from variety questions

Add a focused review note for the False Friends / Word Choice failures. The naturalness pass seems to be overwriting these phrases for a reason, but the reason is not always clearly aligned with the benchmark expectation.

| Case | First pass | Final output | Note |
| --- | --- | --- | --- |
| `Atendió la universidad en Madrid.` | `Asistió a la universidad en Madrid.` | `Estudió en la universidad en Madrid.` | The first pass already fixed the false friend. The naturalness/fallback change from `asistió a` to `estudió en` seems unnecessary and may slightly shift meaning. Investigate why the second pass prefers this wording when there is no obvious remaining issue. |
| `Aplicó para un trabajo.` | `Aplicó a un trabajo.` | `Se postuló a un trabajo.` | This may be a viable regional/natural alternative, but `Solicitó un trabajo` still feels like the more obvious expected correction. Review whether `se postuló a un trabajo` is acceptable for the target variety and whether it sounds natural in this standalone context. |
| `Estoy embarazado por llegar tarde.` | `Estoy apenado por llegar tarde.` | `Siento llegar tarde.` | The first pass chose `apenado`, while the final output moved to `siento`. This may expose a Peninsular Spanish versus Latin American Spanish issue around `apenado`, `avergonzado`, `me da vergüenza`, and apology-style rewrites. |

Questions to answer:

- Is the naturalness pass overwriting first-pass false-friend fixes because it considers the first-pass wording regionally marked, too literal, or less idiomatic?
- Should benchmark expected outputs specify the target variety more explicitly for false-friend corrections?
- Is `se postuló a un trabajo` an acceptable alternative, or should the test prefer `solicitó un trabajo` for the app's target Spanish?
- Is `apenado` acceptable in the intended target variety, or is the system mixing Peninsular and Latin American preferences?

Follow-up:

- Run these false-friend cases five times each and record whether the same replacements recur.
- Compare first-pass-only output against final two-pass output to identify which changes are coming specifically from naturalness/fallback.
- Add manual language-review notes for regional acceptability before changing the benchmark answer key.
- Consider adding target-variety wording to the prompt or benchmark notes if the failures are mainly variety conflicts rather than correction-quality failures.

## Phrase-Level Naturalness: `Puedo tener una cerveza`

Highlight this case as an output-format/harness-scoring failure more than a missed naturalness correction:

| Input | Expected | Final output |
| --- | --- | --- |
| `¿Puedo tener una cerveza?` | `¿Me pones una cerveza?` | `¿Me pones una cerveza? / ¿Me das una cerveza? / ¿Me pones una caña?` |

Harness details:

- Operation type: `replacement`.
- Expected owner: `naturalness`.
- First pass made no change, which is expected for this naturalness-only case.
- Naturalness on original text returned multiple alternatives.
- Naturalness on first-pass corrected text also returned multiple alternatives.
- Parallel merge had no skipped edit.
- Fallback was not used.
- Final correction count was 1.
- Score in `docs/two_pass_integration_harness.md`: `ambiguous`.

Working interpretation:

- The naturalness pass did identify the issue: `¿Puedo tener una cerveza?` is understandable but English-influenced in many bar/cafe contexts.
- What was missing was not awareness of the natural phrasing. What was missing was the requirement to return one corrected sentence only.
- The output gave several viable alternatives separated by slashes, which breaks the correction pipeline because the app needs a single final corrected text.
- The harness scored it as `ambiguous` because the final output changed the phrase but did not exactly match the expected correction or an accepted alternative. The scorer is mechanical and does not try to decide whether the first option inside a slash-separated list should count as a partial success.

Review questions:

- Should `¿Me pones una cerveza?` be the preferred target for Peninsular Spanish?
- Should `¿Me das una cerveza?` be accepted as a valid alternative?
- Should `¿Me pones una caña?` be excluded because it adds specificity: `caña` is not exactly the same as `cerveza`.

Follow-up:

- Add a deterministic guard or parser check for slash-separated alternatives in final corrected text.
- If multiple alternatives appear, either reject the naturalness edit or choose the first complete sentence consistently.
- Keep this case in the five-run smoke-test set to see whether the model repeatedly returns multiple options.

## Phrase-Level Naturalness: same slash-separated issue for `pasar un buen tiempo`

This appears to be the same failure pattern as `¿Puedo tener una cerveza?`.

| Input | Expected | Final output |
| --- | --- | --- |
| `Quiero pasar un buen tiempo.` | `Quiero pasarlo bien.` | `Quiero pasarlo bien / pasar un buen rato.` |

Harness details:

- Operation type: `replacement`.
- Expected owner: `naturalness`.
- First pass made no change, which is expected for this naturalness-only case.
- Naturalness on original text returned `pasarlo bien / pasar un buen rato`.
- Naturalness on first-pass corrected text returned the same alternatives.
- Parallel merge had no skipped edit.
- Fallback was not used.
- Final correction count was 1.
- Score in `docs/two_pass_integration_harness.md`: `ambiguous`.

Working interpretation:

- This is not a missed issue. The naturalness pass recognised that `pasar un buen tiempo` is English-influenced.
- The failure is that it returned two options instead of one final replacement.
- Both `pasarlo bien` and `pasar un buen rato` may be valid, but the app needs one corrected sentence.

Follow-up:

- Treat this together with `¿Puedo tener una cerveza?` as an output-control failure class.
- Repeated five-run smoke tests should record how often naturalness returns slash-separated alternatives in phrase-level naturalness cases.
- If this repeats, fix the naturalness output contract before treating these as language-quality failures.

## Phrase-Level Naturalness: `Estoy corriendo tarde`

Highlight this case separately from the slash-separated-output failures.

| Input | Expected | First pass | Naturalness on original | Naturalness on first-pass text | Final output |
| --- | --- | --- | --- | --- | --- |
| `Estoy corriendo tarde para la reunión.` | `Voy tarde a la reunión.` | `Estoy llegando tarde para la reunión.` | `Llego tarde a la reunión.` | `Voy a llegar tarde a la reunión.` | `Voy a llegar tarde a la reunión.` |

Harness details:

- Operation type: `replacement`.
- Expected owner: `naturalness`.
- The first pass changed the submitted phrase to `Estoy llegando tarde para la reunión.`
- Naturalness on the original text proposed `Llego tarde a la reunión.`
- The parallel merge had a skipped edit, so fallback was used.
- Naturalness on first-pass corrected text proposed `Voy a llegar tarde a la reunión.`
- Score in `docs/two_pass_integration_harness.md`: `partial_fix`.

Pipeline logistics:

- Production starts first pass and naturalness-on-original at the same time.
- The first naturalness pass therefore reviews the original submitted text.
- The merge tries to apply the original-text naturalness edit onto the first-pass corrected text.
- If that edit cannot be applied safely because the first pass changed the relevant wording, the pipeline runs a fallback naturalness pass on the first-pass corrected text.
- The live harness records both naturalness-on-original and naturalness-on-first-pass for every fixture so the report can compare them, even though production only needs the second one when fallback is triggered.

Working interpretation:

- `Estoy corriendo tarde` is a direct English calque for "I am running late", so the naturalness pass had a legitimate reason to change it.
- The first pass may have overstepped by changing `corriendo tarde` to `llegando tarde`, because that is more of a naturalness/word-choice correction than a narrow grammar/spelling/accent/punctuation correction.
- This may be related to the fact that the smallest visible change is only one word: `corriendo` -> `llegando`. The phrase is a calque, but it can also look like a single word-choice replacement. That may be why the first pass treated it as eligible, even though the broader issue belongs to phrase-level naturalness.
- Review whether the system is too willing to classify phrase-level calques as single-token word-choice fixes when only one word needs to change.
- `Voy a llegar tarde a la reunión` is understandable and likely acceptable Spanish, but it is not the same benchmark target as `Voy tarde a la reunión`.
- The final output may shift the aspect slightly: "I am running late / I am late on the way" versus "I am going to arrive late."

Follow-up:

- Add this case to repeated five-run smoke tests and track whether the first pass consistently changes `corriendo tarde`.
- Review whether the first pass should leave this phrase untouched and allow naturalness to own the correction.
- Add a targeted test or annotation for phrase-level calques whose minimal edit is a single word, because they may fall through the boundary between word choice and naturalness.
- Decide whether `Voy a llegar tarde a la reunión` should be accepted as an alternative or kept as `partial_fix` because it changes the nuance.

## Valid Regional / Should Not Flag: `Voy para casa`

Add this as a first-pass boundary issue, not a naturalness/fallback issue.

| Input | Expected | First pass | Final output |
| --- | --- | --- | --- |
| `Voy para casa ahora mismo.` | `Voy para casa ahora mismo.` | `Voy para la casa ahora mismo.` | `Voy para la casa ahora mismo.` |

Working interpretation:

- The actual change was the first pass adding `la`.
- The second pass appears to have accepted or confirmed the first-pass-normalized phrase rather than introducing a new change.
- The failure therefore belongs to first-pass restraint: it should not change valid regional Spanish just because a more standard or more explicit article form also exists.

Follow-up:

- Add this case to repeated five-run smoke tests and track whether first pass consistently inserts `la`.
- Review the first-pass prompt boundary around valid article-free regional expressions such as `para casa`.
- Do not treat this as evidence that naturalness is over-rewriting unless future runs show naturalness changing the phrase when first pass leaves it untouched.

## Already Correct / Do Not Tinker: `tomar una foto`

Add this as a no-change restraint issue.

| Input | Expected | Final output |
| --- | --- | --- |
| `Necesito tomar una foto del documento.` | `Necesito tomar una foto del documento.` | `Necesito sacar una foto / hacer una foto del documento.` |

Working interpretation:

- The original phrase was already acceptable Spanish.
- The failure appears to be that the naturalness pass added alternative phrasing where no correction was needed.
- This is similar to the phrase-level naturalness slash-separated-output issue, but stricter: this fixture expected no change at all.
- `Sacar una foto` and `hacer una foto` may be valid alternatives depending on variety, but they are not corrections if `tomar una foto` is already acceptable.

Follow-up:

- Add this case to repeated five-run smoke tests and track whether naturalness consistently rewrites `tomar una foto`.
- Confirm target-variety expectations for `tomar una foto`, `sacar una foto`, and `hacer una foto`.
- Treat this as naturalness overcorrection unless manual review finds that `tomar una foto del documento` is unacceptable for the target variety.

## Mixed Operations: what "mixed" means

Clarify the meaning of the Mixed Operations group. These fixtures are synthetic stress tests: each one combines two simpler correction types into the same sentence so the pipeline has to handle more than one operation at once.

| Fixture | Intended operations | Outcome note |
| --- | --- | --- |
| `mixed-preposition-and-redundant-pronoun` | Insert missing preposition `en` in `Insisto en que`; delete repeated second `yo`. | Failed as `partial_fix`: main corrections happened, but final output also removed the conjunction `y` after the comma. |
| `mixed-article-and-accent` | Insert missing article `un`; add accents in `compré`, `café`, `cafetería`, `pequeña`. | Passed. |
| `mixed-personal-a-and-subjunctive` | Insert personal `a`; replace indicative `estudias` with subjunctive `estudies`. | Failed as `ambiguous`: first pass produced the expected correction, then naturalness/fallback rewrote the sentence and introduced `me dijo que`. |
| `mixed-gender-agreement-and-redundant-pronoun` | Replace `abierto` with `abiertas`; delete trailing redundant `a mí`. | Passed. |
| `mixed-verb-agreement-and-missing-que` | Replace `estudia` with `estudian`; insert missing `que` in `creo que`. | Failed as `ambiguous`: first pass produced the expected correction, then naturalness/fallback removed `Ellos` and changed `está bien terminar hoy` to `podemos terminar hoy`. |

Working interpretation:

- "Mixed" does not mean the sentence is naturally mixed-register or dialectal.
- It means the benchmark combines more than one correction operation in a single fixture.
- The failures are useful because they show interaction problems between first pass, naturalness, merge, and fallback.
- In two of the failed mixed cases, the first pass had already produced the expected answer and the later naturalness/fallback path caused the drift.
- For `mixed-preposition-and-redundant-pronoun`, note a possible first-pass interaction: the input contains both a missing preposition and the repeated `y yo ... y yo ...` pattern. The first pass fixed `Insisto que` -> `Insisto en que`, but did not remove the second `yo`. That may mean the extra preposition issue made the repeated-pronoun issue less clear to the first pass, even though repeated-pronoun cases were handled in other tests.
- Also check whether the repeated conjunction/pronoun shape itself is causing instability: `, y yo trabajo mucho y yo estudio...` has two `y yo` sequences, so later naturalness/fallback may be trying to smooth the whole coordination rather than only deleting the second pronoun.
- For `mixed-personal-a-and-subjunctive`, the first pass already produced the expected correction: `Vi a mi profesor en la estación, y es importante que estudies.` The failure is that naturalness/fallback added extra information by changing the second clause to `y me dijo que era importante que estudiara.` That introduces a new speaker/action: someone told the learner it was important. This was not present in the original, so treat this as meaning-changing over-rewrite rather than a missed grammar correction. However, also note that the original fixture is semantically awkward: "I saw my professor at the station, and it is important that you study" does not have an obvious logical connection. Naturalness may be trying to repair that coherence gap. This could be a benchmark fixture-design issue as much as a model issue.
- For `mixed-verb-agreement-and-missing-que`, the first pass also produced the expected correction: `Ellos estudian todas las noches, y creo que está bien terminar hoy.` The final output changed this to `Estudian todas las noches, y creo que podemos terminar hoy.` That removes `Ellos` and changes the meaning of the second clause. But the fixture itself is also semantically odd: "They study every night, and I think it is good to finish today" does not clearly say what `it` refers to or why the two clauses are connected. Naturalness may have inferred a more coherent classroom/work context and changed `está bien terminar hoy` to `podemos terminar hoy`. This should be flagged as possible fixture-design weakness, not only model over-rewrite.

Follow-up:

- Keep these as stress tests, but label the two intended operations clearly in any summary report.
- In repeated five-run mode, track whether the first pass reaches the expected correction before judging the final two-pass output.
- For mixed failures, record whether the failure belongs to first pass, naturalness/fallback, merge behavior, or benchmark scoring.
- Add a focused comparison between a simple repeated-pronoun case and the mixed missing-preposition-plus-repeated-pronoun case to see whether the first pass misses pronoun deletion only when another correction is present.
- Consider rewriting semantically odd mixed fixtures so they still test the same operations but do not invite coherence repair from the naturalness pass.

## Prompt/contract audit: first pass, naturalness, and fallback

Full writeup moved to a dedicated file rather than kept here: `docs/two_pass_prompt_contract_audit.md`.

Confirms the fallback pass has no prompt of its own — it reuses `naturalnessReviewSpanish` (the same prompt and client as the parallel naturalness call) against the first pass's own corrected text, with no framing telling the model it's a rerun. Lays out where each prompt is defined, exact input text and output schema per pass, when each runs in production vs. the diagnostic harness, and connects four recurring failure patterns (naturalness over-rewriting correct first-pass output, slash-separated alternatives, first pass straying into word-choice/naturalness territory, fallback changing meaning after the first pass already fixed objective errors) to specific gaps in the prompt text — cross-checked against both the diagnostic issue log and the production-style benchmark report, so these read as prompt-level issues, not artifacts of either report's own methodology.

No prompts or production code changed as part of this audit — it's investigation only, with a possible follow-up prompt-change issue noted as a next step, not started here.

## Status update (issue #112)

Reviewed the fixture/scoring questions raised across this document and the live benchmark issue log, and made the following changes in `test/two_pass_integration_harness.dart`:

- **`mixed-personal-a-and-subjunctive`** and **`mixed-verb-agreement-and-missing-que`**: rewritten (both `text` and `expectedCorrectedText`) to remove the coherence gaps flagged above ("Mixed Operations: what 'mixed' means"). Both fixtures now form single, self-contained, logically connected sentences while still testing the same two original operations (personal `a` + subjunctive mood; verb agreement + missing `que`). Confirmed no other test file hardcodes the old text.
- **`false-friend-aplico-trabajo`**: added `Se postuló a un trabajo.` as an acceptable alternative (genuinely natural, especially in Latin American varieties), while keeping `Solicitó un trabajo.` as the primary expectation.
- **`false-friend-embarazado`**: added `Estoy avergonzado por llegar tarde.` as an acceptable alternative (a valid minimal adjective-swap fix, not regionally marked the way `apenado` is), keeping the more idiomatic `Me da vergüenza llegar tarde.` as primary.
- **Pro-drop ("valid pro-drop alternatives may be marked too strictly", per issue #112's own text)**: found `delete-repeated-yo-compre` already expected full pro-drop (both subject pronouns dropped) as its primary answer, while `delete-repeated-yo-estudio`, `delete-repeated-ellos-visitaron`, and `delete-repeated-nosotros` required keeping the first pronoun — an inconsistency. Added the fully-pro-dropped form as an acceptable alternative to all three, matching the precedent `delete-repeated-yo-compre` already set. `delete-repeated-a-mi` was left unchanged — its repeated `a mí` is emphatic dative clitic doubling, not an optional subject pronoun, so pro-drop doesn't apply there.
- **`article-cita-medico`** (`Tengo cita con médico mañana.`): reviewed and deliberately left unchanged/strict, with a documenting note added rather than a loosened alternative. This exact phrase was added as a worked example in the first-pass prompt in issue #109 specifically to teach the model to add both missing articles — loosening the fixture now would contradict that prompt-engineering decision. Recorded as an explicit target-variety assumption per this issue's requirements, not a gap.
- Every changed/annotated fixture's `note` field now documents the issue #112 reasoning inline, and both `note` and `acceptableAlternatives` are already rendered per-fixture in every generated report (see `buildReport` in `test/two_pass_integration_harness.dart`), so a reader can already tell a scoring/fixture-design judgment call apart from a real product failure without new reporting machinery.

Not changed as part of this issue: the naturalness slash-separated-alternatives cases (`¿Puedo tener una cerveza?`, `Quiero pasar un buen tiempo.`) and the `Voy para casa` regional case — these were prompt/first-pass boundary issues, not fixture-design issues, and were already addressed by issues #108 and #109 respectively (confirmed passing in the live #117 evaluation runs). `Estoy corriendo tarde` and `su parte -> su informe` remain open naturalness/fallback over-rewrite questions, not fixture problems, and are out of scope here.

## Status update (issue #111)

Added three deterministic safety guards to `mergeNaturalnessReview` (`lib/features/corrections/domain/naturalness_merge.dart`), directly addressing observed failures documented above and in `docs/two_pass_prompt_contract_audit.md`:

- **`spanTooBroad`** (new `NaturalnessMergeSkipReason`): skips an issue whose span covers 80%+ of `firstPassCorrectedText` — a full-sentence rewrite in disguise, not a narrow calque/idiom/collocation fix. Directly catches the fallback pattern seen repeatedly across the #110/#117 live runs: `"Vi mucho tráfico ayer."` -> `"Había mucho tráfico ayer."`, where the span was the entire sentence.
- **`contentWordReplaced`** (new `NaturalnessMergeSkipReason`): skips an issue whose span is a short function-word-wrapped phrase (e.g. determiner/possessive + one noun) where that one content word is entirely absent from the replacement — the `"su parte" -> "su informe"` pattern from "Subjunctive / Mood: investigate `su parte` -> `su informe`" above. Deliberately narrow: does **not** catch a bare single-word span (e.g. a false-friend fix like `"Atendió" -> "Asistió"`) or a phrase whose content word carries over into the replacement (e.g. `"hacer una decisión" -> "tomar una decisión"`) — both are legitimate naturalness territory. Verified against the existing test suite, including issue #34's synthetic three-way overlap-chain test, to confirm no existing legitimate replacement gets caught.
- **Word-boundary-aware span matching** (no new skip reason — makes the existing `spanNotFound` classification correct): a plain substring search can match a span like `"a tienda"` starting mid-word, inside the trailing "a" of an unrelated word "la" (e.g. `"Fui a **la** tienda"`). Applying the edit there duplicated the article — the exact `"Fui a la la tienda"` artifact from "Articles / Determiners: review the two failed cases separately" above. Matches are now filtered to real word boundaries before being counted found/ambiguous.

The slash-separated-alternatives guard (`multiOptionReplacement`) issue #111 also asked to evaluate was already implemented in issue #108 — confirmed still working, no changes needed.

All three new guards use the same "skip, never guess" precedent already established for `spanNotFound`/`ambiguousSpan`/`overlapsAnotherEdit`/`multiOptionReplacement` — a guarded edit lands in `skippedEdits`, which (unchanged) is what makes the two-pass pipeline trigger the fallback rerun when it happens during the parallel merge. No new "downgrade" or alternate pathway was needed; skip already produces the right downstream behavior.

Focused unit tests for each guard (positive case + at least one case proving legitimate replacements still apply) are in `test/features/corrections/domain/naturalness_merge_test.dart`.

**Deliberately not attempted**: a general "naturalness replaced a valid content noun with a semantically inferred one" guard broader than the specific wrapped-phrase shape above. Distinguishing a legitimate word-choice/false-friend correction (`"hace" -> "tiene"`, `"Atendió" -> "Asistió"`) from an invented, unrelated substitution requires semantic/dictionary knowledge this merge layer doesn't have; a broader mechanical heuristic tried during this issue produced a real false positive against issue #34's own overlap-chain test. This remains better addressed at the prompt level (see `docs/two_pass_prompt_contract_audit.md`'s own suggested follow-up) than as a merge-layer guard.
