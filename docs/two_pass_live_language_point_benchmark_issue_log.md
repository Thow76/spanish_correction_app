# Two-Pass Live Language-Point Benchmark: Issue Log

Source reports:

- `docs/two_pass_live_language_point_benchmark_findings.md`
- `docs/two_pass_integration_harness.md`
- `docs/two_pass_live_language_point_benchmark_key_findings_by_group.md`

This log records the benchmark cases that did not clearly pass. For this document:

- `pass` means `correct_fix` or `acceptable_no_change`.
- `fail` means `partial_fix`, `ambiguous`, `overcorrection`, `missed_issue`, or `error`.

## Fallback Pass Review Note

The fallback pass needs separate review before the pipeline is treated as validated. The current harness records fallback latency for every phrase, and that latency can add up even when the fallback/final output does not change the first-pass text. This raises a cost and latency question: if the fallback pass is often rechecking work without changing anything, it may be an expensive safety step rather than a consistently useful one.

There is also a quality concern. Several weak groups show the fallback/final path changing text in the failing cases:

- **Unnecessary Extras / Deletions**: the fallback/final output changed the repeated-pronoun cases, often by deleting more than the benchmark expected.
- **False Friends / Word Choice**: all failed cases changed after the first-pass text, including one case where the first pass had already produced the expected correction.
- **Phrase-Level Naturalness**: all failed cases changed in the fallback/final output, including cases where the model returned slash-separated alternatives instead of one corrected sentence.
- **Already Correct / Do Not Tinker**: the one failed case changed already-correct text.
- **Mixed Operations**: failed cases often involved the fallback/final path changing sentence meaning, structure, punctuation, or coordination after the first pass had handled the objective corrections.

The open question is whether the fallback pass is genuinely needed as another model call, or whether part of its job can be mechanised. In principle, the system is trying to compare the naturalness pass on the original text against the first-pass corrected text. That comparison may be partly mechanical: compare spans, check whether the naturalness suggestion still applies to the corrected text, and only call the model again when the code cannot safely decide. The fallback pass may currently be asking `gpt-5.1` to re-litigate work it has effectively just done, which could explain both extra latency and some unwanted rewrites.

Follow-up: review the fallback pass design, prompt, trigger conditions, and whether mechanical comparison can reduce or remove the fallback call. This should be investigated before treating fallback latency and fallback rewrites as acceptable production behaviour.

Additional harness/production distinction:

The current live benchmark harness deliberately calls the naturalness review twice for every phrase: once on the original text and once on the first-pass corrected text. It does this for measurement and comparison. The production two-pass pipeline does not do that. In production, the second naturalness call only happens when the first merge attempt has skipped edits or a conflict.

There is also no separate fallback prompt. The fallback path reuses the same `naturalnessReviewSpanish` prompt and the same `callNaturalnessReview` client. The only difference is the input text: the fallback call reviews the first-pass corrected text instead of the original submitted text. This means the fallback model call has no extra prompt guidance that says "you are resolving a fallback conflict" or "do not re-litigate a first-pass correction."

Follow-up question: add or run a production-mode harness variant that mirrors production more closely by only calling the fallback naturalness pass when the merge actually conflicts. That would separate two measurements:

- **diagnostic mode**: run both naturalness variants every time to compare behaviour.
- **production-mode benchmark**: run fallback only when conflict requires it, so latency and cost reflect the production pipeline more accurately.

## Accents / Diacritics: Grammar Pass Only For Phase One

