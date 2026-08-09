# Two-Pass Linear (Serial) Execution Flow (issue #128)

## Methodology (issue #132)

**This is a proof-of-concept report for a SERIAL two-pass architecture, not the production parallel/fallback pipeline.** Numbers here describe a prototype under evaluation, not production behavior — for the production-equivalent pipeline's own report, see `buildLinearPipelineComparisonReport` (linear vs. parallel, side by side) or `two_pass_fallback_pipeline_comparison_harness.dart`'s reports.

- **Pass 1** corrects grammar, spelling, and punctuation using the revised first-pass prompt (issue #126, `linearFirstPassPrompt`, sourced from `Two-Pass_Prompt_Revision_Summary.docx`) with model `gpt-4.1`.
- **Pass 2** is a lexical-transfer review using the revised second-pass prompt (issue #127, `linearSecondPassPrompt`, same source document) with model `gpt-5.5`. Pass 2 reviews Pass 1's OWN corrected text, never the original submitted text.
- **No fallback path**: production's parallel pipeline re-runs naturalness against the first-pass output only when its concurrent merge conflicts. This serial flow never needs that — Pass 2 always reviews the exact text it will be merged into, so there is nothing left to fall back from.
- **No parallel merge step**: Pass 1 and Pass 2 run one after another, never concurrently, so there are never two independent naturalness calls to reconcile the way production's pipeline has.
- **Purpose**: measure whether this simpler serial architecture is as reliable, as fast, and as cheap as production's parallel + conditional-fallback design.

## Run configuration

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.5`
- Fixture count: `85`
- Total runs: `425`
- Generated: 2026-08-08T19:46:47.948218Z

## Fixture summary

Pass rate is `passed/runs`; "distinct outputs" lists every unique final output produced across a fixture's runs — more than one entry means the model was not stable for that fixture.

| Fixture | Language point | Runs | Pass rate | Distinct final outputs | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| clean-grammar-only | Accents / Diacritics | 5 | 1/5 | `Había mucho tráfico ayer.`; `Vi mucho tráfico ayer.` | 29089 | $0.053780 |
| naturalness-only | Collocations / Strong Calques | 5 | 5/5 | `Voy a tomar una decisión importante.` | 9337 | $0.020410 |
| grammar-and-naturalness-independent | Accents / Diacritics + Collocations / Strong Calques (independent spans) | 5 | 5/5 | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | 12196 | $0.025150 |
| grammar-overlaps-naturalness | Verb Morphology (spelling) overlapping Collocations / Strong Calques | 5 | 5/5 | `Ayer tomó una decisión importante.` | 14558 | $0.032530 |
| ambiguous-naturalness-span | Ambiguous / Repeated Span Safety (Naturalness) | 5 | 4/5 | `Vi mucho tráfico, y luego vi más tráfico.`; `Vi mucho tráfico y luego vi más tráfico.` | 16846 | $0.037872 |
| accent-manana | Accents / Diacritics | 5 | 5/5 | `Voy al parque mañana por la tarde.` | 10125 | $0.021295 |
| accent-medico | Accents / Diacritics | 5 | 5/5 | `El médico llegó después de la reunión.` | 10547 | $0.021785 |
| accent-espana-pais | Accents / Diacritics | 5 | 5/5 | `España es un país muy diverso.` | 9974 | $0.019160 |
| accent-cumpleanos-otono | Accents / Diacritics | 5 | 5/5 | `Mi cumpleaños es en otoño.` | 14245 | $0.025845 |
| accent-cafe-cafeteria | Accents / Diacritics | 5 | 5/5 | `Compré café en una cafetería pequeña.` | 9864 | $0.021420 |
| agreement-ninos-manzanas | Gender / Number Agreement | 5 | 5/5 | `Los niños comen muchas manzanas.` | 10048 | $0.019425 |
| agreement-ventanas-abiertas | Gender / Number Agreement | 5 | 5/5 | `Las ventanas estaban abiertas.` | 9748 | $0.019030 |
| agreement-puerta-cerrada | Gender / Number Agreement | 5 | 5/5 | `Una puerta estaba cerrada.` | 11897 | $0.023175 |
| agreement-billetes-caros | Gender / Number Agreement | 5 | 5/5 | `Los billetes estaban caros.` | 18452 | $0.034855 |
| agreement-fechas-escritas | Gender / Number Agreement | 5 | 5/5 | `Las fechas estaban escritas sin tilde.` | 17526 | $0.038010 |
| verb-nosotros-fuimos | Verb Agreement / Morphology | 5 | 5/5 | `Mis compañeros y yo fuimos a la biblioteca.` | 12413 | $0.019455 |
| verb-ninos-comen | Verb Agreement / Morphology | 5 | 5/5 | `Los niños comen en el jardín.` | 8823 | $0.019150 |
| verb-compre-pan | Verb Agreement / Morphology | 5 | 5/5 | `Yo fui al mercado y compré pan.` | 11286 | $0.020460 |
| verb-ellos-estudian | Verb Agreement / Morphology | 5 | 5/5 | `Ellos estudian todas las noches.` | 10259 | $0.019885 |
| verb-nosotros-vivimos | Verb Agreement / Morphology | 5 | 5/5 | `Nosotros vivimos cerca del centro.` | 9333 | $0.020320 |
| prep-insisto-en | Required Prepositions | 5 | 5/5 | `Insisto en que revises el contrato.` | 10464 | $0.021630 |
| prep-empresa-en-la-que | Required Prepositions | 5 | 3/5 | `La empresa en la que trabajo está cerca.`; `La empresa en que trabajo está cerca.` | 13842 | $0.027774 |
| prep-dependo-de | Required Prepositions | 5 | 5/5 | `Dependo de que me ayudes mañana.` | 15077 | $0.028560 |
| prep-pienso-en-ti | Required Prepositions | 5 | 5/5 | `Pienso en ti todos los días.` | 10774 | $0.019185 |
| prep-sone-con | Required Prepositions | 5 | 5/5 | `Soñé con mi antiguo colegio.` | 11691 | $0.023865 |
| article-puerta-principal | Articles / Determiners | 5 | 5/5 | `Abrió la puerta principal.` | 9849 | $0.020715 |
| article-un-libro | Articles / Determiners | 5 | 5/5 | `Necesito comprar un libro para la clase.` | 9646 | $0.019350 |
| article-el-profesor-la-regla | Articles / Determiners | 5 | 5/5 | `El profesor explicó la regla otra vez.` | 9029 | $0.019535 |
| article-la-tienda | Articles / Determiners | 5 | 5/5 | `Fui a la tienda después del trabajo.` | 10467 | $0.019710 |
| article-cita-medico | Articles / Determiners | 5 | 5/5 | `Tengo una cita con el médico mañana.` | 9646 | $0.020045 |
| subj-estudies | Subjunctive / Mood | 5 | 5/5 | `Es importante que estudies.` | 9133 | $0.019165 |
| subj-tenga-razon | Subjunctive / Mood | 5 | 5/5 | `No creo que tenga razón.` | 11180 | $0.020245 |
| subj-vengas | Subjunctive / Mood | 5 | 5/5 | `Quiero que vengas conmigo.` | 11495 | $0.019090 |
| subj-enviara | Subjunctive / Mood | 5 | 5/5 | `Era necesario que enviara su parte.` | 17219 | $0.031225 |
| subj-hable-frances | Subjunctive / Mood | 5 | 5/5 | `Busco a alguien que hable francés.` | 13843 | $0.021330 |
| missing-que-creo | Required Additions / Omissions | 5 | 5/5 | `Creo que está bien terminar hoy.` | 11077 | $0.023850 |
| missing-les-ninos | Required Additions / Omissions | 5 | 5/5 | `A los niños les expliqué la regla.` | 14459 | $0.023655 |
| missing-personal-a-profesor | Required Additions / Omissions | 5 | 5/5 | `Vi a mi profesor en la estación.` | 12000 | $0.019785 |
| missing-se-levanto | Required Additions / Omissions | 5 | 5/5 | `Se levantó temprano ayer.` | 10059 | $0.019135 |
| missing-le-gusta | Required Additions / Omissions | 5 | 5/5 | `A Juan le gusta el café.` | 9647 | $0.019080 |
| delete-repeated-yo-estudio | Unnecessary Extras / Deletions | 5 | 0/5 | `Yo trabajo mucho y yo estudio por las noches.` | 12560 | $0.025735 |
| delete-repeated-ellos-visitaron | Unnecessary Extras / Deletions | 5 | 2/5 | `Ellos viajaron a México y ellos visitaron varias ciudades.`; `Ellos viajaron a México y visitaron varias ciudades.` | 14104 | $0.026594 |
| delete-repeated-a-mi | Unnecessary Extras / Deletions | 5 | 5/5 | `A mí me gusta el café.` | 9750 | $0.019140 |
| delete-repeated-yo-compre | Unnecessary Extras / Deletions | 5 | 3/5 | `Yo fui al mercado y compré pan.`; `Yo fui al mercado y yo compré pan.` | 12203 | $0.022576 |
| delete-repeated-nosotros | Unnecessary Extras / Deletions | 5 | 0/5 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | 14879 | $0.028765 |
| ser-profesor | Ser / Estar / Haber | 5 | 5/5 | `Mi hermano es profesor.` | 8505 | $0.018910 |
| haber-veinte-personas | Ser / Estar / Haber | 5 | 5/5 | `En la sala hay veinte personas.` | 9339 | $0.019630 |
| ser-capital-madrid | Ser / Estar / Haber | 5 | 5/5 | `Madrid es la capital de España.` | 8826 | $0.018790 |
| estar-contento | Ser / Estar / Haber | 5 | 5/5 | `Estoy muy contento con el resultado.` | 8309 | $0.019015 |
| ser-reunion-segunda-planta | Ser / Estar / Haber | 5 | 5/5 | `La reunión es en la segunda planta.` | 12721 | $0.025495 |
| haber-habia-personas | Impersonal Haber / Se | 5 | 5/5 | `Había muchas personas en la entrada.` | 10699 | $0.020935 |
| haber-hubo-problemas | Impersonal Haber / Se | 5 | 5/5 | `Hubo varios problemas durante la reunión.` | 10951 | $0.020485 |
| se-venden-pisos | Impersonal Haber / Se | 5 | 5/5 | `Se venden pisos en el centro.` | 10258 | $0.021190 |
| se-necesitan-voluntarios | Impersonal Haber / Se | 5 | 5/5 | `Se necesitan voluntarios para el evento.` | 13251 | $0.019525 |
| haber-habia-cifras | Impersonal Haber / Se | 5 | 5/5 | `Había varias cifras incorrectas.` | 12390 | $0.023050 |
| collocation-hacer-decision | Collocations / Strong Calques | 5 | 5/5 | `Necesito tomar una decisión.` | 11797 | $0.021175 |
| collocation-hacer-atencion | Collocations / Strong Calques | 5 | 5/5 | `Tenemos que prestar atención.` | 10259 | $0.020230 |
| collocation-tomar-reunion | Collocations / Strong Calques | 5 | 5/5 | `El equipo tuvo una reunión.` | 11283 | $0.021175 |
| collocation-hacer-paseo | Collocations / Strong Calques | 5 | 5/5 | `Ella dio un paseo.` | 18658 | $0.032410 |
| collocation-hace-sentido | Collocations / Strong Calques | 5 | 5/5 | `Esto tiene sentido.` | 12307 | $0.022435 |
| false-friend-atendio-universidad | False Friends / Word Choice | 5 | 3/5 | `Estudió en la universidad en Madrid.`; `Asistió a la universidad en Madrid.` | 48660 | $0.086220 |
| false-friend-aplico-trabajo | False Friends / Word Choice | 5 | 5/5 | `Solicitó un trabajo.` | 33218 | $0.059125 |
| false-friend-realice | False Friends / Word Choice | 5 | 5/5 | `Me di cuenta de que estaba equivocado.` | 9935 | $0.020250 |
| false-friend-embarazado | False Friends / Word Choice | 5 | 4/5 | `Estoy avergonzado por llegar tarde.`; `Estoy avergonzado de llegar tarde.` | 19782 | $0.038237 |
| false-friend-actualmente-control | False Friends / Word Choice | 5 | 5/5 | `Actualmente vivo en Londres.` | 9231 | $0.019420 |
| naturalness-buen-tiempo | Phrase-Level Naturalness | 5 | 4/5 | `Lo pasamos bien.`; `Pasamos un buen rato.` | 22448 | $0.042854 |
| naturalness-corriendo-tarde | Phrase-Level Naturalness | 5 | 5/5 | `Estoy llegando tarde a la reunión.` | 25413 | $0.044870 |
| naturalness-pasar-buen-tiempo | Phrase-Level Naturalness | 5 | 5/5 | `Quiero pasar un buen rato.` | 13334 | $0.022630 |
| naturalness-puedo-tener-cerveza | Phrase-Level Naturalness | 5 | 5/5 | `¿Puedo tomar una cerveza?` | 12308 | $0.023170 |
| naturalness-llamar-para-atras | Phrase-Level Naturalness | 5 | 5/5 | `Te llamo después.`; `Te devuelvo la llamada.` | 17735 | $0.033376 |
| regional-voy-para-casa | Valid Regional / Should Not Flag | 5 | 0/5 | `Voy para la casa ahora mismo.` | 43326 | $0.045120 |
| regional-vos-tenes | Valid Regional / Should Not Flag | 5 | 5/5 | `Vos tenés razón.` | 12204 | $0.022360 |
| regional-cojo-autobus | Valid Regional / Should Not Flag | 5 | 5/5 | `Cojo el autobús cada mañana.` | 20805 | $0.023035 |
| regional-preterite-esta-manana | Valid Regional / Should Not Flag | 5 | 5/5 | `Esta mañana hablé con mi jefe.` | 10768 | $0.019255 |
| regional-dale | Valid Regional / Should Not Flag | 5 | 5/5 | `Dale, nos vemos más tarde.` | 11692 | $0.025075 |
| correct-buenos-dias | Already Correct / Do Not Tinker | 5 | 5/5 | `Buenos días, ¿cómo estás?` | 13638 | $0.019000 |
| correct-hacer-pregunta | Already Correct / Do Not Tinker | 5 | 5/5 | `Voy a hacer una pregunta al profesor.` | 12779 | $0.021865 |
| correct-tomar-foto | Already Correct / Do Not Tinker | 5 | 5/5 | `Necesito tomar una foto del documento.` | 12761 | $0.026185 |
| correct-visitar-abuela | Already Correct / Do Not Tinker | 5 | 5/5 | `Mañana visitaré a mi abuela.` | 9591 | $0.019285 |
| correct-me-quedo-en-casa | Already Correct / Do Not Tinker | 5 | 5/5 | `Está lloviendo, así que me quedo en casa.` | 9702 | $0.020560 |
| mixed-preposition-and-redundant-pronoun | Mixed Operations | 5 | 3/5 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`; `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | 15479 | $0.030696 |
| mixed-article-and-accent | Mixed Operations | 5 | 5/5 | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | 14784 | $0.031270 |
| mixed-personal-a-and-subjunctive | Mixed Operations | 5 | 5/5 | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | 19462 | $0.038525 |
| mixed-gender-agreement-and-redundant-pronoun | Mixed Operations | 5 | 5/5 | `Las ventanas estaban abiertas, y a mí me gusta el café.` | 14573 | $0.026820 |
| mixed-verb-agreement-and-missing-que | Mixed Operations | 5 | 5/5 | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | 18309 | $0.039705 |

## Accents / Diacritics

### clean-grammar-only

- Original text: `Vi mucho trafico ayer.`
- Expected corrected text: `Vi mucho tráfico ayer.`
- Pass rate: 1/5
- Distinct final outputs:
  - `Había mucho tráfico ayer.`
  - `Vi mucho tráfico ayer.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico ayer.` | Vi -> Había | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Vi mucho tráfico ayer.` | (none) | `Vi mucho tráfico ayer.` | correct_fix | Pass | Matches expected output. |
| 3 | `Vi mucho tráfico ayer.` | Vi -> Había | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi mucho tráfico ayer.` | Vi -> Había | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Vi mucho tráfico ayer.` | Vi -> Había | `Había mucho tráfico ayer.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1724 | $0.000570 | 6244 | $0.011410 | 7968 | $0.011980 |
| 2 | 855 | $0.000570 | 3173 | $0.007270 | 4028 | $0.007840 |
| 3 | 783 | $0.000570 | 5838 | $0.013300 | 6621 | $0.013870 |
| 4 | 779 | $0.000570 | 3888 | $0.007870 | 4667 | $0.008440 |
| 5 | 786 | $0.000570 | 5019 | $0.011080 | 5805 | $0.011650 |

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
| 1 | 646 | $0.000598 | 2073 | $0.003625 | 2719 | $0.004223 |
| 2 | 655 | $0.000598 | 1228 | $0.003745 | 1883 | $0.004343 |
| 3 | 681 | $0.000598 | 1228 | $0.003595 | 1909 | $0.004193 |
| 4 | 530 | $0.000598 | 1173 | $0.003745 | 1703 | $0.004343 |
| 5 | 487 | $0.000598 | 1424 | $0.003595 | 1911 | $0.004193 |

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
| 1 | 576 | $0.000600 | 1647 | $0.003595 | 2223 | $0.004195 |
| 2 | 818 | $0.000600 | 1288 | $0.003745 | 2106 | $0.004345 |
| 3 | 625 | $0.000600 | 1532 | $0.003925 | 2157 | $0.004525 |
| 4 | 606 | $0.000600 | 1260 | $0.003595 | 1866 | $0.004195 |
| 5 | 791 | $0.000600 | 1404 | $0.003925 | 2195 | $0.004525 |

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
| 1 | 801 | $0.000590 | 1262 | $0.003230 | 2063 | $0.003820 |
| 2 | 818 | $0.000590 | 1263 | $0.003230 | 2081 | $0.003820 |
| 3 | 587 | $0.000590 | 1321 | $0.003230 | 1908 | $0.003820 |
| 4 | 604 | $0.000590 | 1098 | $0.003260 | 1702 | $0.003850 |
| 5 | 1205 | $0.000590 | 1015 | $0.003260 | 2220 | $0.003850 |

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
| 1 | 578 | $0.000582 | 2045 | $0.004575 | 2623 | $0.005157 |
| 2 | 683 | $0.000582 | 2082 | $0.004635 | 2765 | $0.005217 |
| 3 | 745 | $0.000582 | 2457 | $0.004725 | 3202 | $0.005307 |
| 4 | 579 | $0.000582 | 2580 | $0.004875 | 3159 | $0.005457 |
| 5 | 541 | $0.000582 | 1955 | $0.004125 | 2496 | $0.004707 |

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
| 1 | 581 | $0.000606 | 1333 | $0.003690 | 1914 | $0.004296 |
| 2 | 534 | $0.000606 | 1372 | $0.003540 | 1906 | $0.004146 |
| 3 | 590 | $0.000606 | 1319 | $0.003570 | 1909 | $0.004176 |
| 4 | 688 | $0.000606 | 1474 | $0.003720 | 2162 | $0.004326 |
| 5 | 632 | $0.000606 | 1341 | $0.003870 | 1973 | $0.004476 |

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
| 1 | 661 | $0.000588 | 1170 | $0.003560 | 1831 | $0.004148 |
| 2 | 593 | $0.000588 | 1417 | $0.003740 | 2010 | $0.004328 |
| 3 | 529 | $0.000588 | 1249 | $0.003380 | 1778 | $0.003968 |
| 4 | 574 | $0.000588 | 1131 | $0.003380 | 1705 | $0.003968 |
| 5 | 672 | $0.000588 | 1341 | $0.003410 | 2013 | $0.003998 |

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
| 1 | 578 | $0.000578 | 1738 | $0.003645 | 2316 | $0.004223 |
| 2 | 683 | $0.000578 | 1334 | $0.003525 | 2017 | $0.004103 |
| 3 | 677 | $0.000578 | 1434 | $0.003675 | 2111 | $0.004253 |
| 4 | 578 | $0.000578 | 1432 | $0.003765 | 2010 | $0.004343 |
| 5 | 782 | $0.000578 | 2561 | $0.003675 | 3343 | $0.004253 |

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
| 1 | 581 | $0.000568 | 1429 | $0.003430 | 2010 | $0.003998 |
| 2 | 498 | $0.000568 | 1240 | $0.003430 | 1738 | $0.003998 |
| 3 | 520 | $0.000568 | 2082 | $0.003550 | 2602 | $0.004118 |
| 4 | 515 | $0.000568 | 1485 | $0.003580 | 2000 | $0.004148 |
| 5 | 571 | $0.000568 | 1338 | $0.003400 | 1909 | $0.003968 |

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
| 1 | 575 | $0.000578 | 2180 | $0.003735 | 2755 | $0.004313 |
| 2 | 615 | $0.000578 | 1471 | $0.003495 | 2086 | $0.004073 |
| 3 | 784 | $0.000578 | 1296 | $0.003735 | 2080 | $0.004313 |
| 4 | 614 | $0.000578 | 1430 | $0.003675 | 2044 | $0.004253 |
| 5 | 577 | $0.000578 | 1741 | $0.003645 | 2318 | $0.004223 |

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
| 1 | 579 | $0.000568 | 2558 | $0.005620 | 3137 | $0.006188 |
| 2 | 682 | $0.000568 | 2761 | $0.006100 | 3443 | $0.006668 |
| 3 | 586 | $0.000568 | 4293 | $0.005770 | 4879 | $0.006338 |
| 4 | 577 | $0.000568 | 2349 | $0.005860 | 2926 | $0.006428 |
| 5 | 892 | $0.000568 | 3381 | $0.006220 | 4273 | $0.006788 |

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
| 1 | 569 | $0.000558 | 1966 | $0.003995 | 2535 | $0.004553 |
| 2 | 563 | $0.000558 | 2357 | $0.003935 | 2920 | $0.004493 |
| 3 | 681 | $0.000558 | 1535 | $0.003845 | 2216 | $0.004403 |
| 4 | 686 | $0.000558 | 1734 | $0.003875 | 2420 | $0.004433 |
| 5 | 578 | $0.000558 | 1638 | $0.003995 | 2216 | $0.004553 |

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
| 1 | 680 | $0.000668 | 1691 | $0.004350 | 2371 | $0.005018 |
| 2 | 642 | $0.000668 | 2027 | $0.004770 | 2669 | $0.005438 |
| 3 | 547 | $0.000668 | 1447 | $0.004230 | 1994 | $0.004898 |
| 4 | 595 | $0.000668 | 2225 | $0.004260 | 2820 | $0.004928 |
| 5 | 709 | $0.000668 | 1633 | $0.004200 | 2342 | $0.004868 |

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
| 1 | 577 | $0.000588 | 2359 | $0.005990 | 2936 | $0.006578 |
| 2 | 574 | $0.000588 | 2355 | $0.005630 | 2929 | $0.006218 |
| 3 | 578 | $0.000588 | 2252 | $0.006170 | 2830 | $0.006758 |
| 4 | 720 | $0.000588 | 2110 | $0.006020 | 2830 | $0.006608 |
| 5 | 884 | $0.000588 | 2149 | $0.005780 | 3033 | $0.006368 |

## Ambiguous / Repeated Span Safety (Naturalness)

### ambiguous-naturalness-span

- Original text: `Vi mucho tráfico, y luego vi más tráfico.`
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Vi mucho tráfico, y luego vi más tráfico.`
  - `Vi mucho tráfico y luego vi más tráfico.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 2 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 3 | `Vi mucho tráfico y luego vi más tráfico.` | (none) | `Vi mucho tráfico y luego vi más tráfico.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |
| 5 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | acceptable_no_change | Pass | Matches expected output; already-correct text was left unchanged. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 579 | $0.000618 | 2601 | $0.006185 | 3180 | $0.006803 |
| 2 | 638 | $0.000618 | 2774 | $0.006935 | 3412 | $0.007553 |
| 3 | 568 | $0.000610 | 2578 | $0.006780 | 3146 | $0.007390 |
| 4 | 615 | $0.000618 | 1573 | $0.004715 | 2188 | $0.005333 |
| 5 | 586 | $0.000618 | 4334 | $0.010175 | 4920 | $0.010793 |

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
| 1 | 712 | $0.000596 | 1289 | $0.003235 | 2001 | $0.003831 |
| 2 | 577 | $0.000596 | 1137 | $0.003235 | 1714 | $0.003831 |
| 3 | 567 | $0.000596 | 1780 | $0.003475 | 2347 | $0.004071 |
| 4 | 755 | $0.000596 | 1321 | $0.003235 | 2076 | $0.003831 |
| 5 | 577 | $0.000596 | 1333 | $0.003265 | 1910 | $0.003861 |

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
| 1 | 781 | $0.000568 | 1230 | $0.003250 | 2011 | $0.003818 |
| 2 | 681 | $0.000568 | 1125 | $0.003220 | 1806 | $0.003788 |
| 3 | 780 | $0.000568 | 1540 | $0.003280 | 2320 | $0.003848 |
| 4 | 576 | $0.000568 | 1335 | $0.003250 | 1911 | $0.003818 |
| 5 | 572 | $0.000568 | 1128 | $0.003190 | 1700 | $0.003758 |

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
| 1 | 679 | $0.000576 | 1615 | $0.004125 | 2294 | $0.004701 |
| 2 | 1036 | $0.000576 | 1717 | $0.004185 | 2753 | $0.004761 |
| 3 | 681 | $0.000576 | 1842 | $0.003915 | 2523 | $0.004491 |
| 4 | 681 | $0.000576 | 1432 | $0.003855 | 2113 | $0.004431 |
| 5 | 576 | $0.000576 | 1638 | $0.004215 | 2214 | $0.004791 |

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
| 1 | 527 | $0.000578 | 3123 | $0.006555 | 3650 | $0.007133 |
| 2 | 577 | $0.000578 | 4197 | $0.007005 | 4774 | $0.007583 |
| 3 | 632 | $0.000578 | 2912 | $0.006345 | 3544 | $0.006923 |
| 4 | 687 | $0.000578 | 3241 | $0.007155 | 3928 | $0.007733 |
| 5 | 513 | $0.000578 | 2043 | $0.004905 | 2556 | $0.005483 |

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
| 1 | 576 | $0.000606 | 3177 | $0.006990 | 3753 | $0.007596 |
| 2 | 488 | $0.000606 | 2554 | $0.006450 | 3042 | $0.007056 |
| 3 | 643 | $0.000606 | 2690 | $0.006480 | 3333 | $0.007086 |
| 4 | 696 | $0.000606 | 3151 | $0.007650 | 3847 | $0.008256 |
| 5 | 892 | $0.000606 | 2659 | $0.007410 | 3551 | $0.008016 |

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
| 1 | 2321 | $0.000616 | 1134 | $0.003305 | 3455 | $0.003921 |
| 2 | 690 | $0.000616 | 1109 | $0.003275 | 1799 | $0.003891 |
| 3 | 984 | $0.000616 | 1129 | $0.003245 | 2113 | $0.003861 |
| 4 | 2011 | $0.000616 | 1330 | $0.003275 | 3341 | $0.003891 |
| 5 | 611 | $0.000616 | 1094 | $0.003275 | 1705 | $0.003891 |

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
| 1 | 576 | $0.000588 | 970 | $0.003320 | 1546 | $0.003908 |
| 2 | 684 | $0.000588 | 1379 | $0.003230 | 2063 | $0.003818 |
| 3 | 683 | $0.000588 | 1123 | $0.003260 | 1806 | $0.003848 |
| 4 | 580 | $0.000588 | 1226 | $0.003140 | 1806 | $0.003728 |
| 5 | 537 | $0.000588 | 1065 | $0.003260 | 1602 | $0.003848 |

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
| 1 | 605 | $0.000606 | 1408 | $0.003780 | 2013 | $0.004386 |
| 2 | 679 | $0.000606 | 1056 | $0.003270 | 1735 | $0.003876 |
| 3 | 547 | $0.000606 | 1534 | $0.003840 | 2081 | $0.004446 |
| 4 | 766 | $0.000606 | 1144 | $0.003270 | 1910 | $0.003876 |
| 5 | 2114 | $0.000606 | 1433 | $0.003270 | 3547 | $0.003876 |

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
| 1 | 575 | $0.000598 | 1436 | $0.003745 | 2011 | $0.004343 |
| 2 | 1296 | $0.000598 | 1125 | $0.003235 | 2421 | $0.003833 |
| 3 | 690 | $0.000598 | 1118 | $0.003265 | 1808 | $0.003863 |
| 4 | 676 | $0.000598 | 1173 | $0.003265 | 1849 | $0.003863 |
| 5 | 736 | $0.000598 | 1434 | $0.003385 | 2170 | $0.003983 |

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
| 1 | 579 | $0.000588 | 1014 | $0.003260 | 1593 | $0.003848 |
| 2 | 686 | $0.000588 | 1203 | $0.003680 | 1889 | $0.004268 |
| 3 | 601 | $0.000588 | 1333 | $0.003560 | 1934 | $0.004148 |
| 4 | 579 | $0.000588 | 1531 | $0.003620 | 2110 | $0.004208 |
| 5 | 679 | $0.000588 | 1128 | $0.003260 | 1807 | $0.003848 |

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
| 1 | 1091 | $0.000606 | 1331 | $0.003840 | 2422 | $0.004446 |
| 2 | 885 | $0.000606 | 1433 | $0.003750 | 2318 | $0.004356 |
| 3 | 561 | $0.000606 | 1347 | $0.003750 | 1908 | $0.004356 |
| 4 | 681 | $0.000606 | 1226 | $0.003630 | 1907 | $0.004236 |
| 5 | 682 | $0.000606 | 1227 | $0.003630 | 1909 | $0.004236 |

### prep-empresa-en-la-que

- Original text: `La empresa que trabajo está cerca.`
- Expected corrected text: `La empresa en la que trabajo está cerca.`
- Pass rate: 3/5
- Distinct final outputs:
  - `La empresa en la que trabajo está cerca.`
  - `La empresa en que trabajo está cerca.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `La empresa en la que trabajo está cerca.` | (none) | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 2 | `La empresa en la que trabajo está cerca.` | (none) | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 3 | `La empresa en que trabajo está cerca.` | (none) | `La empresa en que trabajo está cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `La empresa en la que trabajo está cerca.` | (none) | `La empresa en la que trabajo está cerca.` | correct_fix | Pass | Matches expected output. |
| 5 | `La empresa en que trabajo está cerca.` | (none) | `La empresa en que trabajo está cerca.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 595 | $0.000604 | 1728 | $0.004140 | 2323 | $0.004744 |
| 2 | 574 | $0.000604 | 2253 | $0.005400 | 2827 | $0.006004 |
| 3 | 703 | $0.000596 | 2638 | $0.006145 | 3341 | $0.006741 |
| 4 | 884 | $0.000604 | 1436 | $0.003750 | 2320 | $0.004354 |
| 5 | 678 | $0.000596 | 2353 | $0.005335 | 3031 | $0.005931 |

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
| 1 | 580 | $0.000606 | 2458 | $0.006090 | 3038 | $0.006696 |
| 2 | 683 | $0.000606 | 3582 | $0.005130 | 4265 | $0.005736 |
| 3 | 575 | $0.000606 | 1845 | $0.004890 | 2420 | $0.005496 |
| 4 | 691 | $0.000606 | 2214 | $0.004770 | 2905 | $0.005376 |
| 5 | 606 | $0.000606 | 1843 | $0.004650 | 2449 | $0.005256 |

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
| 1 | 685 | $0.000596 | 933 | $0.003235 | 1618 | $0.003831 |
| 2 | 626 | $0.000596 | 996 | $0.003265 | 1622 | $0.003861 |
| 3 | 849 | $0.000596 | 1124 | $0.003235 | 1973 | $0.003831 |
| 4 | 2122 | $0.000596 | 1574 | $0.003235 | 3696 | $0.003831 |
| 5 | 735 | $0.000596 | 1130 | $0.003235 | 1865 | $0.003831 |

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
| 1 | 662 | $0.000596 | 1654 | $0.004555 | 2316 | $0.005151 |
| 2 | 897 | $0.000596 | 1318 | $0.003655 | 2215 | $0.004251 |
| 3 | 782 | $0.000596 | 1866 | $0.004435 | 2648 | $0.005031 |
| 4 | 658 | $0.000596 | 1640 | $0.004315 | 2298 | $0.004911 |
| 5 | 699 | $0.000596 | 1515 | $0.003925 | 2214 | $0.004521 |

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
| 1 | 680 | $0.000576 | 1627 | $0.003705 | 2307 | $0.004281 |
| 2 | 596 | $0.000576 | 1273 | $0.003645 | 1869 | $0.004221 |
| 3 | 651 | $0.000576 | 1309 | $0.003705 | 1960 | $0.004281 |
| 4 | 677 | $0.000576 | 1239 | $0.003555 | 1916 | $0.004131 |
| 5 | 672 | $0.000576 | 1125 | $0.003225 | 1797 | $0.003801 |

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
| 1 | 640 | $0.000606 | 1372 | $0.003270 | 2012 | $0.003876 |
| 2 | 681 | $0.000606 | 1331 | $0.003270 | 2012 | $0.003876 |
| 3 | 578 | $0.000606 | 1102 | $0.003270 | 1680 | $0.003876 |
| 4 | 804 | $0.000606 | 1129 | $0.003240 | 1933 | $0.003846 |
| 5 | 695 | $0.000606 | 1314 | $0.003270 | 2009 | $0.003876 |

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
| 1 | 585 | $0.000594 | 1117 | $0.003295 | 1702 | $0.003889 |
| 2 | 577 | $0.000594 | 1027 | $0.003265 | 1604 | $0.003859 |
| 3 | 574 | $0.000594 | 1330 | $0.003475 | 1904 | $0.004069 |
| 4 | 784 | $0.000594 | 1330 | $0.003265 | 2114 | $0.003859 |
| 5 | 586 | $0.000594 | 1119 | $0.003265 | 1705 | $0.003859 |

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
| 1 | 683 | $0.000606 | 1322 | $0.003630 | 2005 | $0.004236 |
| 2 | 587 | $0.000606 | 1832 | $0.003270 | 2419 | $0.003876 |
| 3 | 588 | $0.000606 | 1401 | $0.003270 | 1989 | $0.003876 |
| 4 | 819 | $0.000606 | 1273 | $0.003270 | 2092 | $0.003876 |
| 5 | 837 | $0.000606 | 1125 | $0.003240 | 1962 | $0.003846 |

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
| 1 | 578 | $0.000594 | 1494 | $0.003505 | 2072 | $0.004099 |
| 2 | 722 | $0.000594 | 1431 | $0.003295 | 2153 | $0.003889 |
| 3 | 682 | $0.000594 | 1229 | $0.003505 | 1911 | $0.004099 |
| 4 | 547 | $0.000594 | 1156 | $0.003505 | 1703 | $0.004099 |
| 5 | 679 | $0.000594 | 1128 | $0.003265 | 1807 | $0.003859 |

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
| 1 | 717 | $0.000578 | 1090 | $0.003285 | 1807 | $0.003863 |
| 2 | 576 | $0.000578 | 1183 | $0.003225 | 1759 | $0.003803 |
| 3 | 521 | $0.000578 | 1126 | $0.003255 | 1647 | $0.003833 |
| 4 | 581 | $0.000578 | 1430 | $0.003255 | 2011 | $0.003833 |
| 5 | 577 | $0.000578 | 1332 | $0.003255 | 1909 | $0.003833 |

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
| 1 | 680 | $0.000578 | 1238 | $0.003375 | 1918 | $0.003953 |
| 2 | 670 | $0.000578 | 1844 | $0.003795 | 2514 | $0.004373 |
| 3 | 749 | $0.000578 | 1468 | $0.003435 | 2217 | $0.004013 |
| 4 | 574 | $0.000578 | 1537 | $0.003255 | 2111 | $0.003833 |
| 5 | 986 | $0.000578 | 1434 | $0.003495 | 2420 | $0.004073 |

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
| 1 | 1498 | $0.000588 | 1639 | $0.003260 | 3137 | $0.003848 |
| 2 | 772 | $0.000588 | 1240 | $0.003260 | 2012 | $0.003848 |
| 3 | 679 | $0.000588 | 1182 | $0.003230 | 1861 | $0.003818 |
| 4 | 729 | $0.000588 | 1328 | $0.003260 | 2057 | $0.003848 |
| 5 | 629 | $0.000588 | 1799 | $0.003140 | 2428 | $0.003728 |

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
| 1 | 1255 | $0.000598 | 2492 | $0.005665 | 3747 | $0.006263 |
| 2 | 680 | $0.000598 | 2664 | $0.005875 | 3344 | $0.006473 |
| 3 | 576 | $0.000598 | 2764 | $0.005605 | 3340 | $0.006203 |
| 4 | 671 | $0.000598 | 2468 | $0.005155 | 3139 | $0.005753 |
| 5 | 609 | $0.000598 | 3040 | $0.005935 | 3649 | $0.006533 |

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
| 1 | 783 | $0.000606 | 1171 | $0.003570 | 1954 | $0.004176 |
| 2 | 1760 | $0.000606 | 1739 | $0.003660 | 3499 | $0.004266 |
| 3 | 685 | $0.000606 | 2556 | $0.003570 | 3241 | $0.004176 |
| 4 | 1293 | $0.000606 | 1640 | $0.003600 | 2933 | $0.004206 |
| 5 | 613 | $0.000606 | 1603 | $0.003900 | 2216 | $0.004506 |

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
| 1 | 577 | $0.000586 | 1333 | $0.003860 | 1910 | $0.004446 |
| 2 | 746 | $0.000586 | 1387 | $0.003860 | 2133 | $0.004446 |
| 3 | 612 | $0.000586 | 1621 | $0.003860 | 2233 | $0.004446 |
| 4 | 640 | $0.000586 | 2058 | $0.005480 | 2698 | $0.006066 |
| 5 | 576 | $0.000586 | 1527 | $0.003860 | 2103 | $0.004446 |

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
| 1 | 680 | $0.000596 | 1534 | $0.004375 | 2214 | $0.004971 |
| 2 | 1704 | $0.000596 | 1640 | $0.003925 | 3344 | $0.004521 |
| 3 | 1157 | $0.000596 | 2416 | $0.003865 | 3573 | $0.004461 |
| 4 | 766 | $0.000596 | 2347 | $0.004435 | 3113 | $0.005031 |
| 5 | 576 | $0.000596 | 1639 | $0.004075 | 2215 | $0.004671 |

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
| 1 | 785 | $0.000596 | 1329 | $0.003265 | 2114 | $0.003861 |
| 2 | 1091 | $0.000596 | 1536 | $0.003295 | 2627 | $0.003891 |
| 3 | 884 | $0.000596 | 1842 | $0.003715 | 2726 | $0.004311 |
| 4 | 577 | $0.000596 | 1661 | $0.003265 | 2238 | $0.003861 |
| 5 | 761 | $0.000596 | 1534 | $0.003265 | 2295 | $0.003861 |

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
| 1 | 578 | $0.000578 | 1067 | $0.003255 | 1645 | $0.003833 |
| 2 | 587 | $0.000578 | 1282 | $0.003255 | 1869 | $0.003833 |
| 3 | 678 | $0.000578 | 1025 | $0.003225 | 1703 | $0.003803 |
| 4 | 784 | $0.000578 | 1535 | $0.003255 | 2319 | $0.003833 |
| 5 | 643 | $0.000578 | 1880 | $0.003255 | 2523 | $0.003833 |

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
| 1 | 1091 | $0.000586 | 1227 | $0.003200 | 2318 | $0.003786 |
| 2 | 586 | $0.000586 | 1119 | $0.003260 | 1705 | $0.003846 |
| 3 | 510 | $0.000586 | 1297 | $0.003230 | 1807 | $0.003816 |
| 4 | 576 | $0.000586 | 1240 | $0.003230 | 1816 | $0.003816 |
| 5 | 772 | $0.000586 | 1229 | $0.003230 | 2001 | $0.003816 |

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
| 1 | 616 | $0.000618 | 1806 | $0.004595 | 2422 | $0.005213 |
| 2 | 700 | $0.000618 | 1664 | $0.004565 | 2364 | $0.005183 |
| 3 | 939 | $0.000618 | 2061 | $0.004445 | 3000 | $0.005063 |
| 4 | 668 | $0.000618 | 1843 | $0.004625 | 2511 | $0.005243 |
| 5 | 683 | $0.000618 | 1580 | $0.004415 | 2263 | $0.005033 |

### delete-repeated-ellos-visitaron

- Original text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Expected corrected text: `Ellos viajaron a México y visitaron varias ciudades.`
- Pass rate: 2/5
- Distinct final outputs:
  - `Ellos viajaron a México y ellos visitaron varias ciudades.`
  - `Ellos viajaron a México y visitaron varias ciudades.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Ellos viajaron a México y visitaron varias ciudades.` | (none) | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 3 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 4 | `Ellos viajaron a México y visitaron varias ciudades.` | (none) | `Ellos viajaron a México y visitaron varias ciudades.` | correct_fix | Pass | Matches expected output. |
| 5 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 736 | $0.000648 | 2458 | $0.005420 | 3194 | $0.006068 |
| 2 | 782 | $0.000640 | 1331 | $0.003435 | 2113 | $0.004075 |
| 3 | 784 | $0.000648 | 2841 | $0.005210 | 3625 | $0.005858 |
| 4 | 602 | $0.000640 | 1464 | $0.003735 | 2066 | $0.004375 |
| 5 | 600 | $0.000648 | 2506 | $0.005570 | 3106 | $0.006218 |

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
| 1 | 885 | $0.000592 | 1330 | $0.003260 | 2215 | $0.003852 |
| 2 | 783 | $0.000592 | 1230 | $0.003230 | 2013 | $0.003822 |
| 3 | 682 | $0.000592 | 1226 | $0.003200 | 1908 | $0.003792 |
| 4 | 683 | $0.000592 | 1164 | $0.003230 | 1847 | $0.003822 |
| 5 | 642 | $0.000592 | 1125 | $0.003260 | 1767 | $0.003852 |

### delete-repeated-yo-compre

- Original text: `Yo fui al mercado y yo compré pan.`
- Expected corrected text: `Fui al mercado y compré pan.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Yo fui al mercado y compré pan.`
  - `Yo fui al mercado y yo compré pan.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 2 | `Yo fui al mercado y yo compré pan.` | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |
| 4 | `Yo fui al mercado y yo compré pan.` | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 5 | `Yo fui al mercado y compré pan.` | (none) | `Yo fui al mercado y compré pan.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 780 | $0.000610 | 1243 | $0.003270 | 2023 | $0.003880 |
| 2 | 639 | $0.000618 | 1872 | $0.004805 | 2511 | $0.005423 |
| 3 | 708 | $0.000610 | 1834 | $0.003240 | 2542 | $0.003850 |
| 4 | 818 | $0.000618 | 1681 | $0.004295 | 2499 | $0.004913 |
| 5 | 592 | $0.000610 | 2036 | $0.003900 | 2628 | $0.004510 |

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
| 1 | 580 | $0.000638 | 2150 | $0.004845 | 2730 | $0.005483 |
| 2 | 680 | $0.000638 | 2300 | $0.005655 | 2980 | $0.006293 |
| 3 | 631 | $0.000638 | 1945 | $0.004395 | 2576 | $0.005033 |
| 4 | 576 | $0.000638 | 2595 | $0.005715 | 3171 | $0.006353 |
| 5 | 683 | $0.000638 | 2739 | $0.004965 | 3422 | $0.005603 |

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
| 1 | 483 | $0.000568 | 1107 | $0.003220 | 1590 | $0.003788 |
| 2 | 679 | $0.000568 | 1067 | $0.003220 | 1746 | $0.003788 |
| 3 | 637 | $0.000568 | 886 | $0.003280 | 1523 | $0.003848 |
| 4 | 610 | $0.000568 | 1130 | $0.003220 | 1740 | $0.003788 |
| 5 | 680 | $0.000568 | 1226 | $0.003130 | 1906 | $0.003698 |

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
| 1 | 680 | $0.000588 | 1025 | $0.003260 | 1705 | $0.003848 |
| 2 | 647 | $0.000588 | 1047 | $0.003230 | 1694 | $0.003818 |
| 3 | 719 | $0.000588 | 1618 | $0.003230 | 2337 | $0.003818 |
| 4 | 673 | $0.000588 | 937 | $0.003230 | 1610 | $0.003818 |
| 5 | 609 | $0.000588 | 1384 | $0.003740 | 1993 | $0.004328 |

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
| 1 | 679 | $0.000588 | 1230 | $0.003140 | 1909 | $0.003728 |
| 2 | 576 | $0.000588 | 1128 | $0.003230 | 1704 | $0.003818 |
| 3 | 678 | $0.000588 | 1024 | $0.003140 | 1702 | $0.003728 |
| 4 | 578 | $0.000588 | 1330 | $0.003200 | 1908 | $0.003788 |
| 5 | 547 | $0.000588 | 1056 | $0.003140 | 1603 | $0.003728 |

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
| 1 | 563 | $0.000598 | 1049 | $0.003175 | 1612 | $0.003773 |
| 2 | 576 | $0.000598 | 1217 | $0.003235 | 1793 | $0.003833 |
| 3 | 467 | $0.000598 | 1035 | $0.003235 | 1502 | $0.003833 |
| 4 | 686 | $0.000598 | 1074 | $0.003145 | 1760 | $0.003743 |
| 5 | 621 | $0.000598 | 1021 | $0.003235 | 1642 | $0.003833 |

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
| 1 | 581 | $0.000598 | 1636 | $0.004075 | 2217 | $0.004673 |
| 2 | 624 | $0.000598 | 1491 | $0.003925 | 2115 | $0.004523 |
| 3 | 902 | $0.000598 | 2439 | $0.005215 | 3341 | $0.005813 |
| 4 | 580 | $0.000598 | 2045 | $0.005185 | 2625 | $0.005783 |
| 5 | 580 | $0.000598 | 1843 | $0.004105 | 2423 | $0.004703 |

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
| 1 | 524 | $0.000598 | 1127 | $0.003415 | 1651 | $0.004013 |
| 2 | 732 | $0.000598 | 2049 | $0.003835 | 2781 | $0.004433 |
| 3 | 566 | $0.000598 | 1199 | $0.003595 | 1765 | $0.004193 |
| 4 | 826 | $0.000598 | 1637 | $0.003835 | 2463 | $0.004433 |
| 5 | 987 | $0.000598 | 1052 | $0.003265 | 2039 | $0.003863 |

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
| 1 | 550 | $0.000598 | 1974 | $0.003505 | 2524 | $0.004103 |
| 2 | 764 | $0.000598 | 1119 | $0.003265 | 1883 | $0.003863 |
| 3 | 791 | $0.000598 | 1629 | $0.003655 | 2420 | $0.004253 |
| 4 | 783 | $0.000598 | 1395 | $0.003805 | 2178 | $0.004403 |
| 5 | 718 | $0.000598 | 1228 | $0.003265 | 1946 | $0.003863 |

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
| 1 | 576 | $0.000588 | 1386 | $0.003710 | 1962 | $0.004298 |
| 2 | 728 | $0.000588 | 1433 | $0.003620 | 2161 | $0.004208 |
| 3 | 681 | $0.000588 | 1534 | $0.003950 | 2215 | $0.004538 |
| 4 | 578 | $0.000588 | 1437 | $0.003530 | 2015 | $0.004118 |
| 5 | 577 | $0.000588 | 1328 | $0.003440 | 1905 | $0.004028 |

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
| 1 | 518 | $0.000598 | 4817 | $0.003265 | 5335 | $0.003863 |
| 2 | 895 | $0.000598 | 1069 | $0.003265 | 1964 | $0.003863 |
| 3 | 622 | $0.000598 | 1288 | $0.003265 | 1910 | $0.003863 |
| 4 | 767 | $0.000598 | 1450 | $0.003505 | 2217 | $0.004103 |
| 5 | 574 | $0.000598 | 1251 | $0.003235 | 1825 | $0.003833 |

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
| 1 | 967 | $0.000588 | 2151 | $0.003710 | 3118 | $0.004298 |
| 2 | 681 | $0.000588 | 1534 | $0.003860 | 2215 | $0.004448 |
| 3 | 566 | $0.000588 | 1781 | $0.004340 | 2347 | $0.004928 |
| 4 | 574 | $0.000588 | 1715 | $0.004160 | 2289 | $0.004748 |
| 5 | 577 | $0.000588 | 1844 | $0.004040 | 2421 | $0.004628 |

## False Friends / Word Choice

### false-friend-atendio-universidad

- Original text: `Atendió la universidad en Madrid.`
- Expected corrected text: `Asistió a la universidad en Madrid.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Estudió en la universidad en Madrid.`
  - `Asistió a la universidad en Madrid.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Asistió a la universidad en Madrid.` | Asistió a -> Estudió en | `Estudió en la universidad en Madrid.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |
| 3 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |
| 4 | `Asistió a la universidad en Madrid.` | Asistió a la universidad -> Estudió en la universidad | `Estudió en la universidad en Madrid.` | ambiguous | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Asistió a la universidad en Madrid.` | (none) | `Asistió a la universidad en Madrid.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 783 | $0.000606 | 10446 | $0.018690 | 11229 | $0.019296 |
| 2 | 576 | $0.000606 | 8500 | $0.015360 | 9076 | $0.015966 |
| 3 | 635 | $0.000606 | 5984 | $0.010620 | 6619 | $0.011226 |
| 4 | 573 | $0.000606 | 11269 | $0.020250 | 11842 | $0.020856 |
| 5 | 546 | $0.000606 | 9348 | $0.018270 | 9894 | $0.018876 |

### false-friend-aplico-trabajo

- Original text: `Aplicó para un trabajo.`
- Expected corrected text: `Solicitó un trabajo.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Solicitó un trabajo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Aplicó a un trabajo.` | Aplicó a -> Solicitó | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 2 | `Aplicó para un trabajo.` | Aplicó para -> Solicitó | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 3 | `Aplicó para un trabajo.` | Aplicó para un trabajo -> Solicitó un trabajo | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 4 | `Aplicó a un trabajo.` | Aplicó a -> Solicitó | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |
| 5 | `Aplicó para un trabajo.` | Aplicó para -> Solicitó | `Solicitó un trabajo.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 580 | $0.000578 | 8411 | $0.015555 | 8991 | $0.016133 |
| 2 | 557 | $0.000578 | 4817 | $0.008865 | 5374 | $0.009443 |
| 3 | 678 | $0.000578 | 8911 | $0.014415 | 9589 | $0.014993 |
| 4 | 883 | $0.000578 | 3768 | $0.008085 | 4651 | $0.008663 |
| 5 | 601 | $0.000578 | 4012 | $0.009315 | 4613 | $0.009893 |

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
| 1 | 658 | $0.000606 | 1432 | $0.003300 | 2090 | $0.003906 |
| 2 | 681 | $0.000606 | 1333 | $0.003270 | 2014 | $0.003876 |
| 3 | 679 | $0.000606 | 1126 | $0.003270 | 1805 | $0.003876 |
| 4 | 526 | $0.000606 | 1587 | $0.003750 | 2113 | $0.004356 |
| 5 | 578 | $0.000606 | 1335 | $0.003630 | 1913 | $0.004236 |

### false-friend-embarazado

- Original text: `Estoy embarazado por llegar tarde.`
- Expected corrected text: `Me da vergüenza llegar tarde.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Estoy avergonzado por llegar tarde.`
  - `Estoy avergonzado de llegar tarde.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy embarazado de llegar tarde.` | embarazado -> avergonzado | `Estoy avergonzado de llegar tarde.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy avergonzado por llegar tarde.` | (none) | `Estoy avergonzado por llegar tarde.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 778 | $0.000606 | 2067 | $0.005340 | 2845 | $0.005946 |
| 2 | 544 | $0.000606 | 3697 | $0.006960 | 4241 | $0.007566 |
| 3 | 789 | $0.000598 | 3278 | $0.007285 | 4067 | $0.007883 |
| 4 | 884 | $0.000606 | 1766 | $0.004890 | 2650 | $0.005496 |
| 5 | 707 | $0.000606 | 5272 | $0.010740 | 5979 | $0.011346 |

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
| 1 | 576 | $0.000568 | 1329 | $0.003460 | 1905 | $0.004028 |
| 2 | 751 | $0.000568 | 1364 | $0.003400 | 2115 | $0.003968 |
| 3 | 508 | $0.000568 | 1095 | $0.003250 | 1603 | $0.003818 |
| 4 | 680 | $0.000568 | 1138 | $0.003220 | 1818 | $0.003788 |
| 5 | 666 | $0.000568 | 1124 | $0.003250 | 1790 | $0.003818 |

## Phrase-Level Naturalness

### naturalness-buen-tiempo

- Original text: `Tuvimos un buen tiempo.`
- Expected corrected text: `Lo pasamos bien.`
- Pass rate: 4/5
- Distinct final outputs:
  - `Lo pasamos bien.`
  - `Pasamos un buen rato.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Tuvimos un buen tiempo.` | Tuvimos un buen tiempo. -> Lo pasamos bien. | `Lo pasamos bien.` | correct_fix | Pass | Matches expected output. |
| 2 | `Tuvimos un buen tiempo.` | Tuvimos un buen tiempo. -> Lo pasamos bien. | `Lo pasamos bien.` | correct_fix | Pass | Matches expected output. |
| 3 | `Lo pasamos bien.` | (none) | `Lo pasamos bien.` | correct_fix | Pass | Matches expected output. |
| 4 | `Tuvimos un buen rato.` | Tuvimos -> Pasamos | `Pasamos un buen rato.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Tuvimos un buen tiempo.` | Tuvimos un buen tiempo. -> Lo pasamos bien. | `Lo pasamos bien.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 787 | $0.000588 | 3444 | $0.007550 | 4231 | $0.008138 |
| 2 | 522 | $0.000588 | 5210 | $0.011330 | 5732 | $0.011918 |
| 3 | 682 | $0.000572 | 2251 | $0.003520 | 2933 | $0.004092 |
| 4 | 681 | $0.000588 | 4198 | $0.009290 | 4879 | $0.009878 |
| 5 | 680 | $0.000588 | 3993 | $0.008240 | 4673 | $0.008828 |

### naturalness-corriendo-tarde

- Original text: `Estoy corriendo tarde para la reunión.`
- Expected corrected text: `Voy tarde a la reunión.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Estoy llegando tarde a la reunión.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Estoy llegando tarde para la reunión.` | para -> a | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 2 | `Estoy llegando tarde para la reunión.` | para -> a | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 3 | `Estoy llegando tarde para la reunión.` | para -> a | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 4 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |
| 5 | `Estoy llegando tarde para la reunión.` | para la reunión -> a la reunión | `Estoy llegando tarde a la reunión.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 551 | $0.000590 | 4941 | $0.008600 | 5492 | $0.009190 |
| 2 | 783 | $0.000590 | 3481 | $0.006230 | 4264 | $0.006820 |
| 3 | 640 | $0.000590 | 4371 | $0.008210 | 5011 | $0.008800 |
| 4 | 546 | $0.000590 | 5428 | $0.010460 | 5974 | $0.011050 |
| 5 | 728 | $0.000590 | 3944 | $0.008420 | 4672 | $0.009010 |

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
| 1 | 579 | $0.000588 | 1629 | $0.003860 | 2208 | $0.004448 |
| 2 | 793 | $0.000588 | 1840 | $0.004010 | 2633 | $0.004598 |
| 3 | 736 | $0.000588 | 3326 | $0.003890 | 4062 | $0.004478 |
| 4 | 736 | $0.000588 | 1580 | $0.004040 | 2316 | $0.004628 |
| 5 | 682 | $0.000588 | 1433 | $0.003890 | 2115 | $0.004478 |

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
| 1 | 586 | $0.000588 | 1833 | $0.003890 | 2419 | $0.004478 |
| 2 | 575 | $0.000588 | 1640 | $0.003860 | 2215 | $0.004448 |
| 3 | 680 | $0.000588 | 1508 | $0.004040 | 2188 | $0.004628 |
| 4 | 608 | $0.000588 | 1739 | $0.004100 | 2347 | $0.004688 |
| 5 | 621 | $0.000588 | 2518 | $0.004340 | 3139 | $0.004928 |

### naturalness-llamar-para-atras

- Original text: `Te llamo para atrás.`
- Expected corrected text: `Te devuelvo la llamada.`
- Pass rate: 5/5
- Distinct final outputs:
  - `Te llamo después.`
  - `Te devuelvo la llamada.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Te llamo después.` | (none) | `Te llamo después.` | correct_fix | Pass | Matches expected output. |
| 2 | `Te llamo para atrás.` | Te llamo para atrás -> Te devuelvo la llamada | `Te devuelvo la llamada.` | correct_fix | Pass | Matches expected output. |
| 3 | `Te llamo de vuelta.` | Te llamo de vuelta. -> Te devuelvo la llamada. | `Te devuelvo la llamada.` | correct_fix | Pass | Matches expected output. |
| 4 | `Te llamo después.` | (none) | `Te llamo después.` | correct_fix | Pass | Matches expected output. |
| 5 | `Te llamo después.` | (none) | `Te llamo después.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 577 | $0.000570 | 1434 | $0.003370 | 2011 | $0.003940 |
| 2 | 988 | $0.000578 | 3789 | $0.008265 | 4777 | $0.008843 |
| 3 | 661 | $0.000578 | 6263 | $0.011745 | 6924 | $0.012323 |
| 4 | 771 | $0.000570 | 1342 | $0.003670 | 2113 | $0.004240 |
| 5 | 577 | $0.000570 | 1333 | $0.003460 | 1910 | $0.004030 |

## Valid Regional / Should Not Flag

### regional-voy-para-casa

- Original text: `Voy para casa ahora mismo.`
- Expected corrected text: `Voy para casa ahora mismo.`
- Pass rate: 0/5
- Distinct final outputs:
  - `Voy para la casa ahora mismo.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Voy para la casa ahora mismo.` | (none) | `Voy para la casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Voy para la casa ahora mismo.` | (none) | `Voy para la casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Voy para la casa ahora mismo.` | (none) | `Voy para la casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 4 | `Voy para la casa ahora mismo.` | (none) | `Voy para la casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |
| 5 | `Voy para la casa ahora mismo.` | (none) | `Voy para la casa ahora mismo.` | overcorrection | Fail | Changed the text to something that does not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1204 | $0.000586 | 2751 | $0.006260 | 3955 | $0.006846 |
| 2 | 2830 | $0.000586 | 5017 | $0.009680 | 7847 | $0.010266 |
| 3 | 503 | $0.000586 | 3989 | $0.007490 | 4492 | $0.008076 |
| 4 | 855 | $0.000586 | 3758 | $0.007940 | 4613 | $0.008526 |
| 5 | 914 | $0.000586 | 21505 | $0.010820 | 22419 | $0.011406 |

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
| 1 | 784 | $0.000568 | 1841 | $0.003880 | 2625 | $0.004448 |
| 2 | 682 | $0.000568 | 1738 | $0.003940 | 2420 | $0.004508 |
| 3 | 735 | $0.000568 | 1789 | $0.004060 | 2524 | $0.004628 |
| 4 | 1197 | $0.000568 | 1633 | $0.003760 | 2830 | $0.004328 |
| 5 | 575 | $0.000568 | 1230 | $0.003880 | 1805 | $0.004448 |

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
| 1 | 748 | $0.000598 | 1671 | $0.003865 | 2419 | $0.004463 |
| 2 | 989 | $0.000598 | 1535 | $0.003985 | 2524 | $0.004583 |
| 3 | 593 | $0.000598 | 1929 | $0.003985 | 2522 | $0.004583 |
| 4 | 683 | $0.000598 | 10261 | $0.004075 | 10944 | $0.004673 |
| 5 | 657 | $0.000598 | 1739 | $0.004135 | 2396 | $0.004733 |

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
| 1 | 670 | $0.000598 | 1238 | $0.003265 | 1908 | $0.003863 |
| 2 | 682 | $0.000598 | 1432 | $0.003235 | 2114 | $0.003833 |
| 3 | 576 | $0.000598 | 1843 | $0.003265 | 2419 | $0.003863 |
| 4 | 580 | $0.000598 | 1326 | $0.003235 | 1906 | $0.003833 |
| 5 | 580 | $0.000598 | 1841 | $0.003265 | 2421 | $0.003863 |

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
| 1 | 783 | $0.000598 | 1842 | $0.004675 | 2625 | $0.005273 |
| 2 | 580 | $0.000598 | 1946 | $0.004735 | 2526 | $0.005333 |
| 3 | 780 | $0.000598 | 1436 | $0.004555 | 2216 | $0.005153 |
| 4 | 576 | $0.000598 | 1535 | $0.004345 | 2111 | $0.004943 |
| 5 | 755 | $0.000598 | 1459 | $0.003775 | 2214 | $0.004373 |

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
| 1 | 522 | $0.000588 | 1080 | $0.003140 | 1602 | $0.003728 |
| 2 | 3135 | $0.000588 | 1089 | $0.003260 | 4224 | $0.003848 |
| 3 | 515 | $0.000588 | 1237 | $0.003230 | 1752 | $0.003818 |
| 4 | 610 | $0.000588 | 3625 | $0.003230 | 4235 | $0.003818 |
| 5 | 548 | $0.000588 | 1277 | $0.003200 | 1825 | $0.003788 |

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
| 1 | 784 | $0.000598 | 1399 | $0.003865 | 2183 | $0.004463 |
| 2 | 720 | $0.000598 | 1426 | $0.003625 | 2146 | $0.004223 |
| 3 | 579 | $0.000598 | 1433 | $0.003625 | 2012 | $0.004223 |
| 4 | 605 | $0.000598 | 1345 | $0.003715 | 1950 | $0.004313 |
| 5 | 536 | $0.000598 | 3952 | $0.004045 | 4488 | $0.004643 |

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
| 1 | 519 | $0.000598 | 1536 | $0.004195 | 2055 | $0.004793 |
| 2 | 634 | $0.000598 | 2208 | $0.004705 | 2842 | $0.005303 |
| 3 | 544 | $0.000598 | 2175 | $0.004825 | 2719 | $0.005423 |
| 4 | 574 | $0.000598 | 2049 | $0.004885 | 2623 | $0.005483 |
| 5 | 681 | $0.000598 | 1841 | $0.004585 | 2522 | $0.005183 |

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
| 1 | 579 | $0.000618 | 1227 | $0.003275 | 1806 | $0.003893 |
| 2 | 682 | $0.000618 | 1125 | $0.003245 | 1807 | $0.003863 |
| 3 | 580 | $0.000618 | 1331 | $0.003155 | 1911 | $0.003773 |
| 4 | 624 | $0.000618 | 1078 | $0.003275 | 1702 | $0.003893 |
| 5 | 587 | $0.000618 | 1778 | $0.003245 | 2365 | $0.003863 |

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
| 1 | 634 | $0.000648 | 1128 | $0.003440 | 1762 | $0.004088 |
| 2 | 647 | $0.000648 | 1195 | $0.003560 | 1842 | $0.004208 |
| 3 | 540 | $0.000648 | 1323 | $0.003740 | 1863 | $0.004388 |
| 4 | 585 | $0.000648 | 1640 | $0.003290 | 2225 | $0.003938 |
| 5 | 764 | $0.000648 | 1246 | $0.003290 | 2010 | $0.003938 |

## Mixed Operations

### mixed-preposition-and-redundant-pronoun

- Original text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- Pass rate: 3/5
- Distinct final outputs:
  - `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
  - `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`

| Run | Pass 1 output | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 2 | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | partial_fix | Fail | Changed the text to something that does not match the expected output. |
| 3 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | correct_fix | Pass | Matches expected output. |
| 4 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | correct_fix | Pass | Matches expected output. |
| 5 | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | (none) | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 684 | $0.000716 | 1870 | $0.005485 | 2554 | $0.006201 |
| 2 | 649 | $0.000716 | 1743 | $0.005245 | 2392 | $0.005961 |
| 3 | 577 | $0.000708 | 2662 | $0.005330 | 3239 | $0.006038 |
| 4 | 679 | $0.000708 | 2047 | $0.005480 | 2726 | $0.006188 |
| 5 | 2420 | $0.000708 | 2148 | $0.005600 | 4568 | $0.006308 |

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
| 1 | 682 | $0.000702 | 2050 | $0.004880 | 2732 | $0.005582 |
| 2 | 622 | $0.000702 | 1900 | $0.005540 | 2522 | $0.006242 |
| 3 | 784 | $0.000702 | 2605 | $0.005420 | 3389 | $0.006122 |
| 4 | 633 | $0.000702 | 2049 | $0.005570 | 2682 | $0.006272 |
| 5 | 895 | $0.000702 | 2564 | $0.006350 | 3459 | $0.007052 |

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
| 1 | 562 | $0.000694 | 2869 | $0.006675 | 3431 | $0.007369 |
| 2 | 780 | $0.000694 | 4099 | $0.008115 | 4879 | $0.008809 |
| 3 | 579 | $0.000694 | 2568 | $0.005535 | 3147 | $0.006229 |
| 4 | 566 | $0.000694 | 3277 | $0.007665 | 3843 | $0.008359 |
| 5 | 576 | $0.000694 | 3586 | $0.007065 | 4162 | $0.007759 |

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
| 1 | 564 | $0.000652 | 1962 | $0.004460 | 2526 | $0.005112 |
| 2 | 631 | $0.000652 | 1888 | $0.004490 | 2519 | $0.005142 |
| 3 | 581 | $0.000652 | 2149 | $0.005090 | 2730 | $0.005742 |
| 4 | 781 | $0.000652 | 3688 | $0.004850 | 4469 | $0.005502 |
| 5 | 579 | $0.000652 | 1750 | $0.004670 | 2329 | $0.005322 |

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
| 1 | 565 | $0.000696 | 3996 | $0.009105 | 4561 | $0.009801 |
| 2 | 577 | $0.000696 | 3275 | $0.007845 | 3852 | $0.008541 |
| 3 | 579 | $0.000696 | 2357 | $0.005805 | 2936 | $0.006501 |
| 4 | 677 | $0.000696 | 3178 | $0.007455 | 3855 | $0.008151 |
| 5 | 680 | $0.000696 | 2425 | $0.006015 | 3105 | $0.006711 |

---

## Overall summary

| Metric | Value |
| --- | --- |
| Fixtures | 85 |
| Total runs | 425 |
| Pass rate | 392/425 |

### Score breakdown (issue #129 — full taxonomy, not only pass/fail)

| | Total | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| All runs | 425 | 328 | 6 | 15 | 6 | 64 | 6 | 0 |

### Latency / cost by pass (issue #130 — no fallback phase exists in this harness, so totals equal Pass 1 + Pass 2 only)

| Phase | Total latency (ms) | Total est. cost (USD) |
| --- | --- | --- |
| Pass 1 (first pass) | 301580 | $0.255014 |
| Pass 2 (lexical review) | 870569 | $1.941095 |
| **Total (Pass 1 + Pass 2)** | 1172149 | $2.196109 |
