import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/walkthrough_service.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/navigation/application/new_items_marker.dart';
import 'package:spanish_correction_app/features/navigation/presentation/app_shell.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';

import '../introduction/fake_profile_repository.dart';
import 'in_memory_correction_repository.dart';

/// Nothing in these tests checks a text or transcribes speech.
class _UnusedCorrectionService implements CorrectionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedTranscriptionService implements TranscriptionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

bool _dotShowing(WidgetTester tester, MarkedTab tab) => tester
    .widgetList<Badge>(find.byKey(ValueKey('new-items-dot-${tab.name}')))
    .any((badge) => badge.isLabelVisible);

/// Task 1.4b: the dot in the bottom bar.
void main() {
  late CorrectionRepositoryController controller;
  late NewItemsMarker marker;

  Future<void> pumpShell(WidgetTester tester) async {
    // A phone-sized screen, so the Check a phrase page lays out as on a phone.
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
          profileRepository: FakeProfileRepository(),
          language: Language.spanish,
          onChangeLanguage: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = CorrectionRepositoryController(InMemoryCorrectionRepository());
  });

  testWidgets('no dot when nothing is new', (tester) async {
    marker = NewItemsMarker(repositoryController: controller);
    await tester.runAsync(marker.load);
    await pumpShell(tester);
    expect(_dotShowing(tester, MarkedTab.history), isFalse);
    expect(_dotShowing(tester, MarkedTab.saved), isFalse);
  });

  testWidgets('new items show the dots, and opening a tab clears its own', (
    tester,
  ) async {
    final start = DateTime(2026, 11, 18, 9);
    marker = NewItemsMarker(
      repositoryController: controller,
      clock: () => start,
    );
    await tester.runAsync(marker.load);
    final later = start.add(const Duration(minutes: 1));
    await tester.runAsync(() async {
      await controller.addSubmission(submissionAt(later));
      await controller.addSavedCorrection(savedAt(later));
    });

    await pumpShell(tester);
    expect(_dotShowing(tester, MarkedTab.history), isTrue);
    expect(_dotShowing(tester, MarkedTab.saved), isTrue);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(_dotShowing(tester, MarkedTab.history), isFalse);
    expect(_dotShowing(tester, MarkedTab.saved), isTrue);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(_dotShowing(tester, MarkedTab.saved), isFalse);
  });
}
