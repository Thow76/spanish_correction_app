# Stage 1 Detection Harness

Model: `gpt-5.5`  
Commit: `e370e9fa8f22c96f32927b55cd22eb1987416c32`  
Generated: 2026-07-18T16:36:18.929729  
Runs per phrase: 10

## Core battery (ES-1..ES-6, reused verbatim)

### ES-1-repeated-word

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Note: Two instances of "para" appear before this one ("para comprar", "para preparar"); only "volví para casa" -> "volví a casa" should be flagged. Checks repeated-word targeting.

#### Summary (10 runs, 0 error(s))

- Target 1 ("para casa"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)

#### Run detail

- Run 1: targets caught = [true] · flagged: "volví para casa"
- Run 2: targets caught = [true] · flagged: "volví para casa"
- Run 3: targets caught = [true] · flagged: "volví para casa"
- Run 4: targets caught = [true] · flagged: "volví para casa"
- Run 5: targets caught = [true] · flagged: "volví para casa"
- Run 6: targets caught = [true] · flagged: "volví para casa"
- Run 7: targets caught = [true] · flagged: "volví para casa"
- Run 8: targets caught = [true] · flagged: "volví para casa"
- Run 9: targets caught = [true] · flagged: "volví para casa"
- Run 10: targets caught = [true] · flagged: "volví para casa"

### ES-2-single-char

- Text: `Cuando termino el trabajo, voy para casa en autobús.`
- Note: Negative test. "voy para casa" is acceptable Spanish — confirm no phrase is flagged.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 80.0% (8/10)

#### Run detail

- Run 1: stayed clean = true · flagged: (no phrases flagged)
- Run 2: stayed clean = true · flagged: (no phrases flagged)
- Run 3: stayed clean = true · flagged: (no phrases flagged)
- Run 4: stayed clean = true · flagged: (no phrases flagged)
- Run 5: stayed clean = false · flagged: "voy para casa"
- Run 6: stayed clean = true · flagged: (no phrases flagged)
- Run 7: stayed clean = false · flagged: "voy para casa"
- Run 8: stayed clean = true · flagged: (no phrases flagged)
- Run 9: stayed clean = true · flagged: (no phrases flagged)
- Run 10: stayed clean = true · flagged: (no phrases flagged)

### ES-3-multi-correction

- Text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`
- Note: Two independent targets: "trafico" (spelling) and "llamaron para atrás" (calque) — track both.

#### Summary (10 runs, 0 error(s))

- Target 1 ("trafico"): 100.0% (10/10)
- Target 2 ("llamaron para atrás"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)

#### Run detail

- Run 1: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 2: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 3: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 4: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 5: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 6: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 7: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 8: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 9: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"
- Run 10: targets caught = [true, true] · flagged: "trafico"; "llamaron para atrás"

### ES-4-calque

- Text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`
- Note: Two calque targets — track both.

#### Summary (10 runs, 0 error(s))

- Target 1 ("Puedo tener una cerveza"): 100.0% (10/10)
- Target 2 ("pasar un buen tiempo"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)

#### Run detail

- Run 1: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 2: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 3: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 4: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 5: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 6: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 7: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 8: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 9: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"
- Run 10: targets caught = [true, true] · flagged: "¿Puedo tener una cerveza?"; "pasar un buen tiempo"

### ES-5-accents

- Text: `Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.`
- Note: Four independent accent targets in one phrase — track catch rate per individual word, not just phrase-level.

#### Summary (10 runs, 0 error(s))

- Target 1 ("Espana"): 100.0% (10/10)
- Target 2 ("anos"): 100.0% (10/10)
- Target 3 ("cumpleanos"): 100.0% (10/10)
- Target 4 ("otono"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)

#### Run detail

- Run 1: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 2: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 3: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 4: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 5: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 6: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 7: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 8: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 9: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"
- Run 10: targets caught = [true, true, true, true] · flagged: "Espana"; "anos"; "cumpleanos"; "otono"

### ES-6-redundant-pronoun

- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`
- Note: Spanish is pro-drop; repeating "yo" before every verb is grammatical but unnatural. Expect the 2nd and/or 3rd "yo" flagged (first "yo" typically kept).

#### Summary (10 runs, 0 error(s))

- Target 1 ("yo estudié"): 40.0% (4/10)
- Target 2 ("yo hice la cena"): 30.0% (3/10)
- Fully caught (all targets in one run): 30.0% (3/10)

#### Run detail

- Run 1: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 2: targets caught = [true, true] · flagged: "yo estudié"; "yo hice la cena"
- Run 3: targets caught = [true, false] · flagged: "yo estudié, y yo hice"
- Run 4: targets caught = [false, false] · flagged: ", y"
- Run 5: targets caught = [true, true] · flagged: "Yo fui a casa, yo estudié, y yo hice la cena."
- Run 6: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 7: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 8: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 9: targets caught = [false, false] · flagged: "estudié, y"
- Run 10: targets caught = [true, true] · flagged: "Yo fui a casa, yo estudié, y yo hice la cena."

## Dialectal / regional-split battery

### ES-D1-para-casa-latam

- Text: `Cuando termino el trabajo, voy para casa en autobús.`
- Note: Same text as ES-2, re-run here under the dialectal heading. "voy para casa" is standard in much of Latin America — expect zero flags.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 50.0% (5/10)

#### Run detail

- Run 1: stayed clean = false · flagged: "voy para casa"
- Run 2: stayed clean = true · flagged: (no phrases flagged)
- Run 3: stayed clean = true · flagged: (no phrases flagged)
- Run 4: stayed clean = true · flagged: (no phrases flagged)
- Run 5: stayed clean = true · flagged: (no phrases flagged)
- Run 6: stayed clean = false · flagged: "voy para casa"
- Run 7: stayed clean = false · flagged: "voy para casa"
- Run 8: stayed clean = false · flagged: "voy para casa"
- Run 9: stayed clean = true · flagged: (no phrases flagged)
- Run 10: stayed clean = false · flagged: "voy para casa"

### ES-D2-coger-autobus _(observational only — not scored pass/fail)_

- Text: `Voy a coger el autobús para ir al centro.`
- Note: "coger el autobús" is standard, acceptable Spanish in Spain but carries a vulgar double meaning in much of Latin America. Dialectally loaded — detection may reasonably flag or not flag this. Observational only: recorded, not scored pass/fail.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 100.0% (10/10)

#### Run detail

- Run 1: stayed clean = true · flagged: (no phrases flagged)
- Run 2: stayed clean = true · flagged: (no phrases flagged)
- Run 3: stayed clean = true · flagged: (no phrases flagged)
- Run 4: stayed clean = true · flagged: (no phrases flagged)
- Run 5: stayed clean = true · flagged: (no phrases flagged)
- Run 6: stayed clean = true · flagged: (no phrases flagged)
- Run 7: stayed clean = true · flagged: (no phrases flagged)
- Run 8: stayed clean = true · flagged: (no phrases flagged)
- Run 9: stayed clean = true · flagged: (no phrases flagged)
- Run 10: stayed clean = true · flagged: (no phrases flagged)

### ES-D3-coche

- Text: `Aparqué el coche cerca de la oficina.`
- Note: Negative test. "coche" (car) is ordinary regional vocabulary — must not be flagged.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 100.0% (10/10)

#### Run detail

- Run 1: stayed clean = true · flagged: (no phrases flagged)
- Run 2: stayed clean = true · flagged: (no phrases flagged)
- Run 3: stayed clean = true · flagged: (no phrases flagged)
- Run 4: stayed clean = true · flagged: (no phrases flagged)
- Run 5: stayed clean = true · flagged: (no phrases flagged)
- Run 6: stayed clean = true · flagged: (no phrases flagged)
- Run 7: stayed clean = true · flagged: (no phrases flagged)
- Run 8: stayed clean = true · flagged: (no phrases flagged)
- Run 9: stayed clean = true · flagged: (no phrases flagged)
- Run 10: stayed clean = true · flagged: (no phrases flagged)

## Structural battery — removal sub-set (redundant word present)

### ST-R1-redundant-article

- Text: `Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a mí.`
- Note: The final "a mí" is redundant given "me gusta" already marks the subject. Observational on span cleanliness — record what gets flagged, not just whether it does.

#### Summary (10 runs, 1 error(s))

- Target 1 ("a mí"): 0.0% (0/9)
- Fully caught (all targets in one run): 0.0% (0/9)

#### Run detail

- Run 1: targets caught = [false] · flagged: (no phrases flagged)
- Run 2: targets caught = [false] · flagged: (no phrases flagged)
- Run 3: targets caught = [false] · flagged: (no phrases flagged)
- Run 4: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 5: targets caught = [false] · flagged: (no phrases flagged)
- Run 6: targets caught = [false] · flagged: (no phrases flagged)
- Run 7: targets caught = [false] · flagged: (no phrases flagged)
- Run 8: targets caught = [false] · flagged: (no phrases flagged)
- Run 9: targets caught = [false] · flagged: (no phrases flagged)
- Run 10: targets caught = [false] · flagged: (no phrases flagged)

### ST-R2-redundant-pronoun

- Text: `Nosotros vamos al cine, nosotros comemos palomitas y nosotros volvemos a casa.`
- Note: Same class as ES-6 — repeated redundant "nosotros" (second example alongside it). Expect the 2nd and/or 3rd flagged; record whether the span is a clean single "nosotros" or a messy multi-word span like ES-6 produced.

#### Summary (10 runs, 0 error(s))

- Target 1 ("nosotros comemos palomitas"): 40.0% (4/10)
- Target 2 ("nosotros volvemos a casa"): 40.0% (4/10)
- Fully caught (all targets in one run): 40.0% (4/10)

#### Run detail

- Run 1: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 2: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 3: targets caught = [true, true] · flagged: "Nosotros vamos al cine, nosotros comemos palomitas y nosotros volvemos a casa."
- Run 4: targets caught = [true, true] · flagged: "Nosotros vamos al cine, nosotros comemos palomitas y nosotros volvemos a casa."
- Run 5: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 6: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 7: targets caught = [true, true] · flagged: "nosotros comemos"; "nosotros volvemos"
- Run 8: targets caught = [true, true] · flagged: "nosotros comemos"; "nosotros volvemos"
- Run 9: targets caught = [false, false] · flagged: (no phrases flagged)
- Run 10: targets caught = [false, false] · flagged: (no phrases flagged)

## Structural battery — omission sub-set (nothing to quote)

### ST-O1-missing-question-mark _(observational only — not scored pass/fail)_

- Text: `Como estas hoy?`
- Note: Missing opening "¿". Nothing exists at the error site to quote — observational only. Record what, if anything, is flagged and whether the span is usable.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 0.0% (0/10)

#### Run detail

- Run 1: stayed clean = false · flagged: "Como estas hoy?"
- Run 2: stayed clean = false · flagged: "Como estas hoy?"
- Run 3: stayed clean = false · flagged: "Como estas hoy?"
- Run 4: stayed clean = false · flagged: "Como estas hoy?"
- Run 5: stayed clean = false · flagged: "Como estas hoy?"
- Run 6: stayed clean = false · flagged: "Como"; "estas"
- Run 7: stayed clean = false · flagged: "Como estas hoy?"
- Run 8: stayed clean = false · flagged: "Como estas hoy?"
- Run 9: stayed clean = false · flagged: "Como estas hoy?"
- Run 10: stayed clean = false · flagged: "Como estas hoy?"

### ST-O2-missing-que _(observational only — not scored pass/fail)_

- Text: `Creo está bien, pero no estoy seguro.`
- Note: Missing subordinating "que" ("Creo que está bien"). Nothing exists at the error site to quote — observational only. Record what is flagged.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 0.0% (0/10)

#### Run detail

- Run 1: stayed clean = false · flagged: "Creo está bien"
- Run 2: stayed clean = false · flagged: "Creo está bien"
- Run 3: stayed clean = false · flagged: "Creo está bien"
- Run 4: stayed clean = false · flagged: "Creo está bien"
- Run 5: stayed clean = false · flagged: "Creo está bien"
- Run 6: stayed clean = false · flagged: "Creo está bien"
- Run 7: stayed clean = false · flagged: "Creo está bien"
- Run 8: stayed clean = false · flagged: "Creo está bien"
- Run 9: stayed clean = false · flagged: "Creo está bien"
- Run 10: stayed clean = false · flagged: "Creo está bien"

### ST-O3-missing-preposition _(observational only — not scored pass/fail)_

- Text: `Voy la playa este fin de semana.`
- Note: Missing "a" ("Voy a la playa"). Nothing exists at the error site to quote — observational only. Record what is flagged.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 0.0% (0/10)

#### Run detail

- Run 1: stayed clean = false · flagged: "Voy la playa"
- Run 2: stayed clean = false · flagged: "Voy la playa"
- Run 3: stayed clean = false · flagged: "Voy la playa"
- Run 4: stayed clean = false · flagged: "Voy la playa"
- Run 5: stayed clean = false · flagged: "Voy la playa"
- Run 6: stayed clean = false · flagged: "Voy la playa"
- Run 7: stayed clean = false · flagged: "Voy la playa"
- Run 8: stayed clean = false · flagged: "Voy la playa"
- Run 9: stayed clean = false · flagged: "Voy la playa"
- Run 10: stayed clean = false · flagged: "Voy la playa"

### ST-O4-missing-exclamation-mark

- Text: `Que bonito es este lugar!`
- Note: Two distinct issues bundled deliberately: the missing opening "¡" is a pure omission with nothing to quote — read it from the raw flagged spans below, it is not scored. The missing accent on "Qué" is a normal swap-type target ("Que" -> "Qué") and IS scored — expectedFlags tracks that half only.

#### Summary (10 runs, 0 error(s))

- Target 1 ("Que"): 100.0% (10/10)
- Fully caught (all targets in one run): 100.0% (10/10)

#### Run detail

- Run 1: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 2: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 3: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 4: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 5: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 6: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 7: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 8: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 9: targets caught = [true] · flagged: "Que bonito es este lugar!"
- Run 10: targets caught = [true] · flagged: "Que bonito es este lugar!"

---

## Overall summary

| Phrase | Runs | Errors | Headline rate | Per-target rates |
| --- | --- | --- | --- | --- |
| ES-1-repeated-word | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ES-2-single-char | 10 | 0 | 80.0% (8/10) (clean) | — |
| ES-3-multi-correction | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10) |
| ES-4-calque | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10) |
| ES-5-accents | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10), 100.0% (10/10), 100.0% (10/10) |
| ES-6-redundant-pronoun | 10 | 0 | 30.0% (3/10) (fully caught) | 40.0% (4/10), 30.0% (3/10) |
| ES-D1-para-casa-latam | 10 | 0 | 50.0% (5/10) (clean) | — |
| ES-D2-coger-autobus | 10 | 0 | 100.0% (10/10) (clean) | — |
| ES-D3-coche | 10 | 0 | 100.0% (10/10) (clean) | — |
| ST-R1-redundant-article | 10 | 1 | 0.0% (0/9) (fully caught) | 0.0% (0/9) |
| ST-R2-redundant-pronoun | 10 | 0 | 40.0% (4/10) (fully caught) | 40.0% (4/10), 40.0% (4/10) |
| ST-O1-missing-question-mark | 10 | 0 | 0.0% (0/10) (clean) | — |
| ST-O2-missing-que | 10 | 0 | 0.0% (0/10) (clean) | — |
| ST-O3-missing-preposition | 10 | 0 | 0.0% (0/10) (clean) | — |
| ST-O4-missing-exclamation-mark | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
