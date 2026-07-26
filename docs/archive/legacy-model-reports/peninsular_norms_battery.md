# Peninsular Norms Transfer Battery

Model: `gpt-5.5`  
Commit: `fb1276283fe9e437ca62aaa384f069ee627fc8a1`  
Generated: 2026-07-21T12:09:47.141943  
Runs per case: 5

## Para + destination

### PD-anchor (Anchor)

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrase: "volví para casa"
- Note: Same text as ES-1 in stage2_categorization_harness.dart, reused verbatim as the anchor for continuity with the already-measured baseline (30% verdict convergence live, per docs/stage2_categorization_harness.md).

#### Summary (5 runs, 1 error(s))

- Verdict distribution: dialectal: 1, error: 1, not_an_error: 2 -> convergence 50.0% (2/4)
- Category distribution: : 1, (none): 1, Natural Language: 1, Other: 1 -> convergence 25.0% (1/4)

#### Run detail

- Run 1: verdict=dialectal, category=Other
- Run 2: verdict=error, category=Natural Language
- Run 3: verdict=not_an_error, category=
- Run 4: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 5: verdict=not_an_error, category=(none)

### PD-T1 (Transfer)

- Text: `Ya era tarde cuando vine para casa.`
- Flagged phrase: "vine para casa"
- Note: Same "para + destination" construction, different verb.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### PD-T2 (Transfer)

- Text: `Subió para la oficina en cuanto llegó.`
- Flagged phrase: "Subió para la oficina"
- Note: Same construction, different destination and verb.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: dialectal: 1, error: 4 -> convergence 80.0% (4/5)
- Category distribution: Grammar: 4, Other: 1 -> convergence 80.0% (4/5)

#### Run detail

- Run 1: verdict=error, category=Grammar
- Run 2: verdict=error, category=Grammar
- Run 3: verdict=error, category=Grammar
- Run 4: verdict=dialectal, category=Other
- Run 5: verdict=error, category=Grammar

### PD-T3 (Transfer)

