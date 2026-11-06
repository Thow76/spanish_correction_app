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
- Generated: 2026-08-09T16:47:00.233843Z

## Fixture summary

Pass rate is `passed/runs`; "distinct outputs" lists every unique final output produced across a fixture's runs — more than one entry means the model was not stable for that fixture.

| Fixture | Language point | Runs | Pass rate | Distinct final outputs | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| clean-grammar-only | Accents / Diacritics | 5 | 0/5 | `Había mucho tráfico ayer.` | 16395 | $0.010629 |
| naturalness-only | Collocations / Strong Calques | 5 | 5/5 | `Voy a tomar una decisión importante.` | 8620 | $0.007051 |
| grammar-and-naturalness-independent | Accents / Diacritics + Collocations / Strong Calques (independent spans) | 5 | 5/5 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | 8418 | $0.007501 |
| grammar-overlaps-naturalness | Verb Morphology (spelling) overlapping Collocations / Strong Calques | 5 | 5/5 | `Ayer tomó una decisión importante.` | 12921 | $0.009991 |
| ambiguous-naturalness-span | Ambiguous / Repeated Span Safety (Naturalness) | 5 | 4/5 | `Vi mucho tráfico, y luego vi más tráfico.`; `Vi mucho tráfico y luego todavía más.` | 10464 | $0.008221 |
| accent-manana | Accents / Diacritics | 5 | 5/5 | `Voy al parque mañana por la tarde.` | 10115 | $0.007108 |
| accent-medico | Accents / Diacritics | 5 | 5/5 | `El médico llegó después de la reunión.` | 9685 | $0.007118 |
| accent-espana-pais | Accents / Diacritics | 5 | 5/5 | `España es un país muy diverso.` | 7468 | $0.007061 |
| accent-cumpleanos-otono | Accents / Diacritics | 5 | 5/5 | `Mi cumpleaños es en otoño.` | 7970 | $0.007015 |
| accent-cafe-cafeteria | Accents / Diacritics | 5 | 5/5 | `Compré café en una cafetería pequeña.` | 8073 | $0.007154 |
| agreement-ninos-manzanas | Gender / Number Agreement | 5 | 5/5 | `Los niños comen muchas manzanas.` | 8006 | $0.007098 |
| agreement-ventanas-abiertas | Gender / Number Agreement | 5 | 5/5 | `Las ventanas estaban abiertas.` | 8623 | $0.006939 |
| agreement-puerta-cerrada | Gender / Number Agreement | 5 | 5/5 | `Una puerta estaba cerrada.` | 8315 | $0.006985 |
| agreement-billetes-caros | Gender / Number Agreement | 5 | 5/5 | `Los billetes estaban caros.` | 7802 | $0.006995 |
| agreement-fechas-escritas | Gender / Number Agreement | 5 | 5/5 | `Las fechas estaban escritas sin tilde.` | 7877 | $0.007154 |
| verb-nosotros-fuimos | Verb Agreement / Morphology | 5 | 5/5 | `Mis compañeros y yo fuimos a la biblioteca.` | 8956 | $0.007210 |
| verb-ninos-comen | Verb Agreement / Morphology | 5 | 5/5 | `Los niños comen en el jardín.` | 8532 | $0.007051 |
| verb-compre-pan | Verb Agreement / Morphology | 5 | 5/5 | `Yo fui al mercado y compré pan.` | 8818 | $0.007154 |
| verb-ellos-estudian | Verb Agreement / Morphology | 5 | 5/5 | `Ellos estudian todas las noches.` | 7378 | $0.007108 |
| verb-nosotros-vivimos | Verb Agreement / Morphology | 5 | 5/5 | `Nosotros vivimos cerca del centro.` | 8033 | $0.007051 |
| prep-insisto-en | Required Prepositions | 5 | 5/5 | `Insisto en que revises el contrato.` | 8099 | $0.007154 |
| prep-empresa-en-la-que | Required Prepositions | 5 | 2/5 | `La empresa en la que trabajo está cerca.`; `La empresa en la que trabajo queda cerca.`; `La empresa en la que trabajo está cerca de aquí.` | 13020 | $0.011095 |
| prep-dependo-de | Required Prepositions | 5 | 5/5 | `Dependo de que me ayudes mañana.` | 7498 | $0.007154 |
| prep-pienso-en-ti | Required Prepositions | 5 | 5/5 | `Pienso en ti todos los días.` | 8313 | $0.007098 |
| prep-sone-con | Required Prepositions | 5 | 5/5 | `Soñé con mi antiguo colegio.` | 9758 | $0.007098 |
| article-puerta-principal | Articles / Determiners | 5 | 5/5 | `Abrió la puerta principal.` | 8714 | $0.006985 |
| article-un-libro | Articles / Determiners | 5 | 5/5 | `Necesito comprar un libro para la clase.` | 8516 | $0.007154 |
| article-el-profesor-la-regla | Articles / Determiners | 5 | 5/5 | `El profesor explicó la regla otra vez.` | 8529 | $0.007088 |
| article-la-tienda | Articles / Determiners | 5 | 5/5 | `Fui a la tienda después del trabajo.` | 8527 | $0.007154 |
| article-cita-medico | Articles / Determiners | 5 | 5/5 | `Tengo una cita con el médico mañana.` | 8626 | $0.007088 |
| subj-estudies | Subjunctive / Mood | 5 | 5/5 | `Es importante que estudies.` | 8092 | $0.006995 |
| subj-tenga-razon | Subjunctive / Mood | 5 | 5/5 | `No creo que tenga razón.` | 8579 | $0.006995 |
| subj-vengas | Subjunctive / Mood | 5 | 5/5 | `Quiero que vengas conmigo.` | 8053 | $0.007051 |
| subj-enviara | Subjunctive / Mood | 5 | 2/5 | `Era necesario que enviara su parte.`; `Era necesario que enviara su informe.` | 12718 | $0.009888 |
| subj-hable-frances | Subjunctive / Mood | 5 | 5/5 | `Busco a alguien que hable francés.` | 9441 | $0.007154 |
| missing-que-creo | Required Additions / Omissions | 5 | 5/5 | `Creo que está bien terminar hoy.` | 9748 | $0.007041 |
| missing-les-ninos | Required Additions / Omissions | 5 | 5/5 | `A los niños les expliqué la regla.` | 9851 | $0.007098 |
| missing-personal-a-profesor | Required Additions / Omissions | 5 | 5/5 | `Vi a mi profesor en la estación.` | 9755 | $0.007098 |
| missing-se-levanto | Required Additions / Omissions | 5 | 5/5 | `Se levantó temprano ayer.` | 8409 | $0.006995 |
| missing-le-gusta | Required Additions / Omissions | 5 | 5/5 | `A Juan le gusta el café.` | 8110 | $0.007041 |
| delete-repeated-yo-estudio | Unnecessary Extras / Deletions | 5 | 0/5 | `Yo trabajo mucho y yo estudio por las noches.`; `Yo trabajo mucho y yo estudio por la noche.` | 13426 | $0.011200 |
| delete-repeated-ellos-visitaron | Unnecessary Extras / Deletions | 5 | 5/5 | `Ellos viajaron a México y visitaron varias ciudades.`; `Viajaron a México y visitaron varias ciudades.` | 13374 | $0.011209 |
| delete-repeated-a-mi | Unnecessary Extras / Deletions | 5 | 5/5 | `A mí me gusta el café.` | 8175 | $0.007071 |
| delete-repeated-yo-compre | Unnecessary Extras / Deletions | 5 | 5/5 | `Fui al mercado y compré pan.`; `Yo fui al mercado y compré pan.` | 13023 | $0.010790 |
| delete-repeated-nosotros | Unnecessary Extras / Deletions | 5 | 5/5 | `Nosotros salimos temprano y llegamos a tiempo.`; `Salimos temprano y llegamos a tiempo.` | 14352 | $0.011262 |
| ser-profesor | Ser / Estar / Haber | 5 | 5/5 | `Mi hermano es profesor.` | 9242 | $0.006939 |
| haber-veinte-personas | Ser / Estar / Haber | 5 | 5/5 | `En la sala hay veinte personas.` | 8417 | $0.007051 |
| ser-capital-madrid | Ser / Estar / Haber | 5 | 5/5 | `Madrid es la capital de España.` | 8439 | $0.007051 |
| estar-contento | Ser / Estar / Haber | 5 | 5/5 | `Estoy muy contento con el resultado.` | 10136 | $0.007108 |
| ser-reunion-segunda-planta | Ser / Estar / Haber | 5 | 4/5 | `La reunión es en la segunda planta.`; `La reunión es en la segunda piso.` | 9647 | $0.007938 |
| haber-habia-personas | Impersonal Haber / Se | 5 | 5/5 | `Había muchas personas en la entrada.` | 8111 | $0.007108 |
| haber-hubo-problemas | Impersonal Haber / Se | 5 | 5/5 | `Hubo varios problemas durante la reunión.` | 8517 | $0.007108 |
| se-venden-pisos | Impersonal Haber / Se | 5 | 5/5 | `Se venden pisos en el centro.` | 8004 | $0.007051 |
| se-necesitan-voluntarios | Impersonal Haber / Se | 5 | 5/5 | `Se necesitan voluntarios para el evento.` | 8215 | $0.007108 |
| haber-habia-cifras | Impersonal Haber / Se | 5 | 5/5 | `Había varias cifras incorrectas.` | 7857 | $0.007051 |
| collocation-hacer-decision | Collocations / Strong Calques | 5 | 5/5 | `Necesito tomar una decisión.` | 9181 | $0.006995 |
| collocation-hacer-atencion | Collocations / Strong Calques | 5 | 5/5 | `Tenemos que prestar atención.` | 8110 | $0.006939 |
| collocation-tomar-reunion | Collocations / Strong Calques | 5 | 5/5 | `El equipo tuvo una reunión.` | 7495 | $0.006995 |
| collocation-hacer-paseo | Collocations / Strong Calques | 5 | 5/5 | `Ella dio un paseo.` | 10260 | $0.008719 |
| collocation-hace-sentido | Collocations / Strong Calques | 5 | 5/5 | `Esto tiene sentido.` | 8008 | $0.006883 |
| false-friend-atendio-universidad | False Friends / Word Choice | 5 | 5/5 | `Asistió a la universidad en Madrid.` | 8715 | $0.007154 |
| false-friend-aplico-trabajo | False Friends / Word Choice | 5 | 4/5 | `Solicitó un trabajo.`; `Se postuló a un trabajo.`; `Se postuló para un trabajo.` | 12829 | $0.011365 |
| false-friend-realice | False Friends / Word Choice | 5 | 5/5 | `Me di cuenta de que estaba equivocado.` | 8622 | $0.007154 |
| false-friend-embarazado | False Friends / Word Choice | 5 | 3/5 | `Estoy avergonzado por llegar tarde.`; `Estoy avergonzado de llegar tarde.` | 9541 | $0.008704 |
| false-friend-actualmente-control | False Friends / Word Choice | 5 | 5/5 | `Actualmente vivo en Londres.` | 8495 | $0.006939 |
| naturalness-buen-tiempo | Phrase-Level Naturalness | 5 | 5/5 | `Tuvimos un buen rato.` | 14076 | $0.011601 |
| naturalness-corriendo-tarde | Phrase-Level Naturalness | 5 | 5/5 | `Voy a llegar tarde a la reunión.` | 13190 | $0.011961 |
| naturalness-pasar-buen-tiempo | Phrase-Level Naturalness | 5 | 5/5 | `Quiero pasar un buen rato.` | 9073 | $0.007051 |
| naturalness-puedo-tener-cerveza | Phrase-Level Naturalness | 5 | 5/5 | `¿Puedo tomar una cerveza?` | 7704 | $0.007051 |
| naturalness-llamar-para-atras | Phrase-Level Naturalness | 5 | 5/5 | `Te llamo más tarde.`; `Te llamo después.` | 12616 | $0.011135 |
| regional-voy-para-casa | Valid Regional / Should Not Flag | 5 | 0/5 | `Voy a casa ahora mismo.` | 14356 | $0.011021 |
| regional-vos-tenes | Valid Regional / Should Not Flag | 5 | 5/5 | `Vos tenés razón.` | 8214 | $0.006939 |
| regional-cojo-autobus | Valid Regional / Should Not Flag | 5 | 5/5 | `Cojo el autobús cada mañana.` | 8107 | $0.007108 |
| regional-preterite-esta-manana | Valid Regional / Should Not Flag | 5 | 5/5 | `Esta mañana hablé con mi jefe.` | 8522 | $0.007108 |
| regional-dale | Valid Regional / Should Not Flag | 5 | 5/5 | `Dale, nos vemos más tarde.` | 8142 | $0.007108 |
| correct-buenos-dias | Already Correct / Do Not Tinker | 5 | 5/5 | `Buenos días, ¿cómo estás?` | 8076 | $0.007051 |
| correct-hacer-pregunta | Already Correct / Do Not Tinker | 5 | 5/5 | `Voy a hacer una pregunta al profesor.` | 7903 | $0.007108 |
| correct-tomar-foto | Already Correct / Do Not Tinker | 5 | 3/5 | `Necesito sacar una foto del documento.`; `Necesito tomar una foto del documento.`; `Necesito hacer una foto del documento.` | 10775 | $0.008908 |
| correct-visitar-abuela | Already Correct / Do Not Tinker | 5 | 5/5 | `Mañana visitaré a mi abuela.` | 8315 | $0.007220 |
| correct-me-quedo-en-casa | Already Correct / Do Not Tinker | 5 | 5/5 | `Está lloviendo, así que me quedo en casa.` | 8113 | $0.007389 |
| mixed-preposition-and-redundant-pronoun | Mixed Operations | 5 | 1/5 | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.`; `Insisto en que revises el contrato, trabajo mucho y estudio por las noches.`; `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.`; `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | 13446 | $0.012773 |
| mixed-article-and-accent | Mixed Operations | 5 | 4/5 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`; `Necesito comprar un libro para la clase, y compré un café en una cafetería pequeña.` | 8816 | $0.008536 |
| mixed-personal-a-and-subjunctive | Mixed Operations | 5 | 0/5 | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | 14059 | $0.012200 |
| mixed-gender-agreement-and-redundant-pronoun | Mixed Operations | 5 | 5/5 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | 8401 | $0.007409 |
| mixed-verb-agreement-and-missing-que | Mixed Operations | 5 | 0/5 | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | 13124 | $0.011960 |

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
| 2 | `Vi mucho tráfico ayer.` | Vi mucho tráfico -> Había mucho tráfico | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Vi mucho tráfico ayer.` | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1835 | $0.000596 | 2238 | $0.001544 | 4073 | $0.002140 |
| 2 | 867 | $0.000596 | 1945 | $0.001434 | 2812 | $0.002030 |
| 3 | 864 | $0.000596 | 2169 | $0.001654 | 3033 | $0.002250 |
| 4 | 679 | $0.000596 | 2048 | $0.001474 | 2727 | $0.002070 |
| 5 | 1381 | $0.000596 | 2369 | $0.001544 | 3750 | $0.002140 |

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
| 1 | 575 | $0.000624 | 2711 | $0.000798 | 3286 | $0.001422 |
| 2 | 528 | $0.000624 | 916 | $0.000798 | 1444 | $0.001422 |
| 3 | 791 | $0.000624 | 1024 | $0.000798 | 1815 | $0.001422 |
| 4 | 680 | $0.000624 | 927 | $0.000798 | 1607 | $0.001422 |
| 5 | 914 | $0.000624 | 1049 | $0.000798 | 1963 | $0.001422 |

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
| 1 | 619 | $0.000626 | 1024 | $0.000798 | 1643 | $0.001424 |
| 2 | 575 | $0.000626 | 1129 | $0.000798 | 1704 | $0.001424 |
| 3 | 1908 | $0.000626 | 1090 | $0.000798 | 2998 | $0.001424 |
| 4 | 716 | $0.000626 | 1025 | $0.000798 | 1741 | $0.001424 |
| 5 | 689 | $0.000626 | 910 | $0.000798 | 1599 | $0.001424 |

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
| 1 | 480 | $0.000616 | 826 | $0.000796 | 1306 | $0.001412 |
| 2 | 873 | $0.000616 | 1026 | $0.000796 | 1899 | $0.001412 |
| 3 | 579 | $0.000616 | 858 | $0.000796 | 1437 | $0.001412 |
| 4 | 538 | $0.000616 | 921 | $0.000796 | 1459 | $0.001412 |
| 5 | 476 | $0.000616 | 891 | $0.000796 | 1367 | $0.001412 |

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
| 1 | 605 | $0.000608 | 1023 | $0.000795 | 1628 | $0.001403 |
| 2 | 580 | $0.000608 | 1025 | $0.000795 | 1605 | $0.001403 |
| 3 | 748 | $0.000608 | 853 | $0.000795 | 1601 | $0.001403 |
| 4 | 532 | $0.000608 | 1071 | $0.000795 | 1603 | $0.001403 |
| 5 | 576 | $0.000608 | 957 | $0.000795 | 1533 | $0.001403 |

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
| 1 | 566 | $0.000632 | 1206 | $0.000799 | 1772 | $0.001431 |
| 2 | 578 | $0.000632 | 1012 | $0.000799 | 1590 | $0.001431 |
| 3 | 591 | $0.000632 | 1122 | $0.000799 | 1713 | $0.001431 |
| 4 | 679 | $0.000632 | 932 | $0.000799 | 1611 | $0.001431 |
| 5 | 527 | $0.000632 | 860 | $0.000799 | 1387 | $0.001431 |

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
| 1 | 576 | $0.000614 | 1538 | $0.000796 | 2114 | $0.001410 |
| 2 | 493 | $0.000614 | 1137 | $0.000796 | 1630 | $0.001410 |
| 3 | 547 | $0.000614 | 968 | $0.000796 | 1515 | $0.001410 |
| 4 | 635 | $0.000614 | 1023 | $0.000796 | 1658 | $0.001410 |
| 5 | 576 | $0.000614 | 1127 | $0.000796 | 1703 | $0.001410 |

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
| 1 | 624 | $0.000604 | 1026 | $0.000795 | 1650 | $0.001399 |
| 2 | 475 | $0.000604 | 1328 | $0.000795 | 1803 | $0.001399 |
| 3 | 582 | $0.000604 | 1125 | $0.000795 | 1707 | $0.001399 |
| 4 | 511 | $0.000604 | 1483 | $0.000795 | 1994 | $0.001399 |
| 5 | 592 | $0.000604 | 1435 | $0.000795 | 2027 | $0.001399 |

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
| 1 | 682 | $0.000594 | 1125 | $0.000794 | 1807 | $0.001388 |
| 2 | 782 | $0.000594 | 940 | $0.000794 | 1722 | $0.001388 |
| 3 | 542 | $0.000594 | 939 | $0.000794 | 1481 | $0.001388 |
| 4 | 474 | $0.000594 | 922 | $0.000794 | 1396 | $0.001388 |
| 5 | 681 | $0.000594 | 1023 | $0.000794 | 1704 | $0.001388 |

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
| 1 | 575 | $0.000604 | 921 | $0.000795 | 1496 | $0.001399 |
| 2 | 489 | $0.000604 | 965 | $0.000795 | 1454 | $0.001399 |
| 3 | 528 | $0.000604 | 916 | $0.000795 | 1444 | $0.001399 |
| 4 | 578 | $0.000604 | 1023 | $0.000795 | 1601 | $0.001399 |
| 5 | 578 | $0.000604 | 922 | $0.000795 | 1500 | $0.001399 |

