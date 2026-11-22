import 'package:flutter/foundation.dart';

import '../../../core/enums/language.dart';
import '../../corrections/domain/correction_input_mode.dart';
import '../../corrections/domain/correction_item.dart';
import '../../history/domain/correction_submission.dart';
import '../../profile/application/profile_repository.dart';
import '../../profile/domain/introduction_progress.dart';
import '../../profile/domain/learner_profile.dart';
import '../content/friendly_opener.dart';
import '../content/interest.dart';
import '../content/interest_question.dart';
import '../content/introduction_content.dart';
import '../content/introduction_step_kind.dart';
import '../content/recommendation_item.dart';
import '../content/show_me_demo.dart';
import 'introduction_feedback.dart';
import 'introduction_step.dart';

/// Where "Stop for now" takes the learner (task 1.3).
enum StopDestination {
  /// At least one answer exists, so the end screen comes next.
  endScreen,

  /// No answer yet, so the learner goes straight to the app. The
  /// introduction resumes from the same step on the next launch.
  app,
}

/// The two steps the learner answers, whose answers are sent for feedback.
/// The opener is typed and the interest question is spoken (decision A3),
/// which the check is told, so the spoken answer gets no Spelling items
/// (build step 2.3).
enum _AnsweredStep {
  opener(CorrectionInputMode.typed),
  interestQuestion(CorrectionInputMode.spoken);

  const _AnsweredStep(this.inputMode);

  final CorrectionInputMode inputMode;
}

/// Runs the introduction (decisions A1, A2 and A3; build plan task 1.3).
///
/// It reads the learner's profile, works out which step to show from the
/// saved progress, and saves the profile after every step, so that "Stop for
/// now", closing the app, or "Open now" taking the learner out of the app all
/// resume at the same place. The words come from [IntroductionContent]; the
/// chips each step uses are recorded on the profile when the step is first
/// shown, so a resumed introduction asks the same questions.
///
/// The two answers are sent for feedback in the background through
/// [IntroductionFeedback] as soon as they are given, so they land in History
/// whatever the learner does next (task 1.4). With no [IntroductionFeedback]
/// nothing is sent.
class IntroductionController extends ChangeNotifier {
  IntroductionController({
    required ProfileRepository repository,
    required this.language,
    IntroductionFeedback? feedback,
    DateTime Function()? clock,
  }) : _repository = repository,
       _feedback = feedback,
       _clock = clock ?? DateTime.now;

  final ProfileRepository _repository;
  final IntroductionFeedback? _feedback;
  final Language language;
  final DateTime Function() _clock;

  /// Answers being sent for feedback now.
  final Map<_AnsweredStep, Future<void>> _sending = {};

  /// Answers whose send failed, kept so "See suggestions" can try once more.
  /// Kept in memory only: after a relaunch an unsent answer is not sent.
  final Map<_AnsweredStep, String> _unsent = {};

  /// History entries received this session, by id.
  final Map<String, CorrectionSubmission> _received = {};

  LearnerProfile _profile = LearnerProfile.empty();
  List<String> _selectedInterestIds = const [];
  bool _isLoaded = false;
  bool _stoppedToEndScreen = false;
  Future<void> _pendingSave = Future.value();

  bool get isLoaded => _isLoaded;

  LearnerProfile get profile => _profile;

  IntroductionProgress get progress => _profile.introduction;

  /// The step to show now.
  IntroductionStage get stage {
    final next = progress.nextStage;
    if (_stoppedToEndScreen && next != IntroductionStage.complete) {
      return IntroductionStage.endScreen;
    }
    return next;
  }

  /// Reads the profile, records that the introduction has started in
  /// [language], and gets the first step ready.
  Future<void> load() async {
    _profile = await _repository.getProfile();
    _profile = _profile.withIntroduction(progress.started(language));
    _selectedInterestIds = List.of(_profile.interestIds);
    _prepareStage();
    _isLoaded = true;
    notifyListeners();
    await _save();
  }

  // ---------------------------------------------------------------------------
  // The step as shown
  // ---------------------------------------------------------------------------

