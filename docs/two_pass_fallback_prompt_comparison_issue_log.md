# Two-Pass Fallback Prompt Comparison: Issue Log

Source report:

- Attached report: `Two-Pass Fallback Prompt Comparison: Full Pipeline (issue #117)`

Run configuration:

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture count: `27`
- Generated: `2026-08-03T21:01:20.097216Z`

This log reproduces the fallback prompt comparison using the same plain-English issue-log style as `docs/two_pass_live_language_point_benchmark_issue_log.md`.

For this document:

- `pass` means `correct_fix` or `acceptable_no_change`.
- `fail` means `partial_fix`, `ambiguous`, `overcorrection`, `missed_issue`, or `error`.
- `Current` means the existing reused naturalness prompt was used for fallback.
- `Candidate` means the fallback-specific prompt was used for fallback.

Important context: pass 1 and the naturalness call on the original text were shared between both variants. The only thing being compared is the fallback call itself, and that fallback call only ran where the real conflict logic triggered it. Where fallback did not trigger, both variants usually have the same result because the candidate fallback prompt was never used.

## Overall Summary

| Item | Finding |
| --- | --- |
| Fixtures tested | 27 |
| Fallback triggered | 11 |
| Fallback did not trigger | 16 |
| Current result on fallback-triggered fixtures | 5/11 pass; 6/11 fail |
| Candidate result on fallback-triggered fixtures | 5/11 pass; 6/11 fail |
| Current result on non-triggered fixtures | 9/16 pass; 7/16 fail |
| Candidate result on non-triggered fixtures | 9/16 pass; 7/16 fail |
| Current result overall | 14/27 pass; 13/27 fail |
| Candidate result overall | 14/27 pass; 13/27 fail |
| Practical meaning | The candidate fallback prompt did not improve the overall benchmark score. It helped one mixed-operation case, but lost one false-friend case, so the net result was unchanged. Many failures were not really fallback-prompt failures because fallback never ran. |

## Accents / Diacritics

| Item | Finding |
| --- | --- |
| Result | Current: 0/1 pass; Candidate: 0/1 pass |
| Overall group status | Fail |
| First-pass signal | Passed. It corrected `trafico` to `tráfico`. |
| Naturalness / fallback signal | Failed. Both variants rewrote the sentence beyond the expected accent correction. |
| Practical meaning | This is not an accent-correction failure. It shows that the naturalness/fallback path can still rewrite a sentence after the first pass has already made the narrow required fix. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Vi mucho trafico ayer.` | `Vi mucho tráfico ayer.` | `Vi mucho tráfico ayer.` | `mucho trafico` -> `mucho tráfico` | Yes | `Había mucho tráfico ayer.` | Fail (`ambiguous`) | `Había mucho tráfico ayer.` | Fail (`ambiguous`) |

## Already Correct / Do Not Tinker

| Item | Finding |
| --- | --- |
| Result | Current: 1/2 pass; Candidate: 1/2 pass |
| Overall group status | Needs review |
| First-pass signal | Passed. It left already-correct input unchanged. |
| Naturalness / fallback signal | Mixed. One no-change case stayed unchanged, but one valid phrase was rewritten by the parallel naturalness merge before fallback was involved. |
| Practical meaning | The candidate fallback prompt cannot help when fallback does not run. The issue here is naturalness restraint on already-valid text. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Necesito tomar una foto del documento.` | `Necesito tomar una foto del documento.` | `Necesito tomar una foto del documento.` | `tomar una foto` -> `sacar una foto` | No | `Necesito sacar una foto del documento.` | Fail (`overcorrection`) | `Necesito sacar una foto del documento.` | Fail (`overcorrection`) |
| `Buenos días, ¿cómo estás?` | `Buenos días, ¿cómo estás?` | `Buenos días, ¿cómo estás?` | None | No | `Buenos días, ¿cómo estás?` | Pass (`acceptable_no_change`) | `Buenos días, ¿cómo estás?` | Pass (`acceptable_no_change`) |

## Valid Regional / Should Not Flag

