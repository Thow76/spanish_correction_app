# Walkthrough Question Prompt — Spec

This spec defines the LLM prompt used by the Traducir frases game's walkthrough activity. The walkthrough generates multiple-choice questions that decompose a target sentence into smaller chunks, walking the user through the correct translation one piece at a time. It is triggered when a user scores **KEEP PRACTICING** (and optionally **GOOD**) on a free-production translation attempt, giving them a guided, lower-stakes path to arrive at the correct sentence rather than simply being shown the answer.

## Input contract

The prompt receives four runtime inputs:

1. **targetSentence** (`String`) — The correct Spanish or Portuguese translation of the English source phrase. Sourced from the saved corrected sentence (the assessment-approved version of the user's attempt). The prompt uses this as the ground-truth sentence to decompose into ordered chunks and as the source of the correct answer for each question.

2. **userAttempt** (`String`) — The user's free-production translation attempt. Sourced from the text the user submitted in the game before assessment. The prompt uses this to understand where the user diverged from the target, so questions and distractors can target the specific points they got wrong.

3. **englishSource** (`String`) — The English phrase shown to the user as the prompt to translate. Sourced from `promptPhrase`. The prompt uses this as the meaning the user is trying to express, anchoring each question to what the chunk should convey in English.

4. **corrections** (`List<Correction>`) — The corrections array returned by the assessment API call, using the existing `Correction` model shape from [prompt_builder.dart](lib/core/services/prompt_builder.dart) (`original_phrase`, `corrected_phrase`, `category`, `short_explanation`). The prompt uses these to know which parts of the attempt were wrong and why, so the walkthrough can emphasize the chunks tied to real correction points.

### Note on language selection

Language (Spanish vs Portuguese) is **not** passed as a runtime input. It is encoded in which prompt template is selected — `_walkthroughQuestionPromptSpanish` vs `_walkthroughQuestionPromptPortuguese` — so the language-specific guidance lives in the prompt text itself rather than in a parameter.

## Output contract

The prompt returns a **single JSON object** per call. No prose, markdown, or explanation is returned outside the JSON.

### Top-level shape

| Field | Type | Purpose |
| --- | --- | --- |
| `target_sentence` | `String` | Echo of the `targetSentence` input, returned so the app can validate that the model decomposed the intended sentence and that the concatenated chunks reconstruct it. |
| `questions` | `Array` | The list of multiple-choice questions, **3–5 entries**, one per chunk of the target sentence. |

The `target_sentence` echo is included deliberately: it is cheap, lets the app assert the chunks belong to the sentence it asked about, and guards against the model drifting to a different sentence. If validation is not wanted it can be ignored, but the prompt should always emit it.

### Question object shape

Each entry in `questions` is an object:

| Field | Type | Purpose |
| --- | --- | --- |
| `english_stem` | `String` | The English phrase fragment being tested in this question. |
| `correct_translation` | `String` | The correct target-language translation of the stem, drawn verbatim from the target sentence. |
| `distractors` | `Array<String>` (length 2) | Two plausible wrong answers for the stem. |
| `chunk_position` | `int` | Zero-indexed position of this chunk within the target sentence, used to display chunks in order. |

### Ordering

Questions **must** be returned in ascending `chunk_position` order (0, 1, 2, …) so the UI can render them sequentially without sorting. The `chunk_position` values must be contiguous and start at 0.

### Answer options at render time

The UI shuffles `correct_translation` together with the two `distractors` into a three-option multiple choice at display time. The prompt therefore must **not** pre-shuffle the options or signal which one is correct beyond the field name — `correct_translation` is always the correct answer and the two `distractors` are always wrong.

### Worked example

For the English source "I am going to get my hair cut on Saturday" with target sentence `Vou cortar o cabelo no sábado`, a valid response with three questions:

```json
{
  "target_sentence": "Vou cortar o cabelo no sábado",
  "questions": [
    {
      "english_stem": "I am going",
      "correct_translation": "Vou",
      "distractors": ["Estou indo", "Vai"],
      "chunk_position": 0
    },
    {
      "english_stem": "to get my hair cut",
      "correct_translation": "cortar o cabelo",
      "distractors": ["cortar os cabelos", "pentear o cabelo"],
      "chunk_position": 1
    },
    {
      "english_stem": "on Saturday",
      "correct_translation": "no sábado",
      "distractors": ["em sábado", "no domingo"],
      "chunk_position": 2
    }
  ]
}
```

## Distractor design rules

### Core principle

Distractors must reflect **real learner errors**, not random wrong answers. A distractor's job is to test whether the user can distinguish the correct form from a plausible-but-wrong form they might genuinely produce. If a learner would never write a given option, it is wasted as a distractor — it makes the correct answer obvious and teaches nothing. Every distractor should be something a real student at this level could plausibly choose because it "looks right."

### Error patterns to draw from

Distractors should be built from the kinds of mistakes learners actually make. At minimum, draw from:

- **Person / conjugation confusion** — the right verb in the wrong person or number (e.g. `vou` vs `vai` vs `vem` for "I am going"; `voy` vs `va` vs `vamos`).
- **Wrong preposition / article contraction** — failing to contract, contracting wrongly, or dropping the article (e.g. `em o sábado` vs `no sábado`; `en el sábado` vs `el sábado`).
- **Calques and Spanglish / Portuñol hybrids** — structures carried over from English or from the other Romance language (e.g. `cojer cortar o cabelo`, `para um corto do cabelo`).
- **False friends and natural-language errors** — understandable but non-native word choices, the same category the correction prompt flags as **Natural Language**.
- **Tense / mood slips** — the wrong but adjacent form the user might reach for (e.g. present for an intended future, indicative for an intended subjunctive).

### Anti-patterns to exclude

Do **not** generate distractors that are:

- **Random unrelated vocabulary** — words with no relationship to the stem's meaning.
- **Obviously wrong by part of speech** — e.g. a noun where a verb is clearly required.
- **Grammatically impossible** rather than plausibly wrong — strings no learner would form because they break basic syntax outright.
- **Drawn from a different language entirely** — e.g. an English or French word offered as a target-language option.

A good test: if the distractor is wrong for a *systematic, teachable reason* a learner would recognize after the fact, keep it; if it's wrong because it's nonsense or off-topic, discard it.

### Grounding in the user's attempt

Where the user's actual attempt contains errors relevant to a chunk, those errors should be considered as **candidate distractors**. If the user wrote `em o sábado` for "on Saturday", that is the ideal distractor for that chunk — it makes the activity directly responsive to what the user produced rather than a generic quiz. Use the `corrections` input to identify which chunks the user got wrong and what they wrote, and prefer the user's own error as one of the two distractors when it fits the chunk naturally.

### Worked examples

**Spanish — "I am going" → `voy`**

| Distractor | Error pattern |
| --- | --- |
| `va` | Person confusion — third person for intended first person. |
| `vamos` | Person confusion — first person plural for intended singular. |

**Spanish — "on Saturday" → `el sábado`**

| Distractor | Error pattern |
| --- | --- |
| `en el sábado` | Wrong preposition — inserting `en` where Spanish uses the bare article for days. |
| `en sábado` | Wrong preposition + missing article — calque of English "on Saturday". |

**Portuguese — "to get my hair cut" → `cortar o cabelo`**

| Distractor | Error pattern |
| --- | --- |
| `cojer cortar o cabelo` | Spanglish / Portuñol hybrid — Spanish verb `coger` grafted onto the Portuguese phrase. |
| `para um corto do cabelo` | Calque from English structure ("for a haircut") with an invented noun form. |

**Portuguese — "on Saturday" → `no sábado`**

| Distractor | Error pattern |
| --- | --- |
| `em o sábado` | Uncontracted — failing to contract `em + o` into `no`. |
| `em sábado` | Missing article — dropping the article entirely, calque of English "on Saturday". |

## Chunking rules

### Core principle

Chunks are **meaningful phrase-level units, not individual words**. A chunk should correspond to a translatable unit of meaning that a learner would naturally think of as one piece — "I am going", "to get my hair cut", "on Saturday" — not isolated tokens. The decomposition exists to teach how meaning maps from English to the target language in coherent pieces, so each chunk must be something a learner could meaningfully translate and reason about on its own.

### Target chunk count

Each sentence should decompose into **3 to 5 chunks**.

- **Fewer than 3** means the decomposition isn't doing pedagogical work — the sentence isn't really being broken down.
- **More than 5** means the chunks are likely too granular, or the sentence is too long for this activity.

### Chunk boundary guidance

- **Verb phrases stay together with their auxiliaries** — "I am going" is one chunk, not "I" + "am going".
- **Prepositional phrases stay together with their preposition and object** — "on Saturday" is one chunk, not "on" + "Saturday".
- **Articles stay attached to their nouns** — "the haircut" / "o cabelo" / "el pelo" are not split.
- **Object pronouns and clitics stay attached to their verb** — "me cortaron" / "cortar-se" are single chunks.
- **Compound expressions and fixed phrases are treated as one chunk** — "to get my hair cut" is one unit, not "to get" + "my hair" + "cut".

### Coverage

Every word in the target sentence must belong to **exactly one chunk**. Chunks must be **contiguous and non-overlapping**, and the concatenation of all chunks in `chunk_position` order must reproduce the target sentence (allowing for normal spacing). No word may be dropped, duplicated, or assigned to two chunks.

### Language-specific considerations

- **Clitic pronouns attach to the verb.** Both Spanish and Portuguese attach clitic and object pronouns to verbs; these stay with the verb (e.g. `me cortaron` is one chunk, `cortar-se` is one chunk).
- **Contractions are single chunks.** A preposition + article contraction is never split (e.g. `no sábado`, `del`, `à`, `al`).
- **Reflexive constructions stay whole** — the reflexive marker is kept with its verb (e.g. `cortarme el pelo`).

### Worked examples

**Portuguese — `Vou cortar o cabelo no sábado`** (3 chunks)

| `chunk_position` | Chunk | `english_stem` |
| --- | --- | --- |
| 0 | `Vou` | "I am going" |
| 1 | `cortar o cabelo` | "to get my hair cut" |
| 2 | `no sábado` | "on Saturday" |

**Portuguese — `Amanhã de manhã vou levar as crianças à escola`** (4 chunks)

| `chunk_position` | Chunk | `english_stem` |
| --- | --- | --- |
| 0 | `Amanhã de manhã` | "tomorrow morning" |
| 1 | `vou levar` | "I am going to take" |
| 2 | `as crianças` | "the kids" |
| 3 | `à escola` | "to school" |

**Spanish — `Voy a cortarme el pelo el sábado`** (3 chunks)

| `chunk_position` | Chunk | `english_stem` |
| --- | --- | --- |
| 0 | `Voy a` | "I am going to" |
| 1 | `cortarme el pelo` | "to get my hair cut" |
| 2 | `el sábado` | "on Saturday" |

**Spanish — `Mañana por la mañana voy a llevar a los niños al colegio`** (4 chunks)

| `chunk_position` | Chunk | `english_stem` |
| --- | --- | --- |
| 0 | `Mañana por la mañana` | "tomorrow morning" |
| 1 | `voy a llevar` | "I am going to take" |
| 2 | `a los niños` | "the kids" |
| 3 | `al colegio` | "to school" |

### English stems should be natural English

The English stems shown to the user (`english_stem`) should be **natural English phrases** corresponding to each chunk, not literal word-for-word glosses. "to get my hair cut" is a better stem than "to cut the hair", even though the latter is structurally closer to the target — the stem is the meaning the learner is translating *from*, so it should read the way an English speaker would actually say it.

## Edge cases

### Very short sentences (2 natural chunks)

Some target sentences are short enough (roughly 3–4 words) that they decompose into only **two** natural chunks. The chunking rules call for 3–5 chunks, but forcing a third chunk onto such a sentence produces unnatural decompositions — splitting a verb phrase, isolating an article, or breaking a contraction.

In this case the prompt should **prefer 2 chunks over a forced split**. This is the **one allowed exception** to the 3–5 range; it applies only when no third boundary exists that respects the chunk boundary rules. The prompt must never split a verb phrase, preposition + object, article + noun, or contraction just to reach three chunks.

**Portuguese — `Vou para casa`** (2 chunks)

| `chunk_position` | Chunk | `english_stem` |
| --- | --- | --- |
| 0 | `Vou` | "I am going" |
| 1 | `para casa` | "home" |

**Spanish — `Voy a casa`** (2 chunks)

| `chunk_position` | Chunk | `english_stem` |
| --- | --- | --- |
| 0 | `Voy` | "I am going" |
| 1 | `a casa` | "home" |

### Attempt too far from target to align

When the user's attempt is so far from the target that no meaningful chunk-level alignment is possible (e.g. they translated a different idea, left the field nearly empty, or produced unrelated text), the prompt cannot mine the attempt for chunk-relevant errors. In this case it should **fall back to generic error-pattern distractors** drawn from the patterns in *Distractor design rules* rather than forcing a tie to the attempt. The decomposition of the target sentence proceeds normally; only the grounding of distractors changes.

### Attempt essentially correct, scored KEEP PRACTICING on one critical error

Sometimes the attempt is nearly right but scored KEEP PRACTICING because of a single critical error that changes the meaning (e.g. wrong verb tense). The prompt should **still produce a full 3–5 chunk decomposition** of the whole sentence, not just a question about the broken part. The walkthrough exists to reinforce the entire structure, so the user re-confirms the parts they got right and is guided through the part they missed in context.

### Proper nouns, numbers, and untranslated foreign words

A chunk may consist of a proper noun, a number, or an untranslated foreign word. These are **valid chunks on their own**, or may be attached to their immediate context (e.g. `a Lisboa`, `el 15 de mayo`) where that forms a more natural unit. Because these elements are not translated, their distractors should reflect **common transcription or spelling errors** (wrong accent, misheard digit, misspelled name) rather than translation errors. For example, distractors for `sábado` as a date word target spelling/accent slips, not a different word.

### Multiple valid translations for a chunk

Where more than one valid translation exists for a chunk across regional varieties (e.g. "the car" → `el coche` or `el auto`), `correct_translation` must match the **form used in the target sentence**. A regional alternative may appear as a distractor **only if it would be incorrect in the target sentence's register or variety** — not merely different. If both forms would be acceptable in that register, the alternative is not a valid distractor (it would penalize a correct answer); choose a genuinely wrong form instead.

## Open questions

### Score tier as an input for difficulty

The spec intro notes the walkthrough triggers on KEEP PRACTICING and *optionally* GOOD, but the score tier is not among the four inputs. Should the prompt receive the tier so it can scale question difficulty (e.g. harder, closer distractors for GOOD)?

- **Options:** (a) add `scoreTier` as a fifth input and branch difficulty on it; (b) keep the prompt tier-agnostic and treat all walkthroughs identically.
- **Recommendation:** defer unless GOOD-triggered walkthroughs ship. If they do, add `scoreTier` — it's a cheap input and difficulty tuning is the main reason to distinguish the tiers. Until then, keep the contract at four inputs.

### Source of `english_stem`: generated vs. aligned

`english_stem` is currently produced by the prompt as a natural English phrase per chunk. But `englishSource` is already a runtime input. Should stems be generated freely, or derived by aligning `englishSource` to the chunks?

- **Options:** (a) prompt generates stems freely (current spec); (b) prompt segments the provided `englishSource` into spans aligned to the chunks; (c) hybrid — align where clean, generate where the English and target structures diverge.
- **Recommendation:** keep generation (a), but instruct the prompt to stay faithful to `englishSource` wording where it aligns cleanly, so stems read as fragments of the phrase the user actually saw. Strict span alignment (b) breaks down whenever word order differs between English and the target (which is common), so it shouldn't be a hard requirement.

### Malformed JSON handling

The output contract requires a single JSON object, but nothing specifies what the app does if the model returns malformed or schema-invalid JSON.

- **Options:** (a) retry the call once (optionally with a stricter "return valid JSON only" reminder) before surfacing an error; (b) surface the error immediately and skip the walkthrough.
- **Recommendation:** retry once, then fall back gracefully — skip the walkthrough and let the user proceed rather than blocking the game flow on a transient formatting failure. Validate against the schema (field presence, `distractors` length 2, contiguous `chunk_position`) before accepting.

### Walkthrough trigger on GOOD

The intro hedges with "(and optionally GOOD)". Whether GOOD actually triggers the walkthrough is unresolved and affects both the trigger logic and the score-tier question above.

- **Recommendation:** decide explicitly before implementation. Ship KEEP PRACTICING first; treat GOOD as a follow-up that also resolves the `scoreTier` input question.

### Distractor distinctness validation

The spec says each question has two wrong distractors but does not state that distractors must be distinct from `correct_translation` and from each other. A collision would render the three-option multiple choice degenerate (two identical options, or no wrong answer).

- **Recommendation:** require the prompt to emit two distractors that differ from each other and from `correct_translation`, and have the app validate this on receipt, treating a collision the same as malformed JSON.

### Reconciling the 3–5 range with the 2-chunk exception

The output contract states 3–5 questions, while *Edge cases* permits 2 for very short sentences. The app's validation must accept 2–5 so the exception isn't rejected as malformed.

- **Recommendation:** state the accepted range as **2–5** in validation, with 3–5 as the expected/typical range and 2 reserved for sentences with no valid third boundary. Consider tightening the output-contract wording to reference this exception explicitly.
