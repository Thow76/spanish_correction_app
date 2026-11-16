/// Records the learner's spoken answer to a sound file, for the "Something
/// you're into" step. The file is then turned into text by the existing
/// transcription service, as on the Check a phrase page. Behind an interface
/// so the introduction can be tested without a microphone.
abstract interface class VoiceRecorder {
  /// Whether the app may use the microphone. Asks the learner the first time.
  Future<bool> hasPermission();

  /// Starts recording.
  Future<void> start();

  /// Stops recording and returns the path of the sound file, or null if
  /// nothing was recorded.
  Future<String?> stop();

  Future<void> dispose();
}
