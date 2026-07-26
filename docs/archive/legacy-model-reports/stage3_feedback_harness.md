# Stage 3 Feedback Harness

Model: `gpt-5.5`  
Commit: `e370e9fa8f22c96f32927b55cd22eb1987416c32`  
Generated: 2026-07-18T19:43:50.403756  
Runs per case: 10

## Error-verdict cases (explanation must read as a correction)

### ES-3-calque

- Corrections: [{"start_index":30,"original_phrase":"llamaron para atrás","corrected_phrase":"volvieron a llamar","category":"Natural Language","verdict":"error"}]
- Note: One sentence, must name the calque/literal-translation nature (not just restate the fix), and must not hedge.

#### Summary (10 runs, 0 error(s))

- Target 1 (start_index=30):
  - Missing (no matching result): 0.0% (0/10)
  - Exactly one sentence: 100.0% (10/10)
  - Mentions [calque, literal]: 70.0% (7/10)
  - No hedging: 100.0% (10/10)
- Fully caught (every scored check in one run): 70.0% (7/10)

#### Run detail

- Run 1: start_index=30 -> "“Llamaron para atrás” is an English calque of “called back”; in Spanish the idiom is “volvieron a llamar” for calling again or “devolvieron la llamada” for returning a call."
- Run 2: start_index=30 -> "“Llamaron para atrás” calca el inglés “call back”, pero en español ese modismo no funciona y se dice “volvieron a llamar” o “devolvieron la llamada”."
- Run 3: start_index=30 -> "“Llamar para atrás” es un calco del inglés “call back”; en español lo idiomático es “volver a llamar” para decir que alguien llamó otra vez."
- Run 4: start_index=30 -> "“Llamaron para atrás” is an English calque of “called back,” while Spanish uses the periphrasis “volver a + infinitivo” for doing the action again: “volvieron a llamar.”"
- Run 5: start_index=30 -> "“Llamaron para atrás” is an English calque of “called back”; in Spanish the idiom is “volver a llamar” when they called again."
- Run 6: start_index=30 -> "“Llamaron para atrás” is an English calque of “called back”; in Spanish the idiomatic periphrasis for doing it again is “volver a + infinitivo,” so “volvieron a llamar” sounds natural."
- Run 7: start_index=30 -> "“Llamaron para atrás” is a literal calque of English “called back”; in Spanish the idiomatic way to say they called again is “volvieron a llamar”."
- Run 8: start_index=30 -> "“Llamar para atrás” is a literal calque of English “call back”; in Spanish the idiomatic verb phrase is “volver a llamar” or “devolver la llamada.”"
- Run 9: start_index=30 -> "“Llamar para atrás” is an English calque of “call back”; in Spanish you’d use the idiom “volver a llamar” for calling again."
- Run 10: start_index=30 -> "“Llamar para atrás” es un calco del inglés “call back”; en español se usa la perífrasis “volver a + infinitivo” para expresar que llamaron de nuevo."

### ES-5-accent

- Corrections: [{"start_index":8,"original_phrase":"Espana","corrected_phrase":"España","category":"Spelling","verdict":"error"}]
- Note: One sentence, must name the missing tilde/ñ.

#### Summary (10 runs, 0 error(s))

- Target 1 (start_index=8):
  - Missing (no matching result): 0.0% (0/10)
  - Exactly one sentence: 100.0% (10/10)
  - Mentions [tilde, ñ]: 100.0% (10/10)
- Fully caught (every scored check in one run): 100.0% (10/10)

#### Run detail

