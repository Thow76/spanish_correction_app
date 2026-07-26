# Merged Verdict Battery

Model: `gpt-5.5`  
Commit: `fb1276283fe9e437ca62aaa384f069ee627fc8a1`  
Generated: 2026-07-21T18:02:44.886002  
Runs per case: 10

## Reused: para + destination

### PD-anchor (Anchor)

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrase: "volví para casa"
- Note: Same text as ES-1 in stage2_categorization_harness.dart, reused verbatim as the anchor for continuity with the already-measured baseline (30% verdict convergence live, per docs/stage2_categorization_harness.md).

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 1, not_an_error: 9 -> convergence 90.0% (9/10)
- Category distribution: : 2, (none): 7, Grammar: 1 -> convergence 70.0% (7/10)

#### Run detail

- Run 1: verdict=not_an_error, category=, occurrence=1
- Run 2: verdict=not_an_error, category=, occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### PD-T1 (Transfer)

- Text: `Ya era tarde cuando vine para casa.`
- Flagged phrase: "vine para casa"
- Note: Same "para + destination" construction, different verb.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 1, not_an_error: 9 -> convergence 90.0% (9/10)
- Category distribution: : 1, (none): 8, Grammar: 1 -> convergence 80.0% (8/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### PD-T2 (Transfer)

- Text: `Subió para la oficina en cuanto llegó.`
- Flagged phrase: "Subió para la oficina"
- Note: Same construction, different destination and verb.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 7, not_an_error: 3 -> convergence 70.0% (7/10)
- Category distribution: (none): 3, Grammar: 7 -> convergence 70.0% (7/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

### PD-T3 (Transfer)

- Text: `Al terminar el partido, regresamos para el pueblo.`
- Flagged phrase: "regresamos para el pueblo"
- Note: Same construction, different destination and verb.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 5, not_an_error: 5 -> convergence 50.0% (5/10)
- Category distribution: (none): 5, Grammar: 5 -> convergence 50.0% (5/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### PD-neg (Negative)

- Text: `Ya era tarde cuando volví a casa.`
- Flagged phrase: "volví a casa"
- Note: The accepted Peninsular form of the anchor construction (its own corrected_phrase). Must not be flagged at all.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

## Reused: coger-type vocabulary

### COG-anchor (Anchor)

- Text: `Voy a coger el autobús para ir al centro.`
- Flagged phrase: "coger el autobús"
- Note: Same text as the "coger" case in stage2_categorization_harness.dart — the canonical dialectal case (100% convergence live).

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 10 -> convergence 100.0% (10/10)
- Category distribution: Other: 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=dialectal, category=Other, occurrence=1
- Run 3: verdict=dialectal, category=Other, occurrence=1
- Run 4: verdict=dialectal, category=Other, occurrence=1
- Run 5: verdict=dialectal, category=Other, occurrence=1
- Run 6: verdict=dialectal, category=Other, occurrence=1
- Run 7: verdict=dialectal, category=Other, occurrence=1
- Run 8: verdict=dialectal, category=Other, occurrence=1
- Run 9: verdict=dialectal, category=Other, occurrence=1
- Run 10: verdict=dialectal, category=Other, occurrence=1

### COG-T1 (Transfer)

- Text: `Espera, voy a coger las llaves antes de salir.`
- Flagged phrase: "coger las llaves"
- Note: Same coger-is-vulgar-in-parts-of-Latin-America split, different object.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 10 -> convergence 100.0% (10/10)
- Category distribution: Other: 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=dialectal, category=Other, occurrence=1
- Run 3: verdict=dialectal, category=Other, occurrence=1
- Run 4: verdict=dialectal, category=Other, occurrence=1
- Run 5: verdict=dialectal, category=Other, occurrence=1
- Run 6: verdict=dialectal, category=Other, occurrence=1
- Run 7: verdict=dialectal, category=Other, occurrence=1
- Run 8: verdict=dialectal, category=Other, occurrence=1
- Run 9: verdict=dialectal, category=Other, occurrence=1
- Run 10: verdict=dialectal, category=Other, occurrence=1

### COG-T2 (Transfer)

- Text: `Vamos a coger un taxi para llegar antes.`
- Flagged phrase: "coger un taxi"
- Note: Same split, different vehicle.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 10 -> convergence 100.0% (10/10)
- Category distribution: Other: 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=dialectal, category=Other, occurrence=1
- Run 3: verdict=dialectal, category=Other, occurrence=1
- Run 4: verdict=dialectal, category=Other, occurrence=1
- Run 5: verdict=dialectal, category=Other, occurrence=1
- Run 6: verdict=dialectal, category=Other, occurrence=1
- Run 7: verdict=dialectal, category=Other, occurrence=1
- Run 8: verdict=dialectal, category=Other, occurrence=1
- Run 9: verdict=dialectal, category=Other, occurrence=1
- Run 10: verdict=dialectal, category=Other, occurrence=1

### COG-T3 (Transfer)

- Text: `Con esta lluvia vas a coger frío.`
- Flagged phrase: "coger frío"
- Note: Same split, idiomatic non-transport use of "coger".

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 10 -> convergence 100.0% (10/10)
- Category distribution: Other: 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=dialectal, category=Other, occurrence=1
- Run 3: verdict=dialectal, category=Other, occurrence=1
- Run 4: verdict=dialectal, category=Other, occurrence=1
- Run 5: verdict=dialectal, category=Other, occurrence=1
- Run 6: verdict=dialectal, category=Other, occurrence=1
- Run 7: verdict=dialectal, category=Other, occurrence=1
- Run 8: verdict=dialectal, category=Other, occurrence=1
- Run 9: verdict=dialectal, category=Other, occurrence=1
- Run 10: verdict=dialectal, category=Other, occurrence=1

### COG-neg (Negative)

- Text: `Vamos a tomar el autobús para ir al centro.`
- Flagged phrase: "tomar el autobús"
- Note: Mirrors PD-neg: reuses the pan-dialectal accepted form (the anchor's own corrected_phrase) rather than a same-verb-different-context "coger" sentence. In the varieties where "coger" is taboo, the stigma generally attaches to the verb itself, not to specific senses of it — so a "coger + [some other object]" negative (e.g. "coger un libro de la mesa") would not reliably test anything; it could just as easily read as another instance of the same split. "Tomar el autobús" is accepted everywhere, so a flag on it is an unambiguous overcorrection signal.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

## Reused: ordinary regional vocabulary pairs

### VOC-anchor-ordenador (Anchor)

- Text: `Voy a usar el ordenador en la oficina.`
- Flagged phrase: "ordenador"
- Note: Same text as the "ordenador" case in stage2_categorization_harness.dart.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### VOC-anchor-coche (Anchor)

- Text: `Aparqué el coche cerca de la oficina.`
- Flagged phrase: "coche"
- Note: Same text as the "coche" case in stage2_categorization_harness.dart.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### VOC-anchor-carro (Anchor)

- Text: `Lavé el carro el fin de semana.`
- Flagged phrase: "carro"
- Note: Same text as the "carro" case in stage2_categorization_harness.dart.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### VOC-T1-gafas (Transfer)

- Text: `No veo bien sin mis gafas.`
- Flagged phrase: "gafas"
- Note: Same ordinary-regional-pair shape: gafas (Spain) / lentes (Latin America).

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### VOC-T2-movil (Transfer)

- Text: `Se me quedó el móvil en casa.`
- Flagged phrase: "móvil"
- Note: móvil (Spain) / celular (Latin America).

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### VOC-T3-piso (Transfer)

- Text: `Alquilamos un piso cerca del centro.`
- Flagged phrase: "piso"
- Note: piso (Spain) / apartamento (Latin America).

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 1, not_an_error: 9 -> convergence 90.0% (9/10)
- Category distribution: (none): 9, Other: 1 -> convergence 90.0% (9/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=dialectal, category=Other, occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### VOC-neg-libreria (Negative)

- Text: `Fui a la librería a devolver el libro que pedí prestado.`
- Flagged phrase: "librería"
- Note: Looks like a regional-pair candidate but is a genuine false-friend error in every variety — no established dialect uses "librería" to mean "library" (it means "bookstore" everywhere; "biblioteca" is library everywhere). Must come back as error, not dialectal/not_an_error.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10)
- Category distribution: Word Choice: 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Word Choice, occurrence=1
- Run 2: verdict=error, category=Word Choice, occurrence=1
- Run 3: verdict=error, category=Word Choice, occurrence=1
- Run 4: verdict=error, category=Word Choice, occurrence=1
- Run 5: verdict=error, category=Word Choice, occurrence=1
- Run 6: verdict=error, category=Word Choice, occurrence=1
- Run 7: verdict=error, category=Word Choice, occurrence=1
- Run 8: verdict=error, category=Word Choice, occurrence=1
- Run 9: verdict=error, category=Word Choice, occurrence=1
- Run 10: verdict=error, category=Word Choice, occurrence=1

## Reused: soft-register / circumlocution (BP-001-style)

### SR-anchor (Anchor)

- Text: `En el gimnasio hay una máquina de correr nueva.`
- Flagged phrase: "máquina de correr"
- Note: The Portuguese prompt has a dedicated soft-register bullet (_ptSoftRegisterBullet) built around exactly this phrase ("máquina de correr" -> "esteira"); stage2CategorizationSpanish has no Spanish equivalent bullet. This family tests whether the existing calque/Natural Language machinery catches the same kind of issue in Spanish ("máquina de correr" -> "cinta de correr") without one.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### SR-T1 (Transfer)

- Text: `Compramos una máquina de lavar la ropa.`
- Flagged phrase: "máquina de lavar la ropa"
- Note: Same circumlocution-for-an-everyday-appliance shape, vs. "lavadora".

#### Summary (10 runs, 1 error(s))

- Verdict distribution: error: 7, not_an_error: 2 -> convergence 77.8% (7/9)
- Category distribution: : 1, (none): 1, Natural Language: 7 -> convergence 77.8% (7/9)

#### Run detail

- Run 1: verdict=error, category=Natural Language, occurrence=1
- Run 2: verdict=error, category=Natural Language, occurrence=1
- Run 3: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=error, category=Natural Language, occurrence=1
- Run 6: verdict=error, category=Natural Language, occurrence=1
- Run 7: verdict=error, category=Natural Language, occurrence=1
- Run 8: verdict=not_an_error, category=, occurrence=1
- Run 9: verdict=error, category=Natural Language, occurrence=1
- Run 10: verdict=error, category=Natural Language, occurrence=1

### SR-T2 (Transfer)

- Text: `Necesito un aparato para calentar la comida.`
- Flagged phrase: "aparato para calentar la comida"
- Note: Same shape, vs. "microondas".

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### SR-neg (Negative)

- Text: `Puse el aire acondicionado porque hacía calor.`
- Flagged phrase: "aire acondicionado"
- Note: "Aire acondicionado" is itself the standard idiomatic phrase — there is no shorter single-word native term to prefer instead. Flagging it as an overly wordy circumlocution would be overcorrection.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

## New: seeds

### HP-1

- Text: `Hoy comí en casa de mis abuelos.`
- Flagged phrase: "Hoy comí"
- Note: Hodiernal preterite: simple past for a same-day action. Standard in Latin American and Canary Islands Spanish; Peninsular spoken norm generally prefers "he comido hoy" instead, but both are grammatical. A tense preference, not a confusion/offense risk — per Edit B, this is the kind of split that should land as not_an_error (or, if the model insists on flagging the regional split at all, dialectal) but never error.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) (accepted: dialectal/not_an_error) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### TEMP-1

- Text: `Voy a llamarte en la mañana.`
- Flagged phrase: "en la mañana"
- Note: "en la mañana" (Latin America) vs. "por la mañana" (Spain) — a preposition-choice regional preference, one of Edit B's named examples of what must be not_an_error, not dialectal.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) (accepted: not_an_error) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### ENTRA-1

- Text: `Ayer entramos al cine a las ocho.`
- Flagged phrase: "entramos al cine"
- Note: "entrar a" vs. the traditionally prescribed "entrar en" — widely used and accepted across dialects, expected not_an_error per the locked case list.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) (accepted: not_an_error) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### LEISMO-TRAP-1

- Text: `Ayer le dije a mis padres que llegaría tarde.`
- Flagged phrase: "le dije a mis padres"
- Note: Interpretation note: "decir a alguien" takes an indirect-object clitic (le/les), and "mis padres" is plural, so the correct clitic is "les", not "le" — a plain number-agreement error under every norm, not a recognized dialectal leísmo split (leísmo/laísmo debates concern DIRECT-object clitics, e.g. "le vi" for "lo vi"; the indirect-object clitic here is not in dispute in any variety). This is a deliberate trap: the word "leísmo" in its label superficially resembles the accepted-vs-nonstandard split tested by the LEISMO-DO-* cases below, but the actual phenomenon is a hard agreement violation every established norm rejects — exactly the case Edit A's "established means the educated, written norm" clarification is meant to keep as error.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

### HABER-1

- Text: `En la calle habían muchos coches aparcados.`
- Flagged phrase: "habían muchos coches"
- Note: Existential "haber" pluralized to agree with its complement — proscribed by every established norm despite being extremely common in casual speech across all dialects. The canonical case for Stage 3's strengthened Edit C: common-but-proscribed, so the explanation MUST acknowledge how common it is while still marking it error.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

### QUEISMO-1

- Text: `Me alegro que vinieras a la fiesta.`
- Flagged phrase: "Me alegro que vinieras"
- Note: "Alegrarse" governs "de que"; omitting the required "de" (queísmo) is proscribed in every established variety, however common colloquially — expected error throughout, contrasted against QUEISMO-informar below where the governing verb genuinely takes bare "que".

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## New: controls (fixed anchors, must not drift)

### CTRL-para

- Text: `Cuando termino el trabajo, voy para casa en autobús.`
- Flagged phrase: "voy para casa"
- Note: Same text as ES-2 in stage2_categorization_harness.dart, which accepted {dialectal, not_an_error} for this phrase pre-Edit-B. This control tightens the expectation to not_an_error only, per the locked case list — "voy para casa" carries no real confusion/offense risk (unlike coger), so after Edit B it should no longer plausibly land as dialectal.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) (accepted: not_an_error) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### CTRL-dequeismo

- Text: `Yo pienso de que deberíamos hablar con ella.`
- Flagged phrase: "pienso de que"
- Note: Dequeísmo: inserting an unwanted "de" before "que" where the verb takes bare "que". Fixed anchor, must stay error.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

### CTRL-laismo

- Text: `Ayer la dije que viniera a la reunión.`
- Flagged phrase: "la dije que viniera"
- Note: Laísmo: "la" used for an indirect-object clitic where "le" is required. Unlike masculine-singular direct-object leísmo (RAE-tolerated, see LEISMO-DO-accepted), laísmo is not accepted by any standard register in any variety. Must be error, never dialectal, per the locked case list.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

### CTRL-coger

- Text: `Voy a coger el autobús para ir al centro.`
- Flagged phrase: "coger el autobús"
- Note: Same text as COG-anchor above (reused), duplicated deliberately as an explicit ground-truth-scored control per the locked case list — COG-anchor is scored convergence-only, this entry adds a hard catch-rate check on the same phrase as the canonical real-confusion/offense dialectal case that must survive Edit B's tightened restraint line.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 10 -> convergence 100.0% (10/10) (accepted: dialectal) -> caught 100.0% (10/10)
- Category distribution: Other: 10 -> convergence 100.0% (10/10) (expected Other) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=dialectal, category=Other, occurrence=1
- Run 3: verdict=dialectal, category=Other, occurrence=1
- Run 4: verdict=dialectal, category=Other, occurrence=1
- Run 5: verdict=dialectal, category=Other, occurrence=1
- Run 6: verdict=dialectal, category=Other, occurrence=1
- Run 7: verdict=dialectal, category=Other, occurrence=1
- Run 8: verdict=dialectal, category=Other, occurrence=1
- Run 9: verdict=dialectal, category=Other, occurrence=1
- Run 10: verdict=dialectal, category=Other, occurrence=1

## New this step

### SLD-1

- Text: `Mis padres querían saber el secreto y se los dije.`
- Flagged phrase: "se los dije"
- Note: "El secreto" is singular, so the correct clitic is "se lo dije"; "se los" wrongly extends plural marking from the (plural) indirect-object referent onto the (singular) direct-object clitic — a widespread but proscribed clitic-agreement error. Decided error this session (per the task instruction); included here as a fixed ground truth for future runs.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## New: subcase split — leísmo by gender/number/animacy

### LEISMO-DO-accepted

- Text: `Ayer vi a Juan en el parque y le saludé.`
- Flagged phrase: "le saludé"
- Note: Masculine-singular-animate direct-object leísmo ("le" for "lo") is RAE-tolerated — standard in much of Spain. Must not be error. Minimal pair with LEISMO-DO-nonstandard below: same sentence frame, only the referent's gender differs.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 4, not_an_error: 6 -> convergence 60.0% (6/10) (accepted: dialectal/not_an_error) -> caught 100.0% (10/10)
- Category distribution: (none): 6, Other: 4 -> convergence 60.0% (6/10)

#### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=dialectal, category=Other, occurrence=1
- Run 3: verdict=dialectal, category=Other, occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=dialectal, category=Other, occurrence=1

### LEISMO-DO-nonstandard

- Text: `Ayer vi a Marta en el parque y le saludé.`
- Flagged phrase: "le saludé"
- Note: Same frame as LEISMO-DO-accepted, feminine referent: "le" for a feminine direct object ("la saludé") is not the RAE-tolerated case — no established norm accepts feminine-object leísmo. This is the split the family exists to test: does the model draw the accepted/nonstandard line at animacy+gender+number, or does it treat "leísmo" as a single undifferentiated dialectal bucket?

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## New: subcase split — voseo

### VOSEO-valid

- Text: `Vos tenés razón en eso.`
- Flagged phrase: "Vos tenés"
- Note: Standard Rioplatense voseo conjugation. A pronoun-system regional preference — per Edit B's named example, expected not_an_error.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) (accepted: not_an_error) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

### VOSEO-hypercorrected

- Text: `Vos comistes ayer bien tarde.`
- Flagged phrase: "Vos comistes"
- Note: "Comistes" (with the extra -s) is a hypercorrected/nonstandard voseo preterite; the correct voseo form is "comiste". Wrong even within voseo-using varieties themselves — must be error, not excused as "just voseo".

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) (accepted: error) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) (expected Grammar) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## New: subcase split — queísmo two-regime verbs

