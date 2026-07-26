# Chained Stage 1 -> Stage 2 Harness

Stage 1 model: `gpt-5.5` (stage1DetectionDialectSpanish)  
Stage 2 model: `gpt-5.5` (stage2CategorizationSpanish)  
Commit: `e370e9fa8f22c96f32927b55cd22eb1987416c32`  
Generated: 2026-07-18T22:33:01.836954  
Run counts (tiered by phrase stability):  
- 1 run(s): ES-1, ES-3, ES-4, ES-5, ST-O2, ST-O3
- 3 run(s): ES-2, coger, ordenador, coche, carro, ST-O1, ST-O4, PT-2
- 10 run(s): ES-6, ST-R2
Actual live calls made: 50 Stage 1 + 26 Stage 2 = 76 total  

## Genuine errors (swap-type) — Stage 2 verdict must be error when Stage 1 flags the target

### ES-1

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Note: Also the occurrence-sanity sentence: when Stage 1 flags "volví para casa" or a bare "para", the run detail below shows exactly what occurrence Stage 2 returns — recorded, not scored, since the flagged span (and therefore which "para" Stage 2 is disambiguating against) is whatever Stage 1 actually produced this run, not a fixed input.

#### Summary (1 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (1/1) (clean: 0.0% (0/1))
- Flagged span distribution: "volví para casa": 1
- Hard expectation ("para casa"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "not_an_error": 1 -> caught 0.0% (0/1)
  - Category distribution: "(none)": 1
  - Corrected-phrase distribution: "volví para casa": 1
  - Occurrence distribution: "1": 1

#### Run detail

- Run 1: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"

### ES-3

- Text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`
- Note: Two independent genuine-error targets in one sentence.

#### Summary (1 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (1/1) (clean: 0.0% (0/1))
- Flagged span distribution: "llamaron para atrás": 1, "trafico": 1
- Hard expectation ("trafico"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Spelling": 1
  - Corrected-phrase distribution: "tráfico": 1
  - Occurrence distribution: "1": 1
- Hard expectation ("llamaron para atrás"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Natural Language": 1
  - Corrected-phrase distribution: "volvieron a llamar": 1
  - Occurrence distribution: "1": 1

#### Run detail

- Run 1: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"

### ES-4

- Text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`
- Note: Two calque targets. Live Stage 1 may flag either, both, or neither in a given run — each is scored independently.

#### Summary (1 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (1/1) (clean: 0.0% (0/1))
- Flagged span distribution: "pasar un buen tiempo": 1, "¿Puedo tener una cerveza?": 1
- Hard expectation ("Puedo tener una cerveza"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Natural Language": 1
  - Corrected-phrase distribution: "¿Me da una cerveza?": 1
  - Occurrence distribution: "1": 1
- Hard expectation ("pasar un buen tiempo"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Natural Language": 1
  - Corrected-phrase distribution: "pasarlo bien": 1
  - Occurrence distribution: "1": 1

#### Run detail

- Run 1: "¿Puedo tener una cerveza?" -> verdict=error, category=Natural Language, occurrence=1, corrected="¿Me da una cerveza?" | "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"

### ES-5

- Text: `Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.`
- Note: Four independent missing-accent targets.

#### Summary (1 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (1/1) (clean: 0.0% (0/1))
- Flagged span distribution: "Espana": 1, "anos": 1, "cumpleanos": 1, "otono": 1
- Hard expectation ("Espana"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Spelling": 1
  - Corrected-phrase distribution: "España": 1
  - Occurrence distribution: "1": 1
- Hard expectation ("anos"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Spelling": 1
  - Corrected-phrase distribution: "años": 1
  - Occurrence distribution: "1": 1
- Hard expectation ("cumpleanos"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Spelling": 1
  - Corrected-phrase distribution: "años": 1
  - Occurrence distribution: "1": 1
- Hard expectation ("otono"):
  - Flagged by Stage 1: 100.0% (1/1)
  - Verdict distribution (when flagged): "error": 1 -> caught 100.0% (1/1)
  - Category distribution: "Spelling": 1
  - Corrected-phrase distribution: "otoño": 1
  - Occurrence distribution: "1": 1

#### Run detail

- Run 1: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"

## Dialectal / borderline (observational)

### ES-2

- Text: `Cuando termino el trabajo, voy para casa en autobús.`
- Note: "voy para casa" is standard in much of Latin America. No hard expectation — record whether/how Stage 1 flags it and what Stage 2 does with whatever span it gets.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 0.0% (0/3) (clean: 100.0% (3/3))
- Flagged span distribution: "(clean)": 3

#### Run detail

- Run 1: clean — no Stage 2 call
- Run 2: clean — no Stage 2 call
- Run 3: clean — no Stage 2 call

### coger

- Text: `Voy a coger el autobús para ir al centro.`
- Note: Standard in Spain, vulgar in much of Latin America — the canonical dialectal case. No hard expectation here (already scored with a fixed input in test/stage2_categorization_harness.dart's "coger" case); this is about whether the live chain reproduces that result.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (3/3) (clean: 0.0% (0/3))
- Flagged span distribution: "coger el autobús": 3

#### Run detail

- Run 1: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 2: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 3: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"

## Ordinary regional vocabulary — must not chain into error

### ordenador

- Text: `Voy a usar el ordenador en la oficina.`
- Note: The case stage1DetectionDialectSpanish surfaced 2/10 in the dialect-variant harness. Confirms the full chain never routes it to error, not just Stage 2 in isolation.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 33.3% (1/3) (clean: 66.7% (2/3))
- Flagged span distribution: "(clean)": 2, "ordenador": 1
- Hard expectation ("ordenador"):
  - Flagged by Stage 1: 33.3% (1/3)
  - Verdict distribution (when flagged): "not_an_error": 1 -> caught 100.0% (1/1)
  - Category distribution: "(none)": 1
  - Corrected-phrase distribution: "ordenador": 1
  - Occurrence distribution: "1": 1

#### Run detail

- Run 1: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 2: clean — no Stage 2 call
- Run 3: clean — no Stage 2 call

### coche

- Text: `Aparqué el coche cerca de la oficina.`
- Note: Kept clean by Stage 1 in prior harness runs — if the live dialect variant ever does flag it here, confirms Stage 2 still doesn't call it an error.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 0.0% (0/3) (clean: 100.0% (3/3))
- Flagged span distribution: "(clean)": 3
- Hard expectation ("coche"):
  - Flagged by Stage 1: 0.0% (0/3)
  - Verdict distribution (when flagged): (none) -> caught 0.0% (0/0)
  - Category distribution: (none)
  - Corrected-phrase distribution: (none)
  - Occurrence distribution: (none)

#### Run detail

- Run 1: clean — no Stage 2 call
- Run 2: clean — no Stage 2 call
- Run 3: clean — no Stage 2 call

### carro

- Text: `Lavé el carro el fin de semana.`
- Note: The other side of the coche/carro/auto split — same check.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 0.0% (0/3) (clean: 100.0% (3/3))
- Flagged span distribution: "(clean)": 3
- Hard expectation ("carro"):
  - Flagged by Stage 1: 0.0% (0/3)
  - Verdict distribution (when flagged): (none) -> caught 0.0% (0/0)
  - Category distribution: (none)
  - Corrected-phrase distribution: (none)
  - Occurrence distribution: (none)

#### Run detail

- Run 1: clean — no Stage 2 call
- Run 2: clean — no Stage 2 call
- Run 3: clean — no Stage 2 call

## Omissions (corrected_phrase diff-usability — observational)

### ST-O1

- Text: `Como estas hoy?`
- Note: Missing opening "¿". No hard expectation — Stage 1 quotes around the gap (or doesn't), and the run detail shows whether Stage 2's corrected_phrase reinstates the missing mark.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (3/3) (clean: 0.0% (0/3))
- Flagged span distribution: "Como": 1, "Como estas hoy?": 2, "estas": 1

#### Run detail

- Run 1: "Como estas hoy?" -> verdict=error, category=Grammar, occurrence=1, corrected="¿Cómo estás hoy?"
- Run 2: "Como" -> verdict=error, category=Spelling, occurrence=1, corrected="Cómo" | "estas" -> verdict=error, category=Spelling, occurrence=1, corrected="estás"
- Run 3: "Como estas hoy?" -> verdict=error, category=Spelling, occurrence=1, corrected="¿Cómo estás hoy?"

### ST-O2

- Text: `Creo está bien, pero no estoy seguro.`
- Note: Missing subordinating "que". Read the run detail for whether corrected_phrase comes back as "Creo que está bien" or similar — diff-usable — from whatever span Stage 1 actually flags live.

#### Summary (1 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (1/1) (clean: 0.0% (0/1))
- Flagged span distribution: "Creo está bien": 1

#### Run detail

- Run 1: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"

### ST-O3

- Text: `Voy la playa este fin de semana.`
- Note: Missing preposition "a" — same diff-usability read as ST-O2.

#### Summary (1 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (1/1) (clean: 0.0% (0/1))
- Flagged span distribution: "Voy la playa": 1

#### Run detail

- Run 1: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"

### ST-O4

- Text: `Que bonito es este lugar!`
- Note: Missing opening "¡" (pure omission) bundled with a real accent swap ("Que" -> "Qué"). No hard expectation here — read both off the run detail.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (3/3) (clean: 0.0% (0/3))
- Flagged span distribution: "Que bonito es este lugar!": 3

#### Run detail

- Run 1: "Que bonito es este lugar!" -> verdict=error, category=Grammar, occurrence=1, corrected="¡Qué bonito es este lugar!"
- Run 2: "Que bonito es este lugar!" -> verdict=error, category=Grammar, occurrence=1, corrected="¡Qué bonito es este lugar!"
- Run 3: "Que bonito es este lugar!" -> verdict=error, category=Grammar, occurrence=1, corrected="¡Qué bonito es este lugar!"

## Redundancy (messy-span handoff — the key integration risk, observational)

### ES-6

- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`
- Note: THE key integration risk. Stage 1 has been observed flagging anything from a clean single "yo" to the entire clause, or a fragment like ", y". No hard expectation — the run detail records exactly what span Stage 1 hands off and exactly what Stage 2 does with it (sane correction, empty/garbage one, or a parse failure).

#### Summary (10 runs, 1 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 77.8% (7/9) (clean: 22.2% (2/9))
- Flagged span distribution: "(clean)": 2, "Yo fui a casa, yo estudié, y yo hice la cena": 3, "Yo fui a casa, yo estudié, y yo hice la cena.": 2, "estudié, y": 1, "yo estudié, y yo hice la cena": 1

#### Run detail

- Run 1: clean — no Stage 2 call
- Run 2: "yo estudié, y yo hice la cena" -> verdict=error, category=Grammar, occurrence=1, corrected="yo estudié y yo hice la cena"
- Run 3: "Yo fui a casa, yo estudié, y yo hice la cena." -> verdict=error, category=Natural Language, occurrence=1, corrected="Fui a casa, estudié e hice la cena."
- Run 4: "Yo fui a casa, yo estudié, y yo hice la cena" -> verdict=error, category=Natural Language, occurrence=1, corrected="Fui a casa, estudié e hice la cena"
- Run 5: STAGE1 ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 6: "Yo fui a casa, yo estudié, y yo hice la cena" -> verdict=error, category=Grammar, occurrence=1, corrected="Fui a casa, estudié e hice la cena"
- Run 7: "Yo fui a casa, yo estudié, y yo hice la cena" -> verdict=error, category=Natural Language, occurrence=1, corrected="Fui a casa, estudié e hice la cena"
- Run 8: "estudié, y" -> verdict=error, category=Grammar, occurrence=1, corrected="estudié y"
- Run 9: clean — no Stage 2 call
- Run 10: "Yo fui a casa, yo estudié, y yo hice la cena." -> verdict=error, category=Natural Language, occurrence=1, corrected="Fui a casa, estudié e hice la cena."

### ST-R2

- Text: `Nosotros vamos al cine, nosotros comemos palomitas y nosotros volvemos a casa.`
- Note: Same class and same reason as ES-6 — second messy-span example.

#### Summary (10 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 0.0% (0/10) (clean: 100.0% (10/10))
- Flagged span distribution: "(clean)": 10

#### Run detail

- Run 1: clean — no Stage 2 call
- Run 2: clean — no Stage 2 call
- Run 3: clean — no Stage 2 call
- Run 4: clean — no Stage 2 call
- Run 5: clean — no Stage 2 call
- Run 6: clean — no Stage 2 call
- Run 7: clean — no Stage 2 call
- Run 8: clean — no Stage 2 call
- Run 9: clean — no Stage 2 call
- Run 10: clean — no Stage 2 call

## Cross-language tiebreak (observational)

### PT-2

- Text: `Eu gosto de ir a praia nos fins de semana.`
- Note: Portuguese text through the Spanish-only prompts, deliberately — the docs/correction_consistency_harness.md PT-2 tiebreak case. No hard expectation; read the run detail for what the live chain actually does end to end.

#### Summary (3 runs, 0 Stage 1 error(s), 0 Stage 2 error(s))

- Stage 1 flag rate: 100.0% (3/3) (clean: 0.0% (0/3))
- Flagged span distribution: "Eu gosto de ir a praia nos fins de semana.": 2, "ir a praia": 1

#### Run detail

- Run 1: "ir a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="ir à praia"
- Run 2: "Eu gosto de ir a praia nos fins de semana." -> verdict=error, category=Grammar, occurrence=1, corrected="Eu gosto de ir à praia nos fins de semana."
- Run 3: "Eu gosto de ir a praia nos fins de semana." -> verdict=error, category=Other, occurrence=1, corrected="Me gusta ir a la playa los fines de semana."

---

## Overall summary

| Sentence | Runs | Stage1 errors | Stage2 errors | Stage 1 flag rate | Hard-expectation caught rate(s) |
| --- | --- | --- | --- | --- | --- |
| ES-1 | 1 | 0 | 0 | 100.0% (1/1) | 0.0% (0/1) |
| ES-3 | 1 | 0 | 0 | 100.0% (1/1) | 100.0% (1/1), 100.0% (1/1) |
| ES-4 | 1 | 0 | 0 | 100.0% (1/1) | 100.0% (1/1), 100.0% (1/1) |
| ES-5 | 1 | 0 | 0 | 100.0% (1/1) | 100.0% (1/1), 100.0% (1/1), 100.0% (1/1), 100.0% (1/1) |
| ES-2 | 3 | 0 | 0 | 0.0% (0/3) | — |
| coger | 3 | 0 | 0 | 100.0% (3/3) | — |
| ordenador | 3 | 0 | 0 | 33.3% (1/3) | 100.0% (1/1) |
| coche | 3 | 0 | 0 | 0.0% (0/3) | 0.0% (0/0) |
| carro | 3 | 0 | 0 | 0.0% (0/3) | 0.0% (0/0) |
| ST-O1 | 3 | 0 | 0 | 100.0% (3/3) | — |
| ST-O2 | 1 | 0 | 0 | 100.0% (1/1) | — |
| ST-O3 | 1 | 0 | 0 | 100.0% (1/1) | — |
| ST-O4 | 3 | 0 | 0 | 100.0% (3/3) | — |
| ES-6 | 10 | 1 | 0 | 77.8% (7/9) | — |
| ST-R2 | 10 | 0 | 0 | 0.0% (0/10) | — |
| PT-2 | 3 | 0 | 0 | 100.0% (3/3) | — |
