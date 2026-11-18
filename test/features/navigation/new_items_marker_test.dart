import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/navigation/application/new_items_marker.dart';

import 'in_memory_correction_repository.dart';

/// Task 1.4b: the dot on History and Saved for something not yet looked at.
void main() {
  late DateTime now;
  late CorrectionRepositoryController controller;

  NewItemsMarker newMarker() =>
      NewItemsMarker(repositoryController: controller, clock: () => now);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 18, 9);
    controller = CorrectionRepositoryController(InMemoryCorrectionRepository());
  });

  test('nothing is new before anything is added', () async {
    final marker = newMarker();
    await marker.load();
    expect(marker.hasNew(MarkedTab.history, Language.spanish), isFalse);
    expect(marker.hasNew(MarkedTab.saved, Language.spanish), isFalse);
  });

  test('a new History entry brings the dot on History only', () async {
    final marker = newMarker();
    await marker.load();
    await controller.setActiveLanguage(Language.spanish);
    await controller.addSubmission(
      submissionAt(now.add(const Duration(minutes: 1))),
    );
    expect(marker.hasNew(MarkedTab.history, Language.spanish), isTrue);
    expect(marker.hasNew(MarkedTab.saved, Language.spanish), isFalse);
  });

  test('a new saved point brings the dot on Saved', () async {
    final marker = newMarker();
    await marker.load();
    await controller.setActiveLanguage(Language.spanish);
    await controller.addSavedCorrection(
      savedAt(now.add(const Duration(minutes: 1))),
    );
    expect(marker.hasNew(MarkedTab.saved, Language.spanish), isTrue);
    expect(marker.hasNew(MarkedTab.history, Language.spanish), isFalse);
  });

  test('opening the tab clears its dot, and only its dot', () async {
    final marker = newMarker();
    await marker.load();
    await controller.setActiveLanguage(Language.spanish);
    now = now.add(const Duration(minutes: 1));
    await controller.addSubmission(submissionAt(now));
    await controller.addSavedCorrection(savedAt(now));
    now = now.add(const Duration(minutes: 1));

    await marker.setOpenTab(MarkedTab.history, Language.spanish);

    expect(marker.hasNew(MarkedTab.history, Language.spanish), isFalse);
    expect(marker.hasNew(MarkedTab.saved, Language.spanish), isTrue);
  });

  test('something added while the tab is open is already looked at', () async {
    final marker = newMarker();
    await marker.load();
    await controller.setActiveLanguage(Language.spanish);
    await marker.setOpenTab(MarkedTab.history, Language.spanish);
    now = now.add(const Duration(minutes: 1));
    await controller.addSubmission(submissionAt(now));
    await pumpEventQueue();
    expect(marker.hasNew(MarkedTab.history, Language.spanish), isFalse);
  });

  test('moving to another tab lets the dot come back', () async {
    final marker = newMarker();
    await marker.load();
    await controller.setActiveLanguage(Language.spanish);
    await marker.setOpenTab(MarkedTab.history, Language.spanish);
    await marker.setOpenTab(null, Language.spanish);
    now = now.add(const Duration(minutes: 1));
    await controller.addSubmission(submissionAt(now));
    expect(marker.hasNew(MarkedTab.history, Language.spanish), isTrue);
  });

  test('the dot survives a relaunch, and so does having looked', () async {
    final first = newMarker();
    await first.load();
    await controller.setActiveLanguage(Language.spanish);
    now = now.add(const Duration(minutes: 1));
    await controller.addSubmission(submissionAt(now));
    await controller.addSavedCorrection(savedAt(now));
    await first.setOpenTab(MarkedTab.saved, Language.spanish);
    first.dispose();

    // A later launch: the same phone storage, a fresh marker.
    now = now.add(const Duration(hours: 5));
    final second = newMarker();
    await second.load();
    expect(second.hasNew(MarkedTab.history, Language.spanish), isTrue);
    expect(second.hasNew(MarkedTab.saved, Language.spanish), isFalse);
  });

  test(
    'on a phone that already had the app, older items are not new',
    () async {
      await controller.setActiveLanguage(Language.spanish);
      await controller.addSubmission(
        submissionAt(now.subtract(const Duration(days: 3))),
      );
      await controller.addSavedCorrection(
        savedAt(now.subtract(const Duration(days: 3))),
      );
      final marker = newMarker();
      await marker.load();
      expect(marker.hasNew(MarkedTab.history, Language.spanish), isFalse);
      expect(marker.hasNew(MarkedTab.saved, Language.spanish), isFalse);
    },
  );

  test('each language keeps its own dot', () async {
    final marker = newMarker();
    await marker.load();
    now = now.add(const Duration(minutes: 1));
    await controller.addSubmission(
      submissionAt(now, language: Language.portuguese),
    );
    expect(marker.hasNew(MarkedTab.history, Language.portuguese), isTrue);
    expect(marker.hasNew(MarkedTab.history, Language.spanish), isFalse);

    await marker.setOpenTab(MarkedTab.history, Language.spanish);
    expect(marker.hasNew(MarkedTab.history, Language.portuguese), isTrue);
  });

  test('listeners hear when something new arrives', () async {
    final marker = newMarker();
    await marker.load();
    var heard = 0;
    marker.addListener(() => heard++);
    await controller.addSubmission(
      submissionAt(now.add(const Duration(minutes: 1))),
    );
    expect(heard, greaterThan(0));
  });
}