Accents / Diacritics phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Vi mucho trafico ayer.` | `Vi mucho tráfico ayer.` | `Había mucho tráfico ayer.` | Changed | Fail | 739 | 2052 | 2135 | 4926 | $0.003293 |
| `Voy al parque manana por la tarde.` | `Voy al parque mañana por la tarde.` | `Voy al parque mañana por la tarde.` | Unchanged | Pass | 677 | 1177 | 972 | 2826 | $0.001687 |
| `El medico llego despues de la reunion.` | `El médico llegó después de la reunión.` | `El médico llegó después de la reunión.` | Unchanged | Pass | 579 | 1230 | 1020 | 2829 | $0.001691 |
| `Espana es un pais muy diverso.` | `España es un país muy diverso.` | `España es un país muy diverso.` | Unchanged | Pass | 683 | 2251 | 1898 | 4832 | $0.002438 |
| `Mi cumpleanos es en otono.` | `Mi cumpleaños es en otoño.` | `Mi cumpleaños es en otoño.` | Unchanged | Pass | 525 | 3378 | 1023 | 4926 | $0.003109 |
| `Compre cafe en una cafeteria pequena.` | `Compré café en una cafetería pequeña.` | `Compré café en una cafetería pequeña.` | Unchanged | Pass | 577 | 3687 | 972 | 5236 | $0.003827 |

## Collocations / Strong Calques

Collocations / Strong Calques phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Voy a hacer una decisión importante.` | `Voy a tomar una decisión importante.` | `Voy a tomar una decisión importante.` | Unchanged | Pass | 502 | 1878 | 930 | 3310 | $0.002305 |
| `Necesito hacer una decisión.` | `Necesito tomar una decisión.` | `Necesito tomar una decisión.` | Unchanged | Pass | 569 | 1636 | 1026 | 3231 | $0.002302 |
| `Tenemos que hacer atención.` | `Tenemos que prestar atención.` | `Tenemos que prestar atención.` | Unchanged | Pass | 578 | 2077 | 927 | 3582 | $0.002210 |
| `El equipo tomó una reunión.` | `El equipo tuvo una reunión.` | `El equipo tuvo una reunión.` | Unchanged | Pass | 713 | 1633 | 1032 | 3378 | $0.002383 |
| `Ella hizo un paseo.` | `Ella hizo un paseo.` | `Ella dio un paseo.` | Changed | Pass | 709 | 1864 | 1573 | 4146 | $0.002980 |
| `Esto hace sentido.` | `Esto hace sentido.` | `Esto tiene sentido.` | Changed | Pass | 582 | 1576 | 1560 | 3718 | $0.002868 |

## Accents / Diacritics + Collocations / Strong Calques (Independent Spans)

Accents / Diacritics + Collocations / Strong Calques (Independent Spans) phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | Unchanged | Pass | 728 | 1948 | 1021 | 3697 | $0.002515 |

## Verb Morphology Overlapping Collocations / Strong Calques

Verb Morphology Overlapping Collocations / Strong Calques phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ayer iso una decisión importante.` | `Ayer hizo una decisión importante.` | `Ayer tomó una decisión importante.` | Changed | Pass | 681 | 1946 | 1740 | 4367 | $0.002905 |

## Ambiguous / Repeated Span Safety

Ambiguous / Repeated Span Safety phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Vi mucho tráfico, y luego vi más tráfico.` | `Vi mucho tráfico, y luego vi más tráfico.` | `Había mucho tráfico, y luego había todavía más.` | Changed | Fail | 497 | 2435 | 2560 | 5492 | $0.003933 |

Breakdown:

The correct behaviour in this case was no change. The first pass behaved correctly because it left the sentence unchanged; there was no grammar, spelling, or punctuation error to fix. The naturalness pass then treated the repeated word `tráfico` as something to improve and rewrote the sentence. The rewritten sentence is understandable Spanish, but it is not a correction. It changes the learner's wording unnecessarily.

This is why the case is marked as a fail. Repetition is not automatically wrong, and in this test the repeated wording was valid. The practical issue is that the naturalness pass is too willing to smooth or rewrite valid wording. It needs stronger restraint for no-change cases and should only rewrite repeated wording when there is a clear naturalness problem.

## Gender / Number Agreement

Gender / Number Agreement phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Los niño come muchas manzana.` | `Los niños comen muchas manzanas.` | `Los niños comen muchas manzanas.` | Unchanged | Pass | 663 | 1190 | 1336 | 3189 | $0.001684 |
| `Las ventanas estaban abierto.` | `Las ventanas estaban abiertas.` | `Las ventanas estaban abiertas.` | Unchanged | Pass | 609 | 992 | 2063 | 3664 | $0.001650 |
| `Una puerta estaba cerrado.` | `Una puerta estaba cerrada.` | `Una puerta estaba cerrada.` | Unchanged | Pass | 671 | 1505 | 1036 | 3212 | $0.001659 |
| `Los billetes estaban caro.` | `Los billetes estaban caros.` | `Los billetes estaban caros.` | Unchanged | Pass | 587 | 947 | 1001 | 2535 | $0.001662 |
| `Las fechas estaban escrito sin tilde.` | `Las fechas estaban escritas sin tilde.` | `Las fechas estaban escritas sin tilde.` | Unchanged | Pass | 586 | 2550 | 1147 | 4283 | $0.002497 |

## Verb Agreement / Morphology

Verb Agreement / Morphology phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Mis compañeros y yo fue a la biblioteca.` | `Mis compañeros y yo fuimos a la biblioteca.` | `Mis compañeros y yo fuimos a la biblioteca.` | Unchanged | Pass | 569 | 975 | 907 | 2451 | $0.001709 |
| `Los niños come en el jardín.` | `Los niños comen en el jardín.` | `Los niños comen en el jardín.` | Unchanged | Pass | 527 | 1025 | 1428 | 2980 | $0.001675 |
| `Yo fui al mercado y compra pan.` | `Yo fui al mercado y compré pan.` | `Yo fui al mercado y compré pan.` | Unchanged | Pass | 536 | 1058 | 1214 | 2808 | $0.001697 |
| `Ellos estudia todas las noches.` | `Ellos estudian todas las noches.` | `Ellos estudian todas las noches.` | Unchanged | Pass | 704 | 1137 | 1219 | 3060 | $0.001687 |
| `Nosotros vive cerca del centro.` | `Nosotros vivimos cerca del centro.` | `Nosotros vivimos cerca del centro.` | Unchanged | Pass | 783 | 1233 | 1175 | 3191 | $0.001675 |

