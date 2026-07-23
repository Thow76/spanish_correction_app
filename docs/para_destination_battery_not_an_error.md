# Para + Destination Battery

Standalone extraction of the "para + destination" family from `verdict_battery_merged.dart` (PD-anchor, PD-T1, PD-T2, PD-T3, PD-neg), for investigating whether this construction is genuinely unstable in `stage2CategorizationSpanish` verdict output, without running the full 37-case merged suite.

Model: `gpt-5.5`  
Commit: `bcf1690ab84e66b6159abe80de5431632f9ed164`  
Generated: 2026-07-22T23:09:03.691585  
Runs per case: 10

## PD-anchor (Anchor)

- Text: `Ayer fui al supermercado para comprar pan y después volví para casa para preparar la cena.`
- Flagged phrase: "volví para casa"
- Note: Same text as ES-1 in stage2_categorization_harness.dart, reused verbatim as the anchor for continuity with the already-measured baseline (30% verdict convergence live, per docs/stage2_categorization_harness.md).

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

## PD-T1 (Transfer)

- Text: `Ya era tarde cuando vine para casa.`
- Flagged phrase: "vine para casa"
- Note: Same "para + destination" construction, different verb.

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

## PD-T2 (Transfer)

- Text: `Subió para la oficina en cuanto llegó.`
- Flagged phrase: "Subió para la oficina"
- Note: Same construction, different destination and verb.

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

## PD-T3 (Transfer)

- Text: `Al terminar el partido, regresamos para el pueblo.`
- Flagged phrase: "regresamos para el pueblo"
- Note: Same construction, different destination and verb.

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

## PD-neg (Negative)

- Text: `Ya era tarde cuando volví a casa.`
- Flagged phrase: "volví a casa"
- Note: The accepted Peninsular form of the anchor construction (its own corrected_phrase). Must not be flagged at all.

### Summary (10 runs, 1 error(s))

- Verdict distribution: not_an_error: 9 -> convergence 100.0% (9/9)
- Category distribution: (none): 9 -> convergence 100.0% (9/9)

### Run detail

- Run 1: ERROR — TimeoutException after 0:00:30.000000: Future not completed
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
| 100.0% | 100.0% | 100.0% | 0.0 pts |
