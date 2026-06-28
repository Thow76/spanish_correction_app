import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/enums/language.dart';
import '../../../core/models/walkthrough_exceptions.dart';
import '../../../core/models/walkthrough_question.dart';
import '../../../core/services/walkthrough_service.dart';
import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/text/correction_highlight_spans.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/character_counter.dart';
import '../../../shared/widgets/empty_state_panel.dart';
import '../../../shared/widgets/divider_label.dart';
import '../../../shared/widgets/mic_control.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../../shared/widgets/secondary_action_button.dart';
import '../../../shared/widgets/text_input_panel.dart';
import '../../corrections/application/correction_repository_controller.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/domain/correction_item.dart';
import '../../corrections/domain/error_category.dart';
import '../../write/application/transcription_service.dart';
import '../../write/application/transcription_service_exception.dart';
import '../application/grade_retranslation_use_case.dart';
import '../domain/game_question.dart';
import '../domain/game_session.dart';
import 'widgets/walkthrough_question_view.dart';
import 'widgets/walkthrough_result_view.dart';

class PromptTranslationGameScreen extends StatefulWidget {
  const PromptTranslationGameScreen({
    required this.repositoryController,
    required this.transcriptionService,
    required this.correctionService,
    required this.walkthroughService,
    required this.language,
    super.key,
  });

  final CorrectionRepositoryController repositoryController;
  final TranscriptionService transcriptionService;
  final CorrectionService correctionService;
  final WalkthroughService walkthroughService;
  final Language language;

  @override
  State<PromptTranslationGameScreen> createState() =>
      _PromptTranslationGameScreenState();
}

enum _GamePhase {
  prompt,
  reveal,
  walkthrough,
  walkthroughQuestion,
  walkthroughResult,
  summary,
}

