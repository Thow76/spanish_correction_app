// Stage 1 dialect-flagging variant harness.
//
// Tests `stage1DetectionDialectSpanish`
// (lib/core/services/prompts/correction_prompt.dart) — a variant of the
// Stage 1 bare-detection prompt that adds one sentence, "Flag standard
// dialect differences.", to see:
//   (a) whether it surfaces the intended dialectal cases that the base
//       prompt (stage1DetectionSpanish) treats as clean/ambiguous,
//   (b) whether it starts over-flagging ordinary regional vocabulary that
//       isn't dialectally loaded at all, and
//   (c) whether genuine error detection (the base prompt's core job) is
//       unaffected by the addition.
//
// PARALLEL FILE, not an extension of test/stage1_detection_harness.dart:
// several phrases' scoring semantics genuinely flip between the two prompts
// (ES-2/ES-D1 goes from "must stay clean" under the base prompt to "record
// the flag rate, not scored pass/fail" here, since flagging it is now the
// intended behaviour, not a false positive) — folding that into the
// existing `_Phrase`/scoring model would mean the same fixture meaning two
// different things depending on which prompt is under test, which is more
// confusing than two files that are each internally consistent. Standalone
// by the same discipline as every other harness in this repo: helper
// functions are copied by value from stage1_detection_harness.dart, not
// imported, direct `/v1/chat/completions` call, env-only OPENAI_API_KEY,
// GPT-5.5 default.
//
// Battery: the same phrases (by text) as the relevant subset of
// stage1_detection_harness.dart's battery, so the two harnesses' reports are
// directly comparable phrase-for-phrase:
//   - Regression check (must still catch): ES-1, ES-3, ES-4, ES-5 — same
//     text and expectedFlags as the base harness, same pass/fail scoring.
//   - Intended new flags (the whole point of the variant): ES-2/ES-D1 "voy
//     para casa" and ES-D2 "coger el autobús" — both previously
//     clean/observational; now flagging them is the correct, intended
//     behaviour, so this harness only records the flag rate rather than
//     scoring either outcome as pass/fail.
//   - Key negative test (must NOT get pulled in): ES-D3 "coche" (already a
//     hard negative test in the base harness — kept as one here, since
//     that's exactly the make-or-break question for whether "Flag standard
//     dialect differences" over-triggers on ordinary regional vocabulary)
//     plus a second ordinary-regional-vocab negative, "ordenador" (Spain
//     standard) vs. "computadora" (Latin America) — genuinely
//     interchangeable regional vocabulary, not a dialectal split with any
//     risk of confusion or offense, so this must not flag either.
//
// Does NOT touch `correctText()`, `stage1DetectionSpanish`, or any live
// path.
//
// Run only the offline tests, skipping the live call entirely:
//   flutter test test/stage1_detection_dialect_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/stage1_detection_dialect_harness.dart --timeout none
//
// Writes a report to docs/stage1_detection_dialect_harness.md (override
// with --dart-define=STAGE1_DIALECT_DETECTION_OUTPUT=...) — a distinct file
// from docs/stage1_detection_harness.md, so both are diffable side by side.
// Override run count per phrase with
// --dart-define=STAGE1_DIALECT_RUNS_PER_PHRASE=... (default 10). Override
// the model with --dart-define=STAGE1_DIALECT_DETECTION_MODEL=... (default
// 'gpt-5.5').

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/services/prompts/correction_prompt.dart';

const int runsPerPhrase = int.fromEnvironment(
  'STAGE1_DIALECT_RUNS_PER_PHRASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'STAGE1_DIALECT_DETECTION_OUTPUT',
  defaultValue: 'docs/stage1_detection_dialect_harness.md',
);

/// Model used for the live run. Override with
/// `--dart-define=STAGE1_DIALECT_DETECTION_MODEL=...`, same override
/// pattern as the base harness's `stage1Model`.
const String stage1DialectModel = String.fromEnvironment(
  'STAGE1_DIALECT_DETECTION_MODEL',
  defaultValue: 'gpt-5.5',
);

/// Delay after every call in the live run, same rate-limit mitigation the
/// other harnesses in this repo use.
const int callDelayMs = int.fromEnvironment(
  'STAGE1_DIALECT_CALL_DELAY_MS',
  defaultValue: 750,
);

/// Which battery a phrase belongs to, so the report can print them under
/// separate headings.
enum _PhraseGroup { regressionCheck, intendedFlags, negativeTest }

