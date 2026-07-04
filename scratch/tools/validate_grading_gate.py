"""
Step 4 (re-run) — Validation battery against GPT-5.5, revised prompts.

Standalone script. Does NOT touch the Flutter app. Disposable — just answers
the question "does the Step 2 grading prompt classify is_related correctly?"

Changes from the previous run:
- Instructions rewritten in English to match prompt_builder.dart convention
  (instructions in English, target-language text only in worked examples).
- Added an explicit rule + worked example for reversed/negated core actions
  (e.g. selling vs buying) counting as unrelated, not just different topics.
- Cases 9 and 23 (buy/sell) now have a concrete expected value (False)
  instead of being open.

NOTE: GPT-5.5 is an OpenAI model — needs the OpenAI SDK and an OpenAI key.
NOTE: GPT-5.5 rejects temperature=0 (only default/1 is supported), so no
temperature parameter is passed.

Setup:
    pip install openai
    export OPENAI_API_KEY=sk-...

Run:
    python3 validate_grading_gate.py
"""

import json
from openai import OpenAI

client = OpenAI()  # reads OPENAI_API_KEY from environment

MODEL = "gpt-5.5"

# ---------------------------------------------------------------------------
# Revised grading prompts — English instructions, target-language examples
# ---------------------------------------------------------------------------

GRADING_PROMPT_ES = """You are an evaluator grading a Spanish-language student's attempt in a retranslation recall game.

You are given:
- The student's attempt (attempt).
- The correct target sentence (expectedAnswer) — the sentence the student should have reproduced.
- The target error category (targetCategory) — the type of error the target sentence was designed to correct.

Your task has two steps, in this strict order:

STEP 1 — Relatedness to the target (is_related)
Determine whether the student's attempt addresses the same scenario/content as expectedAnswer, regardless of whether the attempt is grammatically correct or incorrect.

- Mark is_related = true if the attempt addresses the same topic, situation, or action as expectedAnswer, even if it:
  - uses different words,
  - contains grammatical errors,
  - is incomplete but clearly heading toward the same content.
- Mark is_related = false if the attempt addresses a completely different topic, situation, or action from expectedAnswer, OR if the text is empty, illegible, or not an attempt at translation at all.
- Mark is_related = false also when the attempt keeps the same setting/objects as expectedAnswer but reverses or negates the core action (for example: selling instead of buying, leaving instead of arriving, forgetting instead of remembering). A reversed or negated action is not the same content, even when most of the surrounding vocabulary matches.

Example of is_related = false (different topic entirely): expectedAnswer is about going to the supermarket to buy bread; the attempt describes taking the bus home from work. Completely unrelated topics → false.

Example of is_related = false (reversed action): expectedAnswer is "Fui al supermercado a comprar pan."; the attempt is "Fui al supermercado a vender pan." Same setting and objects, but the core action is reversed (selling vs. buying) → false.

Do not confuse "incorrect" with "unrelated." An attempt can be poorly written and still be is_related = true.

STEP 2 — Normal correction (ONLY if is_related = true)
If is_related is false, leave corrected_text identical to the original attempt and corrections as an empty list — do not analyze errors.

If is_related is true, analyze the attempt exactly as in a normal correction:
- Identify errors of type Grammar, Spelling, Word Choice, Natural Language, or Other.
- Produce corrected_text with the corrected version of the student's attempt.
- Produce corrections as a list of objects {original_phrase, corrected_phrase, category, short_explanation}, with explanations in an informal but technically accurate tone.
- Do not compare the attempt word-for-word against expectedAnswer to penalize differences in wording — the attempt does not need to match expectedAnswer exactly to be correct. Only evaluate whether the student's attempt, as written, is grammatically correct and natural.

Respond ONLY with a valid JSON object in this exact shape, with no additional text:

{
  "is_related": boolean,
  "corrected_text": "string",
  "corrections": [
    {
      "original_phrase": "string",
      "corrected_phrase": "string",
      "category": "Grammar" | "Spelling" | "Word Choice" | "Natural Language" | "Other",
      "short_explanation": "string"
    }
  ]
}"""

