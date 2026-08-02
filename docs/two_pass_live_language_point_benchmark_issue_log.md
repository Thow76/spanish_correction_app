# Two-Pass Live Language-Point Benchmark: Issue Log

Source reports:

- `docs/two_pass_live_language_point_benchmark_findings.md`
- `docs/two_pass_integration_harness.md`
- `docs/two_pass_live_language_point_benchmark_key_findings_by_group.md`

This log records the benchmark cases that did not clearly pass. For this document:

- `pass` means `correct_fix` or `acceptable_no_change`.
- `not pass` means `partial_fix`, `ambiguous`, `overcorrection`, `missed_issue`, or `error`.

## Accents / Diacritics

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `clean-grammar-only` | `ambiguous` | `Vi mucho tráfico ayer.` | `Vi mucho tráfico ayer.` | `Había mucho tráfico ayer.` | The first pass made the intended accent correction, but the naturalness/fallback path rewrote the whole sentence. | Naturalness over-rewrite after correct first-pass fix | Tighten naturalness restraint so it does not rewrite already-correct first-pass text unless there is a clear naturalness defect. |

## Collocations / Strong Calques

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | All fixtures in this group clearly passed. | N/A | No immediate follow-up from this group. |

## Accents / Diacritics + Collocations / Strong Calques (Independent Spans)

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | The independent-span fixture clearly passed. | N/A | No immediate follow-up from this group. |

## Verb Morphology Overlapping Collocations / Strong Calques

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | The overlapping-span fixture clearly passed. | N/A | No immediate follow-up from this group. |

## Ambiguous / Repeated Span Safety

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `ambiguous-naturalness-span` | `overcorrection` | `Vi mucho tráfico, y luego vi más tráfico.` | `Vi mucho tráfico, y luego vi más tráfico.` | `Había mucho tráfico, y luego había todavía más.` | The input was already valid and expected to remain unchanged, but the naturalness path rewrote it. | Naturalness overcorrection on valid repeated wording | Tighten naturalness prompt restraint for valid repeated wording and no-change cases. |

Breakdown:

The correct behaviour in this case was no change. The first pass behaved correctly because it left the sentence unchanged; there was no grammar, spelling, or punctuation error to fix. The naturalness pass then treated the repeated word `tráfico` as something to improve and rewrote the sentence. The rewritten sentence is understandable Spanish, but it is not a correction. It changes the learner's wording unnecessarily.

This is why the case is marked as a fail. Repetition is not automatically wrong, and in this test the repeated wording was valid. The practical issue is that the naturalness pass is too willing to smooth or rewrite valid wording. It needs stronger restraint for no-change cases and should only rewrite repeated wording when there is a clear naturalness problem.

## Gender / Number Agreement

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | All fixtures in this group clearly passed. | N/A | No immediate follow-up from this group. |

## Verb Agreement / Morphology

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | All fixtures in this group clearly passed. | N/A | No immediate follow-up from this group. |

## Required Prepositions

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | All fixtures in this group clearly passed. | N/A | No immediate follow-up from this group. |

## Articles / Determiners

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `article-la-tienda` | `ambiguous` | `Fui a la tienda después del trabajo.` | `Fui a la tienda después del trabajo.` | `Fui a la la tienda después del trabajo.` | The first pass produced the correct article insertion, but the final output duplicated the article. | Merge or naturalness interaction around insertion | Investigate why an already-correct insertion became duplicated in the final output. |
| `article-cita-medico` | `partial_fix` | `Tengo una cita con el médico mañana.` | `Tengo cita con el médico mañana.` | `Tengo cita con el médico mañana.` | The model added `el médico` but missed `una cita`, so only one of the two required article insertions was made. | Partial first-pass insertion fix | Add targeted fixture/prompt evidence for multi-insertion article cases. |

Breakdown:

This group tests whether the system correctly adds or fixes Spanish articles such as `el`, `la`, `un`, and `una`. The group result was 3/5 pass and 2/5 not pass. Most cases worked, but two cases exposed different problems.

In `article-la-tienda`, the input was `Fui a tienda después del trabajo.` and the expected output was `Fui a la tienda después del trabajo.` The first pass did the right thing by adding the missing article `la`. At that point, the sentence was correct. The final output then became `Fui a la la tienda después del trabajo.`, which means the article was inserted twice. This is not a first-pass failure. It is a merge/fallback or naturalness interaction problem: the correct article was added, but something later duplicated it.