String _groupHeading(_PhraseGroup group) => switch (group) {
  _PhraseGroup.regressionCheck =>
    'Regression check (genuine errors — must still catch)',
  _PhraseGroup.intendedFlags =>
    'Intended new flags (previously clean/observational — now the correct '
        'behaviour)',
  _PhraseGroup.negativeTest =>
    'Key negative test (ordinary regional vocabulary — must NOT be pulled in)',
};

/// One test phrase for the dialect-variant Stage 1 prompt. Same shape as
/// stage1_detection_harness.dart's `_Phrase`, copied by value.
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

  /// True for the "intended new flags" group: neither flagging nor staying
  /// clean is scored pass/fail here — only the rate is recorded, since
  /// under this variant a flag is the intended/correct outcome, not
  /// something being tested for.
  final bool isObservationalOnly;

  bool get isNegativeTest => expectedFlags.isEmpty;
}

const List<_Phrase> _phrases = [
  // ── Regression check (genuine errors — must still catch). Text and
  // expectedFlags copied by value from stage1_detection_harness.dart's
  // ES-1/ES-3/ES-4/ES-5, unchanged, so before/after scoring is directly
  // comparable. ────────────────────────────────────────────────────────
  _Phrase(
    id: 'ES-1-repeated-word',
    group: _PhraseGroup.regressionCheck,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    expectedFlags: ['para casa'],
    note:
        'Genuine grammar error ("volví para casa" -> "volví a casa"), '
        'unrelated to dialect. Same expectedFlags as the base harness\'s '
        'ES-1-repeated-word — must still be caught with the dialect '
        'instruction added.',
  ),
  _Phrase(
    id: 'ES-3-multi-correction',
    group: _PhraseGroup.regressionCheck,
    text:
        'Ayer había mucho trafico y mis amigos llamaron para atrás para '
        'confirmar la cena.',
    expectedFlags: ['trafico', 'llamaron para atrás'],
    note:
        'A spelling error and a calque, both genuine errors unrelated to '
        'dialect. Same expectedFlags as the base harness\'s '
        'ES-3-multi-correction.',
  ),
  _Phrase(
    id: 'ES-4-calque',
    group: _PhraseGroup.regressionCheck,
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche.',
    expectedFlags: ['Puedo tener una cerveza', 'pasar un buen tiempo'],
    note:
        'Two calque targets, genuine errors unrelated to dialect. Same '
        'expectedFlags as the base harness\'s ES-4-calque.',
  ),
  _Phrase(
    id: 'ES-5-accents',
    group: _PhraseGroup.regressionCheck,
    text:
        'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
    expectedFlags: ['Espana', 'anos', 'cumpleanos', 'otono'],
    note:
        'Four missing-accent targets, genuine errors unrelated to dialect. '
        'Same expectedFlags as the base harness\'s ES-5-accents.',
  ),

  // ── Intended new flags: previously clean (ES-2/ES-D1) or observational
  // (ES-D2) under stage1DetectionSpanish. Under this variant, flagging them
  // is the correct, intended outcome — recorded as a rate, not scored
  // pass/fail. ─────────────────────────────────────────────────────────
  _Phrase(
    id: 'ES-2-para-casa',
    group: _PhraseGroup.intendedFlags,
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
    expectedFlags: [],
    note:
        'Same text as ES-2-single-char / ES-D1-para-casa-latam in the base '
        'harness, where it was a hard negative test (must stay clean) — '
        '"voy para casa" is standard in much of Latin America but a '
        'dialectal split from Peninsular "voy a casa". Under this variant, '
        'flagging it is the intended new behaviour, not a false positive. '
        'Record the flag rate; not scored pass/fail.',
    isObservationalOnly: true,
  ),
  _Phrase(
    id: 'ES-D2-coger-autobus',
    group: _PhraseGroup.intendedFlags,
    text: 'Voy a coger el autobús para ir al centro.',
    expectedFlags: [],
    note:
        'Same text as ES-D2-coger-autobus in the base harness, where it '
        'was already observational (ambiguous under the plain prompt: '
        'standard in Spain, vulgar in much of Latin America). Under this '
        'variant it is expected to flag as a dialect difference. Record '
        'the flag rate; not scored pass/fail.',
    isObservationalOnly: true,
  ),

  // ── Key negative test: ordinary regional vocabulary, no dialectal risk
  // of confusion or offense. The make-or-break question — does "Flag
  // standard dialect differences" over-trigger on plain regional word
  // choice? Kept as a hard pass/fail negative test, same as ES-D3 was in
  // the base harness. ──────────────────────────────────────────────────
  _Phrase(
    id: 'ES-D3-coche',
    group: _PhraseGroup.negativeTest,
    text: 'Aparqué el coche cerca de la oficina.',
    expectedFlags: [],
    note:
        'Same text as ES-D3-coche in the base harness, already a hard '
        'negative test there. "coche" (car) is ordinary regional '
        'vocabulary, not a dialectal split with any confusion/offense '
        'risk — must not be flagged even with the dialect instruction '
        'added. THE make-or-break check for this variant.',
  ),
  _Phrase(
    id: 'ordenador',
    group: _PhraseGroup.negativeTest,
    text: 'Voy a usar el ordenador en la oficina.',
    expectedFlags: [],
    note:
        'New negative test: "ordenador" is Spain-standard, "computadora" '
        'elsewhere — ordinary interchangeable regional vocabulary, not a '
        'dialectal split with real risk of confusion or offense (unlike '
        '"coger el autobús"). Must not be flagged.',
  ),
];

