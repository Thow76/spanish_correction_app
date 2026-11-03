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
- Generated: 2026-08-08T17:54:24.423404Z

## Fixture summary

Pass rate is `passed/runs`; "distinct outputs" lists every unique final output produced across a fixture's runs — more than one entry means the model was not stable for that fixture.

| Fixture | Language point | Runs | Pass rate | Distinct final outputs | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| clean-grammar-only | Accents / Diacritics | 5 | 0/5 | `Había mucho tráfico ayer.` | 15354 | $0.010469 |
| naturalness-only | Collocations / Strong Calques | 5 | 5/5 | `Voy a tomar una decisión importante.` | 10367 | $0.006921 |
| grammar-and-naturalness-independent | Accents / Diacritics + Collocations / Strong Calques (independent spans) | 5 | 5/5 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | 7391 | $0.007371 |
| grammar-overlaps-naturalness | Verb Morphology (spelling) overlapping Collocations / Strong Calques | 5 | 5/5 | `Ayer tomó una decisión importante.` | 14455 | $0.010271 |
| ambiguous-naturalness-span | Ambiguous / Repeated Span Safety (Naturalness) | 5 | 3/5 | `Vi mucho tráfico, y luego vi más tráfico.`; `Vi mucho tráfico y luego vi más tráfico.`; `Vi mucho tráfico y luego todavía más tráfico.` | 8932 | $0.008691 |
| accent-manana | Accents / Diacritics | 5 | 5/5 | `Voy al parque mañana por la tarde.` | 6989 | $0.006978 |
| accent-medico | Accents / Diacritics | 5 | 5/5 | `El médico llegó después de la reunión.` | 9872 | $0.006987 |
| accent-espana-pais | Accents / Diacritics | 5 | 5/5 | `España es un país muy diverso.` | 7403 | $0.006931 |
| accent-cumpleanos-otono | Accents / Diacritics | 5 | 5/5 | `Mi cumpleaños es en otoño.` | 8172 | $0.006885 |
| accent-cafe-cafeteria | Accents / Diacritics | 5 | 5/5 | `Compré café en una cafetería pequeña.` | 6981 | $0.007024 |
| agreement-ninos-manzanas | Gender / Number Agreement | 5 | 5/5 | `Los niños comen muchas manzanas.` | 8115 | $0.006967 |
| agreement-ventanas-abiertas | Gender / Number Agreement | 5 | 5/5 | `Las ventanas estaban abiertas.` | 7185 | $0.006809 |
| agreement-puerta-cerrada | Gender / Number Agreement | 5 | 5/5 | `Una puerta estaba cerrada.` | 7287 | $0.006855 |
| agreement-billetes-caros | Gender / Number Agreement | 5 | 5/5 | `Los billetes estaban caros.` | 8319 | $0.006865 |
| agreement-fechas-escritas | Gender / Number Agreement | 5 | 5/5 | `Las fechas estaban escritas sin tilde.` | 7287 | $0.007024 |
| verb-nosotros-fuimos | Verb Agreement / Morphology | 5 | 5/5 | `Mis compañeros y yo fuimos a la biblioteca.` | 7390 | $0.007080 |
| verb-ninos-comen | Verb Agreement / Morphology | 5 | 5/5 | `Los niños comen en el jardín.` | 7544 | $0.006921 |
| verb-compre-pan | Verb Agreement / Morphology | 5 | 5/5 | `Yo fui al mercado y compré pan.` | 7756 | $0.007024 |
| verb-ellos-estudian | Verb Agreement / Morphology | 5 | 5/5 | `Ellos estudian todas las noches.` | 6982 | $0.006978 |
| verb-nosotros-vivimos | Verb Agreement / Morphology | 5 | 5/5 | `Nosotros vivimos cerca del centro.` | 7396 | $0.006921 |
| prep-insisto-en | Required Prepositions | 5 | 5/5 | `Insisto en que revises el contrato.` | 9852 | $0.007024 |
| prep-empresa-en-la-que | Required Prepositions | 5 | 2/5 | `La empresa donde trabajo está cerca.`; `La empresa en la que trabajo queda cerca.`; `La empresa en la que trabajo está cerca.` | 10256 | $0.010317 |
| prep-dependo-de | Required Prepositions | 5 | 5/5 | `Dependo de que me ayudes mañana.` | 8186 | $0.007024 |
| prep-pienso-en-ti | Required Prepositions | 5 | 5/5 | `Pienso en ti todos los días.` | 7723 | $0.006967 |
| prep-sone-con | Required Prepositions | 5 | 5/5 | `Soñé con mi antiguo colegio.` | 7085 | $0.006967 |
| article-puerta-principal | Articles / Determiners | 5 | 5/5 | `Abrió la puerta principal.` | 7391 | $0.006855 |
| article-un-libro | Articles / Determiners | 5 | 5/5 | `Necesito comprar un libro para la clase.` | 7292 | $0.007024 |
| article-el-profesor-la-regla | Articles / Determiners | 5 | 5/5 | `El profesor explicó la regla otra vez.` | 7239 | $0.006958 |
| article-la-tienda | Articles / Determiners | 5 | 5/5 | `Fui a la tienda después del trabajo.` | 7749 | $0.007024 |
| article-cita-medico | Articles / Determiners | 5 | 5/5 | `Tengo una cita con el médico mañana.` | 10360 | $0.006958 |
| subj-estudies | Subjunctive / Mood | 5 | 5/5 | `Es importante que estudies.` | 7597 | $0.006865 |
| subj-tenga-razon | Subjunctive / Mood | 5 | 5/5 | `No creo que tenga razón.` | 7491 | $0.006865 |
| subj-vengas | Subjunctive / Mood | 5 | 5/5 | `Quiero que vengas conmigo.` | 9031 | $0.006921 |
| subj-enviara | Subjunctive / Mood | 5 | 1/5 | `Era necesario que enviara su aportación.`; `Era necesario que enviara su parte.`; `Era necesario que enviara su informe.` | 11181 | $0.010157 |
| subj-hable-frances | Subjunctive / Mood | 5 | 5/5 | `Busco a alguien que hable francés.` | 7077 | $0.007024 |
| missing-que-creo | Required Additions / Omissions | 5 | 5/5 | `Creo que está bien terminar hoy.` | 7398 | $0.006911 |
| missing-les-ninos | Required Additions / Omissions | 5 | 5/5 | `A los niños les expliqué la regla.` | 7389 | $0.006967 |
| missing-personal-a-profesor | Required Additions / Omissions | 5 | 5/5 | `Vi a mi profesor en la estación.` | 7285 | $0.006967 |
| missing-se-levanto | Required Additions / Omissions | 5 | 5/5 | `Se levantó temprano ayer.` | 7286 | $0.006865 |
| missing-le-gusta | Required Additions / Omissions | 5 | 5/5 | `A Juan le gusta el café.` | 7873 | $0.006911 |
| delete-repeated-yo-estudio | Unnecessary Extras / Deletions | 5 | 0/5 | `Yo trabajo mucho y yo estudio por la noche.` | 11900 | $0.010390 |
| delete-repeated-ellos-visitaron | Unnecessary Extras / Deletions | 5 | 5/5 | `Ellos viajaron a México y visitaron varias ciudades.` | 8308 | $0.007892 |
| delete-repeated-a-mi | Unnecessary Extras / Deletions | 5 | 5/5 | `A mí me gusta el café.` | 7499 | $0.006941 |
| delete-repeated-yo-compre | Unnecessary Extras / Deletions | 5 | 5/5 | `Yo fui al mercado y compré pan.` | 10329 | $0.010200 |
| delete-repeated-nosotros | Unnecessary Extras / Deletions | 5 | 5/5 | `Salimos temprano y llegamos a tiempo.`; `Nosotros salimos temprano y llegamos a tiempo.` | 10390 | $0.010933 |
| ser-profesor | Ser / Estar / Haber | 5 | 5/5 | `Mi hermano es profesor.` | 7734 | $0.006809 |
| haber-veinte-personas | Ser / Estar / Haber | 5 | 5/5 | `En la sala hay veinte personas.` | 7765 | $0.006921 |
| ser-capital-madrid | Ser / Estar / Haber | 5 | 5/5 | `Madrid es la capital de España.` | 8318 | $0.006921 |
| estar-contento | Ser / Estar / Haber | 5 | 5/5 | `Estoy muy contento con el resultado.` | 7601 | $0.006978 |
| ser-reunion-segunda-planta | Ser / Estar / Haber | 5 | 5/5 | `La reunión es en la segunda planta.` | 7091 | $0.006978 |
| haber-habia-personas | Impersonal Haber / Se | 5 | 5/5 | `Había muchas personas en la entrada.` | 7537 | $0.006978 |
| haber-hubo-problemas | Impersonal Haber / Se | 5 | 5/5 | `Hubo varios problemas durante la reunión.` | 7451 | $0.006978 |
| se-venden-pisos | Impersonal Haber / Se | 5 | 5/5 | `Se venden pisos en el centro.` | 7596 | $0.006921 |
| se-necesitan-voluntarios | Impersonal Haber / Se | 5 | 5/5 | `Se necesitan voluntarios para el evento.` | 8008 | $0.006978 |
| haber-habia-cifras | Impersonal Haber / Se | 5 | 5/5 | `Había varias cifras incorrectas.` | 7597 | $0.006921 |
| collocation-hacer-decision | Collocations / Strong Calques | 5 | 5/5 | `Necesito tomar una decisión.` | 7698 | $0.006865 |
| collocation-hacer-atencion | Collocations / Strong Calques | 5 | 5/5 | `Tenemos que prestar atención.` | 7462 | $0.006809 |
| collocation-tomar-reunion | Collocations / Strong Calques | 5 | 5/5 | `El equipo tuvo una reunión.` | 8046 | $0.006865 |
| collocation-hacer-paseo | Collocations / Strong Calques | 5 | 5/5 | `Ella dio un paseo.` | 11182 | $0.009799 |
| collocation-hace-sentido | Collocations / Strong Calques | 5 | 5/5 | `Esto tiene sentido.` | 7801 | $0.006753 |
| false-friend-atendio-universidad | False Friends / Word Choice | 5 | 5/5 | `Asistió a la universidad en Madrid.` | 10851 | $0.007024 |
| false-friend-aplico-trabajo | False Friends / Word Choice | 5 | 4/5 | `Solicitó un trabajo.`; `Se postuló para un trabajo.` | 11818 | $0.011095 |
| false-friend-realice | False Friends / Word Choice | 5 | 5/5 | `Me di cuenta de que estaba equivocado.` | 8821 | $0.007024 |
| false-friend-embarazado | False Friends / Word Choice | 5 | 4/5 | `Estoy avergonzado por llegar tarde.`; `Estoy avergonzado de haber llegado tarde.` | 8528 | $0.007764 |
| false-friend-actualmente-control | False Friends / Word Choice | 5 | 5/5 | `Actualmente vivo en Londres.` | 7187 | $0.006809 |
| naturalness-buen-tiempo | Phrase-Level Naturalness | 5 | 5/5 | `Tuvimos un buen rato.` | 10976 | $0.010601 |
| naturalness-corriendo-tarde | Phrase-Level Naturalness | 5 | 5/5 | `Voy a llegar tarde a la reunión.`; `Estoy llegando tarde a la reunión.` | 11592 | $0.010591 |
| naturalness-pasar-buen-tiempo | Phrase-Level Naturalness | 5 | 5/5 | `Quiero pasar un buen rato.` | 7394 | $0.006921 |
| naturalness-puedo-tener-cerveza | Phrase-Level Naturalness | 5 | 5/5 | `¿Puedo tomar una cerveza?` | 7498 | $0.006921 |
| naturalness-llamar-para-atras | Phrase-Level Naturalness | 5 | 4/5 | `Te llamo luego.`; `Te llamo más tarde.`; `Te llamo después.` | 8417 | $0.008757 |
| regional-voy-para-casa | Valid Regional / Should Not Flag | 5 | 0/5 | `Voy a casa ahora mismo.` | 14660 | $0.011001 |
| regional-vos-tenes | Valid Regional / Should Not Flag | 5 | 5/5 | `Vos tenés razón.` | 7700 | $0.006809 |
| regional-cojo-autobus | Valid Regional / Should Not Flag | 5 | 5/5 | `Cojo el autobús cada mañana.` | 7088 | $0.006978 |
| regional-preterite-esta-manana | Valid Regional / Should Not Flag | 5 | 5/5 | `Esta mañana hablé con mi jefe.` | 6831 | $0.006978 |
| regional-dale | Valid Regional / Should Not Flag | 5 | 5/5 | `Dale, nos vemos más tarde.` | 8364 | $0.006978 |
| correct-buenos-dias | Already Correct / Do Not Tinker | 5 | 5/5 | `Buenos días, ¿cómo estás?` | 7700 | $0.006921 |
| correct-hacer-pregunta | Already Correct / Do Not Tinker | 5 | 5/5 | `Voy a hacer una pregunta al profesor.` | 7291 | $0.006978 |
| correct-tomar-foto | Already Correct / Do Not Tinker | 5 | 2/5 | `Necesito sacar una foto del documento.`; `Necesito tomar una foto del documento.` | 10564 | $0.009567 |
| correct-visitar-abuela | Already Correct / Do Not Tinker | 5 | 5/5 | `Mañana visitaré a mi abuela.` | 7153 | $0.007090 |
| correct-me-quedo-en-casa | Already Correct / Do Not Tinker | 5 | 5/5 | `Está lloviendo, así que me quedo en casa.` | 8763 | $0.007259 |
| mixed-preposition-and-redundant-pronoun | Mixed Operations | 5 | 0/5 | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.`; `Insisto en que revises el contrato, porque yo trabajo mucho y estudio por las noches.` | 16057 | $0.013906 |
| mixed-article-and-accent | Mixed Operations | 5 | 4/5 | `Necesito comprar un libro para la clase, y también compré café en una cafetería pequeña.`; `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | 8145 | $0.008416 |
| mixed-personal-a-and-subjunctive | Mixed Operations | 5 | 0/5 | `Vi a mi profesor en la estación, y recordé que es importante estudiar.`; `Vi a mi profesor en la estación, y recordé que es importante que estudiar.` | 10874 | $0.011350 |
| mixed-gender-agreement-and-redundant-pronoun | Mixed Operations | 5 | 5/5 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | 7418 | $0.007279 |
| mixed-verb-agreement-and-missing-que | Mixed Operations | 5 | 0/5 | `Ellos estudian todas las noches, y creo que está bien dejar de estudiar hoy.` | 11355 | $0.011510 |

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
| 1 | 680 | $0.000570 | 1490 | $0.001534 | 2170 | $0.002104 |
| 2 | 707 | $0.000570 | 5277 | $0.001534 | 5984 | $0.002104 |
| 3 | 554 | $0.000570 | 1400 | $0.001434 | 1954 | $0.002004 |
| 4 | 739 | $0.000570 | 2192 | $0.001534 | 2931 | $0.002104 |
| 5 | 782 | $0.000570 | 1533 | $0.001584 | 2315 | $0.002154 |

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
| 1 | 678 | $0.000598 | 1023 | $0.000798 | 1701 | $0.001396 |
| 2 | 509 | $0.000598 | 683 | $0.000798 | 1192 | $0.001396 |
| 3 | 576 | $0.000598 | 720 | $0.000798 | 1296 | $0.001396 |
| 4 | 679 | $0.000598 | 818 | $0.000798 | 1497 | $0.001396 |
| 5 | 567 | $0.000598 | 736 | $0.000798 | 1303 | $0.001396 |

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
| 1 | 665 | $0.000600 | 3690 | $0.000798 | 4355 | $0.001397 |
| 2 | 518 | $0.000600 | 879 | $0.000798 | 1397 | $0.001397 |
| 3 | 504 | $0.000600 | 983 | $0.000798 | 1487 | $0.001397 |
| 4 | 590 | $0.000600 | 716 | $0.000798 | 1306 | $0.001397 |
| 5 | 603 | $0.000600 | 724 | $0.000798 | 1327 | $0.001397 |

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
| 1 | 761 | $0.000590 | 808 | $0.000796 | 1569 | $0.001386 |
| 2 | 681 | $0.000590 | 773 | $0.000796 | 1454 | $0.001386 |
| 3 | 523 | $0.000590 | 817 | $0.000796 | 1340 | $0.001386 |
| 4 | 580 | $0.000590 | 716 | $0.000796 | 1296 | $0.001386 |
| 5 | 677 | $0.000590 | 1067 | $0.000796 | 1744 | $0.001386 |

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
| 1 | 2073 | $0.000582 | 763 | $0.000795 | 2836 | $0.001377 |
| 2 | 632 | $0.000582 | 820 | $0.000795 | 1452 | $0.001377 |
| 3 | 496 | $0.000582 | 697 | $0.000795 | 1193 | $0.001377 |
| 4 | 576 | $0.000582 | 784 | $0.000795 | 1360 | $0.001377 |
| 5 | 509 | $0.000582 | 822 | $0.000795 | 1331 | $0.001377 |

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
| 1 | 576 | $0.000606 | 819 | $0.000799 | 1395 | $0.001405 |
| 2 | 489 | $0.000606 | 804 | $0.000799 | 1293 | $0.001405 |
| 3 | 579 | $0.000606 | 921 | $0.000799 | 1500 | $0.001405 |
| 4 | 585 | $0.000606 | 709 | $0.000799 | 1294 | $0.001405 |
| 5 | 576 | $0.000606 | 923 | $0.000799 | 1499 | $0.001405 |

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
| 1 | 700 | $0.000588 | 753 | $0.000796 | 1453 | $0.001384 |
| 2 | 831 | $0.000588 | 817 | $0.000796 | 1648 | $0.001384 |
| 3 | 884 | $0.000588 | 818 | $0.000796 | 1702 | $0.001384 |
| 4 | 3385 | $0.000588 | 779 | $0.000796 | 4164 | $0.001384 |
| 5 | 593 | $0.000588 | 807 | $0.000796 | 1400 | $0.001384 |

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
| 1 | 576 | $0.000578 | 719 | $0.000795 | 1295 | $0.001373 |
| 2 | 577 | $0.000578 | 921 | $0.000795 | 1498 | $0.001373 |
| 3 | 1231 | $0.000578 | 679 | $0.000795 | 1910 | $0.001373 |
| 4 | 578 | $0.000578 | 715 | $0.000795 | 1293 | $0.001373 |
| 5 | 682 | $0.000578 | 1020 | $0.000795 | 1702 | $0.001373 |

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
| 1 | 684 | $0.000568 | 743 | $0.000794 | 1427 | $0.001362 |
| 2 | 550 | $0.000568 | 716 | $0.000794 | 1266 | $0.001362 |
| 3 | 885 | $0.000568 | 717 | $0.000794 | 1602 | $0.001362 |
| 4 | 680 | $0.000568 | 715 | $0.000794 | 1395 | $0.001362 |
| 5 | 1092 | $0.000568 | 680 | $0.000794 | 1772 | $0.001362 |

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
| 1 | 643 | $0.000578 | 997 | $0.000795 | 1640 | $0.001373 |
| 2 | 578 | $0.000578 | 818 | $0.000795 | 1396 | $0.001373 |
| 3 | 476 | $0.000578 | 821 | $0.000795 | 1297 | $0.001373 |
| 4 | 575 | $0.000578 | 889 | $0.000795 | 1464 | $0.001373 |
| 5 | 1328 | $0.000578 | 921 | $0.000795 | 2249 | $0.001373 |

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
| 5 | `Ella hizo un paseo.` | hizo un paseo -> dio un paseo | `Ella dio un paseo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 578 | $0.000568 | 1266 | $0.001404 | 1844 | $0.001972 |
| 2 | 676 | $0.000568 | 1812 | $0.001354 | 2488 | $0.001922 |
| 3 | 779 | $0.000568 | 1699 | $0.001454 | 2478 | $0.002022 |
| 4 | 518 | $0.000568 | 1330 | $0.001384 | 1848 | $0.001952 |
| 5 | 886 | $0.000568 | 1638 | $0.001364 | 2524 | $0.001932 |

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
| 1 | 535 | $0.000558 | 679 | $0.000793 | 1214 | $0.001351 |
| 2 | 558 | $0.000558 | 1227 | $0.000793 | 1785 | $0.001351 |
| 3 | 782 | $0.000558 | 821 | $0.000793 | 1603 | $0.001351 |
| 4 | 678 | $0.000558 | 921 | $0.000793 | 1599 | $0.001351 |
| 5 | 575 | $0.000558 | 1025 | $0.000793 | 1600 | $0.001351 |

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
| 1 | 884 | $0.000668 | 700 | $0.000806 | 1584 | $0.001474 |
| 2 | 695 | $0.000668 | 685 | $0.000806 | 1380 | $0.001474 |
| 3 | 610 | $0.000668 | 878 | $0.000806 | 1488 | $0.001474 |
| 4 | 660 | $0.000668 | 778 | $0.000806 | 1438 | $0.001474 |
| 5 | 611 | $0.000668 | 890 | $0.000806 | 1501 | $0.001474 |

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
| 1 | 780 | $0.000588 | 1818 | $0.001406 | 2598 | $0.001994 |
| 2 | 4107 | $0.000588 | 1516 | $0.001526 | 5623 | $0.002114 |
| 3 | 680 | $0.000588 | 1485 | $0.001566 | 2165 | $0.002154 |
| 4 | 609 | $0.000588 | 1279 | $0.001366 | 1888 | $0.001954 |
| 5 | 648 | $0.000588 | 1533 | $0.001466 | 2181 | $0.002054 |

## Ambiguous / Repeated Span Safety (Naturalness)

### ambiguous-naturalness-span

- Original text: `Vi mucho tráfico, y luego vi más tráfico.`
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Vi mucho tráfico, y luego vi más tráfico.`
  - `Vi mucho tráfico y luego vi más tráfico.`
  - `Vi mucho tráfico y luego todavía más tráfico.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico, y luego vi más tráfico.` | vi mucho tráfico, y luego vi más tráfico -> había mucho tráfico, y luego había aún más tráfico | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Vi mucho tráfico y luego vi más tráfico.` | (none) | `Vi mucho tráfico y luego vi más tráfico.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Vi mucho tráfico y luego vi más tráfico.` | vi más tráfico -> todavía más tráfico | `Vi mucho tráfico y luego todavía más tráfico.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 589 | $0.000618 | 1937 | $0.001830 | 2526 | $0.002448 |