## Required Prepositions

Required Prepositions phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Insisto que revises el contrato.` | `Insisto en que revises el contrato.` | `Insisto en que revises el contrato.` | Unchanged | Pass | 604 | 1876 | 1117 | 3597 | $0.002567 |
| `La empresa que trabajo está cerca.` | `La empresa en que trabajo está cerca.` | `La empresa en la que trabajo está cerca.` | Changed | Pass | 988 | 2456 | 2352 | 5796 | $0.003184 |
| `Dependo que me ayudes mañana.` | `Dependo de que me ayudes mañana.` | `Dependo de que me ayudes mañana.` | Unchanged | Pass | 580 | 1839 | 1024 | 3443 | $0.002417 |
| `Pienso ti todos los días.` | `Pienso en ti todos los días.` | `Pienso en ti todos los días.` | Unchanged | Pass | 531 | 2057 | 1063 | 3651 | $0.002384 |
| `Soñé mi antiguo colegio.` | `Soñé con mi antiguo colegio.` | `Soñé con mi antiguo colegio.` | Unchanged | Pass | 794 | 2105 | 1055 | 3954 | $0.002474 |

## Articles / Determiners

Articles / Determiners phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Abrió puerta principal.` | `Abrió la puerta principal.` | `Abrió la puerta principal.` | Unchanged | Pass | 675 | 1773 | 993 | 3441 | $0.002359 |
| `Necesito comprar libro para la clase.` | `Necesito comprar un libro para la clase.` | `Necesito comprar un libro para la clase.` | Unchanged | Pass | 682 | 2252 | 1024 | 3958 | $0.002317 |
| `Profesor explicó regla otra vez.` | `El profesor explicó la regla otra vez.` | `El profesor explicó la regla otra vez.` | Unchanged | Pass | 579 | 2033 | 1138 | 3750 | $0.002511 |
| `Fui a tienda después del trabajo.` | `Fui a la tienda después del trabajo.` | `Fui a la la tienda después del trabajo.` | Changed | Fail | 1031 | 1598 | 918 | 3547 | $0.002267 |
| `Tengo cita con médico mañana.` | `Tengo cita con el médico mañana.` | `Tengo cita con el médico mañana.` | Unchanged | Fail | 988 | 1739 | 1146 | 3873 | $0.002372 |

Breakdown:

This group tests whether the system correctly adds or fixes Spanish articles such as `el`, `la`, `un`, and `una`. The group result was 3/5 pass and 2/5 fail. Most cases worked, but two cases exposed different problems.

In `article-la-tienda`, the input was `Fui a tienda después del trabajo.` and the expected output was `Fui a la tienda después del trabajo.` The first pass did the right thing by adding the missing article `la`. At that point, the sentence was correct. The final output then became `Fui a la la tienda después del trabajo.`, which means the article was inserted twice. This is not a first-pass failure. It is a merge/fallback or naturalness interaction problem: the correct article was added, but something later duplicated it.

In `article-cita-medico`, the input was `Tengo cita con médico mañana.` and the expected output was `Tengo una cita con el médico mañana.` There were two missing articles: `una cita` and `el médico`. The system fixed one of them by changing `médico` to `el médico`, but it did not change `cita` to `una cita`. The final output was `Tengo cita con el médico mañana.` This is a partial fix because the model spotted one missing article but missed the other.