In `article-cita-medico`, the input was `Tengo cita con médico mañana.` and the expected output was `Tengo una cita con el médico mañana.` There were two missing articles: `una cita` and `el médico`. The system fixed one of them by changing `médico` to `el médico`, but it did not change `cita` to `una cita`. The final output was `Tengo cita con el médico mañana.` This is a partial fix because the model spotted one missing article but missed the other.

This group therefore shows two different issues: article duplication after a correct fix, and incomplete correction when more than one article needs to be inserted. Article handling needs targeted follow-up around multiple missing articles in one sentence, insertions during merge/fallback, and preventing duplicated inserted words such as `la la`.

## Subjunctive / Mood

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `subj-enviara` | `ambiguous` | `Era necesario que enviara su parte.` | `Era necesario que enviara su parte.` | `Era necesario que enviara su informe.` | The first pass made the intended subjunctive correction, but the final output changed `parte` to `informe`. | Naturalness/content shift after correct first-pass fix | Tighten restraint so naturalness does not replace content words after the objective grammar fix is already correct. |

## Required Additions / Omissions

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | All fixtures in this group clearly passed. | N/A | No immediate follow-up from this group. |

## Unnecessary Extras / Deletions

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `delete-repeated-ellos-visitaron` | `ambiguous` | `Ellos viajaron a México y visitaron varias ciudades.` | `Ellos viajaron a México y ellos visitaron varias ciudades.` | `Viajaron a México y visitaron varias ciudades.` | The final output removed both subject pronouns instead of only the repeated second `ellos`. This may still be valid Spanish because subject pronouns are often omitted. | Scoring limitation / valid alternative likely | Add acceptable alternative if manual review confirms the final output is acceptable. |
| `delete-repeated-nosotros` | `ambiguous` | `Nosotros salimos temprano y llegamos a tiempo.` | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Salimos temprano y llegamos a tiempo.` | The final output removed both subject pronouns instead of only the repeated second `nosotros`. This may still be valid Spanish because subject pronouns are often omitted. | Scoring limitation / valid alternative likely | Add acceptable alternative if manual review confirms the final output is acceptable. |

Breakdown:

This group tests removal of unnecessary extra words, especially repeated subject pronouns. In Spanish, subject pronouns such as `yo`, `ellos`, and `nosotros` are often optional because the verb ending already shows who is doing the action. Removing a subject pronoun can therefore be correct. The tricky question is whether the model removed only the unnecessary repeated pronoun, or whether it changed more than the benchmark expected.

In `delete-repeated-ellos-visitaron`, the input was `Ellos viajaron a México y ellos visitaron varias ciudades.` The expected output was `Ellos viajaron a México y visitaron varias ciudades.` The benchmark expected the system to remove only the second `ellos`, because it was repeated unnecessarily. The final output was `Viajaron a México y visitaron varias ciudades.` The system removed the repeated second `ellos`, but also removed the first `Ellos`. This may still be perfectly valid Spanish because `Viajaron` already tells us the subject is `ellos`, `ellas`, or `ustedes`. However, the benchmark did not list that as an acceptable alternative, so it was marked ambiguous rather than pass.

In `delete-repeated-nosotros`, the input was `Nosotros salimos temprano y nosotros llegamos a tiempo.` The expected output was `Nosotros salimos temprano y llegamos a tiempo.` The benchmark expected only the second `nosotros` to be removed. The final output was `Salimos temprano y llegamos a tiempo.` The system removed both subject pronouns. Again, this is probably valid Spanish because `salimos` and `llegamos` already show the subject, but the benchmark expected the first `Nosotros` to remain.

This may not be a model failure. It may be a benchmark-scoring issue. The model produced shorter, natural Spanish by dropping both subject pronouns, which is often acceptable. Because the benchmark only had one expected answer, it could not confidently mark these outputs as correct.

The follow-up is therefore not necessarily to fix the model. It may be to add acceptable alternatives for pro-drop Spanish, distinguish valid stronger deletion from true over-deletion, and keep testing pronoun deletion carefully because useful pronoun deletion can look like overcorrection if the benchmark is too strict.

## Ser / Estar / Haber

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | All fixtures in this group clearly passed. | N/A | No immediate follow-up from this group. |

## Impersonal Haber / Se

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| None recorded | `pass` | N/A | N/A | N/A | All fixtures in this group clearly passed. | N/A | No immediate follow-up from this group. |

## False Friends / Word Choice

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `false-friend-atendio-universidad` | `ambiguous` | `Asistió a la universidad en Madrid.` | `Asistió a la universidad en Madrid.` | `Estudió en la universidad en Madrid.` | The first pass produced the expected correction, but the naturalness pass re-edited it to a different wording. | Naturalness re-edits already-correct first-pass fix | Tell naturalness to leave already-correct first-pass fixes alone unless there is a remaining clear naturalness issue. |
| `false-friend-aplico-trabajo` | `ambiguous` | `Solicitó un trabajo.` | `Aplicó a un trabajo.` | `Se postuló a un trabajo.` | The final output may be a valid alternative, but it differs from the expected benchmark answer. | Possible acceptable alternative / lexical variation | Manually review and add acceptable alternatives if valid for the target Spanish variety. |
| `false-friend-embarazado` | `partial_fix` | `Me da vergüenza llegar tarde.` | `Estoy apenado por llegar tarde.` | `Siento llegar tarde.` | The final output avoids the false friend but does not match the expected meaning closely enough. | Partial lexical correction | Decide whether the expected correction should be stricter or whether more acceptable alternatives are needed. |

Breakdown:

This group tests whether the system can deal with words that look like English words but mean something different in Spanish, or cases where the learner has chosen the wrong Spanish word because of English influence. The group result was 2/5 pass and 3/5 not pass, so this is not a clean pass and needs review.

In `false-friend-atendio-universidad`, the input was `Atendió la universidad en Madrid.` and the expected output was `Asistió a la universidad en Madrid.` The first pass produced the expected correction, so the sentence was already correct after pass one. The naturalness/fallback path then changed it again to `Estudió en la universidad en Madrid.` This is not necessarily bad Spanish, but it changes the meaning slightly. `Asistió a la universidad` means "attended university", while `Estudió en la universidad` means "studied at the university". They overlap, but they are not identical. This is a second-pass restraint issue because the naturalness pass re-edited something that had already been fixed correctly.

In `false-friend-aplico-trabajo`, the input was `Aplicó para un trabajo.` The expected output was `Solicitó un trabajo.`, but the final output was `Se postuló a un trabajo.` This may be valid Spanish depending on the target variety. `Solicitó un trabajo` and `Se postuló a un trabajo` are both plausible ways to express applying for a job. This may therefore be a benchmark issue rather than a model failure, because the benchmark only listed one acceptable answer. It needs manual review, and if `Se postuló a un trabajo` is acceptable for the target Spanish variety, it should be added as an acceptable alternative.

In `false-friend-embarazado`, the input was `Estoy embarazado por llegar tarde.` The expected output was `Me da vergüenza llegar tarde.`, but the final output was `Siento llegar tarde.` The system avoided the false friend `embarazado`, which is good, but the final meaning is weaker or different. `Me da vergüenza llegar tarde` means "I feel embarrassed about arriving late", while `Siento llegar tarde` means more like "I'm sorry for arriving late". This is a partial fix because the model recognised that `embarazado` was wrong in this context, but it did not preserve the intended meaning closely enough.

This group shows three separate issues: naturalness re-editing a correct first-pass fix, possible acceptable alternatives missing from the benchmark, and partial meaning preservation. It should not be treated as a simple model failure. The follow-up is to add acceptable alternatives where Spanish has multiple valid word choices, tighten the naturalness pass so it does not re-edit already-correct fixes, check false-friend corrections for meaning preservation, and keep this group as a review-heavy benchmark category rather than a simple exact-match test.

## Phrase-Level Naturalness

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `naturalness-corriendo-tarde` | `partial_fix` | `Voy tarde a la reunión.` | `Estoy llegando tarde para la reunión.` | `Voy a llegar tarde a la reunión.` | The final output is probably acceptable Spanish, but it differs from the single expected benchmark answer. | Possible acceptable alternative / scoring limitation | Add acceptable alternative if manual review confirms it is valid. |
| `naturalness-pasar-buen-tiempo` | `ambiguous` | `Quiero pasarlo bien.` | `Quiero pasar un buen tiempo.` | `Quiero pasarlo bien / pasar un buen rato.` | The final output gives slash-separated alternatives instead of one clean correction. | Naturalness output format problem | Tighten naturalness prompt/schema expectations so final corrected text is a single correction, not a list of options. |
| `naturalness-puedo-tener-cerveza` | `ambiguous` | `¿Me pones una cerveza?` | `¿Puedo tener una cerveza?` | `¿Me pones una cerveza? / ¿Me das una cerveza? / ¿Me pones una caña?` | The final output includes several alternatives instead of one clean correction. | Naturalness output format problem | Tighten naturalness prompt/schema expectations so final corrected text is a single correction, not a list of options. |

Breakdown:

This group tests whether the system can make a phrase sound natural in Spanish where the sentence may be understandable but influenced by English phrasing. The group result was 2/5 pass and 3/5 not pass, so this group needs review. It is not a clean failure, but it is also not reliable enough yet.

In `naturalness-corriendo-tarde`, the input was `Estoy corriendo tarde para la reunión.` The expected output was `Voy tarde a la reunión.`, but the final output was `Voy a llegar tarde a la reunión.` This is probably acceptable Spanish and means "I'm going to be late to the meeting." The issue is that the benchmark expected one specific correction, but the model gave a different valid correction. This may be a benchmark-scoring issue rather than a model failure. If manual review confirms it is acceptable, `Voy a llegar tarde a la reunión.` should be added as an acceptable alternative.

In `naturalness-pasar-buen-tiempo`, the input was `Quiero pasar un buen tiempo.` The expected output was `Quiero pasarlo bien.`, but the final output was `Quiero pasarlo bien / pasar un buen rato.` The model identified the problem correctly: `pasar un buen tiempo` is an English-influenced phrase, and both suggested alternatives are natural Spanish. The problem is output format. The system should provide one final corrected sentence, not multiple options separated by a slash. This is not mainly a language-quality failure; it is an output-control failure.

In `naturalness-puedo-tener-cerveza`, the input was `¿Puedo tener una cerveza?` The expected output was `¿Me pones una cerveza?`, but the final output was `¿Me pones una cerveza? / ¿Me das una cerveza? / ¿Me pones una caña?` Again, the model understood the issue and replaced the English-like phrase with natural Spanish options. But it gave several alternatives instead of one final correction, which is not acceptable for the correction pipeline because the app needs one unified corrected text.

This group shows two main issues: valid alternatives are not always recognised by the benchmark, and the naturalness pass sometimes gives options instead of a final answer. The follow-up is to add acceptable alternatives for valid natural Spanish corrections and tighten the naturalness prompt/schema so it must return one corrected version, not multiple options.

## Valid Regional / Should Not Flag

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `regional-voy-para-casa` | `overcorrection` | `Voy para casa ahora mismo.` | `Voy para la casa ahora mismo.` | `Voy para la casa ahora mismo.` | The input was valid regional Spanish, but the first pass inserted an unnecessary article. | First-pass overcorrection on valid regional Spanish | Tighten first-pass restraint around valid regional Spanish and already-correct inputs. |

Breakdown:

This group tests whether the system can leave valid regional Spanish alone. The group result was 4/5 pass and 1/5 not pass, so it mostly passed but exposed one important boundary issue.

In `regional-voy-para-casa`, the input was `Voy para casa ahora mismo.` The expected behaviour was no change, because `Voy para casa ahora mismo.` can be valid regional Spanish. The first pass inserted `la`, changing `para casa` to `para la casa`, and the final output kept that change. So this issue started in the first pass, not the naturalness pass.

This matters because the system should not automatically standardise or alter regional phrasing just because another form also exists. The first-pass prompt is supposed to be conservative: it should correct objective grammar, spelling, and punctuation errors, not change valid regional Spanish. In this case, it crossed that boundary.

The first pass is mostly behaving well in this group, but it still needs stronger restraint for no-change cases involving regional Spanish. The system needs to distinguish genuinely incorrect article omission from valid article-free regional phrasing. This should be treated as a first-pass overcorrection issue, with follow-up prompt or test tightening so valid regional Spanish remains unchanged even if another version sounds more standard or more common elsewhere.

## Already Correct / Do Not Tinker

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `correct-tomar-foto` | `overcorrection` | `Necesito tomar una foto del documento.` | `Necesito tomar una foto del documento.` | `Necesito sacar una foto / hacer una foto del documento.` | The input was already correct, but the naturalness path changed it and produced slash-separated alternatives. | Naturalness overcorrection on already-correct input | Tighten naturalness no-change restraint and prohibit slash-separated alternatives in final corrected text. |

## Mixed Operations

| Fixture | Score | Expected | First pass | Final output | What happened | Issue type | Follow-up |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `mixed-preposition-and-redundant-pronoun` | `partial_fix` | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` | The final output fixed the preposition and repeated pronoun, but changed punctuation/coordination by removing `y`. | Partial mixed-operation fix / possible style shift | Manually review whether the final output should be accepted or whether the benchmark should require the conjunction to remain. |
| `mixed-personal-a-and-subjunctive` | `ambiguous` | `Vi a mi profesor en la estación, y es importante que estudies.` | `Vi a mi profesor en la estación, y es importante que estudies.` | `Vi a mi profesor en la estación, y me dijo que era importante que estudiara.` | The first pass made the expected corrections, but the naturalness/fallback path changed the sentence meaning and structure. | Naturalness/content shift after correct first-pass fix | Tighten naturalness restraint after first-pass corrections. |
| `mixed-verb-agreement-and-missing-que` | `ambiguous` | `Ellos estudian todas las noches, y creo que está bien terminar hoy.` | `Ellos estudian todas las noches, y creo que está bien terminar hoy.` | `Estudian todas las noches, y creo que podemos terminar hoy.` | The first pass made the expected corrections, but the final output removed the subject and changed the second clause. | Naturalness/content shift after correct first-pass fix | Tighten naturalness restraint and add acceptable alternatives only if the final output is judged acceptable. |

