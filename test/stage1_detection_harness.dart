// Stage 1 bare-detection harness.
//
// Tests `stage1DetectionSpanish` (lib/core/services/prompts/correction_prompt.dart)
// — an experimental single-call detection prompt that asks the model to
// quote problematic phrases only (no categories, no indices, no corrected
// text) — against the app's known Spanish test phrases, to see whether bare
// detection quality holds up before any ordinal/scoring stage is built on
// top of it.
//
// Calls the OpenAI chat completions endpoint directly (mirroring
// bare_prompt_control_test.dart's pattern), NOT `OpenAiCorrectionService` —
// this is a new, additional prompt with no JSON-schema enforcement, so
// there's no live-service method to call through. Reads OPENAI_API_KEY from
// Platform.environment only, no AppConfig fallback, same discipline as
// bare_prompt_control_test.dart. Does NOT touch `correctText()`, the
// existing `correctionPromptSpanish`/`correctionPromptPortuguese` constants,
// or any live path.
//
// Phrase fixtures: the 6 Spanish phrases (ES-1..ES-6) from
// correction_consistency_harness.dart's 12-phrase battery, copied by value
// (id/text/expected substrings only — categories are dropped, since Stage 1
// produces none), plus 3 dialectal/regional-split phrases, plus a structural
// battery (6 phrases, added to measure omission/removal detection — see
// below). The 6 Portuguese phrases (PT-1..PT-6) are deliberately excluded:
// stage1DetectionSpanish is Spanish-only, so running Portuguese text through
// it wouldn't be a meaningful signal at this stage.
//
// Scoring is detection-only: for each phrase, whether the expected
// substring(s) were quoted somewhere in the model's returned array
// (case/diacritic-insensitive containment, same matching rule as
// correction_consistency_harness.dart's `_normalizedOverlap`), and for
// negative-test phrases, whether the array came back empty. No span
// position, no category — Stage 1 produces neither.
//
// Structural battery (measurement only, no prompt changes): tests two error
// shapes Stage 1 hadn't been run against yet.
//   - Removal sub-set (ST-R1, ST-R2): a concrete redundant word exists in
//     the text, so it's scored like a normal target, but the point is
//     reading the raw flagged span for cleanliness (ES-6 found spans were
//     often the whole clause, not a clean single word) — already visible
//     in every run's flagged-phrases printout, no new scoring machinery
//     needed.
//   - Omission sub-set (ST-O1..ST-O4): nothing exists at the error site (the
//     fix is an insertion), so there's no phrase to quote. Scored as
//     observational only (`isObservationalOnly: true`) except ST-O4, which
//     bundles one real scoreable target (a swap-type accent fix) alongside
//     a pure-omission element that's read from the raw flagged spans only.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage1_detection_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/stage1_detection_harness.dart --timeout none
//
// Writes a report to docs/stage1_detection_harness.md (override with
// --dart-define=STAGE1_DETECTION_OUTPUT=...). Override run count per phrase
// with --dart-define=STAGE1_RUNS_PER_PHRASE=... (default 10). Override the
// model with --dart-define=STAGE1_DETECTION_MODEL=... (default 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerPhrase = int.fromEnvironment(
  'STAGE1_RUNS_PER_PHRASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'STAGE1_DETECTION_OUTPUT',
  defaultValue: 'docs/stage1_detection_harness.md',
);

