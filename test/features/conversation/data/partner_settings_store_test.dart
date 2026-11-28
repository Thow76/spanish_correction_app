import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanish_correction_app/features/conversation/data/partner_settings_store.dart';
import 'package:spanish_correction_app/features/conversation/domain/partner_settings.dart';

void main() {
  const store = PartnerSettingsStore();

  test('with nothing stored, greetings are off and no time is set', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = await store.load();

    expect(settings.greetingsOn, isFalse);
    expect(settings.times, isEmpty);
  });

  test('what is saved is read back', () async {
    SharedPreferences.setMockInitialValues({});
    final saved = PartnerSettings(
      greetingsOn: true,
      times: const [GreetingTime(8, 30), GreetingTime(18, 0)],
    );

    await store.save(saved);

    expect(await store.load(), saved);
  });

  test('it is kept with the other settings, as a switch and a list', () async {
    SharedPreferences.setMockInitialValues({'skip_language_selection': true});

    await store.save(
      PartnerSettings(greetingsOn: true, times: const [GreetingTime(18, 0)]),
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('partner_greetings_on'), isTrue);
    expect(prefs.getStringList('partner_greeting_times'), ['18:00']);
    expect(prefs.getBool('skip_language_selection'), isTrue);
  });

  test('a stored time that cannot be read is left out', () async {
    SharedPreferences.setMockInitialValues({
      'partner_greetings_on': true,
      'partner_greeting_times': ['nonsense', '07:45'],
    });

    final settings = await store.load();

    expect(settings.greetingsOn, isTrue);
    expect(settings.times, const [GreetingTime(7, 45)]);
  });
}
