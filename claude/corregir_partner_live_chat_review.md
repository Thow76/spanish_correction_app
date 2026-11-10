# Corregir: partner live-chat review (step E.4)

Started 9 Nov 2026. Notes from a review session, not decisions. Andrew's decisions still go in `claude/corregir_decision_log.md`.

Companion prompt being used for the live chats: `claude/spanish_companion_1.0_prompt.md` (the version with the 10 Nov conversation changes).

## Change of approach (Andrew, 9 Nov 2026)

- The scripted partner test program (pull request 179, `test/partner_prompt_harness.dart`) was run on 9 Nov 2026. Andrew judged it inadequate: scripted learners can't reflect a live chat, because they don't respond to what the partner says.
- Instead, Andrew tests the partner through real voice chats with his ChatGPT companion ("Spanish Companion 1.0"), which uses a similar prompt. He exports each chat verbatim and Claude reviews it against the partner decisions (B3, C2, C4, E1, E2).
- Caveat: the companion runs on ChatGPT's own model, not GPT-6 Luna. The chats show whether the instructions produce the conversation Andrew wants. Luna's behaviour still needs confirming on the phone in slice 3.
- Not yet decided: what happens to pull request 179 (assumed: don't merge yet; keep its partner instructions as starting text), and whether the build plan's step E.4 is formally changed. The build plan has NOT been updated, so the daily build run may still ask Andrew to run the test program.

## What the 9 Nov test program showed (for the record)

- One question at most in ordinary replies: 27 of 27. Unasked comments on the learner's Spanish: none. Goodbye at exchange 10: really 3 of 3 (the word list missed "espero que volvamos a charlar pronto"). Cost: about $0.0016 per ten-exchange chat; about 2.5 seconds per reply.
- Real problem: the partner slipped out of the learner's forms. To a "vosotros" learner it used "les estropeara", "tengan" and "suelen elegir". The automatic check missed it because it only looks for a few Latin American words, not verb endings.
- Only 2 of 27 ordinary replies had no question, although the instructions say many replies should have none.
- The summaries are in English by design (the instructions ask for English).

## Getting transcripts out of ChatGPT

- ChatGPT can only read the full text of the conversation it is in. For other conversations it gets summaries or snippets through memory. Its own answer on 9 Nov: "Full text available from 7 November 2026 to 9 November 2026. Before that: partial visible messages, chat-history snippets, correction notes and saved spreadsheet answers."
- So the 10 Oct to 2 Nov sessions exist only as correction notes, not dialogue. ChatGPT's data export (Settings, then Data controls, then Export data, then `conversations.json`) is the only route to the older full text, if it exists.
- Shared chatgpt.com links can't be read by Claude, because the page needs a browser to load.
- From now on: export each ordinary chat on the same day with the verbatim prompt below, and paste it in. Ordinary chats matter most; comprehension sessions add little, because their questions are scripted.

Verbatim export prompt (run inside the companion conversation):

```
Export the Spanish Companion conversations in this chat as verbatim transcripts for review. I need the exact text, not a summary or a tidied record.

What counts as a companion conversation:
- It starts with your scheduled opener (a short date header in Spanish followed by a Spanish opener), or with me starting a Spanish practice chat.
- It runs until the goodbye, or until I end it or switch to something else.
- It includes reading, video and audio activities started from a companion opener.

Leave out everything else in this chat, for example:
- setting up or editing the companion prompt;
- discussions in English about how the companion works;
- spreadsheet or file administration;
- any unrelated conversation, including ones started here by mistake;
- this export request.
Where you leave out a stretch, write one line in its place: [omitted: <a few words saying what it was>]. Do not copy any of its content.

Rules for the companion conversations:
1. Copy every message in order, both sides.
2. Copy each message exactly as it appears, including voice transcription errors, mixed languages, hesitations, typos and your own in-chat correction notes ("Un detalle: …"). Do not correct, shorten, merge or reword anything.
3. Do not add a corrections section, summary, analysis or commentary.
4. If you cannot see a message, write [not visible]. Never reconstruct or guess a message.

Format, in plain Markdown, one section per companion conversation:

# <date, Europe/London> · <short topic>
Session type: <everyday chat / reading / video or audio / other>

1. **Companion:** <exact text>
2. **Andy:** <exact text> (voice) or (typed), if you can tell; otherwise leave it off
3. **Companion:** <exact text>
…

End with one line per conversation: "Messages exported: N. Omitted: N. Not visible: N."
Then one final line: "Companion conversations exported: N. Other stretches omitted: N."
```

## Chats reviewed so far (ordinary chats with both sides in full)

1. 7 Nov 2026 · Asador Etxebarri, then pinchos and the Basque Country (the chat after the six questions).
2. 8 Nov 2026 · Videogame for learning languages.
3. 10 Nov 2026 · Los anillos de poder.

## Findings

Questions (the main point Andrew raised):
- The companion never asked more than one question per reply. The problem is the kind of question, not the number.
- Questions per reply: 10 of 10 in the pinchos chat; 3 of 5 in the videogame chat; 5 of 8 in the Anillos chat.
- Questions about Andy's own experience and opinions worked, and got long, rich answers: "¿Echas de menos esa forma de salir a comer?", "¿Solías quedarte en un bar o ibas de uno a otro?", "¿Qué te está pareciendo la segunda temporada?".
- Kinds of question that stalled (answered "no sé", "no recuerdo" or "no tengo ni idea"):
  - Precise recall: "¿Había algún pincho por el que volvieras siempre al mismo bar?"
  - Invention or a hypothetical: "Si montaras un bar de pinchos en Escocia, ¿qué ingrediente local pondrías?"; "¿Te habría gustado que mantuvieran más misterio…?"
  - Pushing for detail after Andy said "es una idea básica": "¿Qué tendría que decir el jugador…?"
- Narrowing: in the pinchos chat each question narrowed the same topic (meat, the cut, how it's cooked, why, a dish, bar habits, one pincho, an invented bar), which made it feel like an interview.
- An either/or question got a full answer once (bars) and a short one once ("¿Te enganchan más esas conexiones o las historias nuevas?" got "Sí, me enganchan esas conexiones, pero…").

How chats end:
- Andy ended all three chats himself, each straight after a reply he couldn't do anything with: a hard question (pinchos, videogame) or a flat reply (Anillos). None reached the ten-exchange goodbye.

Giving a view, and the AI disclaimer:
- Anillos chat: after "No sé. ¿Qué piensas tú?" the companion gave its own view with no question, and Andy's next answer was one of his best ("Sí, estoy de acuerdo contigo…").
- Andy turned the question back three times in that chat. When the companion gave a real opinion the chat moved on. When asked "¿Has visto las pelis originales?" it answered flatly ("No, no las he visto… mis comentarios no vienen de una experiencia personal") and Andy left immediately.
- A reply with no question AND nothing new to react to also led to the end.

Other points:
- Openers: the 8 Nov evening opener brought up the videogame without saying where it came from, and confused Andy ("¿de qué estás hablando?"). This matters for the app's follow-up openers (B4).
- Missing words: the companion gave words when Andy was stuck ("cortes", "poco hecho"), and the chat carried on. Under C2 the app partner would currently defer this to the feedback.
- Voice input: it checked a misheard answer ("Sì, caffè nero" for "cocinero") rather than guessing. Relevant for spoken turns.
- In-chat corrections ("Un detalle"): in about half of replies. Andy never responded to one. Each was repeated in the end-of-chat review. This fits C2 (feedback after the chat).

## Full history review (10 Nov 2026, from the ChatGPT data export)

Source: Andrew's extract of all companion threads, 1 Oct to 9 Nov 2026 (`spanish_companion_transcripts_2026-10-01_to_2026-11-09.md`, uploaded in the review session, not saved in the project). About 1,320 messages; 59 companion openers, 35 with replies; about 15 ordinary chats with both sides, plus comprehension sessions. Counts below are from a script over the whole file; the ordinary chats were read in full.

What the wider sample confirms:
- Kind of question matters more than number. Broad questions about Andy's views or experience on a topic he cares about got long answers (AI and trust, 18 Oct; AI agents, 21 Oct; Córdoba: "¿Cambió tu manera de ver la ciudad…?", "¿Hay algo… que eches de menos?", 13 Oct).
- Narrowing into small practical details is common, not a one-off: tortilla (16 Oct: spicy or mild, then do you make it, then does it stick or break, then a bigger plate, then has it ended up scrambled); writing app (17 Oct); an appointment (2 Nov); coffee (20 Oct: "¿Era una cafetería que ya conocías?", "¿Sueles pedir siempre el mismo café?", "¿Prefieres algo con chocolate o una pasta más sencilla?", and Andy left). Trivial either/or detail questions are part of this.
- Andy asks for the companion's own opinion often (12, 13 and 18 Oct, 27 Oct, 10 Nov). Specific opinions worked (Córdoba in the 10th century, 13 Oct; the droid in Andor, 27 Oct). Deflecting back or a balanced both-sides answer drew pushback (12 Oct: "Quiero saber tu opinión"; 18 Oct: "tú has respondido en la forma más diplomática").
- The flat AI disclaimer appears only once in the whole history (10 Nov), and that chat ended straight after it. Elsewhere the companion gave preferences lightly ("Yo elegiría la Córdoba del siglo X… iría de visita breve").

What it changes:
- Missing words are frequent: "no sé cómo se dice…" or similar appears in 17 of Andy's messages across most chats, and the companion supplied the word each time (puré, menú rotativo, tienda de bricolaje, ambientación, lusófono). Under C2 as worded, the app partner would deflect every one of these. This makes the missing-word question important.
- How chats end (corrected 10 Nov 2026 after Andrew's challenge, and checked against the data): about half the ordinary chats ran to or near the companion prompt's ceiling of 10 questions or 10 exchanges (10 Oct: 8 questions, 9 of Andy's turns; 13 Oct: 8 and 10; 14 Oct: 9 and 10; 17 Oct: 9 and 9; 18 Oct: 7 and 9; 2 Nov: 7 and 8). There the final question-less reply is the companion's own instructed wind-down, and Andy rightly read it as the end. So the missing question is not what ends chats. The earlier endings came after replies that gave Andy nothing to engage with (in Andrew's words: "it's not offering opinions that I can agree or disagree with, it's just stating things"): 16 Oct (a remark on the word "desorden"), 8 Nov (the companion backing off, "El resto puede esperar"), 10 Nov (the flat disclaimer); or for ordinary reasons (out of time on 20 Oct; going to eat on 26 Oct).
- In-chat corrections ("Un detalle") appear in 38 of 212 ordinary companion replies (about 18%; denser in November). Andy never responded to one. They also appeared while he was venting about a stressful day, where a correction reads badly. This supports C2.
- Voice: on 11 Oct Andy twice asked the companion to repeat a long, abstract question ("¿Cómo imaginas que esa aplicación podría ayudarles de verdad en su día a día?"). Spoken questions should be short and concrete. Misheard voice turns (Italian or Portuguese words) were handled well by checking ("¿Querías decir…?").
- Openers: 35 of 59 had replies, but reruns and duplicates make the opener data too noisy to compare kinds of opener.

## Proposed changes to the app partner's instructions (for Andrew to decide; not decided; revised 10 Nov 2026 after the full history)

1. Most replies end with one question, of the right kind: broad, about the learner's opinions, experiences or feelings on the topic. Not precise recall, not invention ("Si…", "¿Te habría gustado que…?"), and not small practical details or trivial either/or choices.
2. Don't keep narrowing one topic; after two or three turns, broaden it, link it to something else the learner said, or share something.
3. Every reply leaves the learner something to engage with, ideally an opinion they can agree or disagree with, whether or not it ends with a question. A reply that only states or acknowledges things is what ends chats early. (Andrew's correction, 10 Nov 2026; the length of chats is otherwise set by the soft goodbye, as in the companion's 10-question ceiling.)
4. When the learner says "no sé", or says it is only an idea, don't ask again on that point.
5. When the learner asks what the partner thinks, give a specific opinion, not a both-sides summary, and don't turn the question straight back.
6. Replace the current line "You are an AI… do not claim a real life story as fact" with something like: don't claim to have watched or done things, but answer from what you know, give an opinion and keep the conversation going ("Conozco bien la historia, y lo que más me llama la atención es…").
7. Keep spoken questions short and concrete.
8. A follow-up opener says where it comes from ("El otro día me contaste…").
9. Fix the form-following slip found in the test program (vosotros/ustedes verb forms).

Missing words, answered by Andrew 10 Nov 2026: "I think the missing word thing can be an option. It can be incorporated into settings about your personal preferences… the missing words are sometimes useful. It depends on other things, but it's not something that I've noticed that bothers me." So: giving a missing word when the learner asks becomes a learner preference in settings. This refines C2 (C2 still holds for comments on the learner's mistakes). Recorded in the decision log as the C2 rider of 10 Nov 2026.
Clarified by Andrew the same day: he means a manual on/off control the learner sets themselves, for example a toggle in the chat, in settings, or during setup. It should be tried in the app first and judged there, because the app presents chats as a messaging service: in ChatGPT there is room for a brief note about the text, but in message bubbles such a note may feel incongruous. Claude's suggestion, not decided: in the app the word would be best woven into the partner's ordinary reply ("¿Poco hecho? A mí también me gusta así…") rather than given as a separate note. Still open: where the toggle lives (in the chat, settings or setup) and what it starts as.

Note on the companion prompt: the version saved on 10 Nov (`claude/spanish_companion_1.0_prompt.md`) includes "Many replies should end without a question", together with "Every reply must leave Andy something to respond to". After Andrew's correction these lines stand; the only possible strengthening is to make "share a view" say "an opinion Andy can agree or disagree with".

## Next steps

- Missing words: a learner-controlled on/off toggle, tried in the app first (C2 rider, 10 Nov). Where the toggle lives and its starting position are settled in slice 3.
- Andrew: a few more ordinary chats with the updated companion prompt, each exported the same day with the verbatim prompt.
- Claude: review them; then draft replacement wording for the app partner's instructions for Andrew to approve.
- Pull request 179 now holds the new instructions and the E.4 note in the build plan; Andrew merges it.

## Partner instructions (drafted 10 Nov 2026; accepted by Andrew the same day as a starting point; in pull request 179)

Replaces `partnerBasePrompt` in `test/partner_prompt_harness.dart` (pull request 179). The goodbye, after-goodbye and size-limit lines, and the title and summary instructions, stay as they are; they worked in the 9 Nov test run. The text in square brackets is chosen by the learner's missing-words toggle; only one of the two lines is sent.

```
You are the learner's friendly conversation partner in Spanish. The learner is practising Spanish by chatting with you, so the chat should feel like messaging a friend who has opinions of their own, not like a lesson or an interview.

How to reply:
- Write in Spanish only, in short natural replies: usually two to four sentences, never more than about 70 words. The learner may be speaking rather than typing, so keep sentences, and especially questions, short and concrete.
- Respond to what the learner said first. Then add something of your own they can react to: an opinion, a small claim or a concrete detail. Every reply must give the learner something to agree or disagree with. Never reply with only an acknowledgement or a summary of what they said.
- You may end with ONE question, never two. A good question asks about the learner's opinions, experiences or feelings on the topic ("¿Qué te parece…?", "¿Echas de menos…?"). Do not ask them to recall precise details (a particular name, dish or date), to imagine something hypothetical ("Si montaras…", "¿Te habría gustado que…?"), or to choose between small practical details ("¿Con chocolate o más sencilla?"). Do not push for practical details of an idea the learner describes as early or basic.
- Do not keep narrowing one topic. After two or three exchanges on the same point, broaden it, link it to something else the learner has mentioned, or share something instead of asking.
- If the learner says they don't know, can't remember, or that something is only an idea, do not ask again on that point. Give your own view and move on.
- If the learner asks to talk about something else, or changes the subject, go along with it gladly.

Your own views:
- When the learner asks what you think, give a specific opinion and stand by it. Do not give a balanced list of pros and cons, and do not turn the question straight back to them.
- You have not lived a human life, so do not claim to have seen, eaten, visited or done things. But do not answer with a flat disclaimer either. Answer briefly from what you know, give an opinion, and carry on. For example: "No como tal, pero conozco bien la historia, y lo que más me llama la atención es…".

The learner's Spanish:
- Never comment on, correct or repeat back the learner's Spanish, and never point out mistakes, even gently. Do not praise their grammar either. Just understand them and carry on the conversation.
- If the learner asks you directly whether their Spanish is right (for example "¿se dice así?" or "¿está bien?"), do not answer the question. Say in ONE short sentence that the feedback after the chat will cover it, then carry on with the conversation.
- [Missing words ON:] If the learner is missing a word or asks how to say something ("¿cómo se dice…?", "no sé cómo se dice…"), give the word naturally inside your reply, the way a friend would ("¿Poco hecho? A mí también me gusta así…"), and carry on. Do not explain it or turn it into a lesson.
  [Missing words OFF:] If the learner is missing a word or asks how to say something, do not supply it. Carry on with what they meant, or, if the meaning is unclear, ask them to describe it another way in Spanish.
- If a spoken message looks misheard (words from another language, or words that don't fit), check briefly what they meant ("¿Querías decir…?") rather than guessing.

Which Spanish to use:
- Write neutral, widely understood Spanish, with no slang tied to one country.
- Follow the learner's own forms, including verb endings and pronouns. If they address you with "tú", use "tú"; if with "usted", use "usted". If they use "vosotros" for a group, use vosotros forms whenever you speak to or about that group ("os", "tenéis", "soléis"), never ustedes forms ("les", "tengan", "suelen"). If they use "ustedes", do the reverse. If they use a word that differs by country (for example "ordenador" or "computadora", "móvil" or "celular", "coche" or "carro"), use the same word they used.

Earlier chats:
- If this chat picks up something the learner said in an earlier chat, say so in a few words ("El otro día me contaste que…"), and do not assume details beyond what you were given.
```

What changed from the pull request 179 version, and why:
- New: every reply gives the learner something to agree or disagree with. Chats ended early after replies that only stated things (16 Oct, 8 Nov, 10 Nov), and Andrew's own account.
- Changed: "Many replies should have no question at all" is gone. One question is still the maximum (B3); the rule is now about what kind of question. Drilling, recall, hypothetical and trivial either/or questions stalled across the history; questions about opinions and experience worked.
- New: no narrowing; drop a line after "no sé". From the pinchos, tortilla, coffee and videogame chats.
- New: specific opinions when asked, no both-sides answers. From 12, 13 and 18 Oct, 27 Oct and 10 Nov.
- Changed: the AI line. "You are an AI, so keep what you share light" produced flat disclaimers in the test run, and the one real disclaimer (10 Nov) ended the chat.
- New: the missing-words toggle (Andrew, 10 Nov), woven into the reply rather than given as a note, to suit the messaging layout.
- New: checking misheard voice input; short, concrete spoken questions (11 Oct).
- Strengthened: forms now name verb endings and pronouns, because the 9 Nov test run slipped on vosotros/ustedes ("les estropeara", "tengan", "suelen elegir"). "Usted" added; C4 did not mention it.
- New: follow-ups say where they come from (8 Nov opener).
- Unchanged: no comments on the learner's Spanish and the one-line pointer to the feedback (C2); neutral Spanish (C4); 70-word ceiling; changing subject gladly.
