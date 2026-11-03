# Two-Pass Language Point Test Map

Purpose: define the language points that should drive the next two-pass proof-of-concept harness. This is a test-planning document only. It does not change prompts, model behavior, merge/fallback mechanics, UI behavior, or production correction code.

The current goal is to test whether the two-pass approach is reliable, faster, and cheaper than the previous staged pipeline. The harness should measure final corrected text quality, fallback rate, latency, token usage, and cost before solving first-pass correction cards or highlighting.

## Scoring Labels

Use these labels when reviewing each run:

| Label | Meaning |
| --- | --- |
| `correct_fix` | The system fixed the intended issue correctly. |
| `partial_fix` | The system changed something useful but left the target issue unresolved or only partly resolved. |
| `missed_issue` | The system left a real issue untouched. |
| `overcorrection` | The system changed acceptable Spanish unnecessarily. |
| `acceptable_no_change` | The system correctly left acceptable Spanish unchanged. |
| `ambiguous` | The Spanish judgment is not clean enough for a strict pass/fail. |
| `error` | The run failed, timed out, returned invalid JSON, or otherwise could not be scored normally. |

## Operation Types

Each fixture should also be tagged by edit operation:

| Operation | Meaning |
| --- | --- |
| `replacement` | Replace existing text with different text. |
| `insertion` | Add missing text where nothing exists. |
| `deletion` | Remove unnecessary text. |
| `mixed` | More than one operation type appears in the same input. |
| `no_change` | The expected behavior is to leave the text unchanged. |

## Language Point Matrix

### 1. Accents / Diacritics

Existing anchors: `short-phrase-missing-accent`, `harder-accent-marks-diacritics`, `paragraph-mixed-errors`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `accent-manana` | `Voy al parque manana por la tarde.` | `Voy al parque mañana por la tarde.` | `replacement` |
| `accent-medico` | `El medico llego despues de la reunion.` | `El médico llegó después de la reunión.` | `replacement` |
| `accent-espana-pais` | `Espana es un pais muy diverso.` | `España es un país muy diverso.` | `replacement` |
| `accent-cumpleanos-otono` | `Mi cumpleanos es en otono.` | `Mi cumpleaños es en otoño.` | `replacement` |
| `accent-cafe-cafeteria` | `Compre cafe en una cafeteria pequena.` | `Compré café en una cafetería pequeña.` | `replacement` |

### 2. Gender / Number Agreement

Existing anchors: `sentence-grammar-agreement`, `harder-gender-number-agreement`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `agreement-ninos-manzanas` | `Los niño come muchas manzana.` | `Los niños comen muchas manzanas.` | `replacement` |
| `agreement-ventanas-abiertas` | `Las ventanas estaban abierto.` | `Las ventanas estaban abiertas.` | `replacement` |
| `agreement-puerta-cerrada` | `Una puerta estaba cerrado.` | `Una puerta estaba cerrada.` | `replacement` |
| `agreement-billetes-caros` | `Los billetes estaban caro.` | `Los billetes estaban caros.` | `replacement` |
| `agreement-fechas-escritas` | `Las fechas estaban escrito sin tilde.` | `Las fechas estaban escritas sin tilde.` | `replacement` |

### 3. Verb Agreement / Morphology

Existing anchors: `harder-verb-morphology-agreement`, `sentence-grammar-agreement`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `verb-nosotros-fuimos` | `Mis compañeros y yo fue a la biblioteca.` | `Mis compañeros y yo fuimos a la biblioteca.` | `replacement` |
| `verb-ninos-comen` | `Los niños come en el jardín.` | `Los niños comen en el jardín.` | `replacement` |
| `verb-compre-pan` | `Yo fui al mercado y compra pan.` | `Yo fui al mercado y compré pan.` | `replacement` |
| `verb-ellos-estudian` | `Ellos estudia todas las noches.` | `Ellos estudian todas las noches.` | `replacement` |
| `verb-nosotros-vivimos` | `Nosotros vive cerca del centro.` | `Nosotros vivimos cerca del centro.` | `replacement` |

### 4. Required Prepositions

Existing anchors: `harder-preposition-government`, `harder-relative-clause-preposition`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `prep-insisto-en` | `Insisto que revises el contrato.` | `Insisto en que revises el contrato.` | `insertion` |
| `prep-empresa-en-la-que` | `La empresa que trabajo está cerca.` | `La empresa en la que trabajo está cerca.` | `insertion` |
| `prep-dependo-de` | `Dependo que me ayudes mañana.` | `Dependo de que me ayudes mañana.` | `insertion` |
| `prep-pienso-en-ti` | `Pienso ti todos los días.` | `Pienso en ti todos los días.` | `insertion` |
| `prep-sone-con` | `Soñé mi antiguo colegio.` | `Soñé con mi antiguo colegio.` | `insertion` |

### 5. Articles / Determiners

