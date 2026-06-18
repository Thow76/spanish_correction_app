# Re-translation Grade Validation

Model: `gpt-4.1-mini`  
Generated: 2026-06-17T18:36:51.719302

## es-grammar-present  ✅

- Language: spanish
- English: I am going to get my hair cut on Saturday
- Attempt: `Voy a cortar mi pelo en sábado`
- Saved category judged: **Grammar**
- Tier: **keepPracticing** (expected keepPracticing)
- Category errors (count 3): Grammar:"mi"→"me"; Grammar:"pelo"→"el pelo"; Grammar:"en sábado"→"el sábado."
- All corrections (count 3): Grammar:"mi"→"me"; Grammar:"pelo"→"el pelo"; Grammar:"en sábado"→"el sábado."
- Note: Preposition "en sábado" is a grammar error; expect KEEP PRACTICING.

## es-grammar-clean-spelling-noise  ✅

- Language: spanish
- English: I want to eat breakfast early tomorrow
- Attempt: `Quiero desayunar tenprano mañana`
- Saved category judged: **Grammar**
- Tier: **wellDone** (expected wellDone)
- Category errors (count 0): (none)
- All corrections (count 1): Spelling:"tenprano"→"temprano"
- Note: "tenprano" is a spelling slip (other category); grammar is clean, so expect well done — the spelling noise must NOT flip the verdict.

## es-grammar-fully-clean  ✅

- Language: spanish
- English: I am going to the cinema with my friends
- Attempt: `Voy al cine con mis amigos`
- Saved category judged: **Grammar**
- Tier: **wellDone** (expected wellDone)
- Category errors (count 0): (none)
- All corrections (count 1): Grammar:""→"."
- Note: A clean attempt; expect well done.

## es-wordchoice-present  ⚠️

- Language: spanish
- English: I realised I forgot my keys
- Attempt: `Realicé que olvidé mis llaves`
- Saved category judged: **Word Choice**
- Tier: **wellDone** (expected keepPracticing)
- Category errors (count 0): (none)
- All corrections (count 2): Natural Language:"Realicé"→"Me di cuenta"; Grammar:" "→" de "
- Note: "Realicé" as a calque of "realised" is a word-choice error (should be "Me di cuenta de"); expect KEEP PRACTICING.

## pt-grammar-present  ✅

- Language: portuguese
- English: I am going to take the kids to school
- Attempt: `Vou levar as crianças em a escola`
- Saved category judged: **Grammar**
- Tier: **keepPracticing** (expected keepPracticing)
- Category errors (count 1): Grammar:"em"→"à"
- All corrections (count 1): Grammar:"em"→"à"
- Note: Uncontracted "em a escola" (should be "à escola"); expect KEEP PRACTICING.

## pt-grammar-clean  ✅

- Language: portuguese
- English: I am going home on Saturday
- Attempt: `Vou para casa no sábado`
- Saved category judged: **Grammar**
- Tier: **wellDone** (expected wellDone)
- Category errors (count 0): (none)
- All corrections (count 1): Grammar:""→"."
- Note: A clean attempt; expect well done.

## pt-naturallanguage-present  ✅

- Language: portuguese
- English: It is raining a lot today
- Attempt: `Está fazendo muita chuva hoje`
- Saved category judged: **Natural Language**
- Tier: **keepPracticing** (expected keepPracticing)
- Category errors (count 1): Natural Language:"Está fazendo"→"Está chovendo"
- All corrections (count 3): Natural Language:"Está fazendo"→"Está chovendo"; Grammar:"muita"→"muito"; Grammar:""→"."
- Note: "fazendo chuva" is unnatural (native: "chovendo muito"); expect KEEP PRACTICING if flagged as Natural Language.

## pt-spelling-saved-grammar-clean  ✅

- Language: portuguese
- English: I bought a new car yesterday
- Attempt: `Comprei um carro novo ontén`
- Saved category judged: **Grammar**
- Tier: **wellDone** (expected wellDone)
- Category errors (count 0): (none)
- All corrections (count 0): (none)
- Note: "ontén" is a spelling slip (other category); grammar is clean, so expect well done.

---

Cases: 8 · Tier matched expectation: 7 · Surprises: 1 · Grader errors: 0
