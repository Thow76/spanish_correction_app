import 'dart:async';
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
    this.str = _defaultStr,
    this.random,
    super.key,
  });

  /// The brief pause shown on a correct answer before auto-advancing. Exposed so
  /// tests can flush the timer deterministically via `tester.pump`.
  static const Duration autoAdvanceDelay = Duration(milliseconds: 900);

  /// Default localisation: Spanish. A static tear-off so it can be a const
  /// constructor default. The game wiring passes the real `_str`.
  static String _defaultStr(String es, String pt) => es;

  final List<WalkthroughQuestion> questions;

  /// Output boundary. Defined here as the widget's contract; it is not invoked
  /// until the completion step wires the running tally to it.
  final WalkthroughCompleted onCompleted;

  /// Returns the Spanish or Portuguese string for the active language. Optional
  /// so existing callers/tests need no change; defaults to Spanish.
  final String Function(String es, String pt) str;

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

  /// Pending auto-advance for a correct answer. Cancelled on dispose. The wrong
  /// path schedules nothing — it waits for the manual control.
  Timer? _advanceTimer;

  bool get _isLocked => _selectedOption != null;

  /// Whether the committed answer is correct. Compares the STORED option string
  /// against the STORED [WalkthroughQuestion.correctTranslation] — never a
  /// re-rendered/transformed display label — so judging follows the stored
  /// value regardless of shuffled display order. No normalisation is needed:
  /// the service guarantees the three options are mutually distinct even under
  /// whitespace-normalisation.
  bool get _isCurrentCorrect =>
      _selectedOption == widget.questions[_currentIndex].correctTranslation;

  /// The key (if any) an option's placeholder should carry.
  ///
  /// On a WRONG locked answer, the option matching the stored
  /// [WalkthroughQuestion.correctTranslation] is marked with
  /// `walkthrough-correct-highlight` — a placeholder for the real
  /// "here's the right answer" highlight (the visual is the Figma phase). The
  /// committed option always carries `walkthrough-selected-option`. These never
  /// collide: on a wrong answer the selected option is a distractor, distinct
  /// from the correct one.
  Key? _keyForOption(String option) {
    if (_selectedOption == option) {
      return const Key('walkthrough-selected-option');
    }
    final isCorrectOption =
        option == widget.questions[_currentIndex].correctTranslation;
    if (_isLocked && !_isCurrentCorrect && isCorrectOption) {
      return const Key('walkthrough-correct-highlight');
    }
    return null;
  }

  void _commit(String option) {
    // Tap == commit + lock: once an option is chosen the question is answered
    // and further taps are no-ops. Selection and lock are one action.
    if (_isLocked) {
      return;
    }
    setState(() => _selectedOption = option);

    // Correct answers advance themselves after a brief pause; wrong answers wait
    // for the user to tap the manual control.
    if (_isCurrentCorrect) {
      _advanceTimer = Timer(WalkthroughQuestionView.autoAdvanceDelay, _advance);
    }
  }

  void _advance() {
    // Idempotency guard: cancel any pending auto-advance and refuse to run once
    // finished, so a stray late timer plus any other trigger cannot double-
    // advance or fire completion twice.
    _advanceTimer?.cancel();
    if (_isFinished) {
      return;
    }

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
  void dispose() {
    // Never let the auto-advance fire after the widget is gone.
    _advanceTimer?.cancel();
    super.dispose();
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

  /// Builds one styled option button. [index] gives the display badge letter
  /// (a/b/c). Colours are the neutral default in this step; the correct/wrong
  /// per-state colours are layered on in later steps.
  Widget _buildOption(int index, String option) {
    const stateColor = AppColors.textSecondary;
    final badge = String.fromCharCode('a'.codeUnitAt(0) + index);

    return GestureDetector(
      onTap: () => _commit(option),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.textDisabled.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Text(
              badge,
              style: TextStyle(
                color: stateColor.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 18 / 12,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                option,
                key: _keyForOption(option),
                style: const TextStyle(
                  color: stateColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 21 / 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          widget.str(
            'Paso ${_currentIndex + 1} de ${widget.questions.length}',
            'Passo ${_currentIndex + 1} de ${widget.questions.length}',
          ),
          style: const TextStyle(
            color: AppColors.textDisabled,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
          ),
          child: Text(
            question.englishStem,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 24 / 15,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildOption(i, options[i]),
        ],
        // Placeholder correctness indicator, shown once the question is locked.
        // Real correct/incorrect visuals are the Figma phase.
        if (_isLocked)
          SizedBox(
            key: _isCurrentCorrect
                ? const Key('walkthrough-result-correct')
                : const Key('walkthrough-result-incorrect'),
          ),
        // Placeholder advance control, shown only on a WRONG locked answer.
        // Correct answers auto-advance after a pause, so they show no control.
        if (_isLocked && !_isCurrentCorrect)
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
