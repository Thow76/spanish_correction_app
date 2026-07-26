# Bare Prompt Control Test

Model: `gpt-5.5`  
Generated: 2026-07-13T22:49:04.974703  
Runs per phrase: 10

System prompt:

> You are a proofreader. Read the following text and identify any language errors — grammar, spelling, or unnatural/non-native phrasing. Do not rewrite for style, elegance, or polish beyond fixing actual errors. For each error, quote the exact problematic phrase and briefly explain what's wrong. If there are no errors, say so.

After each explanation, add a rough category tag: Grammar, Spelling, Word Choice, Natural Language, or Other. This is just a best-guess label — don't overthink it, and don't let it change how you evaluate the error itself.

## ES-1-repeated-word

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`

### Run 1/10

- **“volví para casa”** — Lo más natural y estándar es **“volví a casa”**. Con *volver*, normalmente se usa la preposición **a** para indicar el destino. **[Natural Language]**

### Run 2/10

No hay errores claros. La frase es gramatical y comprensible.

Nota: “volví para casa” puede sonar más coloquial o regional; “volví a casa” es más estándar, pero no es necesariamente un error.

### Run 3/10

- “volví para casa” — En español estándar lo natural es “volví a casa”. El verbo “volver” suele ir con “a” para indicar el destino al que se regresa. **[Word Choice]**

### Run 4/10

- **“volví para casa”** — Lo natural y estándar es **“volví a casa”**. Con el verbo *volver*, se usa normalmente la preposición **a** para indicar destino. **[Word Choice]**

### Run 5/10

- **“volví para casa”** — En español estándar, con **“volver”** se usa normalmente la preposición **“a”**: **“volví a casa”**. *Category: Grammar*

### Run 6/10

- **“volví para casa”** — Suena poco natural en español estándar; lo idiomático es **“volví a casa”**. [Natural Language]

### Run 7/10

- **“volví para casa”** — En español estándar lo natural es **“volví a casa”**. Con *volver*, normalmente se usa la preposición **a** para indicar el lugar al que se regresa. **[Word Choice]**

### Run 8/10

- **“volví para casa”** — En español estándar lo natural es decir **“volví a casa”**. El verbo **volver** suele ir con la preposición **a** para indicar destino. **[Natural Language]**

### Run 9/10

- **“volví para casa”** — En español estándar, con **“volver”** se usa normalmente la preposición **“a”**: **“volví a casa”**. *“Para casa”* suena poco natural en este contexto. **[Natural Language]**

### Run 10/10

- **“volví para casa”** — En español estándar lo natural es **“volví a casa”**. Con *volver*, se usa normalmente la preposición **a** para indicar destino. **[Word Choice]**

## ES-2-single-char

- Text: `Cuando termino el trabajo, voy para casa en autobús.`

### Run 1/10

No clear language errors. The sentence is grammatically correct.

Note: **“voy a casa”** may be more common than **“voy para casa”** in some varieties of Spanish, but **“voy para casa”** is not an error.

### Run 2/10

No errors found. The sentence is grammatically correct.

Note: “voy para casa” is colloquial/regional but acceptable. “Voy a casa” would be more standard, but this is not an error.

### Run 3/10

No clear errors. The sentence is grammatical and understandable.

Note: “voy para casa” can sound regional or colloquial; “voy a casa” is more standard in many varieties of Spanish, but “voy para casa” is not necessarily incorrect.

### Run 4/10

No errors found. The sentence is grammatically correct and natural in Spanish.

### Run 5/10

No clear language errors. The sentence is grammatically correct and natural enough in Spanish.

Note: If you mean “When I finish my workday,” **“Cuando termino de trabajar”** or **“Cuando salgo del trabajo”** may be more precise, but **“Cuando termino el trabajo”** is not incorrect.

### Run 6/10

No errors found. The sentence is grammatically correct in Spanish.

### Run 7/10

No clear language errors.

The sentence is grammatical and natural enough in Spanish: “Cuando termino el trabajo, voy para casa en autobús.”

Note: “voy a casa” is also common, but “voy para casa” is acceptable in many varieties of Spanish.

### Run 8/10

ERROR — TimeoutException after 0:00:30.000000: Future not completed

### Run 9/10

No hay errores claros. La frase es gramatical y natural:

“Cuando termino el trabajo, voy para casa en autobús.”

### Run 10/10

No clear language errors.

“voy para casa” is colloquial/regional but acceptable. In more neutral Spanish, “voy a casa” would be more common, but the original is not wrong.

## ES-3-multi-correction

- Text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`

### Run 1/10

- **“trafico”** — Falta la tilde: debe ser **“tráfico”**. [Spelling]

- **“llamaron para atrás”** — Es una traducción literal poco natural de “called back”. En español sería más natural **“llamaron de vuelta”** o **“volvieron a llamar”**. [Natural Language]

### Run 2/10

1. **“trafico”** — Falta la tilde: debe ser **“tráfico”**. [Spelling]

2. **“llamaron para atrás”** — Es una traducción literal poco natural de “called back.” En español se diría **“devolvieron la llamada”**, **“llamaron de vuelta”** o simplemente **“llamaron”**, según el sentido. [Natural Language]

### Run 3/10

- **“trafico”** — Falta la tilde: debe ser **“tráfico”**. [Spelling]