| Item | Finding |
| --- | --- |
| Result | Current: 1/1 pass; Candidate: 1/1 pass |
| Overall group status | Pass |
| First-pass signal | Passed in this comparison run. |
| Naturalness / fallback signal | Passed. No fallback was triggered and no regional wording was changed. |
| Practical meaning | In this report, `Voy para casa ahora mismo.` was protected correctly. This differs from earlier benchmark findings where the first pass overcorrected the same phrase. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Voy para casa ahora mismo.` | `Voy para casa ahora mismo.` | `Voy para casa ahora mismo.` | None | No | `Voy para casa ahora mismo.` | Pass (`acceptable_no_change`) | `Voy para casa ahora mismo.` | Pass (`acceptable_no_change`) |

## Phrase-Level Naturalness

| Item | Finding |
| --- | --- |
| Result | Current: 4/5 pass; Candidate: 4/5 pass |
| Overall group status | Mostly pass, with one benchmark/meaning review case |
| First-pass signal | Mostly left naturalness issues for the naturalness pass, as intended. |
| Naturalness / fallback signal | Mostly passed. The one failing case did not trigger fallback, so the candidate fallback prompt had no chance to change it. |
| Practical meaning | This group does not show a fallback-prompt improvement. It mainly shows that the parallel naturalness pass can handle several phrase-level naturalness cases, while acceptable alternatives still need review. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Tuvimos un buen tiempo.` | `Lo pasamos bien.` | `Tuvimos un buen tiempo.` | `Tuvimos un buen tiempo.` -> `Lo pasamos bien.` | No | `Lo pasamos bien.` | Pass (`correct_fix`) | `Lo pasamos bien.` | Pass (`correct_fix`) |
| `Estoy corriendo tarde para la reunión.` | `Voy tarde a la reunión.` | `Estoy corriendo tarde para la reunión.` | `corriendo tarde` -> `llegando tarde` | No | `Estoy llegando tarde para la reunión.` | Fail (`partial_fix`) | `Estoy llegando tarde para la reunión.` | Fail (`partial_fix`) |
| `Quiero pasar un buen tiempo.` | `Quiero pasarlo bien.` | `Quiero pasar un buen tiempo.` | `pasar un buen tiempo` -> `pasarlo bien` | No | `Quiero pasarlo bien.` | Pass (`correct_fix`) | `Quiero pasarlo bien.` | Pass (`correct_fix`) |
| `¿Puedo tener una cerveza?` | `¿Me pones una cerveza?` | `¿Puedo tener una cerveza?` | `¿Puedo tener una cerveza?` -> `¿Me pones una cerveza?` | No | `¿Me pones una cerveza?` | Pass (`correct_fix`) | `¿Me pones una cerveza?` | Pass (`correct_fix`) |
| `Te llamo para atrás.` | `Te devuelvo la llamada.` | `Te llamo para atrás.` | `Te llamo para atrás.` -> `Te devuelvo la llamada.` | No | `Te devuelvo la llamada.` | Pass (`correct_fix`) | `Te devuelvo la llamada.` | Pass (`correct_fix`) |

## Mixed Operations