| 2 | 678 | $0.000610 | 718 | $0.000799 | 1396 | $0.001409 |
| 3 | 681 | $0.000610 | 1401 | $0.001389 | 2082 | $0.001999 |
| 4 | 607 | $0.000618 | 820 | $0.000800 | 1427 | $0.001418 |
| 5 | 782 | $0.000618 | 719 | $0.000800 | 1501 | $0.001418 |

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
| 1 | 1065 | $0.000596 | 728 | $0.000798 | 1793 | $0.001393 |
| 2 | 695 | $0.000596 | 968 | $0.000798 | 1663 | $0.001393 |
| 3 | 836 | $0.000596 | 818 | $0.000798 | 1654 | $0.001393 |
| 4 | 540 | $0.000596 | 859 | $0.000798 | 1399 | $0.001393 |
| 5 | 781 | $0.000596 | 825 | $0.000798 | 1606 | $0.001393 |

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
| 1 | 572 | $0.000568 | 800 | $0.000794 | 1372 | $0.001362 |
| 2 | 657 | $0.000568 | 760 | $0.000794 | 1417 | $0.001362 |
| 3 | 679 | $0.000568 | 819 | $0.000794 | 1498 | $0.001362 |
| 4 | 579 | $0.000568 | 923 | $0.000794 | 1502 | $0.001362 |
| 5 | 510 | $0.000568 | 886 | $0.000794 | 1396 | $0.001362 |

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
| 1 | 579 | $0.000576 | 726 | $0.000795 | 1305 | $0.001371 |
| 2 | 879 | $0.000576 | 1019 | $0.000795 | 1898 | $0.001371 |
| 3 | 560 | $0.000576 | 834 | $0.000795 | 1394 | $0.001371 |
| 4 | 557 | $0.000576 | 692 | $0.000795 | 1249 | $0.001371 |
| 5 | 623 | $0.000576 | 818 | $0.000795 | 1441 | $0.001371 |

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
| 1 | 581 | $0.000578 | 1228 | $0.000795 | 1809 | $0.001373 |
| 2 | 566 | $0.000578 | 817 | $0.000795 | 1383 | $0.001373 |
| 3 | 704 | $0.000578 | 809 | $0.000795 | 1513 | $0.001373 |
| 4 | 575 | $0.000578 | 719 | $0.000795 | 1294 | $0.001373 |
| 5 | 1426 | $0.000578 | 894 | $0.000795 | 2320 | $0.001373 |

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
| 1 | 576 | $0.000606 | 972 | $0.000799 | 1548 | $0.001405 |
| 2 | 528 | $0.000606 | 816 | $0.000799 | 1344 | $0.001405 |
| 3 | 778 | $0.000606 | 827 | $0.000799 | 1605 | $0.001405 |
| 4 | 610 | $0.000606 | 808 | $0.000799 | 1418 | $0.001405 |
| 5 | 528 | $0.000606 | 844 | $0.000799 | 1372 | $0.001405 |

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
| 1 | 682 | $0.000616 | 717 | $0.000800 | 1399 | $0.001416 |
| 2 | 578 | $0.000616 | 714 | $0.000800 | 1292 | $0.001416 |
| 3 | 641 | $0.000616 | 1063 | $0.000800 | 1704 | $0.001416 |
| 4 | 621 | $0.000616 | 857 | $0.000800 | 1478 | $0.001416 |
| 5 | 803 | $0.000616 | 714 | $0.000800 | 1517 | $0.001416 |

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
| 1 | 668 | $0.000588 | 849 | $0.000796 | 1517 | $0.001384 |
| 2 | 869 | $0.000588 | 786 | $0.000796 | 1655 | $0.001384 |
| 3 | 608 | $0.000588 | 720 | $0.000796 | 1328 | $0.001384 |
| 4 | 682 | $0.000588 | 783 | $0.000796 | 1465 | $0.001384 |
| 5 | 511 | $0.000588 | 1068 | $0.000796 | 1579 | $0.001384 |

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
| 1 | 692 | $0.000606 | 901 | $0.000799 | 1593 | $0.001405 |
| 2 | 743 | $0.000606 | 823 | $0.000799 | 1566 | $0.001405 |
| 3 | 620 | $0.000606 | 879 | $0.000799 | 1499 | $0.001405 |
| 4 | 782 | $0.000606 | 755 | $0.000799 | 1537 | $0.001405 |
| 5 | 741 | $0.000606 | 820 | $0.000799 | 1561 | $0.001405 |

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
| 1 | 598 | $0.000598 | 683 | $0.000798 | 1281 | $0.001396 |
| 2 | 593 | $0.000598 | 728 | $0.000798 | 1321 | $0.001396 |
| 3 | 656 | $0.000598 | 934 | $0.000798 | 1590 | $0.001396 |
| 4 | 620 | $0.000598 | 774 | $0.000798 | 1394 | $0.001396 |
| 5 | 562 | $0.000598 | 834 | $0.000798 | 1396 | $0.001396 |

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
| 1 | 585 | $0.000588 | 811 | $0.000796 | 1396 | $0.001384 |
| 2 | 683 | $0.000588 | 953 | $0.000796 | 1636 | $0.001384 |
| 3 | 648 | $0.000588 | 718 | $0.000796 | 1366 | $0.001384 |
| 4 | 679 | $0.000588 | 679 | $0.000796 | 1358 | $0.001384 |
| 5 | 616 | $0.000588 | 1024 | $0.000796 | 1640 | $0.001384 |

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
| 1 | 629 | $0.000606 | 768 | $0.000799 | 1397 | $0.001405 |
| 2 | 577 | $0.000606 | 819 | $0.000799 | 1396 | $0.001405 |
| 3 | 604 | $0.000606 | 895 | $0.000799 | 1499 | $0.001405 |
| 4 | 3462 | $0.000606 | 800 | $0.000799 | 4262 | $0.001405 |
| 5 | 580 | $0.000606 | 718 | $0.000799 | 1298 | $0.001405 |

