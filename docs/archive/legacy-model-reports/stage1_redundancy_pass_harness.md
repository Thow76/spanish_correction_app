# Stage 1B Dedicated Redundancy Pass Harness

Tests `stage1RedundancyDetectionSpanish` — a standalone detection pass for unnecessary repeated/emphatic pronouns, run independently from `stage1DetectionDialectSpanish` and never merged into it.

Model: `gpt-5.5`  
Prompt: `stage1RedundancyDetectionSpanish`  
Commit: `df5df737c4f6969a59da2c60d76035a9671a2094`  
Generated: 2026-07-19T12:33:19.852732  
Runs per case: 10

## Positive cases (should flag, clean word/short-phrase span)

### ES-6-redundant-yo

- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`
- Redundant pronoun: `yo`
- Note: Text/id copied verbatim from test/stage1_redundancy_model_comparison_harness.dart. Spanish is pro-drop; repeating "yo" before every verb is grammatical but unnatural.

#### Summary (10 runs, 0 error(s))

- Flag rate: 100.0% (10/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "word": 20
- Exact flagged-span distribution: "yo": 20

#### Run detail

- Run 1: flagged: "yo"; "yo"
- Run 2: flagged: "yo"; "yo"
- Run 3: flagged: "yo"; "yo"
- Run 4: flagged: "yo"; "yo"
- Run 5: flagged: "yo"; "yo"
- Run 6: flagged: "yo"; "yo"
- Run 7: flagged: "yo"; "yo"
- Run 8: flagged: "yo"; "yo"
- Run 9: flagged: "yo"; "yo"
- Run 10: flagged: "yo"; "yo"

### ellos-redundant

- Text: `Ellos trabajan mucho, ellos estudian por la noche y ellos nunca descansan.`
- Redundant pronoun: `ellos`
- Note: Text/id copied verbatim from test/stage1_redundancy_model_comparison_harness.dart. Third-person plural.

#### Summary (10 runs, 0 error(s))

- Flag rate: 100.0% (10/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "word": 20
- Exact flagged-span distribution: "ellos": 20

#### Run detail

- Run 1: flagged: "ellos"; "ellos"
- Run 2: flagged: "ellos"; "ellos"
- Run 3: flagged: "ellos"; "ellos"
- Run 4: flagged: "ellos"; "ellos"
- Run 5: flagged: "ellos"; "ellos"
- Run 6: flagged: "ellos"; "ellos"
- Run 7: flagged: "ellos"; "ellos"
- Run 8: flagged: "ellos"; "ellos"
- Run 9: flagged: "ellos"; "ellos"
- Run 10: flagged: "ellos"; "ellos"

### ST-R2-redundant-nosotros

- Text: `Nosotros vamos al cine, nosotros comemos palomitas y nosotros volvemos a casa.`
- Redundant pronoun: `nosotros`
- Note: Text/id copied verbatim from test/stage1_redundancy_model_comparison_harness.dart. Same class as ES-6, plural subject.

#### Summary (10 runs, 0 error(s))

- Flag rate: 100.0% (10/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "word": 20
- Exact flagged-span distribution: "nosotros": 20

#### Run detail

- Run 1: flagged: "nosotros"; "nosotros"
- Run 2: flagged: "nosotros"; "nosotros"
- Run 3: flagged: "nosotros"; "nosotros"
- Run 4: flagged: "nosotros"; "nosotros"
- Run 5: flagged: "nosotros"; "nosotros"
- Run 6: flagged: "nosotros"; "nosotros"
- Run 7: flagged: "nosotros"; "nosotros"
- Run 8: flagged: "nosotros"; "nosotros"
- Run 9: flagged: "nosotros"; "nosotros"
- Run 10: flagged: "nosotros"; "nosotros"

### ST-R1-redundant-a-mi

- Text: `Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a mí.`
- Redundant pronoun: `a mí`
- Note: Text/id copied verbatim from test/stage1_redundancy_model_comparison_harness.dart. THE HARDEST case — 0% flag rate under every prior variant tried (base detection, dialect variant, clean-span variant). Key result: does a dedicated pass do any better than a shared one?

#### Summary (10 runs, 0 error(s))

- Flag rate: 0.0% (0/10)
- Span-bucket distribution (word/phrase/clause, among flagged spans): (none)
- Exact flagged-span distribution: (none)

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

## Restraint cases (must NOT flag)

### restraint-contrast

- Text: `A mí me encanta la playa, pero a él le encanta la montaña.`
- Note: Genuine contrast between two different people, different verb ("encantar") and people than the prompt's own worked example — tests generalization of the contrast exception, not memorization.

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

### restraint-single-emphatic

- Text: `A mí me encantó muchísimo la película.`
- Note: A single emphatic pronoun with no repetition and no contrast — tests whether the restraint instruction holds for ordinary one-off emphasis, not just the contrast case explicitly named in the prompt.

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

### restraint-no-pronoun-issue

- Text: `Compré pan y leche en el supermercado esta mañana.`
- Note: No pronoun at all — basic no-over-trigger sanity check that this narrowly-scoped pass does not invent a problem where none exists.

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
| ES-6-redundant-yo | 10 | 0 | 100.0% (10/10) | "word": 20 |
| ellos-redundant | 10 | 0 | 100.0% (10/10) | "word": 20 |
| ST-R2-redundant-nosotros | 10 | 0 | 100.0% (10/10) | "word": 20 |
| ST-R1-redundant-a-mi | 10 | 0 | 0.0% (0/10) | (none) |
| restraint-contrast | 10 | 0 | 100.0% (10/10) (clean) | — |
| restraint-single-emphatic | 10 | 0 | 100.0% (10/10) (clean) | — |
| restraint-no-pronoun-issue | 10 | 0 | 100.0% (10/10) (clean) | — |