### collocation-hacer-paseo

- Original text: `Ella hizo un paseo.`
- Expected corrected text: `Ella dio un paseo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Ella dio un paseo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ella dio un paseo.` | (none) | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Ella dio un paseo.` | (none) | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000594 | 1229 | $0.000794 | 1806 | $0.001388 |
| 2 | 587 | $0.000594 | 1587 | $0.001394 | 2174 | $0.001988 |
| 3 | 619 | $0.000594 | 1844 | $0.001394 | 2463 | $0.001988 |
| 4 | 575 | $0.000594 | 923 | $0.000794 | 1498 | $0.001388 |
| 5 | 679 | $0.000594 | 1640 | $0.001374 | 2319 | $0.001968 |

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
| 1 | 575 | $0.000584 | 1023 | $0.000793 | 1598 | $0.001377 |
| 2 | 783 | $0.000584 | 1023 | $0.000793 | 1806 | $0.001377 |
| 3 | 537 | $0.000584 | 984 | $0.000793 | 1521 | $0.001377 |
| 4 | 559 | $0.000584 | 922 | $0.000793 | 1481 | $0.001377 |
| 5 | 539 | $0.000584 | 1063 | $0.000793 | 1602 | $0.001377 |

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
| 1 | 681 | $0.000694 | 1036 | $0.000806 | 1717 | $0.001500 |
| 2 | 666 | $0.000694 | 1126 | $0.000806 | 1792 | $0.001500 |
| 3 | 680 | $0.000694 | 1027 | $0.000806 | 1707 | $0.001500 |
| 4 | 575 | $0.000694 | 1024 | $0.000806 | 1599 | $0.001500 |
| 5 | 560 | $0.000694 | 1043 | $0.000806 | 1603 | $0.001500 |

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
| 1 | 633 | $0.000614 | 1814 | $0.001446 | 2447 | $0.002060 |
| 2 | 550 | $0.000614 | 1740 | $0.001366 | 2290 | $0.001980 |
| 3 | 680 | $0.000614 | 2049 | $0.001406 | 2729 | $0.002020 |
| 4 | 575 | $0.000614 | 2048 | $0.001366 | 2623 | $0.001980 |
| 5 | 680 | $0.000614 | 2152 | $0.001336 | 2832 | $0.001950 |

## Ambiguous / Repeated Span Safety (Naturalness)

### ambiguous-naturalness-span

- Original text: `Vi mucho tráfico, y luego vi más tráfico.`
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Vi mucho tráfico, y luego vi más tráfico.`
  - `Vi mucho tráfico y luego todavía más.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Vi mucho tráfico y luego vi más tráfico.` | Vi mucho tráfico y luego vi más tráfico. -> Vi mucho tráfico y luego todavía más. | `Vi mucho tráfico y luego todavía más.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 624 | $0.000644 | 1282 | $0.000800 | 1906 | $0.001444 |
| 2 | 586 | $0.000644 | 1735 | $0.000800 | 2321 | $0.001444 |
| 3 | 676 | $0.000644 | 1232 | $0.000800 | 1908 | $0.001444 |
| 4 | 679 | $0.000644 | 1126 | $0.000800 | 1805 | $0.001444 |
| 5 | 507 | $0.000636 | 2017 | $0.001809 | 2524 | $0.002445 |

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
| 1 | 576 | $0.000622 | 1127 | $0.000798 | 1703 | $0.001420 |
| 2 | 677 | $0.000622 | 1126 | $0.000798 | 1803 | $0.001420 |
| 3 | 565 | $0.000622 | 947 | $0.000798 | 1512 | $0.001420 |
| 4 | 566 | $0.000622 | 951 | $0.000798 | 1517 | $0.001420 |
| 5 | 549 | $0.000622 | 922 | $0.000798 | 1471 | $0.001420 |

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
| 1 | 576 | $0.000594 | 900 | $0.000794 | 1476 | $0.001388 |
| 2 | 662 | $0.000594 | 906 | $0.000794 | 1568 | $0.001388 |
| 3 | 634 | $0.000594 | 1125 | $0.000794 | 1759 | $0.001388 |
| 4 | 530 | $0.000594 | 1071 | $0.000794 | 1601 | $0.001388 |
| 5 | 756 | $0.000594 | 1463 | $0.000794 | 2219 | $0.001388 |

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
| 1 | 537 | $0.000602 | 941 | $0.000795 | 1478 | $0.001397 |
| 2 | 804 | $0.000602 | 1003 | $0.000795 | 1807 | $0.001397 |
| 3 | 660 | $0.000602 | 965 | $0.000795 | 1625 | $0.001397 |
| 4 | 575 | $0.000602 | 1376 | $0.000795 | 1951 | $0.001397 |
| 5 | 533 | $0.000602 | 921 | $0.000795 | 1454 | $0.001397 |

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
| 1 | 625 | $0.000604 | 873 | $0.000795 | 1498 | $0.001399 |
| 2 | 578 | $0.000604 | 923 | $0.000795 | 1501 | $0.001399 |
| 3 | 540 | $0.000604 | 1061 | $0.000795 | 1601 | $0.001399 |
| 4 | 577 | $0.000604 | 934 | $0.000795 | 1511 | $0.001399 |
| 5 | 666 | $0.000604 | 1025 | $0.000795 | 1691 | $0.001399 |

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
| 1 | 578 | $0.000632 | 838 | $0.000799 | 1416 | $0.001431 |
| 2 | 661 | $0.000632 | 931 | $0.000799 | 1592 | $0.001431 |
| 3 | 670 | $0.000632 | 985 | $0.000799 | 1655 | $0.001431 |
| 4 | 617 | $0.000632 | 1073 | $0.000799 | 1690 | $0.001431 |
| 5 | 631 | $0.000632 | 893 | $0.000799 | 1524 | $0.001431 |

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
| 1 | 580 | $0.000642 | 1255 | $0.000800 | 1835 | $0.001442 |
| 2 | 585 | $0.000642 | 911 | $0.000800 | 1496 | $0.001442 |
| 3 | 580 | $0.000642 | 979 | $0.000800 | 1559 | $0.001442 |
| 4 | 621 | $0.000642 | 1022 | $0.000800 | 1643 | $0.001442 |
| 5 | 684 | $0.000642 | 1739 | $0.000800 | 2423 | $0.001442 |

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
| 1 | 682 | $0.000614 | 1105 | $0.000796 | 1787 | $0.001410 |
| 2 | 597 | $0.000614 | 1026 | $0.000796 | 1623 | $0.001410 |
| 3 | 574 | $0.000614 | 1026 | $0.000796 | 1600 | $0.001410 |
| 4 | 578 | $0.000614 | 1024 | $0.000796 | 1602 | $0.001410 |
| 5 | 962 | $0.000614 | 958 | $0.000796 | 1920 | $0.001410 |

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
| 1 | 566 | $0.000632 | 1230 | $0.000799 | 1796 | $0.001431 |
| 2 | 528 | $0.000632 | 1177 | $0.000799 | 1705 | $0.001431 |
| 3 | 630 | $0.000632 | 972 | $0.000799 | 1602 | $0.001431 |
| 4 | 781 | $0.000632 | 1127 | $0.000799 | 1908 | $0.001431 |
| 5 | 782 | $0.000632 | 1025 | $0.000799 | 1807 | $0.001431 |

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
| 1 | 486 | $0.000624 | 1012 | $0.000798 | 1498 | $0.001422 |
| 2 | 545 | $0.000624 | 924 | $0.000798 | 1469 | $0.001422 |
| 3 | 505 | $0.000624 | 1023 | $0.000798 | 1528 | $0.001422 |
| 4 | 579 | $0.000624 | 853 | $0.000798 | 1432 | $0.001422 |
| 5 | 547 | $0.000624 | 904 | $0.000798 | 1451 | $0.001422 |

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
| 1 | 593 | $0.000614 | 924 | $0.000796 | 1517 | $0.001410 |
| 2 | 575 | $0.000614 | 924 | $0.000796 | 1499 | $0.001410 |
| 3 | 573 | $0.000614 | 1025 | $0.000796 | 1598 | $0.001410 |
| 4 | 538 | $0.000614 | 1107 | $0.000796 | 1645 | $0.001410 |
| 5 | 738 | $0.000614 | 1036 | $0.000796 | 1774 | $0.001410 |

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
| 1 | 860 | $0.000632 | 936 | $0.000799 | 1796 | $0.001431 |
| 2 | 679 | $0.000632 | 924 | $0.000799 | 1603 | $0.001431 |
| 3 | 699 | $0.000632 | 1005 | $0.000799 | 1704 | $0.001431 |
| 4 | 507 | $0.000632 | 890 | $0.000799 | 1397 | $0.001431 |
| 5 | 575 | $0.000632 | 1024 | $0.000799 | 1599 | $0.001431 |

### prep-empresa-en-la-que

- Original text: `La empresa que trabajo está cerca.`
- Expected corrected text: `La empresa en la que trabajo está cerca.`
- Pass rate: 2/5
- Distinct final outputs:
  - `La empresa en la que trabajo está cerca.`
  - `La empresa en la que trabajo queda cerca.`
  - `La empresa en la que trabajo está cerca de aquí.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `La empresa en que trabajo está cerca.` | en que trabajo -> en la que trabajo | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 2 | `La empresa en la que trabajo está cerca.` | está cerca -> queda cerca | `La empresa en la que trabajo queda cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `La empresa en la que trabajo está cerca.` | está cerca -> queda cerca | `La empresa en la que trabajo queda cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `La empresa en la que trabajo está cerca.` | cerca -> cerca de aquí | `La empresa en la que trabajo está cerca de aquí.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `La empresa en que trabajo está cerca.` | en que trabajo -> en la que trabajo | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000622 | 1668 | $0.001498 | 2247 | $0.002120 |
| 2 | 547 | $0.000630 | 1844 | $0.001719 | 2391 | $0.002349 |
| 3 | 683 | $0.000630 | 2351 | $0.001689 | 3034 | $0.002319 |
| 4 | 575 | $0.000630 | 2050 | $0.001469 | 2625 | $0.002099 |
| 5 | 576 | $0.000622 | 2147 | $0.001587 | 2723 | $0.002210 |

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
| 1 | 554 | $0.000632 | 974 | $0.000799 | 1528 | $0.001431 |
| 2 | 553 | $0.000632 | 921 | $0.000799 | 1474 | $0.001431 |
| 3 | 459 | $0.000632 | 937 | $0.000799 | 1396 | $0.001431 |
| 4 | 677 | $0.000632 | 924 | $0.000799 | 1601 | $0.001431 |
| 5 | 577 | $0.000632 | 922 | $0.000799 | 1499 | $0.001431 |

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
| 1 | 464 | $0.000622 | 1241 | $0.000798 | 1705 | $0.001420 |
| 2 | 575 | $0.000622 | 924 | $0.000798 | 1499 | $0.001420 |
| 3 | 575 | $0.000622 | 1026 | $0.000798 | 1601 | $0.001420 |
| 4 | 501 | $0.000622 | 1097 | $0.000798 | 1598 | $0.001420 |
| 5 | 680 | $0.000622 | 1230 | $0.000798 | 1910 | $0.001420 |

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
| 1 | 575 | $0.000622 | 924 | $0.000798 | 1499 | $0.001420 |
| 2 | 577 | $0.000622 | 1127 | $0.000798 | 1704 | $0.001420 |
| 3 | 576 | $0.000622 | 1197 | $0.000798 | 1773 | $0.001420 |
| 4 | 611 | $0.000622 | 1257 | $0.000798 | 1868 | $0.001420 |
| 5 | 1780 | $0.000622 | 1134 | $0.000798 | 2914 | $0.001420 |

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
| 1 | 567 | $0.000602 | 1024 | $0.000795 | 1591 | $0.001397 |
| 2 | 679 | $0.000602 | 1157 | $0.000795 | 1836 | $0.001397 |
| 3 | 651 | $0.000602 | 1046 | $0.000795 | 1697 | $0.001397 |
| 4 | 658 | $0.000602 | 1399 | $0.000795 | 2057 | $0.001397 |
| 5 | 613 | $0.000602 | 920 | $0.000795 | 1533 | $0.001397 |

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
| 1 | 594 | $0.000632 | 907 | $0.000799 | 1501 | $0.001431 |
| 2 | 576 | $0.000632 | 1025 | $0.000799 | 1601 | $0.001431 |
| 3 | 575 | $0.000632 | 1128 | $0.000799 | 1703 | $0.001431 |
| 4 | 490 | $0.000632 | 1227 | $0.000799 | 1717 | $0.001431 |
| 5 | 1012 | $0.000632 | 982 | $0.000799 | 1994 | $0.001431 |

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
| 1 | 579 | $0.000620 | 974 | $0.000798 | 1553 | $0.001417 |
| 2 | 669 | $0.000620 | 876 | $0.000798 | 1545 | $0.001417 |
| 3 | 557 | $0.000620 | 957 | $0.000798 | 1514 | $0.001417 |
| 4 | 770 | $0.000620 | 1537 | $0.000798 | 2307 | $0.001417 |
| 5 | 588 | $0.000620 | 1022 | $0.000798 | 1610 | $0.001417 |

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
| 1 | 672 | $0.000632 | 1024 | $0.000799 | 1696 | $0.001431 |
| 2 | 521 | $0.000632 | 1441 | $0.000799 | 1962 | $0.001431 |
| 3 | 657 | $0.000632 | 891 | $0.000799 | 1548 | $0.001431 |
| 4 | 551 | $0.000632 | 1079 | $0.000799 | 1630 | $0.001431 |
| 5 | 649 | $0.000632 | 1042 | $0.000799 | 1691 | $0.001431 |

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
| 1 | 644 | $0.000620 | 943 | $0.000798 | 1587 | $0.001417 |
| 2 | 678 | $0.000620 | 1025 | $0.000798 | 1703 | $0.001417 |
| 3 | 577 | $0.000620 | 1032 | $0.000798 | 1609 | $0.001417 |
| 4 | 570 | $0.000620 | 1291 | $0.000798 | 1861 | $0.001417 |
| 5 | 873 | $0.000620 | 993 | $0.000798 | 1866 | $0.001417 |

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
| 1 | 559 | $0.000604 | 923 | $0.000795 | 1482 | $0.001399 |
| 2 | 681 | $0.000604 | 1050 | $0.000795 | 1731 | $0.001399 |
| 3 | 551 | $0.000604 | 1122 | $0.000795 | 1673 | $0.001399 |
| 4 | 682 | $0.000604 | 1024 | $0.000795 | 1706 | $0.001399 |
| 5 | 492 | $0.000604 | 1008 | $0.000795 | 1500 | $0.001399 |

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
| 1 | 495 | $0.000604 | 1106 | $0.000795 | 1601 | $0.001399 |
| 2 | 576 | $0.000604 | 1233 | $0.000795 | 1809 | $0.001399 |
| 3 | 678 | $0.000604 | 1192 | $0.000795 | 1870 | $0.001399 |
| 4 | 614 | $0.000604 | 922 | $0.000795 | 1536 | $0.001399 |
| 5 | 682 | $0.000604 | 1081 | $0.000795 | 1763 | $0.001399 |

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
| 1 | 526 | $0.000614 | 916 | $0.000796 | 1442 | $0.001410 |
| 2 | 475 | $0.000614 | 1024 | $0.000796 | 1499 | $0.001410 |
| 3 | 679 | $0.000614 | 1140 | $0.000796 | 1819 | $0.001410 |
| 4 | 566 | $0.000614 | 1025 | $0.000796 | 1591 | $0.001410 |
| 5 | 577 | $0.000614 | 1125 | $0.000796 | 1702 | $0.001410 |

### subj-enviara

- Original text: `Era necesario que enviaba su parte.`
- Expected corrected text: `Era necesario que enviara su parte.`
- Pass rate: 2/5
- Distinct final outputs:
  - `Era necesario que enviara su parte.`
  - `Era necesario que enviara su informe.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 2 | `Era necesario que enviara su parte.` | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Era necesario que enviara su parte.` | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 5 | `Era necesario que enviara su parte.` | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 511 | $0.000624 | 1508 | $0.000798 | 2019 | $0.001422 |
| 2 | 673 | $0.000624 | 1945 | $0.001597 | 2618 | $0.002221 |
| 3 | 884 | $0.000624 | 2253 | $0.001717 | 3137 | $0.002341 |
| 4 | 680 | $0.000624 | 1127 | $0.000798 | 1807 | $0.001422 |
| 5 | 510 | $0.000624 | 2627 | $0.001858 | 3137 | $0.002482 |

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
| 1 | 782 | $0.000632 | 1024 | $0.000799 | 1806 | $0.001431 |
| 2 | 790 | $0.000632 | 1117 | $0.000799 | 1907 | $0.001431 |
| 3 | 524 | $0.000632 | 1080 | $0.000799 | 1604 | $0.001431 |
| 4 | 1294 | $0.000632 | 1125 | $0.000799 | 2419 | $0.001431 |
| 5 | 735 | $0.000632 | 970 | $0.000799 | 1705 | $0.001431 |

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
| 1 | 883 | $0.000612 | 1025 | $0.000796 | 1908 | $0.001408 |
| 2 | 781 | $0.000612 | 1127 | $0.000796 | 1908 | $0.001408 |
| 3 | 782 | $0.000612 | 1025 | $0.000796 | 1807 | $0.001408 |
| 4 | 680 | $0.000612 | 1330 | $0.000796 | 2010 | $0.001408 |
| 5 | 1089 | $0.000612 | 1026 | $0.000796 | 2115 | $0.001408 |

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
| 1 | 748 | $0.000622 | 1059 | $0.000798 | 1807 | $0.001420 |
| 2 | 472 | $0.000622 | 1130 | $0.000798 | 1602 | $0.001420 |
| 3 | 576 | $0.000622 | 1477 | $0.000798 | 2053 | $0.001420 |
| 4 | 738 | $0.000622 | 1845 | $0.000798 | 2583 | $0.001420 |
| 5 | 785 | $0.000622 | 1021 | $0.000798 | 1806 | $0.001420 |

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
| 1 | 474 | $0.000622 | 1127 | $0.000798 | 1601 | $0.001420 |
| 2 | 538 | $0.000622 | 1064 | $0.000798 | 1602 | $0.001420 |
| 3 | 572 | $0.000622 | 1244 | $0.000798 | 1816 | $0.001420 |
| 4 | 2203 | $0.000622 | 1083 | $0.000798 | 3286 | $0.001420 |
| 5 | 485 | $0.000622 | 965 | $0.000798 | 1450 | $0.001420 |

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
| 1 | 670 | $0.000604 | 1024 | $0.000795 | 1694 | $0.001399 |
| 2 | 784 | $0.000604 | 1125 | $0.000795 | 1909 | $0.001399 |
| 3 | 577 | $0.000604 | 1025 | $0.000795 | 1602 | $0.001399 |
| 4 | 739 | $0.000604 | 965 | $0.000795 | 1704 | $0.001399 |
| 5 | 578 | $0.000604 | 922 | $0.000795 | 1500 | $0.001399 |

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
| 1 | 578 | $0.000612 | 1023 | $0.000796 | 1601 | $0.001408 |
| 2 | 577 | $0.000612 | 1025 | $0.000796 | 1602 | $0.001408 |
| 3 | 497 | $0.000612 | 907 | $0.000796 | 1404 | $0.001408 |
| 4 | 514 | $0.000612 | 1193 | $0.000796 | 1707 | $0.001408 |
| 5 | 666 | $0.000612 | 1130 | $0.000796 | 1796 | $0.001408 |

## Unnecessary Extras / Deletions

### delete-repeated-yo-estudio

- Original text: `Yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Yo trabajo mucho y yo estudio por las noches.`
  - `Yo trabajo mucho y yo estudio por la noche.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por las noches / en las noches | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por las noches / por la noche | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 5 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000644 | 1844 | $0.001500 | 2421 | $0.002144 |
