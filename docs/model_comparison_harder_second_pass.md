# Spanish Correction Model Comparison Harness

## Run configuration

- Prompt label: `simple-spanish-grammar-spelling-punctuation-only`
- Prompt version: `v1`
- Models: `gpt-5.5`, `gpt-5.4`, `gpt-5.3-chat-latest`, `gpt-5.2`, `gpt-5.1`, `gpt-5`, `gpt-5-mini`, `gpt-4.1`, `gpt-4.1-mini`, `gpt-4o`, `gpt-4o-mini`
- Fixture case ids: `harder-accent-marks-diacritics`, `harder-gender-number-agreement`, `harder-preposition-government`, `harder-verb-morphology-agreement`, `harder-articles-determiners`, `harder-subjunctive-mood`, `harder-object-pronouns-clitics`, `harder-ser-estar-haber`, `harder-personal-a`, `harder-relative-clause-preposition`, `harder-impersonal-haber-se`, `harder-sentence-boundaries-punctuation`, `harder-mixed-b1-b2-paragraph`, `harder-mixed-b2-c1-paragraph`, `harder-near-limit-mixed-text`
- Generated: 2026-07-28T16:15:12.945607Z
- Git branch: `local/add-harder-second-pass-fixtures`
- Git commit: `7f522c1dc27c22e3c35bd67c8da8ea538170182a`
- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`

## Pricing

Verified estimated costs use:
- `gpt-5.5`: input=5.0 USD, output=30.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.5, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown; long-context and data-residency uplifts not applied, checked=2026-07-28
- `gpt-5.4`: input=2.5 USD, output=15.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.4, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5.3-chat-latest`: input=1.75 USD, output=14.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.3-chat-latest, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5.2`: input=1.75 USD, output=14.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.2, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5.1`: input=1.25 USD, output=10.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5`: input=1.25 USD, output=10.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5-mini`: input=0.25 USD, output=2.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5-mini, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-4.1`: input=2.0 USD, output=8.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-4.1-mini`: input=0.4 USD, output=1.6 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1-mini, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-4o`: input=2.5 USD, output=10.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4o, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-4o-mini`: input=0.15 USD, output=0.6 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4o-mini, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## harder-accent-marks-diacritics

- Input text: `El medico llego despues de la reunion.`
- Note: Harder scored B1 sentence: missing written accents only, useful for checking diacritic recovery without wording changes.
- Expected corrected_text: `El médico llegó después de la reunión.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2877 | 140/53/193 | verified 0.002290 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-5.4 | true | expected_correction | 4027 | 140/24/164 | verified 0.000710 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-5.3-chat-latest | true | unexpected_correction | 7441 | 140/30/170 | verified 0.000665 | El médico llegó después de la reunion. | {"corrected_text":"El médico llegó después de la reunion."} |
| gpt-5.2 | true | expected_correction | 1294 | 140/24/164 | verified 0.000581 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-5.1 | true | expected_correction | 6244 | 140/30/170 | verified 0.000475 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-5 | ERROR | error | 30005 | | | | TimeoutException after 0:00:30.000000: Future not completed |
| gpt-5-mini | true | expected_correction | 5319 | 140/222/362 | verified 0.000479 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-4.1 | true | expected_correction | 781 | 145/14/159 | verified 0.000402 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-4.1-mini | true | expected_correction | 782 | 145/14/159 | verified 0.000080 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-4o | true | expected_correction | 663 | 145/14/159 | verified 0.000502 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |
| gpt-4o-mini | true | expected_correction | 1517 | 145/14/159 | verified 0.000030 | El médico llegó después de la reunión. | {"corrected_text":"El médico llegó después de la reunión."} |

## harder-gender-number-agreement

- Input text: `Las ventanas estaban abierto, pero una puerta estaba cerrado.`
- Note: Harder scored B1 sentence: adjective/participle agreement with nearby feminine singular and plural nouns.
- Expected corrected_text: `Las ventanas estaban abiertas, pero una puerta estaba cerrada.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 3364 | 142/51/193 | verified 0.002240 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-5.4 | true | expected_correction | 881 | 142/28/170 | verified 0.000775 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-5.3-chat-latest | true | expected_correction | 3624 | 142/34/176 | verified 0.000724 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-5.2 | true | expected_correction | 1401 | 142/28/170 | verified 0.000641 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-5.1 | true | expected_correction | 2012 | 142/34/176 | verified 0.000518 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-5 | true | expected_correction | 6824 | 142/354/496 | verified 0.003717 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-5-mini | true | expected_correction | 21365 | 142/162/304 | verified 0.000360 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-4.1 | true | expected_correction | 785 | 147/18/165 | verified 0.000438 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-4.1-mini | true | expected_correction | 4378 | 147/18/165 | verified 0.000088 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-4o | true | expected_correction | 826 | 147/18/165 | verified 0.000548 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |
| gpt-4o-mini | true | expected_correction | 1870 | 147/18/165 | verified 0.000033 | Las ventanas estaban abiertas, pero una puerta estaba cerrada. | {"corrected_text":"Las ventanas estaban abiertas, pero una puerta estaba cerrada."} |

