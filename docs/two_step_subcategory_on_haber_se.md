# Two-step suggestions harness (build step E.3)

Step 1 (Issues: Spelling, Grammar, Word Choice) on `gpt-6-luna`; step 2 (Suggestions: Natural phrasing) on `gpt-6-sol`, reading the text after step 1's suggestions were applied. This report measures; it does not gate.

Baseline (step E.2, GPT-4.1 then GPT-5.1): 386 of 425 runs passed (90.8 per cent), about 2.0 seconds and 0.21 cents per check. The August reference was 84.5 per cent.

- Subcategories: **on**. Step 1 was also asked to name one subcategory for each item (build step P.12a); see "Subcategories" below.
- Total runs: `25`
- Generated: 2026-11-28T15:31:34.460998Z

## Did it flag a problem?

**Sentences with a problem: flagged 25 of 25 runs (100.0 per cent).**

- Clean sentences wrongly flagged: `0` of `0` runs

"Flagged" means the model returned at least one item or changed the text. Whether the fix matched is scored separately below.

| Sentence | Language point | Flagged | Runs | Every run? |
| --- | --- | --- | --- | --- |
| `Habían muchas personas en la entrada.` | Impersonal Haber / Se | 5 | 5 | true |
| `Hubieron varios problemas durante la reunión.` | Impersonal Haber / Se | 5 | 5 | true |
| `Se vende pisos en el centro.` | Impersonal Haber / Se | 5 | 5 | true |
| `Se necesita voluntarios para el evento.` | Impersonal Haber / Se | 5 | 5 | true |
| `Habían varias cifras incorrectas.` | Impersonal Haber / Se | 5 | 5 | true |

## Overall

**Pass rate: 25 of 25 (100.0 per cent).**

| Score | Runs |
| --- | --- |
| correct_fix | 25 |
| partial_fix | 0 |
| missed_issue | 0 |
| overcorrection | 0 |
| acceptable_no_change | 0 |
| ambiguous | 0 |
| error | 0 |

## Pass rate per language point

| Language point | Passed | Runs | Pass rate |
| --- | --- | --- | --- |
| Impersonal Haber / Se | 25 | 25 | 100.0 per cent |

## Speed and cost per call

| Step | Model | Average time (ms) | Average cost | Total cost |
| --- | --- | --- | --- | --- |
| 1 Issues | `gpt-6-luna` | 1716 | $0.000175 | $0.004369 |
| 2 Suggestions | `gpt-6-sol` | 998 | $0.001328 | $0.033210 |
| Both | | 2714 | $0.001503 | $0.037579 |

## Subcategories

**Step 1 items with a subcategory from the list, under their own category: 25 of 25 (100.0 per cent).**

| Subcategory is | Items |
| --- | --- |
| On the list, under the item's category | 25 |
| Missing | 0 |
| Not on the list | 0 |
| On the list, but under a different category | 0 |

| Category | Subcategory | Items |
| --- | --- | --- |
| Spelling | Written accents | 0 |
| Spelling | Punctuation and capitals | 0 |
| Spelling | Letters | 0 |
| Grammar | Prepositions | 0 |
| Grammar | Agreement | 25 |
| Grammar | Verb forms and tenses | 0 |
| Grammar | Subjunctive | 0 |
| Grammar | Ser and estar | 0 |
| Grammar | Articles | 0 |
| Grammar | Pronouns | 0 |
| Grammar | Sentence structure | 0 |
| Word Choice | False friends | 0 |
| Word Choice | Mixed-up pairs | 0 |

- The same change returned in more than one run: `6`
- Of those, given a different category or subcategory from one run to another: `0`

To see what the subcategory costs, compare "Speed and cost per call" (row "1 Issues") and the pass rates in this report with a run made without TWO_STEP_SUBCATEGORY.

## Wording and housekeeping

- Items shown: `25`
- Reason lines using "wrong", "error", "incorrect" or "mistake": `0`
- Items dropped (category not allowed for the step, or the written words were not in the text): `0`
- Items that could not be applied (the written words were not found exactly once): `0`
- Runs where step 2 changed words step 1 had already changed: `0`

Scoring: each step returns only its list of items. The app's own code applies them to the text, and the score is taken from that text, which is exactly what the app would show the learner. (Until 20 Nov 2026 each step also returned a whole rewritten text and the score was taken from that.)

## Every run

