import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/enums/language.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../write/application/transcription_service.dart';
import '../../write/application/transcription_service_exception.dart';
import '../domain/game_question.dart';
import '../domain/game_session.dart';

class PromptTranslationGameScreen extends StatefulWidget {
  const PromptTranslationGameScreen({
    required this.repositoryController,
    required this.transcriptionService,
    required this.language,
    super.key,
  });

  final CorrectionRepositoryController repositoryController;
  final TranscriptionService transcriptionService;
  final Language language;

  @override
  State<PromptTranslationGameScreen> createState() =>
      _PromptTranslationGameScreenState();
}

enum _GamePhase { prompt, reveal, summary }

class _PromptTranslationGameScreenState
    extends State<PromptTranslationGameScreen> {
  static const _answerLimit = 600;
  static const _recordingLimitSeconds = 60;

  final _answerController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _random = Random();
  Timer? _recordingTimer;
  GameSession? _session;
  _GamePhase _phase = _GamePhase.prompt;
  String _submittedAnswer = '';
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordingSecondsRemaining = _recordingLimitSeconds;

  String _str(String es, String pt) => switch (widget.language) {
    Language.spanish => es,
    Language.portuguese => pt,
  };

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _str('Traducir frases', 'Traduzir frases');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                AppHeader(
                  title: title,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.cyan),
                  )
                else if (_session == null)
                  EmptyStatePanel(
                    icon: Icons.translate,
                    title: _str('Nada para practicar', 'Nada para praticar'),
                    message: _str(
                      'Guarda algunas correcciones para empezar a practicar.',
                      'Salve algumas correções para começar a praticar.',
                    ),
                  )
                else
                  switch (_phase) {
                    _GamePhase.prompt => _PromptPhase(
                      session: _session!,
                      answerController: _answerController,
                      answerLimit: _answerLimit,
                      isRecording: _isRecording,
                      isTranscribing: _isTranscribing,
                      recordingSecondsRemaining: _recordingSecondsRemaining,
                      onAnswerChanged: (_) => setState(() {}),
                      onMicTap: _isTranscribing ? null : _handleMicTap,
                      onReveal: _revealAnswer,
                      str: _str,
                    ),
                    _GamePhase.reveal => _RevealPhase(
                      question: _session!.currentQuestion,
                      submittedAnswer: _submittedAnswer,
                      onCorrect: () => _recordRating(isCorrect: true),
                      onIncorrect: () => _recordRating(isCorrect: false),
                      str: _str,
                    ),
                    _GamePhase.summary => _SummaryPhase(
                      session: _session!,
                      onPlayAgain: _startSession,
                      onReturn: () => Navigator.of(context).pop(),
                      str: _str,
                    ),
                  },
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _phase = _GamePhase.prompt;
      _submittedAnswer = '';
      _answerController.clear();
    });

    await widget.repositoryController.setActiveLanguage(widget.language);

    if (!mounted) {
      return;
    }

    final eligibleCorrections =
        widget.repositoryController.savedCorrections
            .where((correction) => correction.promptPhrase.trim().isNotEmpty)
            .toList()
          ..shuffle(_random);

    final questions = eligibleCorrections
        .take(10)
        .map((correction) {
          return GameQuestion(
            source: correction,
            promptPhrase: correction.promptPhrase.trim(),
            expectedAnswer: correction.correctedSentence,
          );
        })
        .toList(growable: false);

    setState(() {
      _session = questions.isEmpty ? null : GameSession(questions: questions);
      _isLoading = false;
    });
  }

  void _revealAnswer() {
    setState(() {
      _submittedAnswer = _answerController.text.trim();
      _phase = _GamePhase.reveal;
    });
  }

  void _recordRating({required bool isCorrect}) {
    final nextSession = _session!.recordAnswer(isCorrect: isCorrect);
    setState(() {
      _session = nextSession;
      _submittedAnswer = '';
      _answerController.clear();
      _phase = nextSession.isComplete ? _GamePhase.summary : _GamePhase.prompt;
    });
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
        _showSnackBar(
          _str(
            'Se necesita permiso para usar el micrófono.',
            'É necessário permitir o uso do microfone.',
          ),
        );
        return;
      }

      final temporaryDirectory = await getTemporaryDirectory();
      final audioPath =
          '${temporaryDirectory.path}/learn-recording-${DateTime.now().microsecondsSinceEpoch}.wav';

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
      if (mounted) {
        _showSnackBar(
          _str('No se pudo transcribir.', 'Não foi possível transcrever.'),
        );
      }
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
        _showSnackBar(
          _str('Límite de grabación alcanzado', 'Limite de gravação atingido'),
        );
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
          .take(_answerLimit)
          .toString();
      _answerController.text = limitedTranscript;
      _answerController.selection = TextSelection.collapsed(
        offset: _answerController.text.length,
      );
      setState(() {});
    } on TranscriptionServiceException catch (error) {
      if (mounted) {
        _showSnackBar(_messageForTranscriptionError(error));
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          _str('No se pudo transcribir.', 'Não foi possível transcrever.'),
        );
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForTranscriptionError(TranscriptionServiceException error) {
    return switch (error.reason) {
      TranscriptionFailureReason.missingConfiguration => _str(
        'Falta la clave de OpenAI.',
        'A chave da OpenAI está ausente.',
      ),
      TranscriptionFailureReason.networkUnavailable => _str(
        'Sin conexión. Revisa tu internet.',
        'Sem conexão. Verifique sua internet.',
      ),
      TranscriptionFailureReason.apiFailure ||
      TranscriptionFailureReason.invalidResponse => _str(
        'No se pudo transcribir.',
        'Não foi possível transcrever.',
      ),
    };
  }
}