## harder-preposition-government

- Input text: `Insisto que revises el contrato antes de firmarlo.`
- Note: Harder scored B2 sentence: required preposition after "insistir" without adding any style or word-choice target.
- Expected corrected_text: `Insisto en que revises el contrato antes de firmarlo.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 5425 | 143/68/211 | verified 0.002755 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-5.4 | true | expected_correction | 1442 | 143/29/172 | verified 0.000793 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-5.3-chat-latest | true | expected_correction | 2226 | 143/35/178 | verified 0.000740 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-5.2 | true | expected_correction | 912 | 143/29/172 | verified 0.000656 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-5.1 | ERROR | error | 117756 | | | | TimeoutException after 0:00:30.000000: Future not completed |
| gpt-5 | true | expected_correction | 3683 | 143/163/306 | verified 0.001809 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-5-mini | true | expected_correction | 4672 | 143/227/370 | verified 0.000490 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-4.1 | true | expected_correction | 1471 | 148/19/167 | verified 0.000448 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-4.1-mini | true | expected_correction | 1324 | 148/19/167 | verified 0.000090 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-4o | true | expected_correction | 956 | 148/19/167 | verified 0.000560 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |
| gpt-4o-mini | true | expected_correction | 1867 | 148/19/167 | verified 0.000034 | Insisto en que revises el contrato antes de firmarlo. | {"corrected_text":"Insisto en que revises el contrato antes de firmarlo."} |

## harder-verb-morphology-agreement

- Input text: `Mis compañeros y yo fue a la biblioteca después de clase.`
- Note: Harder scored B1 sentence: first-person plural subject requires matching preterite verb morphology.
- Expected corrected_text: `Mis compañeros y yo fuimos a la biblioteca después de clase.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 1770 | 143/50/193 | verified 0.002215 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-5.4 | true | expected_correction | 1413 | 143/29/172 | verified 0.000793 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-5.3-chat-latest | true | expected_correction | 2306 | 143/35/178 | verified 0.000740 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-5.2 | true | expected_correction | 1199 | 143/29/172 | verified 0.000656 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-5.1 | true | expected_correction | 2722 | 143/35/178 | verified 0.000529 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-5 | true | expected_correction | 11433 | 143/227/370 | verified 0.002449 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-5-mini | true | expected_correction | 4679 | 143/163/306 | verified 0.000362 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-4.1 | true | expected_correction | 775 | 148/19/167 | verified 0.000448 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-4.1-mini | true | expected_correction | 1809 | 148/19/167 | verified 0.000090 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-4o | true | expected_correction | 3676 | 148/19/167 | verified 0.000560 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |
| gpt-4o-mini | true | expected_correction | 1267 | 148/19/167 | verified 0.000034 | Mis compañeros y yo fuimos a la biblioteca después de clase. | {"corrected_text":"Mis compañeros y yo fuimos a la biblioteca después de clase."} |

