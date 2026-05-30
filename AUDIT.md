# Spanish Correction App — Codebase Audit

Generated: 2026-05-31

---

## 1. Project Structure

### `lib/`
| File | Purpose |
|------|---------|
| `main.dart` | Entry point; calls `runApp(SpanishCorrectionApp())` |

### `lib/app/`
| File | Purpose |
|------|---------|
| `spanish_correction_app.dart` | Root `StatefulWidget`; wires up services from `AppConfig` and passes them into `AppShell` |
| `app_config.dart` | Reads `--dart-define` env vars; exposes `AppConfig` value object and `CorrectionProvider` enum |
| `app_theme.dart` | Builds the single `ThemeData` (dark Material 3) used app-wide |

### `lib/features/corrections/`
#### `application/`
| File | Purpose |
|------|---------|
| `correction_repository.dart` | Abstract interface for all persistence operations |
| `correction_repository_controller.dart` | `ChangeNotifier` that wraps the repository and exposes reactive state to the UI |
| `correction_response_schema.dart` | Shared JSON schema and shape strings embedded in AI prompts |
| `correction_service.dart` | Abstract interface for the AI correction service |
| `correction_service_exception.dart` | `CorrectionServiceException` + `CorrectionFailureReason` enum |
| `submit_correction_use_case.dart` | Orchestrates online correction vs. offline queuing |
| `sync_queued_submissions_use_case.dart` | Drains the offline queue when connectivity is restored |

#### `data/`
| File | Purpose |
|------|---------|
| `file_correction_repository.dart` | `CorrectionRepository` backed by a single JSON file on device storage |
| `gemini_correction_service.dart` | `CorrectionService` calling the Gemini REST API; holds the Gemini system prompts |
| `open_ai_correction_service.dart` | `CorrectionService` calling the OpenAI Responses API; holds the OpenAI system prompts |

#### `domain/`
| File | Purpose |
|------|---------|
| `correction_item.dart` | Individual correction with phrase, category, range indexes, and grapheme-aware anchoring logic |
| `correction_response.dart` | Full AI response (original text, corrected text, list of `CorrectionItem`) with reconstruction logic |
| `error_category.dart` | `ErrorCategory` enum (Grammar, Natural Language, Spelling, Word Choice, Other) with display label and colour |
| `queued_submission.dart` | Offline-queued submission waiting for connectivity |

#### `presentation/`
| File | Purpose |
|------|---------|
| `corrections_screen.dart` | Full-screen result view; shows highlighted original/corrected text and a bottom sheet per correction |

### `lib/features/history/`
#### `domain/`
| File | Purpose |
|------|---------|
| `correction_submission.dart` | A completed submission stored in history (id + `CorrectionResponse` + timestamp) |
| `submission_summary.dart` | Lightweight view model used when only summary data is needed |

#### `presentation/`
| File | Purpose |
|------|---------|
| `history_screen.dart` | Lists recent submissions grouped by Today / This Week / Older with swipe-to-delete |

### `lib/features/navigation/`
#### `presentation/`
| File | Purpose |
|------|---------|
| `app_shell.dart` | Hosts the three-tab `NavigationBar` (Write / History / Saved) and manages offline sync |

### `lib/features/saved/`
#### `application/`
| File | Purpose |
|------|---------|
| `save_correction_use_case.dart` | Calls the AI to generate a structured explanation, then persists a `SavedCorrection` |