  /// The current step's label, question, hint and answer mode.
  IntroductionStep get currentStep => switch (stage) {
    IntroductionStage.interests => const IntroductionStep(
      mode: IntroductionAnswerMode.chips,
      label: IntroductionContent.interestsLabel,
      questionText: IntroductionContent.interestsQuestion,
      hint: IntroductionContent.interestsHint,
    ),
    IntroductionStage.choice => const IntroductionStep(
      mode: IntroductionAnswerMode.choice,
      label: IntroductionContent.choiceLabel,
      questionText: IntroductionContent.choiceQuestion,
    ),
    IntroductionStage.friendlyOpener => IntroductionStep(
      mode: IntroductionAnswerMode.type,
      label: IntroductionStepKind.friendlyOpener.label,
      questionText: currentOpener?.text,
      hint: IntroductionContent.typingHint,
    ),
    IntroductionStage.interestQuestion => IntroductionStep(
      mode: IntroductionAnswerMode.microphone,
      label: IntroductionStepKind.somethingYoureInto.label,
      questionText: currentInterestQuestion?.text,
      hint: IntroductionContent.speakingHint,
    ),
    IntroductionStage.recommendation => IntroductionStep(
      mode: IntroductionAnswerMode.recommendationCard,
      label: IntroductionStepKind.recommendation.label,
      questionText: currentRecommendation?.title,
      hint: IntroductionContent.recommendationHint,
    ),
    IntroductionStage.showMeDemo => IntroductionStep(
      mode: IntroductionAnswerMode.demo,
      label: IntroductionStepKind.friendlyOpener.label,
      questionText: currentOpenerForWalkthrough?.text,
    ),
    IntroductionStage.endScreen ||
    IntroductionStage.complete => IntroductionStep(
      mode: IntroductionAnswerMode.end,
      label: IntroductionContent.endLabel,
      questionText: endScreenLine,
    ),
  };

  /// The interests offered as chips.
  List<Interest> get interests => IntroductionContent.interests;

  /// The chips tapped on the chips step so far, in the order tapped.
  List<String> get selectedInterestIds =>
      List.unmodifiable(_selectedInterestIds);

  bool isSelected(String interestId) =>
      _selectedInterestIds.contains(interestId);

  /// Whether the chips step can be passed: one to five chips tapped.
  bool get canConfirmInterests =>
      _selectedInterestIds.length >= IntroductionContent.minimumChips &&
      _selectedInterestIds.length <= IntroductionContent.maximumChips;

  /// The friendly opener being asked, or null when none is recorded.
  FriendlyOpener? get currentOpener {
    final id = progress.opener?.contentId;
    return id == null ? null : IntroductionContent.friendlyOpenerById(id);
  }

  /// The interest question being asked, or null when none is recorded.
  InterestQuestion? get currentInterestQuestion {
    final id = progress.interestQuestion?.contentId;
    return id == null ? null : IntroductionContent.interestQuestionById(id);
  }

  /// The chip the interest question is about.
  Interest? get currentQuestionInterest {
    final id = progress.interestQuestion?.interestId;
    return id == null ? null : IntroductionContent.interestById(id);
  }

  /// The recommendation card being shown, or null when none is recorded.
  RecommendationItem? get currentRecommendation {
    final id = progress.recommendation?.interestId;
    if (id == null) {
      return null;
    }
    final items = IntroductionContent.recommendationsForInterest(id, language);
    return items.isEmpty ? null : items.first;
  }

  /// The chip the recommendation card is linked to.
  Interest? get currentRecommendationInterest {
    final id = progress.recommendation?.interestId;
    return id == null ? null : IntroductionContent.interestById(id);
  }

  /// The Show me demo being played, or null when none is recorded.
  ShowMeDemo? get currentDemo {
    final id = progress.demo?.interestId;
    return id == null
        ? null
        : IntroductionContent.demoForInterest(id, language);
  }

  /// The chip the Show me demo plays on.
  Interest? get currentDemoInterest {
    final id = progress.demo?.interestId;
    return id == null ? null : IntroductionContent.interestById(id);
  }

  /// The friendly opener the walk-through shows, with its sample answer:
  /// the first in the list, the same one "Start now" asks.
  FriendlyOpener? get currentOpenerForWalkthrough {
    final openers = IntroductionContent.friendlyOpenersFor(language);
    return openers.isEmpty ? null : openers.first;
  }

