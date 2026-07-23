# Reflexive-Insertion Span-Width Harness (End-to-End)

Runs the real `runStagedCorrectionPipeline` (Stage 1/1B/1C -> Stage 2 -> position resolution -> insertion narrowing -> dedup -> Stage 3 -> corrected-range computation) against exactly the two sentences that motivated adding `stage1ReflexiveDetectionSpanish`, and reports what text the final resolved span actually covers on both the original side and the corrected side.

Model: `gpt-5.5`  
Commit: `bcf1690ab84e66b6159abe80de5431632f9ed164`  
Generated: 2026-07-22T16:06:59.666901  
Runs per case: 10

## quejo

- Text: `Quejó del ruido toda la noche.`
- Target verb (expected exact original-side span): `Quejó`
- Expected corrected phrase (expected exact corrected-side span): `Se quejó`

### Original-side span summary (10 runs, 2 error(s))

- Exact word match (span == target verb, nothing wider): 100.0% (8/8)
- Overlaps target but wider (e.g. whole sentence): 0.0% (0/8)
- Flagged something, but none of it overlaps the target verb: 0.0% (0/8)
- Clean (nothing flagged at all): 0.0% (0/8)
- Span-bucket distribution (word/phrase/clause, among target-overlapping spans): "word": 8
- Exact resolved-span distribution (target-overlapping spans): "Quejó": 8

### Corrected-side span summary (10 runs, 2 error(s))

- Exact match (corrected span == "Se quejó", nothing wider): 100.0% (8/8)
- Overlaps expected phrase but wider (e.g. whole corrected sentence): 0.0% (0/8)
- Missing the reflexive entirely (covers the verb but not "Se"): 0.0% (0/8)
- No overlap / clean (nothing highlighted on the corrected side): 0.0% (0/8)
- Span-bucket distribution (word/phrase/clause, among target-overlapping corrected spans): "phrase": 8
- Exact corrected-span distribution (target-overlapping spans): "Se quejó": 8

### Run detail

- Run 1: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)
- Run 2: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)
- Run 3: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)
- Run 4: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)
- Run 5: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)
- Run 6: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)
- Run 7: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)
- Run 8: ERROR — ChatCompletionsException: Chat completions call timed out: TimeoutException after 0:00:30.000000: Future not completed
- Run 9: ERROR — ChatCompletionsException: Chat completions call timed out: TimeoutException after 0:00:30.000000: Future not completed
- Run 10: original: "Quejó" [0, 5) (correction, word) | corrected: "Se quejó" [0, 8) (corrected, phrase)

## atrevio

- Text: `Atrevió a preguntarle directamente.`
- Target verb (expected exact original-side span): `Atrevió`
- Expected corrected phrase (expected exact corrected-side span): `Se atrevió`

### Original-side span summary (10 runs, 0 error(s))

- Exact word match (span == target verb, nothing wider): 100.0% (10/10)
- Overlaps target but wider (e.g. whole sentence): 0.0% (0/10)
- Flagged something, but none of it overlaps the target verb: 0.0% (0/10)
- Clean (nothing flagged at all): 0.0% (0/10)
- Span-bucket distribution (word/phrase/clause, among target-overlapping spans): "word": 10
- Exact resolved-span distribution (target-overlapping spans): "Atrevió": 10

### Corrected-side span summary (10 runs, 0 error(s))

- Exact match (corrected span == "Se atrevió", nothing wider): 100.0% (10/10)
- Overlaps expected phrase but wider (e.g. whole corrected sentence): 0.0% (0/10)
- Missing the reflexive entirely (covers the verb but not "Se"): 0.0% (0/10)
- No overlap / clean (nothing highlighted on the corrected side): 0.0% (0/10)
- Span-bucket distribution (word/phrase/clause, among target-overlapping corrected spans): "phrase": 10
- Exact corrected-span distribution (target-overlapping spans): "Se atrevió": 10

### Run detail

- Run 1: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 2: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 3: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 4: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 5: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 6: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 7: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 8: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 9: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)
- Run 10: original: "Atrevió" [0, 7) (correction, word) | corrected: "Se atrevió" [0, 10) (corrected, phrase)

---

## Overall summary

| Case | Runs | Errors | Exact word match | Overlap but wider | Span-bucket distribution | Corrected exact match | Corrected missing reflexive |
| --- | --- | --- | --- | --- | --- | --- | --- |
| quejo | 10 | 2 | 100.0% (8/8) | 0.0% (0/8) | "word": 8 | 100.0% (8/8) | 0.0% (0/8) |
| atrevio | 10 | 0 | 100.0% (10/10) | 0.0% (0/10) | "word": 10 | 100.0% (10/10) | 0.0% (0/10) |
