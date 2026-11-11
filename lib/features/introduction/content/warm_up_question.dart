/// How a warm-up question is answered. The two warm-ups exist to teach the
/// controls (decision A1): one is typed, the other is spoken.
enum WarmUpInput { typed, spoken }

/// One of the two warm-up questions at the start of the introduction.
///
/// [text] is in the target language. [hint] is a small line in English that
/// tells the learner what to do with the control. Warm-up answers get no
/// feedback and are not sent anywhere.
class WarmUpQuestion {
  const WarmUpQuestion({
    required this.id,
    required this.text,
    required this.hint,
    required this.input,
  });

  final String id;
  final String text;
  final String hint;
  final WarmUpInput input;

  @override
  String toString() => 'WarmUpQuestion($id)';
}
