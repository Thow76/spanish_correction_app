# Spanish Correction Model Comparison Harness

## Run configuration

- Prompt label: `simple-spanish-grammar-spelling-punctuation-only`
- Prompt version: `v1`
- Models: `gpt-4.1-mini`
- Fixture case ids: `lexical-control-hacer-pregunta`, `lexical-control-tomar-foto`, `lexical-control-dar-paseo`, `lexical-hacer-paseo`, `lexical-hacer-atencion`, `lexical-tomar-reunion`, `lexical-hacer-decision`, `lexical-tomar-fiesta`
- Runs per model/fixture case: `5`
- Generated: 2026-07-28T22:42:12.154307Z
- Git branch: `correction_pipeline_refactor`
- Git commit: `d398d715f1b2fb1cf52f5453901f3bc3c825248e`
- Cost status: `unknown` unless verified pricing exists in `test/shared/model_pricing.dart`

## Pricing

Verified estimated costs use:
- `gpt-4.1-mini`: input=0.4 USD, output=1.6 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1-mini, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## lexical-control-hacer-pregunta

- Input text: `Voy a hacer una pregunta al profesor después de clase.`
- Note: Valid hacer + pregunta collocation. Ensures the model does not blindly replace hacer.
- Expected corrected_text: `Voy a hacer una pregunta al profesor después de clase.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Voy a hacer una pregunta al profesor después de clase. | 735.0 | 675 | 859 | 820 | verified 0.000430 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 1 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 859 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 2 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 675 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 3 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 680 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 4 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 780 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 5 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 681 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |

## lexical-control-tomar-foto

- Input text: `Necesito tomar una foto del documento antes de enviarlo.`
- Note: Valid tomar + foto collocation. Ensures the model does not blindly replace tomar.
- Expected corrected_text: `Necesito tomar una foto del documento antes de enviarlo.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Necesito tomar una foto del documento antes de enviarlo. | 791.2 | 724 | 885 | 830 | verified 0.000440 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-control-tomar-foto | 1 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 739 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 2 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 724 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 3 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 780 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 4 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 885 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 5 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 828 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |

## lexical-control-dar-paseo

- Input text: `Vamos a dar un paseo por el parque esta tarde.`
- Note: Valid dar + paseo collocation.
- Expected corrected_text: `Vamos a dar un paseo por el parque esta tarde.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Vamos a dar un paseo por el parque esta tarde. | 731.0 | 682 | 781 | 820 | verified 0.000430 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-control-dar-paseo | 1 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 721 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 2 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 692 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 3 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 682 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 4 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 779 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 5 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 781 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |

## lexical-hacer-paseo

- Input text: `Ella hizo un paseo por el parque después del trabajo.`
- Note: Wrong verb-noun collocation: hacer un paseo should be dar un paseo.
- Expected corrected_text: `Ella dio un paseo por el parque después del trabajo.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Ella dio un paseo por el parque después del trabajo. | 947.0 | 695 | 1665 | 820 | verified 0.000430 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-hacer-paseo | 1 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 695 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 2 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 771 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 3 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 885 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 4 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 1665 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 5 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 719 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |

## lexical-hacer-atencion

- Input text: `Tenemos que hacer atención a los detalles del contrato.`
- Note: Wrong verb-noun collocation: hacer atención should be prestar atención.
- Expected corrected_text: `Tenemos que prestar atención a los detalles del contrato.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Tenemos que prestar atención a los detalles del contrato. | 782.4 | 672 | 897 | 810 | verified 0.000420 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-hacer-atencion | 1 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 778 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 2 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 897 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 3 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 672 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 4 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 885 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 5 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 680 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |

## lexical-tomar-reunion

- Input text: `El equipo tomó una reunión para hablar del problema.`
- Note: Wrong verb-noun collocation: tomar una reunión should be tener una reunión.
- Expected corrected_text: `El equipo tuvo una reunión para hablar del problema.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. El equipo tuvo una reunión para hablar del problema. | 802.8 | 680 | 887 | 810 | verified 0.000420 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-tomar-reunion | 1 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 883 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 2 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 887 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 3 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 780 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 4 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 680 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 5 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 784 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |

## lexical-hacer-decision

- Input text: `Quiero hacer una decisión antes de mañana.`
- Note: Wrong verb-noun collocation: hacer una decisión should be tomar una decisión.
- Expected corrected_text: `Quiero tomar una decisión antes de mañana.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Quiero tomar una decisión antes de mañana. | 678.2 | 593 | 774 | 800 | verified 0.000410 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-hacer-decision | 1 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 661 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 2 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 593 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 3 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 683 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 4 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 680 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 5 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 774 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |

## lexical-tomar-fiesta

- Input text: `Mi hermana tomó una fiesta para celebrar su cumpleaños.`
- Note: Wrong verb-noun collocation: tomar una fiesta should be hacer una fiesta.
- Expected corrected_text: `Mi hermana hizo una fiesta para celebrar su cumpleaños.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 0/5 | true | 1. Mi hermana organizó una fiesta para celebrar su cumpleaños. | 751.0 | 682 | 930 | 815 | verified 0.000428 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-tomar-fiesta | 1 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 689 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 2 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 682 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 3 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 930 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 4 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 693 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 5 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 761 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |

---

## Overall model aggregates

| Model | Total runs | Total passed | Pass rate | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 40 | 35 | 87.5% (35/40) | 777.3 | 593 | 1665 | 6525 | verified 0.003408 |

## Overall scoring breakdown

| Model | Valid JSON rate | Expected corrections | Missed fixes | Controls unchanged | Over-corrections | Unexpected outputs |
| --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 100.0% (40/40) | 80.0% (20/25) | 0.0% (0/25) | 100.0% (15/15) | 0.0% (0/15) | 5 |