| 2 | 679 | $0.000644 | 2355 | $0.001620 | 3034 | $0.002264 |
| 3 | 474 | $0.000644 | 1945 | $0.001500 | 2419 | $0.002144 |
| 4 | 579 | $0.000644 | 1797 | $0.001760 | 2376 | $0.002404 |
| 5 | 622 | $0.000644 | 2554 | $0.001600 | 3176 | $0.002244 |

### delete-repeated-ellos-visitaron

- Original text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Expected corrected text: `Ellos viajaron a México y visitaron varias ciudades.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Ellos viajaron a México y visitaron varias ciudades.`
  - `Viajaron a México y visitaron varias ciudades.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | Ellos viajaron a México y ellos visitaron varias ciudades. -> Ellos viajaron a México y visitaron varias ciudades. | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 2 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | Ellos viajaron a México y ellos visitaron varias ciudades. -> Ellos viajaron a México y visitaron varias ciudades. | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | Ellos viajaron a México y ellos visitaron varias ciudades. -> Ellos viajaron a México y visitaron varias ciudades. | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 4 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | Ellos viajaron a México y ellos visitaron varias ciudades. -> Viajaron a México y visitaron varias ciudades. | `Viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | Ellos viajaron a México y ellos visitaron varias ciudades. -> Ellos viajaron a México y visitaron varias ciudades. | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 585 | $0.000674 | 2046 | $0.001594 | 2631 | $0.002268 |