- **“llamaron para atrás”** — Es una traducción literal poco natural de “called back”. En español sería **“devolvieron la llamada”** o **“volvieron a llamar”**, según el sentido. [Natural Language]

### Run 4/10

- **“trafico”** — Falta la tilde: debe ser **“tráfico”**. **[Spelling]**

- **“llamaron para atrás”** — Es una traducción literal poco natural de “called back”. En español sería **“volvieron a llamar”** o **“devolvieron la llamada”**, según el contexto. **[Natural Language]**

### Run 5/10

- **“trafico”** — Falta la tilde: debe ser **“tráfico”**. **[Spelling]**

- **“llamaron para atrás”** — Es una expresión poco natural en español; parece un calco de “called back”. Sería más natural **“volvieron a llamar”** o **“llamaron de vuelta”**, según el contexto. **[Natural Language]**

### Run 6/10

1. **“trafico”** — Falta la tilde: debe ser **“tráfico”**. [Spelling]

2. **“llamaron para atrás”** — Es una traducción literal poco natural de “called back”. En español sería **“devolvieron la llamada”**, **“llamaron de vuelta”** o **“volvieron a llamar”**, según el contexto. [Natural Language]

Corrección posible: **“Ayer había mucho tráfico y mis amigos llamaron de vuelta para confirmar la cena.”**

### Run 7/10

- **“trafico”** — Falta la tilde: debe ser **“tráfico”**. **[Spelling]**

- **“llamaron para atrás”** — Es una traducción literal poco natural de “called back.” En español sería más natural **“volvieron a llamar”** o **“llamaron de vuelta”** (según la región). **[Natural Language]**

### Run 8/10

1. **“trafico”** — Falta la tilde: debe ser **“tráfico”**. [Spelling]

2. **“llamaron para atrás”** — Es una traducción literal poco natural de “called back.” En español sería más natural **“llamaron de vuelta”** o **“volvieron a llamar”**. [Natural Language]

### Run 9/10

Errores encontrados:

1. **“trafico”** — Falta la tilde. Como sustantivo, debe escribirse **“tráfico”**. [Spelling]

2. **“llamaron para atrás”** — Es una traducción literal no natural de “called back”. En español se diría **“devolvieron la llamada”** o **“volvieron a llamar”**, según el contexto. [Natural Language]

Una versión corregida sería: **“Ayer había mucho tráfico y mis amigos volvieron a llamar para confirmar la cena.”**

### Run 10/10

- **“trafico”** → Should be **“tráfico”**. It needs an accent mark. **[Spelling]**

- **“llamaron para atrás”** → This is an unnatural calque from English “called back.” In Spanish, use **“volvieron a llamar”** or **“devolvieron la llamada.”** **[Natural Language]**

## ES-4-calque

