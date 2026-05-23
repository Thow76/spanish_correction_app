enum CorrectionFailureReason {
  missingConfiguration,
  networkUnavailable,
  apiFailure,
  invalidResponse,
}

class CorrectionServiceException implements Exception {
  const CorrectionServiceException(this.reason, this.message);

  final CorrectionFailureReason reason;
  final String message;
}