- Text: `Al terminar el partido, regresamos para el pueblo.`
- Flagged phrase: "regresamos para el pueblo"
- Note: Same construction, different destination and verb.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: dialectal: 2, error: 2, not_an_error: 1 -> convergence 40.0% (2/5)
- Category distribution: (none): 1, Grammar: 2, Other: 2 -> convergence 40.0% (2/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=error, category=Grammar
- Run 3: verdict=dialectal, category=Other
- Run 4: verdict=dialectal, category=Other
- Run 5: verdict=error, category=Grammar

### PD-neg (Negative)

- Text: `Ya era tarde cuando volví a casa.`
- Flagged phrase: "volví a casa"
- Note: The accepted Peninsular form of the anchor construction (its own corrected_phrase). Must not be flagged at all.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

## Coger-type vocabulary

### COG-anchor (Anchor)

- Text: `Voy a coger el autobús para ir al centro.`
- Flagged phrase: "coger el autobús"
- Note: Same text as the "coger" case in stage2_categorization_harness.dart — the canonical dialectal case (100% convergence live).

#### Summary (5 runs, 0 error(s))

- Verdict distribution: dialectal: 5 -> convergence 100.0% (5/5)
- Category distribution: Other: 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=dialectal, category=Other
- Run 2: verdict=dialectal, category=Other
- Run 3: verdict=dialectal, category=Other
- Run 4: verdict=dialectal, category=Other
- Run 5: verdict=dialectal, category=Other

### COG-T1 (Transfer)

- Text: `Espera, voy a coger las llaves antes de salir.`
- Flagged phrase: "coger las llaves"
- Note: Same coger-is-vulgar-in-parts-of-Latin-America split, different object.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: dialectal: 5 -> convergence 100.0% (5/5)
- Category distribution: Other: 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=dialectal, category=Other
- Run 2: verdict=dialectal, category=Other
- Run 3: verdict=dialectal, category=Other
- Run 4: verdict=dialectal, category=Other
- Run 5: verdict=dialectal, category=Other

### COG-T2 (Transfer)

- Text: `Vamos a coger un taxi para llegar antes.`
- Flagged phrase: "coger un taxi"
- Note: Same split, different vehicle.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: dialectal: 5 -> convergence 100.0% (5/5)
- Category distribution: Other: 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=dialectal, category=Other
- Run 2: verdict=dialectal, category=Other
- Run 3: verdict=dialectal, category=Other
- Run 4: verdict=dialectal, category=Other
- Run 5: verdict=dialectal, category=Other

### COG-T3 (Transfer)

- Text: `Con esta lluvia vas a coger frío.`
- Flagged phrase: "coger frío"
- Note: Same split, idiomatic non-transport use of "coger".

#### Summary (5 runs, 0 error(s))

- Verdict distribution: dialectal: 5 -> convergence 100.0% (5/5)
- Category distribution: Other: 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=dialectal, category=Other
- Run 2: verdict=dialectal, category=Other
- Run 3: verdict=dialectal, category=Other
- Run 4: verdict=dialectal, category=Other
- Run 5: verdict=dialectal, category=Other

### COG-neg (Negative)

- Text: `Vamos a tomar el autobús para ir al centro.`
- Flagged phrase: "tomar el autobús"
- Note: Mirrors PD-neg: reuses the pan-dialectal accepted form (the anchor's own corrected_phrase) rather than a same-verb-different-context "coger" sentence. In the varieties where "coger" is taboo, the stigma generally attaches to the verb itself, not to specific senses of it — so a "coger + [some other object]" negative (e.g. "coger un libro de la mesa") would not reliably test anything; it could just as easily read as another instance of the same split. "Tomar el autobús" is accepted everywhere, so a flag on it is an unambiguous overcorrection signal.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

## Ordinary regional vocabulary pairs

### VOC-anchor-ordenador (Anchor)

- Text: `Voy a usar el ordenador en la oficina.`
- Flagged phrase: "ordenador"
- Note: Same text as the "ordenador" case in stage2_categorization_harness.dart.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### VOC-anchor-coche (Anchor)

- Text: `Aparqué el coche cerca de la oficina.`
- Flagged phrase: "coche"
- Note: Same text as the "coche" case in stage2_categorization_harness.dart.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### VOC-anchor-carro (Anchor)

- Text: `Lavé el carro el fin de semana.`
- Flagged phrase: "carro"
- Note: Same text as the "carro" case in stage2_categorization_harness.dart.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### VOC-T1-gafas (Transfer)

- Text: `No veo bien sin mis gafas.`
- Flagged phrase: "gafas"
- Note: Same ordinary-regional-pair shape: gafas (Spain) / lentes (Latin America).

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### VOC-T2-movil (Transfer)

- Text: `Se me quedó el móvil en casa.`
- Flagged phrase: "móvil"
- Note: móvil (Spain) / celular (Latin America).

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### VOC-T3-piso (Transfer)

- Text: `Alquilamos un piso cerca del centro.`
- Flagged phrase: "piso"
- Note: piso (Spain) / apartamento (Latin America).

#### Summary (5 runs, 0 error(s))

- Verdict distribution: dialectal: 4, not_an_error: 1 -> convergence 80.0% (4/5)
- Category distribution: (none): 1, Other: 4 -> convergence 80.0% (4/5)

#### Run detail

- Run 1: verdict=dialectal, category=Other
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=dialectal, category=Other
- Run 4: verdict=dialectal, category=Other
- Run 5: verdict=dialectal, category=Other

### VOC-neg-libreria (Negative)

- Text: `Fui a la librería a devolver el libro que pedí prestado.`
- Flagged phrase: "librería"
- Note: Looks like a regional-pair candidate but is a genuine false-friend error in every variety — no established dialect uses "librería" to mean "library" (it means "bookstore" everywhere; "biblioteca" is library everywhere). Must come back as error, not dialectal/not_an_error.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: error: 5 -> convergence 100.0% (5/5)
- Category distribution: Word Choice: 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=error, category=Word Choice
- Run 2: verdict=error, category=Word Choice
- Run 3: verdict=error, category=Word Choice
- Run 4: verdict=error, category=Word Choice
- Run 5: verdict=error, category=Word Choice

## Soft-register / circumlocution (BP-001-style)

### SR-anchor (Anchor)

- Text: `En el gimnasio hay una máquina de correr nueva.`
- Flagged phrase: "máquina de correr"
- Note: The Portuguese prompt has a dedicated soft-register bullet (_ptSoftRegisterBullet) built around exactly this phrase ("máquina de correr" -> "esteira"); stage2CategorizationSpanish has no Spanish equivalent bullet. This family tests whether the existing calque/Natural Language machinery catches the same kind of issue in Spanish ("máquina de correr" -> "cinta de correr") without one.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### SR-T1 (Transfer)

- Text: `Compramos una máquina de lavar la ropa.`
- Flagged phrase: "máquina de lavar la ropa"
- Note: Same circumlocution-for-an-everyday-appliance shape, vs. "lavadora".

#### Summary (5 runs, 1 error(s))

- Verdict distribution: error: 3, not_an_error: 1 -> convergence 75.0% (3/4)
- Category distribution: (none): 1, Natural Language: 3 -> convergence 75.0% (3/4)

#### Run detail

- Run 1: verdict=error, category=Natural Language
- Run 2: verdict=error, category=Natural Language
- Run 3: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=error, category=Natural Language

### SR-T2 (Transfer)

- Text: `Necesito un aparato para calentar la comida.`
- Flagged phrase: "aparato para calentar la comida"
- Note: Same shape, vs. "microondas".

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

### SR-neg (Negative)

- Text: `Puse el aire acondicionado porque hacía calor.`
- Flagged phrase: "aire acondicionado"
- Note: "Aire acondicionado" is itself the standard idiomatic phrase — there is no shorter single-word native term to prefer instead. Flagging it as an overly wordy circumlocution would be overcorrection.

#### Summary (5 runs, 0 error(s))

- Verdict distribution: not_an_error: 5 -> convergence 100.0% (5/5)
- Category distribution: (none): 5 -> convergence 100.0% (5/5)

#### Run detail

- Run 1: verdict=not_an_error, category=(none)
- Run 2: verdict=not_an_error, category=(none)
- Run 3: verdict=not_an_error, category=(none)
- Run 4: verdict=not_an_error, category=(none)
- Run 5: verdict=not_an_error, category=(none)

---

## Family convergence summary

| Construction family | Anchor convergence (verdict) | Transfer convergence (avg) | Negative convergence | Anchor→Transfer gap |
| --- | --- | --- | --- | --- |
| Para + destination | 50.0% | 73.3% | 100.0% | -23.3 pts |
| Coger-type vocabulary | 100.0% | 100.0% | 100.0% | 0.0 pts |
| Ordinary regional vocabulary pairs | 100.0% | 93.3% | 100.0% | 6.7 pts |
| Soft-register / circumlocution (BP-001-style) | 100.0% | 87.5% | 100.0% | 12.5 pts |
