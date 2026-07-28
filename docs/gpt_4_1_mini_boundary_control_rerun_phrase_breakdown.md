# GPT-4.1 Mini Boundary-Control Rerun Phrase Breakdown

Source run: Spanish Correction Model Comparison Harness  
Prompt label: `simple-spanish-grammar-spelling-punctuation-only`  
Prompt version: `v1`  
Model: `gpt-4.1-mini`  
Generated: `2026-07-28T20:10:26.449896Z`  
Git branch: `correction_pipeline_refactor`  
Git commit: `d398d715f1b2fb1cf52f5453901f3bc3c825248e`

## Overall Result

| Metric | Result |
|---|---:|
| Cases | 10 |
| Valid JSON | 10/10 |
| Task success | 7/10 |
| Grammar-boundary corrections | 3/3 |
| Missed grammar fixes | 0/3 |
| Controls unchanged | 4/7 |
| Over-corrections | 3/7 |
| Average latency | 0.791 seconds |
| Total tokens | 1,821 |
| Total estimated cost | $0.000932 / 0.0932 cents |

## Phrase-Level Breakdown

### 1. `boundary-redundant-yo`

Purpose: pure unchanged boundary control. Tests whether the model removes redundant but grammatical subject pronouns.

| Field | Value |
|---|---|
| Input | `Yo trabajo mucho y yo también estudio por las noches.` |
| Expected output | `Yo trabajo mucho y yo también estudio por las noches.` |
| Actual output | `Yo trabajo mucho y también estudio por las noches.` |
| Result | Fail |
| Failing | Removed the second grammatical `yo`. This is a redundant-pronoun/style edit rather than a spelling or punctuation correction, though it may be acceptable if redundant pronouns are later treated as in-scope. |
| Review status | `over_correction` |
| Latency | 1.007 seconds |
| Cost | $0.000092 / 0.0092 cents |

### 2. `boundary-redundant-ellos`

Purpose: pure unchanged boundary control. Tests whether the model removes repeated but grammatical subject pronouns.

| Field | Value |
|---|---|
| Input | `Ellos viajaron a México y ellos visitaron varias ciudades.` |
| Expected output | `Ellos viajaron a México y ellos visitaron varias ciudades.` |
| Actual output | `Ellos viajaron a México y visitaron varias ciudades.` |
| Result | Fail |
| Failing | Removed the second grammatical `ellos`. This is a redundant-pronoun/style edit rather than a spelling or punctuation correction, though it may be acceptable if redundant pronouns are later treated as in-scope. |
| Review status | `over_correction` |
| Latency | 0.963 seconds |
| Cost | $0.000096 / 0.0096 cents |

### 3. `boundary-para-casa`

Purpose: pure unchanged boundary control. Tests whether the model incorrectly normalizes valid `para casa` usage.

| Field | Value |
|---|---|
| Input | `Está lloviendo, así que voy para casa ahora mismo.` |
| Expected output | `Está lloviendo, así que voy para casa ahora mismo.` |
| Actual output | `Está lloviendo, así que voy para casa ahora mismo.` |
| Result | Pass |
| Failing | None. The model left the valid regional/dialectal construction unchanged. |
| Review status | `unchanged_control` |
| Latency | 0.679 seconds |
| Cost | $0.000097 / 0.0097 cents |

### 4. `boundary-regional-coger`

Purpose: pure unchanged boundary control. Tests whether the model rewrites valid Peninsular Spanish because a word is dialectally sensitive.

| Field | Value |
|---|---|
| Input | `Cada mañana cojo el autobús para llegar a la oficina.` |
| Expected output | `Cada mañana cojo el autobús para llegar a la oficina.` |
| Actual output | `Cada mañana cojo el autobús para llegar a la oficina.` |
| Result | Pass |
| Failing | None. The model left valid Peninsular Spanish unchanged. |
| Review status | `unchanged_control` |
| Latency | 0.594 seconds |
| Cost | $0.000097 / 0.0097 cents |

### 5. `boundary-regional-preterite`

Purpose: pure unchanged boundary control. Tests whether the model changes a valid preterite/present-perfect regional tense preference.

