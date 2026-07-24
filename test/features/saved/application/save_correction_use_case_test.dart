import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/models/walkthrough_activity.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/application/prompt_phrase_translation.dart';
import 'package:spanish_correction_app/features/corrections/application/retranslation_grade_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/saved/application/save_correction_use_case.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';

const _explanation = SavedExplanation(
  whyItsWrong: 'why',
  inContext: 'context',
  alternatives: [],
);

CorrectionItem _correction({String correctedPhrase = 'Fui'}) => CorrectionItem(
  originalPhrase: 'Voy',
  correctedPhrase: correctedPhrase,
  category: ErrorCategory.grammar,
  shortExplanation: 'Use the preterite.',
);

class _FakeCorrectionService implements CorrectionService {
  _FakeCorrectionService({this.promptPhraseResult, this.promptPhraseError});

  final PromptPhraseTranslation? promptPhraseResult;
  final Object? promptPhraseError;

  String? capturedCorrectedSentence;
  String? capturedCorrectedPhrase;

  @override
  Future<CorrectionResponse> correctText(String text, Language language) async =>
      throw UnimplementedError();

  @override
  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  ) async => throw UnimplementedError();

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async => _explanation;

  @override
  Future<PromptPhraseTranslation> generatePromptPhrase({
    required String correctedSentence,
    required String correctedPhrase,
    required Language language,
  }) async {
    capturedCorrectedSentence = correctedSentence;
    capturedCorrectedPhrase = correctedPhrase;
    final error = promptPhraseError;
    if (error != null) {
      throw error;
    }
    return promptPhraseResult ?? const PromptPhraseTranslation(text: '');
  }

  @override
  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  }) async => throw UnimplementedError();
}

class _FakeCorrectionRepository implements CorrectionRepository {
  final List<SavedCorrection> saved = [];

  @override
  Future<void> addSavedCorrection(SavedCorrection correction) async {
    saved.add(correction);
  }

  @override
  Future<List<SavedCorrection>> getSavedCorrections({Language? language}) async =>
      saved;

  @override
  Future<List<CorrectionSubmission>> getRecentSubmissions({Language? language}) async =>
      const [];

  @override
  Future<List<WalkthroughActivity>> getWalkthroughActivities({Language? language}) async =>
      const [];

  @override
  Future<void> addSubmission(CorrectionSubmission submission) async {}

  @override
  Future<void> removeSubmission(String id) async {}

  @override
  Future<void> removeSavedCorrection(String id) async {}

  @override
  Future<void> addWalkthroughActivity(WalkthroughActivity activity) async {}

  @override
  Future<void> removeWalkthroughActivity(String sourcePhraseId) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  group('SaveCorrectionUseCase', () {
    test(
      'success: populates promptPhrase and both highlight indices from the '
      'service result',
      () async {
        final correctionService = _FakeCorrectionService(
          promptPhraseResult: const PromptPhraseTranslation(
            text: 'I went to the market.',
            highlightStartIndex: 2,
            highlightEndIndex: 6,
          ),
        );
        final useCase = SaveCorrectionUseCase(
          correctionService: correctionService,
          repositoryController: CorrectionRepositoryController(
            _FakeCorrectionRepository(),
          ),
        );

        final saved = await useCase.call(
          correction: _correction(),
          originalSentence: 'Voy al mercado.',
          correctedSentence: 'Fui al mercado.',
          language: Language.spanish,
        );

        expect(saved.promptPhrase, 'I went to the market.');
        expect(saved.promptHighlightStartIndex, 2);
        expect(saved.promptHighlightEndIndex, 6);
      },
    );

    test(
      'passes correction.correctedPhrase (not correctedSentence) as '
      'correctedPhrase to generatePromptPhrase',
      () async {
        final correctionService = _FakeCorrectionService();
        final useCase = SaveCorrectionUseCase(
          correctionService: correctionService,
          repositoryController: CorrectionRepositoryController(
            _FakeCorrectionRepository(),
          ),
        );

        await useCase.call(
          correction: _correction(correctedPhrase: 'Fui'),
          originalSentence: 'Voy al mercado.',
          correctedSentence: 'Fui al mercado.',
          language: Language.spanish,
        );

        expect(correctionService.capturedCorrectedSentence, 'Fui al mercado.');
        expect(correctionService.capturedCorrectedPhrase, 'Fui');
      },
    );

    test(
      'generatePromptPhrase throwing falls back to empty text with null '
      'indices, and the save still succeeds',
      () async {
        final correctionService = _FakeCorrectionService(
          promptPhraseError: Exception('network down'),
        );
        final useCase = SaveCorrectionUseCase(
          correctionService: correctionService,
          repositoryController: CorrectionRepositoryController(
            _FakeCorrectionRepository(),
          ),
        );

        final saved = await useCase.call(
          correction: _correction(),
          originalSentence: 'Voy al mercado.',
          correctedSentence: 'Fui al mercado.',
          language: Language.spanish,
        );

        expect(saved.promptPhrase, '');
        expect(saved.promptHighlightStartIndex, isNull);
        expect(saved.promptHighlightEndIndex, isNull);
      },
    );

    test(
      'a verified-empty highlighted_phrase from the service still saves the '
      'translation text with null highlight indices',
      () async {
        final correctionService = _FakeCorrectionService(
          promptPhraseResult: const PromptPhraseTranslation(
            text: 'I bought three apples.',
          ),
        );
        final useCase = SaveCorrectionUseCase(
          correctionService: correctionService,
          repositoryController: CorrectionRepositoryController(
            _FakeCorrectionRepository(),
          ),
        );

        final saved = await useCase.call(
          correction: _correction(),
          originalSentence: 'Compre tres manzanas.',
          correctedSentence: 'Compré tres manzanas.',
          language: Language.spanish,
        );

        expect(saved.promptPhrase, 'I bought three apples.');
        expect(saved.promptHighlightStartIndex, isNull);
        expect(saved.promptHighlightEndIndex, isNull);
      },
    );
  });
}