| Item | Finding |
| --- | --- |
| Result | Current: 1/4 pass; Candidate: 2/4 pass |
| Overall group status | Needs review |
| First-pass signal | Often strong. In several cases the first pass had already produced the expected correction. |
| Naturalness / fallback signal | Mixed. The candidate fallback prompt helped one case by leaving an already-correct first-pass result alone, but both variants still rewrote other mixed cases beyond the expected correction. |
| Practical meaning | This is the clearest place where the candidate fallback prompt helped, but the improvement was narrow and did not change the overall benchmark result. Mixed cases remain important stress tests. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Vi mi profesor en la estación, y es importante que estudias.` | `Vi a mi profesor en la estación, y es importante que estudies.` | `Vi a mi profesor en la estación, y es importante que estudies.` | `Vi mi profesor en la estación` -> `Vi a mi profesor en la estación`<br>`es importante que estudias` -> `es importante que estudies` | Yes | `Vi a mi profesor en la estación, y me dijo que era importante que estudiara.` | Fail (`ambiguous`) | `Vi a mi profesor en la estación, y es importante que estudies.` | Pass (`correct_fix`) |
| `Ellos estudia todas las noches, y creo está bien terminar hoy.` | `Ellos estudian todas las noches, y creo que está bien terminar hoy.` | `Ellos estudian todas las noches, y creo que está bien terminar hoy.` | `creo está bien terminar hoy` -> `creo que está bien terminar hoy` | Yes | `Ellos estudian todas las noches, y creo que ya podemos terminar por hoy.` | Fail (`ambiguous`) | `Ellos estudian todas las noches, y creo que podemos terminar hoy.` | Fail (`ambiguous`) |
| `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | `Insisto que revises el contrato` -> `Insisto en que revises el contrato`<br>`y yo trabajo mucho y yo estudio por las noches` -> `yo trabajo mucho y estudio por las noches` | Yes | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | Fail (`partial_fix`) | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | Fail (`partial_fix`) |
| `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | `Las ventanas estaban abiertas, y a mí me gusta el café.` | `Las ventanas estaban abiertas, y a mí me gusta el café.` | `Las ventanas estaban abierto` -> `Las ventanas estaban abiertas`<br>`y a mí me gusta el café a mí` -> `y a mí me gusta el café` | Yes | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Pass (`correct_fix`) | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Pass (`correct_fix`) |

## False Friends / Word Choice

| Item | Finding |
| --- | --- |
| Result | Current: 2/3 pass; Candidate: 1/3 pass |
| Overall group status | Needs review |
| First-pass signal | Mixed. It left some word-choice work to naturalness, and made a preposition-only correction in one false-friend case. |
| Naturalness / fallback signal | Mixed. The current fallback produced the expected `Solicitó un trabajo.`, while the candidate fallback chose `Se postuló a un trabajo.`, which may be valid but did not match the expected benchmark answer. |
| Practical meaning | This is where the candidate prompt lost the pass it gained in mixed operations. The issue may partly be benchmark strictness around acceptable alternatives, but it still means the candidate prompt did not clearly outperform the current prompt. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Atendió la universidad en Madrid.` | `Asistió a la universidad en Madrid.` | `Atendió la universidad en Madrid.` | `Atendió la universidad` -> `Asistió a la universidad` | No | `Asistió a la universidad en Madrid.` | Pass (`correct_fix`) | `Asistió a la universidad en Madrid.` | Pass (`correct_fix`) |
| `Aplicó para un trabajo.` | `Solicitó un trabajo.` | `Aplicó a un trabajo.` | `Aplicó para un trabajo.` -> `Se postuló para un trabajo.` | Yes | `Solicitó un trabajo.` | Pass (`correct_fix`) | `Se postuló a un trabajo.` | Fail (`ambiguous`) |
| `Estoy embarazado por llegar tarde.` | `Me da vergüenza llegar tarde.` | `Estoy embarazado por llegar tarde.` | `Estoy embarazado por llegar tarde.` -> `Estoy avergonzado por llegar tarde.` | No | `Estoy avergonzado por llegar tarde.` | Fail (`partial_fix`) | `Estoy avergonzado por llegar tarde.` | Fail (`partial_fix`) |

## Subjunctive / Mood

| Item | Finding |
| --- | --- |
| Result | Current: 0/1 pass; Candidate: 0/1 pass |
| Overall group status | Fail |
| First-pass signal | Passed. It changed `enviaba` to `enviara`. |
| Naturalness / fallback signal | Failed. Both variants changed `su parte` to `su informe`, which went beyond the expected mood correction. |
| Practical meaning | The fallback-specific prompt did not stop an unnecessary lexical rewrite once fallback was triggered. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Era necesario que enviaba su parte.` | `Era necesario que enviara su parte.` | `Era necesario que enviara su parte.` | `Era necesario que enviaba su parte.` -> `Era necesario que enviara su parte.` | Yes | `Era necesario que enviara su informe.` | Fail (`ambiguous`) | `Era necesario que enviara su informe.` | Fail (`ambiguous`) |

## Ambiguous / Repeated Span Safety (Naturalness)

| Item | Finding |
| --- | --- |
| Result | Current: 0/1 pass; Candidate: 0/1 pass |
| Overall group status | Fail |
| First-pass signal | Passed. It left the already-valid repeated wording unchanged. |
| Naturalness / fallback signal | Failed before fallback. The naturalness pass rewrote valid repetition, and fallback did not trigger. |
| Practical meaning | This is not a fallback-prompt issue. The candidate fallback prompt cannot protect a case where fallback is never called. The naturalness pass needs stronger restraint around valid repetition. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Vi mucho tráfico, y luego vi más tráfico.` | `Vi mucho tráfico, y luego vi más tráfico.` | `Vi mucho tráfico, y luego vi más tráfico.` | `Vi mucho tráfico, y luego vi más tráfico.` -> `Había mucho tráfico, y luego todavía más.` | No | `Había mucho tráfico, y luego todavía más.` | Fail (`overcorrection`) | `Había mucho tráfico, y luego todavía más.` | Fail (`overcorrection`) |

