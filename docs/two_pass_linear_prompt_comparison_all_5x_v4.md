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
- Generated: 2026-08-09T19:20:02.402758Z

## Fixture summary

Pass rate is `passed/runs`; "distinct outputs" lists every unique final output produced across a fixture's runs — more than one entry means the model was not stable for that fixture.

| Fixture | Language point | Runs | Pass rate | Distinct final outputs | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| clean-grammar-only | Accents / Diacritics | 5 | 5/5 | `Vi mucho tráfico ayer.` | 14180 | $0.009604 |
| naturalness-only | Collocations / Strong Calques | 5 | 5/5 | `Voy a tomar una decisión importante.` | 9208 | $0.009803 |
| grammar-and-naturalness-independent | Accents / Diacritics + Collocations / Strong Calques (independent spans) | 5 | 5/5 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | 9435 | $0.011077 |
| grammar-overlaps-naturalness | Verb Morphology (spelling) overlapping Collocations / Strong Calques | 5 | 5/5 | `Ayer tomó una decisión importante.` | 11814 | $0.012985 |
| ambiguous-naturalness-span | Ambiguous / Repeated Span Safety (Naturalness) | 5 | 5/5 | `Vi mucho tráfico, y luego vi más tráfico.` | 8112 | $0.009028 |
| accent-manana | Accents / Diacritics | 5 | 5/5 | `Voy al parque mañana por la tarde.` | 9132 | $0.009699 |
| accent-medico | Accents / Diacritics | 5 | 5/5 | `El médico llegó después de la reunión.` | 9339 | $0.011621 |
| accent-espana-pais | Accents / Diacritics | 5 | 5/5 | `España es un país muy diverso.` | 10056 | $0.010365 |
| accent-cumpleanos-otono | Accents / Diacritics | 5 | 5/5 | `Mi cumpleaños es en otoño.` | 8514 | $0.010383 |
| accent-cafe-cafeteria | Accents / Diacritics | 5 | 5/5 | `Compré café en una cafetería pequeña.` | 9440 | $0.012081 |
| agreement-ninos-manzanas | Gender / Number Agreement | 5 | 5/5 | `Los niños comen muchas manzanas.` | 9427 | $0.011273 |
| agreement-ventanas-abiertas | Gender / Number Agreement | 5 | 5/5 | `Las ventanas estaban abiertas.` | 12036 | $0.009666 |
| agreement-puerta-cerrada | Gender / Number Agreement | 5 | 5/5 | `Una puerta estaba cerrada.` | 8615 | $0.009584 |
| agreement-billetes-caros | Gender / Number Agreement | 5 | 5/5 | `Los billetes estaban caros.` | 8650 | $0.009635 |
| agreement-fechas-escritas | Gender / Number Agreement | 5 | 5/5 | `Las fechas estaban escritas sin tilde.` | 8406 | $0.009977 |
| verb-nosotros-fuimos | Verb Agreement / Morphology | 5 | 5/5 | `Mis compañeros y yo fuimos a la biblioteca.` | 9696 | $0.010162 |
| verb-ninos-comen | Verb Agreement / Morphology | 5 | 5/5 | `Los niños comen en el jardín.` | 9586 | $0.009867 |
| verb-compre-pan | Verb Agreement / Morphology | 5 | 5/5 | `Yo fui al mercado y compré pan.` | 8943 | $0.009833 |
| verb-ellos-estudian | Verb Agreement / Morphology | 5 | 5/5 | `Ellos estudian todas las noches.` | 10881 | $0.010083 |
| verb-nosotros-vivimos | Verb Agreement / Morphology | 5 | 5/5 | `Nosotros vivimos cerca del centro.` | 8439 | $0.009947 |
| prep-insisto-en | Required Prepositions | 5 | 5/5 | `Insisto en que revises el contrato.` | 8266 | $0.010201 |
| prep-empresa-en-la-que | Required Prepositions | 5 | 3/5 | `La empresa en que trabajo está cerca.`; `La empresa en la que trabajo está cerca.` | 10360 | $0.011328 |
| prep-dependo-de | Required Prepositions | 5 | 5/5 | `Dependo de que me ayudes mañana.` | 8622 | $0.010137 |
| prep-pienso-en-ti | Required Prepositions | 5 | 5/5 | `Pienso en ti todos los días.` | 10805 | $0.010065 |
| prep-sone-con | Required Prepositions | 5 | 5/5 | `Soñé con mi antiguo colegio.` | 8803 | $0.010065 |
| article-puerta-principal | Articles / Determiners | 5 | 5/5 | `Abrió la puerta principal.` | 8742 | $0.009761 |
| article-un-libro | Articles / Determiners | 5 | 5/5 | `Necesito comprar un libro para la clase.` | 8390 | $0.009841 |
| article-el-profesor-la-regla | Articles / Determiners | 5 | 5/5 | `El profesor explicó la regla otra vez.` | 8381 | $0.010071 |
| article-la-tienda | Articles / Determiners | 5 | 5/5 | `Fui a la tienda después del trabajo.` | 9075 | $0.009921 |
| article-cita-medico | Articles / Determiners | 5 | 5/5 | `Tengo una cita con el médico mañana.` | 9638 | $0.009975 |
| subj-estudies | Subjunctive / Mood | 5 | 5/5 | `Es importante que estudies.` | 8737 | $0.009874 |
| subj-tenga-razon | Subjunctive / Mood | 5 | 5/5 | `No creo que tenga razón.` | 9432 | $0.009746 |
| subj-vengas | Subjunctive / Mood | 5 | 5/5 | `Quiero que vengas conmigo.` | 8766 | $0.010083 |
| subj-enviara | Subjunctive / Mood | 5 | 5/5 | `Era necesario que enviara su parte.` | 8611 | $0.009939 |
| subj-hable-frances | Subjunctive / Mood | 5 | 5/5 | `Busco a alguien que hable francés.` | 8904 | $0.010009 |
| missing-que-creo | Required Additions / Omissions | 5 | 5/5 | `Creo que está bien terminar hoy.` | 8314 | $0.009913 |
| missing-les-ninos | Required Additions / Omissions | 5 | 5/5 | `A los niños les expliqué la regla.` | 9744 | $0.010081 |
| missing-personal-a-profesor | Required Additions / Omissions | 5 | 5/5 | `Vi a mi profesor en la estación.` | 8729 | $0.010137 |
| missing-se-levanto | Required Additions / Omissions | 5 | 5/5 | `Se levantó temprano ayer.` | 10257 | $0.009954 |
| missing-le-gusta | Required Additions / Omissions | 5 | 5/5 | `A Juan le gusta el café.` | 9134 | $0.009977 |
| delete-repeated-yo-estudio | Unnecessary Extras / Deletions | 5 | 0/5 | `Yo trabajo mucho y yo estudio por las noches.` | 9542 | $0.009028 |
| delete-repeated-ellos-visitaron | Unnecessary Extras / Deletions | 5 | 0/5 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | 9241 | $0.009196 |
| delete-repeated-a-mi | Unnecessary Extras / Deletions | 5 | 5/5 | `A mí me gusta el café.` | 9541 | $0.010167 |
| delete-repeated-yo-compre | Unnecessary Extras / Deletions | 5 | 0/5 | `Yo fui al mercado y yo compré pan.` | 8416 | $0.009028 |
| delete-repeated-nosotros | Unnecessary Extras / Deletions | 5 | 0/5 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | 9014 | $0.009140 |
| ser-profesor | Ser / Estar / Haber | 5 | 5/5 | `Mi hermano es profesor.` | 8740 | $0.009634 |
| haber-veinte-personas | Ser / Estar / Haber | 5 | 5/5 | `En la sala hay veinte personas.` | 8517 | $0.009947 |
| ser-capital-madrid | Ser / Estar / Haber | 5 | 5/5 | `Madrid es la capital de España.` | 9241 | $0.009931 |
| estar-contento | Ser / Estar / Haber | 5 | 5/5 | `Estoy muy contento con el resultado.` | 7489 | $0.008915 |
| ser-reunion-segunda-planta | Ser / Estar / Haber | 5 | 5/5 | `La reunión es en la segunda planta.` | 8312 | $0.008915 |
| haber-habia-personas | Impersonal Haber / Se | 5 | 5/5 | `Había muchas personas en la entrada.` | 8213 | $0.010155 |
| haber-hubo-problemas | Impersonal Haber / Se | 5 | 5/5 | `Hubo varios problemas durante la reunión.` | 8928 | $0.009971 |
| se-venden-pisos | Impersonal Haber / Se | 5 | 5/5 | `Se venden pisos en el centro.` | 8010 | $0.010019 |
| se-necesitan-voluntarios | Impersonal Haber / Se | 5 | 5/5 | `Se necesitan voluntarios para el evento.` | 8212 | $0.010147 |
| haber-habia-cifras | Impersonal Haber / Se | 5 | 5/5 | `Había varias cifras incorrectas.` | 8376 | $0.009971 |
| collocation-hacer-decision | Collocations / Strong Calques | 5 | 5/5 | `Necesito tomar una decisión.` | 8613 | $0.009794 |
| collocation-hacer-atencion | Collocations / Strong Calques | 5 | 5/5 | `Tenemos que prestar atención.` | 8543 | $0.009690 |
| collocation-tomar-reunion | Collocations / Strong Calques | 5 | 5/5 | `El equipo tuvo una reunión.` | 8338 | $0.009746 |
| collocation-hacer-paseo | Collocations / Strong Calques | 5 | 5/5 | `Ella dio un paseo.` | 11086 | $0.012136 |
| collocation-hace-sentido | Collocations / Strong Calques | 5 | 5/5 | `Esto tiene sentido.` | 8212 | $0.009546 |
| false-friend-atendio-universidad | False Friends / Word Choice | 5 | 5/5 | `Asistió a la universidad en Madrid.` | 8722 | $0.010209 |
| false-friend-aplico-trabajo | False Friends / Word Choice | 5 | 5/5 | `Solicitó un trabajo.` | 12409 | $0.013318 |
| false-friend-realice | False Friends / Word Choice | 5 | 5/5 | `Me di cuenta de que estaba equivocado.` | 8727 | $0.010241 |
| false-friend-embarazado | False Friends / Word Choice | 5 | 3/5 | `Estoy avergonzada por llegar tarde.`; `Estoy avergonzado por llegar tarde.` | 11668 | $0.012084 |
| false-friend-actualmente-control | False Friends / Word Choice | 5 | 5/5 | `Actualmente vivo en Londres.` | 8340 | $0.008746 |
| naturalness-buen-tiempo | Phrase-Level Naturalness | 5 | 5/5 | `Tuvimos un buen rato.`; `Lo pasamos bien.` | 12204 | $0.013129 |
| naturalness-corriendo-tarde | Phrase-Level Naturalness | 5 | 5/5 | `Voy a llegar tarde a la reunión.` | 13852 | $0.014935 |
| naturalness-pasar-buen-tiempo | Phrase-Level Naturalness | 5 | 5/5 | `Quiero pasar un buen rato.` | 9021 | $0.009859 |
| naturalness-puedo-tener-cerveza | Phrase-Level Naturalness | 5 | 0/5 | `¿Puedo tener una cerveza?` | 8008 | $0.008899 |
| naturalness-llamar-para-atras | Phrase-Level Naturalness | 5 | 4/5 | `Te llamo de vuelta.`; `Te llamo después.`; `Te llamo más tarde.` | 11597 | $0.012586 |
| regional-voy-para-casa | Valid Regional / Should Not Flag | 5 | 0/5 | `Voy para la casa ahora mismo.`; `Voy a casa ahora mismo.` | 12203 | $0.013409 |
| regional-vos-tenes | Valid Regional / Should Not Flag | 5 | 5/5 | `Vos tenés razón.` | 9033 | $0.008746 |
| regional-cojo-autobus | Valid Regional / Should Not Flag | 5 | 5/5 | `Cojo el autobús cada mañana.` | 8197 | $0.008915 |
| regional-preterite-esta-manana | Valid Regional / Should Not Flag | 5 | 5/5 | `Esta mañana hablé con mi jefe.` | 8537 | $0.008915 |
| regional-dale | Valid Regional / Should Not Flag | 5 | 5/5 | `Dale, nos vemos más tarde.` | 10465 | $0.008915 |
| correct-buenos-dias | Already Correct / Do Not Tinker | 5 | 5/5 | `Buenos días, ¿cómo estás?` | 9777 | $0.008899 |
| correct-hacer-pregunta | Already Correct / Do Not Tinker | 5 | 5/5 | `Voy a hacer una pregunta al profesor.` | 9104 | $0.008915 |
| correct-tomar-foto | Already Correct / Do Not Tinker | 5 | 5/5 | `Necesito tomar una foto del documento.` | 7816 | $0.008915 |
| correct-visitar-abuela | Already Correct / Do Not Tinker | 5 | 5/5 | `Mañana visitaré a mi abuela.` | 8395 | $0.009028 |
| correct-me-quedo-en-casa | Already Correct / Do Not Tinker | 5 | 5/5 | `Está lloviendo, así que me quedo en casa.` | 7408 | $0.009196 |
| mixed-preposition-and-redundant-pronoun | Mixed Operations | 5 | 0/5 | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.`; `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | 9516 | $0.011740 |
| mixed-article-and-accent | Mixed Operations | 5 | 5/5 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | 10179 | $0.012128 |
| mixed-personal-a-and-subjunctive | Mixed Operations | 5 | 5/5 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | 9280 | $0.011618 |
| mixed-gender-agreement-and-redundant-pronoun | Mixed Operations | 5 | 5/5 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | 9089 | $0.011256 |
| mixed-verb-agreement-and-missing-que | Mixed Operations | 5 | 5/5 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | 9064 | $0.011876 |