### prep-empresa-en-la-que

- Original text: `La empresa que trabajo está cerca.`
- Expected corrected text: `La empresa en la que trabajo está cerca.`
- Pass rate: 2/5
- Distinct final outputs:
  - `La empresa donde trabajo está cerca.`
  - `La empresa en la que trabajo queda cerca.`
  - `La empresa en la que trabajo está cerca.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `La empresa en que trabajo está cerca.` | en que trabajo -> donde trabajo | `La empresa donde trabajo está cerca.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `La empresa en la que trabajo está cerca.` | está cerca -> queda cerca | `La empresa en la que trabajo queda cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `La empresa en que trabajo está cerca.` | en que trabajo -> en la que trabajo | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 4 | `La empresa en que trabajo está cerca.` | en que trabajo -> donde trabajo | `La empresa donde trabajo está cerca.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `La empresa en que trabajo está cerca.` | en que trabajo -> en la que trabajo | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 883 | $0.000596 | 1321 | $0.001468 | 2204 | $0.002064 |
| 2 | 586 | $0.000604 | 1231 | $0.001569 | 1817 | $0.002173 |
| 3 | 574 | $0.000596 | 1529 | $0.001347 | 2103 | $0.001943 |
| 4 | 686 | $0.000596 | 1178 | $0.001347 | 1864 | $0.001943 |
| 5 | 627 | $0.000596 | 1641 | $0.001597 | 2268 | $0.002194 |

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
| 1 | 577 | $0.000606 | 1330 | $0.000799 | 1907 | $0.001405 |
| 2 | 682 | $0.000606 | 817 | $0.000799 | 1499 | $0.001405 |
| 3 | 750 | $0.000606 | 852 | $0.000799 | 1602 | $0.001405 |
| 4 | 575 | $0.000606 | 718 | $0.000799 | 1293 | $0.001405 |
| 5 | 1193 | $0.000606 | 692 | $0.000799 | 1885 | $0.001405 |

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
| 1 | 625 | $0.000596 | 954 | $0.000798 | 1579 | $0.001393 |
| 2 | 930 | $0.000596 | 818 | $0.000798 | 1748 | $0.001393 |
| 3 | 531 | $0.000596 | 765 | $0.000798 | 1296 | $0.001393 |
| 4 | 566 | $0.000596 | 700 | $0.000798 | 1266 | $0.001393 |
| 5 | 909 | $0.000596 | 925 | $0.000798 | 1834 | $0.001393 |

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
| 1 | 578 | $0.000596 | 717 | $0.000798 | 1295 | $0.001393 |
| 2 | 613 | $0.000596 | 883 | $0.000798 | 1496 | $0.001393 |
| 3 | 657 | $0.000596 | 741 | $0.000798 | 1398 | $0.001393 |
| 4 | 781 | $0.000596 | 717 | $0.000798 | 1498 | $0.001393 |
| 5 | 773 | $0.000596 | 625 | $0.000798 | 1398 | $0.001393 |

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
| 1 | 574 | $0.000576 | 1025 | $0.000795 | 1599 | $0.001371 |
| 2 | 677 | $0.000576 | 833 | $0.000795 | 1510 | $0.001371 |
| 3 | 566 | $0.000576 | 660 | $0.000795 | 1226 | $0.001371 |
| 4 | 532 | $0.000576 | 762 | $0.000795 | 1294 | $0.001371 |
| 5 | 739 | $0.000576 | 1023 | $0.000795 | 1762 | $0.001371 |

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
| 1 | 576 | $0.000606 | 922 | $0.000799 | 1498 | $0.001405 |
| 2 | 575 | $0.000606 | 714 | $0.000799 | 1289 | $0.001405 |
| 3 | 888 | $0.000606 | 821 | $0.000799 | 1709 | $0.001405 |
| 4 | 664 | $0.000606 | 680 | $0.000799 | 1344 | $0.001405 |
| 5 | 631 | $0.000606 | 821 | $0.000799 | 1452 | $0.001405 |

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
| 1 | 519 | $0.000594 | 774 | $0.000798 | 1293 | $0.001391 |
| 2 | 604 | $0.000594 | 794 | $0.000798 | 1398 | $0.001391 |
| 3 | 632 | $0.000594 | 872 | $0.000798 | 1504 | $0.001391 |
| 4 | 672 | $0.000594 | 821 | $0.000798 | 1493 | $0.001391 |
| 5 | 781 | $0.000594 | 770 | $0.000798 | 1551 | $0.001391 |

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
| 1 | 831 | $0.000606 | 819 | $0.000799 | 1650 | $0.001405 |
| 2 | 477 | $0.000606 | 1635 | $0.000799 | 2112 | $0.001405 |
| 3 | 682 | $0.000606 | 708 | $0.000799 | 1390 | $0.001405 |
| 4 | 619 | $0.000606 | 875 | $0.000799 | 1494 | $0.001405 |
| 5 | 486 | $0.000606 | 617 | $0.000799 | 1103 | $0.001405 |

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
| 1 | 610 | $0.000594 | 990 | $0.000798 | 1600 | $0.001391 |
| 2 | 576 | $0.000594 | 751 | $0.000798 | 1327 | $0.001391 |
| 3 | 567 | $0.000594 | 797 | $0.000798 | 1364 | $0.001391 |
| 4 | 678 | $0.000594 | 739 | $0.000798 | 1417 | $0.001391 |
| 5 | 3935 | $0.000594 | 717 | $0.000798 | 4652 | $0.001391 |

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
| 1 | 782 | $0.000578 | 1230 | $0.000795 | 2012 | $0.001373 |
| 2 | 576 | $0.000578 | 714 | $0.000795 | 1290 | $0.001373 |
| 3 | 682 | $0.000578 | 720 | $0.000795 | 1402 | $0.001373 |
| 4 | 571 | $0.000578 | 928 | $0.000795 | 1499 | $0.001373 |
| 5 | 586 | $0.000578 | 808 | $0.000795 | 1394 | $0.001373 |

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
| 1 | 729 | $0.000578 | 770 | $0.000795 | 1499 | $0.001373 |
| 2 | 782 | $0.000578 | 1024 | $0.000795 | 1806 | $0.001373 |
| 3 | 678 | $0.000578 | 818 | $0.000795 | 1496 | $0.001373 |
| 4 | 618 | $0.000578 | 702 | $0.000795 | 1320 | $0.001373 |
| 5 | 553 | $0.000578 | 817 | $0.000795 | 1370 | $0.001373 |

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
| 1 | 1397 | $0.000588 | 816 | $0.000796 | 2213 | $0.001384 |
| 2 | 890 | $0.000588 | 717 | $0.000796 | 1607 | $0.001384 |
| 3 | 575 | $0.000588 | 923 | $0.000796 | 1498 | $0.001384 |
| 4 | 576 | $0.000588 | 1435 | $0.000796 | 2011 | $0.001384 |
| 5 | 993 | $0.000588 | 709 | $0.000796 | 1702 | $0.001384 |

