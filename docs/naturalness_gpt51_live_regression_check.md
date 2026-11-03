# Live gpt-5.1 Naturalness Harness Regression Check

Issue: [#41](https://github.com/Thow76/spanish_correction_app/issues/41)

Branch base: `correction_pipeline_refactor`

Scope: confirm gpt-5.1 still performs as expected on the naturalness
harness's focused fixture set before production integration. No prompt or
code changes.

## Command Run

```bash
OPENAI_API_KEY=*** \
NATURALNESS_LIVE=true \
NATURALNESS_COMPARISON_MODELS=gpt-5.1 \
NATURALNESS_OUTPUT=docs/naturalness_gpt_51_regression_check_live.md \
flutter test test/naturalness_model_comparison_harness.dart --tags live --timeout none
```

Ran with the default fixture set (`naturalnessModelComparisonFixtures`,
12 cases) and the default 1 run per fixture. Full per-case detail (input
text, actual vs. expected issue, raw model JSON, tokens) is in the
generated report:
[docs/naturalness_gpt_51_regression_check_live.md](naturalness_gpt_51_regression_check_live.md).

## Result

```text
00:32 +1: All tests passed!
```

| Model | Total runs | Passed | Pass rate | Avg latency | Min / Max latency | Total tokens | Total est. cost |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `gpt-5.1` | 12 | 12 | **100.0%** | 1959 ms | 873 ms / 3726 ms | 4464 | **$0.014505** |

All 8 expected-issue fixtures (calques/collocations: `llamar para atrás`,
`hacer una decisión` ×2, `hacer atención`, `tomar una reunión`, `hacer un
paseo`, the ES-3 multi-correction case, the ES-4 calque-pair case) were
correctly flagged. All 4 control fixtures (valid collocations, the `voy
para casa` regional-variety control, and the `gustar` grammar-trap
control) correctly returned no issue. No invalid JSON, no false positives,
no false negatives.

## Comparison Against The Prior Baseline

`docs/spanish_two_pass_prompt_handoff.md` recorded gpt-5.1 at **100.0%**
(60/60) across a 5-runs-per-fixture benchmark, avg latency 1740.7 ms, total
cost ~$0.073 for that larger run. This regression check (1 run/fixture,
12 calls) reproduces the same **100.0%** pass rate; latency this run
(1959 ms avg) is in the same range as the baseline's, given the
inherent run-to-run latency variance already noted in that document.

## Conclusion

gpt-5.1 still passes the focused naturalness fixture set at the expected
(100%) rate. No regression found. No prompt or code changes made as part
of this issue.