## harder-articles-determiners

- Input text: `Abrió puerta principal porque hacía mucho calor.`
- Note: Harder scored B1 sentence: missing definite article in an ordinary specific noun phrase.
- Expected corrected_text: `Abrió la puerta principal porque hacía mucho calor.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 4061 | 140/96/236 | verified 0.003580 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-5.4 | true | expected_correction | 1397 | 140/26/166 | verified 0.000740 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-5.3-chat-latest | true | expected_correction | 3952 | 140/32/172 | verified 0.000693 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-5.2 | true | expected_correction | 1681 | 140/26/166 | verified 0.000609 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-5.1 | true | expected_correction | 3470 | 140/32/172 | verified 0.000495 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-5 | true | expected_correction | 5110 | 140/224/364 | verified 0.002415 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-5-mini | true | expected_correction | 7715 | 140/160/300 | verified 0.000355 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-4.1 | true | expected_correction | 996 | 145/16/161 | verified 0.000418 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-4.1-mini | true | expected_correction | 985 | 145/16/161 | verified 0.000084 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-4o | true | expected_correction | 1292 | 145/16/161 | verified 0.000522 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |
| gpt-4o-mini | true | expected_correction | 1399 | 145/16/161 | verified 0.000031 | Abrió la puerta principal porque hacía mucho calor. | {"corrected_text":"Abrió la puerta principal porque hacía mucho calor."} |

## harder-subjunctive-mood

- Input text: `Es importante que estudias antes del examen final.`
- Note: Harder scored B1-B2 sentence: impersonal expression requires present subjunctive, with no lexical improvement target.
- Expected corrected_text: `Es importante que estudies antes del examen final.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2931 | 141/53/194 | verified 0.002295 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-5.4 | true | expected_correction | 10101 | 141/26/167 | verified 0.000743 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-5.3-chat-latest | true | expected_correction | 2012 | 141/32/173 | verified 0.000695 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-5.2 | true | expected_correction | 3035 | 141/26/167 | verified 0.000611 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-5.1 | true | expected_correction | 1499 | 141/32/173 | verified 0.000496 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-5 | true | expected_correction | 3249 | 141/160/301 | verified 0.001776 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-5-mini | true | expected_correction | 3538 | 141/160/301 | verified 0.000355 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-4.1 | true | expected_correction | 1088 | 146/16/162 | verified 0.000420 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-4.1-mini | true | expected_correction | 887 | 146/16/162 | verified 0.000084 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-4o | true | expected_correction | 925 | 146/16/162 | verified 0.000525 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |
| gpt-4o-mini | true | expected_correction | 1561 | 146/16/162 | verified 0.000031 | Es importante que estudies antes del examen final. | {"corrected_text":"Es importante que estudies antes del examen final."} |

## harder-object-pronouns-clitics

