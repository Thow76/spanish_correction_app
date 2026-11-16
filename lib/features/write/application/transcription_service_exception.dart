enum TranscriptionFailureReason {
  missingConfiguration,
  networkUnavailable,
  apiFailure,
  invalidResponse,

  /// The recording was too short or too quiet to hold any words, or the
  /// speech model returned one of the lines it invents for silence.
  nothingHeard,
}

class TranscriptionServiceException implements Exception {
  const TranscriptionServiceException(this.reason, this.message);

  final TranscriptionFailureReason reason;
  final String message;
}
