# Two-Pass Live Integration Harness

## Run configuration

- Pass 1: `callFirstPassCorrection` — the simple, narrow `corrected_text`-only first-pass client (issue #68/#65), not the old broad `runStagedCorrectionPipeline`.
- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture selection: all (85 fixtures) (issue #85)
- Fixture count: `85`
- Generated: 2026-08-02T14:01:00.981686Z

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
- Naturalness on original text: trafico -> tráfico
- Naturalness on first-pass corrected text: Vi mucho tráfico ayer. -> Había mucho tráfico ayer.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Había mucho tráfico ayer.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 739 | 153 | $0.000372 |
| Naturalness (original) | 2052 | 384 | $0.001381 |
| Naturalness (first-pass corrected) | 2135 | 399 | $0.001540 |
| **Total** | 4926 | 936 | $0.003293 |

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
| First pass | 502 | 156 | $0.000390 |
| Naturalness (original) | 1878 | 374 | $0.001273 |
| Naturalness (first-pass corrected) | 930 | 311 | $0.000643 |
| **Total** | 3310 | 841 | $0.002305 |

## grammar-and-naturalness-independent

- Input text: `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.`
- Note: Spatially separate first-pass fix ("devia" -> "debía") and naturalness calque ("hizo una decisión"). Expect: the naturalness span is untouched by the first pass, so both variants agree; no conflict.
- Language point: Accents / Diacritics + Collocations / Strong Calques (independent spans)
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- First-pass corrected text: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- Naturalness on original text: hizo una decisión importante -> tomó una decisión importante
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 728 | 172 | $0.000470 |
| Naturalness (original) | 1948 | 393 | $0.001392 |
| Naturalness (first-pass corrected) | 1021 | 319 | $0.000652 |
| **Total** | 3697 | 884 | $0.002515 |

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
| First pass | 681 | 156 | $0.000390 |
| Naturalness (original) | 1946 | 372 | $0.001253 |
| Naturalness (first-pass corrected) | 1740 | 373 | $0.001263 |
| **Total** | 4367 | 901 | $0.002905 |

## ambiguous-naturalness-span

- Input text: `Vi mucho tráfico, y luego vi más tráfico.`
- Note: No first-pass fix needed; naturalness may flag a bare repeated word ambiguously on both passes. Expect: possible conflict that the fallback does not resolve either — the "still unsafe after a rerun" case from issue #37, observed live rather than simulated.
- Language point: Ambiguous / Repeated Span Safety (Naturalness)
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- First-pass corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Naturalness on original text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico, y luego había todavía más.
- Naturalness on first-pass corrected text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico, y luego todavía más.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Había mucho tráfico, y luego había todavía más.`
- Final correction count: 1
- Score: overcorrection

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 497 | 162 | $0.000420 |
| Naturalness (original) | 2435 | 429 | $0.001796 |
| Naturalness (first-pass corrected) | 2560 | 421 | $0.001716 |
| **Total** | 5492 | 1012 | $0.003933 |

## accent-manana

- Input text: `Voy al parque manana por la tarde.`
- Note: Missing accent on "mañana".
- Language point: Accents / Diacritics
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Voy al parque mañana por la tarde.`
- First-pass corrected text: `Voy al parque mañana por la tarde.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Voy al parque mañana por la tarde.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 677 | 158 | $0.000400 |
| Naturalness (original) | 1177 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 972 | 312 | $0.000644 |
| **Total** | 2826 | 782 | $0.001687 |

## accent-medico

- Input text: `El medico llego despues de la reunion.`
- Note: Missing accents on "médico", "llegó", "después", "reunión".
- Language point: Accents / Diacritics
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `El médico llegó después de la reunión.`
- First-pass corrected text: `El médico llegó después de la reunión.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `El médico llegó después de la reunión.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 579 | 159 | $0.000402 |
| Naturalness (original) | 1230 | 313 | $0.000645 |
| Naturalness (first-pass corrected) | 1020 | 312 | $0.000644 |
| **Total** | 2829 | 784 | $0.001691 |

## accent-espana-pais

- Input text: `Espana es un pais muy diverso.`
- Note: Missing accent/ñ on "España" and accent on "país".
- Language point: Accents / Diacritics
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `España es un país muy diverso.`
- First-pass corrected text: `España es un país muy diverso.`
- Naturalness on original text: Espana -> España
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `España es un país muy diverso.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 683 | 157 | $0.000392 |
| Naturalness (original) | 2251 | 388 | $0.001404 |
| Naturalness (first-pass corrected) | 1898 | 311 | $0.000643 |
| **Total** | 4832 | 856 | $0.002438 |

## accent-cumpleanos-otono

- Input text: `Mi cumpleanos es en otono.`
- Note: Missing ñ/accent on "cumpleaños" and "otoño".
- Language point: Accents / Diacritics
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Mi cumpleaños es en otoño.`
- First-pass corrected text: `Mi cumpleaños es en otoño.`
- Naturalness on original text: cumpleanos -> cumpleaños<br>es en otono -> es en otoño
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Mi cumpleaños es en otoño.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 525 | 156 | $0.000384 |
| Naturalness (original) | 3378 | 456 | $0.002084 |
| Naturalness (first-pass corrected) | 1023 | 310 | $0.000641 |
| **Total** | 4926 | 922 | $0.003109 |

## accent-cafe-cafeteria

- Input text: `Compre cafe en una cafeteria pequena.`
- Note: Missing accents on "Compré", "café", "cafetería", "pequeña".
- Language point: Accents / Diacritics
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Compré café en una cafetería pequeña.`
- First-pass corrected text: `Compré café en una cafetería pequeña.`
- Naturalness on original text: Compre -> Compré<br>cafe -> café<br>en una cafeteria pequena -> en una cafetería pequeña
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Compré café en una cafetería pequeña.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 577 | 159 | $0.000408 |
| Naturalness (original) | 3687 | 525 | $0.002774 |
| Naturalness (first-pass corrected) | 972 | 313 | $0.000645 |
| **Total** | 5236 | 997 | $0.003827 |

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
| First pass | 663 | 157 | $0.000398 |
| Naturalness (original) | 1190 | 311 | $0.000643 |
| Naturalness (first-pass corrected) | 1336 | 312 | $0.000644 |
| **Total** | 3189 | 780 | $0.001684 |

## agreement-ventanas-abiertas

- Input text: `Las ventanas estaban abierto.`
- Note: Predicate adjective must agree in gender/number with "ventanas".
- Language point: Gender / Number Agreement
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Las ventanas estaban abiertas.`
- First-pass corrected text: `Las ventanas estaban abiertas.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Las ventanas estaban abiertas.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 609 | 152 | $0.000370 |
| Naturalness (original) | 992 | 309 | $0.000640 |
| Naturalness (first-pass corrected) | 2063 | 309 | $0.000640 |
| **Total** | 3664 | 770 | $0.001650 |

## agreement-puerta-cerrada

- Input text: `Una puerta estaba cerrado.`
- Note: Predicate adjective must agree in gender with "puerta".
- Language point: Gender / Number Agreement
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Una puerta estaba cerrada.`
- First-pass corrected text: `Una puerta estaba cerrada.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Una puerta estaba cerrada.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 671 | 153 | $0.000378 |
| Naturalness (original) | 1505 | 309 | $0.000640 |
| Naturalness (first-pass corrected) | 1036 | 310 | $0.000641 |
| **Total** | 3212 | 772 | $0.001659 |

## agreement-billetes-caros

- Input text: `Los billetes estaban caro.`
- Note: Predicate adjective must agree in number with "billetes".
- Language point: Gender / Number Agreement
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Los billetes estaban caros.`
- First-pass corrected text: `Los billetes estaban caros.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Los billetes estaban caros.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 587 | 154 | $0.000380 |
| Naturalness (original) | 947 | 310 | $0.000641 |
| Naturalness (first-pass corrected) | 1001 | 310 | $0.000641 |
| **Total** | 2535 | 774 | $0.001662 |

## agreement-fechas-escritas

- Input text: `Las fechas estaban escrito sin tilde.`
- Note: Predicate participle must agree in gender/number with "fechas".
- Language point: Gender / Number Agreement
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Las fechas estaban escritas sin tilde.`
- First-pass corrected text: `Las fechas estaban escritas sin tilde.`
- Naturalness on original text: estaban escrito -> estaban escritas
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Las fechas estaban escritas sin tilde.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 586 | 159 | $0.000408 |
| Naturalness (original) | 2550 | 392 | $0.001444 |
| Naturalness (first-pass corrected) | 1147 | 313 | $0.000645 |
| **Total** | 4283 | 864 | $0.002497 |

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
| First pass | 569 | 161 | $0.000418 |
| Naturalness (original) | 975 | 313 | $0.000645 |
| Naturalness (first-pass corrected) | 907 | 314 | $0.000646 |
| **Total** | 2451 | 788 | $0.001709 |

## verb-ninos-comen

- Input text: `Los niños come en el jardín.`
- Note: "come" must be "comen" to agree with the plural subject.
- Language point: Verb Agreement / Morphology
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Los niños comen en el jardín.`
- First-pass corrected text: `Los niños comen en el jardín.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Los niños comen en el jardín.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 527 | 156 | $0.000390 |
| Naturalness (original) | 1025 | 311 | $0.000643 |
| Naturalness (first-pass corrected) | 1428 | 311 | $0.000643 |
| **Total** | 2980 | 778 | $0.001675 |

## verb-compre-pan

- Input text: `Yo fui al mercado y compra pan.`
- Note: "compra" must be first-person preterite "compré".
- Language point: Verb Agreement / Morphology
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Yo fui al mercado y compré pan.`
- First-pass corrected text: `Yo fui al mercado y compré pan.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Yo fui al mercado y compré pan.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 536 | 159 | $0.000408 |
| Naturalness (original) | 1058 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 1214 | 313 | $0.000645 |
| **Total** | 2808 | 784 | $0.001697 |

## verb-ellos-estudian

- Input text: `Ellos estudia todas las noches.`
- Note: "estudia" must be "estudian" to agree with "ellos".
- Language point: Verb Agreement / Morphology
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Ellos estudian todas las noches.`
- First-pass corrected text: `Ellos estudian todas las noches.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Ellos estudian todas las noches.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 704 | 158 | $0.000400 |
| Naturalness (original) | 1137 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 1219 | 312 | $0.000644 |
| **Total** | 3060 | 782 | $0.001687 |

## verb-nosotros-vivimos

- Input text: `Nosotros vive cerca del centro.`
- Note: "vive" must be "vivimos" to agree with "nosotros".
- Language point: Verb Agreement / Morphology
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Nosotros vivimos cerca del centro.`
- First-pass corrected text: `Nosotros vivimos cerca del centro.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Nosotros vivimos cerca del centro.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 783 | 156 | $0.000390 |
| Naturalness (original) | 1233 | 311 | $0.000643 |
| Naturalness (first-pass corrected) | 1175 | 311 | $0.000643 |
| **Total** | 3191 | 778 | $0.001675 |

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
| First pass | 604 | 159 | $0.000408 |
| Naturalness (original) | 1876 | 399 | $0.001514 |
| Naturalness (first-pass corrected) | 1117 | 313 | $0.000645 |
| **Total** | 3597 | 871 | $0.002567 |

## prep-empresa-en-la-que

- Input text: `La empresa que trabajo está cerca.`
- Note: Relative clause needs "en la que" (working "at/in" the company).
- Language point: Required Prepositions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `La empresa en la que trabajo está cerca.`
- First-pass corrected text: `La empresa en que trabajo está cerca.`
- Naturalness on original text: La empresa que trabajo está cerca. -> La empresa donde trabajo está cerca.
- Naturalness on first-pass corrected text: La empresa en que trabajo -> La empresa en la que trabajo
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `La empresa en la que trabajo está cerca.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 988 | 157 | $0.000398 |
| Naturalness (original) | 2456 | 393 | $0.001463 |
| Naturalness (first-pass corrected) | 2352 | 380 | $0.001324 |
| **Total** | 5796 | 930 | $0.003184 |

## prep-dependo-de

- Input text: `Dependo que me ayudes mañana.`
- Note: "depender" requires "de" before a "que" clause.
- Language point: Required Prepositions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Dependo de que me ayudes mañana.`
- First-pass corrected text: `Dependo de que me ayudes mañana.`
- Naturalness on original text: Dependo que me ayudes mañana. -> Dependo de que me ayudes mañana.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Dependo de que me ayudes mañana.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 580 | 159 | $0.000408 |
| Naturalness (original) | 1839 | 384 | $0.001364 |
| Naturalness (first-pass corrected) | 1024 | 313 | $0.000645 |
| **Total** | 3443 | 856 | $0.002417 |

## prep-pienso-en-ti

- Input text: `Pienso ti todos los días.`
- Note: "pensar en" requires the preposition "en" before its object.
- Language point: Required Prepositions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Pienso en ti todos los días.`
- First-pass corrected text: `Pienso en ti todos los días.`
- Naturalness on original text: Pienso ti -> Pienso en ti
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Pienso en ti todos los días.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 531 | 157 | $0.000398 |
| Naturalness (original) | 2057 | 381 | $0.001342 |
| Naturalness (first-pass corrected) | 1063 | 312 | $0.000644 |
| **Total** | 3651 | 850 | $0.002384 |

## prep-sone-con

- Input text: `Soñé mi antiguo colegio.`
- Note: "soñar con" requires the preposition "con".
- Language point: Required Prepositions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Soñé con mi antiguo colegio.`
- First-pass corrected text: `Soñé con mi antiguo colegio.`
- Naturalness on original text: Soñé mi antiguo colegio. -> Soñé con mi antiguo colegio.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Soñé con mi antiguo colegio.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 794 | 157 | $0.000398 |
| Naturalness (original) | 2105 | 390 | $0.001433 |
| Naturalness (first-pass corrected) | 1055 | 312 | $0.000644 |
| **Total** | 3954 | 859 | $0.002474 |

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
| First pass | 675 | 153 | $0.000378 |
| Naturalness (original) | 1773 | 379 | $0.001340 |
| Naturalness (first-pass corrected) | 993 | 310 | $0.000641 |
| **Total** | 3441 | 842 | $0.002359 |

## article-un-libro

- Input text: `Necesito comprar libro para la clase.`
- Note: Missing indefinite article before "libro".
- Language point: Articles / Determiners
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Necesito comprar un libro para la clase.`
- First-pass corrected text: `Necesito comprar un libro para la clase.`
- Naturalness on original text: comprar libro -> comprar un libro
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Necesito comprar un libro para la clase.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 682 | 159 | $0.000408 |
| Naturalness (original) | 2252 | 374 | $0.001264 |
| Naturalness (first-pass corrected) | 1024 | 313 | $0.000645 |
| **Total** | 3958 | 846 | $0.002317 |

## article-el-profesor-la-regla

- Input text: `Profesor explicó regla otra vez.`
- Note: Missing definite articles before both "profesor" and "regla".
- Language point: Articles / Determiners
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `El profesor explicó la regla otra vez.`
- First-pass corrected text: `El profesor explicó la regla otra vez.`
- Naturalness on original text: Profesor explicó regla otra vez. -> El profesor explicó la regla otra vez.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `El profesor explicó la regla otra vez.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 579 | 156 | $0.000396 |
| Naturalness (original) | 2033 | 393 | $0.001471 |
| Naturalness (first-pass corrected) | 1138 | 312 | $0.000644 |
| **Total** | 3750 | 861 | $0.002511 |

## article-la-tienda

- Input text: `Fui a tienda después del trabajo.`
- Note: Missing definite article before "tienda".
- Language point: Articles / Determiners
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Fui a la tienda después del trabajo.`
- First-pass corrected text: `Fui a la tienda después del trabajo.`
- Naturalness on original text: a tienda -> a la tienda
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Fui a la la tienda después del trabajo.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 1031 | 159 | $0.000408 |
| Naturalness (original) | 1598 | 369 | $0.001214 |
| Naturalness (first-pass corrected) | 918 | 313 | $0.000645 |
| **Total** | 3547 | 841 | $0.002267 |

## article-cita-medico

- Input text: `Tengo cita con médico mañana.`
- Note: Missing indefinite article before "cita" and definite before "médico".
- Language point: Articles / Determiners
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Tengo una cita con el médico mañana.`
- First-pass corrected text: `Tengo cita con el médico mañana.`
- Naturalness on original text: con médico -> con el médico
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Tengo cita con el médico mañana.`
- Final correction count: 0
- Score: partial_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 988 | 155 | $0.000388 |
| Naturalness (original) | 1739 | 380 | $0.001341 |
| Naturalness (first-pass corrected) | 1146 | 311 | $0.000643 |
| **Total** | 3873 | 846 | $0.002372 |

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
| First pass | 574 | 154 | $0.000380 |
| Naturalness (original) | 1011 | 310 | $0.000641 |
| Naturalness (first-pass corrected) | 1130 | 310 | $0.000641 |
| **Total** | 2715 | 774 | $0.001662 |

## subj-tenga-razon

- Input text: `No creo que tiene razón.`
- Note: Negated "creer" triggers the subjunctive in its clause.
- Language point: Subjunctive / Mood
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `No creo que tenga razón.`
- First-pass corrected text: `No creo que tenga razón.`
- Naturalness on original text: No creo que tiene razón. -> No creo que tenga razón.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `No creo que tenga razón.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 571 | 154 | $0.000380 |
| Naturalness (original) | 2217 | 374 | $0.001281 |
| Naturalness (first-pass corrected) | 957 | 310 | $0.000641 |
| **Total** | 3745 | 838 | $0.002302 |

## subj-vengas

- Input text: `Quiero que vienes conmigo.`
- Note: "querer que" requires the subjunctive.
- Language point: Subjunctive / Mood
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Quiero que vengas conmigo.`
- First-pass corrected text: `Quiero que vengas conmigo.`
- Naturalness on original text: Quiero que vienes conmigo. -> Quiero que vengas conmigo.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Quiero que vengas conmigo.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 491 | 156 | $0.000390 |
| Naturalness (original) | 2238 | 389 | $0.001423 |
| Naturalness (first-pass corrected) | 1330 | 311 | $0.000643 |
| **Total** | 4059 | 856 | $0.002455 |

## subj-enviara

- Input text: `Era necesario que enviaba su parte.`
- Note: Impersonal past "era necesario que" requires the imperfect subjunctive.
- Language point: Subjunctive / Mood
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Era necesario que enviara su parte.`
- First-pass corrected text: `Era necesario que enviara su parte.`
- Naturalness on original text: Era necesario que enviaba su parte. -> Era necesario que enviara su parte.
- Naturalness on first-pass corrected text: su parte -> su informe
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Era necesario que enviara su informe.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 680 | 158 | $0.000400 |
| Naturalness (original) | 2046 | 394 | $0.001464 |
| Naturalness (first-pass corrected) | 2491 | 417 | $0.001694 |
| **Total** | 5217 | 969 | $0.003557 |

## subj-hable-frances

- Input text: `Busco a alguien que habla francés.`
- Note: Nonspecific antecedent ("alguien que...") requires the subjunctive.
- Language point: Subjunctive / Mood
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Busco a alguien que hable francés.`
- First-pass corrected text: `Busco a alguien que hable francés.`
- Naturalness on original text: que habla francés -> que hable francés
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Busco a alguien que hable francés.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 749 | 159 | $0.000408 |
| Naturalness (original) | 3007 | 417 | $0.001694 |
| Naturalness (first-pass corrected) | 1189 | 313 | $0.000645 |
| **Total** | 4945 | 889 | $0.002747 |

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
| First pass | 578 | 155 | $0.000388 |
| Naturalness (original) | 1741 | 378 | $0.001321 |
| Naturalness (first-pass corrected) | 1228 | 311 | $0.000643 |
| **Total** | 3547 | 844 | $0.002352 |

## missing-les-ninos

- Input text: `A los niños expliqué la regla.`
- Note: Fronted indirect object "a los niños" requires the clitic "les".
- Language point: Required Additions / Omissions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `A los niños les expliqué la regla.`
- First-pass corrected text: `A los niños les expliqué la regla.`
- Naturalness on original text: A los niños expliqué la regla. -> Les expliqué la regla a los niños.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `A los niños les expliqué la regla.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 679 | 157 | $0.000398 |
| Naturalness (original) | 2253 | 407 | $0.001603 |
| Naturalness (first-pass corrected) | 1025 | 312 | $0.000644 |
| **Total** | 3957 | 876 | $0.002644 |

## missing-personal-a-profesor

- Input text: `Vi mi profesor en la estación.`
- Note: Definite human direct object requires the personal "a".
- Language point: Required Additions / Omissions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Vi a mi profesor en la estación.`
- First-pass corrected text: `Vi a mi profesor en la estación.`
- Naturalness on original text: Vi mi profesor -> Vi a mi profesor
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Vi a mi profesor en la estación.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 707 | 157 | $0.000398 |
| Naturalness (original) | 2019 | 382 | $0.001352 |
| Naturalness (first-pass corrected) | 1023 | 312 | $0.000644 |
| **Total** | 3749 | 851 | $0.002394 |

## missing-se-levanto

- Input text: `Levantó temprano ayer.`
- Note: Reflexive "levantarse" requires the reflexive pronoun "se".
- Language point: Required Additions / Omissions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `Se levantó temprano ayer.`
- First-pass corrected text: `Se levantó temprano ayer.`
- Naturalness on original text: Levantó temprano ayer. -> Se levantó temprano ayer.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Se levantó temprano ayer.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 698 | 154 | $0.000380 |
| Naturalness (original) | 2029 | 394 | $0.001481 |
| Naturalness (first-pass corrected) | 1124 | 310 | $0.000641 |
| **Total** | 3851 | 858 | $0.002502 |

## missing-le-gusta

- Input text: `A Juan gusta el café.`
- Note: Fronted "a Juan" with "gustar" requires the clitic "le".
- Language point: Required Additions / Omissions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `A Juan le gusta el café.`
- First-pass corrected text: `A Juan le gusta el café.`
- Naturalness on original text: A Juan gusta el café. -> A Juan le gusta el café.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `A Juan le gusta el café.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 577 | 155 | $0.000388 |
| Naturalness (original) | 2424 | 392 | $0.001461 |
| Naturalness (first-pass corrected) | 1160 | 311 | $0.000643 |
| **Total** | 4161 | 858 | $0.002492 |

## delete-repeated-yo-estudio

- Input text: `Yo trabajo mucho y yo estudio por las noches.`
- Note: Second "yo" is a redundant repeated subject pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- First-pass corrected text: `Yo trabajo mucho y yo estudio por las noches.`
- Naturalness on original text: y yo estudio por las noches -> y estudio por las noches
- Naturalness on first-pass corrected text: Yo trabajo mucho y yo estudio por las noches. -> Trabajo mucho y estudio por las noches.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Yo trabajo mucho y estudio por las noches.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 704 | 162 | $0.000420 |
| Naturalness (original) | 1768 | 391 | $0.001416 |
| Naturalness (first-pass corrected) | 1903 | 396 | $0.001466 |
| **Total** | 4375 | 949 | $0.003302 |

## delete-repeated-ellos-visitaron

- Input text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Note: Second "ellos" is a redundant repeated subject pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `Ellos viajaron a México y visitaron varias ciudades.`
- First-pass corrected text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Naturalness on original text: Ellos viajaron a México y ellos visitaron varias ciudades. -> Viajaron a México y visitaron varias ciudades.
- Naturalness on first-pass corrected text: Ellos viajaron a México y ellos visitaron varias ciudades. -> Viajaron a México y visitaron varias ciudades.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Viajaron a México y visitaron varias ciudades.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 671 | 168 | $0.000450 |
| Naturalness (original) | 1944 | 387 | $0.001350 |
| Naturalness (first-pass corrected) | 2455 | 405 | $0.001530 |
| **Total** | 5070 | 960 | $0.003330 |

## delete-repeated-a-mi

- Input text: `A mí me gusta el café a mí.`
- Note: Trailing "a mí" repeats the fronted emphatic pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `A mí me gusta el café.`
- First-pass corrected text: `A mí me gusta el café.`
- Naturalness on original text: A mí me gusta el café a mí. -> A mí me gusta el café.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `A mí me gusta el café.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 588 | 158 | $0.000394 |
| Naturalness (original) | 2040 | 391 | $0.001425 |
| Naturalness (first-pass corrected) | 875 | 311 | $0.000643 |
| **Total** | 3503 | 860 | $0.002462 |

## delete-repeated-yo-compre

- Input text: `Yo fui al mercado y yo compré pan.`
- Note: Second "yo" is a redundant repeated subject pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `Fui al mercado y compré pan.`
- First-pass corrected text: `Yo fui al mercado y yo compré pan.`
- Naturalness on original text: Yo fui al mercado y yo compré pan. -> Fui al mercado y compré pan.
- Naturalness on first-pass corrected text: Yo fui al mercado y yo compré pan. -> Fui al mercado y compré pan.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Fui al mercado y compré pan.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 724 | 162 | $0.000420 |
| Naturalness (original) | 2425 | 394 | $0.001446 |
| Naturalness (first-pass corrected) | 1873 | 383 | $0.001336 |
| **Total** | 5022 | 939 | $0.003203 |

## delete-repeated-nosotros

- Input text: `Nosotros salimos temprano y nosotros llegamos a tiempo.`
- Note: Second "nosotros" is a redundant repeated subject pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `Nosotros salimos temprano y llegamos a tiempo.`
- First-pass corrected text: `Nosotros salimos temprano y nosotros llegamos a tiempo.`
- Naturalness on original text: Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo.
- Naturalness on first-pass corrected text: Nosotros salimos temprano y nosotros llegamos a tiempo. -> Salimos temprano y llegamos a tiempo.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Salimos temprano y llegamos a tiempo.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 719 | 166 | $0.000440 |
| Naturalness (original) | 2065 | 404 | $0.001529 |
| Naturalness (first-pass corrected) | 1787 | 395 | $0.001439 |
| **Total** | 4571 | 965 | $0.003407 |

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
| First pass | 655 | 152 | $0.000370 |
| Naturalness (original) | 1662 | 372 | $0.001270 |
| Naturalness (first-pass corrected) | 1432 | 309 | $0.000640 |
| **Total** | 3749 | 833 | $0.002280 |

## haber-veinte-personas

- Input text: `En la sala son veinte personas.`
- Note: Existential "there are" requires impersonal "hay", not "son".
- Language point: Ser / Estar / Haber
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `En la sala hay veinte personas.`
- First-pass corrected text: `En la sala hay veinte personas.`
- Naturalness on original text: En la sala son veinte personas. -> En la sala hay veinte personas.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `En la sala hay veinte personas.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 501 | 156 | $0.000390 |
| Naturalness (original) | 1612 | 386 | $0.001393 |
| Naturalness (first-pass corrected) | 1126 | 311 | $0.000643 |
| **Total** | 3239 | 853 | $0.002425 |

## ser-capital-madrid

- Input text: `Madrid está la capital de España.`
- Note: Identity/definition requires "ser", not "estar".
- Language point: Ser / Estar / Haber
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Madrid es la capital de España.`
- First-pass corrected text: `Madrid es la capital de España.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Madrid es la capital de España.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 680 | 156 | $0.000390 |
| Naturalness (original) | 1127 | 311 | $0.000643 |
| Naturalness (first-pass corrected) | 1061 | 311 | $0.000643 |
| **Total** | 2868 | 778 | $0.001675 |

## estar-contento

- Input text: `Estoy muy contento con el resultado.`
- Note: Already correct: temporary state correctly uses "estar".
- Language point: Ser / Estar / Haber
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Estoy muy contento con el resultado.`
- First-pass corrected text: `Estoy muy contento con el resultado.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Estoy muy contento con el resultado.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 642 | 158 | $0.000400 |
| Naturalness (original) | 933 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 1063 | 312 | $0.000644 |
| **Total** | 2638 | 782 | $0.001687 |

## ser-reunion-segunda-planta

- Input text: `La reunión es en la segunda planta.`
- Note: Already correct: event location correctly uses "ser".
- Language point: Ser / Estar / Haber
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `La reunión es en la segunda planta.`
- First-pass corrected text: `La reunión es en la segunda planta.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `La reunión es en la segunda planta.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 534 | 158 | $0.000400 |
| Naturalness (original) | 1133 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 1247 | 312 | $0.000644 |
| **Total** | 2914 | 782 | $0.001687 |

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
| First pass | 645 | 158 | $0.000400 |
| Naturalness (original) | 2605 | 391 | $0.001434 |
| Naturalness (first-pass corrected) | 1060 | 312 | $0.000644 |
| **Total** | 4310 | 861 | $0.002478 |

## haber-hubo-problemas

- Input text: `Hubieron varios problemas durante la reunión.`
- Note: Impersonal "haber" is invariant: "hubo", never "hubieron".
- Language point: Impersonal Haber / Se
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Hubo varios problemas durante la reunión.`
- First-pass corrected text: `Hubo varios problemas durante la reunión.`
- Naturalness on original text: Hubieron varios problemas -> Hubo varios problemas
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Hubo varios problemas durante la reunión.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 593 | 158 | $0.000400 |
| Naturalness (original) | 1980 | 398 | $0.001504 |
| Naturalness (first-pass corrected) | 893 | 312 | $0.000644 |
| **Total** | 3466 | 868 | $0.002547 |

## se-venden-pisos

- Input text: `Se vende pisos en el centro.`
- Note: Passive "se" must agree in number with the plural "pisos".
- Language point: Impersonal Haber / Se
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Se venden pisos en el centro.`
- First-pass corrected text: `Se venden pisos en el centro.`
- Naturalness on original text: Se vende pisos -> Se venden pisos / Se vende piso
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Se venden pisos en el centro.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 782 | 156 | $0.000390 |
| Naturalness (original) | 1969 | 385 | $0.001383 |
| Naturalness (first-pass corrected) | 921 | 311 | $0.000643 |
| **Total** | 3672 | 852 | $0.002415 |

## se-necesitan-voluntarios

- Input text: `Se necesita voluntarios para el evento.`
- Note: Passive "se" must agree in number with the plural "voluntarios".
- Language point: Impersonal Haber / Se
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Se necesitan voluntarios para el evento.`
- First-pass corrected text: `Se necesitan voluntarios para el evento.`
- Naturalness on original text: Se necesita voluntarios -> Se necesitan voluntarios
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Se necesitan voluntarios para el evento.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 761 | 158 | $0.000400 |
| Naturalness (original) | 1974 | 389 | $0.001414 |
| Naturalness (first-pass corrected) | 991 | 312 | $0.000644 |
| **Total** | 3726 | 859 | $0.002458 |

## haber-habia-cifras

- Input text: `Habían varias cifras incorrectas.`
- Note: Impersonal "haber" is invariant: "había", never "habían".
- Language point: Impersonal Haber / Se
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Había varias cifras incorrectas.`
- First-pass corrected text: `Había varias cifras incorrectas.`
- Naturalness on original text: Habían varias cifras incorrectas. -> Había varias cifras incorrectas.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Había varias cifras incorrectas.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 685 | 156 | $0.000390 |
| Naturalness (original) | 2252 | 387 | $0.001403 |
| Naturalness (first-pass corrected) | 1136 | 311 | $0.000643 |
| **Total** | 4073 | 854 | $0.002435 |

## collocation-hacer-decision

- Input text: `Necesito hacer una decisión.`
- Note: English-influenced "hacer una decisión" calque.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Necesito tomar una decisión.`
- First-pass corrected text: `Necesito tomar una decisión.`
- Naturalness on original text: hacer una decisión -> tomar una decisión
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Necesito tomar una decisión.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 569 | 154 | $0.000380 |
| Naturalness (original) | 1636 | 374 | $0.001281 |
| Naturalness (first-pass corrected) | 1026 | 310 | $0.000641 |
| **Total** | 3231 | 838 | $0.002302 |

## collocation-hacer-atencion

- Input text: `Tenemos que hacer atención.`
- Note: English-influenced "hacer atención" calque.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Tenemos que prestar atención.`
- First-pass corrected text: `Tenemos que prestar atención.`
- Naturalness on original text: hacer atención -> prestar atención
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Tenemos que prestar atención.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 578 | 152 | $0.000370 |
| Naturalness (original) | 2077 | 365 | $0.001200 |
| Naturalness (first-pass corrected) | 927 | 309 | $0.000640 |
| **Total** | 3582 | 826 | $0.002210 |

## collocation-tomar-reunion

- Input text: `El equipo tomó una reunión.`
- Note: English-influenced "tomar una reunión" calque.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `El equipo tuvo una reunión.`
- First-pass corrected text: `El equipo tuvo una reunión.`
- Naturalness on original text: tomó una reunión -> tuvo una reunión / se reunió
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `El equipo tuvo una reunión.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 713 | 154 | $0.000380 |
| Naturalness (original) | 1633 | 382 | $0.001361 |
| Naturalness (first-pass corrected) | 1032 | 310 | $0.000641 |
| **Total** | 3378 | 846 | $0.002383 |

## collocation-hacer-paseo

- Input text: `Ella hizo un paseo.`
- Note: English-influenced "hacer un paseo" calque.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Ella dio un paseo.`
- First-pass corrected text: `Ella hizo un paseo.`
- Naturalness on original text: hizo un paseo -> dio un paseo
- Naturalness on first-pass corrected text: hizo un paseo -> dio un paseo
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Ella dio un paseo.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 709 | 152 | $0.000370 |
| Naturalness (original) | 1864 | 385 | $0.001400 |
| Naturalness (first-pass corrected) | 1573 | 366 | $0.001210 |
| **Total** | 4146 | 903 | $0.002980 |

## collocation-hace-sentido

- Input text: `Esto hace sentido.`
- Note: English-influenced "hace sentido" calque.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Esto tiene sentido.`
- First-pass corrected text: `Esto hace sentido.`
- Naturalness on original text: Hace sentido -> Tiene sentido
- Naturalness on first-pass corrected text: Esto hace sentido. -> Esto tiene sentido.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Esto tiene sentido.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 582 | 150 | $0.000360 |
| Naturalness (original) | 1576 | 373 | $0.001289 |
| Naturalness (first-pass corrected) | 1560 | 366 | $0.001219 |
| **Total** | 3718 | 889 | $0.002868 |

## false-friend-atendio-universidad

- Input text: `Atendió la universidad en Madrid.`
- Note: "atender" is a false friend for "attend"; needs "asistir a".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Asistió a la universidad en Madrid.`
- First-pass corrected text: `Asistió a la universidad en Madrid.`
- Naturalness on original text: Atendió la universidad en Madrid -> Estudió en la universidad en Madrid
- Naturalness on first-pass corrected text: Asistió a la universidad en Madrid. -> Estudió en la universidad en Madrid.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Estudió en la universidad en Madrid.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 554 | 159 | $0.000408 |
| Naturalness (original) | 1945 | 396 | $0.001484 |
| Naturalness (first-pass corrected) | 1844 | 402 | $0.001535 |
| **Total** | 4343 | 957 | $0.003427 |

## false-friend-aplico-trabajo

- Input text: `Aplicó para un trabajo.`
- Note: "aplicar para" is a false friend for "apply for"; needs "solicitar".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Solicitó un trabajo.`
- First-pass corrected text: `Aplicó a un trabajo.`
- Naturalness on original text: Aplicó para un trabajo. -> Solicitó un trabajo.
- Naturalness on first-pass corrected text: Aplicó a un trabajo. -> Se postuló a un trabajo.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Se postuló a un trabajo.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 552 | 154 | $0.000380 |
| Naturalness (original) | 2277 | 423 | $0.001771 |
| Naturalness (first-pass corrected) | 1947 | 388 | $0.001421 |
| **Total** | 4776 | 965 | $0.003573 |

## false-friend-realice

- Input text: `Realicé que estaba equivocado.`
- Note: "realizar" is a false friend for "realize"; needs "darse cuenta de".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Me di cuenta de que estaba equivocado.`
- First-pass corrected text: `Me di cuenta de que estaba equivocado.`
- Naturalness on original text: Realicé que estaba equivocado. -> Me di cuenta de que estaba equivocado.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Me di cuenta de que estaba equivocado.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 679 | 159 | $0.000408 |
| Naturalness (original) | 1843 | 382 | $0.001344 |
| Naturalness (first-pass corrected) | 1024 | 313 | $0.000645 |
| **Total** | 3546 | 854 | $0.002397 |

## false-friend-embarazado

- Input text: `Estoy embarazado por llegar tarde.`
- Note: "embarazado" is a false friend for "embarrassed"; needs "me da vergüenza".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Me da vergüenza llegar tarde.`
- First-pass corrected text: `Estoy apenado por llegar tarde.`
- Naturalness on original text: Estoy embarazado por llegar tarde. -> Me da vergüenza haber llegado tarde.
- Naturalness on first-pass corrected text: Estoy apenado por llegar tarde. -> Siento llegar tarde.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Siento llegar tarde.`
- Final correction count: 1
- Score: partial_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 676 | 158 | $0.000400 |
| Naturalness (original) | 2255 | 434 | $0.001864 |
| Naturalness (first-pass corrected) | 1941 | 401 | $0.001534 |
| **Total** | 4872 | 993 | $0.003798 |

## false-friend-actualmente-control

- Input text: `Actualmente vivo en Londres.`
- Note: Already correct: "actualmente" (currently) used correctly here, not as a false-friend trap for "actually".
- Language point: False Friends / Word Choice
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Actualmente vivo en Londres.`
- First-pass corrected text: `Actualmente vivo en Londres.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Actualmente vivo en Londres.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 682 | 152 | $0.000370 |
| Naturalness (original) | 923 | 309 | $0.000640 |
| Naturalness (first-pass corrected) | 1022 | 309 | $0.000640 |
| **Total** | 2627 | 770 | $0.001650 |

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
| First pass | 502 | 156 | $0.000390 |
| Naturalness (original) | 1818 | 394 | $0.001472 |
| Naturalness (first-pass corrected) | 2353 | 410 | $0.001632 |
| **Total** | 4673 | 960 | $0.003495 |

## naturalness-corriendo-tarde

- Input text: `Estoy corriendo tarde para la reunión.`
- Note: English-influenced "corriendo tarde" ("running late").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `Voy tarde a la reunión.`
- First-pass corrected text: `Estoy llegando tarde para la reunión.`
- Naturalness on original text: Estoy corriendo tarde para la reunión. -> Llego tarde a la reunión.
- Naturalness on first-pass corrected text: Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Voy a llegar tarde a la reunión.`
- Final correction count: 1
- Score: partial_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 697 | 157 | $0.000392 |
| Naturalness (original) | 2253 | 398 | $0.001504 |
| Naturalness (first-pass corrected) | 2304 | 422 | $0.001752 |
| **Total** | 5254 | 977 | $0.003648 |

## naturalness-pasar-buen-tiempo

- Input text: `Quiero pasar un buen tiempo.`
- Note: English-influenced "pasar un buen tiempo" ("have a good time").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `Quiero pasarlo bien.`
- First-pass corrected text: `Quiero pasar un buen tiempo.`
- Naturalness on original text: pasar un buen tiempo -> pasarlo bien / pasar un buen rato
- Naturalness on first-pass corrected text: pasar un buen tiempo -> pasarlo bien / pasar un buen rato
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Quiero pasarlo bien / pasar un buen rato.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 637 | 156 | $0.000390 |
| Naturalness (original) | 1920 | 387 | $0.001403 |
| Naturalness (first-pass corrected) | 2160 | 392 | $0.001453 |
| **Total** | 4717 | 935 | $0.003245 |

## naturalness-puedo-tener-cerveza

- Input text: `¿Puedo tener una cerveza?`
- Note: English-influenced "¿puedo tener?" ("can I have?").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `¿Me pones una cerveza?`
- First-pass corrected text: `¿Puedo tener una cerveza?`
- Naturalness on original text: ¿Puedo tener una cerveza? -> ¿Me pones una cerveza? / ¿Me das una cerveza? / ¿Me pones una caña?
- Naturalness on first-pass corrected text: ¿Puedo tener una cerveza? -> ¿Me pones una cerveza? / ¿Me traes una cerveza? / ¿Me das una cerveza?
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `¿Me pones una cerveza? / ¿Me das una cerveza? / ¿Me pones una caña?`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 712 | 156 | $0.000390 |
| Naturalness (original) | 2722 | 451 | $0.002043 |
| Naturalness (first-pass corrected) | 2559 | 431 | $0.001842 |
| **Total** | 5993 | 1038 | $0.004275 |

## naturalness-llamar-para-atras

- Input text: `Te llamo para atrás.`
- Note: English-influenced "llamar para atrás" ("call back").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `Te devuelvo la llamada.`
- First-pass corrected text: `Te llamo para atrás.`
- Naturalness on original text: Te llamo para atrás. -> Te devuelvo la llamada.
- Naturalness on first-pass corrected text: Te llamo para atrás. -> Te devuelvo la llamada.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Te devuelvo la llamada.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 681 | 154 | $0.000380 |
| Naturalness (original) | 2364 | 415 | $0.001691 |
| Naturalness (first-pass corrected) | 2037 | 400 | $0.001541 |
| **Total** | 5082 | 969 | $0.003613 |

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
| First pass | 681 | 155 | $0.000388 |
| Naturalness (original) | 986 | 310 | $0.000641 |
| Naturalness (first-pass corrected) | 1163 | 311 | $0.000643 |
| **Total** | 2830 | 776 | $0.001672 |

## regional-vos-tenes

- Input text: `Vos tenés razón.`
- Note: Valid Rioplatense voseo; must not be flagged.
- Language point: Valid Regional / Should Not Flag
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Vos tenés razón.`
- First-pass corrected text: `Vos tenés razón.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Vos tenés razón.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 594 | 152 | $0.000370 |
| Naturalness (original) | 979 | 309 | $0.000640 |
| Naturalness (first-pass corrected) | 1165 | 309 | $0.000640 |
| **Total** | 2738 | 770 | $0.001650 |

## regional-cojo-autobus

- Input text: `Cojo el autobús cada mañana.`
- Note: Valid Peninsular "coger"; must not be flagged.
- Language point: Valid Regional / Should Not Flag
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Cojo el autobús cada mañana.`
- First-pass corrected text: `Cojo el autobús cada mañana.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Cojo el autobús cada mañana.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 668 | 158 | $0.000400 |
| Naturalness (original) | 1048 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 1016 | 312 | $0.000644 |
| **Total** | 2732 | 782 | $0.001687 |

## regional-preterite-esta-manana

- Input text: `Esta mañana hablé con mi jefe.`
- Note: Valid preterite-for-recent-past regional usage; must not be flagged.
- Language point: Valid Regional / Should Not Flag
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Esta mañana hablé con mi jefe.`
- First-pass corrected text: `Esta mañana hablé con mi jefe.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Esta mañana hablé con mi jefe.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 563 | 158 | $0.000400 |
| Naturalness (original) | 1000 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 931 | 312 | $0.000644 |
| **Total** | 2494 | 782 | $0.001687 |

## regional-dale

- Input text: `Dale, nos vemos más tarde.`
- Note: Valid colloquial "dale"; must not be flagged.
- Language point: Valid Regional / Should Not Flag
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Dale, nos vemos más tarde.`
- First-pass corrected text: `Dale, nos vemos más tarde.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Dale, nos vemos más tarde.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 592 | 158 | $0.000400 |
| Naturalness (original) | 1122 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 1029 | 312 | $0.000644 |
| **Total** | 2743 | 782 | $0.001687 |

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
| First pass | 682 | 156 | $0.000390 |
| Naturalness (original) | 977 | 311 | $0.000643 |
| Naturalness (first-pass corrected) | 1068 | 311 | $0.000643 |
| **Total** | 2727 | 778 | $0.001675 |

## correct-hacer-pregunta

- Input text: `Voy a hacer una pregunta al profesor.`
- Note: Already correct ("hacer una pregunta" is standard, unlike "hacer una decisión"); must not be tinkered with.
- Language point: Already Correct / Do Not Tinker
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Voy a hacer una pregunta al profesor.`
- First-pass corrected text: `Voy a hacer una pregunta al profesor.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Voy a hacer una pregunta al profesor.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 579 | 158 | $0.000400 |
| Naturalness (original) | 1029 | 312 | $0.000644 |
| Naturalness (first-pass corrected) | 1122 | 312 | $0.000644 |
| **Total** | 2730 | 782 | $0.001687 |

## correct-tomar-foto

- Input text: `Necesito tomar una foto del documento.`
- Note: Already correct; must not be tinkered with.
- Language point: Already Correct / Do Not Tinker
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Necesito tomar una foto del documento.`
- First-pass corrected text: `Necesito tomar una foto del documento.`
- Naturalness on original text: tomar una foto -> sacar una foto / hacer una foto
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Necesito sacar una foto / hacer una foto del documento.`
- Final correction count: 1
- Score: overcorrection

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 577 | 158 | $0.000400 |
| Naturalness (original) | 2356 | 400 | $0.001524 |
| Naturalness (first-pass corrected) | 1228 | 312 | $0.000644 |
| **Total** | 4161 | 870 | $0.002567 |

## correct-visitar-abuela

- Input text: `Mañana visitaré a mi abuela.`
- Note: Already correct; must not be tinkered with.
- Language point: Already Correct / Do Not Tinker
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Mañana visitaré a mi abuela.`
- First-pass corrected text: `Mañana visitaré a mi abuela.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Mañana visitaré a mi abuela.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 580 | 162 | $0.000420 |
| Naturalness (original) | 1122 | 314 | $0.000646 |
| Naturalness (first-pass corrected) | 1023 | 314 | $0.000646 |
| **Total** | 2725 | 790 | $0.001713 |

## correct-me-quedo-en-casa

- Input text: `Está lloviendo, así que me quedo en casa.`
- Note: Already correct; must not be tinkered with.
- Language point: Already Correct / Do Not Tinker
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Está lloviendo, así que me quedo en casa.`
- First-pass corrected text: `Está lloviendo, así que me quedo en casa.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Está lloviendo, así que me quedo en casa.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 782 | 168 | $0.000450 |
| Naturalness (original) | 1023 | 317 | $0.000650 |
| Naturalness (first-pass corrected) | 1239 | 317 | $0.000650 |
| **Total** | 3044 | 802 | $0.001750 |

## mixed-preposition-and-redundant-pronoun

- Input text: `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Note: Combines a required-preposition insertion ("insisto en que") with a redundant repeated-pronoun deletion (second "yo").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y estudio por las noches.`
- First-pass corrected text: `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.`
- Naturalness on original text: Insisto que revises el contrato -> Insisto en que revises el contrato<br>y yo trabajo mucho y yo estudio por las noches -> yo trabajo mucho y estudio por las noches
- Naturalness on first-pass corrected text: y yo trabajo mucho y yo estudio por las noches -> yo trabajo mucho y estudio por las noches
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.`
- Final correction count: 1
- Score: partial_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 830 | 181 | $0.000518 |
| Naturalness (original) | 2303 | 455 | $0.001978 |
| Naturalness (first-pass corrected) | 2149 | 404 | $0.001459 |
| **Total** | 5282 | 1040 | $0.003954 |

## mixed-article-and-accent

- Input text: `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.`
- Note: Combines a missing-article insertion ("un libro") with missing accents ("compré", "café", "cafetería", "pequeña").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- First-pass corrected text: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- Naturalness on original text: comprar libro -> comprar un libro<br>cafe -> café<br>una cafeteria pequena -> una cafetería pequeña
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 1089 | 177 | $0.000504 |
| Naturalness (original) | 2687 | 473 | $0.002184 |
| Naturalness (first-pass corrected) | 1305 | 323 | $0.000657 |
| **Total** | 5081 | 973 | $0.003345 |

## mixed-personal-a-and-subjunctive

- Input text: `Vi mi profesor en la estación, y es importante que estudias.`
- Note: Combines a missing personal-"a" insertion with a subjunctive-mood replacement ("estudias" -> "estudies").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Vi a mi profesor en la estación, y es importante que estudies.`
- First-pass corrected text: `Vi a mi profesor en la estación, y es importante que estudies.`
- Naturalness on original text: Vi mi profesor en la estación -> Vi a mi profesor en la estación<br>es importante que estudias -> es importante que estudies
- Naturalness on first-pass corrected text: Vi a mi profesor en la estación, y es importante que estudies. -> Vi a mi profesor en la estación, y me dijo que era importante que estudiara.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Vi a mi profesor en la estación, y me dijo que era importante que estudiara.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 1396 | 171 | $0.000468 |
| Naturalness (original) | 2561 | 462 | $0.002091 |
| Naturalness (first-pass corrected) | 2554 | 440 | $0.001862 |
| **Total** | 6511 | 1073 | $0.004422 |

## mixed-gender-agreement-and-redundant-pronoun

- Input text: `Las ventanas estaban abierto, y a mí me gusta el café a mí.`
- Note: Combines a gender-agreement replacement ("abierto" -> "abiertas") with a redundant-pronoun deletion (trailing "a mí").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Las ventanas estaban abiertas, y a mí me gusta el café.`
- First-pass corrected text: `Las ventanas estaban abiertas, y a mí me gusta el café a mí.`
- Naturalness on original text: Las ventanas estaban abierto -> Las ventanas estaban abiertas<br>y a mí me gusta el café a mí -> y a mí me gusta el café
- Naturalness on first-pass corrected text: y a mí me gusta el café a mí -> y a mí me gusta el café
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Las ventanas estaban abiertas, y a mí me gusta el café.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 888 | 172 | $0.000470 |
| Naturalness (original) | 2423 | 457 | $0.002033 |
| Naturalness (first-pass corrected) | 2184 | 384 | $0.001302 |
| **Total** | 5495 | 1013 | $0.003805 |

## mixed-verb-agreement-and-missing-que

- Input text: `Ellos estudia todas las noches, y creo está bien terminar hoy.`
- Note: Combines a verb-agreement replacement ("estudia" -> "estudian") with a missing-connector insertion ("creo que").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- First-pass corrected text: `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- Naturalness on original text: Ellos estudia todas las noches -> Ellos estudian todas las noches<br>creo está bien terminar hoy -> creo que está bien terminar hoy
- Naturalness on first-pass corrected text: Ellos estudian -> Estudian<br>creo que está bien terminar hoy -> creo que podemos terminar hoy
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Estudian todas las noches, y creo que podemos terminar hoy.`
- Final correction count: 2
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 643 | 173 | $0.000478 |
| Naturalness (original) | 3621 | 468 | $0.002142 |
| Naturalness (first-pass corrected) | 2544 | 479 | $0.002244 |
| **Total** | 6808 | 1120 | $0.004864 |

---

## Overall summary

| Fixtures | Errors | Conflicts | Fallbacks used | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 85 | 0 | 48 | 48 | 332005 | 73848 | $0.217080 |

### Score summary

| Score | Count |
| --- | --- |
| correct_fix | 56 |
| partial_fix | 4 |
| overcorrection | 3 |
| acceptable_no_change | 11 |
| ambiguous | 11 |

### Language point summary

| Language point | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Accents / Diacritics | 6 | 5 | 0 | 0 | 0 | 0 | 1 | 0 |
| Collocations / Strong Calques | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 0 |
| Accents / Diacritics + Collocations / Strong Calques (independent spans) | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Verb Morphology (spelling) overlapping Collocations / Strong Calques | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ambiguous / Repeated Span Safety (Naturalness) | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| Gender / Number Agreement | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Verb Agreement / Morphology | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Required Prepositions | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Articles / Determiners | 5 | 3 | 1 | 0 | 0 | 0 | 1 | 0 |
| Subjunctive / Mood | 5 | 4 | 0 | 0 | 0 | 0 | 1 | 0 |
| Required Additions / Omissions | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Unnecessary Extras / Deletions | 5 | 3 | 0 | 0 | 0 | 0 | 2 | 0 |
| Ser / Estar / Haber | 5 | 3 | 0 | 0 | 0 | 2 | 0 | 0 |
| Impersonal Haber / Se | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| False Friends / Word Choice | 5 | 1 | 1 | 0 | 0 | 1 | 2 | 0 |
| Phrase-Level Naturalness | 5 | 2 | 1 | 0 | 0 | 0 | 2 | 0 |
| Valid Regional / Should Not Flag | 5 | 0 | 0 | 0 | 1 | 4 | 0 | 0 |
| Already Correct / Do Not Tinker | 5 | 0 | 0 | 0 | 1 | 4 | 0 | 0 |
| Mixed Operations | 5 | 2 | 1 | 0 | 0 | 0 | 2 | 0 |

### Operation type summary

| Operation type | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| replacement | 46 | 38 | 2 | 0 | 0 | 0 | 6 | 0 |
| no_change | 14 | 0 | 0 | 0 | 3 | 11 | 0 | 0 |
| insertion | 15 | 13 | 1 | 0 | 0 | 0 | 1 | 0 |
| deletion | 5 | 3 | 0 | 0 | 0 | 0 | 2 | 0 |
| mixed | 5 | 2 | 1 | 0 | 0 | 0 | 2 | 0 |

### Expected owner summary

| Expected owner | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| first_pass | 54 | 45 | 2 | 0 | 0 | 0 | 7 | 0 |
| naturalness | 6 | 3 | 1 | 0 | 0 | 0 | 2 | 0 |
| either | 11 | 8 | 1 | 0 | 0 | 0 | 2 | 0 |
| no_change | 14 | 0 | 0 | 0 | 3 | 11 | 0 | 0 |

### Fallback / conflict summary

| Metric | Count | Rate |
| --- | --- | --- |
| Conflicts | 48 | 56.5% |
| Fallbacks used | 48 | 56.5% |

### Latency / cost outliers

- Average latency: 3906 ms; average cost: $0.002554 (over 85 non-error fixture(s)).
- Outlier threshold: 1.5x the average latency or cost.

| Fixture | Latency (ms) | Est. cost (USD) |
| --- | --- | --- |
| ambiguous-naturalness-span | 5492 | $0.003933 |
| naturalness-puedo-tener-cerveza | 5993 | $0.004275 |
| mixed-preposition-and-redundant-pronoun | 5282 | $0.003954 |
| mixed-personal-a-and-subjunctive | 6511 | $0.004422 |
| mixed-verb-agreement-and-missing-que | 6808 | $0.004864 |
