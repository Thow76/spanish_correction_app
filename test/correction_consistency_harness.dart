// Correction consistency harness.
//
// MANUAL harness — will make live correction-API calls through the REAL,
// unmodified `OpenAiCorrectionService.correctText()` (no prompt injection),
// same pattern as `spanish_ab_stability.dart`. Runs each phrase below
// `runsPerPhrase` times per language and will aggregate catch rate,
// span-width distribution, and category distribution once later steps land.
//
// Step 1 (done): phrase fixtures — scaffold, data model, shape-check test.
// Step 2 (done): span-width bucketing — a pure function classifying a
// CorrectionItem's span as word/phrase/clause, plus unit tests.
// Step 3 (done): catch detection — pure functions checking whether a
// CorrectionResponse caught a phrase's expected target(s).
// Step 4 (done): per-run record type (_RunRecord) and aggregation
// (_aggregatePhrase) rolling a phrase's runs into catch-rate, span-width
// distribution, and category distribution.
// Step 5 (done): markdown report writer (_buildReport), pure — takes
// already-collected records and returns the report string. Golden-tested
// against a captured fixture string.
// Step 6 (done): live-call wiring. The final `test(...)` in main() below is
// a MANUAL harness, tagged 'live' — it calls the REAL, unmodified
// `OpenAiCorrectionService.correctText()` `runsPerPhrase` times for each of
// the 12 phrases (both languages, same loop), builds a _RunRecord per call
// via _buildRunRecord/_errorRunRecord, aggregates and writes the report via
// _buildReport, same instantiation/auth/output pattern as
// spanish_ab_stability.dart. It FAILS (does not silently skip) when no API
// key is configured.
//
// Post-Step-6 fixes (error detail + call spacing): a first live run got
// increasingly rate-limit-shaped errors from partway through PT-1 onward,
// but every failure printed only `ERROR — Instance of
// 'CorrectionServiceException'` — the type's default toString(), with no
// detail. _describeError now surfaces `reason`/`message` instead (message
// already carries the HTTP status/body where applicable — see
// OpenAiCorrectionService._createResponse). A `callDelayMs` (default 750ms,
// `--dart-define=CALL_DELAY_MS=...`) delay was added between calls in the
// live loop to stop firing requests back-to-back; this is scoped entirely
// to this test file, not the production call path.
//
// Step 7 (next, not yet done): actually run it live and sanity-check the
// output against known manual-testing behavior.
//
// Run only the offline tests (Steps 1-5), skipping the live call entirely:
//   flutter test test/correction_consistency_harness.dart --exclude-tags live
//
// Run everything, including the live harness (costs real API calls):
//   OPENAI_API_KEY=sk-... flutter test test/correction_consistency_harness.dart --timeout none
//
// Writes a report to docs/correction_consistency_harness.md (override with
// --dart-define=CONSISTENCY_OUTPUT=...). Override run count per phrase with
// --dart-define=RUNS_PER_PHRASE=... (default 10).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service_exception.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';

const int runsPerPhrase = int.fromEnvironment(
  'RUNS_PER_PHRASE',
  defaultValue: 10,
);

const String outputPath = String.fromEnvironment(
  'CONSISTENCY_OUTPUT',
  defaultValue: 'docs/correction_consistency_harness.md',
);

/// Delay after every `correctText()` call in the live run, so the harness
/// doesn't fire ~120 requests back-to-back. A prior live run started failing
/// partway through PT-1 with errors that looked rate-limit-shaped; this is a
/// test-file-only mitigation (no change to the production call path), easy
/// to tune via `--dart-define=CALL_DELAY_MS=...` without touching code.
const int callDelayMs = int.fromEnvironment('CALL_DELAY_MS', defaultValue: 750);

/// One correction this phrase is expected to trigger.
///
/// [acceptedCategories] is a set (not a single label) because some error
/// patterns straddle two categories in practice — e.g. the redundant-subject-
/// pronoun cases (ES-6/PT-6) are legitimately gradable as either Grammar or
/// Natural Language, and a flip between the two across runs is itself the
/// signal being measured, not a miss.
class _ExpectedTarget {
  const _ExpectedTarget({
    required this.originalPhraseSubstring,
    required this.acceptedCategories,
  });

  /// Substring of the phrase's [_Phrase.text] this target correction should
  /// cover. Matched case/diacritic-insensitively against a run's returned
  /// `CorrectionItem.originalPhrase` in a later step.
  final String originalPhraseSubstring;
  final Set<String> acceptedCategories;
}

/// One test phrase, with zero or more expected target corrections.
///
/// An empty [expectedTargets] list marks a negative test (ES-2): the phrase
/// is expected to produce no correction at all, so "caught" for that phrase
/// means the run returned zero corrections overlapping the phrase's known
/// acceptable-as-is span.
class _Phrase {
  const _Phrase({
    required this.id,
    required this.language,
    required this.text,
    required this.expectedTargets,
    required this.note,
  });

  final String id;
  final Language language;
  final String text;
  final List<_ExpectedTarget> expectedTargets;
  final String note;

  bool get isNegativeTest => expectedTargets.isEmpty;
}

