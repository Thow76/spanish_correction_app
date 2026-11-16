import 'package:spanish_correction_app/features/profile/application/profile_repository.dart';
import 'package:spanish_correction_app/features/profile/domain/learner_profile.dart';

/// Keeps the profile in memory, for the introduction's tests.
class FakeProfileRepository implements ProfileRepository {
  LearnerProfile stored = LearnerProfile.empty();

  /// The last profile saved, or null if nothing has been saved yet.
  LearnerProfile? saved;
  int saveCount = 0;

  @override
  Future<LearnerProfile> getProfile() async => stored;

  @override
  Future<void> saveProfile(LearnerProfile profile) async {
    stored = profile;
    saved = profile;
    saveCount++;
  }

  @override
  Future<LearnerProfile> updateProfile(
    LearnerProfile Function(LearnerProfile profile) change,
  ) async {
    final next = change(stored);
    await saveProfile(next);
    return next;
  }

  @override
  Future<void> clear() async => saveProfile(LearnerProfile.empty());
}
