# gpt-5.1 Naturalness Failure Review

Source: `docs/naturalness_gpt_51_vs_53_by_model_runs.md`

This is a scan-friendly view of the failed `gpt-5.1` naturalness runs. The important pattern is not just that there were 9 failures, but that the failures cluster around three prompt boundaries.

## At a Glance

| Fixture | Expected behavior | Pass rate | Failure pattern |
| --- | --- | ---: | --- |
| `voy para casa` | Return no issue | 80% (4/5) | One regional false positive |
| `Me gusta las películas...` | Return no issue because this is grammar-only | 20% (1/5) | Repeatedly corrected grammar as naturalness |
| `¿Puedo tener una cerveza? ... pasar un buen tiempo` | Flag both naturalness issues | 20% (1/5) | Usually caught only `pasar un buen tiempo` and missed `Puedo tener una cerveza` |

## Totals

- Model: `gpt-5.1`
- Failed runs: `9`
- Combined latency for failed runs: `19.420s`
- Combined estimated cost for failed runs: `verified 0.011067`

## Failure Type Counts

| Failure type | Count | Meaning |
| --- | ---: | --- |
| `false_positive` | 1 | Reported an issue where expected output was no issue |
| `ignored_trap_reported` | 4 | Reported grammar-only wording despite the naturalness-only instruction |
| `missing_expected_issue` | 4 | Missed at least one required naturalness issue |

## 1. Regional Control: `voy para casa`

**Input**

```text
Está lloviendo, así que voy para casa ahora mismo.
```

**Expected output**

```text
(none)
```

**Observed result**

`gpt-5.1` passed 4 out of 5 runs. The one failure treated valid regional/ordinary phrasing as something to normalize.

### Failed Run

| Run | Result | Model output | Latency | Cost |
| ---: | --- | --- | ---: | --- |
| 5 | FAIL (`false_positive`) | `voy para casa -> voy a casa` | 1909 ms | verified 0.001259 |

## 2. Grammar Trap: `Me gusta las películas...`

**Input**

```text
Me gusta las películas de acción los fines de semana.
```

**Expected output**

```text
(none)
```

**Observed result**

`gpt-5.1` passed only 1 out of 5 runs. In 4 runs, it corrected the grammar error as if it were a naturalness issue.

### Failed Runs

| Run | Result | Model output | Latency | Cost |
| ---: | --- | --- | ---: | --- |
| 1 | FAIL (`ignored_trap_reported`) | `Me gusta las películas de acción los fines de semana. -> Me gustan las películas de acción los fines de semana.` | 2009 ms | verified 0.001326 |
| 2 | FAIL (`ignored_trap_reported`) | `Me gusta las películas de acción -> Me gustan las películas de acción` | 2421 ms | verified 0.001216 |
| 3 | FAIL (`ignored_trap_reported`) | `Me gusta las películas de acción -> Me gustan las películas de acción` | 1907 ms | verified 0.001186 |
| 4 | FAIL (`ignored_trap_reported`) | `Me gusta las películas de acción los fines de semana. -> Me gustan las películas de acción los fines de semana.` | 2087 ms | verified 0.001336 |

## 3. Two-Issue Calque Pair: Beer Request + Good Time

**Input**

```text
¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.
```

**Expected output**

```text
Puedo tener una cerveza -> Me pones una cerveza (calque)
pasar un buen tiempo -> pasarlo bien (calque)
```

**Observed result**

`gpt-5.1` passed only 1 out of 5 runs for the full fixture. It usually identified the `pasar un buen tiempo` issue, but missed the `Puedo tener una cerveza` request-form issue.

### Failed Runs

| Run | Result | Model output | Latency | Cost |
| ---: | --- | --- | ---: | --- |
| 2 | FAIL (`missing_expected_issue`) | `Quiero pasar un buen tiempo -> Quiero pasar un buen rato` | 1704 ms | verified 0.001196 |
| 3 | FAIL (`missing_expected_issue`) | `pasar un buen tiempo -> pasarlo bien` | 2728 ms | verified 0.001146 |
| 4 | FAIL (`missing_expected_issue`) | `pasar un buen tiempo -> pasarlo bien` | 1803 ms | verified 0.001216 |
| 5 | FAIL (`missing_expected_issue`) | `pasar un buen tiempo -> pasarlo bien` | 2852 ms | verified 0.001186 |

## Prompt Implication

The `gpt-5.1` failures suggest two separate prompt issues:

1. It needs a stronger hard boundary between grammar correction and naturalness review.
2. It needs clearer instructions to identify every independent naturalness issue in a multi-issue input, not just the most obvious one.

The `voy para casa` result is less severe for `gpt-5.1` than for `gpt-5.3-chat-latest`, but it still shows the prompt should explicitly protect valid regional Spanish from being normalized.
