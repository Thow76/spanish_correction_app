/// How the learner gave the text that is checked (decision C3, build step
/// 2.3).
///
/// For spoken text the phone's transcription wrote the spelling, accents
/// and punctuation, not the learner, so the check shows no Spelling items
/// for it.
enum CorrectionInputMode {
  /// Typed or pasted by the learner.
  typed,

  /// Recorded and transcribed; the learner did not write the letters.
  spoken,
}