- Run 1: start_index=8 -> "En español, la letra ñ es distinta de n, así que el nombre del país se escribe España, no Espana."
- Run 2: start_index=8 -> "Spanish treats ñ as a separate letter, so the country name is spelled España, not Espana."
- Run 3: start_index=8 -> "Acuérdate de la ñ: en español es una letra distinta de n, así que el país se escribe España."
- Run 4: start_index=8 -> "Falta la tilde en la ñ: el nombre del país se escribe “España”, porque “n” y “ñ” son letras distintas en español."
- Run 5: start_index=8 -> "Aquí falta la ñ: en español, España se escribe con esa letra, no con n simple."
- Run 6: start_index=8 -> "En español la ñ es una letra distinta de n, así que el nombre del país se escribe España."
- Run 7: start_index=8 -> "Falta la ñ: en español es una letra distinta de n, así que el país se escribe España, no Espana."
- Run 8: start_index=8 -> "En español, la ñ es una letra distinta de la n, así que España necesita la tilde para respetar la ortografía y la pronunciación."
- Run 9: start_index=8 -> "“España” needs the letter ñ; “Espana” is a spelling error because n and ñ are different letters in Spanish."
- Run 10: start_index=8 -> "“España” needs the ñ because it’s a distinct Spanish letter, not just an accented n, and “Espana” changes the spelling of the country’s name."

### ST-O2

- Corrections: [{"start_index":0,"original_phrase":"Creo está bien","corrected_phrase":"Creo que está bien","category":"Grammar","verdict":"error"}]
- Note: One sentence, must explain the missing "que".

#### Summary (10 runs, 0 error(s))

- Target 1 (start_index=0):
  - Missing (no matching result): 0.0% (0/10)
  - Exactly one sentence: 100.0% (10/10)
  - Mentions [que]: 100.0% (10/10)
- Fully caught (every scored check in one run): 100.0% (10/10)

#### Run detail

- Run 1: start_index=0 -> "After creo, a finite clause needs the conjunction que, so creo está bien breaks the required creo que + indicativo structure."
- Run 2: start_index=0 -> "Con creer + oración subordinada necesitas la conjunción que: «Creo que está bien»; sin ese que, la frase queda cortada."
- Run 3: start_index=0 -> "Después de verbos de opinión como “creer”, necesitas la conjunción “que” para introducir la subordinada: “Creo que está bien”."
- Run 4: start_index=0 -> "Después de “creo” necesitas el nexo “que” para introducir la subordinada completiva: “creo que está bien”."
- Run 5: start_index=0 -> "After verbs of opinion like “creer,” Spanish needs the conjunction “que” to introduce a full subordinate clause, so “Creo que está bien” is the natural structure."
- Run 6: start_index=0 -> "Con verbos de opinión como “creer”, necesitas la conjunción “que” para introducir la subordinada: “Creo que está bien”."
- Run 7: start_index=0 -> "After creer used to introduce a full clause, Spanish needs the conjunction que, so Creo está bien breaks the complementation pattern and Creo que está bien sounds natural."
- Run 8: start_index=0 -> "After verbs of opinion like “creer,” Spanish normally needs the conjunction “que” before a finite clause, so “Creo que está bien” is the natural structure."
- Run 9: start_index=0 -> "Después de “creo” necesitas “que” para introducir la subordinada completiva; sin ese nexo, la frase queda cortada en español estándar."
- Run 10: start_index=0 -> "Después de “creo” necesitas “que” para introducir una oración subordinada con verbo conjugado, así que “Creo que está bien” suena completo y natural."

## Dialectal-verdict cases (must not call it wrong)

### coger

- Corrections: [{"start_index":6,"original_phrase":"coger el autobús","corrected_phrase":"tomar el autobús","category":"Other","verdict":"dialectal"}]
- Note: THE KEY CHECK: explanation must not contain "wrong"/"error"/"incorrect"/"mal"/"incorrecto" — it should explain the regional split instead. Full text always recorded for eyeballing.

#### Summary (10 runs, 1 error(s))

- Target 1 (start_index=6):
  - Missing (no matching result): 0.0% (0/9)
  - Exactly one sentence: 100.0% (9/9)
  - No error-language ("wrong"/"error"/"incorrect"/"mal"/"incorrecto"): 100.0% (9/9)
- Fully caught (every scored check in one run): 100.0% (9/9)

#### Run detail

