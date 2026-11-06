# Two-Pass Linear (Serial) Execution Flow (issue #128)

## Methodology (issue #132)

**This is a proof-of-concept report for a SERIAL two-pass architecture, not the production parallel/fallback pipeline.** Numbers here describe a prototype under evaluation, not production behavior — for the production-equivalent pipeline's own report, see `buildLinearPipelineComparisonReport` (linear vs. parallel, side by side) or `two_pass_fallback_pipeline_comparison_harness.dart`'s reports.

- **Pass 1** corrects grammar, spelling, and punctuation using the revised first-pass prompt (issue #126, `linearFirstPassPrompt`, sourced from `Two-Pass_Prompt_Revision_Summary.docx`) with model `gpt-4.1`.
- **Pass 2** is a lexical-transfer review using the revised second-pass prompt (issue #127, `linearSecondPassPrompt`, same source document) with model `gpt-5.1`. Pass 2 reviews Pass 1's OWN corrected text, never the original submitted text.
- **No fallback path**: production's parallel pipeline re-runs naturalness against the first-pass output only when its concurrent merge conflicts. This serial flow never needs that — Pass 2 always reviews the exact text it will be merged into, so there is nothing left to fall back from.
- **No parallel merge step**: Pass 1 and Pass 2 run one after another, never concurrently, so there are never two independent naturalness calls to reconcile the way production's pipeline has.
- **Purpose**: measure whether this simpler serial architecture is as reliable, as fast, and as cheap as production's parallel + conditional-fallback design.

## Run configuration

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture count: `5`
- Total runs: `15`
- Generated: 2026-08-09T22:24:20.843198Z

## Fixture summary

Pass rate is `passed/runs`; "distinct outputs" lists every unique final output produced across a fixture's runs — more than one entry means the model was not stable for that fixture.

| Fixture | Language point | Runs | Pass rate | Distinct final outputs | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| delete-repeated-yo-estudio | Unnecessary Extras / Deletions | 3 | 0/3 | `Yo trabajo mucho y yo estudio por las noches.` | 7089 | $0.005417 |
| delete-repeated-ellos-visitaron | Unnecessary Extras / Deletions | 3 | 0/3 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | 5213 | $0.005518 |
| delete-repeated-a-mi | Unnecessary Extras / Deletions | 3 | 3/3 | `A mí me gusta el café.` | 5211 | $0.006103 |
| delete-repeated-yo-compre | Unnecessary Extras / Deletions | 3 | 0/3 | `Yo fui al mercado y yo compré pan.` | 5012 | $0.005417 |
| delete-repeated-nosotros | Unnecessary Extras / Deletions | 3 | 0/3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | 5148 | $0.005484 |

## Unnecessary Extras / Deletions

### delete-repeated-yo-estudio

- Original text: `Yo trabajo mucho y yo estudio por las noches.`
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- Pass rate: 0/3
- Distinct final outputs:
  - `Yo trabajo mucho y yo estudio por las noches.`

| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Yo trabajo mucho y yo estudio por las noches.` | (none) | (none) | `Yo trabajo mucho y yo estudio por las noches.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 1527 | $0.000878 | 1549 | $0.000928 | 3076 | $0.001806 |
| 2 | 568 | $0.000878 | 1230 | $0.000928 | 1798 | $0.001806 |
| 3 | 873 | $0.000878 | 1342 | $0.000928 | 2215 | $0.001806 |

### delete-repeated-ellos-visitaron

- Original text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Expected corrected text: `Ellos viajaron a México y visitaron varias ciudades.`
- Pass rate: 0/3
- Distinct final outputs:
  - `Ellos viajaron a México y ellos visitaron varias ciudades.`

| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | (none) | (none) | `Ellos viajaron a México y ellos visitaron varias ciudades.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 782 | $0.000908 | 1229 | $0.000931 | 2011 | $0.001839 |
| 2 | 587 | $0.000908 | 1115 | $0.000931 | 1702 | $0.001839 |
| 3 | 578 | $0.000908 | 922 | $0.000931 | 1500 | $0.001839 |

### delete-repeated-a-mi

- Original text: `A mí me gusta el café a mí.`
- Expected corrected text: `A mí me gusta el café.`
- Pass rate: 3/3
- Distinct final outputs:
  - `A mí me gusta el café.`

| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `A mí me gusta el café.` | A mí me gusta el café a mí. -> A mí me gusta el café. (redundant phrase / pronoun repetition) | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 2 | `A mí me gusta el café.` | A mí me gusta el café a mí. -> A mí me gusta el café. (redundancy) | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 3 | `A mí me gusta el café.` | A mí me gusta el café a mí. -> A mí me gusta el café. (redundant pronoun) | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 785 | $0.001132 | 917 | $0.000924 | 1702 | $0.002056 |
| 2 | 682 | $0.001092 | 1135 | $0.000924 | 1817 | $0.002016 |
| 3 | 702 | $0.001108 | 990 | $0.000924 | 1692 | $0.002032 |

### delete-repeated-yo-compre

- Original text: `Yo fui al mercado y yo compré pan.`
- Expected corrected text: `Fui al mercado y compré pan.`
- Pass rate: 0/3
- Distinct final outputs:
  - `Yo fui al mercado y yo compré pan.`

| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Yo fui al mercado y yo compré pan.` | (none) | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Yo fui al mercado y yo compré pan.` | (none) | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Yo fui al mercado y yo compré pan.` | (none) | (none) | `Yo fui al mercado y yo compré pan.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 580 | $0.000878 | 981 | $0.000928 | 1561 | $0.001806 |
| 2 | 726 | $0.000878 | 1023 | $0.000928 | 1749 | $0.001806 |
| 3 | 576 | $0.000878 | 1126 | $0.000928 | 1702 | $0.001806 |

### delete-repeated-nosotros

- Original text: `Nosotros salimos temprano y nosotros llegamos a tiempo.`
- Expected corrected text: `Nosotros salimos temprano y llegamos a tiempo.`
- Pass rate: 0/3
- Distinct final outputs:
  - `Nosotros salimos temprano y nosotros llegamos a tiempo.`

| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 2 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |
| 3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | (none) | (none) | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | missed_issue | Fail | Left the text unchanged, but that did not match the expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 681 | $0.000898 | 1022 | $0.000930 | 1703 | $0.001828 |
| 2 | 886 | $0.000898 | 888 | $0.000930 | 1774 | $0.001828 |
| 3 | 611 | $0.000898 | 1060 | $0.000930 | 1671 | $0.001828 |

---

## Overall summary

| Metric | Value |
| --- | --- |
| Fixtures | 5 |
| Total runs | 15 |
| Pass rate | 3/15 |

### Score breakdown (issue #129 — full taxonomy, not only pass/fail)

| | Total | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| All runs | 15 | 3 | 0 | 12 | 0 | 0 | 0 | 0 |

### Latency / cost by pass (issue #130 — no fallback phase exists in this harness, so totals equal Pass 1 + Pass 2 only)

| Phase | Total latency (ms) | Total est. cost (USD) |
| --- | --- | --- |
| Pass 1 (first pass) | 11144 | $0.014018 |
| Pass 2 (lexical review) | 16529 | $0.013920 |
| **Total (Pass 1 + Pass 2)** | 27673 | $0.027938 |
