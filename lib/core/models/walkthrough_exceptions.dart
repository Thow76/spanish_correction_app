/// Exception hierarchy for the Traducir frases walkthrough feature.
///
/// [WalkthroughSchemaException] is raised at parse time by the data models.
/// [WalkthroughValidationException] and [WalkthroughApiException] are defined
/// now for the service layer (Section 5) but are not thrown by the data models.
class WalkthroughException implements Exception {
  const WalkthroughException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a walkthrough JSON payload fails to parse: wrong types, missing
/// fields, or the wrong number of distractors.
class WalkthroughSchemaException extends WalkthroughException {
  const WalkthroughSchemaException(super.message);
}

/// Thrown by the service layer when a structurally valid payload fails the
/// semantic checks in Section 5 (distractor distinctness, cross-language
/// contamination, target_sentence reconstruction).
class WalkthroughValidationException extends WalkthroughException {
  const WalkthroughValidationException(super.message);
}

/// Thrown by the service layer when the walkthrough request to the model API
/// fails (network, status, or empty response).
class WalkthroughApiException extends WalkthroughException {
  const WalkthroughApiException(super.message);
}
