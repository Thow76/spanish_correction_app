# Model Research Index

This repository keeps the current prompt/spec conclusions and archives the
historical trial-and-error reports separately.

## Retained conclusions

- `docs/correction_prompt_issues_and_solutions.md` tracks the current correction
  prompt decisions, including the standalone Portuguese prompt and the
  retranslation `is_related` gate.
- `docs/current_spanish_correction_prompt_audit.md` documents the five-stage
  Spanish correction prompts as they were when that pipeline was live. The
  pipeline was deleted in build step 2.5 (24 November 2026); its prompt wording
  is archived verbatim in `docs/archive/staged_pipeline_prompts.md`, and the
  live Spanish path is now the two-step check
  (`lib/features/corrections/data/suggestion_client.dart`).
- `docs/first_pass_correction_architecture_review.md` recommends the next
  first-pass Spanish correction architecture and the safeguards to preserve.
- `docs/walkthrough_prompt_spec.md` is the current walkthrough contract.
- `AUDIT.md` is the current codebase audit/reference map.

## Active regression tests

Keep these `test/` suites untouched; they are the active model-related checks.

- `test/two_step_suggestions_prompt_harness.dart` (the two-step check's test program)
- `test/regional_forms_probe_harness.dart`
- `test/partner_prompt_harness.dart`
- `test/retranslation_grade_validation.dart`
- `test/walkthrough_prompt_validation.dart`
- `test/corrected_index_reliability_probe.dart`
- `test/bare_prompt_control_test.dart`
- `test/model_comparison_harness.dart`

Deleted in build step 2.5 (24 November 2026) together with the five-stage
pipeline they measured: the `stage1_*`, `stage2_*` and `stage3_*` harnesses,
`verdict_battery_merged.dart`, `peninsular_norms_battery.dart`,
`para_destination_battery.dart`, `category_tiebreak_battery.dart`,
`pipeline_baseline_harness.dart` and `correction_consistency_harness.dart`.
Their last reports remain under `docs/archive/legacy-model-reports/`, and the
files themselves are in git history (the `main` commit after pull request 197).

## Shared benchmark fixtures

`test/shared/benchmark_fixtures.dart` holds a small, shared set of
representative Spanish inputs (short phrase, sentence/short paragraph,
paragraph, two-paragraph, and near-600-character cases, including a
CALCS-style calque case) for routine latency/request-count/token-usage/cost/
model-comparison runs — not a language-quality regression suite. Harnesses
such as the model-comparison harness can import and reuse it instead of
re-declaring their own inputs.
Its offline fixture-invariant tests live in
`test/shared/benchmark_fixtures_test.dart`.

## Archived research artifacts

The historical generated reports, prompt snapshots, and harness writeups moved
to `docs/archive/legacy-model-reports/`.

They remain available for reference, but they are no longer the current source
of truth for the app’s prompt behavior.

Active harnesses may still emit markdown reports under `docs/` when run live.
Treat those outputs as review artifacts: either archive them after inspection or
run with an output override that writes directly to
`docs/archive/legacy-model-reports/`.
