import '../../corrections/domain/error_category.dart';

class SavedCorrection {
  const SavedCorrection({
    required this.category,
    required this.shortExplanation,
    required this.originalSentence,
    required this.longExplanation,
    required this.savedAt,
    required this.correctedPhrase,
  });

  final ErrorCategory category;
  final String shortExplanation;
  final String originalSentence;
  final String longExplanation;
  final DateTime savedAt;
  final String correctedPhrase;
}
