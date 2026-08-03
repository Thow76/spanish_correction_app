# Two-Pass Fallback Prompt Comparison: Full Pipeline (issue #117)

## Run configuration

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture count: `17`
- Generated: 2026-08-03T20:36:42.355072Z

Pass 1 and the parallel naturalness call are run once per fixture and shared between both variants below — only the fallback call itself (run once per variant, only when the real conflict logic in `mergeNaturalnessReview` actually triggers it) differs.

## Accents / Diacritics

### clean-grammar-only

- Original text: `Vi mucho trafico ayer.`
- Expected corrected text: `Vi mucho tráfico ayer.`
- Pass 1 (first-pass corrected text): `Vi mucho tráfico ayer.`
- Pass 2 (naturalness on original): mucho trafico -> mucho tráfico
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |

## Already Correct / Do Not Tinker

### correct-tomar-foto

- Original text: `Necesito tomar una foto del documento.`
- Expected corrected text: `Necesito tomar una foto del documento.`
- Pass 1 (first-pass corrected text): `Necesito tomar una foto del documento.`
- Pass 2 (naturalness on original): tomar una foto -> sacar una foto
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Necesito sacar una foto del documento.` | overcorrection | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |
| Candidate (fallback-specific) | (fallback not triggered) | `Necesito sacar una foto del documento.` | overcorrection | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |

### correct-buenos-dias

- Original text: `Buenos días, ¿cómo estás?`
- Expected corrected text: `Buenos días, ¿cómo estás?`
- Pass 1 (first-pass corrected text): `Buenos días, ¿cómo estás?`
- Pass 2 (naturalness on original): (none)
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Buenos días, ¿cómo estás?` | acceptable_no_change | Matches expected output; already-correct first-pass text was left unchanged. |
| Candidate (fallback-specific) | (fallback not triggered) | `Buenos días, ¿cómo estás?` | acceptable_no_change | Matches expected output; already-correct first-pass text was left unchanged. |

## Valid Regional / Should Not Flag

### regional-voy-para-casa

- Original text: `Voy para casa ahora mismo.`
- Expected corrected text: `Voy para casa ahora mismo.`
- Pass 1 (first-pass corrected text): `Voy para casa ahora mismo.`
- Pass 2 (naturalness on original): (none)
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Voy para casa ahora mismo.` | acceptable_no_change | Matches expected output; already-correct first-pass text was left unchanged. |
| Candidate (fallback-specific) | (fallback not triggered) | `Voy para casa ahora mismo.` | acceptable_no_change | Matches expected output; already-correct first-pass text was left unchanged. |

## Phrase-Level Naturalness

### naturalness-buen-tiempo

- Original text: `Tuvimos un buen tiempo.`
- Expected corrected text: `Lo pasamos bien.`
- Pass 1 (first-pass corrected text): `Tuvimos un buen tiempo.`
- Pass 2 (naturalness on original): Tuvimos un buen tiempo. -> Lo pasamos bien.
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Lo pasamos bien.` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |
| Candidate (fallback-specific) | (fallback not triggered) | `Lo pasamos bien.` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |

### naturalness-corriendo-tarde

- Original text: `Estoy corriendo tarde para la reunión.`
- Expected corrected text: `Voy tarde a la reunión.`
- Pass 1 (first-pass corrected text): `Estoy corriendo tarde para la reunión.`
- Pass 2 (naturalness on original): corriendo tarde -> llegando tarde
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Estoy llegando tarde para la reunión.` | partial_fix | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |
| Candidate (fallback-specific) | (fallback not triggered) | `Estoy llegando tarde para la reunión.` | partial_fix | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |

### naturalness-pasar-buen-tiempo

- Original text: `Quiero pasar un buen tiempo.`
- Expected corrected text: `Quiero pasarlo bien.`
- Pass 1 (first-pass corrected text): `Quiero pasar un buen tiempo.`
- Pass 2 (naturalness on original): pasar un buen tiempo -> pasarlo bien
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Quiero pasarlo bien.` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |
| Candidate (fallback-specific) | (fallback not triggered) | `Quiero pasarlo bien.` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |

### naturalness-puedo-tener-cerveza

- Original text: `¿Puedo tener una cerveza?`
- Expected corrected text: `¿Me pones una cerveza?`
- Pass 1 (first-pass corrected text): `¿Puedo tener una cerveza?`
- Pass 2 (naturalness on original): ¿Puedo tener una cerveza? -> ¿Me pones una cerveza?
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `¿Me pones una cerveza?` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |
| Candidate (fallback-specific) | (fallback not triggered) | `¿Me pones una cerveza?` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |

## Mixed Operations

### mixed-personal-a-and-subjunctive

- Original text: `Vi mi profesor en la estación, y es importante que estudias.`
- Expected corrected text: `Vi a mi profesor en la estación, y es importante que estudies.`
- Pass 1 (first-pass corrected text): `Vi a mi profesor en la estación, y es importante que estudies.`
- Pass 2 (naturalness on original): Vi mi profesor en la estación -> Vi a mi profesor en la estación<br>es importante que estudias -> es importante que estudies
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | Vi a mi profesor en la estación, y es importante que estudies. -> Vi a mi profesor en la estación, y me dijo que es importante que estudies. | `Vi a mi profesor en la estación, y me dijo que es importante que estudies.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | Vi a mi profesor en la estación, y es importante que estudies. -> Vi a mi profesor en la estación. Es importante que estudies. | `Vi a mi profesor en la estación. Es importante que estudies.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |

### mixed-verb-agreement-and-missing-que

