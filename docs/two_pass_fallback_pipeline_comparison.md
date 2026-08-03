# Two-Pass Fallback Prompt Comparison: Full Pipeline (issue #117)

## Run configuration

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture count: `10`
- Generated: 2026-08-03T19:24:46.404836Z

Pass 1 and the parallel naturalness call are run once per fixture and shared between both variants below — only the fallback call itself (run once per variant, only when the real conflict logic in `mergeNaturalnessReview` actually triggers it) differs.

## Accents / Diacritics

### clean-grammar-only

- Original text: `Vi mucho trafico ayer.`
- Expected corrected text: `Vi mucho tráfico ayer.`
- Pass 1 (first-pass corrected text): `Vi mucho tráfico ayer.`
- Pass 2 (naturalness on original): Vi mucho trafico ayer. -> Había mucho tráfico ayer.
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | Vi mucho tráfico ayer. -> Había mucho tráfico ayer. | `Había mucho tráfico ayer.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | Vi mucho tráfico ayer. -> Ayer había mucho tráfico. | `Ayer había mucho tráfico.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |

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
| Current (reused prompt) | (fallback not triggered) | `Lo pasamos bien.` | correct_fix | Matches expected output after the fallback edit was applied. |
| Candidate (fallback-specific) | (fallback not triggered) | `Lo pasamos bien.` | correct_fix | Matches expected output after the fallback edit was applied. |

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

## Mixed Operations

### mixed-personal-a-and-subjunctive

- Original text: `Vi mi profesor en la estación, y es importante que estudias.`
- Expected corrected text: `Vi a mi profesor en la estación, y es importante que estudies.`
- Pass 1 (first-pass corrected text): `Vi a mi profesor en la estación, y es importante que estudies.`
- Pass 2 (naturalness on original): Vi mi profesor en la estación -> Vi a mi profesor en la estación<br>es importante que estudias -> es importante que estudies
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | Vi a mi profesor en la estación, y es importante que estudies. -> Vi a mi profesor en la estación, y es importante que estudie. | `Vi a mi profesor en la estación, y es importante que estudie.` | partial_fix | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | (none) | `Vi a mi profesor en la estación, y es importante que estudies.` | correct_fix | Matches expected output; already-correct first-pass text was left unchanged. |

### mixed-verb-agreement-and-missing-que

- Original text: `Ellos estudia todas las noches, y creo está bien terminar hoy.`
- Expected corrected text: `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- Pass 1 (first-pass corrected text): `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- Pass 2 (naturalness on original): Ellos estudia -> Ellos estudian<br>creo está bien terminar hoy -> creo que está bien terminar hoy
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | está bien terminar hoy -> podemos terminar por hoy | `Ellos estudian todas las noches, y creo que podemos terminar por hoy.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | (none) | `Ellos estudian todas las noches, y creo que está bien terminar hoy.` | correct_fix | Matches expected output; already-correct first-pass text was left unchanged. |

## False Friends / Word Choice

### false-friend-atendio-universidad

- Original text: `Atendió la universidad en Madrid.`
- Expected corrected text: `Asistió a la universidad en Madrid.`
- Pass 1 (first-pass corrected text): `Atendió la universidad en Madrid.`
- Pass 2 (naturalness on original): Atendió la universidad en Madrid. -> Asistió a la universidad en Madrid.
- Fallback triggered: false

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | (fallback not triggered) | `Asistió a la universidad en Madrid.` | correct_fix | Matches expected output after the fallback edit was applied. |
| Candidate (fallback-specific) | (fallback not triggered) | `Asistió a la universidad en Madrid.` | correct_fix | Matches expected output after the fallback edit was applied. |

## Subjunctive / Mood

### subj-enviara

- Original text: `Era necesario que enviaba su parte.`
- Expected corrected text: `Era necesario que enviara su parte.`
- Pass 1 (first-pass corrected text): `Era necesario que enviara su parte.`
- Pass 2 (naturalness on original): enviaba su parte -> enviara su parte
- Fallback triggered: true

| Variant | Fallback output | Final output | Score | Reason |
| --- | --- | --- | --- | --- |
| Current (reused prompt) | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |
| Candidate (fallback-specific) | su parte -> su informe | `Era necesario que enviara su informe.` | ambiguous | Fallback changed the first-pass text to something that does not match the expected output. |

---

## Overall summary

| Metric | Value |
| --- | --- |
| Fixtures | 10 |
| Fixtures where fallback triggered | 4 |
| Current pass rate (correct_fix + acceptable_no_change) | 4/10 |
| Candidate pass rate (correct_fix + acceptable_no_change) | 6/10 |
