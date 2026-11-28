# Two-step suggestions harness (build step E.3)

Step 1 (Issues: Spelling, Grammar, Word Choice) on `gpt-6-luna`; step 2 (Suggestions: Natural phrasing) on `gpt-6-sol`, reading the text after step 1's suggestions were applied. This report measures; it does not gate.

Baseline (step E.2, GPT-4.1 then GPT-5.1): 386 of 425 runs passed (90.8 per cent), about 2.0 seconds and 0.21 cents per check. The August reference was 84.5 per cent.

- Subcategories: **on**. Step 1 was also asked to name one subcategory for each item (build step P.12a); see "Subcategories" below.
- Total runs: `420`
- Generated: 2026-11-28T15:28:28.455008Z

## Did it flag a problem?

**Sentences with a problem: flagged 316 of 350 runs (90.3 per cent).**

- Clean sentences wrongly flagged: `4` of `70` runs

"Flagged" means the model returned at least one item or changed the text. Whether the fix matched is scored separately below.

| Sentence | Language point | Flagged | Runs | Every run? |
| --- | --- | --- | --- | --- |
| `Vi mucho trafico ayer.` | Accents / Diacritics | 5 | 5 | true |
| `Voy a hacer una decisión importante.` | Collocations / Strong Calques | 5 | 5 | true |
| `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | Accents / Diacritics + Collocations / Strong Calques (independent spans) | 5 | 5 | true |
| `Vi mucho tráfico, y luego vi más tráfico.` | Ambiguous / Repeated Span Safety (Naturalness) | 4 | 5 | clean, FLAGGED |
| `Voy al parque manana por la tarde.` | Accents / Diacritics | 5 | 5 | true |
| `El medico llego despues de la reunion.` | Accents / Diacritics | 5 | 5 | true |
| `Espana es un pais muy diverso.` | Accents / Diacritics | 5 | 5 | true |
| `Mi cumpleanos es en otono.` | Accents / Diacritics | 5 | 5 | true |
| `Compre cafe en una cafeteria pequena.` | Accents / Diacritics | 5 | 5 | true |
| `Los niño come muchas manzana.` | Gender / Number Agreement | 5 | 5 | true |
| `Las ventanas estaban abierto.` | Gender / Number Agreement | 5 | 5 | true |
| `Una puerta estaba cerrado.` | Gender / Number Agreement | 5 | 5 | true |
| `Los billetes estaban caro.` | Gender / Number Agreement | 5 | 5 | true |
| `Las fechas estaban escrito sin tilde.` | Gender / Number Agreement | 5 | 5 | true |
| `Mis compañeros y yo fue a la biblioteca.` | Verb Agreement / Morphology | 5 | 5 | true |
| `Los niños come en el jardín.` | Verb Agreement / Morphology | 5 | 5 | true |
| `Yo fui al mercado y compra pan.` | Verb Agreement / Morphology | 5 | 5 | true |
| `Ellos estudia todas las noches.` | Verb Agreement / Morphology | 5 | 5 | true |
| `Nosotros vive cerca del centro.` | Verb Agreement / Morphology | 5 | 5 | true |
| `Insisto que revises el contrato.` | Required Prepositions | 5 | 5 | true |
| `La empresa que trabajo está cerca.` | Required Prepositions | 5 | 5 | true |
| `Dependo que me ayudes mañana.` | Required Prepositions | 5 | 5 | true |
| `Pienso ti todos los días.` | Required Prepositions | 5 | 5 | true |
| `Soñé mi antiguo colegio.` | Required Prepositions | 5 | 5 | true |
| `Abrió puerta principal.` | Articles / Determiners | 5 | 5 | true |
| `Necesito comprar libro para la clase.` | Articles / Determiners | 5 | 5 | true |
| `Profesor explicó regla otra vez.` | Articles / Determiners | 5 | 5 | true |
| `Fui a tienda después del trabajo.` | Articles / Determiners | 5 | 5 | true |
| `Tengo cita con médico mañana.` | Articles / Determiners | 5 | 5 | true |
| `Es importante que estudias.` | Subjunctive / Mood | 5 | 5 | true |
| `No creo que tiene razón.` | Subjunctive / Mood | 5 | 5 | true |
| `Quiero que vienes conmigo.` | Subjunctive / Mood | 5 | 5 | true |
| `Era necesario que enviaba su parte.` | Subjunctive / Mood | 5 | 5 | true |
| `Busco a alguien que habla francés.` | Subjunctive / Mood | 5 | 5 | true |
| `Creo está bien terminar hoy.` | Required Additions / Omissions | 5 | 5 | true |
| `A los niños expliqué la regla.` | Required Additions / Omissions | 5 | 5 | true |
| `Vi mi profesor en la estación.` | Required Additions / Omissions | 5 | 5 | true |
| `Levantó temprano ayer.` | Required Additions / Omissions | 5 | 5 | true |
| `A Juan gusta el café.` | Required Additions / Omissions | 5 | 5 | true |
| `Yo trabajo mucho y yo estudio por las noches.` | Unnecessary Extras / Deletions | 5 | 5 | true |
| `Ellos viajaron a México y ellos visitaron varias ciudades.` | Unnecessary Extras / Deletions | 5 | 5 | true |
| `A mí me gusta el café a mí.` | Unnecessary Extras / Deletions | 5 | 5 | true |
| `Yo fui al mercado y yo compré pan.` | Unnecessary Extras / Deletions | 5 | 5 | true |
| `Nosotros salimos temprano y nosotros llegamos a tiempo.` | Unnecessary Extras / Deletions | 5 | 5 | true |
| `Mi hermano está profesor.` | Ser / Estar / Haber | 5 | 5 | true |
| `En la sala son veinte personas.` | Ser / Estar / Haber | 5 | 5 | true |
| `Madrid está la capital de España.` | Ser / Estar / Haber | 2 | 5 | false |
| `Estoy muy contento con el resultado.` | Ser / Estar / Haber | 0 | 5 | clean, left alone |
| `La reunión es en la segunda planta.` | Ser / Estar / Haber | 0 | 5 | clean, left alone |
| `Habían muchas personas en la entrada.` | Impersonal Haber / Se | 0 | 5 | false |
| `Hubieron varios problemas durante la reunión.` | Impersonal Haber / Se | 0 | 5 | false |
| `Se vende pisos en el centro.` | Impersonal Haber / Se | 0 | 5 | false |
| `Se necesita voluntarios para el evento.` | Impersonal Haber / Se | 0 | 5 | false |
| `Habían varias cifras incorrectas.` | Impersonal Haber / Se | 0 | 5 | false |
| `Necesito hacer una decisión.` | Collocations / Strong Calques | 5 | 5 | true |
| `Tenemos que hacer atención.` | Collocations / Strong Calques | 2 | 5 | false |
| `El equipo tomó una reunión.` | Collocations / Strong Calques | 5 | 5 | true |
| `Ella hizo un paseo.` | Collocations / Strong Calques | 2 | 5 | false |
| `Quiero preguntar una pregunta.` | Collocations / Strong Calques | 5 | 5 | true |
| `Atendió la universidad en Madrid.` | False Friends / Word Choice | 5 | 5 | true |
| `Saqué un libro de la librería pública.` | False Friends / Word Choice | 5 | 5 | true |
| `Realicé que estaba equivocado.` | False Friends / Word Choice | 5 | 5 | true |
| `Estoy embarazado por llegar tarde.` | False Friends / Word Choice | 5 | 5 | true |
| `Actualmente vivo en Londres.` | False Friends / Word Choice | 0 | 5 | clean, left alone |
| `Tuvimos un buen tiempo.` | Phrase-Level Naturalness | 5 | 5 | true |
| `Estoy corriendo tarde para la reunión.` | Phrase-Level Naturalness | 5 | 5 | true |
| `Quiero pasar un buen tiempo.` | Phrase-Level Naturalness | 5 | 5 | true |
| `¿Puedo tener una cerveza?` | Phrase-Level Naturalness | 5 | 5 | true |
| `La reunión tomó lugar ayer.` | Phrase-Level Naturalness | 5 | 5 | true |
| `Voy para casa ahora mismo.` | Valid Regional / Should Not Flag | 0 | 5 | clean, left alone |
| `Vos tenés razón.` | Valid Regional / Should Not Flag | 0 | 5 | clean, left alone |
| `Cojo el autobús cada mañana.` | Valid Regional / Should Not Flag | 0 | 5 | clean, left alone |
| `Esta mañana hablé con mi jefe.` | Valid Regional / Should Not Flag | 0 | 5 | clean, left alone |
| `Dale, nos vemos más tarde.` | Valid Regional / Should Not Flag | 0 | 5 | clean, left alone |
| `Buenos días, ¿cómo estás?` | Already Correct / Do Not Tinker | 0 | 5 | clean, left alone |
| `Voy a hacer una pregunta al profesor.` | Already Correct / Do Not Tinker | 0 | 5 | clean, left alone |
| `Necesito tomar una foto del documento.` | Already Correct / Do Not Tinker | 0 | 5 | clean, left alone |
| `Mañana visitaré a mi abuela.` | Already Correct / Do Not Tinker | 0 | 5 | clean, left alone |
| `Está lloviendo, así que me quedo en casa.` | Already Correct / Do Not Tinker | 0 | 5 | clean, left alone |
| `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Mixed Operations | 5 | 5 | true |
| `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | Mixed Operations | 5 | 5 | true |
| `Vi mi profesor en la estación, y recordé que es importante que estudio.` | Mixed Operations | 5 | 5 | true |
| `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | Mixed Operations | 5 | 5 | true |
| `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.` | Mixed Operations | 5 | 5 | true |

## Overall

**Pass rate: 357 of 420 (85.0 per cent).**

| Score | Runs |
| --- | --- |
| correct_fix | 301 |
| partial_fix | 15 |
| missed_issue | 6 |
| overcorrection | 4 |
| acceptable_no_change | 56 |
| ambiguous | 0 |
| error | 38 |

## Pass rate per language point

| Language point | Passed | Runs | Pass rate |
| --- | --- | --- | --- |
| Accents / Diacritics | 22 | 30 | 73.3 per cent |
| Collocations / Strong Calques | 24 | 30 | 80.0 per cent |
| Accents / Diacritics + Collocations / Strong Calques (independent spans) | 5 | 5 | 100.0 per cent |
| Ambiguous / Repeated Span Safety (Naturalness) | 1 | 5 | 20.0 per cent |
| Gender / Number Agreement | 25 | 25 | 100.0 per cent |
| Verb Agreement / Morphology | 25 | 25 | 100.0 per cent |
| Required Prepositions | 25 | 25 | 100.0 per cent |
| Articles / Determiners | 20 | 25 | 80.0 per cent |
| Subjunctive / Mood | 25 | 25 | 100.0 per cent |
| Required Additions / Omissions | 25 | 25 | 100.0 per cent |
| Unnecessary Extras / Deletions | 25 | 25 | 100.0 per cent |
| Ser / Estar / Haber | 12 | 25 | 48.0 per cent |
| Impersonal Haber / Se | 0 | 25 | 0.0 per cent |
| False Friends / Word Choice | 23 | 25 | 92.0 per cent |
| Phrase-Level Naturalness | 25 | 25 | 100.0 per cent |
| Valid Regional / Should Not Flag | 25 | 25 | 100.0 per cent |
| Already Correct / Do Not Tinker | 25 | 25 | 100.0 per cent |
| Mixed Operations | 25 | 25 | 100.0 per cent |

## Speed and cost per call

| Step | Model | Average time (ms) | Average cost | Total cost |
| --- | --- | --- | --- | --- |
| 1 Issues | `gpt-6-luna` | 1634 | $0.000153 | $0.064227 |
| 2 Suggestions | `gpt-6-sol` | 1210 | $0.001656 | $0.695590 |
| Both | | 2843 | $0.001809 | $0.759817 |

## Subcategories

**Step 1 items with a subcategory from the list, under their own category: 316 of 316 (100.0 per cent).**

| Subcategory is | Items |
| --- | --- |
| On the list, under the item's category | 316 |
| Missing | 0 |
| Not on the list | 0 |
| On the list, but under a different category | 0 |

| Category | Subcategory | Items |
| --- | --- | --- |
| Spelling | Written accents | 53 |
| Spelling | Punctuation and capitals | 0 |
| Spelling | Letters | 31 |
| Grammar | Prepositions | 40 |
| Grammar | Agreement | 65 |
| Grammar | Verb forms and tenses | 5 |
| Grammar | Subjunctive | 30 |
| Grammar | Ser and estar | 7 |
| Grammar | Articles | 35 |
| Grammar | Pronouns | 15 |
| Grammar | Sentence structure | 15 |
| Word Choice | False friends | 17 |
| Word Choice | Mixed-up pairs | 3 |

- The same change returned in more than one run: `74`
- Of those, given a different category or subcategory from one run to another: `3`

| Sentence | Change | Names given |
| --- | --- | --- |
| grammar-and-naturalness-independent | `devia` -> `debía` | Spelling / Written accents<br>Spelling / Letters |
| false-friend-atendio-universidad | `Atendió` -> `Asistió a` | Word Choice / False friends<br>Word Choice / Mixed-up pairs |
| false-friend-atendio-universidad | `Atendió la universidad` -> `Asistió a la universidad` | Word Choice / Mixed-up pairs<br>Word Choice / False friends |

To see what the subcategory costs, compare "Speed and cost per call" (row "1 Issues") and the pass rates in this report with a run made without TWO_STEP_SUBCATEGORY.

## Wording and housekeeping

- Items shown: `409`
- Reason lines using "wrong", "error", "incorrect" or "mistake": `0`
- Items dropped (category not allowed for the step, or the written words were not in the text): `0`
- Items that could not be applied (the written words were not found exactly once): `0`
- Runs where step 2 changed words step 1 had already changed: `0`

Scoring: each step returns only its list of items. The app's own code applies them to the text, and the score is taken from that text, which is exactly what the app would show the learner. (Until 20 Nov 2026 each step also returned a whole rewritten text and the score was taken from that.)

## Every run