const List<_Phrase> _phrases = [
  // ── Spanish ──────────────────────────────────────────────────────────────
  _Phrase(
    id: 'ES-1-repeated-word',
    language: Language.spanish,
    text:
        'Ayer fui al supermercado para comprar pan y después volví para casa '
        'para preparar la cena.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'para casa',
        acceptedCategories: {'Grammar'},
      ),
    ],
    note:
        'Two instances of "para" appear before this one ("para comprar", '
        '"para preparar"); only "volví para casa" -> "volví a casa" should '
        'be flagged. Checks repeated-word span targeting.',
  ),
  _Phrase(
    id: 'ES-2-single-char',
    language: Language.spanish,
    text: 'Cuando termino el trabajo, voy para casa en autobús.',
    expectedTargets: [],
    note:
        'Negative test. "voy para casa" is acceptable Spanish — confirm no '
        'correction fires.',
  ),
  _Phrase(
    id: 'ES-3-multi-correction',
    language: Language.spanish,
    text:
        'Ayer había mucho trafico y mis amigos llamaron para atrás para '
        'confirmar la cena.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'trafico',
        acceptedCategories: {'Spelling'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'llamaron para atrás',
        acceptedCategories: {'Natural Language'},
      ),
    ],
    note:
        'Two independent targets: "trafico" -> "tráfico" (Spelling) and '
        '"llamaron para atrás" -> "devolvieron la llamada" (Natural '
        'Language) — track both.',
  ),
  _Phrase(
    id: 'ES-4-calque',
    language: Language.spanish,
    text:
        '¿Puedo tener una cerveza? Quiero pasar un buen tiempo con mis '
        'amigos esta noche.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'Puedo tener una cerveza',
        acceptedCategories: {'Natural Language'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'pasar un buen tiempo',
        acceptedCategories: {'Natural Language'},
      ),
    ],
    note:
        'Two calque targets: "Puedo tener una cerveza" and "pasar un buen '
        'tiempo" -> "pasarlo bien" — track both.',
  ),
  _Phrase(
    id: 'ES-5-accents',
    language: Language.spanish,
    text:
        'Vivo en Espana desde hace tres anos y mi cumpleanos es en otono.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'Espana',
        acceptedCategories: {'Spelling'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'anos',
        acceptedCategories: {'Spelling'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'cumpleanos',
        acceptedCategories: {'Spelling'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'otono',
        acceptedCategories: {'Spelling'},
      ),
    ],
    note:
        'Four independent accent targets in one phrase — track catch rate '
        'per individual word, not just phrase-level.',
  ),
  _Phrase(
    id: 'ES-6-redundant-pronoun',
    language: Language.spanish,
    text: 'Yo fui a casa, yo estudié, y yo hice la cena.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'yo estudié',
        acceptedCategories: {'Grammar', 'Natural Language'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'yo hice la cena',
        acceptedCategories: {'Grammar', 'Natural Language'},
      ),
    ],
    note:
        'Spanish is pro-drop; repeating "yo" before every verb is '
        'grammatical but unnatural. Expect the 2nd and/or 3rd "yo" dropped '
        '(first "yo" typically kept). Category assignment itself may be '
        'unstable between Grammar and Natural Language — both accepted.',
  ),

  // ── Portuguese ───────────────────────────────────────────────────────────
  _Phrase(
    id: 'PT-1-repeated-word',
    language: Language.portuguese,
    text:
        'Ontem fui ao supermercado para comprar pão e depois voltei para '
        'casa para preparar o jantar, mas esqueci para pegar o leite.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'esqueci para pegar',
        acceptedCategories: {'Grammar'},
      ),
    ],
    note:
        '"para" appears four times; only "esqueci para pegar" -> "esqueci '
        'de pegar" should be flagged. Checks correct-instance targeting.',
  ),
  _Phrase(
    id: 'PT-2-single-char',
    language: Language.portuguese,
    text:
        'Eu gosto de ir a praia nos fins de semana com a minha família.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'a praia',
        acceptedCategories: {'Grammar'},
      ),
    ],
    note:
        '"a" -> "à". Confirm correction lands on "a praia", not the later '
        '"a minha família".',
  ),
  _Phrase(
    id: 'PT-3-multi-correction',
    language: Language.portuguese,
    text:
        'Ontem tinha muito transito no caminho para o trabalho e meus '
        'amigos ligaram de volta para confirmar o jantar.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'transito',
        acceptedCategories: {'Spelling'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'ligaram de volta',
        acceptedCategories: {'Natural Language'},
      ),
    ],
    note:
        'Two independent targets: "transito" -> "trânsito" (Spelling) and '
        '"ligaram de volta" -> "retornaram a ligação" or similar (Natural '
        'Language) — track both.',
  ),
  _Phrase(
    id: 'PT-4-calque',
    language: Language.portuguese,
    text:
        'Posso ter uma cerveja? Quero passar um bom tempo com meus amigos '
        'essa noite.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'Posso ter uma cerveja',
        acceptedCategories: {'Natural Language'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'passar um bom tempo',
        acceptedCategories: {'Natural Language'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'essa noite',
        acceptedCategories: {'Natural Language'},
      ),
    ],
    note:
        'Three targets: "Posso ter uma cerveja", "passar um bom tempo" -> '
        '"me divertir"/"curtir", and possibly "essa noite" -> "hoje à '
        'noite" — track all three.',
  ),
  _Phrase(
    id: 'PT-5-accents',
    language: Language.portuguese,
    text:
        'Morei em Sao Paulo por tres anos mas agora vivo em Curitiba e '
        'meu aniversario é em julho.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'Sao',
        acceptedCategories: {'Spelling'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'tres',
        acceptedCategories: {'Spelling'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'aniversario',
        acceptedCategories: {'Spelling'},
      ),
    ],
    note:
        'Three independent accent targets in one phrase — track catch '
        'rate per individual word.',
  ),
  _Phrase(
    id: 'PT-6-redundant-pronoun',
    language: Language.portuguese,
    text: 'Eu fui para casa, eu estudei, e eu fiz o jantar.',
    expectedTargets: [
      _ExpectedTarget(
        originalPhraseSubstring: 'eu estudei',
        acceptedCategories: {'Grammar', 'Natural Language'},
      ),
      _ExpectedTarget(
        originalPhraseSubstring: 'eu fiz o jantar',
        acceptedCategories: {'Grammar', 'Natural Language'},
      ),
    ],
    note:
        'Portuguese is pro-drop; same pattern as ES-6. Expect 2nd and/or '
        '3rd "eu" dropped, first typically kept. This overlaps directly '
        'with the known BP-002 pronoun rule (~33-40% detection miss '
        'rate) — this phrase is a direct test of that existing known '
        'limitation, not a new unrelated case.',
  ),
];