/// Lowercases and strips Spanish diacritics so span matching survives the
/// model correcting the accent itself. Copied by value from
/// stage1_detection_harness.dart's `_normalizeForMatch` — this file stays
/// standalone, so it's duplicated rather than imported.
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

/// Case/diacritic-insensitive containment check in either direction. Copied
/// by value from stage1_detection_harness.dart's `_normalizedOverlap`.
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
/// call. No `response_format` — the dialect variant's JSON-array
/// instruction lives entirely in the prompt text, same approach as the
/// other harnesses' `buildChatCompletionsBody`.
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
/// from the other harnesses' `extractReplyText`.
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
/// Copied by value from stage1_detection_harness.dart's
/// `parseDetectionArray` — same tolerant bracket-extraction approach.
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
/// via [error] rather than dropped, same as the other harnesses'
/// `_RunRecord`.
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
/// computed over non-error runs only, same as the other harnesses'
/// aggregate types.
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

/// Builds the full markdown report: a header block (naming this as the
/// dialect-flagging variant and pointing at the base harness's report for
/// comparison), then each phrase group as its own section, one subsection
/// per phrase (metadata, aggregate summary, run-by-run breakdown), then an
/// overall-summary table.
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
    ..writeln('# Stage 1 Detection Harness — Dialect-Flagging Variant')
    ..writeln()
    ..writeln(
      'Compares `stage1DetectionDialectSpanish` against the same battery '
      '`stage1DetectionSpanish` was run on — see docs/stage1_detection_harness.md '
      'for the base-prompt results this is meant to sit alongside.',
    )
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

