# Spanish Correction Model Comparison Harness

## Run configuration

- Prompt label: `simple-spanish-grammar-spelling-punctuation-only`
- Prompt version: `v1`
- Models: `gpt-4.1-mini`
- Fixture case ids: `lexical-control-hacer-pregunta`, `lexical-control-tomar-foto`, `lexical-control-dar-paseo`, `lexical-hacer-paseo`, `lexical-hacer-atencion`, `lexical-tomar-reunion`, `lexical-hacer-decision`, `lexical-tomar-fiesta`
- Runs per model/fixture case: `5`
- Generated: 2026-07-28T23:01:16.119718Z
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
| gpt-4.1-mini | 5/5 | true | 1. Voy a hacer una pregunta al profesor después de clase. | 942.6 | 780 | 1185 | 820 | verified 0.000430 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 1 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 1185 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 2 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 990 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 3 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 839 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 4 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 919 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |
| gpt-4.1-mini | lexical-control-hacer-pregunta | 5 | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | Voy a hacer una pregunta al profesor después de clase. | PASS | true | unchanged_control | 780 | 147/17/164 | verified 0.000086 | {"corrected_text":"Voy a hacer una pregunta al profesor después de clase."} |

## lexical-control-tomar-foto

- Input text: `Necesito tomar una foto del documento antes de enviarlo.`
- Note: Valid tomar + foto collocation. Ensures the model does not blindly replace tomar.
- Expected corrected_text: `Necesito tomar una foto del documento antes de enviarlo.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Necesito tomar una foto del documento antes de enviarlo. | 761.8 | 710 | 784 | 830 | verified 0.000440 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-control-tomar-foto | 1 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 778 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 2 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 710 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 3 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 753 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 4 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 784 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |
| gpt-4.1-mini | lexical-control-tomar-foto | 5 | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | Necesito tomar una foto del documento antes de enviarlo. | PASS | true | unchanged_control | 784 | 148/18/166 | verified 0.000088 | {"corrected_text":"Necesito tomar una foto del documento antes de enviarlo."} |

## lexical-control-dar-paseo

- Input text: `Vamos a dar un paseo por el parque esta tarde.`
- Note: Valid dar + paseo collocation.
- Expected corrected_text: `Vamos a dar un paseo por el parque esta tarde.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Vamos a dar un paseo por el parque esta tarde. | 761.8 | 677 | 785 | 820 | verified 0.000430 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-control-dar-paseo | 1 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 780 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 2 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 783 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 3 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 784 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 4 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 785 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |
| gpt-4.1-mini | lexical-control-dar-paseo | 5 | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | Vamos a dar un paseo por el parque esta tarde. | PASS | true | unchanged_control | 677 | 147/17/164 | verified 0.000086 | {"corrected_text":"Vamos a dar un paseo por el parque esta tarde."} |

## lexical-hacer-paseo

- Input text: `Ella hizo un paseo por el parque después del trabajo.`
- Note: Wrong verb-noun collocation: hacer un paseo should be dar un paseo.
- Expected corrected_text: `Ella dio un paseo por el parque después del trabajo.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Ella dio un paseo por el parque después del trabajo. | 702.0 | 675 | 772 | 820 | verified 0.000430 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-hacer-paseo | 1 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 680 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 2 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 681 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 3 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 675 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 4 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 702 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |
| gpt-4.1-mini | lexical-hacer-paseo | 5 | Ella hizo un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | Ella dio un paseo por el parque después del trabajo. | PASS | true | expected_correction | 772 | 147/17/164 | verified 0.000086 | {"corrected_text":"Ella dio un paseo por el parque después del trabajo."} |

## lexical-hacer-atencion

- Input text: `Tenemos que hacer atención a los detalles del contrato.`
- Note: Wrong verb-noun collocation: hacer atención should be prestar atención.
- Expected corrected_text: `Tenemos que prestar atención a los detalles del contrato.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Tenemos que prestar atención a los detalles del contrato. | 780.8 | 641 | 884 | 810 | verified 0.000420 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-hacer-atencion | 1 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 775 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 2 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 781 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 3 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 641 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 4 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 823 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |
| gpt-4.1-mini | lexical-hacer-atencion | 5 | Tenemos que hacer atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | Tenemos que prestar atención a los detalles del contrato. | PASS | true | expected_correction | 884 | 146/16/162 | verified 0.000084 | {"corrected_text":"Tenemos que prestar atención a los detalles del contrato."} |

