# Spanish Correction Model Comparison Harness

## Run configuration

- Prompt label: `simple-spanish-grammar-spelling-punctuation-only`
- Prompt version: `v1`
- Models: `gpt-4.1-mini`
- Fixture case ids: `boundary-redundant-yo`, `boundary-redundant-ellos`, `boundary-para-casa`, `boundary-regional-coger`, `boundary-regional-preterite`, `boundary-calque-llamar-para-atras`, `boundary-collocation-hacer-decision`, `boundary-gustar-agreement`, `boundary-missing-que`, `boundary-ser-estar-profesor`
- Runs per model/fixture case: `5`
- Generated: 2026-07-28T22:33:29.866939Z
- Git branch: `harness-repeat-runs`
- Git commit: `d398d715f1b2fb1cf52f5453901f3bc3c825248e`
- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`

## Pricing

Verified estimated costs use:
- `gpt-4.1-mini`: input=0.4 USD, output=1.6 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1-mini, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## boundary-redundant-yo

- Input text: `Yo trabajo mucho y yo también estudio por las noches.`
- Note: Pure unchanged boundary control: tests whether the model removes redundant but grammatical subject pronouns.
- Expected corrected_text: `Yo trabajo mucho y yo también estudio por las noches.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/5 | false | 1. Yo trabajo mucho y también estudio por las noches.<br>2. Yo trabajo mucho y yo también estudio por las noches. | 1013.2 | 763 | 1542 | 816 | verified 0.000424 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-redundant-yo | 1 | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y también estudio por las noches. | FAIL | true | over_correction | 1542 | 147/16/163 | verified 0.000084 | {"corrected_text":"Yo trabajo mucho y también estudio por las noches."} |
| gpt-4.1-mini | boundary-redundant-yo | 2 | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y yo también estudio por las noches. | PASS | true | unchanged_control | 763 | 147/17/164 | verified 0.000086 | {"corrected_text":"Yo trabajo mucho y yo también estudio por las noches."} |
| gpt-4.1-mini | boundary-redundant-yo | 3 | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y también estudio por las noches. | FAIL | true | over_correction | 1045 | 147/16/163 | verified 0.000084 | {"corrected_text":"Yo trabajo mucho y también estudio por las noches."} |
| gpt-4.1-mini | boundary-redundant-yo | 4 | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y también estudio por las noches. | FAIL | true | over_correction | 830 | 147/16/163 | verified 0.000084 | {"corrected_text":"Yo trabajo mucho y también estudio por las noches."} |
| gpt-4.1-mini | boundary-redundant-yo | 5 | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y yo también estudio por las noches. | Yo trabajo mucho y también estudio por las noches. | FAIL | true | over_correction | 886 | 147/16/163 | verified 0.000084 | {"corrected_text":"Yo trabajo mucho y también estudio por las noches."} |

## boundary-redundant-ellos

