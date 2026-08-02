# Two-Pass Live Integration Harness

## Run configuration

- Pass 1: `callFirstPassCorrection` — the simple, narrow `corrected_text`-only first-pass client (issue #68/#65), not the old broad `runStagedCorrectionPipeline`.
- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture selection: all (85 fixtures) (issue #85)
- Fixture count: `85`
- Generated: 2026-08-02T22:29:36.945131Z

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
- Naturalness on original text: mucho trafico -> mucho tráfico
- Naturalness on first-pass corrected text: Vi mucho tráfico ayer. -> Había mucho tráfico ayer.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Había mucho tráfico ayer.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 1815 | 153 | $0.000372 |
| Naturalness (original) | 3438 | 371 | $0.001251 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 3440 | — | — |
| Naturalness (first-pass corrected) | 2048 | 390 | $0.001450 |
| **Total** | 5488 | 914 | $0.003073 |

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
| First pass | 807 | 156 | $0.000390 |
| Naturalness (original) | 1789 | 370 | $0.001233 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1790 | — | — |
| Naturalness (first-pass corrected) | 1095 | 311 | $0.000643 |
| **Total** | 2885 | 837 | $0.002265 |

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
| First pass | 918 | 172 | $0.000470 |
| Naturalness (original) | 1469 | 384 | $0.001302 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1469 | — | — |
| Naturalness (first-pass corrected) | 1128 | 319 | $0.000652 |
| **Total** | 2597 | 875 | $0.002425 |

## grammar-overlaps-naturalness

- Input text: `Ayer iso una decisión importante.`
- Note: The first-pass fix ("iso" -> "hizo") sits inside the exact naturalness calque span ("hizo una decisión") — the case the fallback exists for. Expect: naturalness-on-original flags the pre-correction wording (conflict against firstPassCorrectedText), naturalness-on-corrected flags the post-correction wording (resolves cleanly) — fallback used.
- Language point: Verb Morphology (spelling) overlapping Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Ayer tomó una decisión importante.`
- First-pass corrected text: `Ayer hizo una decisión importante.`
- Naturalness on original text: iso una decisión -> tomó una decisión
- Naturalness on first-pass corrected text: hizo una decisión importante -> tomó una decisión importante
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Ayer tomó una decisión importante.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 570 | 156 | $0.000390 |
| Naturalness (original) | 1764 | 377 | $0.001303 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1765 | — | — |
| Naturalness (first-pass corrected) | 1952 | 399 | $0.001522 |
| **Total** | 3717 | 932 | $0.003215 |

## ambiguous-naturalness-span

- Input text: `Vi mucho tráfico, y luego vi más tráfico.`
- Note: No first-pass fix needed; naturalness may flag a bare repeated word ambiguously on both passes. Expect: possible conflict that the fallback does not resolve either — the "still unsafe after a rerun" case from issue #37, observed live rather than simulated.
- Language point: Ambiguous / Repeated Span Safety (Naturalness)
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- First-pass corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Naturalness on original text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico, y luego todavía más.
- Naturalness on first-pass corrected text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico, y luego todavía más.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Había mucho tráfico, y luego todavía más.`
- Final correction count: 1
- Score: overcorrection

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 672 | 162 | $0.000420 |
| Naturalness (original) | 2383 | 416 | $0.001666 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2384 | — | — |
| Naturalness (first-pass corrected) | 2894 | 399 | $0.001496 |
| **Total** | 5278 | 977 | $0.003583 |

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
| First pass | 745 | 158 | $0.000400 |
| Naturalness (original) | 1183 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1184 | — | — |
| Naturalness (first-pass corrected) | 1139 | 312 | $0.000644 |
| **Total** | 2323 | 782 | $0.001687 |

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
| First pass | 680 | 159 | $0.000402 |
| Naturalness (original) | 984 | 313 | $0.000645 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 984 | — | — |
| Naturalness (first-pass corrected) | 1023 | 312 | $0.000644 |
| **Total** | 2007 | 784 | $0.001691 |

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
| First pass | 576 | 157 | $0.000392 |
| Naturalness (original) | 1601 | 354 | $0.001064 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1602 | — | — |
| Naturalness (first-pass corrected) | 1024 | 311 | $0.000643 |
| **Total** | 2626 | 822 | $0.002098 |

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
| First pass | 679 | 156 | $0.000384 |
| Naturalness (original) | 2520 | 455 | $0.002074 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2521 | — | — |
| Naturalness (first-pass corrected) | 1024 | 310 | $0.000641 |
| **Total** | 3545 | 921 | $0.003099 |

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
| First pass | 674 | 159 | $0.000408 |
| Naturalness (original) | 3036 | 508 | $0.002604 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 3036 | — | — |
| Naturalness (first-pass corrected) | 1019 | 313 | $0.000645 |
| **Total** | 4055 | 980 | $0.003657 |

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
| First pass | 620 | 157 | $0.000398 |
| Naturalness (original) | 1110 | 311 | $0.000643 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1111 | — | — |
| Naturalness (first-pass corrected) | 1419 | 312 | $0.000644 |
| **Total** | 2530 | 780 | $0.001684 |

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
| First pass | 576 | 152 | $0.000370 |
| Naturalness (original) | 1087 | 309 | $0.000640 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1088 | — | — |
| Naturalness (first-pass corrected) | 1125 | 309 | $0.000640 |
| **Total** | 2213 | 770 | $0.001650 |

## agreement-puerta-cerrada

- Input text: `Una puerta estaba cerrado.`
- Note: Predicate adjective must agree in gender with "puerta".
- Language point: Gender / Number Agreement
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Una puerta estaba cerrada.`
- First-pass corrected text: `Una puerta estaba cerrada.`
- Naturalness on original text: estaba cerrado -> estaba cerrada
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Una puerta estaba cerrada.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 682 | 153 | $0.000378 |
| Naturalness (original) | 2421 | 381 | $0.001360 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2422 | — | — |
| Naturalness (first-pass corrected) | 1331 | 310 | $0.000641 |
| **Total** | 3753 | 844 | $0.002379 |

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
| First pass | 577 | 154 | $0.000380 |
| Naturalness (original) | 1499 | 310 | $0.000641 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1499 | — | — |
| Naturalness (first-pass corrected) | 1023 | 310 | $0.000641 |
| **Total** | 2522 | 774 | $0.001662 |

## agreement-fechas-escritas

- Input text: `Las fechas estaban escrito sin tilde.`
- Note: Predicate participle must agree in gender/number with "fechas".
- Language point: Gender / Number Agreement
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Las fechas estaban escritas sin tilde.`
- First-pass corrected text: `Las fechas estaban escritas sin tilde.`
- Naturalness on original text: Las fechas estaban escrito -> Las fechas estaban escritas
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Las fechas estaban escritas sin tilde.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 575 | 159 | $0.000408 |
| Naturalness (original) | 1650 | 379 | $0.001314 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1651 | — | — |
| Naturalness (first-pass corrected) | 970 | 313 | $0.000645 |
| **Total** | 2621 | 851 | $0.002367 |

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
| First pass | 906 | 161 | $0.000418 |
| Naturalness (original) | 1106 | 313 | $0.000645 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1107 | — | — |
| Naturalness (first-pass corrected) | 1111 | 314 | $0.000646 |
| **Total** | 2218 | 788 | $0.001709 |

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
| First pass | 779 | 156 | $0.000390 |
| Naturalness (original) | 1191 | 311 | $0.000643 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1192 | — | — |
| Naturalness (first-pass corrected) | 1026 | 311 | $0.000643 |
| **Total** | 2218 | 778 | $0.001675 |

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
| First pass | 676 | 159 | $0.000408 |
| Naturalness (original) | 1393 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1394 | — | — |
| Naturalness (first-pass corrected) | 1226 | 313 | $0.000645 |
| **Total** | 2620 | 784 | $0.001697 |

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
| First pass | 686 | 158 | $0.000400 |
| Naturalness (original) | 1005 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1006 | — | — |
| Naturalness (first-pass corrected) | 1144 | 312 | $0.000644 |
| **Total** | 2150 | 782 | $0.001687 |

## verb-nosotros-vivimos

- Input text: `Nosotros vive cerca del centro.`
- Note: "vive" must be "vivimos" to agree with "nosotros".
- Language point: Verb Agreement / Morphology
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Nosotros vivimos cerca del centro.`
- First-pass corrected text: `Nosotros vivimos cerca del centro.`
- Naturalness on original text: Nosotros vive cerca del centro. -> Nosotros vivimos cerca del centro.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Nosotros vivimos cerca del centro.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 1192 | 156 | $0.000390 |
| Naturalness (original) | 2393 | 408 | $0.001613 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2394 | — | — |
| Naturalness (first-pass corrected) | 1121 | 311 | $0.000643 |
| **Total** | 3515 | 875 | $0.002645 |

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
| First pass | 689 | 159 | $0.000408 |
| Naturalness (original) | 1909 | 390 | $0.001424 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1910 | — | — |
| Naturalness (first-pass corrected) | 985 | 313 | $0.000645 |
| **Total** | 2895 | 862 | $0.002477 |

## prep-empresa-en-la-que

- Input text: `La empresa que trabajo está cerca.`
- Note: Relative clause needs "en la que" (working "at/in" the company).
- Language point: Required Prepositions
- Operation type: insertion
- Expected owner: first_pass
- Expected corrected text: `La empresa en la que trabajo está cerca.`
- First-pass corrected text: `La empresa en que trabajo está cerca.`
- Naturalness on original text: La empresa que trabajo está cerca. -> La empresa donde trabajo está cerca.
- Naturalness on first-pass corrected text: La empresa en que trabajo está cerca. -> La empresa donde trabajo está cerca.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `La empresa donde trabajo está cerca.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 592 | 157 | $0.000398 |
| Naturalness (original) | 2356 | 383 | $0.001362 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2357 | — | — |
| Naturalness (first-pass corrected) | 2252 | 380 | $0.001324 |
| **Total** | 4609 | 920 | $0.003084 |

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
| First pass | 677 | 159 | $0.000408 |
| Naturalness (original) | 2009 | 387 | $0.001394 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2010 | — | — |
| Naturalness (first-pass corrected) | 1022 | 313 | $0.000645 |
| **Total** | 3032 | 859 | $0.002447 |

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
| First pass | 581 | 157 | $0.000398 |
| Naturalness (original) | 2014 | 384 | $0.001373 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2015 | — | — |
| Naturalness (first-pass corrected) | 1135 | 312 | $0.000644 |
| **Total** | 3150 | 853 | $0.002414 |

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
| First pass | 569 | 157 | $0.000398 |
| Naturalness (original) | 1899 | 395 | $0.001482 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1900 | — | — |
| Naturalness (first-pass corrected) | 2615 | 312 | $0.000644 |
| **Total** | 4515 | 864 | $0.002524 |

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
| First pass | 694 | 153 | $0.000378 |
| Naturalness (original) | 3289 | 374 | $0.001290 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 3289 | — | — |
| Naturalness (first-pass corrected) | 1177 | 310 | $0.000641 |
| **Total** | 4466 | 837 | $0.002309 |

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
| First pass | 523 | 159 | $0.000408 |
| Naturalness (original) | 2060 | 395 | $0.001474 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2060 | — | — |
| Naturalness (first-pass corrected) | 975 | 313 | $0.000645 |
| **Total** | 3035 | 867 | $0.002527 |

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
| First pass | 525 | 156 | $0.000396 |
| Naturalness (original) | 1955 | 377 | $0.001311 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1956 | — | — |
| Naturalness (first-pass corrected) | 1367 | 312 | $0.000644 |
| **Total** | 3323 | 845 | $0.002351 |

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
| First pass | 542 | 159 | $0.000408 |
| Naturalness (original) | 2693 | 377 | $0.001294 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2694 | — | — |
| Naturalness (first-pass corrected) | 1236 | 313 | $0.000645 |
| **Total** | 3930 | 849 | $0.002347 |

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
| First pass | 773 | 155 | $0.000388 |
| Naturalness (original) | 1900 | 368 | $0.001221 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1901 | — | — |
| Naturalness (first-pass corrected) | 1332 | 311 | $0.000643 |
| **Total** | 3233 | 834 | $0.002252 |

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
| First pass | 561 | 154 | $0.000380 |
| Naturalness (original) | 1143 | 310 | $0.000641 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1144 | — | — |
| Naturalness (first-pass corrected) | 1067 | 310 | $0.000641 |
| **Total** | 2211 | 774 | $0.001662 |

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
| First pass | 737 | 154 | $0.000380 |
| Naturalness (original) | 2424 | 398 | $0.001521 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2425 | — | — |
| Naturalness (first-pass corrected) | 1125 | 310 | $0.000641 |
| **Total** | 3550 | 862 | $0.002543 |

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
| First pass | 679 | 156 | $0.000390 |
| Naturalness (original) | 2728 | 386 | $0.001393 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2729 | — | — |
| Naturalness (first-pass corrected) | 1328 | 311 | $0.000643 |
| **Total** | 4057 | 853 | $0.002425 |

## subj-enviara

- Input text: `Era necesario que enviaba su parte.`
- Note: Impersonal past "era necesario que" requires the imperfect subjunctive.
- Language point: Subjunctive / Mood
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Era necesario que enviara su parte.`
- First-pass corrected text: `Era necesario que enviara su parte.`
- Naturalness on original text: enviaba su parte -> enviara su parte
- Naturalness on first-pass corrected text: su parte -> su informe / su reporte / su formulario (según el contexto)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Era necesario que enviara su informe / su reporte / su formulario (según el contexto).`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 513 | 158 | $0.000400 |
| Naturalness (original) | 2012 | 387 | $0.001394 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2013 | — | — |
| Naturalness (first-pass corrected) | 3993 | 444 | $0.001964 |
| **Total** | 6006 | 989 | $0.003758 |

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
| First pass | 659 | 159 | $0.000408 |
| Naturalness (original) | 3722 | 383 | $0.001354 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 3723 | — | — |
| Naturalness (first-pass corrected) | 1156 | 313 | $0.000645 |
| **Total** | 4879 | 855 | $0.002407 |

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
| First pass | 691 | 155 | $0.000388 |
| Naturalness (original) | 2114 | 386 | $0.001401 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2114 | — | — |
| Naturalness (first-pass corrected) | 981 | 311 | $0.000643 |
| **Total** | 3095 | 852 | $0.002432 |

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
| First pass | 619 | 157 | $0.000398 |
| Naturalness (original) | 1985 | 386 | $0.001393 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1985 | — | — |
| Naturalness (first-pass corrected) | 1162 | 312 | $0.000644 |
| **Total** | 3147 | 855 | $0.002434 |

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
| First pass | 604 | 157 | $0.000398 |
| Naturalness (original) | 2054 | 380 | $0.001332 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2055 | — | — |
| Naturalness (first-pass corrected) | 1172 | 312 | $0.000644 |
| **Total** | 3227 | 849 | $0.002374 |

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
| First pass | 726 | 154 | $0.000380 |
| Naturalness (original) | 2201 | 387 | $0.001411 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2201 | — | — |
| Naturalness (first-pass corrected) | 972 | 310 | $0.000641 |
| **Total** | 3173 | 851 | $0.002432 |

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
| First pass | 588 | 155 | $0.000388 |
| Naturalness (original) | 1826 | 374 | $0.001281 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1827 | — | — |
| Naturalness (first-pass corrected) | 1115 | 311 | $0.000643 |
| **Total** | 2942 | 840 | $0.002312 |

## delete-repeated-yo-estudio

- Input text: `Yo trabajo mucho y yo estudio por las noches.`
- Note: Second "yo" is a redundant repeated subject pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `Yo trabajo mucho y estudio por las noches.`
- First-pass corrected text: `Yo trabajo mucho y yo estudio por las noches.`
- Naturalness on original text: yo trabajo mucho y yo estudio por las noches -> trabajo mucho y estudio por las noches
- Naturalness on first-pass corrected text: Yo trabajo mucho y yo estudio por las noches. -> Trabajo mucho y estudio por las noches.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Trabajo mucho y estudio por las noches.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 783 | 162 | $0.000420 |
| Naturalness (original) | 1897 | 386 | $0.001366 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1898 | — | — |
| Naturalness (first-pass corrected) | 2045 | 400 | $0.001506 |
| **Total** | 3943 | 948 | $0.003293 |

## delete-repeated-ellos-visitaron

- Input text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Note: Second "ellos" is a redundant repeated subject pronoun.
- Language point: Unnecessary Extras / Deletions
- Operation type: deletion
- Expected owner: first_pass
- Expected corrected text: `Ellos viajaron a México y visitaron varias ciudades.`
- First-pass corrected text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Naturalness on original text: Ellos viajaron a México y ellos visitaron varias ciudades. -> Ellos viajaron a México y visitaron varias ciudades.
- Naturalness on first-pass corrected text: Ellos viajaron a México y ellos visitaron varias ciudades. -> Viajaron a México y visitaron varias ciudades.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Ellos viajaron a México y visitaron varias ciudades.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 694 | 168 | $0.000450 |
| Naturalness (original) | 1822 | 384 | $0.001320 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1823 | — | — |
| Naturalness (first-pass corrected) | 2097 | 404 | $0.001520 |
| **Total** | 3920 | 956 | $0.003290 |

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
| First pass | 629 | 158 | $0.000394 |
| Naturalness (original) | 2473 | 376 | $0.001275 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2473 | — | — |
| Naturalness (first-pass corrected) | 1127 | 311 | $0.000643 |
| **Total** | 3600 | 845 | $0.002312 |

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
| First pass | 680 | 162 | $0.000420 |
| Naturalness (original) | 2421 | 408 | $0.001586 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2422 | — | — |
| Naturalness (first-pass corrected) | 2090 | 408 | $0.001586 |
| **Total** | 4512 | 978 | $0.003593 |

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
| First pass | 639 | 166 | $0.000440 |
| Naturalness (original) | 1966 | 400 | $0.001489 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1966 | — | — |
| Naturalness (first-pass corrected) | 2673 | 396 | $0.001449 |
| **Total** | 4639 | 962 | $0.003377 |

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
| First pass | 671 | 152 | $0.000370 |
| Naturalness (original) | 1888 | 355 | $0.001100 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1888 | — | — |
| Naturalness (first-pass corrected) | 1137 | 309 | $0.000640 |
| **Total** | 3025 | 816 | $0.002110 |

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
| First pass | 681 | 156 | $0.000390 |
| Naturalness (original) | 1803 | 376 | $0.001293 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1804 | — | — |
| Naturalness (first-pass corrected) | 895 | 311 | $0.000643 |
| **Total** | 2699 | 843 | $0.002325 |

## ser-capital-madrid

- Input text: `Madrid está la capital de España.`
- Note: Identity/definition requires "ser", not "estar".
- Language point: Ser / Estar / Haber
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Madrid es la capital de España.`
- First-pass corrected text: `Madrid es la capital de España.`
- Naturalness on original text: está la capital de España -> es la capital de España
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Madrid es la capital de España.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 902 | 156 | $0.000390 |
| Naturalness (original) | 1937 | 383 | $0.001362 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1938 | — | — |
| Naturalness (first-pass corrected) | 1024 | 311 | $0.000643 |
| **Total** | 2962 | 850 | $0.002395 |

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
| First pass | 678 | 158 | $0.000400 |
| Naturalness (original) | 987 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 988 | — | — |
| Naturalness (first-pass corrected) | 1022 | 312 | $0.000644 |
| **Total** | 2010 | 782 | $0.001687 |

## ser-reunion-segunda-planta

- Input text: `La reunión es en la segunda planta.`
- Note: Already correct: event location correctly uses "ser".
- Language point: Ser / Estar / Haber
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `La reunión es en la segunda planta.`
- First-pass corrected text: `La reunión es en la segunda planta.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: segunda planta -> segundo piso
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `La reunión es en la segunda planta.`
- Final correction count: 0
- Score: acceptable_no_change

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 577 | 158 | $0.000400 |
| Naturalness (original) | 1296 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1297 | — | — |
| Naturalness (first-pass corrected) | 1945 | 406 | $0.001584 |
| **Total** | 3242 | 876 | $0.002628 |

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
| First pass | 784 | 158 | $0.000400 |
| Naturalness (original) | 2122 | 398 | $0.001504 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2123 | — | — |
| Naturalness (first-pass corrected) | 1217 | 312 | $0.000644 |
| **Total** | 3340 | 868 | $0.002547 |

## haber-hubo-problemas

- Input text: `Hubieron varios problemas durante la reunión.`
- Note: Impersonal "haber" is invariant: "hubo", never "hubieron".
- Language point: Impersonal Haber / Se
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Hubo varios problemas durante la reunión.`
- First-pass corrected text: `Hubo varios problemas durante la reunión.`
- Naturalness on original text: Hubieron varios problemas durante la reunión. -> Hubo varios problemas durante la reunión.
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Hubo varios problemas durante la reunión.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 691 | 158 | $0.000400 |
| Naturalness (original) | 2730 | 400 | $0.001524 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2730 | — | — |
| Naturalness (first-pass corrected) | 1025 | 312 | $0.000644 |
| **Total** | 3755 | 870 | $0.002567 |

## se-venden-pisos

- Input text: `Se vende pisos en el centro.`
- Note: Passive "se" must agree in number with the plural "pisos".
- Language point: Impersonal Haber / Se
- Operation type: replacement
- Expected owner: first_pass
- Expected corrected text: `Se venden pisos en el centro.`
- First-pass corrected text: `Se venden pisos en el centro.`
- Naturalness on original text: Se vende pisos -> Se venden pisos
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Se venden pisos en el centro.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 574 | 156 | $0.000390 |
| Naturalness (original) | 1965 | 381 | $0.001342 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1965 | — | — |
| Naturalness (first-pass corrected) | 1068 | 311 | $0.000643 |
| **Total** | 3033 | 848 | $0.002375 |

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
| First pass | 682 | 158 | $0.000400 |
| Naturalness (original) | 2331 | 384 | $0.001364 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2332 | — | — |
| Naturalness (first-pass corrected) | 1125 | 312 | $0.000644 |
| **Total** | 3457 | 854 | $0.002407 |

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
| First pass | 518 | 156 | $0.000390 |
| Naturalness (original) | 1699 | 385 | $0.001383 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1700 | — | — |
| Naturalness (first-pass corrected) | 1021 | 311 | $0.000643 |
| **Total** | 2721 | 852 | $0.002415 |

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
| First pass | 576 | 154 | $0.000380 |
| Naturalness (original) | 1805 | 380 | $0.001341 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1805 | — | — |
| Naturalness (first-pass corrected) | 1331 | 310 | $0.000641 |
| **Total** | 3136 | 844 | $0.002363 |

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
| First pass | 682 | 152 | $0.000370 |
| Naturalness (original) | 2113 | 364 | $0.001190 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2114 | — | — |
| Naturalness (first-pass corrected) | 1024 | 309 | $0.000640 |
| **Total** | 3138 | 825 | $0.002200 |

## collocation-tomar-reunion

- Input text: `El equipo tomó una reunión.`
- Note: English-influenced "tomar una reunión" calque.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `El equipo tuvo una reunión.`
- First-pass corrected text: `El equipo tuvo una reunión.`
- Naturalness on original text: tomó una reunión -> tuvo una reunión
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `El equipo tuvo una reunión.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 594 | 154 | $0.000380 |
| Naturalness (original) | 1807 | 384 | $0.001381 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1808 | — | — |
| Naturalness (first-pass corrected) | 920 | 310 | $0.000641 |
| **Total** | 2728 | 848 | $0.002402 |

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
| First pass | 783 | 152 | $0.000370 |
| Naturalness (original) | 2162 | 386 | $0.001410 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2163 | — | — |
| Naturalness (first-pass corrected) | 1998 | 377 | $0.001320 |
| **Total** | 4161 | 915 | $0.003100 |

## collocation-hace-sentido

- Input text: `Esto hace sentido.`
- Note: English-influenced "hace sentido" calque.
- Language point: Collocations / Strong Calques
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Esto tiene sentido.`
- First-pass corrected text: `Esto tiene sentido.`
- Naturalness on original text: hace sentido -> tiene sentido
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Esto tiene sentido.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 534 | 150 | $0.000360 |
| Naturalness (original) | 1711 | 369 | $0.001249 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1712 | — | — |
| Naturalness (first-pass corrected) | 1324 | 308 | $0.000639 |
| **Total** | 3036 | 827 | $0.002247 |

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
| First pass | 681 | 159 | $0.000408 |
| Naturalness (original) | 2269 | 409 | $0.001614 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2270 | — | — |
| Naturalness (first-pass corrected) | 2822 | 423 | $0.001745 |
| **Total** | 5092 | 991 | $0.003767 |

## false-friend-aplico-trabajo

- Input text: `Aplicó para un trabajo.`
- Note: "aplicar para" is a false friend for "apply for"; needs "solicitar".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Solicitó un trabajo.`
- First-pass corrected text: `Aplicó para un trabajo.`
- Naturalness on original text: Aplicó para un trabajo -> Solicitó un trabajo
- Naturalness on first-pass corrected text: Aplicó para un trabajo. -> Solicitó un trabajo.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Solicitó un trabajo.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 2211 | 154 | $0.000380 |
| Naturalness (original) | 2210 | 394 | $0.001481 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2211 | — | — |
| Naturalness (first-pass corrected) | 2453 | 402 | $0.001561 |
| **Total** | 4664 | 950 | $0.003423 |

## false-friend-realice

- Input text: `Realicé que estaba equivocado.`
- Note: "realizar" is a false friend for "realize"; needs "darse cuenta de".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Me di cuenta de que estaba equivocado.`
- First-pass corrected text: `Me di cuenta de que estaba equivocado.`
- Naturalness on original text: Realicé que estaba equivocado -> Me di cuenta de que estaba equivocado
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Me di cuenta de que estaba equivocado.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 568 | 159 | $0.000408 |
| Naturalness (original) | 1940 | 376 | $0.001284 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1941 | — | — |
| Naturalness (first-pass corrected) | 992 | 313 | $0.000645 |
| **Total** | 2933 | 848 | $0.002337 |

## false-friend-embarazado

- Input text: `Estoy embarazado por llegar tarde.`
- Note: "embarazado" is a false friend for "embarrassed"; needs "me da vergüenza".
- Language point: False Friends / Word Choice
- Operation type: replacement
- Expected owner: either
- Expected corrected text: `Me da vergüenza llegar tarde.`
- First-pass corrected text: `Estoy avergonzado por llegar tarde.`
- Naturalness on original text: Estoy embarazado por llegar tarde. -> Me da vergüenza llegar tarde.
- Naturalness on first-pass corrected text: Estoy avergonzado por llegar tarde. -> Me da vergüenza llegar tarde.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Me da vergüenza llegar tarde.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 681 | 159 | $0.000408 |
| Naturalness (original) | 2128 | 425 | $0.001774 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2129 | — | — |
| Naturalness (first-pass corrected) | 2120 | 408 | $0.001595 |
| **Total** | 4249 | 992 | $0.003777 |

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
| First pass | 610 | 152 | $0.000370 |
| Naturalness (original) | 1002 | 309 | $0.000640 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1002 | — | — |
| Naturalness (first-pass corrected) | 1020 | 309 | $0.000640 |
| **Total** | 2022 | 770 | $0.001650 |

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
| First pass | 784 | 156 | $0.000390 |
| Naturalness (original) | 1707 | 394 | $0.001472 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1707 | — | — |
| Naturalness (first-pass corrected) | 1664 | 395 | $0.001482 |
| **Total** | 3371 | 945 | $0.003345 |

## naturalness-corriendo-tarde

- Input text: `Estoy corriendo tarde para la reunión.`
- Note: English-influenced "corriendo tarde" ("running late").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `Voy tarde a la reunión.`
- First-pass corrected text: `Estoy llegando tarde para la reunión.`
- Naturalness on original text: Estoy corriendo tarde para la reunión. -> Voy tarde a la reunión.
- Naturalness on first-pass corrected text: para la reunión -> a la reunión
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Estoy llegando tarde a la reunión.`
- Final correction count: 1
- Score: partial_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 528 | 157 | $0.000392 |
| Naturalness (original) | 2088 | 389 | $0.001414 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2089 | — | — |
| Naturalness (first-pass corrected) | 2065 | 380 | $0.001332 |
| **Total** | 4154 | 926 | $0.003138 |

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
| First pass | 661 | 156 | $0.000390 |
| Naturalness (original) | 1582 | 397 | $0.001502 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1583 | — | — |
| Naturalness (first-pass corrected) | 1945 | 401 | $0.001543 |
| **Total** | 3528 | 954 | $0.003435 |

## naturalness-puedo-tener-cerveza

- Input text: `¿Puedo tener una cerveza?`
- Note: English-influenced "¿puedo tener?" ("can I have?").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `¿Me pones una cerveza?`
- First-pass corrected text: `¿Puedo tener una cerveza?`
- Naturalness on original text: ¿Puedo tener una cerveza? -> ¿Me pones una cerveza? / ¿Me traes una cerveza? / ¿Me das una cerveza?
- Naturalness on first-pass corrected text: ¿Puedo tener una cerveza? -> ¿Me pones / me pones una cerveza?; ¿Me das una cerveza?; ¿Me pones una cerveza, por favor?
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `¿Me pones una cerveza? / ¿Me traes una cerveza? / ¿Me das una cerveza?`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 683 | 156 | $0.000390 |
| Naturalness (original) | 2118 | 429 | $0.001822 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2119 | — | — |
| Naturalness (first-pass corrected) | 2451 | 463 | $0.002162 |
| **Total** | 4570 | 1048 | $0.004375 |

## naturalness-llamar-para-atras

- Input text: `Te llamo para atrás.`
- Note: English-influenced "llamar para atrás" ("call back").
- Language point: Phrase-Level Naturalness
- Operation type: replacement
- Expected owner: naturalness
- Expected corrected text: `Te devuelvo la llamada.`
- First-pass corrected text: `Te llamo para atrás.`
- Naturalness on original text: Te llamo para atrás. -> Te devuelvo la llamada / Te llamo luego / Te vuelvo a llamar.
- Naturalness on first-pass corrected text: Te llamo para atrás. -> Te devuelvo la llamada.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Te devuelvo la llamada / Te llamo luego / Te vuelvo a llamar.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 577 | 154 | $0.000380 |
| Naturalness (original) | 2070 | 413 | $0.001671 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2071 | — | — |
| Naturalness (first-pass corrected) | 2298 | 408 | $0.001621 |
| **Total** | 4369 | 975 | $0.003672 |

## regional-voy-para-casa

- Input text: `Voy para casa ahora mismo.`
- Note: Valid regional Spanish ("para casa"); must not be flagged.
- Language point: Valid Regional / Should Not Flag
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Voy para casa ahora mismo.`
- First-pass corrected text: `Voy a casa ahora mismo.`
- Naturalness on original text: (none)
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Voy a casa ahora mismo.`
- Final correction count: 0
- Score: overcorrection

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 679 | 154 | $0.000380 |
| Naturalness (original) | 1135 | 310 | $0.000641 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1136 | — | — |
| Naturalness (first-pass corrected) | 1077 | 310 | $0.000641 |
| **Total** | 2213 | 774 | $0.001662 |

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
| First pass | 576 | 152 | $0.000370 |
| Naturalness (original) | 975 | 309 | $0.000640 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 975 | — | — |
| Naturalness (first-pass corrected) | 1074 | 309 | $0.000640 |
| **Total** | 2049 | 770 | $0.001650 |

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
| First pass | 640 | 158 | $0.000400 |
| Naturalness (original) | 1152 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1152 | — | — |
| Naturalness (first-pass corrected) | 1024 | 312 | $0.000644 |
| **Total** | 2176 | 782 | $0.001687 |

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
| First pass | 535 | 158 | $0.000400 |
| Naturalness (original) | 891 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 892 | — | — |
| Naturalness (first-pass corrected) | 1149 | 312 | $0.000644 |
| **Total** | 2041 | 782 | $0.001687 |

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
| First pass | 645 | 158 | $0.000400 |
| Naturalness (original) | 851 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 852 | — | — |
| Naturalness (first-pass corrected) | 1230 | 312 | $0.000644 |
| **Total** | 2082 | 782 | $0.001687 |

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
| First pass | 689 | 156 | $0.000390 |
| Naturalness (original) | 1189 | 311 | $0.000643 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1189 | — | — |
| Naturalness (first-pass corrected) | 1141 | 311 | $0.000643 |
| **Total** | 2330 | 778 | $0.001675 |

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
| First pass | 661 | 158 | $0.000400 |
| Naturalness (original) | 1513 | 312 | $0.000644 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1513 | — | — |
| Naturalness (first-pass corrected) | 1097 | 312 | $0.000644 |
| **Total** | 2610 | 782 | $0.001687 |

## correct-tomar-foto

- Input text: `Necesito tomar una foto del documento.`
- Note: Already correct; must not be tinkered with.
- Language point: Already Correct / Do Not Tinker
- Operation type: no_change
- Expected owner: no_change
- Expected corrected text: `Necesito tomar una foto del documento.`
- First-pass corrected text: `Necesito tomar una foto del documento.`
- Naturalness on original text: tomar una foto -> sacar una foto / hacer una foto
- Naturalness on first-pass corrected text: tomar una foto -> sacar una foto / hacer una foto
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Necesito sacar una foto / hacer una foto del documento.`
- Final correction count: 1
- Score: overcorrection

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 586 | 158 | $0.000400 |
| Naturalness (original) | 2217 | 389 | $0.001414 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2217 | — | — |
| Naturalness (first-pass corrected) | 1534 | 375 | $0.001274 |
| **Total** | 3751 | 922 | $0.003087 |

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
| First pass | 716 | 162 | $0.000420 |
| Naturalness (original) | 1294 | 314 | $0.000646 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1295 | — | — |
| Naturalness (first-pass corrected) | 1022 | 314 | $0.000646 |
| **Total** | 2317 | 790 | $0.001713 |

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
| First pass | 780 | 168 | $0.000450 |
| Naturalness (original) | 966 | 317 | $0.000650 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 967 | — | — |
| Naturalness (first-pass corrected) | 1661 | 317 | $0.000650 |
| **Total** | 2628 | 802 | $0.001750 |

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
| First pass | 676 | 181 | $0.000518 |
| Naturalness (original) | 2287 | 451 | $0.001937 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2287 | — | — |
| Naturalness (first-pass corrected) | 2533 | 416 | $0.001579 |
| **Total** | 4820 | 1048 | $0.004034 |

## mixed-article-and-accent

- Input text: `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.`
- Note: Combines a missing-article insertion ("un libro") with missing accents ("compré", "café", "cafetería", "pequeña").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- First-pass corrected text: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- Naturalness on original text: comprar libro -> comprar un libro<br>compre cafe -> compré café<br>en una cafeteria pequena -> en una cafetería pequeña
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.`
- Final correction count: 0
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 733 | 177 | $0.000504 |
| Naturalness (original) | 3633 | 551 | $0.002964 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 3633 | — | — |
| Naturalness (first-pass corrected) | 1200 | 323 | $0.000657 |
| **Total** | 4833 | 1051 | $0.004125 |

## mixed-personal-a-and-subjunctive

- Input text: `Vi mi profesor en la estación, y es importante que estudias.`
- Note: Combines a missing personal-"a" insertion with a subjunctive-mood replacement ("estudias" -> "estudies").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Vi a mi profesor en la estación, y es importante que estudies.`
- First-pass corrected text: `Vi a mi profesor en la estación, y es importante que estudies.`
- Naturalness on original text: Vi mi profesor en la estación -> Vi a mi profesor en la estación<br>es importante que estudias -> es importante que estudies
- Naturalness on first-pass corrected text: Vi a mi profesor en la estación, y es importante que estudies. -> Vi a mi profesor en la estación. Es importante que estudies.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Vi a mi profesor en la estación. Es importante que estudies.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 678 | 171 | $0.000468 |
| Naturalness (original) | 2418 | 450 | $0.001971 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2418 | — | — |
| Naturalness (first-pass corrected) | 2150 | 417 | $0.001632 |
| **Total** | 4568 | 1038 | $0.004072 |

## mixed-gender-agreement-and-redundant-pronoun

- Input text: `Las ventanas estaban abierto, y a mí me gusta el café a mí.`
- Note: Combines a gender-agreement replacement ("abierto" -> "abiertas") with a redundant-pronoun deletion (trailing "a mí").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Las ventanas estaban abiertas, y a mí me gusta el café.`
- First-pass corrected text: `Las ventanas estaban abiertas, y a mí me gusta el café a mí.`
- Naturalness on original text: estaban abierto -> estaban abiertas<br>y a mí me gusta el café a mí -> y a mí me gusta el café
- Naturalness on first-pass corrected text: a mí me gusta el café a mí -> a mí me gusta el café
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Las ventanas estaban abiertas, y a mí me gusta el café.`
- Final correction count: 1
- Score: correct_fix

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 634 | 172 | $0.000470 |
| Naturalness (original) | 2250 | 466 | $0.002122 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 2251 | — | — |
| Naturalness (first-pass corrected) | 2151 | 405 | $0.001512 |
| **Total** | 4402 | 1043 | $0.004105 |

## mixed-verb-agreement-and-missing-que

- Input text: `Ellos estudia todas las noches, y creo está bien terminar hoy.`
- Note: Combines a verb-agreement replacement ("estudia" -> "estudian") with a missing-connector insertion ("creo que").
- Language point: Mixed Operations
- Operation type: mixed
- Expected owner: first_pass
- Expected corrected text: `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- First-pass corrected text: `Ellos estudian todas las noches, y creo que está bien terminar hoy.`
- Naturalness on original text: creo está bien -> creo que está bien
- Naturalness on first-pass corrected text: Ellos estudian todas las noches, y creo que está bien terminar hoy. -> Ellos estudian todas las noches y creo que está bien que hoy terminen / y creo que hoy pueden terminar / y creo que hoy está bien que terminen.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Ellos estudian todas las noches y creo que está bien que hoy terminen / y creo que hoy pueden terminar / y creo que hoy está bien que terminen.`
- Final correction count: 1
- Score: ambiguous

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 684 | 173 | $0.000478 |
| Naturalness (original) | 1971 | 384 | $0.001302 |
| Parallel phase wall-clock (first pass + naturalness, concurrent — issue #98) | 1972 | — | — |
| Naturalness (first-pass corrected) | 2751 | 467 | $0.002124 |
| **Total** | 4723 | 1024 | $0.003904 |

---

## Overall summary

| Fixtures | Errors | Conflicts | Fallbacks used | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 85 | 0 | 51 | 51 | 286908 | 73994 | $0.218540 |

### Score summary

| Score | Count |
| --- | --- |
| correct_fix | 56 |
| partial_fix | 3 |
| overcorrection | 3 |
| acceptable_no_change | 11 |
| ambiguous | 12 |

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
| Required Prepositions | 5 | 4 | 0 | 0 | 0 | 0 | 1 | 0 |
| Articles / Determiners | 5 | 3 | 1 | 0 | 0 | 0 | 1 | 0 |
| Subjunctive / Mood | 5 | 4 | 0 | 0 | 0 | 0 | 1 | 0 |
| Required Additions / Omissions | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Unnecessary Extras / Deletions | 5 | 3 | 0 | 0 | 0 | 0 | 2 | 0 |
| Ser / Estar / Haber | 5 | 3 | 0 | 0 | 0 | 2 | 0 | 0 |
| Impersonal Haber / Se | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| False Friends / Word Choice | 5 | 3 | 0 | 0 | 0 | 1 | 1 | 0 |
| Phrase-Level Naturalness | 5 | 1 | 1 | 0 | 0 | 0 | 3 | 0 |
| Valid Regional / Should Not Flag | 5 | 0 | 0 | 0 | 1 | 4 | 0 | 0 |
| Already Correct / Do Not Tinker | 5 | 0 | 0 | 0 | 1 | 4 | 0 | 0 |
| Mixed Operations | 5 | 2 | 1 | 0 | 0 | 0 | 2 | 0 |

### Operation type summary

| Operation type | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| replacement | 46 | 39 | 1 | 0 | 0 | 0 | 6 | 0 |
| no_change | 14 | 0 | 0 | 0 | 3 | 11 | 0 | 0 |
| insertion | 15 | 12 | 1 | 0 | 0 | 0 | 2 | 0 |
| deletion | 5 | 3 | 0 | 0 | 0 | 0 | 2 | 0 |
| mixed | 5 | 2 | 1 | 0 | 0 | 0 | 2 | 0 |

### Expected owner summary

| Expected owner | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| first_pass | 54 | 44 | 2 | 0 | 0 | 0 | 8 | 0 |
| naturalness | 6 | 2 | 1 | 0 | 0 | 0 | 3 | 0 |
| either | 11 | 10 | 0 | 0 | 0 | 0 | 1 | 0 |
| no_change | 14 | 0 | 0 | 0 | 3 | 11 | 0 | 0 |

### Fallback / conflict summary

| Metric | Count | Rate |
| --- | --- | --- |
| Conflicts | 51 | 60.0% |
| Fallbacks used | 51 | 60.0% |

### Latency / cost outliers

- Average latency: 3375 ms; average cost: $0.002571 (over 85 non-error fixture(s)).
- Outlier threshold: 1.5x the average latency or cost.

| Fixture | Latency (ms) | Est. cost (USD) |
| --- | --- | --- |
| clean-grammar-only | 5488 | $0.003073 |
| ambiguous-naturalness-span | 5278 | $0.003583 |
| subj-enviara | 6006 | $0.003758 |
| false-friend-atendio-universidad | 5092 | $0.003767 |
| naturalness-puedo-tener-cerveza | 4570 | $0.004375 |
| mixed-preposition-and-redundant-pronoun | 4820 | $0.004034 |
| mixed-article-and-accent | 4833 | $0.004125 |
| mixed-personal-a-and-subjunctive | 4568 | $0.004072 |
| mixed-gender-agreement-and-redundant-pronoun | 4402 | $0.004105 |
| mixed-verb-agreement-and-missing-que | 4723 | $0.003904 |