| 2 | 793 | $0.000674 | 2445 | $0.001644 | 3238 | $0.002318 |
| 3 | 578 | $0.000674 | 1990 | $0.001564 | 2568 | $0.002238 |
| 4 | 636 | $0.000674 | 1640 | $0.001474 | 2276 | $0.002148 |
| 5 | 678 | $0.000674 | 1983 | $0.001564 | 2661 | $0.002238 |

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
| 1 | 539 | $0.000618 | 1230 | $0.000796 | 1769 | $0.001414 |
| 2 | 575 | $0.000618 | 1130 | $0.000796 | 1705 | $0.001414 |
| 3 | 577 | $0.000618 | 1025 | $0.000796 | 1602 | $0.001414 |
| 4 | 576 | $0.000618 | 922 | $0.000796 | 1498 | $0.001414 |
| 5 | 579 | $0.000618 | 1022 | $0.000796 | 1601 | $0.001414 |

### delete-repeated-yo-compre

- Original text: `Yo fui al mercado y yo compré pan.`
- Expected corrected text: `Fui al mercado y compré pan.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Fui al mercado y compré pan.`
  - `Yo fui al mercado y compré pan.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo fui al mercado y yo compré pan.` | Yo fui al mercado y yo compré pan. -> Fui al mercado y compré pan. | `Fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 2 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 3 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 4 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 5 | `Yo fui al mercado y yo compré pan.` | yo compré pan -> compré pan | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 680 | $0.000644 | 2356 | $0.001580 | 3036 | $0.002224 |
| 2 | 661 | $0.000644 | 2097 | $0.001600 | 2758 | $0.002244 |
| 3 | 547 | $0.000644 | 1864 | $0.001430 | 2411 | $0.002074 |
| 4 | 655 | $0.000644 | 1751 | $0.001520 | 2406 | $0.002164 |
| 5 | 492 | $0.000644 | 1920 | $0.001440 | 2412 | $0.002084 |

### delete-repeated-nosotros

- Original text: `Nosotros salimos temprano y nosotros llegamos a tiempo.`
- Expected corrected text: `Nosotros salimos temprano y llegamos a tiempo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Nosotros salimos temprano y llegamos a tiempo.`
  - `Salimos temprano y llegamos a tiempo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo -> Nosotros salimos temprano y llegamos a tiempo | `Nosotros salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Nosotros salimos temprano y llegamos a tiempo. | `Nosotros salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000664 | 1985 | $0.001502 | 2562 | $0.002167 |
