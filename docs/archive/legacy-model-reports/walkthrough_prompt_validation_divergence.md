# Walkthrough Prompt Validation — Run Divergence

Compares two runs of the identical 18-case battery to check the stability of chunk decomposition and grounding behavior across non-deterministic LLM outputs.

- Run 1 (reviewed): `docs/walkthrough_prompt_validation.md`
- Run 2: `docs/walkthrough_prompt_validation_run2.md`
- Generated (UTC): 2026-06-16T18:58:08.198689Z

## Summary

| Test case | R1 chunks | R2 chunks | Chunk count match | R1 grounding | R2 grounding | Grounding match | Parse match | Divergence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ES-G-01 | 3 | 3 | yes | 2 of 2 | 2 of 2 | yes | yes | no |
| ES-G-02 | 4 | 4 | yes | 1 of 1 | 1 of 1 | yes | yes | no |
| ES-G-03 | 3 | 3 | yes | 1 of 1 | 1 of 1 | yes | yes | no |
| ES-G-04 | 4 | 4 | yes | 1 of 1 | 1 of 1 | yes | yes | no |
| ES-F-01 | 3 | 3 | yes | n/a | n/a | n/a | yes | no |
| ES-F-02 | 4 | 4 | yes | n/a | n/a | n/a | yes | no |
| ES-F-03 | 3 | 3 | yes | n/a | n/a | n/a | yes | no |
| ES-F-04 | 3 | 3 | yes | n/a | n/a | n/a | yes | no |
| ES-E-01 | 2 | 2 | yes | 1 of 1 | 1 of 1 | yes | yes | no |
| PT-G-01 | 3 | 3 | yes | 2 of 2 | 2 of 2 | yes | yes | no |
| PT-G-02 | 4 | 4 | yes | 1 of 1 | 1 of 1 | yes | yes | no |
| PT-G-03 | 3 | 3 | yes | 0 of 1 | 0 of 1 | yes | yes | no |
| PT-G-04 | 4 | 4 | yes | 1 of 1 | 1 of 1 | yes | yes | no |
| PT-F-01 | 3 | 3 | yes | n/a | n/a | n/a | yes | no |
| PT-F-02 | 4 | 3 | no | n/a | n/a | n/a | yes | yes |
| PT-F-03 | 3 | 3 | yes | n/a | n/a | n/a | yes | no |
| PT-F-04 | 3 | 3 | yes | n/a | n/a | n/a | yes | no |
| PT-E-01 | 2 | 2 | yes | 1 of 1 | 1 of 1 | yes | yes | no |

## PT-F-02

Diverged on: chunk count.

| chunk_position | run 1 chunk | run 2 chunk |
| --- | --- | --- |
| 0 | Amanhã | Amanhã |
| 1 | vou | vou visitar |
| 2 | visitar | a minha avó |
| 3 | a minha avó | — |

Run 2 produced a 3-chunk decomposition where run 1 produced 4.

## Stability summary

- Total test cases run: 18
- Test cases with identical chunk decomposition across runs: 17 of 18
- Test cases where grounding behavior was stable across runs: 8 of 8
- Test cases where both runs parsed successfully: 18 of 18
- Test cases with zero divergence on any axis: 17 of 18

