import 'package:flutter/foundation.dart';

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

  List<CorrectionSubmission> get recentSubmissions => _recentSubmissions;
  List<SavedCorrection> get savedCorrections => _savedCorrections;
  List<QueuedSubmission> get queuedSubmissions => _queuedSubmissions;
  bool get isLoadingHistory => _isLoadingHistory;

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _recentSubmissions = await _repository.loadRecentSubmissions();
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> addSubmission(CorrectionSubmission submission) async {
    await _repository.addSubmission(submission);
    _recentSubmissions = await _repository.loadRecentSubmissions();
    notifyListeners();
  }

  Future<void> loadSavedCorrections() async {
    _savedCorrections = await _repository.loadSavedCorrections();
    notifyListeners();
  }

  Future<void> addSavedCorrection(SavedCorrection correction) async {
    await _repository.addSavedCorrection(correction);
    _savedCorrections = await _repository.loadSavedCorrections();
    notifyListeners();
  }

  Future<void> loadQueuedSubmissions() async {
    _queuedSubmissions = await _repository.loadQueuedSubmissions();
    notifyListeners();
  }

  Future<void> enqueueSubmission(QueuedSubmission submission) async {
    await _repository.enqueueSubmission(submission);
    _queuedSubmissions = await _repository.loadQueuedSubmissions();
    notifyListeners();
  }

  Future<void> removeQueuedSubmission(String id) async {
    await _repository.removeQueuedSubmission(id);
    _queuedSubmissions = await _repository.loadQueuedSubmissions();
    notifyListeners();
  }
}