This group therefore shows two different issues: article duplication after a correct fix, and incomplete correction when more than one article needs to be inserted. Article handling needs targeted follow-up around multiple missing articles in one sentence, insertions during merge/fallback, and preventing duplicated inserted words such as `la la`.

## Subjunctive / Mood

Subjunctive / Mood phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Es importante que estudias.` | `Es importante que estudies.` | `Es importante que estudies.` | Unchanged | Pass | 574 | 1011 | 1130 | 2715 | $0.001662 |
| `No creo que tiene razón.` | `No creo que tenga razón.` | `No creo que tenga razón.` | Unchanged | Pass | 571 | 2217 | 957 | 3745 | $0.002302 |
| `Quiero que vienes conmigo.` | `Quiero que vengas conmigo.` | `Quiero que vengas conmigo.` | Unchanged | Pass | 491 | 2238 | 1330 | 4059 | $0.002455 |
| `Era necesario que enviaba su parte.` | `Era necesario que enviara su parte.` | `Era necesario que enviara su informe.` | Changed | Fail | 680 | 2046 | 2491 | 5217 | $0.003557 |
| `Busco a alguien que habla francés.` | `Busco a alguien que hable francés.` | `Busco a alguien que hable francés.` | Unchanged | Pass | 749 | 3007 | 1189 | 4945 | $0.002747 |

## Required Additions / Omissions

Required Additions / Omissions phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Creo está bien terminar hoy.` | `Creo que está bien terminar hoy.` | `Creo que está bien terminar hoy.` | Unchanged | Pass | 578 | 1741 | 1228 | 3547 | $0.002352 |
| `A los niños expliqué la regla.` | `A los niños les expliqué la regla.` | `A los niños les expliqué la regla.` | Unchanged | Pass | 679 | 2253 | 1025 | 3957 | $0.002644 |
| `Vi mi profesor en la estación.` | `Vi a mi profesor en la estación.` | `Vi a mi profesor en la estación.` | Unchanged | Pass | 707 | 2019 | 1023 | 3749 | $0.002394 |
| `Levantó temprano ayer.` | `Se levantó temprano ayer.` | `Se levantó temprano ayer.` | Unchanged | Pass | 698 | 2029 | 1124 | 3851 | $0.002502 |
| `A Juan gusta el café.` | `A Juan le gusta el café.` | `A Juan le gusta el café.` | Unchanged | Pass | 577 | 2424 | 1160 | 4161 | $0.002492 |

## Unnecessary Extras / Deletions

