# Correction Consistency Harness

Model: `gpt-5.5`  
Commit: `89042e59261e59713fc977e860563173defdf69c`  
Generated: 2026-07-15T00:24:40.699055  
Runs per phrase: 10

## ES-1-repeated-word

- Language: spanish
- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Note: Two instances of "para" appear before this one ("para comprar", "para preparar"); only "volví para casa" -> "volví a casa" should be flagged. Checks repeated-word span targeting.

### Summary (10 runs, 0 error(s))

- Target 1 ("para casa"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)
- Span-width distribution: word 6, phrase 12, clause 0
- Category distribution: Grammar 15, Natural Language 3

### Run detail

- Run 1: targets caught = [true] · corrections: [Grammar] "a casa" (phrase)
- Run 2: targets caught = [true] · corrections: [Natural Language] "a comprar" (phrase); [Grammar] "a casa" (phrase)
- Run 3: targets caught = [true] · corrections: [Grammar] "a" (word); [Grammar] "a casa" (phrase)
- Run 4: targets caught = [true] · corrections: [Grammar] "a comprar" (phrase); [Grammar] "a casa" (phrase)
- Run 5: targets caught = [true] · corrections: [Grammar] "a" (word); [Grammar] "a" (word)
- Run 6: targets caught = [true] · corrections: [Grammar] "a" (word)
- Run 7: targets caught = [true] · corrections: [Grammar] "a comprar" (phrase); [Grammar] "a casa" (phrase)
- Run 8: targets caught = [true] · corrections: [Natural Language] "a comprar" (phrase); [Grammar] "a casa" (phrase)
- Run 9: targets caught = [true] · corrections: [Grammar] "a" (word); [Grammar] "a" (word)
- Run 10: targets caught = [true] · corrections: [Natural Language] "a comprar" (phrase); [Grammar] "a casa" (phrase)

## ES-2-single-char

- Language: spanish
- Text: `Cuando termino el trabajo, voy para casa en autobús.`
- Note: Negative test. "voy para casa" is acceptable Spanish — confirm no correction fires.

### Summary (10 runs, 0 error(s))

- Stayed clean: 40.0% (4/10)
- Span-width distribution: word 3, phrase 5, clause 0
- Category distribution: Grammar 3, Natural Language 5

### Run detail

- Run 1: stayed clean = true · corrections: (no corrections)
- Run 2: stayed clean = false · corrections: [Natural Language] "termino de trabajar" (phrase)
- Run 3: stayed clean = false · corrections: [Natural Language] "termino de trabajar" (phrase)
- Run 4: stayed clean = true · corrections: (no corrections)
- Run 5: stayed clean = false · corrections: [Natural Language] "termino de trabajar" (phrase); [Grammar] "a" (word)
- Run 6: stayed clean = false · corrections: [Natural Language] "termino de trabajar" (phrase)
- Run 7: stayed clean = false · corrections: [Grammar] "a" (word)
- Run 8: stayed clean = false · corrections: [Natural Language] "termino de trabajar" (phrase); [Grammar] "a" (word)
- Run 9: stayed clean = true · corrections: (no corrections)
- Run 10: stayed clean = true · corrections: (no corrections)

## ES-3-multi-correction

- Language: spanish
- Text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`
- Note: Two independent targets: "trafico" -> "tráfico" (Spelling) and "llamaron para atrás" -> "devolvieron la llamada" (Natural Language) — track both.

### Summary (10 runs, 0 error(s))

- Target 1 ("trafico"): 100.0% (10/10)
- Target 2 ("llamaron para atrás"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)
- Span-width distribution: word 10, phrase 10, clause 0
- Category distribution: Natural Language 10, Spelling 10

### Run detail

- Run 1: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "volvieron a llamar" (phrase)
- Run 2: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "volvieron a llamar" (phrase)
- Run 3: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)
- Run 4: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)
- Run 5: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)
- Run 6: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)
- Run 7: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)
- Run 8: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)
- Run 9: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)
- Run 10: targets caught = [true, true] · corrections: [Spelling] "tráfico" (word); [Natural Language] "devolvieron la llamada" (phrase)

## ES-4-calque

- Language: spanish
- Text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`
- Note: Two calque targets: "Puedo tener una cerveza" and "pasar un buen tiempo" -> "pasarlo bien" — track both.

### Summary (10 runs, 0 error(s))

- Target 1 ("Puedo tener una cerveza"): 100.0% (10/10)
- Target 2 ("pasar un buen tiempo"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)
- Span-width distribution: word 0, phrase 20, clause 0
- Category distribution: Natural Language 20

