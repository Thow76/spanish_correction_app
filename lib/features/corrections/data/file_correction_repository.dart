import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/enums/language.dart';
import '../../../core/models/walkthrough_activity.dart';
import '../../history/domain/correction_submission.dart';
import '../../saved/domain/saved_correction.dart';
import '../application/correction_repository.dart';

class FileCorrectionRepository implements CorrectionRepository {
  FileCorrectionRepository({File? file}) : _file = file;

  static const _fileName = 'correction_store.json';
  static const _oldFileName = 'spanish_correction_store.json';
  static const _recentLimit = 20;

  final File? _file;

  @override
  Future<List<CorrectionSubmission>> getRecentSubmissions({
    Language? language,
  }) async {
    final state = await _readState();
    final all = state.recentSubmissions;
    final filtered = language == null
        ? all
        : all.where((s) => s.language == language).toList();
    return List.unmodifiable(filtered.take(_recentLimit).toList());
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
  Future<void> removeSubmission(String id) async {
    final state = await _readState();
    final nextSubmissions = state.recentSubmissions
        .where((submission) => submission.id != id)
        .toList();

    if (nextSubmissions.length == state.recentSubmissions.length) {
      return;
    }

    await _writeState(state.copyWith(recentSubmissions: nextSubmissions));
  }

  @override
  Future<List<SavedCorrection>> getSavedCorrections({
    Language? language,
  }) async {
    final state = await _readState();
    final all = state.savedCorrections;
    final filtered = language == null
        ? all
        : all.where((c) => c.language == language).toList();
    return List.unmodifiable(filtered);
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
  Future<void> removeSavedCorrection(String id) async {
    final state = await _readState();
    final nextSaved = state.savedCorrections
        .where((correction) => correction.id != id)
        .toList();

    if (nextSaved.length == state.savedCorrections.length) {
      return;
    }

    await _writeState(state.copyWith(savedCorrections: nextSaved));
  }

  @override
  Future<List<WalkthroughActivity>> getWalkthroughActivities({
    Language? language,
  }) async {
    final state = await _readState();
    final all = state.walkthroughActivities;
    final filtered = language == null
        ? all
        : all.where((a) => a.language == language).toList();
    return List.unmodifiable(filtered);
  }

  @override
  Future<void> addWalkthroughActivity(WalkthroughActivity activity) async {
    final state = await _readState();
    final nextActivities = [
      activity,
      ...state.walkthroughActivities.where(
        (item) => item.sourcePhraseId != activity.sourcePhraseId,
      ),
    ];

    await _writeState(state.copyWith(walkthroughActivities: nextActivities));
  }

  @override
  Future<void> removeWalkthroughActivity(String sourcePhraseId) async {
    final state = await _readState();
    final nextActivities = state.walkthroughActivities
        .where((activity) => activity.sourcePhraseId != sourcePhraseId)
        .toList();

    if (nextActivities.length == state.walkthroughActivities.length) {
      return;
    }

    await _writeState(state.copyWith(walkthroughActivities: nextActivities));
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
    final newFile = File('${directory.path}/$_fileName');

    if (!await newFile.exists()) {
      final oldFile = File('${directory.path}/$_oldFileName');
      if (await oldFile.exists()) {
        await oldFile.copy(newFile.path);
        await oldFile.delete();
      }
    }

    return newFile;
  }
}

class _CorrectionStoreState {
  const _CorrectionStoreState({
    required this.recentSubmissions,
    required this.savedCorrections,
    required this.walkthroughActivities,
  });

  const _CorrectionStoreState.empty()
    : recentSubmissions = const [],
      savedCorrections = const [],
      walkthroughActivities = const [];

  final List<CorrectionSubmission> recentSubmissions;
  final List<SavedCorrection> savedCorrections;
  final List<WalkthroughActivity> walkthroughActivities;

  // Deliberately does not read a `queued_submissions` key: the queued-
  // submission feature has been removed. Any such key left over in an
  // existing install's store file from before this change is simply
  // ignored here and dropped from the file on the next write, via toJson()
  // below no longer emitting it — no explicit migration needed.
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
      walkthroughActivities: _readList(
        json['walkthrough_activities'],
        WalkthroughActivity.fromJson,
      ),
    );
  }

  _CorrectionStoreState copyWith({
    List<CorrectionSubmission>? recentSubmissions,
    List<SavedCorrection>? savedCorrections,
    List<WalkthroughActivity>? walkthroughActivities,
  }) {
    return _CorrectionStoreState(
      recentSubmissions: recentSubmissions ?? this.recentSubmissions,
      savedCorrections: savedCorrections ?? this.savedCorrections,
      walkthroughActivities:
          walkthroughActivities ?? this.walkthroughActivities,
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
      'walkthrough_activities': walkthroughActivities
          .map((activity) => activity.toJson())
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

    // Skip non-map entries (as before) and, additionally, any map-shaped entry
    // whose fromJson throws. The walkthrough models parse strictly and throw on
    // bad records (e.g. an unrecognised language); without this guard a single
    // corrupt entry would fail the whole-file read and block every other record
    // type from loading. Containment matches the older types, which never throw.
    final result = <T>[];
    for (final entry in value.whereType<Map<String, Object?>>()) {
      try {
        result.add(fromJson(entry));
      } catch (error) {
        debugPrint('Skipping malformed $T record in store: $error');
      }
    }
    return result;
  }
}
