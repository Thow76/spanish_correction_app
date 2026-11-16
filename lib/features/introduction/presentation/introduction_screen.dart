import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/text_input_panel.dart';
import '../../corrections/presentation/corrections_screen.dart';
import '../../profile/application/profile_repository.dart';
import '../../profile/domain/introduction_progress.dart';
import '../../write/application/transcription_service.dart';
import '../application/introduction_controller.dart';
import '../application/introduction_step.dart';
import '../application/link_opener.dart';
import '../application/voice_recorder.dart';
import '../content/introduction_content.dart';
import '../content/introduction_step_kind.dart';
import '../content/recommendation_item.dart';
import 'introduction_step_frame.dart';
import 'spoken_answer_step.dart';

/// The introduction (decisions A1, A2 and A3; build plan task 1.3).
///
/// Shown once per install between the language choice and the app. The
/// steps are: the interest chips; the choice of "Start now" or "Show me how
/// it works"; for Show me how it works, the guided walk-through first; then
/// for everyone the friendly opener (typed), a question about one of the
/// chosen chips (spoken) and a recommendation card (Open now or Skip); then
/// the end screen. "Stop for now" is on every step (decisions A3 and A4).
///
/// [onDone] is called when the learner leaves: with true when the
/// introduction was finished from the end screen, with false when "Stop for
/// now" took them to the app with no answer yet (it resumes on the next
/// launch).
class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({
    required this.language,
    required this.profileRepository,
    required this.transcriptionService,
    required this.recorderFactory,
    required this.linkOpener,
    required this.onDone,
    super.key,
  });

  final Language language;
  final ProfileRepository profileRepository;
  final TranscriptionService transcriptionService;

  /// Makes the microphone recorder for the spoken step.
  final VoiceRecorder Function() recorderFactory;
  final LinkOpener linkOpener;
  final ValueChanged<bool> onDone;

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  late final IntroductionController _controller;
  VoiceRecorder? _recorder;

  @override
  void initState() {
    super.initState();
    _controller = IntroductionController(
      repository: widget.profileRepository,
      language: widget.language,
    )..addListener(_onChanged);
    _controller.load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _recorder?.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  VoiceRecorder get _voiceRecorder => _recorder ??= widget.recorderFactory();

  @override
  Widget build(BuildContext context) {
    if (!_controller.isLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    final step = _controller.currentStep;
    if (step.mode == IntroductionAnswerMode.demo) {
      return _Walkthrough(
        key: const ValueKey(IntroductionStage.showMeDemo),
        controller: _controller,
        onStopForNow: _stopForNow,
        onSeeFeedback: _playDemoFeedback,
      );
    }
    final isEnd = step.mode == IntroductionAnswerMode.end;
    return IntroductionStepFrame(
      key: ValueKey(_controller.stage),
      label: step.label,
      questionText: step.questionText,
      hint: step.hint,
      onStopForNow: isEnd ? null : _stopForNow,
      child: _buildStepBody(step),
    );
  }

  Widget _buildStepBody(IntroductionStep step) {
    return switch (step.mode) {
      IntroductionAnswerMode.chips => _InterestsStep(controller: _controller),
      IntroductionAnswerMode.choice => _ChoiceStep(controller: _controller),
      IntroductionAnswerMode.type => _TypedAnswerStep(
        onSend: (_) => _controller.answerOpener(),
      ),
      IntroductionAnswerMode.microphone => _InterestQuestionStep(
        controller: _controller,
        child: SpokenAnswerStep(
          recorder: _voiceRecorder,
          transcriptionService: widget.transcriptionService,
          language: widget.language,
          onSend: (_) => _controller.answerInterestQuestion(),
        ),
      ),
      IntroductionAnswerMode.recommendationCard => _RecommendationStep(
        controller: _controller,
        onOpen: _openRecommendation,
      ),
      // The walk-through builds its own frames, in [build].
      IntroductionAnswerMode.demo => const SizedBox.shrink(),
      IntroductionAnswerMode.end => _EndStep(onContinue: _finish),
    };
  }

  Future<void> _stopForNow() async {
    final destination = await _controller.stopForNow();
    if (destination == StopDestination.app && mounted) {
      widget.onDone(false);
    }
  }

  Future<void> _finish() async {
    await _controller.finish();
    if (mounted) {
      widget.onDone(true);
    }
  }

  Future<void> _openRecommendation() async {
    final item = await _controller.openRecommendation();
    if (item == null) {
      return;
    }
    final opened = await widget.linkOpener.open(Uri.parse(item.url));
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('The link could not be opened: ${item.url}')),
      );
    }
  }

  /// Shows the walk-through's feedback on the existing results screen, with
  /// no AI call. Saving a point there shows how saving works but keeps
  /// nothing, so the sample learner's mistakes never reach the learner's own
  /// Saved list. Coming back marks the walk-through watched, and the
  /// learner's own turn begins (decision A4).
  Future<void> _playDemoFeedback() async {
    final demo = _controller.currentDemo;
    if (demo == null) {
      await _controller.finishDemo();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => CorrectionsScreen(
          response: demo.toCorrectionResponse(),
          onSaveCorrection: (_) {
            ScaffoldMessenger.of(routeContext).showSnackBar(
              const SnackBar(
                content: Text(
                  'This is how a point is saved for later. In the demo, '
                  'nothing is kept.',
                ),
              ),
            );
          },
        ),
      ),
    );
    if (mounted) {
      await _controller.finishDemo();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(IntroductionContent.walkthroughYourTurn)),
      );
    }
  }
}