### QUEISMO-informar

- Text: `Me informó que llegaría tarde.`
- Flagged phrase: "informó que"
- Note: "Informar" genuinely takes bare "que" — contrast case against QUEISMO-1's "me alegro que" (which requires "de que"). Tests whether the model applies the de-que/que-alone distinction per-verb rather than pattern-matching on the surface "verb + que" shape.

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) (accepted: not_an_error) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=not_an_error, category=(none), occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

---

## Reused-family convergence rollup

| Construction family | Anchor convergence (verdict) | Transfer convergence (avg) | Negative convergence | Anchor→Transfer gap |
| --- | --- | --- | --- | --- |
| Reused: para + destination | 90.0% | 70.0% | 100.0% | 20.0 pts |
| Reused: coger-type vocabulary | 100.0% | 100.0% | 100.0% | 0.0 pts |
| Reused: ordinary regional vocabulary pairs | 100.0% | 96.7% | 100.0% | 3.3 pts |
| Reused: soft-register / circumlocution (BP-001-style) | 100.0% | 88.9% | 100.0% | 11.1 pts |

## New-case catch-rate summary

| Case | Accepted verdicts | Verdict catch rate | Category catch rate |
| --- | --- | --- | --- |
| HP-1 | dialectal/not_an_error | 100.0% (10/10) | n/a |
| TEMP-1 | not_an_error | 100.0% (10/10) | n/a |
| ENTRA-1 | not_an_error | 100.0% (10/10) | n/a |
| LEISMO-TRAP-1 | error | 100.0% (10/10) | 100.0% (10/10) |
| HABER-1 | error | 100.0% (10/10) | 100.0% (10/10) |
| QUEISMO-1 | error | 100.0% (10/10) | 100.0% (10/10) |
| CTRL-para | not_an_error | 100.0% (10/10) | n/a |
| CTRL-dequeismo | error | 100.0% (10/10) | 100.0% (10/10) |
| CTRL-laismo | error | 100.0% (10/10) | 100.0% (10/10) |
| CTRL-coger | dialectal | 100.0% (10/10) | 100.0% (10/10) |
| SLD-1 | error | 100.0% (10/10) | 100.0% (10/10) |
| LEISMO-DO-accepted | dialectal/not_an_error | 100.0% (10/10) | n/a |
| LEISMO-DO-nonstandard | error | 100.0% (10/10) | 100.0% (10/10) |
| VOSEO-valid | not_an_error | 100.0% (10/10) | n/a |
| VOSEO-hypercorrected | error | 100.0% (10/10) | 100.0% (10/10) |
| QUEISMO-informar | not_an_error | 100.0% (10/10) | n/a |