### subj-enviara

- Original text: `Era necesario que enviaba su parte.`
- Expected corrected text: `Era necesario que enviara su parte.`
- Pass rate: 1/5
- Distinct final outputs:
  - `Era necesario que enviara su aportación.`
  - `Era necesario que enviara su parte.`
  - `Era necesario que enviara su informe.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Era necesario que enviara su parte.` | su parte -> su aportación | `Era necesario que enviara su aportación.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 3 | `Era necesario que enviara su parte.` | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Era necesario que enviara su parte.` | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Era necesario que enviara su parte.` | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 578 | $0.000598 | 2055 | $0.001628 | 2633 | $0.002226 |
| 2 | 673 | $0.000598 | 820 | $0.000798 | 1493 | $0.001396 |
| 3 | 575 | $0.000598 | 1914 | $0.001628 | 2489 | $0.002226 |
| 4 | 583 | $0.000598 | 1560 | $0.001607 | 2143 | $0.002205 |
| 5 | 681 | $0.000598 | 1742 | $0.001508 | 2423 | $0.002106 |

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
| 1 | 518 | $0.000606 | 778 | $0.000799 | 1296 | $0.001405 |
| 2 | 575 | $0.000606 | 820 | $0.000799 | 1395 | $0.001405 |
| 3 | 505 | $0.000606 | 889 | $0.000799 | 1394 | $0.001405 |
| 4 | 579 | $0.000606 | 820 | $0.000799 | 1399 | $0.001405 |
| 5 | 847 | $0.000606 | 746 | $0.000799 | 1593 | $0.001405 |

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
| 1 | 741 | $0.000586 | 970 | $0.000796 | 1711 | $0.001382 |
| 2 | 637 | $0.000586 | 758 | $0.000796 | 1395 | $0.001382 |
| 3 | 808 | $0.000586 | 745 | $0.000796 | 1553 | $0.001382 |
| 4 | 522 | $0.000586 | 923 | $0.000796 | 1445 | $0.001382 |
| 5 | 577 | $0.000586 | 717 | $0.000796 | 1294 | $0.001382 |

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
| 1 | 677 | $0.000596 | 1004 | $0.000798 | 1681 | $0.001393 |
| 2 | 701 | $0.000596 | 758 | $0.000798 | 1459 | $0.001393 |
| 3 | 637 | $0.000596 | 923 | $0.000798 | 1560 | $0.001393 |
| 4 | 554 | $0.000596 | 843 | $0.000798 | 1397 | $0.001393 |
| 5 | 576 | $0.000596 | 716 | $0.000798 | 1292 | $0.001393 |

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
| 1 | 679 | $0.000596 | 718 | $0.000798 | 1397 | $0.001393 |
| 2 | 884 | $0.000596 | 713 | $0.000798 | 1597 | $0.001393 |
| 3 | 782 | $0.000596 | 626 | $0.000798 | 1408 | $0.001393 |
| 4 | 667 | $0.000596 | 818 | $0.000798 | 1485 | $0.001393 |
| 5 | 681 | $0.000596 | 717 | $0.000798 | 1398 | $0.001393 |

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
| 1 | 780 | $0.000578 | 923 | $0.000795 | 1703 | $0.001373 |
| 2 | 576 | $0.000578 | 718 | $0.000795 | 1294 | $0.001373 |
| 3 | 565 | $0.000578 | 1034 | $0.000795 | 1599 | $0.001373 |
| 4 | 679 | $0.000578 | 715 | $0.000795 | 1394 | $0.001373 |
| 5 | 530 | $0.000578 | 766 | $0.000795 | 1296 | $0.001373 |

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
| 1 | 987 | $0.000586 | 1329 | $0.000796 | 2316 | $0.001382 |
| 2 | 577 | $0.000586 | 1127 | $0.000796 | 1704 | $0.001382 |
| 3 | 482 | $0.000586 | 729 | $0.000796 | 1211 | $0.001382 |
| 4 | 474 | $0.000586 | 868 | $0.000796 | 1342 | $0.001382 |
| 5 | 545 | $0.000586 | 755 | $0.000796 | 1300 | $0.001382 |

## Unnecessary Extras / Deletions

### delete-repeated-yo-estudio

- Original text: `Yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Yo trabajo mucho y yo estudio por la noche.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Yo trabajo mucho y yo estudio por las noches.` | por las noches -> por la noche | `Yo trabajo mucho y yo estudio por la noche.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 586 | $0.000618 | 1483 | $0.001350 | 2069 | $0.001968 |
| 2 | 520 | $0.000618 | 1807 | $0.001500 | 2327 | $0.002118 |
| 3 | 1637 | $0.000618 | 1819 | $0.001530 | 3456 | $0.002148 |
| 4 | 600 | $0.000618 | 1536 | $0.001590 | 2136 | $0.002208 |
| 5 | 680 | $0.000618 | 1232 | $0.001330 | 1912 | $0.001948 |

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
| 1 | 677 | $0.000640 | 691 | $0.000802 | 1368 | $0.001442 |
| 2 | 584 | $0.000640 | 1042 | $0.000802 | 1626 | $0.001442 |
| 3 | 783 | $0.000640 | 819 | $0.000802 | 1602 | $0.001442 |
| 4 | 680 | $0.000648 | 1338 | $0.001474 | 2018 | $0.002122 |
| 5 | 670 | $0.000640 | 1024 | $0.000802 | 1694 | $0.001442 |

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
| 1 | 712 | $0.000592 | 889 | $0.000796 | 1601 | $0.001388 |
| 2 | 578 | $0.000592 | 921 | $0.000796 | 1499 | $0.001388 |
| 3 | 682 | $0.000592 | 819 | $0.000796 | 1501 | $0.001388 |
| 4 | 611 | $0.000592 | 673 | $0.000796 | 1284 | $0.001388 |
| 5 | 692 | $0.000592 | 922 | $0.000796 | 1614 | $0.001388 |