// -----------------------------------------------------------------------------
// The steps
// -----------------------------------------------------------------------------

class _InterestsStep extends StatelessWidget {
  const _InterestsStep({required this.controller});

  final IntroductionController controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.selectedInterestIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final interest in controller.interests)
              FilterChip(
                label: Text(interest.labelFor(controller.language)),
                selected: controller.isSelected(interest.id),
                onSelected: (_) {
                  final changed = controller.toggleInterest(interest.id);
                  if (!changed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You can pick up to five.')),
                    );
                  }
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '$count of ${IntroductionContent.maximumChips} chosen',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryActionButton(
          label: 'Continue',
          onPressed: controller.canConfirmInterests
              ? controller.confirmInterests
              : null,
        ),
      ],
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({required this.controller});

  final IntroductionController controller;

  @override
  Widget build(BuildContext context) {
    const descriptionStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
      height: 20 / 14,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryActionButton(
          label: IntroductionContent.startNowButton,
          onPressed: () => controller.choose(IntroductionChoice.tryIt),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          IntroductionContent.startNowDescription,
          style: descriptionStyle,
        ),
        const SizedBox(height: AppSpacing.xl),
        _OutlinedChoiceButton(
          label: IntroductionContent.showMeButton,
          onPressed: () => controller.choose(IntroductionChoice.showMe),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          IntroductionContent.showMeDescription,
          style: descriptionStyle,
        ),
      ],
    );
  }
}

class _TypedAnswerStep extends StatefulWidget {
  const _TypedAnswerStep({required this.onSend});

  final Future<void> Function(String answer) onSend;

  @override
  State<_TypedAnswerStep> createState() => _TypedAnswerStepState();
}

class _TypedAnswerStepState extends State<_TypedAnswerStep> {
  final _textController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 160,
          child: TextInputPanel(
            controller: _textController,
            characterLimit: 600,
            hintText: 'Escribe tu respuesta...',
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryActionButton(
          label: 'Send',
          isLoading: _isSending,
          onPressed: hasText ? _send : null,
        ),
      ],
    );
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    try {
      await widget.onSend(_textController.text.trim());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}

class _InterestQuestionStep extends StatelessWidget {
  const _InterestQuestionStep({required this.controller, required this.child});

  final IntroductionController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final interest = controller.currentQuestionInterest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (interest != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(label: Text(interest.labelFor(controller.language))),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        child,
      ],
    );
  }
}

class _RecommendationStep extends StatefulWidget {
  const _RecommendationStep({required this.controller, required this.onOpen});

  final IntroductionController controller;
  final Future<void> Function() onOpen;

  @override
  State<_RecommendationStep> createState() => _RecommendationStepState();
}

