// Re-translation grade validation harness (Section 6, Chunk 2).
//
// This is a MANUAL validation harness, not an automated `flutter test` suite —
// it makes live correction-API calls. It is the first time GradeRetranslationUseCase
// (and the underlying correction grader, via OpenAiCorrectionService.gradeRetranslation)
// runs on the re-translation step, so this harness exists to confirm the
// category-filtered verdict and well-done / KEEP PRACTICING tier are sensible on
// a battery of realistic attempts. It also includes off-topic regression cases
// (see `_Case.expectedAnswer`) covering the fix for the off-topic-scoring bug,
// where an attempt about a different scenario than the target could previously
// score well done because nothing checked relatedness.
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
    required this.expectedAnswer,
    required this.savedCategory,
    required this.expectedTier,
    this.expectedIsRelated = true,
    required this.note,
  });

  final String id;
  final Language language;

  /// The English prompt the user re-translates. Context for the reviewer only
  /// — the grader never sees this field.
  final String englishSource;
  final String attempt;

  /// The correct target-language sentence, passed to the grader as
  /// `expectedAnswer` (mirrors how the real app populates
  /// `GameQuestion.expectedAnswer` from `SavedCorrection.correctedSentence`).
  ///
  /// Until this fix, this field didn't exist, and neither did anything like
  /// it being sent to the grader: the grader judged [attempt] in isolation,
  /// with no target sentence to compare it against, so it had no way to
  /// notice when an attempt was about a completely different scenario. An
  /// off-topic attempt could still score well done, because nothing ever
  /// checked relatedness. That was the root cause of the off-topic-scoring
  /// bug (logged in docs/correction_prompt_issues_and_solutions.md) — the
  /// grader now takes [expectedAnswer] explicitly and checks relatedness
  /// first (see `RetranslationGradeResponse.isRelated`) before grading for
  /// errors.
  final String expectedAnswer;
  final ErrorCategory savedCategory;

  /// The tier a human reviewer expects, so the report flags surprises.
  final RetranslationTier expectedTier;

  /// Whether the attempt is expected to be judged related to [expectedAnswer].
  /// Defaults to true since almost every case is a genuine (if imperfect)
  /// attempt at the target sentence; only the off-topic regression cases set
  /// this to false.
  final bool expectedIsRelated;
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
    expectedAnswer: 'Voy a cortar mi pelo el sábado.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.siguePracticando,
    note: 'Preposition "en sábado" is a grammar error; expect KEEP PRACTICING.',
  ),
  _Case(
    id: 'es-grammar-clean-spelling-noise',
    language: Language.spanish,
    englishSource: 'I want to eat breakfast early tomorrow',
    attempt: 'Quiero desayunar tenprano mañana',
    expectedAnswer: 'Quiero desayunar temprano mañana.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.bienHecho,
    note:
        '"tenprano" is a spelling slip (other category); grammar (the target) '
        'is clean, so the target is fixed — but the spelling error leaves the '
        'sentence unclean, so expect Bien hecho (not Excelente; the noise must '
        'NOT flip it to Sigue practicando).',
  ),
  _Case(
    id: 'es-grammar-fully-clean',
    language: Language.spanish,
    englishSource: 'I am going to the cinema with my friends',
    attempt: 'Voy al cine con mis amigos',
    expectedAnswer: 'Voy al cine con mis amigos.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.excelente,
    note: 'A clean attempt; expect well done.',
  ),
  _Case(
    id: 'es-wordchoice-present',
    language: Language.spanish,
    englishSource: 'I realised I forgot my keys',
    attempt: 'Realicé que olvidé mis llaves',
    expectedAnswer: 'Me di cuenta de que olvidé mis llaves.',
    savedCategory: ErrorCategory.wordChoice,
    expectedTier: RetranslationTier.siguePracticando,
    note:
        '"Realicé" as a calque of "realised" is a word-choice error '
        '(should be "Me di cuenta de"); expect KEEP PRACTICING.',
  ),
  _Case(
    id: 'es-off-topic-bus-bread',
    language: Language.spanish,
    englishSource: 'I went to the supermarket to buy bread',
    attempt: 'Tomé el autobús a casa desde el trabajo.',
    expectedAnswer: 'Fui al supermercado a comprar pan.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.siguePracticando,
    expectedIsRelated: false,
    note:
        'Off-topic regression case: the attempt is about taking the bus home from '
        'work, an entirely different scenario from buying bread at the '
        'supermarket. Expect isRelated: false and Sigue practicando WITHOUT '
        'the category/tier logic ever running (categoryErrors must be empty '
        'even though the attempt happens to contain a grammar-shaped phrase).',
  ),
  // ── Portuguese ──────────────────────────────────────────────────────────────
  _Case(
    id: 'pt-grammar-present',
    language: Language.portuguese,
    englishSource: 'I am going to take the kids to school',
    attempt: 'Vou levar as crianças em a escola',
    expectedAnswer: 'Vou levar as crianças à escola.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.siguePracticando,
    note:
        'Uncontracted "em a escola" (should be "à escola"); expect KEEP PRACTICING.',
  ),
  _Case(
    id: 'pt-grammar-clean',
    language: Language.portuguese,
    englishSource: 'I am going home on Saturday',
    attempt: 'Vou para casa no sábado',
    expectedAnswer: 'Vou para casa no sábado.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.excelente,
    note: 'A clean attempt; expect well done.',
  ),
  _Case(
    id: 'pt-naturallanguage-present',
    language: Language.portuguese,
    englishSource: 'It is raining a lot today',
    attempt: 'Está fazendo muita chuva hoje',
    expectedAnswer: 'Está chovendo muito hoje.',
    savedCategory: ErrorCategory.naturalLanguage,
    expectedTier: RetranslationTier.siguePracticando,
    note:
        '"fazendo chuva" is unnatural (native: "chovendo muito"); expect '
        'KEEP PRACTICING if flagged as Natural Language.',
  ),
  _Case(
    id: 'pt-spelling-saved-grammar-clean',
    language: Language.portuguese,
    englishSource: 'I bought a new car yesterday',
    attempt: 'Comprei um carro novo ontén',
    expectedAnswer: 'Comprei um carro novo ontem.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.bienHecho,
    note:
        '"ontén" is a spelling slip (other category); grammar (the target) is '
        'clean, so the target is fixed — but the spelling error leaves the '
        'sentence unclean, so expect Bien hecho.',
  ),
  _Case(
    id: 'pt-off-topic-bus-bread',
    language: Language.portuguese,
    englishSource: 'I went to the supermarket to buy bread',
    attempt: 'Peguei o ônibus para casa depois do trabalho.',
    expectedAnswer: 'Fui ao supermercado comprar pão.',
    savedCategory: ErrorCategory.grammar,
    expectedTier: RetranslationTier.siguePracticando,
    expectedIsRelated: false,
    note:
        'Off-topic regression case: the attempt is about taking the bus home from '
        'work, an entirely different scenario from buying bread at the '
        'supermarket. Expect isRelated: false and Sigue practicando WITHOUT '
        'the category/tier logic ever running (categoryErrors must be empty '
        'even though the attempt happens to contain a grammar-shaped phrase).',
  ),
];

