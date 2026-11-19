import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/walkthrough_service.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/navigation/application/new_items_marker.dart';
import 'package:spanish_correction_app/features/navigation/presentation/app_shell.dart';
import 'package:spanish_correction_app/features/profile/domain/learner_profile.dart';
import 'package:spanish_correction_app/features/profile/presentation/profile_screen.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';

import '../../introduction/fake_profile_repository.dart';
import '../../navigation/in_memory_correction_repository.dart';

class _UnusedCorrectionService implements CorrectionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedTranscriptionService implements TranscriptionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Task 1.5: the profile screen.
void main() {
  late FakeProfileRepository repository;

  setUp(() {
    repository = FakeProfileRepository();
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ProfileScreen(profileRepository: repository)),
    );
    await tester.pumpAndSettle();
  }

  Finder chosen(String id) => find.byKey(ValueKey('chosen-$id'));
  Finder notChosen(String id) => find.byKey(ValueKey('not-chosen-$id'));

  testWidgets('lists the chosen interests in English, in the order chosen', (
    tester,
  ) async {
    repository.stored = LearnerProfile(interestIds: ['music', 'travel']);
    await pumpProfile(tester);

    expect(find.text('Your interests'), findsOneWidget);
    expect(find.text('2 of 5 chosen'), findsOneWidget);
    expect(chosen('music'), findsOneWidget);
    expect(chosen('travel'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    // Music was tapped first, so it is listed first.
    expect(
      tester.getTopLeft(chosen('music')).dy,
      lessThan(tester.getTopLeft(chosen('travel')).dy),
    );
    // The others are offered to add, not listed as chosen.
    expect(notChosen('music'), findsNothing);
    expect(notChosen('history'), findsOneWidget);
  });

  testWidgets('adding an interest saves it at the end of the list', (
    tester,
  ) async {
    repository.stored = LearnerProfile(interestIds: ['music']);
    await pumpProfile(tester);

    await tester.tap(find.byTooltip('Add History'));
    await tester.pumpAndSettle();

    expect(repository.stored.interestIds, ['music', 'history']);
    expect(chosen('history'), findsOneWidget);
    expect(notChosen('history'), findsNothing);
    expect(find.text('2 of 5 chosen'), findsOneWidget);
  });

  testWidgets('removing an interest saves the shorter list', (tester) async {
    repository.stored = LearnerProfile(interestIds: ['music', 'travel']);
    await pumpProfile(tester);

    await tester.tap(find.byTooltip('Remove Music'));
    await tester.pumpAndSettle();

    expect(repository.stored.interestIds, ['travel']);
    expect(chosen('music'), findsNothing);
    expect(notChosen('music'), findsOneWidget);
  });

  testWidgets('the last interest cannot be removed', (tester) async {
    repository.stored = LearnerProfile(interestIds: ['music']);
    await pumpProfile(tester);
    final savesBefore = repository.saveCount;

    await tester.tap(find.byTooltip('Remove Music'));
    await tester.pump();

    expect(find.text('Keep at least one interest.'), findsOneWidget);
    expect(repository.saveCount, savesBefore);
    expect(repository.stored.interestIds, ['music']);
  });

  testWidgets('a sixth interest is refused', (tester) async {
    final five = ['travel', 'music', 'sport', 'history', 'technology'];
    repository.stored = LearnerProfile(interestIds: five);
    await pumpProfile(tester);
    final savesBefore = repository.saveCount;

    final addFirst = find.byTooltip('Add Food and cooking');
    await tester.ensureVisible(addFirst);
    await tester.tap(addFirst);
    await tester.pump();

    expect(
      find.text('You can have up to five. Remove one first.'),
      findsOneWidget,
    );
    expect(repository.saveCount, savesBefore);
    expect(repository.stored.interestIds, five);
  });

  testWidgets('an id with no matching interest is kept but not shown', (
    tester,
  ) async {
    repository.stored = LearnerProfile(
      interestIds: ['retired-interest', 'music'],
    );
    await pumpProfile(tester);

    expect(find.text('1 of 5 chosen'), findsOneWidget);
    await tester.tap(find.byTooltip('Add Travel'));
    await tester.pumpAndSettle();
    expect(repository.stored.interestIds, [
      'retired-interest',
      'music',
      'travel',
    ]);
  });

  testWidgets('with no interests, says so and offers all ten', (tester) async {
    await pumpProfile(tester);

    expect(
      find.text('No interests chosen yet. Add one below.'),
      findsOneWidget,
    );
    expect(find.text('0 of 5 chosen'), findsOneWidget);
    await tester.tap(find.byTooltip('Add Music'));
    await tester.pumpAndSettle();
    expect(repository.stored.interestIds, ['music']);
  });

  testWidgets('the person icon beside settings opens the profile', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    repository.stored = LearnerProfile(interestIds: ['sport']);
    final controller = CorrectionRepositoryController(
      InMemoryCorrectionRepository(),
    );
    final marker = NewItemsMarker(repositoryController: controller);
    await tester.runAsync(marker.load);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          correctionService: _UnusedCorrectionService(),
          repositoryController: controller,
          transcriptionService: _UnusedTranscriptionService(),
          walkthroughService: WalkthroughService(apiKey: '', model: 'test'),
          newItemsMarker: marker,
          profileRepository: repository,
          language: Language.spanish,
          onChangeLanguage: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Your profile'), findsWidgets);
    expect(chosen('sport'), findsOneWidget);
  });
}
