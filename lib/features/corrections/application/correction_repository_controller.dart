import 'package:flutter/foundation.dart';

import '../../../core/enums/language.dart';
import '../../../core/models/walkthrough_activity.dart';
import '../../history/domain/correction_submission.dart';
import '../../saved/domain/saved_correction.dart';
import 'correction_repository.dart';

class CorrectionRepositoryController extends ChangeNotifier {
  CorrectionRepositoryController(this._repository);

  final CorrectionRepository _repository;

  List<CorrectionSubmission> _recentSubmissions = const [];
  List<SavedCorrection> _savedCorrections = const [];
  List<WalkthroughActivity> _walkthroughActivities = const [];
  bool _isLoadingHistory = false;
  Language? _activeLanguage;

  List<CorrectionSubmission> get recentSubmissions => _recentSubmissions;
  List<SavedCorrection> get savedCorrections => _savedCorrections;
  List<WalkthroughActivity> get walkthroughActivities => _walkthroughActivities;
  bool get isLoadingHistory => _isLoadingHistory;
  Language? get activeLanguage => _activeLanguage;

  Future<void> setActiveLanguage(Language language) async {
    _activeLanguage = language;
    await Future.wait([
      _refreshRecentSubmissions(),
      _refreshSavedCorrections(),
      _refreshWalkthroughActivities(),
    ]);
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _recentSubmissions = await _repository.getRecentSubmissions(
        language: _activeLanguage,
      );
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> addSubmission(CorrectionSubmission submission) async {
    await _repository.addSubmission(submission);
    _recentSubmissions = await _repository.getRecentSubmissions(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> removeSubmission(String id) async {
    await _repository.removeSubmission(id);
    _recentSubmissions = await _repository.getRecentSubmissions(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> loadSavedCorrections() async {
    _savedCorrections = await _repository.getSavedCorrections(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> addSavedCorrection(SavedCorrection correction) async {
    await _repository.addSavedCorrection(correction);
    _savedCorrections = await _repository.getSavedCorrections(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> removeSavedCorrection(String id) async {
    await _repository.removeSavedCorrection(id);
    _savedCorrections = await _repository.getSavedCorrections(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> loadWalkthroughActivities() async {
    _walkthroughActivities = await _repository.getWalkthroughActivities(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> addWalkthroughActivity(WalkthroughActivity activity) async {
    await _repository.addWalkthroughActivity(activity);
    _walkthroughActivities = await _repository.getWalkthroughActivities(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> removeWalkthroughActivity(String sourcePhraseId) async {
    await _repository.removeWalkthroughActivity(sourcePhraseId);
    _walkthroughActivities = await _repository.getWalkthroughActivities(
      language: _activeLanguage,
    );
    notifyListeners();
  }

  Future<void> _refreshRecentSubmissions() async {
    _recentSubmissions = await _repository.getRecentSubmissions(
      language: _activeLanguage,
    );
  }

  Future<void> _refreshSavedCorrections() async {
    _savedCorrections = await _repository.getSavedCorrections(
      language: _activeLanguage,
    );
  }

  Future<void> _refreshWalkthroughActivities() async {
    _walkthroughActivities = await _repository.getWalkthroughActivities(
      language: _activeLanguage,
    );
  }
}
