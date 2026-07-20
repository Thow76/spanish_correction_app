import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/data/file_correction_repository.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_item.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_response.dart';
import 'package:spanish_correction_app/features/corrections/domain/error_category.dart';
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

    final submissions = await repository.getRecentSubmissions();

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
      promptPhrase: 'Yesterday I went to the market.',
      language: Language.spanish,
    );

    await repository.addSavedCorrection(savedCorrection);

    final savedCorrections = await repository.getSavedCorrections();

    expect(savedCorrections, hasLength(1));
    expect(savedCorrections.single.id, 'saved-1');
    expect(savedCorrections.single.category, ErrorCategory.grammar);
  });

  test(
    'skips a malformed walkthrough activity without dropping other records',
    () async {
      Map<String, Object?> activityJson({
        required String sourcePhraseId,
        required String language,
      }) => {
        'source_phrase_id': sourcePhraseId,
        'target_sentence': 'voy a la tienda',
        'language': language,
        'questions': [
          {
            'english_stem': 'I am going',
            'correct_translation': 'voy',
            'distractors': ['va', 'vamos'],
            'chunk_position': 0,
          },
        ],
        'answers': <Object?>[null],
        'completed_at': null,
      };

      // One valid activity, one map-shaped but invalid activity (unrecognised
      // language -> WalkthroughActivity.fromJson throws), alongside valid
      // entries of every other record type, all in a single store file. Also
      // includes a leftover 'queued_submissions' key, hand-written rather
      // than built from the (now-removed) QueuedSubmission class — this is
      // what an existing install's store file looks like from before the
      // queued-submission feature was removed, confirming reading such a
      // file is still safe (no migration needed; the key is simply ignored).
      final storeJson = {
        'recent_submissions': [_submission(0).toJson()],
        'saved_corrections': [_savedCorrection().toJson()],
        'queued_submissions': [
          {
            'id': 'queued-1',
            'text': 'Ayer yo fue al mercado.',
            'created_at': DateTime(2026, 5, 24, 10).toIso8601String(),
            'language': 'spanish',
          },
        ],
        'walkthrough_activities': [
          activityJson(sourcePhraseId: 'phrase-1', language: 'spanish'),
          activityJson(sourcePhraseId: 'phrase-2', language: 'klingon'),
        ],
      };

      await File(
        '${tempDirectory.path}/store.json',
      ).writeAsString(jsonEncode(storeJson));

      final activities = await repository.getWalkthroughActivities();

      // The malformed activity is skipped; the valid one still loads.
      expect(activities, hasLength(1));
      expect(activities.single.sourcePhraseId, 'phrase-1');

      // Every other record type is unaffected by the corrupt walkthrough
      // entry, or by the leftover queued_submissions key.
      expect(await repository.getRecentSubmissions(), hasLength(1));
      expect(await repository.getSavedCorrections(), hasLength(1));
    },
  );

  test(
    'a leftover queued_submissions key from before the queueing feature was '
    'removed is dropped from the store file on the next write, with no '
    'explicit migration step',
    () async {
      final storeFile = File('${tempDirectory.path}/store.json');
      await storeFile.writeAsString(
        jsonEncode({
          'recent_submissions': <Object?>[],
          'saved_corrections': <Object?>[],
          'queued_submissions': [
            {
              'id': 'queued-1',
              'text': 'Ayer yo fue al mercado.',
              'created_at': DateTime(2026, 5, 24, 10).toIso8601String(),
              'language': 'spanish',
            },
          ],
          'walkthrough_activities': <Object?>[],
        }),
      );

      // Any write at all rewrites the whole store — here, adding a new
      // submission.
      await repository.addSubmission(_submission(0));

      final rewritten =
          jsonDecode(await storeFile.readAsString()) as Map<String, Object?>;
      expect(rewritten.containsKey('queued_submissions'), isFalse);
      expect(rewritten['recent_submissions'], hasLength(1));
    },
  );
}

SavedCorrection _savedCorrection() {
  return SavedCorrection(
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
    promptPhrase: 'Yesterday I went to the market.',
    language: Language.spanish,
  );
}

CorrectionSubmission _submission(int index) {
  return CorrectionSubmission(
    id: 'submission-$index',
    createdAt: DateTime(2026, 5, 24, 12, index),
    language: Language.spanish,
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