## Accents / Diacritics

### clean-grammar-only

- Original text: `Vi mucho trafico ayer.`
- Expected corrected text: `Vi mucho tráfico ayer.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Vi mucho tráfico ayer.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico ayer.` | (none) | `Vi mucho tráfico ayer.` | correct_fix | Pass | Matches expected output. |
| 2 | `Vi mucho tráfico ayer.` | (none) | `Vi mucho tráfico ayer.` | correct_fix | Pass | Matches expected output. |
| 3 | `Vi mucho tráfico ayer.` | (none) | `Vi mucho tráfico ayer.` | correct_fix | Pass | Matches expected output. |
| 4 | `Vi mucho tráfico ayer.` | (none) | `Vi mucho tráfico ayer.` | correct_fix | Pass | Matches expected output. |
| 5 | `Vi mucho tráfico ayer.` | (none) | `Vi mucho tráfico ayer.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1619 | $0.000998 | 1245 | $0.000921 | 2864 | $0.001919 |
| 2 | 975 | $0.000998 | 1026 | $0.000921 | 2001 | $0.001919 |
| 3 | 825 | $0.000982 | 987 | $0.000921 | 1812 | $0.001903 |
| 4 | 672 | $0.001006 | 5119 | $0.000921 | 5791 | $0.001927 |
| 5 | 783 | $0.001014 | 929 | $0.000921 | 1712 | $0.001935 |

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
| 1 | 885 | $0.001026 | 921 | $0.000925 | 1806 | $0.001951 |
| 2 | 883 | $0.001018 | 1024 | $0.000925 | 1907 | $0.001943 |
| 3 | 781 | $0.001010 | 1023 | $0.000925 | 1804 | $0.001935 |
| 4 | 690 | $0.001010 | 914 | $0.000925 | 1604 | $0.001935 |
| 5 | 952 | $0.001010 | 1059 | $0.000925 | 2011 | $0.001935 |

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
| 1 | 988 | $0.001444 | 1022 | $0.000925 | 2010 | $0.002369 |
| 2 | 884 | $0.001324 | 921 | $0.000925 | 1805 | $0.002249 |
| 3 | 1090 | $0.001468 | 799 | $0.000925 | 1889 | $0.002393 |
| 4 | 917 | $0.001436 | 882 | $0.000925 | 1799 | $0.002361 |
| 5 | 811 | $0.001324 | 1025 | $0.000925 | 1836 | $0.002249 |

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
| 1 | 707 | $0.001130 | 891 | $0.000924 | 1598 | $0.002054 |
| 2 | 682 | $0.001130 | 1024 | $0.000924 | 1706 | $0.002054 |
| 3 | 1294 | $0.001130 | 1126 | $0.000924 | 2420 | $0.002054 |
| 4 | 1092 | $0.001178 | 1170 | $0.000924 | 2262 | $0.002102 |
| 5 | 945 | $0.001178 | 1125 | $0.000924 | 2070 | $0.002102 |

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
| 1 | 781 | $0.001154 | 921 | $0.000923 | 1702 | $0.002077 |
| 2 | 679 | $0.001154 | 1133 | $0.000923 | 1812 | $0.002077 |
| 3 | 671 | $0.001154 | 1025 | $0.000923 | 1696 | $0.002077 |
| 4 | 678 | $0.001154 | 873 | $0.000923 | 1551 | $0.002077 |
| 5 | 835 | $0.001154 | 918 | $0.000923 | 1753 | $0.002077 |

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
| 1 | 914 | $0.001482 | 894 | $0.000926 | 1808 | $0.002408 |
| 2 | 883 | $0.001506 | 1022 | $0.000926 | 1905 | $0.002432 |
| 3 | 988 | $0.001498 | 923 | $0.000926 | 1911 | $0.002424 |
| 4 | 892 | $0.001482 | 1028 | $0.000926 | 1920 | $0.002408 |
| 5 | 1041 | $0.001482 | 855 | $0.000926 | 1896 | $0.002408 |

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
| 1 | 672 | $0.001024 | 1228 | $0.000924 | 1900 | $0.001948 |
| 2 | 782 | $0.001040 | 1026 | $0.000924 | 1808 | $0.001964 |
| 3 | 803 | $0.001048 | 1050 | $0.000924 | 1853 | $0.001972 |
| 4 | 839 | $0.001048 | 1127 | $0.000924 | 1966 | $0.001972 |
| 5 | 721 | $0.001024 | 960 | $0.000924 | 1681 | $0.001948 |

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
| 1 | 725 | $0.001038 | 1049 | $0.000923 | 1774 | $0.001961 |
| 2 | 766 | $0.001038 | 1013 | $0.000923 | 1779 | $0.001961 |
| 3 | 659 | $0.001038 | 840 | $0.000923 | 1499 | $0.001961 |
| 4 | 781 | $0.001022 | 1127 | $0.000923 | 1908 | $0.001945 |
| 5 | 782 | $0.001046 | 871 | $0.000923 | 1653 | $0.001969 |

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
| 1 | 835 | $0.001012 | 1139 | $0.000921 | 1974 | $0.001933 |
| 2 | 777 | $0.001044 | 1101 | $0.000921 | 1878 | $0.001965 |
| 3 | 684 | $0.001020 | 789 | $0.000921 | 1473 | $0.001941 |
| 4 | 633 | $0.000988 | 808 | $0.000921 | 1441 | $0.001909 |
| 5 | 883 | $0.001020 | 894 | $0.000921 | 1777 | $0.001941 |

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
| 1 | 708 | $0.001022 | 820 | $0.000923 | 1528 | $0.001945 |
| 2 | 621 | $0.001022 | 980 | $0.000923 | 1601 | $0.001945 |
| 3 | 754 | $0.001022 | 1153 | $0.000923 | 1907 | $0.001945 |
| 4 | 787 | $0.001030 | 858 | $0.000923 | 1645 | $0.001953 |
| 5 | 608 | $0.001038 | 1049 | $0.000923 | 1657 | $0.001961 |

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
| 1 | 690 | $0.000828 | 1508 | $0.001541 | 2198 | $0.002369 |
| 2 | 556 | $0.000828 | 1530 | $0.001611 | 2086 | $0.002439 |
| 3 | 834 | $0.000828 | 1684 | $0.001621 | 2518 | $0.002449 |
| 4 | 635 | $0.000828 | 1619 | $0.001681 | 2254 | $0.002509 |
| 5 | 525 | $0.000828 | 1505 | $0.001541 | 2030 | $0.002369 |

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
| 1 | 681 | $0.000986 | 1023 | $0.000920 | 1704 | $0.001906 |
| 2 | 681 | $0.001010 | 983 | $0.000920 | 1664 | $0.001930 |
| 3 | 719 | $0.001002 | 925 | $0.000920 | 1644 | $0.001922 |
| 4 | 709 | $0.000986 | 888 | $0.000920 | 1597 | $0.001906 |
| 5 | 681 | $0.000962 | 922 | $0.000920 | 1603 | $0.001882 |

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
| 1 | 908 | $0.001280 | 1430 | $0.000934 | 2338 | $0.002214 |
| 2 | 989 | $0.001280 | 818 | $0.000934 | 1807 | $0.002214 |
| 3 | 783 | $0.001256 | 922 | $0.000934 | 1705 | $0.002190 |
| 4 | 783 | $0.001312 | 1022 | $0.000934 | 1805 | $0.002246 |
| 5 | 890 | $0.001280 | 890 | $0.000934 | 1780 | $0.002214 |

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
| 1 | 708 | $0.000992 | 1536 | $0.001594 | 2244 | $0.002586 |
| 2 | 879 | $0.001000 | 1841 | $0.001714 | 2720 | $0.002714 |
| 3 | 683 | $0.001000 | 1635 | $0.001684 | 2318 | $0.002684 |
| 4 | 782 | $0.000992 | 1740 | $0.001504 | 2522 | $0.002496 |
| 5 | 679 | $0.000992 | 1331 | $0.001514 | 2010 | $0.002506 |

## Ambiguous / Repeated Span Safety (Naturalness)

### ambiguous-naturalness-span

- Original text: `Vi mucho tráfico, y luego vi más tráfico.`
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Vi mucho tráfico, y luego vi más tráfico.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000878 | 821 | $0.000928 | 1398 | $0.001806 |
| 2 | 680 | $0.000878 | 1125 | $0.000928 | 1805 | $0.001806 |
| 3 | 682 | $0.000878 | 1023 | $0.000928 | 1705 | $0.001806 |
| 4 | 596 | $0.000878 | 901 | $0.000928 | 1497 | $0.001806 |
| 5 | 783 | $0.000878 | 924 | $0.000928 | 1707 | $0.001806 |

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
| 1 | 720 | $0.001296 | 974 | $0.000925 | 1694 | $0.002221 |
| 2 | 1027 | $0.001360 | 1176 | $0.000925 | 2203 | $0.002285 |
| 3 | 913 | $0.001352 | 870 | $0.000925 | 1783 | $0.002277 |
| 4 | 761 | $0.001328 | 1026 | $0.000925 | 1787 | $0.002253 |
| 5 | 958 | $0.001312 | 1002 | $0.000925 | 1960 | $0.002237 |

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
| 1 | 807 | $0.001012 | 979 | $0.000921 | 1786 | $0.001933 |
| 2 | 721 | $0.001012 | 1148 | $0.000921 | 1869 | $0.001933 |
| 3 | 964 | $0.001012 | 940 | $0.000921 | 1904 | $0.001933 |
| 4 | 865 | $0.001012 | 1025 | $0.000921 | 1890 | $0.001933 |
| 5 | 783 | $0.001012 | 3804 | $0.000921 | 4587 | $0.001933 |

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
| 1 | 653 | $0.000996 | 933 | $0.000923 | 1586 | $0.001919 |
| 2 | 682 | $0.000980 | 921 | $0.000923 | 1603 | $0.001903 |
| 3 | 960 | $0.001004 | 948 | $0.000923 | 1908 | $0.001926 |
| 4 | 681 | $0.000988 | 1027 | $0.000923 | 1708 | $0.001910 |
| 5 | 865 | $0.001004 | 945 | $0.000923 | 1810 | $0.001926 |

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
| 1 | 673 | $0.000998 | 922 | $0.000923 | 1595 | $0.001920 |
| 2 | 679 | $0.000982 | 1031 | $0.000923 | 1710 | $0.001904 |
| 3 | 938 | $0.001022 | 884 | $0.000923 | 1822 | $0.001945 |
| 4 | 865 | $0.001022 | 990 | $0.000923 | 1855 | $0.001945 |
| 5 | 695 | $0.000998 | 973 | $0.000923 | 1668 | $0.001920 |

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
| 1 | 711 | $0.001074 | 958 | $0.000926 | 1669 | $0.002000 |
| 2 | 691 | $0.001042 | 826 | $0.000926 | 1517 | $0.001968 |
| 3 | 662 | $0.001042 | 1125 | $0.000926 | 1787 | $0.001968 |
| 4 | 885 | $0.001106 | 923 | $0.000926 | 1808 | $0.002032 |
| 5 | 690 | $0.001082 | 935 | $0.000926 | 1625 | $0.002008 |

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
| 1 | 758 | $0.001044 | 923 | $0.000928 | 1681 | $0.001972 |
| 2 | 1653 | $0.001148 | 1076 | $0.000928 | 2729 | $0.002076 |
| 3 | 985 | $0.001148 | 923 | $0.000928 | 1908 | $0.002076 |
| 4 | 782 | $0.001036 | 899 | $0.000928 | 1681 | $0.001963 |
| 5 | 704 | $0.001148 | 993 | $0.000928 | 1697 | $0.002076 |

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
| 1 | 654 | $0.001080 | 1071 | $0.000924 | 1725 | $0.002004 |
| 2 | 794 | $0.001000 | 1030 | $0.000924 | 1824 | $0.001924 |
| 3 | 732 | $0.001000 | 964 | $0.000924 | 1696 | $0.001924 |
| 4 | 783 | $0.001088 | 1230 | $0.000924 | 2013 | $0.002012 |
| 5 | 783 | $0.001080 | 1545 | $0.000924 | 2328 | $0.002004 |

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
| 1 | 875 | $0.001034 | 880 | $0.000926 | 1755 | $0.001960 |
| 2 | 722 | $0.001042 | 1020 | $0.000926 | 1742 | $0.001968 |
| 3 | 786 | $0.001042 | 920 | $0.000926 | 1706 | $0.001968 |
| 4 | 698 | $0.001042 | 822 | $0.000926 | 1520 | $0.001968 |
| 5 | 686 | $0.001042 | 1534 | $0.000926 | 2220 | $0.001968 |

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
| 1 | 694 | $0.001098 | 944 | $0.000925 | 1638 | $0.002023 |
| 2 | 792 | $0.001106 | 3137 | $0.000925 | 3929 | $0.002031 |
| 3 | 653 | $0.001106 | 957 | $0.000925 | 1610 | $0.002031 |
| 4 | 1218 | $0.001098 | 899 | $0.000925 | 2117 | $0.002023 |
| 5 | 739 | $0.001050 | 848 | $0.000925 | 1587 | $0.001975 |

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
| 1 | 724 | $0.001072 | 974 | $0.000924 | 1698 | $0.001996 |
| 2 | 759 | $0.001072 | 957 | $0.000924 | 1716 | $0.001996 |
| 3 | 675 | $0.001080 | 942 | $0.000924 | 1617 | $0.002004 |
| 4 | 774 | $0.001072 | 1046 | $0.000924 | 1820 | $0.001996 |
| 5 | 596 | $0.001032 | 992 | $0.000924 | 1588 | $0.001956 |

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
| 1 | 631 | $0.001114 | 998 | $0.000926 | 1629 | $0.002040 |
| 2 | 618 | $0.001114 | 840 | $0.000926 | 1458 | $0.002040 |
| 3 | 740 | $0.001114 | 862 | $0.000926 | 1602 | $0.002040 |
| 4 | 644 | $0.001114 | 1124 | $0.000926 | 1768 | $0.002040 |
| 5 | 683 | $0.001114 | 1126 | $0.000926 | 1809 | $0.002040 |

### prep-empresa-en-la-que

- Original text: `La empresa que trabajo está cerca.`
- Expected corrected text: `La empresa en la que trabajo está cerca.`
- Pass rate: 3/5
- Distinct final outputs:
  - `La empresa en que trabajo está cerca.`
  - `La empresa en la que trabajo está cerca.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `La empresa en que trabajo está cerca.` | (none) | `La empresa en que trabajo está cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `La empresa en que trabajo está cerca.` | La empresa en que trabajo -> La empresa en la que trabajo | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 3 | `La empresa en que trabajo está cerca.` | en que trabajo -> en la que trabajo | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 4 | `La empresa en la que trabajo está cerca.` | (none) | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 5 | `La empresa en que trabajo está cerca.` | (none) | `La empresa en que trabajo está cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 782 | $0.001024 | 923 | $0.000925 | 1705 | $0.001949 |