class _PromptTranslationGameScreenState
    extends State<PromptTranslationGameScreen> {
  static const _answerLimit = 600;
  static const _recordingLimitSeconds = 60;

  final _answerController = TextEditingController();
  final _audioRecorder = AudioRecorder();
  final _random = Random();
  late final GradeRetranslationUseCase _grader;
  Timer? _recordingTimer;
  GameSession? _session;
  _GamePhase _phase = _GamePhase.prompt;
  String _submittedAnswer = '';
  bool _isLoading = true;
  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordingSecondsRemaining = _recordingLimitSeconds;

  // AI grade of the current re-translation (Chunk 2 use case). The AI proposes
  // a verdict; the user disposes via the retained self-mark. Reset per attempt.
  bool _isGrading = false;
  RetranslationGrade? _grade;
  Object? _gradeError;

  // Walkthrough intro state (Section 6a). Offered after a KEEP PRACTICING
  // attempt is scored. [_walkthroughQuestion] is the question captured at entry
  // — the session pointer has already advanced past it by then, so the intro and
  // the Yes-path service inputs read from this capture, not _session. The fetch
  // state is reset by [_advanceToNext] on the No path (and at session start).
  GameQuestion? _walkthroughQuestion;
  bool _isFetchingWalkthrough = false;
  WalkthroughException? _walkthroughError;
  List<WalkthroughQuestion>? _walkthroughQuestions;

  // Walkthrough score, captured once [WalkthroughQuestionView] completes and read
  // by the result phase.
  int _walkthroughCorrect = 0;
  int _walkthroughTotal = 0;

  // The session as it stood BEFORE the walkthrough-triggering attempt was
  // recorded (pointing at that phrase, with its pre-attempt counts). "Try again"
  // restores this so the same phrase is re-attempted fresh and the discarded
  // attempt is not double-counted. Null outside the walkthrough flow.
  GameSession? _sessionBeforeWalkthrough;

  String _str(String es, String pt) => switch (widget.language) {
    Language.spanish => es,
    Language.portuguese => pt,
  };

  @override
  void initState() {
    super.initState();
    _grader = GradeRetranslationUseCase(
      correctionService: widget.correctionService,
    );
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
                      isGrading: _isGrading,
                      grade: _grade,
                      gradeFailed: _gradeError != null,
                      onContinue: _continueAfterReveal,
                      onTryAgain: _tryAgainAfterReveal,
                      onWalkthrough: _walkthroughAfterReveal,
                      onSeeAnswer: _handleSeeAnswer,
                      str: _str,
                    ),
                    _GamePhase.walkthrough => _WalkthroughIntroPhase(
                      attempt: _submittedAnswer,
                      corrections: _grade?.corrections ?? const [],
                      isFetching: _isFetchingWalkthrough,
                      error: _walkthroughError,
                      onYes: _startWalkthrough,
                      onNo: _advanceToNext,
                      str: _str,
                    ),
                    _GamePhase.walkthroughQuestion => WalkthroughQuestionView(
                      questions: _walkthroughQuestions!,
                      onCompleted: _handleWalkthroughCompleted,
                      str: _str,
                    ),
                    _GamePhase.walkthroughResult => WalkthroughResultView(
                      correctCount: _walkthroughCorrect,
                      totalCount: _walkthroughTotal,
                      onContinue: _advanceToNext,
                      onTryAgain: _retrySamePhrase,
                      onSeeAnswer: _handleSeeAnswer,
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
      _resetAttemptState();
      _isLoading = true;
      _phase = _GamePhase.prompt;
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

  Future<void> _revealAnswer() async {
    final answer = _answerController.text.trim();
    final question = _session!.currentQuestion;
    setState(() {
      _submittedAnswer = answer;
      _phase = _GamePhase.reveal;
      _grade = null;
      _gradeError = null;
      _isGrading = true;
    });

    try {
      final grade = await _grader.call(
        attempt: answer,
        savedErrorCategory: question.source.category,
        language: widget.language,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _grade = grade;
        _isGrading = false;
      });
    } catch (error) {
      // No retry-in-place here (that is Section 6a): degrade gracefully to the
      // plain self-mark when the grade is unavailable.
      if (!mounted) {
        return;
      }
      setState(() {
        _gradeError = error;
        _isGrading = false;
      });
    }
  }

  /// Records the score for the current attempt and advances the session
  /// pointer, snapshotting the pre-record session and the just-answered question
  /// first. Pure field mutation — callers wrap it in [setState] and then pick a
  /// destination ([_continueAfterReveal] / [_walkthroughAfterReveal], and in
  /// Phase 5 the per-tier "Try again" path).
  ///
  /// Scoring is bundled into [GameSession.recordPoints], which ALSO advances
  /// `currentIndex`, so once this runs the session points at the *next*
  /// question. The just-answered question is captured into [_walkthroughQuestion]
  /// BEFORE recording (the walkthrough and any retry read this capture, not the
  /// now-advanced `_session.currentQuestion`); [_submittedAnswer]/[_grade] are
  /// left untouched for the intro.
  ///
  /// The pre-record snapshot ([_sessionBeforeWalkthrough]) is taken for EVERY
  /// tier, not just KEEP PRACTICING. Today only the walkthrough path reads it,
  /// but Phase 5 offers "Try again" on Bien hecho too, and that retry restores
  /// this snapshot to drop the discarded attempt's score — exactly as the
  /// keep-practicing retry has always done. Capturing it unconditionally is
  /// harmless on the advance path because [_advanceToNext] clears it.
  void _recordScore() {
    // Phase 2: the X/Y score is re-sourced from the AI tier, not a user
    // self-mark. Each tier carries a weight via [_pointsFor].
    final points = _pointsFor(_grade?.tier);
    _sessionBeforeWalkthrough = _session;
    _walkthroughQuestion = _session!.currentQuestion;
    _session = _session!.recordPoints(points: points);
  }

  /// Maps the AI re-translation [tier] to its session-score weight (Excelente =
  /// 2, Bien hecho = 1, Sigue practicando = 0). A null tier — an unavailable
  /// grade (offline/failed) — scores 0, matching the agreed miss fallback. The
  /// denominator is fixed at 2 per answered question by [GameSession.maxScore].
  int _pointsFor(RetranslationTier? tier) {
    switch (tier) {
      case RetranslationTier.excelente:
        return 2;
      case RetranslationTier.bienHecho:
        return 1;
      case RetranslationTier.siguePracticando:
      case null:
        return 0;
    }
  }

  /// Continue past the reveal screen: record the score and move on to the next
  /// phrase (or the summary). The forward path for the satisfied tiers
  /// (Excelente / Bien hecho) and the unavailable-grade fallback.
  void _continueAfterReveal() {
    setState(_recordScore);
    _advanceToNext();
  }

  /// Record the score and open the walkthrough intro for the just-answered
  /// phrase. Routes into the existing [_GamePhase.walkthrough]; [_recordScore]
  /// has already captured the phrase and the retry snapshot.
  void _walkthroughAfterReveal() {
    setState(() {
      _recordScore();
      _phase = _GamePhase.walkthrough;
    });
  }

  /// "Intentar de nuevo" on the Bien hecho reveal screen: record the score (to
  /// take the pre-record snapshot) then immediately restore it via
  /// [_retrySamePhrase], dropping this attempt's score and re-attempting the
  /// same phrase fresh. Mirrors the walkthrough-result retry; relies on the
  /// all-tier snapshot [_recordScore] now takes.
  void _tryAgainAfterReveal() {
    setState(_recordScore);
    _retrySamePhrase();
  }

  /// Clears every per-attempt and walkthrough field so the next attempt starts
  /// completely clean. The single source of truth for "what an attempt owns",
  /// shared by [_advanceToNext] and the retry path so neither can leak stale
  /// state. Does NOT touch [_session] or [_phase] — the caller sets those.
  void _resetAttemptState() {
    _submittedAnswer = '';
    _answerController.clear();
    _grade = null;
    _gradeError = null;
    _isGrading = false;
    _walkthroughQuestion = null;
    _isFetchingWalkthrough = false;
    _walkthroughError = null;
    _walkthroughQuestions = null;
    _walkthroughCorrect = 0;
    _walkthroughTotal = 0;
    _sessionBeforeWalkthrough = null;
  }

  /// Advance-only transition: clears the per-attempt state and swaps to the next
  /// phrase (or the summary). Does NOT call [GameSession.recordPoints] — the
  /// score was already recorded by [_recordScore] before any walkthrough intro
  /// was shown, so the No path reusing this cannot double-count. Pure setState,
  /// no Navigator.pop (a pop would exit the whole game).
  void _advanceToNext() {
    setState(() {
      _resetAttemptState();
      _phase = _session!.isComplete ? _GamePhase.summary : _GamePhase.prompt;
    });
  }

  /// "Try the full translation again" on the result screen: restores the session
  /// snapshot (re-pointing at the just-attempted phrase with its pre-attempt
  /// counts) and returns to a clean prompt. The discarded attempt's score is
  /// dropped, so the retry is a genuine fresh GRADED attempt — deliberately
  /// breaking the "walkthrough never re-scores" rule. If the retry also grades
  /// keep-practicing, the same path offers the walkthrough again.
  void _retrySamePhrase() {
    final snapshot = _sessionBeforeWalkthrough;
    if (snapshot == null) {
      return;
    }
    setState(() {
      _resetAttemptState();
      _session = snapshot;
      _phase = _GamePhase.prompt;
    });
  }

  /// Yes path on the walkthrough intro: fetches the multiple-choice questions.
  ///
  /// This is the first live exercise of [WalkthroughService] in the running
  /// app. On success it transitions to the stub question phase; on failure it
  /// surfaces the retry-in-place error state (the user stays on the intro). The
  /// three walkthrough exception types are caught distinctly even though v1
  /// shows a single user-facing message.
  Future<void> _startWalkthrough() async {
    final question = _walkthroughQuestion;
    final grade = _grade;
    if (question == null || grade == null) {
      return;
    }

    setState(() {
      _isFetchingWalkthrough = true;
      _walkthroughError = null;
    });

    try {
      final questions = await widget.walkthroughService.fetchQuestions(
        targetSentence: question.expectedAnswer,
        userAttempt: _submittedAnswer,
        englishSource: question.promptPhrase,
        corrections: grade.corrections,
        language: widget.language,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _walkthroughQuestions = questions;
        _isFetchingWalkthrough = false;
        // STUB: the question screen itself is a later section. For now we land
        // on a placeholder phase that reports how many questions were fetched.
        _phase = _GamePhase.walkthroughQuestion;
      });
    } on WalkthroughApiException catch (error) {
      _handleWalkthroughFailure(error);
    } on WalkthroughSchemaException catch (error) {
      _handleWalkthroughFailure(error);
    } on WalkthroughValidationException catch (error) {
      _handleWalkthroughFailure(error);
    }
  }

  /// Stores the walkthrough score and shows the result phase. Fired exactly once
  /// by [WalkthroughQuestionView] when every question has been answered.
  void _handleWalkthroughCompleted({
    required int correctCount,
    required int totalCount,
  }) {
    setState(() {
      _walkthroughCorrect = correctCount;
      _walkthroughTotal = totalCount;
      _phase = _GamePhase.walkthroughResult;
    });
  }

  /// "See Answer" on the result screen. The answer/explanation destination
  /// screen does not exist yet (deferred dependency), so this is intentionally a
  /// no-op for now.
  // TODO: route to the answer/explanation screen once it exists.
  void _handleSeeAnswer() {}

  void _handleWalkthroughFailure(WalkthroughException error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _walkthroughError = error;
      _isFetchingWalkthrough = false;
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
    final count = answerController.text.characters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressLabel(
          text: str(
            'Pregunta ${session.currentIndex + 1} de ${session.totalCount}',
            'Pergunta ${session.currentIndex + 1} de ${session.totalCount}',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SavedErrorLabel(
          category: question.source.category,
          originalPhrase: question.source.originalPhrase,
        ),
        const SizedBox(height: AppSpacing.md),
        _PromptCard(text: question.promptPhrase),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          height: 168,
          child: TextInputPanel(
            controller: answerController,
            characterLimit: answerLimit,
            hintText: str(
              'Escribe o graba tu respuesta...',
              'Escreva ou grave sua resposta...',
            ),
            onChanged: onAnswerChanged,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CharacterCounter(count: count, limit: answerLimit),
        const SizedBox(height: AppSpacing.xl),
        DividerLabel(label: str('o', 'ou')),
        const SizedBox(height: AppSpacing.md),
        MicControl(
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
    required this.isGrading,
    required this.grade,
    required this.gradeFailed,
    required this.onContinue,
    required this.onTryAgain,
    required this.onWalkthrough,
    required this.onSeeAnswer,
    required this.str,
  });

  final GameQuestion question;
  final String submittedAnswer;
  final bool isGrading;
  final RetranslationGrade? grade;
  final bool gradeFailed;

  /// Per-tier reveal routes (Phase 5), selected by [_RevealActionBar] off
  /// `grade.tier`: [onContinue] for the satisfied tiers, [onTryAgain] for Bien
  /// hecho's retry, [onWalkthrough] for Sigue practicando, and [onSeeAnswer] for
  /// the (still-stubbed) answer screen.
  final VoidCallback onContinue;
  final VoidCallback onTryAgain;
  final VoidCallback onWalkthrough;
  final VoidCallback onSeeAnswer;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    final grade = this.grade;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phase 5 (Figma 596:1160 / :1241 / :1358): the tier heading and the
        // diff-underlined answer block. Rendered only once the grade resolves;
        // while grading / on grade failure the interim panels below stand in.
        // The old comparison/verdict/context panels are still present here and
        // are removed at the Step 7 cutover.
        if (grade != null) ...[
          _RevealHeading(tier: grade.tier, str: str),
          const SizedBox(height: AppSpacing.md),
          _CurrentAnswerBlock(
            answer: submittedAnswer,
            corrections: grade.corrections,
            str: str,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
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
        _VerdictPanel(
          isGrading: isGrading,
          grade: grade,
          gradeFailed: gradeFailed,
          str: str,
        ),
        const SizedBox(height: AppSpacing.md),
        _ContextPanel(text: question.source.shortExplanation),
        const SizedBox(height: AppSpacing.xxl),
        _RevealActionBar(
          tier: grade?.tier,
          isGrading: isGrading,
          onContinue: onContinue,
          onTryAgain: onTryAgain,
          onWalkthrough: onWalkthrough,
          onSeeAnswer: onSeeAnswer,
          str: str,
        ),
      ],
    );
  }
}

/// The bottom action bar on the reveal screen, routing per [RetranslationTier]
/// (Figma 596:1160 / 596:1241 / 596:1358):
///
/// - Excelente: a single "Siguiente pregunta" continue.
/// - Bien hecho: "Siguiente pregunta" + an "Intentar de nuevo" retry.
/// - Sigue practicando: "Practicar paso a paso" (walkthrough) + "Ver respuesta"
///   (see answer). No standalone continue — the walkthrough IS the forward path.
///
/// While grading, a disabled continue holds the slot until the AI verdict
/// resolves. If the grade is unavailable (offline/failed: [tier] is null and not
/// grading) a single enabled continue is the only safe forward action, matching
/// the historical fallback where a missing grade scores as a miss and advances.
///
/// Each button carries a stable per-tier key (reveal-continue / reveal-try-again
/// / reveal-walkthrough / reveal-see-answer) so the funnel tests tap by tier,
/// not by (localised) label.
class _RevealActionBar extends StatelessWidget {
  const _RevealActionBar({
    required this.tier,
    required this.isGrading,
    required this.onContinue,
    required this.onTryAgain,
    required this.onWalkthrough,
    required this.onSeeAnswer,
    required this.str,
  });

  /// The resolved outcome tier, or null while grading or when the grade is
  /// unavailable.
  final RetranslationTier? tier;
  final bool isGrading;
  final VoidCallback onContinue;
  final VoidCallback onTryAgain;
  final VoidCallback onWalkthrough;
  final VoidCallback onSeeAnswer;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    if (isGrading) {
      // Hold the continue slot disabled until the AI verdict resolves.
      return PrimaryActionButton(
        key: const Key('reveal-continue'),
        label: str('Siguiente pregunta', 'Próxima pergunta'),
        onPressed: null,
      );
    }

    switch (tier) {
      case RetranslationTier.bienHecho:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryActionButton(
              key: const Key('reveal-continue'),
              label: str('Siguiente pregunta', 'Próxima pergunta'),
              onPressed: onContinue,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryActionButton(
              key: const Key('reveal-try-again'),
              label: str('Intentar de nuevo', 'Tentar de novo'),
              onPressed: onTryAgain,
            ),
          ],
        );
      case RetranslationTier.siguePracticando:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryActionButton(
              key: const Key('reveal-walkthrough'),
              label: str('Practicar paso a paso', 'Praticar passo a passo'),
              onPressed: onWalkthrough,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryActionButton(
              key: const Key('reveal-see-answer'),
              label: str('Ver respuesta', 'Ver resposta'),
              onPressed: onSeeAnswer,
            ),
          ],
        );
      case RetranslationTier.excelente:
      case null:
        // Excelente shows a single continue; a null (unavailable) grade falls
        // back to the same single continue as the only safe forward action.
        return PrimaryActionButton(
          key: const Key('reveal-continue'),
          label: str('Siguiente pregunta', 'Próxima pergunta'),
          onPressed: onContinue,
        );
    }
  }
}