| Sentence | Run | Original | Step 1 items | Step 2 items | Final | Score |
| --- | --- | --- | --- | --- | --- | --- |
| haber-habia-personas | 1 | `Habían muchas personas en la entrada.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular even when the noun that follows is plural.] | (none) | `Había muchas personas en la entrada.` | Pass (correct_fix) |
| haber-habia-personas | 2 | `Habían muchas personas en la entrada.` | Habían -> Había [Grammar / Agreement: With impersonal haber, the verb stays singular regardless of the number of people.] | (none) | `Había muchas personas en la entrada.` | Pass (correct_fix) |
| haber-habia-personas | 3 | `Habían muchas personas en la entrada.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular even when the noun that follows is plural.] | (none) | `Había muchas personas en la entrada.` | Pass (correct_fix) |
| haber-habia-personas | 4 | `Habían muchas personas en la entrada.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular even when the noun that follows is plural.] | (none) | `Había muchas personas en la entrada.` | Pass (correct_fix) |
| haber-habia-personas | 5 | `Habían muchas personas en la entrada.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular, even when the noun that follows is plural.] | (none) | `Había muchas personas en la entrada.` | Pass (correct_fix) |
| haber-hubo-problemas | 1 | `Hubieron varios problemas durante la reunión.` | Hubieron -> Hubo [Grammar / Agreement: Impersonal haber stays singular, even when it refers to plural problems.] | (none) | `Hubo varios problemas durante la reunión.` | Pass (correct_fix) |
| haber-hubo-problemas | 2 | `Hubieron varios problemas durante la reunión.` | Hubieron -> Hubo [Grammar / Agreement: With haber meaning “there was” or “there were,” Spanish uses the singular form regardless of the following noun.] | (none) | `Hubo varios problemas durante la reunión.` | Pass (correct_fix) |
| haber-hubo-problemas | 3 | `Hubieron varios problemas durante la reunión.` | Hubieron -> Hubo [Grammar / Agreement: In this impersonal use of haber, the verb stays singular.] | (none) | `Hubo varios problemas durante la reunión.` | Pass (correct_fix) |
| haber-hubo-problemas | 4 | `Hubieron varios problemas durante la reunión.` | Hubieron -> Hubo [Grammar / Agreement: Impersonal haber stays singular even when the noun that follows is plural.] | (none) | `Hubo varios problemas durante la reunión.` | Pass (correct_fix) |
| haber-hubo-problemas | 5 | `Hubieron varios problemas durante la reunión.` | Hubieron -> Hubo [Grammar / Agreement: Impersonal haber stays singular, even when it refers to several things.] | (none) | `Hubo varios problemas durante la reunión.` | Pass (correct_fix) |
| se-venden-pisos | 1 | `Se vende pisos en el centro.` | Se vende -> Se venden [Grammar / Agreement: With plural pisos as the subject, the verb takes the plural form venden.] | (none) | `Se venden pisos en el centro.` | Pass (correct_fix) |
| se-venden-pisos | 2 | `Se vende pisos en el centro.` | vende -> venden [Grammar / Agreement: With this passive se construction, the verb agrees with the plural subject “pisos”.] | (none) | `Se venden pisos en el centro.` | Pass (correct_fix) |
| se-venden-pisos | 3 | `Se vende pisos en el centro.` | Se vende pisos -> Se venden pisos [Grammar / Agreement: With the plural noun “pisos,” the verb agrees in the plural in this passive construction.] | (none) | `Se venden pisos en el centro.` | Pass (correct_fix) |
| se-venden-pisos | 4 | `Se vende pisos en el centro.` | Se vende -> Se venden [Grammar / Agreement: The verb agrees with the plural noun “pisos” in this construction.] | (none) | `Se venden pisos en el centro.` | Pass (correct_fix) |
| se-venden-pisos | 5 | `Se vende pisos en el centro.` | vende -> venden [Grammar / Agreement: With the plural noun “pisos,” the verb agrees in the plural in this construction.] | (none) | `Se venden pisos en el centro.` | Pass (correct_fix) |
| se-necesitan-voluntarios | 1 | `Se necesita voluntarios para el evento.` | Se necesita voluntarios -> Se necesitan voluntarios [Grammar / Agreement: With passive se, the verb agrees with the plural noun “voluntarios.”] | (none) | `Se necesitan voluntarios para el evento.` | Pass (correct_fix) |
| se-necesitan-voluntarios | 2 | `Se necesita voluntarios para el evento.` | necesita voluntarios -> necesitan voluntarios [Grammar / Agreement: With the plural noun “voluntarios,” the verb agrees in the plural in this se construction.] | (none) | `Se necesitan voluntarios para el evento.` | Pass (correct_fix) |
| se-necesitan-voluntarios | 3 | `Se necesita voluntarios para el evento.` | Se necesita voluntarios -> Se necesitan voluntarios [Grammar / Agreement: With this passive construction, the verb agrees in number with “voluntarios.”] | (none) | `Se necesitan voluntarios para el evento.` | Pass (correct_fix) |
| se-necesitan-voluntarios | 4 | `Se necesita voluntarios para el evento.` | Se necesita voluntarios -> Se necesitan voluntarios [Grammar / Agreement: With the passive se construction, the verb agrees with the plural noun “voluntarios.”] | (none) | `Se necesitan voluntarios para el evento.` | Pass (correct_fix) |
| se-necesitan-voluntarios | 5 | `Se necesita voluntarios para el evento.` | Se necesita -> Se necesitan [Grammar / Agreement: With passive se, the verb agrees with the plural subject “voluntarios.”] | (none) | `Se necesitan voluntarios para el evento.` | Pass (correct_fix) |
| haber-habia-cifras | 1 | `Habían varias cifras incorrectas.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular even when the following noun is plural.] | (none) | `Había varias cifras incorrectas.` | Pass (correct_fix) |
| haber-habia-cifras | 2 | `Habían varias cifras incorrectas.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular, even when the following noun is plural.] | (none) | `Había varias cifras incorrectas.` | Pass (correct_fix) |
| haber-habia-cifras | 3 | `Habían varias cifras incorrectas.` | Habían -> Había [Grammar / Agreement: Existential haber stays singular, even when the noun that follows is plural.] | (none) | `Había varias cifras incorrectas.` | Pass (correct_fix) |
| haber-habia-cifras | 4 | `Habían varias cifras incorrectas.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular when it introduces something that exists.] | (none) | `Había varias cifras incorrectas.` | Pass (correct_fix) |
| haber-habia-cifras | 5 | `Habían varias cifras incorrectas.` | Habían -> Había [Grammar / Agreement: Impersonal haber stays singular even when it is followed by a plural noun.] | (none) | `Había varias cifras incorrectas.` | Pass (correct_fix) |