- Text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`

### Run 1/10

- “¿Puedo tener una cerveza?” — Suena como traducción literal de “Can I have a beer?” En español sería más natural decir “¿Me puede dar una cerveza?” o “¿Me pone una cerveza?” **[Natural Language]**

- “pasar un buen tiempo” — Es una traducción literal de “have a good time”. En español se dice “pasarlo bien” o “pasar un buen rato”. **[Natural Language]**

### Run 2/10

- “¿Puedo tener una cerveza?” — This is an unnatural calque from English “Can I have a beer?” In Spanish, you would normally say “¿Me puede dar una cerveza?”, “¿Me pone una cerveza?” or “¿Puedo tomar una cerveza?” Category: Natural Language

- “pasar un buen tiempo” — This sounds non-native in this context. More natural would be “pasarlo bien” or “pasar un buen rato.” Category: Natural Language

### Run 3/10

- **“¿Puedo tener una cerveza?”** — This sounds like a literal translation of “Can I have a beer?” In Spanish, for requesting a beer, it would be more natural to say **“¿Me das una cerveza?”**, **“¿Me puedes dar una cerveza?”**, or **“¿Me pones/traes una cerveza?”** depending on context. **[Natural Language]**

- **“pasar un buen tiempo”** — This is understandable, but it sounds non-native in this context. More natural options are **“pasarlo bien”** or **“pasar un buen rato”**. **[Natural Language]**

### Run 4/10

- **“¿Puedo tener una cerveza?”** — This is a literal translation of “Can I have a beer?” and sounds unnatural in Spanish. More natural would be **“¿Me puede dar una cerveza?”** or **“¿Me trae una cerveza?”**. **[Natural Language]**

- **“pasar un buen tiempo”** — This is also an English-influenced phrase. In Spanish, you would usually say **“pasarlo bien”** or **“pasar un buen rato”**. **[Natural Language]**

### Run 5/10

- “¿Puedo tener una cerveza?” — This is understandable but unnatural in Spanish as a request. More natural would be “¿Me das una cerveza?”, “¿Me pone una cerveza?” or “¿Puedo tomar una cerveza?” **[Natural Language]**

- “pasar un buen tiempo” — This is a literal translation of “have a good time” and sounds unnatural. In Spanish, say “pasarlo bien” or “pasar un buen rato.” **[Natural Language]**

### Run 6/10

1. **“¿Puedo tener una cerveza?”** — This is grammatically understandable, but it sounds unnatural in Spanish for ordering or asking for a beer. More natural would be **“¿Me puede dar una cerveza?”** or **“¿Puedo pedir una cerveza?”**  
   **Category: Natural Language**

2. **“pasar un buen tiempo”** — This is a literal translation of “have a good time” and sounds non-native. More natural Spanish would be **“pasarlo bien”** or **“pasar un buen rato.”**  
   **Category: Natural Language**

### Run 7/10

- **“¿Puedo tener una cerveza?”** — This is a literal translation of “Can I have a beer?” In Spanish, it sounds unnatural for ordering or asking for a beer. More natural would be **“¿Me puede dar una cerveza?”**, **“¿Me pone una cerveza?”**, or **“¿Puedo tomar una cerveza?”** depending on context. **[Natural Language]**

- **“pasar un buen tiempo”** — This is also a literal translation of “have a good time.” In Spanish, the natural expression is **“pasar un buen rato”** or **“pasarlo bien”**. **[Natural Language]**

### Run 8/10

- **“¿Puedo tener una cerveza?”** — This is a literal translation of “Can I have a beer?” and sounds unnatural in Spanish if you mean ordering or asking for one. More natural would be “¿Me puede dar una cerveza?” or “¿Puedo tomar una cerveza?” depending on context. **[Natural Language]**

- **“pasar un buen tiempo”** — This is an unnatural calque from English “have a good time.” In Spanish, you would usually say “pasarlo bien” or “pasar un buen rato.” **[Natural Language]**

### Run 9/10

- “¿Puedo tener una cerveza?” — This is a literal translation of “Can I have a beer?” In Spanish, it sounds unnatural if you are ordering or asking someone to give you one. More natural would be “¿Me puede dar una cerveza?” or “¿Puedo tomar una cerveza?” depending on context. **[Natural Language]**

- “pasar un buen tiempo” — This is also a literal translation of “have a good time.” In Spanish, “pasarlo bien” or “pasar un buen rato” is more natural. **[Natural Language]**

### Run 10/10

- “¿Puedo tener una cerveza?” — This is a literal translation of “Can I have a beer?” and sounds unnatural in Spanish. More natural: “¿Me puede dar una cerveza?” or “¿Me pones una cerveza?” — Natural Language

- “pasar un buen tiempo” — This is also a literal-sounding phrase. In Spanish, you would usually say “pasarlo bien” or “pasar un buen rato.” — Natural Language

## ES-5-accents

- Text: `Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.`

### Run 1/10

- **“Espana”** → Should be **“España”**. Missing the letter **ñ**. [Spelling]

- **“anos”** → Should be **“años”**. Missing **ñ**; *anos* has a different meaning in Spanish. [Spelling]

- **“cumpleanos”** → Should be **“cumpleaños”**. Missing **ñ**. [Spelling]

- **“otono”** → Should be **“otoño”**. Missing **ñ**. [Spelling]

### Run 2/10

- **“Espana”** → should be **“España”**. Missing **ñ**. **[Spelling]**
- **“anos”** → should be **“años”**. Missing **ñ**; *anos* means something different in Spanish. **[Spelling]**
- **“cumpleanos”** → should be **“cumpleaños”**. Missing **ñ**. **[Spelling]**
- **“otono”** → should be **“otoño”**. Missing **ñ**. **[Spelling]**

### Run 3/10

- **“Espana”** — Missing the tilde; it should be **“España.”** [Spelling]

- **“anos”** — Missing the tilde; it should be **“años.”** Without the tilde, **“anos”** means “anuses.” [Spelling]

- **“cumpleanos”** — Missing the tilde; it should be **“cumpleaños.”** [Spelling]

- **“otono”** — Missing the tilde; it should be **“otoño.”** [Spelling]

Corrected sentence: **Vivo en España desde hace tres años y mi cumpleaños es en otoño.**

### Run 4/10

- **“Espana”** → Should be **“España”**. The letter **ñ** is required. **[Spelling]**

- **“anos”** → Should be **“años”**. Without **ñ**, “anos” means “anuses,” not “years.” **[Spelling]**

- **“cumpleanos”** → Should be **“cumpleaños”**. The word requires **ñ**. **[Spelling]**

- **“otono”** → Should be **“otoño”**. The word requires **ñ**. **[Spelling]**

### Run 5/10

- **“Espana”** — Missing the tilde: should be **“España”**. [Spelling]

- **“anos”** — Missing the tilde: should be **“años”**. Without the tilde, it means something else. [Spelling]

- **“cumpleanos”** — Missing the tilde: should be **“cumpleaños”**. [Spelling]

- **“otono”** — Missing the tilde: should be **“otoño”**. [Spelling]

### Run 6/10

- “Espana” — Missing the tilde: should be “España.” **[Spelling]**
- “anos” — Missing the tilde: should be “años.” Without the tilde, “anos” means “anuses.” **[Spelling]**
- “cumpleanos” — Missing the tilde: should be “cumpleaños.” **[Spelling]**
- “otono” — Missing the tilde: should be “otoño.” **[Spelling]**

### Run 7/10

- “Espana” → should be “España.” Missing the letter “ñ.” [Spelling]

- “anos” → should be “años.” Missing the letter “ñ”; “anos” means “anuses,” so this changes the meaning. [Spelling]

- “cumpleanos” → should be “cumpleaños.” Missing the letter “ñ.” [Spelling]

- “otono” → should be “otoño.” Missing the letter “ñ.” [Spelling]

### Run 8/10

- “Espana” — Missing the ñ; it should be “España.” [Spelling]

- “anos” — Missing the ñ; it should be “años.” Without ñ, it has a different meaning. [Spelling]

- “cumpleanos” — Missing the ñ; it should be “cumpleaños.” [Spelling]

- “otono” — Missing the ñ; it should be “otoño.” [Spelling]

### Run 9/10

Errors found:

1. **“Espana”** — Missing the ñ. Correct: **“España”**. [Spelling]

2. **“anos”** — Missing the ñ. Correct: **“años”**. Without ñ, it means something else in Spanish. [Spelling]

3. **“cumpleanos”** — Missing the ñ. Correct: **“cumpleaños”**. [Spelling]

4. **“otono”** — Missing the ñ. Correct: **“otoño”**. [Spelling]

Corrected sentence: **“Vivo en España desde hace tres años y mi cumpleaños es en otoño.”**

### Run 10/10

- “Espana” → Should be “España”; the country name requires “ñ.” **[Spelling]**

- “anos” → Should be “años”; “anos” means “anuses,” while “años” means “years.” **[Spelling]**

- “cumpleanos” → Should be “cumpleaños”; it requires “ñ.” **[Spelling]**

- “otono” → Should be “otoño”; it requires “ñ.” **[Spelling]**

## ES-6-redundant-pronoun

- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`

