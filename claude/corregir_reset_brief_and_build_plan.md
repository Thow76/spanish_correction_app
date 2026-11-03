# Corregir: reset brief and build plan

Living document, maintained by a scheduled run. Stored in the project as `claude/corregir_reset_brief_and_build_plan.md` (the Projects tool puts new docs written by Claude under `claude/`; later runs should read and replace that path).

Direction is settled in `claude/corregir_current_app_and_direction.md`; decisions are recorded in `claude/corregir_decision_log.md`. This document is the design those decisions produce. Where it still describes something that has not been decided, it says so.

## 1. Change log

- **2026-11-02 (decision F1; stage F closed; the question process is complete)** — The first build goes step by step, in slices, each one a version Andrew uses on his phone before the next. Slice 1 is the onboarding, the introduction and the profile (Andrew's choice: it drives the conversations), shipped with placeholder content if Andrew's own isn't written yet. Claude's reading of the order after it, open to correction: slice 2, the new check on the Write page; slice 3, Home and chats; slice 4, feedback from chats and History; slice 5, the partner's greetings and notifications. The merge comes first, and the harness work (baseline, rework, partner prompt) runs alongside slices 1 and 2. Also recorded, open to correction: Scrapbook and Goals hidden until built; chats Spanish only; the introduction runs for Spanish in slice 1. Section 3 is rewritten as the build-ready task list. Edits: section 3 (whole). Confirmed by Andrew the same day after a plain-English walk-through of the stages ("I'm happy with how it's been laid out"); the old Write page is called the Check a phrase page from now on. Section 3's slice 2 heading renamed to match.
- **2026-11-02 (decision E3; stage E closed)** — What is kept on the phone. The first build is phone only: chats, summaries, History, Saved, the profile and the settings live on the phone, with no server or cloud storage. Nothing is built for backup or for recovery on a new phone or a reinstall; Android's own phone-wide backup is left exactly as it is, neither switched off nor promised. No backup setting, no export button. Saved keeps no limit (text only). The scrapbook, after the first build, gets a sensible cap when it is designed and is the learner's own to keep and clear. Recovery and cloud storage are questions for a release. Edits: 2.1 (closing paragraph), Phase 3 task 2.
- **2026-10-30 (decision E2)** — The partner runs on GPT-6 Luna, as a starting point Andrew tests on his own chats: its replies, the sign-off at the size limit, the greeting opener, and (Claude's reading, open to correction) each chat's title and summary. The model name sits in one setting so it can be switched, for example to GPT-6 Sol, if Luna proves too flat or follows the partner's instructions poorly. The sitting check is unchanged (Luna for Issues, Sol for Suggestions); the app's other calls stay on GPT-5.5. The partner's share of an ordinary chat is about a fifth of a penny at most; the check, about 1p per sitting, is now nearly all of a chat's cost. Edits: 2.7 risk 6, Phase 3 prototype line and task 2.
- **2026-10-29 (decision E1)** — The chat's size limit counts the characters in the whole chat, the learner's and the partner's together, starting at 20,000 (roughly 50 ordinary exchanges, about five times past the soft goodbye). First recorded the same day as 200,000 from Andrew's first reply; corrected by Andrew to 20,000. Before each partner reply the app adds up the characters; at the limit the partner signs off and the field becomes "This chat has ended" and New chat. The value sits in one place. Near the limit a reply sends about 5,000 tokens (about a tenth of a penny cached, about 1p after a break, on GPT-6 Sol). The partner's model is E2. Edits: 2.2 step 2, 2.7 risk 6, Phase 3 task 2.
- **2026-10-28 (decision D1; stage D closed)** — Guidance over time. Every stage D feature waits until after the first build (error record, progress summary, goals, steering towards difficulties, the staged practice route); the B3 and B4 chat summaries and follow-ups are the only guidance over time in the first build. History keeps its limit of 20 cards, with Andrew's rule for which goes: when a new card would make 21, the oldest card with at least one saved point goes first, otherwise the oldest card; the card of a chat still on Home is never removed. Saved keeps its own full copy of each point, so it is the long-term record, and later stage D features work from it. The proposal to log every suggestion shown is not in the first build. A 30-day limit was weighed and not chosen. Edits: 2.2 step 6, 2.6 (opening and decided note), Phase 2 (status line and task 1), Phase 3 task 4.
- **2026-10-27 (decision C4; stage C closed)** — Focus areas and variety of Spanish. Nothing to choose in the first build: no focus areas (the learner's saving is the filter, as C5 set) and no variety setting. The partner writes neutral, widely understood Spanish and follows the learner's forms ("vosotros" or "ustedes"); the check accepts forms normal in any major variety (C3). Regional notes come after the first build, on demand: Andrew's proposal of a note the learner asks for when in doubt, a button on the sheet such as "Is this regional?", one small AI call per tap, starting with Spain, Mexico and Argentina, framed as tendencies, not rules, and tried on Andrew's sentences first. Edits: 2.2 steps 2 and 4, 2.3 (focus-area note and regional usage heading), 2.5 (three-way verdict row), 2.7 risk 3, Phase 0 task 2, Phase 1 goal, tasks 1 and 4 and done-when line, Phase 3 task 2.
- **2026-10-27 (decision C5)** — After the feedback. No query mechanism in the first build: no buttons for asking the AI about a point; Andrew's idea of querying one's own Spanish is designed after the first build, if at all, from use. No "Not useful" or "Ignore" button either: Andrew removed it, doubting how well a coding agent could build it and expecting added waiting time and clashes. The learner's own saving is the filter; a point not saved simply stays on the History card. The bottom sheet on a highlighted phrase keeps "Save for later" only. The earlier proposals of dismiss-and-suppress and a "dismissed" status are withdrawn. Edits: 2.3 (regional usage proposal, dismiss bullet and honest limit; actions bullet), 2.6 (status field, dismissed line), 2.7 risk 2, Phase 1 goal, tasks 5 and 6 and done-when line.
- **2026-10-26 (decision C2)** — The partner says nothing about the learner's Spanish during a chat: no pointing out mistakes and no deliberate recasting; all feedback comes after the sitting. Claude's reading, open to correction: a direct question mid-chat gets one short line saying the feedback after the chat will cover it, and the chat carries on. Andrew's proposal of a further mechanism for querying one's own production after the feedback is C5. Edits: 2.2 step 2, Phase 3 prototype line and task 2.
- **2026-10-26 (decision C3)** — The category list. Four categories in two groups. Issues (first step only): Spelling (never shown for spoken turns), Grammar, Word meaning. Suggestions (second step only): Natural phrasing. Tone and register was proposed and dropped by Andrew ("it's a chat interface not a job interview"). Word Choice is split between Word meaning and Natural phrasing and the label goes; Natural Language becomes Natural phrasing; regional forms are flagged in neither group (whether they show as notes is C4). Claude's reading, open to correction: formality-only points are not flagged; forms common in speech but rejected by standard Spanish are Grammar Issues with C1's acknowledging reason line. The pronoun line moves to the second step's prompt. Edits: 2.3 ("Other" bullet and "How suggestions are worded").
- **2026-10-26 (decision C1)** — How feedback is worded. Option 1, one suggestion voice, with Andrew's rider: feedback is split into two groups. Issues are technical, objective mistakes the models should flag consistently (the first step, cheaper model). Suggestions are natural-language points such as calques and idioms, where the model is less consistent (the second step, stronger model). "Corrections" and "Corrected" go; the reason line never says "wrong", "error" or "incorrect"; the standing AI line appears. Claude's reading, open to correction: the suggestion voice is held to the Suggestions group, Issues are stated plainly with the rule, the two groups have their own headings, and the group is fixed by which step found the point. The category list for the two groups is C3. Edits: 2.2 step 4, 2.3 ("How suggestions are worded").
- **2026-10-24 (decision B6; stage B closed)** — Who picks what a chat is about, and the introduction: no change to the design. In the first build the partner opens with a check-in or a follow-up (B4), the learner can start a chat on anything and change the subject by asking (B5); choosing a topic from the scrapbook or profile comes with those features after the first build. The introduction stays as A1 drew it, with no reactions and no skip, to be judged after use. Edits: none beyond this entry.
- **2026-10-23 (decision B5)** — The small leftovers from stage B. The Home icon "Check a text" is renamed "Check a phrase" and opens today's Write page unchanged (large box, 600-character counter, recording and Whisper), so a learner can still write more. No "New question" button: the learner asks the partner for something else, or taps New chat; the partner's instructions accept a change of subject gracefully. The chat's message field grows to about five lines, then scrolls; no limit on a single message for now. The scrapbook, goals, specifics and the learner-set chat length come after the first build, one at a time. Edits: 2.1 (closing paragraph), 2.2 step 2 and closing paragraph, Phase 3 tasks 2 and 5.
- **2026-10-22 (decision B4, part 4 of 4; B4 complete)** — The greeting's words. Andrew's own proposal: the notification is a fixed invitation from the app, rotating among three phrases in the target language (for example "¿Te apetece charlar un rato?"), not the opener itself. The opener is written by the AI only when the learner responds (taps the notification, or opens the app after a set time), in one call that chooses a check-in or a follow-up from the freshest context. With no connection or a failed call, a short fixed line opens the chat. Nothing is written in advance; no bank of openers; no extra call at the end of a chat; an ignored notification costs nothing. This replaces part 3's "carrying the greeting's first line". Edits: 2.2 step 2 (closing parenthesis), 2.4 (notifications row), Phase 3 task 2 (notifications lines).
- **2026-10-22 (decision B4, part 3 of 4)** — Notifications. A partner greeting also arrives as a phone notification at each set time, carrying the greeting's first line; the phone schedules it itself, with no server; tapping it opens the app on that greeting's chat; no notifications when greetings are off. Notifications move from Phase 4 into the first build for greetings. The app asks once for permission to show notifications. Where the greeting's words come from (part 4) is still open, and has to be settled because the text must exist when the notification is scheduled. Edits: 2.2 step 2 (closing parenthesis), 2.4 (notifications row), Phase 3 task 2 (closing lines), Phase 4 tasks.
- **2026-10-21 (decision B4, parts 1 and 2 of 4)** — Partner settings, first two parts. The learner can set up to two times of day for the partner's greeting, or switch greetings off (part 1, 20 Oct 2026). In the first build the partner's own openers are of two kinds only, the everyday check-in and the follow-up to an earlier chat; the interests-led, scrapbook and topical kinds, and the setting for choosing and prioritising kinds of chat, come after the first build (part 2, 21 Oct 2026, "for the moment"). Notifications (part 3) and where the greeting's words come from (part 4) are still open. Edits: 2.2 step 2 (closing parenthesis), Phase 3 task 2 (closing line).
- **2026-10-19 (decision P5)** — Unnecessary pronouns are folded into general suggestions: the prompts may try to catch them, with no attempt at consistency and no step owning the pattern as a guarantee. Standing principle: the two-step check works within the agent's limitations rather than trying to eliminate them; a prompt change is kept only if it improves output without an increase in cost and latency. Part 1 of the question order (the correction engine) is closed. Edits: 2.5 (closing line), 2.7 risk 4, section 3 rules line.
- **2026-10-19 (decision P4)** — The two-step check becomes the app's one way of checking Spanish, for chat sittings and the Write page alike. One shot per model, each returning a four-part list (what was written, what is suggested, a category, a one-line reason); no re-runs, fallbacks or cross-checks; the cheap-model-for-basics, strong-model-for-hard-cases cost split is a standing rule. A sitting is checked as one joined text through the same path. The five-stage pipeline is deleted, with only its prompt wording archived; the shared positioning and highlighting code stays. Edits: 2.3 (wording paragraph), 2.4 (prompt rows), 2.5 (pipeline row and closing rules), 2.7 risk 6, section 3 rules line and Phase 1 tasks 2 and 3.
- **2026-10-19 (decision P3)** — Models and prices. The baseline run uses the summer's GPT-4.1 and GPT-5.1; the reworked suggestion check runs on GPT-6 Luna (first step) and GPT-6 Sol (second step), OpenAI's named replacements; the harness price list is corrected with prices verified on 19 Oct 2026. Edits: 2.4 (fixtures row), 2.7 contradictions list (model line), section 3 rules line.
- **2026-10-19 (decision P2)** — Before the two-step prompts are changed, the linear harness is run once as it stands, after the merge, in the full form (85 fixtures, five runs each), and its figures are recorded here as the baseline for the reworked suggestion check. Edits: 2.4 (fixtures row), section 3 rules line (baseline run added as the second task, with a line to fill in).
- **2026-10-19 (decision P1)** — The side branch `correction_pipeline_refactor` is merged back into `main` (three test-file clashes to resolve; the app's behaviour is unchanged). Rider from Andrew: the two-step check is not kept as it was. Clear errors such as grammar are still caught as before; the language issues that caused challenges and inconsistencies move to a general suggestions mode that does not present its corrections as certain, through adjustments to the prompts and the relevant deterministic code. Corrected the same day on Andrew's instruction: the highlighting, positioning and category machinery already exists on `main` and is reused unchanged; the branch did not build any of it, being concerned with model performance on corrections. The two-step check only has to return its findings as a list of items in the shape `main` already consumes. Edits: 2.3 ("How suggestions are worded"), 2.4 (two rows), 2.7 risk 9 and the contradictions list, section 3 rules line.
- **2026-10-17 (decision B3)** — How a chat begins, carries on and ends, decided through the eight-step mock-up "Corregir chat flow". The app opens on Home: the icon band and under it a list of up to five chats, each with a title, with any partner greeting or follow-up waiting above them (replaces B2 point 1, "Home is the chat"). A chat begins with the partner's casual greeting at a set time, the partner's follow-up to an earlier chat, or New chat, which opens an empty chat the learner starts. Spoken turns appear as text while the learner speaks, using the phone's own speech recognition. Each partner reply asks at most one question. A soft goodbye comes at about ten exchanges; the only hard end is the chat's size limit; a sixth chat deletes the oldest; there is no new-day rule. History keeps one card per chat beside checked texts. Each sitting is checked when it ends and offered through a one-line strip. Chats have their own store on the phone; each reply sends only the current chat. The "Other" category is dropped. Edits: 2.2 steps 2 to 4 and closing line, 2.3 ("Other" bullet), 2.4 speech row, 2.7 risk 6, Phase 3 tasks 2, 4 and 5.
- **2026-10-08 (decision B2)** — The home page is the chat. It fills the screen from under a row of three labelled icons (Check a text, Scrapbook, Goals) down to the bottom bar, with a message field and microphone docked above the bar and "New chat" at the top right of the chat area. Partner messages are light bubbles on the left, the learner's replies coloured bubbles on the right. There is no separate "start a conversation" button. Accepted by Andrew "for the moment" from mockup E on the canvas "Corregir home screen options". How a chat begins, carries on and ends is question B3. Edits: 2.2 step 2 and closing line, Phase 3 tasks 2 and 5. (Point 1 replaced by B3.)
- **2026-10-07 (decision B1)** — The app gets a home page that it opens on. The bottom bar stays at four places: Home, History, Saved, Learn; Home takes the place of Write. Conversation is typed or spoken and its screen mimics the Write flow (text box and audio control). What the home page holds, and whether the Write page is kept behind a button, is question B2. Edits: 2.2 step 2 and closing line, 2.8, Phase 3 task 5.
- **2026-10-07 (decision A2)** — The profile is one per learner, shared across languages, saved on the phone as its own file, and opened and edited from a person icon in the app bar. Interests are asked in the target language in the introduction and listed in English on the profile screen. The introduction runs once and does not replay on a language switch. Anything about the language being learnt (the scrapbook, when it is built) is kept per language. Edits: 2.1 (A2 paragraph added), 2.2 step 1, 2.4 last row, Phase 3 tasks 1 and 3.
- **2026-10-05 (decision A1)** — Confirmed by Andrew as the decision for the first iteration: a scripted introduction in the target language (two warm-up questions, interest chips, about three fuller questions, then suggestions now or later). Edits: 2.1 (proposal replaced by the decision), 2.2 step 1, 2.4 last row, 2.7 risk 5, Phase 3 tasks 1 and 3.
- **2026-10-05 (correction)** — An earlier edit today recorded "decision A1" (profile gathered by a get-to-know-you conversation; two ways into the app). That was Andrew's proposal for discussion, not a decision, and it was recorded in error. The sections it touched (2.1, 2.2, 2.4, 2.7 risk 5, section 3 note, Phase 3) now describe it as a proposal under discussion. Kept from that edit, because they follow from the settled direction and not from A1: 2.8 replaced with a pointer to the decision log; statements that treated settled or still-open points as decided corrected; the note that the phase order in section 3 is out of date.
- **2026-10-05 (decision S2 in the log; first recorded here as "A1")** — The learner talks to the AI only; person-to-person was never part of the app. Edits: 2.1 assumption replaced with the decision.
- **2026-10-05** — Housekeeping only; no change to the plan. Checked: project doc list (no new or changed docs), project memory, and a fresh clone of the repo (no commits on any branch since 10 Aug 2026). Edits: (a) removed one contradiction from 2.7 because the project memory index now says correction is core; (b) added the repo's `AUDIT.md` to the out-of-date references in 2.5 (it is dated 31 May 2026 and describes the Gemini-era app); (c) tidied the 2 Oct entry below. Learner-chosen focus areas re-checked: still not written down anywhere.
- **2026-10-02** — First version. Written from: all 8 project docs, project memory (overview, learnings, index), and a full clone of the repo (`main` and `correction_pipeline_refactor`). Not read: raw chat transcripts, and one of the two project docs that share the title "# Catalog of Spanish regional constructions…" (the tool can only open one of them by name).

---

## 2. Reset brief

### 2.1 Product statement

Corregir is a conversation partner for upper-intermediate and advanced learners of Spanish and Brazilian Portuguese. It learns what you like to talk about, keeps you talking or writing about it, and shows you **possible issues** in what you said. You keep the ones that matter, and the app turns them into practice so that long-standing ("baked-in") mistakes finally shift.

**Who it is for:** learners who already communicate well and no longer get corrected by anyone, so the same mistakes repeat for years. Not beginners.

**Decided (S2, 5 Oct 2026):** the learner talks to the AI and to nobody else. Connecting learners with other people is not part of the app, now or later, so there are no accounts, backend, matching or moderation.

**Decided (A1, 5 Oct 2026), for the first iteration:** the app first learns about the learner through a short scripted introduction in the target language, straight after the language is picked. No form in the learner's own language, no choice screen, no opt-out to Write for now.

1. Two warm-up questions that teach the controls: one typed (¿Cómo estás?), one spoken (¿De dónde eres?), each with a small hint in English. No feedback on these.
2. One interests question answered by tapping chips in the target language. The chosen chips are the profile.
3. About three fuller questions drawn from the chosen chips, each written to pull a different structure. Answered by typing or speaking.
4. Each fuller answer is sent for feedback in the background as it is given.
5. End screen: a closing line and two buttons, see suggestions or not now. "See" walks through the existing results screen for each answer in turn; "not now" leaves the answers in History.
6. "Stop for now" on every step. It goes to the end screen if at least one fuller answer exists, otherwise to the main app.
7. No reaction to the learner's answers in this iteration. Target length two to three minutes, never more than five.

The introduction exists to get the learner talking, using the app and seeing what it does. It is not a diagnostic and is not expected to show what they find difficult.

**Decided (A2, 7 Oct 2026): where the profile lives and how it changes.**

- **One profile per learner, shared across languages.** A learner who switches between Spanish and Portuguese keeps the same interests. The introduction runs once per install and does not replay on a language switch.
- **Its own section, opened from the app bar.** A person icon in the `AppBar` of `lib/features/navigation/presentation/app_shell.dart`, beside the existing settings icon, opens a profile screen where the learner can see and edit their interests.
- **Interests are shown in two ways.** In the introduction the chips are in the target language, as part of showing what the app does. On the profile screen the same interests are listed in English. So each interest is stored as a language-neutral id with an English label and a label per target language.
- **Saved on the phone as its own file.** A new `learner_profile.json` beside `correction_store.json`, not a SharedPreferences string, so that more can be added later without a migration. Introduction progress is kept in the same file so "stop for now" can resume.
- **Language-specific material is kept per language.** The scrapbook (a queued proposal, not yet designed) will be one per language being learnt. The profile file is shaped with a shared part and a per-language part from the start.

The profile is expected to grow beyond the tapped interests (specifics, goals, a progress summary, a scrapbook). Those are Andrew's proposals from 7 Oct 2026, held as queued topics in the decision log, and are not decided here. B5 (23 Oct 2026): specifics, goals and the scrapbook come after the first build, brought in one at a time once the app is in use. E3 (2 Nov 2026): the scrapbook, being the one part that could grow large (images, PDFs, full texts), gets a sensible cap when it is designed; it is the learner's own collection on the phone, to keep and clear.

### 2.2 Core loop

1. **Introduction and profile** — a short scripted introduction in the target language; the interest chips the learner taps are the profile (A1, see 2.1). The profile is then viewed and edited from the person icon in the app bar (A2).
2. **Conversation** — Home is the first place in the bottom bar and what the app opens on (B1). Under the header sits a band of three labelled icons: Check a phrase (first drawn as "Check a text"; renamed by B5), Scrapbook, Goals (B2). Under the band is a list of up to five chats, newest first, each with a short title and its last line, like WhatsApp; a partner greeting or follow-up, when there is one, waits above them (B3). An opened chat fills the screen without the icon band: the partner's messages are light bubbles on the left, the learner's coloured bubbles on the right, with a message field and microphone above the bottom bar (B2, B3). A chat begins in one of three ways (B3): the partner's casual greeting at a time the learner set, or never if turned off; the partner's follow-up to an earlier chat, drawn from the active chats and from short summaries of the five most recently deleted; or the learner tapping "+ New chat", which opens an empty chat where the learner speaks first. The partner titles the chat from the first exchange. The learner replies by typing or speaking; spoken words appear in the message field as they are said and can be corrected before sending. The message field grows as the learner types or speaks, to about five lines, then scrolls inside itself, and a single message has no length limit for now (B5). There is no "New question" button: to change the subject the learner simply asks the partner, or taps New chat, and the partner accepts a change of subject gracefully (B5). Each partner reply answers first and asks at most one question. The partner never comments on or corrects the learner's Spanish during a chat, and does not deliberately recast; a direct question about the learner's language gets one short line saying the feedback after the chat will cover it (C2, 26 Oct 2026). The partner writes neutral, widely understood Spanish and follows the learner's forms (if the learner uses "vosotros" or "ustedes", so does the partner); there is no variety setting in the first build (C4, 27 Oct 2026). At about ten exchanges the partner says a soft goodbye and stops asking; the learner can carry on. The only hard end is the chat's size limit, where the partner signs off and the field is replaced by "This chat has ended" and New chat. A chat that goes quiet stays on the list and carries on later with a day marker. A sixth chat deletes the oldest without asking. An unanswered greeting is cleared at the next daily refresh, an unanswered follow-up after 48 hours; with no server these happen when the app is next opened. (B4, 20 to 22 Oct 2026: the learner sets up to two greeting times a day or switches greetings off; in the first build the partner's own openers are the check-in and the follow-up only, with no kinds-of-chat setting until the interests-led, scrapbook and topical kinds exist; at each set time the phone shows a notification, scheduled on the phone with no server, carrying one of three fixed invitations in rotation ("¿Te apetece charlar un rato?" and two others); tapping it, or opening the app after a set time, opens the greeting chat, and the AI writes the opener at that moment, choosing a check-in or a follow-up from the active chats and summaries; with no connection or a failed call a short fixed line ("¡Hola! ¿Qué tal?") opens the chat instead. The size limit (E1, 29 Oct 2026): the characters in the whole chat, learner's and partner's together, up to 20,000, roughly 50 ordinary exchanges, about five times past the soft goodbye. B5, 23 Oct 2026: the learner-set chat length comes after the first build, so the soft goodbye stays at about ten exchanges.)
3. **Captured input** — every learner turn is stored with its chat, in a chat store of its own on the phone (B3): up to five chats, each with its turns, title, language, dates and who started it, plus summaries of the five most recently deleted. Each partner reply sends only the current chat.
4. **Suggested issues** — each sitting is checked when it ends (the partner's goodbye, the size limit, or the learner leaving), sending only the turns since the last check, and also when a chat reaches its limit or is deleted (B3). If something was found while the learner is still in the chat, a one-line strip above the message field offers it, naming both counts (for example "2 issues, 1 suggestion from this chat"), See, a cross; See opens that chat's History entry; the strip closes for good with the cross or on leaving. Results go on the chat's History card, one card per chat beside checked texts, which stays after the chat leaves Home. How the feedback is worded is decided (C1, 26 Oct 2026; see 2.3): two groups, Issues and Suggestions. The category list within the groups is decided (C3, 26 Oct 2026). The learner does not choose what they get feedback on in the first build: every point is shown and saving is the filter (C4, C5, 27 Oct 2026).
5. **Learner saves what matters** — from a History card: tap category chips (each with a count) and swipe right to save them, or swipe with nothing chosen to be asked whether to save all; or open the card, where each sitting shows Original and Corrected, and tap a highlighted phrase to save one error through today's sheet (B3). Nothing is saved automatically.
6. **Practice and recall** — saved items feed "Traducir frases"; repeated patterns are counted and brought back in later conversations. (Details: stage D. D1, 28 Oct 2026: not in the first build; counting patterns and bringing them back come after it, working from what the learner saved.)

The existing Write flow joins this loop at step 4, with the learner's own text or speech in place of a conversation transcript. From B1 it no longer has a place in the bottom bar. From B2 it is reached from an icon on Home, which B5 (23 Oct 2026) renamed "Check a phrase". It opens today's Write page unchanged: the large text box with its 600-character counter, recording and Whisper transcription, with the P4 two-step check behind it, so a learner can still write more if they want. Checked texts sit in History beside chats, with the same cards and the same swipe to save (B3).

### 2.3 The correction reframing

**What was already decided, and where it is written**

- Source: project doc `claude/correction_reframe_source_aug2026.md` (summary of the chat "Document review and feedback", 9–12 Aug 2026), and the project memory overview ("Current state — product direction").
- Decided then: the app stops saying "this is an error". It says "this is a possible issue, this is what the AI suggests, and this is the category it would put it in". The learner accepts or dismisses. Saved items feed the game. A wrong flag is "a redundant suggestion, not a false lesson", so the bar is "useful more often than not".
- Why: consistent, authoritative correction was only reachable on gpt-5.5 for Pass 2, at about 5x the cost and 2x the latency. The cheaper model could not be prompted into handling cases like "voy para casa" (0/5 after three attempts).
- Caveat recorded at the time, still true: softer wording reduces the harm of a wrong flag; it does not remove it.

**Learner-selectable focus areas: not found in any document**

- I searched every project doc, project memory and the repo. The idea of the learner choosing feedback areas is **not written down anywhere** except as Andrew's recollection in memory (1 Oct 2026). The source doc above says explicitly that it does not appear in that chat or any other project chat.
- So the list below is a **proposal**. Whether and how the learner chooses what they get feedback on is a queued stage C question in the decision log. (C4, 27 Oct 2026: no focus areas in the first build; the learner sees every point and saving is the filter. The table stays as a proposal for later, if ever.)

| Focus area | What it covers | Maps to existing category | Default |
|---|---|---|---|
| Grammar | Verbs, agreement, prepositions, pronouns, mood | `Grammar` | On |
| Word choice | Wrong word, false friends | `Word Choice` | On |
| Natural phrasing | Calques, collocations, literal translations | `Natural Language` | On |
| Spelling and accents | Misspellings, missing accents | `Spelling` | On for typed text, **off for voice** |
| Punctuation | ¿ ¡ commas, full stops | Currently folded into `Grammar` | **Off**, and always off for voice |
| Regional usage notes | "This is fine in X, but lands differently in Y" | `dialectal` verdict / `CorrectionNote` | Off |

Three points behind that table:

- **Punctuation needs code work.** `ErrorCategory.fromLabel` in `lib/features/corrections/domain/error_category.dart` folds Punctuation and Preposition into Grammar, and every prompt since has done the same. To let a learner switch punctuation off, the model must tag it separately again.
- **Voice changes what is fair to flag.** For spoken input, the speech recogniser writes the spelling, accents and punctuation, not the learner. Flagging them is noise. They should be forced off for voice turns.
- **"Other" is dropped (decided in B3, 16 Oct 2026).** It was a bucket for model uncertainty, not something a learner would choose. The app's categories are Grammar, Natural Language, Spelling and Word Choice; `ErrorCategory` and the prompts lose `Other`. (C1 and C3, 26 Oct 2026: replaced by four categories in two groups. Issues: Spelling, Grammar, Word meaning. Suggestions: Natural phrasing. Word Choice is split between Word meaning (the word changes the meaning) and Natural phrasing (understood but not the most natural); Natural Language becomes Natural phrasing. The focus-area table above is an older proposal and predates this list; focus areas are C4.)

**Standard versus regional usage, as a learner choice** (proposal; how the learner's variety is respected is a queued stage C question. **Decided (C4, 27 Oct 2026):** neither setting below is in the first build. The partner writes neutral Spanish and follows the learner's forms; the check flags no regional form (C3). After the first build, regional notes come on demand rather than as a setting: a button on the sheet that opens on tapping a highlighted phrase (for example "Is this regional?"), one small AI call per tap, starting with Spain, Mexico and Argentina, worded as tendencies ("more usual in Spain"), never rules, and tried on Andrew's own sentences before it is built.)

- Old approach: the model had to decide `error` / `dialectal` / `not_an_error` correctly on every run. The regional catalogs list about 25 constructions where that decision flips between runs, and several where the two catalogs themselves disagree (for example *recién llegué*: `not_an_error` in one, `dialectal` in the other).
- New approach, two learner settings instead of one model verdict:
  1. **Target variety** (Spain / Latin America / no preference). Passed into the prompt as a fact about the learner: "do not suggest changes to forms that are normal in the learner's variety".
  2. **Regional usage notes** on or off. When on, regional items appear as a neutral note, never as a suggestion to change. This reuses the existing `CorrectionNote` and the notes panel in `corrections_screen.dart`.
- **Dismiss means "stop telling me this".** When the learner dismisses a suggestion, the app stores the phrase and suppresses the same flag in future, in code. This is the one part of the design that fixes a repeated wrong flag for certain, without needing the model to behave. (Withdrawn by C5, 27 Oct 2026: there is no dismiss, "Not useful" or "Ignore" button and nothing stores rejected suggestions; the learner's own saving is the filter, and a point not saved simply stays on the History card.)
- Honest limit: none of this makes the model right about "voy para casa". It lowers how often the question comes up and makes a wrong flag cheaper. (The one-tap silencing first proposed here was withdrawn by C5, so a wrong flag can recur.)

**How suggestions are worded**

- **Decided (P1 rider, 19 Oct 2026):** the two-step check is no longer concerned with catching every error accurately. Clear errors such as grammar, which the first step picks up easily, keep their present handling. The language issues that caused challenges and inconsistencies in the summer (naturalness, regional usage, word choice) are phased into a more general suggestions mode that does not present its corrections as certain. This is done through adjustments to the prompts and the relevant deterministic code. What that code is, corrected on Andrew's instruction (19 Oct 2026): the highlighting is already dealt with on `main` and is reused as it stands. An item on `main` is a phrase, a suggested phrase, a category and a short explanation (`correction_item.dart`); the code finds the phrase's position in the text by occurrence (`correction_original_range_resolver.dart`), draws the coloured highlights with a search fallback when no position is given (`correction_highlight_spans.dart`), removes overlaps and works out the matching range in the corrected text. The experimental branch built none of this, because it was measuring model performance on corrections, not screens. So the only code the two-step check needs is a small parsing step that turns each step's reply into that list of items (the branch already has one for the second step, `naturalness_correction_mapper.dart`); the suggestion framing itself lives in the prompts and in the category and explanation text each item carries. **Decided (P4, 19 Oct 2026):** the two steps are the app's one check, for a chat sitting and for a checked text alike. Each model gets one shot: it looks at the text once and returns its findings as a list in the four-part shape above (what was written, what is suggested, a category, a one-line reason), the first step the clear fixes, the second the suggestions, with no separate categorising or explaining stage and no re-running, fallback or cross-checking to iron out inconsistencies. The cost split (cheap model for basics, strong model only for calques, idioms, collocations and advanced usage) is a standing rule. If the one-shot version proves too slow when measured, the fallback is to split the work into stages (spot, suggest, categorise, reason). A sitting is checked as one text, the learner's messages since the last check joined one per line. **Decided (C1, 26 Oct 2026):** the wording below, with Andrew's rider that feedback comes in two groups. Points marked as Claude's reading are open to Andrew's correction.
- **Two groups.** **Issues**: technical, objective mistakes that the models should flag consistently, returned only by the first step (cheaper model). **Suggestions**: natural-language points such as calques, idiomatic expressions and other higher-level points where the model is less consistent, returned only by the second step (stronger model). The group is fixed in code by which step found the point. **Decided (C3, 26 Oct 2026):** the categories. Issues: **Spelling** (letters, written accents, ¿ ¡ and other punctuation; never shown for spoken turns), **Grammar** (verb forms, tense and mood, agreement, ser and estar, por and para, the preposition a verb needs, articles, pronouns, word order), **Word meaning** (a word that says something other than what was meant: false friends, confused pairs such as saber and conocer). Suggestions: **Natural phrasing** (calques and literal translations, idioms, word partnerships, a better word where the learner's is understood, unnecessary pronouns). The test: would a careful speaker anywhere in the Spanish-speaking world reject it (Issue), or is it about sounding natural (Suggestion)? Tone and register was proposed and dropped by Andrew. Claude's reading, open to correction: formality-only points are not flagged; forms common in speech but rejected by standard Spanish ("habían muchas personas") are Grammar Issues. Regional forms are flagged in neither group (notes: C4). The unnecessary-pronoun line belongs in the second step's prompt. One new colour (Word meaning); saved items under the old labels are renamed once on the phone.
- Screen titles and labels: no "Corrections" / "Corrected" / "No corrections required" (today's wording in `corrections_screen.dart`); the improved text is the suggested version. Claude's reading: the results screen and an opened History card show the two groups under the headings "Issues" and "Suggestions". The drawn screens' "errors" become neutral words ("Tap the highlighted words to save them", "Save everything from this chat").
- Each item: what you wrote → what the AI suggests → category → one sentence of why.
- The explanation sentence never uses "wrong", "error" or "incorrect". `stage3FeedbackSpanish` already has this rule for `dialectal` items and a harness check for it (`test/stage3_feedback_harness.dart`); extend it to every item.
- Claude's reading of "the gradation needs to be contained": the suggestion voice is held to the Suggestions group. Issues are stated plainly with the rule and no hedging ("After 'quiero que' Spanish uses the subjunctive: 'vengas'"); Suggestions are offered as suggestions ("A more natural way to say this is…").
- Keep the Stage 3 rule that widely used but proscribed forms must be acknowledged ("you'll hear this constantly, but it is avoided in careful writing"). After C3 this applies to Grammar Issues such as "habían muchas personas" ("you'll hear 'habían' a lot, but standard Spanish uses 'había' here").
- **Decided (C5, 27 Oct 2026):** each item has one action, **Save** ("Save for later" on today's bottom sheet, or the swipe on a History card). There is no "Not useful" or "Ignore" button, and no follow-up buttons for querying a point (such as "Is mine actually wrong?" or "Show me examples") in the first build. The learner's own saving is the filter; a point not saved stays on the History card and goes no further. A way to query one's own Spanish after the feedback may be designed after the first build, from use.
- One standing line on the screen: "These are AI suggestions. Check anything that surprises you." No per-item hedging; that would make everything read as mush.

### 2.4 What carries over

| Keep | Where | Why |
|---|---|---|
| Speech-to-text | `lib/features/write/data/open_ai_whisper_transcription_service.dart`, `lib/shared/widgets/mic_control.dart` | Stays for the Write page. In chats, B3 decided that spoken words appear on screen as the learner speaks, using the phone's own speech recognition (free, no AI call), with no recording and no time limit; the learner can correct the text before sending. So the app has two ways of hearing speech until Write is changed to match. The chat may still reuse `mic_control.dart` for the button. |
| Suggestion data shape and highlighting | `correction_item.dart`, `correction_response.dart`, `correction_original_range_resolver.dart`, `lib/shared/text/correction_highlight_spans.dart` | Position anchoring in code (not trusting model indexes) was hard-won and is independent of how the suggestion is framed. |
| Regional notes | `correction_note.dart`, `_NotesPanel` in `corrections_screen.dart` | Already the right shape for "regional usage notes". |
| Saving | `lib/features/saved/` (`SavedCorrection`, `SaveCorrectionUseCase`, saved screens) | "Learner saves what matters" is already built, including the English prompt phrase the game needs. |
| Recall game | `lib/features/learn/` (session builder, "Traducir frases", grading, walkthrough) | This is the practice half of the loop. The session builder already filters by category. |
| OpenAI client with usage logging | `lib/features/corrections/data/openai_chat_completions_client.dart` (`onUsage` hook) | Cost per conversation becomes the key number; the hook already exists. |
| Explanation tone rules | `stage3FeedbackSpanish` in `lib/core/services/prompts/correction_prompt.dart` | Closest existing text to the new wording rules. P4 (19 Oct 2026): the five-stage prompts are archived as wording only, in a docs file, when the pipeline is deleted; this one is the main reason to keep them. |
| Two-step prompt wording | `firstPassCorrectionSpanish`, `naturalnessReviewSpanish` in `correction_prompt.dart`, and `linearFirstPassPrompt`, `linearSecondPassPrompt` in `test/two_pass_linear_prompt_comparison_harness.dart` (on `main` once the P1 merge is done) | Best restraint wording the project has, including the "voy para casa" example. P4 (19 Oct 2026): the starting point for the app's one suggestion check; each step is reworked to return a four-part list in one shot. |
| Fixtures and harnesses | `test/shared/benchmark_fixtures.dart` (9 fixtures on `main`, 58 on the branch; both sets kept in the P1 merge) and the 85 fixtures in `test/two_pass_integration_harness.dart`, with the linear comparison harness and `test/shared/model_pricing.dart` | Ready-made test sentences with clean controls and regional controls, and the harness that measures cost, speed and accuracy. P2 (19 Oct 2026): the harness is run once as it stands, in the full five-run form, before the prompts are changed, and its figures become the baseline (see the section 3 rules line). The pricing table was marked as unverified placeholders; P3 (19 Oct 2026) corrects it with verified prices per million tokens (input / output, US dollars): GPT-4.1 $2 / $8; GPT-5.1 $1.25 / $10; GPT-5.5 $5 / $30 (cached input $0.50); GPT-6 Luna $0.10 / $0.50; GPT-6 Sol $2 / $10. |
| The two catalogs | Project docs | No longer rule books for the model. They become (a) the source list for pattern tags in 2.6 and (b) the regional control sentences for the harness. |
| Portuguese prompt | `correctionPromptPortuguese` in `correction_prompt.dart` | Already a single call built from small blocks, which is the shape the Spanish side is moving to. |
| Interest taxonomy, context cards, notifications | Project memory only | Kept as plans. **Evidence is thin:** there is no doc and no code for any of them, only one-line memory summaries. A1 needs a set list of interests after all, as chips in the target language, plus a small bank of fuller questions per chip. Andrew writes both; they are content, not code. A2 adds that each interest needs three labels: English (for the profile screen), Spanish and Portuguese (for the introduction). Notifications (B4 part 3, 22 Oct 2026): no longer only a plan. Partner greetings arrive as local notifications scheduled on the phone (no server, no push service); the repo has no notification code or package yet, so this is new work in the first build (a local notifications package, a one-time permission request, scheduling at the learner's set times, and opening the greeting chat when tapped). B4 part 4 (22 Oct 2026): the notification carries a fixed invitation, one of three phrases in rotation, not the opener; the opener is written by the AI when the learner responds. Andrew writes the three phrases (and the fixed fallback line) in each language. |

### 2.5 What to drop or simplify

| Drop or simplify | Where | Why |
|---|---|---|
| Five-call staged pipeline as the live Spanish path | `staged_correction_pipeline.dart`, `stage1_detection_client.dart`, `stage2_categorization_client.dart`, `stage3_feedback_client.dart`, the `staged_correction_*.dart` domain files, and their tests and harnesses | Built to get consistent verdicts and categories. About 20–30p per 10 submissions on gpt-5.5. A conversation with 10–20 learner turns cannot afford five calls per turn. **P4 (19 Oct 2026): deleted, not parked**, once the two-step check is wired in; only its prompt wording is archived (a docs file holding `stage1DetectionSpanish`, the 1B and 1C prompts, `stage2CategorizationSpanish` and `stage3FeedbackSpanish`). The shared domain code the screens use (`correction_original_range_resolver.dart`, `correction_overlap_resolver.dart`, `correction_corrected_range_calculator.dart`, `correction_insertion_offset_calculator.dart`, `correction_highlight_spans.dart`) is not part of the pipeline and stays. |
| Three-way verdict as a gate | `staged_correction_verdict.dart`, `staged_correction_verdict_splitter.dart` | Replaced by the learner's variety setting plus notes. Only the "note, not a fix" idea survives. (C4, 27 Oct 2026: in the first build, by no regional flagging at all; on-demand regional notes come later.) |
| Stage 2's ~2,000-token boundary rules | `stage2CategorizationSpanish` | Existed so that the same error always got the same category. Focus areas are coarser and a wrong label is now low-cost. Keep two or three of the tiebreak lines at most. |
| Span-scope trimming | `staged_correction_span_scope*.dart`, `correction_span_trim_calculator.dart` | Polish for exact highlight width. Not needed to show "you wrote / suggested". |
| Parallel + fallback two-pass machinery | On the branch: `two_pass_correction_pipeline.dart`, `naturalness_merge.dart`, `naturalness_correction_mapper.dart` | The project's own 5x report found the simpler serial version performed the same on the hard cases (51.1% vs 51.9%). The merge machinery buys nothing. |
| Further model comparison | `test/model_comparison_harness.dart` and related docs | The question "which model is consistent enough" is the one the reset stops asking. |
| Offline queue | `sync_queued_submissions_use_case.dart` | A conversation cannot run offline. Low priority to remove; just do not extend it. |
| "Business Analysis & Requirements" and `AUDIT.md` as references | Project doc; repo root | Both describe the earlier app (Gemini, 7 categories, correction only). `AUDIT.md` is dated 31 May 2026 and predates the staged pipeline. Out of date in almost every section; do not use either to learn the current code. |

**What still earns its place from the old pipeline:** occurrence-based positioning in code, overlap dedup, corrected-text reconstruction (the game needs a clean corrected sentence), and the redundant-pronoun and reflexive detection *ideas* as lines in the new prompt. P5 (19 Oct 2026): those lines are tried, not guaranteed; pronouns are folded into general suggestions, no step owns the pattern, and the pronoun fixtures measure rather than gate.

**Deleting (changed by P4, 19 Oct 2026).** The earlier rule here was "unwire, do not remove". Andrew's decision is to delete the five-stage pipeline's own code and tests outright once the two-step check is wired in, because efficiency was the whole reason for moving away from it, and to archive only its prompt wording for reference. Deleting is still its own task (find every file and test that touches the pipeline), done after the two-step check is in and working, not in the same change. Everything else in this table is still "unwire first, delete later".

### 2.6 Tracking baked-in errors over time

The account-level memory names this as the app's wedge: "a persistent per-learner error corpus from actual mistakes". Nothing in the repo does it yet. History keeps only the 20 most recent submissions (`_recentLimit` in `file_correction_repository.dart`).

**Decided (D1, 28 Oct 2026):** none of the mechanism below is in the first build. History keeps its limit of 20 cards; when a new card would make 21, the oldest card on which at least one point has been saved is removed first, otherwise the oldest card, and the card of a chat still on Home is never removed. A saved point is stored in Saved as its own full copy (`SavedCorrection` holds the sentence, phrases and explanation, with no link back to History), so Saved is the long-term record, and the error record, when it comes, works from what the learner saved rather than from a log of every suggestion shown (in line with C5: saving is the filter). The proposal below stays as background for after the first build.

Proposed mechanism (after the first build, if at all):

- **Log every suggestion shown**, not just saved ones. Fields: date, conversation id, the learner's sentence, original phrase, suggested phrase, focus area, **pattern tag**, input mode (typed/voice), and status (saved / not saved; C5, 27 Oct 2026, removed the "dismissed" status, since there is no dismiss button).
- **Pattern tag from a closed list.** The model picks one tag from a fixed list of roughly 30, taken from the headings of `spanish_category_boundary_catalog_merged.md` (ser/estar, governed preposition, gustar-type verbs, mood selection, impersonal haber, accent on verb form, support-verb collocation, false friend, body-part possessive, redundant pronoun, clitic order, and so on) plus "other". A closed list is the only way counts mean anything.
- **A pattern is "baked-in" when** it has appeared in 3 or more separate conversations, or the learner has saved it twice. (The earlier rule "dismissed items never count" fell away with the dismiss button, C5.)
- **What the count drives:** a "Your patterns" list; priority in the game session builder; and a line in the tutor prompt ("this learner often slips on X; steer towards situations that need it").
- **Weak point, stated plainly:** the project's own lesson is that models flip between categories across runs. Thirty tags will flip more than five categories did. Counting over many conversations smooths this, but it must be measured in a harness (same sentence, 5 runs, same tag?) before any screen is built on it. If tag stability is poor, fall back to counting by focus area plus the exact phrase pair, which is cruder but computed in code.

### 2.7 Risks and honest concerns

1. **The reframing absorbs wrong flags, not missed ones.** If the model misses a baked-in error, the learner never knows. The whole value of the app depends on catch rate for subtle errors (calques, collocations), and the project's own tests showed cheaper models are weakest exactly there (GPT-4.1 "fails completely on calque detection"). Softer wording does nothing for this.
2. **A wrong suggestion can still teach a wrong lesson.** An advanced learner told that "voy para casa" might be better as "voy a casa" may believe it. The learner profile in memory notes Andrew himself can "suspect bad AI output but not verify it confidently". The target user is in the same position. C5 (27 Oct 2026) removed dismiss-and-suppress, so a wrong suggestion can come back in later chats; the learner's protection is that nothing is saved, and so nothing reaches practice, unless they choose it.
3. **Focus filtering depends on labelling, which is the thing that was inconsistent.** If a grammar issue is labelled "word choice" and the learner has word choice off, it is silently hidden. Mitigation: filter in code on a coarse label, default most areas on, and measure mislabel rate. C4 (27 Oct 2026): no focus filter in the first build, so this risk does not arise yet; a category filter in History or Saved only narrows what the learner is looking at, never what the check returns.
4. **Inconsistency becomes visible in a new way.** In conversation the same mistake will be flagged on Monday and not on Thursday. The pattern count will under-report. Learners may notice. P5 (19 Oct 2026): accepted, not mitigated. Andrew's standing principle is that dealing with the model's inconsistencies is no longer a focus; the check works within the agent's limitations, and a prompt line may be tried for a pattern but never engineered into a guarantee.
5. **Conversation is a new, unproven build.** There is no conversation or profile code at all. The tutor prompt work (naturalness, word ceiling, multi-message turns) was planned in August and never started in the repo. A1 eases this for the first step: the introduction is scripted, needs no partner prompt and no AI call per turn, and can be built from existing parts before the conversation feature.
6. **Cost moves from per-submission to per-conversation.** B3 fixes the shape: one AI call per partner reply, sending only the current chat (with prompt caching, late turns cost only modestly more than early ones), up to the chat's size limit; one check per sitting when it ends, sending only the turns since the last check, about the size of checking one short text today, spent whether or not the learner looks. P4 (19 Oct 2026): that check is the two-step check, one call on GPT-6 Luna and one on GPT-6 Sol per sitting or per checked text, with the Sol call carrying nearly all the cost; per-message checking, if ever wanted, would multiply that by the messages in a sitting. The partner also writes a title and a short summary per chat. E1 (29 Oct 2026): the size limit is 20,000 characters in the whole chat; near it each reply sends about 5,000 tokens, mostly at the cached rate within a session, in full after a break. E2 (30 Oct 2026): the partner runs on GPT-6 Luna, so its share of an ordinary chat is about a fifth of a penny at most and the sitting check (about 1p) is nearly all of a chat's cost; near the limit a partner reply costs well under a tenth of a penny even after a break. Honest limit: Luna is untested by the project for conversation, and the model is switched if it proves too flat.
7. **"Any general AI can do this."** The memory records Andrew's own position that plain correction is not enough. A chat partner that also flags mistakes is also something a general AI app does. The defensible part is the persistent error record and the practice loop, so it should not be allowed to slip behind conversation polish.
8. **Scope.** One developer, two languages, conversation, profile, tracking, game, notifications.
9. **Repo state.** `main` stopped on 27 Jul 2026. All two-pass work (77 files, about 39,000 added lines) sits unmerged on `correction_pipeline_refactor`, last commit 10 Aug 2026. Nothing has been committed anywhere since (re-checked 19 Oct 2026). P1 (19 Oct 2026) decided to merge the branch into `main`: 165 commits, three clashing test files, no change to the app's behaviour. Until Andrew has done the merge on his Mac, the reset still starts from a split codebase.

**Contradictions found between sources**

- Memory says Andrew "recalls settling on" learner-chosen focus areas. The source doc says it appears in no project chat. Treated as new.
- Memory says the linear harness is at `test/two_pass_linear_prompt_comparison_harness.dart`. True only on the branch until the P1 merge is done; true on `main` after it.
- Memory ties the Pass 1 regression to commit `67c728c` / issue #156. In the repo, `67c728c` is issue #154; the #156 schema change is `cc26ab7`. The follow-up #164 ("reframe Pass 1's corrections instruction") is the last commit on the branch; whether the planned revert happened is not visible.
- Account-level memory says the app uses Riverpod. `pubspec.yaml` has no Riverpod; state is `ChangeNotifier`.
- Model: the live Spanish path uses `AppConfig.openAiCorrectionModel`, default `gpt-5.5`. The `gpt-5.6-terra` constant in `app_config.dart` is defined but not referenced anywhere else in `lib/`. P3 (19 Oct 2026): the summer's GPT-4.1 and GPT-5.1 are retired on 14 Jan 2027 and 1 Apr 2027; the reworked check runs on GPT-6 Luna and GPT-6 Sol. The app's other calls (game grading, saving, walkthrough, Portuguese) stay on gpt-5.5 for now.
- The two regional catalogs give different verdicts for the same constructions under the same policy name. Under the new framing this matters less, but neither should be treated as settled truth.

### 2.8 Open decisions

All questions before the first build are decided (2 Nov 2026). See `claude/corregir_decision_log.md`. The ten-item list that used to be here has been removed; several items were settled by the direction (the partner is an AI) and the rest are asked there in stage order.

---

## 3. Build plan: build-ready task list

**Status: rewritten 2 Nov 2026 from decision F1. This replaces the draft of 2 Oct 2026.** The build goes step by step, in slices. Each slice is a version Andrew installs and uses on his phone before the next one starts. Andrew's own answer to F1 fixed slice 1, the onboarding (the introduction and the profile), because it drives the conversations. The order of slices 2 to 5 is Claude's reading of "go logically, step by step", open to Andrew's correction: each slice needs only what came before it.

**Rules for every task.**

- One task is one issue and one change per run.
- Prompt work happens in the test harness before it reaches the app.
- No live AI calls without opt-in. The key comes from the environment only.
- Portuguese is left untouched unless a task says otherwise.
- All work is based on `main` after the merge (task 0.1).
- Storage (E3): everything stays on the phone. Do not add Android backup rules, switch backup off, or build export or restore.
- Model names sit in one setting each: the check uses GPT-6 Luna (Issues) and GPT-6 Sol (Suggestions); the partner uses GPT-6 Luna; the app's other calls stay on GPT-5.5.

### Slice 0: before any app work

- **0.1 Merge (Andrew, on his Mac).** Merge `correction_pipeline_refactor` into `main` (P1). Resolve the three test-file clashes by keeping both sides' test sentences. The app's behaviour does not change.

**Engine track (test harness only, no app changes).** These tasks can run alongside slices 1 and 2. E.1 to E.3 must be finished before slice 2's task 2.1, and E.4 before slice 3.

- **E.1 Prices.** Correct `test/shared/model_pricing.dart` with the prices verified on 19 Oct 2026 (see 2.4).
- **E.2 Baseline run (Andrew, on his Mac; P2, P3).** Run `test/two_pass_linear_prompt_comparison_harness.dart` exactly as it stands: all 85 test sentences, five times each, on GPT-4.1 and GPT-5.1. Record the results on the baseline line below. **Baseline (to be filled in from Andrew's report):** overall pass rate and pass rate per language point; the three unnecessary-pronoun sentences; cost and time per check. The August reference point is 84.5 per cent (359 of 425 runs, 8 Aug 2026).
- **E.3 Rework the two-step prompts in the harness (P4, P5, C1, C3).**
  - Each step makes one call and returns a list of four-part items: what was written, the suggestion, a category, a one-line reason.
  - The first step runs on GPT-6 Luna and returns only Issue categories: Spelling, Grammar, Word meaning.
  - The second step runs on GPT-6 Sol and returns only Natural phrasing. The unnecessary-pronoun line goes in this prompt.
  - Wording rules (C1): the reason line never says "wrong", "error" or "incorrect"; forms common in speech but avoided in careful writing are acknowledged as such. Regional forms are flagged in neither step (C3, C4).
  - Measure against the baseline and report speed per call. The harness measures; it does not gate (P5).
- **E.4 Partner prompt harness (B3, C2, C4, E2).** The partner prompt is run on GPT-6 Luna for:
  - natural replies, with at most one question per reply;
  - no comments on the learner's Spanish, and one short line pointing to the feedback if asked about it;
  - neutral Spanish that follows the learner's forms;
  - the soft goodbye at about ten exchanges, and the sign-off at the size limit;
  - a title and a short summary for each chat.

  Report the cost of a 10-turn chat.

### Slice 1: onboarding (the introduction and the profile). First version on the phone.

- **1.1 Content as data (A1, A2).**
  - An interest list: each interest has an id and English, Spanish and Portuguese labels.
  - About three fuller questions per interest, each written to pull a different structure.
  - The two warm-up questions (one typed, one spoken), each with a small hint in English.
  - The end-screen line.

  Placeholder ("dummy") content is enough to build and ship this slice; Andrew replaces it with his own later. Claude's reading, open to correction: in this slice the introduction runs for Spanish; a learner who picks Portuguese goes straight to today's app, until Portuguese content exists.
- **1.2 Profile model and store (A2).**
  - New `lib/features/profile/` with a `LearnerProfile` model. It has a shared part (the chosen interest ids, and introduction progress and completion) and a per-language part, which is empty for now.
  - A file store writes `learner_profile.json` beside `correction_store.json`, following `lib/features/corrections/data/file_correction_repository.dart`.
  - Offline tests.
- **1.3 Introduction flow (A1).**
  - New `lib/features/introduction/`: a step model (question text, and answer mode: type, microphone or chips), and screens reusing `text_input_panel.dart`, `mic_control.dart` and the existing transcription service.
  - Steps:
    1. the two warm-ups, with no feedback;
    2. the interest chips in the target language;
    3. about three fuller questions drawn from the chosen chips;
    4. the end screen.
  - "Stop for now" is on every step. It goes to the end screen if at least one fuller answer exists, otherwise to the app. Progress is saved so the introduction resumes where it stopped.
  - Shown from `lib/app/spanish_correction_app.dart` between `LanguageSelectionScreen` and `AppShell`, once per install. It is skipped when the profile file says it is complete, including after a language switch.
  - There are no reactions to answers and no skip (B6). The target length is two to three minutes.
- **1.4 Feedback on the fuller answers (A1).**
  - Each fuller answer is sent in the background through `SubmitCorrectionUseCase`, so it lands in History.
  - The end screen offers "See suggestions" or "Not now". "See" walks through `corrections_screen.dart` one answer after another; "Not now" leaves the answers in History.
  - Until slice 2 this uses today's check and its old "Corrections" wording.
- **1.5 Profile screen (A2).** A person icon in the `AppBar` of `lib/features/navigation/presentation/app_shell.dart`, beside settings. It opens a screen listing the learner's interests in English, with add and remove.
- **Done when:** on a fresh install, Andrew can do all of the following:
  - pick Spanish and go through the introduction with one typed and one spoken warm-up;
  - tap interests, then answer the fuller questions by typing or speaking;
  - stop half-way, relaunch and resume;
  - see the answers in History and walk through their suggestions;
  - open the profile and see the interests in English, and have his edits kept;
  - relaunch or switch language without the introduction replaying.

  To run the introduction again while testing, clear the app's data in Android's settings; nothing is built for this.

### Slice 2: the new check on the Check a phrase page (the old Write page)

- **2.1 Suggestion client (P4).** New `lib/features/corrections/data/suggestion_client.dart`. It calls GPT-6 Luna and then GPT-6 Sol with the prompts from E.3 (kept in `correction_prompt.dart`), and parses each reply into `CorrectionItem`s. Use the branch's `naturalness_correction_mapper.dart` as the model for the parser. The group (Issue or Suggestion) is fixed by which step found the point.
- **2.2 Categories (C3).**
  - `ErrorCategory` becomes Spelling, Grammar, Word meaning and Natural phrasing, with one new colour for Word meaning.
  - Items already saved are renamed once on the phone: Word Choice becomes Word meaning, Natural Language becomes Natural phrasing, and Other is dropped.
  - The filters in Saved and in the game use the new list.
- **2.3 Routing.**
  - In `open_ai_correction_service.dart`, Spanish `correctText()` goes to the new client.
  - `write_screen.dart` passes the input mode, so spoken text gets no Spelling items.
  - The introduction's feedback now goes through the same path.
- **2.4 Wording (C1, C5).**
  - In `corrections_screen.dart`, "Corrections" and "Corrected" go; the improved text is the suggested version.
  - The screen shows "Issues" and "Suggestions" headings, and the standing line "These are AI suggestions. Check anything that surprises you."
  - Save is the only action.
- **2.5 Delete the five-stage pipeline (P4).** This is a separate task, done only once 2.3 works on the phone. Archive the stage prompts' wording to a docs file, then delete the pipeline's clients, staged-only domain files, tests and harnesses (list in 2.5). Keep the shared positioning and highlighting code.
- **Done when:**
  - a typed text missing "¿" shows a Spelling Issue, and the same text spoken does not;
  - a calque appears under Suggestions;
  - saved points appear in the game, and old saved points carry the new category names.

### Slice 3: Home and chats (Spanish only)

- **3.1 Home (B1, B2, B5).**
  - In `app_shell.dart`, the first destination becomes a new home screen (`lib/features/home/`) with a home icon and the label "Home". The bar stays at four places.
  - A band of icons holds "Check a phrase", which opens `WriteScreen` unchanged. Scrapbook and Goals are hidden until built (recorded with F1, open to correction).
  - The chat list sits under the band.
- **3.2 Chat model and store (B3).**
  - New `lib/features/conversation/`. A `Chat` has: id, title, language, dates, who started it, kind, turns marked typed or spoken, whether it has ended, its exchange count, and how far it has been checked.
  - Chats are stored in their own JSON file beside `correction_store.json`. The store holds up to five chats; a sixth deletes the oldest without asking. It keeps short summaries of the five most recently deleted chats.
  - An empty New chat is not stored until the learner sends something.
- **3.3 Partner client (E2).** Runs on GPT-6 Luna, with the model name in one setting. Each reply sends only the current chat. The same client writes the title from the first exchange and the summary when a chat is deleted. The prompt comes from E.4.
- **3.4 Chat view (B3, B5).**
  - Partner bubbles on the left, the learner's on the right, with day markers between days.
  - A back link to the list.
  - A message field that grows to about five lines, then scrolls inside itself, with no limit on a single message.
  - Live speech through the phone's own recognition (for example `speech_to_text`), editable before sending.
  - No "New question" control.
- **3.5 Endings (B3, E1).**
  - The soft goodbye comes at about ten exchanges; after it the partner answers but asks nothing more.
  - Before each reply the app adds up all the characters in the chat. At 20,000 (one constant), the partner signs off and the field is replaced by "This chat has ended" and New chat.
- **Done when:** Andrew can do all of the following:
  - start a chat, and talk by voice and by text;
  - get the soft goodbye;
  - come back the next day to a day marker and a partner that carries on;
  - start a sixth chat and see the oldest go;
  - see a long chat end at the limit.

### Slice 4: feedback from chats, and History

- **4.1 The check after each sitting (B3, P4).**
  - Runs when a sitting ends: the partner's goodbye, the size limit, or the learner leaving the chat. It also runs when a chat is deleted.
  - It sends the learner's turns since the last check, joined one per line, through `suggestion_client.dart`.
  - The results are added to that chat's History card.
- **4.2 The strip (B3, C1).**
  - Shown only if something was found while the learner is still in the chat: "N issues, N suggestions from this chat", See, and a cross.
  - See opens the chat's History entry, and Back returns to the chat.
  - The cross, or leaving the chat, closes it for good.
- **4.3 History cards (B3, C1).**
  - Chats and checked texts are listed together.
  - Each card has a count on every category chip and a green left edge.
  - Tap chips, then swipe right to save them; swipe right with nothing chosen to be asked whether to save everything.
  - An opened chat card shows each sitting as an outlined pair, the Original with highlights and the suggested version, under the Saved screen's filter row. Tapping a highlighted phrase opens today's sheet with "Save for later".
  - Neutral wording throughout.
- **4.4 History trimming (D1).** History keeps 20 cards. When a new card would make 21, `addSubmission` in `file_correction_repository.dart` removes the oldest card with at least one saved point, or otherwise the oldest card. It never removes the card of a chat still on Home. Saved is not touched.
- **Done when:**
  - a chat with seeded mistakes shows the strip when the sitting ends;
  - See opens the card;
  - chips can be saved by swiping, and single points by tapping;
  - saved points appear in the game;
  - adding a 21st card removes the right one.

### Slice 5: the partner's greetings

- **5.1 Partner settings (B4).** Up to two greeting times a day and an on-or-off switch, stored with the other settings.
- **5.2 Notifications (B4).**
  - A local notifications package (for example `flutter_local_notifications`), with permission asked once.
  - One notification at each set time, using one of three fixed invitations in rotation. Andrew writes the phrases; placeholders are enough to start.
  - Rescheduled when the settings change and each time the app starts; cancelled when greetings are off.
  - Exact-to-the-minute timing is optional.
- **5.3 The opener (B3, B4).**
  - Tapping the notification, or opening the app after a set time, creates the greeting chat.
  - One partner call writes the opener: a check-in, or a follow-up from the active chats and the summaries. Typing dots show while it is written.
  - With no connection or a failed call, the chat opens with "¡Hola! ¿Qué tal?".
  - A greeting counts as one of the five chats only when the learner answers it. An unanswered greeting is cleared at the next daily refresh, and an unanswered follow-up after 48 hours, both checked when the app opens.
- **Done when:**
  - a set time brings a notification, and tapping it opens a chat with a fresh opener;
  - with the phone offline, the fixed line appears;
  - switching greetings off stops the notifications.

### After the first build (not planned here)

The following each come one at a time once the app is in use:

- the scrapbook, with a sensible cap set when it is designed (E3), and goals and specifics;
- the learner-set chat length;
- the interests-led, scrapbook and topical openers, with a kinds-of-chat setting;
- query buttons and on-demand regional notes (C4, C5);
- stage D features, working from Saved (D1);
- Portuguese chats;
- backup and cloud storage, if the app is ever released (E3).

### Suggested next single task for Claude Code

Once Andrew has done the merge (0.1): task 1.2, the profile model and file store with offline tests. It touches no screens and no AI calls, and the introduction (1.3) builds on it.

### Build progress

Kept by the scheduled build run. One step per run, in the order of this section. A step is done only when it is recorded here.

- [ ] **0.1 Merge `correction_pipeline_refactor` into `main` (Andrew, on his Mac).** Waiting for Andrew (set 3 Nov 2026). Checked that day: `main` does not yet contain the summer branch's work, and the branch is not on GitHub, so it exists only on Andrew's Mac.
- [ ] E.1 Prices
- [ ] E.2 Baseline run (Andrew, on his Mac)
- [ ] E.3 Rework the two-step prompts in the harness
- [ ] E.4 Partner prompt harness
- [ ] 1.1 to 1.5 Slice 1: onboarding
- [ ] 2.1 to 2.5 Slice 2: the new check
- [ ] 3.1 to 3.5 Slice 3: Home and chats
- [ ] 4.1 to 4.4 Slice 4: feedback from chats, and History
- [ ] 5.1 to 5.3 Slice 5: the partner's greetings
