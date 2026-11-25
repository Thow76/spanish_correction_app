import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/core/services/walkthrough_service.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_repository_controller.dart';
import 'package:spanish_correction_app/features/corrections/application/correction_service.dart';
import 'package:spanish_correction_app/features/home/presentation/home_screen.dart';
import 'package:spanish_correction_app/features/navigation/application/new_items_marker.dart';
import 'package:spanish_correction_app/features/navigation/presentation/app_shell.dart';
import 'package:spanish_correction_app/features/write/application/transcription_service.dart';
import 'package:spanish_correction_app/features/write/presentation/write_screen.dart';

import '../introduction/fake_profile_repository.dart';
import '../navigation/in_memory_correction_repository.dart';

/// Nothing in these tests checks a text or transcribes speech.
class _UnusedCorrectionService implements CorrectionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UnusedTranscriptionService implements TranscriptionService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Build step 3.1: Home is the first place in the bottom bar (decision B1),
/// with Check a phrase in the band under the header (B2, B5) and no
/// Scrapbook or Goals yet (F1). Portuguese keeps today's Write page (F1).
void main() {
  late CorrectionRepositoryController controller;

  Future<void> pumpShell(WidgetTester tester, Language language) async {
    // A phone-sized screen, so the pages lay out as on a phone.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final marker = NewItemsMarker(repositoryController: controller);
    await tester.runAsync(marker.load);
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          correctionService: _UnusedCorrectionService(),
          repositoryController: controller,
          transcriptionService: _UnusedTranscriptionService(),
          walkthroughService: WalkthroughService(apiKey: '', model: 'test'),
          newItemsMarker: marker,
          profileRepository: FakeProfileRepository(),
          language: language,
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

  testWidgets('Spanish opens on Home, with Check a phrase in the band', (
    tester,
  ) async {
    await pumpShell(tester, Language.spanish);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WriteScreen), findsNothing);

    // The bar still has four places; the first is Home, not Write.
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Write'), findsNothing);

    expect(find.text('Check a phrase'), findsOneWidget);
    expect(find.text('Scrapbook'), findsNothing);
    expect(find.text('Goals'), findsNothing);
    expect(find.text('No chats yet'), findsOneWidget);
  });

  testWidgets('Check a phrase opens the Write page, and back returns to Home', (
    tester,
  ) async {
    await pumpShell(tester, Language.spanish);

    await tester.tap(find.byKey(const ValueKey('home-check-a-phrase')));
    await tester.pumpAndSettle();
    expect(find.byType(WriteScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    // The page is today's Write page as it is.
    expect(
      find.text("Write or record - we'll handle the rest."),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(WriteScreen), findsNothing);
  });

  testWidgets('Portuguese keeps the Write tab', (tester) async {
    await pumpShell(tester, Language.portuguese);

    expect(find.byType(WriteScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text('Write'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });
}
