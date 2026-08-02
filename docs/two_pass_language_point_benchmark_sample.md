# Two-Pass Live Integration Harness

## Run configuration

- Pass 1: `callFirstPassCorrection` — the simple, narrow `corrected_text`-only first-pass client (issue #68/#65), not the old broad `runStagedCorrectionPipeline`.
- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture selection: sample — up to 1 per language point (19 fixtures total) (issue #85)
- Fixture count: `19`
- Generated: 2026-08-02T13:52:42.502449Z

## Pricing

Verified estimated costs use:
- `gpt-4.1`: input=2.0 USD, output=8.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5.1`: input=1.25 USD, output=10.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## clean-grammar-only

- Input text: `Vi mucho trafico ayer.`
- Note: First-pass-only fixable error (missing accent); no naturalness issue anywhere. Expect: no conflict, no fallback.
- Language point: Accents / Diacritics
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Vi mucho tráfico ayer.`
- First-pass corrected text: `Vi mucho tráfico ayer.`
- Naturalness on original text: Vi mucho trafico ayer. -> Había mucho tráfico ayer.
- Naturalness on first-pass corrected text: Vi mucho tráfico ayer. -> Había mucho tráfico ayer.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Había mucho tráfico ayer.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 1816 | 153 | $0.000372 |
| Naturalness (original) | 3082 | 380 | $0.001341 |
| Naturalness (first-pass corrected) | 2092 | 379 | $0.001340 |
| **Total** | 6990 | 912 | $0.003053 |

## naturalness-only

- Input text: `Voy a hacer una decisión importante.`
- Note: No first-pass-fixable error; a naturalness calque only. Expect: naturalness-on-original and naturalness-on-corrected agree (the text is identical either way), no conflict.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `Voy a tomar una decisión importante.`
- First-pass corrected text: `Voy a tomar una decisión importante.`
- Naturalness on original text: hacer una decisión -> tomar una decisión
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Voy a tomar una decisión importante.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 619 | 156 | $0.000390 |
| Naturalness (original) | 2232 | 389 | $0.001423 |
| Naturalness (first-pass corrected) | 1148 | 311 | $0.000643 |
| **Total** | 3999 | 856 | $0.002455 |

## grammar-and-naturalness-independent

- Input text: `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.`
- Note: Spatially separate first-pass fix ("devia" -> "debía") and naturalness calque ("hizo una decisión"). Expect: the naturalness span is untouched by the first pass, so both variants agree; no conflict.
- Language point: Accents / Diacritics + Collocations / Strong Calques (independent spans)
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- First-pass corrected text: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- Naturalness on original text: hizo una decisión -> tomó una decisión
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 717 | 172 | $0.000470 |
| Naturalness (original) | 2010 | 388 | $0.001342 |
| Naturalness (first-pass corrected) | 1025 | 319 | $0.000652 |
| **Total** | 3752 | 879 | $0.002465 |

## grammar-overlaps-naturalness

- Input text: `Ayer iso una decisión importante.`
- Note: The first-pass fix ("iso" -> "hizo") sits inside the exact naturalness calque span ("hizo una decisión") — the case the fallback exists for. Expect: naturalness-on-original flags the pre-correction wording (conflict against firstPassCorrectedText), naturalness-on-corrected flags the post-correction wording (resolves cleanly) — fallback used.
- Language point: Verb Morphology (spelling) overlapping Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Ayer tomó una decisión importante.`
- First-pass corrected text: `Ayer hizo una decisión importante.`
- Naturalness on original text: iso una decisión -> tomó una decisión
- Naturalness on first-pass corrected text: hizo una decisión -> tomó una decisión
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Ayer tomó una decisión importante.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 797 | 156 | $0.000390 |
| Naturalness (original) | 1828 | 377 | $0.001303 |
| Naturalness (first-pass corrected) | 1976 | 387 | $0.001403 |
| **Total** | 4601 | 920 | $0.003095 |

## ambiguous-naturalness-span

- Input text: `Vi mucho tráfico, y luego vi más tráfico.`
- Note: No first-pass fix needed; naturalness may flag a bare repeated word ambiguously on both passes. Expect: possible conflict that the fallback does not resolve either — the "still unsafe after a rerun" case from issue #37, observed live rather than simulated.
- Language point: Ambiguous / Repeated Span Safety (Naturalness)
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- First-pass corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Naturalness on original text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico, y luego todavía más.
- Naturalness on first-pass corrected text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico, y luego había aún más.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Había mucho tráfico, y luego todavía más.`
- Final correction count: 1
- Score: overcorrection

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 815 | 162 | $0.000420 |
| Naturalness (original) | 2389 | 407 | $0.001576 |
| Naturalness (first-pass corrected) | 2228 | 433 | $0.001836 |
| **Total** | 5432 | 1002 | $0.003832 |

## agreement-ninos-manzanas

- Input text: `Los niño come muchas manzana.`
- Note: Plural article/noun/verb and noun-number agreement.
- Language point: Gender / Number Agreement
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Los niños comen muchas manzanas.`
- First-pass corrected text: `Los niños comen muchas manzanas.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Los niños comen muchas manzanas.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 603 | 157 | $0.000398 |
| Naturalness (original) | 1127 | 311 | $0.000643 |
| Naturalness (first-pass corrected) | 943 | 312 | $0.000644 |
| **Total** | 2673 | 780 | $0.001684 |

## verb-nosotros-fuimos

- Input text: `Mis compañeros y yo fue a la biblioteca.`
- Note: "fue" must be "fuimos" to agree with "mis compañeros y yo".
- Language point: Verb Agreement / Morphology
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Mis compañeros y yo fuimos a la biblioteca.`
- First-pass corrected text: `Mis compañeros y yo fuimos a la biblioteca.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Mis compañeros y yo fuimos a la biblioteca.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 658 | 161 | $0.000418 |
| Naturalness (original) | 1138 | 313 | $0.000645 |
| Naturalness (first-pass corrected) | 1115 | 314 | $0.000646 |
| **Total** | 2911 | 788 | $0.001709 |

## prep-insisto-en

- Input text: `Insisto que revises el contrato.`
- Note: "insistir" requires "en" before a "que" clause.
- Language point: Required Prepositions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Insisto en que revises el contrato.`
- First-pass corrected text: `Insisto en que revises el contrato.`
- Naturalness on original text: Insisto que revises el contrato. -> Insisto en que revises el contrato.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Insisto en que revises el contrato.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 645 | 159 | $0.000408 |
| Naturalness (original) | 2097 | 385 | $0.001374 |
| Naturalness (first-pass corrected) | 1110 | 313 | $0.000645 |
| **Total** | 3852 | 857 | $0.002427 |

## article-puerta-principal

- Input text: `Abrió puerta principal.`
- Note: Missing definite article before "puerta principal".
- Language point: Articles / Determiners
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Abrió la puerta principal.`
- First-pass corrected text: `Abrió la puerta principal.`
- Naturalness on original text: Abrió puerta principal. -> Abrió la puerta principal.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Abrió la puerta principal.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 577 | 153 | $0.000378 |
| Naturalness (original) | 1804 | 379 | $0.001340 |
| Naturalness (first-pass corrected) | 1117 | 310 | $0.000641 |
| **Total** | 3498 | 842 | $0.002359 |

## subj-estudies

- Input text: `Es importante que estudias.`
- Note: Impersonal "es importante que" requires the subjunctive.
- Language point: Subjunctive / Mood
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Es importante que estudies.`
- First-pass corrected text: `Es importante que estudies.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Es importante que estudies.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 524 | 154 | $0.000380 |
| Naturalness (original) | 1123 | 310 | $0.000641 |
| Naturalness (first-pass corrected) | 1230 | 310 | $0.000641 |
| **Total** | 2877 | 774 | $0.001662 |

## missing-que-creo

- Input text: `Creo está bien terminar hoy.`
- Note: "creer" requires the connector "que" before its clause.
- Language point: Required Additions / Omissions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Creo que está bien terminar hoy.`
- First-pass corrected text: `Creo que está bien terminar hoy.`
- Naturalness on original text: Creo está bien terminar hoy. -> Creo que está bien terminar hoy.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Creo que está bien terminar hoy.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 505 | 155 | $0.000388 |
| Naturalness (original) | 1826 | 369 | $0.001231 |
| Naturalness (first-pass corrected) | 1027 | 311 | $0.000643 |
| **Total** | 3358 | 835 | $0.002262 |

## delete-repeated-yo-estudio

- Input text: `Yo trabajo mucho y yo estudio por las noches.`
- Note: Second "yo" is a redundant repeated subject pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- First-pass corrected text: `Yo trabajo mucho y yo estudio por las noches.`
- Naturalness on original text: Yo trabajo mucho y yo estudio por las noches. -> Trabajo mucho y estudio por las noches.
- Naturalness on first-pass corrected text: Yo trabajo mucho y yo estudio por las noches. -> Trabajo mucho y estudio por las noches.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Trabajo mucho y estudio por las noches.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 662 | 162 | $0.000420 |
| Naturalness (original) | 2255 | 409 | $0.001596 |
| Naturalness (first-pass corrected) | 2252 | 385 | $0.001356 |
| **Total** | 5169 | 956 | $0.003372 |

## ser-profesor

- Input text: `Mi hermano está profesor.`
- Note: Profession/identity requires "ser", not "estar".
- Language point: Ser / Estar / Haber
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Mi hermano es profesor.`
- First-pass corrected text: `Mi hermano es profesor.`
- Naturalness on original text: está profesor -> es profesor
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Mi hermano es profesor.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 576 | 152 | $0.000370 |
| Naturalness (original) | 2570 | 369 | $0.001240 |
| Naturalness (first-pass corrected) | 911 | 309 | $0.000640 |
| **Total** | 4057 | 830 | $0.002250 |

## haber-habia-personas

- Input text: `Habían muchas personas en la entrada.`
- Note: Impersonal "haber" is invariant: "había", never "habían".
- Language point: Impersonal Haber / Se
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Había muchas personas en la entrada.`
- First-pass corrected text: `Había muchas personas en la entrada.`
- Naturalness on original text: Habían muchas personas -> Había muchas personas
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Había muchas personas en la entrada.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 680 | 158 | $0.000400 |
| Naturalness (original) | 2509 | 384 | $0.001364 |
| Naturalness (first-pass corrected) | 892 | 312 | $0.000644 |
| **Total** | 4081 | 854 | $0.002407 |

## false-friend-atendio-universidad

- Input text: `Atendió la universidad en Madrid.`
- Note: "atender" is a false friend for "attend"; needs "asistir a".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Asistió a la universidad en Madrid.`
- First-pass corrected text: `Asistió a la universidad en Madrid.`
- Naturalness on original text: Atendió la universidad en Madrid. -> Estudió en la universidad en Madrid.
- Naturalness on first-pass corrected text: Asistió a la universidad en Madrid. -> Estudió en la universidad en Madrid.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Estudió en la universidad en Madrid.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 760 | 159 | $0.000408 |
| Naturalness (original) | 2312 | 433 | $0.001854 |
| Naturalness (first-pass corrected) | 1963 | 409 | $0.001605 |
| **Total** | 5035 | 1001 | $0.003867 |

## naturalness-buen-tiempo

- Input text: `Tuvimos un buen tiempo.`
- Note: English-influenced "tener un buen tiempo" ("had a good time").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `Lo pasamos bien.`
- First-pass corrected text: `Tuvimos un buen tiempo.`
- Naturalness on original text: Tuvimos un buen tiempo. -> Lo pasamos bien.
- Naturalness on first-pass corrected text: Tuvimos un buen tiempo. -> Lo pasamos bien.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Lo pasamos bien.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 776 | 156 | $0.000390 |
| Naturalness (original) | 1874 | 395 | $0.001482 |
| Naturalness (first-pass corrected) | 1954 | 396 | $0.001492 |
| **Total** | 4604 | 947 | $0.003365 |

## regional-voy-para-casa

- Input text: `Voy para casa ahora mismo.`
- Note: Valid regional Spanish ("para casa"); must not be flagged.
- Language point: Valid Regional / Should Not Flag
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Voy para casa ahora mismo.`
- First-pass corrected text: `Voy para la casa ahora mismo.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Voy para la casa ahora mismo.`
- Final correction count: 0
- Score: overcorrection

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 668 | 155 | $0.000388 |
| Naturalness (original) | 1334 | 310 | $0.000641 |
| Naturalness (first-pass corrected) | 960 | 311 | $0.000643 |
| **Total** | 2962 | 776 | $0.001672 |

## correct-buenos-dias

- Input text: `Buenos días, ¿cómo estás?`
- Note: Already correct; must not be tinkered with.
- Language point: Already Correct / Do Not Tinker
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Buenos días, ¿cómo estás?`
- First-pass corrected text: `Buenos días, ¿cómo estás?`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Buenos días, ¿cómo estás?`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 639 | 156 | $0.000390 |
| Naturalness (original) | 1226 | 311 | $0.000643 |
| Naturalness (first-pass corrected) | 1019 | 311 | $0.000643 |
| **Total** | 2884 | 778 | $0.001675 |

## mixed-preposition-and-redundant-pronoun

- Input text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Note: Combines a required-preposition insertion ("insisto en que") with a redundant repeated-pronoun deletion (second "yo").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- First-pass corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- Naturalness on original text: Insisto que revises el contrato -> Insisto en que revises el contrato<br>y yo trabajo mucho y yo estudio por las noches -> yo trabajo mucho y estudio por las noches
- Naturalness on first-pass corrected text: Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches. -> Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Insisto en que revises el contrato; yo trabajo mucho y estudio por las noches.`
- Final correction count: 1
- Score: partial_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 685 | 180 | $0.000510 |
| Naturalness (original) | 3806 | 454 | $0.001968 |
| Naturalness (first-pass corrected) | 2096 | 429 | $0.001718 |
| **Total** | 6587 | 1063 | $0.004195 |

---

## Overall summary

| Fixtures | Errors | Conflicts | Fallbacks used | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 19 | 0 | 11 | 11 | 79322 | 16650 | $0.049808 |

### Score summary

| Score | Count |
| --- | --- |
| correct_fix | 12 |
| partial_fix | 1 |
| overcorrection | 2 |
| acceptable_no_change | 1 |
| ambiguous | 3 |

### Language point summary

| Language point | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Accents / Diacritics | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| Collocations / Strong Calques | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Accents / Diacritics + Collocations / Strong Calques (independent spans) | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Verb Morphology (spelling) overlapping Collocations / Strong Calques | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ambiguous / Repeated Span Safety (Naturalness) | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| Gender / Number Agreement | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Verb Agreement / Morphology | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Required Prepositions | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Articles / Determiners | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Subjunctive / Mood | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Required Additions / Omissions | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Unnecessary Extras / Deletions | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| Ser / Estar / Haber | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Impersonal Haber / Se | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| False Friends / Word Choice | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| Phrase-Level Naturalness | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Valid Regional / Should Not Flag | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| Already Correct / Do Not Tinker | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| Mixed Operations | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |

### Operation type summary

| Operation type | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| replacement | 11 | 9 | 0 | 0 | 0 | 0 | 2 | 0 |
| no_change | 3 | 0 | 0 | 0 | 2 | 1 | 0 | 0 |
| insertion | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| deletion | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 0 |
| mixed | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 0 |

### Expected owner summary

| Expected owner | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| first_pass | 11 | 8 | 1 | 0 | 0 | 0 | 2 | 0 |
| naturalness | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| either | 3 | 2 | 0 | 0 | 0 | 0 | 1 | 0 |
| no_change | 3 | 0 | 0 | 0 | 2 | 1 | 0 | 0 |

### Fallback / conflict summary

| Metric | Count | Rate |
| --- | --- | --- |
| Conflicts | 11 | 57.9% |
| Fallbacks used | 11 | 57.9% |

### Latency / cost outliers

- Average latency: 4175 ms; average cost: $0.002621 (over 19 non-error fixture(s)).
- Outlier threshold: 1.5x the average latency or cost.

| Fixture | Latency (ms) | Est. cost (USD) |
| --- | --- | --- |
| clean-grammar-only | 6990 | $0.003053 |
| mixed-preposition-and-redundant-pronoun | 6587 | $0.004195 |