/// The colour-coded tier heading at the top of the reveal screen (Figma
/// 596:1315 et al): Sora Bold 18/27. Excelente is green, Bien hecho cyan, Sigue
/// practicando amber — the sole tier signal now that the verdict card is gone.
class _RevealHeading extends StatelessWidget {
  const _RevealHeading({required this.tier, required this.str});

  final RetranslationTier tier;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (tier) {
      RetranslationTier.excelente => (
        str('¡Excelente!', 'Excelente!'),
        AppColors.success,
      ),
      RetranslationTier.bienHecho => (
        str('¡Bien hecho!', 'Muito bem!'),
        AppColors.cyan,
      ),
      RetranslationTier.siguePracticando => (
        str('Sigue practicando', 'Continue praticando'),
        AppColors.amber,
      ),
    };

    return Text(
      label,
      key: const Key('reveal-heading'),
      style: TextStyle(
        color: color,
        fontFamily: 'Sora',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 27 / 18,
      ),
    );
  }
}

/// The "Tu respuesta" block on the reveal screen (Figma 596:1316 et al): the
/// learner's submitted attempt on a surface card, with any substantive errors
/// the grader found diff-underlined in the highlight yellow (#EFDC5B). The diff
/// set is the FULL [corrections] list, not just the saved category — so Bien
/// hecho still underlines the other-category error it left behind, and a clean
/// Excelente attempt renders with no underline at all.
class _CurrentAnswerBlock extends StatelessWidget {
  const _CurrentAnswerBlock({
    required this.answer,
    required this.corrections,
    required this.str,
  });

