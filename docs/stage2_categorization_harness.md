# Stage 2 Categorization Harness

Model: `gpt-5.5`  
Commit: `fb1276283fe9e437ca62aaa384f069ee627fc8a1`  
Generated: 2026-07-21T11:03:10.943214  
Runs per case: 10

## Core (swap-type, from the validated Stage 1 targets)

### ES-1

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrases: ["volví para casa"]
- Note: "para" -> "a" is a preposition fix: Grammar, not Spelling.

#### Summary (10 runs, 0 error(s))

- Target 1 ("volví para casa"):
  - Verdict distribution: dialectal: 3, error: 3, not_an_error: 4 (accepted: error) -> 30.0% (3/10)
  - Category distribution: : 1, (none): 3, Grammar: 3, Other: 3 (expected Grammar) -> 30.0% (3/10)
  - Corrected-phrase distribution: volví a casa: 6, volví para casa: 4 (expected "volví a casa") -> 60.0% (6/10)
  - Occurrence distribution: 1: 10 (expected 1) -> 100.0% (10/10)
- Fully caught (every scored dimension in one run): 30.0% (3/10)

#### Run detail

- Run 1: "volví para casa" -> verdict=dialectal, category=Other, occurrence=1, corrected="volví a casa"
- Run 2: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 3: "volví para casa" -> verdict=error, category=Grammar, occurrence=1, corrected="volví a casa"
- Run 4: "volví para casa" -> verdict=error, category=Grammar, occurrence=1, corrected="volví a casa"
- Run 5: "volví para casa" -> verdict=dialectal, category=Other, occurrence=1, corrected="volví a casa"
- Run 6: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 7: "volví para casa" -> verdict=error, category=Grammar, occurrence=1, corrected="volví a casa"
- Run 8: "volví para casa" -> verdict=not_an_error, category=, occurrence=1, corrected="volví para casa"
- Run 9: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 10: "volví para casa" -> verdict=dialectal, category=Other, occurrence=1, corrected="volví a casa"

### ES-3

- Text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`
- Flagged phrases: ["trafico","llamaron para atrás"]
- Note: Two independent targets in one case: a missing-accent Spelling fix and a calque Natural Language fix.

#### Summary (10 runs, 0 error(s))

- Target 1 ("trafico"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Spelling: 10 (expected Spelling) -> 100.0% (10/10)
  - Corrected-phrase distribution: tráfico: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Target 2 ("llamaron para atrás"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Natural Language: 10 (expected Natural Language) -> 100.0% (10/10)
  - Corrected-phrase distribution: devolvieron la llamada: 5, volvieron a llamar: 5 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 2: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 3: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"
- Run 4: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"
- Run 5: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"
- Run 6: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 7: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 8: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 9: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"
- Run 10: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"

### ES-4

- Text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`
- Flagged phrases: ["pasar un buen tiempo"]
- Note: Calque -> idiomatic restructure: Natural Language.

#### Summary (10 runs, 0 error(s))

