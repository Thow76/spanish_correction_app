# Spanish Two-Pass Prompt Handoff

## Status

This work is complete for a first testing phase. The strongest current direction is a two-pass Spanish correction design:

1. First pass: objective grammar, spelling, and punctuation correction.
2. Second pass: naturalness, calques, idioms, collocations, and regional-variety restraint.

The purpose is to keep objective correction separate from subjective or usage-based naturalness feedback.

## Current Candidate Models

| Stage | Purpose | Candidate model | Current confidence |
| --- | --- | --- | --- |
| First pass | Grammar, spelling, punctuation only | `gpt-4.1` / `gpt-4.1-mini` family | Good first-pass candidate, especially for low-cost objective correction |
| Naturalness pass | Naturalness, calques, idioms, collocations | `gpt-5.1` | Strongest current candidate |

Note: prior handoff notes highlighted `gpt-4.1-mini` as surprisingly useful for the first pass because it was cheap, fast, and less tempted to rewrite stylistically. The user direction is to treat the first-pass prompt as the GPT-4.1-family correction pass, with model choice still open between `gpt-4.1` and `gpt-4.1-mini`.

## First-Pass Prompt

Harness:

```bash
flutter test test/model_comparison_harness.dart --tags live --timeout none
```

Prompt metadata:

```text
Prompt label: simple-spanish-grammar-spelling-punctuation-only
Prompt version: v1
```

System prompt:

```text
You are a Spanish correction engine.

Correct only objective Spanish grammar, spelling, and punctuation errors.

Do not correct word choice.
Do not improve naturalness.
Do not rewrite for style, fluency, tone, or elegance.
Do not change valid regional Spanish.
Do not treat awkward but grammatically valid Spanish as an error.

Return JSON only. Do not include Markdown or commentary.
```

User prompt template:

```text
Correct the following Spanish text for grammar, spelling, and punctuation only.

Text:
{inputText}
```

Response shape:

```json
{
  "corrected_text": "string"
}
```

Key first-pass principle: this prompt should fix objective errors only. It should not fix naturalness, collocations, calques, style, tone, fluency, or valid regional forms.

## Naturalness Prompt

Harness:

```bash
flutter test test/naturalness_model_comparison_harness.dart --tags live --timeout none
```

Prompt metadata:

```text
Prompt label: spanish-naturalness-only-variety-restraint
Prompt version: v3
```

Current intended system prompt:

```text
You are a Spanish tutor reviewing a text that has been checked for grammar, spelling, and punctuation.

Your task is to identify wording that a native Spanish speaker would be unlikely to use naturally in this context. This includes calques, idioms, and collocations.

Do not report spelling, punctuation, or grammatical errors.
If the only problem is grammar, spelling, or punctuation, return no issue.

Do not normalise wording that is natural in an established variety of Spanish. A form is not a naturalness issue merely because another form is more widespread, more neutral, or preferred by the reviewer's own regional variety. This includes established regional uses of para with verbs of movement to express direction or destination, such as ir para + place, where another variety may prefer ir a + place.

Ignore spelling, punctuation, or grammar errors even if they appear in the same sentence as a naturalness issue.

Return JSON only.
```

Response shape:

```json
{
  "has_naturalness_issue": true,
  "issues": [
    {
      "span": "string",
      "natural_replacement": "string",
      "explanation": "string"
    }
  ]
}
```

For no issue:

```json
{
  "has_naturalness_issue": false,
  "issues": []
}
```

Small implementation cleanup: the current Dart string has `regional variety.This includes...` without a space. The latest run still succeeded, but this should be tidied before making the prompt production-facing.

## Naturalness Test Set

The focused naturalness benchmark uses 12 fixtures, 5 runs per model:

| Fixture | Input | Expected |
| --- | --- | --- |
| `naturalness-calque-llamar-para-atras` | `Te llamo para atrás cuando termine la reunión.` | Flag `llamo para atrás` |
| `naturalness-collocation-necesito-hacer-decision` | `Necesito hacer una decisión importante antes del viernes.` | Flag `hacer una decisión` |
| `naturalness-collocation-quiero-hacer-decision` | `Quiero hacer una decisión antes de mañana.` | Flag `hacer una decisión` |
| `naturalness-collocation-hacer-atencion` | `Tenemos que hacer atención a los detalles del contrato.` | Flag `hacer atención` |
| `naturalness-collocation-tomar-reunion` | `El equipo tomó una reunión para hablar del problema.` | Flag `tomó una reunión` |
| `naturalness-collocation-hacer-paseo` | `Ella hizo un paseo por el parque después del trabajo.` | Flag `hizo un paseo` |
| `naturalness-control-hacer-pregunta` | `Voy a hacer una pregunta al profesor después de clase.` | No issue |
| `naturalness-control-tomar-foto` | `Necesito tomar una foto del documento antes de enviarlo.` | No issue |
| `naturalness-control-para-casa` | `Está lloviendo, así que voy para casa ahora mismo.` | No issue |
| `naturalness-grammar-trap-gustar-agreement` | `Me gusta las películas de acción los fines de semana.` | No naturalness issue; grammar-only trap |
| `naturalness-es3-multi-correction` | `Ayer había mucho trafico y mis amigos llamaron para atrás para confirmar la cena.` | Flag `llamaron para atrás`; ignore `trafico` accent |
| `naturalness-es4-calque-pair` | `¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis amigos esta noche.` | Flag both `Puedo tener una cerveza` and `pasar un buen tiempo` |

