import '../../../core/enums/language.dart';

/// One interest the learner can tap in the introduction (decision A1) and see
/// listed on the profile screen (decision A2).
///
/// The [id] is language-neutral and is what the profile stores. The chips in
/// the introduction show the label in the target language; the profile screen
/// shows [english].
class Interest {
  const Interest({
    required this.id,
    required this.english,
    required this.spanish,
    required this.portuguese,
  });

  final String id;
  final String english;
  final String spanish;
  final String portuguese;

  /// The chip label for the language being learnt.
  String labelFor(Language language) => switch (language) {
    Language.spanish => spanish,
    Language.portuguese => portuguese,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Interest && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Interest($id)';
}