/// Span-width bucket for a single correction, by word count of the span it
/// covers.
enum SpanBucket { word, phrase, clause }

/// Classifies [item]'s span as [SpanBucket.word] (1 word), [SpanBucket.phrase]
/// (2-4 words), or [SpanBucket.clause] (5+ words).
///
/// `item.originalPhrase` is already the exact submitted-text slice between
/// `startIndex`/`endIndex` (see `CorrectionItem.fromAnchoredJson`), so its
/// word count directly reflects the span width — no separate index math is
/// needed. The one case that breaks down is an insertion (`isInsertion`),
/// where `originalPhrase` is empty by definition; there the inserted
/// `correctedPhrase` is the only text describing the span, so it's used
/// instead. A correction with no text on either side (degenerate/malformed)
/// falls back to [SpanBucket.word] rather than throwing.
SpanBucket bucketFor(CorrectionItem item) {
  final spanText = item.originalPhrase.trim().isNotEmpty
      ? item.originalPhrase
      : item.correctedPhrase;
  final wordCount = _wordCount(spanText);

  if (wordCount <= 1) {
    return SpanBucket.word;
  }
  if (wordCount <= 4) {
    return SpanBucket.phrase;
  }
  return SpanBucket.clause;
}

int _wordCount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return 0;
  }
  return trimmed.split(RegExp(r'\s+')).length;
}

/// Whether [target] was caught somewhere in [response]: at least one
/// returned correction has a category [target] accepts, and its span
/// overlaps [target]'s substring.
///
/// "Overlaps" is a case/diacritic-insensitive containment check in either
/// direction, not exact equality — the model may return a correction whose
/// `originalPhrase` is a larger span than the target substring (e.g. the
/// whole clause around "para casa") or, in principle, a smaller one, and
/// either should still count as catching the target.
bool _wasTargetCaught(CorrectionResponse response, _ExpectedTarget target) {
  return response.corrections.any((correction) {
    if (!target.acceptedCategories.contains(correction.category.label)) {
      return false;
    }
    return _normalizedOverlap(
      target.originalPhraseSubstring,
      correction.originalPhrase,
    );
  });
}

/// For a negative-test phrase (empty `expectedTargets`), whether [response]
/// correctly produced no corrections at all.
bool _staysClean(CorrectionResponse response) => response.corrections.isEmpty;

/// Checks [response] against every expected target in [phrase], returning
/// one bool per target in the same order as `phrase.expectedTargets`.
/// Always empty for negative-test phrases — use [_staysClean] for those.
List<bool> _catchResultsFor(CorrectionResponse response, _Phrase phrase) {
  return phrase.expectedTargets
      .map((target) => _wasTargetCaught(response, target))
      .toList();
}

bool _normalizedOverlap(String a, String b) {
  final normalizedA = _normalizeForMatch(a);
  final normalizedB = _normalizeForMatch(b);
  if (normalizedA.isEmpty || normalizedB.isEmpty) {
    return false;
  }
  return normalizedA.contains(normalizedB) || normalizedB.contains(normalizedA);
}

/// Lowercases and strips Spanish/Portuguese diacritics so span matching
/// survives the model correcting the accent itself (e.g. target substring
/// "trafico" vs. a returned correction echoing "tráfico").
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

/// One correction actually returned in a run, reduced to the three things
/// the aggregate cares about: its category label, its span-width bucket,
/// and the replacement wording (for eyeballing in the report later).
class _RunCorrection {
  const _RunCorrection({
    required this.category,
    required this.bucket,
    required this.replacementText,
  });

  final String category;
  final SpanBucket bucket;
  final String replacementText;
}

/// One run's outcome for one phrase.
///
/// Exactly one of two shapes applies, matching [_Phrase.isNegativeTest]:
/// - Positive-test phrase: [targetCaught] holds one bool per expected
///   target (same order as `phrase.expectedTargets`); [stayedClean] is null.
/// - Negative-test phrase: [stayedClean] holds whether the run produced no
///   corrections; [targetCaught] is null.
///
/// A transient API failure on this run is recorded via [error] rather than
/// dropped — matching how `retranslation_grade_validation.dart` and
/// `spanish_ab_stability.dart` both keep a failed run visible in the report
/// instead of silently skipping it. When [error] is set, [targetCaught],
/// [stayedClean], and [corrections] carry no data and must not be read.
class _RunRecord {
  const _RunRecord({
    required this.phraseId,
    required this.runIndex,
    this.targetCaught,
    this.stayedClean,
    this.corrections = const [],
    this.error,
  });

  final String phraseId;
  final int runIndex;
  final List<bool>? targetCaught;
  final bool? stayedClean;
  final List<_RunCorrection> corrections;
  final Object? error;

  bool get isError => error != null;
}