- Input text: `A los niños expliqué la regla con paciencia.`
- Note: Harder scored B2 sentence: preposed indirect object requires the matching clitic pronoun.
- Expected corrected_text: `A los niños les expliqué la regla con paciencia.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 9129 | 140/128/268 | verified 0.004540 | A los niños les expliqué la regla con paciencia. | {"corrected_text":"A los niños les expliqué la regla con paciencia."} |
| gpt-5.4 | true | missed_correction | 1393 | 140/25/165 | verified 0.000725 | A los niños expliqué la regla con paciencia. | {"corrected_text":"A los niños expliqué la regla con paciencia."} |
| gpt-5.3-chat-latest | true | missed_correction | 3088 | 140/95/235 | verified 0.001575 | A los niños expliqué la regla con paciencia. | {"corrected_text":"A los niños expliqué la regla con paciencia."} |
| gpt-5.2 | true | missed_correction | 1806 | 140/25/165 | verified 0.000595 | A los niños expliqué la regla con paciencia. | {"corrected_text":"A los niños expliqué la regla con paciencia."} |
| gpt-5.1 | true | expected_correction | 1487 | 140/32/172 | verified 0.000495 | A los niños les expliqué la regla con paciencia. | {"corrected_text":"A los niños les expliqué la regla con paciencia."} |
| gpt-5 | true | expected_correction | 7718 | 140/416/556 | verified 0.004335 | A los niños les expliqué la regla con paciencia. | {"corrected_text":"A los niños les expliqué la regla con paciencia."} |
| gpt-5-mini | true | missed_correction | 13725 | 140/159/299 | verified 0.000353 | A los niños expliqué la regla con paciencia. | {"corrected_text":"A los niños expliqué la regla con paciencia."} |
| gpt-4.1 | true | expected_correction | 4368 | 145/16/161 | verified 0.000418 | A los niños les expliqué la regla con paciencia. | {"corrected_text":"A los niños les expliqué la regla con paciencia."} |
| gpt-4.1-mini | true | expected_correction | 1709 | 145/16/161 | verified 0.000084 | A los niños les expliqué la regla con paciencia. | {"corrected_text":"A los niños les expliqué la regla con paciencia."} |
| gpt-4o | true | expected_correction | 1596 | 145/16/161 | verified 0.000522 | A los niños les expliqué la regla con paciencia. | {"corrected_text":"A los niños les expliqué la regla con paciencia."} |
| gpt-4o-mini | true | unexpected_correction | 1048 | 145/16/161 | verified 0.000031 | A los niños, expliqué la regla con paciencia. | {"corrected_text":"A los niños, expliqué la regla con paciencia."} |

## harder-ser-estar-haber

- Input text: `En la sala son veinte personas esperando la reunión.`
- Note: Harder scored B1 sentence: existential "haber" is required for a there-is/there-are meaning.
- Expected corrected_text: `En la sala hay veinte personas esperando la reunión.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 4204 | 141/144/285 | verified 0.005025 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-5.4 | true | missed_correction | 2215 | 141/26/167 | verified 0.000743 | En la sala son veinte personas esperando la reunión. | {"corrected_text":"En la sala son veinte personas esperando la reunión."} |
| gpt-5.3-chat-latest | true | expected_correction | 2729 | 141/32/173 | verified 0.000695 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-5.2 | true | expected_correction | 987 | 141/26/167 | verified 0.000611 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-5.1 | true | expected_correction | 886 | 141/32/173 | verified 0.000496 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-5 | true | expected_correction | 11122 | 141/736/877 | verified 0.007536 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-5-mini | true | expected_correction | 6721 | 141/352/493 | verified 0.000739 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-4.1 | true | expected_correction | 1087 | 146/16/162 | verified 0.000420 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-4.1-mini | true | expected_correction | 1094 | 146/16/162 | verified 0.000084 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-4o | true | expected_correction | 4158 | 146/16/162 | verified 0.000525 | En la sala hay veinte personas esperando la reunión. | {"corrected_text":"En la sala hay veinte personas esperando la reunión."} |
| gpt-4o-mini | true | missed_correction | 990 | 146/16/162 | verified 0.000031 | En la sala son veinte personas esperando la reunión. | {"corrected_text":"En la sala son veinte personas esperando la reunión."} |

## harder-personal-a

