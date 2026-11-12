/// The part of the profile that belongs to one language (decision A2, point
/// 6): material about the language being learnt is kept per language.
///
/// Empty for now. The scrapbook, goals and specifics will live here when they
/// are built; adding them is a change to this class only. The file format
/// already has a place for it (`languages.spanish`, `languages.portuguese`)
/// so that older profile files keep reading when fields are added.
class LanguageProfile {
  const LanguageProfile();

  factory LanguageProfile.fromJson(Map<String, Object?> json) {
    // No fields yet; the map is accepted so that an older or newer file
    // still reads.
    return const LanguageProfile();
  }

  Map<String, Object?> toJson() => const {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LanguageProfile;

  @override
  int get hashCode => (LanguageProfile).hashCode;

  @override
  String toString() => 'LanguageProfile()';
}