  final String answer;
  final List<CorrectionItem> corrections;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          str('Tu respuesta', 'Sua resposta'),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 24 / 15,
              ),
              children: buildHighlightedSpans(
                text: answer.isEmpty ? '...' : answer,
                corrections: corrections,
                color: AppColors.naturalLanguage,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows the AI's verdict and its reasoning on the reveal phase, alongside the
/// retained self-mark below it. The AI proposes; the user disposes.
class _VerdictPanel extends StatelessWidget {
  const _VerdictPanel({
    required this.isGrading,
    required this.grade,
    required this.gradeFailed,
    required this.str,
  });

  final bool isGrading;
  final RetranslationGrade? grade;
  final bool gradeFailed;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Widget body;

    if (isGrading) {
      accent = AppColors.cyan;
      body = Row(
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            str('Evaluando con la IA...', 'Avaliando com a IA...'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      );
    } else if (grade == null) {
      // Grade unavailable (e.g. offline). Degrade to plain self-mark.
      accent = AppColors.textSecondary;
      body = Text(
        gradeFailed
            ? str(
                'Valoración de la IA no disponible. Usa tu propia valoración.',
                'Avaliação da IA indisponível. Use sua própria avaliação.',
              )
            : '',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      );
    } else {
      final resolved = grade!;
      final category = resolved.judgedCategory.label;
      // Step 1 (Phase 4): select off the real tier instead of the two-bucket
      // isWellDone. excelente intentionally renders identically to bienHecho for
      // now — its distinct Excelente visuals land in the next step. bienHecho and
      // siguePracticando keep their exact current appearance.
      final IconData verdictIcon;
      final String verdictLabel;
      final String reasoning;
      switch (resolved.tier) {
        case RetranslationTier.excelente:
          // Figma 596:1160: the Excelente heading colour is #5de4a0
          // (AppColors.success) and the label is "¡Excelente!". The frame is a
          // fuller Phase 5 result screen with no verdict icon or reasoning
          // subtext, so within the interim card the icon and reasoning below are
          // documented in-house defaults (not from Figma) kept for parity with
          // the other two states — adjust freely. The reasoning is whole-sentence
          // (no category) because excelente means the entire sentence is clean.
          accent = AppColors.success;
          verdictIcon = Icons.verified_outlined;
          verdictLabel = str('¡Excelente!', 'Excelente!');
          reasoning = str(
            'Toda la frase está correcta de principio a fin.',
            'A frase inteira está correta do início ao fim.',
          );
        case RetranslationTier.bienHecho:
          accent = AppColors.mint;
          verdictIcon = Icons.check_circle_outline;
          verdictLabel = str('Bien hecho', 'Muito bem');
          reasoning = str(
            'La categoría de enfoque ($category) está correcta en tu traducción.',
            'A categoria em foco ($category) está correta na sua tradução.',
          );
        case RetranslationTier.siguePracticando:
          accent = AppColors.coral;
          verdictIcon = Icons.error_outline;
          verdictLabel = str('Sigue practicando', 'Continue praticando');
          reasoning = str(
            'La IA marcó en tu categoría de enfoque ($category): '
            '${_describeErrors(resolved)}.',
            'A IA apontou na sua categoria em foco ($category): '
            '${_describeErrors(resolved)}.',
          );
      }

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verdictIcon,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                verdictLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reasoning,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            str('Valoración de la IA', 'Avaliação da IA'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );
  }

  String _describeErrors(RetranslationGrade grade) {
    return grade.categoryErrors
        .map((error) => '"${error.originalPhrase}" → "${error.correctedPhrase}"')
        .join(', ');
  }
}

/// Walkthrough intro (Section 6a), shown after a KEEP PRACTICING attempt is
/// scored. Renders the user's attempt with its errors highlighted in a single
/// game accent (coral) — its own surface, separate from the reveal phase's grey
/// "Tu respuesta" panel — and offers a "Work through it?" Yes/No CTA. Yes drives
/// [onYes] (fetch, with a loading and retry-in-place error state); No drives the
/// advance-only [onNo].
class _WalkthroughIntroPhase extends StatelessWidget {
  const _WalkthroughIntroPhase({
    required this.attempt,
    required this.corrections,
    required this.isFetching,
    required this.error,
    required this.onYes,
    required this.onNo,
    required this.str,
  });

  final String attempt;
  final List<CorrectionItem> corrections;
  final bool isFetching;
  final WalkthroughException? error;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.coral, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              str('Sigue practicando', 'Continue praticando'),
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.coral.withValues(alpha: 0.26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                str('Tu respuesta', 'Sua resposta'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                  children: buildHighlightedSpans(
                    text: attempt.isEmpty ? '...' : attempt,
                    corrections: corrections,
                    color: AppColors.coral,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        _WalkthroughIntroCta(
          isFetching: isFetching,
          error: error,
          onYes: onYes,
          onNo: onNo,
          str: str,
        ),
      ],
    );
  }
}

/// The CTA region of the walkthrough intro: the Yes/No prompt, the loading
/// state while [onYes] runs, and the retry-in-place error state.
class _WalkthroughIntroCta extends StatelessWidget {
  const _WalkthroughIntroCta({
    required this.isFetching,
    required this.error,
    required this.onYes,
    required this.onNo,
    required this.str,
  });

  final bool isFetching;
  final WalkthroughException? error;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return Center(
        child: Column(
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(
                color: AppColors.cyan,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              str('Preparando el repaso...', 'Preparando a revisão...'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      // Retry-in-place: the user stays on the intro. v1 shows one message for
      // all three exception types; Reintentar re-runs the same fetch.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            str(
              'No se pudo preparar el repaso. Inténtalo de nuevo.',
              'Não foi possível preparar a revisão. Tente novamente.',
            ),
            style: const TextStyle(
              color: AppColors.coral,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryActionButton(
            label: str('Reintentar', 'Tentar de novo'),
            onPressed: onYes,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: onNo,
            child: Text(
              str('Ahora no', 'Agora não'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          str('¿Lo trabajamos paso a paso?', 'Vamos trabalhar isso passo a passo?'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 22 / 16,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: PrimaryActionButton(
                label: str('Ahora no', 'Agora não'),
                onPressed: onNo,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryActionButton(
                label: str('Sí, vamos', 'Sim, vamos'),
                onPressed: onYes,
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
                '${session.score} / ${session.maxScore}',
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
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.5,
      ),
    );
  }
}

/// Frame 584:1111's row above the prompt card: the saved error's category
/// label followed by the learner's ORIGINAL (wrong) phrase, underlined in the
/// category's accent colour. Deliberately shows the wrong phrase, never the
/// correction — revealing the corrected phrase would give away the recall
/// answer. Both values are sourced from the correction this game question was
/// built from, so the label is dynamic per phrase.
class _SavedErrorLabel extends StatelessWidget {
  const _SavedErrorLabel({required this.category, required this.originalPhrase});

  final ErrorCategory category;
  final String originalPhrase;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 22.5 / 15,
        ),
        children: [
          TextSpan(text: '${category.label}:  '),
          TextSpan(
            text: originalPhrase,
            style: TextStyle(
              color: category.color,
              decoration: TextDecoration.underline,
              decorationColor: category.color,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 24 / 15,
        ),
      ),
    );
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