### Run 1/10

- **“yo estudié, y yo hice”** — In Spanish, a comma is normally not used before **“y”** in a simple coordinated list like this. **[Grammar]**

- **“Yo fui…, yo estudié…, yo hice…”** — Repeating **“yo”** before every verb is grammatically possible, but it sounds unnatural/non-native unless you are deliberately emphasizing “I.” **[Natural Language]**

### Run 2/10

- **“yo fui…, yo estudié…, y yo hice…”** — Repeating **“yo”** before every verb is grammatically possible, but it sounds unnatural in Spanish unless you want strong emphasis or contrast. **[Natural Language]**

- **“, y”** — In Spanish, a comma is normally not used before **“y”** in a simple list of actions. **[Grammar]**

### Run 3/10

- **“Yo fui a casa, yo estudié, y yo hice la cena.”** — The repeated subject pronoun **“yo”** sounds unnatural in Spanish unless you want strong emphasis. Spanish normally omits subject pronouns when the verb already makes the subject clear. **[Natural Language]**

- **“estudié, y”** — In Spanish, a comma is usually not used before **“y”** in a simple list of actions. **[Grammar]**

### Run 4/10

- **“Yo fui a casa, yo estudié, y yo hice la cena.”** — The repeated **“yo”** sounds unnatural in Spanish unless you are emphasizing or contrasting who did each action. Spanish usually omits subject pronouns when the verb form makes the subject clear. **[Natural Language]**

- **“, y”** — The comma before **“y”** is generally not used in a simple list of actions in Spanish. **[Grammar]**

### Run 5/10

1. **“yo estudié, y yo hice”** — In Spanish, a comma is normally not used before **“y”** in a simple list of coordinated clauses. It should be **“yo estudié y yo hice”**. **[Grammar]**

2. **“Yo fui…, yo estudié…, yo hice…”** — Repeating **“yo”** before every verb is grammatically possible, but it sounds unnatural unless you are deliberately emphasizing “I” each time. **[Natural Language]**

### Run 6/10

- **“yo … yo … yo”** — In Spanish, repeating the subject pronoun this way sounds unnatural unless you are emphasizing or contrasting who did each action. Normally the pronoun would be omitted after the first time, or omitted entirely. **[Natural Language]**

- **“, y”** — In Spanish, a comma is usually not used before **“y”** in a simple list or sequence of actions. **[Other]**

### Run 7/10

- **“yo estudié, y yo hice”** — In Spanish, a comma is normally not used before **“y”** in a simple list or sequence of actions. **Category: Grammar**

- **“Yo fui…, yo estudié…, y yo hice…”** — Repeating **“yo”** before every verb is grammatically possible but unnatural unless you want strong emphasis or contrast. Spanish usually omits repeated subject pronouns. **Category: Natural Language**

### Run 8/10

- **“yo … yo … yo”** — Repeating **“yo”** before every verb is grammatically possible, but it sounds unnatural/non-native unless you are emphasizing the subject each time. **[Natural Language]**

- **“, y”** — In Spanish, a comma is usually not used before **“y”** in a simple list of actions with the same subject. **[Grammar]**

### Run 9/10

- **“Yo fui…, yo estudié…, y yo hice…”** — Repeating **“yo”** before every verb sounds unnatural in Spanish unless you are deliberately emphasizing or contrasting the subject. Spanish normally drops the subject pronoun here: **“Fui a casa, estudié…”**. **[Natural Language]**

- **“, y yo hice”** — The comma before **“y”** is generally unnecessary in a simple list in Spanish. **[Grammar]**

### Run 10/10

- **“Yo fui a casa, yo estudié, y yo hice la cena”** — Repeating **“yo”** before every verb is grammatically possible, but it sounds unnatural in Spanish unless you are deliberately emphasizing “I.” **[Natural Language]**

- **“, y”** — In a simple list/sequence, Spanish normally does not use a comma before **“y.”** **[Other]**

A more natural corrected version would be: **“Fui a casa, estudié e hice la cena.”**

