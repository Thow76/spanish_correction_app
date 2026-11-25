# Spanish Games: handover to Corregir

Written 2026-11-25 from the Spanish Games build run's conversation with Andrew, and saved into this repo the same day. Notes, not decisions: Andrew's decisions about bringing the games into Corregir go in `claude/corregir_decision_log.md` (stage G), and build steps go in section 3 of `claude/corregir_reset_brief_and_build_plan.md` only once he has answered.

Purpose: carry the games work into the Corregir project, where the games become a standalone practice part of the app with its own back end. Each point is marked **Andrew** (he said or decided it) or **Proposal** (Claude's suggestion, not agreed).

Checked against this repo on 25 Nov 2026 (see the note at the end): the handover's earlier summary used C3's original category names; C3 was revised on 21 Nov 2026 and the four categories are now Spelling, Grammar, Word Choice and Natural phrasing.

## 1. Where things stand (25 Nov 2026)

- Repo `Thow76/spanish_companion_games` (Flutter web, Firebase Hosting `svg-explorer-qqwcu`). Every build and UI item in `claude/Spanish Games Build Plan.md` is done except U19 (on hold). No open PRs. Main at PR #57.
- The app: six games (Choose a correction, Fill the gap, Repair, Spot the error, Sentence ordering, Matching), filter, 5/10 per round with Finish, padlocks per question (B30), Repair focus/hint, end-of-round summary, results sent to the sheet.
- The loop today: ChatGPT companion logs mistakes in the Feedback sheet → ChatGPT games task writes the Questions tab of Test Review → Apps Script (`apps_script/test_review.gs`) exports `questions.json` to Drive and receives results → stage ladder kept in Test Review (Stage, Locked Stage, Last Result, Rule ID), Rules tab holds the matching rule bank.
- Still open on Andrew's side: S15 (ChatGPT prompt for ladder rows), S16 (correction flow, partly talked through below), S17 (one-right-option rule in the prompts).
- Logic worth porting as-is: question format and parser (`lib/models/`), answer checking (`answer_check.dart`), stage rules (`nextStage_` in the script), ordering window (`orderWindow_`), matching round check (`checkMatchRound_`), sentence diff (`SentenceText.changedRuns`).

## 2. The correction flow (Andrew, 25 Nov)

- **Andrew:** "the padlock idea is problematic unless it's a curated set of errors." Two practice modes: Free and Guided.
- **Andrew:** Guided: "you select a group of errors which can be handpicked or grouped by type / subtype", limited to groups of 5, 10 or 15. A type or subtype with 16–30 errors → the app suggests a two-group split; more → three or more.
- **Andrew:** A group "works as a whole where you need to complete all the answers in that group successfully": 9 of 10 does not move on until the last one is right. After an unsuccessful finish you can try again straight away, with only the ones you got wrong.
- **Andrew:** After a group is completed, progress follows spaced learning: "the next group will open in a designated time window and send a notification."
- **Andrew:** Guided uses the current stages plus a translation stage: the original phrase in the learner's own language with the error highlighted; the learner recalls the corrected version; points for accurate recall. Avoid "endlessly litigating the same phrase": the game is recalling the original correction, not offering an alternative version.
- **Andrew:** Context is key: errors can feel "disembodied"; seeing an error in its full context should be an option.
- **Proposals (not agreed):** Free = practice only, does not move the ladder; split evenly (number of groups = errors ÷ 15 rounded up, e.g. 22 → 11 + 11); type groups for stages 1–3, mixed (interleaved) later; a mistake still wrong after two retries leaves the group and drops back on its own so one item cannot hold nine; widening gaps (e.g. 1, 3, 7 days); translation stage after Spot the error, marking only the highlighted chunk; a `context` field (the line answered plus the learner's full message) with a "Show context" option.
- Open question asked, not answered: two-retries rule, or the group waits for every answer.

## 3. Moving off the sheet (Andrew, 25 Nov)

- **Andrew:** the endless changing of the sheet script is becoming an issue; the sheet exists because this started in ChatGPT; the Portuguese version is now in Claude.
- **Andrew:** this is eventually "just an app": the games are a standalone tab of Corregir, with storage and retrieval as "an SQL style SQL light part of the app".
- **Andrew:** "maybe these scheduled tasks have come to the end of their useful purpose", and the next step is to go into the Corregir project and set up a standalone element that implements the back end based on what happens now.

## 4. Proposed architecture (Proposal, not agreed)

- drift (SQLite for Flutter; also runs on web via WASM, unlike sqflite) as the single store.
- Tables: `corrections` (language es/pt, original, corrected, marked span, category, subcategory, explanation, context, conversation id, saved at, stage, locked stage, retired), `questions` (correction id, stage, game, prompt, answers, options, focus, hint, fixed start/end, rule id), `attempts` (question id, at, right, hinted, mode free/guided), `practice_groups` and `group_items` (stage, next unlock at, passed), `rules` (the rule bank).
- Ladder, groups, retries and unlock times in Dart, with unit tests (port of the script's rules).
- Questions written when a correction is saved: one AI call per correction for all stages; the API key needs a small server function (e.g. Firebase), not the app.
- Local notifications on the phone (simple natively; web push is fiddly, iPhone only from the home screen).
- Open decision (asked, not answered): does practice need to be the same on phone and laptop? One device → local drift only. Both → cloud sync (Supabase/Postgres, or Firebase).

## 5. Suggested steps (Proposal, not agreed)

1. Freeze the sheet script; the current Spanish loop keeps running.
2. Put loading and result-sending behind one interface; Drive/script as one implementation, drift the other; port the ladder logic.
3. One-off import of Test Review into the database.
4. Games as a Dart package used by Corregir's practice tab; the web app a thin shell around it. Reconcile the two theme files (see Next Stage Notes section 7).
5. Corregir's save step writes `corrections` and triggers question writing; the sheet retires.
6. Guided mode, groups, spaced unlocking, notifications.

## 6. Scheduled tasks (as found 25 Nov)

- Spanish Games: "Build next step" (daily 04:49), "UI next step" (daily 03:49), "PR review" (daily 05:54), "Weekly progress" (Sundays 17:48). All still on; with every B-item done and U19 on hold they currently find nothing to do.
- Corregir: "Corregir Build" (daily 08:01, Claude Code, repo `Thow76/spanish_correction_app`) builds one step a day from section 3 of `claude/corregir_reset_brief_and_build_plan.md`, never reopening `claude/corregir_decision_log.md`; "Corregir Build check" (08:41) reports on it. Its prompt calls Corregir a Flutter/Android app and says the OpenAI key is read from the environment, not the code. So the games back end only gets built by that task once it is written into the brief's section 3 as steps, with decisions in the decision log, from a conversation in the Corregir project.
- Untouched: "Spanish Voice Chat Proposal" (19:35) and the Portuguese tasks; they do not depend on the games build.

## 7. Already noted for the merge

See `claude/Spanish Games Next Stage Notes.md` (in the games repo) section 7: Corregir's `SavedCorrection` lacks subcategory, options, hints, recall questions, conversation link, spoken/written and practice state; category names to settle (Corregir C3, as revised 21 Nov 2026: Spelling, Grammar, Word Choice, Natural phrasing); Corregir's "Traducir frases" game; English vs Spanish interface copy; laptop play lost unless Corregir gets a web build.

## Checked against this repo (25 Nov 2026)

- Slices 1 and 2 are built; step 2.5 (delete the five-stage pipeline) is on main through PR #198. Slice 3, Home and chats, is next.
- D1 (28 Oct 2026): every stage D feature, including the staged practice route for saved mistakes, waits until after the first build. Bringing the games in reopens D1 for them.
- E3 (2 Nov 2026): the first build is phone only, with no server and no cloud storage of the app's own.
- F1 (2 Nov 2026): slices in order, onboarding first; section 3's "After the first build" list holds stage D work.
- C3: four categories, revised 21 Nov 2026 to Spelling, Grammar, Word Choice (Issues) and Natural phrasing (Suggestions).
- Storage today is JSON files on the phone (`correction_store.json`, `learner_profile.json`); there is no database.
- "Traducir frases" already exists in the Learn tab (`lib/features/learn/`).