| 2 | 988 | $0.001088 | 1742 | $0.001665 | 2730 | $0.002753 |
| 3 | 769 | $0.001088 | 1513 | $0.001495 | 2282 | $0.002583 |
| 4 | 820 | $0.001104 | 1014 | $0.000926 | 1834 | $0.002030 |
| 5 | 787 | $0.001088 | 1022 | $0.000925 | 1809 | $0.002013 |

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
| 1 | 701 | $0.001114 | 898 | $0.000926 | 1599 | $0.002040 |
| 2 | 685 | $0.001114 | 1019 | $0.000926 | 1704 | $0.002040 |
| 3 | 976 | $0.001114 | 1134 | $0.000926 | 2110 | $0.002040 |
| 4 | 685 | $0.001050 | 800 | $0.000926 | 1485 | $0.001976 |
| 5 | 805 | $0.001114 | 919 | $0.000926 | 1724 | $0.002040 |

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
| 1 | 2727 | $0.001088 | 880 | $0.000925 | 3607 | $0.002013 |
| 2 | 827 | $0.001088 | 920 | $0.000925 | 1747 | $0.002013 |
| 3 | 784 | $0.001088 | 922 | $0.000925 | 1706 | $0.002013 |
| 4 | 759 | $0.001088 | 943 | $0.000925 | 1702 | $0.002013 |
| 5 | 783 | $0.001088 | 1260 | $0.000925 | 2043 | $0.002013 |

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
| 1 | 748 | $0.001088 | 923 | $0.000925 | 1671 | $0.002013 |
| 2 | 665 | $0.001088 | 1046 | $0.000925 | 1711 | $0.002013 |
| 3 | 876 | $0.001088 | 1024 | $0.000925 | 1900 | $0.002013 |
| 4 | 632 | $0.001088 | 1178 | $0.000925 | 1810 | $0.002013 |
| 5 | 783 | $0.001088 | 928 | $0.000925 | 1711 | $0.002013 |

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
| 1 | 980 | $0.001036 | 1030 | $0.000923 | 2010 | $0.001959 |
| 2 | 674 | $0.001028 | 1044 | $0.000923 | 1718 | $0.001950 |
| 3 | 658 | $0.001028 | 880 | $0.000923 | 1538 | $0.001950 |
| 4 | 558 | $0.001028 | 1196 | $0.000923 | 1754 | $0.001950 |
| 5 | 671 | $0.001028 | 1051 | $0.000923 | 1722 | $0.001950 |

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
| 1 | 654 | $0.001042 | 1125 | $0.000926 | 1779 | $0.001968 |
| 2 | 715 | $0.001042 | 1137 | $0.000926 | 1852 | $0.001968 |
| 3 | 741 | $0.001042 | 1017 | $0.000926 | 1758 | $0.001968 |
| 4 | 606 | $0.001042 | 918 | $0.000926 | 1524 | $0.001968 |
| 5 | 611 | $0.001042 | 866 | $0.000926 | 1477 | $0.001968 |

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
| 1 | 784 | $0.001094 | 989 | $0.000925 | 1773 | $0.002019 |
| 2 | 714 | $0.001070 | 888 | $0.000925 | 1602 | $0.001995 |
| 3 | 565 | $0.001070 | 864 | $0.000925 | 1429 | $0.001995 |
| 4 | 707 | $0.001070 | 1002 | $0.000925 | 1709 | $0.001995 |
| 5 | 786 | $0.001142 | 1082 | $0.000925 | 1868 | $0.002067 |

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
| 1 | 683 | $0.001106 | 1059 | $0.000926 | 1742 | $0.002032 |
| 2 | 677 | $0.001026 | 1025 | $0.000926 | 1702 | $0.001952 |
| 3 | 887 | $0.001106 | 1022 | $0.000926 | 1909 | $0.002032 |
| 4 | 886 | $0.001026 | 1126 | $0.000926 | 2012 | $0.001952 |
| 5 | 626 | $0.001026 | 1084 | $0.000926 | 1710 | $0.001952 |

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
| 1 | 777 | $0.001070 | 1059 | $0.000925 | 1836 | $0.001995 |
| 2 | 851 | $0.001070 | 1023 | $0.000925 | 1874 | $0.001995 |
| 3 | 780 | $0.001070 | 975 | $0.000925 | 1755 | $0.001995 |
| 4 | 832 | $0.001070 | 1494 | $0.000925 | 2326 | $0.001995 |
| 5 | 789 | $0.001070 | 1058 | $0.000925 | 1847 | $0.001995 |

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
| 1 | 625 | $0.001046 | 976 | $0.000923 | 1601 | $0.001969 |
| 2 | 733 | $0.001062 | 972 | $0.000923 | 1705 | $0.001985 |
| 3 | 781 | $0.001030 | 1129 | $0.000923 | 1910 | $0.001953 |
| 4 | 680 | $0.001054 | 1022 | $0.000923 | 1702 | $0.001976 |
| 5 | 816 | $0.001070 | 1003 | $0.000923 | 1819 | $0.001992 |

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
| 1 | 875 | $0.001022 | 1159 | $0.000923 | 2034 | $0.001945 |
| 2 | 718 | $0.001022 | 952 | $0.000923 | 1670 | $0.001945 |
| 3 | 682 | $0.001030 | 982 | $0.000923 | 1664 | $0.001953 |
| 4 | 1135 | $0.001038 | 1123 | $0.000923 | 2258 | $0.001961 |
| 5 | 783 | $0.001022 | 1023 | $0.000923 | 1806 | $0.001945 |

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
| 1 | 775 | $0.001096 | 1045 | $0.000924 | 1820 | $0.002020 |
| 2 | 1141 | $0.001064 | 1015 | $0.000924 | 2156 | $0.001988 |
| 3 | 743 | $0.001128 | 872 | $0.000924 | 1615 | $0.002052 |
| 4 | 712 | $0.001128 | 925 | $0.000924 | 1637 | $0.002052 |
| 5 | 642 | $0.001048 | 896 | $0.000924 | 1538 | $0.001972 |