## PT-1-repeated-word

- Text: `Ontem fui ao supermercado para comprar pão e depois voltei para casa para preparar o jantar, mas esqueci para pegar o leite.`

### Run 1/10

- **“esqueci para pegar o leite”** — O verbo **“esquecer”** não é usado com **“para”** nesse caso. O correto seria **“esqueci de pegar o leite”** ou **“esqueci o leite”**. **[Grammar]**

### Run 2/10

- **“esqueci para pegar o leite”** — O verbo **“esquecer”** seguido de infinitivo normalmente exige **“de”**: o correto seria **“esqueci de pegar o leite”**. Categoria: **Grammar**

### Run 3/10

- **“esqueci para pegar o leite”** — O verbo **“esquecer”** não é usado com **“para”** nesse caso. O correto seria **“esqueci de pegar o leite”** ou **“esqueci o leite”**. **[Grammar]**

### Run 4/10

- **“esqueci para pegar o leite”** — O verbo **“esquecer”** não é usado com **“para”** nesse contexto. O correto seria **“esqueci de pegar o leite”** ou **“esqueci-me de pegar o leite”**. **[Grammar]**

### Run 5/10

- **“esqueci para pegar o leite”** — O verbo **“esquecer”** não é usado com **“para”** nesse caso. O correto seria **“esqueci de pegar o leite”**. **[Grammar]**

### Run 6/10

- **“esqueci para pegar o leite”** — O verbo **“esquecer”** não é usado com **“para”** nesse contexto. O correto seria **“esqueci de pegar o leite”**. **[Grammar]**

### Run 7/10

- **“esqueci para pegar o leite”** — O correto é **“esqueci de pegar o leite”**. Em português, usa-se **“esquecer de + infinitivo”** quando se quer dizer que alguém deixou de fazer algo. **[Grammar]**

### Run 8/10

- **“esqueci para pegar o leite”** — O verbo **“esquecer”** não se usa com **“para”** nesse caso. O correto seria **“esqueci de pegar o leite”** ou **“esqueci-me de pegar o leite”**. **[Grammar]**

### Run 9/10

- **“esqueci para pegar o leite”** — A construção correta é **“esqueci de pegar o leite”**. Em português, usa-se **“esquecer de + infinitivo”**, não **“esquecer para + infinitivo”**. **[Grammar]**

### Run 10/10

- “esqueci para pegar o leite” — O verbo “esquecer” com outro verbo no infinitivo deve ser usado com “de”: “esqueci de pegar o leite”. **[Grammar]**

## PT-2-single-char

- Text: `Eu gosto de ir a praia nos fins de semana com a minha família.`

### Run 1/10

- **“ir a praia”** — O correto é **“ir à praia”**, com crase, porque há a preposição **“a”** exigida por “ir” + o artigo feminino **“a”** antes de “praia”. **[Grammar]**

### Run 2/10

- **“a praia”** — Should be **“à praia”**. In Portuguese, **ir a** + **a praia** requires crase: **ir à praia**. **[Grammar]**

### Run 3/10

- **“ir a praia”** — O correto é **“ir à praia”**, com crase, porque o verbo “ir” exige a preposição **a** e “praia” admite o artigo feminino **a**. **[Grammar]**

### Run 4/10

- **“a praia”** — O correto é **“à praia”**, com crase, porque o verbo **“ir”** exige a preposição **a** (“ir a”) e **praia** vem com o artigo feminino **a**. **[Grammar]**

### Run 5/10

- “ir a praia” → Should be “ir à praia.” The verb “ir” takes the preposition “a,” and “praia” uses the article “a,” so they combine with crasis: “à.” **[Grammar]**

### Run 6/10

- **“ir a praia”** — O correto é **“ir à praia”**, com crase, porque há a preposição **a** exigida por “ir” + o artigo **a** de “a praia”. **[Grammar]**

### Run 7/10

- **“ir a praia”** — O correto é **“ir à praia”**, com crase, porque o verbo “ir” pede a preposição **a** e “praia” aceita o artigo **a**. **[Grammar]**

### Run 8/10

- **“a praia”** → O correto é **“à praia”**, com crase, porque o verbo “ir” pede a preposição **a** e “praia” exige o artigo **a**. **[Grammar]**

### Run 9/10

- **“ir a praia”** → O correto é **“ir à praia”**, com crase, porque o verbo “ir” pede a preposição **a** e “praia” vem com o artigo feminino **a**. **[Grammar]**

### Run 10/10

- “ir a praia” — falta crase: o correto é “ir à praia” (“ir a” + “a praia”). **[Grammar]**

## PT-3-multi-correction

- Text: `Ontem tinha muito transito no caminho para o trabalho e meus amigos ligaram de volta para confirmar o jantar.`

### Run 1/10

- **“transito”** — Está faltando o acento: o correto é **“trânsito”** quando significa tráfego. **[Spelling]**

### Run 2/10

- **“transito”** — falta o acento: o correto é **“trânsito”**. **[Spelling]**

- **“tinha muito trânsito”** — em português padrão escrito, para indicar existência, o mais adequado é **“havia muito trânsito”**. “Tinha” é comum na fala informal, especialmente no Brasil, mas pode ser considerado inadequado em registro mais formal. **[Grammar]**

### Run 3/10