Existing anchor: `harder-articles-determiners`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `article-puerta-principal` | `Abrió puerta principal.` | `Abrió la puerta principal.` | `insertion` |
| `article-un-libro` | `Necesito comprar libro para la clase.` | `Necesito comprar un libro para la clase.` | `insertion` |
| `article-el-profesor-la-regla` | `Profesor explicó regla otra vez.` | `El profesor explicó la regla otra vez.` | `insertion` |
| `article-la-tienda` | `Fui a tienda después del trabajo.` | `Fui a la tienda después del trabajo.` | `insertion` |
| `article-cita-medico` | `Tengo cita con médico mañana.` | `Tengo una cita con el médico mañana.` | `insertion` |

### 6. Subjunctive / Mood

Existing anchors: `harder-subjunctive-mood`, `harder-mixed-b2-c1-paragraph`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `subj-estudies` | `Es importante que estudias.` | `Es importante que estudies.` | `replacement` |
| `subj-tenga-razon` | `No creo que tiene razón.` | `No creo que tenga razón.` | `replacement` |
| `subj-vengas` | `Quiero que vienes conmigo.` | `Quiero que vengas conmigo.` | `replacement` |
| `subj-enviara` | `Era necesario que enviaba su parte.` | `Era necesario que enviara su parte.` | `replacement` |
| `subj-hable-frances` | `Busco a alguien que habla francés.` | `Busco a alguien que hable francés.` | `replacement` |

### 7. Required Additions / Omissions

Existing anchors: `boundary-missing-que`, `harder-object-pronouns-clitics`, `harder-personal-a`, Stage 1C reflexive tests.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `missing-que-creo` | `Creo está bien terminar hoy.` | `Creo que está bien terminar hoy.` | `insertion` |
| `missing-les-ninos` | `A los niños expliqué la regla.` | `A los niños les expliqué la regla.` | `insertion` |
| `missing-personal-a-profesor` | `Vi mi profesor en la estación.` | `Vi a mi profesor en la estación.` | `insertion` |
| `missing-se-levanto` | `Levantó temprano ayer.` | `Se levantó temprano ayer.` | `insertion` |
| `missing-le-gusta` | `A Juan gusta el café.` | `A Juan le gusta el café.` | `insertion` |

### 8. Unnecessary Extras / Deletions

Existing anchors: `boundary-redundant-yo`, `boundary-redundant-ellos`, staged redundant-pronoun tests.