### subj-enviara

- Original text: `Era necesario que enviaba su parte.`
- Expected corrected text: `Era necesario que enviara su parte.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Era necesario que enviara su parte.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 2 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 3 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 4 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |
| 5 | `Era necesario que enviara su parte.` | (none) | `Era necesario que enviara su parte.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 720 | $0.001034 | 938 | $0.000925 | 1658 | $0.001959 |
| 2 | 637 | $0.001026 | 970 | $0.000925 | 1607 | $0.001951 |
| 3 | 781 | $0.001082 | 961 | $0.000925 | 1742 | $0.002007 |
| 4 | 946 | $0.001082 | 922 | $0.000925 | 1868 | $0.002007 |
| 5 | 714 | $0.001090 | 1022 | $0.000925 | 1736 | $0.002015 |

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
| 1 | 591 | $0.001066 | 1493 | $0.000926 | 2084 | $0.001992 |
| 2 | 625 | $0.001066 | 966 | $0.000926 | 1591 | $0.001992 |
| 3 | 704 | $0.001066 | 1116 | $0.000926 | 1820 | $0.001992 |
| 4 | 612 | $0.001074 | 1195 | $0.000926 | 1807 | $0.002000 |
| 5 | 600 | $0.001106 | 1002 | $0.000926 | 1602 | $0.002032 |

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
| 1 | 726 | $0.001054 | 881 | $0.000924 | 1607 | $0.001978 |
| 2 | 729 | $0.001054 | 1070 | $0.000924 | 1799 | $0.001978 |
| 3 | 746 | $0.001054 | 958 | $0.000924 | 1704 | $0.001978 |
| 4 | 662 | $0.001054 | 881 | $0.000924 | 1543 | $0.001978 |
| 5 | 598 | $0.001078 | 1063 | $0.000924 | 1661 | $0.002002 |

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
| 1 | 781 | $0.001104 | 1231 | $0.000925 | 2012 | $0.002029 |
| 2 | 769 | $0.001088 | 1049 | $0.000925 | 1818 | $0.002013 |
| 3 | 737 | $0.001088 | 1260 | $0.000925 | 1997 | $0.002013 |
| 4 | 859 | $0.001088 | 914 | $0.000925 | 1773 | $0.002013 |
| 5 | 1123 | $0.001088 | 1021 | $0.000925 | 2144 | $0.002013 |

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
| 1 | 787 | $0.001088 | 920 | $0.000925 | 1707 | $0.002013 |
| 2 | 881 | $0.001120 | 906 | $0.000925 | 1787 | $0.002045 |
| 3 | 751 | $0.001128 | 1073 | $0.000925 | 1824 | $0.002053 |
| 4 | 887 | $0.001056 | 955 | $0.000925 | 1842 | $0.001981 |
| 5 | 647 | $0.001120 | 922 | $0.000925 | 1569 | $0.002045 |

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
| 1 | 1117 | $0.001070 | 1097 | $0.000923 | 2214 | $0.001992 |
| 2 | 1847 | $0.001062 | 881 | $0.000923 | 2728 | $0.001985 |
| 3 | 624 | $0.001070 | 1077 | $0.000923 | 1701 | $0.001992 |
| 4 | 784 | $0.001070 | 1127 | $0.000923 | 1911 | $0.001992 |
| 5 | 752 | $0.001070 | 951 | $0.000923 | 1703 | $0.001992 |

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
| 1 | 785 | $0.001086 | 1024 | $0.000924 | 1809 | $0.002010 |
| 2 | 781 | $0.001062 | 1048 | $0.000924 | 1829 | $0.001986 |
| 3 | 654 | $0.001070 | 943 | $0.000924 | 1597 | $0.001994 |
| 4 | 965 | $0.001062 | 1024 | $0.000924 | 1989 | $0.001986 |
| 5 | 887 | $0.001078 | 1023 | $0.000924 | 1910 | $0.002002 |