- Run 1: start_index=6 -> "“Coger el autobús” suena totalmente normal en España, pero en buena parte de Latinoamérica “coger” puede tener una connotación sexual, así que “tomar el autobús” es más neutral allí."
- Run 2: start_index=6 -> "«Coger el autobús» es natural en España, pero en buena parte de Latinoamérica «coger» puede sonar vulgar o con doble sentido, así que «tomar el autobús» es la opción más neutral allí."
- Run 3: start_index=6 -> "En España “coger el autobús” suena totalmente normal, pero en buena parte de Latinoamérica “coger” puede tener una lectura sexual, así que “tomar el autobús” queda más neutral allí."
- Run 4: start_index=6 -> "En España “coger el autobús” suena totalmente normal, pero en buena parte de América “coger” puede tener una lectura sexual, así que “tomar el autobús” evita ese choque dialectal."
- Run 5: start_index=6 -> "“Coger el autobús” es totalmente normal en España, pero en buena parte de América puede sonar vulgar por el sentido sexual de “coger”, así que “tomar el autobús” es la opción más neutra allí."
- Run 6: start_index=6 -> "«Coger el autobús» es totalmente natural en España, mientras que en muchos países de Latinoamérica se prefiere «tomar el autobús» porque «coger» puede sonar vulgar o sexual."
- Run 7: start_index=6 -> "Coger el autobús is perfectly standard in Spain, while in much of Latin America coger has a sexual meaning, so tomar el autobús sounds more neutral there."
- Run 8: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 9: start_index=6 -> "“Coger el autobús” is standard in Spain, while “tomar el autobús” sounds more neutral across Latin America, where “coger” can have a sexual meaning in some countries."
- Run 10: start_index=6 -> "“Coger el autobús” es totalmente normal en España, pero en gran parte de Latinoamérica “coger” puede tener una connotación sexual, así que “tomar el autobús” suena más neutro y panhispánico."

### ES-2

- Corrections: [{"start_index":27,"original_phrase":"voy para casa","corrected_phrase":"voy para casa","category":"Other","verdict":"dialectal"}]
- Note: Same check as coger. corrected_phrase == original_phrase here — dialectal often has no substitution. Read the recorded text to confirm the explanation handles that gracefully rather than inventing a fix (not itself a scored dimension, no reliable way to check that programmatically).

#### Summary (10 runs, 0 error(s))

- Target 1 (start_index=27):
  - Missing (no matching result): 0.0% (0/10)
  - Exactly one sentence: 100.0% (10/10)
  - No error-language ("wrong"/"error"/"incorrect"/"mal"/"incorrecto"): 100.0% (10/10)
- Fully caught (every scored check in one run): 100.0% (10/10)

#### Run detail

- Run 1: start_index=27 -> "“Voy para casa” is natural in much of Latin America to mean “I’m heading home,” while in Spain “voy a casa” is usually the neutral everyday phrasing."
- Run 2: start_index=27 -> "«Voy para casa» suena natural en muchas zonas de América y también en usos coloquiales de España, mientras que «voy a casa» es la opción más neutra y extendida en registros estándar."
- Run 3: start_index=27 -> "“Voy para casa” is natural in many parts of Latin America, while in Spain “voy a casa” is the more neutral everyday choice and “para” can sound regional or a bit marked."
- Run 4: start_index=27 -> "“Voy para casa” es natural en muchas zonas, sobre todo con el matiz de ‘voy rumbo a casa’, mientras que en registros o regiones más neutras suele preferirse “voy a casa”."
- Run 5: start_index=27 -> "«Voy para casa» suena natural en muchas zonas de América y Canarias con el sentido de «me voy a casa», mientras que en buena parte de España peninsular se prefiere «voy a casa»."
- Run 6: start_index=27 -> "“Voy para casa” suena natural en buena parte de Latinoamérica y algunas zonas de España con el sentido de “me dirijo a casa”, mientras que en gran parte de España lo más neutro sería “voy a casa”."
- Run 7: start_index=27 -> "“Voy para casa” suena natural en muchas zonas de América para decir que vas rumbo a casa, mientras que en España suele preferirse “voy a casa” en ese contexto."
- Run 8: start_index=27 -> "«Voy para casa» suena natural en muchas zonas de América y España como ‘me dirijo a casa’, mientras que en otras variedades se prefiere «voy a casa» para ese mismo movimiento."
- Run 9: start_index=27 -> "«Voy para casa» es natural en buena parte de América y también suena coloquial en algunas zonas de España, mientras que en el español peninsular más neutro suele preferirse «voy a casa»."
- Run 10: start_index=27 -> "«Voy para casa» es natural en muchas zonas de América y con sentido de ‘me dirijo hacia casa’, mientras que en España suele preferirse «voy a casa» para un destino directo."

