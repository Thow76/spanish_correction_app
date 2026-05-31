import 'package:flutter/foundation.dart';

import '../../../core/enums/language.dart';
import '../../history/domain/correction_submission.dart';
import '../../saved/domain/saved_correction.dart';
import '../domain/queued_submission.dart';
import 'correction_repository.dart';

class CorrectionRepositoryController extends ChangeNotifier {
  CorrectionRepositoryController(this._repository);

  final CorrectionRepository _repository;

  List<CorrectionSubmission> _recentSubmissions = const [];
  List<SavedCorrection> _savedCorrections = const [];
  List<QueuedSubmission> _queuedSubmissions = const [];
  bool _isLoadingHistory = false;
  Language? _activeLanguage;

  List<CorrectionSubmission> get recentSubmissions => _recentSubmissions;
  List<SavedCorrection> get savedCorrections => _savedCorrections;
  List<QueuedSubmission> get queuedSubmissions => _queuedSubmissions;
  bool get isLoadingHistory => _isLoadingHistory;
  Language? get activeLanguage => _activeLanguage;

  Future<void> setActiveLanguage(Language language) async {
    _activeLanguage = language;
    await Future.wait([
      _refreshRecentSubmissions(),
      _refreshSavedCorrections(),
      _refreshQueuedSubmissions(),
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

  // Queue is always loaded unfiltered — sync drains all languages.
  Future<void> loadQueuedSubmissions() async {
    _queuedSubmissions = await _repository.getQueuedSubmissions();
    notifyListeners();
  }

  Future<void> enqueueSubmission(QueuedSubmission submission) async {
    await _repository.enqueueSubmission(submission);
    _queuedSubmissions = await _repository.getQueuedSubmissions();
    notifyListeners();
  }

  Future<void> removeQueuedSubmission(String id) async {
    await _repository.removeQueuedSubmission(id);
    _queuedSubmissions = await _repository.getQueuedSubmissions();
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

  Future<void> _refreshQueuedSubmissions() async {
    _queuedSubmissions = await _repository.getQueuedSubmissions();
  }
}