class _RecommendationStepState extends State<_RecommendationStep> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final item = controller.currentRecommendation;
    final interest = controller.currentRecommendationInterest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item != null)
          _RecommendationCard(
            item: item,
            interestLabel: interest?.labelFor(controller.language),
          ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryActionButton(
          label: 'Open now',
          onPressed: _isBusy ? null : () => _run(widget.onOpen),
        ),
        const SizedBox(height: AppSpacing.md),
        _OutlinedChoiceButton(
          label: 'Skip',
          onPressed: _isBusy ? null : () => _run(controller.skipRecommendation),
        ),
      ],
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item, this.interestLabel});

  final RecommendationItem item;
  final String? interestLabel;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (item.type) {
      RecommendationType.article => 'Article',
      RecommendationType.video => 'Video',
      RecommendationType.other => 'Resource',
    };
    final typeIcon = switch (item.type) {
      RecommendationType.article => Icons.article_outlined,
      RecommendationType.video => Icons.play_circle_outline,
      RecommendationType.other => Icons.headphones_outlined,
    };
    final placeholder = Container(
      height: 140,
      color: AppColors.cyan.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(typeIcon, color: AppColors.cyan, size: 48),
    );
    final thumbnailUrl = item.thumbnailUrl;

    return Container(
      key: const ValueKey('recommendation-card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (thumbnailUrl != null)
            Image.network(
              thumbnailUrl,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          else
            placeholder,
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${item.source} · $typeLabel',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (interestLabel != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Because you like: $interestLabel',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Show me how it works" (decision A4): four short parts, each in the
/// usual frame with its label, then the learner's own turn.
///
/// 1. Friendly opener: the first opener and a sample typed answer.
/// 2. Something you're into: the demo question on the learner's first chip
///    and the sample learner's answer.
/// 3. A recommendation: the card the learner's own turn will show.
/// 4. Feedback: what the feedback is, then the sample answer's feedback on
///    the results screen, with no AI call.
///
/// Which part is showing is not saved: a learner who stops part-way sees the
/// walk-through from its start next time.
class _Walkthrough extends StatefulWidget {
  const _Walkthrough({
    required this.controller,
    required this.onStopForNow,
    required this.onSeeFeedback,
    super.key,
  });

  final IntroductionController controller;
  final VoidCallback onStopForNow;
  final Future<void> Function() onSeeFeedback;

  @override
  State<_Walkthrough> createState() => _WalkthroughState();
}

class _WalkthroughState extends State<_Walkthrough> {
  int _part = 0;

  static const _captionStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
    height: 20 / 14,
  );

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final demo = controller.currentDemo;
    final opener = controller.currentOpenerForWalkthrough;
    final recommendation = controller.walkthroughRecommendation;
    final interest = controller.currentDemoInterest;
    final next = PrimaryActionButton(
      label: 'Next',
      onPressed: () => setState(() => _part++),
    );

    return switch (_part) {
      0 => IntroductionStepFrame(
        key: const ValueKey('walkthrough-opener'),
        label: IntroductionStepKind.friendlyOpener.label,
        questionText: opener?.text,
        onStopForNow: widget.onStopForNow,
        child: _part0(next),
      ),
      1 => IntroductionStepFrame(
        key: const ValueKey('walkthrough-interest'),
        label: IntroductionStepKind.somethingYoureInto.label,
        questionText: demo?.question,
        onStopForNow: widget.onStopForNow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (interest != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(interest.labelFor(controller.language)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const Text(
              IntroductionContent.walkthroughInterestCaption,
              style: _captionStyle,
            ),
            const SizedBox(height: AppSpacing.md),
            if (demo != null) _SampleAnswer(text: demo.sampleAnswer),
            const SizedBox(height: AppSpacing.xl),
            next,
          ],
        ),
      ),
      2 => IntroductionStepFrame(
        key: const ValueKey('walkthrough-recommendation'),
        label: IntroductionStepKind.recommendation.label,
        questionText: recommendation?.title,
        onStopForNow: widget.onStopForNow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              IntroductionContent.walkthroughRecommendationCaption,
              style: _captionStyle,
            ),
            const SizedBox(height: AppSpacing.md),
            if (recommendation != null)
              _RecommendationCard(
                item: recommendation,
                interestLabel: IntroductionContent.interestById(
                  recommendation.interestId,
                )?.labelFor(controller.language),
              ),
            const SizedBox(height: AppSpacing.xl),
            next,
          ],
        ),
      ),
      _ => IntroductionStepFrame(
        key: const ValueKey('walkthrough-feedback'),
        label: IntroductionContent.walkthroughFeedbackLabel,
        questionText: IntroductionContent.walkthroughFeedbackQuestion,
        onStopForNow: widget.onStopForNow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              IntroductionContent.walkthroughFeedbackCaption,
              style: _captionStyle,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryActionButton(
              label: 'See the feedback',
              onPressed: widget.onSeeFeedback,
            ),
          ],
        ),
      ),
    };
  }

  Widget _part0(Widget next) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          IntroductionContent.walkthroughOpenerCaption,
          style: _captionStyle,
        ),
        const SizedBox(height: AppSpacing.md),
        const _SampleAnswer(text: IntroductionContent.walkthroughOpenerAnswer),
        const SizedBox(height: AppSpacing.xl),
        next,
      ],
    );
  }
}

/// A sample learner's answer in the walk-through, in a tinted box.
class _SampleAnswer extends StatelessWidget {
  const _SampleAnswer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 24 / 15,
        ),
      ),
    );
  }
}

class _EndStep extends StatelessWidget {
  const _EndStep({required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    return PrimaryActionButton(label: 'Continue', onPressed: onContinue);
  }
}

/// A second choice that looks as clearly tappable as the main button: a
/// solid cyan outline and white text, without the main button's fill. Used
/// for Show me beside Try it, and Skip beside Open now.
class _OutlinedChoiceButton extends StatelessWidget {
  const _OutlinedChoiceButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.cyan, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Sora',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