- Input text: `Vi mi profesor en la estación esta mañana.`
- Note: Harder scored B1 sentence: direct object referring to a specific person requires personal "a".
- Expected corrected_text: `Vi a mi profesor en la estación esta mañana.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2319 | 140/54/194 | verified 0.002320 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-5.4 | true | expected_correction | 2421 | 140/26/166 | verified 0.000740 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-5.3-chat-latest | true | expected_correction | 2300 | 140/32/172 | verified 0.000693 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-5.2 | true | expected_correction | 3054 | 140/26/166 | verified 0.000609 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-5.1 | true | expected_correction | 7551 | 140/32/172 | verified 0.000495 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-5 | true | expected_correction | 2822 | 140/160/300 | verified 0.001775 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-5-mini | ERROR | error | 30002 | | | | TimeoutException after 0:00:30.000000: Future not completed |
| gpt-4.1 | true | expected_correction | 808 | 145/16/161 | verified 0.000418 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-4.1-mini | true | expected_correction | 824 | 145/16/161 | verified 0.000084 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-4o | true | expected_correction | 782 | 145/16/161 | verified 0.000522 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |
| gpt-4o-mini | true | expected_correction | 888 | 145/16/161 | verified 0.000031 | Vi a mi profesor en la estación esta mañana. | {"corrected_text":"Vi a mi profesor en la estación esta mañana."} |

## harder-relative-clause-preposition

- Input text: `La empresa que trabajo está cerca de mi casa.`
- Note: Harder scored B2 sentence: relative clause requires the preposition governed by "trabajar en".
- Expected corrected_text: `La empresa en la que trabajo está cerca de mi casa.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2420 | 141/84/225 | verified 0.003225 | La empresa en la que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en la que trabajo está cerca de mi casa."} |
| gpt-5.4 | true | unexpected_correction | 3853 | 141/27/168 | verified 0.000758 | La empresa en que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en que trabajo está cerca de mi casa."} |
| gpt-5.3-chat-latest | true | expected_correction | 3141 | 141/34/175 | verified 0.000723 | La empresa en la que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en la que trabajo está cerca de mi casa."} |
| gpt-5.2 | true | expected_correction | 1191 | 141/28/169 | verified 0.000639 | La empresa en la que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en la que trabajo está cerca de mi casa."} |
| gpt-5.1 | true | unexpected_correction | 1499 | 141/33/174 | verified 0.000506 | La empresa en que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en que trabajo está cerca de mi casa."} |
| gpt-5 | true | expected_correction | 17062 | 141/610/751 | verified 0.006276 | La empresa en la que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en la que trabajo está cerca de mi casa."} |
| gpt-5-mini | true | expected_correction | 15632 | 141/290/431 | verified 0.000615 | La empresa en la que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en la que trabajo está cerca de mi casa."} |
| gpt-4.1 | true | unexpected_correction | 783 | 146/17/163 | verified 0.000428 | La empresa en que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en que trabajo está cerca de mi casa."} |
| gpt-4.1-mini | true | expected_correction | 884 | 146/18/164 | verified 0.000087 | La empresa en la que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en la que trabajo está cerca de mi casa."} |
| gpt-4o | true | unexpected_correction | 2525 | 146/17/163 | verified 0.000535 | La empresa en que trabajo está cerca de mi casa. | {"corrected_text":"La empresa en que trabajo está cerca de mi casa."} |
| gpt-4o-mini | true | unexpected_correction | 987 | 146/16/162 | verified 0.000031 | La empresa donde trabajo está cerca de mi casa. | {"corrected_text":"La empresa donde trabajo está cerca de mi casa."} |

## harder-impersonal-haber-se

