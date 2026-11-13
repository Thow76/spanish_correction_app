/// Which part of the introduction a step belongs to (decision A1).
enum IntroductionStepKind {
  /// One of the two warm-up questions that teach the controls.
  warmUp,

  /// The interest chips in the target language.
  interests,

  /// One of the fuller questions drawn from the chosen chips.
  fullerQuestion,

  /// The closing screen.
  endScreen,
}

/// How the learner answers a step.
enum AnswerMode {
  /// A text box only.
  typed,

  /// The microphone; the transcript is shown in the text box before sending.
  spoken,

  /// Both the text box and the microphone, as on the Check a phrase page.
  typedOrSpoken,

  /// Tapping chips.
  chips,

  /// Nothing to answer (the end screen).
  none,
}

/// One screen of the introduction: what it says and how it is answered.
///
/// The introduction is a short scripted flow (decision A1), so a step is
/// little more than a question and an answer mode. [IntroductionController]
/// works out which step comes next from the saved progress; the screen only
/// shows the step it is given.
class IntroductionStep {
  const IntroductionStep({
    required this.kind,
    required this.id,
    required this.text,
    required this.answerMode,
    this.hint,
    this.number = 1,
    this.count = 1,
  });

  final IntroductionStepKind kind;

  /// The id of the question behind this step (a warm-up or fuller question
  /// id from `IntroductionContent`), or a fixed id for the chips and the end
  /// screen.
  final String id;

  /// What the learner sees, in the target language.
  final String text;

  /// A small line in English under the question, telling the learner what to
  /// do with the control. Null when there is nothing to explain.
  final String? hint;

  final AnswerMode answerMode;

  /// This step's place among the steps of the same [kind], counting from one,
  /// so the screen can say "2 of 3".
  final int number;

  /// How many steps of the same [kind] there are.
  final int count;

  bool get isWarmUp => kind == IntroductionStepKind.warmUp;
  bool get isInterests => kind == IntroductionStepKind.interests;
  bool get isFullerQuestion => kind == IntroductionStepKind.fullerQuestion;
  bool get isEndScreen => kind == IntroductionStepKind.endScreen;

  /// Whether this step takes a written or spoken answer.
  bool get takesTextAnswer =>
      answerMode == AnswerMode.typed ||
      answerMode == AnswerMode.spoken ||
      answerMode == AnswerMode.typedOrSpoken;

  bool get showsTextBox => takesTextAnswer;

  bool get showsMicrophone =>
      answerMode == AnswerMode.spoken || answerMode == AnswerMode.typedOrSpoken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntroductionStep &&
          other.kind == kind &&
          other.id == id &&
          other.text == text &&
          other.hint == hint &&
          other.answerMode == answerMode &&
          other.number == number &&
          other.count == count;

  @override
  int get hashCode =>
      Object.hash(kind, id, text, hint, answerMode, number, count);

  @override
  String toString() => 'IntroductionStep($kind, $id, $answerMode)';
}