| 2 | 639 | $0.000664 | 1742 | $0.001542 | 2381 | $0.002206 |
| 3 | 588 | $0.000664 | 2446 | $0.001642 | 3034 | $0.002306 |
| 4 | 1089 | $0.000664 | 2052 | $0.001572 | 3141 | $0.002236 |
| 5 | 575 | $0.000664 | 2659 | $0.001682 | 3234 | $0.002347 |

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
| 1 | 1318 | $0.000594 | 1105 | $0.000794 | 2423 | $0.001388 |
| 2 | 578 | $0.000594 | 923 | $0.000794 | 1501 | $0.001388 |
| 3 | 578 | $0.000594 | 1023 | $0.000794 | 1601 | $0.001388 |
| 4 | 782 | $0.000594 | 1026 | $0.000794 | 1808 | $0.001388 |
| 5 | 473 | $0.000594 | 1436 | $0.000794 | 1909 | $0.001388 |

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
| 1 | 680 | $0.000614 | 1025 | $0.000796 | 1705 | $0.001410 |
| 2 | 532 | $0.000614 | 1065 | $0.000796 | 1597 | $0.001410 |
| 3 | 477 | $0.000614 | 1035 | $0.000796 | 1512 | $0.001410 |
| 4 | 611 | $0.000614 | 983 | $0.000796 | 1594 | $0.001410 |
| 5 | 583 | $0.000614 | 1426 | $0.000796 | 2009 | $0.001410 |

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
| 1 | 579 | $0.000614 | 1128 | $0.000796 | 1707 | $0.001410 |
| 2 | 587 | $0.000614 | 1064 | $0.000796 | 1651 | $0.001410 |
| 3 | 628 | $0.000614 | 1334 | $0.000796 | 1962 | $0.001410 |
| 4 | 576 | $0.000614 | 1022 | $0.000796 | 1598 | $0.001410 |
| 5 | 472 | $0.000614 | 1049 | $0.000796 | 1521 | $0.001410 |

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
| 1 | 595 | $0.000624 | 1088 | $0.000798 | 1683 | $0.001422 |
| 2 | 1911 | $0.000624 | 930 | $0.000798 | 2841 | $0.001422 |
| 3 | 554 | $0.000624 | 1048 | $0.000798 | 1602 | $0.001422 |
| 4 | 817 | $0.000624 | 1184 | $0.000798 | 2001 | $0.001422 |
| 5 | 780 | $0.000624 | 1229 | $0.000798 | 2009 | $0.001422 |