### delete-repeated-yo-compre

- Original text: `Yo fui al mercado y yo compré pan.`
- Expected corrected text: `Fui al mercado y compré pan.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Yo fui al mercado y compré pan.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo fui al mercado y yo compré pan.` | Yo fui al mercado y yo compré pan. -> Yo fui al mercado y compré pan. | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 2 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 3 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 4 | `Yo fui al mercado y yo compré pan.` | yo compré pan -> compré pan | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 5 | `Yo fui al mercado y yo compré pan.` | yo compré -> compré | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 834 | $0.000618 | 1279 | $0.001490 | 2113 | $0.002108 |
| 2 | 681 | $0.000618 | 1432 | $0.001480 | 2113 | $0.002098 |
| 3 | 576 | $0.000618 | 1332 | $0.001390 | 1908 | $0.002008 |
| 4 | 575 | $0.000618 | 1538 | $0.001380 | 2113 | $0.001998 |
| 5 | 782 | $0.000618 | 1300 | $0.001370 | 2082 | $0.001988 |

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
| 2 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Nosotros salimos temprano y llegamos a tiempo. | `Nosotros salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo. | `Salimos temprano y llegamos a tiempo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 711 | $0.000638 | 1333 | $0.001502 | 2044 | $0.002141 |
| 2 | 676 | $0.000638 | 1231 | $0.001502 | 1907 | $0.002141 |
| 3 | 651 | $0.000638 | 1562 | $0.001542 | 2213 | $0.002180 |
| 4 | 681 | $0.000638 | 1647 | $0.001632 | 2328 | $0.002270 |
| 5 | 582 | $0.000638 | 1316 | $0.001563 | 1898 | $0.002201 |

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
| 1 | 579 | $0.000568 | 820 | $0.000794 | 1399 | $0.001362 |
| 2 | 781 | $0.000568 | 921 | $0.000794 | 1702 | $0.001362 |
| 3 | 518 | $0.000568 | 776 | $0.000794 | 1294 | $0.001362 |
| 4 | 678 | $0.000568 | 923 | $0.000794 | 1601 | $0.001362 |
| 5 | 784 | $0.000568 | 954 | $0.000794 | 1738 | $0.001362 |

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
| 1 | 851 | $0.000588 | 819 | $0.000796 | 1670 | $0.001384 |
| 2 | 782 | $0.000588 | 758 | $0.000796 | 1540 | $0.001384 |
| 3 | 845 | $0.000588 | 818 | $0.000796 | 1663 | $0.001384 |
| 4 | 782 | $0.000588 | 822 | $0.000796 | 1604 | $0.001384 |
| 5 | 573 | $0.000588 | 715 | $0.000796 | 1288 | $0.001384 |

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
| 1 | 583 | $0.000588 | 726 | $0.000796 | 1309 | $0.001384 |
| 2 | 668 | $0.000588 | 1028 | $0.000796 | 1696 | $0.001384 |
| 3 | 2020 | $0.000588 | 705 | $0.000796 | 2725 | $0.001384 |
| 4 | 477 | $0.000588 | 725 | $0.000796 | 1202 | $0.001384 |
| 5 | 615 | $0.000588 | 771 | $0.000796 | 1386 | $0.001384 |

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
| 1 | 569 | $0.000598 | 1393 | $0.000798 | 1962 | $0.001396 |
| 2 | 525 | $0.000598 | 720 | $0.000798 | 1245 | $0.001396 |
| 3 | 576 | $0.000598 | 821 | $0.000798 | 1397 | $0.001396 |
| 4 | 575 | $0.000598 | 925 | $0.000798 | 1500 | $0.001396 |
| 5 | 680 | $0.000598 | 817 | $0.000798 | 1497 | $0.001396 |

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
| 3 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `La reunión es en la segunda planta.` | (none) | `La reunión es en la segunda planta.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 502 | $0.000598 | 692 | $0.000798 | 1194 | $0.001396 |
| 2 | 784 | $0.000598 | 849 | $0.000798 | 1633 | $0.001396 |
| 3 | 647 | $0.000598 | 867 | $0.000798 | 1514 | $0.001396 |
| 4 | 533 | $0.000598 | 715 | $0.000798 | 1248 | $0.001396 |
| 5 | 691 | $0.000598 | 811 | $0.000798 | 1502 | $0.001396 |

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
| 1 | 679 | $0.000598 | 668 | $0.000798 | 1347 | $0.001396 |
| 2 | 932 | $0.000598 | 924 | $0.000798 | 1856 | $0.001396 |
| 3 | 588 | $0.000598 | 707 | $0.000798 | 1295 | $0.001396 |
| 4 | 646 | $0.000598 | 954 | $0.000798 | 1600 | $0.001396 |
| 5 | 609 | $0.000598 | 830 | $0.000798 | 1439 | $0.001396 |

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
| 1 | 636 | $0.000598 | 718 | $0.000798 | 1354 | $0.001396 |
| 2 | 884 | $0.000598 | 717 | $0.000798 | 1601 | $0.001396 |
| 3 | 781 | $0.000598 | 717 | $0.000798 | 1498 | $0.001396 |
| 4 | 681 | $0.000598 | 759 | $0.000798 | 1440 | $0.001396 |
| 5 | 633 | $0.000598 | 925 | $0.000798 | 1558 | $0.001396 |

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
| 1 | 782 | $0.000588 | 713 | $0.000796 | 1495 | $0.001384 |
| 2 | 681 | $0.000588 | 1128 | $0.000796 | 1809 | $0.001384 |
| 3 | 577 | $0.000588 | 716 | $0.000796 | 1293 | $0.001384 |
| 4 | 615 | $0.000588 | 783 | $0.000796 | 1398 | $0.001384 |
| 5 | 779 | $0.000588 | 822 | $0.000796 | 1601 | $0.001384 |

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
| 1 | 679 | $0.000598 | 1138 | $0.000798 | 1817 | $0.001396 |
| 2 | 781 | $0.000598 | 1014 | $0.000798 | 1795 | $0.001396 |
| 3 | 485 | $0.000598 | 809 | $0.000798 | 1294 | $0.001396 |
| 4 | 679 | $0.000598 | 923 | $0.000798 | 1602 | $0.001396 |
| 5 | 782 | $0.000598 | 718 | $0.000798 | 1500 | $0.001396 |

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
| 1 | 575 | $0.000588 | 717 | $0.000796 | 1292 | $0.001384 |
| 2 | 680 | $0.000588 | 669 | $0.000796 | 1349 | $0.001384 |
| 3 | 625 | $0.000588 | 718 | $0.000796 | 1343 | $0.001384 |
| 4 | 782 | $0.000588 | 1125 | $0.000796 | 1907 | $0.001384 |
| 5 | 579 | $0.000588 | 1127 | $0.000796 | 1706 | $0.001384 |

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
| 1 | 578 | $0.000606 | 1742 | $0.000799 | 2320 | $0.001405 |
| 2 | 578 | $0.000606 | 3787 | $0.000799 | 4365 | $0.001405 |
| 3 | 687 | $0.000606 | 800 | $0.000799 | 1487 | $0.001405 |
| 4 | 591 | $0.000606 | 708 | $0.000799 | 1299 | $0.001405 |
| 5 | 687 | $0.000606 | 693 | $0.000799 | 1380 | $0.001405 |

### false-friend-aplico-trabajo

- Original text: `Aplicó para un trabajo.`
- Expected corrected text: `Solicitó un trabajo.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Solicitó un trabajo.`
  - `Se postuló para un trabajo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Se postuló para un trabajo | `Se postuló para un trabajo.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 602 | $0.000578 | 1653 | $0.001605 | 2255 | $0.002183 |
| 2 | 477 | $0.000578 | 1588 | $0.001555 | 2065 | $0.002133 |
| 3 | 611 | $0.000578 | 1639 | $0.001665 | 2250 | $0.002243 |
| 4 | 983 | $0.000578 | 2052 | $0.001735 | 3035 | $0.002313 |
| 5 | 576 | $0.000578 | 1637 | $0.001645 | 2213 | $0.002223 |

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
| 1 | 581 | $0.000606 | 717 | $0.000799 | 1298 | $0.001405 |
| 2 | 575 | $0.000606 | 2358 | $0.000799 | 2933 | $0.001405 |
| 3 | 783 | $0.000606 | 985 | $0.000799 | 1768 | $0.001405 |
| 4 | 617 | $0.000606 | 818 | $0.000799 | 1435 | $0.001405 |
| 5 | 783 | $0.000606 | 604 | $0.000799 | 1387 | $0.001405 |

### false-friend-embarazado

- Original text: `Estoy embarazado por llegar tarde.`
- Expected corrected text: `Me da vergüenza llegar tarde.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Estoy avergonzado por llegar tarde.`
  - `Estoy avergonzado de haber llegado tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy avergonzado por llegar tarde.` | por llegar tarde -> de haber llegado tarde | `Estoy avergonzado de haber llegado tarde.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 692 | $0.000606 | 715 | $0.000799 | 1407 | $0.001405 |