## lexical-tomar-reunion

- Input text: `El equipo tomó una reunión para hablar del problema.`
- Note: Wrong verb-noun collocation: tomar una reunión should be tener una reunión.
- Expected corrected_text: `El equipo tuvo una reunión para hablar del problema.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. El equipo tuvo una reunión para hablar del problema. | 700.0 | 625 | 779 | 810 | verified 0.000420 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-tomar-reunion | 1 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 689 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 2 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 672 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 3 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 625 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 4 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 735 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |
| gpt-4.1-mini | lexical-tomar-reunion | 5 | El equipo tomó una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | El equipo tuvo una reunión para hablar del problema. | PASS | true | expected_correction | 779 | 146/16/162 | verified 0.000084 | {"corrected_text":"El equipo tuvo una reunión para hablar del problema."} |

## lexical-hacer-decision

- Input text: `Quiero hacer una decisión antes de mañana.`
- Note: Wrong verb-noun collocation: hacer una decisión should be tomar una decisión.
- Expected corrected_text: `Quiero tomar una decisión antes de mañana.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 5/5 | true | 1. Quiero tomar una decisión antes de mañana. | 802.8 | 680 | 886 | 800 | verified 0.000410 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-hacer-decision | 1 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 786 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 2 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 680 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 3 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 883 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 4 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 886 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |
| gpt-4.1-mini | lexical-hacer-decision | 5 | Quiero hacer una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | Quiero tomar una decisión antes de mañana. | PASS | true | expected_correction | 779 | 145/15/160 | verified 0.000082 | {"corrected_text":"Quiero tomar una decisión antes de mañana."} |

## lexical-tomar-fiesta

- Input text: `Mi hermana tomó una fiesta para celebrar su cumpleaños.`
- Note: Wrong verb-noun collocation: tomar una fiesta should be hacer una fiesta.
- Expected corrected_text: `Mi hermana hizo una fiesta para celebrar su cumpleaños.`

| Model | Runs passed | Outputs identical | Distinct actual outputs | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 1/5 | false | 1. Mi hermana organizó una fiesta para celebrar su cumpleaños.<br>2. Mi hermana hizo una fiesta para celebrar su cumpleaños. | 714.2 | 634 | 789 | 814 | verified 0.000426 |

### Individual runs

| Model | Fixture id | Run | Input text | Expected output | Actual output | Pass/fail | Valid JSON | Review status | Latency (ms) | Tokens (in/out/total) | Est. cost (USD) | raw_response |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | lexical-tomar-fiesta | 1 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 786 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 2 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | PASS | true | expected_correction | 722 | 146/16/162 | verified 0.000084 | {"corrected_text":"Mi hermana hizo una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 3 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 634 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 4 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 789 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |
| gpt-4.1-mini | lexical-tomar-fiesta | 5 | Mi hermana tomó una fiesta para celebrar su cumpleaños. | Mi hermana hizo una fiesta para celebrar su cumpleaños. | Mi hermana organizó una fiesta para celebrar su cumpleaños. | FAIL | true | unexpected_correction | 640 | 146/17/163 | verified 0.000086 | {"corrected_text":"Mi hermana organizó una fiesta para celebrar su cumpleaños."} |

---

## Overall model aggregates

| Model | Total runs | Total passed | Pass rate | Avg latency (ms) | Min latency (ms) | Max latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 40 | 36 | 90.0% (36/40) | 770.8 | 625 | 1185 | 6524 | verified 0.003406 |

## Overall scoring breakdown

| Model | Valid JSON rate | Expected corrections | Missed fixes | Controls unchanged | Over-corrections | Unexpected outputs |
| --- | --- | --- | --- | --- | --- | --- |
| gpt-4.1-mini | 100.0% (40/40) | 84.0% (21/25) | 0.0% (0/25) | 100.0% (15/15) | 0.0% (0/15) | 4 |