#### `domain/`
| File | Purpose |
|------|---------|
| `saved_correction.dart` | A bookmarked correction with full sentence context, explanation, and timestamp |
| `saved_explanation.dart` | Structured AI explanation (why it's wrong, in-context example, alternatives) |

#### `presentation/`
| File | Purpose |
|------|---------|
| `saved_screen.dart` | Grid of saved corrections, filterable by `ErrorCategory`, with swipe-to-delete |
| `saved_detail_screen.dart` | Detail view for a single saved correction with collapsible sections |

### `lib/features/write/`
#### `application/`
| File | Purpose |
|------|---------|
| `transcription_service.dart` | Abstract interface for audio transcription |
| `transcription_service_exception.dart` | `TranscriptionServiceException` + `TranscriptionFailureReason` enum |

#### `data/`
| File | Purpose |
|------|---------|
| `open_ai_whisper_transcription_service.dart` | `TranscriptionService` that POSTs WAV audio to OpenAI Whisper |

#### `presentation/`
| File | Purpose |
|------|---------|
| `write_screen.dart` | Main input screen; text field, character counter, microphone control, and submit button |

### `lib/shared/`
#### `design/`
| File | Purpose |
|------|---------|
| `app_colors.dart` | All colour constants used in the app |
| `app_spacing.dart` | Named spacing constants (xs → xxl) |

#### `network/`
| File | Purpose |
|------|---------|
| `network_status_service.dart` | Abstract interface for connectivity checks and change stream |
| `connectivity_network_status_service.dart` | Implementation backed by `connectivity_plus` |

#### `widgets/`
| File | Purpose |
|------|---------|
| `app_header.dart` | Reusable 56 px screen header with optional leading widget |
| `empty_state_panel.dart` | Card with icon, title, and message for empty list states |
| `primary_action_button.dart` | Full-width CTA button with loading spinner |

---

## 2. Data Models

### `CorrectionItem` (`lib/features/corrections/domain/correction_item.dart`)
```dart
class CorrectionItem {
  final String originalPhrase;
  final String correctedPhrase;
  final ErrorCategory category;
  final String shortExplanation;
  final int? startIndex;       // grapheme-based, inclusive
  final int? endIndex;         // grapheme-based, exclusive
  final int? correctedStartIndex;
  final int? correctedEndIndex;
}
```

### `CorrectionResponse` (`lib/features/corrections/domain/correction_response.dart`)
```dart
class CorrectionResponse {
  final String originalText;
  final String correctedText;
  final List<CorrectionItem> corrections;
}
```

### `ErrorCategory` (`lib/features/corrections/domain/error_category.dart`)
```dart
enum ErrorCategory {
  grammar('Grammar', AppColors.grammar),
  naturalLanguage('Natural Language', AppColors.naturalLanguage),
  spelling('Spelling', AppColors.spelling),
  wordChoice('Word Choice', AppColors.wordChoice),
  other('Other', AppColors.other);

  final String label;
  final Color color;
}
```

### `QueuedSubmission` (`lib/features/corrections/domain/queued_submission.dart`)
```dart
class QueuedSubmission {
  final String id;
  final String text;
  final DateTime createdAt;
}
```

### `CorrectionSubmission` (`lib/features/history/domain/correction_submission.dart`)
```dart
class CorrectionSubmission {
  final String id;
  final CorrectionResponse response;
  final DateTime createdAt;
}
```

### `SubmissionSummary` (`lib/features/history/domain/submission_summary.dart`)
```dart
class SubmissionSummary {
  final String originalText;
  final String correctedText;
  final DateTime createdAt;
  final int errorCount;
}
```

### `SavedCorrection` (`lib/features/saved/domain/saved_correction.dart`)
```dart
class SavedCorrection {
  final String id;
  final ErrorCategory category;
  final String shortExplanation;
  final String originalSentence;
  final SavedExplanation explanation;
  final DateTime savedAt;
  final String correctedPhrase;
  final String originalPhrase;
  final String correctedSentence;
}
```

### `SavedExplanation` (`lib/features/saved/domain/saved_explanation.dart`)
```dart
class SavedExplanation {
  final String whyItsWrong;
  final String inContext;
  final List<String> alternatives;
}
```

---

## 3. State Management

**Approach:** Manual `ChangeNotifier` — no third-party state management library (no Provider package, Riverpod, Bloc, etc.).

Services and the repository controller are instantiated in `_SpanishCorrectionAppState.initState()` and passed down the widget tree as constructor arguments.

### Controllers / Notifiers

| Class | File | Role |
|-------|------|------|
| `CorrectionRepositoryController` | `lib/features/corrections/application/correction_repository_controller.dart` | The only `ChangeNotifier`. Holds `recentSubmissions`, `savedCorrections`, `queuedSubmissions`, and `isLoadingHistory`. Widgets call `addListener` / `removeListener` directly. |

### Reactive observations
- `HistoryScreen` calls `repositoryController.addListener(_handleRepositoryChanged)` in `initState` and `setState(() {})` on every change.
- `SavedScreen` does the same pattern.
- `AppShell` listens to `NetworkStatusService.connectionChanges` (a `Stream<bool>`) via a `StreamSubscription` to trigger offline sync.

---

## 4. Navigation / Routing

**Approach:** Plain `Navigator` — no named routes, no GoRouter, no auto_route.

### Tab navigation
`AppShell` renders a Flutter `NavigationBar` with three destinations. Tab switches update `_selectedIndex` via `setState`; the body shows `screens[_selectedIndex]` directly (no push).

```
Write (index 0) → WriteScreen
History (index 1) → HistoryScreen
Saved (index 2) → SavedScreen
```

### Pushed routes (all use `MaterialPageRoute`)

| Source | Destination | Trigger |
|--------|-------------|---------|
| `WriteScreen` | `CorrectionsScreen` | Submit button success |
| `HistoryScreen` | `CorrectionsScreen` | Tap a history card |
| `SavedScreen` | `SavedDetailScreen` | Tap a saved correction card |

### Modal sheets
- `CorrectionsScreen` opens a full-height `showModalBottomSheet` when a highlighted correction is tapped.

---

## 5. Local Storage

**Library:** Custom file-based JSON store using `dart:io` (`File`) and `path_provider` (`getApplicationDocumentsDirectory`).  
No Hive, Isar, SharedPreferences, or SQLite.

### File
| Filename | Location |
|----------|----------|
| `spanish_correction_store.json` | `<ApplicationDocumentsDirectory>/spanish_correction_store.json` |

### JSON keys written / read

| Key | Type | Description |
|-----|------|-------------|
| `recent_submissions` | `List<CorrectionSubmission>` | Up to 20 most recent correction results |
| `saved_corrections` | `List<SavedCorrection>` | All bookmarked corrections (unbounded) |
| `queued_submissions` | `List<QueuedSubmission>` | Offline-queued texts awaiting sync |

The entire file is read and rewritten atomically on every mutation (no partial updates). The `recent_submissions` list is capped at 20 items (`_recentLimit = 20`).

Temporary audio files for recording are written to `getTemporaryDirectory()` with the pattern `spanish-recording-<microseconds>.wav` and are not cleaned up explicitly.

---

## 6. Gemini Integration

### How the request is sent (`lib/features/corrections/data/gemini_correction_service.dart`)

```dart
// Endpoint
Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$_model:generateContent')

// Headers
'x-goog-api-key': _apiKey
'Content-Type': 'application/json'

// Body structure
{
  "system_instruction": { "parts": [{ "text": <systemInstruction> }] },
  "contents": [{ "parts": [{ "text": "Review this Spanish text:\n\n$text" }] }],
  "generationConfig": {
    "temperature": 0.2,
    "responseMimeType": "application/json"   // "text/plain" for long explanation
  }
}
```

Timeouts: 10 s to open connection, 30 s to read response.

### Correction system prompt (full text)

```
You are a Spanish correction engine for a mobile language-learning app.

Return only valid JSON with this exact shape:
{
  "original_text": "string",
  "corrected_text": "string",
  "corrections": [
    {
      "start_index": 0,
      "end_index": 0,
      "original_phrase": "string",
      "corrected_phrase": "string",
      "category": "string",
      "short_explanation": "string"
    }
  ]
}

Rules:
- Preserve the user's original text in original_text.
- corrected_text must contain a polished corrected version of the whole text.
- Each correction must identify the text being corrected with start_index, end_index, and original_phrase.
- original_phrase must be the exact substring of the submitted text between start_index and end_index, copied character-for-character including accents, ñ, and Spanish punctuation.
- For zero-length insertion ranges, original_phrase must be an empty string.
- Before returning each correction, verify that original_phrase matches the slice your indexes point to; if it does not, fix the indexes so they do. The app rejects any correction where they disagree.
- start_index is zero-based and inclusive.
- end_index is zero-based and exclusive.
- For missing punctuation or any other inserted text, use an empty range where start_index equals end_index at the insertion point.
- Insertion points must fall on a word boundary (start of text, end of text, or next to whitespace or punctuation). Never insert in the middle of a word.
- Do not replace a neighboring character just to add missing punctuation.
- Indexes must refer only to the submitted Spanish text, not the instruction text or labels.
- Indexes are measured in user-perceived characters, not bytes.
- Accented letters, ñ, inverted punctuation, emoji, and combining-accent sequences each count as one user-perceived character.
- category must be exactly one of: Grammar, Natural Language, Spelling, Word Choice, Other.
- short_explanation must be one informal but technically accurate sentence.
- If there are no corrections, return an empty corrections array and keep corrected_text equal to original_text.
- Do not include Markdown, code fences, commentary, or keys outside the requested JSON.
- Do not create Spelling corrections for accents or Spanish characters that are already present in the submitted text.

Category rules:
- Grammar: grammatical structure, verb conjugation, agreement, tense, pronoun use, preposition use, and punctuation.
- Natural Language: phrasing that is technically understandable but unnatural, awkward, overly literal, an anglicism or false friend, or not how a native speaker would normally write it. Flag these actively, even when the meaning is clear — naturalness is one of the main things learners need to learn.
- Spelling: misspellings, missing or incorrect written accents/diacritics, and orthographic errors.
- Word Choice: incorrect or suboptimal vocabulary choice where grammar and spelling are otherwise acceptable.
- Other: only use this for genuine edge cases that do not fit the categories above.

Natural language handling:
- Actively look for phrasing that is technically valid Spanish but not how a native speaker would express the idea. Do not skip these because the meaning is understandable.
- Flag anglicisms and false friends where Spanish prefers a different word (e.g. "memorias" used to mean "memories" should be "recuerdos"; "realizar" used to mean "to notice" should be "darse cuenta"; "atender" used to mean "to attend a class" should be "asistir").
- Flag overly literal English-style constructions where Spanish phrases the idea differently (e.g. "una juventud con la naturaleza alrededor" -> "una infancia rodeada de naturaleza"; "tomar una decisión sobre" -> "decidir sobre").
- Flag awkward circumlocutions when a single idiomatic word or expression exists.
- When a word does not make sense in context but a phonetically similar word would (likely a speech-to-text or typing slip, e.g. "fruta y colas así" -> "fruta y cosas así"), correct it as Natural Language and note in short_explanation that the original looks like a transcription slip.

Punctuation handling:
- Always inspect punctuation separately, even if the sentence has other errors.
- Missing or incorrect Spanish opening question marks (¿), closing question marks (?), opening exclamation marks (¡), closing exclamation marks (!), commas, periods, colons, semicolons, or quotation marks are Grammar.
- Insertion points for punctuation must sit on a word boundary. Opening marks like "¿" and "¡" go before a word; closing marks like "?", "!", ",", ".", ";", and ":" go immediately after a word, never inside one.
- Examples:
  - "Como estas?" -> "¿Cómo estás?" includes Grammar insertion of "¿" at start_index 0, end_index 0, original_phrase "" and Spelling edits for missing accents.
  - "Que bonito!" -> "¡Qué bonito!" includes Grammar insertion of "¡" at start_index 0, end_index 0, original_phrase "" and Spelling edit for missing accent.
  - "Hola como estas" -> "Hola, ¿cómo estás?" includes Grammar insertions for comma/question punctuation and Spelling edits for missing accents.

Important category boundaries:
- Missing accents are Spelling, not Grammar.
- Incorrect prepositions are Grammar.
- Punctuation is Grammar, not Other.
- Anglicisms, false friends, and overly literal English-style constructions are Natural Language, not Word Choice. Use Word Choice only when the user picked a real Spanish synonym that is grammatical and idiomatic but slightly suboptimal in register or precision.
```

**Note:** The OpenAI provider (`open_ai_correction_service.dart`) uses an identical correction system prompt, with one additional Natural Language handling rule about not flagging colloquial-but-established expressions and not flagging constructions merely because a shorter form exists.

### Long explanation system prompt (both providers)
```
You explain Spanish corrections to learners.

Write a concise but useful longer explanation for the saved correction.
Include:
- why the original phrase was wrong or unnatural
- how the corrected phrase works in context
- one or two alternative phrasings if useful

Return plain text only, not JSON or Markdown.
```

### Structured explanation system prompt (both providers)
```
You explain Spanish corrections to learners.

Return only valid JSON with this exact shape:
{
  "why_its_wrong": "string",
  "in_context": "string",
  "alternatives": ["string"]
}

Rules:
- why_its_wrong explains why the original phrase is incorrect or unnatural.
- in_context gives one corrected example sentence using the corrected phrase naturally.
- alternatives contains one to three alternative phrasings. Use an empty array if there are no useful alternatives.
- Keep every field concise and learner-friendly.
- Do not include Markdown, code fences, commentary, or keys outside the requested JSON.
```

---

## 7. Whisper Integration

**File:** `lib/features/write/data/open_ai_whisper_transcription_service.dart`

### How the request is sent

```dart
// Endpoint
Uri.https('api.openai.com', '/v1/audio/transcriptions')

// Headers
Authorization: Bearer <apiKey>
Content-Type: multipart/form-data; boundary=<random-boundary>

// Form fields
model          = "whisper-1"
language       = "es"
response_format = "json"
prompt         = "Hola, ¿cómo estás? Me llamo María. El niño jugó rápidamente en el jardín. Sí, también está aquí."
file           = <WAV binary>   (filename: "recording.wav", content-type: "audio/wav")
```

Timeouts: 10 s to open connection, 45 s to read response.

### Recording configuration (`WriteScreen`)
```dart
RecordConfig(
  encoder: AudioEncoder.wav,
  numChannels: 1,
  sampleRate: 16000,
)
```
Maximum recording duration: 60 seconds (`_recordingLimitSeconds`).

### How the transcript populates the text field
After `_audioRecorder.stop()` returns the audio path, `transcriptionService.transcribeSpanishAudio(audioPath)` is awaited. The returned `String` is trimmed to the 600-character limit using `transcript.characters.take(_characterLimit)`, then assigned to `_controller.text`. The cursor is moved to the end and `_handleTextChanged` is called to update the character counter.

---

## 8. Hardcoded User-Facing Strings

### App-level
| String | Location |
|--------|----------|
| `'Corrector de Espanol'` | `spanish_correction_app.dart` — `MaterialApp.title` |

### Navigation bar
| String | Location |
|--------|----------|
| `'Write'` | `app_shell.dart` — tab label |
| `'History'` | `app_shell.dart` — tab label |
| `'Saved'` | `app_shell.dart` — tab label |
| `'Synced $syncedCount queued $label'` | `app_shell.dart` — snackbar after offline sync |

### WriteScreen
| String | Location |
|--------|----------|
| `'Corregir'` | `write_screen.dart` — `AppHeader` title |
| `"Write or record - we'll handle the rest."` | `write_screen.dart` — subtitle |
| `'Type or paste your Spanish text here...'` | `write_screen.dart` — `TextField` hint |
| `'or'` | `write_screen.dart` — divider label between text input and mic |
| `'Tap to record'` | `write_screen.dart` — mic idle label |
| `'Tap to stop'` | `write_screen.dart` — mic active label |
| `'Transcribing...'` | `write_screen.dart` — mic transcribing label |
| `'Corregir'` | `write_screen.dart` — submit button label (idle) |
| `'Reviewing'` | `write_screen.dart` — submit button label (loading) |
| `'Character limit reached'` | `write_screen.dart` — snackbar |
| `'No internet available. Submission queued for sync.'` | `write_screen.dart` — snackbar |
| `'Something went wrong. Please try again.'` | `write_screen.dart` — snackbar (generic error) |
| `'Microphone permission is required to record audio.'` | `write_screen.dart` — snackbar |
| `'Unable to transcribe audio - please try again.'` | `write_screen.dart` — snackbar (start/transcription error) |
| `'Recording limit reached'` | `write_screen.dart` — snackbar |
| `'Saved for later'` | `write_screen.dart` — snackbar after saving a correction |
| `'Gemini API key is missing. Run with --dart-define=GEMINI_API_KEY=...'` | `write_screen.dart` — correction error message |
| `'No internet available. Please check your connection.'` | `write_screen.dart` — correction error message |
| `'OpenAI API key is missing. Run with --dart-define=OPENAI_API_KEY=...'` | `write_screen.dart` — transcription error message |
| `'Unable to transcribe audio - please try again.'` | `write_screen.dart` — transcription network/API error |

### CorrectionsScreen
| String | Location |
|--------|----------|
| `'Corrections'` | `corrections_screen.dart` — `AppHeader` title |
| `'Original'` | `corrections_screen.dart` — text panel title |
| `'Corrected'` | `corrections_screen.dart` — text panel title |
| `'Copy corrected text'` | `corrections_screen.dart` — button label |
| `'Corrected text copied'` | `corrections_screen.dart` — snackbar |
| `'Save for Later'` | `corrections_screen.dart` — bottom sheet button label |

### HistoryScreen
| String | Location |
|--------|----------|
| `'History'` | `history_screen.dart` — `AppHeader` title |
| `'No reviewed text yet'` | `history_screen.dart` — empty state title |
| `'Recent submissions will appear here after you review Spanish text.'` | `history_screen.dart` — empty state message |
| `'Today'` | `history_screen.dart` — group header label |
| `'This Week'` | `history_screen.dart` — group header label |
| `'Older'` | `history_screen.dart` — group header label |
| `'1 error'` / `'$count errors'` | `history_screen.dart` — count pill |
| `'Delete entry?'` | `history_screen.dart` — dialog title |
| `'This will remove the submission from your history. This cannot be undone.'` | `history_screen.dart` — dialog body |
| `'Cancel'` | `history_screen.dart` — dialog button |
| `'Delete'` | `history_screen.dart` — dialog button and swipe background |
| `'Saved for later'` | `history_screen.dart` — snackbar |
| `'Something went wrong. Please try again.'` | `history_screen.dart` — snackbar (save error) |
| `'Entry deleted'` | `history_screen.dart` — snackbar |
| `'Unable to delete entry. Please try again.'` | `history_screen.dart` — snackbar |
| `'Gemini API key is missing.'` | `history_screen.dart` — error message |
| `'No internet available. Please check your connection.'` | `history_screen.dart` — error message |
| `'Something went wrong. Please try again.'` | `history_screen.dart` — error message |

### SavedScreen
| String | Location |
|--------|----------|
| `'Saved'` | `saved_screen.dart` — `AppHeader` title |
| `'Clear'` | `saved_screen.dart` — filter chip label |
| `'No saved corrections'` | `saved_screen.dart` — empty state title |
| `'Tap a highlighted correction and save it to build your review list.'` | `saved_screen.dart` — empty state message |
| `'Nothing in this category'` | `saved_screen.dart` — filtered empty state title |
| `'Clear the filter to see all saved corrections.'` | `saved_screen.dart` — filtered empty state message |
| `'Delete saved correction?'` | `saved_screen.dart` — dialog title |
| `'This will remove the correction from your saved list. This cannot be undone.'` | `saved_screen.dart` — dialog body |
| `'Cancel'` | `saved_screen.dart` — dialog button |
| `'Delete'` | `saved_screen.dart` — dialog button and swipe background |
| `'Saved correction deleted'` | `saved_screen.dart` — snackbar |
| `'Unable to delete correction. Please try again.'` | `saved_screen.dart` — snackbar |

### SavedDetailScreen
| String | Location |
|--------|----------|
| `'Saved'` | `saved_detail_screen.dart` — `AppHeader` title |
| `'Saved $date'` | `saved_detail_screen.dart` — subtitle below corrected phrase |
| `"Why it's wrong"` | `saved_detail_screen.dart` — collapsible section title |
| `'In context'` | `saved_detail_screen.dart` — collapsible section title |
| `'Alternatives'` | `saved_detail_screen.dart` — collapsible section title |
| `'Original text'` | `saved_detail_screen.dart` — collapsible section title |
| `'Corrected text'` | `saved_detail_screen.dart` — collapsible section title |
| `'No alternatives saved for this correction.'` | `saved_detail_screen.dart` — fallback body |
| `'No original text saved for this correction.'` | `saved_detail_screen.dart` — fallback body |
| `'No corrected text saved for this correction.'` | `saved_detail_screen.dart` — fallback body |
| `'No detail saved for this section.'` | `saved_detail_screen.dart` — generic fallback |
