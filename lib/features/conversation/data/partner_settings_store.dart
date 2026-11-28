import 'package:shared_preferences/shared_preferences.dart';

import '../domain/partner_settings.dart';

/// Keeps the partner settings on the phone with the app's other settings
/// (build step 5.1), in the same place as "Skip language selection on
/// startup".
class PartnerSettingsStore {
  const PartnerSettingsStore();

  static const keyGreetingsOn = 'partner_greetings_on';
  static const keyGreetingTimes = 'partner_greeting_times';

  /// The stored settings. With nothing stored, greetings are off and no
  /// time is set. A stored time that cannot be read is left out.
  Future<PartnerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PartnerSettings(
      greetingsOn: prefs.getBool(keyGreetingsOn) ?? false,
      times: [
        for (final stored in prefs.getStringList(keyGreetingTimes) ?? const [])
          ?GreetingTime.tryParse(stored),
      ],
    );
  }

  Future<void> save(PartnerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyGreetingsOn, settings.greetingsOn);
    await prefs.setStringList(keyGreetingTimes, [
      for (final time in settings.times) time.toStored(),
    ]);
  }
}