/// Model used for the live run. Override with
/// `--dart-define=STAGE1_DETECTION_MODEL=...`, same override pattern as
/// `correction_consistency_harness.dart`'s `consistencyModel`.
const String stage1Model = String.fromEnvironment(
  'STAGE1_DETECTION_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation
/// `correction_consistency_harness.dart` added after a live run started
/// failing partway through with rate-limit-shaped errors.
const int callDelayMs = int.fromEnvironment(
  'STAGE1_CALL_DELAY_MS',
  defaultValue: 750,
);

/// Which battery a phrase belongs to, so the report can print them under
/// separate headings even though they run through the same prompt.
enum _PhraseGroup { core, dialectal, structuralRemoval, structuralOmission }

/// One test phrase for Stage 1 detection. Unlike
/// `correction_consistency_harness.dart`'s `_Phrase`, there is no
/// per-target category — Stage 1 quotes phrases only, so expectations are
/// bare substrings.
class _Phrase {
  const _Phrase({
    required this.id,
    required this.group,
    required this.text,
    required this.expectedFlags,
    required this.note,
    this.isObservationalOnly = false,
  });

  final String id;
  final _PhraseGroup group;
  final String text;

  /// Substrings expected to be quoted (overlap-matched, not exact) somewhere
  /// in the model's returned array. Empty marks a negative test: the phrase
  /// is expected to produce an empty array.
  final List<String> expectedFlags;
  final String note;

  /// True for phrases where neither a flag nor a clean result is "correct"
  /// — the run result is recorded for read-through, not scored as pass/fail
  /// (e.g. ES-D2: "coger el autobús" is dialectally loaded, could go either
  /// way depending on the model's assumed audience).
  final bool isObservationalOnly;

  bool get isNegativeTest => expectedFlags.isEmpty;
}

const List<_Phrase> _phrases = [
  // ── Core battery (ES-1..ES-6, copied by value from
  // correction_consistency_harness.dart's 12-phrase battery — text and
  // expected-substring targets only; categories dropped since Stage 1
  // produces none) ───────────────────────────────────────────────────────
  _Phrase(
    id: 'ES-1-repeated-word',
    group: _PhraseGroup.core,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    expectedFlags: ['para casa'],
    note:
        'Two instances of "para" appear before this one ("para comprar", '
        '"para preparar"); only "volví para casa" -> "volví a casa" should '
        'be flagged. Checks repeated-word targeting.',
  ),
  _Phrase(
    id: 'ES-2-single-char',
    group: _PhraseGroup.core,
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
    expectedFlags: [],
    note:
        'Negative test. "voy para casa" is acceptable Spanish — confirm no '
        'phrase is flagged.',
  ),
  _Phrase(
    id: 'ES-3-multi-correction',
    group: _PhraseGroup.core,
    text:
        'Ayer había mucho trafico y mis amigos llamaron para atrás para '
        'confirmar la cena.',
    expectedFlags: ['trafico', 'llamaron para atrás'],
    note:
        'Two independent targets: "trafico" (spelling) and "llamaron para '
        'atrás" (calque) — track both.',
  ),
  _Phrase(
    id: 'ES-4-calque',
    group: _PhraseGroup.core,
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche.',
    expectedFlags: ['Puedo tener una cerveza', 'pasar un buen tiempo'],
    note: 'Two calque targets — track both.',
  ),
  _Phrase(
    id: 'ES-5-accents',
    group: _PhraseGroup.core,
    text:
        'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
    expectedFlags: ['Espana', 'anos', 'cumpleanos', 'otono'],
    note:
        'Four independent accent targets in one phrase — track catch rate '
        'per individual word, not just phrase-level.',
  ),
  _Phrase(
    id: 'ES-6-redundant-pronoun',
    group: _PhraseGroup.core,
    text: 'Yo fui a casa, yo estudié, y yo hice la cena.',
    expectedFlags: ['yo estudié', 'yo hice la cena'],
    note:
        'Spanish is pro-drop; repeating "yo" before every verb is '
        'grammatical but unnatural. Expect the 2nd and/or 3rd "yo" flagged '
        '(first "yo" typically kept).',
  ),

  // ── Dialectal / regional-split battery (new) ────────────────────────────
  _Phrase(
    id: 'ES-D1-para-casa-latam',
    group: _PhraseGroup.dialectal,
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
    expectedFlags: [],
    note:
        'Same text as ES-2, re-run here under the dialectal heading. "voy '
        'para casa" is standard in much of Latin America — expect zero '
        'flags.',
  ),
  _Phrase(
    id: 'ES-D2-coger-autobus',
    group: _PhraseGroup.dialectal,
    text: 'Voy a coger el autobús para ir al centro.',
    expectedFlags: [],
    note:
        '"coger el autobús" is standard, acceptable Spanish in Spain but '
        'carries a vulgar double meaning in much of Latin America. '
        'Dialectally loaded — detection may reasonably flag or not flag '
        'this. Observational only: recorded, not scored pass/fail.',
    isObservationalOnly: true,
  ),
  _Phrase(
    id: 'ES-D3-coche',
    group: _PhraseGroup.dialectal,
    text: 'Aparqué el coche cerca de la oficina.',
    expectedFlags: [],
    note:
        'Negative test. "coche" (car) is ordinary regional vocabulary — '
        'must not be flagged.',
  ),

  // ── Structural battery — removal sub-set (redundant word present; scored
  // like a normal target, but read the raw flagged span in the run detail
  // below to see whether it's clean or messy) ────────────────────────────
  _Phrase(
    id: 'ST-R1-redundant-article',
    group: _PhraseGroup.structuralRemoval,
    text:
        'Me gusta el fútbol y el tenis, pero el baloncesto no me gusta a '
        'mí.',
    expectedFlags: ['a mí'],
    note:
        'The final "a mí" is redundant given "me gusta" already marks the '
        'subject. Observational on span cleanliness — record what gets '
        'flagged, not just whether it does.',
  ),
  _Phrase(
    id: 'ST-R2-redundant-pronoun',
    group: _PhraseGroup.structuralRemoval,
    text:
        'Nosotros vamos al cine, nosotros comemos palomitas y nosotros '
        'volvemos a casa.',
    expectedFlags: ['nosotros comemos palomitas', 'nosotros volvemos a casa'],
    note:
        'Same class as ES-6 — repeated redundant "nosotros" (second example '
        'alongside it). Expect the 2nd and/or 3rd flagged; record whether '
        'the span is a clean single "nosotros" or a messy multi-word span '
        'like ES-6 produced.',
  ),

  // ── Structural battery — omission sub-set (nothing exists at the error
  // site; the fix is an insertion, so there's no phrase to quote — scored
  // observational only except where noted) ───────────────────────────────
  _Phrase(
    id: 'ST-O1-missing-question-mark',
    group: _PhraseGroup.structuralOmission,
    text: 'Como estas hoy?',
    expectedFlags: [],
    note:
        'Missing opening "¿". Nothing exists at the error site to quote — '
        'observational only. Record what, if anything, is flagged and '
        'whether the span is usable.',
    isObservationalOnly: true,
  ),
  _Phrase(
    id: 'ST-O2-missing-que',
    group: _PhraseGroup.structuralOmission,
    // Submitted with "que" omitted, per the requested fixture: "Creo Ø está
    // bien, pero no estoy seguro." -> "Creo está bien, pero no estoy
    // seguro."
    text: 'Creo está bien, pero no estoy seguro.',
    expectedFlags: [],
    note:
        'Missing subordinating "que" ("Creo que está bien"). Nothing '
        'exists at the error site to quote — observational only. Record '
        'what is flagged.',
    isObservationalOnly: true,
  ),
  _Phrase(
    id: 'ST-O3-missing-preposition',
    group: _PhraseGroup.structuralOmission,
    text: 'Voy la playa este fin de semana.',
    expectedFlags: [],
    note:
        'Missing "a" ("Voy a la playa"). Nothing exists at the error site '
        'to quote — observational only. Record what is flagged.',
    isObservationalOnly: true,
  ),
  _Phrase(
    id: 'ST-O4-missing-exclamation-mark',
    group: _PhraseGroup.structuralOmission,
    text: 'Que bonito es este lugar!',
    expectedFlags: ['Que'],
    note:
        'Two distinct issues bundled deliberately: the missing opening "¡" '
        'is a pure omission with nothing to quote — read it from the raw '
        'flagged spans below, it is not scored. The missing accent on '
        '"Qué" is a normal swap-type target ("Que" -> "Qué") and IS '
        'scored — expectedFlags tracks that half only.',
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself (e.g. target substring "trafico" vs.
/// a returned quote echoing "tráfico"). Copied by value from
/// correction_consistency_harness.dart's `_normalizeForMatch` — this file
/// stays standalone, so it's duplicated rather than imported.
String _normalizeForMatch(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàäâã]'), 'a')
      .replaceAll(RegExp('[éèëê]'), 'e')
      .replaceAll(RegExp('[íìïî]'), 'i')
      .replaceAll(RegExp('[óòöôõ]'), 'o')
      .replaceAll(RegExp('[úùüû]'), 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c');
}

/// Case/diacritic-insensitive containment check in either direction — the
/// model may quote a larger or smaller span than the target substring and
/// either should still count as catching it. Same rule as
/// correction_consistency_harness.dart's `_normalizedOverlap`.
bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Whether [target] was quoted somewhere in [flaggedPhrases].
bool _wasTargetCaught(List<String> flaggedPhrases, String target) {
  return flaggedPhrases.any((flag) => _normalizedOverlap(target, flag));
}

/// Checks [flaggedPhrases] against every expected target in [phrase],
/// returning one bool per target in the same order as
/// `phrase.expectedFlags`. Always empty for negative-test phrases.
List<bool> _catchResultsFor(List<String> flaggedPhrases, _Phrase phrase) {
  return phrase.expectedFlags
      .map((target) => _wasTargetCaught(flaggedPhrases, target))
      .toList();
}

/// Builds the raw JSON-able request body for one OpenAI chat completions
/// call: `model` plus a two-message `messages` array (system, then user).
/// No `response_format` — Stage 1's JSON-array instruction lives entirely in
/// the prompt text itself (see `stage1DetectionSpanish`), same "prompt does
/// the work, not API-enforced schema" approach as bare_prompt_control_test.dart.
Map<String, Object?> buildChatCompletionsBody({
  required String model,
  required String systemPrompt,
  required String userText,
}) {
  return {
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userText},
    ],
  };
}

/// Extracts the assistant's reply text from a decoded chat completions
/// response body: `choices[0].message.content`, trimmed. Copied by value
/// from bare_prompt_control_test.dart's `extractReplyText`.
String extractReplyText(Map<String, Object?> decodedBody) {
  final choices = decodedBody['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException(
      'Chat completions response has no choices.',
    );
  }

  final firstChoice = choices.first;
  if (firstChoice is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice is not an object.');
  }

  final message = firstChoice['message'];
  if (message is! Map<String, Object?>) {
    throw const FormatException('Chat completions choice has no message.');
  }

  final content = message['content'];
  if (content is! String || content.trim().isEmpty) {
    throw const FormatException('Chat completions message has no content.');
  }

  return content.trim();
}

/// Parses a Stage 1 reply into the list of quoted phrases it flagged.
///
/// Tolerates the model wrapping the array in Markdown code fences or
/// trailing commentary (despite the prompt asking it not to) by extracting
/// the substring between the first `[` and the last `]` before decoding,
/// same defensive approach as `OpenAiCorrectionService._extractJsonObject`
/// uses for `{`/`}`. Throws a [FormatException] on anything that isn't a
/// JSON array of strings once extracted.
List<String> parseDetectionArray(String replyText) {
  final trimmed = replyText.trim();
  final start = trimmed.indexOf('[');
  final end = trimmed.lastIndexOf(']');
  if (start == -1 || end == -1 || end <= start) {
    throw const FormatException('No JSON array found in Stage 1 reply.');
  }

  final decoded = jsonDecode(trimmed.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('Stage 1 reply array did not decode to a List.');
  }

  return decoded.map((element) {
    if (element is! String) {
      throw FormatException(
        'Stage 1 reply array contained a non-string element: $element',
      );
    }
    return element;
  }).toList();
}

/// One run's outcome for one phrase. A transient API failure is recorded
/// via [error] rather than dropped, same as
/// correction_consistency_harness.dart's `_RunRecord`.
class _RunRecord {
  const _RunRecord({
    required this.phraseId,
    required this.runIndex,
    this.flaggedPhrases = const [],
    this.targetCaught,
    this.stayedClean,
    this.error,
  });

  final String phraseId;
  final int runIndex;
  final List<String> flaggedPhrases;
  final List<bool>? targetCaught;
  final bool? stayedClean;
  final Object? error;

  bool get isError => error != null;
}

_RunRecord _buildRunRecord({
  required _Phrase phrase,
  required int runIndex,
  required List<String> flaggedPhrases,
}) {
  return _RunRecord(
    phraseId: phrase.id,
    runIndex: runIndex,
    flaggedPhrases: flaggedPhrases,
    targetCaught: phrase.isNegativeTest
        ? null
        : _catchResultsFor(flaggedPhrases, phrase),
    stayedClean: phrase.isNegativeTest ? flaggedPhrases.isEmpty : null,
  );
}

_RunRecord _errorRunRecord({
  required _Phrase phrase,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(phraseId: phrase.id, runIndex: runIndex, error: error);
}

/// Aggregated results for one phrase across all its runs. Rates are
/// computed over non-error runs only, same as
/// correction_consistency_harness.dart's `_PhraseAggregate`.
class _PhraseAggregate {
  const _PhraseAggregate({
    required this.phraseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.targetCatchRates,
    required this.fullyCaughtRate,
    required this.cleanRate,
  });

  final String phraseId;
  final int totalRuns;
  final int errorRuns;
  final List<double> targetCatchRates;
  final double? fullyCaughtRate;
  final double? cleanRate;
}

_PhraseAggregate _aggregatePhrase(_Phrase phrase, List<_RunRecord> records) {
  final okRecords = records.where((r) => !r.isError).toList();
  final errorCount = records.length - okRecords.length;

  var targetCatchRates = const <double>[];
  double? fullyCaughtRate;
  double? cleanRate;

  if (phrase.isNegativeTest) {
    cleanRate = okRecords.isEmpty
        ? 0.0
        : okRecords.where((r) => r.stayedClean == true).length /
              okRecords.length;
  } else {
    targetCatchRates = List.generate(phrase.expectedFlags.length, (index) {
      if (okRecords.isEmpty) {
        return 0.0;
      }
      final caughtCount = okRecords
          .where((r) => r.targetCaught![index])
          .length;
      return caughtCount / okRecords.length;
    });
    fullyCaughtRate = okRecords.isEmpty
        ? 0.0
        : okRecords.where((r) => r.targetCaught!.every((c) => c)).length /
              okRecords.length;
  }

  return _PhraseAggregate(
    phraseId: phrase.id,
    totalRuns: records.length,
    errorRuns: errorCount,
    targetCatchRates: targetCatchRates,
    fullyCaughtRate: fullyCaughtRate,
    cleanRate: cleanRate,
  );
}

String _percentLabel(int count, int total) {
  if (total == 0) {
    return '0.0% (0/0)';
  }
  final pct = (count / total * 100).toStringAsFixed(1);
  return '$pct% ($count/$total)';
}

String _groupHeading(_PhraseGroup group) => switch (group) {
  _PhraseGroup.core => 'Core battery (ES-1..ES-6, reused verbatim)',
  _PhraseGroup.dialectal => 'Dialectal / regional-split battery',
  _PhraseGroup.structuralRemoval =>
    'Structural battery — removal sub-set (redundant word present)',
  _PhraseGroup.structuralOmission =>
    'Structural battery — omission sub-set (nothing to quote)',
};

String _describeError(Object error) => error.toString();

String _describeRun(_Phrase phrase, _RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }

  final status = phrase.isNegativeTest
      ? 'stayed clean = ${record.stayedClean}'
      : 'targets caught = ${record.targetCaught}';

  final flagged = record.flaggedPhrases.isEmpty
      ? '(no phrases flagged)'
      : record.flaggedPhrases.map((f) => '"$f"').join('; ');

  return '- $prefix: $status · flagged: $flagged';
}

/// Builds the full markdown report: a header block, then each phrase group
/// as its own section (so dialectal results read separately from the core
/// battery, per the requirement), one subsection per phrase (metadata,
/// aggregate summary, run-by-run breakdown), then an overall-summary table.
///
/// Pure — takes already-collected [recordsByPhraseId] rather than making any
/// calls itself, golden-testable against synthetic data with no live API
/// involved, same approach as the other harnesses' `_buildReport`.
String _buildReport({
  required String model,
  required int runsPerPhrase,
  required DateTime generatedAt,
  required List<_Phrase> phrases,
  required Map<String, List<_RunRecord>> recordsByPhraseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Stage 1 Detection Harness')
    ..writeln()
    ..writeln('Model: `$model`  ');
  if (commit != null) {
    report.writeln('Commit: `$commit`  ');
  }
  report
    ..writeln('Generated: ${generatedAt.toIso8601String()}  ')
    ..writeln('Runs per phrase: $runsPerPhrase')
    ..writeln();

  final summaryRows = <String>[];

  for (final group in _PhraseGroup.values) {
    final groupPhrases = phrases.where((p) => p.group == group).toList();
    if (groupPhrases.isEmpty) {
      continue;
    }

    report
      ..writeln('## ${_groupHeading(group)}')
      ..writeln();

    for (final phrase in groupPhrases) {
      final records = recordsByPhraseId[phrase.id] ?? const <_RunRecord>[];
      final aggregate = _aggregatePhrase(phrase, records);
      final okRecords = records.where((r) => !r.isError).toList();
      final observationalTag = phrase.isObservationalOnly
          ? ' _(observational only — not scored pass/fail)_'
          : '';

      report
        ..writeln('### ${phrase.id}$observationalTag')
        ..writeln()
        ..writeln('- Text: `${phrase.text}`')
        ..writeln('- Note: ${phrase.note}')
        ..writeln()
        ..writeln(
          '#### Summary (${aggregate.totalRuns} runs, '
          '${aggregate.errorRuns} error(s))',
        )
        ..writeln();

      if (phrase.isNegativeTest) {
        final cleanCount = okRecords.where((r) => r.stayedClean == true).length;
        final cleanLabel = _percentLabel(cleanCount, okRecords.length);
        report.writeln('- Stayed clean: $cleanLabel');
        summaryRows.add(
          '| ${phrase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
          '$cleanLabel (clean) | — |',
        );
      } else {
        final perTargetLabels = <String>[];
        for (var i = 0; i < phrase.expectedFlags.length; i++) {
          final target = phrase.expectedFlags[i];
          final caughtCount = okRecords.where((r) => r.targetCaught![i]).length;
          final label = _percentLabel(caughtCount, okRecords.length);
          perTargetLabels.add(label);
          report.writeln('- Target ${i + 1} ("$target"): $label');
        }
        final fullyCaughtCount = okRecords
            .where((r) => r.targetCaught!.every((caught) => caught))
            .length;
        final fullyCaughtLabel = _percentLabel(
          fullyCaughtCount,
          okRecords.length,
        );
        report.writeln(
          '- Fully caught (all targets in one run): $fullyCaughtLabel',
        );
        summaryRows.add(
          '| ${phrase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
          '$fullyCaughtLabel (fully caught) | ${perTargetLabels.join(', ')} |',
        );
      }

      report
        ..writeln()
        ..writeln('#### Run detail')
        ..writeln();

      for (final record in records) {
        report.writeln(_describeRun(phrase, record));
      }
      report.writeln();
    }
  }

  report
    ..writeln('---')
    ..writeln()
    ..writeln('## Overall summary')
    ..writeln()
    ..writeln('| Phrase | Runs | Errors | Headline rate | Per-target rates |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final row in summaryRows) {
    report.writeln(row);
  }

  return report.toString();
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

Future<List<String>> _callStage1Detection({
  required HttpClient httpClient,
  required String apiKey,
  required String model,
  required String userText,
}) async {
  final request = await httpClient
      .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
      .timeout(const Duration(seconds: 10));

  request.headers
    ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
    ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);

  request.add(
    utf8.encode(
      jsonEncode(
        buildChatCompletionsBody(
          model: model,
          systemPrompt: stage1DetectionSpanish,
          userText: userText,
        ),
      ),
    ),
  );

  final response = await request.close().timeout(const Duration(seconds: 30));
  final body = await utf8.decodeStream(response);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Chat completions call failed with HTTP ${response.statusCode}: $body',
    );
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'Chat completions response root is not an object.',
    );
  }

  return parseDetectionArray(extractReplyText(decoded));
}

