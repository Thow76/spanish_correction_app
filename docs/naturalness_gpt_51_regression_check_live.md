# Spanish Naturalness Model Comparison Harness

## Run configuration

- Prompt label: `spanish-naturalness-only-variety-restraint`
- Prompt version: `v3`
- Models: `gpt-5.1`
- Fixture case ids: `naturalness-calque-llamar-para-atras`, `naturalness-collocation-necesito-hacer-decision`, `naturalness-collocation-quiero-hacer-decision`, `naturalness-collocation-hacer-atencion`, `naturalness-collocation-tomar-reunion`, `naturalness-collocation-hacer-paseo`, `naturalness-control-hacer-pregunta`, `naturalness-control-tomar-foto`, `naturalness-control-para-casa`, `naturalness-grammar-trap-gustar-agreement`, `naturalness-es3-multi-correction`, `naturalness-es4-calque-pair`
- Runs per model/fixture case: `1`
- Generated: 2026-07-31T22:08:20.936414Z
- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`

## Pricing

Verified estimated costs use:
- `gpt-5.1`: input=1.25 USD, output=10.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## naturalness-calque-llamar-para-atras

- Input text: `Te llamo para atrás cuando termine la reunión.`
- Note: Naturalness/calque issue: literal English-influenced phrasing that should be identified without treating it as grammar.
- Expected naturalness issue(s): llamo para atrás -> llamo después (calque)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. Te llamo para atrás -> Te devuelvo la llamada / Te llamo de nuevo | 3409.0 | 3409 | 3409 | 403 | verified 0.001536 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-calque-llamar-para-atras | 1 | Te llamo para atrás cuando termine la reunión. | llamo para atrás -> llamo después (calque) | Te llamo para atrás -> Te devuelvo la llamada / Te llamo de nuevo | true | PASS | true | expected_issues_detected | 3409 | 285/118/403 | verified 0.001536 | {"has_naturalness_issue":true,"issues":[{"span":"Te llamo para atrás","natural_replacement":"Te devuelvo la llamada / Te llamo de nuevo","explanation":"\"Llamar para atrás\" es un calco del inglés \"to call back\". Aunque se oye en algunos contextos coloquiales, en un registro estándar o neutro lo natural sería decir \"te devuelvo la llamada\" o simplemente \"te llamo de nuevo\"."}]} |

## naturalness-collocation-necesito-hacer-decision

- Input text: `Necesito hacer una decisión importante antes del viernes.`
- Note: Collocation overlap case: tests whether the naturalness pass also detects hacer una decisión as a lexical-selection issue.
- Expected naturalness issue(s): hacer una decisión -> tomar una decisión (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. hacer una decisión -> tomar una decisión | 1649.0 | 1649 | 1649 | 367 | verified 0.001176 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-collocation-necesito-hacer-decision | 1 | Necesito hacer una decisión importante antes del viernes. | hacer una decisión -> tomar una decisión (collocation) | hacer una decisión -> tomar una decisión | true | PASS | true | expected_issues_detected | 1649 | 285/82/367 | verified 0.001176 | {"has_naturalness_issue":true,"issues":[{"span":"hacer una decisión","natural_replacement":"tomar una decisión","explanation":"En español, lo natural es decir \"tomar una decisión\" y no \"hacer una decisión\", que es un calco del inglés \"make a decision\"."}]} |

## naturalness-collocation-quiero-hacer-decision

- Input text: `Quiero hacer una decisión antes de mañana.`
- Note: Short collocation overlap case: hacer una decisión should be identified as unnatural lexical selection.
- Expected naturalness issue(s): hacer una decisión -> tomar una decisión (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. hacer una decisión -> tomar una decisión | 2112.0 | 2112 | 2112 | 390 | verified 0.001415 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-collocation-quiero-hacer-decision | 1 | Quiero hacer una decisión antes de mañana. | hacer una decisión -> tomar una decisión (collocation) | hacer una decisión -> tomar una decisión | true | PASS | true | expected_issues_detected | 2112 | 284/106/390 | verified 0.001415 | {"has_naturalness_issue":true,"issues":[{"span":"hacer una decisión","natural_replacement":"tomar una decisión","explanation":"En español, el verbo natural que se usa con \"decisión\" es \"tomar\" y no \"hacer\". \"Hacer una decisión\" suena a calco del inglés \"to make a decision\" y no es una colocación habitual entre hablantes nativos."}]} |

## naturalness-collocation-hacer-atencion

- Input text: `Tenemos que hacer atención a los detalles del contrato.`
- Note: Collocation overlap case: hacer atención should be identified as unnatural lexical selection.
- Expected naturalness issue(s): hacer atención -> prestar atención (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. hacer atención -> prestar atención | 1817.0 | 1817 | 1817 | 371 | verified 0.001216 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-collocation-hacer-atencion | 1 | Tenemos que hacer atención a los detalles del contrato. | hacer atención -> prestar atención (collocation) | hacer atención -> prestar atención | true | PASS | true | expected_issues_detected | 1817 | 285/86/371 | verified 0.001216 | {"has_naturalness_issue":true,"issues":[{"span":"hacer atención","natural_replacement":"prestar atención","explanation":"En este contexto, un hablante nativo diría \"prestar atención\" a los detalles, no \"hacer atención\", que suena a calco del inglés \"to pay attention\"."}]} |

## naturalness-collocation-tomar-reunion

- Input text: `El equipo tomó una reunión para hablar del problema.`
- Note: Collocation overlap case: tomar una reunión should be identified as unnatural lexical selection.
- Expected naturalness issue(s): tomó una reunión -> tuvo una reunión (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. tomó una reunión -> tuvo una reunión / se reunió | 1818.0 | 1818 | 1818 | 386 | verified 0.001366 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-collocation-tomar-reunion | 1 | El equipo tomó una reunión para hablar del problema. | tomó una reunión -> tuvo una reunión (collocation) | tomó una reunión -> tuvo una reunión / se reunió | true | PASS | true | expected_issues_detected | 1818 | 285/101/386 | verified 0.001366 | {"has_naturalness_issue":true,"issues":[{"span":"tomó una reunión","natural_replacement":"tuvo una reunión / se reunió","explanation":"\"Tomar una reunión\" es un calco del inglés (to take a meeting) y suena poco natural en la mayoría de variedades de español. Lo habitual es decir \"tener una reunión\" o simplemente \"reunirse\"."}]} |

## naturalness-collocation-hacer-paseo

- Input text: `Ella hizo un paseo por el parque después del trabajo.`
- Note: Collocation overlap case: hacer un paseo should be identified as unnatural lexical selection.
- Expected naturalness issue(s): hizo un paseo -> dio un paseo (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. hizo un paseo -> dio un paseo | 1722.0 | 1722 | 1722 | 371 | verified 0.001208 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-collocation-hacer-paseo | 1 | Ella hizo un paseo por el parque después del trabajo. | hizo un paseo -> dio un paseo (collocation) | hizo un paseo -> dio un paseo | true | PASS | true | expected_issues_detected | 1722 | 286/85/371 | verified 0.001208 | {"has_naturalness_issue":true,"issues":[{"span":"hizo un paseo","natural_replacement":"dio un paseo","explanation":"En este contexto, un hablante nativo suele decir \"dar un paseo\" en lugar de \"hacer un paseo\" para referirse a caminar o pasear por un lugar."}]} |

## naturalness-control-hacer-pregunta

- Input text: `Voy a hacer una pregunta al profesor después de clase.`
- Note: Valid collocation control: hacer una pregunta should not be reported as a naturalness issue.
- Expected naturalness issue(s): (none)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. (none) | 1266.0 | 1266 | 1266 | 315 | verified 0.000648 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-control-hacer-pregunta | 1 | Voy a hacer una pregunta al profesor después de clase. | (none) | (none) | false | PASS | true | clean_control | 1266 | 286/29/315 | verified 0.000648 | {"has_naturalness_issue":false,"issues":[]} |

## naturalness-control-tomar-foto

- Input text: `Necesito tomar una foto del documento antes de enviarlo.`
- Note: Valid collocation control: tomar una foto should not be reported as a naturalness issue.
- Expected naturalness issue(s): (none)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. (none) | 873.0 | 873 | 873 | 316 | verified 0.000649 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-control-tomar-foto | 1 | Necesito tomar una foto del documento antes de enviarlo. | (none) | (none) | false | PASS | true | clean_control | 873 | 287/29/316 | verified 0.000649 | {"has_naturalness_issue":false,"issues":[]} |

## naturalness-control-para-casa

- Input text: `Está lloviendo, así que voy para casa ahora mismo.`
- Note: Valid regional/ordinary phrasing control: voy para casa should not be normalized away.
- Expected naturalness issue(s): (none)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. (none) | 1372.0 | 1372 | 1372 | 317 | verified 0.000650 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-control-para-casa | 1 | Está lloviendo, así que voy para casa ahora mismo. | (none) | (none) | false | PASS | true | clean_control | 1372 | 288/29/317 | verified 0.000650 | {"has_naturalness_issue":false,"issues":[]} |

## naturalness-grammar-trap-gustar-agreement

- Input text: `Me gusta las películas de acción los fines de semana.`
- Note: Grammar trap: the naturalness-only prompt should ignore ordinary grammar errors such as gustar agreement.
- Expected naturalness issue(s): (none)
- Must ignore span(s): `Me gusta las películas`

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. (none) | 1532.0 | 1532 | 1532 | 315 | verified 0.000648 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-grammar-trap-gustar-agreement | 1 | Me gusta las películas de acción los fines de semana. | (none) | (none) | false | PASS | true | clean_control | 1532 | 286/29/315 | verified 0.000648 | {"has_naturalness_issue":false,"issues":[]} |

## naturalness-es3-multi-correction

- Input text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`
- Note: ES-3 naturalness case with a spelling trap: report llamaron para atrás, but ignore trafico without an accent.
- Expected naturalness issue(s): llamaron para atrás -> devolvieron la llamada (calque)
- Must ignore span(s): `trafico`

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. llamaron para atrás -> volvieron a llamar | 2212.0 | 2212 | 2212 | 400 | verified 0.001436 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-es3-multi-correction | 1 | Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena. | llamaron para atrás -> devolvieron la llamada (calque) | llamaron para atrás -> volvieron a llamar | true | PASS | true | expected_issues_detected | 2212 | 293/107/400 | verified 0.001436 | {"has_naturalness_issue":true,"issues":[{"span":"llamaron para atrás","natural_replacement":"volvieron a llamar","explanation":"\"Llamar para atrás\" es un calco del inglés \"to call back\" y suena poco natural en la mayoría de variedades del español. Lo habitual es decir \"volver a llamar\" u otra expresión equivalente como \"devolver la llamada\" según el contexto."}]} |

