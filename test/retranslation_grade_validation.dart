// Re-translation grade validation harness (Section 6, Chunk 2).
//
// This is a MANUAL validation harness, not an automated `flutter test` suite —
// it makes live correction-API calls. It is the first time GradeRetranslationUseCase
// (and the underlying correction grader, via OpenAiCorrectionService.correctText)
// runs on the re-translation step, so this harness exists to confirm the
// category-filtered verdict and well-done / KEEP PRACTICING tier are sensible on
// a battery of realistic attempts.
//
// Run it like the walkthrough validation harness:
//   OPENAI_API_KEY=sk-... flutter test test/retranslation_grade_validation.dart --timeout none
//
// It uses the same configuration source as the app (AppConfig.fromEnvironment
// with Platform.environment overrides for OPENAI_API_KEY / OPENAI_CORRECTION_MODEL),
// so it runs out of the box against OpenAI. It writes a reviewable markdown
// report to docs/retranslation_grade_validation.md (override with
// --dart-define=RETRANSLATION_OUTPUT=...).
//
// The harness FAILS (does not silently skip) when no API key is configured, so
// a missing key is visible rather than passing as a no-op.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/data/open_ai_correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/learn/application/grade_retranslation_use_case.dart';

const String outputPath = String.fromEnvironment(
  'RETRANSLATION_OUTPUT',
  defaultValue: 'docs/retranslation_grade_validation.md',
);

/// One re-translation attempt to grade.
class _Case {
  const _Case({
    required this.id,
    required this.language,
    required this.englishSource,
    required this.attempt,
    required this.savedCategory,
    required this.expectedTier,
    required this.note,
  });

  final String id;
  final Language language;

  /// The English prompt the user re-translates (context for the reviewer only;
  /// the grader judges the attempt on its own).
  final String englishSource;
  final String attempt;
  final ErrorCategory savedCategory;

  /// The tier a human reviewer expects, so the report flags surprises.
  final RetranslationTier expectedTier;
  final String note;
}

/// Battery spanning categories, tiers, and both languages. Attempts are written
/// to plausibly contain (or avoid) an error in the saved category while
/// sometimes carrying noise in OTHER categories — the noise must not flip the
/// verdict.
const List<_Case> _battery = [
  // ── Spanish ────────────────────────────────────────────────────────────────
  _Case(
    id: 'es-grammar-present',
    language: Language.spanish,
    englishSource: 'I am going to get my hair cut on Saturday',
    attempt: 'Voy a cortar mi pelo en sábado',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.keepPracticing,
    note: 'Preposition "en sábado" is a grammar error; expect KEEP PRACTICING.',
  ),
  _Case(
    id: 'es-grammar-clean-spelling-noise',
    language: Language.spanish,
    englishSource: 'I want to eat breakfast early tomorrow',
    attempt: 'Quiero desayunar tenprano mañana',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.wellDone,
    note:
        '"tenprano" is a spelling slip (other category); grammar is clean, so '
        'expect well done — the spelling noise must NOT flip the verdict.',
  ),
  _Case(
    id: 'es-grammar-fully-clean',
    language: Language.spanish,
    englishSource: 'I am going to the cinema with my friends',
    attempt: 'Voy al cine con mis amigos',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.wellDone,
    note: 'A clean attempt; expect well done.',
  ),
  _Case(
    id: 'es-wordchoice-present',
    language: Language.spanish,
    englishSource: 'I realised I forgot my keys',
    attempt: 'Realicé que olvidé mis llaves',
    savedCategory: ErrorCategory.wordChoice,
    expectedTier: RetranslationTier.keepPracticing,
    note:
        '"Realicé" as a calque of "realised" is a word-choice error '
        '(should be "Me di cuenta de"); expect KEEP PRACTICING.',
  ),
  // ── Portuguese ──────────────────────────────────────────────────────────────
  _Case(
    id: 'pt-grammar-present',
    language: Language.portuguese,
    englishSource: 'I am going to take the kids to school',
    attempt: 'Vou levar as crianças em a escola',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.keepPracticing,
    note: 'Uncontracted "em a escola" (should be "à escola"); expect KEEP PRACTICING.',
  ),
  _Case(
    id: 'pt-grammar-clean',
    language: Language.portuguese,
    englishSource: 'I am going home on Saturday',
    attempt: 'Vou para casa no sábado',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.wellDone,
    note: 'A clean attempt; expect well done.',
  ),
  _Case(
    id: 'pt-naturallanguage-present',
    language: Language.portuguese,
    englishSource: 'It is raining a lot today',
    attempt: 'Está fazendo muita chuva hoje',
    savedCategory: ErrorCategory.naturalLanguage,
    expectedTier: RetranslationTier.keepPracticing,
    note:
        '"fazendo chuva" is unnatural (native: "chovendo muito"); expect '
        'KEEP PRACTICING if flagged as Natural Language.',
  ),
  _Case(
    id: 'pt-spelling-saved-grammar-clean',
    language: Language.portuguese,
    englishSource: 'I bought a new car yesterday',
    attempt: 'Comprei um carro novo ontén',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.wellDone,
    note:
        '"ontén" is a spelling slip (other category); grammar is clean, so '
        'expect well done.',
  ),
];

