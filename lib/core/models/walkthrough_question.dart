import 'walkthrough_exceptions.dart';

/// The two wrong answers for a walkthrough question.
///
/// Value object enforcing the model's only structural guarantee at parse time:
/// there must be exactly two distractors. The model intermittently returns
/// three (PT-G-04), and that is rejected here rather than left to the service
/// layer. Distinctness and cross-language contamination are validated later.
class Distractors {
  const Distractors({required this.first, required this.second});

  final String first;
  final String second;

  /// Parses the raw `distractors` JSON value (a list of two strings).
  ///
  /// Throws [WalkthroughSchemaException] if the value is not a list, does not
  /// contain exactly two elements, or contains a non-string element.
  factory Distractors.fromJson(Object? json) {
    if (json is! List) {
      throw WalkthroughSchemaException(
        'Expected distractors to be a list, got ${json.runtimeType}.',
      );
    }
    if (json.length != 2) {
      throw WalkthroughSchemaException(
        'Expected exactly 2 distractors, got ${json.length}.',
      );
    }
    final first = json[0];
    final second = json[1];
    if (first is! String || second is! String) {
      throw const WalkthroughSchemaException(
        'Expected each distractor to be a string.',
      );
    }
    return Distractors(first: first, second: second);
  }

  List<String> toJson() => [first, second];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Distractors &&
          other.first == first &&
          other.second == second;

  @override
  int get hashCode => Object.hash(first, second);
}

/// One multiple-choice question for a single chunk of the target sentence.
class WalkthroughQuestion {
  const WalkthroughQuestion({
    required this.englishStem,
    required this.correctTranslation,
    required this.distractors,
    required this.chunkPosition,
  });

  final String englishStem;
  final String correctTranslation;
  final Distractors distractors;
  final int chunkPosition;

  /// Parses one question object from the model's JSON.
  ///
  /// Throws [WalkthroughSchemaException] on missing or wrongly-typed fields, or
  /// when the distractor count is not exactly two (via [Distractors.fromJson]).
  factory WalkthroughQuestion.fromJson(Map<String, Object?> json) {
    final englishStem = json['english_stem'];
    if (englishStem is! String) {
      throw const WalkthroughSchemaException(
        'Expected english_stem to be a string.',
      );
    }
    final correctTranslation = json['correct_translation'];
    if (correctTranslation is! String) {
      throw const WalkthroughSchemaException(
        'Expected correct_translation to be a string.',
      );
    }
    final chunkPosition = json['chunk_position'];
    if (chunkPosition is! int) {
      throw const WalkthroughSchemaException(
        'Expected chunk_position to be an integer.',
      );
    }
    return WalkthroughQuestion(
      englishStem: englishStem,
      correctTranslation: correctTranslation,
      distractors: Distractors.fromJson(json['distractors']),
      chunkPosition: chunkPosition,
    );
  }

  Map<String, Object?> toJson() => {
    'english_stem': englishStem,
    'correct_translation': correctTranslation,
    'distractors': distractors.toJson(),
    'chunk_position': chunkPosition,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalkthroughQuestion &&
          other.englishStem == englishStem &&
          other.correctTranslation == correctTranslation &&
          other.distractors == distractors &&
          other.chunkPosition == chunkPosition;

  @override
  int get hashCode =>
      Object.hash(englishStem, correctTranslation, distractors, chunkPosition);
}