- Input text: `Ellos viajaron a México y ellos visitaron varias ciudades.`
- Note: Pure unchanged boundary control: tests whether the model removes repeated but grammatical subject pronouns.
- Expected corrected_text: `Ellos viajaron a México y ellos visitaron varias ciudades.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 0/5 | true | 1. Ellos viajaron a México y visitaron varias ciudades. | 699.4 | 658 | 746 | 835 | verified 0.000442 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-redundant-ellos | 1 | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y visitaron varias ciudades. | FAIL | true | over_correction | 658 | 149/18/167 | verified 0.000088 | {"corrected_text":"Ellos viajaron a México y visitaron varias ciudades."} |
| gpt-4.1-mini | boundary-redundant-ellos | 2 | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y visitaron varias ciudades. | FAIL | true | over_correction | 698 | 149/18/167 | verified 0.000088 | {"corrected_text":"Ellos viajaron a México y visitaron varias ciudades."} |
| gpt-4.1-mini | boundary-redundant-ellos | 3 | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y visitaron varias ciudades. | FAIL | true | over_correction | 680 | 149/18/167 | verified 0.000088 | {"corrected_text":"Ellos viajaron a México y visitaron varias ciudades."} |
| gpt-4.1-mini | boundary-redundant-ellos | 4 | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y visitaron varias ciudades. | FAIL | true | over_correction | 746 | 149/18/167 | verified 0.000088 | {"corrected_text":"Ellos viajaron a México y visitaron varias ciudades."} |
| gpt-4.1-mini | boundary-redundant-ellos | 5 | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y ellos visitaron varias ciudades. | Ellos viajaron a México y visitaron varias ciudades. | FAIL | true | over_correction | 715 | 149/18/167 | verified 0.000088 | {"corrected_text":"Ellos viajaron a México y visitaron varias ciudades."} |

## boundary-para-casa

- Input text: `Está lloviendo, así que voy para casa ahora mismo.`
- Note: Pure unchanged boundary control: tests whether the model incorrectly normalizes valid "para casa" usage.
- Expected corrected_text: `Está lloviendo, así que voy para casa ahora mismo.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Está lloviendo, así que voy para casa ahora mismo. | 843.8 | 781 | 989 | 840 | verified 0.000450 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-para-casa | 1 | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | PASS | true | unchanged_control | 781 | 149/19/168 | verified 0.000090 | {"corrected_text":"Está lloviendo, así que voy para casa ahora mismo."} |
| gpt-4.1-mini | boundary-para-casa | 2 | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | PASS | true | unchanged_control | 989 | 149/19/168 | verified 0.000090 | {"corrected_text":"Está lloviendo, así que voy para casa ahora mismo."} |
| gpt-4.1-mini | boundary-para-casa | 3 | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | PASS | true | unchanged_control | 885 | 149/19/168 | verified 0.000090 | {"corrected_text":"Está lloviendo, así que voy para casa ahora mismo."} |
| gpt-4.1-mini | boundary-para-casa | 4 | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | PASS | true | unchanged_control | 783 | 149/19/168 | verified 0.000090 | {"corrected_text":"Está lloviendo, así que voy para casa ahora mismo."} |
| gpt-4.1-mini | boundary-para-casa | 5 | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | Está lloviendo, así que voy para casa ahora mismo. | PASS | true | unchanged_control | 781 | 149/19/168 | verified 0.000090 | {"corrected_text":"Está lloviendo, así que voy para casa ahora mismo."} |

## boundary-regional-coger

- Input text: `Cada mañana cojo el autobús para llegar a la oficina.`
- Note: Pure unchanged boundary control: tests whether the model rewrites valid Peninsular Spanish because a word is dialectally sensitive.
- Expected corrected_text: `Cada mañana cojo el autobús para llegar a la oficina.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Cada mañana cojo el autobús para llegar a la oficina. | 720.4 | 613 | 855 | 840 | verified 0.000450 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-regional-coger | 1 | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | PASS | true | unchanged_control | 680 | 149/19/168 | verified 0.000090 | {"corrected_text":"Cada mañana cojo el autobús para llegar a la oficina."} |
| gpt-4.1-mini | boundary-regional-coger | 2 | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | PASS | true | unchanged_control | 613 | 149/19/168 | verified 0.000090 | {"corrected_text":"Cada mañana cojo el autobús para llegar a la oficina."} |
| gpt-4.1-mini | boundary-regional-coger | 3 | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | PASS | true | unchanged_control | 671 | 149/19/168 | verified 0.000090 | {"corrected_text":"Cada mañana cojo el autobús para llegar a la oficina."} |
| gpt-4.1-mini | boundary-regional-coger | 4 | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | PASS | true | unchanged_control | 855 | 149/19/168 | verified 0.000090 | {"corrected_text":"Cada mañana cojo el autobús para llegar a la oficina."} |
| gpt-4.1-mini | boundary-regional-coger | 5 | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | Cada mañana cojo el autobús para llegar a la oficina. | PASS | true | unchanged_control | 783 | 149/19/168 | verified 0.000090 | {"corrected_text":"Cada mañana cojo el autobús para llegar a la oficina."} |

## boundary-regional-preterite

- Input text: `Esta mañana hablé con mi jefe sobre el proyecto nuevo.`
- Note: Pure unchanged boundary control: tests whether the model changes a valid preterite/present-perfect regional tense preference.
- Expected corrected_text: `Esta mañana hablé con mi jefe sobre el proyecto nuevo.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Esta mañana hablé con mi jefe sobre el proyecto nuevo. | 741.8 | 678 | 819 | 830 | verified 0.000440 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-regional-preterite | 1 | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | PASS | true | unchanged_control | 690 | 148/18/166 | verified 0.000088 | {"corrected_text":"Esta mañana hablé con mi jefe sobre el proyecto nuevo."} |
| gpt-4.1-mini | boundary-regional-preterite | 2 | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | PASS | true | unchanged_control | 736 | 148/18/166 | verified 0.000088 | {"corrected_text":"Esta mañana hablé con mi jefe sobre el proyecto nuevo."} |
| gpt-4.1-mini | boundary-regional-preterite | 3 | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | PASS | true | unchanged_control | 786 | 148/18/166 | verified 0.000088 | {"corrected_text":"Esta mañana hablé con mi jefe sobre el proyecto nuevo."} |
| gpt-4.1-mini | boundary-regional-preterite | 4 | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | PASS | true | unchanged_control | 819 | 148/18/166 | verified 0.000088 | {"corrected_text":"Esta mañana hablé con mi jefe sobre el proyecto nuevo."} |
| gpt-4.1-mini | boundary-regional-preterite | 5 | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | Esta mañana hablé con mi jefe sobre el proyecto nuevo. | PASS | true | unchanged_control | 678 | 148/18/166 | verified 0.000088 | {"corrected_text":"Esta mañana hablé con mi jefe sobre el proyecto nuevo."} |

