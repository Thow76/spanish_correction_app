import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/models/walkthrough_activity.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';

/// Keeps History and Saved in memory for the dot's tests (task 1.4b).
class InMemoryCorrectionRepository implements CorrectionRepository {
  final submissions = <CorrectionSubmission>[];
  final saved = <SavedCorrection>[];

  @override
  Future<List<CorrectionSubmission>> getRecentSubmissions({
    Language? language,
  }) async => [
    for (final s in submissions)
      if (language == null || s.language == language) s,
  ];

  @override
  Future<void> addSubmission(CorrectionSubmission submission) async =>
      submissions.insert(0, submission);

  @override
  Future<void> removeSubmission(String id) async =>
      submissions.removeWhere((s) => s.id == id);

  @override
  Future<List<SavedCorrection>> getSavedCorrections({
    Language? language,
  }) async => [
    for (final c in saved)
      if (language == null || c.language == language) c,
  ];

  @override
  Future<void> addSavedCorrection(SavedCorrection correction) async =>
      saved.insert(0, correction);

  @override
  Future<void> removeSavedCorrection(String id) async =>
      saved.removeWhere((c) => c.id == id);

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
    submissions.clear();
    saved.clear();
  }
}

CorrectionSubmission submissionAt(
  DateTime time, {
  String id = 'entry',
  Language language = Language.spanish,
}) => CorrectionSubmission(
  id: id,
  response: const CorrectionResponse(
    originalText: 'Hola',
    correctedText: 'Hola',
    corrections: [],
  ),
  createdAt: time,
  language: language,
);

SavedCorrection savedAt(
  DateTime time, {
  String id = 'point',
  Language language = Language.spanish,
}) => SavedCorrection(
  id: id,
  category: ErrorCategory.grammar,
  shortExplanation: 'reason',
  originalSentence: 'Yo voy ayer.',
  explanation: const SavedExplanation(
    whyItsWrong: 'why',
    inContext: 'context',
    alternatives: [],
  ),
  savedAt: time,
  correctedPhrase: 'fui',
  originalPhrase: 'voy',
  correctedSentence: 'Yo fui ayer.',
  promptPhrase: 'I went yesterday.',
  language: language,
);
