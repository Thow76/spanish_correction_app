# Stage 1C Dedicated Reflexive-Insertion Pass Harness

Tests `stage1ReflexiveDetectionSpanish` — a standalone detection pass for missing obligatory reflexive pronouns, run independently from the shared general detection prompt.

Model: `gpt-5.5`  
Prompt: `stage1ReflexiveDetectionSpanish`  
Commit: `bcf1690ab84e66b6159abe80de5431632f9ed164`  
Generated: 2026-07-22T13:18:45.263045  
Runs per case: 10

## Positive cases (should flag, clean single-verb span)

### reflexive-levanto

- Text: `Levantó temprano y desayunó con calma.`
- Target verb: `Levantó`
- Note: "Levantó temprano" has no valid object and leaves the clause hanging without the reflexive — needs "Se levantó" to be complete.

#### Summary (10 runs, 0 error(s))

- Flag rate: 100.0% (10/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "word": 10
- Exact flagged-span distribution: "Levantó": 10

#### Run detail

- Run 1: flagged: "Levantó"
- Run 2: flagged: "Levantó"
- Run 3: flagged: "Levantó"
- Run 4: flagged: "Levantó"
- Run 5: flagged: "Levantó"
- Run 6: flagged: "Levantó"
- Run 7: flagged: "Levantó"
- Run 8: flagged: "Levantó"
- Run 9: flagged: "Levantó"
- Run 10: flagged: "Levantó"

### reflexive-atrevio

- Text: `Atrevió a preguntarle directamente.`
- Target verb: `Atrevió`
- Note: "Atrever" is inherently reflexive (atreverse a) — the sentence is ungrammatical without "Se atrevió".

#### Summary (10 runs, 0 error(s))

- Flag rate: 100.0% (10/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "word": 10
- Exact flagged-span distribution: "Atrevió": 10

#### Run detail

- Run 1: flagged: "Atrevió"
- Run 2: flagged: "Atrevió"
- Run 3: flagged: "Atrevió"
- Run 4: flagged: "Atrevió"
- Run 5: flagged: "Atrevió"
- Run 6: flagged: "Atrevió"
- Run 7: flagged: "Atrevió"
- Run 8: flagged: "Atrevió"
- Run 9: flagged: "Atrevió"
- Run 10: flagged: "Atrevió"

## Restraint cases (must NOT flag)

### restraint-decidio-coche

- Text: `Decidí el color del coche.`
- Note: Already a complete, correct sentence as written — "decidir" with a direct object needs no reflexive here, even though "decidirse" exists with a different meaning in other sentences.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 100.0% (10/10)

#### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: flagged: (no phrases flagged)
- Run 3: flagged: (no phrases flagged)
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: flagged: (no phrases flagged)
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: (no phrases flagged)

### restraint-me-decidi-azul

- Text: `Me decidí por el azul.`
- Note: Same verb as restraint-decidio-coche, already correctly reflexive with a different complement — must not be flagged as missing anything.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 100.0% (10/10)

#### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: flagged: (no phrases flagged)
- Run 3: flagged: (no phrases flagged)
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: flagged: (no phrases flagged)
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: (no phrases flagged)

### restraint-paro-coche

- Text: `Paré el coche en la esquina.`
- Note: Non-reflexive "parar" (to stop something) — correct as-is, no reflexive needed.

#### Summary (10 runs, 0 error(s))

- Stayed clean: 100.0% (10/10)

#### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: flagged: (no phrases flagged)
- Run 3: flagged: (no phrases flagged)
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: flagged: (no phrases flagged)
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: (no phrases flagged)

---

## Overall summary

| Case | Runs | Errors | Headline rate | Span-bucket distribution |
| --- | --- | --- | --- | --- |
| reflexive-levanto | 10 | 0 | 100.0% (10/10) | "word": 10 |
| reflexive-atrevio | 10 | 0 | 100.0% (10/10) | "word": 10 |
| restraint-decidio-coche | 10 | 0 | 100.0% (10/10) (clean) | — |
| restraint-me-decidi-azul | 10 | 0 | 100.0% (10/10) (clean) | — |
| restraint-paro-coche | 10 | 0 | 100.0% (10/10) (clean) | — |
