import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/character_counter.dart';
import '../../../shared/widgets/divider_label.dart';
import '../../../shared/widgets/mic_control.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/text_input_panel.dart';
import '../../profile/application/profile_repository.dart';
import '../../write/application/transcription_service.dart';
import '../../write/application/transcription_service_exception.dart';
import '../application/introduction_controller.dart';
import '../content/interest.dart';
import '../domain/introduction_step.dart';
import 'answer_recorder.dart';

/// The introduction (decision A1): two warm-ups, the interest chips, about
/// three fuller questions and an end screen, one step at a time.
///
/// Shown once per install, between the language choice and the app
/// (`SpanishCorrectionApp`). It reads and saves progress through an
/// [IntroductionController]; [onLeave] is called when the learner leaves,
/// whether by "Stop for now" or from the end screen.
///
/// Until task 1.4 the end screen has a single "Continue to the app" button;
/// 1.4 replaces it with "See suggestions" and "Not now".
class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({
    required this.language,
    required this.profileRepository,
    required this.transcriptionService,
    required this.onLeave,
    this.createRecorder = MicrophoneAnswerRecorder.new,
    super.key,
  });

  final Language language;
  final ProfileRepository profileRepository;
  final TranscriptionService transcriptionService;
  final VoidCallback onLeave;

  /// Makes the recorder for spoken answers. Tests pass a fake.
  final AnswerRecorder Function() createRecorder;

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  static const _characterLimit = 600;
  static const _recordingLimitSeconds = 60;

  late final IntroductionController _controller;
  final _textController = TextEditingController();
  AnswerRecorder? _recorder;
  Timer? _recordingTimer;
  String? _shownStepId;
  bool _hasShownLimitMessage = false;
  bool _isSending = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _hasLeft = false;
  int _recordingSecondsRemaining = _recordingLimitSeconds;

  @override
  void initState() {
    super.initState();
    _controller = IntroductionController(
      profileRepository: widget.profileRepository,
      language: widget.language,
    );
    _controller.addListener(_handleStepChange);
    _controller.load();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder?.dispose();
    _controller.removeListener(_handleStepChange);
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// Clears the answer box when a new step arrives, and leaves if the
  /// introduction turns out to be complete already.
  void _handleStepChange() {
    final step = _controller.step;
    if (_controller.isLoaded && step == null) {
      _leave();
      return;
    }
    if (step != null && step.id != _shownStepId) {
      _shownStepId = step.id;
      _textController.clear();
      _hasShownLimitMessage = false;
    }
  }

  void _leave() {
    if (_hasLeft) {
      return;
    }
    _hasLeft = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onLeave();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Read above the Scaffold: here MediaQuery still carries the real
    // keyboard inset (the Scaffold zeroes it for its body).
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final step = _controller.step;
        if (step == null) {
          return const Scaffold(backgroundColor: AppColors.background);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 390),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        24,
                        16,
                        keyboardVisible ? 0 : 24,
                      ),
                      child: switch (step.kind) {
                        IntroductionStepKind.warmUp ||
                        IntroductionStepKind.fullerQuestion => _buildAnswerStep(
                          step,
                          keyboardVisible: keyboardVisible,
                        ),
                        IntroductionStepKind.interests => _buildInterestsStep(
                          step,
                        ),
                        IntroductionStepKind.endScreen => _buildEndScreen(step),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Warm-ups and fuller questions
  // ---------------------------------------------------------------------------

  Widget _buildAnswerStep(
    IntroductionStep step, {
    required bool keyboardVisible,
  }) {
    final count = _textController.text.characters.length;
    final busy = _isRecording || _isTranscribing || _isSending;
    final textHint = switch (step.answerMode) {
      AnswerMode.spoken => 'Your answer will appear here after you speak.',
      _ => 'Type your answer here...',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(
          label: step.isWarmUp
              ? 'Warm-up ${step.number} of ${step.count}'
              : 'Question ${step.number} of ${step.count}',
          onStop: busy ? null : _stopForNow,
        ),
        const SizedBox(height: AppSpacing.md),
        _QuestionText(step.text),
        if (step.hint case final hint?) ...[
          const SizedBox(height: AppSpacing.sm),
          _HintText(hint),
        ],
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: TextInputPanel(
            controller: _textController,
            characterLimit: _characterLimit,
            onChanged: _handleTextChanged,
            hintText: textHint,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CharacterCounter(count: count, limit: _characterLimit),
        if (step.showsMicrophone && !keyboardVisible) ...[
          const SizedBox(height: AppSpacing.xl),
          if (step.answerMode == AnswerMode.typedOrSpoken) ...[
            const DividerLabel(label: 'or'),
            const SizedBox(height: AppSpacing.md),
          ],
          MicControl(
            onTap: _isTranscribing || _isSending ? null : _handleMicTap,
            isRecording: _isRecording,
            isTranscribing: _isTranscribing,
            secondsRemaining: _recordingSecondsRemaining,
            idleLabel: 'Tap to record',
            activeLabel: 'Tap to stop',
            transcribingLabel: 'Transcribing...',
          ),
          const SizedBox(height: AppSpacing.xxl),
        ] else
          const SizedBox(height: AppSpacing.xl),
        PrimaryActionButton(
          label: 'Send',
          isLoading: _isSending,
          onPressed: count == 0 || busy ? null : () => _send(step),
        ),
      ],
    );
  }

  void _handleTextChanged(String value) {
    final count = value.characters.length;
    if (count < _characterLimit) {
      _hasShownLimitMessage = false;
    }
    if (count == _characterLimit && !_hasShownLimitMessage) {
      _hasShownLimitMessage = true;
      _showSnackBar('Character limit reached');
    }
    setState(() {});
  }

  Future<void> _send(IntroductionStep step) async {
    if (_isSending) {
      return;
    }
    final answer = _textController.text.trim();
    if (answer.isEmpty) {
      return;
    }
    setState(() => _isSending = true);
    try {
      if (step.isWarmUp) {
        await _controller.answerWarmUp(answer);
      } else {
        await _controller.answerFullerQuestion(answer);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleMicTap() async {
    if (_isRecording) {
      await _stopRecordingAndTranscribe();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final recorder = _recorder ??= widget.createRecorder();
      if (!await recorder.hasPermission()) {
        _showSnackBar('Microphone permission is required to record audio.');
        return;
      }
      await recorder.start();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecording = true;
        _recordingSecondsRemaining = _recordingLimitSeconds;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        final nextValue = _recordingSecondsRemaining - 1;
        setState(() => _recordingSecondsRemaining = nextValue);
        if (nextValue <= 0) {
          _recordingTimer?.cancel();
          _stopRecordingAndTranscribe(showLimitMessage: true);
        }
      });
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to transcribe audio - please try again.');
      }
    }
  }

  Future<void> _stopRecordingAndTranscribe({
    bool showLimitMessage = false,
  }) async {
    _recordingTimer?.cancel();
    final recorder = _recorder;
    if (!_isRecording || recorder == null) {
      return;
    }
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    try {
      final audioPath = await recorder.stop();
      if (showLimitMessage && mounted) {
        _showSnackBar('Recording limit reached');
      }
      if (audioPath == null) {
        throw const TranscriptionServiceException(
          TranscriptionFailureReason.apiFailure,
          'No recording path returned.',
        );
      }
      final transcript = await widget.transcriptionService.transcribeAudio(
        audioPath,
        widget.language,
      );
      if (!mounted) {
        return;
      }
      final limitedTranscript = transcript.characters
          .take(_characterLimit)
          .toString();
      _textController.text = limitedTranscript;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
      _handleTextChanged(limitedTranscript);
    } on TranscriptionServiceException catch (error) {
      if (mounted) {
        _showSnackBar(_messageForTranscriptionError(error));
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Unable to transcribe audio - please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _recordingSecondsRemaining = _recordingLimitSeconds;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Interests
  // ---------------------------------------------------------------------------

  Widget _buildInterestsStep(IntroductionStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(label: 'Your interests', onStop: _stopForNow),
        const SizedBox(height: AppSpacing.md),
        _QuestionText(step.text),
        if (step.hint case final hint?) ...[
          const SizedBox(height: AppSpacing.sm),
          _HintText(hint),
        ],
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final interest in _controller.interests)
                  _InterestChip(
                    interest: interest,
                    language: widget.language,
                    selected: _controller.isInterestChosen(interest.id),
                    onTap: () => _controller.toggleInterest(interest.id),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryActionButton(
          label: 'Continue',
          onPressed: _controller.continueFromInterests,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // End screen
  // ---------------------------------------------------------------------------

  Widget _buildEndScreen(IntroductionStep step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(label: 'All done', onStop: null, showStop: false),
        const Spacer(),
        _QuestionText(step.text),
        const Spacer(),
        PrimaryActionButton(
          label: 'Continue to the app',
          isLoading: _isSending,
          onPressed: _isSending ? null : _finish,
        ),
      ],
    );
  }

  Future<void> _finish() async {
    setState(() => _isSending = true);
    try {
      await _controller.finish();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
    _leave();
  }

  // ---------------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------------

  void _stopForNow() {
    if (_controller.stopForNow() == StopOutcome.app) {
      _leave();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForTranscriptionError(TranscriptionServiceException error) {
    return switch (error.reason) {
      TranscriptionFailureReason.missingConfiguration =>
        'OpenAI API key is missing. Run with --dart-define=OPENAI_API_KEY=...',
      TranscriptionFailureReason.networkUnavailable =>
        'No internet available. Please check your connection.',
      TranscriptionFailureReason.apiFailure ||
      TranscriptionFailureReason.invalidResponse =>
        'Unable to transcribe audio - please try again.',
    };
  }
}

/// The small line at the top of a step ("Warm-up 1 of 2") with "Stop for
/// now" on the right. [onStop] null greys the button out (while a recording
/// or a send is in flight); [showStop] false leaves it out altogether.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.label,
    required this.onStop,
    this.showStop = true,
  });

  final String label;
  final VoidCallback? onStop;
  final bool showStop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (showStop)
            TextButton(
              onPressed: onStop,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text(
                'Stop for now',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionText extends StatelessWidget {
  const _QuestionText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Sora',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 30 / 22,
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 20 / 14,
      ),
    );
  }
}

/// One interest chip, labelled in the language being learnt (decision A2).
class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.interest,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final Interest interest;
  final Language language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(interest.labelFor(language)),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.cyan.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 15,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.cyan
            : AppColors.textPrimary.withValues(alpha: 0.18),
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }
}
