import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/corrections/application/submit_correction_use_case.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';
import 'package:spanish_correction_app/features/corrections/domain/queued_submission.dart';
import 'package:spanish_correction_app/shared/network/network_status_service.dart';

void main() {
  test(
    'preserves the submitted original text when the API echo loses accents',
    () async {
      final repository = _FakeCorrectionRepository();
      final useCase = SubmitCorrectionUseCase(
        correctionService: _GarbledOriginalCorrectionService(),
        repositoryController: CorrectionRepositoryController(repository),
        networkStatusService: _ConnectedNetworkStatusService(),
      );

      final result = await useCase('Cómo estás? Qué tal?');

      expect(result.response?.originalText, 'Cómo estás? Qué tal?');
      expect(
        repository.submissions.single.response.originalText,
        'Cómo estás? Qué tal?',
      );
    },
  );
}

class _GarbledOriginalCorrectionService implements CorrectionService {
  @override
  Future<CorrectionResponse> correctText(String text) async {
    return const CorrectionResponse(
      originalText: 'C mo est s? Qu tal?',
      correctedText: '¿Cómo estás? ¿Qué tal?',
      corrections: [
        CorrectionItem(
          originalPhrase: 'C mo est s?',
          correctedPhrase: '¿Cómo estás?',
          category: ErrorCategory.spelling,
          shortExplanation: 'Accents are required here.',
        ),
      ],
    );
  }

  @override
  Future<String> generateLongExplanation(CorrectionItem correction) async => '';

  @override
  Future<SavedExplanation> generateStructuredExplanation(
    CorrectionItem correction,
  ) async {
    return const SavedExplanation(
      whyItsWrong: '',
      inContext: '',
      alternatives: [],
    );
  }
}

class _ConnectedNetworkStatusService implements NetworkStatusService {
  @override
  Future<bool> get hasConnection async => true;

  @override
  Stream<bool> get connectionChanges => const Stream.empty();
}

class _FakeCorrectionRepository implements CorrectionRepository {
  final submissions = <CorrectionSubmission>[];
  final savedCorrections = <SavedCorrection>[];
  final queuedSubmissions = <QueuedSubmission>[];

  @override
  Future<void> addSavedCorrection(SavedCorrection correction) async {
    savedCorrections.add(correction);
  }

  @override
  Future<void> addSubmission(CorrectionSubmission submission) async {
    submissions.add(submission);
  }

  @override
  Future<void> clear() async {
    submissions.clear();
    savedCorrections.clear();
    queuedSubmissions.clear();
  }

  @override
  Future<void> enqueueSubmission(QueuedSubmission submission) async {
    queuedSubmissions.add(submission);
  }

  @override
  Future<List<QueuedSubmission>> loadQueuedSubmissions() async {
    return queuedSubmissions;
  }

  @override
  Future<List<CorrectionSubmission>> loadRecentSubmissions() async {
    return submissions;
  }

  @override
  Future<List<SavedCorrection>> loadSavedCorrections() async {
    return savedCorrections;
  }

  @override
  Future<void> removeQueuedSubmission(String id) async {
    queuedSubmissions.removeWhere((submission) => submission.id == id);
  }
}