  /// The recommendation card the walk-through shows: the one the learner's
  /// own card will show later, picked from the chips the same way.
  RecommendationItem? get walkthroughRecommendation =>
      IntroductionContent.pickForChips(
        chosenInterestIds: _profile.interestIds,
        language: language,
      )?.recommendation;

  /// The "Read" example on the walk-through's recommendation screen: the
  /// learner's own recommendation when it is an article, otherwise the first
  /// article written for the language.
  RecommendationItem? get walkthroughReadExample {
    final own = walkthroughRecommendation;
    if (own != null && own.type == RecommendationType.article) {
      return own;
    }
    for (final item in IntroductionContent.recommendationsFor(language)) {
      if (item.type == RecommendationType.article) {
        return item;
      }
    }
    return own;
  }

  /// The closing line on the end screen.
  String get endScreenLine =>
      IntroductionContent.endScreenLineFor(language) ??
      IntroductionContent.endScreenLine;

  // ---------------------------------------------------------------------------
  // What the learner does
  // ---------------------------------------------------------------------------

  /// Taps or untaps a chip. Tapping a sixth chip changes nothing and returns
  /// false, so the screen can say five is the most.
  bool toggleInterest(String interestId) {
    if (isSelected(interestId)) {
      _selectedInterestIds = [
        for (final id in _selectedInterestIds)
          if (id != interestId) id,
      ];
      notifyListeners();
      return true;
    }
    if (_selectedInterestIds.length >= IntroductionContent.maximumChips) {
      return false;
    }
    _selectedInterestIds = [..._selectedInterestIds, interestId];
    notifyListeners();
    return true;
  }

  /// Passes the chips step: the tapped chips become the profile's interests.
  Future<void> confirmInterests() async {
    if (!canConfirmInterests) {
      return;
    }
    _profile = _profile
        .withInterestIds(_selectedInterestIds)
        .withIntroduction(progress.withInterestsChosen());
    await _advance();
  }

  /// Records the choice of Try it or Show me.
  Future<void> choose(IntroductionChoice choice) async {
    _update(progress.withChoice(choice));
    await _advance();
  }

  /// Records that the friendly opener has been answered with [answer], and
  /// sends the answer for feedback in the background (task 1.4).
  Future<void> answerOpener(String answer) async {
    _update(progress.withOpenerAnswered());
    _startSending(_AnsweredStep.opener, answer);
    await _advance();
  }

  /// Records that the interest question has been answered with [answer], and
  /// sends the answer for feedback in the background (task 1.4).
  Future<void> answerInterestQuestion(String answer) async {
    _update(progress.withInterestQuestionAnswered());
    _startSending(_AnsweredStep.interestQuestion, answer);
    await _advance();
  }

  /// Records "Open now" on the recommendation card and returns the item, so
  /// the screen can open its link. The choice is saved before the link is
  /// opened, so coming back to the app, or relaunching it, carries on at the
  /// next step.
  Future<RecommendationItem?> openRecommendation() async {
    final item = currentRecommendation;
    _update(progress.withRecommendationOpened());
    await _advance();
    return item;
  }

  /// Records "Skip" on the recommendation card.
  Future<void> skipRecommendation() async {
    _update(progress.withRecommendationSkipped());
    await _advance();
  }

  /// Records that the "Show me how it works" walk-through has been watched.
  /// The learner's own Try it steps come next (decision A4).
  Future<void> finishDemo() async {
    _update(progress.withDemoWatched());
    await _advance();
  }

  /// "Stop for now". With an answer, the end screen comes next; without one,
  /// the learner goes to the app and the introduction resumes on the next
  /// launch. Chips tapped on the chips step are kept either way.
  Future<StopDestination> stopForNow() async {
    if (stage == IntroductionStage.interests) {
      _profile = _profile.withInterestIds(_selectedInterestIds);
    }
    if (progress.hasAnswer) {
      _stoppedToEndScreen = true;
      notifyListeners();
      await _save();
      return StopDestination.endScreen;
    }
    await _save();
    return StopDestination.app;
  }