Future<List<String>> _callStage1DetectionDialect({
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
          systemPrompt: stage1DetectionDialectSpanish,
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
  test('stage1 dialect-variant harness phrase fixtures are well-formed', () {
    expect(
      _phrases.length,
      8,
      reason: '4 regression-check + 2 intended-flags + 2 negative-test.',
    );

    final regressionCheck = _phrases.where((p) => p.group == _PhraseGroup.regressionCheck);
    final intendedFlags = _phrases.where((p) => p.group == _PhraseGroup.intendedFlags);
    final negativeTest = _phrases.where((p) => p.group == _PhraseGroup.negativeTest);
    expect(regressionCheck.length, 4);
    expect(intendedFlags.length, 2);
    expect(negativeTest.length, 2);

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

    // Regression-check phrases carry real targets (positive tests) and are
    // never observational — this is the "must still catch" group.
    for (final phrase in regressionCheck) {
      expect(phrase.isNegativeTest, isFalse, reason: phrase.id);
      expect(phrase.isObservationalOnly, isFalse, reason: phrase.id);
    }

    // Intended-flags phrases are negative-shaped (empty expectedFlags, so a
    // flag isn't checked against a specific substring) but observational —
    // the point is recording the rate, not pass/fail.
    for (final phrase in intendedFlags) {
      expect(phrase.isNegativeTest, isTrue, reason: phrase.id);
      expect(phrase.isObservationalOnly, isTrue, reason: phrase.id);
    }

    // Negative-test phrases are hard pass/fail: must stay clean, not merely
    // observational.
    for (final phrase in negativeTest) {
      expect(phrase.isNegativeTest, isTrue, reason: phrase.id);
      expect(phrase.isObservationalOnly, isFalse, reason: phrase.id);
    }

    // Same text as the base harness's phrases, verbatim, so results are
    // directly comparable — guard against retyping drift.
    final textsById = {for (final p in _phrases) p.id: p.text};
    expect(
      textsById['ES-1-repeated-word'],
      'Ayer fui al supermercado para comprar pan y después volví para casa '
      'para preparar la cena.',
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
      textsById['ES-2-para-casa'],
      'Cuando termino el trabajo, voy para casa en autobús.',
    );
    expect(
      textsById['ES-D2-coger-autobus'],
      'Voy a coger el autobús para ir al centro.',
    );
    expect(
      textsById['ES-D3-coche'],
      'Aparqué el coche cerca de la oficina.',
    );
  });

  test(
    'stage1DetectionDialectSpanish is stage1DetectionSpanish plus exactly '
    'one inserted sentence',
    () {
      const addedSentence = 'Flag standard dialect differences.';
      expect(stage1DetectionDialectSpanish, contains(addedSentence));

      final withoutAddition = stage1DetectionDialectSpanish.replaceFirst(
        '$addedSentence ',
        '',
      );
      expect(
        withoutAddition,
        stage1DetectionSpanish,
        reason:
            'Removing the added sentence (plus its trailing space) from '
            'stage1DetectionDialectSpanish must yield stage1DetectionSpanish '
            'exactly — that is the whole point of the variant: one sentence '
            'added, nothing else changed.',
      );
    },
  );

  group('parseDetectionArray', () {
    test('parses a populated array', () {
      expect(
        parseDetectionArray('["voy para casa", "coger el autobús"]'),
        ['voy para casa', 'coger el autobús'],
      );
    });

    test('parses an empty array', () {
      expect(parseDetectionArray('[]'), isEmpty);
    });

    test('tolerates surrounding commentary or Markdown fences', () {
      expect(
        parseDetectionArray('```json\n["coche"]\n```'),
        ['coche'],
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
        () => parseDetectionArray('["coche", 42]'),
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

    test('_wasTargetCaught is false when nothing overlaps', () {
      expect(_wasTargetCaught(['otono'], 'trafico'), isFalse);
    });

    test('_catchResultsFor returns one bool per expected target, in order', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
      expect(phrase.expectedFlags.length, 2);

      final result = _catchResultsFor(['trafico'], phrase);
      expect(result, [true, false]);
    });

    test('_catchResultsFor is empty for a negative-test phrase', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-D3-coche');
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

      expect(record.targetCaught, [true, false]);
      expect(record.stayedClean, isNull);
      expect(record.isError, isFalse);
    });

    test(
      'intended-flags phrase: still builds a stayedClean record like any '
      'negative-shaped phrase (observational-ness is a report-only tag)',
      () {
        final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-para-casa');

        final flaggedRecord = _buildRunRecord(
          phrase: phrase,
          runIndex: 1,
          flaggedPhrases: ['voy para casa'],
        );
        expect(flaggedRecord.stayedClean, isFalse);

        final cleanRecord = _buildRunRecord(
          phrase: phrase,
          runIndex: 2,
          flaggedPhrases: const [],
        );
        expect(cleanRecord.stayedClean, isTrue);
      },
    );

    test('_errorRunRecord carries the error and no data', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
      final record = _errorRunRecord(
        phrase: phrase,
        runIndex: 3,
        error: StateError('timed out'),
      );

      expect(record.isError, isTrue);
      expect(record.error, isA<StateError>());
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

    test(
      'intended-flags phrase: cleanRate is really "stayed-clean rate", read '
      'as (1 - flag rate) in the report',
      () {
        final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-para-casa');

        final records = [
          _RunRecord(phraseId: phrase.id, runIndex: 1, stayedClean: false, flaggedPhrases: const ['voy para casa']),
          _RunRecord(phraseId: phrase.id, runIndex: 2, stayedClean: false, flaggedPhrases: const ['voy para casa']),
          _RunRecord(phraseId: phrase.id, runIndex: 3, stayedClean: true),
        ];

        final aggregate = _aggregatePhrase(phrase, records);

        // 2/3 runs flagged it (stayedClean == false) -> cleanRate 1/3.
        expect(aggregate.cleanRate, closeTo(1 / 3, 0.0001));
      },
    );

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
    '(header referencing the base-prompt report, grouped sections, '
    'per-phrase summary + run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerPhrase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        phrases: const [
          _Phrase(
            id: 'TEST-1-regression',
            group: _PhraseGroup.regressionCheck,
            text: 'Ejemplo de prueba para el informe.',
            expectedFlags: ['prueba'],
            note: 'Synthetic regression-check phrase for report golden test.',
          ),
          _Phrase(
            id: 'TEST-2-intended-flag',
            group: _PhraseGroup.intendedFlags,
            text: 'Frase dialectal de prueba.',
            expectedFlags: [],
            note: 'Synthetic intended-flag phrase for report golden test.',
            isObservationalOnly: true,
          ),
          _Phrase(
            id: 'TEST-3-negative',
            group: _PhraseGroup.negativeTest,
            text: 'Vocabulario regional ordinario.',
            expectedFlags: [],
            note: 'Synthetic negative-test phrase for report golden test.',
          ),
        ],
        recordsByPhraseId: {
          'TEST-1-regression': [
            _RunRecord(
              phraseId: 'TEST-1-regression',
              runIndex: 1,
              flaggedPhrases: const ['prueba'],
              targetCaught: const [true],
            ),
            _RunRecord(
              phraseId: 'TEST-1-regression',
              runIndex: 2,
              flaggedPhrases: const [],
              targetCaught: const [false],
            ),
          ],
          'TEST-2-intended-flag': [
            _RunRecord(
              phraseId: 'TEST-2-intended-flag',
              runIndex: 1,
              stayedClean: false,
              flaggedPhrases: const ['frase dialectal'],
            ),
            _errorRunRecord(
              phrase: const _Phrase(
                id: 'TEST-2-intended-flag',
                group: _PhraseGroup.intendedFlags,
                text: 'Frase dialectal de prueba.',
                expectedFlags: [],
                note: '',
                isObservationalOnly: true,
              ),
              runIndex: 2,
              error: StateError('Stage 1 dialect call timed out'),
            ),
          ],
          'TEST-3-negative': [
            _RunRecord(
              phraseId: 'TEST-3-negative',
              runIndex: 1,
              stayedClean: true,
            ),
            _RunRecord(
              phraseId: 'TEST-3-negative',
              runIndex: 2,
              stayedClean: true,
            ),
          ],
        },
        commit: 'abc1234',
      );

      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'stage1 dialect-variant harness (live)',
    () async {
      final apiKey = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY to run the Stage 1 dialect-variant harness. '
          'This script does NOT fall back to any hardcoded/default key — '
          'no AppConfig involved, by design (see the file header).',
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
              final flaggedPhrases = await _callStage1DetectionDialect(
                httpClient: httpClient,
                apiKey: apiKey,
                model: stage1DialectModel,
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
        model: stage1DialectModel,
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
    r'"# Stage 1 Detection Harness — Dialect-Flagging Variant\n\nCompares `stage1DetectionDialectSpanish` against the same battery `stage1DetectionSpanish` was run on — see docs/stage1_detection_harness.md for the base-prompt results this is meant to sit alongside.\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per phrase: 2\n\n## Regression check (genuine errors — must still catch)\n\n### TEST-1-regression\n\n- Text: `Ejemplo de prueba para el informe.`\n- Note: Synthetic regression-check phrase for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Target 1 (\"prueba\"): 50.0% (1/2)\n- Fully caught (all targets in one run): 50.0% (1/2)\n\n#### Run detail\n\n- Run 1: targets caught = [true] · flagged: \"prueba\"\n- Run 2: targets caught = [false] · flagged: (no phrases flagged)\n\n## Intended new flags (previously clean/observational — now the correct behaviour)\n\n### TEST-2-intended-flag _(observational only — not scored pass/fail)_\n\n- Text: `Frase dialectal de prueba.`\n- Note: Synthetic intended-flag phrase for report golden test.\n\n#### Summary (2 runs, 1 error(s))\n\n- Stayed clean: 0.0% (0/1)\n\n#### Run detail\n\n- Run 1: stayed clean = false · flagged: \"frase dialectal\"\n- Run 2: ERROR — Bad state: Stage 1 dialect call timed out\n\n## Key negative test (ordinary regional vocabulary — must NOT be pulled in)\n\n### TEST-3-negative\n\n- Text: `Vocabulario regional ordinario.`\n- Note: Synthetic negative-test phrase for report golden test.\n\n#### Summary (2 runs, 0 error(s))\n\n- Stayed clean: 100.0% (2/2)\n\n#### Run detail\n\n- Run 1: stayed clean = true · flagged: (no phrases flagged)\n- Run 2: stayed clean = true · flagged: (no phrases flagged)\n\n---\n\n## Overall summary\n\n| Phrase | Runs | Errors | Headline rate | Per-target rates |\n| --- | --- | --- | --- | --- |\n| TEST-1-regression | 2 | 0 | 50.0% (1/2) (fully caught) | 50.0% (1/2) |\n| TEST-2-intended-flag | 2 | 1 | 0.0% (0/1) (clean) | — |\n| TEST-3-negative | 2 | 0 | 100.0% (2/2) (clean) | — |\n"';
