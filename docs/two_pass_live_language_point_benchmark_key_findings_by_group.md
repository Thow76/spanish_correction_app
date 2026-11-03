# Two-Pass Live Language-Point Benchmark: Key Findings By Group

Source reports:

- `docs/two_pass_live_language_point_benchmark_findings.md`
- `docs/two_pass_integration_harness.md`
- PR #94: https://github.com/Thow76/spanish_correction_app/pull/94

## How To Read This

For this summary:

- `pass` means the fixture scored `correct_fix` or `acceptable_no_change`.
- `not pass` means the fixture scored `partial_fix`, `ambiguous`, `overcorrection`, `missed_issue`, or `error`.
- `Overall group status` says whether the benchmark group itself should be treated as cleanly passed, failed, or needing review.
- `First-pass signal` says what the simple first-pass model appears to be doing.
- `Naturalness / fallback signal` says what the second pass or fallback path appears to be doing.

Across the full 85-fixture run there were 0 API or parsing errors, 56 `correct_fix` results, 11 `acceptable_no_change` results, 11 `ambiguous` results, 4 `partial_fix` results, 3 `overcorrection` results, and 0 `missed_issue` results. The clear pass rate was 67/85, or 78.8%. The not-pass rate was 18/85, or 21.2%.

## Accents / Diacritics

| Item | Finding |
| --- | --- |
| Result | 5/6 pass; 1/6 not pass |
| Overall group status | Needs review |
| First-pass signal | Passed the accent-correction task. The first pass corrected the missing accent in the not-pass case. |
| Naturalness / fallback signal | Did not clearly pass. It rewrote the already-correct first-pass output. |
| Practical meaning | This is not an accent-correction failure. It is a second-pass restraint problem. |

The not-pass case was `clean-grammar-only`: expected `Vi mucho tráfico ayer.`, first pass produced `Vi mucho tráfico ayer.`, but the final output became `Había mucho tráfico ayer.`.

## Collocations / Strong Calques

| Item | Finding |
| --- | --- |
| Result | 6/6 pass; 0/6 not pass |
| Overall group status | Pass |
| First-pass signal | Mixed but acceptable for final-output testing. The first pass corrected some collocation cases itself and left others for naturalness. |
| Naturalness / fallback signal | Passed. The final outputs matched the intended corrections across the group. |
| Practical meaning | The two-pass system handles this group well, although ownership is not perfectly clean because the first pass sometimes fixes collocations. |

This group is a clear final-output pass. The only caution is architectural: collocation correction sometimes happened in the first pass even though the naturalness pass is the intended owner for this kind of issue.

## Accents / Diacritics + Collocations / Strong Calques (Independent Spans)

| Item | Finding |
| --- | --- |
| Result | 1/1 pass; 0/1 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It handled the mechanical accent issue. |
| Naturalness / fallback signal | Passed. It handled the separate collocation issue. |
| Practical meaning | Independent first-pass and naturalness corrections can merge successfully when the spans do not interfere with each other. |

## Verb Morphology Overlapping Collocations / Strong Calques

| Item | Finding |
| --- | --- |
| Result | 1/1 pass; 0/1 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It fixed the spelling/morphology part. |
| Naturalness / fallback signal | Passed. The fallback resolved the overlapping collocation span correctly. |
| Practical meaning | The fallback path works for this tested overlap case. |

## Ambiguous / Repeated Span Safety

| Item | Finding |
| --- | --- |
| Result | 0/1 pass; 1/1 not pass |
| Overall group status | Fail |
| First-pass signal | Passed by leaving the already-valid input unchanged. |
| Naturalness / fallback signal | Failed. It rewrote valid repeated wording that should have remained unchanged. |
| Practical meaning | Ambiguous naturalness spans are risky when the correct action is no change. |

The failing case was `ambiguous-naturalness-span`: expected unchanged `Vi mucho tráfico, y luego vi más tráfico.`, but final output became `Había mucho tráfico, y luego había todavía más.`.

## Gender / Number Agreement