| 2 | 622 | $0.000606 | 680 | $0.000799 | 1302 | $0.001405 |
| 3 | 878 | $0.000606 | 1359 | $0.001539 | 2237 | $0.002145 |
| 4 | 819 | $0.000606 | 755 | $0.000799 | 1574 | $0.001405 |
| 5 | 679 | $0.000606 | 1329 | $0.000799 | 2008 | $0.001405 |

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
| 1 | 680 | $0.000568 | 821 | $0.000794 | 1501 | $0.001362 |
| 2 | 576 | $0.000568 | 820 | $0.000794 | 1396 | $0.001362 |
| 3 | 574 | $0.000568 | 1027 | $0.000794 | 1601 | $0.001362 |
| 4 | 553 | $0.000568 | 740 | $0.000794 | 1293 | $0.001362 |
| 5 | 679 | $0.000568 | 717 | $0.000794 | 1396 | $0.001362 |

## Phrase-Level Naturalness

### naturalness-buen-tiempo

- Original text: `Tuvimos un buen tiempo.`
- Expected corrected text: `Lo pasamos bien.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Tuvimos un buen rato.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Tuvimos un buen rato.` | (none) | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 2 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 3 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 4 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 5 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000588 | 1025 | $0.000796 | 1604 | $0.001384 |
| 2 | 575 | $0.000588 | 1949 | $0.001706 | 2524 | $0.002294 |
| 3 | 540 | $0.000588 | 1854 | $0.001736 | 2394 | $0.002324 |
| 4 | 630 | $0.000588 | 1611 | $0.001766 | 2241 | $0.002354 |
| 5 | 508 | $0.000588 | 1705 | $0.001656 | 2213 | $0.002244 |