## Join-key integrity

### multi-correction-join-key

- Corrections: [{"start_index":0,"original_phrase":"trafico","corrected_phrase":"tráfico","category":"Spelling","verdict":"error"},{"start_index":20,"original_phrase":"llamaron para atrás","corrected_phrase":"volvieron a llamar","category":"Natural Language","verdict":"error"},{"start_index":50,"original_phrase":"voy para casa","corrected_phrase":"voy para casa","category":"Other","verdict":"dialectal"}]
- Note: Three corrections with distinct start_index values (0, 20, 50). Confirms every returned object's start_index matches an input start_index, one explanation per correction, none dropped or duplicated — content quality isn't re-scored here (already covered by the single-correction cases above).

#### Summary (10 runs, 0 error(s))

- Target 1 (start_index=0):
  - Missing (no matching result): 0.0% (0/10)
  - Exactly one sentence: 100.0% (10/10)
- Target 2 (start_index=20):
  - Missing (no matching result): 0.0% (0/10)
  - Exactly one sentence: 100.0% (10/10)
- Target 3 (start_index=50):
  - Missing (no matching result): 0.0% (0/10)
  - Exactly one sentence: 100.0% (10/10)
- Join-key integrity: 100.0% (10/10)
- Fully caught (every scored check in one run): 100.0% (10/10)

#### Run detail