Unnecessary Extras / Deletions phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Yo trabajo mucho y yo estudio por las noches.` | `Yo trabajo mucho y yo estudio por las noches.` | `Yo trabajo mucho y estudio por las noches.` | Changed | Pass | 704 | 1768 | 1903 | 4375 | $0.003302 |
| `Ellos viajaron a México y ellos visitaron varias ciudades.` | `Ellos viajaron a México y ellos visitaron varias ciudades.` | `Viajaron a México y visitaron varias ciudades.` | Changed | Fail | 671 | 1944 | 2455 | 5070 | $0.003330 |
| `A mí me gusta el café a mí.` | `A mí me gusta el café.` | `A mí me gusta el café.` | Unchanged | Pass | 588 | 2040 | 875 | 3503 | $0.002462 |
| `Yo fui al mercado y yo compré pan.` | `Yo fui al mercado y yo compré pan.` | `Fui al mercado y compré pan.` | Changed | Pass | 724 | 2425 | 1873 | 5022 | $0.003203 |
| `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Salimos temprano y llegamos a tiempo.` | Changed | Fail | 719 | 2065 | 1787 | 4571 | $0.003407 |

Breakdown:

This group tests removal of unnecessary extra words, especially repeated subject pronouns. In Spanish, subject pronouns such as `yo`, `ellos`, and `nosotros` are often optional because the verb ending already shows who is doing the action. Removing a subject pronoun can therefore be correct. The tricky question is whether the model removed only the unnecessary repeated pronoun, or whether it changed more than the benchmark expected.

In `delete-repeated-ellos-visitaron`, the input was `Ellos viajaron a México y ellos visitaron varias ciudades.` The expected output was `Ellos viajaron a México y visitaron varias ciudades.` The benchmark expected the system to remove only the second `ellos`, because it was repeated unnecessarily. The final output was `Viajaron a México y visitaron varias ciudades.` The system removed the repeated second `ellos`, but also removed the first `Ellos`. This may still be perfectly valid Spanish because `Viajaron` already tells us the subject is `ellos`, `ellas`, or `ustedes`. However, the benchmark did not list that as an acceptable alternative, so it was marked ambiguous rather than pass.

In `delete-repeated-nosotros`, the input was `Nosotros salimos temprano y nosotros llegamos a tiempo.` The expected output was `Nosotros salimos temprano y llegamos a tiempo.` The benchmark expected only the second `nosotros` to be removed. The final output was `Salimos temprano y llegamos a tiempo.` The system removed both subject pronouns. Again, this is probably valid Spanish because `salimos` and `llegamos` already show the subject, but the benchmark expected the first `Nosotros` to remain.

This may not be a model failure. It may be a benchmark-scoring issue. The model produced shorter, natural Spanish by dropping both subject pronouns, which is often acceptable. Because the benchmark only had one expected answer, it could not confidently mark these outputs as correct.

The follow-up is therefore not necessarily to fix the model. It may be to add acceptable alternatives for pro-drop Spanish, distinguish valid stronger deletion from true over-deletion, and keep testing pronoun deletion carefully because useful pronoun deletion can look like overcorrection if the benchmark is too strict.

## Ser / Estar / Haber

Ser / Estar / Haber phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Mi hermano está profesor.` | `Mi hermano es profesor.` | `Mi hermano es profesor.` | Unchanged | Pass | 655 | 1662 | 1432 | 3749 | $0.002280 |
| `En la sala son veinte personas.` | `En la sala hay veinte personas.` | `En la sala hay veinte personas.` | Unchanged | Pass | 501 | 1612 | 1126 | 3239 | $0.002425 |
| `Madrid está la capital de España.` | `Madrid es la capital de España.` | `Madrid es la capital de España.` | Unchanged | Pass | 680 | 1127 | 1061 | 2868 | $0.001675 |
| `Estoy muy contento con el resultado.` | `Estoy muy contento con el resultado.` | `Estoy muy contento con el resultado.` | Unchanged | Pass | 642 | 933 | 1063 | 2638 | $0.001687 |
| `La reunión es en la segunda planta.` | `La reunión es en la segunda planta.` | `La reunión es en la segunda planta.` | Unchanged | Pass | 534 | 1133 | 1247 | 2914 | $0.001687 |

## Impersonal Haber / Se

Impersonal Haber / Se phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Habían muchas personas en la entrada.` | `Había muchas personas en la entrada.` | `Había muchas personas en la entrada.` | Unchanged | Pass | 645 | 2605 | 1060 | 4310 | $0.002478 |
| `Hubieron varios problemas durante la reunión.` | `Hubo varios problemas durante la reunión.` | `Hubo varios problemas durante la reunión.` | Unchanged | Pass | 593 | 1980 | 893 | 3466 | $0.002547 |
| `Se vende pisos en el centro.` | `Se venden pisos en el centro.` | `Se venden pisos en el centro.` | Unchanged | Pass | 782 | 1969 | 921 | 3672 | $0.002415 |
| `Se necesita voluntarios para el evento.` | `Se necesitan voluntarios para el evento.` | `Se necesitan voluntarios para el evento.` | Unchanged | Pass | 761 | 1974 | 991 | 3726 | $0.002458 |
| `Habían varias cifras incorrectas.` | `Había varias cifras incorrectas.` | `Había varias cifras incorrectas.` | Unchanged | Pass | 685 | 2252 | 1136 | 4073 | $0.002435 |

## False Friends / Word Choice

False Friends / Word Choice phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Atendió la universidad en Madrid.` | `Asistió a la universidad en Madrid.` | `Estudió en la universidad en Madrid.` | Changed | Fail | 554 | 1945 | 1844 | 4343 | $0.003427 |
| `Aplicó para un trabajo.` | `Aplicó a un trabajo.` | `Se postuló a un trabajo.` | Changed | Fail | 552 | 2277 | 1947 | 4776 | $0.003573 |
| `Realicé que estaba equivocado.` | `Me di cuenta de que estaba equivocado.` | `Me di cuenta de que estaba equivocado.` | Unchanged | Pass | 679 | 1843 | 1024 | 3546 | $0.002397 |
| `Estoy embarazado por llegar tarde.` | `Estoy apenado por llegar tarde.` | `Siento llegar tarde.` | Changed | Fail | 676 | 2255 | 1941 | 4872 | $0.003798 |
| `Actualmente vivo en Londres.` | `Actualmente vivo en Londres.` | `Actualmente vivo en Londres.` | Unchanged | Pass | 682 | 923 | 1022 | 2627 | $0.001650 |

