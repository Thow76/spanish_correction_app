import '../../../core/enums/language.dart';

/// Where the learner is in the introduction (decisions A1 and A2).
///
/// "Stop for now" is on every step of the introduction, and the profile file
/// keeps this record so the introduction can resume where it stopped. Once
/// [isComplete] is true the introduction never shows again on this install,
/// including after a language switch (decision A2, point 3).
enum IntroductionStage {
  /// The two warm-up questions, one typed and one spoken.
  warmUps,

  /// The interest chips in the target language.
  interests,

  /// The fuller questions drawn from the chosen chips.
  fullerQuestions,

  /// The end screen: "See suggestions" or "Not now".
  endScreen,

  /// The introduction has been finished and will not show again.
  complete,
}

/// One fuller question the learner has answered.
///
/// [submissionId] is the id of the History entry the answer was sent to for
/// feedback (task 1.4). It is null when the answer has not been sent, for
/// example when the send failed or has not happened yet.
class FullerAnswer {
  const FullerAnswer({required this.questionId, this.submissionId});

  final String questionId;
  final String? submissionId;

  factory FullerAnswer.fromJson(Map<String, Object?> json) {
    final rawQuestionId = json['question_id'];
    final rawSubmissionId = json['submission_id'];
    return FullerAnswer(
      questionId: rawQuestionId is String ? rawQuestionId : '',
      submissionId: rawSubmissionId is String ? rawSubmissionId : null,
    );
  }

  Map<String, Object?> toJson() {
    return {'question_id': questionId, 'submission_id': submissionId};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullerAnswer &&
          other.questionId == questionId &&
          other.submissionId == submissionId;

  @override
  int get hashCode => Object.hash(questionId, submissionId);

  @override
  String toString() => 'FullerAnswer($questionId, $submissionId)';
}

/// The learner's progress through the introduction.
///
/// Everything here is what "Stop for now" needs to bring the learner back to
/// the same place: which warm-ups are done, whether the chips have been
/// passed, which fuller questions were drawn (so the same ones come back) and
/// which of those have been answered. The chosen interests themselves live on
/// the profile, not here, because they outlive the introduction.
class IntroductionProgress {
  const IntroductionProgress({
    this.language,
    this.answeredWarmUpIds = const [],
    this.interestsChosen = false,
    this.fullerQuestionIds = const [],
    this.fullerAnswers = const [],
    this.isComplete = false,
    this.completedAt,
  });

  /// Nothing started yet.
  const IntroductionProgress.notStarted()
    : language = null,
      answeredWarmUpIds = const [],
      interestsChosen = false,
      fullerQuestionIds = const [],
      fullerAnswers = const [],
      isComplete = false,
      completedAt = null;

  /// The language the introduction was run in, set when it starts. Null
  /// until then. There is one introduction per learner (decision A2), so this
  /// is recorded once.
  final Language? language;

  /// Ids of the warm-up questions the learner has answered, in order.
  final List<String> answeredWarmUpIds;

  /// Whether the learner has passed the interest chips step. Tapping no chip
  /// still counts as passing it (the fuller questions are then drawn from
  /// every interest), so this is separate from the profile's interest list.
  final bool interestsChosen;

  /// The fuller questions drawn for this learner, in the order asked. Kept so
  /// that resuming shows the same questions rather than drawing fresh ones.
  final List<String> fullerQuestionIds;

  /// The fuller questions answered so far.
  final List<FullerAnswer> fullerAnswers;

  /// True once the introduction has been finished (or stopped at the end
  /// screen). It is then skipped on every launch and every language switch.
  final bool isComplete;

  final DateTime? completedAt;

  /// Whether the learner has started the introduction at all.
  bool get hasStarted =>
      language != null ||
      answeredWarmUpIds.isNotEmpty ||
      interestsChosen ||
      fullerQuestionIds.isNotEmpty ||
      fullerAnswers.isNotEmpty ||
      isComplete;

  /// Whether at least one fuller answer exists. "Stop for now" goes to the
  /// end screen when this is true and straight to the app when it is false
  /// (build plan task 1.3).
  bool get hasFullerAnswer => fullerAnswers.isNotEmpty;

  /// Whether every drawn fuller question has an answer.
  bool get allFullerQuestionsAnswered =>
      fullerQuestionIds.isNotEmpty &&
      fullerQuestionIds.every(hasAnsweredFullerQuestion);

  bool hasAnsweredWarmUp(String warmUpId) =>
      answeredWarmUpIds.contains(warmUpId);

