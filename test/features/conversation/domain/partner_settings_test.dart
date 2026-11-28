import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/conversation/domain/partner_settings.dart';

void main() {
  const morning = GreetingTime(8, 30);
  const evening = GreetingTime(18, 0);
  const night = GreetingTime(21, 15);

  group('a greeting time', () {
    test('is stored as HH:mm and read back', () {
      expect(morning.toStored(), '08:30');
      expect(GreetingTime.tryParse('08:30'), morning);
      expect(GreetingTime.tryParse('21:15'), night);
    });

    test('anything else does not read as a time', () {
      expect(GreetingTime.tryParse(''), isNull);
      expect(GreetingTime.tryParse('24:00'), isNull);
      expect(GreetingTime.tryParse('12:60'), isNull);
      expect(GreetingTime.tryParse('six'), isNull);
    });

    test('is shown on the twelve-hour clock', () {
      expect(morning.toLabel(), '8:30 am');
      expect(evening.toLabel(), '6:00 pm');
      expect(const GreetingTime(0, 5).toLabel(), '12:05 am');
      expect(const GreetingTime(12, 0).toLabel(), '12:00 pm');
    });
  });

  group('partner settings', () {
    test('start with greetings off and no time set', () {
      final settings = PartnerSettings();

      expect(settings.greetingsOn, isFalse);
      expect(settings.times, isEmpty);
      expect(settings.activeTimes, isEmpty);
    });

    test('switching on for the first time sets one time, 6 pm', () {
      final settings = PartnerSettings().withGreetingsOn(true);

      expect(settings.greetingsOn, isTrue);
      expect(settings.times, [evening]);
      expect(settings.activeTimes, [evening]);
    });

    test('switching off keeps the times but none is active', () {
      final settings = PartnerSettings(
        greetingsOn: true,
        times: [morning, night],
      ).withGreetingsOn(false);

      expect(settings.times, [morning, night]);
      expect(settings.activeTimes, isEmpty);
      expect(settings.withGreetingsOn(true).times, [morning, night]);
    });

    test('times are kept in order through the day', () {
      final settings = PartnerSettings(
        greetingsOn: true,
        times: [night, morning],
      );

      expect(settings.times, [morning, night]);
    });

    test('a second time can be added, a third cannot', () {
      var settings = PartnerSettings(greetingsOn: true, times: [evening]);
      expect(settings.canAddTime, isTrue);

      settings = settings.withTimeAdded(morning);
      expect(settings.times, [morning, evening]);
      expect(settings.canAddTime, isFalse);

      expect(settings.withTimeAdded(night).times, [morning, evening]);
    });

    test('never more than two, however they arrive', () {
      final settings = PartnerSettings(times: [night, morning, evening]);

      expect(settings.times, hasLength(PartnerSettings.maxTimes));
    });

    test('the same time twice is kept once', () {
      final settings = PartnerSettings(
        greetingsOn: true,
        times: [evening],
      ).withTimeAdded(evening);

      expect(settings.times, [evening]);
    });

    test('a time can be changed', () {
      final settings = PartnerSettings(
        greetingsOn: true,
        times: [morning, evening],
      ).withTimeChanged(0, night);

      expect(settings.times, [evening, night]);
    });

    test('changing a time to match the other leaves one', () {
      final settings = PartnerSettings(
        greetingsOn: true,
        times: [morning, evening],
      ).withTimeChanged(0, evening);

      expect(settings.times, [evening]);
    });

    test('a time can be removed, but not the last one while on', () {
      var settings = PartnerSettings(
        greetingsOn: true,
        times: [morning, evening],
      );

      settings = settings.withTimeRemoved(morning);
      expect(settings.times, [evening]);

      expect(settings.withTimeRemoved(evening).times, [evening]);
    });

    test('the time offered for a second greeting differs from the first', () {
      expect(PartnerSettings().suggestedNewTime, evening);
      expect(
        PartnerSettings(times: [evening]).suggestedNewTime,
        const GreetingTime(6, 0),
      );
    });

    test('settings with the same switch and times are equal', () {
      expect(
        PartnerSettings(greetingsOn: true, times: [morning]),
        PartnerSettings(greetingsOn: true, times: [morning]),
      );
      expect(
        PartnerSettings(greetingsOn: true, times: [morning]),
        isNot(PartnerSettings(times: [morning])),
      );
    });
  });
}
