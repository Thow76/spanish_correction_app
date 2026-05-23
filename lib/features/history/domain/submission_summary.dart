class SubmissionSummary {
  const SubmissionSummary({
    required this.originalText,
    required this.correctedText,
    required this.createdAt,
    required this.errorCount,
  });

  final String originalText;
  final String correctedText;
  final DateTime createdAt;
  final int errorCount;
}
