import '../../../core/enums/language.dart';

/// Where the learner is in the introduction (decisions A2 and A3).
///
/// "Stop for now" is on every step of the introduction, and the profile file
/// keeps this record so the introduction can resume where it stopped,
/// including after "Open now" on the recommendation card takes the learner
/// out of the app. Once [IntroductionProgress.isComplete] is true the
/// introduction never shows again on this install, including after a
/// language switch (decision A2, point 3).
enum IntroductionStage {
  /// The interest chips in the target language, one to five of them.
  interests,

  /// The choice between "Try it" and "Show me".
  choice,

  /// Try it, step one: the friendly opener, answered by typing.
  friendlyOpener,

  /// Try it, step two: a question about one of the chosen chips, answered by
  /// speaking.
  interestQuestion,

  /// Try it, step three: the recommendation card for one of the chosen
  /// chips, with Open now or Skip and nothing to answer.
  recommendation,

  /// "Show me how it works": the guided walk-through on one of the chosen
  /// chips, played before the Try it steps (decision A4).
  showMeDemo,

  /// The end screen: "See suggestions" or "Not now".
  endScreen,

  /// The introduction has been finished and will not show again.
  complete,
}

/// What the learner chose after the chips (decisions A3 and A4): "Start now"
/// ([tryIt]) goes straight to the three steps; "Show me how it works"
/// ([showMe]) plays the walk-through first, then the same three steps.
enum IntroductionChoice {
  tryIt,
  showMe;

  String toJson() => switch (this) {
    IntroductionChoice.tryIt => 'try_it',
    IntroductionChoice.showMe => 'show_me',
  };

  static IntroductionChoice? fromJson(Object? value) => switch (value) {
    'try_it' => IntroductionChoice.tryIt,
    'show_me' => IntroductionChoice.showMe,
    _ => null,
  };
}

/// What the learner did with the recommendation card.
enum RecommendationOutcome {
  /// "Open now": the link was opened outside the app.
  opened,

  /// "Skip": the learner moved on without opening it.
  skipped;

  String toJson() => switch (this) {
    RecommendationOutcome.opened => 'opened',
    RecommendationOutcome.skipped => 'skipped',
  };

  static RecommendationOutcome? fromJson(Object? value) => switch (value) {
    'opened' => RecommendationOutcome.opened,
    'skipped' => RecommendationOutcome.skipped,
    _ => null,
  };
}

/// A step the learner answers: the friendly opener or the interest question.
///
/// [contentId] is the id of the opener or question that was shown, kept so
/// that resuming shows the same one rather than a fresh one. [interestId] is
/// the chip the question was about; it is null for the opener, which is not
/// drawn from the chips. [submissionId] is the id of the History entry the
/// answer was sent to for feedback (task 1.4). It is null while the answer
/// has not been sent, for example when the send failed or has not happened
/// yet, so [isAnswered] is recorded on its own.
class StepAnswer {
  const StepAnswer({
    required this.contentId,
    this.interestId,
    this.isAnswered = false,
    this.submissionId,
  });

  final String contentId;
  final String? interestId;
  final bool isAnswered;
  final String? submissionId;

  /// The same step marked answered. A [submissionId] that is null keeps the
  /// one already recorded, so the id can be added once the send is done.
  StepAnswer answered({String? submissionId}) => StepAnswer(
    contentId: contentId,
    interestId: interestId,
    isAnswered: true,
    submissionId: submissionId ?? this.submissionId,
  );