void main() {
  test(
    're-translation grade validation harness',
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
            expectedAnswer: testCase.expectedAnswer,
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

        final tierMatched = grade.tier == testCase.expectedTier;
        final relatedMatched = grade.isRelated == testCase.expectedIsRelated;
        final matched = tierMatched && relatedMatched;
        if (!matched) {
          surprises++;
        }

        report
          ..writeln('## ${testCase.id}  ${matched ? '✅' : '⚠️'}')
          ..writeln()
          ..writeln('- Language: ${testCase.language.name}')
          ..writeln('- English: ${testCase.englishSource}')
          ..writeln('- Attempt: `${testCase.attempt}`')
          ..writeln('- Expected answer: `${testCase.expectedAnswer}`')
          ..writeln(
            '- Saved category judged: **${testCase.savedCategory.label}**',
          )
          ..writeln(
            '- Related: **${grade.isRelated}** ${relatedMatched ? '✅' : '⚠️'} '
            '(expected ${testCase.expectedIsRelated})',
          )
          ..writeln(
            '- Tier: **${grade.tier.name}** ${tierMatched ? '✅' : '⚠️'} '
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
          'isRelated=${grade.isRelated} (expected ${testCase.expectedIsRelated}) '
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
          'Cases: ${_battery.length} · Matched expectation (tier + related): '
          '${_battery.length - surprises - errors} · Surprises: $surprises · '
          'Grader errors: $errors',
        );

      File(outputPath).writeAsStringSync(report.toString());
      // ignore: avoid_print
      print('Wrote $outputPath ($surprises tier surprise(s))');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

String _describe(List corrections) {
  if (corrections.isEmpty) {
    return '(none)';
  }
  return corrections
      .map(
        (c) =>
            '${c.category.label}:"${c.originalPhrase}"→"${c.correctedPhrase}"',
      )
      .join('; ');
}

String _readEnvironment(String key, {String defaultValue = ''}) {
  final value = Platform.environment[key]?.trim();
  return value == null || value.isEmpty ? defaultValue : value;
}
