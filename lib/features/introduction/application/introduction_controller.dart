import 'package:flutter/foundation.dart';

import '../../../core/enums/language.dart';
import '../../profile/application/profile_repository.dart';
import '../../profile/domain/introduction_progress.dart';
import '../../profile/domain/learner_profile.dart';
import '../content/fuller_question.dart';
import '../content/interest.dart';
import '../content/introduction_content.dart';
import '../content/warm_up_question.dart';
import '../domain/introduction_step.dart';

/// Where "Stop for now" sends the learner (build plan task 1.3).
enum StopOutcome {
  /// At least one fuller answer exists, so the end screen is shown first.
  endScreen,

  /// Nothing fuller has been answered yet: straight to the app. Progress is
  /// kept, so the introduction resumes here on the next launch.
  app,
}

/// Runs the introduction (decision A1) on top of the saved profile.
///
/// It works out which [IntroductionStep] to show from the progress in the
/// profile file, records each answer there as it happens, and draws the
/// fuller questions once the chips are passed. Every change is saved at
/// once, so "Stop for now" (or the app being closed) loses nothing and the
/// introduction resumes where it stopped.
///
/// Warm-up answers get no feedback and are not kept (decision A1). Fuller
/// answers are recorded as answered; sending them for feedback is task 1.4,
/// which hooks in at [answerFullerQuestion].
class IntroductionController extends ChangeNotifier {
  IntroductionController({
    required ProfileRepository profileRepository,
    required this.language,
    DateTime Function()? now,
  }) : _profileRepository = profileRepository,
       _now = now ?? DateTime.now;

  static const String interestsStepId = 'interests';
  static const String endScreenStepId = 'end';

  final ProfileRepository _profileRepository;
  final Language language;
  final DateTime Function() _now;

  LearnerProfile? _profile;
  bool _stoppedEarly = false;
  bool _disposed = false;

  /// Whether the introduction has any content for [language]. In slice 1
  /// only Spanish has (decision F1); a Portuguese learner goes straight to
  /// the app.
  static bool canRunFor(Language language) =>
      IntroductionContent.hasContentFor(language);

  /// Whether [profile] still needs the introduction in [language]: it has
  /// content for that language and has not been completed on this install.
  static bool isNeeded(LearnerProfile profile, Language language) =>
      canRunFor(language) && !profile.introduction.isComplete;

  bool get isLoaded => _profile != null;

  /// The profile as last read or saved. Null until [load] has run.
  LearnerProfile? get profile => _profile;

  List<WarmUpQuestion> get warmUps =>
      IntroductionContent.warmUpQuestionsFor(language);

  /// The chips to show, in content order.
  List<Interest> get interests => IntroductionContent.interests;

  /// The ids of the chips the learner has tapped, in the order tapped.
  List<String> get chosenInterestIds => _profile?.interestIds ?? const [];

  bool isInterestChosen(String interestId) =>
      chosenInterestIds.contains(interestId);

  /// The questions drawn for this learner, in the order asked.
  List<FullerQuestion> get fullerQuestions {
    final progress = _profile?.introduction;
    if (progress == null) {
      return const [];
    }
    return [
      for (final id in progress.fullerQuestionIds)
        ?IntroductionContent.fullerQuestionById(id),
    ];
  }

  /// Whether the learner has answered at least one fuller question.
  bool get hasFullerAnswer => _profile?.introduction.hasFullerAnswer ?? false;

  /// The step to show now. Null before [load], and null once the
  /// introduction is complete.
  IntroductionStep? get step {
    final profile = _profile;
    if (profile == null) {
      return null;
    }
    final progress = profile.introduction;
    if (progress.isComplete) {
      return null;
    }
    if (_stoppedEarly) {
      return _endScreenStep;
    }

    switch (progress.stageFor(warmUpCount: warmUps.length)) {
      case IntroductionStage.warmUps:
        return _nextWarmUpStep(progress);
      case IntroductionStage.interests:
        return _interestsStep;
      case IntroductionStage.fullerQuestions:
        return _nextFullerQuestionStep(progress) ?? _endScreenStep;
      case IntroductionStage.endScreen:
        return _endScreenStep;
      case IntroductionStage.complete:
        return null;
    }
  }

  /// Reads the profile and records that the introduction has started in
  /// [language]. Safe to call again; a second call only re-reads.
  Future<void> load() async {
    final profile = await _profileRepository.getProfile();
    if (profile.introduction.language == null &&
        !profile.introduction.isComplete) {
      await _save(
        profile.withIntroduction(profile.introduction.started(language)),
      );
    } else {
      _profile = profile;
      _notify();
    }
  }

