import 'package:characters/characters.dart';

import '../../../core/enums/language.dart';
import '../../corrections/domain/correction_response.dart';
import '../../corrections/domain/error_category.dart';

/// One point of pre-written feedback in a "Show me" demo.
///
/// It is the app's existing item shape (what was written, what is suggested,
/// a category and a one-line reason) written out by hand, so the demo can
/// show the results screen with no AI call. [originalPhrase] must appear in
/// the demo's sample answer exactly once; [correctedPhrase] replaces it. The
/// categories are today's (`ErrorCategory`) until slice 2 brings in the new
/// list (decision C3); the demo's categories are updated then.
class DemoFeedbackPoint {
  const DemoFeedbackPoint({
    required this.originalPhrase,
    required this.correctedPhrase,
    required this.category,
    required this.shortExplanation,
  });

  final String originalPhrase;
  final String correctedPhrase;
  final ErrorCategory category;

  /// The one-line reason, in English, in the wording the app uses: no
  /// "wrong", "error" or "incorrect" (decision C1).
  final String shortExplanation;
}

/// The material for the "Show me" demo on one interest (decision A3).
///
/// Show me plays a fixed, scripted demo: a question, a sample learner answer
/// with a couple of typical mistakes, then the feedback screen with the
/// highlights and reasons, and saving a point. Nothing here is sent to the AI.
/// [toCorrectionResponse] turns the sample answer and its points into the
/// same object the existing results screen takes.
class ShowMeDemo {
  const ShowMeDemo({
    required this.id,
    required this.interestId,
    required this.language,
    required this.question,
    required this.sampleAnswer,
    required this.points,
  });

  final String id;
  final String interestId;
  final Language language;

  /// The question the sample learner was asked, in the target language.
  final String question;

  /// The sample learner's answer, in the target language, with a couple of
  /// typical mistakes in it.
  final String sampleAnswer;

  /// The pre-written feedback on [sampleAnswer], in the order the phrases
  /// appear in it. The demo's "saving a point" step saves the first one.
  final List<DemoFeedbackPoint> points;

  /// The sample answer and its points as the results screen expects them:
  /// each point anchored to its place in the answer, the corrected text built
  /// from the answer plus the points, and the corrected-side highlights
  /// worked out, all by the same code the live check uses.
  CorrectionResponse toCorrectionResponse() {
    final answerGraphemes = sampleAnswer.characters.toList();
    final corrections = <Map<String, Object?>>[
      for (final point in points)
        {
          'original_phrase': point.originalPhrase,
          'start_index': _graphemeIndexOf(
            answerGraphemes,
            point.originalPhrase.characters.toList(),
          ),
          'corrected_phrase': point.correctedPhrase,
          'category': point.category.label,
          'short_explanation': point.shortExplanation,
        },
    ];
    return CorrectionResponse.fromAnchoredJson({
      'corrections': corrections,
    }, submittedText: sampleAnswer);
  }

  /// The position of [needle] in [haystack], counted in graphemes as the
  /// correction anchoring does, or 0 when it is not there (the anchoring then
  /// falls back to the nearest match and drops the point if there is none).
  static int _graphemeIndexOf(List<String> haystack, List<String> needle) {
    if (needle.isEmpty || needle.length > haystack.length) {
      return 0;
    }
    for (var start = 0; start <= haystack.length - needle.length; start++) {
      var matched = true;
      for (var offset = 0; offset < needle.length; offset++) {
        if (haystack[start + offset] != needle[offset]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return start;
      }
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ShowMeDemo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ShowMeDemo($id)';
}