### naturalness-corriendo-tarde

- Original text: `Estoy corriendo tarde para la reunión.`
- Expected corrected text: `Voy tarde a la reunión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Voy a llegar tarde a la reunión.`
  - `Estoy llegando tarde a la reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión -> Voy a llegar tarde a la reunión | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 4 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 782 | $0.000590 | 1750 | $0.001796 | 2532 | $0.002386 |
| 2 | 603 | $0.000590 | 1504 | $0.001356 | 2107 | $0.001946 |
| 3 | 882 | $0.000590 | 1607 | $0.001706 | 2489 | $0.002296 |
| 4 | 816 | $0.000590 | 1297 | $0.001356 | 2113 | $0.001946 |
| 5 | 1020 | $0.000590 | 1331 | $0.001426 | 2351 | $0.002016 |

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
| 1 | 580 | $0.000588 | 818 | $0.000796 | 1398 | $0.001384 |
| 2 | 576 | $0.000588 | 789 | $0.000796 | 1365 | $0.001384 |
| 3 | 608 | $0.000588 | 1168 | $0.000796 | 1776 | $0.001384 |
| 4 | 639 | $0.000588 | 718 | $0.000796 | 1357 | $0.001384 |
| 5 | 680 | $0.000588 | 818 | $0.000796 | 1498 | $0.001384 |

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
| 1 | 577 | $0.000588 | 924 | $0.000796 | 1501 | $0.001384 |
| 2 | 577 | $0.000588 | 716 | $0.000796 | 1293 | $0.001384 |
| 3 | 782 | $0.000588 | 921 | $0.000796 | 1703 | $0.001384 |
| 4 | 576 | $0.000588 | 719 | $0.000796 | 1295 | $0.001384 |
| 5 | 884 | $0.000588 | 822 | $0.000796 | 1706 | $0.001384 |

### naturalness-llamar-para-atras

- Original text: `Te llamo para atrás.`
- Expected corrected text: `Te devuelvo la llamada.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Te llamo luego.`
  - `Te llamo más tarde.`
  - `Te llamo después.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Te llamo luego.` | (none) | `Te llamo luego.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Te llamo más tarde.` | (none) | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |
| 3 | `Te llamo de vuelta.` | de vuelta -> más tarde | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |
| 4 | `Te llamo para atrás.` | para atrás -> después | `Te llamo después.` | correct_fix | Pass | Matches expected output. |
| 5 | `Te llamo después.` | (none) | `Te llamo después.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 537 | $0.000570 | 587 | $0.000794 | 1124 | $0.001364 |
| 2 | 540 | $0.000578 | 821 | $0.000795 | 1361 | $0.001373 |
| 3 | 682 | $0.000578 | 1488 | $0.001755 | 2170 | $0.002333 |
| 4 | 522 | $0.000578 | 1691 | $0.001745 | 2213 | $0.002323 |
| 5 | 627 | $0.000570 | 922 | $0.000794 | 1549 | $0.001364 |

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
| 1 | 577 | $0.000586 | 1639 | $0.001546 | 2216 | $0.002132 |
| 2 | 679 | $0.000586 | 2458 | $0.001526 | 3137 | $0.002112 |
| 3 | 577 | $0.000586 | 1433 | $0.001616 | 2010 | $0.002202 |
| 4 | 607 | $0.000586 | 1515 | $0.001666 | 2122 | $0.002252 |
| 5 | 568 | $0.000586 | 4607 | $0.001716 | 5175 | $0.002302 |

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
| 1 | 488 | $0.000568 | 909 | $0.000794 | 1397 | $0.001362 |
| 2 | 499 | $0.000568 | 795 | $0.000794 | 1294 | $0.001362 |
| 3 | 508 | $0.000568 | 787 | $0.000794 | 1295 | $0.001362 |
| 4 | 679 | $0.000568 | 787 | $0.000794 | 1466 | $0.001362 |
| 5 | 711 | $0.000568 | 1537 | $0.000794 | 2248 | $0.001362 |

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
| 1 | 575 | $0.000598 | 726 | $0.000798 | 1301 | $0.001396 |
| 2 | 536 | $0.000598 | 807 | $0.000798 | 1343 | $0.001396 |
| 3 | 729 | $0.000598 | 667 | $0.000798 | 1396 | $0.001396 |
| 4 | 831 | $0.000598 | 757 | $0.000798 | 1588 | $0.001396 |
| 5 | 741 | $0.000598 | 719 | $0.000798 | 1460 | $0.001396 |

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
| 1 | 564 | $0.000598 | 620 | $0.000798 | 1184 | $0.001396 |
| 2 | 584 | $0.000598 | 717 | $0.000798 | 1301 | $0.001396 |
| 3 | 679 | $0.000598 | 820 | $0.000798 | 1499 | $0.001396 |
| 4 | 661 | $0.000598 | 718 | $0.000798 | 1379 | $0.001396 |
| 5 | 566 | $0.000598 | 902 | $0.000798 | 1468 | $0.001396 |

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
| 1 | 470 | $0.000598 | 723 | $0.000798 | 1193 | $0.001396 |
| 2 | 625 | $0.000598 | 715 | $0.000798 | 1340 | $0.001396 |
| 3 | 2021 | $0.000598 | 709 | $0.000798 | 2730 | $0.001396 |
| 4 | 681 | $0.000598 | 718 | $0.000798 | 1399 | $0.001396 |
| 5 | 985 | $0.000598 | 717 | $0.000798 | 1702 | $0.001396 |

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
| 1 | 689 | $0.000588 | 913 | $0.000796 | 1602 | $0.001384 |
| 2 | 578 | $0.000588 | 1350 | $0.000796 | 1928 | $0.001384 |
| 3 | 661 | $0.000588 | 716 | $0.000796 | 1377 | $0.001384 |
| 4 | 511 | $0.000588 | 779 | $0.000796 | 1290 | $0.001384 |
| 5 | 580 | $0.000588 | 923 | $0.000796 | 1503 | $0.001384 |

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
| 1 | 678 | $0.000598 | 718 | $0.000798 | 1396 | $0.001396 |
| 2 | 576 | $0.000598 | 1026 | $0.000798 | 1602 | $0.001396 |
| 3 | 577 | $0.000598 | 821 | $0.000798 | 1398 | $0.001396 |
| 4 | 678 | $0.000598 | 657 | $0.000798 | 1335 | $0.001396 |
| 5 | 840 | $0.000598 | 720 | $0.000798 | 1560 | $0.001396 |

