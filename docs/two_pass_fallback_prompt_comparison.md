# Fallback Naturalness Prompt Comparison (issue #110)

## Run configuration

- Naturalness model: `gpt-5.1`
- Fixture count: `5`
- Generated: 2026-08-03T17:36:05.467134Z

Each fixture below is called once under each variant, against the exact same already-correct `firstPassCorrectedText` — the only thing that differs between the two calls for the same fixture is the system prompt.

| Fixture | Current-reused outcome | Current-reused result | Candidate outcome | Candidate result |
| --- | --- | --- | --- | --- |
| clean-grammar-only-overrewrite | issue_applied_text_changed | `Había mucho tráfico ayer.` | no_issue_flagged | `Vi mucho tráfico ayer.` |
| false-friend-atendio-overrewrite | issue_applied_text_changed | `Estudió en la universidad en Madrid.` | issue_applied_text_changed | `Estudió en la universidad en Madrid.` |
| mixed-personal-a-subjunctive-overrewrite | issue_applied_text_changed | `Vi a mi profesor en la estación. Es importante que estudies.` | issue_applied_text_changed | `Vi a mi profesor en la estación, y me recordó que es importante que estudies.` |
| mixed-verb-agreement-que-overrewrite | issue_applied_text_changed | `Ellos estudian todas las noches y creo que está bien que hoy terminemos.` | issue_applied_text_changed | `Ellos estudian todas las noches, y creo que está bien que terminemos hoy.` |
| subjunctive-su-parte-overrewrite | issue_applied_text_changed | `Era necesario que enviara su informe.` | issue_applied_text_changed | `Era necesario que enviara su informe.` |

## Aggregate: unwanted change rate on already-correct text

| Variant | Changed already-correct text | Rate |
| --- | --- | --- |
| Current (reused naturalness prompt) | 5/5 | 100.0% |
| Candidate (fallback-specific prompt) | 4/5 | 80.0% |
