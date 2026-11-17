import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/text/correction_highlight_spans.dart';
import '../../../shared/widgets/category_pill.dart';
import '../../corrections/application/correction_service_exception.dart';
import '../../corrections/domain/correction_item.dart';
import '../../corrections/domain/error_category.dart';
import '../../corrections/presentation/corrections_screen.dart';
import '../../history/domain/correction_submission.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/text_input_panel.dart';
import '../../profile/application/profile_repository.dart';
import '../../profile/domain/introduction_progress.dart';
import '../../write/application/transcription_service.dart';
import '../application/introduction_controller.dart';
import '../application/introduction_feedback.dart';
import '../application/introduction_step.dart';
import '../application/link_opener.dart';
import '../application/voice_recorder.dart';
import '../content/introduction_content.dart';
import '../content/introduction_step_kind.dart';
import '../content/recommendation_item.dart';
import '../content/show_me_demo.dart';
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
/// The two answers are sent for feedback through [feedback] as soon as they
/// are given, so they land in History. The end screen offers "See
/// suggestions", which walks through the results screen one answer after
/// another with Save on each point, or "Not now", which leaves them in
/// History (task 1.4).
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
    this.feedback,
    super.key,
  });

  final Language language;
  final ProfileRepository profileRepository;
  final TranscriptionService transcriptionService;

  /// Makes the microphone recorder for the spoken step.
  final VoiceRecorder Function() recorderFactory;
  final LinkOpener linkOpener;
  final ValueChanged<bool> onDone;

  /// Sends the two answers for feedback and saves points. Null sends
  /// nothing.
  final IntroductionFeedback? feedback;

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  late final IntroductionController _controller;
  VoiceRecorder? _recorder;
  bool _isGettingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = IntroductionController(
      repository: widget.profileRepository,
      language: widget.language,
      feedback: widget.feedback,
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
        onFinished: _controller.finishDemo,
      );
    }
    final isEnd = step.mode == IntroductionAnswerMode.end;
    return IntroductionStepFrame(
      key: ValueKey(_controller.stage),
      label: step.label,
      labelColor: introductionLabelColor(switch (_controller.stage) {
        IntroductionStage.friendlyOpener => IntroductionStepKind.friendlyOpener,
        IntroductionStage.interestQuestion =>
          IntroductionStepKind.somethingYoureInto,
        IntroductionStage.recommendation => IntroductionStepKind.recommendation,
        _ => null,
      }),
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
        onSend: _controller.answerOpener,
      ),
      IntroductionAnswerMode.microphone => _InterestQuestionStep(
        controller: _controller,
        child: SpokenAnswerStep(
          recorder: _voiceRecorder,
          transcriptionService: widget.transcriptionService,
          language: widget.language,
          onSend: _controller.answerInterestQuestion,
        ),
      ),
      IntroductionAnswerMode.recommendationCard => _RecommendationStep(
        controller: _controller,
        onOpen: _openRecommendation,
      ),
      // The walk-through builds its own frames, in [build].
      IntroductionAnswerMode.demo => const SizedBox.shrink(),
      IntroductionAnswerMode.end => _EndStep(
        isGettingSuggestions: _isGettingSuggestions,
        onSeeSuggestions: _seeSuggestions,
        onNotNow: _finish,
      ),
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

  /// "See suggestions": walks through the results screen for each answer,
  /// opener first, then finishes the introduction (task 1.4). Each point
  /// offers Save; moving on without saving is ignoring it (decisions C5 and
  /// A4). Going back from a results screen also moves on.
  Future<void> _seeSuggestions() async {
    if (_isGettingSuggestions) {
      return;
    }
    setState(() => _isGettingSuggestions = true);
    final submissions = await _controller.suggestionsToShow();
    if (!mounted) {
      return;
    }
    setState(() => _isGettingSuggestions = false);
    if (submissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your suggestions could not be fetched just now. Check your '
            'internet connection and try again, or tap Not now.',
          ),
        ),
      );
      return;
    }
    for (final (index, submission) in submissions.indexed) {
      final isLast = index == submissions.length - 1;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (routeContext) => CorrectionsScreen(
            key: ValueKey('introduction-suggestions-$index'),
            response: submission.response,
            title: submissions.length == 1
                ? 'Corrections'
                : 'Corrections ${index + 1} of ${submissions.length}',
            onSaveCorrection: (point) =>
                _savePoint(routeContext, point, submission),
            nextLabel: isLast ? 'Done' : 'Next answer',
            onNext: () => Navigator.of(routeContext).pop(),
          ),
        ),
      );
      if (!mounted) {
        return;
      }
    }
    await _finish();
  }

  Future<void> _savePoint(
    BuildContext routeContext,
    CorrectionItem point,
    CorrectionSubmission submission,
  ) async {
    final messenger = ScaffoldMessenger.of(routeContext);
    try {
      await _controller.savePoint(point, submission);
      messenger.showSnackBar(const SnackBar(content: Text('Saved for later')));
    } on CorrectionServiceException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (error.reason) {
            CorrectionFailureReason.missingConfiguration =>
              'OpenAI API key is missing.',
            CorrectionFailureReason.networkUnavailable =>
              'No internet available. Please check your connection.',
            CorrectionFailureReason.apiFailure ||
            CorrectionFailureReason.invalidResponse =>
              'Something went wrong. Please try again.',
          }),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
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