### correct-tomar-foto

- Original text: `Necesito tomar una foto del documento.`
- Expected corrected text: `Necesito tomar una foto del documento.`
- Pass rate: 2/5
- Distinct final outputs:
  - `Necesito sacar una foto del documento.`
  - `Necesito tomar una foto del documento.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito tomar una foto del documento.` | tomar una foto -> sacar una foto | `Necesito sacar una foto del documento.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Necesito tomar una foto del documento.` | tomar una foto -> sacar una foto | `Necesito sacar una foto del documento.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Necesito tomar una foto del documento.` | tomar una foto -> sacar una foto | `Necesito sacar una foto del documento.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 650 | $0.000598 | 1358 | $0.001648 | 2008 | $0.002246 |
| 2 | 1397 | $0.000598 | 821 | $0.000798 | 2218 | $0.001396 |
| 3 | 575 | $0.000598 | 1845 | $0.001648 | 2420 | $0.002246 |
| 4 | 679 | $0.000598 | 1742 | $0.001688 | 2421 | $0.002286 |
| 5 | 781 | $0.000598 | 716 | $0.000798 | 1497 | $0.001396 |

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
| 1 | 592 | $0.000618 | 909 | $0.000800 | 1501 | $0.001418 |
| 2 | 577 | $0.000618 | 820 | $0.000800 | 1397 | $0.001418 |
| 3 | 690 | $0.000618 | 809 | $0.000800 | 1499 | $0.001418 |
| 4 | 740 | $0.000618 | 657 | $0.000800 | 1397 | $0.001418 |
| 5 | 686 | $0.000618 | 673 | $0.000800 | 1359 | $0.001418 |

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
| 1 | 718 | $0.000648 | 921 | $0.000804 | 1639 | $0.001452 |
| 2 | 1503 | $0.000648 | 1024 | $0.000804 | 2527 | $0.001452 |
| 3 | 679 | $0.000648 | 920 | $0.000804 | 1599 | $0.001452 |
| 4 | 578 | $0.000648 | 717 | $0.000804 | 1295 | $0.001452 |
| 5 | 601 | $0.000648 | 1102 | $0.000804 | 1703 | $0.001452 |

## Mixed Operations

### mixed-preposition-and-redundant-pronoun

- Original text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.`
  - `Insisto en que revises el contrato, porque yo trabajo mucho y estudio por las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato, porque yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato, porque yo trabajo mucho y estudio por las noches.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 725 | $0.000708 | 1797 | $0.001971 | 2522 | $0.002679 |
| 2 | 912 | $0.000708 | 2227 | $0.002531 | 3139 | $0.003239 |
| 3 | 695 | $0.000708 | 1824 | $0.001971 | 2519 | $0.002679 |
| 4 | 683 | $0.000708 | 1945 | $0.002031 | 2628 | $0.002739 |
| 5 | 638 | $0.000708 | 4611 | $0.001861 | 5249 | $0.002569 |

### mixed-article-and-accent

- Original text: `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.`
- Expected corrected text: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Necesito comprar un libro para la clase, y también compré café en una cafetería pequeña.`
  - `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Necesito comprar un libro para la clase, y compré café -> Necesito comprar un libro para la clase, y también compré café | `Necesito comprar un libro para la clase, y también compré café en una cafetería pequeña.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 3 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 4 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |
| 5 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 614 | $0.000702 | 1640 | $0.001661 | 2254 | $0.002363 |
| 2 | 733 | $0.000702 | 764 | $0.000811 | 1497 | $0.001513 |
| 3 | 632 | $0.000702 | 869 | $0.000811 | 1501 | $0.001513 |
| 4 | 644 | $0.000702 | 751 | $0.000811 | 1395 | $0.001513 |
| 5 | 679 | $0.000702 | 819 | $0.000811 | 1498 | $0.001513 |

### mixed-personal-a-and-subjunctive

- Original text: `Vi mi profesor en la estación, y recordé que es importante que estudio.`
- Expected corrected text: `Vi a mi profesor en la estación, y recordé que es importante que estudie.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Vi a mi profesor en la estación, y recordé que es importante estudiar.`
  - `Vi a mi profesor en la estación, y recordé que es importante que estudiar.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | es importante que estudie -> es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | que estudie -> estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | estudie -> estudiar | `Vi a mi profesor en la estación, y recordé que es importante que estudiar.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | recordé que es importante que estudie -> recordé que es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | recordé que es importante que estudie -> recordé que es importante estudiar | `Vi a mi profesor en la estación, y recordé que es importante estudiar.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000694 | 1537 | $0.001540 | 2114 | $0.002234 |
| 2 | 723 | $0.000694 | 1314 | $0.001450 | 2037 | $0.002144 |
| 3 | 865 | $0.000694 | 1326 | $0.001520 | 2191 | $0.002214 |
| 4 | 749 | $0.000694 | 1572 | $0.001710 | 2321 | $0.002404 |
| 5 | 573 | $0.000694 | 1638 | $0.001660 | 2211 | $0.002354 |

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
| 1 | 578 | $0.000652 | 717 | $0.000804 | 1295 | $0.001456 |
| 2 | 552 | $0.000652 | 742 | $0.000804 | 1294 | $0.001456 |
| 3 | 883 | $0.000652 | 820 | $0.000804 | 1703 | $0.001456 |
| 4 | 768 | $0.000652 | 833 | $0.000804 | 1601 | $0.001456 |
| 5 | 578 | $0.000652 | 947 | $0.000804 | 1525 | $0.001456 |

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
| 1 | 653 | $0.000696 | 1539 | $0.001550 | 2192 | $0.002246 |
| 2 | 679 | $0.000696 | 1638 | $0.001680 | 2317 | $0.002376 |
| 3 | 984 | $0.000696 | 1330 | $0.001530 | 2314 | $0.002226 |
| 4 | 782 | $0.000696 | 1638 | $0.001650 | 2420 | $0.002346 |
| 5 | 678 | $0.000696 | 1434 | $0.001620 | 2112 | $0.002316 |

---

## Overall summary

| Metric | Value |
| --- | --- |
| Fixtures | 85 |
| Total runs | 425 |
| Pass rate | 379/425 |

### Score breakdown (issue #129 — full taxonomy, not only pass/fail)

| | Total | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| All runs | 425 | 319 | 6 | 0 | 10 | 60 | 30 | 0 |

### Latency / cost by pass (issue #130 — no fallback phase exists in this harness, so totals equal Pass 1 + Pass 2 only)

| Phase | Total latency (ms) | Total est. cost (USD) |
| --- | --- | --- |
| Pass 1 (first pass) | 300826 | $0.255014 |
| Pass 2 (lexical review) | 433450 | $0.403882 |
| **Total (Pass 1 + Pass 2)** | 734276 | $0.658896 |
