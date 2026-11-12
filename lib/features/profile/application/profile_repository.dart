import '../domain/learner_profile.dart';

/// Where the learner's profile is kept (decision A2).
///
/// There is one profile per install. [getProfile] never fails for want of a
/// file: a missing or unreadable store reads as an empty profile.
abstract interface class ProfileRepository {
  Future<LearnerProfile> getProfile();

  Future<void> saveProfile(LearnerProfile profile);

  /// Reads the profile, applies [change] to it and saves the result, which
  /// is returned.
  Future<LearnerProfile> updateProfile(
    LearnerProfile Function(LearnerProfile profile) change,
  );

  /// Puts the profile back to empty, so the introduction runs again. Nothing
  /// in the app calls this yet; it exists for tests and for a future reset.
  Future<void> clear();
}