Breakdown:

This group tests whether the system can deal with words that look like English words but mean something different in Spanish, or cases where the learner has chosen the wrong Spanish word because of English influence. The group result was 2/5 pass and 3/5 fail, so this is not a clean pass and needs review.

In `false-friend-atendio-universidad`, the input was `Atendió la universidad en Madrid.` and the expected output was `Asistió a la universidad en Madrid.` The first pass produced the expected correction, so the sentence was already correct after pass one. The naturalness/fallback path then changed it again to `Estudió en la universidad en Madrid.` This is not necessarily bad Spanish, but it changes the meaning slightly. `Asistió a la universidad` means "attended university", while `Estudió en la universidad` means "studied at the university". They overlap, but they are not identical. This is a second-pass restraint issue because the naturalness pass re-edited something that had already been fixed correctly.

In `false-friend-aplico-trabajo`, the input was `Aplicó para un trabajo.` The expected output was `Solicitó un trabajo.`, but the final output was `Se postuló a un trabajo.` This may be valid Spanish depending on the target variety. `Solicitó un trabajo` and `Se postuló a un trabajo` are both plausible ways to express applying for a job. This may therefore be a benchmark issue rather than a model failure, because the benchmark only listed one acceptable answer. It needs manual review, and if `Se postuló a un trabajo` is acceptable for the target Spanish variety, it should be added as an acceptable alternative.

In `false-friend-embarazado`, the input was `Estoy embarazado por llegar tarde.` The expected output was `Me da vergüenza llegar tarde.`, but the final output was `Siento llegar tarde.` The system avoided the false friend `embarazado`, which is good, but the final meaning is weaker or different. `Me da vergüenza llegar tarde` means "I feel embarrassed about arriving late", while `Siento llegar tarde` means more like "I'm sorry for arriving late". This is a partial fix because the model recognised that `embarazado` was wrong in this context, but it did not preserve the intended meaning closely enough.

This group shows three separate issues: naturalness re-editing a correct first-pass fix, possible acceptable alternatives missing from the benchmark, and partial meaning preservation. It should not be treated as a simple model failure. The follow-up is to add acceptable alternatives where Spanish has multiple valid word choices, tighten the naturalness pass so it does not re-edit already-correct fixes, check false-friend corrections for meaning preservation, and keep this group as a review-heavy benchmark category rather than a simple exact-match test.

## Phrase-Level Naturalness

