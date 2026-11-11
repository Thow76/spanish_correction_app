import '../../../core/enums/language.dart';

/// The structure a fuller question is written to pull out of the learner.
///
/// Decision A1 asks for about three fuller questions per interest, "each
/// written to pull a different structure". The structure is recorded on each
/// question so the introduction can choose three that differ, and so Andrew
/// can see at a glance what each question is for when he writes his own.
enum QuestionStructure {
  /// Present tense and habits: what the learner usually does, how often.
  presentHabits,

  /// Telling something that happened: preterite and imperfect.
  pastNarrative,

  /// An opinion with a reason: "creo que", "me parece", the subjunctive after
  /// doubt or judgement.
  opinionAndReason,

  /// Imagining: "si pudieras", conditional forms.
  hypothetical,

  /// Plans and intentions: the future, "pensar", "tener ganas de".
  futurePlans,

  /// Describing or comparing: adjectives, "más que", "lo que más".
  descriptionAndComparison,
}

/// One of the fuller questions asked after the interest chips.
///
/// Each question belongs to one interest ([interestId]) and one target
/// language. In slice 1 only Spanish questions exist; Portuguese questions are
/// added later as more entries, not as a change to this shape.
class FullerQuestion {
  const FullerQuestion({
    required this.id,
    required this.interestId,
    required this.language,
    required this.text,
    required this.structure,
  });

  final String id;
  final String interestId;
  final Language language;

  /// The question as shown to the learner, in the target language.
  final String text;
  final QuestionStructure structure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FullerQuestion && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FullerQuestion($id)';
}
