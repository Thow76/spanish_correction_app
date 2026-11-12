import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../application/profile_repository.dart';
import '../domain/learner_profile.dart';

/// Keeps the learner's profile in `learner_profile.json` in the app's
/// documents folder, beside `correction_store.json` (decision A2, point 5).
///
/// Follows `FileCorrectionRepository`: the whole profile is read and written
/// as one indented JSON file, a missing or blank file reads as an empty
/// profile, and a file that cannot be parsed is treated as empty rather than
/// stopping the app. Everything stays on the phone (decision E3).
class FileProfileRepository implements ProfileRepository {
  FileProfileRepository({File? file}) : _file = file;

  static const fileName = 'learner_profile.json';

  final File? _file;

  @override
  Future<LearnerProfile> getProfile() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      return LearnerProfile.empty();
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return LearnerProfile.empty();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (error) {
      debugPrint('Profile file could not be read, starting empty: $error');
      return LearnerProfile.empty();
    }
    if (decoded is! Map<String, Object?>) {
      return LearnerProfile.empty();
    }

    return LearnerProfile.fromJson(decoded);
  }

  @override
  Future<void> saveProfile(LearnerProfile profile) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(profile.toJson()));
  }

  @override
  Future<LearnerProfile> updateProfile(
    LearnerProfile Function(LearnerProfile profile) change,
  ) async {
    final next = change(await getProfile());
    await saveProfile(next);
    return next;
  }

  @override
  Future<void> clear() async {
    await saveProfile(LearnerProfile.empty());
  }

  Future<File> _resolveFile() async {
    if (_file != null) {
      return _file;
    }

    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }
}
