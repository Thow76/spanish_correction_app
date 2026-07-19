# Stage 1 Detection Harness — Dialect-Flagging Variant

Compares `stage1DetectionDialectSpanish` against the same battery `stage1DetectionSpanish` was run on — see docs/stage1_detection_harness.md for the base-prompt results this is meant to sit alongside.

Model: `gpt-5.5`  
Commit: `e370e9fa8f22c96f32927b55cd22eb1987416c32`  
Generated: 2026-07-18T21:01:55.347761  
Runs per phrase: 10

## Regression check (genuine errors — must still catch)

### ES-1-repeated-word

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Note: Genuine grammar error ("volví para casa" -> "volví a casa"), unrelated to dialect. Same expectedFlags as the base harness's ES-1-repeated-word — must still be caught with the dialect instruction added.

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

### ES-3-multi-correction

- Text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`
- Note: A spelling error and a calque, both genuine errors unrelated to dialect. Same expectedFlags as the base harness's ES-3-multi-correction.

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
- Note: Two calque targets, genuine errors unrelated to dialect. Same expectedFlags as the base harness's ES-4-calque.

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
- Note: Four missing-accent targets, genuine errors unrelated to dialect. Same expectedFlags as the base harness's ES-5-accents.

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

## Intended new flags (previously clean/observational — now the correct behaviour)

### ES-2-para-casa _(observational only — not scored pass/fail)_

- Text: `Cuando termino el trabajo, voy para casa en autobús.`
- Note: Same text as ES-2-single-char / ES-D1-para-casa-latam in the base harness, where it was a hard negative test (must stay clean) — "voy para casa" is standard in much of Latin America but a dialectal split from Peninsular "voy a casa". Under this variant, flagging it is the intended new behaviour, not a false positive. Record the flag rate; not scored pass/fail.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 70.0% (7/10)

#### Run detail

- Run 1: stayed clean = true · flagged: (no phrases flagged)
- Run 2: stayed clean = false · flagged: "voy para casa"
- Run 3: stayed clean = true · flagged: (no phrases flagged)
- Run 4: stayed clean = true · flagged: (no phrases flagged)
- Run 5: stayed clean = true · flagged: (no phrases flagged)
- Run 6: stayed clean = false · flagged: "voy para casa"
- Run 7: stayed clean = true · flagged: (no phrases flagged)
- Run 8: stayed clean = false · flagged: "voy para casa"
- Run 9: stayed clean = true · flagged: (no phrases flagged)
- Run 10: stayed clean = true · flagged: (no phrases flagged)

### ES-D2-coger-autobus _(observational only — not scored pass/fail)_

- Text: `Voy a coger el autobús para ir al centro.`
- Note: Same text as ES-D2-coger-autobus in the base harness, where it was already observational (ambiguous under the plain prompt: standard in Spain, vulgar in much of Latin America). Under this variant it is expected to flag as a dialect difference. Record the flag rate; not scored pass/fail.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 10.0% (1/10)

#### Run detail

- Run 1: stayed clean = false · flagged: "coger el autobús"
- Run 2: stayed clean = false · flagged: "coger el autobús"
- Run 3: stayed clean = false · flagged: "coger el autobús"
- Run 4: stayed clean = false · flagged: "coger el autobús"
- Run 5: stayed clean = false · flagged: "coger el autobús"
- Run 6: stayed clean = false · flagged: "coger el autobús"
- Run 7: stayed clean = false · flagged: "coger el autobús"
- Run 8: stayed clean = true · flagged: (no phrases flagged)
- Run 9: stayed clean = false · flagged: "coger el autobús"
- Run 10: stayed clean = false · flagged: "coger el autobús"

## Key negative test (ordinary regional vocabulary — must NOT be pulled in)

### ES-D3-coche

- Text: `Aparqué el coche cerca de la oficina.`
- Note: Same text as ES-D3-coche in the base harness, already a hard negative test there. "coche" (car) is ordinary regional vocabulary, not a dialectal split with any confusion/offense risk — must not be flagged even with the dialect instruction added. THE make-or-break check for this variant.

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

### ordenador

- Text: `Voy a usar el ordenador en la oficina.`
- Note: New negative test: "ordenador" is Spain-standard, "computadora" elsewhere — ordinary interchangeable regional vocabulary, not a dialectal split with real risk of confusion or offense (unlike "coger el autobús"). Must not be flagged.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 80.0% (8/10)

#### Run detail

- Run 1: stayed clean = false · flagged: "ordenador"
- Run 2: stayed clean = true · flagged: (no phrases flagged)
- Run 3: stayed clean = false · flagged: "ordenador"
- Run 4: stayed clean = true · flagged: (no phrases flagged)
- Run 5: stayed clean = true · flagged: (no phrases flagged)
- Run 6: stayed clean = true · flagged: (no phrases flagged)
- Run 7: stayed clean = true · flagged: (no phrases flagged)
- Run 8: stayed clean = true · flagged: (no phrases flagged)
- Run 9: stayed clean = true · flagged: (no phrases flagged)
- Run 10: stayed clean = true · flagged: (no phrases flagged)

---

## Overall summary

| Phrase | Runs | Errors | Headline rate | Per-target rates |
| --- | --- | --- | --- | --- |
| ES-1-repeated-word | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10) |
| ES-3-multi-correction | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10) |
| ES-4-calque | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10) |
| ES-5-accents | 10 | 0 | 100.0% (10/10) (fully caught) | 100.0% (10/10), 100.0% (10/10), 100.0% (10/10), 100.0% (10/10) |
| ES-2-para-casa | 10 | 0 | 70.0% (7/10) (clean) | — |
| ES-D2-coger-autobus | 10 | 0 | 10.0% (1/10) (clean) | — |
| ES-D3-coche | 10 | 0 | 100.0% (10/10) (clean) | — |
| ordenador | 10 | 0 | 80.0% (8/10) (clean) | — |