/// Builds the [_RunRecord] for a successful call: reduces [response] against
/// [phrase]'s expectations via [_catchResultsFor]/[_staysClean], and reduces
/// every returned correction to a [_RunCorrection] via [bucketFor].
_RunRecord _buildRunRecord({
  required _Phrase phrase,
  required int runIndex,
  required CorrectionResponse response,
}) {
  final runCorrections = response.corrections
      .map(
        (correction) => _RunCorrection(
          category: correction.category.label,
          bucket: bucketFor(correction),
          replacementText: correction.correctedPhrase,
        ),
      )
      .toList();

  return _RunRecord(
    phraseId: phrase.id,
    runIndex: runIndex,
    targetCaught: phrase.isNegativeTest ? null : _catchResultsFor(response, phrase),
    stayedClean: phrase.isNegativeTest ? _staysClean(response) : null,
    corrections: runCorrections,
  );
}

/// Records a run where the correction call itself failed (network/API/parse
/// error), so the aggregate's error count includes it instead of losing it.
_RunRecord _errorRunRecord({
  required _Phrase phrase,
  required int runIndex,
  required Object error,
}) {
  return _RunRecord(phraseId: phrase.id, runIndex: runIndex, error: error);
}

/// Aggregated results for one phrase across all its runs.
class _PhraseAggregate {
  const _PhraseAggregate({
    required this.phraseId,
    required this.totalRuns,
    required this.errorRuns,
    required this.targetCatchRates,
    required this.fullyCaughtRate,
    required this.cleanRate,
    required this.spanBucketCounts,
    required this.categoryCounts,
  });

  final String phraseId;
  final int totalRuns;
  final int errorRuns;

  /// One catch rate (0.0-1.0) per expected target, in `expectedTargets`
  /// order, computed over non-error runs only. Empty for negative-test
  /// phrases.
  final List<double> targetCatchRates;

  /// Fraction of non-error runs where every expected target was caught.
  /// Null for negative-test phrases (use [cleanRate] instead).
  final double? fullyCaughtRate;

  /// Fraction of non-error runs that produced no corrections at all.
  /// Null for positive-test phrases (use [fullyCaughtRate]/[targetCatchRates]
  /// instead).
  final double? cleanRate;

  /// Count of every correction returned across all non-error runs, by
  /// span-width bucket.
  final Map<SpanBucket, int> spanBucketCounts;

  /// Count of every correction returned across all non-error runs, by
  /// category label.
  final Map<String, int> categoryCounts;
}

