/// The three kinds of chat the introduction previews (decision A3).
///
/// Each "Try it" step, and each part of the "Show me" demo, carries a small
/// English label naming the kind of chat the app rotates through. The
/// wording here is the working wording from decision A3; Andrew settles it
/// with the chip list, by editing [label] and nothing else.
enum IntroductionStepKind {
  /// An everyday question, the same for everyone, answered by typing.
  friendlyOpener('Friendly opener'),

  /// A question about one of the chips the learner tapped, answered by
  /// speaking.
  somethingYoureInto("Something you're into"),

  /// A recommendation card linked to one of the learner's chips: nothing to
  /// answer, just Open now or Skip.
  recommendation('A recommendation');

  const IntroductionStepKind(this.label);

  /// The small English title shown above the step.
  final String label;
}
