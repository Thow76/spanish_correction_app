# Category Tiebreak Transfer Battery

Model: `gpt-5.5`  
Commit: `15dac00325063bdfa321e8e468a3e514910b9302`  
Generated: 2026-07-22T10:48:34.634167  
Runs per case: 10

## GWC-anchor

Rule tested: Never use Word Choice merely because the correction changes one token (existential "haber" agreement)  
Note: Existential "haber" wrongly pluralized to agree with its complement. Only one token changes (habían -> había) — the consolidated principle exists specifically so this stays Grammar rather than drifting to Word Choice.

### GWC-anchor

- Label: habían muchos coches -> Grammar
- Text: `En la fiesta habían muchos coches aparcados en la calle.`
- Flagged phrase: "habían muchos coches"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## GWC-T1

Rule tested: Same rule as GWC-anchor, transfer to an unnamed construction  
Note: Impersonal "hacer" with a time-duration expression is invariable ("hacía dos años", never "hacían"), same one-token-agreement shape as existential "haber" but a different verb, never mentioned in the added rules.

### GWC-T1

- Label: Hacían dos años -> Grammar
- Text: `Hacían dos años que vivía allí cuando decidió mudarse.`
- Flagged phrase: "Hacían dos años"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## SG-anchor

Rule tested: Mandatory contraction (al/del) is Grammar, even though it looks like a spelling/fusion issue  
Note: Missing the obligatory a+el -> al contraction.

### SG-anchor

- Label: a el mercado -> Grammar
- Text: `Fui a el mercado esta mañana.`
- Flagged phrase: "a el mercado"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## SG-T1

Rule tested: Same rule as SG-anchor, transfer to the suppletive-form half  
Note: Con + mí is not valid Spanish; the suppletive form "conmigo" is obligatory. Same Grammar rule as the al/del contraction, but a genuinely different error shape (a suppletive pronoun form, not a preposition+article fusion).

### SG-T1

- Label: con mí -> Grammar
- Text: `¿Quieres venir con mí al cine?`
- Flagged phrase: "con mí"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## WCO-anchor

Rule tested: CONTINUITY BASELINE, not one of the five new rules — dialectal taboo vocabulary is Other via the pre-existing, unmodified Restraint paragraph  
Note: Same text as `COG-anchor`/`CTRL-coger` in verdict_battery_merged.dart, reused for continuity. Included so the report shows whether the five new Boundary-rule additions coexist with the older Restraint mechanism without regressing it — not itself evidence about the new rules.

### WCO-anchor

- Label: coger el autobús -> dialectal/Other
- Text: `Voy a coger el autobús para ir al centro.`
- Flagged phrase: "coger el autobús"
- Expected verdict: dialectal
- Expected category: Other

#### Summary (10 runs, 0 error(s))

- Verdict distribution: dialectal: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Other: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=dialectal, category=Other, occurrence=1
- Run 2: verdict=dialectal, category=Other, occurrence=1
- Run 3: verdict=dialectal, category=Other, occurrence=1
- Run 4: verdict=dialectal, category=Other, occurrence=1
- Run 5: verdict=dialectal, category=Other, occurrence=1
- Run 6: verdict=dialectal, category=Other, occurrence=1
- Run 7: verdict=dialectal, category=Other, occurrence=1
- Run 8: verdict=dialectal, category=Other, occurrence=1
- Run 9: verdict=dialectal, category=Other, occurrence=1
- Run 10: verdict=dialectal, category=Other, occurrence=1

## GO-anchor

Rule tested: Pronoun/clitic case, agreement, order, placement, or doubling is Grammar, never Other  
Note: Reused verbatim from `SLD-1` in verdict_battery_merged.dart for continuity. "El secreto" is singular, so the correct clitic is "se lo dije"; "se los" wrongly extends plural marking onto the direct-object clitic — a clitic-agreement error.

### GO-anchor

- Label: se los dije -> Grammar
- Text: `Mis padres querían saber el secreto y se los dije.`
- Flagged phrase: "se los dije"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## GO-T1

Rule tested: Same rule as GO-anchor, transfer to a clitic-order error  
Note: Reflexive/dative clitic cluster order is fixed (se before me); "me se cayó" reverses it. Same Grammar-never-Other rule as the clitic-agreement case above, but the specific defect is order, not agreement.

### GO-T1

- Label: me se cayó -> Grammar
- Text: `Estábamos lavando los platos cuando me se cayó el vaso de las manos.`
- Flagged phrase: "me se cayó"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

## CHAIN-SS-1

Rule tested: Composition: the se/sé accent rule and the contraction rule must not bleed into each other  
Note: One sentence, three flagged phrases sent to Stage 2 together in a single call (not three separate calls) — the point is whether having a Grammar-flagged contraction ("a el") in the same context pulls the unrelated accent error ("Se") into Grammar too, or causes the correct suppletive form ("conmigo") to be overcorrected by proximity to the other two errors.

### CHAIN-SS-1-accent

