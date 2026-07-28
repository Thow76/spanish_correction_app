# Spanish Correction Model Comparison Harness

## Run configuration

- Prompt label: `simple-spanish-grammar-spelling-punctuation-only`
- Prompt version: `v1`
- Models: `gpt-5.5`, `gpt-5.3-chat-latest`, `gpt-5.2`, `gpt-5.1`, `gpt-5`, `gpt-5-mini`, `gpt-4.1`, `gpt-4.1-mini`, `gpt-4o`, `gpt-4o-mini`
- Fixture case ids: `short-phrase-missing-accent`, `sentence-grammar-agreement`
- Generated: 2026-07-28T13:06:26.147794Z
- Git branch: `correction_pipeline_refactor`
- Git commit: `e0b521453c88984f305a4a3942e390429cb8d29e`
- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`

## Pricing

Verified estimated costs use:
- `gpt-5.3-chat-latest`: input=1.75 USD, output=14.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.3-chat-latest, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-4.1`: input=2.0 USD, output=8.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

Unknown cost because pricing is unavailable or unverified for: `gpt-5.5`, `gpt-5.2`, `gpt-5.1`, `gpt-5`, `gpt-5-mini`, `gpt-4.1-mini`, `gpt-4o`, `gpt-4o-mini`.

## short-phrase-missing-accent

- Input text: `Voy al parque manana por la tarde.`
- Note: Short correction case: missing accent on "mañana". Exercises the shortest-input latency/cost floor with one objective spelling fix.
- Expected corrected_text: `Voy al parque mañana por la tarde.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2786 | 139/49/188 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-5.3-chat-latest | true | expected_correction | 2312 | 139/30/169 | verified 0.000663 | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-5.2 | true | expected_correction | 1327 | 139/24/163 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-5.1 | true | expected_correction | 992 | 139/30/169 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-5 | true | expected_correction | 3015 | 139/158/297 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-5-mini | true | expected_correction | 5921 | 139/158/297 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-4.1 | true | expected_correction | 855 | 144/14/158 | verified 0.000400 | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-4.1-mini | true | expected_correction | 1117 | 144/14/158 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-4o | true | expected_correction | 2218 | 144/14/158 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |
| gpt-4o-mini | true | expected_correction | 1089 | 144/14/158 | unknown (pricing unavailable/unverified) | Voy al parque mañana por la tarde. | {"corrected_text":"Voy al parque mañana por la tarde."} |

## sentence-grammar-agreement

- Input text: `Los niño come muchas manzana en el jardín.`
- Note: Sentence correction case: objective plural agreement errors in noun phrases and verb agreement.
- Expected corrected_text: `Los niños comen muchas manzanas en el jardín.`

| Model | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | corrected_text | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | true | expected_correction | 2112 | 141/57/198 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-5.3-chat-latest | true | expected_correction | 2214 | 141/33/174 | verified 0.000709 | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-5.2 | true | expected_correction | 1399 | 141/27/168 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-5.1 | true | expected_correction | 1138 | 141/33/174 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-5 | true | expected_correction | 4830 | 141/289/430 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-5-mini | true | expected_correction | 5519 | 141/353/494 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-4.1 | true | expected_correction | 855 | 146/17/163 | verified 0.000428 | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-4.1-mini | true | expected_correction | 890 | 146/17/163 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-4o | true | expected_correction | 780 | 146/17/163 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |
| gpt-4o-mini | true | expected_correction | 1077 | 146/17/163 | unknown (pricing unavailable/unverified) | Los niños comen muchas manzanas en el jardín. | {"corrected_text":"Los niños comen muchas manzanas en el jardín."} |

---

## Overall summary

| Model | Cases | Valid JSON rate | Task success rate | Expected corrections | Missed fixes | Controls unchanged | Over-corrections | Unexpected outputs | Avg latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.5 | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 2449.0 | 386 | unknown (pricing unavailable/unverified) |
| gpt-5.3-chat-latest | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 2263.0 | 343 | verified 0.001372 |
| gpt-5.2 | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 1363.0 | 331 | unknown (pricing unavailable/unverified) |
| gpt-5.1 | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 1065.0 | 343 | unknown (pricing unavailable/unverified) |
| gpt-5 | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 3922.5 | 727 | unknown (pricing unavailable/unverified) |
| gpt-5-mini | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 5720.0 | 791 | unknown (pricing unavailable/unverified) |
| gpt-4.1 | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 855.0 | 321 | verified 0.000828 |
| gpt-4.1-mini | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 1003.5 | 321 | unknown (pricing unavailable/unverified) |
| gpt-4o | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 1499.0 | 321 | unknown (pricing unavailable/unverified) |
| gpt-4o-mini | 2 | 100.0% (2/2) | 100.0% (2/2) | 100.0% (2/2) | 0.0% (0/2) | 0.0% (0/0) | 0.0% (0/0) | 0 | 1083.0 | 321 | unknown (pricing unavailable/unverified) |