## Naturalness Results

Latest run included the explicit `ir para + place` protection.

| Model | Runs | Passed | Pass rate | Avg latency | Total cost |
| --- | ---: | ---: | ---: | ---: | ---: |
| `gpt-5.1` | 60 | 60 | 100.0% | 1740.7 ms | $0.073275 |
| `gpt-5.3-chat-latest` | 60 | 58 | 96.7% | 6475.6 ms | $0.120633 |

The `para` line fixed the prior `voy para casa` false positives:

| Model | Before explicit `para` line | After explicit `para` line |
| --- | ---: | ---: |
| `gpt-5.1` | 3/5 | 5/5 |
| `gpt-5.3-chat-latest` | 2/5 | 5/5 |

No obvious regression appeared: both models still caught `llamar para atrás` calques after the `ir para + place` protection was added.

Cost note for `gpt-5.1`: one run over all 12 phrases costs roughly $0.014-$0.015. The full 60-call `gpt-5.1` benchmark cost about $0.073.

## Key Conclusions

The naturalness stage is strong enough for a first implementation candidate using `gpt-5.1`.

The most important prompt boundary was regional variety. The models repeatedly tried to normalize `voy para casa` to `voy a casa` until the prompt explicitly protected movement/destination uses of `para`.

The grammar/naturalness boundary is now much stronger. The grammar trap `Me gusta las películas de acción los fines de semana.` passed 5/5 for `gpt-5.1` after the prompt revisions.

Latency has variance, sometimes large, but cost is stable because it tracks token count rather than wall-clock duration.

## Next Design Question

The next stage is deciding how to combine the two prompts.

### Option A: Sequential

Flow:

```text
Original text
  -> first-pass grammar/spelling/punctuation correction
  -> naturalness review on corrected text
  -> merge final feedback
```

Pros:
- Matches the naturalness prompt assumption: the text has already been checked for grammar, spelling, and punctuation.
- Reduces grammar-noise ambiguity for the naturalness model.
- Cleaner mental model for the user: first objective correctness, then naturalness.

Cons:
- Adds end-to-end latency.
- Naturalness spans refer to the corrected text, so mapping them back to the original may need careful UI handling.
- A first-pass rewrite could alter the phrase that the naturalness model would otherwise have flagged.

### Option B: Parallel

Flow:

```text
Original text
  -> first-pass grammar/spelling/punctuation correction
  -> naturalness review
  -> merge final feedback
```

Pros:
- Lower user-facing latency if both calls run concurrently.
- Naturalness spans refer directly to the original text.
- Keeps both models independent for easier debugging.

Cons:
- Naturalness model must continue ignoring grammar/spelling/punctuation noise in raw text.
- Conflicts need resolution if the first pass changes text inside a naturalness span.
- The naturalness prompt says the text has already been checked, which is less literally true in parallel mode.

### Current Recommendation

Prototype both merge strategies with the same fixture set before choosing.

For production UX, sequential is conceptually cleaner if the naturalness pass is meant to review already-corrected Spanish. Parallel is attractive if latency is the overriding constraint, but it requires stronger merge/conflict logic.

Suggested immediate next experiment:

1. Run first-pass correction on the 12 naturalness fixtures.
2. Feed the corrected output into the `gpt-5.1` naturalness prompt.
3. Compare against running naturalness directly on the original input.
4. Check whether expected naturalness spans are preserved, moved, or erased.
5. Decide whether the UI should display naturalness comments against original text or corrected text.

## Files To Inspect Next

```bash
test/model_comparison_harness.dart
test/naturalness_model_comparison_harness.dart
test/shared/benchmark_fixtures.dart
docs/model_comparison_boundary_control_live.md
docs/model_comparison_lexical_collocation_live.md
docs/naturalness_gpt_51_vs_53_live.md
```

Before changing code, run:

```bash
git status --short
rg -n "systemPrompt|naturalnessSystemPrompt|NATURALNESS_|MODEL_COMPARISON_" test lib docs
```