void main() {
  test('re-translation grade validation harness', () async {
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
        're-translation grade validation harness.',
      );
    }

    final service = OpenAiCorrectionService(apiKey: apiKey, model: model);
    final useCase = GradeRetranslationUseCase(correctionService: service);

    final report = StringBuffer()
      ..writeln('# Re-translation Grade Validation')
      ..writeln()
      ..writeln('Model: `$model`  ')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln();

    var surprises = 0;
    var errors = 0;
    for (final testCase in _battery) {
      final RetranslationGrade grade;
      try {
        grade = await useCase.call(
          attempt: testCase.attempt,
          savedErrorCategory: testCase.savedCategory,
          language: testCase.language,
        );
      } catch (error) {
        // A transient API failure on one case must not lose the whole run.
        errors++;
        report
          ..writeln('## ${testCase.id}  ❌ (grader error)')
          ..writeln()
          ..writeln('- Attempt: `${testCase.attempt}`')
          ..writeln('- Error: $error')
          ..writeln();
        // ignore: avoid_print
        print('[ERR ] ${testCase.id}: $error');
        continue;
      }

      final matched = grade.tier == testCase.expectedTier;
      if (!matched) {
        surprises++;
      }

      report
        ..writeln('## ${testCase.id}  ${matched ? '✅' : '⚠️'}')
        ..writeln()
        ..writeln('- Language: ${testCase.language.name}')
        ..writeln('- English: ${testCase.englishSource}')
        ..writeln('- Attempt: `${testCase.attempt}`')
        ..writeln('- Saved category judged: **${testCase.savedCategory.label}**')
        ..writeln(
          '- Tier: **${grade.tier.name}** '
          '(expected ${testCase.expectedTier.name})',
        )
        ..writeln(
          '- Category errors (count ${grade.categoryErrors.length}): '
          '${_describe(grade.categoryErrors)}',
        )
        ..writeln(
          '- All corrections (count ${grade.corrections.length}): '
          '${_describe(grade.corrections)}',
        )
        ..writeln('- Note: ${testCase.note}')
        ..writeln();

      // ignore: avoid_print
      print(
        '[${matched ? 'ok ' : 'DIFF'}] ${testCase.id}: '
        'tier=${grade.tier.name} '
        '(expected ${testCase.expectedTier.name}) '
        'categoryErrors=${grade.categoryErrors.length} '
        'allCorrections=${grade.corrections.length}',
      );
    }

    report
      ..writeln('---')
      ..writeln()
      ..writeln(
        'Cases: ${_battery.length} · Tier matched expectation: '
        '${_battery.length - surprises - errors} · Surprises: $surprises · '
        'Grader errors: $errors',
      );

    File(outputPath).writeAsStringSync(report.toString());
    // ignore: avoid_print
    print('Wrote $outputPath ($surprises tier surprise(s))');
  }, timeout: const Timeout(Duration(minutes: 10)));
}

String _describe(List corrections) {
  if (corrections.isEmpty) {
    return '(none)';
  }
  return corrections
      .map((c) => '${c.category.label}:"${c.originalPhrase}"→"${c.correctedPhrase}"')
      .join('; ');
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}
