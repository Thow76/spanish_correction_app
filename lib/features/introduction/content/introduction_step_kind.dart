/// The three kinds of chat the introduction previews (decision A3).
///
/// Each "Try it" step, and each part of the "Show me" demo, carries a small
/// English label naming the kind of chat the app rotates through. The
/// wording was settled by Andrew on 16 Nov 2026, replacing A3's working
/// labels ("Friendly opener", "Something you're into", "A recommendation").
enum IntroductionStepKind {
  /// An everyday question, the same for everyone, answered by typing.
  friendlyOpener('Chat about your day'),

  /// A question about one of the chips the learner tapped, answered by
  /// speaking.
  somethingYoureInto('Chat about your interests'),

  /// A recommendation card linked to one of the learner's chips: nothing to
  /// answer, just Open now or Skip.
  recommendation('Chat about a recommendation');

  const IntroductionStepKind(this.label);

  /// The small English title shown above the step.
  final String label;
}