- “transito” — Missing accent; the correct spelling is “trânsito”. **[Spelling]**

### Run 4/10

- **“transito”** — Faltou o acento: o correto é **“trânsito”**. **[Spelling]**

Não há outros erros claros na frase.

### Run 5/10

- **“transito”** — Faltou o acento: o correto é **“trânsito”**. [Spelling]

### Run 6/10

- **“transito”** → should be **“trânsito”**. The noun meaning “traffic” requires an accent; without it, it is a verb form. **[Spelling]**

No other clear language errors. “Tinha muito trânsito” is colloquial but common in Brazilian Portuguese; in more formal writing, **“havia muito trânsito”** would be preferred.

### Run 7/10

- **“transito”** — Falta o acento: o correto é **“trânsito”**. [Spelling]

### Run 8/10

- **“transito”** — Faltou o acento: o correto é **“trânsito”**. [Spelling]

### Run 9/10

- **“transito”** — Missing accent; it should be **“trânsito”**. **[Spelling]**

No other clear errors. Corrected sentence:  
**“Ontem tinha muito trânsito no caminho para o trabalho e meus amigos ligaram de volta para confirmar o jantar.”**

### Run 10/10

- **“transito”** — Falta o acento: o correto é **“trânsito”**. **[Spelling]**

## PT-4-calque

- Text: `Posso ter uma cerveja? Quero passar um bom tempo com meus amigos essa noite.`

### Run 1/10

1. **“Posso ter uma cerveja?”** — In Portuguese, **“ter”** is unnatural here as a direct translation of “have.” To order or ask for a beer, you would normally say **“Posso pedir uma cerveja?”**, **“Posso tomar uma cerveja?”**, or **“Você pode me trazer uma cerveja?”**. **[Natural Language]**

2. **“passar um bom tempo”** — This can be understood as “spend quite a lot of time,” not necessarily “have a good time.” If you mean “enjoy myself / have fun,” a more natural phrase would be **“me divertir”** or **“passar bons momentos.”** **[Word Choice]**

### Run 2/10

- **“Posso ter uma cerveja?”** — Em português, **“ter”** não soa natural para pedir uma bebida. Melhor: **“Posso tomar uma cerveja?”**, **“Posso pegar uma cerveja?”** ou **“Pode me trazer uma cerveja?”**  
  **Tag: Natural Language**

- **“passar um bom tempo”** — Se a intenção é dizer “have a good time”, isso soa como tradução literal. Em português, seria mais natural dizer **“me divertir”** ou **“passar um tempo agradável”**.  
  **Tag: Natural Language**

### Run 3/10

- **“Posso ter uma cerveja?”** — Soa como tradução literal de “Can I have a beer?” Em português, o mais natural seria **“Posso pedir uma cerveja?”**, **“Posso tomar uma cerveja?”** ou **“Você pode me trazer uma cerveja?”**  
  **[Natural Language]**

- **“passar um bom tempo”** — Pode ser entendido como “passar bastante tempo”, mas se a intenção é dizer “have a good time”, o natural seria **“me divertir”** ou **“passar um tempo agradável”**.  
  **[Word Choice]**

### Run 4/10

- **“Posso ter uma cerveja?”** — Soa como tradução literal de “Can I have a beer?” Em português, **“ter uma cerveja”** é pouco natural nesse contexto; o mais natural seria algo como “Posso pedir uma cerveja?” ou “Pode me trazer uma cerveja?” **[Natural Language]**

- **“passar um bom tempo”** — Em português, essa expressão geralmente significa **“passar bastante tempo / um bom período de tempo”**, não necessariamente “divertir-se” ou “have a good time”. Se a intenção é dizer que quer se divertir, a frase soa não nativa. **[Word Choice]**

### Run 5/10

- **“Posso ter uma cerveja?”** — Em português, isso soa como tradução literal de “Can I have a beer?”. O mais natural seria **“Posso pedir uma cerveja?”**, **“Pode me trazer uma cerveja?”** ou **“Quero uma cerveja, por favor.”** [Natural Language]

- **“passar um bom tempo”** — Se a intenção é dizer “have a good time”, essa expressão soa pouco natural em português. Melhor seria **“me divertir”** ou **“passar bons momentos”**. [Natural Language]

### Run 6/10

1. **“Posso ter uma cerveja?”** — This is a literal translation of “Can I have a beer?” and sounds unnatural in Portuguese. More natural options would be **“Posso pedir uma cerveja?”**, **“Pode me trazer uma cerveja?”**, or **“Posso tomar uma cerveja?”** depending on context. **[Natural Language]**

2. **“passar um bom tempo”** — This can mean “spend quite a long time,” but if you mean “have a good time,” it sounds like an English-influenced phrase. A more natural phrasing would be **“me divertir”** or **“passar bons momentos.”** **[Word Choice]**

### Run 7/10

1. **“Posso ter uma cerveja?”** — Em português, isso soa como tradução literal de “Can I have a beer?”. O natural seria algo como “Pode me trazer uma cerveja?” ou “Queria uma cerveja.” **[Natural Language]**

2. **“passar um bom tempo com meus amigos”** — A expressão pode ser entendida como “passar bastante tempo”, não necessariamente “divertir-se” ou “ter bons momentos”. Se a intenção é “have a good time”, seria mais natural dizer “me divertir com meus amigos” ou “passar bons momentos com meus amigos”. **[Word Choice]**