Expected owner: first pass may catch. For POC scoring, judge final corrected text rather than correction-card detail.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `delete-repeated-yo-estudio` | `Yo trabajo mucho y yo estudio por las noches.` | `Yo trabajo mucho y estudio por las noches.` | `deletion` |
| `delete-repeated-ellos-visitaron` | `Ellos viajaron a México y ellos visitaron varias ciudades.` | `Ellos viajaron a México y visitaron varias ciudades.` | `deletion` |
| `delete-repeated-a-mi` | `A mí me gusta el café a mí.` | `A mí me gusta el café.` | `deletion` |
| `delete-repeated-yo-compre` | `Yo fui al mercado y yo compré pan.` | `Fui al mercado y compré pan.` | `deletion` |
| `delete-repeated-nosotros` | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Nosotros salimos temprano y llegamos a tiempo.` | `deletion` |

Note: some single subject pronouns are acceptable when used for emphasis. These cases are intended to test repeated pronouns where the repetition adds nothing.

### 9. Ser / Estar / Haber

Existing anchors: `boundary-ser-estar-profesor`, `harder-ser-estar-haber`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `ser-profesor` | `Mi hermano está profesor.` | `Mi hermano es profesor.` | `replacement` |
| `haber-veinte-personas` | `En la sala son veinte personas.` | `En la sala hay veinte personas.` | `replacement` |
| `ser-capital-madrid` | `Madrid está la capital de España.` | `Madrid es la capital de España.` | `replacement` |
| `estar-contento` | `Estoy muy contento con el resultado.` | `Estoy muy contento con el resultado.` | `no_change` |
| `ser-reunion-segunda-planta` | `La reunión es en la segunda planta.` | `La reunión es en la segunda planta.` | `no_change` |

### 10. Impersonal Haber / Se

Existing anchors: `harder-impersonal-haber-se`, `harder-near-limit-mixed-text`.

Expected owner: first pass.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `haber-habia-personas` | `Habían muchas personas en la entrada.` | `Había muchas personas en la entrada.` | `replacement` |
| `haber-hubo-problemas` | `Hubieron varios problemas durante la reunión.` | `Hubo varios problemas durante la reunión.` | `replacement` |
| `se-venden-pisos` | `Se vende pisos en el centro.` | `Se venden pisos en el centro.` | `replacement` |
| `se-necesitan-voluntarios` | `Se necesita voluntarios para el evento.` | `Se necesitan voluntarios para el evento.` | `replacement` |
| `haber-habia-cifras` | `Habían varias cifras incorrectas.` | `Había varias cifras incorrectas.` | `replacement` |

### 11. Collocations / Strong Calques

Existing anchors: `lexical-collocation-*`, `naturalness-collocation-*`.

Expected owner: either pass acceptable for POC, but record which pass solved it.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `collocation-hacer-decision` | `Necesito hacer una decisión.` | `Necesito tomar una decisión.` | `replacement` |
| `collocation-hacer-atencion` | `Tenemos que hacer atención.` | `Tenemos que prestar atención.` | `replacement` |
| `collocation-tomar-reunion` | `El equipo tomó una reunión.` | `El equipo tuvo una reunión.` | `replacement` |
| `collocation-hacer-paseo` | `Ella hizo un paseo.` | `Ella dio un paseo.` | `replacement` |
| `collocation-hace-sentido` | `Esto hace sentido.` | `Esto tiene sentido.` | `replacement` |

### 12. False Friends / Word Choice

Existing anchors: merged-results set; adjacent to naturalness and lexical harnesses.

Expected owner: either pass acceptable for POC, but record whether first pass, naturalness, or fallback solved it.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `false-friend-atendio-universidad` | `Atendió la universidad en Madrid.` | `Asistió a la universidad en Madrid.` | `replacement` |
| `false-friend-aplico-trabajo` | `Aplicó para un trabajo.` | `Solicitó un trabajo.` | `replacement` |
| `false-friend-realice` | `Realicé que estaba equivocado.` | `Me di cuenta de que estaba equivocado.` | `replacement` |
| `false-friend-embarazado` | `Estoy embarazado por llegar tarde.` | `Me da vergüenza llegar tarde.` | `replacement` |
| `false-friend-actualmente-control` | `Actualmente vivo en Londres.` | `Actualmente vivo en Londres.` | `no_change` |

### 13. Phrase-Level Naturalness

Existing anchors: `naturalness-es4-calque-pair`, merged-results `running-late`, `have-good-time`.

Expected owner: naturalness pass, unless first pass already produces an acceptable correction. Record which pass solved it.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `naturalness-buen-tiempo` | `Tuvimos un buen tiempo.` | `Lo pasamos bien.` | `replacement` |
| `naturalness-corriendo-tarde` | `Estoy corriendo tarde para la reunión.` | `Voy tarde a la reunión.` | `replacement` |
| `naturalness-pasar-buen-tiempo` | `Quiero pasar un buen tiempo.` | `Quiero pasarlo bien.` | `replacement` |
| `naturalness-puedo-tener-cerveza` | `¿Puedo tener una cerveza?` | `¿Me pones una cerveza?` | `replacement` |
| `naturalness-llamar-para-atras` | `Te llamo para atrás.` | `Te devuelvo la llamada.` | `replacement` |

### 14. Valid Regional / Should Not Flag

Existing anchors: `boundary-para-casa`, `sentence-correct-voseo`, `boundary-regional-coger`.

Expected owner: no pass should change these.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `regional-voy-para-casa` | `Voy para casa ahora mismo.` | `Voy para casa ahora mismo.` | `no_change` |
| `regional-vos-tenes` | `Vos tenés razón.` | `Vos tenés razón.` | `no_change` |
| `regional-cojo-autobus` | `Cojo el autobús cada mañana.` | `Cojo el autobús cada mañana.` | `no_change` |
| `regional-preterite-esta-manana` | `Esta mañana hablé con mi jefe.` | `Esta mañana hablé con mi jefe.` | `no_change` |
| `regional-dale` | `Dale, nos vemos más tarde.` | `Dale, nos vemos más tarde.` | `no_change` |

### 15. Already Correct / Do Not Tinker

Existing anchors: `short-phrase-already-correct`, `two-paragraph-already-correct`, naturalness controls.

Expected owner: no pass should change these.

| ID | Input | Expected output | Operation |
| --- | --- | --- | --- |
| `correct-buenos-dias` | `Buenos días, ¿cómo estás?` | `Buenos días, ¿cómo estás?` | `no_change` |
| `correct-hacer-pregunta` | `Voy a hacer una pregunta al profesor.` | `Voy a hacer una pregunta al profesor.` | `no_change` |
| `correct-tomar-foto` | `Necesito tomar una foto del documento.` | `Necesito tomar una foto del documento.` | `no_change` |
| `correct-visitar-abuela` | `Mañana visitaré a mi abuela.` | `Mañana visitaré a mi abuela.` | `no_change` |
| `correct-me-quedo-en-casa` | `Está lloviendo, así que me quedo en casa.` | `Está lloviendo, así que me quedo en casa.` | `no_change` |

## Harness Guidance

The next harness should report, per fixture:

- language point
- operation type
- expected owner (`first_pass`, `naturalness`, `either`, or `no_change`)
- first-pass output
- naturalness-on-original output
- naturalness-after-first-pass output where measured
- final merged output
- scoring label
- fallback used
- per-call latency
- total latency
- token usage
- estimated cost
- errors or invalid responses

Do not treat a model's changed output as a success by itself. The scoring should distinguish a correct fix from a partial fix, a harmless alternative, an overcorrection, and a missed issue.