## Articles / Determiners

| Item | Finding |
| --- | --- |
| Result | Current: 0/1 pass; Candidate: 0/1 pass |
| Overall group status | Fail |
| First-pass signal | Passed. It inserted the missing article correctly. |
| Naturalness / fallback signal | Failed before fallback. The merge duplicated the article, and fallback did not trigger. |
| Practical meaning | This is a merge/application problem, not a fallback-prompt comparison result. Both variants are identical because fallback was never called. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Fui a tienda después del trabajo.` | `Fui a la tienda después del trabajo.` | `Fui a la tienda después del trabajo.` | `a tienda` -> `a la tienda` | No | `Fui a la la tienda después del trabajo.` | Fail (`ambiguous`) | `Fui a la la tienda después del trabajo.` | Fail (`ambiguous`) |

## Verb Morphology Overlapping Collocations / Strong Calques

| Item | Finding |
| --- | --- |
| Result | Current: 1/1 pass; Candidate: 1/1 pass |
| Overall group status | Pass |
| First-pass signal | Partial. It corrected the spelling/morphology part from `iso` to `hizo`, but left the calque. |
| Naturalness / fallback signal | Passed. Both fallback variants moved the sentence to the expected collocation. |
| Practical meaning | This is one of the cases where fallback genuinely matters and both prompts handled it successfully. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ayer iso una decisión importante.` | `Ayer tomó una decisión importante.` | `Ayer hizo una decisión importante.` | `iso una decisión importante` -> `tomó una decisión importante` | Yes | `Ayer tomó una decisión importante.` | Pass (`correct_fix`) | `Ayer tomó una decisión importante.` | Pass (`correct_fix`) |

## Collocations / Strong Calques

