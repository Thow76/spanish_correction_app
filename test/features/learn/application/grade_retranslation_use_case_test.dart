import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/learn/application/grade_retranslation_use_case.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';

void main() {
  CorrectionItem item(ErrorCategory category, {String phrase = 'x'}) {
    return CorrectionItem(
      originalPhrase: phrase,
      correctedPhrase: '$phrase!',
      category: category,
      shortExplanation: 'explanation',
    );
  }

  group('GradeRetranslationUseCase', () {
    test(
      'Bien hecho when the saved category is fixed but other substantive '
      'errors remain',
      () async {
        final service = _FakeCorrectionService([
          item(ErrorCategory.spelling),
          item(ErrorCategory.wordChoice),
        ]);
        final useCase = GradeRetranslationUseCase(correctionService: service);

        final grade = await useCase.call(
          attempt: 'mi intento',
          savedErrorCategory: ErrorCategory.grammar,
          language: Language.spanish,
        );

        // Target (grammar) is fixed, but spelling + word-choice errors remain,
        // so the sentence is not clean -> Bien hecho, not Excelente.
        expect(grade.tier, RetranslationTier.bienHecho);
        // Still a "fixed target" outcome: isWellDone stays true and the
        // walkthrough does not trigger.
        expect(grade.isWellDone, isTrue);
        expect(grade.isKeepPracticing, isFalse);
        expect(grade.categoryErrors, isEmpty);
        // Full list is preserved for the walkthrough service.
        expect(grade.corrections, hasLength(2));
        expect(grade.judgedCategory, ErrorCategory.grammar);
      },
    );

    test(
      'Sigue practicando when the saved error category is still present',
      () async {
        final service = _FakeCorrectionService([
          item(ErrorCategory.grammar),
          item(ErrorCategory.spelling),
        ]);
        final useCase = GradeRetranslationUseCase(correctionService: service);

        final grade = await useCase.call(
          attempt: 'mi intento',
          savedErrorCategory: ErrorCategory.grammar,
          language: Language.spanish,
        );

        expect(grade.tier, RetranslationTier.siguePracticando);
        expect(grade.isKeepPracticing, isTrue);
        expect(grade.categoryErrors, hasLength(1));
        expect(grade.categoryErrors.single.category, ErrorCategory.grammar);
        expect(grade.corrections, hasLength(2));
      },
    );

    test(
      'errors in other categories never trigger Sigue practicando, but do '
      'downgrade Excelente to Bien hecho',
      () async {
        // Several non-grammar errors but no grammar error: the target is
        // fixed, so this is never Sigue practicando. The other substantive
        // errors mean the sentence is not clean -> Bien hecho.
        final service = _FakeCorrectionService([
          item(ErrorCategory.spelling),
          item(ErrorCategory.naturalLanguage),
          item(ErrorCategory.wordChoice),
          item(ErrorCategory.other),
        ]);
        final useCase = GradeRetranslationUseCase(correctionService: service);

        final grade = await useCase.call(
          attempt: 'mi intento',
          savedErrorCategory: ErrorCategory.grammar,
          language: Language.portuguese,
        );

        expect(grade.tier, RetranslationTier.bienHecho);
        expect(grade.isWellDone, isTrue);
        expect(grade.isKeepPracticing, isFalse);
        expect(grade.categoryErrors, isEmpty);
        expect(grade.corrections, hasLength(4));
      },
    );

    test(
      'a pure punctuation insertion in the saved category does not count',
      () async {
        // The grader commonly inserts a missing final period as a Grammar
        // correction (empty original -> "."). This must not flip the tier.
        final service = _FakeCorrectionService([
          const CorrectionItem(
            originalPhrase: '',
            correctedPhrase: '.',
            category: ErrorCategory.grammar,
            shortExplanation: 'Add a full stop.',
          ),
        ]);
        final useCase = GradeRetranslationUseCase(correctionService: service);

        final grade = await useCase.call(
          attempt: 'Voy al cine con mis amigos',
          savedErrorCategory: ErrorCategory.grammar,
          language: Language.spanish,
        );

        expect(grade.tier, RetranslationTier.excelente);
        expect(grade.categoryErrors, isEmpty);
        // Still kept in the full list for the walkthrough service.
        expect(grade.corrections, hasLength(1));
      },
    );

    test(
      'a substantive grammar error alongside a punctuation insertion still '
      'Sigue practicando',
      () async {
        final service = _FakeCorrectionService([
          item(ErrorCategory.grammar, phrase: 'en'),
          const CorrectionItem(
            originalPhrase: '',
            correctedPhrase: '.',
            category: ErrorCategory.grammar,
            shortExplanation: 'Add a full stop.',
          ),
        ]);
        final useCase = GradeRetranslationUseCase(correctionService: service);

        final grade = await useCase.call(
          attempt: 'Voy a cortar mi pelo en sábado',
          savedErrorCategory: ErrorCategory.grammar,
          language: Language.spanish,
        );

        expect(grade.tier, RetranslationTier.siguePracticando);
        expect(grade.categoryErrors, hasLength(1));
        expect(grade.categoryErrors.single.originalPhrase, 'en');
      },
    );

    test('a clean re-translation (no corrections) is Excelente', () async {
      final service = _FakeCorrectionService(const []);
      final useCase = GradeRetranslationUseCase(correctionService: service);

      final grade = await useCase.call(
        attempt: 'una traducción perfecta',
        savedErrorCategory: ErrorCategory.naturalLanguage,
        language: Language.spanish,
      );

      expect(grade.tier, RetranslationTier.excelente);
      expect(grade.corrections, isEmpty);
      expect(grade.categoryErrors, isEmpty);
    });

    group('three-tier edge cases', () {
      test(
        'a non-substantive error in another category stays Excelente',
        () async {
          // Target (grammar) is fixed. The only other-category correction is a
          // pure punctuation insertion (empty original -> "."), which is not
          // substantive, so the sentence still counts as clean -> Excelente.
          final service = _FakeCorrectionService([
            const CorrectionItem(
              originalPhrase: '',
              correctedPhrase: '.',
              category: ErrorCategory.spelling,
              shortExplanation: 'Add a full stop.',
            ),
          ]);
          final useCase = GradeRetranslationUseCase(correctionService: service);

          final grade = await useCase.call(
            attempt: 'Voy al cine con mis amigos',
            savedErrorCategory: ErrorCategory.grammar,
            language: Language.spanish,
          );

          expect(grade.tier, RetranslationTier.excelente);
          expect(grade.categoryErrors, isEmpty);
          // The non-substantive item is still kept for the walkthrough.
          expect(grade.corrections, hasLength(1));
        },
      );

      test(
        'target fixed with exactly one other substantive error is Bien hecho',
        () async {
          final service = _FakeCorrectionService([
            item(ErrorCategory.spelling),
          ]);
          final useCase = GradeRetranslationUseCase(correctionService: service);

          final grade = await useCase.call(
            attempt: 'mi intento',
            savedErrorCategory: ErrorCategory.grammar,
            language: Language.spanish,
          );

          expect(grade.tier, RetranslationTier.bienHecho);
          expect(grade.isWellDone, isTrue);
          expect(grade.isKeepPracticing, isFalse);
          expect(grade.categoryErrors, isEmpty);
        },
      );

      test(
        'target not fixed dominates even when the rest is clean',
        () async {
          // The only correction is a substantive error in the target category
          // and nothing else: the target failure dominates -> Sigue practicando.
          final service = _FakeCorrectionService([
            item(ErrorCategory.grammar, phrase: 'en'),
          ]);
          final useCase = GradeRetranslationUseCase(correctionService: service);

          final grade = await useCase.call(
            attempt: 'Voy a cortar mi pelo en sábado',
            savedErrorCategory: ErrorCategory.grammar,
            language: Language.spanish,
          );

          expect(grade.tier, RetranslationTier.siguePracticando);
          expect(grade.isKeepPracticing, isTrue);
          expect(grade.isWellDone, isFalse);
          expect(grade.categoryErrors, hasLength(1));
        },
      );

      test(
        'target not fixed with other substantive errors is still Sigue '
        'practicando',
        () async {
          // Other-category errors never upgrade a failed target.
          final service = _FakeCorrectionService([
            item(ErrorCategory.grammar),
            item(ErrorCategory.spelling),
            item(ErrorCategory.wordChoice),
          ]);
          final useCase = GradeRetranslationUseCase(correctionService: service);

          final grade = await useCase.call(
            attempt: 'mi intento',
            savedErrorCategory: ErrorCategory.grammar,
            language: Language.spanish,
          );

          expect(grade.tier, RetranslationTier.siguePracticando);
          expect(grade.isKeepPracticing, isTrue);
          expect(grade.categoryErrors, hasLength(1));
        },
      );
    });

    test('trims the attempt before grading', () async {
      final service = _FakeCorrectionService(const []);
      final useCase = GradeRetranslationUseCase(correctionService: service);

      await useCase.call(
        attempt: '   mi intento  ',
        savedErrorCategory: ErrorCategory.grammar,
        language: Language.spanish,
      );

      expect(service.lastText, 'mi intento');
      expect(service.lastLanguage, Language.spanish);
    });
  });
}

class _FakeCorrectionService implements CorrectionService {
  _FakeCorrectionService(this._corrections);

  final List<CorrectionItem> _corrections;
  String? lastText;
  Language? lastLanguage;

  @override
  Future<CorrectionResponse> correctText(String text, Language language) async {
    lastText = text;
    lastLanguage = language;
    return CorrectionResponse(
      originalText: text,
      correctedText: text,
      corrections: _corrections,
    );
  }

  @override
  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<String> generatePromptPhrase({
    required String correctedSentence,
    required Language language,
  }) async => throw UnimplementedError();
}
