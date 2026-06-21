import 'package:flutter/material.dart';

import '../../../../core/models/walkthrough_question.dart';
import '../../../../shared/design/app_colors.dart';

/// Signature for the walkthrough's single completion boundary: reports the raw
/// tally once every question has been answered. Percentage rendering and the
/// results screen are a later phase — this hands back only the counts.
typedef WalkthroughCompleted =
    void Function({required int correctCount, required int totalCount});

/// The chunk-by-chunk multiple-choice walkthrough flow.
///
/// Self-contained: it receives the fetched [questions] and a single
/// [onCompleted] callback, owns its own question-cursor/answer state internally,
/// and reports the score out exactly once when finished. One input boundary in
/// ([questions]), one "done + score" boundary out ([onCompleted]).
///
/// Phase 1 scope: state/logic plus a minimal placeholder rendering — enough to
/// drive and test the flow. The real per-question UI (Figma) and the
/// results/score screen are later phases. Assumes [questions] is non-empty (the
/// walkthrough service guarantees 3–5 validated questions).
class WalkthroughQuestionView extends StatefulWidget {
  const WalkthroughQuestionView({
    required this.questions,
    required this.onCompleted,
    super.key,
  });

  final List<WalkthroughQuestion> questions;

  /// Output boundary. Defined here as the widget's contract; it is not invoked
  /// until the completion step wires the running tally to it.
  final WalkthroughCompleted onCompleted;

  @override
  State<WalkthroughQuestionView> createState() =>
      _WalkthroughQuestionViewState();
}

class _WalkthroughQuestionViewState extends State<WalkthroughQuestionView> {
  // Reassigned by the advance step; not yet mutated in this (shell-only) step.
  // ignore: prefer_final_fields
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];

    return Text(
      question.englishStem,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}
