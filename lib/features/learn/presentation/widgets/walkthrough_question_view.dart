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
  /// A question allows up to this many wrong picks before it locks and
  /// reveals the correct option — a wrong pick within the limit lets the
  /// learner try a different option instead of ending the question outright.
  static const _maxAttempts = 2;

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

  /// The option that resolved the current question, or null while it's still
  /// open. Set on a correct pick (locks immediately) or on the pick that
  /// exhausts [_maxAttempts] wrong tries (locks and reveals). A wrong pick
  /// that still has attempts remaining does NOT set this — the question stays
  /// open for another try. Reset per question by the advance step.
  String? _selectedOption;

  /// Wrong attempts used on the current question so far. Reset per question.
  int _attemptCount = 0;

  /// Options already tried and found wrong on the current question — styled
  /// coral and inert to a re-tap, whether or not the question has locked yet.
  /// Reset per question.
  final Set<String> _triedWrongOptions = {};

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
    // Once locked (correct pick, or the final wrong pick), further taps are
    // no-ops. A previously-tried wrong option is also a no-op — it doesn't
    // spend another attempt.
    if (_isLocked || _triedWrongOptions.contains(option)) {
      return;
    }

    final isCorrectOption =
        option == widget.questions[_currentIndex].correctTranslation;

    if (isCorrectOption) {
      setState(() => _selectedOption = option);
      // Correct answers advance themselves after a brief pause; the wrong path
      // never auto-advances — it waits for the manual control once locked.
      _advanceTimer = Timer(WalkthroughQuestionView.autoAdvanceDelay, _advance);
      return;
    }

    setState(() {
      _triedWrongOptions.add(option);
      _attemptCount++;
      // Only lock (and thus reveal the correct option) once attempts are
      // exhausted — a wrong pick within the limit leaves the question open so
      // the learner can try a different option.
      if (_attemptCount >= _maxAttempts) {
        _selectedOption = option;
      }
    });
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
      _attemptCount = 0;
      _triedWrongOptions.clear();
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
  /// (a/b/c). The correct option turns green once the question locks (a
  /// correct pick, or the pick that exhausts [_maxAttempts]) — never before,
  /// so it isn't handed to the learner mid-retry. Any tried-wrong option turns
  /// coral as soon as it's tried, locked or not. Untried options keep the
  /// neutral default.
  Widget _buildOption(int index, String option) {
    final isCorrectOption =
        option == widget.questions[_currentIndex].correctTranslation;
    final isGreen = _isLocked && isCorrectOption;
    final isCoral = _triedWrongOptions.contains(option);

    final Color stateColor;
    final Color fillColor;
    final Color borderColor;
    if (isGreen) {
      stateColor = AppColors.success;
      fillColor = AppColors.success.withValues(alpha: 0.14);
      borderColor = AppColors.success;
    } else if (isCoral) {
      stateColor = AppColors.coral;
      fillColor = AppColors.coral.withValues(alpha: 0.12);
      borderColor = AppColors.coral;
    } else {
      stateColor = AppColors.textSecondary;
      fillColor = AppColors.textDisabled.withValues(alpha: 0.12);
      borderColor = AppColors.textPrimary.withValues(alpha: 0.12);
    }
    final badge = String.fromCharCode('a'.codeUnitAt(0) + index);

    return GestureDetector(
      onTap: () => _commit(option),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
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
                style: TextStyle(
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
        // Correct-answer affordance: shown on a correct locked answer while it
        // auto-advances. Carries the result-correct marker.
        if (_isLocked && _isCurrentCorrect) ...[
          const SizedBox(height: 14),
          Text(
            widget.str(
              '✓ Correcto — siguiente paso…',
              '✓ Correto — próximo passo…',
            ),
            key: const Key('walkthrough-result-correct'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ],
        // Wrong-answer affordance: the correct option is highlighted and this
        // line is the manual continue control (the correct path auto-advances,
        // so it has no control). Carries both the result-incorrect marker and
        // the advance tap target.
        if (_isLocked && !_isCurrentCorrect) ...[
          const SizedBox(height: 14),
          GestureDetector(
            key: const Key('walkthrough-advance'),
            onTap: _advance,
            behavior: HitTestBehavior.opaque,
            child: Text(
              widget.str(
                'La respuesta correcta está resaltada — siguiente paso…',
                'A resposta correta está destacada — próximo passo…',
              ),
              key: const Key('walkthrough-result-incorrect'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
                height: 18 / 12,
              ),
            ),
          ),
        ],
        // Retry affordance: shown after a wrong pick that still has attempts
        // left — the question stays open (no reveal, no advance control) so
        // the learner tries a different option.
        if (!_isLocked && _attemptCount > 0) ...[
          const SizedBox(height: 14),
          Text(
            widget.str('Inténtalo de nuevo…', 'Tente novamente…'),
            key: const Key('walkthrough-result-retry'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ],
      ],
    );
  }
}