- Input text: `Habían muchas personas en la entrada del museo.`
- Note: Harder scored B2 sentence: impersonal "haber" remains singular before a plural noun phrase.
- Expected corrected_text: `Había muchas personas en la entrada del museo.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2221 | 141/58/199 | verified 0.002445 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-5.4 | true | expected_correction | 3524 | 141/26/167 | verified 0.000743 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-5.3-chat-latest | true | expected_correction | 2132 | 141/32/173 | verified 0.000695 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-5.2 | true | expected_correction | 1705 | 141/26/167 | verified 0.000611 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-5.1 | true | expected_correction | 1155 | 141/32/173 | verified 0.000496 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-5 | true | expected_correction | 6061 | 141/224/365 | verified 0.002416 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-5-mini | true | expected_correction | 4040 | 141/160/301 | verified 0.000355 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-4.1 | true | expected_correction | 781 | 146/16/162 | verified 0.000420 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-4.1-mini | true | expected_correction | 2110 | 146/16/162 | verified 0.000084 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-4o | true | expected_correction | 1604 | 146/16/162 | verified 0.000525 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |
| gpt-4o-mini | true | expected_correction | 989 | 146/16/162 | verified 0.000031 | Había muchas personas en la entrada del museo. | {"corrected_text":"Había muchas personas en la entrada del museo."} |

## harder-sentence-boundaries-punctuation

- Input text: `Terminé el informe llegué a casa muy tarde.`
- Note: Harder scored B1-B2 sentence: run-on sentence needs a boundary without changing the words.
- Expected corrected_text: `Terminé el informe. Llegué a casa muy tarde.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | unexpected_correction | 2404 | 142/113/255 | verified 0.004100 | Terminé el informe; llegué a casa muy tarde. | {"corrected_text":"Terminé el informe; llegué a casa muy tarde."} |
| gpt-5.4 | true | unexpected_correction | 1210 | 142/28/170 | verified 0.000775 | Terminé el informe, llegué a casa muy tarde. | {"corrected_text":"Terminé el informe, llegué a casa muy tarde."} |
| gpt-5.3-chat-latest | true | unexpected_correction | 3035 | 142/98/240 | verified 0.001620 | Terminé el informe y llegué a casa muy tarde. | {"corrected_text":"Terminé el informe y llegué a casa muy tarde."} |
| gpt-5.2 | true | unexpected_correction | 934 | 142/28/170 | verified 0.000641 | Terminé el informe y llegué a casa muy tarde. | {"corrected_text":"Terminé el informe y llegué a casa muy tarde."} |
| gpt-5.1 | true | unexpected_correction | 1657 | 142/34/176 | verified 0.000518 | Terminé el informe, llegué a casa muy tarde. | {"corrected_text":"Terminé el informe, llegué a casa muy tarde."} |
| gpt-5 | true | expected_correction | 9176 | 142/482/624 | verified 0.004997 | Terminé el informe. Llegué a casa muy tarde. | {"corrected_text":"Terminé el informe. Llegué a casa muy tarde."} |
| gpt-5-mini | true | expected_correction | 4471 | 142/226/368 | verified 0.000487 | Terminé el informe. Llegué a casa muy tarde. | {"corrected_text":"Terminé el informe. Llegué a casa muy tarde."} |
| gpt-4.1 | true | unexpected_correction | 1091 | 147/18/165 | verified 0.000438 | Terminé el informe, llegué a casa muy tarde. | {"corrected_text":"Terminé el informe, llegué a casa muy tarde."} |
| gpt-4.1-mini | true | unexpected_correction | 833 | 147/18/165 | verified 0.000088 | Terminé el informe y llegué a casa muy tarde. | {"corrected_text":"Terminé el informe y llegué a casa muy tarde."} |
| gpt-4o | true | unexpected_correction | 23568 | 147/18/165 | verified 0.000548 | Terminé el informe y llegué a casa muy tarde. | {"corrected_text":"Terminé el informe y llegué a casa muy tarde."} |
| gpt-4o-mini | true | unexpected_correction | 987 | 147/18/165 | verified 0.000033 | Terminé el informe, llegué a casa muy tarde. | {"corrected_text":"Terminé el informe, llegué a casa muy tarde."} |

## harder-mixed-b1-b2-paragraph