class _PromptPhase extends StatelessWidget {
  const _PromptPhase({
    required this.session,
    required this.answerController,
    required this.answerLimit,
    required this.isRecording,
    required this.isTranscribing,
    required this.recordingSecondsRemaining,
    required this.onAnswerChanged,
    required this.onMicTap,
    required this.onReveal,
    required this.str,
  });

  final GameSession session;
  final TextEditingController answerController;
  final int answerLimit;
  final bool isRecording;
  final bool isTranscribing;
  final int recordingSecondsRemaining;
  final ValueChanged<String> onAnswerChanged;
  final VoidCallback? onMicTap;
  final VoidCallback onReveal;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    final question = session.currentQuestion;
    final answer = answerController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressLabel(
          text: str(
            'Pregunta ${session.currentIndex + 1} de ${session.totalCount}',
            'Pergunta ${session.currentIndex + 1} de ${session.totalCount}',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PromptCard(text: question.promptPhrase),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 168,
          child: _AnswerInputPanel(
            controller: answerController,
            answerLimit: answerLimit,
            hintText: str(
              'Escribe o graba tu respuesta...',
              'Escreva ou grave sua resposta...',
            ),
            onChanged: onAnswerChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _MicControl(
          onTap: onMicTap,
          isRecording: isRecording,
          isTranscribing: isTranscribing,
          secondsRemaining: recordingSecondsRemaining,
          idleLabel: str('Toca para grabar', 'Toque para gravar'),
          activeLabel: str('Toca para detener', 'Toque para parar'),
          transcribingLabel: str('Transcribiendo...', 'Transcrevendo...'),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryActionButton(
          label: str('Ver respuesta', 'Ver resposta'),
          onPressed: answer.isEmpty || isRecording || isTranscribing
              ? null
              : onReveal,
        ),
      ],
    );
  }
}

class _RevealPhase extends StatelessWidget {
  const _RevealPhase({
    required this.question,
    required this.submittedAnswer,
    required this.onCorrect,
    required this.onIncorrect,
    required this.str,
  });

  final GameQuestion question;
  final String submittedAnswer;
  final VoidCallback onCorrect;
  final VoidCallback onIncorrect;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AnswerComparisonPanel(
          title: str('Tu respuesta', 'Sua resposta'),
          text: submittedAnswer.isEmpty ? '...' : submittedAnswer,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _AnswerComparisonPanel(
          title: str('Respuesta esperada', 'Resposta esperada'),
          text: question.expectedAnswer,
          color: AppColors.mint,
        ),
        const SizedBox(height: AppSpacing.md),
        _ContextPanel(text: question.source.shortExplanation),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(
              child: PrimaryActionButton(
                label: str('Casi', 'Quase'),
                onPressed: onIncorrect,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryActionButton(
                label: str('Lo logré', 'Acertei'),
                onPressed: onCorrect,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryPhase extends StatelessWidget {
  const _SummaryPhase({
    required this.session,
    required this.onPlayAgain,
    required this.onReturn,
    required this.str,
  });

  final GameSession session;
  final VoidCallback onPlayAgain;
  final VoidCallback onReturn;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.16)),
          ),
          child: Column(
            children: [
              Text(
                '${session.correctCount} / ${session.totalCount}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontFamily: 'Sora',
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                str('Resultado', 'Resultado'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryActionButton(
          label: str('Jugar de nuevo', 'Jogar de novo'),
          onPressed: onPlayAgain,
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryActionButton(
          label: str('Volver', 'Voltar'),
          onPressed: onReturn,
        ),
      ],
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Sora',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 32 / 24,
        ),
      ),
    );
  }
}

class _AnswerInputPanel extends StatelessWidget {
  const _AnswerInputPanel({
    required this.controller,
    required this.answerLimit,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int answerLimit;
  final String hintText;
  final ValueChanged<String> onChanged;

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
        inputFormatters: [LengthLimitingTextInputFormatter(answerLimit)],
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

class _AnswerComparisonPanel extends StatelessWidget {
  const _AnswerComparisonPanel({
    required this.title,
    required this.text,
    required this.color,
  });

  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 21 / 14,
        ),
      ),
    );
  }
}
