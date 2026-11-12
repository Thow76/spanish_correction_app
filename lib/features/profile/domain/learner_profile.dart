import '../../../core/enums/language.dart';
import 'introduction_progress.dart';
import 'language_profile.dart';

/// The learner's profile (decision A2).
///
/// There is one profile per learner, shared across Spanish and Portuguese. It
/// has a shared part, the chosen interests and the introduction's progress
/// and completion, and a per-language part ([LanguageProfile]), which is
/// empty for now. It is saved on the phone as its own file,
/// `learner_profile.json`, by `FileProfileRepository`.
class LearnerProfile {
  LearnerProfile({
    List<String> interestIds = const [],
    this.introduction = const IntroductionProgress.notStarted(),
    Map<Language, LanguageProfile> languages = const {},
  }) : interestIds = List.unmodifiable(interestIds),
       languages = Map.unmodifiable(languages);

  /// A profile with nothing in it: no interests, introduction not started.
  factory LearnerProfile.empty() => LearnerProfile();

  /// The ids of the interests the learner tapped, in the order tapped, and
  /// later edited on the profile screen. Ids refer to
  /// `IntroductionContent.interests`; an id that no longer matches an
  /// interest there is kept in the file but has no label to show.
  final List<String> interestIds;

  /// Where the learner is in the introduction, and whether it is complete.
  final IntroductionProgress introduction;

  /// The per-language parts. A language with no entry has an empty part.
  final Map<Language, LanguageProfile> languages;

  bool get hasInterests => interestIds.isNotEmpty;

  bool hasInterest(String interestId) => interestIds.contains(interestId);

  /// The per-language part for [language], empty if none is stored.
  LanguageProfile languageProfile(Language language) =>
      languages[language] ?? const LanguageProfile();

  LearnerProfile copyWith({
    List<String>? interestIds,
    IntroductionProgress? introduction,
    Map<Language, LanguageProfile>? languages,
  }) {
    return LearnerProfile(
      interestIds: interestIds ?? this.interestIds,
      introduction: introduction ?? this.introduction,
      languages: languages ?? this.languages,
    );
  }

  /// Replaces the interest list. Duplicates are dropped, keeping the first.
  LearnerProfile withInterestIds(Iterable<String> ids) =>
      copyWith(interestIds: _distinct(ids));

  /// Adds an interest at the end of the list. Adding one already there
  /// changes nothing.
  LearnerProfile withInterestAdded(String interestId) => hasInterest(interestId)
      ? this
      : copyWith(interestIds: [...interestIds, interestId]);

  /// Removes an interest. Removing one not there changes nothing.
  LearnerProfile withInterestRemoved(String interestId) =>
      !hasInterest(interestId)
      ? this
      : copyWith(
          interestIds: interestIds.where((id) => id != interestId).toList(),
        );

  LearnerProfile withIntroduction(IntroductionProgress introduction) =>
      copyWith(introduction: introduction);

  LearnerProfile withLanguageProfile(
    Language language,
    LanguageProfile profile,
  ) => copyWith(languages: {...languages, language: profile});

  factory LearnerProfile.fromJson(Map<String, Object?> json) {
    final rawInterestIds = json['interest_ids'];
    final rawIntroduction = json['introduction'];
    final rawLanguages = json['languages'];

    return LearnerProfile(
      interestIds: rawInterestIds is List
          ? _distinct(rawInterestIds.whereType<String>())
          : const [],
      introduction: rawIntroduction is Map<String, Object?>
          ? IntroductionProgress.fromJson(rawIntroduction)
          : const IntroductionProgress.notStarted(),
      languages: rawLanguages is Map<String, Object?>
          ? _readLanguages(rawLanguages)
          : const {},
    );
  }

  Map<String, Object?> toJson() {
    return {
      'interest_ids': interestIds,
      'introduction': introduction.toJson(),
      'languages': {
        for (final entry in languages.entries)
          entry.key.toJson(): entry.value.toJson(),
      },
    };
  }

  static Map<Language, LanguageProfile> _readLanguages(
    Map<String, Object?> json,
  ) {
    final result = <Language, LanguageProfile>{};
    for (final language in Language.values) {
      final raw = json[language.toJson()];
      if (raw is Map<String, Object?>) {
        result[language] = LanguageProfile.fromJson(raw);
      }
    }
    return result;
  }

  static List<String> _distinct(Iterable<String> ids) {
    final seen = <String>{};
    return [
      for (final id in ids)
        if (id.isNotEmpty && seen.add(id)) id,
    ];
  }

  @override
  String toString() =>
      'LearnerProfile(interests: $interestIds, '
      'introduction complete: ${introduction.isComplete})';
}
