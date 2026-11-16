import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/secondary_action_button.dart';
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
import '../content/recommendation_item.dart';
import 'introduction_step_frame.dart';
import 'spoken_answer_step.dart';

/// The introduction (decisions A1, A2 and A3; build plan task 1.3).
///
/// Shown once per install between the language choice and the app. The
/// steps are: the interest chips; the choice of Try it or Show me; for Try
/// it, the friendly opener (typed), a question about one of the chosen chips
/// (spoken) and a recommendation card (Open now or Skip); for Show me, the
/// fixed demo; then the end screen. "Stop for now" is on every step.
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
      IntroductionAnswerMode.demo => _ShowMeStep(
        controller: _controller,
        onSeeFeedback: _playDemoFeedback,
      ),
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

  /// Shows the demo's feedback on the existing results screen, with no AI
  /// call. Saving a point there shows how saving works but keeps nothing,
  /// so the sample learner's mistakes never reach the learner's own Saved
  /// list. Coming back marks the demo watched.
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
          label: 'Try it',
          onPressed: () => controller.choose(IntroductionChoice.tryIt),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          IntroductionContent.tryItDescription,
          style: descriptionStyle,
        ),
        const SizedBox(height: AppSpacing.xl),
        SecondaryActionButton(
          label: 'Show me',
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
        SecondaryActionButton(
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

class _ShowMeStep extends StatelessWidget {
  const _ShowMeStep({required this.controller, required this.onSeeFeedback});

  final IntroductionController controller;
  final Future<void> Function() onSeeFeedback;

  @override
  Widget build(BuildContext context) {
    final demo = controller.currentDemo;
    final interest = controller.currentDemoInterest;
    const smallStyle = TextStyle(color: AppColors.textSecondary, fontSize: 14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (interest != null)
          Text(
            'An example chat about ${interest.english.toLowerCase()}. '
            'A learner was asked the question above, and answered:',
            style: smallStyle,
          ),
        const SizedBox(height: AppSpacing.md),
        if (demo != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              demo.sampleAnswer,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 24 / 15,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryActionButton(
          label: 'See the feedback',
          onPressed: onSeeFeedback,
        ),
      ],
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
