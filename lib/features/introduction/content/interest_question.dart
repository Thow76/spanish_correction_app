import '../../../core/enums/language.dart';

/// A question about one of the learner's chips: the "Something you're into"
/// step of "Try it" (decision A3: "the app takes one chip they tapped and
/// asks about it", for football "¿Qué equipo sigues?").
///
/// The question is answered by speaking. The English hint for speaking is
/// shared by every question and lives in `IntroductionContent.speakingHint`.
/// Each interest has at least one question per language; in slice 1 only
/// Spanish questions exist.
class InterestQuestion {
  const InterestQuestion({
    required this.id,
    required this.interestId,
    required this.language,
    required this.text,
  });

  final String id;
  final String interestId;
  final Language language;

  /// The question as shown to the learner, in the target language.
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is InterestQuestion && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InterestQuestion($id)';
}
