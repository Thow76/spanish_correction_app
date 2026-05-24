enum TranscriptionFailureReason {
  missingConfiguration,
  networkUnavailable,
  apiFailure,
  invalidResponse,
}

class TranscriptionServiceException implements Exception {
  const TranscriptionServiceException(this.reason, this.message);

  final TranscriptionFailureReason reason;
  final String message;
}
