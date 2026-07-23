# Stage 2 `span_scope` Classification-Consistency Harness

Calls `stage2CategorizationSpanish` in isolation (one hand-written flagged phrase per case, standing in for Stage 1 output) and reports whether the new `span_scope` field (`exact`/`full`) is returned consistently and correctly across repeated runs, before any span-trimming logic is wired to read it.

Model: `gpt-5.5`  
Commit: `aee1c012a93a5666405255a566b774b3e0773a48`  
Generated: 2026-07-23T11:45:12.150702  
Runs per case: 10

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
- Run 2: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 3: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 4: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 5: category=Natural Language, span_scope=exact, original_phrase="La mesa tiene cuatro personas", corrected_phrase="La mesa es para cuatro personas"
- Run 6: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 7: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 8: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 9: category=Natural Language, span_scope=full, original_phrase="La mesa tiene cuatro personas", corrected_phrase="En la mesa hay cuatro personas"
- Run 10: category=Natural Language, span_scope=exact, original_phrase="La mesa tiene cuatro personas", corrected_phrase="La mesa es para cuatro personas"

---

## Overall summary

| Case | Runs | Errors | Category match | span_scope match | span_scope missing | span_scope distribution |
| --- | --- | --- | --- | --- | --- | --- |
| mesa-clause | 10 | 0 | 100.0% (10/10) | 80.0% (8/10) | 0.0% (0/10) | "exact": 2, "full": 8 |
