/// How the learner takes part in a step of the introduction (task 1.3).
enum IntroductionAnswerMode {
  /// Tapping interest chips, one to five.
  chips,

  /// Choosing between Try it and Show me.
  choice,

  /// Typing an answer (the friendly opener).
  type,

  /// Speaking an answer (the interest question).
  microphone,

  /// A recommendation card: Open now or Skip, nothing to answer.
  recommendationCard,

  /// The Show me demo: watching, nothing to answer.
  demo,

  /// The end screen.
  end,
}

/// One step of the introduction as the screen shows it: the small English
/// label above it, the question (if there is one), the small English hint
/// under it, and how the learner answers (task 1.3).
class IntroductionStep {
  const IntroductionStep({
    required this.mode,
    required this.label,
    this.questionText,
    this.hint,
  });

  final IntroductionAnswerMode mode;

  /// The small English label above the step, for example "Friendly opener".
  final String label;

  /// The question, in the target language where the step asks one.
  final String? questionText;

  /// The small English hint under the question.
  final String? hint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntroductionStep &&
          other.mode == mode &&
          other.label == label &&
          other.questionText == questionText &&
          other.hint == hint;

  @override
  int get hashCode => Object.hash(mode, label, questionText, hint);

  @override
  String toString() => 'IntroductionStep($mode, $label)';
}
