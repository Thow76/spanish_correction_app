# Model Research Index

This repository keeps the current prompt/spec conclusions and archives the
historical trial-and-error reports separately.

## Retained conclusions

- `docs/correction_prompt_issues_and_solutions.md` tracks the current correction
  prompt decisions, including the standalone Portuguese prompt and the
  retranslation `is_related` gate.
- `docs/current_spanish_correction_prompt_audit.md` documents the current live
  Spanish staged correction prompts and prompt-risk wording without changing
  prompt behavior.
- `docs/walkthrough_prompt_spec.md` is the current walkthrough contract.
- `AUDIT.md` is the current codebase audit/reference map.

## Active regression tests

Keep these `test/` suites untouched; they are the active model-related checks.

- `test/stage1_detection_harness.dart`
- `test/stage1_detection_dialect_harness.dart`
- `test/stage1_reflexive_detection_harness.dart`
- `test/stage1_reflexive_span_width_harness.dart`
- `test/stage1_redundancy_pass_harness.dart`
- `test/stage1_redundancy_model_comparison_harness.dart`
- `test/stage1_stage2_chained_harness.dart`
- `test/stage2_categorization_harness.dart`
- `test/stage2_span_scope_harness.dart`
- `test/stage3_feedback_harness.dart`
- `test/verdict_battery_merged.dart`
- `test/retranslation_grade_validation.dart`
- `test/walkthrough_prompt_validation.dart`
- `test/correction_consistency_harness.dart`
- `test/corrected_index_reliability_probe.dart`
- `test/peninsular_norms_battery.dart`
- `test/para_destination_battery.dart`
- `test/category_tiebreak_battery.dart`
- `test/bare_prompt_control_test.dart`
- `test/model_comparison_harness.dart`
- `test/pipeline_baseline_harness.dart`

## Archived research artifacts

The historical generated reports, prompt snapshots, and harness writeups moved
to `docs/archive/legacy-model-reports/`.

They remain available for reference, but they are no longer the current source
of truth for the app’s prompt behavior.

Active harnesses may still emit markdown reports under `docs/` when run live.
Treat those outputs as review artifacts: either archive them after inspection or
run with an output override that writes directly to
`docs/archive/legacy-model-reports/`.