  factory StepAnswer.fromJson(Map<String, Object?> json) {
    final rawContentId = json['content_id'];
    final rawInterestId = json['interest_id'];
    final rawSubmissionId = json['submission_id'];
    final rawIsAnswered = json['is_answered'];
    return StepAnswer(
      contentId: rawContentId is String ? rawContentId : '',
      interestId: rawInterestId is String ? rawInterestId : null,
      isAnswered: rawIsAnswered is bool && rawIsAnswered,
      submissionId: rawSubmissionId is String ? rawSubmissionId : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'content_id': contentId,
      'interest_id': interestId,
      'is_answered': isAnswered,
      'submission_id': submissionId,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepAnswer &&
          other.contentId == contentId &&
          other.interestId == interestId &&
          other.isAnswered == isAnswered &&
          other.submissionId == submissionId;

  @override
  int get hashCode =>
      Object.hash(contentId, interestId, isAnswered, submissionId);

  @override
  String toString() =>
      'StepAnswer($contentId, interest: $interestId, '
      'answered: $isAnswered, submission: $submissionId)';
}

/// The recommendation card step: which chip it was linked to and what the
/// learner did with it. [outcome] is null while the card is showing and
/// nothing has been chosen yet.
class RecommendationStep {
  const RecommendationStep({required this.interestId, this.outcome});

  final String interestId;
  final RecommendationOutcome? outcome;

  bool get isDone => outcome != null;

  RecommendationStep withOutcome(RecommendationOutcome outcome) =>
      RecommendationStep(interestId: interestId, outcome: outcome);

  factory RecommendationStep.fromJson(Map<String, Object?> json) {
    final rawInterestId = json['interest_id'];
    return RecommendationStep(
      interestId: rawInterestId is String ? rawInterestId : '',
      outcome: RecommendationOutcome.fromJson(json['outcome']),
    );
  }

  Map<String, Object?> toJson() {
    return {'interest_id': interestId, 'outcome': outcome?.toJson()};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendationStep &&
          other.interestId == interestId &&
          other.outcome == outcome;

  @override
  int get hashCode => Object.hash(interestId, outcome);

  @override
  String toString() => 'RecommendationStep($interestId, $outcome)';
}

/// The "Show me" demo: which chip it plays on and whether it has been
/// watched to the end.
class DemoStep {
  const DemoStep({required this.interestId, this.isWatched = false});

  final String interestId;
  final bool isWatched;

  DemoStep watched() => DemoStep(interestId: interestId, isWatched: true);

  factory DemoStep.fromJson(Map<String, Object?> json) {
    final rawInterestId = json['interest_id'];
    final rawIsWatched = json['is_watched'];
    return DemoStep(
      interestId: rawInterestId is String ? rawInterestId : '',
      isWatched: rawIsWatched is bool && rawIsWatched,
    );
  }

  Map<String, Object?> toJson() {
    return {'interest_id': interestId, 'is_watched': isWatched};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DemoStep &&
          other.interestId == interestId &&
          other.isWatched == isWatched;

  @override
  int get hashCode => Object.hash(interestId, isWatched);

  @override
  String toString() => 'DemoStep($interestId, watched: $isWatched)';
}

/// The learner's progress through the introduction (decision A3).
///
/// Everything here is what "Stop for now" needs to bring the learner back to
/// the same place: whether the chips have been passed, the choice made (Try
/// it or Show me), which opener and which interest question were shown and
/// whether each has been answered (with the History entry id once sent),
/// which chip the recommendation card was for and whether it was opened or
/// skipped, whether the demo has been watched, and whether the introduction
/// is complete. The chosen interests themselves live on the profile, not
/// here, because they outlive the introduction.
///
/// The chips each step uses are recorded as they are shown, so that a
/// resumed introduction carries on with the same chips even if the interest
/// list has been edited in between (the picks come from
/// `IntroductionContent.pickForChips` when a step is first shown).
class IntroductionProgress {
  const IntroductionProgress({
    this.language,
    this.interestsChosen = false,
    this.choice,
    this.opener,
    this.interestQuestion,
    this.recommendation,
    this.demo,
    this.isComplete = false,
    this.completedAt,
  });

  /// Nothing started yet.
  const IntroductionProgress.notStarted()
    : language = null,
      interestsChosen = false,
      choice = null,
      opener = null,
      interestQuestion = null,
      recommendation = null,
      demo = null,
      isComplete = false,
      completedAt = null;

  /// The language the introduction was run in, set when it starts. Null
  /// until then. There is one introduction per learner (decision A2), so this
  /// is recorded once.
  final Language? language;

  /// Whether the learner has passed the interest chips step. The chips
  /// themselves are on the profile; this says the step is behind them.
  final bool interestsChosen;

  /// Try it or Show me. Null until the learner has chosen.
  final IntroductionChoice? choice;

  /// The friendly opener shown, and whether it has been answered. Null until
  /// the opener step is first shown.
  final StepAnswer? opener;

  /// The interest question shown (with its chip), and whether it has been
  /// answered. Null until the question step is first shown.
  final StepAnswer? interestQuestion;

  /// The recommendation card shown (with its chip), and whether it was
  /// opened or skipped. Null until the card is first shown.
  final RecommendationStep? recommendation;

  /// The Show me demo (with its chip), and whether it has been watched. Null
  /// until the demo is first shown.
  final DemoStep? demo;

  /// True once the introduction has been finished (or stopped at the end
  /// screen). It is then skipped on every launch and every language switch.
  final bool isComplete;

  final DateTime? completedAt;

  /// Whether the learner has started the introduction at all.
  bool get hasStarted =>
      language != null ||
      interestsChosen ||
      choice != null ||
      opener != null ||
      interestQuestion != null ||
      recommendation != null ||
      demo != null ||
      isComplete;

  bool get hasAnsweredOpener => opener?.isAnswered ?? false;

  bool get hasAnsweredInterestQuestion => interestQuestion?.isAnswered ?? false;

  /// Whether at least one answer exists (the opener's or the interest
  /// question's). "Stop for now" goes to the end screen when this is true and
  /// straight to the app when it is false (build plan task 1.3).
  bool get hasAnswer => hasAnsweredOpener || hasAnsweredInterestQuestion;

  /// The answers given so far, opener first, for the end screen's walk
  /// through their suggestions (task 1.4).
  List<StepAnswer> get answers => [
    if (hasAnsweredOpener) opener!,
    if (hasAnsweredInterestQuestion) interestQuestion!,
  ];

  /// Whether the recommendation card has been opened or skipped.
  bool get hasDecidedRecommendation => recommendation?.isDone ?? false;

  /// Whether the Show me demo has been watched to the end.
  bool get hasWatchedDemo => demo?.isWatched ?? false;

  /// Whether every step of the chosen path is behind the learner, so the
  /// end screen is next.
  bool get hasFinishedChosenPath => switch (choice) {
    IntroductionChoice.tryIt => _hasFinishedTryItSteps,
    IntroductionChoice.showMe => hasWatchedDemo && _hasFinishedTryItSteps,
    null => false,
  };

  bool get _hasFinishedTryItSteps =>
      hasAnsweredOpener &&
      hasAnsweredInterestQuestion &&
      hasDecidedRecommendation;

  /// The step the introduction should show next when it resumes.
  ///
  /// "Start now" (Try it) goes straight to the opener, the interest question
  /// and the recommendation card. "Show me how it works" plays the walk-
  /// through first, then the same three steps (decision A4), so every
  /// learner answers the two questions.
  IntroductionStage get nextStage {
    if (isComplete) {
      return IntroductionStage.complete;
    }
    if (!interestsChosen) {
      return IntroductionStage.interests;
    }
    if (choice == null) {
      return IntroductionStage.choice;
    }
    if (choice == IntroductionChoice.showMe && !hasWatchedDemo) {
      return IntroductionStage.showMeDemo;
    }
    if (!hasAnsweredOpener) {
      return IntroductionStage.friendlyOpener;
    }
    if (!hasAnsweredInterestQuestion) {
      return IntroductionStage.interestQuestion;
    }
    if (!hasDecidedRecommendation) {
      return IntroductionStage.recommendation;
    }
    return IntroductionStage.endScreen;
  }

  IntroductionProgress copyWith({
    Language? language,
    bool? interestsChosen,
    IntroductionChoice? choice,
    StepAnswer? opener,
    StepAnswer? interestQuestion,
    RecommendationStep? recommendation,
    DemoStep? demo,
    bool? isComplete,
    DateTime? completedAt,
  }) {
    return IntroductionProgress(
      language: language ?? this.language,
      interestsChosen: interestsChosen ?? this.interestsChosen,
      choice: choice ?? this.choice,
      opener: opener ?? this.opener,
      interestQuestion: interestQuestion ?? this.interestQuestion,
      recommendation: recommendation ?? this.recommendation,
      demo: demo ?? this.demo,
      isComplete: isComplete ?? this.isComplete,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Records that the introduction has started in [language]. Does nothing
  /// if a language is already recorded.
  IntroductionProgress started(Language language) =>
      this.language == null ? copyWith(language: language) : this;

  /// Records that the chips step has been passed.
  IntroductionProgress withInterestsChosen() => copyWith(interestsChosen: true);

  /// Records the choice of Try it or Show me. Choosing again replaces the
  /// earlier choice; whether the learner is offered that is for the
  /// introduction screens to decide.
  IntroductionProgress withChoice(IntroductionChoice choice) =>
      copyWith(choice: choice);

  /// Records which friendly opener was shown, so that resuming shows the
  /// same one. Showing it again when one is already recorded changes
  /// nothing.
  IntroductionProgress withOpenerShown(String openerId) =>
      opener != null ? this : copyWith(opener: StepAnswer(contentId: openerId));

  /// Records that the opener has been answered, with the History entry id
  /// once the answer has been sent. Calling it again adds a [submissionId]
  /// that was missing. Does nothing if no opener has been shown.
  IntroductionProgress withOpenerAnswered({String? submissionId}) =>
      opener == null
      ? this
      : copyWith(opener: opener!.answered(submissionId: submissionId));

  /// Records which interest question was shown and which chip it is about.
  /// Showing it again when one is already recorded changes nothing.
  IntroductionProgress withInterestQuestionShown({
    required String interestId,
    required String questionId,
  }) => interestQuestion != null
      ? this
      : copyWith(
          interestQuestion: StepAnswer(
            contentId: questionId,
            interestId: interestId,
          ),
        );

  /// Records that the interest question has been answered, with the History
  /// entry id once the answer has been sent. Calling it again adds a
  /// [submissionId] that was missing. Does nothing if no question has been
  /// shown.
  IntroductionProgress withInterestQuestionAnswered({String? submissionId}) =>
      interestQuestion == null
      ? this
      : copyWith(
          interestQuestion: interestQuestion!.answered(
            submissionId: submissionId,
          ),
        );

  /// Records which chip the recommendation card is for. Showing it again
  /// when one is already recorded changes nothing.
  IntroductionProgress withRecommendationShown(String interestId) =>
      recommendation != null
      ? this
      : copyWith(recommendation: RecommendationStep(interestId: interestId));

  /// Records that the learner tapped Open now on the recommendation card.
  /// Does nothing if no card has been shown.
  IntroductionProgress withRecommendationOpened() =>
      _withRecommendationOutcome(RecommendationOutcome.opened);

  /// Records that the learner tapped Skip on the recommendation card. Does
  /// nothing if no card has been shown.
  IntroductionProgress withRecommendationSkipped() =>
      _withRecommendationOutcome(RecommendationOutcome.skipped);

  IntroductionProgress _withRecommendationOutcome(
    RecommendationOutcome outcome,
  ) => recommendation == null
      ? this
      : copyWith(recommendation: recommendation!.withOutcome(outcome));

  /// Records which chip the Show me demo plays on. Showing it again when one
  /// is already recorded changes nothing.
  IntroductionProgress withDemoShown(String interestId) =>
      demo != null ? this : copyWith(demo: DemoStep(interestId: interestId));

  /// Records that the demo has been watched to the end. Does nothing if no
  /// demo has been shown.
  IntroductionProgress withDemoWatched() =>
      demo == null ? this : copyWith(demo: demo!.watched());

  /// Marks the introduction finished at [now]. It will not show again.
  IntroductionProgress completed(DateTime now) =>
      copyWith(isComplete: true, completedAt: now);

  /// Reads a saved record. Fields the 1.2 version wrote for the old design
  /// (`answered_warm_up_ids`, `fuller_question_ids`, `fuller_answers`) are
  /// ignored, like any other unknown field, so an older file still reads.
  factory IntroductionProgress.fromJson(Map<String, Object?> json) {
    final rawLanguage = json['language'];
    final rawCompletedAt = json['completed_at'];
    return IntroductionProgress(
      language: rawLanguage is String ? Language.fromJson(rawLanguage) : null,
      interestsChosen: _readBool(json['interests_chosen']),
      choice: IntroductionChoice.fromJson(json['choice']),
      opener: _readStep(json['opener']),
      interestQuestion: _readStep(json['interest_question']),
      recommendation: _readRecommendation(json['recommendation']),
      demo: _readDemo(json['demo']),
      isComplete: _readBool(json['is_complete']),
      completedAt: rawCompletedAt is String
          ? DateTime.tryParse(rawCompletedAt)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'language': language?.toJson(),
      'interests_chosen': interestsChosen,
      'choice': choice?.toJson(),
      'opener': opener?.toJson(),
      'interest_question': interestQuestion?.toJson(),
      'recommendation': recommendation?.toJson(),
      'demo': demo?.toJson(),
      'is_complete': isComplete,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  static bool _readBool(Object? value) => value is bool && value;

  static StepAnswer? _readStep(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }
    final step = StepAnswer.fromJson(value);
    return step.contentId.isEmpty ? null : step;
  }

  static RecommendationStep? _readRecommendation(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }
    final step = RecommendationStep.fromJson(value);
    return step.interestId.isEmpty ? null : step;
  }

  static DemoStep? _readDemo(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }
    final step = DemoStep.fromJson(value);
    return step.interestId.isEmpty ? null : step;
  }
}