/// "Show me how it works" (decision A4): four short guided parts, each in
/// the usual frame with its label and a small chat to look at, with dots
/// showing how far through the learner is.
///
/// 1. Chat about your day: the app's question and a sample typed answer.
/// 2. Chat about your interests: the question on the learner's first chip and
///    the sample learner's spoken answer.
/// 3. Chat about a recommendation: three small examples under Read, Watch
///    and Listen (an article, a programme, a podcast), none opened.
/// 4. Feedback: the sample answer with its phrases highlighted; tapping one
///    shows its category, the suggestion and the reason, with Save. Nothing is sent to the
///    AI and nothing is kept, so the sample learner's mistakes never reach
///    the learner's own Saved list. "Your turn" appears once a phrase has
///    been tapped.
///
/// Which part is showing is not saved: a learner who stops part-way sees the
/// walk-through from its start next time.
class _Walkthrough extends StatefulWidget {
  const _Walkthrough({
    required this.controller,
    required this.onStopForNow,
    required this.onFinished,
    super.key,
  });

  final IntroductionController controller;
  final VoidCallback onStopForNow;
  final Future<void> Function() onFinished;

  @override
  State<_Walkthrough> createState() => _WalkthroughState();
}

class _WalkthroughState extends State<_Walkthrough> {
  static const _partCount = 4;

  int _part = 0;
  int? _selectedPoint;
  final Set<int> _savedPoints = {};
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final demo = controller.currentDemo;
    final opener = controller.currentOpenerForWalkthrough;
    final readExample = controller.walkthroughReadExample;
    final interest = controller.currentDemoInterest;
    final next = PrimaryActionButton(
      label: 'Next',
      onPressed: () => setState(() => _part++),
    );