- Label: Se -> Spelling (missing accent, unrelated to contraction)
- Text: `Se amable y ven a el cine conmigo.`
- Flagged phrase: "Se"
- Expected verdict: error
- Expected category: Spelling

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Spelling: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Spelling, occurrence=1
- Run 2: verdict=error, category=Spelling, occurrence=1
- Run 3: verdict=error, category=Spelling, occurrence=1
- Run 4: verdict=error, category=Spelling, occurrence=1
- Run 5: verdict=error, category=Spelling, occurrence=1
- Run 6: verdict=error, category=Spelling, occurrence=1
- Run 7: verdict=error, category=Spelling, occurrence=1
- Run 8: verdict=error, category=Spelling, occurrence=1
- Run 9: verdict=error, category=Spelling, occurrence=1
- Run 10: verdict=error, category=Spelling, occurrence=1

### CHAIN-SS-1-contraction

- Label: a el -> Grammar (mandatory contraction)
- Text: `Se amable y ven a el cine conmigo.`
- Flagged phrase: "a el"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1
- Run 2: verdict=error, category=Grammar, occurrence=1
- Run 3: verdict=error, category=Grammar, occurrence=1
- Run 4: verdict=error, category=Grammar, occurrence=1
- Run 5: verdict=error, category=Grammar, occurrence=1
- Run 6: verdict=error, category=Grammar, occurrence=1
- Run 7: verdict=error, category=Grammar, occurrence=1
- Run 8: verdict=error, category=Grammar, occurrence=1
- Run 9: verdict=error, category=Grammar, occurrence=1
- Run 10: verdict=error, category=Grammar, occurrence=1

### CHAIN-SS-1-suppletive

- Label: conmigo -> correct as-is, not_an_error
- Text: `Se amable y ven a el cine conmigo.`
- Flagged phrase: "conmigo"
- Expected verdict: not_an_error
- Expected category: (none)

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

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

## CHAIN-REFL-1

Rule tested: Reflexive/non-reflexive verb pairs: obligatory-reflexive branch is Grammar  
Note: Live run against the original "no standard non-reflexive use" wording (docs/category_tiebreak_battery.md, commit 15dac00) showed the model proposing the correct fix ("Se levantó") in 10/10 runs, but categorizing it Grammar only 1/10 times and Natural Language 9/10 — that wording let the model justify Natural Language by pointing to "levantar"'s other uses (levantar pesas, levantar la mano) even in a sentence where the reflexive is the only complete reading. The rule was sharpened to judge the specific sentence as written rather than the verb's uses elsewhere in Spanish — this sentence has no valid non-reflexive object, so under the sharpened rule the missing "se" stays Grammar. Sentence deliberately avoids "coger" — a word with its own dialectal/taboo history elsewhere in this project's testing — so nothing else in the sentence competes for the model's attention on the one error under test. captureCorrectedPhrase is on for this check so the report shows what fix the model actually proposes, not just its verdict and category.

### CHAIN-REFL-1

- Label: Levantó -> Grammar (missing obligatory reflexive)
- Text: `Levantó temprano y desayunó con calma.`
- Flagged phrase: "Levantó"
- Expected verdict: error
- Expected category: Grammar

#### Summary (10 runs, 0 error(s))

- Verdict distribution: error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: Grammar: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)

#### Run detail

- Run 1: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 2: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 3: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 4: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 5: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 6: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 7: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 8: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 9: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"
- Run 10: verdict=error, category=Grammar, occurrence=1, corrected_phrase="Se levantó"

## CHAIN-REFL-2

Rule tested: Reflexive/non-reflexive verb pairs: alternating-complement branch must not be overcorrected across the alternation  
Note: Comparative pair across two separate sentences, two separate Stage 2 calls (not one sentence with two phrases — "decidir el color" and "decidirse por el azul" are different sentences). Both sentences as given are independently correct Spanish: "decidir" + direct object vs. "decidirse" + por-phrase are different, equally valid complement patterns. This does NOT test miscategorizing a genuine complement-mismatch error as Natural Language (neither sentence contains an error) — it tests the narrower claim that the model does not treat the two patterns as a single right/wrong pair and "correct" one into the other's shape.

### CHAIN-REFL-2-directObject

- Label: Decidí el color del coche -> not_an_error (decidir + direct object)
- Text: `Decidí el color del coche.`
- Flagged phrase: "Decidí el color del coche"
- Expected verdict: not_an_error
- Expected category: (none)

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

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

### CHAIN-REFL-2-porPhrase

- Label: Me decidí por el azul -> not_an_error (decidirse + por-phrase)
- Text: `Me decidí por el azul.`
- Flagged phrase: "Me decidí por el azul"
- Expected verdict: not_an_error
- Expected category: (none)

#### Summary (10 runs, 0 error(s))

- Verdict distribution: not_an_error: 10 -> convergence 100.0% (10/10) -> caught 100.0% (10/10)
- Category distribution: (none): 10 -> convergence 100.0% (10/10)

#### Run detail

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

