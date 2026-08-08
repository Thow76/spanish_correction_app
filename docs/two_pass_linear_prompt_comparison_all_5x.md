# Two-Pass Linear (Serial) Execution Flow (issue #128)

## Methodology (issue #132)

**This is a proof-of-concept report for a SERIAL two-pass architecture, not the production parallel/fallback pipeline.** Numbers here describe a prototype under evaluation, not production behavior — for the production-equivalent pipeline's own report, see `buildLinearPipelineComparisonReport` (linear vs. parallel, side by side) or `two_pass_fallback_pipeline_comparison_harness.dart`'s reports.

- **Pass 1** corrects grammar, spelling, and punctuation using the revised first-pass prompt (issue #126, `linearFirstPassPrompt`, sourced from `Two-Pass_Prompt_Revision_Summary.docx`) with model `gpt-4.1`.
- **Pass 2** is a lexical-transfer review using the revised second-pass prompt (issue #127, `linearSecondPassPrompt`, same source document) with model `gpt-5.1`. Pass 2 reviews Pass 1's OWN corrected text, never the original submitted text.
- **No fallback path**: production's parallel pipeline re-runs naturalness against the first-pass output only when its concurrent merge conflicts. This serial flow never needs that — Pass 2 always reviews the exact text it will be merged into, so there is nothing left to fall back from.
- **No parallel merge step**: Pass 1 and Pass 2 run one after another, never concurrently, so there are never two independent naturalness calls to reconcile the way production's pipeline has.
- **Purpose**: measure whether this simpler serial architecture is as reliable, as fast, and as cheap as production's parallel + conditional-fallback design.

## Run configuration

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture count: `85`
- Total runs: `425`
- Generated: 2026-08-08T12:45:05.308620Z

## Fixture summary

Pass rate is `passed/runs`; "distinct outputs" lists every unique final output produced across a fixture's runs — more than one entry means the model was not stable for that fixture.

| Fixture | Language point | Runs | Pass rate | Distinct final outputs | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| clean-grammar-only | Accents / Diacritics | 5 | 0/5 | `Había mucho tráfico ayer.` | 11694 | $0.010879 |
| naturalness-only | Collocations / Strong Calques | 5 | 5/5 | `Voy a tomar una decisión importante.` | 7332 | $0.006921 |
| grammar-and-naturalness-independent | Accents / Diacritics + Collocations / Strong Calques (independent spans) | 5 | 5/5 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | 6528 | $0.007371 |
| grammar-overlaps-naturalness | Verb Morphology (spelling) overlapping Collocations / Strong Calques | 5 | 5/5 | `Ayer tomó una decisión importante.` | 11763 | $0.010171 |
| ambiguous-naturalness-span | Ambiguous / Repeated Span Safety (Naturalness) | 5 | 4/5 | `Vi mucho tráfico y luego todavía más.`; `Vi mucho tráfico, y luego vi más tráfico.` | 8390 | $0.007930 |
| accent-manana | Accents / Diacritics | 5 | 5/5 | `Voy al parque mañana por la tarde.` | 6678 | $0.006978 |
| accent-medico | Accents / Diacritics | 5 | 5/5 | `El médico llegó después de la reunión.` | 6961 | $0.006987 |
| accent-espana-pais | Accents / Diacritics | 5 | 5/5 | `España es un país muy diverso.` | 7209 | $0.006931 |
| accent-cumpleanos-otono | Accents / Diacritics | 5 | 5/5 | `Mi cumpleaños es en otoño.` | 8924 | $0.006885 |
| accent-cafe-cafeteria | Accents / Diacritics | 5 | 5/5 | `Compré café en una cafetería pequeña.` | 7394 | $0.007024 |
| agreement-ninos-manzanas | Gender / Number Agreement | 5 | 5/5 | `Los niños comen muchas manzanas.` | 6980 | $0.006967 |
| agreement-ventanas-abiertas | Gender / Number Agreement | 5 | 5/5 | `Las ventanas estaban abiertas.` | 9133 | $0.006809 |
| agreement-puerta-cerrada | Gender / Number Agreement | 5 | 5/5 | `Una puerta estaba cerrada.` | 7818 | $0.006855 |
| agreement-billetes-caros | Gender / Number Agreement | 5 | 5/5 | `Los billetes estaban caros.` | 7225 | $0.006865 |
| agreement-fechas-escritas | Gender / Number Agreement | 5 | 5/5 | `Las fechas estaban escritas sin tilde.` | 7449 | $0.007024 |
| verb-nosotros-fuimos | Verb Agreement / Morphology | 5 | 5/5 | `Mis compañeros y yo fuimos a la biblioteca.` | 8007 | $0.007080 |
| verb-ninos-comen | Verb Agreement / Morphology | 5 | 5/5 | `Los niños comen en el jardín.` | 7083 | $0.006921 |
| verb-compre-pan | Verb Agreement / Morphology | 5 | 5/5 | `Yo fui al mercado y compré pan.` | 7598 | $0.007024 |
| verb-ellos-estudian | Verb Agreement / Morphology | 5 | 5/5 | `Ellos estudian todas las noches.` | 7288 | $0.006978 |
| verb-nosotros-vivimos | Verb Agreement / Morphology | 5 | 5/5 | `Nosotros vivimos cerca del centro.` | 8528 | $0.006921 |
| prep-insisto-en | Required Prepositions | 5 | 5/5 | `Insisto en que revises el contrato.` | 7682 | $0.007024 |
| prep-empresa-en-la-que | Required Prepositions | 5 | 1/5 | `La empresa en la que trabajo queda cerca.`; `La empresa donde trabajo está cerca de aquí.`; `La empresa en la que trabajo está cerca.`; `La empresa en la que trabajo está cerca de aquí.`; `La empresa donde trabajo está cerca.` | 12929 | $0.011045 |
| prep-dependo-de | Required Prepositions | 5 | 5/5 | `Dependo de que me ayudes mañana.` | 6783 | $0.007024 |
| prep-pienso-en-ti | Required Prepositions | 5 | 5/5 | `Pienso en ti todos los días.` | 6675 | $0.006967 |
| prep-sone-con | Required Prepositions | 5 | 5/5 | `Soñé con mi antiguo colegio.` | 7057 | $0.006967 |
| article-puerta-principal | Articles / Determiners | 5 | 5/5 | `Abrió la puerta principal.` | 7219 | $0.006855 |
| article-un-libro | Articles / Determiners | 5 | 5/5 | `Necesito comprar un libro para la clase.` | 6874 | $0.007024 |
| article-el-profesor-la-regla | Articles / Determiners | 5 | 5/5 | `El profesor explicó la regla otra vez.` | 7806 | $0.006958 |
| article-la-tienda | Articles / Determiners | 5 | 5/5 | `Fui a la tienda después del trabajo.` | 7390 | $0.007024 |
| article-cita-medico | Articles / Determiners | 5 | 5/5 | `Tengo una cita con el médico mañana.` | 7294 | $0.006958 |
| subj-estudies | Subjunctive / Mood | 5 | 5/5 | `Es importante que estudies.` | 6817 | $0.006865 |
| subj-tenga-razon | Subjunctive / Mood | 5 | 5/5 | `No creo que tenga razón.` | 6935 | $0.006865 |
| subj-vengas | Subjunctive / Mood | 5 | 5/5 | `Quiero que vengas conmigo.` | 6990 | $0.006921 |
| subj-enviara | Subjunctive / Mood | 5 | 3/5 | `Era necesario que enviara su parte.`; `Era necesario que enviara su informe.`; `Era necesario que enviara su parte del trabajo.` | 11899 | $0.010128 |
| subj-hable-frances | Subjunctive / Mood | 5 | 5/5 | `Busco a alguien que hable francés.` | 7787 | $0.007024 |
| missing-que-creo | Required Additions / Omissions | 5 | 5/5 | `Creo que está bien terminar hoy.` | 6691 | $0.006911 |
| missing-les-ninos | Required Additions / Omissions | 5 | 5/5 | `A los niños les expliqué la regla.` | 6780 | $0.006967 |
| missing-personal-a-profesor | Required Additions / Omissions | 5 | 5/5 | `Vi a mi profesor en la estación.` | 6979 | $0.006967 |
| missing-se-levanto | Required Additions / Omissions | 5 | 5/5 | `Se levantó temprano ayer.` | 7701 | $0.006865 |
| missing-le-gusta | Required Additions / Omissions | 5 | 5/5 | `A Juan le gusta el café.` | 7601 | $0.006911 |
| delete-repeated-yo-estudio | Unnecessary Extras / Deletions | 5 | 0/5 | `Yo trabajo mucho y yo estudio por la noche.`; `Yo trabajo mucho y yo estudio por las noches.` | 12924 | $0.010780 |
| delete-repeated-ellos-visitaron | Unnecessary Extras / Deletions | 5 | 5/5 | `Ellos viajaron a México y visitaron varias ciudades.` | 7903 | $0.008042 |
| delete-repeated-a-mi | Unnecessary Extras / Deletions | 5 | 5/5 | `A mí me gusta el café.` | 8416 | $0.006941 |
| delete-repeated-yo-compre | Unnecessary Extras / Deletions | 5 | 0/5 | `Yo fui al mercado y compré pan.` | 15375 | $0.009751 |
| delete-repeated-nosotros | Unnecessary Extras / Deletions | 5 | 5/5 | `Salimos temprano y llegamos a tiempo.`; `Nosotros salimos temprano y llegamos a tiempo.` | 11899 | $0.011213 |
| ser-profesor | Ser / Estar / Haber | 5 | 5/5 | `Mi hermano es profesor.` | 7082 | $0.006809 |
| haber-veinte-personas | Ser / Estar / Haber | 5 | 5/5 | `En la sala hay veinte personas.` | 7396 | $0.006921 |
| ser-capital-madrid | Ser / Estar / Haber | 5 | 5/5 | `Madrid es la capital de España.` | 7085 | $0.006921 |
| estar-contento | Ser / Estar / Haber | 5 | 5/5 | `Estoy muy contento con el resultado.` | 7189 | $0.006978 |
| ser-reunion-segunda-planta | Ser / Estar / Haber | 5 | 5/5 | `La reunión es en la segunda planta.` | 7802 | $0.007918 |
| haber-habia-personas | Impersonal Haber / Se | 5 | 5/5 | `Había muchas personas en la entrada.` | 8315 | $0.006978 |
| haber-hubo-problemas | Impersonal Haber / Se | 5 | 5/5 | `Hubo varios problemas durante la reunión.` | 6882 | $0.006978 |
| se-venden-pisos | Impersonal Haber / Se | 5 | 5/5 | `Se venden pisos en el centro.` | 7291 | $0.006921 |
| se-necesitan-voluntarios | Impersonal Haber / Se | 5 | 5/5 | `Se necesitan voluntarios para el evento.` | 7495 | $0.006978 |
| haber-habia-cifras | Impersonal Haber / Se | 5 | 5/5 | `Había varias cifras incorrectas.` | 8549 | $0.006921 |
| collocation-hacer-decision | Collocations / Strong Calques | 5 | 5/5 | `Necesito tomar una decisión.` | 7225 | $0.006865 |
| collocation-hacer-atencion | Collocations / Strong Calques | 5 | 5/5 | `Tenemos que prestar atención.` | 6815 | $0.006809 |
| collocation-tomar-reunion | Collocations / Strong Calques | 5 | 5/5 | `El equipo tuvo una reunión.` | 6786 | $0.006865 |
| collocation-hacer-paseo | Collocations / Strong Calques | 5 | 5/5 | `Ella dio un paseo.` | 10172 | $0.009219 |
| collocation-hace-sentido | Collocations / Strong Calques | 5 | 5/5 | `Esto tiene sentido.` | 7377 | $0.006753 |
| false-friend-atendio-universidad | False Friends / Word Choice | 5 | 5/5 | `Asistió a la universidad en Madrid.` | 6675 | $0.007024 |
| false-friend-aplico-trabajo | False Friends / Word Choice | 5 | 4/5 | `Se postuló para un trabajo.`; `Solicitó un trabajo.`; `Se postuló a un trabajo.` | 13439 | $0.011305 |
| false-friend-realice | False Friends / Word Choice | 5 | 5/5 | `Me di cuenta de que estaba equivocado.` | 7815 | $0.007024 |
| false-friend-embarazado | False Friends / Word Choice | 5 | 5/5 | `Estoy avergonzado por llegar tarde.` | 8297 | $0.007024 |
| false-friend-actualmente-control | False Friends / Word Choice | 5 | 5/5 | `Actualmente vivo en Londres.` | 6796 | $0.006809 |
| naturalness-buen-tiempo | Phrase-Level Naturalness | 5 | 0/5 | `Tuvimos un rato muy agradable.`; `Tuvimos un buen rato.` | 11296 | $0.010651 |
| naturalness-corriendo-tarde | Phrase-Level Naturalness | 5 | 0/5 | `Estoy llegando tarde a la reunión.`; `Voy a llegar tarde a la reunión.` | 11152 | $0.010741 |
| naturalness-pasar-buen-tiempo | Phrase-Level Naturalness | 5 | 0/5 | `Quiero pasar un buen rato.` | 7802 | $0.006921 |
| naturalness-puedo-tener-cerveza | Phrase-Level Naturalness | 5 | 0/5 | `¿Puedo tomar una cerveza?` | 7036 | $0.006921 |
| naturalness-llamar-para-atras | Phrase-Level Naturalness | 5 | 0/5 | `Te llamo más tarde.`; `Te llamo después.`; `Te llamo de nuevo.` | 9694 | $0.009486 |
| regional-voy-para-casa | Valid Regional / Should Not Flag | 5 | 1/5 | `Voy a casa ahora mismo.`; `Voy para casa ahora mismo.` | 12406 | $0.010991 |
| regional-vos-tenes | Valid Regional / Should Not Flag | 5 | 5/5 | `Vos tenés razón.` | 6108 | $0.006809 |
| regional-cojo-autobus | Valid Regional / Should Not Flag | 5 | 5/5 | `Cojo el autobús cada mañana.` | 6978 | $0.006978 |
| regional-preterite-esta-manana | Valid Regional / Should Not Flag | 5 | 5/5 | `Esta mañana hablé con mi jefe.` | 6946 | $0.006978 |
| regional-dale | Valid Regional / Should Not Flag | 5 | 5/5 | `Dale, nos vemos más tarde.` | 6781 | $0.006978 |
| correct-buenos-dias | Already Correct / Do Not Tinker | 5 | 5/5 | `Buenos días, ¿cómo estás?` | 7724 | $0.006921 |
| correct-hacer-pregunta | Already Correct / Do Not Tinker | 5 | 5/5 | `Voy a hacer una pregunta al profesor.` | 6758 | $0.006978 |
| correct-tomar-foto | Already Correct / Do Not Tinker | 5 | 4/5 | `Necesito tomar una foto del documento.`; `Necesito hacer una foto del documento.` | 9441 | $0.007647 |
| correct-visitar-abuela | Already Correct / Do Not Tinker | 5 | 5/5 | `Mañana visitaré a mi abuela.` | 7799 | $0.007090 |
| correct-me-quedo-en-casa | Already Correct / Do Not Tinker | 5 | 5/5 | `Está lloviendo, así que me quedo en casa.` | 7702 | $0.007259 |
| mixed-preposition-and-redundant-pronoun | Mixed Operations | 5 | 2/5 | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.`; `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`; `Insisto en que revises el contrato, mientras yo trabajo mucho y estudio por las noches.` | 18756 | $0.013206 |
| mixed-article-and-accent | Mixed Operations | 5 | 5/5 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | 8316 | $0.007566 |
| mixed-personal-a-and-subjunctive | Mixed Operations | 5 | 0/5 | `Vi a mi profesor en la estación y recordé que es importante estudiar.`; `Vi a mi profesor en la estación, y recordé que es importante estudiar.`; `Vi a mi profesor en la estación, y recordé que era importante que estudiara.` | 13739 | $0.011801 |
| mixed-gender-agreement-and-redundant-pronoun | Mixed Operations | 5 | 5/5 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | 7551 | $0.007279 |
| mixed-verb-agreement-and-missing-que | Mixed Operations | 5 | 0/5 | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | 11800 | $0.011540 |

## Accents / Diacritics

### clean-grammar-only

- Original text: `Vi mucho trafico ayer.`
- Expected corrected text: `Vi mucho tráfico ayer.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Había mucho tráfico ayer.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 769 | $0.000570 | 2133 | $0.001624 | 2902 | $0.002194 |
| 2 | 498 | $0.000570 | 1522 | $0.001524 | 2020 | $0.002094 |
| 3 | 550 | $0.000570 | 1643 | $0.001694 | 2193 | $0.002264 |
| 4 | 732 | $0.000570 | 1572 | $0.001554 | 2304 | $0.002124 |
| 5 | 537 | $0.000570 | 1738 | $0.001634 | 2275 | $0.002204 |

### accent-manana

- Original text: `Voy al parque manana por la tarde.`
- Expected corrected text: `Voy al parque mañana por la tarde.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Voy al parque mañana por la tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Voy al parque mañana por la tarde.` | (none) | `Voy al parque mañana por la tarde.` | correct_fix | Pass | Matches expected output. |
| 2 | `Voy al parque mañana por la tarde.` | (none) | `Voy al parque mañana por la tarde.` | correct_fix | Pass | Matches expected output. |
| 3 | `Voy al parque mañana por la tarde.` | (none) | `Voy al parque mañana por la tarde.` | correct_fix | Pass | Matches expected output. |
| 4 | `Voy al parque mañana por la tarde.` | (none) | `Voy al parque mañana por la tarde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Voy al parque mañana por la tarde.` | (none) | `Voy al parque mañana por la tarde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 478 | $0.000598 | 817 | $0.000798 | 1295 | $0.001396 |
| 2 | 578 | $0.000598 | 742 | $0.000798 | 1320 | $0.001396 |
| 3 | 555 | $0.000598 | 657 | $0.000798 | 1212 | $0.001396 |
| 4 | 633 | $0.000598 | 820 | $0.000798 | 1453 | $0.001396 |
| 5 | 579 | $0.000598 | 819 | $0.000798 | 1398 | $0.001396 |

### accent-medico

- Original text: `El medico llego despues de la reunion.`
- Expected corrected text: `El médico llegó después de la reunión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `El médico llegó después de la reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `El médico llegó después de la reunión.` | (none) | `El médico llegó después de la reunión.` | correct_fix | Pass | Matches expected output. |
| 2 | `El médico llegó después de la reunión.` | (none) | `El médico llegó después de la reunión.` | correct_fix | Pass | Matches expected output. |
| 3 | `El médico llegó después de la reunión.` | (none) | `El médico llegó después de la reunión.` | correct_fix | Pass | Matches expected output. |
| 4 | `El médico llegó después de la reunión.` | (none) | `El médico llegó después de la reunión.` | correct_fix | Pass | Matches expected output. |
| 5 | `El médico llegó después de la reunión.` | (none) | `El médico llegó después de la reunión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 575 | $0.000600 | 816 | $0.000798 | 1391 | $0.001397 |
| 2 | 567 | $0.000600 | 733 | $0.000798 | 1300 | $0.001397 |
| 3 | 574 | $0.000600 | 719 | $0.000798 | 1293 | $0.001397 |
| 4 | 800 | $0.000600 | 799 | $0.000798 | 1599 | $0.001397 |
| 5 | 580 | $0.000600 | 798 | $0.000798 | 1378 | $0.001397 |

### accent-espana-pais

- Original text: `Espana es un pais muy diverso.`
- Expected corrected text: `España es un país muy diverso.`
- Pass rate: 5/5
- Distinct final outputs:
  - `España es un país muy diverso.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `España es un país muy diverso.` | (none) | `España es un país muy diverso.` | correct_fix | Pass | Matches expected output. |
| 2 | `España es un país muy diverso.` | (none) | `España es un país muy diverso.` | correct_fix | Pass | Matches expected output. |
| 3 | `España es un país muy diverso.` | (none) | `España es un país muy diverso.` | correct_fix | Pass | Matches expected output. |
| 4 | `España es un país muy diverso.` | (none) | `España es un país muy diverso.` | correct_fix | Pass | Matches expected output. |
| 5 | `España es un país muy diverso.` | (none) | `España es un país muy diverso.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 554 | $0.000590 | 861 | $0.000796 | 1415 | $0.001386 |
| 2 | 479 | $0.000590 | 1019 | $0.000796 | 1498 | $0.001386 |
| 3 | 680 | $0.000590 | 754 | $0.000796 | 1434 | $0.001386 |
| 4 | 750 | $0.000590 | 715 | $0.000796 | 1465 | $0.001386 |
| 5 | 678 | $0.000590 | 719 | $0.000796 | 1397 | $0.001386 |

### accent-cumpleanos-otono

- Original text: `Mi cumpleanos es en otono.`
- Expected corrected text: `Mi cumpleaños es en otoño.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Mi cumpleaños es en otoño.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Mi cumpleaños es en otoño.` | (none) | `Mi cumpleaños es en otoño.` | correct_fix | Pass | Matches expected output. |
| 2 | `Mi cumpleaños es en otoño.` | (none) | `Mi cumpleaños es en otoño.` | correct_fix | Pass | Matches expected output. |
| 3 | `Mi cumpleaños es en otoño.` | (none) | `Mi cumpleaños es en otoño.` | correct_fix | Pass | Matches expected output. |
| 4 | `Mi cumpleaños es en otoño.` | (none) | `Mi cumpleaños es en otoño.` | correct_fix | Pass | Matches expected output. |
| 5 | `Mi cumpleaños es en otoño.` | (none) | `Mi cumpleaños es en otoño.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000582 | 1827 | $0.000795 | 2406 | $0.001377 |
| 2 | 591 | $0.000582 | 820 | $0.000795 | 1411 | $0.001377 |
| 3 | 1294 | $0.000582 | 736 | $0.000795 | 2030 | $0.001377 |
| 4 | 556 | $0.000582 | 923 | $0.000795 | 1479 | $0.001377 |
| 5 | 688 | $0.000582 | 910 | $0.000795 | 1598 | $0.001377 |

### accent-cafe-cafeteria

- Original text: `Compre cafe en una cafeteria pequena.`
- Expected corrected text: `Compré café en una cafetería pequeña.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Compré café en una cafetería pequeña.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Compré café en una cafetería pequeña.` | (none) | `Compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 2 | `Compré café en una cafetería pequeña.` | (none) | `Compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 3 | `Compré café en una cafetería pequeña.` | (none) | `Compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 4 | `Compré café en una cafetería pequeña.` | (none) | `Compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 5 | `Compré café en una cafetería pequeña.` | (none) | `Compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000606 | 716 | $0.000799 | 1295 | $0.001405 |
| 2 | 684 | $0.000606 | 714 | $0.000799 | 1398 | $0.001405 |
| 3 | 576 | $0.000606 | 822 | $0.000799 | 1398 | $0.001405 |
| 4 | 577 | $0.000606 | 921 | $0.000799 | 1498 | $0.001405 |
| 5 | 935 | $0.000606 | 870 | $0.000799 | 1805 | $0.001405 |

## Collocations / Strong Calques

### naturalness-only

- Original text: `Voy a hacer una decisión importante.`
- Expected corrected text: `Voy a tomar una decisión importante.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Voy a tomar una decisión importante.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Voy a tomar una decisión importante.` | (none) | `Voy a tomar una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 2 | `Voy a tomar una decisión importante.` | (none) | `Voy a tomar una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 3 | `Voy a tomar una decisión importante.` | (none) | `Voy a tomar una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 4 | `Voy a tomar una decisión importante.` | (none) | `Voy a tomar una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 5 | `Voy a tomar una decisión importante.` | (none) | `Voy a tomar una decisión importante.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 523 | $0.000588 | 619 | $0.000796 | 1142 | $0.001384 |
| 2 | 728 | $0.000588 | 1070 | $0.000796 | 1798 | $0.001384 |
| 3 | 801 | $0.000588 | 713 | $0.000796 | 1514 | $0.001384 |
| 4 | 664 | $0.000588 | 705 | $0.000796 | 1369 | $0.001384 |
| 5 | 786 | $0.000588 | 723 | $0.000796 | 1509 | $0.001384 |

### collocation-hacer-decision

- Original text: `Necesito hacer una decisión.`
- Expected corrected text: `Necesito tomar una decisión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Necesito tomar una decisión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito tomar una decisión.` | (none) | `Necesito tomar una decisión.` | correct_fix | Pass | Matches expected output. |
| 2 | `Necesito tomar una decisión.` | (none) | `Necesito tomar una decisión.` | correct_fix | Pass | Matches expected output. |
| 3 | `Necesito tomar una decisión.` | (none) | `Necesito tomar una decisión.` | correct_fix | Pass | Matches expected output. |
| 4 | `Necesito tomar una decisión.` | (none) | `Necesito tomar una decisión.` | correct_fix | Pass | Matches expected output. |
| 5 | `Necesito tomar una decisión.` | (none) | `Necesito tomar una decisión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 652 | $0.000578 | 820 | $0.000795 | 1472 | $0.001373 |
| 2 | 624 | $0.000578 | 775 | $0.000795 | 1399 | $0.001373 |
| 3 | 575 | $0.000578 | 1040 | $0.000795 | 1615 | $0.001373 |
| 4 | 556 | $0.000578 | 834 | $0.000795 | 1390 | $0.001373 |
| 5 | 569 | $0.000578 | 780 | $0.000795 | 1349 | $0.001373 |

### collocation-hacer-atencion

- Original text: `Tenemos que hacer atención.`
- Expected corrected text: `Tenemos que prestar atención.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Tenemos que prestar atención.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Tenemos que prestar atención.` | (none) | `Tenemos que prestar atención.` | correct_fix | Pass | Matches expected output. |
| 2 | `Tenemos que prestar atención.` | (none) | `Tenemos que prestar atención.` | correct_fix | Pass | Matches expected output. |
| 3 | `Tenemos que prestar atención.` | (none) | `Tenemos que prestar atención.` | correct_fix | Pass | Matches expected output. |
| 4 | `Tenemos que prestar atención.` | (none) | `Tenemos que prestar atención.` | correct_fix | Pass | Matches expected output. |
| 5 | `Tenemos que prestar atención.` | (none) | `Tenemos que prestar atención.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 516 | $0.000568 | 798 | $0.000794 | 1314 | $0.001362 |
| 2 | 573 | $0.000568 | 947 | $0.000794 | 1520 | $0.001362 |
| 3 | 472 | $0.000568 | 820 | $0.000794 | 1292 | $0.001362 |
| 4 | 675 | $0.000568 | 770 | $0.000794 | 1445 | $0.001362 |
| 5 | 571 | $0.000568 | 673 | $0.000794 | 1244 | $0.001362 |

### collocation-tomar-reunion

- Original text: `El equipo tomó una reunión.`
- Expected corrected text: `El equipo tuvo una reunión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `El equipo tuvo una reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `El equipo tuvo una reunión.` | (none) | `El equipo tuvo una reunión.` | correct_fix | Pass | Matches expected output. |
| 2 | `El equipo tuvo una reunión.` | (none) | `El equipo tuvo una reunión.` | correct_fix | Pass | Matches expected output. |
| 3 | `El equipo tuvo una reunión.` | (none) | `El equipo tuvo una reunión.` | correct_fix | Pass | Matches expected output. |
| 4 | `El equipo tuvo una reunión.` | (none) | `El equipo tuvo una reunión.` | correct_fix | Pass | Matches expected output. |
| 5 | `El equipo tuvo una reunión.` | (none) | `El equipo tuvo una reunión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 582 | $0.000578 | 714 | $0.000795 | 1296 | $0.001373 |
| 2 | 581 | $0.000578 | 783 | $0.000795 | 1364 | $0.001373 |
| 3 | 519 | $0.000578 | 711 | $0.000795 | 1230 | $0.001373 |
| 4 | 576 | $0.000578 | 820 | $0.000795 | 1396 | $0.001373 |
| 5 | 680 | $0.000578 | 820 | $0.000795 | 1500 | $0.001373 |

### collocation-hacer-paseo

- Original text: `Ella hizo un paseo.`
- Expected corrected text: `Ella dio un paseo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Ella dio un paseo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ella dio un paseo.` | (none) | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 605 | $0.000568 | 1304 | $0.001334 | 1909 | $0.001902 |
| 2 | 575 | $0.000568 | 1946 | $0.001444 | 2521 | $0.002012 |
| 3 | 681 | $0.000568 | 1535 | $0.001484 | 2216 | $0.002052 |
| 4 | 609 | $0.000568 | 1469 | $0.001324 | 2078 | $0.001892 |
| 5 | 615 | $0.000568 | 833 | $0.000794 | 1448 | $0.001362 |

### collocation-hace-sentido

- Original text: `Esto hace sentido.`
- Expected corrected text: `Esto tiene sentido.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Esto tiene sentido.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Esto tiene sentido.` | (none) | `Esto tiene sentido.` | correct_fix | Pass | Matches expected output. |
| 2 | `Esto tiene sentido.` | (none) | `Esto tiene sentido.` | correct_fix | Pass | Matches expected output. |
| 3 | `Esto tiene sentido.` | (none) | `Esto tiene sentido.` | correct_fix | Pass | Matches expected output. |
| 4 | `Esto tiene sentido.` | (none) | `Esto tiene sentido.` | correct_fix | Pass | Matches expected output. |
| 5 | `Esto tiene sentido.` | (none) | `Esto tiene sentido.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 667 | $0.000558 | 1021 | $0.000793 | 1688 | $0.001351 |
| 2 | 577 | $0.000558 | 945 | $0.000793 | 1522 | $0.001351 |
| 3 | 485 | $0.000558 | 685 | $0.000793 | 1170 | $0.001351 |
| 4 | 476 | $0.000558 | 1033 | $0.000793 | 1509 | $0.001351 |
| 5 | 566 | $0.000558 | 922 | $0.000793 | 1488 | $0.001351 |

## Accents / Diacritics + Collocations / Strong Calques (independent spans)

### grammar-and-naturalness-independent

- Original text: `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.`
- Expected corrected text: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- Pass rate: 5/5
- Distinct final outputs:
  - `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | (none) | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 2 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | (none) | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 3 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | (none) | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 4 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | (none) | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 5 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | (none) | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 548 | $0.000668 | 850 | $0.000806 | 1398 | $0.001474 |
| 2 | 521 | $0.000668 | 773 | $0.000806 | 1294 | $0.001474 |
| 3 | 669 | $0.000668 | 677 | $0.000806 | 1346 | $0.001474 |
| 4 | 530 | $0.000668 | 613 | $0.000806 | 1143 | $0.001474 |
| 5 | 627 | $0.000668 | 720 | $0.000806 | 1347 | $0.001474 |

## Verb Morphology (spelling) overlapping Collocations / Strong Calques

### grammar-overlaps-naturalness

- Original text: `Ayer iso una decisión importante.`
- Expected corrected text: `Ayer tomó una decisión importante.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Ayer tomó una decisión importante.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ayer hizo una decisión importante.` | hizo una decisión -> tomó una decisión | `Ayer tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 2 | `Ayer hizo una decisión importante.` | hizo una decisión -> tomó una decisión | `Ayer tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ayer hizo una decisión importante.` | hizo una decisión -> tomó una decisión | `Ayer tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 4 | `Ayer hizo una decisión importante.` | hizo una decisión -> tomó una decisión | `Ayer tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ayer hizo una decisión importante.` | hizo una decisión -> tomó una decisión | `Ayer tomó una decisión importante.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 626 | $0.000588 | 1570 | $0.001476 | 2196 | $0.002064 |
| 2 | 542 | $0.000588 | 1232 | $0.001376 | 1774 | $0.001964 |
| 3 | 577 | $0.000588 | 3376 | $0.001556 | 3953 | $0.002144 |
| 4 | 474 | $0.000588 | 1331 | $0.001376 | 1805 | $0.001964 |
| 5 | 562 | $0.000588 | 1473 | $0.001446 | 2035 | $0.002034 |

## Ambiguous / Repeated Span Safety (Naturalness)

### ambiguous-naturalness-span

- Original text: `Vi mucho tráfico, y luego vi más tráfico.`
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Vi mucho tráfico y luego todavía más.`
  - `Vi mucho tráfico, y luego vi más tráfico.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico, y luego vi más tráfico.` | Vi mucho tráfico, y luego vi más tráfico. -> Vi mucho tráfico y luego todavía más. | `Vi mucho tráfico y luego todavía más.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 589 | $0.000618 | 1561 | $0.001640 | 2150 | $0.002258 |
| 2 | 620 | $0.000618 | 1129 | $0.000800 | 1749 | $0.001418 |
| 3 | 677 | $0.000618 | 784 | $0.000800 | 1461 | $0.001418 |
| 4 | 613 | $0.000618 | 1021 | $0.000800 | 1634 | $0.001418 |
| 5 | 578 | $0.000618 | 818 | $0.000800 | 1396 | $0.001418 |

## Gender / Number Agreement

### agreement-ninos-manzanas

- Original text: `Los niño come muchas manzana.`
- Expected corrected text: `Los niños comen muchas manzanas.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Los niños comen muchas manzanas.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Los niños comen muchas manzanas.` | (none) | `Los niños comen muchas manzanas.` | correct_fix | Pass | Matches expected output. |
| 2 | `Los niños comen muchas manzanas.` | (none) | `Los niños comen muchas manzanas.` | correct_fix | Pass | Matches expected output. |
| 3 | `Los niños comen muchas manzanas.` | (none) | `Los niños comen muchas manzanas.` | correct_fix | Pass | Matches expected output. |
| 4 | `Los niños comen muchas manzanas.` | (none) | `Los niños comen muchas manzanas.` | correct_fix | Pass | Matches expected output. |
| 5 | `Los niños comen muchas manzanas.` | (none) | `Los niños comen muchas manzanas.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 505 | $0.000596 | 901 | $0.000798 | 1406 | $0.001393 |
| 2 | 551 | $0.000596 | 734 | $0.000798 | 1285 | $0.001393 |
| 3 | 476 | $0.000596 | 713 | $0.000798 | 1189 | $0.001393 |
| 4 | 577 | $0.000596 | 922 | $0.000798 | 1499 | $0.001393 |
| 5 | 643 | $0.000596 | 958 | $0.000798 | 1601 | $0.001393 |

### agreement-ventanas-abiertas

- Original text: `Las ventanas estaban abierto.`
- Expected corrected text: `Las ventanas estaban abiertas.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Las ventanas estaban abiertas.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Las ventanas estaban abiertas.` | (none) | `Las ventanas estaban abiertas.` | correct_fix | Pass | Matches expected output. |
| 2 | `Las ventanas estaban abiertas.` | (none) | `Las ventanas estaban abiertas.` | correct_fix | Pass | Matches expected output. |
| 3 | `Las ventanas estaban abiertas.` | (none) | `Las ventanas estaban abiertas.` | correct_fix | Pass | Matches expected output. |
| 4 | `Las ventanas estaban abiertas.` | (none) | `Las ventanas estaban abiertas.` | correct_fix | Pass | Matches expected output. |
| 5 | `Las ventanas estaban abiertas.` | (none) | `Las ventanas estaban abiertas.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 578 | $0.000568 | 922 | $0.000794 | 1500 | $0.001362 |
| 2 | 558 | $0.000568 | 2441 | $0.000794 | 2999 | $0.001362 |
| 3 | 616 | $0.000568 | 729 | $0.000794 | 1345 | $0.001362 |
| 4 | 562 | $0.000568 | 1229 | $0.000794 | 1791 | $0.001362 |
| 5 | 578 | $0.000568 | 920 | $0.000794 | 1498 | $0.001362 |

### agreement-puerta-cerrada

- Original text: `Una puerta estaba cerrado.`
- Expected corrected text: `Una puerta estaba cerrada.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Una puerta estaba cerrada.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Una puerta estaba cerrada.` | (none) | `Una puerta estaba cerrada.` | correct_fix | Pass | Matches expected output. |
| 2 | `Una puerta estaba cerrada.` | (none) | `Una puerta estaba cerrada.` | correct_fix | Pass | Matches expected output. |
| 3 | `Una puerta estaba cerrada.` | (none) | `Una puerta estaba cerrada.` | correct_fix | Pass | Matches expected output. |
| 4 | `Una puerta estaba cerrada.` | (none) | `Una puerta estaba cerrada.` | correct_fix | Pass | Matches expected output. |
| 5 | `Una puerta estaba cerrada.` | (none) | `Una puerta estaba cerrada.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 614 | $0.000576 | 887 | $0.000795 | 1501 | $0.001371 |
| 2 | 683 | $0.000576 | 857 | $0.000795 | 1540 | $0.001371 |
| 3 | 743 | $0.000576 | 851 | $0.000795 | 1594 | $0.001371 |
| 4 | 664 | $0.000576 | 902 | $0.000795 | 1566 | $0.001371 |
| 5 | 683 | $0.000576 | 934 | $0.000795 | 1617 | $0.001371 |

### agreement-billetes-caros

- Original text: `Los billetes estaban caro.`
- Expected corrected text: `Los billetes estaban caros.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Los billetes estaban caros.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Los billetes estaban caros.` | (none) | `Los billetes estaban caros.` | correct_fix | Pass | Matches expected output. |
| 2 | `Los billetes estaban caros.` | (none) | `Los billetes estaban caros.` | correct_fix | Pass | Matches expected output. |
| 3 | `Los billetes estaban caros.` | (none) | `Los billetes estaban caros.` | correct_fix | Pass | Matches expected output. |
| 4 | `Los billetes estaban caros.` | (none) | `Los billetes estaban caros.` | correct_fix | Pass | Matches expected output. |
| 5 | `Los billetes estaban caros.` | (none) | `Los billetes estaban caros.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 565 | $0.000578 | 923 | $0.000795 | 1488 | $0.001373 |
| 2 | 677 | $0.000578 | 922 | $0.000795 | 1599 | $0.001373 |
| 3 | 579 | $0.000578 | 817 | $0.000795 | 1396 | $0.001373 |
| 4 | 578 | $0.000578 | 818 | $0.000795 | 1396 | $0.001373 |
| 5 | 577 | $0.000578 | 769 | $0.000795 | 1346 | $0.001373 |

### agreement-fechas-escritas

- Original text: `Las fechas estaban escrito sin tilde.`
- Expected corrected text: `Las fechas estaban escritas sin tilde.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Las fechas estaban escritas sin tilde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Las fechas estaban escritas sin tilde.` | (none) | `Las fechas estaban escritas sin tilde.` | correct_fix | Pass | Matches expected output. |
| 2 | `Las fechas estaban escritas sin tilde.` | (none) | `Las fechas estaban escritas sin tilde.` | correct_fix | Pass | Matches expected output. |
| 3 | `Las fechas estaban escritas sin tilde.` | (none) | `Las fechas estaban escritas sin tilde.` | correct_fix | Pass | Matches expected output. |
| 4 | `Las fechas estaban escritas sin tilde.` | (none) | `Las fechas estaban escritas sin tilde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Las fechas estaban escritas sin tilde.` | (none) | `Las fechas estaban escritas sin tilde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 737 | $0.000606 | 712 | $0.000799 | 1449 | $0.001405 |
| 2 | 646 | $0.000606 | 851 | $0.000799 | 1497 | $0.001405 |
| 3 | 572 | $0.000606 | 930 | $0.000799 | 1502 | $0.001405 |
| 4 | 681 | $0.000606 | 822 | $0.000799 | 1503 | $0.001405 |
| 5 | 575 | $0.000606 | 923 | $0.000799 | 1498 | $0.001405 |

## Verb Agreement / Morphology

### verb-nosotros-fuimos

- Original text: `Mis compañeros y yo fue a la biblioteca.`
- Expected corrected text: `Mis compañeros y yo fuimos a la biblioteca.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Mis compañeros y yo fuimos a la biblioteca.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Mis compañeros y yo fuimos a la biblioteca.` | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | correct_fix | Pass | Matches expected output. |
| 2 | `Mis compañeros y yo fuimos a la biblioteca.` | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | correct_fix | Pass | Matches expected output. |
| 3 | `Mis compañeros y yo fuimos a la biblioteca.` | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | correct_fix | Pass | Matches expected output. |
| 4 | `Mis compañeros y yo fuimos a la biblioteca.` | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | correct_fix | Pass | Matches expected output. |
| 5 | `Mis compañeros y yo fuimos a la biblioteca.` | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 782 | $0.000616 | 823 | $0.000800 | 1605 | $0.001416 |
| 2 | 571 | $0.000616 | 820 | $0.000800 | 1391 | $0.001416 |
| 3 | 492 | $0.000616 | 802 | $0.000800 | 1294 | $0.001416 |
| 4 | 1196 | $0.000616 | 817 | $0.000800 | 2013 | $0.001416 |
| 5 | 681 | $0.000616 | 1023 | $0.000800 | 1704 | $0.001416 |

### verb-ninos-comen

- Original text: `Los niños come en el jardín.`
- Expected corrected text: `Los niños comen en el jardín.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Los niños comen en el jardín.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Los niños comen en el jardín.` | (none) | `Los niños comen en el jardín.` | correct_fix | Pass | Matches expected output. |
| 2 | `Los niños comen en el jardín.` | (none) | `Los niños comen en el jardín.` | correct_fix | Pass | Matches expected output. |
| 3 | `Los niños comen en el jardín.` | (none) | `Los niños comen en el jardín.` | correct_fix | Pass | Matches expected output. |
| 4 | `Los niños comen en el jardín.` | (none) | `Los niños comen en el jardín.` | correct_fix | Pass | Matches expected output. |
| 5 | `Los niños comen en el jardín.` | (none) | `Los niños comen en el jardín.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 576 | $0.000588 | 729 | $0.000796 | 1305 | $0.001384 |
| 2 | 568 | $0.000588 | 803 | $0.000796 | 1371 | $0.001384 |
| 3 | 590 | $0.000588 | 820 | $0.000796 | 1410 | $0.001384 |
| 4 | 781 | $0.000588 | 818 | $0.000796 | 1599 | $0.001384 |
| 5 | 581 | $0.000588 | 817 | $0.000796 | 1398 | $0.001384 |

### verb-compre-pan

- Original text: `Yo fui al mercado y compra pan.`
- Expected corrected text: `Yo fui al mercado y compré pan.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Yo fui al mercado y compré pan.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 2 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 3 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 4 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 5 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 676 | $0.000606 | 924 | $0.000799 | 1600 | $0.001405 |
| 2 | 578 | $0.000606 | 717 | $0.000799 | 1295 | $0.001405 |
| 3 | 689 | $0.000606 | 909 | $0.000799 | 1598 | $0.001405 |
| 4 | 684 | $0.000606 | 840 | $0.000799 | 1524 | $0.001405 |
| 5 | 553 | $0.000606 | 1028 | $0.000799 | 1581 | $0.001405 |

### verb-ellos-estudian

- Original text: `Ellos estudia todas las noches.`
- Expected corrected text: `Ellos estudian todas las noches.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Ellos estudian todas las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos estudian todas las noches.` | (none) | `Ellos estudian todas las noches.` | correct_fix | Pass | Matches expected output. |
| 2 | `Ellos estudian todas las noches.` | (none) | `Ellos estudian todas las noches.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ellos estudian todas las noches.` | (none) | `Ellos estudian todas las noches.` | correct_fix | Pass | Matches expected output. |
| 4 | `Ellos estudian todas las noches.` | (none) | `Ellos estudian todas las noches.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ellos estudian todas las noches.` | (none) | `Ellos estudian todas las noches.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 679 | $0.000598 | 929 | $0.000798 | 1608 | $0.001396 |
| 2 | 753 | $0.000598 | 883 | $0.000798 | 1636 | $0.001396 |
| 3 | 547 | $0.000598 | 706 | $0.000798 | 1253 | $0.001396 |
| 4 | 640 | $0.000598 | 656 | $0.000798 | 1296 | $0.001396 |
| 5 | 687 | $0.000598 | 808 | $0.000798 | 1495 | $0.001396 |

### verb-nosotros-vivimos

- Original text: `Nosotros vive cerca del centro.`
- Expected corrected text: `Nosotros vivimos cerca del centro.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Nosotros vivimos cerca del centro.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Nosotros vivimos cerca del centro.` | (none) | `Nosotros vivimos cerca del centro.` | correct_fix | Pass | Matches expected output. |
| 2 | `Nosotros vivimos cerca del centro.` | (none) | `Nosotros vivimos cerca del centro.` | correct_fix | Pass | Matches expected output. |
| 3 | `Nosotros vivimos cerca del centro.` | (none) | `Nosotros vivimos cerca del centro.` | correct_fix | Pass | Matches expected output. |
| 4 | `Nosotros vivimos cerca del centro.` | (none) | `Nosotros vivimos cerca del centro.` | correct_fix | Pass | Matches expected output. |
| 5 | `Nosotros vivimos cerca del centro.` | (none) | `Nosotros vivimos cerca del centro.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 679 | $0.000588 | 1028 | $0.000796 | 1707 | $0.001384 |
| 2 | 781 | $0.000588 | 817 | $0.000796 | 1598 | $0.001384 |
| 3 | 603 | $0.000588 | 794 | $0.000796 | 1397 | $0.001384 |
| 4 | 578 | $0.000588 | 1536 | $0.000796 | 2114 | $0.001384 |
| 5 | 679 | $0.000588 | 1033 | $0.000796 | 1712 | $0.001384 |

## Required Prepositions

### prep-insisto-en

- Original text: `Insisto que revises el contrato.`
- Expected corrected text: `Insisto en que revises el contrato.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Insisto en que revises el contrato.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Insisto en que revises el contrato.` | (none) | `Insisto en que revises el contrato.` | correct_fix | Pass | Matches expected output. |
| 2 | `Insisto en que revises el contrato.` | (none) | `Insisto en que revises el contrato.` | correct_fix | Pass | Matches expected output. |
| 3 | `Insisto en que revises el contrato.` | (none) | `Insisto en que revises el contrato.` | correct_fix | Pass | Matches expected output. |
| 4 | `Insisto en que revises el contrato.` | (none) | `Insisto en que revises el contrato.` | correct_fix | Pass | Matches expected output. |
| 5 | `Insisto en que revises el contrato.` | (none) | `Insisto en que revises el contrato.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 672 | $0.000606 | 821 | $0.000799 | 1493 | $0.001405 |
| 2 | 577 | $0.000606 | 756 | $0.000799 | 1333 | $0.001405 |
| 3 | 947 | $0.000606 | 923 | $0.000799 | 1870 | $0.001405 |
| 4 | 683 | $0.000606 | 1058 | $0.000799 | 1741 | $0.001405 |
| 5 | 643 | $0.000606 | 602 | $0.000799 | 1245 | $0.001405 |

### prep-empresa-en-la-que

- Original text: `La empresa que trabajo está cerca.`
- Expected corrected text: `La empresa en la que trabajo está cerca.`
- Pass rate: 1/5
- Distinct final outputs:
  - `La empresa en la que trabajo queda cerca.`
  - `La empresa donde trabajo está cerca de aquí.`
  - `La empresa en la que trabajo está cerca.`
  - `La empresa en la que trabajo está cerca de aquí.`
  - `La empresa donde trabajo está cerca.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `La empresa en la que trabajo está cerca.` | está cerca -> queda cerca | `La empresa en la que trabajo queda cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `La empresa en la que trabajo está cerca.` | en la que trabajo está cerca -> donde trabajo está cerca de aquí | `La empresa donde trabajo está cerca de aquí.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `La empresa en que trabajo está cerca.` | en que trabajo -> en la que trabajo | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 4 | `La empresa en la que trabajo está cerca.` | cerca -> cerca de aquí | `La empresa en la que trabajo está cerca de aquí.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `La empresa en que trabajo está cerca.` | en que trabajo -> donde trabajo | `La empresa donde trabajo está cerca.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 696 | $0.000604 | 2308 | $0.001729 | 3004 | $0.002333 |
| 2 | 563 | $0.000604 | 2208 | $0.001719 | 2771 | $0.002323 |
| 3 | 647 | $0.000596 | 1887 | $0.001498 | 2534 | $0.002093 |
| 4 | 873 | $0.000604 | 1736 | $0.001749 | 2609 | $0.002353 |
| 5 | 683 | $0.000596 | 1328 | $0.001347 | 2011 | $0.001943 |

### prep-dependo-de

- Original text: `Dependo que me ayudes mañana.`
- Expected corrected text: `Dependo de que me ayudes mañana.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Dependo de que me ayudes mañana.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Dependo de que me ayudes mañana.` | (none) | `Dependo de que me ayudes mañana.` | correct_fix | Pass | Matches expected output. |
| 2 | `Dependo de que me ayudes mañana.` | (none) | `Dependo de que me ayudes mañana.` | correct_fix | Pass | Matches expected output. |
| 3 | `Dependo de que me ayudes mañana.` | (none) | `Dependo de que me ayudes mañana.` | correct_fix | Pass | Matches expected output. |
| 4 | `Dependo de que me ayudes mañana.` | (none) | `Dependo de que me ayudes mañana.` | correct_fix | Pass | Matches expected output. |
| 5 | `Dependo de que me ayudes mañana.` | (none) | `Dependo de que me ayudes mañana.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000606 | 689 | $0.000799 | 1268 | $0.001405 |
| 2 | 607 | $0.000606 | 816 | $0.000799 | 1423 | $0.001405 |
| 3 | 471 | $0.000606 | 825 | $0.000799 | 1296 | $0.001405 |
| 4 | 580 | $0.000606 | 651 | $0.000799 | 1231 | $0.001405 |
| 5 | 644 | $0.000606 | 921 | $0.000799 | 1565 | $0.001405 |

### prep-pienso-en-ti

- Original text: `Pienso ti todos los días.`
- Expected corrected text: `Pienso en ti todos los días.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Pienso en ti todos los días.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Pienso en ti todos los días.` | (none) | `Pienso en ti todos los días.` | correct_fix | Pass | Matches expected output. |
| 2 | `Pienso en ti todos los días.` | (none) | `Pienso en ti todos los días.` | correct_fix | Pass | Matches expected output. |
| 3 | `Pienso en ti todos los días.` | (none) | `Pienso en ti todos los días.` | correct_fix | Pass | Matches expected output. |
| 4 | `Pienso en ti todos los días.` | (none) | `Pienso en ti todos los días.` | correct_fix | Pass | Matches expected output. |
| 5 | `Pienso en ti todos los días.` | (none) | `Pienso en ti todos los días.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 480 | $0.000596 | 814 | $0.000798 | 1294 | $0.001393 |
| 2 | 581 | $0.000596 | 716 | $0.000798 | 1297 | $0.001393 |
| 3 | 578 | $0.000596 | 816 | $0.000798 | 1394 | $0.001393 |
| 4 | 478 | $0.000596 | 816 | $0.000798 | 1294 | $0.001393 |
| 5 | 579 | $0.000596 | 817 | $0.000798 | 1396 | $0.001393 |

### prep-sone-con

- Original text: `Soñé mi antiguo colegio.`
- Expected corrected text: `Soñé con mi antiguo colegio.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Soñé con mi antiguo colegio.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Soñé con mi antiguo colegio.` | (none) | `Soñé con mi antiguo colegio.` | correct_fix | Pass | Matches expected output. |
| 2 | `Soñé con mi antiguo colegio.` | (none) | `Soñé con mi antiguo colegio.` | correct_fix | Pass | Matches expected output. |
| 3 | `Soñé con mi antiguo colegio.` | (none) | `Soñé con mi antiguo colegio.` | correct_fix | Pass | Matches expected output. |
| 4 | `Soñé con mi antiguo colegio.` | (none) | `Soñé con mi antiguo colegio.` | correct_fix | Pass | Matches expected output. |
| 5 | `Soñé con mi antiguo colegio.` | (none) | `Soñé con mi antiguo colegio.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 574 | $0.000596 | 825 | $0.000798 | 1399 | $0.001393 |
| 2 | 779 | $0.000596 | 719 | $0.000798 | 1498 | $0.001393 |
| 3 | 578 | $0.000596 | 819 | $0.000798 | 1397 | $0.001393 |
| 4 | 580 | $0.000596 | 816 | $0.000798 | 1396 | $0.001393 |
| 5 | 585 | $0.000596 | 782 | $0.000798 | 1367 | $0.001393 |

## Articles / Determiners

### article-puerta-principal

- Original text: `Abrió puerta principal.`
- Expected corrected text: `Abrió la puerta principal.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Abrió la puerta principal.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Abrió la puerta principal.` | (none) | `Abrió la puerta principal.` | correct_fix | Pass | Matches expected output. |
| 2 | `Abrió la puerta principal.` | (none) | `Abrió la puerta principal.` | correct_fix | Pass | Matches expected output. |
| 3 | `Abrió la puerta principal.` | (none) | `Abrió la puerta principal.` | correct_fix | Pass | Matches expected output. |
| 4 | `Abrió la puerta principal.` | (none) | `Abrió la puerta principal.` | correct_fix | Pass | Matches expected output. |
| 5 | `Abrió la puerta principal.` | (none) | `Abrió la puerta principal.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 621 | $0.000576 | 804 | $0.000795 | 1425 | $0.001371 |
| 2 | 681 | $0.000576 | 1024 | $0.000795 | 1705 | $0.001371 |
| 3 | 578 | $0.000576 | 717 | $0.000795 | 1295 | $0.001371 |
| 4 | 574 | $0.000576 | 820 | $0.000795 | 1394 | $0.001371 |
| 5 | 579 | $0.000576 | 821 | $0.000795 | 1400 | $0.001371 |

### article-un-libro

- Original text: `Necesito comprar libro para la clase.`
- Expected corrected text: `Necesito comprar un libro para la clase.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Necesito comprar un libro para la clase.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito comprar un libro para la clase.` | (none) | `Necesito comprar un libro para la clase.` | correct_fix | Pass | Matches expected output. |
| 2 | `Necesito comprar un libro para la clase.` | (none) | `Necesito comprar un libro para la clase.` | correct_fix | Pass | Matches expected output. |
| 3 | `Necesito comprar un libro para la clase.` | (none) | `Necesito comprar un libro para la clase.` | correct_fix | Pass | Matches expected output. |
| 4 | `Necesito comprar un libro para la clase.` | (none) | `Necesito comprar un libro para la clase.` | correct_fix | Pass | Matches expected output. |
| 5 | `Necesito comprar un libro para la clase.` | (none) | `Necesito comprar un libro para la clase.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 487 | $0.000606 | 808 | $0.000799 | 1295 | $0.001405 |
| 2 | 545 | $0.000606 | 747 | $0.000799 | 1292 | $0.001405 |
| 3 | 577 | $0.000606 | 1024 | $0.000799 | 1601 | $0.001405 |
| 4 | 577 | $0.000606 | 815 | $0.000799 | 1392 | $0.001405 |
| 5 | 583 | $0.000606 | 711 | $0.000799 | 1294 | $0.001405 |

### article-el-profesor-la-regla

- Original text: `Profesor explicó regla otra vez.`
- Expected corrected text: `El profesor explicó la regla otra vez.`
- Pass rate: 5/5
- Distinct final outputs:
  - `El profesor explicó la regla otra vez.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `El profesor explicó la regla otra vez.` | (none) | `El profesor explicó la regla otra vez.` | correct_fix | Pass | Matches expected output. |
| 2 | `El profesor explicó la regla otra vez.` | (none) | `El profesor explicó la regla otra vez.` | correct_fix | Pass | Matches expected output. |
| 3 | `El profesor explicó la regla otra vez.` | (none) | `El profesor explicó la regla otra vez.` | correct_fix | Pass | Matches expected output. |
| 4 | `El profesor explicó la regla otra vez.` | (none) | `El profesor explicó la regla otra vez.` | correct_fix | Pass | Matches expected output. |
| 5 | `El profesor explicó la regla otra vez.` | (none) | `El profesor explicó la regla otra vez.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 585 | $0.000594 | 1024 | $0.000798 | 1609 | $0.001391 |
| 2 | 883 | $0.000594 | 716 | $0.000798 | 1599 | $0.001391 |
| 3 | 781 | $0.000594 | 821 | $0.000798 | 1602 | $0.001391 |
| 4 | 569 | $0.000594 | 827 | $0.000798 | 1396 | $0.001391 |
| 5 | 700 | $0.000594 | 900 | $0.000798 | 1600 | $0.001391 |

### article-la-tienda

- Original text: `Fui a tienda después del trabajo.`
- Expected corrected text: `Fui a la tienda después del trabajo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Fui a la tienda después del trabajo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Fui a la tienda después del trabajo.` | (none) | `Fui a la tienda después del trabajo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Fui a la tienda después del trabajo.` | (none) | `Fui a la tienda después del trabajo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Fui a la tienda después del trabajo.` | (none) | `Fui a la tienda después del trabajo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Fui a la tienda después del trabajo.` | (none) | `Fui a la tienda después del trabajo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Fui a la tienda después del trabajo.` | (none) | `Fui a la tienda después del trabajo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 854 | $0.000606 | 751 | $0.000799 | 1605 | $0.001405 |
| 2 | 575 | $0.000606 | 716 | $0.000799 | 1291 | $0.001405 |
| 3 | 654 | $0.000606 | 1153 | $0.000799 | 1807 | $0.001405 |
| 4 | 477 | $0.000606 | 866 | $0.000799 | 1343 | $0.001405 |
| 5 | 628 | $0.000606 | 716 | $0.000799 | 1344 | $0.001405 |

### article-cita-medico

- Original text: `Tengo cita con médico mañana.`
- Expected corrected text: `Tengo una cita con el médico mañana.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Tengo una cita con el médico mañana.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Tengo una cita con el médico mañana.` | (none) | `Tengo una cita con el médico mañana.` | correct_fix | Pass | Matches expected output. |
| 2 | `Tengo una cita con el médico mañana.` | (none) | `Tengo una cita con el médico mañana.` | correct_fix | Pass | Matches expected output. |
| 3 | `Tengo una cita con el médico mañana.` | (none) | `Tengo una cita con el médico mañana.` | correct_fix | Pass | Matches expected output. |
| 4 | `Tengo una cita con el médico mañana.` | (none) | `Tengo una cita con el médico mañana.` | correct_fix | Pass | Matches expected output. |
| 5 | `Tengo una cita con el médico mañana.` | (none) | `Tengo una cita con el médico mañana.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 681 | $0.000594 | 832 | $0.000798 | 1513 | $0.001391 |
| 2 | 463 | $0.000594 | 880 | $0.000798 | 1343 | $0.001391 |
| 3 | 516 | $0.000594 | 719 | $0.000798 | 1235 | $0.001391 |
| 4 | 784 | $0.000594 | 920 | $0.000798 | 1704 | $0.001391 |
| 5 | 580 | $0.000594 | 919 | $0.000798 | 1499 | $0.001391 |

## Subjunctive / Mood

### subj-estudies

- Original text: `Es importante que estudias.`
- Expected corrected text: `Es importante que estudies.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Es importante que estudies.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Es importante que estudies.` | (none) | `Es importante que estudies.` | correct_fix | Pass | Matches expected output. |
| 2 | `Es importante que estudies.` | (none) | `Es importante que estudies.` | correct_fix | Pass | Matches expected output. |
| 3 | `Es importante que estudies.` | (none) | `Es importante que estudies.` | correct_fix | Pass | Matches expected output. |
| 4 | `Es importante que estudies.` | (none) | `Es importante que estudies.` | correct_fix | Pass | Matches expected output. |
| 5 | `Es importante que estudies.` | (none) | `Es importante que estudies.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000578 | 735 | $0.000795 | 1314 | $0.001373 |
| 2 | 660 | $0.000578 | 716 | $0.000795 | 1376 | $0.001373 |
| 3 | 600 | $0.000578 | 713 | $0.000795 | 1313 | $0.001373 |
| 4 | 663 | $0.000578 | 771 | $0.000795 | 1434 | $0.001373 |
| 5 | 626 | $0.000578 | 754 | $0.000795 | 1380 | $0.001373 |

### subj-tenga-razon

- Original text: `No creo que tiene razón.`
- Expected corrected text: `No creo que tenga razón.`
- Pass rate: 5/5
- Distinct final outputs:
  - `No creo que tenga razón.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `No creo que tenga razón.` | (none) | `No creo que tenga razón.` | correct_fix | Pass | Matches expected output. |
| 2 | `No creo que tenga razón.` | (none) | `No creo que tenga razón.` | correct_fix | Pass | Matches expected output. |
| 3 | `No creo que tenga razón.` | (none) | `No creo que tenga razón.` | correct_fix | Pass | Matches expected output. |
| 4 | `No creo que tenga razón.` | (none) | `No creo que tenga razón.` | correct_fix | Pass | Matches expected output. |
| 5 | `No creo que tenga razón.` | (none) | `No creo que tenga razón.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 537 | $0.000578 | 720 | $0.000795 | 1257 | $0.001373 |
| 2 | 666 | $0.000578 | 740 | $0.000795 | 1406 | $0.001373 |
| 3 | 773 | $0.000578 | 814 | $0.000795 | 1587 | $0.001373 |
| 4 | 582 | $0.000578 | 717 | $0.000795 | 1299 | $0.001373 |
| 5 | 578 | $0.000578 | 808 | $0.000795 | 1386 | $0.001373 |

### subj-vengas

- Original text: `Quiero que vienes conmigo.`
- Expected corrected text: `Quiero que vengas conmigo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Quiero que vengas conmigo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Quiero que vengas conmigo.` | (none) | `Quiero que vengas conmigo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Quiero que vengas conmigo.` | (none) | `Quiero que vengas conmigo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Quiero que vengas conmigo.` | (none) | `Quiero que vengas conmigo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Quiero que vengas conmigo.` | (none) | `Quiero que vengas conmigo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Quiero que vengas conmigo.` | (none) | `Quiero que vengas conmigo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 588 | $0.000588 | 617 | $0.000796 | 1205 | $0.001384 |
| 2 | 677 | $0.000588 | 819 | $0.000796 | 1496 | $0.001384 |
| 3 | 578 | $0.000588 | 817 | $0.000796 | 1395 | $0.001384 |
| 4 | 580 | $0.000588 | 713 | $0.000796 | 1293 | $0.001384 |
| 5 | 781 | $0.000588 | 820 | $0.000796 | 1601 | $0.001384 |

### subj-enviara

- Original text: `Era necesario que enviaba su parte.`
- Expected corrected text: `Era necesario que enviara su parte.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Era necesario que enviara su parte.`
  - `Era necesario que enviara su informe.`
  - `Era necesario que enviara su parte del trabajo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Era necesario que enviara su parte.` | era necesario que enviara su parte -> era necesario que mandara su parte | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 2 | `Era necesario que enviara su parte.` | enviara su parte -> enviara su informe | `Era necesario que enviara su informe.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Era necesario que enviara su parte.` | enviara su parte -> enviara su parte del trabajo | `Era necesario que enviara su parte del trabajo.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 5 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 580 | $0.000598 | 3029 | $0.002018 | 3609 | $0.002616 |
| 2 | 656 | $0.000598 | 2216 | $0.001818 | 2872 | $0.002416 |
| 3 | 679 | $0.000598 | 1844 | $0.001708 | 2523 | $0.002306 |
| 4 | 578 | $0.000598 | 818 | $0.000798 | 1396 | $0.001396 |
| 5 | 620 | $0.000598 | 879 | $0.000798 | 1499 | $0.001396 |

### subj-hable-frances

- Original text: `Busco a alguien que habla francés.`
- Expected corrected text: `Busco a alguien que hable francés.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Busco a alguien que hable francés.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Busco a alguien que hable francés.` | (none) | `Busco a alguien que hable francés.` | correct_fix | Pass | Matches expected output. |
| 2 | `Busco a alguien que hable francés.` | (none) | `Busco a alguien que hable francés.` | correct_fix | Pass | Matches expected output. |
| 3 | `Busco a alguien que hable francés.` | (none) | `Busco a alguien que hable francés.` | correct_fix | Pass | Matches expected output. |
| 4 | `Busco a alguien que hable francés.` | (none) | `Busco a alguien que hable francés.` | correct_fix | Pass | Matches expected output. |
| 5 | `Busco a alguien que hable francés.` | (none) | `Busco a alguien que hable francés.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 469 | $0.000606 | 928 | $0.000799 | 1397 | $0.001405 |
| 2 | 548 | $0.000606 | 848 | $0.000799 | 1396 | $0.001405 |
| 3 | 683 | $0.000606 | 817 | $0.000799 | 1500 | $0.001405 |
| 4 | 497 | $0.000606 | 1631 | $0.000799 | 2128 | $0.001405 |
| 5 | 666 | $0.000606 | 700 | $0.000799 | 1366 | $0.001405 |

## Required Additions / Omissions

### missing-que-creo

- Original text: `Creo está bien terminar hoy.`
- Expected corrected text: `Creo que está bien terminar hoy.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Creo que está bien terminar hoy.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Creo que está bien terminar hoy.` | (none) | `Creo que está bien terminar hoy.` | correct_fix | Pass | Matches expected output. |
| 2 | `Creo que está bien terminar hoy.` | (none) | `Creo que está bien terminar hoy.` | correct_fix | Pass | Matches expected output. |
| 3 | `Creo que está bien terminar hoy.` | (none) | `Creo que está bien terminar hoy.` | correct_fix | Pass | Matches expected output. |
| 4 | `Creo que está bien terminar hoy.` | (none) | `Creo que está bien terminar hoy.` | correct_fix | Pass | Matches expected output. |
| 5 | `Creo que está bien terminar hoy.` | (none) | `Creo que está bien terminar hoy.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 490 | $0.000586 | 789 | $0.000796 | 1279 | $0.001382 |
| 2 | 509 | $0.000586 | 733 | $0.000796 | 1242 | $0.001382 |
| 3 | 597 | $0.000586 | 679 | $0.000796 | 1276 | $0.001382 |
| 4 | 558 | $0.000586 | 832 | $0.000796 | 1390 | $0.001382 |
| 5 | 536 | $0.000586 | 968 | $0.000796 | 1504 | $0.001382 |

### missing-les-ninos

- Original text: `A los niños expliqué la regla.`
- Expected corrected text: `A los niños les expliqué la regla.`
- Pass rate: 5/5
- Distinct final outputs:
  - `A los niños les expliqué la regla.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `A los niños les expliqué la regla.` | (none) | `A los niños les expliqué la regla.` | correct_fix | Pass | Matches expected output. |
| 2 | `A los niños les expliqué la regla.` | (none) | `A los niños les expliqué la regla.` | correct_fix | Pass | Matches expected output. |
| 3 | `A los niños les expliqué la regla.` | (none) | `A los niños les expliqué la regla.` | correct_fix | Pass | Matches expected output. |
| 4 | `A los niños les expliqué la regla.` | (none) | `A los niños les expliqué la regla.` | correct_fix | Pass | Matches expected output. |
| 5 | `A los niños les expliqué la regla.` | (none) | `A los niños les expliqué la regla.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 493 | $0.000596 | 794 | $0.000798 | 1287 | $0.001393 |
| 2 | 635 | $0.000596 | 768 | $0.000798 | 1403 | $0.001393 |
| 3 | 476 | $0.000596 | 819 | $0.000798 | 1295 | $0.001393 |
| 4 | 579 | $0.000596 | 727 | $0.000798 | 1306 | $0.001393 |
| 5 | 670 | $0.000596 | 819 | $0.000798 | 1489 | $0.001393 |

### missing-personal-a-profesor

- Original text: `Vi mi profesor en la estación.`
- Expected corrected text: `Vi a mi profesor en la estación.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Vi a mi profesor en la estación.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi a mi profesor en la estación.` | (none) | `Vi a mi profesor en la estación.` | correct_fix | Pass | Matches expected output. |
| 2 | `Vi a mi profesor en la estación.` | (none) | `Vi a mi profesor en la estación.` | correct_fix | Pass | Matches expected output. |
| 3 | `Vi a mi profesor en la estación.` | (none) | `Vi a mi profesor en la estación.` | correct_fix | Pass | Matches expected output. |
| 4 | `Vi a mi profesor en la estación.` | (none) | `Vi a mi profesor en la estación.` | correct_fix | Pass | Matches expected output. |
| 5 | `Vi a mi profesor en la estación.` | (none) | `Vi a mi profesor en la estación.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 491 | $0.000596 | 1106 | $0.000798 | 1597 | $0.001393 |
| 2 | 582 | $0.000596 | 716 | $0.000798 | 1298 | $0.001393 |
| 3 | 519 | $0.000596 | 722 | $0.000798 | 1241 | $0.001393 |
| 4 | 651 | $0.000596 | 696 | $0.000798 | 1347 | $0.001393 |
| 5 | 680 | $0.000596 | 816 | $0.000798 | 1496 | $0.001393 |

### missing-se-levanto

- Original text: `Levantó temprano ayer.`
- Expected corrected text: `Se levantó temprano ayer.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Se levantó temprano ayer.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Se levantó temprano ayer.` | (none) | `Se levantó temprano ayer.` | correct_fix | Pass | Matches expected output. |
| 2 | `Se levantó temprano ayer.` | (none) | `Se levantó temprano ayer.` | correct_fix | Pass | Matches expected output. |
| 3 | `Se levantó temprano ayer.` | (none) | `Se levantó temprano ayer.` | correct_fix | Pass | Matches expected output. |
| 4 | `Se levantó temprano ayer.` | (none) | `Se levantó temprano ayer.` | correct_fix | Pass | Matches expected output. |
| 5 | `Se levantó temprano ayer.` | (none) | `Se levantó temprano ayer.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 683 | $0.000578 | 819 | $0.000795 | 1502 | $0.001373 |
| 2 | 1027 | $0.000578 | 858 | $0.000795 | 1885 | $0.001373 |
| 3 | 601 | $0.000578 | 942 | $0.000795 | 1543 | $0.001373 |
| 4 | 662 | $0.000578 | 816 | $0.000795 | 1478 | $0.001373 |
| 5 | 478 | $0.000578 | 815 | $0.000795 | 1293 | $0.001373 |

### missing-le-gusta

- Original text: `A Juan gusta el café.`
- Expected corrected text: `A Juan le gusta el café.`
- Pass rate: 5/5
- Distinct final outputs:
  - `A Juan le gusta el café.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `A Juan le gusta el café.` | (none) | `A Juan le gusta el café.` | correct_fix | Pass | Matches expected output. |
| 2 | `A Juan le gusta el café.` | (none) | `A Juan le gusta el café.` | correct_fix | Pass | Matches expected output. |
| 3 | `A Juan le gusta el café.` | (none) | `A Juan le gusta el café.` | correct_fix | Pass | Matches expected output. |
| 4 | `A Juan le gusta el café.` | (none) | `A Juan le gusta el café.` | correct_fix | Pass | Matches expected output. |
| 5 | `A Juan le gusta el café.` | (none) | `A Juan le gusta el café.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 505 | $0.000586 | 1009 | $0.000796 | 1514 | $0.001382 |
| 2 | 669 | $0.000586 | 817 | $0.000796 | 1486 | $0.001382 |
| 3 | 692 | $0.000586 | 911 | $0.000796 | 1603 | $0.001382 |
| 4 | 681 | $0.000586 | 821 | $0.000796 | 1502 | $0.001382 |
| 5 | 574 | $0.000586 | 922 | $0.000796 | 1496 | $0.001382 |

## Unnecessary Extras / Deletions

### delete-repeated-yo-estudio

- Original text: `Yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Yo trabajo mucho y yo estudio por la noche.`
  - `Yo trabajo mucho y yo estudio por las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por las noches / en las noches | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por las noches / en las noches / de noche | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 4 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 884 | $0.000618 | 1946 | $0.001640 | 2830 | $0.002258 |
| 2 | 577 | $0.000618 | 1749 | $0.001540 | 2326 | $0.002158 |
| 3 | 569 | $0.000618 | 2456 | $0.001630 | 3025 | $0.002248 |
| 4 | 556 | $0.000618 | 1724 | $0.001440 | 2280 | $0.002058 |
| 5 | 720 | $0.000618 | 1743 | $0.001440 | 2463 | $0.002058 |

### delete-repeated-ellos-visitaron

- Original text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Expected corrected text: `Ellos viajaron a México y visitaron varias ciudades.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Ellos viajaron a México y visitaron varias ciudades.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos viajaron a México y visitaron varias ciudades.` | (none) | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 2 | `Ellos viajaron a México y visitaron varias ciudades.` | (none) | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ellos viajaron a México y visitaron varias ciudades.` | (none) | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 4 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | Ellos viajaron a México y ellos visitaron varias ciudades. -> Ellos viajaron a México y visitaron varias ciudades. | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ellos viajaron a México y visitaron varias ciudades.` | (none) | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 572 | $0.000640 | 720 | $0.000802 | 1292 | $0.001442 |
| 2 | 575 | $0.000640 | 727 | $0.000802 | 1302 | $0.001442 |
| 3 | 879 | $0.000640 | 815 | $0.000802 | 1694 | $0.001442 |
| 4 | 641 | $0.000648 | 1687 | $0.001624 | 2328 | $0.002272 |
| 5 | 571 | $0.000640 | 716 | $0.000802 | 1287 | $0.001442 |

### delete-repeated-a-mi

- Original text: `A mí me gusta el café a mí.`
- Expected corrected text: `A mí me gusta el café.`
- Pass rate: 5/5
- Distinct final outputs:
  - `A mí me gusta el café.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `A mí me gusta el café.` | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 2 | `A mí me gusta el café.` | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 3 | `A mí me gusta el café.` | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 4 | `A mí me gusta el café.` | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 5 | `A mí me gusta el café.` | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 682 | $0.000592 | 1227 | $0.000796 | 1909 | $0.001388 |
| 2 | 914 | $0.000592 | 871 | $0.000796 | 1785 | $0.001388 |
| 3 | 742 | $0.000592 | 883 | $0.000796 | 1625 | $0.001388 |
| 4 | 680 | $0.000592 | 1124 | $0.000796 | 1804 | $0.001388 |
| 5 | 577 | $0.000592 | 716 | $0.000796 | 1293 | $0.001388 |

### delete-repeated-yo-compre

- Original text: `Yo fui al mercado y yo compré pan.`
- Expected corrected text: `Fui al mercado y compré pan.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Yo fui al mercado y compré pan.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo fui al mercado y yo compré pan.` | yo compré pan -> compré pan | `Yo fui al mercado y compré pan.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Yo fui al mercado y yo compré pan.` | Yo fui al mercado y yo compré pan. -> Yo fui al mercado y compré pan. | `Yo fui al mercado y compré pan.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 880 | $0.000618 | 1697 | $0.001420 | 2577 | $0.002038 |
| 2 | 622 | $0.000610 | 921 | $0.000799 | 1543 | $0.001409 |
| 3 | 884 | $0.000618 | 6030 | $0.001530 | 6914 | $0.002148 |
| 4 | 575 | $0.000618 | 1345 | $0.001330 | 1920 | $0.001948 |
| 5 | 783 | $0.000618 | 1638 | $0.001590 | 2421 | $0.002208 |

### delete-repeated-nosotros

- Original text: `Nosotros salimos temprano y nosotros llegamos a tiempo.`
- Expected corrected text: `Nosotros salimos temprano y llegamos a tiempo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Salimos temprano y llegamos a tiempo.`
  - `Nosotros salimos temprano y llegamos a tiempo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Nosotros salimos temprano y llegamos a tiempo. | `Nosotros salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Nosotros salimos temprano y llegamos a tiempo. | `Nosotros salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Nosotros salimos temprano y llegamos a tiempo. | `Nosotros salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000638 | 1468 | $0.001613 | 2045 | $0.002250 |
| 2 | 644 | $0.000638 | 1824 | $0.001602 | 2468 | $0.002240 |
| 3 | 598 | $0.000638 | 1742 | $0.001642 | 2340 | $0.002280 |
| 4 | 579 | $0.000638 | 1844 | $0.001572 | 2423 | $0.002210 |
| 5 | 574 | $0.000638 | 2049 | $0.001592 | 2623 | $0.002230 |

## Ser / Estar / Haber

### ser-profesor

- Original text: `Mi hermano está profesor.`
- Expected corrected text: `Mi hermano es profesor.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Mi hermano es profesor.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Mi hermano es profesor.` | (none) | `Mi hermano es profesor.` | correct_fix | Pass | Matches expected output. |
| 2 | `Mi hermano es profesor.` | (none) | `Mi hermano es profesor.` | correct_fix | Pass | Matches expected output. |
| 3 | `Mi hermano es profesor.` | (none) | `Mi hermano es profesor.` | correct_fix | Pass | Matches expected output. |
| 4 | `Mi hermano es profesor.` | (none) | `Mi hermano es profesor.` | correct_fix | Pass | Matches expected output. |
| 5 | `Mi hermano es profesor.` | (none) | `Mi hermano es profesor.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000568 | 1122 | $0.000794 | 1701 | $0.001362 |
| 2 | 682 | $0.000568 | 674 | $0.000794 | 1356 | $0.001362 |
| 3 | 512 | $0.000568 | 723 | $0.000794 | 1235 | $0.001362 |
| 4 | 541 | $0.000568 | 852 | $0.000794 | 1393 | $0.001362 |
| 5 | 579 | $0.000568 | 818 | $0.000794 | 1397 | $0.001362 |

### haber-veinte-personas

- Original text: `En la sala son veinte personas.`
- Expected corrected text: `En la sala hay veinte personas.`
- Pass rate: 5/5
- Distinct final outputs:
  - `En la sala hay veinte personas.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `En la sala hay veinte personas.` | (none) | `En la sala hay veinte personas.` | correct_fix | Pass | Matches expected output. |
| 2 | `En la sala hay veinte personas.` | (none) | `En la sala hay veinte personas.` | correct_fix | Pass | Matches expected output. |
| 3 | `En la sala hay veinte personas.` | (none) | `En la sala hay veinte personas.` | correct_fix | Pass | Matches expected output. |
| 4 | `En la sala hay veinte personas.` | (none) | `En la sala hay veinte personas.` | correct_fix | Pass | Matches expected output. |
| 5 | `En la sala hay veinte personas.` | (none) | `En la sala hay veinte personas.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 582 | $0.000588 | 923 | $0.000796 | 1505 | $0.001384 |
| 2 | 589 | $0.000588 | 806 | $0.000796 | 1395 | $0.001384 |
| 3 | 746 | $0.000588 | 753 | $0.000796 | 1499 | $0.001384 |
| 4 | 781 | $0.000588 | 715 | $0.000796 | 1496 | $0.001384 |
| 5 | 682 | $0.000588 | 819 | $0.000796 | 1501 | $0.001384 |

### ser-capital-madrid

- Original text: `Madrid está la capital de España.`
- Expected corrected text: `Madrid es la capital de España.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Madrid es la capital de España.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Madrid es la capital de España.` | (none) | `Madrid es la capital de España.` | correct_fix | Pass | Matches expected output. |
| 2 | `Madrid es la capital de España.` | (none) | `Madrid es la capital de España.` | correct_fix | Pass | Matches expected output. |
| 3 | `Madrid es la capital de España.` | (none) | `Madrid es la capital de España.` | correct_fix | Pass | Matches expected output. |
| 4 | `Madrid es la capital de España.` | (none) | `Madrid es la capital de España.` | correct_fix | Pass | Matches expected output. |
| 5 | `Madrid es la capital de España.` | (none) | `Madrid es la capital de España.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 520 | $0.000588 | 877 | $0.000796 | 1397 | $0.001384 |
| 2 | 574 | $0.000588 | 752 | $0.000796 | 1326 | $0.001384 |
| 3 | 614 | $0.000588 | 678 | $0.000796 | 1292 | $0.001384 |
| 4 | 858 | $0.000588 | 815 | $0.000796 | 1673 | $0.001384 |
| 5 | 684 | $0.000588 | 713 | $0.000796 | 1397 | $0.001384 |

### estar-contento

- Original text: `Estoy muy contento con el resultado.`
- Expected corrected text: `Estoy muy contento con el resultado.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Estoy muy contento con el resultado.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy muy contento con el resultado.` | (none) | `Estoy muy contento con el resultado.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Estoy muy contento con el resultado.` | (none) | `Estoy muy contento con el resultado.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Estoy muy contento con el resultado.` | (none) | `Estoy muy contento con el resultado.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Estoy muy contento con el resultado.` | (none) | `Estoy muy contento con el resultado.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Estoy muy contento con el resultado.` | (none) | `Estoy muy contento con el resultado.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 639 | $0.000598 | 847 | $0.000798 | 1486 | $0.001396 |
| 2 | 593 | $0.000598 | 759 | $0.000798 | 1352 | $0.001396 |
| 3 | 840 | $0.000598 | 712 | $0.000798 | 1552 | $0.001396 |
| 4 | 599 | $0.000598 | 775 | $0.000798 | 1374 | $0.001396 |
| 5 | 708 | $0.000598 | 717 | $0.000798 | 1425 | $0.001396 |

### ser-reunion-segunda-planta

- Original text: `La reunión es en la segunda planta.`
- Expected corrected text: `La reunión es en la segunda planta.`
- Pass rate: 5/5
- Distinct final outputs:
  - `La reunión es en la segunda planta.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `La reunión es en la segunda planta.` | en la segunda planta -> en la segunda planta / en el segundo piso | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000598 | 820 | $0.000798 | 1399 | $0.001396 |
| 2 | 492 | $0.000598 | 903 | $0.000798 | 1395 | $0.001396 |
| 3 | 577 | $0.000598 | 1741 | $0.001738 | 2318 | $0.002336 |
| 4 | 578 | $0.000598 | 720 | $0.000798 | 1298 | $0.001396 |
| 5 | 573 | $0.000598 | 819 | $0.000798 | 1392 | $0.001396 |

## Impersonal Haber / Se

### haber-habia-personas

- Original text: `Habían muchas personas en la entrada.`
- Expected corrected text: `Había muchas personas en la entrada.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Había muchas personas en la entrada.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Había muchas personas en la entrada.` | (none) | `Había muchas personas en la entrada.` | correct_fix | Pass | Matches expected output. |
| 2 | `Había muchas personas en la entrada.` | (none) | `Había muchas personas en la entrada.` | correct_fix | Pass | Matches expected output. |
| 3 | `Había muchas personas en la entrada.` | (none) | `Había muchas personas en la entrada.` | correct_fix | Pass | Matches expected output. |
| 4 | `Había muchas personas en la entrada.` | (none) | `Había muchas personas en la entrada.` | correct_fix | Pass | Matches expected output. |
| 5 | `Había muchas personas en la entrada.` | (none) | `Había muchas personas en la entrada.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 682 | $0.000598 | 684 | $0.000798 | 1366 | $0.001396 |
| 2 | 510 | $0.000598 | 861 | $0.000798 | 1371 | $0.001396 |
| 3 | 588 | $0.000598 | 752 | $0.000798 | 1340 | $0.001396 |
| 4 | 503 | $0.000598 | 952 | $0.000798 | 1455 | $0.001396 |
| 5 | 564 | $0.000598 | 2219 | $0.000798 | 2783 | $0.001396 |

### haber-hubo-problemas

- Original text: `Hubieron varios problemas durante la reunión.`
- Expected corrected text: `Hubo varios problemas durante la reunión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Hubo varios problemas durante la reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Hubo varios problemas durante la reunión.` | (none) | `Hubo varios problemas durante la reunión.` | correct_fix | Pass | Matches expected output. |
| 2 | `Hubo varios problemas durante la reunión.` | (none) | `Hubo varios problemas durante la reunión.` | correct_fix | Pass | Matches expected output. |
| 3 | `Hubo varios problemas durante la reunión.` | (none) | `Hubo varios problemas durante la reunión.` | correct_fix | Pass | Matches expected output. |
| 4 | `Hubo varios problemas durante la reunión.` | (none) | `Hubo varios problemas durante la reunión.` | correct_fix | Pass | Matches expected output. |
| 5 | `Hubo varios problemas durante la reunión.` | (none) | `Hubo varios problemas durante la reunión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000598 | 922 | $0.000798 | 1501 | $0.001396 |
| 2 | 680 | $0.000598 | 718 | $0.000798 | 1398 | $0.001396 |
| 3 | 592 | $0.000598 | 686 | $0.000798 | 1278 | $0.001396 |
| 4 | 592 | $0.000598 | 658 | $0.000798 | 1250 | $0.001396 |
| 5 | 473 | $0.000598 | 982 | $0.000798 | 1455 | $0.001396 |

### se-venden-pisos

- Original text: `Se vende pisos en el centro.`
- Expected corrected text: `Se venden pisos en el centro.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Se venden pisos en el centro.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Se venden pisos en el centro.` | (none) | `Se venden pisos en el centro.` | correct_fix | Pass | Matches expected output. |
| 2 | `Se venden pisos en el centro.` | (none) | `Se venden pisos en el centro.` | correct_fix | Pass | Matches expected output. |
| 3 | `Se venden pisos en el centro.` | (none) | `Se venden pisos en el centro.` | correct_fix | Pass | Matches expected output. |
| 4 | `Se venden pisos en el centro.` | (none) | `Se venden pisos en el centro.` | correct_fix | Pass | Matches expected output. |
| 5 | `Se venden pisos en el centro.` | (none) | `Se venden pisos en el centro.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 580 | $0.000588 | 1125 | $0.000796 | 1705 | $0.001384 |
| 2 | 518 | $0.000588 | 877 | $0.000796 | 1395 | $0.001384 |
| 3 | 576 | $0.000588 | 718 | $0.000796 | 1294 | $0.001384 |
| 4 | 581 | $0.000588 | 745 | $0.000796 | 1326 | $0.001384 |
| 5 | 600 | $0.000588 | 971 | $0.000796 | 1571 | $0.001384 |

### se-necesitan-voluntarios

- Original text: `Se necesita voluntarios para el evento.`
- Expected corrected text: `Se necesitan voluntarios para el evento.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Se necesitan voluntarios para el evento.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Se necesitan voluntarios para el evento.` | (none) | `Se necesitan voluntarios para el evento.` | correct_fix | Pass | Matches expected output. |
| 2 | `Se necesitan voluntarios para el evento.` | (none) | `Se necesitan voluntarios para el evento.` | correct_fix | Pass | Matches expected output. |
| 3 | `Se necesitan voluntarios para el evento.` | (none) | `Se necesitan voluntarios para el evento.` | correct_fix | Pass | Matches expected output. |
| 4 | `Se necesitan voluntarios para el evento.` | (none) | `Se necesitan voluntarios para el evento.` | correct_fix | Pass | Matches expected output. |
| 5 | `Se necesitan voluntarios para el evento.` | (none) | `Se necesitan voluntarios para el evento.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 782 | $0.000598 | 716 | $0.000798 | 1498 | $0.001396 |
| 2 | 579 | $0.000598 | 935 | $0.000798 | 1514 | $0.001396 |
| 3 | 565 | $0.000598 | 711 | $0.000798 | 1276 | $0.001396 |
| 4 | 497 | $0.000598 | 903 | $0.000798 | 1400 | $0.001396 |
| 5 | 578 | $0.000598 | 1229 | $0.000798 | 1807 | $0.001396 |

### haber-habia-cifras

- Original text: `Habían varias cifras incorrectas.`
- Expected corrected text: `Había varias cifras incorrectas.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Había varias cifras incorrectas.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Había varias cifras incorrectas.` | (none) | `Había varias cifras incorrectas.` | correct_fix | Pass | Matches expected output. |
| 2 | `Había varias cifras incorrectas.` | (none) | `Había varias cifras incorrectas.` | correct_fix | Pass | Matches expected output. |
| 3 | `Había varias cifras incorrectas.` | (none) | `Había varias cifras incorrectas.` | correct_fix | Pass | Matches expected output. |
| 4 | `Había varias cifras incorrectas.` | (none) | `Había varias cifras incorrectas.` | correct_fix | Pass | Matches expected output. |
| 5 | `Había varias cifras incorrectas.` | (none) | `Había varias cifras incorrectas.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 524 | $0.000588 | 983 | $0.000796 | 1507 | $0.001384 |
| 2 | 466 | $0.000588 | 1024 | $0.000796 | 1490 | $0.001384 |
| 3 | 539 | $0.000588 | 683 | $0.000796 | 1222 | $0.001384 |
| 4 | 820 | $0.000588 | 755 | $0.000796 | 1575 | $0.001384 |
| 5 | 2121 | $0.000588 | 634 | $0.000796 | 2755 | $0.001384 |

## False Friends / Word Choice

### false-friend-atendio-universidad

- Original text: `Atendió la universidad en Madrid.`
- Expected corrected text: `Asistió a la universidad en Madrid.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Asistió a la universidad en Madrid.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |
| 2 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |
| 3 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |
| 4 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |
| 5 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 473 | $0.000606 | 804 | $0.000799 | 1277 | $0.001405 |
| 2 | 489 | $0.000606 | 781 | $0.000799 | 1270 | $0.001405 |
| 3 | 516 | $0.000606 | 672 | $0.000799 | 1188 | $0.001405 |
| 4 | 474 | $0.000606 | 864 | $0.000799 | 1338 | $0.001405 |
| 5 | 603 | $0.000606 | 999 | $0.000799 | 1602 | $0.001405 |

### false-friend-aplico-trabajo

- Original text: `Aplicó para un trabajo.`
- Expected corrected text: `Solicitó un trabajo.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Se postuló para un trabajo.`
  - `Solicitó un trabajo.`
  - `Se postuló a un trabajo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Aplicó a un trabajo.` | Aplicó a un trabajo -> Se postuló para un trabajo | `Se postuló para un trabajo.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Aplicó a un trabajo.` | Aplicó a un trabajo. -> Se postuló a un trabajo. | `Se postuló a un trabajo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 575 | $0.000578 | 1744 | $0.001745 | 2319 | $0.002323 |
| 2 | 579 | $0.000578 | 1792 | $0.001675 | 2371 | $0.002253 |
| 3 | 1037 | $0.000578 | 1635 | $0.001495 | 2672 | $0.002073 |
| 4 | 539 | $0.000578 | 2499 | $0.001675 | 3038 | $0.002253 |
| 5 | 942 | $0.000578 | 2097 | $0.001825 | 3039 | $0.002403 |

### false-friend-realice

- Original text: `Realicé que estaba equivocado.`
- Expected corrected text: `Me di cuenta de que estaba equivocado.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Me di cuenta de que estaba equivocado.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Me di cuenta de que estaba equivocado.` | (none) | `Me di cuenta de que estaba equivocado.` | correct_fix | Pass | Matches expected output. |
| 2 | `Me di cuenta de que estaba equivocado.` | (none) | `Me di cuenta de que estaba equivocado.` | correct_fix | Pass | Matches expected output. |
| 3 | `Me di cuenta de que estaba equivocado.` | (none) | `Me di cuenta de que estaba equivocado.` | correct_fix | Pass | Matches expected output. |
| 4 | `Me di cuenta de que estaba equivocado.` | (none) | `Me di cuenta de que estaba equivocado.` | correct_fix | Pass | Matches expected output. |
| 5 | `Me di cuenta de que estaba equivocado.` | (none) | `Me di cuenta de que estaba equivocado.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 573 | $0.000606 | 820 | $0.000799 | 1393 | $0.001405 |
| 2 | 782 | $0.000606 | 719 | $0.000799 | 1501 | $0.001405 |
| 3 | 1135 | $0.000606 | 770 | $0.000799 | 1905 | $0.001405 |
| 4 | 596 | $0.000606 | 1111 | $0.000799 | 1707 | $0.001405 |
| 5 | 479 | $0.000606 | 830 | $0.000799 | 1309 | $0.001405 |

### false-friend-embarazado

- Original text: `Estoy embarazado por llegar tarde.`
- Expected corrected text: `Me da vergüenza llegar tarde.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Estoy avergonzado por llegar tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 4 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 665 | $0.000606 | 1025 | $0.000799 | 1690 | $0.001405 |
| 2 | 577 | $0.000606 | 818 | $0.000799 | 1395 | $0.001405 |
| 3 | 577 | $0.000606 | 687 | $0.000799 | 1264 | $0.001405 |
| 4 | 474 | $0.000606 | 2181 | $0.000799 | 2655 | $0.001405 |
| 5 | 477 | $0.000606 | 816 | $0.000799 | 1293 | $0.001405 |

### false-friend-actualmente-control

- Original text: `Actualmente vivo en Londres.`
- Expected corrected text: `Actualmente vivo en Londres.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Actualmente vivo en Londres.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Actualmente vivo en Londres.` | (none) | `Actualmente vivo en Londres.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Actualmente vivo en Londres.` | (none) | `Actualmente vivo en Londres.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Actualmente vivo en Londres.` | (none) | `Actualmente vivo en Londres.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Actualmente vivo en Londres.` | (none) | `Actualmente vivo en Londres.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Actualmente vivo en Londres.` | (none) | `Actualmente vivo en Londres.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000568 | 820 | $0.000794 | 1397 | $0.001362 |
| 2 | 477 | $0.000568 | 920 | $0.000794 | 1397 | $0.001362 |
| 3 | 477 | $0.000568 | 817 | $0.000794 | 1294 | $0.001362 |
| 4 | 530 | $0.000568 | 764 | $0.000794 | 1294 | $0.001362 |
| 5 | 520 | $0.000568 | 894 | $0.000794 | 1414 | $0.001362 |

## Phrase-Level Naturalness

### naturalness-buen-tiempo

- Original text: `Tuvimos un buen tiempo.`
- Expected corrected text: `Lo pasamos bien.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Tuvimos un rato muy agradable.`
  - `Tuvimos un buen rato.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Tuvimos un buen rato.` | un buen rato -> un rato muy agradable | `Tuvimos un rato muy agradable.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Tuvimos un buen rato.` | (none) | `Tuvimos un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Tuvimos un buen tiempo.` | buen tiempo -> buen rato | `Tuvimos un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 478 | $0.000588 | 1796 | $0.001796 | 2274 | $0.002384 |
| 2 | 506 | $0.000588 | 714 | $0.000796 | 1220 | $0.001384 |
| 3 | 577 | $0.000588 | 1639 | $0.001606 | 2216 | $0.002194 |
| 4 | 735 | $0.000588 | 1620 | $0.001656 | 2355 | $0.002244 |
| 5 | 777 | $0.000588 | 2454 | $0.001856 | 3231 | $0.002444 |

### naturalness-corriendo-tarde

- Original text: `Estoy corriendo tarde para la reunión.`
- Expected corrected text: `Voy tarde a la reunión.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Estoy llegando tarde a la reunión.`
  - `Voy a llegar tarde a la reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 497 | $0.000590 | 1532 | $0.001676 | 2029 | $0.002266 |
| 2 | 497 | $0.000590 | 2078 | $0.001466 | 2575 | $0.002056 |
| 3 | 580 | $0.000590 | 1470 | $0.001436 | 2050 | $0.002026 |
| 4 | 557 | $0.000590 | 1633 | $0.001456 | 2190 | $0.002046 |
| 5 | 567 | $0.000590 | 1741 | $0.001756 | 2308 | $0.002346 |

### naturalness-pasar-buen-tiempo

- Original text: `Quiero pasar un buen tiempo.`
- Expected corrected text: `Quiero pasarlo bien.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Quiero pasar un buen rato.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 592 | $0.000588 | 804 | $0.000796 | 1396 | $0.001384 |
| 2 | 782 | $0.000588 | 820 | $0.000796 | 1602 | $0.001384 |
| 3 | 576 | $0.000588 | 739 | $0.000796 | 1315 | $0.001384 |
| 4 | 1169 | $0.000588 | 1025 | $0.000796 | 2194 | $0.001384 |
| 5 | 511 | $0.000588 | 784 | $0.000796 | 1295 | $0.001384 |

### naturalness-puedo-tener-cerveza

- Original text: `¿Puedo tener una cerveza?`
- Expected corrected text: `¿Me pones una cerveza?`
- Pass rate: 0/5
- Distinct final outputs:
  - `¿Puedo tomar una cerveza?`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 783 | $0.000588 | 728 | $0.000796 | 1511 | $0.001384 |
| 2 | 770 | $0.000588 | 783 | $0.000796 | 1553 | $0.001384 |
| 3 | 616 | $0.000588 | 715 | $0.000796 | 1331 | $0.001384 |
| 4 | 579 | $0.000588 | 715 | $0.000796 | 1294 | $0.001384 |
| 5 | 574 | $0.000588 | 773 | $0.000796 | 1347 | $0.001384 |

### naturalness-llamar-para-atras

- Original text: `Te llamo para atrás.`
- Expected corrected text: `Te devuelvo la llamada.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Te llamo más tarde.`
  - `Te llamo después.`
  - `Te llamo de nuevo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Te llamo de vuelta.` | de vuelta -> más tarde | `Te llamo más tarde.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Te llamo después.` | (none) | `Te llamo después.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Te llamo de vuelta.` | de vuelta -> más tarde | `Te llamo más tarde.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Te llamo de nuevo.` | (none) | `Te llamo de nuevo.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Te llamo de vuelta.` | de vuelta -> más tarde | `Te llamo más tarde.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 524 | $0.000578 | 1637 | $0.001635 | 2161 | $0.002213 |
| 2 | 579 | $0.000570 | 974 | $0.000794 | 1553 | $0.001364 |
| 3 | 594 | $0.000578 | 1465 | $0.001695 | 2059 | $0.002273 |
| 4 | 690 | $0.000578 | 810 | $0.000795 | 1500 | $0.001373 |
| 5 | 571 | $0.000578 | 1850 | $0.001685 | 2421 | $0.002263 |

## Valid Regional / Should Not Flag

### regional-voy-para-casa

- Original text: `Voy para casa ahora mismo.`
- Expected corrected text: `Voy para casa ahora mismo.`
- Pass rate: 1/5
- Distinct final outputs:
  - `Voy a casa ahora mismo.`
  - `Voy para casa ahora mismo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Voy para la casa ahora mismo.` | para la casa -> para casa | `Voy para casa ahora mismo.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 576 | $0.000586 | 1536 | $0.001576 | 2112 | $0.002162 |
| 2 | 682 | $0.000586 | 1946 | $0.001666 | 2628 | $0.002252 |
| 3 | 680 | $0.000586 | 2147 | $0.001646 | 2827 | $0.002232 |
| 4 | 685 | $0.000586 | 1941 | $0.001676 | 2626 | $0.002262 |
| 5 | 577 | $0.000586 | 1636 | $0.001496 | 2213 | $0.002082 |

### regional-vos-tenes

- Original text: `Vos tenés razón.`
- Expected corrected text: `Vos tenés razón.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Vos tenés razón.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vos tenés razón.` | (none) | `Vos tenés razón.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Vos tenés razón.` | (none) | `Vos tenés razón.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Vos tenés razón.` | (none) | `Vos tenés razón.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Vos tenés razón.` | (none) | `Vos tenés razón.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Vos tenés razón.` | (none) | `Vos tenés razón.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 478 | $0.000568 | 669 | $0.000794 | 1147 | $0.001362 |
| 2 | 524 | $0.000568 | 715 | $0.000794 | 1239 | $0.001362 |
| 3 | 576 | $0.000568 | 720 | $0.000794 | 1296 | $0.001362 |
| 4 | 514 | $0.000568 | 827 | $0.000794 | 1341 | $0.001362 |
| 5 | 463 | $0.000568 | 622 | $0.000794 | 1085 | $0.001362 |

### regional-cojo-autobus

- Original text: `Cojo el autobús cada mañana.`
- Expected corrected text: `Cojo el autobús cada mañana.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Cojo el autobús cada mañana.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Cojo el autobús cada mañana.` | (none) | `Cojo el autobús cada mañana.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Cojo el autobús cada mañana.` | (none) | `Cojo el autobús cada mañana.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Cojo el autobús cada mañana.` | (none) | `Cojo el autobús cada mañana.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Cojo el autobús cada mañana.` | (none) | `Cojo el autobús cada mañana.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Cojo el autobús cada mañana.` | (none) | `Cojo el autobús cada mañana.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 638 | $0.000598 | 756 | $0.000798 | 1394 | $0.001396 |
| 2 | 612 | $0.000598 | 846 | $0.000798 | 1458 | $0.001396 |
| 3 | 461 | $0.000598 | 948 | $0.000798 | 1409 | $0.001396 |
| 4 | 567 | $0.000598 | 708 | $0.000798 | 1275 | $0.001396 |
| 5 | 688 | $0.000598 | 754 | $0.000798 | 1442 | $0.001396 |

### regional-preterite-esta-manana

- Original text: `Esta mañana hablé con mi jefe.`
- Expected corrected text: `Esta mañana hablé con mi jefe.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Esta mañana hablé con mi jefe.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Esta mañana hablé con mi jefe.` | (none) | `Esta mañana hablé con mi jefe.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Esta mañana hablé con mi jefe.` | (none) | `Esta mañana hablé con mi jefe.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Esta mañana hablé con mi jefe.` | (none) | `Esta mañana hablé con mi jefe.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Esta mañana hablé con mi jefe.` | (none) | `Esta mañana hablé con mi jefe.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Esta mañana hablé con mi jefe.` | (none) | `Esta mañana hablé con mi jefe.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 540 | $0.000598 | 820 | $0.000798 | 1360 | $0.001396 |
| 2 | 578 | $0.000598 | 748 | $0.000798 | 1326 | $0.001396 |
| 3 | 530 | $0.000598 | 834 | $0.000798 | 1364 | $0.001396 |
| 4 | 578 | $0.000598 | 817 | $0.000798 | 1395 | $0.001396 |
| 5 | 580 | $0.000598 | 921 | $0.000798 | 1501 | $0.001396 |

### regional-dale

- Original text: `Dale, nos vemos más tarde.`
- Expected corrected text: `Dale, nos vemos más tarde.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Dale, nos vemos más tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Dale, nos vemos más tarde.` | (none) | `Dale, nos vemos más tarde.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Dale, nos vemos más tarde.` | (none) | `Dale, nos vemos más tarde.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Dale, nos vemos más tarde.` | (none) | `Dale, nos vemos más tarde.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Dale, nos vemos más tarde.` | (none) | `Dale, nos vemos más tarde.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Dale, nos vemos más tarde.` | (none) | `Dale, nos vemos más tarde.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 681 | $0.000598 | 717 | $0.000798 | 1398 | $0.001396 |
| 2 | 579 | $0.000598 | 739 | $0.000798 | 1318 | $0.001396 |
| 3 | 657 | $0.000598 | 661 | $0.000798 | 1318 | $0.001396 |
| 4 | 511 | $0.000598 | 839 | $0.000798 | 1350 | $0.001396 |
| 5 | 581 | $0.000598 | 816 | $0.000798 | 1397 | $0.001396 |

## Already Correct / Do Not Tinker

### correct-buenos-dias

- Original text: `Buenos días, ¿cómo estás?`
- Expected corrected text: `Buenos días, ¿cómo estás?`
- Pass rate: 5/5
- Distinct final outputs:
  - `Buenos días, ¿cómo estás?`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Buenos días, ¿cómo estás?` | (none) | `Buenos días, ¿cómo estás?` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Buenos días, ¿cómo estás?` | (none) | `Buenos días, ¿cómo estás?` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Buenos días, ¿cómo estás?` | (none) | `Buenos días, ¿cómo estás?` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Buenos días, ¿cómo estás?` | (none) | `Buenos días, ¿cómo estás?` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Buenos días, ¿cómo estás?` | (none) | `Buenos días, ¿cómo estás?` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1708 | $0.000588 | 746 | $0.000796 | 2454 | $0.001384 |
| 2 | 545 | $0.000588 | 718 | $0.000796 | 1263 | $0.001384 |
| 3 | 549 | $0.000588 | 847 | $0.000796 | 1396 | $0.001384 |
| 4 | 683 | $0.000588 | 714 | $0.000796 | 1397 | $0.001384 |
| 5 | 477 | $0.000588 | 737 | $0.000796 | 1214 | $0.001384 |

### correct-hacer-pregunta

- Original text: `Voy a hacer una pregunta al profesor.`
- Expected corrected text: `Voy a hacer una pregunta al profesor.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Voy a hacer una pregunta al profesor.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Voy a hacer una pregunta al profesor.` | (none) | `Voy a hacer una pregunta al profesor.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Voy a hacer una pregunta al profesor.` | (none) | `Voy a hacer una pregunta al profesor.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Voy a hacer una pregunta al profesor.` | (none) | `Voy a hacer una pregunta al profesor.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Voy a hacer una pregunta al profesor.` | (none) | `Voy a hacer una pregunta al profesor.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Voy a hacer una pregunta al profesor.` | (none) | `Voy a hacer una pregunta al profesor.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 660 | $0.000598 | 718 | $0.000798 | 1378 | $0.001396 |
| 2 | 539 | $0.000598 | 755 | $0.000798 | 1294 | $0.001396 |
| 3 | 682 | $0.000598 | 612 | $0.000798 | 1294 | $0.001396 |
| 4 | 680 | $0.000598 | 817 | $0.000798 | 1497 | $0.001396 |
| 5 | 483 | $0.000598 | 812 | $0.000798 | 1295 | $0.001396 |

### correct-tomar-foto

- Original text: `Necesito tomar una foto del documento.`
- Expected corrected text: `Necesito tomar una foto del documento.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Necesito tomar una foto del documento.`
  - `Necesito hacer una foto del documento.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Necesito tomar una foto del documento.` | tomar una foto -> hacer una foto | `Necesito hacer una foto del documento.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000598 | 2661 | $0.000798 | 3240 | $0.001396 |
| 2 | 500 | $0.000598 | 1306 | $0.001468 | 1806 | $0.002066 |
| 3 | 682 | $0.000598 | 1022 | $0.000798 | 1704 | $0.001396 |
| 4 | 679 | $0.000598 | 615 | $0.000798 | 1294 | $0.001396 |
| 5 | 679 | $0.000598 | 718 | $0.000798 | 1397 | $0.001396 |

### correct-visitar-abuela

- Original text: `Mañana visitaré a mi abuela.`
- Expected corrected text: `Mañana visitaré a mi abuela.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Mañana visitaré a mi abuela.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Mañana visitaré a mi abuela.` | (none) | `Mañana visitaré a mi abuela.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Mañana visitaré a mi abuela.` | (none) | `Mañana visitaré a mi abuela.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Mañana visitaré a mi abuela.` | (none) | `Mañana visitaré a mi abuela.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Mañana visitaré a mi abuela.` | (none) | `Mañana visitaré a mi abuela.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Mañana visitaré a mi abuela.` | (none) | `Mañana visitaré a mi abuela.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 758 | $0.000618 | 947 | $0.000800 | 1705 | $0.001418 |
| 2 | 680 | $0.000618 | 1071 | $0.000800 | 1751 | $0.001418 |
| 3 | 528 | $0.000618 | 820 | $0.000800 | 1348 | $0.001418 |
| 4 | 991 | $0.000618 | 761 | $0.000800 | 1752 | $0.001418 |
| 5 | 479 | $0.000618 | 764 | $0.000800 | 1243 | $0.001418 |

### correct-me-quedo-en-casa

- Original text: `Está lloviendo, así que me quedo en casa.`
- Expected corrected text: `Está lloviendo, así que me quedo en casa.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Está lloviendo, así que me quedo en casa.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Está lloviendo, así que me quedo en casa.` | (none) | `Está lloviendo, así que me quedo en casa.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Está lloviendo, así que me quedo en casa.` | (none) | `Está lloviendo, así que me quedo en casa.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Está lloviendo, así que me quedo en casa.` | (none) | `Está lloviendo, así que me quedo en casa.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Está lloviendo, así que me quedo en casa.` | (none) | `Está lloviendo, así que me quedo en casa.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Está lloviendo, así que me quedo en casa.` | (none) | `Está lloviendo, así que me quedo en casa.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 581 | $0.000648 | 1023 | $0.000804 | 1604 | $0.001452 |
| 2 | 681 | $0.000648 | 924 | $0.000804 | 1605 | $0.001452 |
| 3 | 574 | $0.000648 | 829 | $0.000804 | 1403 | $0.001452 |
| 4 | 668 | $0.000648 | 820 | $0.000804 | 1488 | $0.001452 |
| 5 | 573 | $0.000648 | 1029 | $0.000804 | 1602 | $0.001452 |

## Mixed Operations

### mixed-preposition-and-redundant-pronoun

- Original text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- Pass rate: 2/5
- Distinct final outputs:
  - `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.`
  - `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
  - `Insisto en que revises el contrato, mientras yo trabajo mucho y estudio por las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | insisto en que revises -> insisto en que revises bien | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | correct_fix | Pass | Matches expected output. |
| 3 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | insisto en que revises el contrato -> insisto en que revises el contrato; yo trabajo mucho y estudio por las noches | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | correct_fix | Pass | Matches expected output. |
| 4 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato, mientras yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato, mientras yo trabajo mucho y estudio por las noches.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000708 | 2352 | $0.002031 | 2929 | $0.002739 |
| 2 | 579 | $0.000708 | 1535 | $0.001711 | 2114 | $0.002419 |
| 3 | 722 | $0.000708 | 1495 | $0.001691 | 2217 | $0.002399 |
| 4 | 681 | $0.000708 | 2049 | $0.002071 | 2730 | $0.002779 |
| 5 | 677 | $0.000708 | 8089 | $0.002161 | 8766 | $0.002869 |

### mixed-article-and-accent

- Original text: `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.`
- Expected corrected text: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 2 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 3 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 4 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 5 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1295 | $0.000702 | 922 | $0.000811 | 2217 | $0.001513 |
| 2 | 680 | $0.000702 | 717 | $0.000811 | 1397 | $0.001513 |
| 3 | 626 | $0.000702 | 771 | $0.000811 | 1397 | $0.001513 |
| 4 | 1070 | $0.000702 | 755 | $0.000811 | 1825 | $0.001513 |
| 5 | 664 | $0.000702 | 816 | $0.000811 | 1480 | $0.001513 |

### mixed-personal-a-and-subjunctive

- Original text: `Vi mi profesor en la estación, y recordé que es importante que estudio.`
- Expected corrected text: `Vi a mi profesor en la estación, y recordé que es importante que estudie.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Vi a mi profesor en la estación y recordé que es importante estudiar.`
  - `Vi a mi profesor en la estación, y recordé que es importante estudiar.`
  - `Vi a mi profesor en la estación, y recordé que era importante que estudiara.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi a mi profesor en la estación y recordé que es importante que estudie.` | es importante que estudie -> es importante estudiar | `Vi a mi profesor en la estación y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Vi a mi profesor en la estación y recordé que es importante que estudie.` | recordé que es importante que estudie -> recordé que es importante estudiar | `Vi a mi profesor en la estación y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | es importante que estudie -> es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | recordé que es importante que estudie -> recordé que era importante que estudiara | `Vi a mi profesor en la estación, y recordé que era importante que estudiara.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | es importante que estudie -> es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 580 | $0.000686 | 1968 | $0.001729 | 2548 | $0.002415 |
| 2 | 552 | $0.000686 | 2151 | $0.001769 | 2703 | $0.002455 |
| 3 | 682 | $0.000694 | 1431 | $0.001510 | 2113 | $0.002204 |
| 4 | 593 | $0.000694 | 3494 | $0.001840 | 4087 | $0.002534 |
| 5 | 663 | $0.000694 | 1625 | $0.001500 | 2288 | $0.002194 |

### mixed-gender-agreement-and-redundant-pronoun

- Original text: `Las ventanas estaban abierto, y a mí me gusta el café a mí.`
- Expected corrected text: `Las ventanas estaban abiertas, y a mí me gusta el café.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Las ventanas estaban abiertas, y a mí me gusta el café.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | (none) | `Las ventanas estaban abiertas, y a mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 2 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | (none) | `Las ventanas estaban abiertas, y a mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 3 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | (none) | `Las ventanas estaban abiertas, y a mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 4 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | (none) | `Las ventanas estaban abiertas, y a mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 5 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | (none) | `Las ventanas estaban abiertas, y a mí me gusta el café.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 580 | $0.000652 | 710 | $0.000804 | 1290 | $0.001456 |
| 2 | 505 | $0.000652 | 842 | $0.000804 | 1347 | $0.001456 |
| 3 | 466 | $0.000652 | 1395 | $0.000804 | 1861 | $0.001456 |
| 4 | 731 | $0.000652 | 927 | $0.000804 | 1658 | $0.001456 |
| 5 | 622 | $0.000652 | 773 | $0.000804 | 1395 | $0.001456 |

### mixed-verb-agreement-and-missing-que

- Original text: `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.`
- Expected corrected text: `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | terminar de estudiar hoy -> dejar de estudiar hoy | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | terminar de estudiar hoy -> dejar de estudiar hoy | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | terminar de estudiar hoy -> dejar de estudiar hoy | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | terminar de estudiar hoy -> dejar de estudiar hoy | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | terminar de estudiar hoy -> dejar de estudiar hoy | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 493 | $0.000696 | 1760 | $0.001690 | 2253 | $0.002386 |
| 2 | 598 | $0.000696 | 1459 | $0.001590 | 2057 | $0.002286 |
| 3 | 643 | $0.000696 | 1851 | $0.001560 | 2494 | $0.002256 |
| 4 | 534 | $0.000696 | 1568 | $0.001640 | 2102 | $0.002336 |
| 5 | 1208 | $0.000696 | 1686 | $0.001580 | 2894 | $0.002276 |

---

## Overall summary

| Metric | Value |
| --- | --- |
| Fixtures | 85 |
| Total runs | 425 |
| Pass rate | 359/425 |

### Score breakdown (issue #129 — full taxonomy, not only pass/fail)

| | Total | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| All runs | 425 | 295 | 22 | 2 | 6 | 64 | 36 | 0 |

### Latency / cost by pass (issue #130 — no fallback phase exists in this harness, so totals equal Pass 1 + Pass 2 only)

| Phase | Total latency (ms) | Total est. cost (USD) |
| --- | --- | --- |
| Pass 1 (first pass) | 267214 | $0.255030 |
| Pass 2 (lexical review) | 445442 | $0.402245 |
| **Total (Pass 1 + Pass 2)** | 712656 | $0.657275 |
