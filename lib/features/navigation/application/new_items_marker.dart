import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums/language.dart';
import '../../corrections/application/correction_repository_controller.dart';

/// The two tabs in the bottom bar that can show the dot (task 1.4b).
enum MarkedTab { history, saved }

/// Works out whether History or Saved holds something the learner has not
/// yet looked at, so the bottom bar can show a small dot on that tab
/// (decision A4, point 5; task 1.4b).
///
/// For each tab and each language it keeps the time the learner last
/// looked at that tab. Anything in the tab that is newer than that time is
/// new. The times are kept on the phone, so the dot survives a relaunch.
///
/// The first time the app runs with this in place, the times start at that
/// moment: on a fresh install that is before the introduction sends its two
/// answers, so they bring the dot; on a phone that already had the app,
/// what was there before counts as seen.
class NewItemsMarker extends ChangeNotifier {
  NewItemsMarker({
    required CorrectionRepositoryController repositoryController,
    DateTime Function()? clock,
  }) : _repositoryController = repositoryController,
       _clock = clock ?? DateTime.now;

  final CorrectionRepositoryController _repositoryController;
  final DateTime Function() _clock;

  final Map<String, DateTime> _lastSeen = {};
  bool _loaded = false;
  MarkedTab? _openTab;
  Language? _openLanguage;

  /// Reads the times kept on the phone, starting any that are missing at
  /// the present moment. Call once when the app starts, before anything
  /// can be added to History or Saved.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final now = _clock();
    for (final tab in MarkedTab.values) {
      for (final language in Language.values) {
        final key = _key(tab, language);
        final kept = DateTime.tryParse(prefs.getString(key) ?? '');
        if (kept != null) {
          _lastSeen[key] = kept;
        } else {
          _lastSeen[key] = now;
          await prefs.setString(key, now.toIso8601String());
        }
      }
    }
    if (!_loaded) {
      _loaded = true;
      _repositoryController.addListener(_onItemsChanged);
    }
    notifyListeners();
  }

  /// Whether [tab] holds something in [language] the learner has not yet
  /// looked at.
  bool hasNew(MarkedTab tab, Language language) {
    if (!_loaded) return false;
    final seen = _lastSeen[_key(tab, language)];
    if (seen == null) return false;
    return _itemTimes(tab, language).any((time) => time.isAfter(seen));
  }

  /// Tells the marker which tab is on screen, or null for a tab with no
  /// dot. Opening History or Saved counts as looking at everything in it,
  /// and so does anything that arrives while it stays open.
  Future<void> setOpenTab(MarkedTab? tab, Language language) async {
    _openTab = tab;
    _openLanguage = language;
    if (tab != null) {
      await markSeen(tab, language);
    }
  }

  /// Counts everything now in [tab] as looked at.
  Future<void> markSeen(MarkedTab tab, Language language) async {
    if (!_loaded) return;
    final key = _key(tab, language);
    var latest = _clock();
    for (final time in _itemTimes(tab, language)) {
      if (time.isAfter(latest)) latest = time;
    }
    final seen = _lastSeen[key];
    if (seen != null && !latest.isAfter(seen)) return;
    _lastSeen[key] = latest;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, latest.toIso8601String());
  }

  void _onItemsChanged() {
    final tab = _openTab;
    final language = _openLanguage;
    if (tab != null && language != null && hasNew(tab, language)) {
      markSeen(tab, language);
      return;
    }
    notifyListeners();
  }

  Iterable<DateTime> _itemTimes(MarkedTab tab, Language language) {
    switch (tab) {
      case MarkedTab.history:
        return _repositoryController.recentSubmissions
            .where((item) => item.language == language)
            .map((item) => item.createdAt);
      case MarkedTab.saved:
        return _repositoryController.savedCorrections
            .where((item) => item.language == language)
            .map((item) => item.savedAt);
    }
  }

  static String _key(MarkedTab tab, Language language) =>
      'new_items_last_seen_${tab.name}_${language.toJson()}';

  @override
  void dispose() {
    if (_loaded) {
      _repositoryController.removeListener(_onItemsChanged);
    }
    super.dispose();
  }
}