### ser-reunion-segunda-planta

- Original text: `La reunión es en la segunda planta.`
- Expected corrected text: `La reunión es en la segunda planta.`
- Pass rate: 4/5
- Distinct final outputs:
  - `La reunión es en la segunda planta.`
  - `La reunión es en la segunda piso.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `La reunión es en la segunda planta.` | planta -> piso | `La reunión es en la segunda piso.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 3 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 682 | $0.000624 | 1020 | $0.000798 | 1702 | $0.001422 |
| 2 | 478 | $0.000624 | 2453 | $0.001628 | 2931 | $0.002252 |
| 3 | 499 | $0.000624 | 1003 | $0.000798 | 1502 | $0.001422 |
| 4 | 681 | $0.000624 | 1023 | $0.000798 | 1704 | $0.001422 |
| 5 | 578 | $0.000624 | 1230 | $0.000798 | 1808 | $0.001422 |

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
| 1 | 575 | $0.000624 | 1026 | $0.000798 | 1601 | $0.001422 |
| 2 | 577 | $0.000624 | 943 | $0.000798 | 1520 | $0.001422 |
| 3 | 757 | $0.000624 | 1028 | $0.000798 | 1785 | $0.001422 |
| 4 | 476 | $0.000624 | 1106 | $0.000798 | 1582 | $0.001422 |
| 5 | 598 | $0.000624 | 1025 | $0.000798 | 1623 | $0.001422 |

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
| 1 | 575 | $0.000624 | 1640 | $0.000798 | 2215 | $0.001422 |
| 2 | 587 | $0.000624 | 1024 | $0.000798 | 1611 | $0.001422 |
| 3 | 565 | $0.000624 | 924 | $0.000798 | 1489 | $0.001422 |
| 4 | 578 | $0.000624 | 1024 | $0.000798 | 1602 | $0.001422 |
| 5 | 576 | $0.000624 | 1024 | $0.000798 | 1600 | $0.001422 |

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
| 1 | 580 | $0.000614 | 1178 | $0.000796 | 1758 | $0.001410 |
| 2 | 534 | $0.000614 | 995 | $0.000796 | 1529 | $0.001410 |
| 3 | 696 | $0.000614 | 851 | $0.000796 | 1547 | $0.001410 |
| 4 | 497 | $0.000614 | 981 | $0.000796 | 1478 | $0.001410 |
| 5 | 667 | $0.000614 | 1025 | $0.000796 | 1692 | $0.001410 |

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
| 1 | 471 | $0.000624 | 929 | $0.000798 | 1400 | $0.001422 |
| 2 | 558 | $0.000624 | 1248 | $0.000798 | 1806 | $0.001422 |
| 3 | 578 | $0.000624 | 1230 | $0.000798 | 1808 | $0.001422 |
| 4 | 575 | $0.000624 | 924 | $0.000798 | 1499 | $0.001422 |
| 5 | 576 | $0.000624 | 1126 | $0.000798 | 1702 | $0.001422 |

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
| 1 | 782 | $0.000614 | 922 | $0.000796 | 1704 | $0.001410 |
| 2 | 476 | $0.000614 | 894 | $0.000796 | 1370 | $0.001410 |
| 3 | 530 | $0.000614 | 997 | $0.000796 | 1527 | $0.001410 |
| 4 | 680 | $0.000614 | 868 | $0.000796 | 1548 | $0.001410 |
| 5 | 629 | $0.000614 | 1079 | $0.000796 | 1708 | $0.001410 |

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
| 1 | 532 | $0.000632 | 1683 | $0.000799 | 2215 | $0.001431 |
| 2 | 600 | $0.000632 | 1103 | $0.000799 | 1703 | $0.001431 |
| 3 | 435 | $0.000632 | 1065 | $0.000799 | 1500 | $0.001431 |
| 4 | 609 | $0.000632 | 1198 | $0.000799 | 1807 | $0.001431 |
| 5 | 475 | $0.000632 | 1015 | $0.000799 | 1490 | $0.001431 |

### false-friend-aplico-trabajo

- Original text: `Aplicó para un trabajo.`
- Expected corrected text: `Solicitó un trabajo.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Solicitó un trabajo.`
  - `Se postuló a un trabajo.`
  - `Se postuló para un trabajo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Aplicó a un trabajo.` | Aplicó a un trabajo -> Se postuló a un trabajo | `Se postuló a un trabajo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Aplicó para un trabajo.` | Aplicó para un trabajo. -> Solicitó un trabajo. | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Aplicó a un trabajo.` | Aplicó a un trabajo -> Se postuló para un trabajo | `Se postuló para un trabajo.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Aplicó a un trabajo.` | Aplicó a un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 585 | $0.000604 | 2050 | $0.001575 | 2635 | $0.002179 |
| 2 | 678 | $0.000604 | 2253 | $0.001775 | 2931 | $0.002379 |
| 3 | 579 | $0.000604 | 1842 | $0.001625 | 2421 | $0.002229 |
| 4 | 576 | $0.000604 | 1842 | $0.001705 | 2418 | $0.002309 |
| 5 | 478 | $0.000604 | 1946 | $0.001665 | 2424 | $0.002269 |

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
| 1 | 578 | $0.000632 | 1535 | $0.000799 | 2113 | $0.001431 |
| 2 | 475 | $0.000632 | 935 | $0.000799 | 1410 | $0.001431 |
| 3 | 565 | $0.000632 | 1435 | $0.000799 | 2000 | $0.001431 |
| 4 | 676 | $0.000632 | 927 | $0.000799 | 1603 | $0.001431 |
| 5 | 573 | $0.000632 | 923 | $0.000799 | 1496 | $0.001431 |

### false-friend-embarazado

- Original text: `Estoy embarazado por llegar tarde.`
- Expected corrected text: `Me da vergüenza llegar tarde.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Estoy avergonzado por llegar tarde.`
  - `Estoy avergonzado de llegar tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy avergonzado por llegar tarde.` | por llegar tarde -> de llegar tarde | `Estoy avergonzado de llegar tarde.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Estoy avergonzado por llegar tarde.` | por llegar tarde -> de llegar tarde | `Estoy avergonzado de llegar tarde.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 576 | $0.000632 | 932 | $0.000799 | 1508 | $0.001431 |
