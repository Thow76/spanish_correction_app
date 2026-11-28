import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_correction_app/features/conversation/data/partner_settings_store.dart';
import 'package:spanish_correction_app/features/conversation/domain/partner_settings.dart';
import 'package:spanish_correction_app/features/conversation/presentation/partner_settings_screen.dart';

void main() {
  const store = PartnerSettingsStore();

  /// Shows the screen. The clock dialog is answered with [picks] in turn;
  /// a null pick is the learner cancelling.
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<GreetingTime?> picks = const [],
  }) async {
    final remaining = [...picks];
    await tester.pumpWidget(
      MaterialApp(
        home: PartnerSettingsScreen(
          pickTime: (context, initial) async => remaining.removeAt(0),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('starts off, with no times showing', (tester) async {
    await pumpScreen(tester);

    final greetings = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('partner-greetings-switch')),
    );
    expect(greetings.value, isFalse);
    expect(find.text('Your partner waits for you to start a chat.'), findsOne);
    expect(find.byKey(const ValueKey('greeting-time-0')), findsNothing);
    expect(find.byKey(const ValueKey('add-greeting-time')), findsNothing);
  });

  testWidgets('switching on shows 6 pm and saves it', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('partner-greetings-switch')));
    await tester.pumpAndSettle();

    expect(find.text('6:00 pm'), findsOne);
    expect(find.text('Add a second time'), findsOne);
    // With one time only, there is nothing to remove.
    expect(find.byKey(const ValueKey('remove-greeting-time-0')), findsNothing);

    final saved = await store.load();
    expect(saved.greetingsOn, isTrue);
    expect(saved.times, const [GreetingTime(18, 0)]);
  });

  testWidgets('a time can be changed by tapping it', (tester) async {
    await pumpScreen(tester, picks: const [GreetingTime(7, 45)]);
    await tester.tap(find.byKey(const ValueKey('partner-greetings-switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('greeting-time-0')));
    await tester.pumpAndSettle();

    expect(find.text('7:45 am'), findsOne);
    expect((await store.load()).times, const [GreetingTime(7, 45)]);
  });

  testWidgets('cancelling the clock changes nothing', (tester) async {
    await pumpScreen(tester, picks: const [null]);
    await tester.tap(find.byKey(const ValueKey('partner-greetings-switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('greeting-time-0')));
    await tester.pumpAndSettle();

    expect(find.text('6:00 pm'), findsOne);
  });

  testWidgets('a second time can be added, and then no third', (tester) async {
    await pumpScreen(tester, picks: const [GreetingTime(8, 0)]);
    await tester.tap(find.byKey(const ValueKey('partner-greetings-switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-greeting-time')));
    await tester.pumpAndSettle();

    expect(find.text('8:00 am'), findsOne);
    expect(find.text('6:00 pm'), findsOne);
    expect(find.byKey(const ValueKey('add-greeting-time')), findsNothing);
    expect((await store.load()).times, const [
      GreetingTime(8, 0),
      GreetingTime(18, 0),
    ]);
  });

  testWidgets('with two times, either can be removed', (tester) async {
    await store.save(
      PartnerSettings(
        greetingsOn: true,
        times: const [GreetingTime(8, 0), GreetingTime(18, 0)],
      ),
    );
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('remove-greeting-time-0')));
    await tester.pumpAndSettle();

    expect(find.text('8:00 am'), findsNothing);
    expect(find.text('6:00 pm'), findsOne);
    expect((await store.load()).times, const [GreetingTime(18, 0)]);
  });

  testWidgets('switching off hides the times but keeps them', (tester) async {
    await store.save(
      PartnerSettings(greetingsOn: true, times: const [GreetingTime(8, 0)]),
    );
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('partner-greetings-switch')));
    await tester.pumpAndSettle();

    expect(find.text('8:00 am'), findsNothing);
    final saved = await store.load();
    expect(saved.greetingsOn, isFalse);
    expect(saved.times, const [GreetingTime(8, 0)]);
  });
}
