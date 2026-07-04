# Correction Prompt: Issues & Solutions Log

A living reference document tracking identified issues, applied solutions, and
validation test cases for the Spanish and Brazilian Portuguese correction prompts
in `lib/core/services/prompt_builder.dart`.

---

## How to use this document

When a new prompt issue is identified, add an entry under the relevant language
section following the structure below. Mark the status as **Open**, **In
Progress**, or **Resolved**. Link the affected prompt section and record the
test cases used to validate any fix so they can be re-run after future prompt
changes.

---

## Structural decisions

### Portuguese prompt is a standalone declaration (not a runtime swap)

**Decision:** `_correctionPromptPortuguese` is declared as a standalone
`static final` string, not generated via
`_correctionPromptSpanish.replaceAll('Spanish', 'Brazilian Portuguese')`.

**Rationale:** The swap approach caused the Portuguese prompt to inherit
Spanish-specific examples (¿, ¡, ñ, `memorias → recuerdos`) that are either
inapplicable or actively misleading for Portuguese. The explanation prompts
already had hand-written Portuguese variants for the same reason; the
correction prompt now follows suit.

**Implication:** Any change to shared rules (indexing behaviour, JSON shape,
category definitions) must be applied to both prompts manually. The JSON
response shape is shared via `$correctionResponseJsonShape` to mitigate drift
on schema changes.

---

## Spanish

*No issues logged yet.*

---

## Brazilian Portuguese

### BP-001 — Soft-register natural language terms not flagged

**Status:** Resolved
**Affected section:** Natural language handling
**Prompt file:** `_correctionPromptPortuguese`

#### Problem

Genuinely informal or less-idiomatic-but-understandable terms were not being
flagged as Natural Language corrections. The specific trigger was
"máquina de correr" (treadmill) not being flagged, where the standard
Brazilian term is "esteira."

Investigation confirmed that "máquina de correr" is grammatical, transparent,
and understood in Brazil — it is not a calque or anglicism in the strict sense.
The model was correctly declining to flag something it read as acceptable,
because the original prompt grouped it with stronger errors (anglicisms, false
friends) without distinguishing the softer register-level case.

#### Root cause

Two compounding issues:

1. The prompt placed `"máquina de correr" -> "esteira"` in the calque bullet
   alongside clear-cut errors like `"printar" -> "imprimir"`. The model
   disagreed with the severity framing and discounted the example.

2. No instruction existed for the soft category of "grammatical and
   understandable, but not what a native would reach for" — the model had no
   guidance on how to handle the tension between comprehensibility and
   native-level naturalness.

#### Solution

Two changes to the Natural language handling section:

1. Removed `"máquina de correr" -> "esteira"` from the calque bullet.

2. Added a dedicated soft-register bullet immediately after the calque bullet:

```
- Flag the more idiomatic native term even when the user's phrasing is
  grammatical and fully understandable, when a single everyday word is clearly
  preferred in Brazil (e.g. "máquina de correr" is understood but a Brazilian
  would normally say "esteira"). Mark these as Natural Language and make the
  short_explanation note that the original is understandable but the native
  term is what a speaker would normally use.
```

#### Validation test cases

All cases below were run against the updated prompt and produced the expected
result.

| Sentence | Expected behaviour | Result |
|---|---|---|
| Fiz alguns exercícios com pesos e depois passei um pouco de tempo na máquina de correr. | Flag "máquina de correr" → "esteira" as Natural Language | ✅ Flagged |
| Fiz 30 minutos na bicicleta estacionária depois da musculação. | Flag "bicicleta estacionária" → "bicicleta ergométrica" as Natural Language | ✅ Flagged |
| Tem uma máquina de café nova na sala de reuniões. | Flag "máquina de café" → "cafeteira" as Natural Language | ✅ Flagged |
| A cozinha do apartamento tem máquina de lavar louça. | Flag "máquina de lavar louça" → "lava-louças" as Natural Language | ✅ Flagged |
| Coloquei as roupas na máquina de lavar antes de sair. | No correction — "máquina de lavar" is standard Brazilian usage | ✅ Not flagged |
| Vou fazer um corte de cabelo no sábado. | Flag "fazer um corte de cabelo" → "cortar o cabelo" as Natural Language | ✅ Flagged |

#### Known limitation — test case skew

The positive test cases above are heavily weighted towards the `máquina de X`
construction. Broader coverage across other soft-register patterns (descriptive
nominalisations, verbose verbal phrases, calques not involving "máquina") is
needed to build confidence that the rule generalises correctly. Suggested
additional test cases for future validation passes:

- Verbose verbal phrase: "Fiz uma caminhada" vs "Caminhei" pattern
- Nominalisation calque: "Fazer um passeio" → "Passear"
- Non-máquina circumlocution: "aparelho de televisão" → "televisão" or "TV"
- Register edge case: a sentence where the verbose form is genuinely more
  natural in context, to confirm the model isn't over-flagging

---

## Cross-language

### RG-001 — Off-topic submissions scored Excelente in the retranslation game

**Status:** Resolved
**Affected section:** Retranslation game grading (`GradeRetranslationUseCase`)
**Prompt file:** New standalone `_gradingPromptSpanish` / `_gradingPromptPortuguese` in `prompt_builder.dart`

#### Problem

A submitted answer with zero relation to the expected translation was
graded ¡Excelente! — confirmed live on device, both languages. Example:
expected answer about buying bread at the supermarket; submitted answer
about taking the bus home from work. The grader returned "Toda la frase
está correcta de principio a fin."