- Target 1 ("pasar un buen tiempo"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Natural Language: 10 (expected Natural Language) -> 100.0% (10/10)
  - Corrected-phrase distribution: pasar un buen rato: 6, pasarlo bien: 4 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 2: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
- Run 3: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 4: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
- Run 5: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
- Run 6: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 7: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 8: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 9: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 10: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"

### ES-5

- Text: `Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.`
- Flagged phrases: ["Espana","anos","cumpleanos","otono"]
- Note: Four independent missing-accent targets, all plain Spelling.

#### Summary (10 runs, 0 error(s))

- Target 1 ("Espana"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Spelling: 10 (expected Spelling) -> 100.0% (10/10)
  - Corrected-phrase distribution: España: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Target 2 ("anos"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Spelling: 10 (expected Spelling) -> 100.0% (10/10)
  - Corrected-phrase distribution: años: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Target 3 ("cumpleanos"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Spelling: 10 (expected Spelling) -> 100.0% (10/10)
  - Corrected-phrase distribution: años: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Target 4 ("otono"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Spelling: 10 (expected Spelling) -> 100.0% (10/10)
  - Corrected-phrase distribution: otoño: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 2: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 3: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 4: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 5: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 6: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 7: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 8: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 9: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"
- Run 10: "Espana" -> verdict=error, category=Spelling, occurrence=1, corrected="España" | "anos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "cumpleanos" -> verdict=error, category=Spelling, occurrence=1, corrected="años" | "otono" -> verdict=error, category=Spelling, occurrence=1, corrected="otoño"

### ES-6

- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`
- Flagged phrases: ["yo"]
- Note: Category-stability check for the redundant-pronoun boundary rule — the live bug this case guards against: a redundant "yo" repeated across clauses genuinely fits both Grammar's pronoun-use clause and Natural Language's "unnatural combination of otherwise-acceptable words," and without an explicit tiebreak the category flip-flopped between runs. The boundary rule exists specifically so this converges to Natural Language, not Grammar — that convergence is what's under test. corrected_phrase is expected empty (a pure deletion), and verdict must stay error throughout.

#### Summary (10 runs, 1 error(s))

- Target 1 ("yo"):
  - Verdict distribution: error: 9 (accepted: error) -> 100.0% (9/9)
  - Category distribution: Natural Language: 9 (expected Natural Language) -> 100.0% (9/9)
  - Corrected-phrase distribution: : 9 (expected "") -> 100.0% (9/9)
  - Occurrence distribution: 1: 9 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (9/9)

#### Run detail

- Run 1: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 2: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 3: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 4: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 5: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 6: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 7: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 8: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 9: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""
- Run 10: "yo" -> verdict=error, category=Natural Language, occurrence=1, corrected=""

## Occurrence gating case

### ES-1-occurrence

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrases: ["para"]
- Note: Same text as ES-1, but the flagged phrase is the bare, ambiguous "para" (appears 3 times: before "comprar", before "casa", before "preparar") to force disambiguation. The intended instance is the 2nd ("para casa" -> "a casa") — the other two are correctly used. THE KEY RESULT is whether occurrence comes back as 2; category and corrected_phrase are recorded but not scored here.

#### Summary (10 runs, 3 error(s))

- Target 1 ("para"):
  - Verdict distribution: dialectal: 1, error: 4, not_an_error: 2 (accepted: error) -> 57.1% (4/7)
  - Category distribution: : 1, (none): 1, Grammar: 4, Other: 1 (not scored)
  - Corrected-phrase distribution: a: 5, para: 2 (not scored)
  - Occurrence distribution: 2: 7 (expected 2) -> 100.0% (7/7)
- Fully caught (every scored dimension in one run): 57.1% (4/7)

#### Run detail

- Run 1: "para" -> verdict=dialectal, category=Other, occurrence=2, corrected="a"
- Run 2: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 3: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"
- Run 4: "para" -> verdict=not_an_error, category=(none), occurrence=2, corrected="para"
- Run 5: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"
- Run 6: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 7: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"
- Run 8: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"
- Run 9: "para" -> verdict=not_an_error, category=, occurrence=2, corrected="para"
- Run 10: ERROR — TimeoutException after 0:00:30.000000: Future not completed

## Dialectal

### ES-2

- Text: `Cuando termino el trabajo, voy para casa en autobús.`
- Flagged phrases: ["voy para casa"]
- Note: "voy para casa" is standard in much of Latin America. Must NOT come back as error. Record which of dialectal/not_an_error it actually returns.

#### Summary (10 runs, 0 error(s))

- Target 1 ("voy para casa"):
  - Verdict distribution: not_an_error: 10 (accepted: dialectal/not_an_error) -> 100.0% (10/10)
  - Category distribution: (none): 10 (not scored)
  - Corrected-phrase distribution: voy para casa: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 2: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 3: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 4: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 5: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 6: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 7: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 8: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 9: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"
- Run 10: "voy para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="voy para casa"

### coger

- Text: `Voy a coger el autobús para ir al centro.`
- Flagged phrases: ["coger el autobús"]
- Note: Standard in Spain, vulgar in much of Latin America — the canonical dialectal case. category must be Other per the prompt's own rule for dialectal verdicts.

#### Summary (10 runs, 0 error(s))

- Target 1 ("coger el autobús"):
  - Verdict distribution: dialectal: 10 (accepted: dialectal) -> 100.0% (10/10)
  - Category distribution: Other: 10 (expected Other) -> 100.0% (10/10)
  - Corrected-phrase distribution: tomar el autobús: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 2: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 3: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 4: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 5: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 6: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 7: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 8: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 9: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"
- Run 10: "coger el autobús" -> verdict=dialectal, category=Other, occurrence=1, corrected="tomar el autobús"

## Ordinary regional vocabulary — must not be error

### ordenador

- Text: `Voy a usar el ordenador en la oficina.`
- Flagged phrases: ["ordenador"]
- Note: The specific case Stage 1's dialect variant surfaced (flagged 2/10 by stage1DetectionDialectSpanish, per docs/stage1_detection_dialect_harness.md) but had never been run through Stage 2. "ordenador" (Spain) vs. "computadora" (Latin America) is ordinary regional vocabulary — must not come back as error. Record which of dialectal/not_an_error it returns, plus category and corrected_phrase.

#### Summary (10 runs, 0 error(s))

- Target 1 ("ordenador"):
  - Verdict distribution: not_an_error: 10 (accepted: dialectal/not_an_error) -> 100.0% (10/10)
  - Category distribution: (none): 10 (not scored)
  - Corrected-phrase distribution: ordenador: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 2: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 3: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 4: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 5: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 6: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 7: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 8: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 9: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"
- Run 10: "ordenador" -> verdict=not_an_error, category=(none), occurrence=1, corrected="ordenador"

### coche

- Text: `Aparqué el coche cerca de la oficina.`
- Flagged phrases: ["coche"]
- Note: The case Stage 1 kept clean in both the base and dialect-variant harnesses (never actually surfaced to Stage 2 in practice) — confirms Stage 2 agrees it is not an error, if it were ever fed this phrase.

#### Summary (10 runs, 0 error(s))

- Target 1 ("coche"):
  - Verdict distribution: not_an_error: 10 (accepted: dialectal/not_an_error) -> 100.0% (10/10)
  - Category distribution: (none): 10 (not scored)
  - Corrected-phrase distribution: coche: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 2: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 3: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 4: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 5: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 6: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 7: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 8: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 9: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"
- Run 10: "coche" -> verdict=not_an_error, category=(none), occurrence=1, corrected="coche"

### carro

- Text: `Lavé el carro el fin de semana.`
- Flagged phrases: ["carro"]
- Note: The other side of the coche/carro/auto split — same check.

#### Summary (10 runs, 0 error(s))

- Target 1 ("carro"):
  - Verdict distribution: not_an_error: 10 (accepted: dialectal/not_an_error) -> 100.0% (10/10)
  - Category distribution: (none): 10 (not scored)
  - Corrected-phrase distribution: carro: 10 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 2: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 3: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 4: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 5: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 6: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 7: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 8: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 9: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"
- Run 10: "carro" -> verdict=not_an_error, category=(none), occurrence=1, corrected="carro"

## Omission (corrected_phrase diff-usability)

### ST-O2

- Text: `Creo está bien, pero no estoy seguro.`
- Flagged phrases: ["Creo está bien"]
- Note: Missing subordinating "que". The point is whether corrected_phrase comes back diff-usable ("Creo que está bien") — that's what code would diff against the original to find the insertion.

#### Summary (10 runs, 9 error(s))

- Target 1 ("Creo está bien"):
  - Verdict distribution: error: 1 (accepted: error) -> 100.0% (1/1)
  - Category distribution: Grammar: 1 (not scored)
  - Corrected-phrase distribution: Creo que está bien: 1 (expected "Creo que está bien") -> 100.0% (1/1)
  - Occurrence distribution: 1: 1 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (1/1)

#### Run detail

- Run 1: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 2: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 3: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 4: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 5: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 6: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 7: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 8: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 9: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 10: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}


### ST-O3

- Text: `Voy la playa este fin de semana.`
- Flagged phrases: ["Voy la playa"]
- Note: Missing preposition "a" — same diff-usability check as ST-O2.

#### Summary (10 runs, 10 error(s))

- Target 1 ("Voy la playa"):
  - Verdict distribution: (none) (accepted: error) -> 0.0% (0/0)
  - Category distribution: (none) (not scored)
  - Corrected-phrase distribution: (none) (expected "Voy a la playa") -> 0.0% (0/0)
  - Occurrence distribution: (none) (not scored)
- Fully caught (every scored dimension in one run): 0.0% (0/0)

#### Run detail

- Run 1: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 2: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 3: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 4: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 5: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 6: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 7: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 8: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 9: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 10: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}


## Cross-language category-stability check (PT-2)

### PT-2

- Text: `Eu gosto de ir a praia nos fins de semana.`
- Flagged phrases: ["a praia"]
- Note: Portuguese text run through the Spanish-only stage2CategorizationSpanish prompt deliberately — this is the tiebreak case from docs/correction_consistency_harness.md's PT-2 (60% catch rate, split Grammar/Spelling under the app's current single-call prompt). The preposition-plus-article-contraction boundary rule exists specifically so this converges to Grammar, not Spelling — that convergence is what's under test, not general PT support.

#### Summary (10 runs, 10 error(s))

- Target 1 ("a praia"):
  - Verdict distribution: (none) (accepted: error) -> 0.0% (0/0)
  - Category distribution: (none) (expected Grammar) -> 0.0% (0/0)
  - Corrected-phrase distribution: (none) (expected "à praia") -> 0.0% (0/0)
  - Occurrence distribution: (none) (not scored)
- Fully caught (every scored dimension in one run): 0.0% (0/0)

#### Run detail

- Run 1: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 2: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 3: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 4: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 5: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 6: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 7: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 8: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 9: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}

- Run 10: ERROR — Exception: Chat completions call failed with HTTP 429: {
    "error": {
        "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, read the docs: https://platform.openai.com/docs/guides/error-codes/api-errors.",
        "type": "insufficient_quota",
        "param": null,
        "code": "insufficient_quota"
    }
}


---

## Overall summary

| Case | Runs | Errors | Headline rate | Per-target verdict rates |
| --- | --- | --- | --- | --- |
| ES-1 | 10 | 0 | 30.0% (3/10) (fully caught) | 30.0% (3/10) |
| ES-3 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10) |
| ES-4 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ES-5 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10), 100.0% (10/10), 100.0% (10/10) |
| ES-6 | 10 | 1 | 100.0% (9/9) (fully caught) | 100.0% (9/9) |
| ES-1-occurrence | 10 | 3 | 57.1% (4/7) (fully caught) | 57.1% (4/7) |
| ES-2 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| coger | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ordenador | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| coche | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| carro | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ST-O2 | 10 | 9 | 100.0% (1/1) (fully caught) | 100.0% (1/1) |
| ST-O3 | 10 | 10 | 0.0% (0/0) (fully caught) | 0.0% (0/0) |
| PT-2 | 10 | 10 | 0.0% (0/0) (fully caught) | 0.0% (0/0) |
