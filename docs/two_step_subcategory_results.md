# Subcategory measurement: results (for build step P.12b)

Andrew ran the measurement that build step P.12a (pull request 213) asked for on 28 Nov 2026, on his Mac: the two-step test program on all 84 sentences, five runs each, once with subcategories off and once with them on. Models: step 1 on GPT-6 Luna, step 2 on GPT-6 Sol.

The run with subcategories on lost 38 of its 420 runs near the end, because the OpenAI account ran out of credit (every one failed with "HTTP 429"). All 38 were in two language points: Ser / Estar / Haber (13 of its 25 runs) and Impersonal Haber / Se (all 25). Andrew then re-ran just those two language points, five runs each, with subcategories on. The combined figures below replace both language points' 50 runs in the main report with the 50 re-run runs, so every one of the 420 runs is a real answer.

## The reports

- `docs/two_step_subcategory_off_5x.md`: subcategories off, 420 runs.
- `docs/two_step_subcategory_on_5x.md`: subcategories on, 420 runs, of which 38 failed for lack of credit.
- `docs/two_step_subcategory_on_ser_estar.md`: re-run of Ser / Estar / Haber, subcategories on, 25 runs.
- `docs/two_step_subcategory_on_haber_se.md`: re-run of Impersonal Haber / Se, subcategories on, 25 runs.

## Combined figures

| | Subcategories off | Subcategories on (combined) |
| --- | --- | --- |
| Pass rate | 396 of 420 (94.3 per cent) | 395 of 420 (94.0 per cent) |
| Sentences with a problem flagged | 346 of 350 (98.9 per cent) | 344 of 350 (98.3 per cent) |
| Clean sentences wrongly flagged | 5 of 70 | 4 of 70 |
| Step 1 average cost per call | $0.000122 | about $0.000168 |
| Step 1 average time per call | 1.95 seconds | 1.4 to 1.7 seconds (see note) |

How the combined "on" figures were worked out:

- Pass rate: 357 in the main report, less the 12 passes it had for Ser / Estar / Haber, plus 25 and 25 from the two re-runs.
- Flagged: 316 in the main report, less the 12 Ser / Estar / Haber runs it flagged, plus 15 and 25 from the re-runs. The 10 clean Ser / Estar runs in the main report had all failed for lack of credit; in the re-run none of the 10 was flagged.
- Cost: the failed calls cost nothing but were counted in the main report's average, which pulled it down to $0.000153. Counting only calls that got an answer gives about $0.000168. That is about $0.00005 more per check, roughly 2 to 3 per cent of a whole check (about $0.0019).
- Time: the failed calls returned quickly, so the main report's 1.63 seconds is a little low; the two re-runs averaged 1.72 and 1.38 seconds. Either way, step 1 was not slower than with subcategories off.

Language points that moved between the two runs (5 runs each unless stated): Collocations / Strong Calques 26 to 24 of 30; False Friends / Word Choice 25 to 23; Gender / Number Agreement 24 to 25; Required Prepositions 24 to 25; Ambiguous / Repeated Span Safety 0 to 1 of 5. All others were the same. These are within the usual run-to-run variation; the overall pass rate is 1 run in 420 apart.

## Subcategories (combined, subcategories on)

**Every one of step 1's 344 items had a subcategory from the list, under its own category.** None was missing, none was off the list, and none was under the wrong category. (316 items in the main report, less the 12 from its Ser / Estar / Haber runs, plus 15 and 25 from the re-runs.)

| Category | Subcategory | Items |
| --- | --- | --- |
| Spelling | Written accents | 53 |
| Spelling | Letters | 31 |
| Spelling | Punctuation and capitals | 0 |
| Grammar | Agreement | 90 |
| Grammar | Prepositions | 40 |
| Grammar | Articles | 35 |
| Grammar | Subjunctive | 30 |
| Grammar | Pronouns | 15 |
| Grammar | Sentence structure | 14 |
| Grammar | Ser and estar | 11 |
| Grammar | Verb forms and tenses | 5 |
| Word Choice | False friends | 17 |
| Word Choice | Mixed-up pairs | 3 |

The 25 Impersonal Haber / Se items ("habían" to "había", "se vende" to "se venden" and so on) were all named Agreement. In the Ser / Estar re-run, "son" to "hay" was named Sentence structure in some runs and Ser and estar in others.

Consistency: where the same change came back in more than one run, it was given a different subcategory from one run to another four times: "devia" to "debía" (Written accents or Letters), "Atendió" to "Asistió a" and "Atendió la universidad" to "Asistió a la universidad" (False friends or Mixed-up pairs), and "son" to "hay" (Sentence structure or Ser and estar).

## Against what P.12a asked for

- The pass rate has not got worse beyond the usual variation: 94.0 against 94.3 per cent.
- Every subcategory is from the list, under its own category: yes, 344 of 344.
- Extra cost and time per call: about $0.00005 more per check, and no extra time.

Whether Andrew is content for the subcategory to go into the app (step P.12b) is his decision; see the "Done outside the plan" list at the end of the Build progress list in `claude/corregir_reset_brief_and_build_plan.md`.