Phrase-Level Naturalness phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Tuvimos un buen tiempo.` | `Tuvimos un buen tiempo.` | `Lo pasamos bien.` | Changed | Pass | 502 | 1818 | 2353 | 4673 | $0.003495 |
| `Estoy corriendo tarde para la reunión.` | `Estoy llegando tarde para la reunión.` | `Voy a llegar tarde a la reunión.` | Changed | Fail | 697 | 2253 | 2304 | 5254 | $0.003648 |
| `Quiero pasar un buen tiempo.` | `Quiero pasar un buen tiempo.` | `Quiero pasarlo bien / pasar un buen rato.` | Changed | Fail | 637 | 1920 | 2160 | 4717 | $0.003245 |
| `¿Puedo tener una cerveza?` | `¿Puedo tener una cerveza?` | `¿Me pones una cerveza? / ¿Me das una cerveza? / ¿Me pones una caña?` | Changed | Fail | 712 | 2722 | 2559 | 5993 | $0.004275 |
| `Te llamo para atrás.` | `Te llamo para atrás.` | `Te devuelvo la llamada.` | Changed | Pass | 681 | 2364 | 2037 | 5082 | $0.003613 |

Breakdown:

This group tests whether the system can make a phrase sound natural in Spanish where the sentence may be understandable but influenced by English phrasing. The group result was 2/5 pass and 3/5 fail, so this group needs review. It is not a clean failure, but it is also not reliable enough yet.

In `naturalness-corriendo-tarde`, the input was `Estoy corriendo tarde para la reunión.` The expected output was `Voy tarde a la reunión.`, but the final output was `Voy a llegar tarde a la reunión.` This is probably acceptable Spanish and means "I'm going to be late to the meeting." The issue is that the benchmark expected one specific correction, but the model gave a different valid correction. This may be a benchmark-scoring issue rather than a model failure. If manual review confirms it is acceptable, `Voy a llegar tarde a la reunión.` should be added as an acceptable alternative.

In `naturalness-pasar-buen-tiempo`, the input was `Quiero pasar un buen tiempo.` The expected output was `Quiero pasarlo bien.`, but the final output was `Quiero pasarlo bien / pasar un buen rato.` The model identified the problem correctly: `pasar un buen tiempo` is an English-influenced phrase, and both suggested alternatives are natural Spanish. The problem is output format. The system should provide one final corrected sentence, not multiple options separated by a slash. This is not mainly a language-quality failure; it is an output-control failure.

In `naturalness-puedo-tener-cerveza`, the input was `¿Puedo tener una cerveza?` The expected output was `¿Me pones una cerveza?`, but the final output was `¿Me pones una cerveza? / ¿Me das una cerveza? / ¿Me pones una caña?` Again, the model understood the issue and replaced the English-like phrase with natural Spanish options. But it gave several alternatives instead of one final correction, which is not acceptable for the correction pipeline because the app needs one unified corrected text.

This group shows two main issues: valid alternatives are not always recognised by the benchmark, and the naturalness pass sometimes gives options instead of a final answer. The follow-up is to add acceptable alternatives for valid natural Spanish corrections and tighten the naturalness prompt/schema so it must return one corrected version, not multiple options.

## Valid Regional / Should Not Flag

Valid Regional / Should Not Flag phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Voy para casa ahora mismo.` | `Voy para la casa ahora mismo.` | `Voy para la casa ahora mismo.` | Unchanged | Fail | 681 | 986 | 1163 | 2830 | $0.001672 |
| `Vos tenés razón.` | `Vos tenés razón.` | `Vos tenés razón.` | Unchanged | Pass | 594 | 979 | 1165 | 2738 | $0.001650 |
| `Cojo el autobús cada mañana.` | `Cojo el autobús cada mañana.` | `Cojo el autobús cada mañana.` | Unchanged | Pass | 668 | 1048 | 1016 | 2732 | $0.001687 |
| `Esta mañana hablé con mi jefe.` | `Esta mañana hablé con mi jefe.` | `Esta mañana hablé con mi jefe.` | Unchanged | Pass | 563 | 1000 | 931 | 2494 | $0.001687 |
| `Dale, nos vemos más tarde.` | `Dale, nos vemos más tarde.` | `Dale, nos vemos más tarde.` | Unchanged | Pass | 592 | 1122 | 1029 | 2743 | $0.001687 |

Breakdown:

This group tests whether the system can leave valid regional Spanish alone. The group result was 4/5 pass and 1/5 fail, so it mostly passed but exposed one important boundary issue.

In `regional-voy-para-casa`, the input was `Voy para casa ahora mismo.` The expected behaviour was no change, because `Voy para casa ahora mismo.` can be valid regional Spanish. The first pass inserted `la`, changing `para casa` to `para la casa`, and the final output kept that change. So this issue started in the first pass, not the naturalness pass.

This matters because the system should not automatically standardise or alter regional phrasing just because another form also exists. The first-pass prompt is supposed to be conservative: it should correct objective grammar, spelling, and punctuation errors, not change valid regional Spanish. In this case, it crossed that boundary.

The first pass is mostly behaving well in this group, but it still needs stronger restraint for no-change cases involving regional Spanish. The system needs to distinguish genuinely incorrect article omission from valid article-free regional phrasing. This should be treated as a first-pass overcorrection issue, with follow-up prompt or test tightening so valid regional Spanish remains unchanged even if another version sounds more standard or more common elsewhere.

## Already Correct / Do Not Tinker

