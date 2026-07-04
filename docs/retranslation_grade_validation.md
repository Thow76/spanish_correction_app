# Re-translation Grade Validation

Model: `gpt-5.5`  
Generated: 2026-07-04T22:49:04.258013

## es-grammar-present  ✅

- Language: spanish
- English: I am going to get my hair cut on Saturday
- Attempt: `Voy a cortar mi pelo en sábado`
- Expected answer: `Voy a cortar mi pelo el sábado.`
- Saved category judged: **Grammar**
- Related: **true** ✅ (expected true)
- Tier: **siguePracticando** ✅ (expected siguePracticando)
- Category errors (count 1): Grammar:"en sábado"→"el sábado"
- All corrections (count 1): Grammar:"en sábado"→"el sábado"
- Note: Preposition "en sábado" is a grammar error; expect KEEP PRACTICING.

## es-grammar-clean-spelling-noise  ✅

- Language: spanish
- English: I want to eat breakfast early tomorrow
- Attempt: `Quiero desayunar tenprano mañana`
- Expected answer: `Quiero desayunar temprano mañana.`
- Saved category judged: **Grammar**
- Related: **true** ✅ (expected true)
- Tier: **bienHecho** ✅ (expected bienHecho)
- Category errors (count 0): (none)
- All corrections (count 1): Spelling:"tenprano"→"temprano"
- Note: "tenprano" is a spelling slip (other category); grammar (the target) is clean, so the target is fixed — but the spelling error leaves the sentence unclean, so expect Bien hecho (not Excelente; the noise must NOT flip it to Sigue practicando).

## es-grammar-fully-clean  ⚠️

- Language: spanish
- English: I am going to the cinema with my friends
- Attempt: `Voy al cine con mis amigos`
- Expected answer: `Voy al cine con mis amigos.`
- Saved category judged: **Grammar**
- Related: **true** ✅ (expected true)
- Tier: **bienHecho** ⚠️ (expected excelente)
- Category errors (count 0): (none)
- All corrections (count 1): Other:"Voy al cine con mis amigos"→"Voy al cine con mis amigos."
- Note: A clean attempt; expect well done.

## es-wordchoice-present  ✅

- Language: spanish
- English: I realised I forgot my keys
- Attempt: `Realicé que olvidé mis llaves`
- Expected answer: `Me di cuenta de que olvidé mis llaves.`
- Saved category judged: **Word Choice**
- Related: **true** ✅ (expected true)
- Tier: **siguePracticando** ✅ (expected siguePracticando)
- Category errors (count 1): Word Choice:"Realicé que"→"Me di cuenta de que"
- All corrections (count 2): Word Choice:"Realicé que"→"Me di cuenta de que"; Other:"llaves"→"llaves."
- Note: "Realicé" as a calque of "realised" is a word-choice error (should be "Me di cuenta de"); expect KEEP PRACTICING.

## es-off-topic-bus-bread  ✅

- Language: spanish
- English: I went to the supermarket to buy bread
- Attempt: `Tomé el autobús a casa desde el trabajo.`
- Expected answer: `Fui al supermercado a comprar pan.`
- Saved category judged: **Grammar**
- Related: **false** ✅ (expected false)
- Tier: **siguePracticando** ✅ (expected siguePracticando)
- Category errors (count 0): (none)
- All corrections (count 0): (none)
- Note: Off-topic regression case: the attempt is about taking the bus home from work, an entirely different scenario from buying bread at the supermarket. Expect isRelated: false and Sigue practicando WITHOUT the category/tier logic ever running (categoryErrors must be empty even though the attempt happens to contain a grammar-shaped phrase).

## pt-grammar-present  ✅

- Language: portuguese
- English: I am going to take the kids to school
- Attempt: `Vou levar as crianças em a escola`
- Expected answer: `Vou levar as crianças à escola.`
- Saved category judged: **Grammar**
- Related: **true** ✅ (expected true)
- Tier: **siguePracticando** ✅ (expected siguePracticando)
- Category errors (count 1): Grammar:"em a escola"→"à escola"
- All corrections (count 1): Grammar:"em a escola"→"à escola"
- Note: Uncontracted "em a escola" (should be "à escola"); expect KEEP PRACTICING.

## pt-grammar-clean  ⚠️

- Language: portuguese
- English: I am going home on Saturday
- Attempt: `Vou para casa no sábado`
- Expected answer: `Vou para casa no sábado.`
- Saved category judged: **Grammar**
- Related: **true** ✅ (expected true)
- Tier: **bienHecho** ⚠️ (expected excelente)
- Category errors (count 0): (none)
- All corrections (count 1): Other:"Vou para casa no sábado"→"Vou para casa no sábado."
- Note: A clean attempt; expect well done.

## pt-naturallanguage-present  ✅

- Language: portuguese
- English: It is raining a lot today
- Attempt: `Está fazendo muita chuva hoje`
- Expected answer: `Está chovendo muito hoje.`
- Saved category judged: **Natural Language**
- Related: **true** ✅ (expected true)
- Tier: **siguePracticando** ✅ (expected siguePracticando)
- Category errors (count 1): Natural Language:"Está fazendo muita chuva"→"Está chovendo muito"
- All corrections (count 1): Natural Language:"Está fazendo muita chuva"→"Está chovendo muito"
- Note: "fazendo chuva" is unnatural (native: "chovendo muito"); expect KEEP PRACTICING if flagged as Natural Language.

## pt-spelling-saved-grammar-clean  ✅

- Language: portuguese
- English: I bought a new car yesterday
- Attempt: `Comprei um carro novo ontén`
- Expected answer: `Comprei um carro novo ontem.`
- Saved category judged: **Grammar**
- Related: **true** ✅ (expected true)
- Tier: **bienHecho** ✅ (expected bienHecho)
- Category errors (count 0): (none)
- All corrections (count 1): Spelling:"ontén"→"ontem"
- Note: "ontén" is a spelling slip (other category); grammar (the target) is clean, so the target is fixed — but the spelling error leaves the sentence unclean, so expect Bien hecho.

## pt-off-topic-bus-bread  ✅

- Language: portuguese
- English: I went to the supermarket to buy bread
- Attempt: `Peguei o ônibus para casa depois do trabalho.`
- Expected answer: `Fui ao supermercado comprar pão.`
- Saved category judged: **Grammar**
- Related: **false** ✅ (expected false)
- Tier: **siguePracticando** ✅ (expected siguePracticando)
- Category errors (count 0): (none)
- All corrections (count 0): (none)
- Note: Off-topic regression case: the attempt is about taking the bus home from work, an entirely different scenario from buying bread at the supermarket. Expect isRelated: false and Sigue practicando WITHOUT the category/tier logic ever running (categoryErrors must be empty even though the attempt happens to contain a grammar-shaped phrase).

---

Cases: 10 · Matched expectation (tier + related): 8 · Surprises: 2 · Grader errors: 0