### Run detail

- Run 1: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 2: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 3: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 4: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 5: targets caught = [true, true] · corrections: [Natural Language] "¿Me trae una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 6: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 7: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 8: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 9: targets caught = [true, true] · corrections: [Natural Language] "¿Me trae una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)
- Run 10: targets caught = [true, true] · corrections: [Natural Language] "¿Me pone una cerveza?" (phrase); [Natural Language] "pasarlo bien" (phrase)

## ES-5-accents

- Language: spanish
- Text: `Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.`
- Note: Four independent accent targets in one phrase — track catch rate per individual word, not just phrase-level.

### Summary (10 runs, 0 error(s))

- Target 1 ("Espana"): 100.0% (10/10)
- Target 2 ("anos"): 100.0% (10/10)
- Target 3 ("cumpleanos"): 100.0% (10/10)
- Target 4 ("otono"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)
- Span-width distribution: word 40, phrase 0, clause 0
- Category distribution: Spelling 40

### Run detail

- Run 1: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 2: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 3: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 4: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 5: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 6: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 7: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 8: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 9: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)
- Run 10: targets caught = [true, true, true, true] · corrections: [Spelling] "España" (word); [Spelling] "años" (word); [Spelling] "cumpleaños" (word); [Spelling] "otoño" (word)

## ES-6-redundant-pronoun