## Unnecessary Extras / Deletions

### delete-repeated-yo-estudio

- Original text: `Yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Yo trabajo mucho y yo estudio por las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 4 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 5 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 847 | $0.000878 | 1127 | $0.000928 | 1974 | $0.001806 |
| 2 | 717 | $0.000878 | 1229 | $0.000928 | 1946 | $0.001806 |
| 3 | 777 | $0.000878 | 1131 | $0.000928 | 1908 | $0.001806 |
| 4 | 783 | $0.000878 | 1023 | $0.000928 | 1806 | $0.001806 |
| 5 | 681 | $0.000878 | 1227 | $0.000928 | 1908 | $0.001806 |

### delete-repeated-ellos-visitaron

- Original text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Expected corrected text: `Ellos viajaron a México y visitaron varias ciudades.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Ellos viajaron a México y ellos visitaron varias ciudades.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 4 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 5 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1514 | $0.000908 | 960 | $0.000931 | 2474 | $0.001839 |
| 2 | 642 | $0.000908 | 961 | $0.000931 | 1603 | $0.001839 |
| 3 | 627 | $0.000908 | 1126 | $0.000931 | 1753 | $0.001839 |
| 4 | 569 | $0.000908 | 1053 | $0.000931 | 1622 | $0.001839 |
| 5 | 660 | $0.000908 | 1129 | $0.000931 | 1789 | $0.001839 |

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
| 1 | 883 | $0.001108 | 1024 | $0.000924 | 1907 | $0.002032 |
| 2 | 781 | $0.001140 | 1124 | $0.000924 | 1905 | $0.002064 |
| 3 | 992 | $0.001116 | 1025 | $0.000924 | 2017 | $0.002040 |
| 4 | 955 | $0.001092 | 823 | $0.000924 | 1778 | $0.002016 |
| 5 | 706 | $0.001092 | 1228 | $0.000924 | 1934 | $0.002016 |

### delete-repeated-yo-compre