void main() {
  test('stage1 detection harness phrase fixtures are well-formed', () {
    expect(
      _phrases.length,
      15,
      reason:
          '6 core (ES-1..ES-6) + 3 dialectal + 2 structural-removal + 4 '
          'structural-omission.',
    );

    final core = _phrases.where((p) => p.group == _PhraseGroup.core);
    final dialectal = _phrases.where((p) => p.group == _PhraseGroup.dialectal);
    final structuralRemoval = _phrases.where(
      (p) => p.group == _PhraseGroup.structuralRemoval,
    );
    final structuralOmission = _phrases.where(
      (p) => p.group == _PhraseGroup.structuralOmission,
    );
    expect(core.length, 6);
    expect(dialectal.length, 3);
    expect(structuralRemoval.length, 2);
    expect(structuralOmission.length, 4);

    final ids = _phrases.map((p) => p.id).toSet();
    expect(ids.length, _phrases.length, reason: 'Phrase ids must be unique.');

    for (final phrase in _phrases) {
      expect(phrase.text.trim(), isNotEmpty, reason: phrase.id);
      for (final target in phrase.expectedFlags) {
        expect(
          phrase.text.contains(target),
          isTrue,
          reason:
              '${phrase.id}: expected substring "$target" not found in '
              'phrase text.',
        );
      }
    }

    // Core battery text copied verbatim from
    // correction_consistency_harness.dart's 12-phrase battery — guard
    // against retyping drift.
    final textsById = {for (final p in _phrases) p.id: p.text};
    expect(
      textsById['ES-1-repeated-word'],
      'Ayer fui al supermercado para comprar pan y después volví para casa '
      'para preparar la cena.',
    );
    expect(
      textsById['ES-2-single-char'],
      'Cuando termino el trabajo, voy para casa en autobús.',
    );
    expect(
      textsById['ES-3-multi-correction'],
      'Ayer había mucho trafico y mis amigos llamaron para atrás para '
      'confirmar la cena.',
    );
    expect(
      textsById['ES-4-calque'],
      '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
      'amigos esta noche.',
    );
    expect(
      textsById['ES-5-accents'],
      'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
    );
    expect(
      textsById['ES-6-redundant-pronoun'],
      'Yo fui a casa, yo estudié, y yo hice la cena.',
    );

    // Observational-only phrases: ES-D2 (dialectal ambiguity) plus the three
    // pure-omission structural phrases (ST-O4 is excluded — it carries one
    // real scoreable target, the "Que" -> "Qué" accent swap).
    expect(
      _phrases.where((p) => p.isObservationalOnly).map((p) => p.id).toList(),
      [
        'ES-D2-coger-autobus',
        'ST-O1-missing-question-mark',
        'ST-O2-missing-que',
        'ST-O3-missing-preposition',
      ],
    );

    // Exactly ES-2/ES-D1/ES-D3 are hard negative tests (must stay clean);
    // ES-D2 and ST-O1..ST-O3 have empty expectedFlags too but are
    // observational, not a hard pass/fail negative test. ST-O4 has a
    // non-empty expectedFlags (the accent-swap target) so it's not a
    // negative test at all.
    final negativeIds = _phrases
        .where((p) => p.isNegativeTest && !p.isObservationalOnly)
        .map((p) => p.id)
        .toSet();
    expect(negativeIds, {
      'ES-2-single-char',
      'ES-D1-para-casa-latam',
      'ES-D3-coche',
    });
  });

  test('stage1DetectionSpanish prompt asks for quoted phrases only, as a JSON array', () {
    expect(stage1DetectionSpanish, contains('Spanish tutor'));
    expect(stage1DetectionSpanish, contains('Quote each problematic phrase'));
    expect(stage1DetectionSpanish, contains('JSON array'));
    expect(stage1DetectionSpanish, contains('[]'));
    expect(stage1DetectionSpanish, contains('corrected text'));
    expect(stage1DetectionSpanish, isNot(contains('start_index')));
    expect(stage1DetectionSpanish, isNot(contains('Grammar, Natural Language')));
  });

  group('parseDetectionArray', () {
    test('parses a populated array', () {
      expect(
        parseDetectionArray('["volví para casa", "trafico"]'),
        ['volví para casa', 'trafico'],
      );
    });

    test('parses an empty array', () {
      expect(parseDetectionArray('[]'), isEmpty);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      expect(
        parseDetectionArray('```json\n["trafico"]\n```'),
        ['trafico'],
      );
      expect(
        parseDetectionArray('Here you go: ["trafico"] — hope that helps.'),
        ['trafico'],
      );
    });

    test('throws when no array is present', () {
      expect(
        () => parseDetectionArray('No errors found.'),
        throwsFormatException,
      );
    });

    test('throws when the array contains a non-string element', () {
      expect(
        () => parseDetectionArray('["trafico", 42]'),
        throwsFormatException,
      );
    });
  });

  group('catch detection', () {
    test('_wasTargetCaught is true on exact match', () {
      expect(_wasTargetCaught(['trafico'], 'trafico'), isTrue);
    });

    test('_wasTargetCaught is true regardless of case/diacritics', () {
      expect(_wasTargetCaught(['TRÁFICO'], 'trafico'), isTrue);
    });

    test('_wasTargetCaught is true when the quote is a larger span', () {
      expect(
        _wasTargetCaught(['ayer había mucho trafico'], 'trafico'),
        isTrue,
      );
    });

    test('_wasTargetCaught is false when nothing overlaps', () {
      expect(_wasTargetCaught(['otono'], 'trafico'), isFalse);
    });

    test('_wasTargetCaught is false when flaggedPhrases is empty', () {
      expect(_wasTargetCaught([], 'trafico'), isFalse);
    });

    test('_catchResultsFor returns one bool per expected target, in order', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
      expect(phrase.expectedFlags.length, 2);

      // Only "trafico" is caught; "llamaron para atrás" is missed.
      final result = _catchResultsFor(['trafico'], phrase);
      expect(result, [true, false]);
    });

    test('_catchResultsFor is empty for a negative-test phrase', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-single-char');
      expect(phrase.isNegativeTest, isTrue);
      expect(_catchResultsFor([], phrase), isEmpty);
    });
  });

  group('_buildRunRecord / _errorRunRecord', () {
    test('positive-test phrase: targetCaught set, stayedClean null', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
      final record = _buildRunRecord(
        phrase: phrase,
        runIndex: 1,
        flaggedPhrases: ['trafico'],
      );

      expect(record.phraseId, 'ES-3-multi-correction');
      expect(record.runIndex, 1);
      expect(record.targetCaught, [true, false]);
      expect(record.stayedClean, isNull);
      expect(record.isError, isFalse);
      expect(record.flaggedPhrases, ['trafico']);
    });

    test('negative-test phrase: stayedClean set, targetCaught null', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-single-char');

      final cleanRecord = _buildRunRecord(
        phrase: phrase,
        runIndex: 1,
        flaggedPhrases: const [],
      );
      expect(cleanRecord.stayedClean, isTrue);
      expect(cleanRecord.targetCaught, isNull);

      final dirtyRecord = _buildRunRecord(
        phrase: phrase,
        runIndex: 2,
        flaggedPhrases: ['voy para casa'],
      );
      expect(dirtyRecord.stayedClean, isFalse);
    });

    test('_errorRunRecord carries the error and no data', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
      final record = _errorRunRecord(
        phrase: phrase,
        runIndex: 3,
        error: StateError('timed out'),
      );

      expect(record.isError, isTrue);
      expect(record.error, isA<StateError>());
      expect(record.targetCaught, isNull);
      expect(record.stayedClean, isNull);
      expect(record.flaggedPhrases, isEmpty);
    });
  });

  group('_aggregatePhrase', () {
    test('positive-test phrase: rates computed over non-error runs only', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');

      final records = [
        _RunRecord(
          phraseId: phrase.id,
          runIndex: 1,
          flaggedPhrases: const ['trafico', 'llamaron para atrás'],
          targetCaught: const [true, true],
        ),
        _RunRecord(
          phraseId: phrase.id,
          runIndex: 2,
          flaggedPhrases: const ['trafico'],
          targetCaught: const [true, false],
        ),
        _errorRunRecord(phrase: phrase, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregatePhrase(phrase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.targetCatchRates, [1.0, 0.5]);
      expect(aggregate.fullyCaughtRate, 0.5);
      expect(aggregate.cleanRate, isNull);
    });

    test('negative-test phrase: cleanRate computed, no target rates', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-single-char');

      final records = [
        _RunRecord(phraseId: phrase.id, runIndex: 1, stayedClean: true),
        _RunRecord(
          phraseId: phrase.id,
          runIndex: 2,
          stayedClean: false,
          flaggedPhrases: const ['voy para casa'],
        ),
        _errorRunRecord(phrase: phrase, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregatePhrase(phrase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.targetCatchRates, isEmpty);
      expect(aggregate.fullyCaughtRate, isNull);
      expect(aggregate.cleanRate, 0.5);
    });

    test('all runs erroring yields zeroed rates, not a crash', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
      final records = [
        _errorRunRecord(phrase: phrase, runIndex: 1, error: StateError('a')),
        _errorRunRecord(phrase: phrase, runIndex: 2, error: StateError('b')),
      ];

      final aggregate = _aggregatePhrase(phrase, records);

      expect(aggregate.totalRuns, 2);
      expect(aggregate.errorRuns, 2);
      expect(aggregate.targetCatchRates, [0.0, 0.0]);
      expect(aggregate.fullyCaughtRate, 0.0);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, grouped sections, per-phrase summary + run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerPhrase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        phrases: const [
          _Phrase(
            id: 'TEST-1-core',
            group: _PhraseGroup.core,
            text: 'Ejemplo de prueba para el informe.',
            expectedFlags: ['prueba'],
            note: 'Synthetic phrase for report golden test.',
          ),
          _Phrase(
            id: 'TEST-2-dialectal',
            group: _PhraseGroup.dialectal,
            text: 'Frase de teste dialectal.',
            expectedFlags: [],
            note: 'Synthetic observational phrase for report golden test.',
            isObservationalOnly: true,
          ),
          _Phrase(
            id: 'TEST-3-structural-removal',
            group: _PhraseGroup.structuralRemoval,
            text: 'Ejemplo con palabra redundante redundante.',
            expectedFlags: ['palabra redundante'],
            note: 'Synthetic removal-subset phrase for report golden test.',
          ),
          _Phrase(
            id: 'TEST-4-structural-omission',
            group: _PhraseGroup.structuralOmission,
            text: 'Falta algo aqui.',
            expectedFlags: [],
            note: 'Synthetic omission-subset phrase for report golden test.',
            isObservationalOnly: true,
          ),
        ],
        recordsByPhraseId: {
          'TEST-1-core': [
            _RunRecord(
              phraseId: 'TEST-1-core',
              runIndex: 1,
              flaggedPhrases: const ['prueba'],
              targetCaught: const [true],
            ),
            _RunRecord(
              phraseId: 'TEST-1-core',
              runIndex: 2,
              flaggedPhrases: const [],
              targetCaught: const [false],
            ),
          ],
          'TEST-2-dialectal': [
            _RunRecord(
              phraseId: 'TEST-2-dialectal',
              runIndex: 1,
              stayedClean: true,
            ),
            _errorRunRecord(
              phrase: const _Phrase(
                id: 'TEST-2-dialectal',
                group: _PhraseGroup.dialectal,
                text: 'Frase de teste dialectal.',
                expectedFlags: [],
                note: '',
                isObservationalOnly: true,
              ),
              runIndex: 2,
              error: StateError('Stage 1 call timed out'),
            ),
          ],
          'TEST-3-structural-removal': [
            _RunRecord(
              phraseId: 'TEST-3-structural-removal',
              runIndex: 1,
              flaggedPhrases: const ['redundante'],
              targetCaught: const [true],
            ),
            _RunRecord(
              phraseId: 'TEST-3-structural-removal',
              runIndex: 2,
              flaggedPhrases: const ['palabra redundante redundante'],
              targetCaught: const [true],
            ),
          ],
          'TEST-4-structural-omission': [
            _RunRecord(
              phraseId: 'TEST-4-structural-omission',
              runIndex: 1,
              stayedClean: true,
            ),
            _RunRecord(
              phraseId: 'TEST-4-structural-omission',
              runIndex: 2,
              stayedClean: false,
              flaggedPhrases: const ['Falta algo aqui'],
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'stage1 detection harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the Stage 1 detection harness. This '
          'script does NOT fall back to any hardcoded/default key — no '
          'AppConfig involved, by design (see the file header).',
        );
      }

      final httpClient = HttpClient();
      final recordsByPhraseId = <String, List<_RunRecord>>{};

      try {
        for (final phrase in _phrases) {
          final records = <_RunRecord>[];
          // ignore: avoid_print
          print('=== ${phrase.id} ===');

          for (var run = 1; run <= runsPerPhrase; run++) {
            _RunRecord record;
            try {
              final flaggedPhrases = await _callStage1Detection(
                httpClient: httpClient,
                apiKey: apiKey,
                model: stage1Model,
                userText: phrase.text,
              );
              record = _buildRunRecord(
                phrase: phrase,
                runIndex: run,
                flaggedPhrases: flaggedPhrases,
              );
            } catch (error) {
              record = _errorRunRecord(phrase: phrase, runIndex: run, error: error);
            }
            records.add(record);
            // ignore: avoid_print
            print(_describeRun(phrase, record));
            await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
          }

          recordsByPhraseId[phrase.id] = records;
        }
      } finally {
        httpClient.close();
      }

      final report = _buildReport(
        model: stage1Model,
        runsPerPhrase: runsPerPhrase,
        generatedAt: DateTime.now(),
        phrases: _phrases,
        recordsByPhraseId: recordsByPhraseId,
        commit: _gitHead(),
      );

      File(outputPath).writeAsStringSync(report);
      // ignore: avoid_print
      print('Wrote $outputPath');
    },
    timeout: const Timeout(Duration(minutes: 30)),
    tags: ['live'],
  );
}

const String _expectedReportGolden =
    r'"# Stage 1 Detection Harness\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per phrase: 2\n\n## Core battery (ES-1..ES-6, reused verbatim)\n\n### TEST-1-core\n\n- Text: `Ejemplo de prueba para el informe.`\n- Note: Synthetic phrase for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Target 1 (\"prueba\"): 50.0% (1/2)\n- Fully caught (all targets in one run): 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: targets caught = [true] · flagged: \"prueba\"\n- Run 2: targets caught = [false] · flagged: (no phrases flagged)\n\n## Dialectal / regional-split battery\n\n### TEST-2-dialectal _(observational only — not scored pass/fail)_\n\n- Text: `Frase de teste dialectal.`\n- Note: Synthetic observational phrase for report golden test.\n\n#### Summary (2 runs, 1 error(s))\n\n- Stayed clean: 100.0% (1/1)\n\n#### Run detail\n\n- Run 1: stayed clean = true · flagged: (no phrases flagged)\n- Run 2: ERROR — Bad state: Stage 1 call timed out\n\n## Structural battery — removal sub-set (redundant word present)\n\n### TEST-3-structural-removal\n\n- Text: `Ejemplo con palabra redundante redundante.`\n- Note: Synthetic removal-subset phrase for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Target 1 (\"palabra redundante\"): 100.0% (2/2)\n- Fully caught (all targets in one run): 100.0% (2/2)\n\n#### Run detail\n\n- Run 1: targets caught = [true] · flagged: \"redundante\"\n- Run 2: targets caught = [true] · flagged: \"palabra redundante redundante\"\n\n## Structural battery — omission sub-set (nothing to quote)\n\n### TEST-4-structural-omission _(observational only — not scored pass/fail)_\n\n- Text: `Falta algo aqui.`\n- Note: Synthetic omission-subset phrase for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Stayed clean: 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: stayed clean = true · flagged: (no phrases flagged)\n- Run 2: stayed clean = false · flagged: \"Falta algo aqui\"\n\n---\n\n## Overall summary\n\n| Phrase | Runs | Errors | Headline rate | Per-target rates |\n| --- | --- | --- | --- | --- |\n| TEST-1-core | 2 | 0 | 50.0% (1/2) (fully caught) | 50.0% (1/2) |\n| TEST-2-dialectal | 2 | 1 | 100.0% (1/1) (clean) | — |\n| TEST-3-structural-removal | 2 | 0 | 100.0% (2/2) (fully caught) | 100.0% (2/2) |\n| TEST-4-structural-omission | 2 | 0 | 50.0% (1/2) (clean) | — |\n"';