### Run 8/10

- **“Posso ter uma cerveja?”** — Em português, “ter uma cerveja” soa como tradução literal de “Can I have a beer?” O mais natural seria algo como “Posso pedir uma cerveja?” ou “Pode me trazer uma cerveja?” **[Natural Language]**

- **“passar um bom tempo”** — A expressão pode ser entendida como “passar bastante tempo”, não necessariamente “se divertir”. Se a intenção é “have a good time”, o mais natural seria “me divertir” ou “passar bons momentos”. **[Word Choice]**

### Run 9/10

- **“Posso ter uma cerveja?”** — Soa como uma tradução literal do inglês (“Can I have…”). Em português, o mais natural seria **“Posso pedir uma cerveja?”**, **“Pode me trazer uma cerveja?”** ou **“Quero uma cerveja, por favor.”**  
  **Tag: Natural Language**

- **“passar um bom tempo”** — Se a intenção é dizer “have a good time”, essa expressão soa pouco natural em português. **“Passar um bom tempo”** pode ser entendido como “passar bastante tempo”. Melhor seria **“me divertir”** ou **“passar bons momentos”**.  
  **Tag: Word Choice**

### Run 10/10

- **“Posso ter uma cerveja?”** — É gramaticalmente compreensível, mas soa como uma tradução literal de “Can I have a beer?” Em português, para pedir uma cerveja, seria mais natural dizer **“Posso pedir uma cerveja?”**, **“Pode me trazer uma cerveja?”** ou **“Quero uma cerveja, por favor.”** [Natural Language]

O restante da frase não contém erros claros.

## PT-5-accents

- Text: `Morei em Sao Paulo por tres anos mas agora vivo em Curitiba e meu aniversario é em julho.`

### Run 1/10

- “Sao Paulo” — Missing accent: should be “São Paulo.” [Spelling]

- “tres” — Missing accent: should be “três.” [Spelling]

- “por tres anos mas agora” — A comma is needed before “mas”: “por três anos, mas agora.” [Grammar]

- “aniversario” — Missing accent: should be “aniversário.” [Spelling]

### Run 2/10

- **"Sao Paulo"** — Missing accent; it should be **"São Paulo"**. **[Spelling]**

- **"tres"** — Missing accent; it should be **"três"**. **[Spelling]**

- **"anos mas agora"** — A comma is needed before **"mas"**: **"anos, mas agora"**. **[Grammar]**

- **"aniversario"** — Missing accent; it should be **"aniversário"**. **[Spelling]**

### Run 3/10

- **“Sao Paulo”** → should be **“São Paulo”**. The place name needs the tilde. **[Spelling]**

- **“tres”** → should be **“três”**. Missing circumflex accent. **[Spelling]**

- **“por tres anos mas agora”** → should be **“por três anos, mas agora”**. A comma is needed before **“mas”**. **[Grammar]**

- **“aniversario”** → should be **“aniversário”**. Missing acute accent. **[Spelling]**

### Run 4/10

Identified errors:

1. **“Sao Paulo”** — The correct spelling is **“São Paulo”**, with a tilde on **São**. **[Spelling]**

2. **“tres”** — The correct spelling is **“três”**, with an accent. **[Spelling]**

3. **“por tres anos mas agora”** — A comma is needed before **“mas”**: **“por três anos, mas agora”**. **[Grammar]**

4. **“aniversario”** — The correct spelling is **“aniversário”**, with an accent. **[Spelling]**

### Run 5/10

Errors found:

1. **“Sao Paulo”** — Missing accent; correct spelling is **“São Paulo.”**  
   **Category: Spelling**

2. **“tres”** — Missing accent; correct spelling is **“três.”**  
   **Category: Spelling**

3. **“tres anos mas”** — A comma is needed before **“mas”**: **“três anos, mas.”**  
   **Category: Grammar**

4. **“aniversario”** — Missing accent; correct spelling is **“aniversário.”**  
   **Category: Spelling**

### Run 6/10

Errors found:

1. **“Sao Paulo”** — Missing accent; it should be **“São Paulo.”** [Spelling]

2. **“tres”** — Missing accent; it should be **“três.”** [Spelling]

3. **“por tres anos mas agora”** — A comma is needed before **“mas”**: **“por três anos, mas agora...”** [Grammar]

4. **“aniversario”** — Missing accent; it should be **“aniversário.”** [Spelling]

### Run 7/10

- “Sao Paulo” → should be “São Paulo.” Missing accent/tilde in the city name. **[Spelling]**
- “tres” → should be “três.” Missing accent. **[Spelling]**
- “por tres anos mas agora” → should be “por três anos, mas agora.” A comma is needed before “mas.” **[Grammar]**
- “aniversario” → should be “aniversário.” Missing accent. **[Spelling]**

### Run 8/10

Errors found:

1. **“Sao Paulo”** — The city name should include the accent: **“São Paulo.”** [Spelling]

2. **“tres”** — Missing accent; the correct form is **“três.”** [Spelling]

3. **“anos mas”** — A comma is needed before **“mas”** in this contrastive clause: **“anos, mas.”** [Grammar]

4. **“aniversario”** — Missing accent; the correct form is **“aniversário.”** [Spelling]

Corrected sentence:  
**Morei em São Paulo por três anos, mas agora vivo em Curitiba e meu aniversário é em julho.**