- Original text: `Yo fui al mercado y yo compré pan.`
- Expected corrected text: `Fui al mercado y compré pan.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Yo fui al mercado y yo compré pan.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo fui al mercado y yo compré pan.` | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Yo fui al mercado y yo compré pan.` | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Yo fui al mercado y yo compré pan.` | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 4 | `Yo fui al mercado y yo compré pan.` | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 5 | `Yo fui al mercado y yo compré pan.` | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 593 | $0.000878 | 1076 | $0.000928 | 1669 | $0.001806 |
| 2 | 717 | $0.000878 | 1134 | $0.000928 | 1851 | $0.001806 |
| 3 | 535 | $0.000878 | 1070 | $0.000928 | 1605 | $0.001806 |
| 4 | 769 | $0.000878 | 919 | $0.000928 | 1688 | $0.001806 |
| 5 | 514 | $0.000878 | 1089 | $0.000928 | 1603 | $0.001806 |

### delete-repeated-nosotros

- Original text: `Nosotros salimos temprano y nosotros llegamos a tiempo.`
- Expected corrected text: `Nosotros salimos temprano y llegamos a tiempo.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Nosotros salimos temprano y nosotros llegamos a tiempo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 4 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 5 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 683 | $0.000898 | 1125 | $0.000930 | 1808 | $0.001828 |
| 2 | 693 | $0.000898 | 1433 | $0.000930 | 2126 | $0.001828 |
| 3 | 563 | $0.000898 | 1025 | $0.000930 | 1588 | $0.001828 |
| 4 | 684 | $0.000898 | 955 | $0.000930 | 1639 | $0.001828 |
| 5 | 933 | $0.000898 | 920 | $0.000930 | 1853 | $0.001828 |

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
| 1 | 683 | $0.001004 | 936 | $0.000921 | 1619 | $0.001925 |
| 2 | 785 | $0.001004 | 921 | $0.000921 | 1706 | $0.001925 |
| 3 | 884 | $0.001028 | 1026 | $0.000921 | 1910 | $0.001949 |
| 4 | 676 | $0.001004 | 1034 | $0.000921 | 1710 | $0.001925 |
| 5 | 883 | $0.000988 | 912 | $0.000921 | 1795 | $0.001909 |

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
| 1 | 783 | $0.001064 | 1226 | $0.000924 | 2009 | $0.001988 |
| 2 | 695 | $0.001064 | 895 | $0.000924 | 1590 | $0.001988 |
| 3 | 693 | $0.001064 | 936 | $0.000924 | 1629 | $0.001988 |
| 4 | 600 | $0.001072 | 986 | $0.000924 | 1586 | $0.001996 |
| 5 | 781 | $0.001064 | 922 | $0.000924 | 1703 | $0.001988 |

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
| 1 | 785 | $0.001064 | 1023 | $0.000924 | 1808 | $0.001988 |
| 2 | 781 | $0.001080 | 989 | $0.000924 | 1770 | $0.002004 |
| 3 | 917 | $0.001080 | 998 | $0.000924 | 1915 | $0.002004 |
| 4 | 773 | $0.001024 | 1062 | $0.000924 | 1835 | $0.001948 |
| 5 | 886 | $0.001064 | 1027 | $0.000924 | 1913 | $0.001988 |

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
| 1 | 516 | $0.000858 | 892 | $0.000925 | 1408 | $0.001783 |
| 2 | 539 | $0.000858 | 945 | $0.000925 | 1484 | $0.001783 |
| 3 | 582 | $0.000858 | 915 | $0.000925 | 1497 | $0.001783 |
| 4 | 578 | $0.000858 | 1023 | $0.000925 | 1601 | $0.001783 |
| 5 | 578 | $0.000858 | 921 | $0.000925 | 1499 | $0.001783 |

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
| 1 | 549 | $0.000858 | 898 | $0.000925 | 1447 | $0.001783 |
| 2 | 519 | $0.000858 | 1034 | $0.000925 | 1553 | $0.001783 |
| 3 | 782 | $0.000858 | 988 | $0.000925 | 1770 | $0.001783 |
| 4 | 717 | $0.000858 | 1229 | $0.000925 | 1946 | $0.001783 |
| 5 | 739 | $0.000858 | 857 | $0.000925 | 1596 | $0.001783 |

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
| 1 | 786 | $0.001106 | 807 | $0.000925 | 1593 | $0.002031 |
| 2 | 759 | $0.001098 | 954 | $0.000925 | 1713 | $0.002023 |
| 3 | 682 | $0.001106 | 920 | $0.000925 | 1602 | $0.002031 |
| 4 | 761 | $0.001122 | 943 | $0.000925 | 1704 | $0.002047 |
| 5 | 678 | $0.001098 | 923 | $0.000925 | 1601 | $0.002023 |

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
| 1 | 766 | $0.001050 | 937 | $0.000925 | 1703 | $0.001975 |
| 2 | 782 | $0.001098 | 1128 | $0.000925 | 1910 | $0.002023 |
| 3 | 697 | $0.001098 | 904 | $0.000925 | 1601 | $0.002023 |
| 4 | 781 | $0.001050 | 924 | $0.000925 | 1705 | $0.001975 |
| 5 | 715 | $0.001050 | 1294 | $0.000925 | 2009 | $0.001975 |

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
| 1 | 783 | $0.001080 | 921 | $0.000924 | 1704 | $0.002004 |
| 2 | 649 | $0.001080 | 854 | $0.000924 | 1503 | $0.002004 |
| 3 | 604 | $0.001080 | 905 | $0.000924 | 1509 | $0.002004 |
| 4 | 691 | $0.001096 | 1002 | $0.000924 | 1693 | $0.002020 |
| 5 | 783 | $0.001064 | 818 | $0.000924 | 1601 | $0.001988 |

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
| 1 | 733 | $0.001090 | 1074 | $0.000925 | 1807 | $0.002015 |
| 2 | 593 | $0.001130 | 905 | $0.000925 | 1498 | $0.002055 |
| 3 | 764 | $0.001106 | 940 | $0.000925 | 1704 | $0.002031 |
| 4 | 800 | $0.001090 | 856 | $0.000925 | 1656 | $0.002015 |
| 5 | 732 | $0.001106 | 815 | $0.000925 | 1547 | $0.002031 |

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
| 1 | 808 | $0.001072 | 895 | $0.000924 | 1703 | $0.001996 |
| 2 | 817 | $0.001072 | 975 | $0.000924 | 1792 | $0.001996 |
| 3 | 696 | $0.001072 | 920 | $0.000924 | 1616 | $0.001996 |
| 4 | 787 | $0.001072 | 919 | $0.000924 | 1706 | $0.001996 |
| 5 | 681 | $0.001064 | 878 | $0.000924 | 1559 | $0.001988 |

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
| 1 | 780 | $0.001114 | 835 | $0.000926 | 1615 | $0.002040 |
| 2 | 780 | $0.001106 | 836 | $0.000926 | 1616 | $0.002032 |
| 3 | 756 | $0.001146 | 1022 | $0.000926 | 1778 | $0.002072 |
| 4 | 680 | $0.001106 | 1023 | $0.000926 | 1703 | $0.002032 |
| 5 | 761 | $0.001106 | 1249 | $0.000926 | 2010 | $0.002032 |

### false-friend-aplico-trabajo

- Original text: `Aplicó para un trabajo.`
- Expected corrected text: `Solicitó un trabajo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Solicitó un trabajo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Aplicó para un trabajo.` | Aplicó para un trabajo. -> Solicitó un trabajo. | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Aplicó a un trabajo.` | Aplicó a un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Aplicó para un trabajo.` | Aplicó para un trabajo. -> Solicitó un trabajo. | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 682 | $0.000838 | 1841 | $0.001633 | 2523 | $0.002471 |
| 2 | 578 | $0.000838 | 1719 | $0.001672 | 2297 | $0.002510 |
| 3 | 907 | $0.001014 | 2149 | $0.001833 | 3056 | $0.002847 |
| 4 | 515 | $0.000838 | 1419 | $0.001613 | 1934 | $0.002450 |
| 5 | 549 | $0.000838 | 2050 | $0.002203 | 2599 | $0.003040 |

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
| 1 | 692 | $0.001122 | 1115 | $0.000926 | 1807 | $0.002048 |
| 2 | 675 | $0.001114 | 1132 | $0.000926 | 1807 | $0.002040 |
| 3 | 840 | $0.001122 | 880 | $0.000926 | 1720 | $0.002048 |
| 4 | 771 | $0.001130 | 816 | $0.000926 | 1587 | $0.002056 |
| 5 | 781 | $0.001122 | 1025 | $0.000926 | 1806 | $0.002048 |

### false-friend-embarazado

- Original text: `Estoy embarazado por llegar tarde.`
- Expected corrected text: `Me da vergüenza llegar tarde.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Estoy avergonzada por llegar tarde.`
  - `Estoy avergonzado por llegar tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy embarazada por llegar tarde.` | embarazada por llegar tarde -> avergonzada por llegar tarde | `Estoy avergonzada por llegar tarde.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 4 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy embarazada por llegar tarde.` | embarazada por llegar tarde -> avergonzada por llegar tarde | `Estoy avergonzada por llegar tarde.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1702 | $0.001074 | 2562 | $0.001984 | 4264 | $0.003058 |