    final (String label, String? heading, List<Widget> body) = switch (_part) {
      0 => (
        IntroductionStepKind.friendlyOpener.label,
        null,
        [
          if (opener != null) _ChatBubble.app(opener.text),
          const _ChatBubble.learner(
            IntroductionContent.walkthroughOpenerAnswer,
            icon: Icons.keyboard_outlined,
          ),
        ],
      ),
      1 => (
        IntroductionStepKind.somethingYoureInto.label,
        null,
        [
          if (interest != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(interest.labelFor(controller.language))),
            ),
          if (demo != null) ...[
            _ChatBubble.app(demo.question),
            _ChatBubble.learner(demo.sampleAnswer, icon: Icons.mic_none),
          ],
        ],
      ),
      2 => (
        IntroductionStepKind.recommendation.label,
        null,
        [
          for (final (title, item) in [
            (IntroductionContent.walkthroughReadTitle, readExample),
            (
              IntroductionContent.walkthroughWatchTitle,
              IntroductionContent.walkthroughWatchExample,
            ),
            (
              IntroductionContent.walkthroughListenTitle,
              IntroductionContent.walkthroughListenExample,
            ),
          ])
            if (item != null) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    color: introductionLabelColor(
                      IntroductionStepKind.recommendation,
                    ),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CompactRecommendationCard(item: item),
            ],
        ],
      ),
      _ => (
        IntroductionContent.walkthroughFeedbackLabel,
        IntroductionContent.walkthroughFeedbackHeading,
        [
          if (demo != null) ...[
            _highlightedAnswer(demo),
            if (_selectedPoint != null)
              _pointCard(demo.points[_selectedPoint!], _selectedPoint!),
          ],
        ],
      ),
    };

    final color = switch (_part) {
      0 => introductionLabelColor(IntroductionStepKind.friendlyOpener),
      1 => introductionLabelColor(IntroductionStepKind.somethingYoureInto),
      2 => introductionLabelColor(IntroductionStepKind.recommendation),
      _ => introductionFeedbackLabelColor,
    };

    return IntroductionStepFrame(
      key: ValueKey('walkthrough-$_part'),
      label: label,
      labelColor: color,
      onStopForNow: widget.onStopForNow,
      bottomAction: _part < _partCount - 1
          ? next
          : PrimaryActionButton(
              label: IntroductionContent.walkthroughYourTurnButton,
              onPressed: _selectedPoint == null && demo != null
                  ? null
                  : widget.onFinished,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressDots(count: _partCount, current: _part, color: color),
          // The heading sits under the dots, so the dots are in the same
          // place on every part (only the feedback part has a heading).
          if (heading != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Sora',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 32 / 24,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ...body,
        ],
      ),
    );
  }

  /// The sample answer in a learner bubble, highlighted the way the app's
  /// results screen highlights: each phrase in bold in its category's
  /// colour, and tappable. Under it, the four categories and their colours.
  Widget _highlightedAnswer(ShowMeDemo demo) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final response = demo.toCorrectionResponse();
    final spans = buildHighlightedSpans(
      text: demo.sampleAnswer,
      corrections: response.corrections,
      color: AppColors.cyan,
      colorOf: (item) => item.category.color,
      recognizerOf: (item) {
        final index = demo.points.indexWhere(
          (point) => point.originalPhrase == item.originalPhrase,
        );
        final recognizer = TapGestureRecognizer()
          ..onTap = () => setState(() => _selectedPoint = index);
        _recognizers.add(recognizer);
        return recognizer;
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          key: const ValueKey('walkthrough-categories'),
          alignment: WrapAlignment.start,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final category in ErrorCategory.values)
              if (category != ErrorCategory.other)
                IntrinsicWidth(
                  child: CategoryPill(
                    label: category.label,
                    color: category.color,
                  ),
                ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        // The sample answer, in a container the same width and shape as the
        // point card below it.
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
          ),
          child: Text.rich(
            TextSpan(children: spans),
            key: const ValueKey('walkthrough-highlighted-answer'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              height: 24 / 16,
            ),
          ),
        ),
      ],
    );
  }

  /// The tapped point: its category and Save on one row, then what was said,
  /// the suggestion and the reason, kept compact so the screen does not need
  /// scrolling.
  Widget _pointCard(DemoFeedbackPoint point, int index) {
    final isSaved = _savedPoints.contains(index);
    return Container(
      key: const ValueKey('walkthrough-point-card'),
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: point.category.color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryPill(
                label: point.category.label,
                color: point.category.color,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: isSaved
                    ? null
                    : () => setState(() => _savedPoints.add(index)),
                icon: Icon(isSaved ? Icons.check : Icons.bookmark_border),
                label: Text(isSaved ? 'Saved' : 'Save'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  disabledForegroundColor: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Text(
                point.originalPhrase,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.textSecondary,
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                color: AppColors.textSecondary,
                size: 16,
              ),
              Text(
                point.correctedPhrase,
                style: TextStyle(
                  color: point.category.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            point.shortExplanation,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dots showing which part of the walk-through is showing.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.count,
    required this.current,
    required this.color,
  });

  final int count;
  final int current;

  /// The colour of the current part's label; the dots take it on.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('walkthrough-progress'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= current ? color : AppColors.textDisabled,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// One message in the walk-through's small chats: the app's on the left,
/// the sample learner's on the right with a small icon saying whether it was
/// typed or spoken.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble.app(String this.text)
    : rich = null,
      icon = null,
      fromApp = true;

  const _ChatBubble.learner(String this.text, {required this.icon})
    : rich = null,
      fromApp = false;

  final String? text;
  final TextSpan? rich;
  final IconData? icon;
  final bool fromApp;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 16,
      height: 24 / 16,
    );
    final content = rich != null
        ? Text.rich(rich!, style: style)
        : Text(text!, style: style);
    return Align(
      alignment: fromApp ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: AppSpacing.md),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: fromApp
              ? AppColors.surface
              : AppColors.cyan.withValues(alpha: 0.18),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromApp ? 4 : 16),
            bottomRight: Radius.circular(fromApp ? 16 : 4),
          ),
        ),
        child: icon == null
            ? content
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3, right: 8),
                    child: Icon(icon, size: 16, color: AppColors.cyan),
                  ),
                  Flexible(child: content),
                ],
              ),
      ),
    );
  }
}

/// The end screen's two buttons (task 1.4): "See suggestions" walks through
/// the feedback on the two answers; "Not now" leaves them in History.
class _EndStep extends StatelessWidget {
  const _EndStep({
    required this.isGettingSuggestions,
    required this.onSeeSuggestions,
    required this.onNotNow,
  });

  final bool isGettingSuggestions;
  final Future<void> Function() onSeeSuggestions;
  final Future<void> Function() onNotNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryActionButton(
          label: isGettingSuggestions
              ? 'Getting your suggestions'
              : 'See suggestions',
          isLoading: isGettingSuggestions,
          onPressed: onSeeSuggestions,
        ),
        const SizedBox(height: AppSpacing.md),
        _OutlinedChoiceButton(
          label: 'Not now',
          onPressed: isGettingSuggestions ? null : onNotNow,
        ),
      ],
    );
  }
}

/// A small recommendation card for the walk-through's examples: an icon for
/// the kind of item (or its thumbnail), the title and where it comes from.
class _CompactRecommendationCard extends StatelessWidget {
  const _CompactRecommendationCard({required this.item});

  final RecommendationItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      RecommendationType.article => Icons.article_outlined,
      RecommendationType.video => Icons.play_circle_outline,
      RecommendationType.other => Icons.headphones_outlined,
    };
    final iconBox = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.cyan, size: 28),
    );
    final thumbnailUrl = item.thumbnailUrl;
    return Container(
      key: ValueKey('walkthrough-example-${item.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                thumbnailUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => iconBox,
              ),
            )
          else
            iconBox,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.source,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