Breakdown:

This group tests sentences where more than one kind of correction is needed at the same time. These are harder than single-error cases because the system has to make multiple corrections without letting one pass interfere with the other. The group result was 2/5 pass and 3/5 not pass, so this group needs review. It is useful because it reveals interaction problems between the first pass, naturalness pass, merge, and fallback.

In `mixed-preposition-and-redundant-pronoun`, the input was `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` The expected output was `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` There were two intended fixes: add the missing preposition, changing `Insisto que` to `Insisto en que`, and remove the repeated second `yo`. The final output was `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` The system added the missing `en` and removed the repeated second `yo`, but it also removed the conjunction `y` after the comma. So the main corrections were made, but the sentence structure changed more than expected. This is why it was marked as a partial fix.

In `mixed-personal-a-and-subjunctive`, the input was `Vi mi profesor en la estación, y es importante que estudias.` The expected output was `Vi a mi profesor en la estación, y es importante que estudies.` There were two intended fixes: add personal `a`, changing `Vi mi profesor` to `Vi a mi profesor`, and correct the subjunctive from `estudias` to `estudies`. The first pass output was `Vi a mi profesor en la estación, y es importante que estudies.`, which was exactly what was expected. The final output was `Vi a mi profesor en la estación, y me dijo que era importante que estudiara.` The naturalness/fallback path changed the meaning and structure by introducing a new idea, `me dijo que`, meaning "he/she told me that." That was not in the original sentence. This is not a first-pass failure. It is a second-pass over-rewrite after a correct first-pass fix.

