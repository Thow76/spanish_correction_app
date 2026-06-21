import 'dart:math';

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
    this.random,
    super.key,
  });

  final List<WalkthroughQuestion> questions;

  /// Output boundary. Defined here as the widget's contract; it is not invoked
  /// until the completion step wires the running tally to it.
  final WalkthroughCompleted onCompleted;

  /// Injectable randomness for the per-question option shuffle, so tests can
  /// seed it. Defaults to a fresh [Random] when null.
  final Random? random;

  @override
  State<WalkthroughQuestionView> createState() =>
      _WalkthroughQuestionViewState();
}

class _WalkthroughQuestionViewState extends State<WalkthroughQuestionView> {
  int _currentIndex = 0;

  /// Set once the last question is advanced past, at which point [onCompleted]
  /// has already fired. Also swaps the placeholder body to a finished marker.
  bool _isFinished = false;

  /// Correct answers banked so far. A question's correctness is banked when it
  /// is advanced past, so this only counts answered questions.
  int _correctCount = 0;

  /// The three display options per question, indexed in step with
  /// [widget.questions]. Shuffled once here so a rebuild never reorders them;
  /// the stored [WalkthroughQuestion.correctTranslation] remains the source of
  /// truth for judging, so the shuffle carries no "which is correct" signal.
  late final List<List<String>> _shuffledOptions;

  /// The committed option for the current question, or null while unanswered.
  /// Tapping an option commits it; the question then locks (later taps are
  /// ignored). Reset per question by the advance step.
  String? _selectedOption;

  bool get _isLocked => _selectedOption != null;

  /// Whether the committed answer is correct. Compares the STORED option string
  /// against the STORED [WalkthroughQuestion.correctTranslation] — never a
  /// re-rendered/transformed display label — so judging follows the stored
  /// value regardless of shuffled display order. No normalisation is needed:
  /// the service guarantees the three options are mutually distinct even under
  /// whitespace-normalisation.
  bool get _isCurrentCorrect =>
      _selectedOption == widget.questions[_currentIndex].correctTranslation;

  void _commit(String option) {
    // Tap == commit + lock: once an option is chosen the question is answered
    // and further taps are no-ops. Selection and lock are one action.
    if (_isLocked) {
      return;
    }
    setState(() => _selectedOption = option);
  }

  void _advance() {
    // Bank the just-answered question's correctness as it is advanced past.
    if (_isCurrentCorrect) {
      _correctCount++;
    }

    final isLastQuestion = _currentIndex == widget.questions.length - 1;
    if (isLastQuestion) {
      setState(() => _isFinished = true);
      // Fire the single completion boundary exactly once, from the event
      // handler (never from build), now that every question is banked.
      widget.onCompleted(
        correctCount: _correctCount,
        totalCount: widget.questions.length,
      );
      return;
    }

    setState(() {
      _currentIndex++;
      // Fresh per-question state for the next question.
      _selectedOption = null;
    });
  }

  @override
  void initState() {
    super.initState();
    final random = widget.random ?? Random();
    _shuffledOptions = [
      for (final question in widget.questions)
        [
          question.correctTranslation,
          question.distractors.first,
          question.distractors.second,
        ]..shuffle(random),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Finished placeholder: the results/score screen is a later phase.
    if (_isFinished) {
      return const SizedBox(key: Key('walkthrough-finished'));
    }

    final question = widget.questions[_currentIndex];
    final options = _shuffledOptions[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          question.englishStem,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        for (final option in options)
          GestureDetector(
            onTap: () => _commit(option),
            child: Text(
              option,
              key: _selectedOption == option
                  ? const Key('walkthrough-selected-option')
                  : null,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        // Placeholder correctness indicator, shown once the question is locked.
        // Real correct/incorrect visuals are the Figma phase.
        if (_isLocked)
          SizedBox(
            key: _isCurrentCorrect
                ? const Key('walkthrough-result-correct')
                : const Key('walkthrough-result-incorrect'),
          ),
        // Placeholder advance control, shown once the question is locked.
        if (_isLocked)
          GestureDetector(
            key: const Key('walkthrough-advance'),
            onTap: _advance,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(height: 44),
          ),
      ],
    );
  }
}
