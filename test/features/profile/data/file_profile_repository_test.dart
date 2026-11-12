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
              .withWarmUpAnswered('warm-up-typed')
              .withInterestsChosen(fullerQuestionIds: ['travel-1', 'music-2'])
              .withFullerAnswer(
                const FullerAnswer(
                  questionId: 'travel-1',
                  submissionId: 'sub-1',
                ),
              ),
        );

    await repository.saveProfile(profile);
    final restored = await repository.getProfile();

    expect(await file.exists(), isTrue);
    expect(restored.interestIds, ['travel', 'music']);
    expect(restored.introduction.language, Language.spanish);
    expect(restored.introduction.answeredWarmUpIds, ['warm-up-typed']);
    expect(restored.introduction.interestsChosen, isTrue);
    expect(restored.introduction.fullerQuestionIds, ['travel-1', 'music-2']);
    expect(restored.introduction.fullerAnswers, const [
      FullerAnswer(questionId: 'travel-1', submissionId: 'sub-1'),
    ]);
    expect(restored.introduction.isComplete, isFalse);
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
    expect(
      restored.introduction.stageFor(warmUpCount: 2),
      IntroductionStage.complete,
    );
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