## boundary-calque-llamar-para-atras

- Input text: `Te llamo para atrás cuando termine la reunión.`
- Note: Word-choice/naturalness boundary control: tests whether the model rewrites a calque as a naturalness improvement.
- Expected corrected_text: `Te llamo para atrás cuando termine la reunión.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 2/5 | false | 1. Te llamo después cuando termine la reunión.<br>2. Te llamo para atrás cuando termine la reunión.<br>3. Te llamo después de que termine la reunión. | 720.8 | 675 | 787 | 808 | verified 0.000417 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-calque-llamar-para-atras | 1 | Te llamo para atrás cuando termine la reunión. | Te llamo para atrás cuando termine la reunión. | Te llamo después cuando termine la reunión. | FAIL | true | over_correction | 781 | 146/15/161 | verified 0.000082 | {"corrected_text":"Te llamo después cuando termine la reunión."} |
| gpt-4.1-mini | boundary-calque-llamar-para-atras | 2 | Te llamo para atrás cuando termine la reunión. | Te llamo para atrás cuando termine la reunión. | Te llamo para atrás cuando termine la reunión. | PASS | true | unchanged_control | 680 | 146/16/162 | verified 0.000084 | {"corrected_text":"Te llamo para atrás cuando termine la reunión."} |
| gpt-4.1-mini | boundary-calque-llamar-para-atras | 3 | Te llamo para atrás cuando termine la reunión. | Te llamo para atrás cuando termine la reunión. | Te llamo para atrás cuando termine la reunión. | PASS | true | unchanged_control | 675 | 146/16/162 | verified 0.000084 | {"corrected_text":"Te llamo para atrás cuando termine la reunión."} |
| gpt-4.1-mini | boundary-calque-llamar-para-atras | 4 | Te llamo para atrás cuando termine la reunión. | Te llamo para atrás cuando termine la reunión. | Te llamo después cuando termine la reunión. | FAIL | true | over_correction | 787 | 146/15/161 | verified 0.000082 | {"corrected_text":"Te llamo después cuando termine la reunión."} |
| gpt-4.1-mini | boundary-calque-llamar-para-atras | 5 | Te llamo para atrás cuando termine la reunión. | Te llamo para atrás cuando termine la reunión. | Te llamo después de que termine la reunión. | FAIL | true | over_correction | 681 | 146/16/162 | verified 0.000084 | {"corrected_text":"Te llamo después de que termine la reunión."} |

## boundary-collocation-hacer-decision

- Input text: `Necesito hacer una decisión importante antes del viernes.`
- Note: Word-choice/naturalness boundary control: tests whether the model rewrites an unnatural collocation such as "hacer una decisión" to "tomar una decisión".
- Expected corrected_text: `Necesito hacer una decisión importante antes del viernes.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 0/5 | true | 1. Necesito tomar una decisión importante antes del viernes. | 885.0 | 681 | 1291 | 810 | verified 0.000420 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-collocation-hacer-decision | 1 | Necesito hacer una decisión importante antes del viernes. | Necesito hacer una decisión importante antes del viernes. | Necesito tomar una decisión importante antes del viernes. | FAIL | true | over_correction | 779 | 146/16/162 | verified 0.000084 | {"corrected_text":"Necesito tomar una decisión importante antes del viernes."} |
| gpt-4.1-mini | boundary-collocation-hacer-decision | 2 | Necesito hacer una decisión importante antes del viernes. | Necesito hacer una decisión importante antes del viernes. | Necesito tomar una decisión importante antes del viernes. | FAIL | true | over_correction | 681 | 146/16/162 | verified 0.000084 | {"corrected_text":"Necesito tomar una decisión importante antes del viernes."} |
| gpt-4.1-mini | boundary-collocation-hacer-decision | 3 | Necesito hacer una decisión importante antes del viernes. | Necesito hacer una decisión importante antes del viernes. | Necesito tomar una decisión importante antes del viernes. | FAIL | true | over_correction | 785 | 146/16/162 | verified 0.000084 | {"corrected_text":"Necesito tomar una decisión importante antes del viernes."} |
| gpt-4.1-mini | boundary-collocation-hacer-decision | 4 | Necesito hacer una decisión importante antes del viernes. | Necesito hacer una decisión importante antes del viernes. | Necesito tomar una decisión importante antes del viernes. | FAIL | true | over_correction | 889 | 146/16/162 | verified 0.000084 | {"corrected_text":"Necesito tomar una decisión importante antes del viernes."} |
| gpt-4.1-mini | boundary-collocation-hacer-decision | 5 | Necesito hacer una decisión importante antes del viernes. | Necesito hacer una decisión importante antes del viernes. | Necesito tomar una decisión importante antes del viernes. | FAIL | true | over_correction | 1291 | 146/16/162 | verified 0.000084 | {"corrected_text":"Necesito tomar una decisión importante antes del viernes."} |

