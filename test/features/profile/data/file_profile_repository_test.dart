import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/profile/data/file_profile_repository.dart';
import 'package:spanish_correction_app/features/profile/domain/introduction_progress.dart';
import 'package:spanish_correction_app/features/profile/domain/learner_profile.dart';

void main() {
  late Directory tempDirectory;
  late File file;
  late FileProfileRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'learner_profile_repository_test_',
    );
    file = File('${tempDirectory.path}/${FileProfileRepository.fileName}');
    repository = FileProfileRepository(file: file);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('the file is named learner_profile.json', () {
    expect(FileProfileRepository.fileName, 'learner_profile.json');
  });

  test('reads an empty profile when there is no file yet', () async {
    final profile = await repository.getProfile();

    expect(profile.interestIds, isEmpty);
    expect(profile.introduction.hasStarted, isFalse);
    expect(await file.exists(), isFalse);
  });

  test('saves the profile and reads it back', () async {
    final profile = LearnerProfile.empty()
        .withInterestIds(['travel', 'music'])
        .withIntroduction(
          const IntroductionProgress.notStarted()
              .started(Language.spanish)
              .withInterestsChosen()
              .withChoice(IntroductionChoice.tryIt)
              .withOpenerShown('opener-how-are-you')
              .withOpenerAnswered(submissionId: 'sub-1')
              .withInterestQuestionShown(
                interestId: 'travel',
                questionId: 'travel-question-1',
              ),
        );

    await repository.saveProfile(profile);
    final restored = await repository.getProfile();

    expect(await file.exists(), isTrue);
    expect(restored.interestIds, ['travel', 'music']);
    expect(restored.introduction.language, Language.spanish);
    expect(restored.introduction.interestsChosen, isTrue);
    expect(restored.introduction.choice, IntroductionChoice.tryIt);
    expect(
      restored.introduction.opener,
      const StepAnswer(
        contentId: 'opener-how-are-you',
        isAnswered: true,
        submissionId: 'sub-1',
      ),
    );
    expect(
      restored.introduction.interestQuestion,
      const StepAnswer(contentId: 'travel-question-1', interestId: 'travel'),
    );
    expect(restored.introduction.isComplete, isFalse);
    expect(restored.introduction.nextStage, IntroductionStage.interestQuestion);
  });

  test('writes readable, indented JSON with the expected keys', () async {
    await repository.saveProfile(
      LearnerProfile.empty().withInterestAdded('travel'),
    );

    final content = await file.readAsString();
    final decoded = jsonDecode(content) as Map<String, Object?>;

    expect(content, contains('\n  "interest_ids"'));
    expect(decoded['interest_ids'], ['travel']);
    expect(decoded['introduction'], isA<Map<String, Object?>>());
    expect(decoded['languages'], isA<Map<String, Object?>>());
  });

  test('creates the folder if it is missing', () async {
    final nested = FileProfileRepository(
      file: File('${tempDirectory.path}/deeper/still/learner_profile.json'),
    );

    await nested.saveProfile(LearnerProfile.empty().withInterestAdded('food'));

    expect((await nested.getProfile()).interestIds, ['food']);
  });

  test('a completed introduction is remembered across reads', () async {
    await repository.saveProfile(
      LearnerProfile.empty().withIntroduction(
        const IntroductionProgress.notStarted()
            .started(Language.spanish)
            .completed(DateTime(2026, 11, 12, 10)),
      ),
    );

    final restored = await repository.getProfile();

    expect(restored.introduction.isComplete, isTrue);
    expect(restored.introduction.completedAt, DateTime(2026, 11, 12, 10));
    expect(restored.introduction.nextStage, IntroductionStage.complete);
  });

  test('updateProfile reads, changes and saves in one go', () async {
    await repository.saveProfile(
      LearnerProfile.empty().withInterestAdded('travel'),
    );

    final updated = await repository.updateProfile(
      (profile) => profile.withInterestAdded('sport'),
    );

    expect(updated.interestIds, ['travel', 'sport']);
    expect((await repository.getProfile()).interestIds, ['travel', 'sport']);
  });

  test('a blank file reads as an empty profile', () async {
    await file.writeAsString('   \n');

    final profile = await repository.getProfile();

    expect(profile.interestIds, isEmpty);
    expect(profile.introduction.hasStarted, isFalse);
  });

  test('a file that is not JSON reads as an empty profile', () async {
    await file.writeAsString('{ this is not json');

    final profile = await repository.getProfile();

    expect(profile.interestIds, isEmpty);
    expect(profile.introduction.hasStarted, isFalse);
  });

  test('a file holding a list rather than a map reads as empty', () async {
    await file.writeAsString('[1, 2, 3]');

    final profile = await repository.getProfile();

    expect(profile.interestIds, isEmpty);
  });

  test('a file written by the 1.2 version still reads and resumes', () async {
    // The 1.2 version recorded warm-ups and fuller questions (decision A1).
    await file.writeAsString(
      jsonEncode({
        'interest_ids': ['travel', 'food'],
        'introduction': {
          'language': 'spanish',
          'answered_warm_up_ids': ['warm-up-typed', 'warm-up-spoken'],
          'interests_chosen': true,
          'fuller_question_ids': ['travel-1', 'food-2', 'travel-3'],
          'fuller_answers': [
            {'question_id': 'travel-1', 'submission_id': 'sub-1'},
          ],
          'is_complete': false,
          'completed_at': null,
        },
        'languages': <String, Object?>{},
      }),
    );

    final profile = await repository.getProfile();

    expect(profile.interestIds, ['travel', 'food']);
    expect(profile.introduction.language, Language.spanish);
    expect(profile.introduction.interestsChosen, isTrue);
    expect(profile.introduction.hasAnswer, isFalse);
    expect(profile.introduction.nextStage, IntroductionStage.choice);
  });

  test('a file with extra keys from a newer version still reads', () async {
    await file.writeAsString(
      jsonEncode({
        'interest_ids': ['travel'],
        'introduction': {'is_complete': true},
        'languages': {
          'spanish': {'scrapbook': <Object?>[]},
        },
        'goals': ['something later'],
      }),
    );

    final profile = await repository.getProfile();

    expect(profile.interestIds, ['travel']);
    expect(profile.introduction.isComplete, isTrue);
    expect(profile.languages.keys, [Language.spanish]);
  });

  test('clear puts the profile back to empty', () async {
    await repository.saveProfile(
      LearnerProfile.empty()
          .withInterestAdded('travel')
          .withIntroduction(
            const IntroductionProgress.notStarted().completed(
              DateTime(2026, 11, 12),
            ),
          ),
    );

    await repository.clear();
    final profile = await repository.getProfile();

    expect(profile.interestIds, isEmpty);
    expect(profile.introduction.isComplete, isFalse);
  });
}