- Language: spanish
- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`
- Note: Spanish is pro-drop; repeating "yo" before every verb is grammatical but unnatural. Expect the 2nd and/or 3rd "yo" dropped (first "yo" typically kept). Category assignment itself may be unstable between Grammar and Natural Language — both accepted.

### Summary (10 runs, 1 error(s))

- Target 1 ("yo estudié"): 88.9% (8/9)
- Target 2 ("yo hice la cena"): 55.6% (5/9)
- Fully caught (all targets in one run): 55.6% (5/9)
- Span-width distribution: word 4, phrase 16, clause 2
- Category distribution: Grammar 7, Natural Language 15

### Run detail

- Run 1: targets caught = [true, true] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] "estudié" (phrase); [Grammar] "e" (word)
- Run 2: targets caught = [true, true] · corrections: [Natural Language] "Fui a casa, estudié e hice la cena." (clause)
- Run 3: targets caught = [true, false] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] ", estudié" (phrase); [Grammar] " e hice" (phrase)
- Run 4: targets caught = [true, true] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] "estudié" (phrase); [Grammar] "e" (word); [Natural Language] "hice" (phrase)
- Run 5: targets caught = [true, false] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] "estudié" (phrase); [Grammar] " e hice" (phrase)
- Run 6: targets caught = [false, false] · corrections: [Natural Language] "Fui" (phrase); [Grammar] " e" (phrase)
- Run 7: targets caught = [true, true] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] "estudié" (phrase); [Grammar] "e" (word)
- Run 8: ERROR — apiFailure: OpenAI correction timed out: TimeoutException after 0:00:30.000000: Future not completed
- Run 9: targets caught = [true, false] · corrections: [Natural Language] "Fui a casa, estudié e hice" (clause)
- Run 10: targets caught = [true, true] · corrections: [Natural Language] "Fui" (phrase); [Grammar] "e" (word)

## PT-1-repeated-word

- Language: portuguese
- Text: `Ontem fui ao supermercado para comprar pão e depois voltei para casa para preparar o jantar, mas esqueci para pegar o leite.`
- Note: "para" appears four times; only "esqueci para pegar" -> "esqueci de pegar" should be flagged. Checks correct-instance targeting.

### Summary (10 runs, 0 error(s))

- Target 1 ("esqueci para pegar"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)
- Span-width distribution: word 10, phrase 0, clause 0
- Category distribution: Grammar 10

### Run detail

- Run 1: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 2: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 3: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 4: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 5: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 6: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 7: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 8: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 9: targets caught = [true] · corrections: [Grammar] "de" (word)
- Run 10: targets caught = [true] · corrections: [Grammar] "de" (word)

## PT-2-single-char

- Language: portuguese
- Text: `Eu gosto de ir a praia nos fins de semana com a minha família.`
- Note: "a" -> "à". Confirm correction lands on "a praia", not the later "a minha família".

### Summary (10 runs, 0 error(s))

- Target 1 ("a praia"): 90.0% (9/10)
- Fully caught (all targets in one run): 90.0% (9/10)
- Span-width distribution: word 9, phrase 1, clause 0
- Category distribution: Grammar 9, Spelling 1

### Run detail

- Run 1: targets caught = [true] · corrections: [Grammar] "à" (word)
- Run 2: targets caught = [false] · corrections: [Spelling] "à" (word)
- Run 3: targets caught = [true] · corrections: [Grammar] "à" (word)
- Run 4: targets caught = [true] · corrections: [Grammar] "à" (word)
- Run 5: targets caught = [true] · corrections: [Grammar] "à" (word)
- Run 6: targets caught = [true] · corrections: [Grammar] "à" (word)
- Run 7: targets caught = [true] · corrections: [Grammar] "à praia" (phrase)
- Run 8: targets caught = [true] · corrections: [Grammar] "à" (word)
- Run 9: targets caught = [true] · corrections: [Grammar] "à" (word)
- Run 10: targets caught = [true] · corrections: [Grammar] "à" (word)

## PT-3-multi-correction

- Language: portuguese
- Text: `Ontem tinha muito transito no caminho para o trabalho e meus amigos ligaram de volta para confirmar o jantar.`
- Note: Two independent targets: "transito" -> "trânsito" (Spelling) and "ligaram de volta" -> "retornaram a ligação" or similar (Natural Language) — track both.

### Summary (10 runs, 0 error(s))

- Target 1 ("transito"): 100.0% (10/10)
- Target 2 ("ligaram de volta"): 0.0% (0/10)
- Fully caught (all targets in one run): 0.0% (0/10)
- Span-width distribution: word 10, phrase 0, clause 0
- Category distribution: Spelling 10

### Run detail

- Run 1: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 2: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 3: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 4: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 5: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 6: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 7: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 8: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 9: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)
- Run 10: targets caught = [true, false] · corrections: [Spelling] "trânsito" (word)

## PT-4-calque

- Language: portuguese
- Text: `Posso ter uma cerveja? Quero passar um bom tempo com meus amigos essa noite.`
- Note: Three targets: "Posso ter uma cerveja", "passar um bom tempo" -> "me divertir"/"curtir", and possibly "essa noite" -> "hoje à noite" — track all three.

### Summary (10 runs, 1 error(s))

- Target 1 ("Posso ter uma cerveja"): 66.7% (6/9)
- Target 2 ("passar um bom tempo"): 100.0% (9/9)
- Target 3 ("essa noite"): 11.1% (1/9)
- Fully caught (all targets in one run): 11.1% (1/9)
- Span-width distribution: word 3, phrase 16, clause 0
- Category distribution: Natural Language 16, Word Choice 3

### Run detail

- Run 1: targets caught = [true, true, false] · corrections: [Natural Language] "Você pode me trazer" (phrase); [Natural Language] "me divertir" (phrase)
- Run 2: targets caught = [false, true, false] · corrections: [Word Choice] "pegar" (word); [Natural Language] "me divertir" (phrase)
- Run 3: targets caught = [false, true, false] · corrections: [Word Choice] "tomar" (word); [Natural Language] "me divertir" (phrase)
- Run 4: targets caught = [true, true, false] · corrections: [Natural Language] "Você pode me trazer uma cerveja" (phrase); [Natural Language] "me divertir" (phrase)
- Run 5: targets caught = [true, true, false] · corrections: [Natural Language] "Pode me trazer" (phrase); [Natural Language] "me divertir" (phrase)
- Run 6: targets caught = [true, true, false] · corrections: [Natural Language] "Pode me trazer" (phrase); [Natural Language] "me divertir" (phrase)
- Run 7: targets caught = [false, true, false] · corrections: [Word Choice] "pegar" (word); [Natural Language] "me divertir" (phrase)
- Run 8: targets caught = [true, true, false] · corrections: [Natural Language] "Pode me trazer uma cerveja?" (phrase); [Natural Language] "me divertir" (phrase)
- Run 9: ERROR — apiFailure: OpenAI correction timed out: TimeoutException after 0:00:30.000000: Future not completed
- Run 10: targets caught = [true, true, true] · corrections: [Natural Language] "Pode me trazer uma cerveja" (phrase); [Natural Language] "me divertir" (phrase); [Natural Language] "hoje à noite" (phrase)

## PT-5-accents

- Language: portuguese
- Text: `Morei em Sao Paulo por tres anos mas agora vivo em Curitiba e meu aniversario é em julho.`
- Note: Three independent accent targets in one phrase — track catch rate per individual word.

### Summary (10 runs, 1 error(s))

- Target 1 ("Sao"): 100.0% (9/9)
- Target 2 ("tres"): 100.0% (9/9)
- Target 3 ("aniversario"): 100.0% (9/9)
- Fully caught (all targets in one run): 100.0% (9/9)
- Span-width distribution: word 38, phrase 0, clause 0
- Category distribution: Grammar 9, Spelling 27, Word Choice 2

### Run detail

- Run 1: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Spelling] "aniversário" (word)
- Run 2: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Spelling] "aniversário" (word)
- Run 3: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Spelling] "aniversário" (word)
- Run 4: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Spelling] "aniversário" (word)
- Run 5: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Word Choice] "moro" (word); [Spelling] "aniversário" (word)
- Run 6: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Spelling] "aniversário" (word)
- Run 7: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Spelling] "aniversário" (word)
- Run 8: ERROR — apiFailure: OpenAI correction timed out: TimeoutException after 0:00:30.000000: Future not completed
- Run 9: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Spelling] "aniversário" (word)
- Run 10: targets caught = [true, true, true] · corrections: [Spelling] "São" (word); [Spelling] "três" (word); [Grammar] "," (word); [Word Choice] "moro" (word); [Spelling] "aniversário" (word)

## PT-6-redundant-pronoun

- Language: portuguese
- Text: `Eu fui para casa, eu estudei, e eu fiz o jantar.`
- Note: Portuguese is pro-drop; same pattern as ES-6. Expect 2nd and/or 3rd "eu" dropped, first typically kept. This overlaps directly with the known BP-002 pronoun rule (~33-40% detection miss rate) — this phrase is a direct test of that existing known limitation, not a new unrelated case.

### Summary (10 runs, 0 error(s))

- Target 1 ("eu estudei"): 70.0% (7/10)
- Target 2 ("eu fiz o jantar"): 20.0% (2/10)
- Fully caught (all targets in one run): 20.0% (2/10)
- Span-width distribution: word 0, phrase 7, clause 6
- Category distribution: Natural Language 13

### Run detail

- Run 1: targets caught = [true, false] · corrections: [Natural Language] "Fui para casa, estudei e fiz" (clause)
- Run 2: targets caught = [true, false] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] ", estudei e fiz" (clause)
- Run 3: targets caught = [false, false] · corrections: (no corrections)
- Run 4: targets caught = [true, false] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] "estudei e fiz" (clause)
- Run 5: targets caught = [true, true] · corrections: [Natural Language] "Fui para casa, estudei e fiz o jantar." (clause)
- Run 6: targets caught = [true, false] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] "estudei e fiz" (clause)
- Run 7: targets caught = [true, true] · corrections: [Natural Language] "Fui" (phrase); [Natural Language] "estudei" (phrase); [Natural Language] "fiz" (phrase)
- Run 8: targets caught = [true, false] · corrections: [Natural Language] "estudei e fiz" (clause)
- Run 9: targets caught = [false, false] · corrections: (no corrections)
- Run 10: targets caught = [false, false] · corrections: [Natural Language] "Fui" (phrase)

---

## Overall summary

| Phrase | Runs | Errors | Headline rate | Per-target rates |
| --- | --- | --- | --- | --- |
| ES-1-repeated-word | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ES-2-single-char | 10 | 0 | 40.0% (4/10) (clean) | — |
| ES-3-multi-correction | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10) |
| ES-4-calque | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10) |
| ES-5-accents | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10), 100.0% (10/10), 100.0% (10/10) |
| ES-6-redundant-pronoun | 10 | 1 | 55.6% (5/9) (fully caught) | 88.9% (8/9), 55.6% (5/9) |
| PT-1-repeated-word | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| PT-2-single-char | 10 | 0 | 90.0% (9/10) (fully caught) | 90.0% (9/10) |
| PT-3-multi-correction | 10 | 0 | 0.0% (0/10) (fully caught) | 100.0% (10/10), 0.0% (0/10) |
| PT-4-calque | 10 | 1 | 11.1% (1/9) (fully caught) | 66.7% (6/9), 100.0% (9/9), 11.1% (1/9) |
| PT-5-accents | 10 | 1 | 100.0% (9/9) (fully caught) | 100.0% (9/9), 100.0% (9/9), 100.0% (9/9) |
| PT-6-redundant-pronoun | 10 | 0 | 20.0% (2/10) (fully caught) | 70.0% (7/10), 20.0% (2/10) |
