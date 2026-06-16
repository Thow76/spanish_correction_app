# Section 3 readiness assessment

Evaluation of the two walkthrough-prompt validation runs against the
pre-committed Section 3 thresholds. These runs were produced *after* the
Section 2 prompt tightening (explicit three-case grounding gate plus a
distractor-distinctness final check).

- Run 1: `docs/walkthrough_prompt_validation.md`
- Run 2: `docs/walkthrough_prompt_validation_run2.md`
- Divergence: `docs/walkthrough_prompt_validation_divergence.md`
- Model: `gpt-4.1-mini`
- Battery: 18 cases (8 grounding-track, 8 fallback-track, 2 edge)

## Thresholds and results

| # | Threshold | Run 1 | Run 2 | R1 | R2 |
| --- | --- | --- | --- | --- | --- |
| 1 | Grounding: ≥ 6 of 8 grounding-track cases pass (case passes if majority of its grounded chunks ground) | 7 of 8 cases (9 of 10 grounded chunks) | 7 of 8 cases (9 of 10 grounded chunks) | PASS | PASS |
| 2 | Fallback: all 4 fallback cases per language produce sensible generic distractors, no forced grounding | ES 4/4, PT 4/4 | ES 4/4, PT 4/4 | PASS | PASS |
| 3 | Edge: the 1 edge case per language produces exactly 2 chunks | ES 2, PT 2 | ES 2, PT 2 | PASS | PASS |
| 4 | Parse: ≥ 17 of 18 cases parse cleanly (valid JSON, fields present, 2 distinct distractors ≠ correct, contiguous chunk_position from 0) | 18 of 18 | 17 of 18 | PASS | PASS |
| 5 | Stability: ≥ 14/18 decomposition match across runs; ≥ 6/8 grounding-track stable per language | decomposition 17/18; grounding ES 4/4, PT 4/4 stable | (cross-run, same figures) | PASS | PASS |

All five thresholds pass on both runs. The two soft spots are within tolerance:
the grounding miss on PT-G-03 (1 of 8 cases) still leaves 7 of 8 ≥ 6, and the
single parse-cleanliness miss in run 2 (PT-F-02) leaves 17 of 18 ≥ 17. Both are
flagged in Notable observations because they are systematic, not random.

## Per-language breakdown

### Spanish

- **Grounding** — Run 1: 4 of 4 cases pass (5 of 5 grounded chunks). Run 2:
  4 of 4 cases pass (5 of 5 grounded chunks). Every targeted wrong form
  (`Quieres`, `aplicar`, `atender`, `a el banco`, `en viernes`) appeared in the
  distractors for the relevant chunk in both runs.
- **Fallback** — Run 1: 4 of 4 clean. Run 2: 4 of 4 clean. No forced grounding
  in either run. ES-F-04 ("radically wrong" attempt) surfaced `muchas naranjas`
  as a chunk-1 distractor in run 2, but that form is supplied by the corrections
  list (paired to the target chunk `tres manzanas`) and is
  part-of-speech-appropriate, so it reads as legitimate correction-based
  grounding rather than reaching into off-topic words.
- **Edge** — ES-E-01 produced exactly 2 chunks (`Voy` / `al gimnasio`) in both
  runs and grounded `a el gimnasio`. Pass.
- **Stability (grounding-track)** — 4 of 4 Spanish grounding cases stable across
  runs. All 9 Spanish cases had identical decomposition across runs.

### Portuguese

- **Grounding** — Run 1: 3 of 4 cases pass (4 of 5 grounded chunks). Run 2:
  3 of 4 cases pass (4 of 5 grounded chunks). `Quer`, `checar`, `a o banco`,
  and `em sexta` grounded in both runs. **PT-G-03 failed grounding in both
  runs** (0 of 1 grounded chunks): for target `Vou cortar o cabelo amanhã.`
  against attempt `Vou cortar el cabelo amanhã.`, the chunk `cortar o cabelo`
  got distractors `cojer cortar o cabelo` and `para um corto do cabelo` instead
  of the user's actual `el cabelo`.
- **Fallback** — Run 1: 4 of 4 clean. Run 2: 4 of 4 clean. No forced grounding
  in either run; the pre-tightening PT-F-03 over-grounding (which lifted `Eu`
  and `gosta` from the off-topic attempt) is resolved — both runs now produce
  generic distractors (`Os trens`/`O treno`, `chego`/`chegam`). PT-F-02 produced
  low-quality distractors in both runs (see observations) but did not reach into
  the attempt.
- **Edge** — PT-E-01 produced exactly 2 chunks (`Vou` / `ao mercado`) in both
  runs and grounded `a o mercado`. Pass.
- **Stability (grounding-track)** — 4 of 4 Portuguese grounding cases stable
  across runs. Note this counts PT-G-03 as stable because it failed *identically*
  in both runs. The only decomposition divergence in the battery was PT-F-02 (a
  fallback case): run 1 = 4 chunks, run 2 = 3 chunks.

## Notable observations

- **One error pattern grounds unreliably; the rest are solid.** Preposition/
  contraction (`a el banco`/`en viernes`; `a o banco`/`em sexta`),
  person/conjugation (`Quieres`; `Quer`), calque/anglicism (`aplicar para`;
  `checar`), and the Spanish false friend (`atender`) all grounded in both runs.
  The lone failure is the **Portuñol article pattern, PT-G-03 (`el cabelo`),
  which failed in both runs** — a systematic, reproducible miss, not run-to-run
  noise.