| 2 | 566 | $0.000632 | 1847 | $0.001599 | 2413 | $0.002231 |
| 3 | 882 | $0.000632 | 1639 | $0.001549 | 2521 | $0.002181 |
| 4 | 580 | $0.000632 | 936 | $0.000799 | 1516 | $0.001431 |
| 5 | 559 | $0.000632 | 1024 | $0.000799 | 1583 | $0.001431 |

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
| 1 | 691 | $0.000594 | 1024 | $0.000794 | 1715 | $0.001388 |
| 2 | 568 | $0.000594 | 1023 | $0.000794 | 1591 | $0.001388 |
| 3 | 681 | $0.000594 | 932 | $0.000794 | 1613 | $0.001388 |
| 4 | 577 | $0.000594 | 1528 | $0.000794 | 2105 | $0.001388 |
| 5 | 615 | $0.000594 | 856 | $0.000794 | 1471 | $0.001388 |

## Phrase-Level Naturalness

### naturalness-buen-tiempo

- Original text: `Tuvimos un buen tiempo.`
- Expected corrected text: `Lo pasamos bien.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Tuvimos un buen rato.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 2 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 3 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 4 | `Tuvimos un buen tiempo.` | buen tiempo -> buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 5 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 604 | $0.000614 | 2252 | $0.001726 | 2856 | $0.002340 |
| 2 | 678 | $0.000614 | 2357 | $0.001656 | 3035 | $0.002270 |
| 3 | 576 | $0.000614 | 1950 | $0.001616 | 2526 | $0.002230 |
| 4 | 675 | $0.000614 | 2255 | $0.001786 | 2930 | $0.002400 |
| 5 | 546 | $0.000614 | 2183 | $0.001746 | 2729 | $0.002360 |

### naturalness-corriendo-tarde

- Original text: `Estoy corriendo tarde para la reunión.`
- Expected corrected text: `Voy tarde a la reunión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Voy a llegar tarde a la reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión -> Voy a llegar tarde a la reunión | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión -> Voy a llegar tarde a la reunión | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 4 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión -> Voy a llegar tarde a la reunión | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 578 | $0.000616 | 1843 | $0.001846 | 2421 | $0.002462 |
| 2 | 576 | $0.000616 | 1855 | $0.001626 | 2431 | $0.002242 |
| 3 | 669 | $0.000616 | 2047 | $0.001796 | 2716 | $0.002412 |
| 4 | 886 | $0.000616 | 1892 | $0.001766 | 2778 | $0.002382 |
| 5 | 632 | $0.000616 | 2212 | $0.001846 | 2844 | $0.002462 |

### naturalness-pasar-buen-tiempo

- Original text: `Quiero pasar un buen tiempo.`
- Expected corrected text: `Quiero pasarlo bien.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Quiero pasar un buen rato.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | correct_fix | Pass | Matches expected output. |
| 2 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | correct_fix | Pass | Matches expected output. |
| 3 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | correct_fix | Pass | Matches expected output. |
| 4 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | correct_fix | Pass | Matches expected output. |
| 5 | `Quiero pasar un buen rato.` | (none) | `Quiero pasar un buen rato.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 616 | $0.000614 | 1128 | $0.000796 | 1744 | $0.001410 |
| 2 | 577 | $0.000614 | 1026 | $0.000796 | 1603 | $0.001410 |
| 3 | 547 | $0.000614 | 1055 | $0.000796 | 1602 | $0.001410 |
| 4 | 1504 | $0.000614 | 913 | $0.000796 | 2417 | $0.001410 |
| 5 | 683 | $0.000614 | 1024 | $0.000796 | 1707 | $0.001410 |

### naturalness-puedo-tener-cerveza

- Original text: `¿Puedo tener una cerveza?`
- Expected corrected text: `¿Me pones una cerveza?`
- Pass rate: 5/5
- Distinct final outputs:
  - `¿Puedo tomar una cerveza?`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | correct_fix | Pass | Matches expected output. |
| 2 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | correct_fix | Pass | Matches expected output. |
| 3 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | correct_fix | Pass | Matches expected output. |
| 4 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | correct_fix | Pass | Matches expected output. |
| 5 | `¿Puedo tomar una cerveza?` | (none) | `¿Puedo tomar una cerveza?` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 578 | $0.000614 | 923 | $0.000796 | 1501 | $0.001410 |
| 2 | 600 | $0.000614 | 899 | $0.000796 | 1499 | $0.001410 |
| 3 | 576 | $0.000614 | 1026 | $0.000796 | 1602 | $0.001410 |
| 4 | 578 | $0.000614 | 980 | $0.000796 | 1558 | $0.001410 |
| 5 | 519 | $0.000614 | 1025 | $0.000796 | 1544 | $0.001410 |

### naturalness-llamar-para-atras

- Original text: `Te llamo para atrás.`
- Expected corrected text: `Te devuelvo la llamada.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Te llamo más tarde.`
  - `Te llamo después.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Te llamo para atrás.` | para atrás -> más tarde | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |
| 2 | `Te llamo para atrás.` | para atrás -> después | `Te llamo después.` | correct_fix | Pass | Matches expected output. |
| 3 | `Te llamo de vuelta.` | de vuelta -> más tarde | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |
| 4 | `Te llamo para atrás.` | para atrás -> después | `Te llamo después.` | correct_fix | Pass | Matches expected output. |
| 5 | `Te llamo para atrás.` | para atrás -> más tarde | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 626 | $0.000604 | 1693 | $0.001565 | 2319 | $0.002169 |
| 2 | 688 | $0.000604 | 1630 | $0.001705 | 2318 | $0.002309 |
| 3 | 679 | $0.000604 | 2356 | $0.001605 | 3035 | $0.002209 |
| 4 | 675 | $0.000604 | 1745 | $0.001485 | 2420 | $0.002089 |
| 5 | 679 | $0.000604 | 1845 | $0.001755 | 2524 | $0.002359 |

## Valid Regional / Should Not Flag

### regional-voy-para-casa

