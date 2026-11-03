# Two-Pass Work: Existing Correction Pipeline Regression Check

Issue: [#40](https://github.com/Thow76/spanish_correction_app/issues/40)

Branch base: `correction_pipeline_refactor`

Scope: run the focused, non-live existing correction pipeline tests and
confirm the two-pass work (issues #27-#39) hasn't regressed them. No
behavior changes.

## Commands Run

```bash
flutter test test/features/corrections/data/staged_correction_pipeline_test.dart
flutter test test/features/corrections/domain
```

## Results

```text
flutter test test/features/corrections/data/staged_correction_pipeline_test.dart
10/10 passing — 00:00 +10: All tests passed!

flutter test test/features/corrections/domain
169/169 passing — 00:01 +169: All tests passed!
```

Zero failures in either run.

## Why This Was Expected To Pass

Every issue in this two-pass chain (#27-#39) added new files
(`naturalness_issue.dart`, `naturalness_review.dart`,
`naturalness_merge.dart`, `naturalness_correction_mapper.dart`,
`naturalness_review_client.dart`, `two_pass_correction_pipeline.dart`, and
their tests) rather than modifying the existing staged pipeline's own
files (`staged_correction_pipeline.dart`, `stage1_detection_client.dart`,
`stage2_categorization_client.dart`, `stage3_feedback_client.dart`, or any
`domain/` file `staged_correction_pipeline.dart` already depended on).
`runStagedCorrectionPipeline` is not called by any of the new two-pass
code except as an input to `runTwoPassCorrectionPipeline` (issue #35/#39)
— it is invoked exactly as it always was, with no changes to its own
behavior. This regression check confirms that expectation held.

## Pre-Existing, Unrelated Findings (Not This Work)

`flutter analyze` (full project) reports 6 pre-existing `info`-level
findings, all in test harness files this refactor never touched:

```text
test/naturalness_model_comparison_harness.dart:407:1  — library_private_types_in_public_api
test/naturalness_model_comparison_harness.dart:571:1  — library_private_types_in_public_api
test/naturalness_model_comparison_harness.dart:573:12 — library_private_types_in_public_api
test/shared/benchmark_fixtures.dart:206:9  — use_super_parameters
test/shared/benchmark_fixtures.dart:261:9  — use_super_parameters
test/shared/benchmark_fixtures.dart:318:9  — use_super_parameters
```

These are lint-level `info`s (not warnings or errors), pre-date this
branch's two-pass work, and are unrelated to it — noted here per this
issue's acceptance criteria ("any pre-existing failures are documented
separately from this work"), not fixed as part of it.

No behavior changes were made as part of this issue.
