# Current Spanish Correction Prompt Audit

Issue: [#5](https://github.com/Thow76/spanish_correction_app/issues/5)

Branch base: `correction_pipeline_refactor`

Scope: documentation only. This audit does not change prompts, model behavior,
pipeline flow, span/highlighting logic, tests, or UI code.

## Live Correction Path

The app's live Spanish correction path is:

1. `OpenAiCorrectionService.correctText(text, Language.spanish)`
2. `_correctSpanishTextViaStagedPipeline(text)`
3. `runStagedCorrectionPipeline(...)`
4. `callStage1AndMergeFlaggedPhrases(...)`
5. `callStage2Categorization(...)`, only when Stage 1/1B/1C return flagged phrases
6. local positioning, insertion narrowing, span-scope trimming, deduplication, and verdict splitting
7. `callStage3Feedback(...)`, only when Stage 2 leaves error or dialectal candidates
8. local corrected-text reconstruction from ranged error items

The old single-call Spanish correction prompt is not present. `PromptBuilder`
throws for `PromptBuilder.correctionSystemPrompt(Language.spanish)`, so Spanish
corrections do not use the legacy `/v1/responses` correction prompt path.

## Live Stage Prompts

| Stage | Prompt constant | Location | Response shape | Role |
| --- | --- | --- | --- | --- |
| Stage 1 | `stage1DetectionDialectSpanish` | `lib/core/services/prompts/correction_prompt.dart` | JSON array of strings | General detection, including dialect differences |
| Stage 1B | `stage1RedundancyDetectionSpanish` | `lib/core/services/prompts/correction_prompt.dart` | JSON array of strings | Dedicated redundant subject/emphatic pronoun detection |
| Stage 1C | `stage1ReflexiveDetectionSpanish` | `lib/core/services/prompts/correction_prompt.dart` | JSON array of strings | Dedicated missing obligatory reflexive pronoun detection |
| Stage 2 | `stage2CategorizationSpanish` | `lib/core/services/prompts/correction_prompt.dart` | JSON array of objects | Categorizes flagged phrases, chooses corrected phrase, verdict, category, and optional span scope |
| Stage 3 | `stage3FeedbackSpanish` | `lib/core/services/prompts/correction_prompt.dart` | JSON array of objects | Adds short explanations for error and dialectal candidates |

All five prompt calls use `OpenAiChatCompletionsClient.complete()` and the
`/v1/chat/completions` endpoint. The client sends a two-message request:
`system` is the prompt constant and `user` is the submitted text or stage input.

## Early Exits

The staged pipeline has two successful early exits:

- Stage 1 early exit: if Stage 1, Stage 1B, and Stage 1C return no flagged
  phrases, the response returns the submitted text unchanged and does not call
  Stage 2 or Stage 3.
- Stage 2 early exit: if Stage 2 returns no `error` or `dialectal` candidates
  after local filtering/splitting, the response returns the submitted text
  unchanged and does not call Stage 3.

These exits are important to cost and latency analysis because a clean input can
make three API requests, while a full pipeline run can make five.

## Related Spanish Prompts Outside First-Pass Correction

These prompts are Spanish-language and production-reachable, but they are not
the first-pass correction prompts:

| Prompt | Location | Caller | Purpose |
| --- | --- | --- | --- |
| `_gradingPromptSpanish` | `lib/core/services/prompt_builder.dart` | `OpenAiCorrectionService.gradeRetranslation()` | Grades a learner's retranslation attempt against an expected answer |
| `_longExplanationPromptSpanish` | `lib/core/services/prompt_builder.dart` | `OpenAiCorrectionService.generateLongExplanation()` | Generates longer plain-text explanation for a saved correction |
| `_structuredExplanationPromptSpanish` | `lib/core/services/prompt_builder.dart` | `OpenAiCorrectionService.generateStructuredExplanation()` | Generates structured saved-explanation JSON |
| `promptPhraseSystemPrompt(Language.spanish)` | `lib/core/services/prompt_builder.dart` | `OpenAiCorrectionService.generatePromptPhrase()` | Translates corrected Spanish sentence to English and selects a highlight span |
| `_walkthroughQuestionPromptSpanish` | `lib/core/services/prompt_builder.dart` | walkthrough generation path | Builds multiple-choice walkthrough questions |

These should not be treated as the current Spanish correction pipeline, but they
do matter for downstream learning flows after a correction is saved or used in a
retranslation/walkthrough feature.

## Prompt Wording That Appears Important To Preserve

Stage 1 family:

- The exact-quote JSON-array contract is important because later stages resolve
  positions mechanically against the submitted text.
- Stage 1B is deliberately narrow. Existing comments and harnesses indicate it
  was kept separate because earlier attempts to fold span-cleanliness guidance
  into general detection regressed other detection cases.
- Stage 1C is also deliberately narrow. It exists to catch missing obligatory
  reflexives while keeping the general detection prompt untouched.
- Stage 1B and Stage 1C both ask for the narrowest possible quote: pronoun only
  for redundancy, verb only for missing reflexive. That protects downstream span
  width and highlighting.

Stage 2:

- The `occurrence` field avoids asking the model for character offsets. This is
  important because the app resolves positions locally and because Spanish
  accents/diacritics previously exposed index reliability problems.
- `verdict` separates `error`, `dialectal`, and `not_an_error`. This allows
  Stage 1 to over-flag suspicious phrases while Stage 2 can decline to correct
  valid language.
- The dialectal restraint rule is important: ordinary regional preferences such
  as voseo, `ustedes/vosotros`, common tense preferences, or `voy/volví para
  casa` should not automatically become errors.
- The calque test is important: a phrase is an error on calque grounds only if
  no established variety uses it natively for that meaning.
- `span_scope` is important for Natural Language corrections because local
  highlighting needs to know whether only the exact changed piece or the full
  phrase should remain highlighted.
- The explicit reflexive/non-reflexive rule is important because it narrows
  missing-reflexive cases to the specific sentence, not the verb in isolation.

Stage 3:

- The dialectal branch explicitly forbids saying "wrong", "error", or
  "incorrect". That protects the user-facing tone for regional forms.
- The short explanation tone is intentionally informal and tutor-like, which is
  part of the app experience.
- The "common but proscribed" explanation rule appears intended to avoid giving
  misleadingly absolute feedback for widespread but non-standard usage.

## Prompt Wording That May Cause Problems

Stage 1 general detection may be too broad:

- It asks the model to identify anything a native speaker would consider wrong
  or would not naturally say.
- It also says to flag standard dialect differences.

That wording can produce useful recall, but it means Stage 1 may call attention
to naturalness, style, or regional differences that are not objective errors.
Stage 2 can downgrade those to `not_an_error`, but the extra Stage 2 request is
still paid for. This is a latency/cost risk, not necessarily a correctness bug.

Stage 1 and Stage 2 have a built-in scope tension:

- Stage 1 tells the model to flag dialect differences.
- Stage 2 says ordinary regional preferences should usually be `not_an_error`
  and reserves `dialectal` for real risk of confusion or offense.

That may be intentional: broad detection followed by narrower adjudication. It
is still worth making explicit before designing any simplified prompt, because a
single-pass replacement would need to decide which side of that tension it wants.

Stage 2 is very long and policy-heavy:

- It carries category definitions, boundary rules, dialectal policy, calque
  policy, span-scope rules, and worked examples in one prompt.
- This likely preserves many hard-won fixes, but it also increases input tokens
  and gives the model many competing instructions to satisfy.

This is one of the main prompt-level contributors to cost in a full pipeline
run. It should not be simplified inside this issue, but it is a candidate for
future prompt experiments.

Stage 2 parser enforcement is looser than the prompt contract in one respect:

- The prompt says `span_scope` applies only when category is Natural Language
  and every other category omits it.
- The parser accepts any valid `span_scope` string regardless of category and
  does not enforce the category-to-span-scope relationship.

This is not a prompt change request. It is a contract/documentation observation
for any later mechanical validation issue.

Stage 3 does not receive the full submission text:

- Stage 3 receives the correction objects, not the complete learner submission.
- That keeps the feedback call smaller, but it may limit explanations where the
  correction depends heavily on wider context.

Existing comments already frame this as an open question rather than an
oversight.

## Stale Or Contradictory Comments

Several comments now appear stale after the Spanish correction path was wired
into the staged pipeline:

- `staged_correction_pipeline.dart` still says the staged pipeline is not called
  from `correctText()` or any live route.
- `openai_chat_completions_client.dart` still says the chat-completions client is
  not wired into `correctText()` or any live route.
- In `correction_prompt.dart`, the headers for Stage 1 dialect, Stage 1B,
  Stage 2, and Stage 3 still say "experimental, not wired into any live path" or
  that `OpenAiCorrectionService` does not read them.

The code path contradicts those comments. For example, `stage1_detection_client`
uses `stage1DetectionDialectSpanish`, `stage1RedundancyDetectionSpanish`, and
`stage1ReflexiveDetectionSpanish`; `stage2_categorization_client` uses
`stage2CategorizationSpanish`; and `stage3_feedback_client` uses
`stage3FeedbackSpanish`.

This audit does not update those comments because issue #5 is prompt-audit only.
A future documentation-cleanup issue could safely correct them without changing
prompt behavior.

## Existing Evidence And Harness Context

Current active harnesses and archived reports show why the prompt suite became
specialized:

- `test/stage1_detection_harness.dart` and
  `test/stage1_detection_dialect_harness.dart` cover general Stage 1 detection.
- `test/stage1_redundancy_pass_harness.dart` and
  `test/stage1_redundancy_model_comparison_harness.dart` focus on repeated
  subject/emphatic pronoun detection.
- `test/stage1_reflexive_detection_harness.dart` and
  `test/stage1_reflexive_span_width_harness.dart` focus on missing reflexive
  detection and resulting span width.
- `test/stage2_categorization_harness.dart`,
  `test/stage2_span_scope_harness.dart`, and `test/verdict_battery_merged.dart`
  cover verdict, category, dialectal, para-destination, and span-scope behavior.
- `test/stage3_feedback_harness.dart` covers explanation behavior.
- `test/correction_consistency_harness.dart` exercises the live correction
  service path for consistency but is not a prompt inventory.
- `test/pipeline_baseline_harness.dart` is the current baseline harness for
  staged-pipeline latency/tokens/cost observability.
- `test/model_comparison_harness.dart` is a standalone simplified-prompt
  comparison harness and should not be mistaken for the live correction prompt.

Historical markdown reports under `docs/archive/legacy-model-reports/` remain
useful as research context, but `docs/model-research-index.md` states they are
not the current source of truth.

## Recommendations For Future Work

No prompt changes should be made as part of issue #5.

Future standalone prompt-design or architecture work should consider:

- testing a reduced first-pass prompt that corrects only grammar, spelling, and
  punctuation, separate from naturalness, word choice, explanation, and
  dialectal feedback
- preserving the local occurrence/range reconstruction approach rather than
  returning character indices from the model
- deciding explicitly whether broad Stage 1 recall is worth the extra Stage 2
  calls it can cause
- preserving the dedicated redundancy and reflexive protections unless a
  simplified prompt proves it can match them
- treating stale comments as a separate documentation-cleanup task
- using issue #6 observability and issue #11 fixtures before making an
  architecture decision in issue #4