## naturalness-es4-calque-pair

- Input text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`
- Note: ES-4 naturalness case with two calque issues in one input: a literal request form and pasar un buen tiempo.
- Expected naturalness issue(s): Puedo tener una cerveza -> Me pones una cerveza (calque)<br>pasar un buen tiempo -> pasarlo bien (calque)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 1/1 | true | 1. ¿Puedo tener una cerveza? -> ¿Me pones una cerveza? / ¿Me pones una caña? / ¿Me puede traer una cerveza?<br>pasar un buen tiempo -> pasarlo bien / pasarla bien / divertirme | 3726.0 | 3726 | 3726 | 513 | verified 0.002557 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | naturalness-es4-calque-pair | 1 | ¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche. | Puedo tener una cerveza -> Me pones una cerveza (calque)<br>pasar un buen tiempo -> pasarlo bien (calque) | ¿Puedo tener una cerveza? -> ¿Me pones una cerveza? / ¿Me pones una caña? / ¿Me puede traer una cerveza?<br>pasar un buen tiempo -> pasarlo bien / pasarla bien / divertirme | true | PASS | true | expected_issues_detected | 3726 | 294/219/513 | verified 0.002557 | {"has_naturalness_issue":true,"issues":[{"span":"¿Puedo tener una cerveza?","natural_replacement":"¿Me pones una cerveza? / ¿Me pones una caña? / ¿Me puede traer una cerveza?","explanation":"\"¿Puedo tener una cerveza?\" es un calco del inglés \"Can I have a beer?\". En un bar o restaurante, un hablante nativo suele usar fórmulas como \"¿Me pones...?\", \"¿Me trae...?\" o simplemente \"Una cerveza, por favor\"."},{"span":"pasar un buen tiempo","natural_replacement":"pasarlo bien / pasarla bien / divertirme","explanation":"\"pasar un buen tiempo\" suena a traducción literal de \"have a good time\". Lo natural en la mayoría de variedades es \"pasarlo bien\", \"pasarla bien\" (sobre todo en América) o verbos como \"divertirme\"."}]} |

---

## Overall model aggregates

| Model | Total runs | Total passed | Pass rate | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 12 | 12 | 100.0% (12/12) | 1959.0 | 873 | 3726 | 4464 | verified 0.014505 |

## Compare and contrast

| Model | Pass rate | Failed expected-issue runs | False-positive control runs | Ignored grammar/spelling trap runs | Invalid/error runs | Avg latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-5.1 | 100.0% (12/12) | 0 | 0 | 0 | 0 | 1959.0 | 4464 | verified 0.014505 |

### Direct readout

- Only one model was run, so there is no direct model contrast.
