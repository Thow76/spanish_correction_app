# Stage 2 Categorization Harness

Model: `gpt-5.5`  
Commit: `e370e9fa8f22c96f32927b55cd22eb1987416c32`  
Generated: 2026-07-18T21:56:15.265271  
Runs per case: 10

## Core (swap-type, from the validated Stage 1 targets)

### ES-1

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrases: ["volví para casa"]
- Note: "para" -> "a" is a preposition fix: Grammar, not Spelling.

#### Summary (10 runs, 0 error(s))

- Target 1 ("volví para casa"):
  - Verdict distribution: dialectal: 3, not_an_error: 7 (accepted: error) -> 0.0% (0/10)
  - Category distribution: : 1, (none): 6, Other: 3 (expected Grammar) -> 0.0% (0/10)
  - Corrected-phrase distribution: volví a casa: 3, volví para casa: 7 (expected "volví a casa") -> 30.0% (3/10)
  - Occurrence distribution: 1: 10 (expected 1) -> 100.0% (10/10)
- Fully caught (every scored dimension in one run): 0.0% (0/10)

#### Run detail

- Run 1: "volví para casa" -> verdict=dialectal, category=Other, occurrence=1, corrected="volví a casa"
- Run 2: "volví para casa" -> verdict=not_an_error, category=, occurrence=1, corrected="volví para casa"
- Run 3: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 4: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 5: "volví para casa" -> verdict=dialectal, category=Other, occurrence=1, corrected="volví a casa"
- Run 6: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 7: "volví para casa" -> verdict=dialectal, category=Other, occurrence=1, corrected="volví a casa"
- Run 8: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 9: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"
- Run 10: "volví para casa" -> verdict=not_an_error, category=(none), occurrence=1, corrected="volví para casa"

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
  - Verdict distribution: dialectal: 1, error: 9 (accepted: error) -> 90.0% (9/10)
  - Category distribution: Natural Language: 9, Other: 1 (expected Natural Language) -> 90.0% (9/10)
  - Corrected-phrase distribution: devolvieron la llamada: 6, volvieron a llamar: 4 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 90.0% (9/10)

#### Run detail

- Run 1: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 2: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 3: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 4: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"
- Run 5: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=dialectal, category=Other, occurrence=1, corrected="devolvieron la llamada"
- Run 6: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"
- Run 7: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="volvieron a llamar"
- Run 8: "trafico" -> verdict=error, category=Spelling, occurrence=1, corrected="tráfico" | "llamaron para atrás" -> verdict=error, category=Natural Language, occurrence=1, corrected="devolvieron la llamada"
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
  - Corrected-phrase distribution: pasar un buen rato: 4, pasarlo bien: 6 (not scored)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
- Run 2: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
- Run 3: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 4: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasar un buen rato"
- Run 5: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
- Run 6: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
- Run 7: "pasar un buen tiempo" -> verdict=error, category=Natural Language, occurrence=1, corrected="pasarlo bien"
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

## Occurrence gating case

### ES-1-occurrence

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrases: ["para"]
- Note: Same text as ES-1, but the flagged phrase is the bare, ambiguous "para" (appears 3 times: before "comprar", before "casa", before "preparar") to force disambiguation. The intended instance is the 2nd ("para casa" -> "a casa") — the other two are correctly used. THE KEY RESULT is whether occurrence comes back as 2; category and corrected_phrase are recorded but not scored here.

#### Summary (10 runs, 0 error(s))

- Target 1 ("para"):
  - Verdict distribution: dialectal: 1, error: 4, not_an_error: 5 (accepted: error) -> 40.0% (4/10)
  - Category distribution: (none): 5, Grammar: 4, Other: 1 (not scored)
  - Corrected-phrase distribution: a: 5, para: 5 (not scored)
  - Occurrence distribution: 2: 10 (expected 2) -> 100.0% (10/10)
- Fully caught (every scored dimension in one run): 40.0% (4/10)

#### Run detail