| 2 | 697 | $0.001058 | 975 | $0.000926 | 1672 | $0.001984 |
| 3 | 679 | $0.001138 | 850 | $0.000926 | 1529 | $0.002064 |
| 4 | 681 | $0.001138 | 922 | $0.000926 | 1603 | $0.002064 |
| 5 | 681 | $0.001010 | 1919 | $0.001904 | 2600 | $0.002914 |

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
| 1 | 560 | $0.000828 | 862 | $0.000921 | 1422 | $0.001749 |
| 2 | 577 | $0.000828 | 944 | $0.000921 | 1521 | $0.001749 |
| 3 | 711 | $0.000828 | 1073 | $0.000921 | 1784 | $0.001749 |
| 4 | 683 | $0.000828 | 906 | $0.000921 | 1589 | $0.001749 |
| 5 | 694 | $0.000828 | 1330 | $0.000921 | 2024 | $0.001749 |

## Phrase-Level Naturalness

### naturalness-buen-tiempo

- Original text: `Tuvimos un buen tiempo.`
- Expected corrected text: `Lo pasamos bien.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Tuvimos un buen rato.`
  - `Lo pasamos bien.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 2 | `Tuvimos un buen tiempo.` | Tuvimos un buen tiempo. -> Lo pasamos bien. | `Lo pasamos bien.` | correct_fix | Pass | Matches expected output. |
| 3 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 4 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |
| 5 | `Tuvimos un buen tiempo.` | un buen tiempo -> un buen rato | `Tuvimos un buen rato.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 576 | $0.000848 | 1641 | $0.001794 | 2217 | $0.002642 |
| 2 | 556 | $0.000848 | 1761 | $0.001724 | 2317 | $0.002572 |
| 3 | 749 | $0.000848 | 1774 | $0.001854 | 2523 | $0.002702 |
| 4 | 884 | $0.000848 | 1639 | $0.001844 | 2523 | $0.002692 |
| 5 | 575 | $0.000848 | 2049 | $0.001674 | 2624 | $0.002522 |

### naturalness-corriendo-tarde

- Original text: `Estoy corriendo tarde para la reunión.`
- Expected corrected text: `Voy tarde a la reunión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Voy a llegar tarde a la reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión -> Voy a llegar tarde a la reunión | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 4 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy llegando tarde para la reunión.` | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | `Voy a llegar tarde a la reunión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 575 | $0.001098 | 2050 | $0.002054 | 2625 | $0.003152 |
| 2 | 681 | $0.001082 | 2558 | $0.001914 | 3239 | $0.002996 |
| 3 | 749 | $0.001074 | 1935 | $0.001804 | 2684 | $0.002878 |
| 4 | 979 | $0.001098 | 1854 | $0.001834 | 2833 | $0.002932 |
| 5 | 822 | $0.001114 | 1649 | $0.001864 | 2471 | $0.002978 |

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
| 1 | 771 | $0.001072 | 1093 | $0.000924 | 1864 | $0.001996 |
| 2 | 714 | $0.001056 | 1025 | $0.000924 | 1739 | $0.001980 |
| 3 | 782 | $0.001032 | 856 | $0.000924 | 1638 | $0.001956 |
| 4 | 849 | $0.001040 | 1021 | $0.000924 | 1870 | $0.001964 |
| 5 | 819 | $0.001040 | 1091 | $0.000924 | 1910 | $0.001964 |

### naturalness-puedo-tener-cerveza

- Original text: `¿Puedo tener una cerveza?`
- Expected corrected text: `¿Me pones una cerveza?`
- Pass rate: 0/5
- Distinct final outputs:
  - `¿Puedo tener una cerveza?`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `¿Puedo tener una cerveza?` | (none) | `¿Puedo tener una cerveza?` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `¿Puedo tener una cerveza?` | (none) | `¿Puedo tener una cerveza?` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `¿Puedo tener una cerveza?` | (none) | `¿Puedo tener una cerveza?` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 4 | `¿Puedo tener una cerveza?` | (none) | `¿Puedo tener una cerveza?` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 5 | `¿Puedo tener una cerveza?` | (none) | `¿Puedo tener una cerveza?` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 516 | $0.000856 | 1059 | $0.000924 | 1575 | $0.001780 |
| 2 | 610 | $0.000856 | 1018 | $0.000924 | 1628 | $0.001780 |
| 3 | 547 | $0.000856 | 1054 | $0.000924 | 1601 | $0.001780 |
| 4 | 681 | $0.000856 | 1027 | $0.000924 | 1708 | $0.001780 |
| 5 | 544 | $0.000856 | 952 | $0.000924 | 1496 | $0.001780 |

### naturalness-llamar-para-atras

- Original text: `Te llamo para atrás.`
- Expected corrected text: `Te devuelvo la llamada.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Te llamo de vuelta.`
  - `Te llamo después.`
  - `Te llamo más tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Te llamo de vuelta.` | (none) | `Te llamo de vuelta.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Te llamo para atrás.` | para atrás -> después | `Te llamo después.` | correct_fix | Pass | Matches expected output. |
| 3 | `Te llamo de vuelta.` | de vuelta -> más tarde | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |
| 4 | `Te llamo para atrás.` | para atrás -> más tarde | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Te llamo para atrás.` | para atrás -> más tarde | `Te llamo más tarde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 604 | $0.001014 | 998 | $0.000923 | 1602 | $0.001937 |
| 2 | 558 | $0.000838 | 1815 | $0.001833 | 2373 | $0.002671 |
| 3 | 864 | $0.001006 | 1540 | $0.001733 | 2404 | $0.002739 |
| 4 | 757 | $0.000838 | 2037 | $0.001783 | 2794 | $0.002620 |
| 5 | 534 | $0.000838 | 1890 | $0.001783 | 2424 | $0.002620 |

## Valid Regional / Should Not Flag

### regional-voy-para-casa

- Original text: `Voy para casa ahora mismo.`
- Expected corrected text: `Voy para casa ahora mismo.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Voy para la casa ahora mismo.`
  - `Voy a casa ahora mismo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Voy para la casa ahora mismo.` | (none) | `Voy para la casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Voy para la casa ahora mismo.` | para la casa -> a casa | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Voy para la casa ahora mismo.` | Voy para la casa ahora mismo. -> Voy a casa ahora mismo. | `Voy a casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 679 | $0.001006 | 923 | $0.000924 | 1602 | $0.001930 |
| 2 | 677 | $0.001054 | 1741 | $0.001694 | 2418 | $0.002748 |
| 3 | 679 | $0.001054 | 1727 | $0.001634 | 2406 | $0.002688 |
| 4 | 697 | $0.001062 | 2179 | $0.001934 | 2876 | $0.002996 |
| 5 | 853 | $0.001014 | 2048 | $0.002034 | 2901 | $0.003048 |

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
| 1 | 682 | $0.000828 | 1023 | $0.000921 | 1705 | $0.001749 |
| 2 | 660 | $0.000828 | 945 | $0.000921 | 1605 | $0.001749 |
| 3 | 679 | $0.000828 | 1023 | $0.000921 | 1702 | $0.001749 |
| 4 | 1249 | $0.000828 | 966 | $0.000921 | 2215 | $0.001749 |
| 5 | 896 | $0.000828 | 910 | $0.000921 | 1806 | $0.001749 |

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
| 1 | 682 | $0.000858 | 1126 | $0.000925 | 1808 | $0.001783 |
| 2 | 578 | $0.000858 | 971 | $0.000925 | 1549 | $0.001783 |
| 3 | 660 | $0.000858 | 993 | $0.000925 | 1653 | $0.001783 |
| 4 | 679 | $0.000858 | 878 | $0.000925 | 1557 | $0.001783 |
| 5 | 626 | $0.000858 | 1004 | $0.000925 | 1630 | $0.001783 |

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
| 1 | 568 | $0.000858 | 959 | $0.000925 | 1527 | $0.001783 |
| 2 | 1078 | $0.000858 | 922 | $0.000925 | 2000 | $0.001783 |
| 3 | 785 | $0.000858 | 1022 | $0.000925 | 1807 | $0.001783 |
| 4 | 576 | $0.000858 | 1018 | $0.000925 | 1594 | $0.001783 |
| 5 | 586 | $0.000858 | 1023 | $0.000925 | 1609 | $0.001783 |

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
| 1 | 579 | $0.000858 | 924 | $0.000925 | 1503 | $0.001783 |
| 2 | 2750 | $0.000858 | 1572 | $0.000925 | 4322 | $0.001783 |
| 3 | 618 | $0.000858 | 922 | $0.000925 | 1540 | $0.001783 |
| 4 | 785 | $0.000858 | 886 | $0.000925 | 1671 | $0.001783 |
| 5 | 517 | $0.000858 | 912 | $0.000925 | 1429 | $0.001783 |

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
| 1 | 581 | $0.000856 | 918 | $0.000924 | 1499 | $0.001780 |
| 2 | 683 | $0.000856 | 975 | $0.000924 | 1658 | $0.001780 |
| 3 | 615 | $0.000856 | 1341 | $0.000924 | 1956 | $0.001780 |
| 4 | 1605 | $0.000856 | 1193 | $0.000924 | 2798 | $0.001780 |
| 5 | 918 | $0.000856 | 948 | $0.000924 | 1866 | $0.001780 |

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
| 1 | 821 | $0.000858 | 863 | $0.000925 | 1684 | $0.001783 |
| 2 | 1571 | $0.000858 | 934 | $0.000925 | 2505 | $0.001783 |
| 3 | 690 | $0.000858 | 982 | $0.000925 | 1672 | $0.001783 |
| 4 | 617 | $0.000858 | 994 | $0.000925 | 1611 | $0.001783 |
| 5 | 633 | $0.000858 | 999 | $0.000925 | 1632 | $0.001783 |

### correct-tomar-foto

- Original text: `Necesito tomar una foto del documento.`
- Expected corrected text: `Necesito tomar una foto del documento.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Necesito tomar una foto del documento.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 4 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Necesito tomar una foto del documento.` | (none) | `Necesito tomar una foto del documento.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 587 | $0.000858 | 907 | $0.000925 | 1494 | $0.001783 |
| 2 | 644 | $0.000858 | 1067 | $0.000925 | 1711 | $0.001783 |
| 3 | 642 | $0.000858 | 860 | $0.000925 | 1502 | $0.001783 |
| 4 | 677 | $0.000858 | 873 | $0.000925 | 1550 | $0.001783 |
| 5 | 714 | $0.000858 | 845 | $0.000925 | 1559 | $0.001783 |

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
| 1 | 567 | $0.000878 | 1017 | $0.000928 | 1584 | $0.001806 |
| 2 | 790 | $0.000878 | 1024 | $0.000928 | 1814 | $0.001806 |
| 3 | 577 | $0.000878 | 1128 | $0.000928 | 1705 | $0.001806 |
| 4 | 666 | $0.000878 | 1039 | $0.000928 | 1705 | $0.001806 |
| 5 | 587 | $0.000878 | 1000 | $0.000928 | 1587 | $0.001806 |

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
| 1 | 697 | $0.000908 | 918 | $0.000931 | 1615 | $0.001839 |
| 2 | 588 | $0.000908 | 914 | $0.000931 | 1502 | $0.001839 |
| 3 | 474 | $0.000908 | 923 | $0.000931 | 1397 | $0.001839 |
| 4 | 525 | $0.000908 | 972 | $0.000931 | 1497 | $0.001839 |
| 5 | 576 | $0.000908 | 821 | $0.000931 | 1397 | $0.001839 |

