import '../enums/language.dart';
import 'walkthrough_exceptions.dart';
import 'walkthrough_question.dart';
import 'walkthrough_state.dart';

/// A single Traducir frases walkthrough: the chunk-by-chunk multiple-choice
/// activity generated for one source phrase, plus the learner's progress.
///
/// Parsing is strict, matching [WalkthroughQuestion]: wrongly-typed fields are
/// rejected with [WalkthroughSchemaException] rather than coerced to defaults.
class WalkthroughActivity {
  const WalkthroughActivity({
    required this.sourcePhraseId,
    required this.targetSentence,
    required this.language,
    required this.questions,
    required this.answers,
    this.completedAt,
  });

  /// Ties this activity to the source phrase it was generated from.
  final String sourcePhraseId;

  /// The language this activity belongs to, used to scope persisted activities
  /// exactly as corrections are scoped.
  final Language language;

  /// The full target-language sentence, carried at the envelope level in the
  /// model response. Stored here so the Section 5 reconstruction check can
  /// compare the concatenation of chunk answers against it.
  final String targetSentence;

  final List<WalkthroughQuestion> questions;

  /// One entry per question, indexed in step with [questions]. `null` means the
  /// learner has not yet answered that question.
  final List<String?> answers;

  final DateTime? completedAt;

  /// Derived lifecycle. [WalkthroughState.completed] once [completedAt] is set,
  /// [WalkthroughState.inProgress] once any answer is recorded, otherwise
  /// [WalkthroughState.notStarted]. Never persisted, so it cannot drift.
  WalkthroughState get state {
    if (completedAt != null) {
      return WalkthroughState.completed;
    }
    if (answers.any((answer) => answer != null)) {
      return WalkthroughState.inProgress;
    }
    return WalkthroughState.notStarted;
  }

  /// Parses a persisted walkthrough activity.
  ///
  /// Throws [WalkthroughSchemaException] on missing or wrongly-typed fields,
  /// including when `questions` or `answers` are not lists.
  factory WalkthroughActivity.fromJson(Map<String, Object?> json) {
    final sourcePhraseId = json['source_phrase_id'];
    if (sourcePhraseId is! String) {
      throw const WalkthroughSchemaException(
        'Expected source_phrase_id to be a string.',
      );
    }
    final targetSentence = json['target_sentence'];
    if (targetSentence is! String) {
      throw const WalkthroughSchemaException(
        'Expected target_sentence to be a string.',
      );
    }

    final rawLanguage = json['language'];
    if (rawLanguage is! String) {
      throw const WalkthroughSchemaException(
        'Expected language to be a string.',
      );
    }
    // Strict, unlike the older models' coercing Language.fromJson: reject any
    // value that is not a recognised language rather than defaulting.
    Language? language;
    for (final candidate in Language.values) {
      if (candidate.toJson() == rawLanguage) {
        language = candidate;
        break;
      }
    }
    if (language == null) {
      throw WalkthroughSchemaException(
        'Expected language to be a recognised language, got "$rawLanguage".',
      );
    }

    final rawQuestions = json['questions'];
    if (rawQuestions is! List) {
      throw WalkthroughSchemaException(
        'Expected questions to be a list, got ${rawQuestions.runtimeType}.',
      );
    }
    final questions = rawQuestions.map((element) {
      if (element is! Map<String, Object?>) {
        throw const WalkthroughSchemaException(
          'Expected each question to be an object.',
        );
      }
      return WalkthroughQuestion.fromJson(element);
    }).toList();

    final rawAnswers = json['answers'];
    if (rawAnswers is! List) {
      throw WalkthroughSchemaException(
        'Expected answers to be a list, got ${rawAnswers.runtimeType}.',
      );
    }
    final answers = rawAnswers.map((element) {
      if (element != null && element is! String) {
        throw const WalkthroughSchemaException(
          'Expected each answer to be a string or null.',
        );
      }
      return element as String?;
    }).toList();

    final rawCompletedAt = json['completed_at'];
    DateTime? completedAt;
    if (rawCompletedAt != null) {
      if (rawCompletedAt is! String) {
        throw const WalkthroughSchemaException(
          'Expected completed_at to be a string or null.',
        );
      }
      final parsed = DateTime.tryParse(rawCompletedAt);
      if (parsed == null) {
        throw WalkthroughSchemaException(
          'Expected completed_at to be an ISO-8601 timestamp, got '
          '"$rawCompletedAt".',
        );
      }
      completedAt = parsed;
    }

    return WalkthroughActivity(
      sourcePhraseId: sourcePhraseId,
      targetSentence: targetSentence,
      language: language,
      questions: questions,
      answers: answers,
      completedAt: completedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'source_phrase_id': sourcePhraseId,
    'target_sentence': targetSentence,
    'language': language.toJson(),
    'questions': questions.map((question) => question.toJson()).toList(),
    'answers': answers,
    'completed_at': completedAt?.toIso8601String(),
  };

  WalkthroughActivity copyWith({
    Language? language,
    List<String?>? answers,
    DateTime? completedAt,
  }) {
    return WalkthroughActivity(
      sourcePhraseId: sourcePhraseId,
      targetSentence: targetSentence,
      language: language ?? this.language,
      questions: questions,
      answers: answers ?? this.answers,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalkthroughActivity &&
          other.sourcePhraseId == sourcePhraseId &&
          other.targetSentence == targetSentence &&
          other.language == language &&
          _listEquals(other.questions, questions) &&
          _listEquals(other.answers, answers) &&
          other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
    sourcePhraseId,
    targetSentence,
    language,
    Object.hashAll(questions),
    Object.hashAll(answers),
    completedAt,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