| Field | Value |
|---|---|
| Input | `Esta mañana hablé con mi jefe sobre el proyecto nuevo.` |
| Expected output | `Esta mañana hablé con mi jefe sobre el proyecto nuevo.` |
| Actual output | `Esta mañana hablé con mi jefe sobre el proyecto nuevo.` |
| Result | Pass |
| Failing | None. The model left the valid tense choice unchanged. |
| Review status | `unchanged_control` |
| Latency | 1.223 seconds |
| Cost | $0.000095 / 0.0095 cents |

### 6. `boundary-calque-llamar-para-atras`

Purpose: word-choice/naturalness boundary control. Tests whether the model rewrites a calque as a naturalness improvement.

| Field | Value |
|---|---|
| Input | `Te llamo para atrás cuando termine la reunión.` |
| Expected output | `Te llamo para atrás cuando termine la reunión.` |
| Actual output | `Te llamo para atrás cuando termine la reunión.` |
| Result | Pass |
| Failing | None. The added prompt wording protected this calque from being rewritten. |
| Review status | `unchanged_control` |
| Latency | 0.587 seconds |
| Cost | $0.000091 / 0.0091 cents |

### 7. `boundary-collocation-hacer-decision`

Purpose: word-choice/naturalness boundary control. Tests whether the model rewrites an unnatural collocation such as `hacer una decisión` to `tomar una decisión`.

| Field | Value |
|---|---|
| Input | `Necesito hacer una decisión importante antes del viernes.` |
| Expected output | `Necesito hacer una decisión importante antes del viernes.` |
| Actual output | `Necesito tomar una decisión importante antes del viernes.` |
| Result | Fail |
| Failing | Rewrote `hacer una decisión` to `tomar una decisión`, which is a collocation/word-choice correction outside the current prompt scope. This remains the main meaningful boundary failure after the prompt tweak. |
| Review status | `over_correction` |
| Latency | 0.610 seconds |
| Cost | $0.000091 / 0.0091 cents |

### 8. `boundary-gustar-agreement`

Purpose: grammar-boundary correction. Tests true verb agreement in a construction learners often experience as lexical or idiomatic.

| Field | Value |
|---|---|
| Input | `Me gusta las películas de acción los fines de semana.` |
| Expected output | `Me gustan las películas de acción los fines de semana.` |
| Actual output | `Me gustan las películas de acción los fines de semana.` |
| Result | Pass |
| Failing | None. The model corrected the objective `gustar` agreement error. |
| Review status | `expected_correction` |
| Latency | 0.780 seconds |
| Cost | $0.000093 / 0.0093 cents |

### 9. `boundary-missing-que`

Purpose: grammar-boundary correction. Tests whether the model corrects an omitted complementizer without rewriting the sentence.

| Field | Value |
|---|---|
| Input | `Creo está bien terminar el proyecto esta semana.` |
| Expected output | `Creo que está bien terminar el proyecto esta semana.` |
| Actual output | `Creo que está bien terminar el proyecto esta semana.` |
| Result | Pass |
| Failing | None. The model added the missing `que` without rewriting the sentence. |
| Review status | `expected_correction` |
| Latency | 0.790 seconds |
| Cost | $0.000091 / 0.0091 cents |

### 10. `boundary-ser-estar-profesor`

Purpose: grammar-boundary correction. Tests objective `ser`/`estar` correction without changing wording beyond the verb.

| Field | Value |
|---|---|
| Input | `Mi hermano está profesor en una escuela secundaria.` |
| Expected output | `Mi hermano es profesor en una escuela secundaria.` |
| Actual output | `Mi hermano es profesor en una escuela secundaria.` |
| Result | Pass |
| Failing | None. The model corrected the objective `ser`/`estar` error without additional wording changes. |
| Review status | `expected_correction` |
| Latency | 0.672 seconds |
| Cost | $0.000089 / 0.0089 cents |

## Interpretation

The rerun improved from 6/10 to 7/10.

The added prompt wording successfully protected the calque case:

```text
Te llamo para atrás cuando termine la reunión.
```

It did not protect the collocation case:

```text
Necesito hacer una decisión importante antes del viernes.
```

`gpt-4.1-mini` still corrected all true grammar-boundary cases:

- `Me gusta` -> `Me gustan`
- missing `que`
- `está profesor` -> `es profesor`

The remaining meaningful issue is collocation/word-combination correction. The redundant pronoun changes remain marked as over-corrections by this test, but they may be acceptable if redundant pronouns are later treated as in-scope for the correction layer.
