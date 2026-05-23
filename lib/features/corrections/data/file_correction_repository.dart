import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../history/domain/correction_submission.dart';
import '../../saved/domain/saved_correction.dart';
import '../application/correction_repository.dart';
import '../domain/queued_submission.dart';

class FileCorrectionRepository implements CorrectionRepository {
  FileCorrectionRepository({File? file}) : _file = file;

  static const _fileName = 'spanish_correction_store.json';
  static const _recentLimit = 20;

  final File? _file;

  @override
  Future<List<CorrectionSubmission>> loadRecentSubmissions() async {
    final state = await _readState();
    return List.unmodifiable(state.recentSubmissions);
  }

  @override
  Future<void> addSubmission(CorrectionSubmission submission) async {
    final state = await _readState();
    final nextSubmissions = [
      submission,
      ...state.recentSubmissions.where((item) => item.id != submission.id),
    ].take(_recentLimit).toList();

    await _writeState(state.copyWith(recentSubmissions: nextSubmissions));
  }

  @override
  Future<List<SavedCorrection>> loadSavedCorrections() async {
    final state = await _readState();
    return List.unmodifiable(state.savedCorrections);
  }

  @override
  Future<void> addSavedCorrection(SavedCorrection correction) async {
    final state = await _readState();
    final nextSaved = [
      correction,
      ...state.savedCorrections.where((item) => item.id != correction.id),
    ];

    await _writeState(state.copyWith(savedCorrections: nextSaved));
  }

  @override
  Future<List<QueuedSubmission>> loadQueuedSubmissions() async {
    final state = await _readState();
    return List.unmodifiable(state.queuedSubmissions);
  }

  @override
  Future<void> enqueueSubmission(QueuedSubmission submission) async {
    final state = await _readState();
    final nextQueue = [
      ...state.queuedSubmissions.where((item) => item.id != submission.id),
      submission,
    ];

    await _writeState(state.copyWith(queuedSubmissions: nextQueue));
  }

  @override
  Future<void> removeQueuedSubmission(String id) async {
    final state = await _readState();
    final nextQueue = state.queuedSubmissions
        .where((submission) => submission.id != id)
        .toList();

    await _writeState(state.copyWith(queuedSubmissions: nextQueue));
  }

  @override
  Future<void> clear() async {
    await _writeState(const _CorrectionStoreState.empty());
  }

  Future<_CorrectionStoreState> _readState() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      return const _CorrectionStoreState.empty();
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return const _CorrectionStoreState.empty();
    }

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, Object?>) {
      return const _CorrectionStoreState.empty();
    }

    return _CorrectionStoreState.fromJson(decoded);
  }

  Future<void> _writeState(_CorrectionStoreState state) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(state.toJson()));
  }

  Future<File> _resolveFile() async {
    if (_file != null) {
      return _file;
    }

    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }
}

class _CorrectionStoreState {
  const _CorrectionStoreState({
    required this.recentSubmissions,
    required this.savedCorrections,
    required this.queuedSubmissions,
  });

  const _CorrectionStoreState.empty()
    : recentSubmissions = const [],
      savedCorrections = const [],
      queuedSubmissions = const [];

  final List<CorrectionSubmission> recentSubmissions;
  final List<SavedCorrection> savedCorrections;
  final List<QueuedSubmission> queuedSubmissions;

  factory _CorrectionStoreState.fromJson(Map<String, Object?> json) {
    return _CorrectionStoreState(
      recentSubmissions: _readList(
        json['recent_submissions'],
        CorrectionSubmission.fromJson,
      ),
      savedCorrections: _readList(
        json['saved_corrections'],
        SavedCorrection.fromJson,
      ),
      queuedSubmissions: _readList(
        json['queued_submissions'],
        QueuedSubmission.fromJson,
      ),
    );
  }

  _CorrectionStoreState copyWith({
    List<CorrectionSubmission>? recentSubmissions,
    List<SavedCorrection>? savedCorrections,
    List<QueuedSubmission>? queuedSubmissions,
  }) {
    return _CorrectionStoreState(
      recentSubmissions: recentSubmissions ?? this.recentSubmissions,
      savedCorrections: savedCorrections ?? this.savedCorrections,
      queuedSubmissions: queuedSubmissions ?? this.queuedSubmissions,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'recent_submissions': recentSubmissions
          .map((submission) => submission.toJson())
          .toList(),
      'saved_corrections': savedCorrections
          .map((correction) => correction.toJson())
          .toList(),
      'queued_submissions': queuedSubmissions
          .map((submission) => submission.toJson())
          .toList(),
    };
  }

  static List<T> _readList<T>(
    Object? value,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    if (value is! List) {
      return [];
    }

    return value.whereType<Map<String, Object?>>().map(fromJson).toList();
  }
}
