/// A time of day at which the partner writes a greeting, to the minute.
class GreetingTime implements Comparable<GreetingTime> {
  const GreetingTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Reads "HH:mm", as [toStored] writes it. Null for anything else.
  static GreetingTime? tryParse(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) {
      return null;
    }
    return GreetingTime(hour, minute);
  }

  final int hour;
  final int minute;

  int get minutesIntoDay => hour * 60 + minute;

  /// "HH:mm" on the 24-hour clock, for storing.
  String toStored() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// The time as shown to the learner, for example "6:00 pm".
  String toLabel() {
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:${minute.toString().padLeft(2, '0')} '
        '${hour < 12 ? 'am' : 'pm'}';
  }

  @override
  int compareTo(GreetingTime other) =>
      minutesIntoDay.compareTo(other.minutesIntoDay);

  @override
  bool operator ==(Object other) =>
      other is GreetingTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => minutesIntoDay;

  @override
  String toString() => 'GreetingTime(${toStored()})';
}

/// The learner's settings for the partner's greetings (decision B4, part 1;
/// build step 5.1): whether the partner writes first at all, and at up to
/// two times of day.
///
/// The times are always in order through the day, with no time twice and
/// never more than [maxTimes]. They are kept while greetings are switched
/// off, so switching back on brings them back.
class PartnerSettings {
  PartnerSettings({
    this.greetingsOn = false,
    Iterable<GreetingTime> times = const [],
  }) : times = List.unmodifiable(_tidy(times));

  /// At most two greeting times a day (decision B4).
  static const maxTimes = 2;

  /// The time put in when greetings are first switched on with no time set.
  static const firstTime = GreetingTime(18, 0);

  /// Whether the partner writes a greeting at the set times.
  final bool greetingsOn;

  /// The greeting times, earliest first.
  final List<GreetingTime> times;

  bool get canAddTime => times.length < maxTimes;

  /// The times a greeting is due at: [times] when greetings are on, none
  /// when they are off. Step 5.2 schedules its notifications from this.
  List<GreetingTime> get activeTimes => greetingsOn ? times : const [];

  /// Greetings switched on or off. Switching on with no time set puts in
  /// [firstTime], so that "on" always means at least one greeting a day.
  PartnerSettings withGreetingsOn(bool on) => PartnerSettings(
    greetingsOn: on,
    times: on && times.isEmpty ? const [firstTime] : times,
  );

  /// The settings with [time] added. Nothing changes if there are already
  /// [maxTimes] times or [time] is already set.
  PartnerSettings withTimeAdded(GreetingTime time) =>
      canAddTime ? _withTimes([...times, time]) : this;

  /// The settings with the time at [index] changed to [time]. If that makes
  /// two times the same, only one is kept.
  PartnerSettings withTimeChanged(int index, GreetingTime time) {
    if (index < 0 || index >= times.length) {
      return this;
    }
    return _withTimes([...times]..[index] = time);
  }

  /// The settings with [time] removed. The last time cannot be removed
  /// while greetings are on; switch greetings off instead.
  PartnerSettings withTimeRemoved(GreetingTime time) {
    if (greetingsOn && times.length <= 1) {
      return this;
    }
    return _withTimes(times.where((kept) => kept != time));
  }

  /// A time worth offering when the learner adds one: [firstTime], or
  /// twelve hours from the time already set if that is taken.
  GreetingTime get suggestedNewTime {
    if (!times.contains(firstTime)) {
      return firstTime;
    }
    return GreetingTime((firstTime.hour + 12) % 24, firstTime.minute);
  }

  PartnerSettings _withTimes(Iterable<GreetingTime> next) =>
      PartnerSettings(greetingsOn: greetingsOn, times: next);

  static List<GreetingTime> _tidy(Iterable<GreetingTime> times) =>
      (times.toSet().toList()..sort()).take(maxTimes).toList();

  @override
  bool operator ==(Object other) =>
      other is PartnerSettings &&
      other.greetingsOn == greetingsOn &&
      other.times.length == times.length &&
      [
        for (var i = 0; i < times.length; i++) times[i] == other.times[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hash(greetingsOn, Object.hashAll(times));
}