/// Aggregates [records] (all for the same [phrase]) into catch-rate,
/// span-width distribution, and category distribution stats.
///
/// Rates are computed over non-error runs only, so an errored run lowers
/// neither a catch rate nor the clean rate — it's tracked separately via
/// [_PhraseAggregate.errorRuns] instead, the same "don't lose a failure but
/// don't let it corrupt the stat" approach the existing harnesses use for
/// per-case grader errors.
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
    targetCatchRates = List.generate(phrase.expectedTargets.length, (index) {
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

  final spanBucketCounts = {for (final bucket in SpanBucket.values) bucket: 0};
  final categoryCounts = <String, int>{};
  for (final record in okRecords) {
    for (final correction in record.corrections) {
      spanBucketCounts[correction.bucket] =
          spanBucketCounts[correction.bucket]! + 1;
      categoryCounts[correction.category] =
          (categoryCounts[correction.category] ?? 0) + 1;
    }
  }

  return _PhraseAggregate(
    phraseId: phrase.id,
    totalRuns: records.length,
    errorRuns: errorCount,
    targetCatchRates: targetCatchRates,
    fullyCaughtRate: fullyCaughtRate,
    cleanRate: cleanRate,
    spanBucketCounts: spanBucketCounts,
    categoryCounts: categoryCounts,
  );
}

/// Builds the full markdown report, in the same header/section style as
/// `spanish_ab_stability.dart`/`retranslation_grade_validation.dart`: a
/// header block, one section per phrase (metadata, aggregate summary, then
/// a run-by-run breakdown), and a final overall-summary table.
///
/// Pure — takes already-collected [recordsByPhraseId] rather than making any
/// calls itself, so it's golden-testable against synthetic data with no live
/// API involved. [phrases] supplies the metadata (text, note, expected
/// targets) that [recordsByPhraseId] alone doesn't carry; [commit] is
/// omitted from the header entirely when null, since a pure function has no
/// business shelling out to git itself.
String _buildReport({
  required String model,
  required int runsPerPhrase,
  required DateTime generatedAt,
  required List<_Phrase> phrases,
  required Map<String, List<_RunRecord>> recordsByPhraseId,
  String? commit,
}) {
  final report = StringBuffer()
    ..writeln('# Correction Consistency Harness')
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

  for (final phrase in phrases) {
    final records = recordsByPhraseId[phrase.id] ?? const <_RunRecord>[];
    final aggregate = _aggregatePhrase(phrase, records);
    final okRecords = records.where((r) => !r.isError).toList();

    report
      ..writeln('## ${phrase.id}')
      ..writeln()
      ..writeln('- Language: ${phrase.language.name}')
      ..writeln('- Text: `${phrase.text}`')
      ..writeln('- Note: ${phrase.note}')
      ..writeln()
      ..writeln(
        '### Summary (${aggregate.totalRuns} runs, '
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
      for (var i = 0; i < phrase.expectedTargets.length; i++) {
        final target = phrase.expectedTargets[i];
        final caughtCount = okRecords.where((r) => r.targetCaught![i]).length;
        final label = _percentLabel(caughtCount, okRecords.length);
        perTargetLabels.add(label);
        report.writeln(
          '- Target ${i + 1} ("${target.originalPhraseSubstring}"): $label',
        );
      }
      final fullyCaughtCount = okRecords
          .where((r) => r.targetCaught!.every((caught) => caught))
          .length;
      final fullyCaughtLabel = _percentLabel(
        fullyCaughtCount,
        okRecords.length,
      );
      report.writeln('- Fully caught (all targets in one run): $fullyCaughtLabel');
      summaryRows.add(
        '| ${phrase.id} | ${aggregate.totalRuns} | ${aggregate.errorRuns} | '
        '$fullyCaughtLabel (fully caught) | ${perTargetLabels.join(', ')} |',
      );
    }

    report
      ..writeln(
        '- Span-width distribution: word '
        '${aggregate.spanBucketCounts[SpanBucket.word]}, phrase '
        '${aggregate.spanBucketCounts[SpanBucket.phrase]}, clause '
        '${aggregate.spanBucketCounts[SpanBucket.clause]}',
      )
      ..writeln(
        '- Category distribution: '
        '${_describeCategoryCounts(aggregate.categoryCounts)}',
      )
      ..writeln()
      ..writeln('### Run detail')
      ..writeln();

    for (final record in records) {
      report.writeln(_describeRun(phrase, record));
    }
    report.writeln();
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

String _percentLabel(int count, int total) {
  if (total == 0) {
    return '0.0% (0/0)';
  }
  final pct = (count / total * 100).toStringAsFixed(1);
  return '$pct% ($count/$total)';
}

String _describeCategoryCounts(Map<String, int> counts) {
  if (counts.isEmpty) {
    return '(none)';
  }
  final entries = counts.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key} ${entry.value}').join(', ');
}

String _describeRun(_Phrase phrase, _RunRecord record) {
  final prefix = 'Run ${record.runIndex}';
  if (record.isError) {
    return '- $prefix: ERROR — ${_describeError(record.error!)}';
  }

  final status = phrase.isNegativeTest
      ? 'stayed clean = ${record.stayedClean}'
      : 'targets caught = ${record.targetCaught}';

  final corrections = record.corrections.isEmpty
      ? '(no corrections)'
      : record.corrections
            .map(
              (c) => '[${c.category}] "${c.replacementText}" (${c.bucket.name})',
            )
            .join('; ');

  return '- $prefix: $status · corrections: $corrections';
}

/// Renders an error for the report/console. `CorrectionServiceException` has
/// no `toString()` override, so a bare `'$error'` prints only
/// `Instance of 'CorrectionServiceException'` — which is exactly what made
/// the live run's mid-battery failures unreadable (rate limit vs. something
/// else was indistinguishable). `message` already carries the HTTP status
/// code and response body where applicable (see
/// `OpenAiCorrectionService._createResponse`'s `apiFailure` throw), so
/// surfacing `reason` + `message` is sufficient — no separate status-code
/// field exists to extract.
String _describeError(Object error) {
  if (error is CorrectionServiceException) {
    return '${error.reason.name}: ${error.message}';
  }
  return error.toString();
}

void main() {
  test('correction consistency harness phrase fixtures are well-formed', () {
    expect(_phrases.length, 12, reason: '6 Spanish + 6 Portuguese phrases.');

    final spanish = _phrases.where((p) => p.language == Language.spanish);
    final portuguese = _phrases.where(
      (p) => p.language == Language.portuguese,
    );
    expect(spanish.length, 6);
    expect(portuguese.length, 6);

    final ids = _phrases.map((p) => p.id).toSet();
    expect(ids.length, _phrases.length, reason: 'Phrase ids must be unique.');

    const validCategories = {
      'Grammar',
      'Natural Language',
      'Spelling',
      'Word Choice',
      'Other',
    };

    for (final phrase in _phrases) {
      expect(phrase.text.trim(), isNotEmpty, reason: phrase.id);

      for (final target in phrase.expectedTargets) {
        expect(
          phrase.text.contains(target.originalPhraseSubstring),
          isTrue,
          reason:
              '${phrase.id}: expected substring '
              '"${target.originalPhraseSubstring}" not found in phrase text.',
        );
        expect(
          target.acceptedCategories.isNotEmpty,
          isTrue,
          reason: phrase.id,
        );
        expect(
          target.acceptedCategories.difference(validCategories),
          isEmpty,
          reason:
              '${phrase.id}: unknown category in '
              '${target.acceptedCategories}.',
        );
      }
    }

    // Exactly one negative test (ES-2) in the current battery.
    expect(_phrases.where((p) => p.isNegativeTest).length, 1);
  });

  group('bucketFor', () {
    CorrectionItem item({
      required String originalPhrase,
      required String correctedPhrase,
    }) {
      return CorrectionItem(
        originalPhrase: originalPhrase,
        correctedPhrase: correctedPhrase,
        category: ErrorCategory.grammar,
        shortExplanation: 'test',
      );
    }

    test('single word is bucketed as word', () {
      expect(
        bucketFor(item(originalPhrase: 'trafico', correctedPhrase: 'tráfico')),
        SpanBucket.word,
      );
    });

    test('two words is bucketed as phrase (lower boundary)', () {
      expect(
        bucketFor(
          item(originalPhrase: 'para casa', correctedPhrase: 'a casa'),
        ),
        SpanBucket.phrase,
      );
    });

    test('four words is bucketed as phrase (upper boundary)', () {
      expect(
        bucketFor(
          item(
            originalPhrase: 'llamaron para atrás ayer',
            correctedPhrase: 'devolvieron la llamada ayer',
          ),
        ),
        SpanBucket.phrase,
      );
    });

    test('five words is bucketed as clause (lower boundary)', () {
      expect(
        bucketFor(
          item(
            originalPhrase: 'voy para casa en autobús',
            correctedPhrase: 'voy a casa en autobús',
          ),
        ),
        SpanBucket.clause,
      );
    });

    test('many words is bucketed as clause', () {
      expect(
        bucketFor(
          item(
            originalPhrase: 'Puedo tener una cerveza esta noche con mis amigos',
            correctedPhrase: '¿Me puedes traer una cerveza?',
          ),
        ),
        SpanBucket.clause,
      );
    });

    test('insertion (empty originalPhrase) falls back to correctedPhrase', () {
      final insertion = CorrectionItem(
        originalPhrase: '',
        correctedPhrase: 'a',
        category: ErrorCategory.grammar,
        shortExplanation: 'test',
        startIndex: 10,
        endIndex: 10,
      );
      expect(insertion.isInsertion, isTrue);
      expect(bucketFor(insertion), SpanBucket.word);
    });

    test('insertion with a multi-word correctedPhrase is bucketed by it', () {
      final insertion = CorrectionItem(
        originalPhrase: '',
        correctedPhrase: 'de vez en cuando',
        category: ErrorCategory.grammar,
        shortExplanation: 'test',
        startIndex: 10,
        endIndex: 10,
      );
      expect(bucketFor(insertion), SpanBucket.phrase);
    });

    test('degenerate correction with no text on either side is word', () {
      expect(
        bucketFor(item(originalPhrase: '', correctedPhrase: '')),
        SpanBucket.word,
      );
    });
  });

  group('catch detection', () {
    CorrectionItem correction({
      required String originalPhrase,
      required String correctedPhrase,
      required ErrorCategory category,
    }) {
      return CorrectionItem(
        originalPhrase: originalPhrase,
        correctedPhrase: correctedPhrase,
        category: category,
        shortExplanation: 'test',
      );
    }

    CorrectionResponse response(List<CorrectionItem> corrections) {
      return CorrectionResponse(
        originalText: 'unused in these tests',
        correctedText: 'unused in these tests',
        corrections: corrections,
      );
    }

    group('_wasTargetCaught', () {
      const target = _ExpectedTarget(
        originalPhraseSubstring: 'para casa',
        acceptedCategories: {'Grammar'},
      );

      test('true when a correction overlaps the target span and category matches', () {
        final result = response([
          correction(
            originalPhrase: 'para casa',
            correctedPhrase: 'a casa',
            category: ErrorCategory.grammar,
          ),
        ]);
        expect(_wasTargetCaught(result, target), isTrue);
      });

      test('true when the returned span is a larger clause containing the target', () {
        final result = response([
          correction(
            originalPhrase: 'volví para casa',
            correctedPhrase: 'volví a casa',
            category: ErrorCategory.grammar,
          ),
        ]);
        expect(_wasTargetCaught(result, target), isTrue);
      });

      test('true regardless of case or diacritics', () {
        final result = response([
          correction(
            originalPhrase: 'PARA CÁSA',
            correctedPhrase: 'a casa',
            category: ErrorCategory.grammar,
          ),
        ]);
        expect(_wasTargetCaught(result, target), isTrue);
      });

      test('false when category does not match, even if span overlaps', () {
        final result = response([
          correction(
            originalPhrase: 'para casa',
            correctedPhrase: 'a casa',
            category: ErrorCategory.spelling,
          ),
        ]);
        expect(_wasTargetCaught(result, target), isFalse);
      });

      test('false when no correction overlaps the span', () {
        final result = response([
          correction(
            originalPhrase: 'trafico',
            correctedPhrase: 'tráfico',
            category: ErrorCategory.spelling,
          ),
        ]);
        expect(_wasTargetCaught(result, target), isFalse);
      });

      test('false when there are no corrections at all', () {
        expect(_wasTargetCaught(response([]), target), isFalse);
      });

      test('accepts either category when target allows more than one', () {
        const dualCategoryTarget = _ExpectedTarget(
          originalPhraseSubstring: 'yo estudié',
          acceptedCategories: {'Grammar', 'Natural Language'},
        );
        final result = response([
          correction(
            originalPhrase: 'yo estudié',
            correctedPhrase: 'estudié',
            category: ErrorCategory.naturalLanguage,
          ),
        ]);
        expect(_wasTargetCaught(result, dualCategoryTarget), isTrue);
      });
    });

    test('_staysClean is true only when corrections is empty', () {
      expect(_staysClean(response([])), isTrue);
      expect(
        _staysClean(
          response([
            correction(
              originalPhrase: 'x',
              correctedPhrase: 'y',
              category: ErrorCategory.grammar,
            ),
          ]),
        ),
        isFalse,
      );
    });

    test(
      '_catchResultsFor returns one bool per expected target, in order',
      () {
        final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
        expect(phrase.expectedTargets.length, 2);

        // Only the first target ("trafico") is caught; "llamaron para
        // atrás" is missed this run.
        final result = response([
          correction(
            originalPhrase: 'trafico',
            correctedPhrase: 'tráfico',
            category: ErrorCategory.spelling,
          ),
        ]);

        expect(_catchResultsFor(result, phrase), [true, false]);
      },
    );

    test('_catchResultsFor is empty for a negative-test phrase', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-single-char');
      expect(phrase.isNegativeTest, isTrue);
      expect(_catchResultsFor(response([]), phrase), isEmpty);
    });
  });

  group('_buildRunRecord / _errorRunRecord', () {
    CorrectionItem correction({
      required String originalPhrase,
      required String correctedPhrase,
      required ErrorCategory category,
    }) {
      return CorrectionItem(
        originalPhrase: originalPhrase,
        correctedPhrase: correctedPhrase,
        category: category,
        shortExplanation: 'test',
      );
    }

    CorrectionResponse response(List<CorrectionItem> corrections) {
      return CorrectionResponse(
        originalText: 'unused in these tests',
        correctedText: 'unused in these tests',
        corrections: corrections,
      );
    }

    test('positive-test phrase: targetCaught set, stayedClean null', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');
      final result = response([
        correction(
          originalPhrase: 'trafico',
          correctedPhrase: 'tráfico',
          category: ErrorCategory.spelling,
        ),
      ]);

      final record = _buildRunRecord(phrase: phrase, runIndex: 1, response: result);

      expect(record.phraseId, 'ES-3-multi-correction');
      expect(record.runIndex, 1);
      expect(record.targetCaught, [true, false]);
      expect(record.stayedClean, isNull);
      expect(record.isError, isFalse);
      expect(record.corrections, hasLength(1));
      expect(record.corrections.single.category, 'Spelling');
      expect(record.corrections.single.bucket, SpanBucket.word);
      expect(record.corrections.single.replacementText, 'tráfico');
    });

    test('negative-test phrase: stayedClean set, targetCaught null', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-single-char');

      final cleanRecord = _buildRunRecord(
        phrase: phrase,
        runIndex: 1,
        response: response([]),
      );
      expect(cleanRecord.stayedClean, isTrue);
      expect(cleanRecord.targetCaught, isNull);
      expect(cleanRecord.corrections, isEmpty);

      final dirtyRecord = _buildRunRecord(
        phrase: phrase,
        runIndex: 2,
        response: response([
          correction(
            originalPhrase: 'para casa',
            correctedPhrase: 'a casa',
            category: ErrorCategory.grammar,
          ),
        ]),
      );
      expect(dirtyRecord.stayedClean, isFalse);
      expect(dirtyRecord.corrections, hasLength(1));
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
      expect(record.corrections, isEmpty);
    });
  });

  group('_aggregatePhrase', () {
    test('positive-test phrase: rates computed over non-error runs only', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-3-multi-correction');

      final records = [
        _RunRecord(
          phraseId: phrase.id,
          runIndex: 1,
          targetCaught: const [true, true],
          corrections: const [
            _RunCorrection(
              category: 'Spelling',
              bucket: SpanBucket.word,
              replacementText: 'tráfico',
            ),
            _RunCorrection(
              category: 'Natural Language',
              bucket: SpanBucket.phrase,
              replacementText: 'devolvieron la llamada',
            ),
          ],
        ),
        _RunRecord(
          phraseId: phrase.id,
          runIndex: 2,
          targetCaught: const [true, false],
          corrections: const [
            _RunCorrection(
              category: 'Spelling',
              bucket: SpanBucket.word,
              replacementText: 'tráfico',
            ),
          ],
        ),
        _errorRunRecord(phrase: phrase, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregatePhrase(phrase, records);

      expect(aggregate.phraseId, phrase.id);
      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      // Over the 2 non-error runs: target 0 ("trafico") caught in both = 1.0;
      // target 1 ("llamaron para atrás") caught in only run 1 = 0.5.
      expect(aggregate.targetCatchRates, [1.0, 0.5]);
      // Only run 1 caught every target.
      expect(aggregate.fullyCaughtRate, 0.5);
      expect(aggregate.cleanRate, isNull);
      expect(aggregate.spanBucketCounts[SpanBucket.word], 2);
      expect(aggregate.spanBucketCounts[SpanBucket.phrase], 1);
      expect(aggregate.spanBucketCounts[SpanBucket.clause], 0);
      expect(aggregate.categoryCounts['Spelling'], 2);
      expect(aggregate.categoryCounts['Natural Language'], 1);
    });

    test('negative-test phrase: cleanRate computed, no target rates', () {
      final phrase = _phrases.firstWhere((p) => p.id == 'ES-2-single-char');

      final records = [
        _RunRecord(phraseId: phrase.id, runIndex: 1, stayedClean: true),
        _RunRecord(
          phraseId: phrase.id,
          runIndex: 2,
          stayedClean: false,
          corrections: const [
            _RunCorrection(
              category: 'Grammar',
              bucket: SpanBucket.phrase,
              replacementText: 'a casa',
            ),
          ],
        ),
        _errorRunRecord(phrase: phrase, runIndex: 3, error: StateError('boom')),
      ];

      final aggregate = _aggregatePhrase(phrase, records);

      expect(aggregate.totalRuns, 3);
      expect(aggregate.errorRuns, 1);
      expect(aggregate.targetCatchRates, isEmpty);
      expect(aggregate.fullyCaughtRate, isNull);
      expect(aggregate.cleanRate, 0.5);
      expect(aggregate.categoryCounts['Grammar'], 1);
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
      expect(aggregate.spanBucketCounts.values.every((count) => count == 0), isTrue);
      expect(aggregate.categoryCounts, isEmpty);
    });
  });

  test(
    '_buildReport matches the captured golden format '
    '(header, per-phrase summary + run detail, overall table)',
    () {
      final report = _buildReport(
        model: 'test-model',
        runsPerPhrase: 2,
        generatedAt: DateTime.utc(2026, 1, 1, 12),
        phrases: const [
          _Phrase(
            id: 'TEST-1-multi',
            language: Language.spanish,
            text: 'Ejemplo de prueba para el informe.',
            expectedTargets: [
              _ExpectedTarget(
                originalPhraseSubstring: 'prueba',
                acceptedCategories: {'Spelling'},
              ),
              _ExpectedTarget(
                originalPhraseSubstring: 'para el informe',
                acceptedCategories: {'Grammar', 'Natural Language'},
              ),
            ],
            note: 'Synthetic phrase for report golden test.',
          ),
          _Phrase(
            id: 'TEST-2-negative',
            language: Language.portuguese,
            text: 'Frase de teste negativo.',
            expectedTargets: [],
            note: 'Synthetic negative-test phrase for report golden test.',
          ),
        ],
        recordsByPhraseId: {
          'TEST-1-multi': [
            _RunRecord(
              phraseId: 'TEST-1-multi',
              runIndex: 1,
              targetCaught: const [true, true],
              corrections: const [
                _RunCorrection(
                  category: 'Spelling',
                  bucket: SpanBucket.word,
                  replacementText: 'prueba',
                ),
                _RunCorrection(
                  category: 'Natural Language',
                  bucket: SpanBucket.phrase,
                  replacementText: 'para el reporte',
                ),
              ],
            ),
            _RunRecord(
              phraseId: 'TEST-1-multi',
              runIndex: 2,
              targetCaught: const [true, false],
              corrections: const [
                _RunCorrection(
                  category: 'Spelling',
                  bucket: SpanBucket.word,
                  replacementText: 'prueba',
                ),
              ],
            ),
          ],
          'TEST-2-negative': [
            _RunRecord(
              phraseId: 'TEST-2-negative',
              runIndex: 1,
              stayedClean: true,
            ),
            _errorRunRecord(
              phrase: const _Phrase(
                id: 'TEST-2-negative',
                language: Language.portuguese,
                text: 'Frase de teste negativo.',
                expectedTargets: [],
                note: '',
              ),
              runIndex: 2,
              error: StateError('OpenAI correction timed out'),
            ),
          ],
        },
        commit: 'abc1234',
      );

      // Captured verbatim from _buildReport's own output for this exact
      // input (see the Step 5 commit) — a byte-for-byte format regression
      // test, same idea as prompt_builder_golden_test.dart's fixture
      // comparison, just embedded inline rather than in a separate file.
      expect(report, jsonDecode(_expectedReportGolden));
    },
  );

  test(
    'correction consistency harness (live)',
    () async {
      final config = AppConfig.fromEnvironment();
      final apiKey = _readEnvironment(
        'OPENAI_API_KEY',
        defaultValue: config.openAiApiKey,
      );
      final model = _readEnvironment(
        'OPENAI_CORRECTION_MODEL',
        defaultValue: config.openAiCorrectionModel,
      );

      if (apiKey.isEmpty) {
        fail(
          'Set OPENAI_API_KEY (or a default in AppConfig) to run the '
          'correction consistency harness.',
        );
      }

      final service = OpenAiCorrectionService(apiKey: apiKey, model: model);
      final recordsByPhraseId = <String, List<_RunRecord>>{};

      for (final phrase in _phrases) {
        final records = <_RunRecord>[];
        // ignore: avoid_print
        print('=== ${phrase.id} ===');

        for (var run = 1; run <= runsPerPhrase; run++) {
          _RunRecord record;
          try {
            final response = await service.correctText(
              phrase.text,
              phrase.language,
            );
            record = _buildRunRecord(
              phrase: phrase,
              runIndex: run,
              response: response,
            );
          } catch (error) {
            // A transient API failure on one run must not lose the whole
            // battery — recorded via _errorRunRecord instead of rethrown,
            // same as the per-case error handling in
            // retranslation_grade_validation.dart.
            record = _errorRunRecord(phrase: phrase, runIndex: run, error: error);
          }
          records.add(record);
          // ignore: avoid_print
          print(_describeRun(phrase, record));
          await Future<void>.delayed(const Duration(milliseconds: callDelayMs));
        }

        recordsByPhraseId[phrase.id] = records;
      }

      final report = _buildReport(
        model: model,
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
    timeout: const Timeout(Duration(minutes: 60)),
    tags: ['live'],
  );
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}

String _gitHead() {
  try {
    final result = Process.runSync('git', ['rev-parse', 'HEAD']);
    return (result.stdout as String).trim();
  } catch (_) {
    return 'unknown';
  }
}

const String _expectedReportGolden =
    r'"# Correction Consistency Harness\n\nModel: `test-model`  \nCommit: `abc1234`  \nGenerated: 2026-01-01T12:00:00.000Z  \nRuns per phrase: 2\n\n## TEST-1-multi\n\n- Language: spanish\n- Text: `Ejemplo de prueba para el informe.`\n- Note: Synthetic phrase for report golden test.\n\n### Summary (2 runs, 0 error(s))\n\n- Target 1 (\"prueba\"): 100.0% (2/2)\n- Target 2 (\"para el informe\"): 50.0% (1/2)\n- Fully caught (all targets in one run): 50.0% (1/2)\n- Span-width distribution: word 2, phrase 1, clause 0\n- Category distribution: Natural Language 1, Spelling 2\n\n### Run detail\n\n- Run 1: targets caught = [true, true] · corrections: [Spelling] \"prueba\" (word); [Natural Language] \"para el reporte\" (phrase)\n- Run 2: targets caught = [true, false] · corrections: [Spelling] \"prueba\" (word)\n\n## TEST-2-negative\n\n- Language: portuguese\n- Text: `Frase de teste negativo.`\n- Note: Synthetic negative-test phrase for report golden test.\n\n### Summary (2 runs, 1 error(s))\n\n- Stayed clean: 100.0% (1/1)\n- Span-width distribution: word 0, phrase 0, clause 0\n- Category distribution: (none)\n\n### Run detail\n\n- Run 1: stayed clean = true · corrections: (no corrections)\n- Run 2: ERROR — Bad state: OpenAI correction timed out\n\n---\n\n## Overall summary\n\n| Phrase | Runs | Errors | Headline rate | Per-target rates |\n| --- | --- | --- | --- | --- |\n| TEST-1-multi | 2 | 0 | 50.0% (1/2) (fully caught) | 100.0% (2/2), 50.0% (1/2) |\n| TEST-2-negative | 2 | 1 | 100.0% (1/1) (clean) | — |\n"';