- Original text: `Voy para casa ahora mismo.`
- Expected corrected text: `Voy para casa ahora mismo.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Voy a casa ahora mismo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 676 | $0.000612 | 2050 | $0.001586 | 2726 | $0.002198 |
| 2 | 578 | $0.000612 | 1741 | $0.001576 | 2319 | $0.002188 |
| 3 | 782 | $0.000612 | 3688 | $0.001556 | 4470 | $0.002168 |
| 4 | 614 | $0.000612 | 1858 | $0.001666 | 2472 | $0.002278 |
| 5 | 522 | $0.000612 | 1847 | $0.001576 | 2369 | $0.002188 |

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
| 1 | 781 | $0.000594 | 1025 | $0.000794 | 1806 | $0.001388 |
| 2 | 578 | $0.000594 | 1025 | $0.000794 | 1603 | $0.001388 |
| 3 | 578 | $0.000594 | 989 | $0.000794 | 1567 | $0.001388 |
| 4 | 496 | $0.000594 | 1037 | $0.000794 | 1533 | $0.001388 |
| 5 | 628 | $0.000594 | 1077 | $0.000794 | 1705 | $0.001388 |

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
| 1 | 575 | $0.000624 | 1129 | $0.000798 | 1704 | $0.001422 |
| 2 | 576 | $0.000624 | 946 | $0.000798 | 1522 | $0.001422 |
| 3 | 515 | $0.000624 | 1163 | $0.000798 | 1678 | $0.001422 |
| 4 | 568 | $0.000624 | 931 | $0.000798 | 1499 | $0.001422 |
| 5 | 579 | $0.000624 | 1125 | $0.000798 | 1704 | $0.001422 |

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
| 1 | 679 | $0.000624 | 1027 | $0.000798 | 1706 | $0.001422 |
| 2 | 453 | $0.000624 | 1456 | $0.000798 | 1909 | $0.001422 |
| 3 | 575 | $0.000624 | 923 | $0.000798 | 1498 | $0.001422 |
| 4 | 577 | $0.000624 | 1024 | $0.000798 | 1601 | $0.001422 |
| 5 | 810 | $0.000624 | 998 | $0.000798 | 1808 | $0.001422 |

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
| 1 | 475 | $0.000624 | 1025 | $0.000798 | 1500 | $0.001422 |
| 2 | 986 | $0.000624 | 1022 | $0.000798 | 2008 | $0.001422 |
| 3 | 580 | $0.000624 | 1024 | $0.000798 | 1604 | $0.001422 |
| 4 | 577 | $0.000624 | 958 | $0.000798 | 1535 | $0.001422 |
| 5 | 545 | $0.000624 | 950 | $0.000798 | 1495 | $0.001422 |

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
| 1 | 750 | $0.000614 | 922 | $0.000796 | 1672 | $0.001410 |
| 2 | 807 | $0.000614 | 1000 | $0.000796 | 1807 | $0.001410 |
| 3 | 585 | $0.000614 | 913 | $0.000796 | 1498 | $0.001410 |
| 4 | 523 | $0.000614 | 993 | $0.000796 | 1516 | $0.001410 |
| 5 | 661 | $0.000614 | 922 | $0.000796 | 1583 | $0.001410 |

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
| 1 | 580 | $0.000624 | 932 | $0.000798 | 1512 | $0.001422 |
| 2 | 564 | $0.000624 | 922 | $0.000798 | 1486 | $0.001422 |
| 3 | 576 | $0.000624 | 1023 | $0.000798 | 1599 | $0.001422 |
| 4 | 610 | $0.000624 | 1097 | $0.000798 | 1707 | $0.001422 |
| 5 | 550 | $0.000624 | 1049 | $0.000798 | 1599 | $0.001422 |

### correct-tomar-foto

- Original text: `Necesito tomar una foto del documento.`
- Expected corrected text: `Necesito tomar una foto del documento.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Necesito sacar una foto del documento.`
  - `Necesito tomar una foto del documento.`
  - `Necesito hacer una foto del documento.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito tomar una foto del documento.` | tomar una foto -> sacar una foto | `Necesito sacar una foto del documento.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Necesito tomar una foto del documento.` | tomar una foto -> hacer una foto | `Necesito hacer una foto del documento.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 681 | $0.000624 | 2251 | $0.001698 | 2932 | $0.002322 |
| 2 | 578 | $0.000624 | 922 | $0.000798 | 1500 | $0.001422 |
| 3 | 519 | $0.000624 | 981 | $0.000798 | 1500 | $0.001422 |
| 4 | 477 | $0.000624 | 1637 | $0.000798 | 2114 | $0.001422 |
| 5 | 579 | $0.000624 | 2150 | $0.001698 | 2729 | $0.002322 |

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
| 1 | 1190 | $0.000644 | 962 | $0.000800 | 2152 | $0.001444 |
| 2 | 539 | $0.000644 | 921 | $0.000800 | 1460 | $0.001444 |
| 3 | 581 | $0.000644 | 818 | $0.000800 | 1399 | $0.001444 |
| 4 | 473 | $0.000644 | 1001 | $0.000800 | 1474 | $0.001444 |
| 5 | 807 | $0.000644 | 1023 | $0.000800 | 1830 | $0.001444 |

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
| 1 | 682 | $0.000674 | 924 | $0.000804 | 1606 | $0.001478 |
| 2 | 576 | $0.000674 | 1023 | $0.000804 | 1599 | $0.001478 |
| 3 | 783 | $0.000674 | 1024 | $0.000804 | 1807 | $0.001478 |
| 4 | 679 | $0.000674 | 901 | $0.000804 | 1580 | $0.001478 |
| 5 | 601 | $0.000674 | 920 | $0.000804 | 1521 | $0.001478 |

## Mixed Operations

### mixed-preposition-and-redundant-pronoun

- Original text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- Pass rate: 1/5
- Distinct final outputs:
  - `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.`
  - `Insisto en que revises el contrato, trabajo mucho y estudio por las noches.`
  - `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.`
  - `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | insisto en que revises el contrato -> insisto en que revises el contrato<br>y yo trabajo mucho y yo estudio por las noches -> yo trabajo mucho y estudio por las noches | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | y yo trabajo mucho y yo estudio por las noches -> trabajo mucho y estudio por las noches | `Insisto en que revises el contrato, trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | yo trabajo mucho y yo estudio por las noches -> yo trabajo mucho y estudio por las noches | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 992 | $0.000742 | 2249 | $0.002243 | 3241 | $0.002985 |
| 2 | 576 | $0.000742 | 1947 | $0.001512 | 2523 | $0.002254 |
| 3 | 677 | $0.000734 | 2357 | $0.002001 | 3034 | $0.002735 |
| 4 | 576 | $0.000742 | 1841 | $0.001873 | 2417 | $0.002615 |
| 5 | 688 | $0.000742 | 1543 | $0.001443 | 2231 | $0.002185 |

### mixed-article-and-accent

- Original text: `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.`
- Expected corrected text: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
  - `Necesito comprar un libro para la clase, y compré un café en una cafetería pequeña.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 2 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 3 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Necesito comprar un libro para la clase, y compré café -> Necesito comprar un libro para la clase, y compré un café | `Necesito comprar un libro para la clase, y compré un café en una cafetería pequeña.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 5 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 666 | $0.000728 | 923 | $0.000811 | 1589 | $0.001539 |
| 2 | 679 | $0.000728 | 945 | $0.000811 | 1624 | $0.001539 |
| 3 | 658 | $0.000728 | 1843 | $0.001651 | 2501 | $0.002379 |
| 4 | 709 | $0.000728 | 892 | $0.000811 | 1601 | $0.001539 |
| 5 | 577 | $0.000728 | 924 | $0.000811 | 1501 | $0.001539 |

### mixed-personal-a-and-subjunctive

- Original text: `Vi mi profesor en la estación, y recordé que es importante que estudio.`
- Expected corrected text: `Vi a mi profesor en la estación, y recordé que es importante que estudie.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Vi a mi profesor en la estación, y recordé que es importante estudiar.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | recordé que es importante que estudie -> recordé que es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | recordé que es importante que estudie -> recordé que es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | es importante que estudie -> es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | es importante que estudie -> es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | es importante que estudie -> es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000720 | 2106 | $0.001790 | 2683 | $0.002510 |
| 2 | 621 | $0.000720 | 2048 | $0.001660 | 2669 | $0.002380 |
| 3 | 697 | $0.000720 | 1825 | $0.001750 | 2522 | $0.002470 |
| 4 | 1826 | $0.000720 | 2028 | $0.001690 | 3854 | $0.002410 |
| 5 | 679 | $0.000720 | 1652 | $0.001710 | 2331 | $0.002430 |

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
| 1 | 664 | $0.000678 | 1024 | $0.000804 | 1688 | $0.001482 |
| 2 | 577 | $0.000678 | 1230 | $0.000804 | 1807 | $0.001482 |
| 3 | 680 | $0.000678 | 921 | $0.000804 | 1601 | $0.001482 |
| 4 | 679 | $0.000678 | 1165 | $0.000804 | 1844 | $0.001482 |
| 5 | 539 | $0.000678 | 922 | $0.000804 | 1461 | $0.001482 |

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
| 1 | 577 | $0.000722 | 1698 | $0.001780 | 2275 | $0.002502 |
| 2 | 534 | $0.000722 | 1929 | $0.001730 | 2463 | $0.002452 |
| 3 | 956 | $0.000722 | 1679 | $0.001530 | 2635 | $0.002252 |
| 4 | 985 | $0.000722 | 2147 | $0.001570 | 3132 | $0.002292 |
| 5 | 810 | $0.000722 | 1809 | $0.001740 | 2619 | $0.002462 |

---

## Overall summary

| Metric | Value |
| --- | --- |
| Fixtures | 85 |
| Total runs | 425 |
| Pass rate | 382/425 |

### Score breakdown (issue #129 — full taxonomy, not only pass/fail)

| | Total | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| All runs | 425 | 321 | 9 | 2 | 9 | 61 | 23 | 0 |

### Latency / cost by pass (issue #130 — no fallback phase exists in this harness, so totals equal Pass 1 + Pass 2 only)

| Phase | Total latency (ms) | Total est. cost (USD) |
| --- | --- | --- |
| Pass 1 (first pass) | 274368 | $0.266168 |
| Pass 2 (lexical review) | 535676 | $0.411369 |
| **Total (Pass 1 + Pass 2)** | 810044 | $0.677537 |
