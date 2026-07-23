# Stage 2 `span_scope` Classification-Consistency Harness

Calls `stage2CategorizationSpanish` in isolation (one hand-written flagged phrase per case, standing in for Stage 1 output) and reports whether the new `span_scope` field (`exact`/`full`) is returned consistently and correctly across repeated runs, before any span-trimming logic is wired to read it.

Model: `gpt-5.5`  
Commit: `aee1c012a93a5666405255a566b774b3e0773a48`  
Generated: 2026-07-23T11:22:14.644373  
Runs per case: 10

## cerveza-predicate

- Text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`
- Flagged phrase: `Puedo tener una cerveza`
- Expected category: `Natural Language`
- Expected span_scope: `exact`
- Note: Predicate restructure — the prompt's own worked exact example. "una cerveza" is unchanged context that means the same thing alone; only "Puedo tener" -> "Me da"/"Me pone" actually differs.

### Summary (10 runs, 0 error(s))

- No result overlapping the flagged phrase: 0.0% (0/10)
- Category matches "Natural Language": 100.0% (10/10)
- Category distribution: "Natural Language": 10
- span_scope matches "exact" (among category-matching runs): 100.0% (10/10)
- span_scope present but wrong value (among category-matching runs): 0.0% (0/10)
- span_scope missing entirely despite Natural Language category (among category-matching runs): 0.0% (0/10)
- span_scope distribution (among category-matching runs): "exact": 10

### Run detail

- Run 1: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 2: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 3: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 4: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 5: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 6: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 7: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 8: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 9: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"
- Run 10: category=Natural Language, span_scope=exact, original_phrase="Puedo tener una cerveza", corrected_phrase="Me da una cerveza"

## decision-collocation

- Text: `Hice una decisión importante sobre mi futuro académico.`
- Flagged phrase: `Hice una decisión importante`
- Expected category: `Natural Language`
- Expected span_scope: `full`
- Note: Fixed-phrase collocation ("hacer" vs "tomar" una decisión) — the prompt's own worked full example, now embedded in a longer sentence than the prompt's bare phrase to check the value still holds once there is real surrounding context to be tempted into trimming.

### Summary (10 runs, 0 error(s))

- No result overlapping the flagged phrase: 0.0% (0/10)
- Category matches "Natural Language": 100.0% (10/10)
- Category distribution: "Natural Language": 10
- span_scope matches "full" (among category-matching runs): 100.0% (10/10)
- span_scope present but wrong value (among category-matching runs): 0.0% (0/10)
- span_scope missing entirely despite Natural Language category (among category-matching runs): 0.0% (0/10)
- span_scope distribution (among category-matching runs): "full": 10

### Run detail

- Run 1: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 2: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 3: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 4: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 5: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 6: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 7: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 8: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 9: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"
- Run 10: category=Natural Language, span_scope=full, original_phrase="Hice una decisión importante", corrected_phrase="Tomé una decisión importante"

## mesa-clause

- Text: `La mesa tiene cuatro personas porque no hay más sillas disponibles.`
- Flagged phrase: `La mesa tiene cuatro personas`
- Expected category: `Natural Language`
- Expected span_scope: `full`
- Note: Core-clause restructure — capacity calque ("the table has four people" for "the table seats/holds four people"). The natural fix reassigns grammatical roles across the whole clause (e.g. "tiene" -> "es para"/"caben"), not a single-word swap inside an otherwise unchanged frame, so no smaller piece of the quoted phrase stands on its own.

### Summary (10 runs, 0 error(s))

- No result overlapping the flagged phrase: 0.0% (0/10)
- Category matches "Natural Language": 100.0% (10/10)
- Category distribution: "Natural Language": 10
- span_scope matches "full" (among category-matching runs): 80.0% (8/10)
- span_scope present but wrong value (among category-matching runs): 20.0% (2/10)
- span_scope missing entirely despite Natural Language category (among category-matching runs): 0.0% (0/10)
- span_scope distribution (among category-matching runs): "exact": 2, "full": 8

### Run detail

- Run 1: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 2: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa caben cuatro personas"
- Run 3: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 4: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 5: category=Natural Language, span_scope=exact, original_phrase="La mesa tiene cuatro personas", corrected_phrase="La mesa es para cuatro personas"
- Run 6: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 7: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa caben cuatro personas"
- Run 8: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 9: category=Natural Language, span_scope=exact, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 10: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"

## redundant-pronoun-fresh

- Text: `Mi hermana trabaja en un hospital y ella ayuda mucho a los pacientes enfermos.`
- Flagged phrase: `ella ayuda mucho a los pacientes enfermos`
- Expected category: `Natural Language`
- Expected span_scope: `exact`
- Note: Fresh construction (not from any existing catalog): a single redundant-pronoun token ("ella" repeating "mi hermana"), not a fixed collocation — the token-type case the task asked for, with a genuinely wide flagged phrase around the one word that's actually wrong, so trimming down to "exact" is non-trivial rather than already-minimal (unlike the catalog's only redundant-pronoun example, ES-6, which flags the bare pronoun alone).

### Summary (10 runs, 0 error(s))

- No result overlapping the flagged phrase: 0.0% (0/10)
- Category matches "Natural Language": 90.0% (9/10)
- Category distribution: "(none)": 1, "Natural Language": 9
- span_scope matches "exact" (among category-matching runs): 100.0% (9/9)
- span_scope present but wrong value (among category-matching runs): 0.0% (0/9)
- span_scope missing entirely despite Natural Language category (among category-matching runs): 0.0% (0/9)
- span_scope distribution (among category-matching runs): "exact": 9

### Run detail

- Run 1: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"
- Run 2: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"
- Run 3: category=(none), span_scope=(missing), original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ella ayuda mucho a los pacientes enfermos"
- Run 4: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"
- Run 5: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"
- Run 6: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"
- Run 7: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"
- Run 8: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"
- Run 9: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes"
- Run 10: category=Natural Language, span_scope=exact, original_phrase="ella ayuda mucho a los pacientes enfermos", corrected_phrase="ayuda mucho a los pacientes enfermos"

---

## Overall summary

| Case | Runs | Errors | Category match | span_scope match | span_scope missing | span_scope distribution |
| --- | --- | --- | --- | --- | --- | --- |
| cerveza-predicate | 10 | 0 | 100.0% (10/10) | 100.0% (10/10) | 0.0% (0/10) | "exact": 10 |
| decision-collocation | 10 | 0 | 100.0% (10/10) | 100.0% (10/10) | 0.0% (0/10) | "full": 10 |
| mesa-clause | 10 | 0 | 100.0% (10/10) | 80.0% (8/10) | 0.0% (0/10) | "exact": 2, "full": 8 |
| redundant-pronoun-fresh | 10 | 0 | 90.0% (9/10) | 100.0% (9/9) | 0.0% (0/9) | "exact": 9 |