| Item | Finding |
| --- | --- |
| Result | 5/5 pass; 0/5 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It corrected the agreement errors reliably. |
| Naturalness / fallback signal | Passed. No harmful second-pass rewrite was recorded. |
| Practical meaning | This group is a clean pass for the current benchmark. |

## Verb Agreement / Morphology

| Item | Finding |
| --- | --- |
| Result | 5/5 pass; 0/5 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It corrected verb agreement and morphology errors reliably. |
| Naturalness / fallback signal | Passed. No harmful second-pass rewrite was recorded. |
| Practical meaning | This group is a clean pass for the current benchmark. |

## Required Prepositions

| Item | Finding |
| --- | --- |
| Result | 5/5 pass; 0/5 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It corrected required preposition errors reliably. |
| Naturalness / fallback signal | Passed. No harmful second-pass rewrite was recorded. |
| Practical meaning | This group is a clean pass for the current benchmark. |

## Articles / Determiners

| Item | Finding |
| --- | --- |
| Result | 3/5 pass; 2/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Partially passed. It handled several article cases, but missed one required insertion in `article-cita-medico`. |
| Naturalness / fallback signal | Needs review. One case duplicated an already-correct article insertion in the final output. |
| Practical meaning | Article insertions are a real weak spot, especially when more than one insertion or merge interaction is involved. |

Not-pass cases:

- `article-la-tienda`: first pass produced the expected `Fui a la tienda después del trabajo.`, but final output became `Fui a la la tienda después del trabajo.`
- `article-cita-medico`: expected `Tengo una cita con el médico mañana.`, but output only added `el médico`, producing `Tengo cita con el médico mañana.`

## Subjunctive / Mood

| Item | Finding |
| --- | --- |
| Result | 4/5 pass; 1/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Mostly passed. It made the intended subjunctive correction in the not-pass case. |
| Naturalness / fallback signal | Did not clearly pass. It changed a content word after the grammar fix was already correct. |
| Practical meaning | Subjunctive correction looks strong, but second-pass restraint still needs attention. |

The not-pass case was `subj-enviara`: expected `Era necesario que enviara su parte.`, first pass produced that exact output, but final output became `Era necesario que enviara su informe.`

## Required Additions / Omissions

| Item | Finding |
| --- | --- |
| Result | 5/5 pass; 0/5 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It handled required additions and omissions reliably in this group. |
| Naturalness / fallback signal | Passed. No harmful second-pass rewrite was recorded. |
| Practical meaning | This group is a clean pass for the current benchmark. |

## Unnecessary Extras / Deletions

| Item | Finding |
| --- | --- |
| Result | 3/5 pass; 2/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Mixed. It did not always remove the repeated pronoun itself. |
| Naturalness / fallback signal | Possibly acceptable, but not scored as a clear pass. It removed both subject pronouns in two cases. |
| Practical meaning | These may be valid Spanish alternatives rather than true defects, but they need manual review and acceptable-alternative handling. |

Not-pass cases:

- `delete-repeated-ellos-visitaron`: expected to keep the first `Ellos`, but final output dropped the subject pronoun entirely.
- `delete-repeated-nosotros`: expected to keep the first `Nosotros`, but final output dropped the subject pronoun entirely.

## Ser / Estar / Haber

| Item | Finding |
| --- | --- |
| Result | 5/5 pass; 0/5 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It handled required corrections and no-change cases correctly. |
| Naturalness / fallback signal | Passed. No harmful second-pass rewrite was recorded. |
| Practical meaning | This group is a clean pass for the current benchmark. |

## Impersonal Haber / Se

| Item | Finding |
| --- | --- |
| Result | 5/5 pass; 0/5 not pass |
| Overall group status | Pass |
| First-pass signal | Passed. It handled impersonal `haber` and `se` cases reliably. |
| Naturalness / fallback signal | Passed. No harmful second-pass rewrite was recorded. |
| Practical meaning | This group is a clean pass for the current benchmark. |

## False Friends / Word Choice