## boundary-gustar-agreement

- Input text: `Me gusta las películas de acción los fines de semana.`
- Note: Grammar-boundary correction: tests true verb agreement in a construction learners often experience as lexical or idiomatic.
- Expected corrected_text: `Me gustan las películas de acción los fines de semana.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Me gustan las películas de acción los fines de semana. | 823.0 | 673 | 1092 | 820 | verified 0.000430 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-gustar-agreement | 1 | Me gusta las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | PASS | true | expected_correction | 780 | 147/17/164 | verified 0.000086 | {"corrected_text":"Me gustan las películas de acción los fines de semana."} |
| gpt-4.1-mini | boundary-gustar-agreement | 2 | Me gusta las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | PASS | true | expected_correction | 1092 | 147/17/164 | verified 0.000086 | {"corrected_text":"Me gustan las películas de acción los fines de semana."} |
| gpt-4.1-mini | boundary-gustar-agreement | 3 | Me gusta las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | PASS | true | expected_correction | 890 | 147/17/164 | verified 0.000086 | {"corrected_text":"Me gustan las películas de acción los fines de semana."} |
| gpt-4.1-mini | boundary-gustar-agreement | 4 | Me gusta las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | PASS | true | expected_correction | 673 | 147/17/164 | verified 0.000086 | {"corrected_text":"Me gustan las películas de acción los fines de semana."} |
| gpt-4.1-mini | boundary-gustar-agreement | 5 | Me gusta las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | Me gustan las películas de acción los fines de semana. | PASS | true | expected_correction | 680 | 147/17/164 | verified 0.000086 | {"corrected_text":"Me gustan las películas de acción los fines de semana."} |

## boundary-missing-que

- Input text: `Creo está bien terminar el proyecto esta semana.`
- Note: Grammar-boundary correction: tests whether the model corrects an omitted complementizer without rewriting the sentence.
- Expected corrected_text: `Creo que está bien terminar el proyecto esta semana.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Creo que está bien terminar el proyecto esta semana. | 682.8 | 591 | 778 | 805 | verified 0.000418 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-missing-que | 1 | Creo está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | PASS | true | expected_correction | 679 | 145/16/161 | verified 0.000084 | {"corrected_text":"Creo que está bien terminar el proyecto esta semana."} |
| gpt-4.1-mini | boundary-missing-que | 2 | Creo está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | PASS | true | expected_correction | 778 | 145/16/161 | verified 0.000084 | {"corrected_text":"Creo que está bien terminar el proyecto esta semana."} |
| gpt-4.1-mini | boundary-missing-que | 3 | Creo está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | PASS | true | expected_correction | 686 | 145/16/161 | verified 0.000084 | {"corrected_text":"Creo que está bien terminar el proyecto esta semana."} |
| gpt-4.1-mini | boundary-missing-que | 4 | Creo está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | PASS | true | expected_correction | 680 | 145/16/161 | verified 0.000084 | {"corrected_text":"Creo que está bien terminar el proyecto esta semana."} |
| gpt-4.1-mini | boundary-missing-que | 5 | Creo está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | Creo que está bien terminar el proyecto esta semana. | PASS | true | expected_correction | 591 | 145/16/161 | verified 0.000084 | {"corrected_text":"Creo que está bien terminar el proyecto esta semana."} |

