import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/models/walkthrough_activity.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service_exception.dart';
import 'package:spanish_correction_app/features/corrections/application/retranslation_grade_response.dart';
import 'package:spanish_correction_app/features/corrections/application/submit_correction_use_case.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';

/// Covers the offline-queueing/auto-retry removal: any failure — network or
/// otherwise — must propagate immediately as a [CorrectionServiceException]
/// for the caller to show as an error, never be swallowed and stored for a
/// later silent retry. There is no queue to write to any more: the
/// [CorrectionRepository] interface itself no longer has queue methods, so
/// there is nothing this use case even could enqueue to.
void main() {
  late _FakeCorrectionRepository repository;
  late CorrectionRepositoryController controller;

  setUp(() {
    repository = _FakeCorrectionRepository();
    controller = CorrectionRepositoryController(repository);
  });

  test(
    'a successful submission returns the response directly and adds it to '
    'the repository',
    () async {
      const response = CorrectionResponse(
        originalText: 'Ayer yo fue al mercado.',
        correctedText: 'Ayer fui al mercado.',
        corrections: [
          CorrectionItem(
            originalPhrase: 'fue',
            correctedPhrase: 'fui',
            category: ErrorCategory.grammar,
            shortExplanation: 'Use fui with yo in the preterite.',
          ),
        ],
      );
      final useCase = SubmitCorrectionUseCase(
        correctionService: _FakeCorrectionService(responseToReturn: response),
        repositoryController: controller,
      );

      final result = await useCase('Ayer yo fue al mercado.', Language.spanish);

      expect(result, response);
      expect(repository.addedSubmissions, hasLength(1));
      expect(repository.addedSubmissions.single.response, response);
      expect(repository.addedSubmissions.single.language, Language.spanish);
    },
  );

  test(
    'a network failure propagates immediately as CorrectionServiceException '
    '— nothing is added to the repository, and there is no queue for it to '
    'go to instead',
    () async {
      final useCase = SubmitCorrectionUseCase(
        correctionService: _FakeCorrectionService(
          exceptionToThrow: const CorrectionServiceException(
            CorrectionFailureReason.networkUnavailable,
            'No internet available.',
          ),
        ),
        repositoryController: controller,
      );

      await expectLater(
        () => useCase('Ayer yo fue al mercado.', Language.spanish),
        throwsA(
          isA<CorrectionServiceException>().having(
            (error) => error.reason,
            'reason',
            CorrectionFailureReason.networkUnavailable,
          ),
        ),
      );

      expect(repository.addedSubmissions, isEmpty);
    },
  );

  test(
    'a non-network service failure propagates immediately too, exactly the '
    'same as a network failure — both are plain errors now, neither is '
    'treated specially',
    () async {
      final useCase = SubmitCorrectionUseCase(
        correctionService: _FakeCorrectionService(
          exceptionToThrow: const CorrectionServiceException(
            CorrectionFailureReason.apiFailure,
            'Something went wrong.',
          ),
        ),
        repositoryController: controller,
      );

      await expectLater(
        () => useCase('Ayer yo fue al mercado.', Language.spanish),
        throwsA(
          isA<CorrectionServiceException>().having(
            (error) => error.reason,
            'reason',
            CorrectionFailureReason.apiFailure,
          ),
        ),
      );

      expect(repository.addedSubmissions, isEmpty);
    },
  );
}

class _FakeCorrectionService implements CorrectionService {
  _FakeCorrectionService({this.responseToReturn, this.exceptionToThrow});

  final CorrectionResponse? responseToReturn;
  final Object? exceptionToThrow;

  @override
  Future<CorrectionResponse> correctText(String text, Language language) async {
    final exception = exceptionToThrow;
    if (exception != null) {
      throw exception;
    }
    return responseToReturn!;
  }

  @override
  Future<String> generateLongExplanation(
    CorrectionItem correction,
    Language language,
  ) async => '';

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
    Language language,
  ) async => const SavedExplanation(
    whyItsWrong: '',
    inContext: '',
    alternatives: [],
  );

  @override
  Future<String> generatePromptPhrase({
    required String correctedSentence,
    required Language language,
  }) async => '';

  @override
  Future<RetranslationGradeResponse> gradeRetranslation({
    required String attempt,
    required String expectedAnswer,
    required ErrorCategory targetCategory,
    required Language language,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeCorrectionRepository implements CorrectionRepository {
  final List<CorrectionSubmission> addedSubmissions = [];

  @override
  Future<List<CorrectionSubmission>> getRecentSubmissions({
    Language? language,
  }) async => List.unmodifiable(addedSubmissions);

  @override
  Future<void> addSubmission(CorrectionSubmission submission) async {
    addedSubmissions.add(submission);
  }

  @override
  Future<void> removeSubmission(String id) async {
    addedSubmissions.removeWhere((submission) => submission.id == id);
  }

  @override
  Future<List<SavedCorrection>> getSavedCorrections({
    Language? language,
  }) async => const [];

  @override
  Future<void> addSavedCorrection(SavedCorrection correction) async {}

  @override
  Future<void> removeSavedCorrection(String id) async {}

  @override
  Future<List<WalkthroughActivity>> getWalkthroughActivities({
    Language? language,
  }) async => const [];

  @override
  Future<void> addWalkthroughActivity(WalkthroughActivity activity) async {}

  @override
  Future<void> removeWalkthroughActivity(String sourcePhraseId) async {}

  @override
  Future<void> clear() async {
    addedSubmissions.clear();
  }
}
