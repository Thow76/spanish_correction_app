import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/mic_control.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/text_input_panel.dart';
import '../../write/application/transcription_service.dart';
import '../../write/application/transcription_service_exception.dart';
import '../application/voice_recorder.dart';

/// The "Something you're into" step's answer: the microphone, then the words
/// heard in a box the learner can correct, then Send (task 1.3).
///
/// It records and transcribes as the Check a phrase page does: the same
/// microphone control, the same sixty-second limit, the same transcription
/// service.
class SpokenAnswerStep extends StatefulWidget {
  const SpokenAnswerStep({
    required this.recorder,
    required this.transcriptionService,
    required this.language,
    required this.onSend,
    super.key,
  });

  final VoiceRecorder recorder;
  final TranscriptionService transcriptionService;
  final Language language;
  final Future<void> Function(String answer) onSend;

  @override
  State<SpokenAnswerStep> createState() => _SpokenAnswerStepState();
}

class _SpokenAnswerStepState extends State<SpokenAnswerStep> {
  static const _characterLimit = 600;
  static const _recordingLimitSeconds = 60;

  final _controller = TextEditingController();
  Timer? _recordingTimer;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isSending = false;
  int _secondsRemaining = _recordingLimitSeconds;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    if (_isRecording) {
      unawaited(widget.recorder.stop());
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MicControl(
          onTap: _isTranscribing || _isSending ? null : _handleMicTap,
          isRecording: _isRecording,
          isTranscribing: _isTranscribing,
          secondsRemaining: _secondsRemaining,
          idleLabel: 'Tap to record',
          activeLabel: 'Tap to stop',
          transcribingLabel: 'Transcribing...',
        ),
        if (hasText) ...[
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 140,
            child: TextInputPanel(
              controller: _controller,
              characterLimit: _characterLimit,
              hintText: '',
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'You can correct the words before sending.',
            style: TextStyle(fontSize: 13),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryActionButton(
          label: 'Send',
          isLoading: _isSending,
          onPressed: !hasText || _isRecording || _isTranscribing ? null : _send,
        ),
      ],
    );
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    try {
      await widget.onSend(_controller.text.trim());
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleMicTap() async {
    if (_isRecording) {
      await _stopAndTranscribe();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    try {
      if (!await widget.recorder.hasPermission()) {
        _showSnackBar('Microphone permission is required to record audio.');
        return;
      }
      await widget.recorder.start();
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecording = true;
        _secondsRemaining = _recordingLimitSeconds;
      });
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        final next = _secondsRemaining - 1;
        setState(() => _secondsRemaining = next);
        if (next <= 0) {
          _recordingTimer?.cancel();
          _stopAndTranscribe(showLimitMessage: true);
        }
      });
    } catch (_) {
      _showSnackBar('Unable to record audio - please try again.');
    }
  }

  Future<void> _stopAndTranscribe({bool showLimitMessage = false}) async {
    _recordingTimer?.cancel();
    if (!_isRecording) {
      return;
    }
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });
    try {
      final path = await widget.recorder.stop();
      if (showLimitMessage) {
        _showSnackBar('Recording limit reached');
      }
      if (path == null) {
        throw const TranscriptionServiceException(
          TranscriptionFailureReason.apiFailure,
          'No recording path returned.',
        );
      }
      final transcript = await widget.transcriptionService.transcribeAudio(
        path,
        widget.language,
      );
      if (!mounted) {
        return;
      }
      _controller.text = transcript.characters.take(_characterLimit).toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    } on TranscriptionServiceException catch (error) {
      _showSnackBar(switch (error.reason) {
        TranscriptionFailureReason.missingConfiguration =>
          'OpenAI key is missing. Put it in secrets/openai_key.txt and run the app again.',
        TranscriptionFailureReason.networkUnavailable =>
          'No internet available. Please check your connection.',
        TranscriptionFailureReason.apiFailure ||
        TranscriptionFailureReason.invalidResponse =>
          'Unable to transcribe audio - please try again.',
      });
    } catch (_) {
      _showSnackBar('Unable to transcribe audio - please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
          _secondsRemaining = _recordingLimitSeconds;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
