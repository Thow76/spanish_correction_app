import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../corrections/application/correction_service_exception.dart';
import '../../corrections/application/submit_correction_use_case.dart';
import '../../corrections/domain/correction_item.dart';
import '../../corrections/presentation/corrections_screen.dart';
import '../../saved/application/save_correction_use_case.dart';
import '../application/transcription_service.dart';
import '../application/transcription_service_exception.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({
    required this.submitCorrectionUseCase,
    required this.saveCorrectionUseCase,
    required this.transcriptionService,
    required this.language,
    super.key,
  });

  final SubmitCorrectionUseCase submitCorrectionUseCase;
  final SaveCorrectionUseCase saveCorrectionUseCase;
  final TranscriptionService transcriptionService;
  final Language language;

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  static const _characterLimit = 600;
  static const _recordingLimitSeconds = 60;

  final _controller = TextEditingController();
  final _audioRecorder = AudioRecorder();
  Timer? _recordingTimer;
  bool _hasShownLimitMessage = false;
  bool _isReviewing = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordingSecondsRemaining = _recordingLimitSeconds;

  // Returns the Spanish string for Language.spanish, Portuguese for Language.portuguese.
  String _str(String es, String pt) => switch (widget.language) {
    Language.spanish => es,
    Language.portuguese => pt,
  };

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = _controller.text.characters.length;
    final progress = count / _characterLimit;
    final isNearLimit = count >= 560;
    final progressColor = isNearLimit ? AppColors.coral : AppColors.cyan;

    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppHeader(title: 'Correct'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      "Write or record - we'll handle the rest.",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        height: 24 / 16,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: _TextInputPanel(
                        controller: _controller,
                        onChanged: _handleTextChanged,
                        hintText: _str(
                          'Type or paste your Spanish text here...',
                          'Type or paste your Portuguese text here...',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CharacterCounter(
                      count: count,
                      limit: _characterLimit,
                      progress: progress,
                      color: progressColor,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _DividerLabel(label: 'or'),
                    const SizedBox(height: AppSpacing.md),
                    _MicControl(
                      onTap: _isTranscribing ? null : _handleMicTap,
                      isRecording: _isRecording,
                      isTranscribing: _isTranscribing,
                      secondsRemaining: _recordingSecondsRemaining,
                      idleLabel: 'Tap to record',
                      activeLabel: 'Tap to stop',
                      transcribingLabel: 'Transcribing...',
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryActionButton(
                      label: _isReviewing ? 'Reviewing' : 'Correct',
                      isLoading: _isReviewing,
                      onPressed: count == 0 || _isRecording || _isTranscribing
                          ? null
                          : _reviewText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reviewText() async {
    if (_isReviewing) {
      return;
    }

    setState(() => _isReviewing = true);

    try {
      final result = await widget.submitCorrectionUseCase(
        _controller.text.trim(),
        widget.language,
      );

      if (!mounted) {
        return;
      }

      if (result.wasQueued) {
        _showSnackBar('No internet available. Submission queued for sync.');
        return;
      }

      final response = result.response;
      if (response == null) {
        _showSnackBar('Something went wrong. Please try again.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return CorrectionsScreen(
              response: response,
              onSaveCorrection: (item) =>
                  _saveCorrection(item, response.correctedText),
            );
          },
        ),
      );
    } on CorrectionServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_messageForCorrectionError(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isReviewing = false);
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
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showSnackBar('Microphone permission is required to record audio.');
        return;
      }

      final temporaryDirectory = await getTemporaryDirectory();
      final audioPath =
          '${temporaryDirectory.path}/spanish-recording-${DateTime.now().microsecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          numChannels: 1,
          sampleRate: 16000,
        ),
        path: audioPath,
      );

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
      if (!mounted) {
        return;
      }
      _showSnackBar('Unable to transcribe audio - please try again.');
    }
  }

  Future<void> _stopRecordingAndTranscribe({
    bool showLimitMessage = false,
  }) async {
    _recordingTimer?.cancel();

    if (!_isRecording) {
      return;
    }

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    try {
      final audioPath = await _audioRecorder.stop();
      if (showLimitMessage && mounted) {
        _showSnackBar('Recording limit reached');
      }

      if (audioPath == null) {
        throw const TranscriptionServiceException(
          TranscriptionFailureReason.apiFailure,
          'No recording path returned.',
        );
      }

      final transcript = await widget.transcriptionService
          .transcribeAudio(audioPath, widget.language);

      if (!mounted) {
        return;
      }

      final limitedTranscript = transcript.characters
          .take(_characterLimit)
          .toString();
      _controller.text = limitedTranscript;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _handleTextChanged(limitedTranscript);
    } on TranscriptionServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_messageForTranscriptionError(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Unable to transcribe audio - please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _recordingSecondsRemaining = _recordingLimitSeconds;
        });
      }
    }
  }

  Future<void> _saveCorrection(
    CorrectionItem item,
    String correctedSentence,
  ) async {
    try {
      await widget.saveCorrectionUseCase(
        correction: item,
        originalSentence: _controller.text.trim(),
        correctedSentence: correctedSentence,
        language: widget.language,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar('Saved for later');
    } on CorrectionServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_messageForCorrectionError(error));
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnackBar('Something went wrong. Please try again.');
    }
  }

  String _messageForCorrectionError(CorrectionServiceException error) {
    return switch (error.reason) {
      CorrectionFailureReason.missingConfiguration =>
        'Gemini API key is missing. Run with --dart-define=GEMINI_API_KEY=...',
      CorrectionFailureReason.networkUnavailable =>
        'No internet available. Please check your connection.',
      CorrectionFailureReason.apiFailure ||
      CorrectionFailureReason.invalidResponse =>
        'Something went wrong. Please try again.',
    };
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

class _TextInputPanel extends StatelessWidget {
  const _TextInputPanel({
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        inputFormatters: [LengthLimitingTextInputFormatter(600)],
        onChanged: onChanged,
        cursorColor: AppColors.cyan,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          height: 24 / 15,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _CharacterCounter extends StatelessWidget {
  const _CharacterCounter({
    required this.count,
    required this.limit,
    required this.progress,
    required this.color,
  });

  final int count;
  final int limit;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: progress.clamp(0, 1),
            backgroundColor: AppColors.textDisabled.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$count / $limit',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.textDisabled)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        const Expanded(child: Divider(color: AppColors.textDisabled)),
      ],
    );
  }
}

class _MicControl extends StatelessWidget {
  const _MicControl({
    required this.onTap,
    required this.isRecording,
    required this.isTranscribing,
    required this.secondsRemaining,
    required this.idleLabel,
    required this.activeLabel,
    required this.transcribingLabel,
  });

  final VoidCallback? onTap;
  final bool isRecording;
  final bool isTranscribing;
  final int secondsRemaining;
  final String idleLabel;
  final String activeLabel;
  final String transcribingLabel;

  @override
  Widget build(BuildContext context) {
    final color = isRecording ? AppColors.coral : AppColors.cyan;
    final label = isTranscribing
        ? transcribingLabel
        : isRecording
        ? activeLabel
        : idleLabel;

    return Center(
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: isRecording ? 0.2 : 0.12),
                border: Border.all(
                  color: color.withValues(alpha: isRecording ? 1 : 0.4),
                  width: 2,
                ),
                boxShadow: isRecording
                    ? [
                        BoxShadow(
                          color: AppColors.coral.withValues(alpha: 0.32),
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              child: isTranscribing
                  ? const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.cyan,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isRecording ? Icons.stop : Icons.mic_none,
                      color: color,
                      size: 34,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isRecording) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatTimer(secondsRemaining),
              style: TextStyle(
                color: secondsRemaining <= 10
                    ? AppColors.coral
                    : AppColors.textPrimary,
                fontFamily: 'Sora',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimer(int value) {
    final safeValue = value.clamp(0, 60);
    final minutes = safeValue ~/ 60;
    final seconds = safeValue % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