## Mixed Operations

### mixed-preposition-and-redundant-pronoun

- Original text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.`
  - `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches. -> Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 738 | $0.001224 | 1706 | $0.001860 | 2444 | $0.003084 |
| 2 | 833 | $0.001224 | 904 | $0.000940 | 1737 | $0.002164 |
| 3 | 723 | $0.001224 | 1024 | $0.000940 | 1747 | $0.002164 |
| 4 | 860 | $0.001224 | 969 | $0.000940 | 1829 | $0.002164 |
| 5 | 832 | $0.001224 | 927 | $0.000940 | 1759 | $0.002164 |

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
| 1 | 1116 | $0.001474 | 839 | $0.000939 | 1955 | $0.002413 |
| 2 | 848 | $0.001498 | 822 | $0.000939 | 1670 | $0.002437 |
| 3 | 1304 | $0.001474 | 940 | $0.000939 | 2244 | $0.002413 |
| 4 | 1177 | $0.001498 | 908 | $0.000939 | 2085 | $0.002437 |
| 5 | 762 | $0.001490 | 1463 | $0.000939 | 2225 | $0.002429 |

### mixed-personal-a-and-subjunctive

- Original text: `Vi mi profesor en la estación, y recordé que es importante que estudio.`
- Expected corrected text: `Vi a mi profesor en la estación, y recordé que es importante que estudie.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Vi a mi profesor en la estación, y recordé que es importante que estudie.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | correct_fix | Pass | Matches expected output. |
| 2 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | correct_fix | Pass | Matches expected output. |
| 3 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | correct_fix | Pass | Matches expected output. |
| 4 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | correct_fix | Pass | Matches expected output. |
| 5 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1001 | $0.001442 | 905 | $0.000938 | 1906 | $0.002380 |
| 2 | 888 | $0.001322 | 988 | $0.000938 | 1876 | $0.002259 |
| 3 | 921 | $0.001354 | 919 | $0.000938 | 1840 | $0.002292 |
| 4 | 886 | $0.001378 | 922 | $0.000938 | 1808 | $0.002315 |
| 5 | 988 | $0.001434 | 862 | $0.000938 | 1850 | $0.002371 |

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
| 1 | 843 | $0.001328 | 1025 | $0.000931 | 1868 | $0.002259 |
| 2 | 881 | $0.001368 | 854 | $0.000931 | 1735 | $0.002299 |
| 3 | 1060 | $0.001328 | 1020 | $0.000931 | 2080 | $0.002259 |
| 4 | 781 | $0.001288 | 921 | $0.000931 | 1702 | $0.002219 |
| 5 | 768 | $0.001288 | 936 | $0.000931 | 1704 | $0.002219 |

### mixed-verb-agreement-and-missing-que

- Original text: `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.`
- Expected corrected text: `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | correct_fix | Pass | Matches expected output. |
| 2 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | correct_fix | Pass | Matches expected output. |
| 4 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 861 | $0.001388 | 940 | $0.000938 | 1801 | $0.002325 |
| 2 | 712 | $0.001452 | 1256 | $0.000938 | 1968 | $0.002390 |
| 3 | 805 | $0.001460 | 846 | $0.000938 | 1651 | $0.002397 |
| 4 | 884 | $0.001436 | 1028 | $0.000938 | 1912 | $0.002374 |
| 5 | 881 | $0.001452 | 851 | $0.000938 | 1732 | $0.002390 |

---

## Overall summary

| Metric | Value |
| --- | --- |
| Fixtures | 85 |
| Total runs | 425 |
| Pass rate | 385/425 |

### Score breakdown (issue #129 — full taxonomy, not only pass/fail)

| | Total | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| All runs | 425 | 320 | 9 | 25 | 5 | 65 | 1 | 0 |

### Latency / cost by pass (issue #130 — no fallback phase exists in this harness, so totals equal Pass 1 + Pass 2 only)

| Phase | Total latency (ms) | Total est. cost (USD) |
| --- | --- | --- |
| Pass 1 (first pass) | 329172 | $0.444482 |
| Pass 2 (lexical review) | 463642 | $0.424821 |
| **Total (Pass 1 + Pass 2)** | 792814 | $0.869303 |
