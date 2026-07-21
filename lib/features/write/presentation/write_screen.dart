import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/character_counter.dart';
import '../../../shared/widgets/divider_label.dart';
import '../../../shared/widgets/mic_control.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/text_input_panel.dart';
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
    required this.keyboardVisible,
    super.key,
  });

  final SubmitCorrectionUseCase submitCorrectionUseCase;
  final SaveCorrectionUseCase saveCorrectionUseCase;
  final TranscriptionService transcriptionService;
  final Language language;
  final bool keyboardVisible;

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
    final keyboardVisible = widget.keyboardVisible;
    final count = _controller.text.characters.length;

    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 48, 16, keyboardVisible ? 0 : 24),
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
                      child: TextInputPanel(
                        controller: _controller,
                        characterLimit: _characterLimit,
                        onChanged: _handleTextChanged,
                        hintText: _str(
                          'Type or paste your Spanish text here...',
                          'Type or paste your Portuguese text here...',
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CharacterCounter(count: count, limit: _characterLimit),
                    if (!keyboardVisible) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const DividerLabel(label: 'or'),
                      const SizedBox(height: AppSpacing.md),
                      MicControl(
                        onTap: _isTranscribing ? null : _handleMicTap,
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
      final response = await widget.submitCorrectionUseCase(
        _controller.text.trim(),
        widget.language,
      );

      if (!mounted) {
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
        'OpenAI API key is missing. Run with --dart-define=OPENAI_API_KEY=...',
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
