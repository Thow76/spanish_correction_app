import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_input_mode.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/introduction/application/introduction_feedback.dart';

/// Stands in for the check, History and Saved in the introduction's tests.
/// Every answer comes back with one Grammar point on its first word.
class FakeIntroductionFeedback implements IntroductionFeedback {
  /// The answers sent, in order.
  final sent = <String>[];

  /// How each answer in [sent] was given, in the same order.
  final sentModes = <CorrectionInputMode>[];

  /// Every History entry made, by id.
  final history = <String, CorrectionSubmission>{};

  /// The points saved, with the answer each came from.
  final saved = <(CorrectionItem, CorrectionSubmission)>[];

  /// How many sends still fail before they start working.
  int failuresLeft = 0;

  int _count = 0;

  @override
  Future<CorrectionSubmission> send(
    String answer,
    Language language, {
    CorrectionInputMode inputMode = CorrectionInputMode.typed,
  }) async {
    sent.add(answer);
    sentModes.add(inputMode);
    if (failuresLeft > 0) {
      failuresLeft--;
      throw Exception('no internet');
    }
    _count++;
    final firstWord = answer.split(' ').first;
    final submission = CorrectionSubmission(
      id: 'submission-$_count',
      response: CorrectionResponse(
        originalText: answer,
        correctedText: answer,
        corrections: [
          CorrectionItem(
            originalPhrase: firstWord,
            correctedPhrase: firstWord,
            category: ErrorCategory.grammar,
            shortExplanation: 'Point $_count.',
            startIndex: 0,
            endIndex: firstWord.length,
            correctedStartIndex: 0,
            correctedEndIndex: firstWord.length,
          ),
        ],
      ),
      createdAt: DateTime.utc(2026, 11, 17),
      language: language,
    );
    history[submission.id] = submission;
    return submission;
  }

  @override
  Future<CorrectionSubmission?> find(
    String submissionId,
    Language language,
  ) async => history[submissionId];

  @override
  Future<void> save(
    CorrectionItem point,
    CorrectionSubmission submission,
  ) async {
    saved.add((point, submission));
  }
}