- Run 1: "para" -> verdict=not_an_error, category=(none), occurrence=2, corrected="para"
- Run 2: "para" -> verdict=not_an_error, category=(none), occurrence=2, corrected="para"
- Run 3: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"
- Run 4: "para" -> verdict=not_an_error, category=(none), occurrence=2, corrected="para"
- Run 5: "para" -> verdict=not_an_error, category=(none), occurrence=2, corrected="para"
- Run 6: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"
- Run 7: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"
- Run 8: "para" -> verdict=not_an_error, category=(none), occurrence=2, corrected="para"
- Run 9: "para" -> verdict=dialectal, category=Other, occurrence=2, corrected="a"
- Run 10: "para" -> verdict=error, category=Grammar, occurrence=2, corrected="a"

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

#### Summary (10 runs, 0 error(s))

- Target 1 ("Creo está bien"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Grammar: 10 (not scored)
  - Corrected-phrase distribution: Creo que está bien: 10 (expected "Creo que está bien") -> 100.0% (10/10)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 2: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 3: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 4: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 5: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 6: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 7: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 8: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 9: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"
- Run 10: "Creo está bien" -> verdict=error, category=Grammar, occurrence=1, corrected="Creo que está bien"

### ST-O3

- Text: `Voy la playa este fin de semana.`
- Flagged phrases: ["Voy la playa"]
- Note: Missing preposition "a" — same diff-usability check as ST-O2.

#### Summary (10 runs, 0 error(s))

- Target 1 ("Voy la playa"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Grammar: 10 (not scored)
  - Corrected-phrase distribution: Voy a la playa: 10 (expected "Voy a la playa") -> 100.0% (10/10)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 100.0% (10/10)

#### Run detail

- Run 1: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 2: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 3: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 4: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 5: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 6: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 7: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 8: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 9: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"
- Run 10: "Voy la playa" -> verdict=error, category=Grammar, occurrence=1, corrected="Voy a la playa"

## Cross-language category-stability check (PT-2)

### PT-2

- Text: `Eu gosto de ir a praia nos fins de semana.`
- Flagged phrases: ["a praia"]
- Note: Portuguese text run through the Spanish-only stage2CategorizationSpanish prompt deliberately — this is the tiebreak case from docs/correction_consistency_harness.md's PT-2 (60% catch rate, split Grammar/Spelling under the app's current single-call prompt). The preposition-plus-article-contraction boundary rule exists specifically so this converges to Grammar, not Spelling — that convergence is what's under test, not general PT support.

#### Summary (10 runs, 0 error(s))

- Target 1 ("a praia"):
  - Verdict distribution: error: 10 (accepted: error) -> 100.0% (10/10)
  - Category distribution: Grammar: 10 (expected Grammar) -> 100.0% (10/10)
  - Corrected-phrase distribution: a la playa: 1, à praia: 9 (expected "à praia") -> 90.0% (9/10)
  - Occurrence distribution: 1: 10 (not scored)
- Fully caught (every scored dimension in one run): 90.0% (9/10)

#### Run detail

- Run 1: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 2: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="a la playa"
- Run 3: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 4: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 5: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 6: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 7: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 8: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 9: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"
- Run 10: "a praia" -> verdict=error, category=Grammar, occurrence=1, corrected="à praia"

---

## Overall summary

| Case | Runs | Errors | Headline rate | Per-target verdict rates |
| --- | --- | --- | --- | --- |
| ES-1 | 10 | 0 | 0.0% (0/10) (fully caught) | 0.0% (0/10) |
| ES-3 | 10 | 0 | 90.0% (9/10) (fully caught) | 100.0% (10/10), 90.0% (9/10) |
| ES-4 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ES-5 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10), 100.0% (10/10), 100.0% (10/10) |
| ES-1-occurrence | 10 | 0 | 40.0% (4/10) (fully caught) | 40.0% (4/10) |
| ES-2 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| coger | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ordenador | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| coche | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| carro | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ST-O2 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ST-O3 | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| PT-2 | 10 | 0 | 90.0% (9/10) (fully caught) | 100.0% (10/10) |