## boundary-ser-estar-profesor

- Input text: `Mi hermano está profesor en una escuela secundaria.`
- Note: Grammar-boundary correction: tests objective ser/estar correction without changing wording beyond the verb.
- Expected corrected_text: `Mi hermano es profesor en una escuela secundaria.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Mi hermano es profesor en una escuela secundaria. | 717.8 | 588 | 883 | 800 | verified 0.000410 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | boundary-ser-estar-profesor | 1 | Mi hermano está profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | PASS | true | expected_correction | 829 | 145/15/160 | verified 0.000082 | {"corrected_text":"Mi hermano es profesor en una escuela secundaria."} |
| gpt-4.1-mini | boundary-ser-estar-profesor | 2 | Mi hermano está profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | PASS | true | expected_correction | 619 | 145/15/160 | verified 0.000082 | {"corrected_text":"Mi hermano es profesor en una escuela secundaria."} |
| gpt-4.1-mini | boundary-ser-estar-profesor | 3 | Mi hermano está profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | PASS | true | expected_correction | 588 | 145/15/160 | verified 0.000082 | {"corrected_text":"Mi hermano es profesor en una escuela secundaria."} |
| gpt-4.1-mini | boundary-ser-estar-profesor | 4 | Mi hermano está profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | PASS | true | expected_correction | 670 | 145/15/160 | verified 0.000082 | {"corrected_text":"Mi hermano es profesor en una escuela secundaria."} |
| gpt-4.1-mini | boundary-ser-estar-profesor | 5 | Mi hermano está profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | Mi hermano es profesor en una escuela secundaria. | PASS | true | expected_correction | 883 | 145/15/160 | verified 0.000082 | {"corrected_text":"Mi hermano es profesor en una escuela secundaria."} |

---

## Overall model aggregates

| Model | Total runs | Total passed | Pass rate | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 50 | 33 | 66.0% (33/50) | 784.8 | 588 | 1542 | 8204 | verified 0.004300 |

## Overall scoring breakdown

| Model | Valid JSON rate | Expected corrections | Missed fixes | Controls unchanged | Over-corrections | Unexpected outputs |
| --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 100.0% (50/50) | 100.0% (15/15) | 0.0% (0/15) | 51.4% (18/35) | 48.6% (17/35) | 0 |
