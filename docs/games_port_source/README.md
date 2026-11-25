# Games port source (reference only)

Copied on 25 Nov 2026 from `Thow76/spanish_companion_games` at main, commit 2a447d3 (PR #57), for the practice track in section 3 of `claude/corregir_reset_brief_and_build_plan.md` (decision G1). The files end in `.txt` so the analyzer and tests ignore them. They are the source to port, not code the app uses; do not edit them.

| File | From | What to port |
| --- | --- | --- |
| `question.dart.txt` | `lib/models/question.dart` | question format |
| `question_parser.dart.txt` | `lib/models/question_parser.dart` | parser |
| `answer_check.dart.txt` | `lib/models/answer_check.dart` | answer checking |
| `ladder_locks.dart.txt` | `lib/models/ladder_locks.dart` | padlocks per question |
| `sentence_text.dart.txt` | `lib/widgets/sentence_text.dart` | `SentenceText.changedRuns` (sentence diff) |
| `test_review.gs.txt` | `apps_script/test_review.gs` | `nextStage_` (stage ladder), `orderWindow_` (ordering window), `checkMatchRound_` (matching round check) |
| `question_parser_test.dart.txt` | `test/question_parser_test.dart` | tests to port with the parser and answer checking |
| `ladder_locks_test.dart.txt` | `test/models/ladder_locks_test.dart` | tests to port with the ladder |