| Item | Finding |
| --- | --- |
| Result | Current: 2/2 pass; Candidate: 2/2 pass |
| Overall group status | Pass |
| First-pass signal | Mixed. One collocation was left for naturalness, and one was already corrected by the first pass. |
| Naturalness / fallback signal | Passed. Both variants reached the expected output. |
| Practical meaning | These cases do not show a meaningful difference between the fallback prompts. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ella hizo un paseo.` | `Ella dio un paseo.` | `Ella hizo un paseo.` | `hizo un paseo` -> `dio un paseo` | No | `Ella dio un paseo.` | Pass (`correct_fix`) | `Ella dio un paseo.` | Pass (`correct_fix`) |
| `Esto hace sentido.` | `Esto tiene sentido.` | `Esto tiene sentido.` | `hace sentido` -> `tiene sentido` | Yes | `Esto tiene sentido.` | Pass (`correct_fix`) | `Esto tiene sentido.` | Pass (`correct_fix`) |

## Required Prepositions

| Item | Finding |
| --- | --- |
| Result | Current: 0/1 pass; Candidate: 0/1 pass |
| Overall group status | Needs review |
| First-pass signal | Partial. It produced `en que`, while the expected benchmark output was `en la que`. |
| Naturalness / fallback signal | Both variants changed the phrase to `donde trabajo`, which may be natural but did not match the expected benchmark answer. |
| Practical meaning | This looks like a benchmark/acceptable-alternative review case as much as a fallback issue. The output may be valid Spanish, but it did not preserve the exact expected correction path. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `La empresa que trabajo está cerca.` | `La empresa en la que trabajo está cerca.` | `La empresa en que trabajo está cerca.` | `La empresa que trabajo` -> `La empresa donde trabajo` | Yes | `La empresa donde trabajo está cerca.` | Fail (`ambiguous`) | `La empresa donde trabajo está cerca.` | Fail (`ambiguous`) |

## Unnecessary Extras / Deletions

| Item | Finding |
| --- | --- |
| Result | Current: 2/4 pass; Candidate: 2/4 pass |
| Overall group status | Needs review |
| First-pass signal | Mixed. It sometimes removed only the repeated pronoun, and sometimes left deletion work to naturalness. |
| Naturalness / fallback signal | Mixed. Two cases passed, while two cases removed more pronouns than the expected benchmark answer. |
| Practical meaning | These failures may be valid pro-drop Spanish rather than true defects. The fallback-specific prompt did not change the outcome because most failing cases did not trigger fallback. |

| Phrase | Expected | First pass corrected phrase | Pass 2 signal | Fallback triggered | Current final output | Current pass/fail | Candidate final output | Candidate pass/fail |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Yo trabajo mucho y yo estudio por las noches.` | `Yo trabajo mucho y estudio por las noches.` | `Yo trabajo mucho y yo estudio por las noches.` | `Yo trabajo mucho y yo estudio por las noches.` -> `Trabajo mucho y estudio por las noches.` | No | `Trabajo mucho y estudio por las noches.` | Fail (`ambiguous`) | `Trabajo mucho y estudio por las noches.` | Fail (`ambiguous`) |
| `Ellos viajaron a México y ellos visitaron varias ciudades.` | `Ellos viajaron a México y visitaron varias ciudades.` | `Ellos viajaron a México y visitaron varias ciudades.` | `Ellos viajaron a México y ellos visitaron varias ciudades.` -> `Viajaron a México y visitaron varias ciudades.` | Yes | `Ellos viajaron a México y visitaron varias ciudades.` | Pass (`correct_fix`) | `Ellos viajaron a México y visitaron varias ciudades.` | Pass (`correct_fix`) |
| `Yo fui al mercado y yo compré pan.` | `Fui al mercado y compré pan.` | `Yo fui al mercado y yo compré pan.` | `Yo fui al mercado y yo compré pan.` -> `Fui al mercado y compré pan.` | No | `Fui al mercado y compré pan.` | Pass (`correct_fix`) | `Fui al mercado y compré pan.` | Pass (`correct_fix`) |
| `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Nosotros salimos temprano y llegamos a tiempo.` | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Nosotros salimos temprano y nosotros llegamos a tiempo.` -> `Salimos temprano y llegamos a tiempo.` | No | `Salimos temprano y llegamos a tiempo.` | Fail (`ambiguous`) | `Salimos temprano y llegamos a tiempo.` | Fail (`ambiguous`) |

## Main Takeaways

The candidate fallback-specific prompt did not improve the benchmark overall. It produced the same total pass rate as the current reused prompt: 14/27 overall and 5/11 on fallback-triggered fixtures.

The candidate did help one important mixed-operation case: `mixed-personal-a-and-subjunctive`. In that fixture, the current fallback rewrote an already-correct first-pass result, while the candidate left it unchanged. That is a useful signal that fallback-specific restraint can help.

However, the candidate also lost one case that the current prompt passed: `false-friend-aplico-trabajo`. The current fallback produced the expected `Solicitó un trabajo.`, while the candidate produced `Se postuló a un trabajo.`. That may be a valid Spanish alternative, but under the benchmark it was not a pass.

The biggest practical point is that many failures are not fallback-prompt failures. They happen when fallback is not triggered, which means the fallback-specific prompt never runs. Those cases point instead to naturalness restraint, acceptable-alternative scoring, merge safety, and over-rewrite prevention.

The next sensible step is not to assume the candidate fallback prompt is better. It should be treated as inconclusive: promising in one restraint case, weaker in one lexical choice case, and irrelevant to non-triggered failures. Follow-up work should separate fallback-prompt quality from upstream naturalness and merge behaviour.