#### Root cause

`GameQuestion.expectedAnswer` was never sent to the grading model at all,
for either language. `GradeRetranslationUseCase.call()` forwarded the
attempt straight into the shared `CorrectionService.correctText()` path —
the same path used by the walkthrough feature — which judges grammar and
idiomaticity in isolation. Neither language's correction prompt had any
instruction to compare against a target, because no target was ever given.
This was a single structural gap, not two independently-introduced bugs:
both prompts and the whole request pipeline funnel through the same
underlying call, and neither was ever designed to receive or check a
target sentence.

#### Solution

A dedicated grading path (not a modification of the shared correction
path), with two-stage grading:

1. **Relatedness gate** — a new `is_related` field, judged first. The
   grader is given `expectedAnswer` and `targetCategory` alongside the
   attempt, and marks `is_related = false` only when the attempt addresses
   a completely different topic/situation/action, is empty/illegible, OR
   reverses/negates the core action of the target (e.g. selling instead of
   buying) while keeping the same setting/vocabulary — this last rule was
   added after validation surfaced it as a gap (see below).
2. **Existing tiering** — unchanged, only runs when `is_related = true`.
   `_tierFor`/`_isSubstantive` were not modified.

Implementation: new dedicated `RetranslationGradeResponse` type (not a
change to the shared `CorrectionResponse`), with `fromJson` throwing a
typed exception on a missing/malformed `is_related` rather than silently
defaulting either way. New `CorrectionService.gradeRetranslation(...)`
method, implemented for `OpenAiCorrectionService` (current production
provider); `GeminiCorrectionService` has a compile-only stub pending real
implementation if Gemini becomes selectable again.
`GradeRetranslationUseCase.call()` branches on `isRelated` before touching
tiering logic at all; `_VerdictPanel` shows a distinct honest message
("Esto no aborda la frase objetivo — inténtalo de nuevo." /
"Isso não aborda a frase-alvo — tente de novo.") for the off-topic case,
while the tier identity (label/color/icon) stays the same `siguePracticando`
as the normal "target error not fixed" case — these are two distinct
messages sharing one tier, not a new tier.

#### Validation test cases

Two rounds of validation, both against `gpt-5.5` (the production grading
model):

**Round 1 — standalone 28-case battery (14 Spanish + 14 Portuguese), isolated prompt test:**

| Result | Count |
|---|---|
| Initial run | 26 PASS, 0 FAIL, 0 ERROR, 2 OPEN |
| Fix applied | Added explicit rule + worked example for reversed/negated core actions (buy vs. sell) after the 2 open cases both defaulted to `is_related = true` |
| Re-run | 28 PASS, 0 FAIL, 0 ERROR |

**Round 2 — live production call path (`test/retranslation_grade_validation.dart`, real `OpenAiCorrectionService.gradeRetranslation`, no mocking):**

| Case | isRelated | Tier | Result |
|---|---|---|---|
| es-off-topic-bus-bread | false ✅ | siguePracticando ✅ | Matches — the original bug, confirmed fixed end-to-end |
| pt-off-topic-bus-bread | false ✅ | siguePracticando ✅ | Matches — the original bug, confirmed fixed end-to-end |
| 8 other pre-existing cases | — | — | 6 matched expectation; 2 tier surprises unrelated to this fix (see TC-001, logged separately below) |

Both off-topic regression cases returned zero corrections, confirming the
grader skips correction analysis entirely once `is_related = false`, as
designed.

---

### TC-001 — Trailing-punctuation-only correction misclassified as substantive

**Status:** Open
**Affected section:** `GradeRetranslationUseCase._isSubstantive`
**Discovered during:** RG-001 validation (Round 2, live run), unrelated to
the off-topic fix — logged here so it isn't lost, not fixed as part of RG-001.

#### Problem

Two live-run cases (`es-grammar-fully-clean`, `pt-grammar-clean`) expected
tier `excelente` but received `bienHecho`. In both cases the grader
returned exactly one `Other`-category correction consisting of the entire
original sentence as `original_phrase`, with the only change being an
added trailing period (e.g. `"Voy al cine con mis amigos"` →
`"Voy al cine con mis amigos."`).

#### Root cause

`_isSubstantive` already special-cases punctuation-only insertions, but
only when `original_phrase` is empty (a zero-width insertion). Here the
model instead echoes the full sentence as `original_phrase` with a period
appended — a different correction shape the existing heuristic doesn't
recognize, so it's counted as a substantive error and downgrades the tier.

#### Suggested next step (not yet actioned)

`_isSubstantive` likely needs a second case: treat a correction as
punctuation-only when `corrected_phrase` differs from `original_phrase`
solely by trailing punctuation, not just when `original_phrase` is empty.
Needs its own validation pass before changing — same discipline as RG-001 —
since loosening this heuristic incorrectly could mask genuinely substantive
errors that happen to end in a punctuation change.

---

## Prompt change log

| Date | Language | Section | Change summary |
|---|---|---|---|
| Jun 2026 | Portuguese | Architecture | Replaced runtime replaceAll swap with standalone `_correctionPromptPortuguese` declaration |
| Jun 2026 | Portuguese | Natural language handling | Removed "máquina de correr" from calque bullet; added soft-register bullet (BP-001) |
| Jul 2026 | Cross-language | Retranslation game grading | Added dedicated `is_related` relatedness gate (RG-001) — new grading prompts, new response type, use-case branching before tiering |
