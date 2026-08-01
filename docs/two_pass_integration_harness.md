# Two-Pass Live Integration Harness

## Run configuration

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture count: `5`
- Generated: 2026-07-31T23:48:11.458195Z

## Pricing

Verified estimated costs use:
- `gpt-4.1`: input=2.0 USD, output=8.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5.1`: input=1.25 USD, output=10.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## clean-grammar-only

- Input text: `Vi mucho trafico ayer.`
- Note: First-pass-only fixable error (missing accent); no naturalness issue anywhere. Expect: no conflict, no fallback.
- First-pass corrected text: `Vi mucho tráfico ayer.`
- Naturalness on original text: trafico -> tráfico
- Naturalness on first-pass corrected text: Vi mucho tráfico ayer. -> Había mucho tráfico ayer.
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Había mucho tráfico ayer.`
- Final correction count: 2

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 4236 | 3204 | $0.006978 |
| Naturalness (original) | 2557 | 390 | $0.001441 |
| Naturalness (first-pass corrected) | 1740 | 387 | $0.001420 |
| **Total** | 8533 | 3981 | $0.009839 |

## naturalness-only

- Input text: `Voy a hacer una decisión importante.`
- Note: No first-pass-fixable error; a naturalness calque only. Expect: naturalness-on-original and naturalness-on-corrected agree (the text is identical either way), no conflict.
- First-pass corrected text: `Voy a tomar una decisión importante.`
- Naturalness on original text: hacer una decisión -> tomar una decisión
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Voy a tomar una decisión importante.`
- Final correction count: 1

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 3005 | 3238 | $0.007202 |
| Naturalness (original) | 1672 | 381 | $0.001342 |
| Naturalness (first-pass corrected) | 1112 | 311 | $0.000643 |
| **Total** | 5789 | 3930 | $0.009187 |

## grammar-and-naturalness-independent

- Input text: `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.`
- Note: Spatially separate first-pass fix ("devia" -> "debía") and naturalness calque ("hizo una decisión"). Expect: the naturalness span is untouched by the first pass, so both variants agree; no conflict.
- First-pass corrected text: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- Naturalness on original text: hizo una decisión importante -> tomó una decisión importante
- Naturalness on first-pass corrected text: (none)
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.`
- Final correction count: 2

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 3251 | 3390 | $0.008028 |
| Naturalness (original) | 1424 | 375 | $0.001213 |
| Naturalness (first-pass corrected) | 817 | 319 | $0.000652 |
| **Total** | 5492 | 4084 | $0.009893 |

## grammar-overlaps-naturalness

- Input text: `Ayer iso una decisión importante.`
- Note: The first-pass fix ("iso" -> "hizo") sits inside the exact naturalness calque span ("hizo una decisión") — the case the fallback exists for. Expect: naturalness-on-original flags the pre-correction wording (conflict against firstPassCorrectedText), naturalness-on-corrected flags the post-correction wording (resolves cleanly) — fallback used.
- First-pass corrected text: `Ayer hizo una decisión importante.`
- Naturalness on original text: iso una decisión -> tomó una decisión
- Naturalness on first-pass corrected text: hizo una decisión -> tomó una decisión
- Conflict (parallel merge had a skipped edit): true
- Fallback used: true
- Final merged output: `Ayer tomó una decisión importante.`
- Final correction count: 2

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 3035 | 3213 | $0.006984 |
| Naturalness (original) | 1859 | 368 | $0.001213 |
| Naturalness (first-pass corrected) | 1927 | 375 | $0.001283 |
| **Total** | 6821 | 3956 | $0.009479 |

## ambiguous-naturalness-span

- Input text: `Vi mucho tráfico, y luego vi más tráfico.`
- Note: No first-pass fix needed; naturalness may flag a bare repeated word ambiguously on both passes. Expect: possible conflict that the fallback does not resolve either — the "still unsafe after a rerun" case from issue #37, observed live rather than simulated.
- First-pass corrected text: `Vi mucho tráfico, y luego vi más tráfico.`
- Naturalness on original text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico, y luego todavía más.
- Naturalness on first-pass corrected text: Vi mucho tráfico, y luego vi más tráfico. -> Había mucho tráfico y luego todavía más.
- Conflict (parallel merge had a skipped edit): false
- Fallback used: false
- Final merged output: `Había mucho tráfico, y luego todavía más.`
- Final correction count: 1

| Phase | Latency (ms) | Total tokens | Est. cost (USD) |
| --- | --- | --- | --- |
| First pass | 565 | 804 | $0.001626 |
| Naturalness (original) | 2678 | 429 | $0.001796 |
| Naturalness (first-pass corrected) | 2352 | 410 | $0.001606 |
| **Total** | 5595 | 1643 | $0.005028 |

---

## Overall summary

| Fixtures | Errors | Conflicts | Fallbacks used | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 5 | 0 | 4 | 4 | 32230 | 17594 | $0.043427 |