- Input text: `El sabado visite a mi prima en Valencia. Ella me dijo que los billetes estaban caro, pero al final los compramos antes de salir`
- Note: Harder scored mixed B1-B2 paragraph: accents, plural agreement, and sentence-final punctuation in ordinary narrative language.
- Expected corrected_text: `El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2933 | 160/105/265 | verified 0.003950 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-5.4 | true | expected_correction | 2829 | 160/46/206 | verified 0.001090 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-5.3-chat-latest | true | expected_correction | 3242 | 160/116/276 | verified 0.001904 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-5.2 | true | expected_correction | 1193 | 160/46/206 | verified 0.000924 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-5.1 | true | expected_correction | 4284 | 160/52/212 | verified 0.000720 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-5 | true | expected_correction | 9145 | 160/436/596 | verified 0.004560 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-5-mini | true | expected_correction | 7110 | 160/372/532 | verified 0.000784 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-4.1 | true | expected_correction | 1125 | 165/36/201 | verified 0.000618 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-4.1-mini | true | expected_correction | 998 | 165/36/201 | verified 0.000124 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-4o | true | expected_correction | 681 | 165/36/201 | verified 0.000772 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |
| gpt-4o-mini | true | expected_correction | 1522 | 165/36/201 | verified 0.000046 | El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir. | {"corrected_text":"El sábado visité a mi prima en Valencia. Ella me dijo que los billetes estaban caros, pero al final los compramos antes de salir."} |

## harder-mixed-b2-c1-paragraph

- Input text: `Aunque el informe que hablábamos era complejo, era importante que todos entendían las conclusiones antes de la votación.`
- Note: Harder scored mixed B2-C1 paragraph: required relative preposition and subjunctive mood in a formal but plain sentence.
- Expected corrected_text: `Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 3511 | 155/164/319 | verified 0.005695 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-5.4 | true | expected_correction | 1502 | 155/41/196 | verified 0.001002 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-5.3-chat-latest | true | expected_correction | 4367 | 155/175/330 | verified 0.002721 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-5.2 | true | expected_correction | 1395 | 155/41/196 | verified 0.000845 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-5.1 | true | expected_correction | 984 | 155/47/202 | verified 0.000664 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-5 | true | expected_correction | 6080 | 155/303/458 | verified 0.003224 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-5-mini | true | expected_correction | 5629 | 155/303/458 | verified 0.000645 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-4.1 | true | expected_correction | 781 | 160/31/191 | verified 0.000568 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-4.1-mini | true | expected_correction | 956 | 160/31/191 | verified 0.000114 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-4o | true | expected_correction | 817 | 160/31/191 | verified 0.000710 | Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe del que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |
| gpt-4o-mini | true | unexpected_correction | 1344 | 160/30/190 | verified 0.000042 | Aunque el informe que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación. | {"corrected_text":"Aunque el informe que hablábamos era complejo, era importante que todos entendieran las conclusiones antes de la votación."} |

## harder-near-limit-mixed-text

