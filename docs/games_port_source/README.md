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

## Screens and widgets (added 26 Nov 2026, for the games screens slice)

Copied from the same commit (2a447d3) for slice L in section 3 (decisions G9 to G13). `screens/` holds the web app's home, six game screens and end-of-round summary from `lib/screens/`; `widgets/` holds its shared widgets from `lib/widgets/`. They are the reference for each game's layout and flow (G10: the same games, in Corregir's look). Take the layout, the order of things on screen and the flow; do not take the colours, fonts or sizes, which come from Corregir's own theme. The web app's `lib/theme/` is deliberately not copied.
