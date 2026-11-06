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
- Generated: 2026-08-09T23:25:56.169501Z

## Fixture summary

Pass rate is `passed/runs`; "distinct outputs" lists every unique final output produced across a fixture's runs — more than one entry means the model was not stable for that fixture.

| Fixture | Language point | Runs | Pass rate | Distinct final outputs | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| delete-repeated-yo-estudio | Unnecessary Extras / Deletions | 3 | 0/3 | `Yo trabajo mucho y yo estudio por las noches.` | 6705 | $0.005548 |
| delete-repeated-ellos-visitaron | Unnecessary Extras / Deletions | 3 | 0/3 | `Ellos viajaron a México y ellos visitaron varias ciudades.` | 6339 | $0.005650 |
| delete-repeated-a-mi | Unnecessary Extras / Deletions | 3 | 3/3 | `A mí me gusta el café.` | 5622 | $0.006243 |
| delete-repeated-yo-compre | Unnecessary Extras / Deletions | 3 | 0/3 | `Yo fui al mercado y yo compré pan.` | 5020 | $0.005548 |
| delete-repeated-nosotros | Unnecessary Extras / Deletions | 3 | 0/3 | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | 5000 | $0.005616 |

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
| 1 | 1597 | $0.000922 | 1395 | $0.000928 | 2992 | $0.001850 |
| 2 | 783 | $0.000922 | 1007 | $0.000928 | 1790 | $0.001850 |
| 3 | 777 | $0.000922 | 1146 | $0.000928 | 1923 | $0.001850 |

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
| 1 | 679 | $0.000952 | 1057 | $0.000931 | 1736 | $0.001883 |
| 2 | 649 | $0.000952 | 1125 | $0.000931 | 1774 | $0.001883 |
| 3 | 687 | $0.000952 | 2142 | $0.000931 | 2829 | $0.001883 |

### delete-repeated-a-mi

- Original text: `A mí me gusta el café a mí.`
- Expected corrected text: `A mí me gusta el café.`
- Pass rate: 3/3
- Distinct final outputs:
  - `A mí me gusta el café.`

| Run | Pass 1 output | Pass 1 corrections | Pass 2 signal | Final output | Score | Pass/fail | Reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `A mí me gusta el café.` | A mí me gusta el café a mí. -> A mí me gusta el café. (Elimination of redundant phrase) | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 2 | `A mí me gusta el café.` | A mí me gusta el café a mí. -> A mí me gusta el café. (redundancy/word order) | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |
| 3 | `A mí me gusta el café.` | A mí me gusta el café a mí. -> A mí me gusta el café. (redundant pronoun removal) | (none) | `A mí me gusta el café.` | correct_fix | Pass | Matches expected output. |

| Run | Pass 1 latency (ms) | Pass 1 cost | Pass 2 latency (ms) | Pass 2 cost | Total latency (ms) | Total cost |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 682 | $0.001152 | 1165 | $0.000924 | 1847 | $0.002076 |
| 2 | 845 | $0.001160 | 1024 | $0.000924 | 1869 | $0.002084 |
| 3 | 820 | $0.001160 | 1086 | $0.000924 | 1906 | $0.002084 |

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
| 1 | 580 | $0.000922 | 910 | $0.000928 | 1490 | $0.001850 |
| 2 | 897 | $0.000922 | 1020 | $0.000928 | 1917 | $0.001850 |
| 3 | 684 | $0.000922 | 929 | $0.000928 | 1613 | $0.001850 |

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
| 1 | 672 | $0.000942 | 1127 | $0.000930 | 1799 | $0.001872 |
| 2 | 599 | $0.000942 | 898 | $0.000930 | 1497 | $0.001872 |
| 3 | 575 | $0.000942 | 1129 | $0.000930 | 1704 | $0.001872 |

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
| Pass 1 (first pass) | 11526 | $0.014686 |
| Pass 2 (lexical review) | 17160 | $0.013920 |
| **Total (Pass 1 + Pass 2)** | 28686 | $0.028606 |
