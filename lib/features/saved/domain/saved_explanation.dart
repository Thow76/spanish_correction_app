class SavedExplanation {
  const SavedExplanation({
    required this.whyItsWrong,
    required this.inContext,
    required this.alternatives,
  });

  final String whyItsWrong;
  final String inContext;
  final List<String> alternatives;

  factory SavedExplanation.fromJson(Map<String, Object?> json) {
    final alternatives = json['alternatives'];

    return SavedExplanation(
      whyItsWrong: json['why_its_wrong'] as String? ?? '',
      inContext: json['in_context'] as String? ?? '',
      alternatives: alternatives is List
          ? alternatives.whereType<String>().toList()
          : const [],
    );
  }

  factory SavedExplanation.fromLegacyLongExplanation(String value) {
    return SavedExplanation(
      whyItsWrong: value,
      inContext: '',
      alternatives: const [],
    );
  }

  Map<String, Object?> toJson() {
    return {
      'why_its_wrong': whyItsWrong,
      'in_context': inContext,
      'alternatives': alternatives,
    };
  }
}
