# Two-step suggestions harness (build step E.3)

Step 1 (Issues: Spelling, Grammar, Word Choice) on `gpt-6-luna`; step 2 (Suggestions: Natural phrasing) on `gpt-6-sol`, reading the text after step 1's suggestions were applied. This report measures; it does not gate.

Baseline (step E.2, GPT-4.1 then GPT-5.1): 386 of 425 runs passed (90.8 per cent), about 2.0 seconds and 0.21 cents per check. The August reference was 84.5 per cent.

- Subcategories: **on**. Step 1 was also asked to name one subcategory for each item (build step P.12a); see "Subcategories" below.
- Total runs: `25`
- Generated: 2026-11-28T15:38:00.599020Z

## Did it flag a problem?

**Sentences with a problem: flagged 15 of 15 runs (100.0 per cent).**

- Clean sentences wrongly flagged: `0` of `10` runs

"Flagged" means the model returned at least one item or changed the text. Whether the fix matched is scored separately below.

| Sentence | Language point | Flagged | Runs | Every run? |
| --- | --- | --- | --- | --- |
| `Mi hermano está profesor.` | Ser / Estar / Haber | 5 | 5 | true |
| `En la sala son veinte personas.` | Ser / Estar / Haber | 5 | 5 | true |
| `Madrid está la capital de España.` | Ser / Estar / Haber | 5 | 5 | true |
| `Estoy muy contento con el resultado.` | Ser / Estar / Haber | 0 | 5 | clean, left alone |
| `La reunión es en la segunda planta.` | Ser / Estar / Haber | 0 | 5 | clean, left alone |

## Overall

**Pass rate: 25 of 25 (100.0 per cent).**

| Score | Runs |
| --- | --- |
| correct_fix | 15 |
| partial_fix | 0 |
| missed_issue | 0 |
| overcorrection | 0 |
| acceptable_no_change | 10 |
| ambiguous | 0 |
| error | 0 |

## Pass rate per language point

| Language point | Passed | Runs | Pass rate |
| --- | --- | --- | --- |
| Ser / Estar / Haber | 25 | 25 | 100.0 per cent |

## Speed and cost per call

| Step | Model | Average time (ms) | Average cost | Total cost |
| --- | --- | --- | --- | --- |
| 1 Issues | `gpt-6-luna` | 1380 | $0.000157 | $0.003918 |
| 2 Suggestions | `gpt-6-sol` | 1047 | $0.001368 | $0.034210 |
| Both | | 2428 | $0.001525 | $0.038128 |

## Subcategories

**Step 1 items with a subcategory from the list, under their own category: 15 of 15 (100.0 per cent).**

| Subcategory is | Items |
| --- | --- |
| On the list, under the item's category | 15 |
| Missing | 0 |
| Not on the list | 0 |
| On the list, but under a different category | 0 |

| Category | Subcategory | Items |
| --- | --- | --- |
| Spelling | Written accents | 0 |
| Spelling | Punctuation and capitals | 0 |
| Spelling | Letters | 0 |
| Grammar | Prepositions | 0 |
| Grammar | Agreement | 0 |
| Grammar | Verb forms and tenses | 0 |
| Grammar | Subjunctive | 0 |
| Grammar | Ser and estar | 11 |
| Grammar | Articles | 0 |
| Grammar | Pronouns | 0 |
| Grammar | Sentence structure | 4 |
| Word Choice | False friends | 0 |
| Word Choice | Mixed-up pairs | 0 |

- The same change returned in more than one run: `3`
- Of those, given a different category or subcategory from one run to another: `1`

| Sentence | Change | Names given |
| --- | --- | --- |
| haber-veinte-personas | `son` -> `hay` | Grammar / Sentence structure<br>Grammar / Ser and estar |

To see what the subcategory costs, compare "Speed and cost per call" (row "1 Issues") and the pass rates in this report with a run made without TWO_STEP_SUBCATEGORY.

## Wording and housekeeping

- Items shown: `15`
- Reason lines using "wrong", "error", "incorrect" or "mistake": `0`
- Items dropped (category not allowed for the step, or the written words were not in the text): `0`
- Items that could not be applied (the written words were not found exactly once): `0`
- Runs where step 2 changed words step 1 had already changed: `0`

Scoring: each step returns only its list of items. The app's own code applies them to the text, and the score is taken from that text, which is exactly what the app would show the learner. (Until 20 Nov 2026 each step also returned a whole rewritten text and the score was taken from that.)

## Every run

| Sentence | Run | Original | Step 1 items | Step 2 items | Final | Score |
| --- | --- | --- | --- | --- | --- | --- |
| ser-profesor | 1 | `Mi hermano está profesor.` | está -> es [Grammar / Ser and estar: Use ser to describe someone's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 2 | `Mi hermano está profesor.` | está -> es [Grammar / Ser and estar: Spanish uses ser for a person's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 3 | `Mi hermano está profesor.` | está profesor -> es profesor [Grammar / Ser and estar: Spanish uses ser for a person's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 4 | `Mi hermano está profesor.` | está -> es [Grammar / Ser and estar: Use ser to describe someone's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 5 | `Mi hermano está profesor.` | está -> es [Grammar / Ser and estar: Spanish uses ser for a person's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| haber-veinte-personas | 1 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses haber to say that people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 2 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses “haber” to state that people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 3 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses haber to express the existence of people in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 4 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses haber to state that people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 5 | `En la sala son veinte personas.` | son -> hay [Grammar / Ser and estar: Spanish uses hay to say that people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| ser-capital-madrid | 1 | `Madrid está la capital de España.` | está -> es [Grammar / Ser and estar: Spanish uses ser to identify a city as a country's capital.] | (none) | `Madrid es la capital de España.` | Pass (correct_fix) |
| ser-capital-madrid | 2 | `Madrid está la capital de España.` | está -> es [Grammar / Ser and estar: Spanish uses ser to identify a city as a capital.] | (none) | `Madrid es la capital de España.` | Pass (correct_fix) |
| ser-capital-madrid | 3 | `Madrid está la capital de España.` | está -> es [Grammar / Ser and estar: Use ser to identify Madrid as the capital of Spain.] | (none) | `Madrid es la capital de España.` | Pass (correct_fix) |
| ser-capital-madrid | 4 | `Madrid está la capital de España.` | está -> es [Grammar / Ser and estar: Use ser to identify Madrid as the capital of Spain.] | (none) | `Madrid es la capital de España.` | Pass (correct_fix) |
| ser-capital-madrid | 5 | `Madrid está la capital de España.` | está -> es [Grammar / Ser and estar: Spanish uses ser to identify a city as a country's capital.] | (none) | `Madrid es la capital de España.` | Pass (correct_fix) |
| estar-contento | 1 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Pass (acceptable_no_change) |
| estar-contento | 2 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Pass (acceptable_no_change) |
| estar-contento | 3 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Pass (acceptable_no_change) |
| estar-contento | 4 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Pass (acceptable_no_change) |
| estar-contento | 5 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Pass (acceptable_no_change) |
| ser-reunion-segunda-planta | 1 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Pass (acceptable_no_change) |
| ser-reunion-segunda-planta | 2 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Pass (acceptable_no_change) |
| ser-reunion-segunda-planta | 3 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Pass (acceptable_no_change) |
| ser-reunion-segunda-planta | 4 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Pass (acceptable_no_change) |
| ser-reunion-segunda-planta | 5 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Pass (acceptable_no_change) |
