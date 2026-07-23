# Para + Destination Battery

Standalone extraction of the "para + destination" family from `verdict_battery_merged.dart` (PD-anchor, PD-T1, PD-T2, PD-T3, PD-neg), for investigating whether this construction is genuinely unstable in `stage2CategorizationSpanish` verdict output, without running the full 37-case merged suite.

Model: `gpt-5.5`  
Commit: `bcf1690ab84e66b6159abe80de5431632f9ed164`  
Generated: 2026-07-22T19:11:04.603324  
Runs per case: 10

## PD-anchor (Anchor)

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrase: "volví para casa"
- Note: Same text as ES-1 in stage2_categorization_harness.dart, reused verbatim as the anchor for continuity with the already-measured baseline (30% verdict convergence live, per docs/stage2_categorization_harness.md).

### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 2, not_an_error: 8 -> convergence 80.0% (8/10)
- Category distribution: : 2, (none): 6, Grammar: 2 -> convergence 60.0% (6/10)

### Run detail

- Run 1: verdict=not_an_error, category=, occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=not_an_error, category=, occurrence=1

## PD-T1 (Transfer)

- Text: `Ya era tarde cuando vine para casa.`
- Flagged phrase: "vine para casa"
- Note: Same "para + destination" construction, different verb.

### Summary (10 runs, 2 error(s))

- Verdict distribution: not_an_error: 8 -> convergence 100.0% (8/8)
- Category distribution: (none): 8 -> convergence 100.0% (8/8)

### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=not_an_error, category=(none), occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=not_an_error, category=(none), occurrence=1
- Run 6: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 7: verdict=not_an_error, category=(none), occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 10: verdict=not_an_error, category=(none), occurrence=1

## PD-T2 (Transfer)

- Text: `Subió para la oficina en cuanto llegó.`
- Flagged phrase: "Subió para la oficina"
- Note: Same construction, different destination and verb.

### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 5, not_an_error: 5 -> convergence 50.0% (5/10)
- Category distribution: : 1, (none): 4, Grammar: 5 -> convergence 50.0% (5/10)

### Run detail

- Run 1: verdict=not_an_error, category=(none), occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=not_an_error, category=, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=not_an_error, category=(none), occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

## PD-T3 (Transfer)

- Text: `Al terminar el partido, regresamos para el pueblo.`
- Flagged phrase: "regresamos para el pueblo"
- Note: Same construction, different destination and verb.

### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 1, error: 5, not_an_error: 4 -> convergence 50.0% (5/10)
- Category distribution: (none): 4, Grammar: 5, Other: 1 -> convergence 50.0% (5/10)

### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=not_an_error, category=(none), occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=not_an_error, category=(none), occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=not_an_error, category=(none), occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=not_an_error, category=(none), occurrence=1

## PD-neg (Negative)

- Text: `Ya era tarde cuando volví a casa.`
- Flagged phrase: "volví a casa"
- Note: The accepted Peninsular form of the anchor construction (its own corrected_phrase). Must not be flagged at all.

### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

### Run detail

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

## Convergence rollup

| Anchor convergence (verdict) | Transfer convergence (avg, T1+T2+T3) | Negative convergence | Anchor→Transfer gap |
| --- | --- | --- | --- |
| 80.0% | 66.7% | 100.0% | 13.3 pts |