  /// The History entries for "See suggestions" on the end screen, opener
  /// first (task 1.4). It waits for any answer still being sent, and tries
  /// once more any answer whose send failed this session. An answer that
  /// could not be sent, or whose History card is gone, is left out, so the
  /// list can be empty.
  Future<List<CorrectionSubmission>> suggestionsToShow() async {
    final feedback = _feedback;
    if (feedback == null) {
      return const [];
    }
    await Future.wait(_sending.values);
    for (final MapEntry(key: step, value: answer) in Map.of(_unsent).entries) {
      _startSending(step, answer);
    }
    await Future.wait(_sending.values);

    final submissions = <CorrectionSubmission>[];
    for (final answer in progress.answers) {
      final id = answer.submissionId;
      if (id == null) {
        continue;
      }
      final submission = _received[id] ?? await feedback.find(id, language);
      if (submission != null) {
        submissions.add(submission);
      }
    }
    return submissions;
  }

  /// Saves one point from the suggestions into Saved, through the existing
  /// save path. Moving on without saving is ignoring it (decisions C5, A4).
  Future<void> savePoint(
    CorrectionItem point,
    CorrectionSubmission from,
  ) async {
    await _feedback?.save(point, from);
  }

  /// Finishes the introduction from the end screen. It will not show again
  /// on this install, including after a language switch.
  Future<void> finish() async {
    _update(progress.completed(_clock()));
    notifyListeners();
    await _save();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _startSending(_AnsweredStep step, String answer) {
    final feedback = _feedback;
    if (feedback == null || answer.trim().isEmpty) {
      return;
    }
    _unsent.remove(step);
    _sending[step] = _send(feedback, step, answer);
  }

  /// Sends one answer and records its History entry id on the profile. A
  /// failure is kept for one more try from "See suggestions".
  Future<void> _send(
    IntroductionFeedback feedback,
    _AnsweredStep step,
    String answer,
  ) async {
    try {
      final submission = await feedback.send(
        answer,
        language,
        inputMode: step.inputMode,
      );
      _received[submission.id] = submission;
      _update(switch (step) {
        _AnsweredStep.opener => progress.withOpenerAnswered(
          submissionId: submission.id,
        ),
        _AnsweredStep.interestQuestion => progress.withInterestQuestionAnswered(
          submissionId: submission.id,
        ),
      });
      await _save();
    } catch (error) {
      debugPrint('The introduction could not send an answer: $error');
      _unsent[step] = answer;
    }
  }

  void _update(IntroductionProgress next) {
    _profile = _profile.withIntroduction(next);
  }

  Future<void> _advance() async {
    _prepareStage();
    notifyListeners();
    await _save();
  }

  /// Records the content for the step about to be shown, the first time it
  /// is shown: which opener, which chip and question, which chip the card or
  /// the demo is for.
  void _prepareStage() {
    final picks = IntroductionContent.pickForChips(
      chosenInterestIds: _profile.interestIds,
      language: language,
    );
    switch (progress.nextStage) {
      case IntroductionStage.friendlyOpener:
        final openers = IntroductionContent.friendlyOpenersFor(language);
        if (progress.opener == null && openers.isNotEmpty) {
          _update(progress.withOpenerShown(openers.first.id));
        }
      case IntroductionStage.interestQuestion:
        if (progress.interestQuestion == null && picks != null) {
          _update(
            progress.withInterestQuestionShown(
              interestId: picks.questionInterestId,
              questionId: picks.interestQuestion.id,
            ),
          );
        }
      case IntroductionStage.recommendation:
        if (progress.recommendation == null && picks != null) {
          _update(
            progress.withRecommendationShown(picks.recommendationInterestId),
          );
        }
      case IntroductionStage.showMeDemo:
        if (progress.demo == null && picks != null) {
          _update(progress.withDemoShown(picks.demoInterestId));
        }
      case IntroductionStage.interests ||
          IntroductionStage.choice ||
          IntroductionStage.endScreen ||
          IntroductionStage.complete:
        break;
    }
  }

  /// Saves the profile as it is now. Saves run one after another, so a
  /// later save never lands before an earlier one.
  Future<void> _save() {
    final snapshot = _profile;
    _pendingSave = _pendingSave
        .then((_) => _repository.saveProfile(snapshot))
        .catchError((Object error) {
          debugPrint('The introduction could not save the profile: $error');
        });
    return _pendingSave;
  }
}
