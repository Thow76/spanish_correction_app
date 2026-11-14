import '../../../core/enums/language.dart';

/// One of the small shared set of everyday questions that open "Try it"
/// (decision A3: "an everyday question such as '¿Qué tal estás hoy?', not
/// drawn from the chips, the same for everyone").
///
/// The opener is answered by typing. The English hint for typing is shared
/// by every opener and lives in `IntroductionContent.typingHint`.
class FriendlyOpener {
  const FriendlyOpener({
    required this.id,
    required this.language,
    required this.text,
  });

  final String id;
  final Language language;

  /// The question as shown to the learner, in the target language.
  final String text;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FriendlyOpener && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FriendlyOpener($id)';
}
