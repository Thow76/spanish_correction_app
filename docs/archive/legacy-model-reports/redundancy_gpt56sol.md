# Stage 1 Redundancy Model-Comparison Harness

Model: `gpt-5.6-sol`  
Prompt: `stage1DetectionDialectSpanish`  
Commit: `e370e9fa8f22c96f32927b55cd22eb1987416c32`  
Generated: 2026-07-18T23:42:25.937618  
Runs per case: 10

## ES-6-redundant-yo

- Text: `Yo fui a casa, yo estudié, y yo hice la cena.`
- Redundant pronoun: `yo`
- Note: Text/id copied verbatim from test/stage1_detection_harness.dart's ES-6-redundant-pronoun. Spanish is pro-drop; repeating "yo" before every verb is grammatical but unnatural.

### Summary (10 runs, 1 error(s))

- Flag rate: 66.7% (6/9)
- Span-bucket distribution (word/phrase/clause, among flagged spans): "clause": 5, "phrase": 1
- Exact flagged-span distribution: "Yo fui a casa, yo estudié, y yo hice la cena.": 1, "yo estudié, y": 1, "yo estudié, y yo hice": 1, "yo estudié, y yo hice la cena": 3

### Run detail

- Run 1: flagged: "yo estudié, y yo hice la cena"
- Run 2: flagged: "Yo fui a casa, yo estudié, y yo hice la cena."
- Run 3: flagged: "yo estudié, y yo hice"
- Run 4: flagged: "yo estudié, y yo hice la cena"
- Run 5: flagged: "yo estudié, y"
- Run 6: flagged: "yo estudié, y yo hice la cena"
- Run 7: flagged: ", y"
- Run 8: flagged: ", y"
- Run 9: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 10: flagged: "estudié, y"

## ST-R2-redundant-nosotros

- Text: `Nosotros vamos al cine, nosotros comemos palomitas y nosotros volvemos a casa.`
- Redundant pronoun: `nosotros`
- Note: Text/id copied verbatim from test/stage1_detection_harness.dart's ST-R2-redundant-pronoun. Same class as ES-6, plural subject.

### Summary (10 runs, 2 error(s))

- Flag rate: 0.0% (0/8)
- Span-bucket distribution (word/phrase/clause, among flagged spans): (none)
- Exact flagged-span distribution: (none)

### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: flagged: (no phrases flagged)
- Run 3: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: (no phrases flagged)

## ST-R1-redundant-a-mi

- Text: `Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a mí.`
- Redundant pronoun: `a mí`
- Note: Text/id copied verbatim from test/stage1_detection_harness.dart's ST-R1-redundant-article. THE HARDEST case — 0/10 flag rate in the earlier structural-battery run. Included specifically to see whether gpt-5.6-sol does any better than the gpt-5.5 baseline here. Redundant emphatic "a mí" given "me gusta" already marks the subject.

### Summary (10 runs, 3 error(s))

- Flag rate: 0.0% (0/7)
- Span-bucket distribution (word/phrase/clause, among flagged spans): (none)
- Exact flagged-span distribution: (none)

### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 3: flagged: (no phrases flagged)
- Run 4: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: (no phrases flagged)
- Run 7: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 8: flagged: (no phrases flagged)
- Run 9: flagged: (no phrases flagged)
- Run 10: flagged: (no phrases flagged)

## ellos-redundant

- Text: `Ellos trabajan mucho, ellos estudian por la noche y ellos nunca descansan.`
- Redundant pronoun: `ellos`
- Note: New case, not in the existing battery — a broader sample beyond yo/nosotros, third-person plural.

### Summary (10 runs, 3 error(s))

- Flag rate: 0.0% (0/7)
- Span-bucket distribution (word/phrase/clause, among flagged spans): (none)
- Exact flagged-span distribution: (none)

### Run detail

- Run 1: flagged: (no phrases flagged)
- Run 2: flagged: (no phrases flagged)
- Run 3: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 4: flagged: (no phrases flagged)
- Run 5: flagged: (no phrases flagged)
- Run 6: flagged: (no phrases flagged)
- Run 7: flagged: (no phrases flagged)
- Run 8: flagged: (no phrases flagged)
- Run 9: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}
- Run 10: ERROR — Exception: Chat completions call failed with HTTP 401: {
  "error": {
    "message": "You have insufficient permissions for this operation.",
    "type": "invalid_request_error",
    "param": null,
    "code": null
  }
}

---

## Overall summary

| Case | Runs | Errors | Flag rate | Span-bucket distribution |
| --- | --- | --- | --- | --- |
| ES-6-redundant-yo | 10 | 1 | 66.7% (6/9) | "clause": 5, "phrase": 1 |
| ST-R2-redundant-nosotros | 10 | 2 | 0.0% (0/8) | (none) |
| ST-R1-redundant-a-mi | 10 | 3 | 0.0% (0/7) | (none) |
| ellos-redundant | 10 | 3 | 0.0% (0/7) | (none) |