GRADING_PROMPT_PT = """You are an evaluator grading a Brazilian Portuguese student's attempt in a retranslation recall game.

You are given:
- The student's attempt (attempt).
- The correct target sentence (expectedAnswer) — the sentence the student should have reproduced.
- The target error category (targetCategory) — the type of error the target sentence was designed to correct.

Your task has two steps, in this strict order:

STEP 1 — Relatedness to the target (is_related)
Determine whether the student's attempt addresses the same scenario/content as expectedAnswer, regardless of whether the attempt is grammatically correct or incorrect.

- Mark is_related = true if the attempt addresses the same topic, situation, or action as expectedAnswer, even if it:
  - uses different words,
  - contains grammatical errors,
  - is incomplete but clearly heading toward the same content.
- Mark is_related = false if the attempt addresses a completely different topic, situation, or action from expectedAnswer, OR if the text is empty, illegible, or not an attempt at translation at all.
- Mark is_related = false also when the attempt keeps the same setting/objects as expectedAnswer but reverses or negates the core action (for example: selling instead of buying, leaving instead of arriving, forgetting instead of remembering). A reversed or negated action is not the same content, even when most of the surrounding vocabulary matches.

Example of is_related = false (different topic entirely): expectedAnswer is about going to the supermarket to buy bread; the attempt describes taking the bus home from work. Completely unrelated topics → false.

Example of is_related = false (reversed action): expectedAnswer is "Fui ao supermercado comprar pão."; the attempt is "Fui ao supermercado vender pão." Same setting and objects, but the core action is reversed (selling vs. buying) → false.

Do not confuse "incorrect" with "unrelated." An attempt can be poorly written and still be is_related = true.

STEP 2 — Normal correction (ONLY if is_related = true)
If is_related is false, leave corrected_text identical to the original attempt and corrections as an empty list — do not analyze errors.

If is_related is true, analyze the attempt exactly as in a normal correction:
- Identify errors of type Grammar, Spelling, Word Choice, Natural Language, or Other.
- Produce corrected_text with the corrected version of the student's attempt.
- Produce corrections as a list of objects {original_phrase, corrected_phrase, category, short_explanation}, with explanations in an informal but technically accurate tone.
- Do not compare the attempt word-for-word against expectedAnswer to penalize differences in wording — the attempt does not need to match expectedAnswer exactly to be correct. Only evaluate whether the student's attempt, as written, is grammatically correct and natural.

Respond ONLY with a valid JSON object in this exact shape, with no additional text:

{
  "is_related": boolean,
  "corrected_text": "string",
  "corrections": [
    {
      "original_phrase": "string",
      "corrected_phrase": "string",
      "category": "Grammar" | "Spelling" | "Word Choice" | "Natural Language" | "Other",
      "short_explanation": "string"
    }
  ]
}"""

# ---------------------------------------------------------------------------
# Step 3 battery — cases 9 and 23 now have a concrete expected value (False)
# ---------------------------------------------------------------------------

ES_TARGET = "Fui al supermercado a comprar pan."
PT_TARGET = "Fui ao supermercado comprar pão."