- Original text: `Ellos estudia todas las noches, y creo está bien terminar hoy.`
- Expected corrected text: `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- Pass 1 (first-pass corrected text): `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- Pass 2 (naturalness on original): Ellos estudia todas las noches -> Ellos estudian todas las noches<br>y creo está bien terminar hoy -> y creo que está bien terminar hoy
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | Ellos estudian todas las noches -> Estudian todas las noches<br>está bien terminar hoy -> podemos terminar por hoy | `Estudian todas las noches, y creo que podemos terminar por hoy.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | creo que está bien terminar hoy -> creo que podemos terminar hoy | `Ellos estudian todas las noches, y creo que podemos terminar hoy.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |

### mixed-preposition-and-redundant-pronoun

- Original text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- Pass 1 (first-pass corrected text): `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Pass 2 (naturalness on original): Insisto que revises el contrato -> Insisto en que revises el contrato<br>y yo trabajo mucho y yo estudio por las noches -> yo trabajo mucho y estudio por las noches
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches. | `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.` | partial_fix | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | y yo trabajo mucho y yo estudio por las noches -> yo trabajo mucho y estudio por las noches | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` | partial_fix | Fallback changed the first-pass text to something that does not match the expected output. |

## False Friends / Word Choice

### false-friend-atendio-universidad

- Original text: `Atendió la universidad en Madrid.`
- Expected corrected text: `Asistió a la universidad en Madrid.`
- Pass 1 (first-pass corrected text): `Atendió la universidad en Madrid.`
- Pass 2 (naturalness on original): Atendió la universidad en Madrid. -> Estudió en la universidad de Madrid.
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Estudió en la universidad de Madrid.` | ambiguous | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |
| Candidate (fallback-specific) | (fallback not triggered) | `Estudió en la universidad de Madrid.` | ambiguous | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |

### false-friend-aplico-trabajo

- Original text: `Aplicó para un trabajo.`
- Expected corrected text: `Solicitó un trabajo.`
- Pass 1 (first-pass corrected text): `Aplicó a un trabajo.`
- Pass 2 (naturalness on original): Aplicó para un trabajo. -> Solicitó un trabajo.
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | Aplicó a un trabajo. -> Se postuló a un trabajo. | `Se postuló a un trabajo.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | Aplicó a un trabajo. -> Solicitó un trabajo. | `Solicitó un trabajo.` | correct_fix | Matches expected output after the fallback edit was applied. |

### false-friend-embarazado

- Original text: `Estoy embarazado por llegar tarde.`
- Expected corrected text: `Me da vergüenza llegar tarde.`
- Pass 1 (first-pass corrected text): `Estoy embarazado por llegar tarde.`
- Pass 2 (naturalness on original): Estoy embarazado por llegar tarde. -> Me da vergüenza llegar tarde.
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Me da vergüenza llegar tarde.` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |
| Candidate (fallback-specific) | (fallback not triggered) | `Me da vergüenza llegar tarde.` | correct_fix | Matches expected output after the parallel naturalness edit was applied. |

## Subjunctive / Mood

### subj-enviara

- Original text: `Era necesario que enviaba su parte.`
- Expected corrected text: `Era necesario que enviara su parte.`
- Pass 1 (first-pass corrected text): `Era necesario que enviara su parte.`
- Pass 2 (naturalness on original): Era necesario que enviaba su parte. -> Era necesario que enviara su parte.
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | enviara su parte -> enviara su informe | `Era necesario que enviara su informe.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |

## Ambiguous / Repeated Span Safety (Naturalness)

### ambiguous-naturalness-span

- Original text: `Vi mucho tráfico, y luego vi más tráfico.`
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Pass 1 (first-pass corrected text): `Vi mucho tráfico, y luego vi más tráfico.`
- Pass 2 (naturalness on original): luego vi más tráfico -> después vi todavía más tráfico
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Vi mucho tráfico, y después vi todavía más tráfico.` | overcorrection | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |
| Candidate (fallback-specific) | (fallback not triggered) | `Vi mucho tráfico, y después vi todavía más tráfico.` | overcorrection | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |

## Articles / Determiners

### article-la-tienda

- Original text: `Fui a tienda después del trabajo.`
- Expected corrected text: `Fui a la tienda después del trabajo.`
- Pass 1 (first-pass corrected text): `Fui a la tienda después del trabajo.`
- Pass 2 (naturalness on original): a tienda -> a la tienda
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Fui a la la tienda después del trabajo.` | ambiguous | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |
| Candidate (fallback-specific) | (fallback not triggered) | `Fui a la la tienda después del trabajo.` | ambiguous | Fallback was never triggered (no conflict), but the parallel merge alone still did not produce the expected output. |

---

## Overall summary

Both variants score identically on every fixture where fallback was never triggered, since neither variant's fallback call runs in that case — the "all fixtures" rate below is diluted by those shared results and is not the number that speaks to the fallback prompt itself. The "fallback-triggered fixtures only" rate is the one that actually compares the two prompts.

| Metric | Value |
| --- | --- |
| Fixtures | 17 |
| Fixtures where fallback triggered | 6 |
| Fixtures where fallback did not trigger | 11 |
| Current pass rate, fallback-triggered fixtures only | 0/6 |
| Candidate pass rate, fallback-triggered fixtures only | 1/6 |
| Current pass rate, non-triggered fixtures only | 6/11 |
| Candidate pass rate, non-triggered fixtures only | 6/11 |
| Current pass rate, all fixtures (diluted, see note above) | 6/17 |
| Candidate pass rate, all fixtures (diluted, see note above) | 7/17 |