- Run 1: start_index=0 -> "A «tráfico» le falta la tilde porque es una palabra esdrújula, y las esdrújulas siempre se acentúan." | start_index=20 -> "«Llamaron para atrás» calca el inglés «called back», mientras que en español idiomático se dice «volvieron a llamar» o «devolvieron la llamada»." | start_index=50 -> "«Voy para casa» suena natural en muchas zonas de América y también coloquialmente en España, aunque «voy a casa» puede sonar más neutro o estándar según la región." | join-key: intact
- Run 2: start_index=0 -> "“Tráfico” lleva tilde porque es una palabra esdrújula, y las esdrújulas siempre se acentúan." | start_index=20 -> "“Llamar para atrás” suena a calco del inglés “call back”; en español natural se usa “volver a llamar” para decir que alguien llama de nuevo." | start_index=50 -> "“Voy para casa” es normal en muchas zonas de América y también se entiende en España, aunque en registros más neutros o peninsulares suele sonar más natural “voy a casa”." | join-key: intact
- Run 3: start_index=0 -> "Falta la tilde en “tráfico” porque es una palabra esdrújula, y las esdrújulas siempre llevan acento gráfico." | start_index=20 -> "“Llamaron para atrás” suena a calco de “call back”; en español se usa el giro idiomático “volvieron a llamar” o “devolvieron la llamada”." | start_index=50 -> "“Voy para casa” es normal en muchas zonas, sobre todo en usos coloquiales de España y América, aunque en otros contextos “voy a casa” puede sonar más neutro." | join-key: intact
- Run 4: start_index=0 -> "Como sustantivo, «tráfico» es esdrújula y lleva tilde; sin ella, «trafico» se lee como forma verbal de «traficar»." | start_index=20 -> "«Llamar para atrás» es un calco de “call back”; en español idiomático se usa «volver a llamar» o «devolver la llamada»." | start_index=50 -> "«Voy para casa» suena natural en muchas zonas de América y en registros coloquiales, mientras que en gran parte de España lo más neutro sería «voy a casa»." | join-key: intact
- Run 5: start_index=0 -> "Tráfico lleva tilde porque es una palabra esdrújula, y en español todas las esdrújulas se acentúan." | start_index=20 -> "Llamaron para atrás es un calco de “call back”, pero en español el idiom natural es volvieron a llamar o devolvieron la llamada." | start_index=50 -> "Voy para casa es muy natural en buena parte de América Latina y suena a “rumbo a casa”, mientras que en España suele preferirse voy a casa para un tono más neutro." | join-key: intact
- Run 6: start_index=0 -> "Falta la tilde porque el sustantivo «tráfico» es esdrújulo, mientras que «trafico» se lee como forma verbal de «traficar»." | start_index=20 -> "«Llamar para atrás» rompe el giro idiomático del español estándar, porque «para atrás» indica dirección física y para repetir la llamada se dice «volvieron a llamar» o «devolvieron la llamada»." | start_index=50 -> "«Voy para casa» es normal en muchas zonas de América y registros coloquiales, mientras que en buena parte de España suele preferirse «voy a casa» como opción más neutra." | join-key: intact
- Run 7: start_index=0 -> "“Tráfico” lleva tilde porque es una palabra esdrújula; sin tilde, “trafico” se lee como la forma verbal de “traficar”." | start_index=20 -> "“Llamaron para atrás” rompe el idiom natural en español, porque para ‘call back’ se usa “volver a llamar” o “devolver la llamada”, no una traducción literal con “para atrás”." | start_index=50 -> "“Voy para casa” es normal en muchas zonas de América y suena más coloquial o direccional, mientras que en España suele preferirse “voy a casa” como opción más neutra." | join-key: intact
- Run 8: start_index=0 -> "“Tráfico” lleva tilde porque es esdrújula; sin tilde, “trafico” se lee como forma del verbo “traficar”." | start_index=20 -> "“Llamar para atrás” rompe el modismo natural en español, porque para “call back” se dice “volver a llamar” o “devolver la llamada”." | start_index=50 -> "“Voy para casa” suena normal en muchas zonas de América y como uso coloquial o regional en España, mientras que en un registro peninsular más neutro suele preferirse “voy a casa”." | join-key: intact
- Run 9: start_index=0 -> "“Tráfico” lleva tilde porque es una palabra esdrújula, y en español las esdrújulas siempre se acentúan." | start_index=20 -> "“Llamar para atrás” rompe el modismo español y suena a calco de “call back”; lo natural es “volver a llamar” para decir que alguien llama otra vez." | start_index=50 -> "“Voy para casa” es normal en muchas zonas de América Latina y en registros coloquiales, mientras que en España suele sonar más neutro “voy a casa”." | join-key: intact
- Run 10: start_index=0 -> "Como sustantivo, “tráfico” es esdrújula, y las esdrújulas siempre llevan tilde." | start_index=20 -> "“Llamar para atrás” calca el inglés “call back” y rompe el modismo español; para repetir la llamada se dice “volver a llamar”." | start_index=50 -> "“Voy para casa” es normal en muchas zonas de Latinoamérica, mientras que en España o en registros más neutros suele preferirse “voy a casa” para marcar destino." | join-key: intact

---

## Overall summary

| Case | Runs | Errors | Fully caught |
| --- | --- | --- | --- |
| ES-3-calque | 10 | 0 | 70.0% (7/10) |
| ES-5-accent | 10 | 0 | 100.0% (10/10) |
| ST-O2 | 10 | 0 | 100.0% (10/10) |
| coger | 10 | 1 | 100.0% (9/9) |
| ES-2 | 10 | 0 | 100.0% (10/10) |
| multi-correction-join-key | 10 | 0 | 100.0% (10/10) |