In `mixed-verb-agreement-and-missing-que`, the input was `Ellos estudia todas las noches, y creo está bien terminar hoy.` The expected output was `Ellos estudian todas las noches, y creo que está bien terminar hoy.` There were two intended fixes: correct verb agreement, changing `Ellos estudia` to `Ellos estudian`, and add the missing `que`, changing `creo está` to `creo que está`. The first pass output was `Ellos estudian todas las noches, y creo que está bien terminar hoy.`, again exactly what was expected. The final output was `Estudian todas las noches, y creo que podemos terminar hoy.` The final output removed the subject `Ellos` and changed the second clause from `está bien terminar hoy` to `podemos terminar hoy`. That changes the meaning and goes beyond correction.

Mixed cases show that the first pass often handles objective corrections correctly, even when there are multiple issues. The problem is that after the first pass has produced the right answer, the naturalness/fallback path may still rewrite the sentence. This creates three risks: sentence meaning changes, sentence structure changes, and small connector or punctuation changes appear even when not requested.

These mixed cases are useful stress tests and should stay in the benchmark because they reveal interaction problems that simple one-error cases do not. The follow-up is not to redesign the whole pipeline. It is to tighten naturalness/fallback behaviour so that when the first pass has already fixed the objective errors, the second pass does not rewrite the sentence unless there is a clear remaining naturalness issue.