  /// Records the current warm-up as answered. The answer itself is not kept
  /// (decision A1: no feedback on warm-ups). Returns false and changes
  /// nothing if [answer] is blank or the current step is not a warm-up.
  Future<bool> answerWarmUp(String answer) async {
    final profile = _profile;
    final current = step;
    if (profile == null ||
        current == null ||
        !current.isWarmUp ||
        answer.trim().isEmpty) {
      return false;
    }
    await _save(
      profile.withIntroduction(
        profile.introduction.withWarmUpAnswered(current.id),
      ),
    );
    return true;
  }

  /// Adds or removes a chip. The choice is saved at once, so a learner who
  /// stops on the chips step finds their taps kept when they come back.
  Future<void> toggleInterest(String interestId) async {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    await _save(
      profile.hasInterest(interestId)
          ? profile.withInterestRemoved(interestId)
          : profile.withInterestAdded(interestId),
    );
  }

  /// Leaves the chips step and draws the fuller questions from the chosen
  /// chips. With no chip tapped the questions are drawn from every interest
  /// (decision A1 as read in task 1.1), so the step is passed either way.
  Future<void> continueFromInterests() async {
    final profile = _profile;
    final current = step;
    if (profile == null || current == null || !current.isInterests) {
      return;
    }
    final drawn = IntroductionContent.drawFullerQuestions(
      chosenInterestIds: profile.interestIds,
      language: language,
    );
    await _save(
      profile.withIntroduction(
        profile.introduction.withInterestsChosen(
          fullerQuestionIds: [for (final question in drawn) question.id],
        ),
      ),
    );
  }

  /// Records the current fuller question as answered. Returns false and
  /// changes nothing if [answer] is blank or the current step is not a
  /// fuller question.
  ///
  /// Task 1.4 sends [answer] for feedback in the background from here and
  /// stores the History entry's id on the [FullerAnswer].
  Future<bool> answerFullerQuestion(String answer) async {
    final profile = _profile;
    final current = step;
    if (profile == null ||
        current == null ||
        !current.isFullerQuestion ||
        answer.trim().isEmpty) {
      return false;
    }
    await _save(
      profile.withIntroduction(
        profile.introduction.withFullerAnswer(
          FullerAnswer(questionId: current.id),
        ),
      ),
    );
    return true;
  }

  /// "Stop for now". Progress is already saved, so this only decides where
  /// the learner goes: the end screen if at least one fuller answer exists,
  /// otherwise the app.
  StopOutcome stopForNow() {
    if (hasFullerAnswer) {
      _stoppedEarly = true;
      _notify();
      return StopOutcome.endScreen;
    }
    return StopOutcome.app;
  }

  /// Leaves the end screen. The introduction is marked complete and never
  /// shows again on this install, including after a language switch
  /// (decision A2).
  Future<void> finish() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }
    await _save(
      profile.withIntroduction(profile.introduction.completed(_now())),
    );
  }

  IntroductionStep? _nextWarmUpStep(IntroductionProgress progress) {
    final warmUps = this.warmUps;
    for (var index = 0; index < warmUps.length; index++) {
      final warmUp = warmUps[index];
      if (!progress.hasAnsweredWarmUp(warmUp.id)) {
        return IntroductionStep(
          kind: IntroductionStepKind.warmUp,
          id: warmUp.id,
          text: warmUp.text,
          hint: warmUp.hint,
          answerMode: switch (warmUp.input) {
            WarmUpInput.typed => AnswerMode.typed,
            WarmUpInput.spoken => AnswerMode.spoken,
          },
          number: index + 1,
          count: warmUps.length,
        );
      }
    }
    return null;
  }

  IntroductionStep get _interestsStep => IntroductionStep(
    kind: IntroductionStepKind.interests,
    id: interestsStepId,
    text:
        IntroductionContent.interestsQuestionFor(language) ??
        IntroductionContent.interestsQuestion,
    hint: IntroductionContent.interestsHint,
    answerMode: AnswerMode.chips,
  );

  /// The first drawn question without an answer. An id that no longer
  /// matches a question (the content was changed since it was drawn) is
  /// passed over.
  IntroductionStep? _nextFullerQuestionStep(IntroductionProgress progress) {
    final questions = fullerQuestions;
    for (var index = 0; index < questions.length; index++) {
      final question = questions[index];
      if (!progress.hasAnsweredFullerQuestion(question.id)) {
        return IntroductionStep(
          kind: IntroductionStepKind.fullerQuestion,
          id: question.id,
          text: question.text,
          answerMode: AnswerMode.typedOrSpoken,
          number: index + 1,
          count: questions.length,
        );
      }
    }
    return null;
  }

  IntroductionStep get _endScreenStep => IntroductionStep(
    kind: IntroductionStepKind.endScreen,
    id: endScreenStepId,
    text:
        IntroductionContent.endScreenLineFor(language) ??
        IntroductionContent.endScreenLine,
    answerMode: AnswerMode.none,
  );

  Future<void> _save(LearnerProfile profile) async {
    await _profileRepository.saveProfile(profile);
    _profile = profile;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