CASES = [
    # Spanish
    ("es", "Fui al supermercado a comprar pan.", ES_TARGET, "Grammar", True),
    ("es", "Fui al súper a comprar pan.", ES_TARGET, "Grammar", True),
    ("es", "Compré pan cuando fui al supermercado.", ES_TARGET, "Grammar", True),
    ("es", "Fui a el supermercado a comprar pan.", ES_TARGET, "Grammar", True),
    ("es", "Fui al supermercado a conprar pan.", ES_TARGET, "Grammar", True),
    ("es", "Fui al súper para pan.", ES_TARGET, "Grammar", True),
    ("es", "Fui al supermercado a comprar leche.", ES_TARGET, "Grammar", True),
    ("es", "Fui a la panadería a comprar pan.", ES_TARGET, "Grammar", True),
    ("es", "Fui al supermercado a vender pan.", ES_TARGET, "Grammar", False),
    ("es", "Tomé el autobús para volver del trabajo.", ES_TARGET, "Grammar", False),
    ("es", "Mi hermana estudia medicina en la universidad.", ES_TARGET, "Grammar", False),
    ("es", "", ES_TARGET, "Grammar", False),
    ("es", "asdkfj qwoeiu xyz", ES_TARGET, "Grammar", False),
    ("es", "I like pizza", ES_TARGET, "Grammar", False),
    # Portuguese
    ("pt", "Fui ao supermercado comprar pão.", PT_TARGET, "Grammar", True),
    ("pt", "Fui ao mercado comprar pão.", PT_TARGET, "Grammar", True),
    ("pt", "Comprei pão quando fui ao supermercado.", PT_TARGET, "Grammar", True),
    ("pt", "Fui a supermercado comprar pão.", PT_TARGET, "Grammar", True),
    ("pt", "Fui ao supermercado conprar pão.", PT_TARGET, "Grammar", True),
    ("pt", "Fui ao mercado por pão.", PT_TARGET, "Grammar", True),
    ("pt", "Fui ao supermercado comprar leite.", PT_TARGET, "Grammar", True),
    ("pt", "Fui à padaria comprar pão.", PT_TARGET, "Grammar", True),
    ("pt", "Fui ao supermercado vender pão.", PT_TARGET, "Grammar", False),
    ("pt", "Peguei o ônibus para voltar do trabalho.", PT_TARGET, "Grammar", False),
    ("pt", "Minha irmã estuda medicina na faculdade.", PT_TARGET, "Grammar", False),
    ("pt", "", PT_TARGET, "Grammar", False),
    ("pt", "asdkfj qwoeiu xyz", PT_TARGET, "Grammar", False),
    ("pt", "I like pizza", PT_TARGET, "Grammar", False),
]


def build_user_content(expected_answer, target_category, attempt):
    return (
        f'expectedAnswer: "{expected_answer}"\n'
        f"targetCategory: {target_category}\n"
        f'attempt: "{attempt}"'
    )


def grade(lang, attempt, expected_answer, target_category):
    system_prompt = GRADING_PROMPT_ES if lang == "es" else GRADING_PROMPT_PT
    user_content = build_user_content(expected_answer, target_category, attempt)
    response = client.chat.completions.create(
        model=MODEL,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_content},
        ],
    )
    return json.loads(response.choices[0].message.content)


def main():
    rows = []
    for idx, (lang, attempt, expected_answer, target_category, expected) in enumerate(CASES, start=1):
        try:
            result = grade(lang, attempt, expected_answer, target_category)
            actual = result.get("is_related")
            status = "PASS" if actual == expected else "FAIL"
            rows.append((idx, lang, expected, actual, status, attempt))
        except Exception as exc:  # noqa: BLE001 — validation script, want to see everything
            rows.append((idx, lang, expected, f"ERROR: {exc}", "ERROR", attempt))

    print(f"{'#':<3} {'Lang':<4} {'Expected':<9} {'Actual':<9} {'Status':<6} Attempt")
    print("-" * 90)
    for idx, lang, expected, actual, status, attempt in rows:
        print(f"{idx:<3} {lang:<4} {str(expected):<9} {str(actual):<9} {status:<6} {attempt!r}")

    fails = [r for r in rows if r[4] == "FAIL"]
    errors = [r for r in rows if r[4] == "ERROR"]

    print("\n" + "=" * 90)
    print(f"{len(rows) - len(fails) - len(errors)} PASS, "
          f"{len(fails)} FAIL, {len(errors)} ERROR — out of {len(rows)} cases")

    if fails:
        print("\nBLOCKING FAILURES (fix prompt before wiring in):")
        for idx, lang, expected, actual, status, attempt in fails:
            print(f"  #{idx} ({lang}): expected {expected}, got {actual} — {attempt!r}")


if __name__ == "__main__":
    main()