| Sentence | Run | Original | Step 1 items | Step 2 items | Final | Score |
| --- | --- | --- | --- | --- | --- | --- |
| clean-grammar-only | 1 | `Vi mucho trafico ayer.` | trafico -> tráfico [Spelling / Written accents: Spanish needs an accent mark on the first vowel of “tráfico.”] | (none) | `Vi mucho tráfico ayer.` | Pass (correct_fix) |
| clean-grammar-only | 2 | `Vi mucho trafico ayer.` | trafico -> tráfico [Spelling / Written accents: Spanish needs an accent mark on this word.] | (none) | `Vi mucho tráfico ayer.` | Pass (correct_fix) |
| clean-grammar-only | 3 | `Vi mucho trafico ayer.` | trafico -> tráfico [Spelling / Written accents: Spanish needs an accent mark on the first syllable of this noun.] | (none) | `Vi mucho tráfico ayer.` | Pass (correct_fix) |
| clean-grammar-only | 4 | `Vi mucho trafico ayer.` | trafico -> tráfico [Spelling / Written accents: Spanish needs an accent mark here because the stress falls on the antepenultimate syllable.] | (none) | `Vi mucho tráfico ayer.` | Pass (correct_fix) |
| clean-grammar-only | 5 | `Vi mucho trafico ayer.` | trafico -> tráfico [Spelling / Written accents: Spanish needs an accent mark on the first syllable of this noun.] | (none) | `Vi mucho tráfico ayer.` | Pass (correct_fix) |
| naturalness-only | 1 | `Voy a hacer una decisión importante.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish speakers say «tomar una decisión» rather than translating “make a decision” literally.] | `Voy a tomar una decisión importante.` | Pass (correct_fix) |
| naturalness-only | 2 | `Voy a hacer una decisión importante.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish naturally uses «tomar una decisión» for this expression.] | `Voy a tomar una decisión importante.` | Pass (correct_fix) |
| naturalness-only | 3 | `Voy a hacer una decisión importante.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish naturally says «tomar una decisión» rather than translating «make a decision» literally.] | `Voy a tomar una decisión importante.` | Pass (correct_fix) |
| naturalness-only | 4 | `Voy a hacer una decisión importante.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish naturally uses «tomar una decisión» for this expression.] | `Voy a tomar una decisión importante.` | Pass (correct_fix) |
| naturalness-only | 5 | `Voy a hacer una decisión importante.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish usually says «tomar una decisión» rather than translating “make a decision” literally.] | `Voy a tomar una decisión importante.` | Pass (correct_fix) |
| grammar-and-naturalness-independent | 1 | `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | devia -> debía [Spelling / Written accents: Spanish writes this verb with b and an accent on the í.] | hizo una decisión importante -> tomó una decisión importante [Natural phrasing: Spanish speakers usually say «tomar una decisión».] | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | Pass (correct_fix) |
| grammar-and-naturalness-independent | 2 | `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | devia -> debía [Spelling / Letters: The imperfect form of deber is spelled with an e and an accent on the í.] | hizo una decisión -> tomó una decisión [Natural phrasing: In Spanish, the natural expression is «tomar una decisión».] | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | Pass (correct_fix) |
| grammar-and-naturalness-independent | 3 | `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | devia -> debía [Spelling / Letters: The verb is spelled debía, with b and an accent on the í.] | hizo una decisión -> tomó una decisión [Natural phrasing: Spanish naturally uses «tomar una decisión» rather than a literal translation of “make a decision”.] | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | Pass (correct_fix) |
| grammar-and-naturalness-independent | 4 | `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | devia -> debía [Spelling / Written accents: The imperfect form of deber is debía, with b and an accent on the í.] | hizo una decisión importante -> tomó una decisión importante [Natural phrasing: Spanish speakers usually say «tomar una decisión».] | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | Pass (correct_fix) |
| grammar-and-naturalness-independent | 5 | `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | devia -> debía [Spelling / Letters: The verb is spelled with b and an accent on the í.] | hizo una decisión -> tomó una decisión [Natural phrasing: Spanish speakers usually say «tomar una decisión».] | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | Pass (correct_fix) |
| ambiguous-naturalness-span | 1 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | vi más tráfico -> todavía más [Natural phrasing: This avoids repeating «vi» and «tráfico» when the context already makes them clear.] | `Vi mucho tráfico, y luego todavía más.` | Fail (overcorrection) |
| ambiguous-naturalness-span | 2 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | vi más tráfico -> vi más [Natural phrasing: Once you’ve mentioned tráfico, you can leave it out when saying you saw more.] | `Vi mucho tráfico, y luego vi más.` | Fail (overcorrection) |
| ambiguous-naturalness-span | 3 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | vi más tráfico -> aún más [Natural phrasing: This avoids repeating the verb and noun when the meaning is already clear.] | `Vi mucho tráfico, y luego aún más.` | Fail (overcorrection) |
| ambiguous-naturalness-span | 4 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | (none) | `Vi mucho tráfico, y luego vi más tráfico.` | Pass (acceptable_no_change) |
| ambiguous-naturalness-span | 5 | `Vi mucho tráfico, y luego vi más tráfico.` | (none) | vi más tráfico -> aún más [Natural phrasing: This avoids repeating “vi” and “tráfico” when the context already makes both clear.] | `Vi mucho tráfico, y luego aún más.` | Fail (overcorrection) |
| accent-manana | 1 | `Voy al parque manana por la tarde.` | manana -> mañana [Spelling / Letters: The Spanish word for “tomorrow” is spelled with ñ.] | (none) | `Voy al parque mañana por la tarde.` | Pass (correct_fix) |
| accent-manana | 2 | `Voy al parque manana por la tarde.` | manana -> mañana [Spelling / Letters: Spanish writes this word with ñ.] | (none) | `Voy al parque mañana por la tarde.` | Pass (correct_fix) |
| accent-manana | 3 | `Voy al parque manana por la tarde.` | manana -> mañana [Spelling / Letters: Spanish writes this word with ñ.] | (none) | `Voy al parque mañana por la tarde.` | Pass (correct_fix) |
| accent-manana | 4 | `Voy al parque manana por la tarde.` | manana -> mañana [Spelling / Letters: Spanish writes this word with ñ.] | (none) | `Voy al parque mañana por la tarde.` | Pass (correct_fix) |
| accent-manana | 5 | `Voy al parque manana por la tarde.` | manana -> mañana [Spelling / Letters: Spanish writes this word with ñ, not n.] | (none) | `Voy al parque mañana por la tarde.` | Pass (correct_fix) |
| accent-medico | 1 | `El medico llego despues de la reunion.` | medico -> médico [Spelling / Written accents: Spanish needs an accent mark on the first syllable of this word.]<br>llego -> llegó [Spelling / Written accents: Spanish needs an accent mark here for the past-tense form.]<br>reunion -> reunión [Spelling / Written accents: Spanish needs an accent mark on the final syllable of this word.] | (none) | `El médico llegó despues de la reunión.` | Fail (partial_fix) |
| accent-medico | 2 | `El medico llego despues de la reunion.` | medico -> médico [Spelling / Written accents: Spanish needs an accent mark on the first syllable here.]<br>llego -> llegó [Spelling / Written accents: The accent mark distinguishes the past-tense form llegó.]<br>reunion -> reunión [Spelling / Written accents: Spanish needs an accent mark on the final syllable here.] | (none) | `El médico llegó despues de la reunión.` | Fail (partial_fix) |
| accent-medico | 3 | `El medico llego despues de la reunion.` | medico -> médico [Spelling / Written accents: Spanish needs an accent mark on this word.]<br>llego -> llegó [Spelling / Written accents: The accent mark distinguishes the past-tense form from the present-tense form.] | (none) | `El médico llegó despues de la reunion.` | Fail (partial_fix) |
| accent-medico | 4 | `El medico llego despues de la reunion.` | medico -> médico [Spelling / Written accents: Spanish needs an accent mark on the first syllable of this word.]<br>llego -> llegó [Spelling / Written accents: The accent mark distinguishes this past-tense verb form.] | (none) | `El médico llegó despues de la reunion.` | Fail (partial_fix) |
| accent-medico | 5 | `El medico llego despues de la reunion.` | medico -> médico [Spelling / Written accents: Spanish needs an accent mark on the first syllable of this word.]<br>llego -> llegó [Spelling / Written accents: The accent mark shows that this is the past-tense form.] | (none) | `El médico llegó despues de la reunion.` | Fail (partial_fix) |
| accent-espana-pais | 1 | `Espana es un pais muy diverso.` | Espana -> España [Spelling / Letters: The name of the country is spelled with ñ in Spanish.]<br>pais -> país [Spelling / Written accents: Spanish needs an accent mark on the í here.] | (none) | `España es un país muy diverso.` | Pass (correct_fix) |
| accent-espana-pais | 2 | `Espana es un pais muy diverso.` | Espana -> España [Spelling / Letters: The name of the country is written with ñ in Spanish.]<br>pais -> país [Spelling / Written accents: Spanish needs an accent mark on the í in país.] | (none) | `España es un país muy diverso.` | Pass (correct_fix) |
| accent-espana-pais | 3 | `Espana es un pais muy diverso.` | Espana -> España [Spelling / Letters: Spanish writes the letter ñ in the name of the country.]<br>pais -> país [Spelling / Written accents: Spanish needs an accent mark on the í here.] | (none) | `España es un país muy diverso.` | Pass (correct_fix) |
| accent-espana-pais | 4 | `Espana es un pais muy diverso.` | Espana -> España [Spelling / Letters: Spanish writes the ñ in the name of the country.]<br>pais -> país [Spelling / Written accents: Spanish needs an accent mark on the í here.] | (none) | `España es un país muy diverso.` | Pass (correct_fix) |
| accent-espana-pais | 5 | `Espana es un pais muy diverso.` | Espana -> España [Spelling / Letters: Spanish writes this country's name with ñ.]<br>pais -> país [Spelling / Written accents: Spanish needs an accent mark on the í here.] | (none) | `España es un país muy diverso.` | Pass (correct_fix) |
| accent-cumpleanos-otono | 1 | `Mi cumpleanos es en otono.` | cumpleanos -> cumpleaños [Spelling / Letters: Spanish writes ñ in this word.]<br>otono -> otoño [Spelling / Letters: Spanish writes ñ in this word.] | (none) | `Mi cumpleaños es en otoño.` | Pass (correct_fix) |
| accent-cumpleanos-otono | 2 | `Mi cumpleanos es en otono.` | cumpleanos -> cumpleaños [Spelling / Letters: Spanish writes this word with ñ.]<br>otono -> otoño [Spelling / Letters: Spanish writes this word with ñ.] | (none) | `Mi cumpleaños es en otoño.` | Pass (correct_fix) |
| accent-cumpleanos-otono | 3 | `Mi cumpleanos es en otono.` | cumpleanos -> cumpleaños [Spelling / Letters: Spanish writes this word with ñ.]<br>otono -> otoño [Spelling / Letters: Spanish writes this word with ñ.] | (none) | `Mi cumpleaños es en otoño.` | Pass (correct_fix) |
| accent-cumpleanos-otono | 4 | `Mi cumpleanos es en otono.` | cumpleanos -> cumpleaños [Spelling / Letters: The ñ distinguishes this word from the spelling with n.] | (none) | `Mi cumpleaños es en otono.` | Fail (partial_fix) |
| accent-cumpleanos-otono | 5 | `Mi cumpleanos es en otono.` | cumpleanos -> cumpleaños [Spelling / Letters: Spanish writes this word with ñ.]<br>otono -> otoño [Spelling / Letters: Spanish writes this word with ñ.] | (none) | `Mi cumpleaños es en otoño.` | Pass (correct_fix) |
| accent-cafe-cafeteria | 1 | `Compre cafe en una cafeteria pequena.` | cafe -> café [Spelling / Written accents: Spanish needs an accent mark on the final vowel of “café.”]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish needs an accent mark on the í in “cafetería.”]<br>pequena -> pequeña [Spelling / Letters: Spanish writes this word with ñ.] | (none) | `Compre café en una cafetería pequeña.` | Fail (partial_fix) |
| accent-cafe-cafeteria | 2 | `Compre cafe en una cafeteria pequena.` | Compre -> Compré [Spelling / Written accents: The accent mark distinguishes the past-tense form “compré” from “compre.”]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent mark on “café.”]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish writes an accent mark on the “i” in “cafetería.”]<br>pequena -> pequeña [Spelling / Letters: The Spanish word uses ñ here.] | (none) | `Compré café en una cafetería pequeña.` | Pass (correct_fix) |
| accent-cafe-cafeteria | 3 | `Compre cafe en una cafeteria pequena.` | Compre -> Compré [Spelling / Written accents: The first-person preterite form needs an accent on the final é.]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent on the final é in café.]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish writes an accent on the í in cafetería.]<br>pequena -> pequeña [Spelling / Letters: The Spanish word uses ñ here.] | (none) | `Compré café en una cafetería pequeña.` | Pass (correct_fix) |
| accent-cafe-cafeteria | 4 | `Compre cafe en una cafeteria pequena.` | Compre -> Compré [Spelling / Written accents: The accent mark shows that this is the past-tense form meaning “I bought.”]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent mark on “café.”]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish writes an accent mark on the í in “cafetería.”] | (none) | `Compré café en una cafetería pequena.` | Fail (partial_fix) |
| accent-cafe-cafeteria | 5 | `Compre cafe en una cafeteria pequena.` | Compre -> Compré [Spelling / Written accents: The accent mark distinguishes the past-tense form “compré” from “compre.”]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent mark on “café.”]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish writes an accent mark on the í in “cafetería.”]<br>pequena -> pequeña [Spelling / Letters: Spanish uses ñ in “pequeña.”] | (none) | `Compré café en una cafetería pequeña.` | Pass (correct_fix) |
| agreement-ninos-manzanas | 1 | `Los niño come muchas manzana.` | niño -> niños [Grammar / Agreement: The plural article “los” requires a plural noun.]<br>come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject.]<br>manzana -> manzanas [Grammar / Agreement: The plural adjective “muchas” requires a plural noun.] | (none) | `Los niños comen muchas manzanas.` | Pass (correct_fix) |
| agreement-ninos-manzanas | 2 | `Los niño come muchas manzana.` | Los niño -> Los niños [Grammar / Agreement: The plural article “los” requires a plural noun.]<br>come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject.]<br>muchas manzana -> muchas manzanas [Grammar / Agreement: The noun needs to agree in number with “muchas”.] | (none) | `Los niños comen muchas manzanas.` | Pass (correct_fix) |
| agreement-ninos-manzanas | 3 | `Los niño come muchas manzana.` | niño -> niños [Grammar / Agreement: The plural article “los” requires a plural noun.]<br>come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject.]<br>manzana -> manzanas [Grammar / Agreement: The plural adjective “muchas” requires a plural noun.] | (none) | `Los niños comen muchas manzanas.` | Pass (correct_fix) |
| agreement-ninos-manzanas | 4 | `Los niño come muchas manzana.` | niño -> niños [Grammar / Agreement: The noun needs to agree in number with the plural article “los”.]<br>come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject “los niños”.]<br>manzana -> manzanas [Grammar / Agreement: The noun needs to agree in number with the plural word “muchas”.] | (none) | `Los niños comen muchas manzanas.` | Pass (correct_fix) |
| agreement-ninos-manzanas | 5 | `Los niño come muchas manzana.` | Los niño -> Los niños [Grammar / Agreement: The noun needs to agree in number with the plural article “Los”.]<br>come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject “Los niños”.]<br>muchas manzana -> muchas manzanas [Grammar / Agreement: The noun needs to agree in number with the plural adjective “muchas”.] | (none) | `Los niños comen muchas manzanas.` | Pass (correct_fix) |
| agreement-ventanas-abiertas | 1 | `Las ventanas estaban abierto.` | abierto -> abiertas [Grammar / Agreement: The adjective agrees with the feminine plural noun “ventanas.”] | (none) | `Las ventanas estaban abiertas.` | Pass (correct_fix) |
| agreement-ventanas-abiertas | 2 | `Las ventanas estaban abierto.` | abierto -> abiertas [Grammar / Agreement: The adjective agrees with the feminine plural noun “ventanas.”] | (none) | `Las ventanas estaban abiertas.` | Pass (correct_fix) |
| agreement-ventanas-abiertas | 3 | `Las ventanas estaban abierto.` | abierto -> abiertas [Grammar / Agreement: The adjective must agree with the feminine plural noun “ventanas.”] | (none) | `Las ventanas estaban abiertas.` | Pass (correct_fix) |
| agreement-ventanas-abiertas | 4 | `Las ventanas estaban abierto.` | abierto -> abiertas [Grammar / Agreement: The adjective agrees in feminine plural with “ventanas.”] | (none) | `Las ventanas estaban abiertas.` | Pass (correct_fix) |
| agreement-ventanas-abiertas | 5 | `Las ventanas estaban abierto.` | abierto -> abiertas [Grammar / Agreement: The adjective agrees in gender and number with the plural feminine noun “ventanas.”] | (none) | `Las ventanas estaban abiertas.` | Pass (correct_fix) |
| agreement-puerta-cerrada | 1 | `Una puerta estaba cerrado.` | cerrado -> cerrada [Grammar / Agreement: The adjective agrees with the feminine noun «puerta».] | (none) | `Una puerta estaba cerrada.` | Pass (correct_fix) |
| agreement-puerta-cerrada | 2 | `Una puerta estaba cerrado.` | estaba cerrado -> estaba cerrada [Grammar / Agreement: The adjective needs to agree in gender with the feminine noun “puerta.”] | (none) | `Una puerta estaba cerrada.` | Pass (correct_fix) |
| agreement-puerta-cerrada | 3 | `Una puerta estaba cerrado.` | estaba cerrado -> estaba cerrada [Grammar / Agreement: The adjective agrees with the feminine noun “puerta.”] | (none) | `Una puerta estaba cerrada.` | Pass (correct_fix) |
| agreement-puerta-cerrada | 4 | `Una puerta estaba cerrado.` | cerrado -> cerrada [Grammar / Agreement: The adjective agrees with the feminine noun “puerta.”] | (none) | `Una puerta estaba cerrada.` | Pass (correct_fix) |
| agreement-puerta-cerrada | 5 | `Una puerta estaba cerrado.` | cerrado -> cerrada [Grammar / Agreement: The adjective agrees with the feminine noun “puerta.”] | (none) | `Una puerta estaba cerrada.` | Pass (correct_fix) |
| agreement-billetes-caros | 1 | `Los billetes estaban caro.` | estaban caro -> estaban caros [Grammar / Agreement: The adjective agrees in number with the plural noun “billetes.”] | (none) | `Los billetes estaban caros.` | Pass (correct_fix) |
| agreement-billetes-caros | 2 | `Los billetes estaban caro.` | estaban caro -> estaban caros [Grammar / Agreement: The adjective needs to agree in number with the plural noun “billetes.”] | (none) | `Los billetes estaban caros.` | Pass (correct_fix) |
| agreement-billetes-caros | 3 | `Los billetes estaban caro.` | estaban caro -> estaban caros [Grammar / Agreement: The adjective agrees with the masculine plural noun “billetes.”] | (none) | `Los billetes estaban caros.` | Pass (correct_fix) |
| agreement-billetes-caros | 4 | `Los billetes estaban caro.` | caro -> caros [Grammar / Agreement: The adjective agrees in number with the plural noun “billetes.”] | (none) | `Los billetes estaban caros.` | Pass (correct_fix) |
| agreement-billetes-caros | 5 | `Los billetes estaban caro.` | caro -> caros [Grammar / Agreement: The adjective agrees with the plural noun “billetes.”] | (none) | `Los billetes estaban caros.` | Pass (correct_fix) |
| agreement-fechas-escritas | 1 | `Las fechas estaban escrito sin tilde.` | estaban escrito -> estaban escritas [Grammar / Agreement: The participle agrees with the feminine plural noun “fechas.”] | (none) | `Las fechas estaban escritas sin tilde.` | Pass (correct_fix) |
| agreement-fechas-escritas | 2 | `Las fechas estaban escrito sin tilde.` | escrito -> escritas [Grammar / Agreement: The participle agrees in gender and number with the feminine plural noun “fechas.”] | (none) | `Las fechas estaban escritas sin tilde.` | Pass (correct_fix) |
| agreement-fechas-escritas | 3 | `Las fechas estaban escrito sin tilde.` | escrito -> escritas [Grammar / Agreement: The participle agrees with the feminine plural noun “fechas.”] | (none) | `Las fechas estaban escritas sin tilde.` | Pass (correct_fix) |
| agreement-fechas-escritas | 4 | `Las fechas estaban escrito sin tilde.` | estaban escrito -> estaban escritas [Grammar / Agreement: The participle agrees with the feminine plural noun “fechas.”] | (none) | `Las fechas estaban escritas sin tilde.` | Pass (correct_fix) |
| agreement-fechas-escritas | 5 | `Las fechas estaban escrito sin tilde.` | estaban escrito -> estaban escritas [Grammar / Agreement: The participle agrees with the feminine plural noun “fechas.”] | (none) | `Las fechas estaban escritas sin tilde.` | Pass (correct_fix) |
| verb-nosotros-fuimos | 1 | `Mis compañeros y yo fue a la biblioteca.` | fue -> fuimos [Grammar / Agreement: The verb agrees with the compound subject “mis compañeros y yo” in the first-person plural.] | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | Pass (correct_fix) |
| verb-nosotros-fuimos | 2 | `Mis compañeros y yo fue a la biblioteca.` | Mis compañeros y yo fue -> Mis compañeros y yo fuimos [Grammar / Agreement: The plural subject “mis compañeros y yo” takes the plural verb form “fuimos.”] | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | Pass (correct_fix) |
| verb-nosotros-fuimos | 3 | `Mis compañeros y yo fue a la biblioteca.` | yo fue -> yo fuimos [Grammar / Agreement: The verb must agree with the plural subject “mis compañeros y yo.”] | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | Pass (correct_fix) |
| verb-nosotros-fuimos | 4 | `Mis compañeros y yo fue a la biblioteca.` | fue -> fuimos [Grammar / Agreement: The verb needs the first-person plural form to agree with “mis compañeros y yo.”] | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | Pass (correct_fix) |
| verb-nosotros-fuimos | 5 | `Mis compañeros y yo fue a la biblioteca.` | fue -> fuimos [Grammar / Agreement: The verb agrees with the plural subject “mis compañeros y yo.”] | (none) | `Mis compañeros y yo fuimos a la biblioteca.` | Pass (correct_fix) |
| verb-ninos-comen | 1 | `Los niños come en el jardín.` | come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject “los niños.”] | (none) | `Los niños comen en el jardín.` | Pass (correct_fix) |
| verb-ninos-comen | 2 | `Los niños come en el jardín.` | come -> comen [Grammar / Agreement: The verb must agree with the plural subject “los niños.”] | (none) | `Los niños comen en el jardín.` | Pass (correct_fix) |
| verb-ninos-comen | 3 | `Los niños come en el jardín.` | come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject “los niños.”] | (none) | `Los niños comen en el jardín.` | Pass (correct_fix) |
| verb-ninos-comen | 4 | `Los niños come en el jardín.` | come -> comen [Grammar / Agreement: The verb needs the plural form to agree with “los niños.”] | (none) | `Los niños comen en el jardín.` | Pass (correct_fix) |
| verb-ninos-comen | 5 | `Los niños come en el jardín.` | come -> comen [Grammar / Agreement: The verb needs to agree with the plural subject “los niños”.] | (none) | `Los niños comen en el jardín.` | Pass (correct_fix) |
| verb-compre-pan | 1 | `Yo fui al mercado y compra pan.` | compra -> compré [Grammar / Verb forms and tenses: The first-person past-tense form is “compré.”] | (none) | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| verb-compre-pan | 2 | `Yo fui al mercado y compra pan.` | compra -> compré [Grammar / Verb forms and tenses: The first-person verb should be in the past tense to match “fui.”] | (none) | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| verb-compre-pan | 3 | `Yo fui al mercado y compra pan.` | compra -> compré [Grammar / Verb forms and tenses: The past-tense verb needs to agree with the first-person subject “yo”.] | (none) | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| verb-compre-pan | 4 | `Yo fui al mercado y compra pan.` | compra -> compré [Grammar / Verb forms and tenses: The past-tense verb matches the completed action expressed by “fui.”] | (none) | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| verb-compre-pan | 5 | `Yo fui al mercado y compra pan.` | compra -> compré [Grammar / Verb forms and tenses: The past-tense verb needs to agree with the first-person subject “yo.”] | (none) | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| verb-ellos-estudian | 1 | `Ellos estudia todas las noches.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject “ellos.”] | (none) | `Ellos estudian todas las noches.` | Pass (correct_fix) |
| verb-ellos-estudian | 2 | `Ellos estudia todas las noches.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject “ellos.”] | (none) | `Ellos estudian todas las noches.` | Pass (correct_fix) |
| verb-ellos-estudian | 3 | `Ellos estudia todas las noches.` | estudia -> estudian [Grammar / Agreement: The verb needs to agree with the plural subject “ellos.”] | (none) | `Ellos estudian todas las noches.` | Pass (correct_fix) |
| verb-ellos-estudian | 4 | `Ellos estudia todas las noches.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject “ellos.”] | (none) | `Ellos estudian todas las noches.` | Pass (correct_fix) |
| verb-ellos-estudian | 5 | `Ellos estudia todas las noches.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject «ellos».] | (none) | `Ellos estudian todas las noches.` | Pass (correct_fix) |
| verb-nosotros-vivimos | 1 | `Nosotros vive cerca del centro.` | vive -> vivimos [Grammar / Agreement: The verb needs to agree with the first-person plural subject “nosotros.”] | (none) | `Nosotros vivimos cerca del centro.` | Pass (correct_fix) |
| verb-nosotros-vivimos | 2 | `Nosotros vive cerca del centro.` | vive -> vivimos [Grammar / Agreement: The verb must agree with the first-person plural subject “nosotros.”] | (none) | `Nosotros vivimos cerca del centro.` | Pass (correct_fix) |
| verb-nosotros-vivimos | 3 | `Nosotros vive cerca del centro.` | vive -> vivimos [Grammar / Agreement: The verb needs to agree with the first-person plural subject “nosotros.”] | (none) | `Nosotros vivimos cerca del centro.` | Pass (correct_fix) |
| verb-nosotros-vivimos | 4 | `Nosotros vive cerca del centro.` | Nosotros vive -> Nosotros vivimos [Grammar / Agreement: The verb must agree with the first-person plural subject nosotros.] | (none) | `Nosotros vivimos cerca del centro.` | Pass (correct_fix) |
| verb-nosotros-vivimos | 5 | `Nosotros vive cerca del centro.` | vive -> vivimos [Grammar / Agreement: The verb must agree with the first-person plural subject “nosotros.”] | (none) | `Nosotros vivimos cerca del centro.` | Pass (correct_fix) |
| prep-insisto-en | 1 | `Insisto que revises el contrato.` | Insisto que -> Insisto en que [Grammar / Prepositions: The verb «insistir» takes «en» before «que» in this construction.] | (none) | `Insisto en que revises el contrato.` | Pass (correct_fix) |
| prep-insisto-en | 2 | `Insisto que revises el contrato.` | Insisto que -> Insisto en que [Grammar / Prepositions: The verb «insistir» takes the preposition «en» before «que».] | (none) | `Insisto en que revises el contrato.` | Pass (correct_fix) |
| prep-insisto-en | 3 | `Insisto que revises el contrato.` | Insisto que -> Insisto en que [Grammar / Prepositions: The verb «insistir» takes the preposition «en» before «que».] | (none) | `Insisto en que revises el contrato.` | Pass (correct_fix) |
| prep-insisto-en | 4 | `Insisto que revises el contrato.` | Insisto que -> Insisto en que [Grammar / Prepositions: The verb «insistir» takes the preposition «en» before «que».] | (none) | `Insisto en que revises el contrato.` | Pass (correct_fix) |
| prep-insisto-en | 5 | `Insisto que revises el contrato.` | Insisto que -> Insisto en que [Grammar / Prepositions: The verb «insistir» takes the preposition «en» before «que» in this construction.] | (none) | `Insisto en que revises el contrato.` | Pass (correct_fix) |
| prep-empresa-en-la-que | 1 | `La empresa que trabajo está cerca.` | que trabajo -> en la que trabajo [Grammar / Prepositions: For the place where someone works, Spanish uses trabajar en.] | (none) | `La empresa en la que trabajo está cerca.` | Pass (correct_fix) |
| prep-empresa-en-la-que | 2 | `La empresa que trabajo está cerca.` | empresa que trabajo -> empresa en la que trabajo [Grammar / Prepositions: In Spanish, trabajar takes en when referring to the place where you work.] | (none) | `La empresa en la que trabajo está cerca.` | Pass (correct_fix) |
| prep-empresa-en-la-que | 3 | `La empresa que trabajo está cerca.` | que trabajo -> en la que trabajo [Grammar / Prepositions: The verb trabajar takes en when referring to the place where someone works.] | (none) | `La empresa en la que trabajo está cerca.` | Pass (correct_fix) |
| prep-empresa-en-la-que | 4 | `La empresa que trabajo está cerca.` | que trabajo -> en la que trabajo [Grammar / Prepositions: The verb trabajar takes en when referring to the place where someone works.] | (none) | `La empresa en la que trabajo está cerca.` | Pass (correct_fix) |
| prep-empresa-en-la-que | 5 | `La empresa que trabajo está cerca.` | que trabajo -> en la que trabajo [Grammar / Prepositions: The verb trabajar needs en here to mean working at a company.] | (none) | `La empresa en la que trabajo está cerca.` | Pass (correct_fix) |
| prep-dependo-de | 1 | `Dependo que me ayudes mañana.` | Dependo que -> Dependo de que [Grammar / Prepositions: The verb «depender» takes the preposition «de» before «que».] | (none) | `Dependo de que me ayudes mañana.` | Pass (correct_fix) |
| prep-dependo-de | 2 | `Dependo que me ayudes mañana.` | Dependo que -> Dependo de que [Grammar / Prepositions: The verb “depender” takes the preposition “de” before “que”.] | (none) | `Dependo de que me ayudes mañana.` | Pass (correct_fix) |
| prep-dependo-de | 3 | `Dependo que me ayudes mañana.` | Dependo que -> Dependo de que [Grammar / Prepositions: The verb «depender» takes the preposition «de» before «que».] | (none) | `Dependo de que me ayudes mañana.` | Pass (correct_fix) |
| prep-dependo-de | 4 | `Dependo que me ayudes mañana.` | Dependo que -> Dependo de que [Grammar / Prepositions: The verb «depender» takes the preposition «de» before «que».] | (none) | `Dependo de que me ayudes mañana.` | Pass (correct_fix) |
| prep-dependo-de | 5 | `Dependo que me ayudes mañana.` | Dependo que -> Dependo de que [Grammar / Prepositions: The verb “depender” takes the preposition “de” before “que.”] | (none) | `Dependo de que me ayudes mañana.` | Pass (correct_fix) |
| prep-pienso-en-ti | 1 | `Pienso ti todos los días.` | Pienso ti -> Pienso en ti [Grammar / Prepositions: In Spanish, pensar takes en when expressing what someone thinks about.] | (none) | `Pienso en ti todos los días.` | Pass (correct_fix) |
| prep-pienso-en-ti | 2 | `Pienso ti todos los días.` | Pienso ti -> Pienso en ti [Grammar / Prepositions: The verb pensar takes en before the person or thing being thought about.] | (none) | `Pienso en ti todos los días.` | Pass (correct_fix) |
| prep-pienso-en-ti | 3 | `Pienso ti todos los días.` | Pienso ti -> Pienso en ti [Grammar / Prepositions: When pensar means to think about someone, Spanish uses en.] | (none) | `Pienso en ti todos los días.` | Pass (correct_fix) |
| prep-pienso-en-ti | 4 | `Pienso ti todos los días.` | Pienso ti -> Pienso en ti [Grammar / Prepositions: The verb “pensar” needs “en” when it means to think about someone.] | (none) | `Pienso en ti todos los días.` | Pass (correct_fix) |
| prep-pienso-en-ti | 5 | `Pienso ti todos los días.` | Pienso ti -> Pienso en ti [Grammar / Prepositions: The verb pensar takes en when expressing what someone is thinking about.] | (none) | `Pienso en ti todos los días.` | Pass (correct_fix) |
| prep-sone-con | 1 | `Soñé mi antiguo colegio.` | Soñé mi antiguo colegio -> Soñé con mi antiguo colegio [Grammar / Prepositions: When soñé means that you dreamed about something, Spanish uses con.] | (none) | `Soñé con mi antiguo colegio.` | Pass (correct_fix) |
| prep-sone-con | 2 | `Soñé mi antiguo colegio.` | Soñé mi antiguo colegio -> Soñé con mi antiguo colegio [Grammar / Prepositions: When soñar means to dream about something, Spanish uses con.] | (none) | `Soñé con mi antiguo colegio.` | Pass (correct_fix) |
| prep-sone-con | 3 | `Soñé mi antiguo colegio.` | Soñé mi antiguo colegio -> Soñé con mi antiguo colegio [Grammar / Prepositions: Spanish uses “soñar con” when saying what you dreamed about.] | (none) | `Soñé con mi antiguo colegio.` | Pass (correct_fix) |
| prep-sone-con | 4 | `Soñé mi antiguo colegio.` | Soñé mi antiguo colegio -> Soñé con mi antiguo colegio [Grammar / Prepositions: The verb “soñar” takes “con” before the thing or person in a dream.] | (none) | `Soñé con mi antiguo colegio.` | Pass (correct_fix) |
| prep-sone-con | 5 | `Soñé mi antiguo colegio.` | Soñé mi antiguo colegio -> Soñé con mi antiguo colegio [Grammar / Prepositions: When you mean that you dreamed about something, Spanish uses soñar con.] | (none) | `Soñé con mi antiguo colegio.` | Pass (correct_fix) |
| article-puerta-principal | 1 | `Abrió puerta principal.` | puerta -> la puerta [Grammar / Articles: Spanish needs an article before this specific noun.] | (none) | `Abrió la puerta principal.` | Pass (correct_fix) |
| article-puerta-principal | 2 | `Abrió puerta principal.` | Abrió puerta -> Abrió la puerta [Grammar / Articles: Spanish normally requires an article before this singular count noun.] | (none) | `Abrió la puerta principal.` | Pass (correct_fix) |
| article-puerta-principal | 3 | `Abrió puerta principal.` | Abrió puerta -> Abrió la puerta [Grammar / Articles: Spanish generally needs an article before a singular count noun used this way.] | (none) | `Abrió la puerta principal.` | Pass (correct_fix) |
| article-puerta-principal | 4 | `Abrió puerta principal.` | Abrió puerta principal -> Abrió la puerta principal [Grammar / Articles: Spanish generally needs an article before this singular noun.] | (none) | `Abrió la puerta principal.` | Pass (correct_fix) |
| article-puerta-principal | 5 | `Abrió puerta principal.` | Abrió puerta -> Abrió la puerta [Grammar / Articles: Spanish normally requires an article before this singular count noun.] | (none) | `Abrió la puerta principal.` | Pass (correct_fix) |
| article-un-libro | 1 | `Necesito comprar libro para la clase.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish generally needs an article before a singular countable noun here.] | (none) | `Necesito comprar un libro para la clase.` | Pass (correct_fix) |
| article-un-libro | 2 | `Necesito comprar libro para la clase.` | comprar libro -> comprar un libro [Grammar / Articles: A singular count noun usually needs an article in Spanish.] | (none) | `Necesito comprar un libro para la clase.` | Pass (correct_fix) |
| article-un-libro | 3 | `Necesito comprar libro para la clase.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish usually needs an article before a singular countable noun.] | (none) | `Necesito comprar un libro para la clase.` | Pass (correct_fix) |
| article-un-libro | 4 | `Necesito comprar libro para la clase.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish uses an article before this singular count noun.] | (none) | `Necesito comprar un libro para la clase.` | Pass (correct_fix) |
| article-un-libro | 5 | `Necesito comprar libro para la clase.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish usually needs an article before a singular countable noun.] | (none) | `Necesito comprar un libro para la clase.` | Pass (correct_fix) |
| article-el-profesor-la-regla | 1 | `Profesor explicó regla otra vez.` | Profesor -> El profesor [Grammar / Articles: Spanish normally uses an article before a singular count noun used as the subject.]<br>regla -> la regla [Grammar / Articles: Spanish uses an article before a singular count noun in this sentence.] | (none) | `El profesor explicó la regla otra vez.` | Pass (correct_fix) |
| article-el-profesor-la-regla | 2 | `Profesor explicó regla otra vez.` | Profesor -> El profesor [Grammar / Articles: A singular count noun used as the subject needs an article here.]<br>regla -> la regla [Grammar / Articles: A singular count noun used as the object needs an article here.] | (none) | `El profesor explicó la regla otra vez.` | Pass (correct_fix) |
| article-el-profesor-la-regla | 3 | `Profesor explicó regla otra vez.` | Profesor -> El profesor [Grammar / Articles: Spanish generally uses an article before a singular countable noun used as the subject.]<br>regla -> la regla [Grammar / Articles: Spanish uses an article before this singular countable noun.] | (none) | `El profesor explicó la regla otra vez.` | Pass (correct_fix) |
| article-el-profesor-la-regla | 4 | `Profesor explicó regla otra vez.` | Profesor -> El profesor [Grammar / Articles: Spanish normally uses an article before a singular countable noun used as the subject.]<br>regla -> la regla [Grammar / Articles: Spanish normally uses an article before a singular countable noun used as the object.] | (none) | `El profesor explicó la regla otra vez.` | Pass (correct_fix) |
| article-el-profesor-la-regla | 5 | `Profesor explicó regla otra vez.` | Profesor -> El profesor [Grammar / Articles: A singular countable noun used as the subject generally needs an article in Spanish.]<br>regla -> la regla [Grammar / Articles: A singular countable noun used as the object generally needs an article in Spanish.] | (none) | `El profesor explicó la regla otra vez.` | Pass (correct_fix) |
| article-la-tienda | 1 | `Fui a tienda después del trabajo.` | a tienda -> a la tienda [Grammar / Articles: Spanish uses the feminine article “la” with “tienda” here.] | (none) | `Fui a la tienda después del trabajo.` | Pass (correct_fix) |
| article-la-tienda | 2 | `Fui a tienda después del trabajo.` | a tienda -> a la tienda [Grammar / Articles: Spanish normally uses an article before “tienda” here.] | (none) | `Fui a la tienda después del trabajo.` | Pass (correct_fix) |
| article-la-tienda | 3 | `Fui a tienda después del trabajo.` | a tienda -> a la tienda [Grammar / Articles: Spanish uses the article la with tienda here.] | (none) | `Fui a la tienda después del trabajo.` | Pass (correct_fix) |
| article-la-tienda | 4 | `Fui a tienda después del trabajo.` | a tienda -> a la tienda [Grammar / Articles: Spanish normally uses an article before “tienda” here.] | (none) | `Fui a la tienda después del trabajo.` | Pass (correct_fix) |
| article-la-tienda | 5 | `Fui a tienda después del trabajo.` | a tienda -> a la tienda [Grammar / Articles: Spanish needs the definite article before “tienda” here.] | (none) | `Fui a la tienda después del trabajo.` | Pass (correct_fix) |
| article-cita-medico | 1 | `Tengo cita con médico mañana.` | con médico -> con el médico [Grammar / Articles: Spanish normally uses an article before “médico” when referring to the doctor.] | (none) | `Tengo cita con el médico mañana.` | Fail (partial_fix) |
| article-cita-medico | 2 | `Tengo cita con médico mañana.` | con médico -> con el médico [Grammar / Articles: Spanish normally uses the definite article before a profession in this phrase.] | (none) | `Tengo cita con el médico mañana.` | Fail (partial_fix) |
| article-cita-medico | 3 | `Tengo cita con médico mañana.` | con médico -> con el médico [Grammar / Articles: Spanish usually requires an article before a specific doctor in this phrase.] | (none) | `Tengo cita con el médico mañana.` | Fail (partial_fix) |
| article-cita-medico | 4 | `Tengo cita con médico mañana.` | con médico -> con el médico [Grammar / Articles: Spanish normally uses an article before “médico” in this phrase.] | (none) | `Tengo cita con el médico mañana.` | Fail (partial_fix) |
| article-cita-medico | 5 | `Tengo cita con médico mañana.` | con médico -> con el médico [Grammar / Articles: Spanish normally uses an article before “médico” when referring to the doctor you have an appointment with.] | (none) | `Tengo cita con el médico mañana.` | Fail (partial_fix) |
| subj-estudies | 1 | `Es importante que estudias.` | estudias -> estudies [Grammar / Subjunctive: After «es importante que», Spanish uses the subjunctive.] | (none) | `Es importante que estudies.` | Pass (correct_fix) |
| subj-estudies | 2 | `Es importante que estudias.` | estudias -> estudies [Grammar / Subjunctive: After “es importante que,” Spanish uses the subjunctive.] | (none) | `Es importante que estudies.` | Pass (correct_fix) |
| subj-estudies | 3 | `Es importante que estudias.` | estudias -> estudies [Grammar / Subjunctive: After «es importante que», Spanish uses the subjunctive.] | (none) | `Es importante que estudies.` | Pass (correct_fix) |
| subj-estudies | 4 | `Es importante que estudias.` | estudias -> estudies [Grammar / Subjunctive: After “es importante que,” Spanish uses the subjunctive.] | (none) | `Es importante que estudies.` | Pass (correct_fix) |
| subj-estudies | 5 | `Es importante que estudias.` | estudias -> estudies [Grammar / Subjunctive: After “es importante que,” Spanish uses the subjunctive.] | (none) | `Es importante que estudies.` | Pass (correct_fix) |
| subj-tenga-razon | 1 | `No creo que tiene razón.` | tiene -> tenga [Grammar / Subjunctive: After “no creo que,” Spanish uses the subjunctive.] | (none) | `No creo que tenga razón.` | Pass (correct_fix) |
| subj-tenga-razon | 2 | `No creo que tiene razón.` | tiene -> tenga [Grammar / Subjunctive: After “no creo que,” Spanish uses the subjunctive to express doubt.] | (none) | `No creo que tenga razón.` | Pass (correct_fix) |
| subj-tenga-razon | 3 | `No creo que tiene razón.` | tiene razón -> tenga razón [Grammar / Subjunctive: After «no creo que», Spanish uses the subjunctive here.] | (none) | `No creo que tenga razón.` | Pass (correct_fix) |
| subj-tenga-razon | 4 | `No creo que tiene razón.` | tiene -> tenga [Grammar / Subjunctive: After “no creo que,” Spanish uses the subjunctive.] | (none) | `No creo que tenga razón.` | Pass (correct_fix) |
| subj-tenga-razon | 5 | `No creo que tiene razón.` | tiene -> tenga [Grammar / Subjunctive: After “no creo que,” Spanish uses the subjunctive to express doubt.] | (none) | `No creo que tenga razón.` | Pass (correct_fix) |
| subj-vengas | 1 | `Quiero que vienes conmigo.` | vienes -> vengas [Grammar / Subjunctive: After “quiero que,” Spanish uses the subjunctive for the person being asked to come.] | (none) | `Quiero que vengas conmigo.` | Pass (correct_fix) |
| subj-vengas | 2 | `Quiero que vienes conmigo.` | vienes -> vengas [Grammar / Subjunctive: After “quiero que,” Spanish uses the subjunctive.] | (none) | `Quiero que vengas conmigo.` | Pass (correct_fix) |
| subj-vengas | 3 | `Quiero que vienes conmigo.` | vienes -> vengas [Grammar / Subjunctive: After “quiero que,” Spanish uses the subjunctive.] | (none) | `Quiero que vengas conmigo.` | Pass (correct_fix) |
| subj-vengas | 4 | `Quiero que vienes conmigo.` | vienes -> vengas [Grammar / Subjunctive: After “quiero que,” Spanish uses the subjunctive here.] | (none) | `Quiero que vengas conmigo.` | Pass (correct_fix) |
| subj-vengas | 5 | `Quiero que vienes conmigo.` | vienes -> vengas [Grammar / Subjunctive: After “quiero que,” Spanish uses the subjunctive for the other person's action.] | (none) | `Quiero que vengas conmigo.` | Pass (correct_fix) |
| subj-enviara | 1 | `Era necesario que enviaba su parte.` | enviaba -> enviara [Grammar / Subjunctive: After “era necesario que,” Spanish uses the subjunctive here.] | (none) | `Era necesario que enviara su parte.` | Pass (correct_fix) |
| subj-enviara | 2 | `Era necesario que enviaba su parte.` | enviaba -> enviara [Grammar / Subjunctive: After “era necesario que,” Spanish uses the subjunctive.] | (none) | `Era necesario que enviara su parte.` | Pass (correct_fix) |
| subj-enviara | 3 | `Era necesario que enviaba su parte.` | enviaba -> enviara [Grammar / Subjunctive: After «era necesario que», Spanish uses the subjunctive here.] | (none) | `Era necesario que enviara su parte.` | Pass (correct_fix) |
| subj-enviara | 4 | `Era necesario que enviaba su parte.` | enviaba -> enviara [Grammar / Subjunctive: After “era necesario que,” Spanish uses the subjunctive.] | (none) | `Era necesario que enviara su parte.` | Pass (correct_fix) |
| subj-enviara | 5 | `Era necesario que enviaba su parte.` | enviaba -> enviara [Grammar / Subjunctive: After «era necesario que», Spanish uses the subjunctive here.] | (none) | `Era necesario que enviara su parte.` | Pass (correct_fix) |
| subj-hable-frances | 1 | `Busco a alguien que habla francés.` | habla -> hable [Grammar / Subjunctive: The subjunctive is used for someone you are looking for whose identity is not specified.] | (none) | `Busco a alguien que hable francés.` | Pass (correct_fix) |
| subj-hable-frances | 2 | `Busco a alguien que habla francés.` | habla -> hable [Grammar / Subjunctive: The subjunctive is used after «busco a alguien que» when the person is not identified.] | (none) | `Busco a alguien que hable francés.` | Pass (correct_fix) |
| subj-hable-frances | 3 | `Busco a alguien que habla francés.` | habla -> hable [Grammar / Subjunctive: The subjunctive is used for a person you are looking for but have not identified.] | (none) | `Busco a alguien que hable francés.` | Pass (correct_fix) |
| subj-hable-frances | 4 | `Busco a alguien que habla francés.` | habla -> hable [Grammar / Subjunctive: The subjunctive is used because you are looking for someone whose identity is not yet known.] | (none) | `Busco a alguien que hable francés.` | Pass (correct_fix) |
| subj-hable-frances | 5 | `Busco a alguien que habla francés.` | habla -> hable [Grammar / Subjunctive: The subjunctive is used for someone whose identity is not yet known.] | (none) | `Busco a alguien que hable francés.` | Pass (correct_fix) |
| missing-que-creo | 1 | `Creo está bien terminar hoy.` | Creo está -> Creo que está [Grammar / Sentence structure: Spanish uses que to connect creo with the following clause.] | (none) | `Creo que está bien terminar hoy.` | Pass (correct_fix) |
| missing-que-creo | 2 | `Creo está bien terminar hoy.` | Creo está -> Creo que está [Grammar / Sentence structure: Spanish uses que to introduce the clause expressing what you think.] | (none) | `Creo que está bien terminar hoy.` | Pass (correct_fix) |
| missing-que-creo | 3 | `Creo está bien terminar hoy.` | Creo está -> Creo que está [Grammar / Sentence structure: Spanish uses que to introduce the clause after creo.] | (none) | `Creo que está bien terminar hoy.` | Pass (correct_fix) |
| missing-que-creo | 4 | `Creo está bien terminar hoy.` | Creo está bien -> Creo que está bien [Grammar / Sentence structure: Spanish uses que to introduce the clause expressing what you think.] | (none) | `Creo que está bien terminar hoy.` | Pass (correct_fix) |
| missing-que-creo | 5 | `Creo está bien terminar hoy.` | Creo está -> Creo que está [Grammar / Sentence structure: Spanish uses que to introduce the clause expressing what you think.] | (none) | `Creo que está bien terminar hoy.` | Pass (correct_fix) |
| missing-les-ninos | 1 | `A los niños expliqué la regla.` | A los niños expliqué -> A los niños les expliqué [Grammar / Pronouns: When the indirect object comes before the verb, Spanish normally repeats it with the pronoun «les».] | (none) | `A los niños les expliqué la regla.` | Pass (correct_fix) |
| missing-les-ninos | 2 | `A los niños expliqué la regla.` | A los niños expliqué -> A los niños les expliqué [Grammar / Pronouns: When an indirect object comes before the verb, Spanish requires the matching pronoun “les”.] | (none) | `A los niños les expliqué la regla.` | Pass (correct_fix) |
| missing-les-ninos | 3 | `A los niños expliqué la regla.` | A los niños expliqué -> A los niños les expliqué [Grammar / Pronouns: A fronted indirect object needs the matching pronoun “les” here.] | (none) | `A los niños les expliqué la regla.` | Pass (correct_fix) |
| missing-les-ninos | 4 | `A los niños expliqué la regla.` | A los niños expliqué -> A los niños les expliqué [Grammar / Pronouns: Spanish requires the indirect object pronoun “les” alongside this fronted indirect object.] | (none) | `A los niños les expliqué la regla.` | Pass (correct_fix) |
| missing-les-ninos | 5 | `A los niños expliqué la regla.` | A los niños expliqué -> A los niños les expliqué [Grammar / Pronouns: A fronted indirect object like “a los niños” is doubled with the pronoun “les” in Spanish.] | (none) | `A los niños les expliqué la regla.` | Pass (correct_fix) |
| missing-personal-a-profesor | 1 | `Vi mi profesor en la estación.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal “a” before a specific person who is the direct object.] | (none) | `Vi a mi profesor en la estación.` | Pass (correct_fix) |
| missing-personal-a-profesor | 2 | `Vi mi profesor en la estación.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal «a» before a specific person who is the direct object.] | (none) | `Vi a mi profesor en la estación.` | Pass (correct_fix) |
| missing-personal-a-profesor | 3 | `Vi mi profesor en la estación.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal “a” before a specific person who is the direct object.] | (none) | `Vi a mi profesor en la estación.` | Pass (correct_fix) |
| missing-personal-a-profesor | 4 | `Vi mi profesor en la estación.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal “a” before a specific person who is the direct object.] | (none) | `Vi a mi profesor en la estación.` | Pass (correct_fix) |
| missing-personal-a-profesor | 5 | `Vi mi profesor en la estación.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal “a” before a specific person who is the direct object.] | (none) | `Vi a mi profesor en la estación.` | Pass (correct_fix) |
| missing-se-levanto | 1 | `Levantó temprano ayer.` | Levantó -> Se levantó [Grammar / Pronouns: The reflexive pronoun se is needed when levantarse means “to get up.”] | (none) | `Se levantó temprano ayer.` | Pass (correct_fix) |
| missing-se-levanto | 2 | `Levantó temprano ayer.` | Levantó -> Se levantó [Grammar / Pronouns: The reflexive pronoun se is needed when levantarse means “to get up.”] | (none) | `Se levantó temprano ayer.` | Pass (correct_fix) |
| missing-se-levanto | 3 | `Levantó temprano ayer.` | Levantó temprano -> Se levantó temprano [Grammar / Pronouns: The verb meaning “to get up” is reflexive in Spanish and needs se.] | (none) | `Se levantó temprano ayer.` | Pass (correct_fix) |
| missing-se-levanto | 4 | `Levantó temprano ayer.` | Levantó -> Se levantó [Grammar / Pronouns: For the meaning “got up,” Spanish uses the reflexive pronoun se.] | (none) | `Se levantó temprano ayer.` | Pass (correct_fix) |
| missing-se-levanto | 5 | `Levantó temprano ayer.` | Levantó -> Se levantó [Grammar / Pronouns: Spanish uses the reflexive pronoun se to mean “got up.”] | (none) | `Se levantó temprano ayer.` | Pass (correct_fix) |
| missing-le-gusta | 1 | `A Juan gusta el café.` | A Juan gusta -> A Juan le gusta [Grammar / Pronouns: The indirect object pronoun “le” is needed with “gustar” to refer to Juan.] | (none) | `A Juan le gusta el café.` | Pass (correct_fix) |
| missing-le-gusta | 2 | `A Juan gusta el café.` | A Juan gusta -> A Juan le gusta [Grammar / Pronouns: The verb gustar needs an indirect object pronoun referring to Juan.] | (none) | `A Juan le gusta el café.` | Pass (correct_fix) |
| missing-le-gusta | 3 | `A Juan gusta el café.` | A Juan gusta -> A Juan le gusta [Grammar / Pronouns: The verb gustar needs an indirect object pronoun referring to Juan.] | (none) | `A Juan le gusta el café.` | Pass (correct_fix) |
| missing-le-gusta | 4 | `A Juan gusta el café.` | A Juan gusta -> A Juan le gusta [Grammar / Pronouns: The indirect object pronoun “le” is needed with “gustar” to refer to Juan.] | (none) | `A Juan le gusta el café.` | Pass (correct_fix) |
| missing-le-gusta | 5 | `A Juan gusta el café.` | A Juan gusta -> A Juan le gusta [Grammar / Pronouns: The indirect object pronoun le is needed with gustar here.] | (none) | `A Juan le gusta el café.` | Pass (correct_fix) |
| delete-repeated-yo-estudio | 1 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | y yo estudio -> y estudio [Natural phrasing: Spanish usually leaves out a repeated subject pronoun when both clauses have the same subject.] | `Yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| delete-repeated-yo-estudio | 2 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | y yo estudio -> y estudio [Natural phrasing: Spanish usually omits a repeated subject pronoun when the subject stays the same.] | `Yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| delete-repeated-yo-estudio | 3 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | y yo estudio -> y estudio [Natural phrasing: The second «yo» is unnecessary because the subject stays the same.] | `Yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| delete-repeated-yo-estudio | 4 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | y yo estudio -> y estudio [Natural phrasing: When the subject stays the same, Spanish usually leaves out the repeated pronoun.] | `Yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| delete-repeated-yo-estudio | 5 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | y yo estudio -> y estudio [Natural phrasing: The second «yo» is unnecessary because the subject is already clear.] | `Yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| delete-repeated-ellos-visitaron | 1 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | y ellos visitaron -> y visitaron [Natural phrasing: The second subject pronoun is unnecessary because the subject stays the same.] | `Ellos viajaron a México y visitaron varias ciudades.` | Pass (correct_fix) |
| delete-repeated-ellos-visitaron | 2 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | y ellos visitaron -> y visitaron [Natural phrasing: When the subject stays the same, Spanish usually leaves out the repeated pronoun.] | `Ellos viajaron a México y visitaron varias ciudades.` | Pass (correct_fix) |
| delete-repeated-ellos-visitaron | 3 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | y ellos visitaron -> y visitaron [Natural phrasing: Spanish usually omits a repeated subject pronoun when it refers to the same people.] | `Ellos viajaron a México y visitaron varias ciudades.` | Pass (correct_fix) |
| delete-repeated-ellos-visitaron | 4 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | y ellos visitaron -> y visitaron [Natural phrasing: Spanish usually omits a repeated subject pronoun when it refers to the same people.] | `Ellos viajaron a México y visitaron varias ciudades.` | Pass (correct_fix) |
| delete-repeated-ellos-visitaron | 5 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | y ellos visitaron -> y visitaron [Natural phrasing: The subject is already clear, so Spanish naturally omits the repeated pronoun.] | `Ellos viajaron a México y visitaron varias ciudades.` | Pass (correct_fix) |
| delete-repeated-a-mi | 1 | `A mí me gusta el café a mí.` | (none) | café a mí -> café [Natural phrasing: The opening «A mí» already provides emphasis, so repeating it at the end is unnecessary.] | `A mí me gusta el café.` | Pass (correct_fix) |
| delete-repeated-a-mi | 2 | `A mí me gusta el café a mí.` | (none) | café a mí -> café [Natural phrasing: The second «a mí» repeats the emphasis already expressed at the start.] | `A mí me gusta el café.` | Pass (correct_fix) |
| delete-repeated-a-mi | 3 | `A mí me gusta el café a mí.` | (none) | el café a mí -> el café [Natural phrasing: The opening «A mí» already expresses this, so repeating it at the end is unnecessary.] | `A mí me gusta el café.` | Pass (correct_fix) |
| delete-repeated-a-mi | 4 | `A mí me gusta el café a mí.` | (none) | café a mí -> café [Natural phrasing: The final «a mí» repeats the emphasis already expressed at the start.] | `A mí me gusta el café.` | Pass (correct_fix) |
| delete-repeated-a-mi | 5 | `A mí me gusta el café a mí.` | (none) | café a mí -> café [Natural phrasing: The second «a mí» repeats the emphasis already expressed at the start.] | `A mí me gusta el café.` | Pass (correct_fix) |
| delete-repeated-yo-compre | 1 | `Yo fui al mercado y yo compré pan.` | (none) | y yo compré -> y compré [Natural phrasing: When the subject stays the same, Spanish usually leaves out the repeated pronoun.] | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| delete-repeated-yo-compre | 2 | `Yo fui al mercado y yo compré pan.` | (none) | y yo compré -> y compré [Natural phrasing: The second subject pronoun is unnecessary because the subject stays the same.] | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| delete-repeated-yo-compre | 3 | `Yo fui al mercado y yo compré pan.` | (none) | y yo compré -> y compré [Natural phrasing: The second «yo» is unnecessary because the subject is already clear.] | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| delete-repeated-yo-compre | 4 | `Yo fui al mercado y yo compré pan.` | (none) | yo compré -> compré [Natural phrasing: Spanish usually omits a repeated subject pronoun when the subject stays the same.] | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| delete-repeated-yo-compre | 5 | `Yo fui al mercado y yo compré pan.` | (none) | y yo compré -> y compré [Natural phrasing: The second yo is unnecessary because the subject is already clear.] | `Yo fui al mercado y compré pan.` | Pass (correct_fix) |
| delete-repeated-nosotros | 1 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | y nosotros llegamos -> y llegamos [Natural phrasing: The second nosotros is unnecessary because the subject is already clear.] | `Nosotros salimos temprano y llegamos a tiempo.` | Pass (correct_fix) |
| delete-repeated-nosotros | 2 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | y nosotros llegamos -> y llegamos [Natural phrasing: Spanish usually leaves out a repeated subject pronoun when the subject stays the same.] | `Nosotros salimos temprano y llegamos a tiempo.` | Pass (correct_fix) |
| delete-repeated-nosotros | 3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | y nosotros llegamos -> y llegamos [Natural phrasing: The second subject pronoun is unnecessary because the subject is already clear.] | `Nosotros salimos temprano y llegamos a tiempo.` | Pass (correct_fix) |
| delete-repeated-nosotros | 4 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | y nosotros llegamos -> y llegamos [Natural phrasing: Spanish usually omits a repeated subject pronoun when the subject stays the same.] | `Nosotros salimos temprano y llegamos a tiempo.` | Pass (correct_fix) |
| delete-repeated-nosotros | 5 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | y nosotros llegamos -> y llegamos [Natural phrasing: The second subject pronoun is unnecessary because the subject stays the same.] | `Nosotros salimos temprano y llegamos a tiempo.` | Pass (correct_fix) |
| ser-profesor | 1 | `Mi hermano está profesor.` | está profesor -> es profesor [Grammar / Ser and estar: Spanish uses ser to identify someone's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 2 | `Mi hermano está profesor.` | está profesor -> es profesor [Grammar / Ser and estar: Use ser to identify someone's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 3 | `Mi hermano está profesor.` | está -> es [Grammar / Ser and estar: Spanish uses ser to state someone's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 4 | `Mi hermano está profesor.` | está profesor -> es profesor [Grammar / Ser and estar: Spanish uses ser to state someone's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| ser-profesor | 5 | `Mi hermano está profesor.` | está profesor -> es profesor [Grammar / Ser and estar: Spanish uses ser for a person's profession.] | (none) | `Mi hermano es profesor.` | Pass (correct_fix) |
| haber-veinte-personas | 1 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses impersonal haber to say how many people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 2 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses “hay” to say that people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 3 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses “hay” to say that people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 4 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses “haber” to state how many people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| haber-veinte-personas | 5 | `En la sala son veinte personas.` | son -> hay [Grammar / Sentence structure: Spanish uses haber in its impersonal form hay to say that people are present in a place.] | (none) | `En la sala hay veinte personas.` | Pass (correct_fix) |
| ser-capital-madrid | 1 | `Madrid está la capital de España.` | está -> es [Grammar / Ser and estar: Use ser to identify Madrid as the capital of Spain.] | (none) | `Madrid es la capital de España.` | Pass (correct_fix) |
| ser-capital-madrid | 2 | `Madrid está la capital de España.` | está -> es [Grammar / Ser and estar: Use ser to identify Madrid as the capital of Spain.] | (none) | `Madrid es la capital de España.` | Pass (correct_fix) |
| ser-capital-madrid | 3 | `Madrid está la capital de España.` | (none) | (none) | `Madrid está la capital de España.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| ser-capital-madrid | 4 | `Madrid está la capital de España.` | (none) | (none) | `Madrid está la capital de España.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| ser-capital-madrid | 5 | `Madrid está la capital de España.` | (none) | (none) | `Madrid está la capital de España.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| estar-contento | 1 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| estar-contento | 2 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| estar-contento | 3 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| estar-contento | 4 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| estar-contento | 5 | `Estoy muy contento con el resultado.` | (none) | (none) | `Estoy muy contento con el resultado.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| ser-reunion-segunda-planta | 1 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| ser-reunion-segunda-planta | 2 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| ser-reunion-segunda-planta | 3 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| ser-reunion-segunda-planta | 4 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| ser-reunion-segunda-planta | 5 | `La reunión es en la segunda planta.` | (none) | (none) | `La reunión es en la segunda planta.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-personas | 1 | `Habían muchas personas en la entrada.` | (none) | (none) | `Habían muchas personas en la entrada.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-personas | 2 | `Habían muchas personas en la entrada.` | (none) | (none) | `Habían muchas personas en la entrada.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-personas | 3 | `Habían muchas personas en la entrada.` | (none) | (none) | `Habían muchas personas en la entrada.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-personas | 4 | `Habían muchas personas en la entrada.` | (none) | (none) | `Habían muchas personas en la entrada.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-personas | 5 | `Habían muchas personas en la entrada.` | (none) | (none) | `Habían muchas personas en la entrada.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-hubo-problemas | 1 | `Hubieron varios problemas durante la reunión.` | (none) | (none) | `Hubieron varios problemas durante la reunión.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-hubo-problemas | 2 | `Hubieron varios problemas durante la reunión.` | (none) | (none) | `Hubieron varios problemas durante la reunión.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-hubo-problemas | 3 | `Hubieron varios problemas durante la reunión.` | (none) | (none) | `Hubieron varios problemas durante la reunión.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-hubo-problemas | 4 | `Hubieron varios problemas durante la reunión.` | (none) | (none) | `Hubieron varios problemas durante la reunión.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-hubo-problemas | 5 | `Hubieron varios problemas durante la reunión.` | (none) | (none) | `Hubieron varios problemas durante la reunión.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-venden-pisos | 1 | `Se vende pisos en el centro.` | (none) | (none) | `Se vende pisos en el centro.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-venden-pisos | 2 | `Se vende pisos en el centro.` | (none) | (none) | `Se vende pisos en el centro.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-venden-pisos | 3 | `Se vende pisos en el centro.` | (none) | (none) | `Se vende pisos en el centro.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-venden-pisos | 4 | `Se vende pisos en el centro.` | (none) | (none) | `Se vende pisos en el centro.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-venden-pisos | 5 | `Se vende pisos en el centro.` | (none) | (none) | `Se vende pisos en el centro.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-necesitan-voluntarios | 1 | `Se necesita voluntarios para el evento.` | (none) | (none) | `Se necesita voluntarios para el evento.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-necesitan-voluntarios | 2 | `Se necesita voluntarios para el evento.` | (none) | (none) | `Se necesita voluntarios para el evento.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-necesitan-voluntarios | 3 | `Se necesita voluntarios para el evento.` | (none) | (none) | `Se necesita voluntarios para el evento.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-necesitan-voluntarios | 4 | `Se necesita voluntarios para el evento.` | (none) | (none) | `Se necesita voluntarios para el evento.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| se-necesitan-voluntarios | 5 | `Se necesita voluntarios para el evento.` | (none) | (none) | `Se necesita voluntarios para el evento.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-cifras | 1 | `Habían varias cifras incorrectas.` | (none) | (none) | `Habían varias cifras incorrectas.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-cifras | 2 | `Habían varias cifras incorrectas.` | (none) | (none) | `Habían varias cifras incorrectas.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-cifras | 3 | `Habían varias cifras incorrectas.` | (none) | (none) | `Habían varias cifras incorrectas.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-cifras | 4 | `Habían varias cifras incorrectas.` | (none) | (none) | `Habían varias cifras incorrectas.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| haber-habia-cifras | 5 | `Habían varias cifras incorrectas.` | (none) | (none) | `Habían varias cifras incorrectas.` | Fail (error: Chat completions call failed with HTTP 429: {) |
| collocation-hacer-decision | 1 | `Necesito hacer una decisión.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish uses «tomar una decisión» rather than a literal translation of “make a decision.”] | `Necesito tomar una decisión.` | Pass (correct_fix) |
| collocation-hacer-decision | 2 | `Necesito hacer una decisión.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish naturally uses «tomar una decisión» rather than translating “make a decision” literally.] | `Necesito tomar una decisión.` | Pass (correct_fix) |
| collocation-hacer-decision | 3 | `Necesito hacer una decisión.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: In Spanish, the natural expression is “tomar una decisión”.] | `Necesito tomar una decisión.` | Pass (correct_fix) |
| collocation-hacer-decision | 4 | `Necesito hacer una decisión.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish naturally uses «tomar una decisión» for this expression.] | `Necesito tomar una decisión.` | Pass (correct_fix) |
| collocation-hacer-decision | 5 | `Necesito hacer una decisión.` | (none) | hacer una decisión -> tomar una decisión [Natural phrasing: Spanish naturally uses «tomar» with «una decisión».] | `Necesito tomar una decisión.` | Pass (correct_fix) |
| collocation-hacer-atencion | 1 | `Tenemos que hacer atención.` | (none) | (none) | `Tenemos que hacer atención.` | Fail (missed_issue) |
| collocation-hacer-atencion | 2 | `Tenemos que hacer atención.` | (none) | hacer atención -> prestar atención [Natural phrasing: Spanish speakers usually say «prestar atención».] | `Tenemos que prestar atención.` | Pass (correct_fix) |
| collocation-hacer-atencion | 3 | `Tenemos que hacer atención.` | (none) | (none) | `Tenemos que hacer atención.` | Fail (missed_issue) |
| collocation-hacer-atencion | 4 | `Tenemos que hacer atención.` | (none) | (none) | `Tenemos que hacer atención.` | Fail (missed_issue) |
| collocation-hacer-atencion | 5 | `Tenemos que hacer atención.` | (none) | hacer atención -> prestar atención [Natural phrasing: Spanish naturally expresses this as «prestar atención».] | `Tenemos que prestar atención.` | Pass (correct_fix) |
| collocation-tomar-reunion | 1 | `El equipo tomó una reunión.` | (none) | tomó una reunión -> tuvo una reunión [Natural phrasing: In Spanish, «tener una reunión» is a natural way to say that a meeting took place.] | `El equipo tuvo una reunión.` | Pass (correct_fix) |
| collocation-tomar-reunion | 2 | `El equipo tomó una reunión.` | (none) | tomó una reunión -> tuvo una reunión [Natural phrasing: Spanish normally says «tener una reunión» rather than translating “take a meeting” literally.] | `El equipo tuvo una reunión.` | Pass (correct_fix) |
| collocation-tomar-reunion | 3 | `El equipo tomó una reunión.` | (none) | tomó una reunión -> tuvo una reunión [Natural phrasing: Spanish speakers usually say «tener una reunión» rather than translate «take a meeting» literally.] | `El equipo tuvo una reunión.` | Pass (correct_fix) |
| collocation-tomar-reunion | 4 | `El equipo tomó una reunión.` | (none) | tomó una reunión -> tuvo una reunión [Natural phrasing: In Spanish, «tener una reunión» is a natural way to say that a team met.] | `El equipo tuvo una reunión.` | Pass (correct_fix) |
| collocation-tomar-reunion | 5 | `El equipo tomó una reunión.` | (none) | tomó una reunión -> tuvo una reunión [Natural phrasing: Spanish speakers usually say «tener una reunión» rather than «tomar una reunión».] | `El equipo tuvo una reunión.` | Pass (correct_fix) |
| collocation-hacer-paseo | 1 | `Ella hizo un paseo.` | (none) | (none) | `Ella hizo un paseo.` | Fail (missed_issue) |
| collocation-hacer-paseo | 2 | `Ella hizo un paseo.` | (none) | hizo un paseo -> dio un paseo [Natural phrasing: Spanish speakers usually say «dar un paseo».] | `Ella dio un paseo.` | Pass (correct_fix) |
| collocation-hacer-paseo | 3 | `Ella hizo un paseo.` | (none) | hizo un paseo -> dio un paseo [Natural phrasing: Spanish speakers usually say «dar un paseo» for taking a walk.] | `Ella dio un paseo.` | Pass (correct_fix) |
| collocation-hacer-paseo | 4 | `Ella hizo un paseo.` | (none) | (none) | `Ella hizo un paseo.` | Fail (missed_issue) |
| collocation-hacer-paseo | 5 | `Ella hizo un paseo.` | (none) | (none) | `Ella hizo un paseo.` | Fail (missed_issue) |
| collocation-preguntar-pregunta | 1 | `Quiero preguntar una pregunta.` | (none) | preguntar una pregunta -> hacer una pregunta [Natural phrasing: Spanish naturally uses «hacer una pregunta» for “ask a question”.] | `Quiero hacer una pregunta.` | Pass (correct_fix) |
| collocation-preguntar-pregunta | 2 | `Quiero preguntar una pregunta.` | (none) | preguntar una pregunta -> hacer una pregunta [Natural phrasing: Spanish usually says «hacer una pregunta» instead of repeating the idea of asking.] | `Quiero hacer una pregunta.` | Pass (correct_fix) |
| collocation-preguntar-pregunta | 3 | `Quiero preguntar una pregunta.` | (none) | preguntar una pregunta -> hacer una pregunta [Natural phrasing: Spanish speakers usually say «hacer una pregunta».] | `Quiero hacer una pregunta.` | Pass (correct_fix) |
| collocation-preguntar-pregunta | 4 | `Quiero preguntar una pregunta.` | (none) | preguntar una pregunta -> hacer una pregunta [Natural phrasing: Spanish commonly uses «hacer una pregunta» to avoid repeating the same idea.] | `Quiero hacer una pregunta.` | Pass (correct_fix) |
| collocation-preguntar-pregunta | 5 | `Quiero preguntar una pregunta.` | (none) | preguntar una pregunta -> hacer una pregunta [Natural phrasing: Spanish speakers usually say «hacer una pregunta» to avoid repeating the same idea.] | `Quiero hacer una pregunta.` | Pass (correct_fix) |
| false-friend-atendio-universidad | 1 | `Atendió la universidad en Madrid.` | Atendió -> Asistió a [Word Choice / False friends: For attending an educational institution, Spanish uses «asistir a», not «atender».] | (none) | `Asistió a la universidad en Madrid.` | Pass (correct_fix) |
| false-friend-atendio-universidad | 2 | `Atendió la universidad en Madrid.` | Atendió la universidad -> Asistió a la universidad [Word Choice / Mixed-up pairs: For attending an institution, Spanish uses “asistir a”; “atender” means to attend to or serve someone.] | (none) | `Asistió a la universidad en Madrid.` | Pass (correct_fix) |
| false-friend-atendio-universidad | 3 | `Atendió la universidad en Madrid.` | Atendió la universidad -> Asistió a la universidad [Word Choice / Mixed-up pairs: For attending an institution, Spanish uses “asistir a”; “atender” means to assist or take care of someone or something.] | (none) | `Asistió a la universidad en Madrid.` | Pass (correct_fix) |
| false-friend-atendio-universidad | 4 | `Atendió la universidad en Madrid.` | Atendió -> Asistió a [Word Choice / Mixed-up pairs: For attending an institution, Spanish uses «asistir a»; «atender» means to attend to or serve.] | (none) | `Asistió a la universidad en Madrid.` | Pass (correct_fix) |
| false-friend-atendio-universidad | 5 | `Atendió la universidad en Madrid.` | Atendió la universidad -> Asistió a la universidad [Word Choice / False friends: “Atender” means to attend to or take care of something, not to attend an educational institution.] | (none) | `Asistió a la universidad en Madrid.` | Pass (correct_fix) |
| false-friend-libreria | 1 | `Saqué un libro de la librería pública.` | librería -> biblioteca [Word Choice / False friends: For a public library, Spanish uses “biblioteca”; “librería” means a bookshop.] | (none) | `Saqué un libro de la biblioteca pública.` | Pass (correct_fix) |
| false-friend-libreria | 2 | `Saqué un libro de la librería pública.` | librería -> biblioteca [Word Choice / False friends: “Librería” means “bookshop”; “biblioteca” is the word for a place where you borrow books.] | (none) | `Saqué un libro de la biblioteca pública.` | Pass (correct_fix) |
| false-friend-libreria | 3 | `Saqué un libro de la librería pública.` | la librería pública -> la biblioteca pública [Word Choice / False friends: “Librería” means a bookstore; “biblioteca” is the word for a library.] | (none) | `Saqué un libro de la biblioteca pública.` | Pass (correct_fix) |
| false-friend-libreria | 4 | `Saqué un libro de la librería pública.` | librería -> biblioteca [Word Choice / False friends: “Librería” means a bookshop; “biblioteca” is the word for a library.] | (none) | `Saqué un libro de la biblioteca pública.` | Pass (correct_fix) |
| false-friend-libreria | 5 | `Saqué un libro de la librería pública.` | librería pública -> biblioteca pública [Word Choice / False friends: “Librería” means a bookshop; “biblioteca” is the word for a library.] | (none) | `Saqué un libro de la biblioteca pública.` | Pass (correct_fix) |
| false-friend-realice | 1 | `Realicé que estaba equivocado.` | Realicé que -> Me di cuenta de que [Word Choice / False friends: Realizar means “to carry out” in Spanish; darse cuenta de means “to realize.”] | (none) | `Me di cuenta de que estaba equivocado.` | Pass (correct_fix) |
| false-friend-realice | 2 | `Realicé que estaba equivocado.` | Realicé -> Me di cuenta [Word Choice / False friends: “Realizar” means to carry out or accomplish, while “darse cuenta” means to realize.] | (none) | `Me di cuenta que estaba equivocado.` | Fail (partial_fix) |
| false-friend-realice | 3 | `Realicé que estaba equivocado.` | Realicé que -> Me di cuenta de que [Word Choice / False friends: “Realizar” means to carry out or accomplish, not to become aware of something.] | (none) | `Me di cuenta de que estaba equivocado.` | Pass (correct_fix) |
| false-friend-realice | 4 | `Realicé que estaba equivocado.` | Realicé -> Me di cuenta [Word Choice / False friends: Here, “realizar” means to carry out, not to become aware of something.] | (none) | `Me di cuenta que estaba equivocado.` | Fail (partial_fix) |
| false-friend-realice | 5 | `Realicé que estaba equivocado.` | Realicé que -> Me di cuenta de que [Word Choice / False friends: Realizar means “to carry out”; darse cuenta expresses realizing something.] | (none) | `Me di cuenta de que estaba equivocado.` | Pass (correct_fix) |
| false-friend-embarazado | 1 | `Estoy embarazado por llegar tarde.` | embarazado -> avergonzado [Word Choice / False friends: “Embarazado” means “pregnant”; “avergonzado” expresses feeling embarrassed.] | (none) | `Estoy avergonzado por llegar tarde.` | Pass (correct_fix) |
| false-friend-embarazado | 2 | `Estoy embarazado por llegar tarde.` | embarazado -> avergonzado [Word Choice / False friends: “Embarazado” means “pregnant”; “avergonzado” expresses feeling embarrassed.] | (none) | `Estoy avergonzado por llegar tarde.` | Pass (correct_fix) |
| false-friend-embarazado | 3 | `Estoy embarazado por llegar tarde.` | embarazado -> avergonzado [Word Choice / False friends: “Embarazado” means pregnant; “avergonzado” expresses feeling embarrassed.] | (none) | `Estoy avergonzado por llegar tarde.` | Pass (correct_fix) |
| false-friend-embarazado | 4 | `Estoy embarazado por llegar tarde.` | embarazado -> avergonzado [Word Choice / False friends: “Embarazado” means “pregnant”; “avergonzado” expresses being embarrassed.] | (none) | `Estoy avergonzado por llegar tarde.` | Pass (correct_fix) |
| false-friend-embarazado | 5 | `Estoy embarazado por llegar tarde.` | embarazado -> avergonzado [Word Choice / False friends: “Embarazado” means “pregnant”; “avergonzado” expresses embarrassment.] | (none) | `Estoy avergonzado por llegar tarde.` | Pass (correct_fix) |
| false-friend-actualmente-control | 1 | `Actualmente vivo en Londres.` | (none) | (none) | `Actualmente vivo en Londres.` | Pass (acceptable_no_change) |
| false-friend-actualmente-control | 2 | `Actualmente vivo en Londres.` | (none) | (none) | `Actualmente vivo en Londres.` | Pass (acceptable_no_change) |
| false-friend-actualmente-control | 3 | `Actualmente vivo en Londres.` | (none) | (none) | `Actualmente vivo en Londres.` | Pass (acceptable_no_change) |
| false-friend-actualmente-control | 4 | `Actualmente vivo en Londres.` | (none) | (none) | `Actualmente vivo en Londres.` | Pass (acceptable_no_change) |
| false-friend-actualmente-control | 5 | `Actualmente vivo en Londres.` | (none) | (none) | `Actualmente vivo en Londres.` | Pass (acceptable_no_change) |
| naturalness-buen-tiempo | 1 | `Tuvimos un buen tiempo.` | (none) | Tuvimos un buen tiempo -> Pasamos un buen rato [Natural phrasing: For an enjoyable experience, Spanish naturally says «pasamos un buen rato».] | `Pasamos un buen rato.` | Pass (correct_fix) |
| naturalness-buen-tiempo | 2 | `Tuvimos un buen tiempo.` | (none) | Tuvimos un buen tiempo. -> Pasamos un buen rato. [Natural phrasing: Spanish usually expresses having a good time with «pasar un buen rato».] | `Pasamos un buen rato.` | Pass (correct_fix) |
| naturalness-buen-tiempo | 3 | `Tuvimos un buen tiempo.` | (none) | Tuvimos un buen tiempo -> Lo pasamos bien [Natural phrasing: Spanish usually expresses enjoying an experience with «pasarlo bien».] | `Lo pasamos bien.` | Pass (correct_fix) |
| naturalness-buen-tiempo | 4 | `Tuvimos un buen tiempo.` | (none) | Tuvimos un buen tiempo -> Lo pasamos bien [Natural phrasing: Spanish commonly uses «pasarlo bien» to say that you enjoyed yourself.] | `Lo pasamos bien.` | Pass (correct_fix) |
| naturalness-buen-tiempo | 5 | `Tuvimos un buen tiempo.` | (none) | Tuvimos un buen tiempo -> Pasamos un buen rato [Natural phrasing: Spanish speakers usually say «pasamos un buen rato» to express that they enjoyed themselves.] | `Pasamos un buen rato.` | Pass (correct_fix) |
| naturalness-corriendo-tarde | 1 | `Estoy corriendo tarde para la reunión.` | (none) | Estoy corriendo tarde para -> Voy tarde a [Natural phrasing: Spanish speakers usually say «voy tarde» rather than literally translating «running late».] | `Voy tarde a la reunión.` | Pass (correct_fix) |
| naturalness-corriendo-tarde | 2 | `Estoy corriendo tarde para la reunión.` | (none) | Estoy corriendo tarde -> Voy tarde [Natural phrasing: Spanish uses «voy tarde» to say you are running late.] | `Voy tarde para la reunión.` | Pass (correct_fix) |
| naturalness-corriendo-tarde | 3 | `Estoy corriendo tarde para la reunión.` | (none) | Estoy corriendo tarde -> Voy tarde [Natural phrasing: Spanish speakers usually say «voy tarde» rather than translate «running late» literally.] | `Voy tarde para la reunión.` | Pass (correct_fix) |
| naturalness-corriendo-tarde | 4 | `Estoy corriendo tarde para la reunión.` | (none) | Estoy corriendo tarde para -> Voy tarde a [Natural phrasing: Spanish speakers usually say «voy tarde» to express that they are running late.] | `Voy tarde a la reunión.` | Pass (correct_fix) |
| naturalness-corriendo-tarde | 5 | `Estoy corriendo tarde para la reunión.` | (none) | Estoy corriendo tarde para la reunión -> Llego tarde a la reunión [Natural phrasing: Spanish usually expresses this idea with «llego tarde», rather than a literal translation of “running late”.] | `Llego tarde a la reunión.` | Pass (correct_fix) |
| naturalness-pasar-buen-tiempo | 1 | `Quiero pasar un buen tiempo.` | (none) | un buen tiempo -> un buen rato [Natural phrasing: For enjoying yourself, Spanish more naturally says «pasar un buen rato».] | `Quiero pasar un buen rato.` | Pass (correct_fix) |
| naturalness-pasar-buen-tiempo | 2 | `Quiero pasar un buen tiempo.` | (none) | pasar un buen tiempo -> pasarlo bien [Natural phrasing: Spanish naturally uses «pasarlo bien» to express having a good time.] | `Quiero pasarlo bien.` | Pass (correct_fix) |
| naturalness-pasar-buen-tiempo | 3 | `Quiero pasar un buen tiempo.` | (none) | un buen tiempo -> un buen rato [Natural phrasing: Spanish more naturally uses «pasar un buen rato» to mean enjoying yourself.] | `Quiero pasar un buen rato.` | Pass (correct_fix) |
| naturalness-pasar-buen-tiempo | 4 | `Quiero pasar un buen tiempo.` | (none) | pasar un buen tiempo -> pasar un buen rato [Natural phrasing: To express enjoying yourself, Spanish more naturally says «pasar un buen rato».] | `Quiero pasar un buen rato.` | Pass (correct_fix) |
| naturalness-pasar-buen-tiempo | 5 | `Quiero pasar un buen tiempo.` | (none) | pasar un buen tiempo -> pasar un buen rato [Natural phrasing: «Pasar un buen rato» is a more natural way to say you want to enjoy yourself.] | `Quiero pasar un buen rato.` | Pass (correct_fix) |
| naturalness-puedo-tener-cerveza | 1 | `¿Puedo tener una cerveza?` | (none) | ¿Puedo tener una cerveza? -> ¿Me puede dar una cerveza? [Natural phrasing: When ordering a drink, Spanish more naturally asks the person serving you to give it to you.] | `¿Me puede dar una cerveza?` | Pass (correct_fix) |
| naturalness-puedo-tener-cerveza | 2 | `¿Puedo tener una cerveza?` | (none) | ¿Puedo tener una cerveza? -> ¿Me puede dar una cerveza? [Natural phrasing: When ordering, Spanish speakers usually ask the server to give them a beer rather than ask if they can have one.] | `¿Me puede dar una cerveza?` | Pass (correct_fix) |
| naturalness-puedo-tener-cerveza | 3 | `¿Puedo tener una cerveza?` | (none) | Puedo tener -> Me puede dar [Natural phrasing: When ordering, Spanish more naturally asks the other person to give you the drink.] | `¿Me puede dar una cerveza?` | Pass (correct_fix) |
| naturalness-puedo-tener-cerveza | 4 | `¿Puedo tener una cerveza?` | (none) | ¿Puedo tener una cerveza? -> ¿Me puede dar una cerveza? [Natural phrasing: When ordering a drink, Spanish more naturally asks the server to give it to you.] | `¿Me puede dar una cerveza?` | Pass (correct_fix) |
| naturalness-puedo-tener-cerveza | 5 | `¿Puedo tener una cerveza?` | (none) | ¿Puedo tener una cerveza? -> ¿Me puede dar una cerveza? [Natural phrasing: When ordering, Spanish speakers usually ask the server to give them a beer rather than ask if they can have one.] | `¿Me puede dar una cerveza?` | Pass (correct_fix) |
| naturalness-tomo-lugar | 1 | `La reunión tomó lugar ayer.` | (none) | tomó lugar -> tuvo lugar [Natural phrasing: «Tuvo lugar» is a more natural way to say that an event happened.] | `La reunión tuvo lugar ayer.` | Pass (correct_fix) |
| naturalness-tomo-lugar | 2 | `La reunión tomó lugar ayer.` | (none) | tomó lugar -> tuvo lugar [Natural phrasing: Spanish uses «tener lugar» to say that an event took place.] | `La reunión tuvo lugar ayer.` | Pass (correct_fix) |
| naturalness-tomo-lugar | 3 | `La reunión tomó lugar ayer.` | (none) | tomó lugar -> tuvo lugar [Natural phrasing: Spanish more naturally says «tuvo lugar» for an event that happened.] | `La reunión tuvo lugar ayer.` | Pass (correct_fix) |
| naturalness-tomo-lugar | 4 | `La reunión tomó lugar ayer.` | (none) | tomó lugar -> tuvo lugar [Natural phrasing: Spanish normally uses «tuvo lugar» to say that an event happened.] | `La reunión tuvo lugar ayer.` | Pass (correct_fix) |
| naturalness-tomo-lugar | 5 | `La reunión tomó lugar ayer.` | (none) | tomó lugar -> tuvo lugar [Natural phrasing: Spanish normally uses «tuvo lugar» to say that an event happened.] | `La reunión tuvo lugar ayer.` | Pass (correct_fix) |
| regional-voy-para-casa | 1 | `Voy para casa ahora mismo.` | (none) | (none) | `Voy para casa ahora mismo.` | Pass (acceptable_no_change) |
| regional-voy-para-casa | 2 | `Voy para casa ahora mismo.` | (none) | (none) | `Voy para casa ahora mismo.` | Pass (acceptable_no_change) |
| regional-voy-para-casa | 3 | `Voy para casa ahora mismo.` | (none) | (none) | `Voy para casa ahora mismo.` | Pass (acceptable_no_change) |
| regional-voy-para-casa | 4 | `Voy para casa ahora mismo.` | (none) | (none) | `Voy para casa ahora mismo.` | Pass (acceptable_no_change) |
| regional-voy-para-casa | 5 | `Voy para casa ahora mismo.` | (none) | (none) | `Voy para casa ahora mismo.` | Pass (acceptable_no_change) |
| regional-vos-tenes | 1 | `Vos tenés razón.` | (none) | (none) | `Vos tenés razón.` | Pass (acceptable_no_change) |
| regional-vos-tenes | 2 | `Vos tenés razón.` | (none) | (none) | `Vos tenés razón.` | Pass (acceptable_no_change) |
| regional-vos-tenes | 3 | `Vos tenés razón.` | (none) | (none) | `Vos tenés razón.` | Pass (acceptable_no_change) |
| regional-vos-tenes | 4 | `Vos tenés razón.` | (none) | (none) | `Vos tenés razón.` | Pass (acceptable_no_change) |
| regional-vos-tenes | 5 | `Vos tenés razón.` | (none) | (none) | `Vos tenés razón.` | Pass (acceptable_no_change) |
| regional-cojo-autobus | 1 | `Cojo el autobús cada mañana.` | (none) | (none) | `Cojo el autobús cada mañana.` | Pass (acceptable_no_change) |
| regional-cojo-autobus | 2 | `Cojo el autobús cada mañana.` | (none) | (none) | `Cojo el autobús cada mañana.` | Pass (acceptable_no_change) |
| regional-cojo-autobus | 3 | `Cojo el autobús cada mañana.` | (none) | (none) | `Cojo el autobús cada mañana.` | Pass (acceptable_no_change) |
| regional-cojo-autobus | 4 | `Cojo el autobús cada mañana.` | (none) | (none) | `Cojo el autobús cada mañana.` | Pass (acceptable_no_change) |
| regional-cojo-autobus | 5 | `Cojo el autobús cada mañana.` | (none) | (none) | `Cojo el autobús cada mañana.` | Pass (acceptable_no_change) |
| regional-preterite-esta-manana | 1 | `Esta mañana hablé con mi jefe.` | (none) | (none) | `Esta mañana hablé con mi jefe.` | Pass (acceptable_no_change) |
| regional-preterite-esta-manana | 2 | `Esta mañana hablé con mi jefe.` | (none) | (none) | `Esta mañana hablé con mi jefe.` | Pass (acceptable_no_change) |
| regional-preterite-esta-manana | 3 | `Esta mañana hablé con mi jefe.` | (none) | (none) | `Esta mañana hablé con mi jefe.` | Pass (acceptable_no_change) |
| regional-preterite-esta-manana | 4 | `Esta mañana hablé con mi jefe.` | (none) | (none) | `Esta mañana hablé con mi jefe.` | Pass (acceptable_no_change) |
| regional-preterite-esta-manana | 5 | `Esta mañana hablé con mi jefe.` | (none) | (none) | `Esta mañana hablé con mi jefe.` | Pass (acceptable_no_change) |
| regional-dale | 1 | `Dale, nos vemos más tarde.` | (none) | (none) | `Dale, nos vemos más tarde.` | Pass (acceptable_no_change) |
| regional-dale | 2 | `Dale, nos vemos más tarde.` | (none) | (none) | `Dale, nos vemos más tarde.` | Pass (acceptable_no_change) |
| regional-dale | 3 | `Dale, nos vemos más tarde.` | (none) | (none) | `Dale, nos vemos más tarde.` | Pass (acceptable_no_change) |
| regional-dale | 4 | `Dale, nos vemos más tarde.` | (none) | (none) | `Dale, nos vemos más tarde.` | Pass (acceptable_no_change) |
| regional-dale | 5 | `Dale, nos vemos más tarde.` | (none) | (none) | `Dale, nos vemos más tarde.` | Pass (acceptable_no_change) |
| correct-buenos-dias | 1 | `Buenos días, ¿cómo estás?` | (none) | (none) | `Buenos días, ¿cómo estás?` | Pass (acceptable_no_change) |
| correct-buenos-dias | 2 | `Buenos días, ¿cómo estás?` | (none) | (none) | `Buenos días, ¿cómo estás?` | Pass (acceptable_no_change) |
| correct-buenos-dias | 3 | `Buenos días, ¿cómo estás?` | (none) | (none) | `Buenos días, ¿cómo estás?` | Pass (acceptable_no_change) |
| correct-buenos-dias | 4 | `Buenos días, ¿cómo estás?` | (none) | (none) | `Buenos días, ¿cómo estás?` | Pass (acceptable_no_change) |
| correct-buenos-dias | 5 | `Buenos días, ¿cómo estás?` | (none) | (none) | `Buenos días, ¿cómo estás?` | Pass (acceptable_no_change) |
| correct-hacer-pregunta | 1 | `Voy a hacer una pregunta al profesor.` | (none) | (none) | `Voy a hacer una pregunta al profesor.` | Pass (acceptable_no_change) |
| correct-hacer-pregunta | 2 | `Voy a hacer una pregunta al profesor.` | (none) | (none) | `Voy a hacer una pregunta al profesor.` | Pass (acceptable_no_change) |
| correct-hacer-pregunta | 3 | `Voy a hacer una pregunta al profesor.` | (none) | (none) | `Voy a hacer una pregunta al profesor.` | Pass (acceptable_no_change) |
| correct-hacer-pregunta | 4 | `Voy a hacer una pregunta al profesor.` | (none) | (none) | `Voy a hacer una pregunta al profesor.` | Pass (acceptable_no_change) |
| correct-hacer-pregunta | 5 | `Voy a hacer una pregunta al profesor.` | (none) | (none) | `Voy a hacer una pregunta al profesor.` | Pass (acceptable_no_change) |
| correct-tomar-foto | 1 | `Necesito tomar una foto del documento.` | (none) | (none) | `Necesito tomar una foto del documento.` | Pass (acceptable_no_change) |
| correct-tomar-foto | 2 | `Necesito tomar una foto del documento.` | (none) | (none) | `Necesito tomar una foto del documento.` | Pass (acceptable_no_change) |
| correct-tomar-foto | 3 | `Necesito tomar una foto del documento.` | (none) | (none) | `Necesito tomar una foto del documento.` | Pass (acceptable_no_change) |
| correct-tomar-foto | 4 | `Necesito tomar una foto del documento.` | (none) | (none) | `Necesito tomar una foto del documento.` | Pass (acceptable_no_change) |
| correct-tomar-foto | 5 | `Necesito tomar una foto del documento.` | (none) | (none) | `Necesito tomar una foto del documento.` | Pass (acceptable_no_change) |
| correct-visitar-abuela | 1 | `Mañana visitaré a mi abuela.` | (none) | (none) | `Mañana visitaré a mi abuela.` | Pass (acceptable_no_change) |
| correct-visitar-abuela | 2 | `Mañana visitaré a mi abuela.` | (none) | (none) | `Mañana visitaré a mi abuela.` | Pass (acceptable_no_change) |
| correct-visitar-abuela | 3 | `Mañana visitaré a mi abuela.` | (none) | (none) | `Mañana visitaré a mi abuela.` | Pass (acceptable_no_change) |
| correct-visitar-abuela | 4 | `Mañana visitaré a mi abuela.` | (none) | (none) | `Mañana visitaré a mi abuela.` | Pass (acceptable_no_change) |
| correct-visitar-abuela | 5 | `Mañana visitaré a mi abuela.` | (none) | (none) | `Mañana visitaré a mi abuela.` | Pass (acceptable_no_change) |
| correct-me-quedo-en-casa | 1 | `Está lloviendo, así que me quedo en casa.` | (none) | (none) | `Está lloviendo, así que me quedo en casa.` | Pass (acceptable_no_change) |
| correct-me-quedo-en-casa | 2 | `Está lloviendo, así que me quedo en casa.` | (none) | (none) | `Está lloviendo, así que me quedo en casa.` | Pass (acceptable_no_change) |
| correct-me-quedo-en-casa | 3 | `Está lloviendo, así que me quedo en casa.` | (none) | (none) | `Está lloviendo, así que me quedo en casa.` | Pass (acceptable_no_change) |
| correct-me-quedo-en-casa | 4 | `Está lloviendo, así que me quedo en casa.` | (none) | (none) | `Está lloviendo, así que me quedo en casa.` | Pass (acceptable_no_change) |
| correct-me-quedo-en-casa | 5 | `Está lloviendo, así que me quedo en casa.` | (none) | (none) | `Está lloviendo, así que me quedo en casa.` | Pass (acceptable_no_change) |
| mixed-preposition-and-redundant-pronoun | 1 | `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Insisto que -> Insisto en que [Grammar / Prepositions: In Spanish, insistir takes the preposition en before que.] | yo trabajo mucho y yo estudio -> yo trabajo mucho y estudio [Natural phrasing: The second «yo» is unnecessary because the subject is already clear.] | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| mixed-preposition-and-redundant-pronoun | 2 | `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Insisto que -> Insisto en que [Grammar / Prepositions: The verb «insistir» takes the preposition «en» before «que».] | y yo estudio por las noches -> y estudio por las noches [Natural phrasing: The second «yo» repeats the same subject, so it can be left out.] | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| mixed-preposition-and-redundant-pronoun | 3 | `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Insisto que -> Insisto en que [Grammar / Prepositions: The verb «insistir» takes the preposition «en» before «que».] | y yo estudio -> y estudio [Natural phrasing: When the subject stays the same, Spanish usually omits the repeated pronoun.] | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| mixed-preposition-and-redundant-pronoun | 4 | `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Insisto que -> Insisto en que [Grammar / Prepositions: In Spanish, insistir takes the preposition en before que.] | yo trabajo mucho y yo estudio -> yo trabajo mucho y estudio [Natural phrasing: The second «yo» adds no emphasis, so Spanish usually leaves it out.] | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| mixed-preposition-and-redundant-pronoun | 5 | `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | Insisto que -> Insisto en que [Grammar / Prepositions: In Spanish, insistir requires the preposition en before que.] | y yo estudio por las noches -> y estudio por las noches [Natural phrasing: The second «yo» repeats the same subject without adding emphasis, so it sounds more natural to omit it.] | `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.` | Pass (correct_fix) |
| mixed-article-and-accent | 1 | `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish uses an article before this singular count noun.]<br>compre -> compré [Spelling / Written accents: The accent mark distinguishes the first-person past form “compré” from “compre.”]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent mark on “café.”]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish writes an accent mark on “cafetería.”]<br>pequena -> pequeña [Spelling / Letters: Spanish uses ñ in “pequeña.”] | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Pass (correct_fix) |
| mixed-article-and-accent | 2 | `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish needs an article before this singular count noun.]<br>compre -> compré [Spelling / Written accents: The accent mark distinguishes the past-tense form from the subjunctive.]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent mark on this word.]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish writes an accent mark on the í in this word.]<br>pequena -> pequeña [Spelling / Letters: This word is spelled with ñ.] | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Pass (correct_fix) |
| mixed-article-and-accent | 3 | `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish generally needs an article before this singular count noun.]<br>compre -> compré [Spelling / Written accents: The accent mark shows the first-person preterite form.]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent mark on the final syllable of this word.]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish writes an accent mark on the í in this word.]<br>pequena -> pequeña [Spelling / Letters: Spanish uses ñ in this word.] | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Pass (correct_fix) |
| mixed-article-and-accent | 4 | `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish needs an article before this singular count noun.]<br>compre -> compré [Spelling / Written accents: The accent marks the first-person past-tense form here.]<br>cafe -> café [Spelling / Written accents: Spanish writes an accent on the final syllable of this word.]<br>cafeteria -> cafetería [Spelling / Written accents: Spanish needs an accent on the í in this word.]<br>pequena -> pequeña [Spelling / Letters: This word needs ñ, which is a different letter from n.] | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Pass (correct_fix) |
| mixed-article-and-accent | 5 | `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | comprar libro -> comprar un libro [Grammar / Articles: Spanish needs an article before this singular count noun.]<br>compre -> compré [Spelling / Written accents: The past-tense form needs an accent mark on the final syllable.]<br>cafe -> café [Spelling / Written accents: Spanish needs an accent mark on the final syllable of this word.]<br>cafeteria -> cafetería [Spelling / Written accents: The accent mark shows that the í is stressed.]<br>pequena -> pequeña [Spelling / Letters: This word is spelled with ñ.] | (none) | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | Pass (correct_fix) |
| mixed-personal-a-and-subjunctive | 1 | `Vi mi profesor en la estación, y recordé que es importante que estudio.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal “a” before a specific person who is a direct object.]<br>que estudio -> que estudie [Grammar / Subjunctive: After “es importante que,” Spanish uses the subjunctive.] | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | Pass (correct_fix) |
| mixed-personal-a-and-subjunctive | 2 | `Vi mi profesor en la estación, y recordé que es importante que estudio.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal “a” before a specific person who is the direct object.]<br>que estudio -> que estudie [Grammar / Subjunctive: After “es importante que,” Spanish uses the subjunctive for the action considered important.] | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | Pass (correct_fix) |
| mixed-personal-a-and-subjunctive | 3 | `Vi mi profesor en la estación, y recordé que es importante que estudio.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal a before a specific person who is the direct object.]<br>que estudio -> que estudie [Grammar / Subjunctive: After “es importante que,” Spanish uses the subjunctive for an action considered important.] | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | Pass (correct_fix) |
| mixed-personal-a-and-subjunctive | 4 | `Vi mi profesor en la estación, y recordé que es importante que estudio.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal “a” before a specific person who is the direct object.]<br>que estudio -> que estudie [Grammar / Subjunctive: After “es importante que,” Spanish uses the subjunctive.] | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | Pass (correct_fix) |
| mixed-personal-a-and-subjunctive | 5 | `Vi mi profesor en la estación, y recordé que es importante que estudio.` | Vi mi profesor -> Vi a mi profesor [Grammar / Prepositions: Spanish uses the personal a before a specific person who is the direct object.]<br>que estudio -> que estudie [Grammar / Subjunctive: After es importante que, Spanish uses the subjunctive.] | (none) | `Vi a mi profesor en la estación, y recordé que es importante que estudie.` | Pass (correct_fix) |
| mixed-gender-agreement-and-redundant-pronoun | 1 | `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | abierto -> abiertas [Grammar / Agreement: The adjective agrees in feminine plural with “las ventanas.”] | el café a mí -> el café [Natural phrasing: The final «a mí» repeats the emphasis already expressed before «me gusta».] | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Pass (correct_fix) |
| mixed-gender-agreement-and-redundant-pronoun | 2 | `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | estaban abierto -> estaban abiertas [Grammar / Agreement: The adjective agrees with “ventanas,” which is feminine plural.] | el café a mí -> el café [Natural phrasing: The second «a mí» is unnecessary because it already appears before the verb.] | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Pass (correct_fix) |
| mixed-gender-agreement-and-redundant-pronoun | 3 | `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | abierto -> abiertas [Grammar / Agreement: The adjective needs to agree with “ventanas” in feminine plural.] | el café a mí -> el café [Natural phrasing: The first «a mí» already provides the emphasis, so it need not be repeated.] | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Pass (correct_fix) |
| mixed-gender-agreement-and-redundant-pronoun | 4 | `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | estaban abierto -> estaban abiertas [Grammar / Agreement: The adjective needs to agree in feminine plural with “las ventanas”.] | el café a mí -> el café [Natural phrasing: Keeping «a mí» once avoids unnecessary repetition.] | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Pass (correct_fix) |
| mixed-gender-agreement-and-redundant-pronoun | 5 | `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | estaban abierto -> estaban abiertas [Grammar / Agreement: The adjective needs to agree with the feminine plural noun “ventanas.”] | café a mí -> café [Natural phrasing: The final «a mí» repeats the emphasis already given at the start of the clause.] | `Las ventanas estaban abiertas, y a mí me gusta el café.` | Pass (correct_fix) |
| mixed-verb-agreement-and-missing-que | 1 | `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject «ellos».]<br>creo está bien -> creo que está bien [Grammar / Sentence structure: Spanish uses «que» here to introduce the clause after «creo».] | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | Pass (correct_fix) |
| mixed-verb-agreement-and-missing-que | 2 | `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject “ellos.”]<br>creo está bien -> creo que está bien [Grammar / Sentence structure: Spanish uses “que” to introduce the clause after “creo.”] | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | Pass (correct_fix) |
| mixed-verb-agreement-and-missing-que | 3 | `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb agrees with the plural subject “ellos.”]<br>creo está bien -> creo que está bien [Grammar / Sentence structure: Spanish uses “que” to introduce this clause after “creo.”] | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | Pass (correct_fix) |
| mixed-verb-agreement-and-missing-que | 4 | `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject «ellos».]<br>creo está -> creo que está [Grammar / Sentence structure: Spanish needs «que» to connect «creo» with the following clause.] | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | Pass (correct_fix) |
| mixed-verb-agreement-and-missing-que | 5 | `Ellos estudia todas las noches, y creo está bien terminar de estudiar hoy.` | Ellos estudia -> Ellos estudian [Grammar / Agreement: The verb needs to agree with the plural subject “ellos.”]<br>creo está -> creo que está [Grammar / Sentence structure: Spanish uses “que” to connect “creo” with the following clause.] | (none) | `Ellos estudian todas las noches, y creo que está bien terminar de estudiar hoy.` | Pass (correct_fix) |