| Item | Finding |
| --- | --- |
| Result | 2/5 pass; 3/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Mixed. It sometimes made useful lexical corrections, including one exact expected correction, but this is not meant to be its main job. |
| Naturalness / fallback signal | Mixed. It sometimes produced plausible alternatives, but it also re-edited an already-correct first-pass fix. |
| Practical meaning | This group is weak for benchmark scoring and needs acceptable alternatives plus better restraint around already-correct fixes. |

Not-pass cases:

- `false-friend-atendio-universidad`: first pass produced expected `Asistió a la universidad en Madrid.`, but final output became `Estudió en la universidad en Madrid.`
- `false-friend-aplico-trabajo`: final output `Se postuló a un trabajo.` may be valid, but differs from expected `Solicitó un trabajo.`
- `false-friend-embarazado`: final output avoided the false friend, but did not match the expected meaning closely enough.

## Phrase-Level Naturalness

| Item | Finding |
| --- | --- |
| Result | 2/5 pass; 3/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Not the main owner. In some cases it left the issue for naturalness, as intended. |
| Naturalness / fallback signal | Mixed. It produced some acceptable corrections, but also returned slash-separated alternatives instead of one final correction. |
| Practical meaning | Naturalness quality needs manual review, and the output format must be tightened so it gives one correction rather than multiple options. |

Not-pass cases:

- `naturalness-corriendo-tarde`: final `Voy a llegar tarde a la reunión.` is probably acceptable, but differs from the expected benchmark answer.
- `naturalness-pasar-buen-tiempo`: final output gave slash-separated alternatives.
- `naturalness-puedo-tener-cerveza`: final output gave slash-separated alternatives.

## Valid Regional / Should Not Flag

| Item | Finding |
| --- | --- |
| Result | 4/5 pass; 1/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Mostly passed, but failed one regional no-change boundary case. |
| Naturalness / fallback signal | Passed in the sense that it did not repair the first-pass overcorrection. The issue originated in the first pass. |
| Practical meaning | The first-pass prompt needs stronger restraint for valid regional Spanish. |

The not-pass case was `regional-voy-para-casa`: expected unchanged `Voy para casa ahora mismo.`, but first pass and final output became `Voy para la casa ahora mismo.`

## Already Correct / Do Not Tinker

| Item | Finding |
| --- | --- |
| Result | 4/5 pass; 1/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Passed. It left the not-pass case unchanged. |
| Naturalness / fallback signal | Failed one no-change case by rewriting already-correct text and returning slash-separated alternatives. |
| Practical meaning | The naturalness pass needs stronger no-change restraint and should not output multiple alternatives as final text. |

The not-pass case was `correct-tomar-foto`: expected unchanged `Necesito tomar una foto del documento.`, but final output became `Necesito sacar una foto / hacer una foto del documento.`

## Mixed Operations

| Item | Finding |
| --- | --- |
| Result | 2/5 pass; 3/5 not pass |
| Overall group status | Needs review |
| First-pass signal | Often passed the objective correction part. In two ambiguous cases it produced the expected corrected text before naturalness/fallback changed it. |
| Naturalness / fallback signal | Mixed. It sometimes changed sentence meaning, structure, punctuation, or coordination beyond the expected correction. |
| Practical meaning | Mixed cases expose interaction problems that single-error cases do not. They should remain in the benchmark as stress tests. |

Not-pass cases:

- `mixed-preposition-and-redundant-pronoun`: final output fixed the core issues but removed the conjunction `y`.
- `mixed-personal-a-and-subjunctive`: first pass produced the expected correction, but final output changed meaning and structure.
- `mixed-verb-agreement-and-missing-que`: first pass produced the expected correction, but final output changed the second clause.

## Practical Next Steps

The benchmark evidence supports continuing the POC, but the next work should be targeted:

1. Tighten first-pass restraint for valid regional and already-correct text.
2. Tighten naturalness restraint so it does not rewrite already-correct first-pass fixes.
3. Prohibit slash-separated alternatives in final corrected text.
4. Add acceptable alternatives for valid Spanish outputs that differ from the single expected benchmark answer.
5. Keep mixed-operation cases as stress tests because they reveal interactions between first pass, naturalness, merge, and fallback.