- Input text: `Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero habían varias cifras que no coincidían con los documentos originales. El resumen que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviaba su parte antes del viernes. También detectamos que las fechas principales estaban escrito sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité.`
- Note: Harder scored near-limit mixed text: objective impersonal haber, relative preposition, subjunctive mood, and agreement errors spread across a long ordinary workplace paragraph.
- Expected corrected_text: `Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 4827 | 228/253/481 | verified 0.008730 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-5.4 | true | unexpected_correction | 1907 | 228/116/344 | verified 0.002310 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso, acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso, acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-5.3-chat-latest | true | expected_correction | 4655 | 228/249/477 | verified 0.003885 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-5.2 | true | expected_correction | 4181 | 228/115/343 | verified 0.002009 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-5.1 | true | expected_correction | 1610 | 228/121/349 | verified 0.001495 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-5 | true | unexpected_correction | 22993 | 228/1593/1821 | verified 0.016215 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-5-mini | true | expected_correction | 13107 | 228/889/1117 | verified 0.001835 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-4.1 | true | expected_correction | 2592 | 233/105/338 | verified 0.001306 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-4.1-mini | true | expected_correction | 1885 | 233/105/338 | verified 0.000261 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-4o | true | expected_correction | 2444 | 233/105/338 | verified 0.001633 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen del que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |
| gpt-4o-mini | true | unexpected_correction | 2420 | 233/104/337 | verified 0.000097 | Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité. | {"corrected_text":"Durante los últimos meses, el equipo ha preparado un informe para la asociación local. Ayer revisamos los datos con la directora, pero había varias cifras que no coincidían con los documentos originales. El resumen que dependíamos para tomar decisiones no estaba completo, y era necesario que cada responsable enviara su parte antes del viernes. También detectamos que las fechas principales estaban escritas sin tilde en algunos archivos. Por eso acordamos corregirlas antes de entregar la versión final al comité."} |

---

## Overall summary

| Model | Cases | Valid JSON rate | Task success rate | Expected corrections | Missed fixes | Controls unchanged | Over-corrections | Unexpected outputs | Avg latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | 15 | 100.0% (15/15) | 93.3% (14/15) | 93.3% (14/15) | 0.0% (0/15) | 0.0% (0/0) | 0.0% (0/0) | 1 | 3626.4 | 3711 | verified 0.055405 |
| gpt-5.4 | 15 | 100.0% (15/15) | 66.7% (10/15) | 66.7% (10/15) | 13.3% (2/15) | 0.0% (0/0) | 0.0% (0/0) | 3 | 2674.3 | 2760 | verified 0.013437 |
| gpt-5.3-chat-latest | 15 | 100.0% (15/15) | 80.0% (12/15) | 80.0% (12/15) | 6.7% (1/15) | 0.0% (0/0) | 0.0% (0/0) | 2 | 3350.0 | 3298 | verified 0.018769 |
| gpt-5.2 | 15 | 100.0% (15/15) | 86.7% (13/15) | 86.7% (13/15) | 6.7% (1/15) | 0.0% (0/0) | 0.0% (0/0) | 1 | 1731.2 | 2760 | verified 0.011237 |
| gpt-5.1 | 15 | 93.3% (14/15) | 80.0% (12/15) | 80.0% (12/15) | 0.0% (0/15) | 0.0% (0/0) | 0.0% (0/0) | 2 | 2647.1 | 2672 | verified 0.008397 |
| gpt-5 | 15 | 93.3% (14/15) | 86.7% (13/15) | 86.7% (13/15) | 0.0% (0/15) | 0.0% (0/0) | 0.0% (0/0) | 1 | 8748.4 | 8185 | verified 0.063501 |
| gpt-5-mini | 15 | 93.3% (14/15) | 86.7% (13/15) | 86.7% (13/15) | 6.7% (1/15) | 0.0% (0/0) | 0.0% (0/0) | 0 | 8408.8 | 5942 | verified 0.008214 |
| gpt-4.1 | 15 | 100.0% (15/15) | 86.7% (13/15) | 86.7% (13/15) | 0.0% (0/15) | 0.0% (0/0) | 0.0% (0/0) | 2 | 1287.5 | 2685 | verified 0.007608 |
| gpt-4.1-mini | 15 | 100.0% (15/15) | 93.3% (14/15) | 93.3% (14/15) | 0.0% (0/15) | 0.0% (0/0) | 0.0% (0/0) | 1 | 1430.5 | 2686 | verified 0.001523 |
| gpt-4o | 15 | 100.0% (15/15) | 86.7% (13/15) | 86.7% (13/15) | 0.0% (0/15) | 0.0% (0/0) | 0.0% (0/0) | 2 | 3100.9 | 2685 | verified 0.009510 |
| gpt-4o-mini | 15 | 100.0% (15/15) | 60.0% (9/15) | 60.0% (9/15) | 6.7% (1/15) | 0.0% (0/0) | 0.0% (0/0) | 5 | 1377.1 | 2682 | verified 0.000569 |