### Run 9/10

Errors found:

1. **“Sao Paulo”** → should be **“São Paulo”**  
   Missing diacritic: *São* requires a tilde. **[Spelling]**

2. **“tres”** → should be **“três”**  
   Missing accent. **[Spelling]**

3. **“por tres anos mas”** → should be **“por três anos, mas”**  
   A comma is needed before **“mas”** when it connects contrasting clauses. **[Grammar]**

4. **“aniversario”** → should be **“aniversário”**  
   Missing accent. **[Spelling]**

Corrected sentence:  
**Morei em São Paulo por três anos, mas agora vivo em Curitiba e meu aniversário é em julho.**

### Run 10/10

- **“Sao Paulo”** — The city name should be written with the accent: **“São Paulo.”** [Spelling]

- **“tres”** — Missing accent; the correct spelling is **“três.”** [Spelling]

- **“por tres anos mas agora”** — A comma is needed before **“mas”** because it introduces a contrasting clause: **“por três anos, mas agora...”** [Grammar]

- **“aniversario”** — Missing accent; the correct spelling is **“aniversário.”** [Spelling]

## PT-6-redundant-pronoun

- Text: `Eu fui para casa, eu estudei, e eu fiz o jantar.`

### Run 1/10

- **“Eu fui para casa, eu estudei, e eu fiz o jantar.”** — A repetição de **“eu”** soa pouco natural em português, já que o sujeito costuma ser omitido quando é claro pelo contexto. **[Natural Language]**

- **“, e”** — A vírgula antes de **“e”** não é necessária aqui, pois liga ações em sequência com o mesmo sujeito. **[Other]**

Sugestão corrigida: **“Eu fui para casa, estudei e fiz o jantar.”**

### Run 2/10

- **“Eu fui para casa, eu estudei, e eu fiz o jantar.”** — A repetição de **“eu”** em todas as orações soa pouco natural em português, já que o sujeito pode ser omitido quando está claro. Além disso, a vírgula antes de **“e”** é desnecessária aqui. **[Natural Language]**

Uma forma corrigida seria: **“Fui para casa, estudei e fiz o jantar.”**

### Run 3/10

- **“eu estudei, e eu fiz”** — A vírgula antes de **“e”** é desnecessária aqui, já que as orações têm o mesmo sujeito e fazem parte de uma sequência simples. **[Grammar]**

- **“Eu fui..., eu estudei..., eu fiz...”** — A repetição de **“eu”** soa pouco natural em português; normalmente o sujeito seria omitido depois da primeira vez. **[Natural Language]**

### Run 4/10

No clear language errors. The sentence is grammatically understandable and correct.

Note: The repetition of “eu” sounds a bit repetitive in Portuguese, but it is not an actual error.

### Run 5/10

- **“eu estudei, e eu fiz”** — The comma before **“e”** is unnecessary in standard Portuguese in this simple list of actions with the same subject. **[Grammar]**

- **“Eu fui para casa, eu estudei, e eu fiz o jantar”** — Repeating **“eu”** before every verb is grammatical, but it sounds unnatural/non-native in Portuguese. More natural: **“Eu fui para casa, estudei e fiz o jantar.”** **[Natural Language]**

### Run 6/10

- **“eu estudei, e eu fiz”** — A vírgula antes de **“e”** é geralmente inadequada nesse tipo de coordenação simples em português, especialmente com o mesmo sujeito. Melhor: “Eu fui para casa, eu estudei e eu fiz o jantar.” **[Grammar]**

- **“Eu fui…, eu estudei…, eu fiz…”** — A repetição de **“eu”** não é gramaticalmente errada, mas soa pouco natural em português, já que o sujeito costuma ser omitido quando está claro. **[Natural Language]**

### Run 7/10

- “, e” — A vírgula antes de “e” não é normalmente usada aqui, já que as ações têm o mesmo sujeito. **[Grammar]**

- “Eu fui..., eu estudei..., eu fiz...” — A repetição de “eu” é gramaticalmente possível, mas soa pouco natural em português; normalmente o sujeito seria omitido depois da primeira vez. **[Natural Language]**

### Run 8/10

- **“Eu ... eu ... eu”** — A repetição do pronome sujeito soa pouco natural em português, já que o sujeito normalmente é omitido quando está claro pelo verbo. Uma forma mais natural seria: “Fui para casa, estudei e fiz o jantar.” **[Natural Language]**

- **“, e eu fiz”** — A vírgula antes de **“e”** geralmente não é usada quando une orações com o mesmo sujeito. **[Grammar]**

### Run 9/10

- **“, e”** — In Portuguese, a comma before **“e”** is usually not used in a simple list of actions with the same subject. **Category: Grammar**

- **“Eu fui..., eu estudei..., eu fiz...”** — Repeating **“eu”** before every verb sounds unnatural in Portuguese when the subject is already clear. A more natural version would omit the repeated pronouns. **Category: Natural Language**

### Run 10/10

- **“eu estudei, e eu fiz”** — The repeated subject pronoun **“eu”** sounds unnatural in Portuguese here; since the subject is the same, it would normally be omitted after the first clause. **[Natural Language]**

- **“, e”** — The comma before **“e”** is generally unnecessary here because the clauses share the same subject and form a simple sequence of actions. **[Grammar]**