  bool hasAnsweredFullerQuestion(String questionId) =>
      fullerAnswers.any((answer) => answer.questionId == questionId);

  /// The ids of the drawn fuller questions not yet answered, in order.
  List<String> get unansweredFullerQuestionIds => fullerQuestionIds
      .where((id) => !hasAnsweredFullerQuestion(id))
      .toList(growable: false);

  /// The step the introduction should show next when it resumes.
  ///
  /// [warmUpCount] is how many warm-up questions the content has (two in
  /// decision A1); the warm-ups stage is over once that many have been
  /// answered.
  IntroductionStage stageFor({required int warmUpCount}) {
    if (isComplete) {
      return IntroductionStage.complete;
    }
    if (answeredWarmUpIds.length < warmUpCount) {
      return IntroductionStage.warmUps;
    }
    if (!interestsChosen) {
      return IntroductionStage.interests;
    }
    if (!allFullerQuestionsAnswered) {
      return IntroductionStage.fullerQuestions;
    }
    return IntroductionStage.endScreen;
  }

  IntroductionProgress copyWith({
    Language? language,
    List<String>? answeredWarmUpIds,
    bool? interestsChosen,
    List<String>? fullerQuestionIds,
    List<FullerAnswer>? fullerAnswers,
    bool? isComplete,
    DateTime? completedAt,
  }) {
    return IntroductionProgress(
      language: language ?? this.language,
      answeredWarmUpIds: answeredWarmUpIds ?? this.answeredWarmUpIds,
      interestsChosen: interestsChosen ?? this.interestsChosen,
      fullerQuestionIds: fullerQuestionIds ?? this.fullerQuestionIds,
      fullerAnswers: fullerAnswers ?? this.fullerAnswers,
      isComplete: isComplete ?? this.isComplete,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Records that the introduction has started in [language]. Does nothing
  /// if a language is already recorded.
  IntroductionProgress started(Language language) =>
      this.language == null ? copyWith(language: language) : this;

  /// Records a warm-up as answered. Answering the same one twice records it
  /// once.
  IntroductionProgress withWarmUpAnswered(String warmUpId) =>
      hasAnsweredWarmUp(warmUpId)
      ? this
      : copyWith(answeredWarmUpIds: [...answeredWarmUpIds, warmUpId]);

  /// Records that the chips step has been passed and which fuller questions
  /// were drawn from the chosen chips.
  IntroductionProgress withInterestsChosen({
    required List<String> fullerQuestionIds,
  }) => copyWith(
    interestsChosen: true,
    fullerQuestionIds: List.unmodifiable(fullerQuestionIds),
  );

  /// Records an answer to a fuller question. Answering the same question
  /// again replaces the earlier record (for example to add a submission id
  /// once the answer has been sent).
  IntroductionProgress withFullerAnswer(FullerAnswer answer) {
    final others = fullerAnswers.where(
      (existing) => existing.questionId != answer.questionId,
    );
    return copyWith(fullerAnswers: [...others, answer]);
  }

  /// Marks the introduction finished at [now]. It will not show again.
  IntroductionProgress completed(DateTime now) =>
      copyWith(isComplete: true, completedAt: now);

  factory IntroductionProgress.fromJson(Map<String, Object?> json) {
    final rawLanguage = json['language'];
    final rawCompletedAt = json['completed_at'];
    return IntroductionProgress(
      language: rawLanguage is String ? Language.fromJson(rawLanguage) : null,
      answeredWarmUpIds: _readStringList(json['answered_warm_up_ids']),
      interestsChosen: _readBool(json['interests_chosen']),
      fullerQuestionIds: _readStringList(json['fuller_question_ids']),
      fullerAnswers: _readAnswers(json['fuller_answers']),
      isComplete: _readBool(json['is_complete']),
      completedAt: rawCompletedAt is String
          ? DateTime.tryParse(rawCompletedAt)
          : null,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'language': language?.toJson(),
      'answered_warm_up_ids': answeredWarmUpIds,
      'interests_chosen': interestsChosen,
      'fuller_question_ids': fullerQuestionIds,
      'fuller_answers': fullerAnswers.map((answer) => answer.toJson()).toList(),
      'is_complete': isComplete,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  static bool _readBool(Object? value) => value is bool && value;

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return List.unmodifiable(value.whereType<String>());
  }

  static List<FullerAnswer> _readAnswers(Object? value) {
    if (value is! List) {
      return const [];
    }
    return List.unmodifiable(
      value
          .whereType<Map<String, Object?>>()
          .map(FullerAnswer.fromJson)
          .where((answer) => answer.questionId.isNotEmpty),
    );
  }
}
