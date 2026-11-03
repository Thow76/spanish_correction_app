# Spanish Naturalness Model Comparison Harness

## Run configuration

- Prompt label: `spanish-naturalness-only`
- Prompt version: `v1`
- Models: `gpt-4.1-mini`
- Fixture case ids: `naturalness-calque-llamar-para-atras`, `naturalness-collocation-necesito-hacer-decision`, `naturalness-collocation-quiero-hacer-decision`, `naturalness-collocation-hacer-atencion`, `naturalness-collocation-tomar-reunion`, `naturalness-collocation-hacer-paseo`, `naturalness-control-hacer-pregunta`, `naturalness-control-tomar-foto`, `naturalness-control-para-casa`, `naturalness-grammar-trap-gustar-agreement`, `naturalness-es3-multi-correction`, `naturalness-es4-calque-pair`
- Runs per model/fixture case: `1`
- Generated: 2026-07-28T23:46:37.777681Z
- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`

## Pricing

Verified estimated costs use:
- `gpt-4.1-mini`: input=0.4 USD, output=1.6 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1-mini, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## naturalness-calque-llamar-para-atras

- Input text: `Te llamo para atrás cuando termine la reunión.`
- Note: Naturalness/calque issue: literal English-influenced phrasing that should be identified without treating it as grammar.
- Expected naturalness issue(s): llamo para atrás -> llamo después (calque)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. Te llamo para atrás -> Te llamo después | 1407.0 | 1407 | 1407 | 293 | verified 0.000207 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-calque-llamar-para-atras | 1 | Te llamo para atrás cuando termine la reunión. | llamo para atrás -> llamo después (calque) | Te llamo para atrás -> Te llamo después | true | PASS | true | expected_issues_detected | 1407 | 218/75/293 | verified 0.000207 | {"has_naturalness_issue":true,"issues":[{"span":"Te llamo para atrás","natural_replacement":"Te llamo después","explanation":"La expresión \"Te llamo para atrás\" no es común en español para indicar que se llamará después; lo más natural es decir \"Te llamo después\" o \"Te llamo luego\"."}]} |

## naturalness-collocation-necesito-hacer-decision

- Input text: `Necesito hacer una decisión importante antes del viernes.`
- Note: Collocation overlap case: tests whether the naturalness pass also detects hacer una decisión as a lexical-selection issue.
- Expected naturalness issue(s): hacer una decisión -> tomar una decisión (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. hacer una decisión importante -> tomar una decisión importante | 1336.0 | 1336 | 1336 | 288 | verified 0.000199 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-collocation-necesito-hacer-decision | 1 | Necesito hacer una decisión importante antes del viernes. | hacer una decisión -> tomar una decisión (collocation) | hacer una decisión importante -> tomar una decisión importante | true | PASS | true | expected_issues_detected | 1336 | 218/70/288 | verified 0.000199 | {"has_naturalness_issue":true,"issues":[{"span":"hacer una decisión importante","natural_replacement":"tomar una decisión importante","explanation":"En español, el verbo que se usa comúnmente con 'decisión' es 'tomar', no 'hacer'. La expresión natural es 'tomar una decisión importante'."}]} |

## naturalness-collocation-quiero-hacer-decision

- Input text: `Quiero hacer una decisión antes de mañana.`
- Note: Short collocation overlap case: hacer una decisión should be identified as unnatural lexical selection.
- Expected naturalness issue(s): hacer una decisión -> tomar una decisión (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. hacer una decisión -> tomar una decisión | 1087.0 | 1087 | 1087 | 273 | verified 0.000176 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-collocation-quiero-hacer-decision | 1 | Quiero hacer una decisión antes de mañana. | hacer una decisión -> tomar una decisión (collocation) | hacer una decisión -> tomar una decisión | true | PASS | true | expected_issues_detected | 1087 | 217/56/273 | verified 0.000176 | {"has_naturalness_issue":true,"issues":[{"span":"hacer una decisión","natural_replacement":"tomar una decisión","explanation":"En español, el verbo que se utiliza naturalmente con 'decisión' es 'tomar', no 'hacer'."}]} |

## naturalness-collocation-hacer-atencion

- Input text: `Tenemos que hacer atención a los detalles del contrato.`
- Note: Collocation overlap case: hacer atención should be identified as unnatural lexical selection.
- Expected naturalness issue(s): hacer atención -> prestar atención (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. hacer atención -> prestar atención | 1089.0 | 1089 | 1089 | 278 | verified 0.000183 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-collocation-hacer-atencion | 1 | Tenemos que hacer atención a los detalles del contrato. | hacer atención -> prestar atención (collocation) | hacer atención -> prestar atención | true | PASS | true | expected_issues_detected | 1089 | 218/60/278 | verified 0.000183 | {"has_naturalness_issue":true,"issues":[{"span":"hacer atención","natural_replacement":"prestar atención","explanation":"La expresión más natural en español para indicar que se debe dedicar cuidado o concentración a algo es \"prestar atención\" y no \"hacer atención\"."}]} |

## naturalness-collocation-tomar-reunion

- Input text: `El equipo tomó una reunión para hablar del problema.`
- Note: Collocation overlap case: tomar una reunión should be identified as unnatural lexical selection.
- Expected naturalness issue(s): tomó una reunión -> tuvo una reunión (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. tomó una reunión -> tuvo una reunión | 1293.0 | 1293 | 1293 | 284 | verified 0.000193 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-collocation-tomar-reunion | 1 | El equipo tomó una reunión para hablar del problema. | tomó una reunión -> tuvo una reunión (collocation) | tomó una reunión -> tuvo una reunión | true | PASS | true | expected_issues_detected | 1293 | 218/66/284 | verified 0.000193 | {"has_naturalness_issue":true,"issues":[{"span":"tomó una reunión","natural_replacement":"tuvo una reunión","explanation":"En español, normalmente decimos \"tener una reunión\" en lugar de \"tomar una reunión\" para expresar que se celebró o participó en una reunión."}]} |

## naturalness-collocation-hacer-paseo

- Input text: `Ella hizo un paseo por el parque después del trabajo.`
- Note: Collocation overlap case: hacer un paseo should be identified as unnatural lexical selection.
- Expected naturalness issue(s): hizo un paseo -> dio un paseo (collocation)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. hizo un paseo -> dio un paseo | 1193.0 | 1193 | 1193 | 282 | verified 0.000188 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-collocation-hacer-paseo | 1 | Ella hizo un paseo por el parque después del trabajo. | hizo un paseo -> dio un paseo (collocation) | hizo un paseo -> dio un paseo | true | PASS | true | expected_issues_detected | 1193 | 219/63/282 | verified 0.000188 | {"has_naturalness_issue":true,"issues":[{"span":"hizo un paseo","natural_replacement":"dio un paseo","explanation":"En español, es más natural decir 'dar un paseo' en lugar de 'hacer un paseo' para expresar que alguien fue a caminar o pasear."}]} |

## naturalness-control-hacer-pregunta

- Input text: `Voy a hacer una pregunta al profesor después de clase.`
- Note: Valid collocation control: hacer una pregunta should not be reported as a naturalness issue.
- Expected naturalness issue(s): (none)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. (none) | 680.0 | 680 | 680 | 231 | verified 0.000107 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-control-hacer-pregunta | 1 | Voy a hacer una pregunta al profesor después de clase. | (none) | (none) | false | PASS | true | clean_control | 680 | 219/12/231 | verified 0.000107 | {"has_naturalness_issue":false,"issues":[]} |

## naturalness-control-tomar-foto

- Input text: `Necesito tomar una foto del documento antes de enviarlo.`
- Note: Valid collocation control: tomar una foto should not be reported as a naturalness issue.
- Expected naturalness issue(s): (none)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. (none) | 601.0 | 601 | 601 | 232 | verified 0.000107 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-control-tomar-foto | 1 | Necesito tomar una foto del documento antes de enviarlo. | (none) | (none) | false | PASS | true | clean_control | 601 | 220/12/232 | verified 0.000107 | {"has_naturalness_issue":false,"issues":[]} |

## naturalness-control-para-casa

- Input text: `Está lloviendo, así que voy para casa ahora mismo.`
- Note: Valid regional/ordinary phrasing control: voy para casa should not be normalized away.
- Expected naturalness issue(s): (none)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 0/1 | true | 1. voy para casa ahora mismo -> voy a casa ahora mismo | 1491.0 | 1491 | 1491 | 310 | verified 0.000231 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-control-para-casa | 1 | Está lloviendo, así que voy para casa ahora mismo. | (none) | voy para casa ahora mismo -> voy a casa ahora mismo | true | FAIL | true | false_positive | 1491 | 221/89/310 | verified 0.000231 | {"has_naturalness_issue":true,"issues":[{"span":"voy para casa ahora mismo","natural_replacement":"voy a casa ahora mismo","explanation":"En español, para expresar la idea de dirigirse a un lugar, es más natural usar 'ir a casa' en lugar de 'ir para casa'. La expresión 'voy para casa' es comprensible pero menos común y puede sonar poco natural en algunos contextos."}]} |

## naturalness-grammar-trap-gustar-agreement

- Input text: `Me gusta las películas de acción los fines de semana.`
- Note: Grammar trap: the naturalness-only prompt should ignore ordinary grammar errors such as gustar agreement.
- Expected naturalness issue(s): (none)
- Must ignore span(s): `Me gusta las películas`

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 0/1 | true | 1. Me gusta las películas de acción -> Me gustan las películas de acción | 1275.0 | 1275 | 1275 | 297 | verified 0.000212 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-grammar-trap-gustar-agreement | 1 | Me gusta las películas de acción los fines de semana. | (none) | Me gusta las películas de acción -> Me gustan las películas de acción | true | FAIL | true | ignored_trap_reported | 1275 | 219/78/297 | verified 0.000212 | {"has_naturalness_issue":true,"issues":[{"span":"Me gusta las películas de acción","natural_replacement":"Me gustan las películas de acción","explanation":"El verbo 'gustar' debe concordar en número con el sujeto 'las películas', que está en plural, por lo que se debe usar 'gustan' en lugar de 'gusta'."}]} |

## naturalness-es3-multi-correction

- Input text: `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.`
- Note: ES-3 naturalness case with a spelling trap: report llamaron para atrás, but ignore trafico without an accent.
- Expected naturalness issue(s): llamaron para atrás -> devolvieron la llamada (calque)
- Must ignore span(s): `trafico`

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/1 | true | 1. llamaron para atrás -> llamaron de vuelta | 1264.0 | 1264 | 1264 | 297 | verified 0.000204 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-es3-multi-correction | 1 | Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena. | llamaron para atrás -> devolvieron la llamada (calque) | llamaron para atrás -> llamaron de vuelta | true | PASS | true | expected_issues_detected | 1264 | 226/71/297 | verified 0.000204 | {"has_naturalness_issue":true,"issues":[{"span":"llamaron para atrás","natural_replacement":"llamaron de vuelta","explanation":"En español, cuando alguien devuelve una llamada, se dice 'llamar de vuelta' o 'volver a llamar'. La expresión 'llamaron para atrás' no es natural."}]} |

## naturalness-es4-calque-pair

- Input text: `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.`
- Note: ES-4 naturalness case with two calque issues in one input: a literal request form and pasar un buen tiempo.
- Expected naturalness issue(s): Puedo tener una cerveza -> Me pones una cerveza (calque)<br>pasar un buen tiempo -> pasarlo bien (calque)

| Model | Runs passed | Outputs identical | Distinct issue outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 0/1 | true | 1. pasar un buen tiempo -> pasar un buen rato | 1427.0 | 1427 | 1427 | 300 | verified 0.000208 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected issue(s) | Actual issue(s) | Has issue | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | naturalness-es4-calque-pair | 1 | ¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche. | Puedo tener una cerveza -> Me pones una cerveza (calque)<br>pasar un buen tiempo -> pasarlo bien (calque) | pasar un buen tiempo -> pasar un buen rato | true | FAIL | true | missing_expected_issue | 1427 | 227/73/300 | verified 0.000208 | {"has_naturalness_issue":true,"issues":[{"span":"pasar un buen tiempo","natural_replacement":"pasar un buen rato","explanation":"La expresión \"pasar un buen tiempo\" es comprensible pero inusual en español. La expresión más natural para indicar disfrutar de un momento agradable es \"pasar un buen rato\"."}]} |

---

## Overall model aggregates

| Model | Total runs | Total passed | Pass rate | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 12 | 9 | 75.0% (9/12) | 1178.6 | 601 | 1491 | 3365 | verified 0.002216 |
