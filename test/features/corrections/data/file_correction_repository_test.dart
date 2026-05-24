import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/corrections/data/file_correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
import 'package:spanish_correction_app/features/corrections/domain/queued_submission.dart';
import 'package:spanish_correction_app/features/history/domain/correction_submission.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_correction.dart';
import 'package:spanish_correction_app/features/saved/domain/saved_explanation.dart';

void main() {
  late Directory tempDirectory;
  late FileCorrectionRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'spanish_correction_repository_test_',
    );
    repository = FileCorrectionRepository(
      file: File('${tempDirectory.path}/store.json'),
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('keeps the 20 most recent submissions', () async {
    for (var index = 0; index < 22; index += 1) {
      await repository.addSubmission(_submission(index));
    }

    final submissions = await repository.loadRecentSubmissions();

    expect(submissions, hasLength(20));
    expect(submissions.first.id, 'submission-21');
    expect(submissions.last.id, 'submission-2');
  });

  test('persists saved corrections', () async {
    final savedCorrection = SavedCorrection(
      id: 'saved-1',
      category: ErrorCategory.grammar,
      shortExplanation: 'Use fui for first-person preterite of ir.',
      originalSentence: 'Ayer yo fue al mercado.',
      explanation: const SavedExplanation(
        whyItsWrong: 'The verb ir uses fui for yo in the preterite.',
        inContext: 'Ayer fui al mercado.',
        alternatives: ['Fui al mercado ayer.'],
      ),
      savedAt: DateTime(2026, 5, 24),
      correctedPhrase: 'fui',
      originalPhrase: 'fue',
      correctedSentence: 'Ayer fui al mercado.',
    );

    await repository.addSavedCorrection(savedCorrection);

    final savedCorrections = await repository.loadSavedCorrections();

    expect(savedCorrections, hasLength(1));
    expect(savedCorrections.single.id, 'saved-1');
    expect(savedCorrections.single.category, ErrorCategory.grammar);
  });

  test('queues and removes offline submissions', () async {
    await repository.enqueueSubmission(
      QueuedSubmission(
        id: 'queued-1',
        text: 'Ayer yo fue al mercado.',
        createdAt: DateTime(2026, 5, 24, 10),
      ),
    );
    await repository.enqueueSubmission(
      QueuedSubmission(
        id: 'queued-2',
        text: 'Compre frutas fresco.',
        createdAt: DateTime(2026, 5, 24, 11),
      ),
    );

    expect((await repository.loadQueuedSubmissions()).map((item) => item.id), [
      'queued-1',
      'queued-2',
    ]);

    await repository.removeQueuedSubmission('queued-1');

    expect((await repository.loadQueuedSubmissions()).map((item) => item.id), [
      'queued-2',
    ]);
  });
}

CorrectionSubmission _submission(int index) {
  return CorrectionSubmission(
    id: 'submission-$index',
    createdAt: DateTime(2026, 5, 24, 12, index),
    response: CorrectionResponse(
      originalText: 'Ayer yo fue al mercado. $index',
      correctedText: 'Ayer fui al mercado. $index',
      corrections: const [
        CorrectionItem(
          originalPhrase: 'fue',
          correctedPhrase: 'fui',
          category: ErrorCategory.grammar,
          shortExplanation: 'Use fui with yo in the preterite.',
        ),
      ],
    ),
  );
}