Already Correct / Do Not Tinker phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Buenos días, ¿cómo estás?` | `Buenos días, ¿cómo estás?` | `Buenos días, ¿cómo estás?` | Unchanged | Pass | 682 | 977 | 1068 | 2727 | $0.001675 |
| `Voy a hacer una pregunta al profesor.` | `Voy a hacer una pregunta al profesor.` | `Voy a hacer una pregunta al profesor.` | Unchanged | Pass | 579 | 1029 | 1122 | 2730 | $0.001687 |
| `Necesito tomar una foto del documento.` | `Necesito tomar una foto del documento.` | `Necesito sacar una foto / hacer una foto del documento.` | Changed | Fail | 577 | 2356 | 1228 | 4161 | $0.002567 |
| `Mañana visitaré a mi abuela.` | `Mañana visitaré a mi abuela.` | `Mañana visitaré a mi abuela.` | Unchanged | Pass | 580 | 1122 | 1023 | 2725 | $0.001713 |
| `Está lloviendo, así que me quedo en casa.` | `Está lloviendo, así que me quedo en casa.` | `Está lloviendo, así que me quedo en casa.` | Unchanged | Pass | 782 | 1023 | 1239 | 3044 | $0.001750 |

## Mixed Operations

Mixed Operations phrase results:

The `Second pass corrected phrase` column records the final output after the naturalness/fallback path. The `Fallback pass` column shows whether that final output changed the first-pass text. Each phrase was run once in the live benchmark.

| Phrase | First pass corrected phrase | Second pass corrected phrase | Fallback pass | Pass/fail | First pass latency (ms) | Second pass latency (ms) | Fallback latency (ms) | Total latency (ms) | Cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` | Changed | Fail | 830 | 2303 | 2149 | 5282 | $0.003954 |
| `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Unchanged | Pass | 1089 | 2687 | 1305 | 5081 | $0.003345 |
| `Vi mi profesor en la estación, y es importante que estudias.` | `Vi a mi profesor en la estación, y es importante que estudies.` | `Vi a mi profesor en la estación, y me dijo que era importante que estudiara.` | Changed | Fail | 1396 | 2561 | 2554 | 6511 | $0.004422 |
| `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | `Las ventanas estaban abiertas, y a mí me gusta el café a mí.` | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Changed | Pass | 888 | 2423 | 2184 | 5495 | $0.003805 |
| `Ellos estudia todas las noches, y creo está bien terminar hoy.` | `Ellos estudian todas las noches, y creo que está bien terminar hoy.` | `Estudian todas las noches, y creo que podemos terminar hoy.` | Changed | Fail | 643 | 3621 | 2544 | 6808 | $0.004864 |

Breakdown:

This group tests sentences where more than one kind of correction is needed at the same time. These are harder than single-error cases because the system has to make multiple corrections without letting one pass interfere with the other. The group result was 2/5 pass and 3/5 fail, so this group needs review. It is useful because it reveals interaction problems between the first pass, naturalness pass, merge, and fallback.

In `mixed-preposition-and-redundant-pronoun`, the input was `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` The expected output was `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` There were two intended fixes: add the missing preposition, changing `Insisto que` to `Insisto en que`, and remove the repeated second `yo`. The final output was `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` The system added the missing `en` and removed the repeated second `yo`, but it also removed the conjunction `y` after the comma. So the main corrections were made, but the sentence structure changed more than expected. This is why it was marked as a partial fix.

In `mixed-personal-a-and-subjunctive`, the input was `Vi mi profesor en la estación, y es importante que estudias.` The expected output was `Vi a mi profesor en la estación, y es importante que estudies.` There were two intended fixes: add personal `a`, changing `Vi mi profesor` to `Vi a mi profesor`, and correct the subjunctive from `estudias` to `estudies`. The first pass output was `Vi a mi profesor en la estación, y es importante que estudies.`, which was exactly what was expected. The final output was `Vi a mi profesor en la estación, y me dijo que era importante que estudiara.` The naturalness/fallback path changed the meaning and structure by introducing a new idea, `me dijo que`, meaning "he/she told me that." That was not in the original sentence. This is not a first-pass failure. It is a second-pass over-rewrite after a correct first-pass fix.

In `mixed-verb-agreement-and-missing-que`, the input was `Ellos estudia todas las noches, y creo está bien terminar hoy.` The expected output was `Ellos estudian todas las noches, y creo que está bien terminar hoy.` There were two intended fixes: correct verb agreement, changing `Ellos estudia` to `Ellos estudian`, and add the missing `que`, changing `creo está` to `creo que está`. The first pass output was `Ellos estudian todas las noches, y creo que está bien terminar hoy.`, again exactly what was expected. The final output was `Estudian todas las noches, y creo que podemos terminar hoy.` The final output removed the subject `Ellos` and changed the second clause from `está bien terminar hoy` to `podemos terminar hoy`. That changes the meaning and goes beyond correction.

Mixed cases show that the first pass often handles objective corrections correctly, even when there are multiple issues. The problem is that after the first pass has produced the right answer, the naturalness/fallback path may still rewrite the sentence. This creates three risks: sentence meaning changes, sentence structure changes, and small connector or punctuation changes appear even when not requested.

These mixed cases are useful stress tests and should stay in the benchmark because they reveal interaction problems that simple one-error cases do not. The follow-up is not to redesign the whole pipeline. It is to tighten naturalness/fallback behaviour so that when the first pass has already fixed the objective errors, the second pass does not rewrite the sentence unless there is a clear remaining naturalness issue.
