# Stage 1 Redundancy Model-Comparison Harness

Model: `gpt-5.5`  
Prompt: `stage1DetectionDialectSpanish`  
Commit: `e370e9fa8f22c96f32927b55cd22eb1987416c32`  
Generated: 2026-07-18T23:24:48.222223  
Runs per case: 10

## ES-6-redundant-yo

- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`
- Redundant pronoun: `yo`
- Note: Text/id copied verbatim from test/stage1_detection_harness.dart's ES-6-redundant-pronoun. Spanish is pro-drop; repeating "yo" before every verb is grammatical but unnatural.

### Summary (10 runs, 1 error(s))

- Flag rate: 33.3% (3/9)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "clause": 3
- Exact flagged-span distribution: "Yo fui a casa, yo estudié, y yo hice la cena": 1, "Yo fui a casa, yo estudié, y yo hice la cena.": 2

### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: flagged: "Yo fui a casa, yo estudié, y yo hice la cena."
- Run 3: flagged: (no phrases flagged)
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: ", y"
- Run 7: ERROR — TimeoutException after 0:00:30.000000: Future not completed
- Run 8: flagged: "Yo fui a casa, yo estudié, y yo hice la cena"
- Run 9: flagged: "Yo fui a casa, yo estudié, y yo hice la cena."
- Run 10: flagged: ", y"

## ST-R2-redundant-nosotros

- Text: `Nosotros vamos al cine, nosotros comemos palomitas y nosotros volvemos a casa.`
- Redundant pronoun: `nosotros`
- Note: Text/id copied verbatim from test/stage1_detection_harness.dart's ST-R2-redundant-pronoun. Same class as ES-6, plural subject.

### Summary (10 runs, 0 error(s))

- Flag rate: 10.0% (1/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "phrase": 2
- Exact flagged-span distribution: "nosotros comemos": 1, "nosotros volvemos": 1

### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: flagged: "nosotros comemos"; "nosotros volvemos"
- Run 3: flagged: (no phrases flagged)
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: flagged: (no phrases flagged)
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: (no phrases flagged)

## ST-R1-redundant-a-mi

- Text: `Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a mí.`
- Redundant pronoun: `a mí`
- Note: Text/id copied verbatim from test/stage1_detection_harness.dart's ST-R1-redundant-article. THE HARDEST case — 0/10 flag rate in the earlier structural-battery run. Included specifically to see whether gpt-5.6-sol does any better than the gpt-5.5 baseline here. Redundant emphatic "a mí" given "me gusta" already marks the subject.

### Summary (10 runs, 0 error(s))

- Flag rate: 0.0% (0/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): (none)
- Exact flagged-span distribution: (none)

### Run detail

- Run 1: flagged: "Me gusta el fútbol y el tenis"
- Run 2: flagged: (no phrases flagged)
- Run 3: flagged: "Me gusta el fútbol y el tenis"
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: "Me gusta el fútbol y el tenis"
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: flagged: "Me gusta el fútbol y el tenis"
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: (no phrases flagged)

## ellos-redundant

- Text: `Ellos trabajan mucho, ellos estudian por la noche y ellos nunca descansan.`
- Redundant pronoun: `ellos`
- Note: New case, not in the existing battery — a broader sample beyond yo/nosotros, third-person plural.

### Summary (10 runs, 0 error(s))

- Flag rate: 40.0% (4/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "clause": 1, "phrase": 6
- Exact flagged-span distribution: "Ellos trabajan mucho, ellos estudian por la noche y ellos nunca descansan.": 1, "ellos estudian": 3, "ellos nunca descansan": 3

### Run detail

- Run 1: flagged: "Ellos trabajan mucho, ellos estudian por la noche y ellos nunca descansan."
- Run 2: flagged: "ellos estudian"; "ellos nunca descansan"
- Run 3: flagged: (no phrases flagged)
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: "ellos estudian"; "ellos nunca descansan"
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: flagged: (no phrases flagged)
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: "ellos estudian"; "ellos nunca descansan"

---

## Overall summary

| Case | Runs | Errors | Flag rate | Span-bucket distribution |
| --- | --- | --- | --- | --- |
| ES-6-redundant-yo | 10 | 1 | 33.3% (3/9) | "clause": 3 |
| ST-R2-redundant-nosotros | 10 | 0 | 10.0% (1/10) | "phrase": 2 |
| ST-R1-redundant-a-mi | 10 | 0 | 0.0% (0/10) | (none) |
| ellos-redundant | 10 | 0 | 40.0% (4/10) | "clause": 1, "phrase": 6 |