- **PT-G-03 reproduces the prompt's own worked-example distractors.** Both runs
  returned `cojer cortar o cabelo` and `para um corto do cabelo` for the
  `cortar o cabelo` chunk — these are verbatim the example distractors written
  into the Brazilian-Portuguese prompt for that exact phrase. The model is
  parroting the example instead of grounding the learner's `el cabelo`. This
  strongly suggests the worked example is overriding the grounding rule when the
  target chunk matches the example.
- **Parse miss is in run 2 only and is a distinctness violation.** PT-F-02
  chunk 0 produced two identical distractors (`Amanha` / `Amanha`), violating
  "distractors distinct from each other." Run 1 had zero shape findings. The
  earlier distractor-equals-`correct_translation` mode (seen pre-tightening) did
  not recur in either run — the new final-check instruction appears to have
  addressed that specific rule.
- **PT-F-02 is the weakest fallback case across runs.** In run 1 it used
  `Domani` (Italian) as a distractor — violating "no words from another language
  entirely"; in run 2 it produced the duplicate distractors above plus the
  invented form `vou visitaré`. The off-topic near-empty attempt (`Nao sei.`)
  consistently yields lower-quality generic distractors here.
- **Same decomposition, different distractors between runs** is common for
  ungrounded chunks (expected under non-determinism). Example: ES-F-02 "Tomorrow"
  distractors were `Mañan`/`Manaña` in run 1 and `Ayer`/`Temprano` in run 2.
  Grounded distractors, by contrast, were stable across runs.
- **`target_sentence` echo is still not verbatim.** The trailing period was
  dropped once per run (run 1 PT-G-02 `…este ano`; run 2 ES-F-04
  `…en el mercado`). Reconstruction logic must not assume an exact echo.
- **No chunk-count overflow.** No case exceeded the 3–5 chunk limit; the maximum
  observed was 4.

## Recommendation

**Option C — Borderline; review with Andrew before proceeding.**

All five thresholds pass on both runs, so there is no hard failure that forces a
return to Section 2. But the Notable observations surfaced a concern that is a
judgment call rather than a number: **PT-G-03 fails grounding in both runs**, on
grounding — the explicitly highest-risk inference in this prompt — and the
failure is **systematic, not random**. It clears threshold 1 only because the
bar tolerates up to two grounding-case misses (7 of 8 ≥ 6), and it counts as
"stable" under threshold 5 precisely because it fails the same way every time.

The failure has a clear, diagnosable cause worth a human decision: the model is
returning the prompt's *own worked-example distractors* (`cojer cortar o
cabelo`, `para um corto do cabelo`) for the `cortar o cabelo` chunk instead of
grounding the learner's `el cabelo`. Because the example in the prompt uses the
same sentence as the PT-G-03 test case, this is partly a test-design artifact —
but it also shows the worked example can override the grounding rule when a real
chunk matches it, which could recur for any sentence close to a documented
example.

Points for the decision:

- If treated as a test-design artifact (the example and the test case collide),
  the prompts are arguably ready, and the fix is to change either the worked
  example or the test sentence and confirm — a light touch.
- If treated as a genuine grounding weakness (examples can shadow grounding),
  the safer path is a Section 2 tweak: instruct that a chunk's grounded
  distractor must come from the learner's actual wrong form for that chunk even
  when a worked example exists for that phrase, then repeat Section 3.

A secondary, non-blocking concern for the same decision: PT-F-02's repeated
low-quality distractors (cross-language in run 1, duplicate in run 2). This does
not fail a threshold but is the kind of thing worth Andrew's eye before
committing to the data-model and service work.

Note: this is not Option A because the grounding miss is systematic and on the
highest-risk axis; it is not Option B because no threshold actually failed.

## Open items for Section 4 and beyond

- **Section 5 (service layer) must enforce the schema rules the prompt did not
  honor reliably:** exactly 2 distractors, distractors distinct from each other
  (failed in run 2, PT-F-02) and from `correct_translation`, and contiguous
  `chunk_position` from 0. Reject or repair on violation rather than trusting the
  model.
- **Add a cross-language / nonsense-distractor guard** (service- or prompt-side):
  `Domani` (Italian) and invented forms like `vou visitaré` slipped through.
- **Section 4 (data model) should match the produced shape** — `target_sentence`
  echo, `questions[]` with `english_stem`, `correct_translation`, `distractors`
  (length 2), `chunk_position`. Do **not** rely on `target_sentence` being a
  verbatim echo (the trailing period was dropped in both runs); reconstruct/verify
  the sentence from the ordered chunks.
- **Re-test PT-G-03 specifically** once the prompt example/test-sentence
  collision is resolved, to confirm the Portuñol article pattern grounds when it
  is not shadowed by a worked example.
- **Re-test the edge two-chunk cases (ES-E-01, PT-E-01)** once the real
  `WalkthroughQuestion` model replaces the local minimal type in the harness, to
  confirm 2-chunk handling survives the proper schema/validation path.
- **Watch PT-F-02** (off-topic near-empty attempt) for distractor quality once
  the proper validation lands — it has been the weakest case in both runs.
