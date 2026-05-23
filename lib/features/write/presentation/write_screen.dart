import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/primary_action_button.dart';
import '../../corrections/application/correction_service.dart';
import '../../corrections/application/correction_service_exception.dart';
import '../../corrections/domain/correction_item.dart';
import '../../corrections/presentation/corrections_screen.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({required this.correctionService, super.key});

  final CorrectionService correctionService;

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  static const _characterLimit = 600;
  final _controller = TextEditingController();
  bool _hasShownLimitMessage = false;
  bool _isReviewing = false;

  @override
  void dispose() {
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const SizedBox(height: 36),
              const AppHeader(title: 'Corregir'),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                "Write or record - we'll handle the rest.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _TextInputPanel(
                controller: _controller,
                onChanged: _handleTextChanged,
              ),
              const SizedBox(height: AppSpacing.sm),
              _CharacterCounter(
                count: count,
                limit: _characterLimit,
                progress: progress,
                color: progressColor,
              ),
              const SizedBox(height: AppSpacing.xl),
              const _DividerLabel(),
              const SizedBox(height: AppSpacing.md),
              _MicControl(onTap: _showWhisperRequirements),
              const SizedBox(height: AppSpacing.xxl),
              PrimaryActionButton(
                label: _isReviewing ? 'Reviewing' : 'Corregir',
                isLoading: _isReviewing,
                onPressed: count == 0 ? null : _reviewText,
              ),
            ],
          ),
        ),
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
      final response = await widget.correctionService.correctText(
        _controller.text.trim(),
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) {
            return CorrectionsScreen(
              response: response,
              onSaveCorrection: _saveCorrection,
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

  Future<void> _saveCorrection(CorrectionItem item) async {
    try {
      await widget.correctionService.generateLongExplanation(item);
      if (!mounted) {
        return;
      }
      _showSnackBar('Long explanation generated. Local saving is next.');
    } on CorrectionServiceException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_messageForCorrectionError(error));
    }
  }

  void _showWhisperRequirements() {
    _showIntegrationSheet(
      title: 'Whisper recording setup',
      icon: Icons.mic_none,
      body:
          'Next we will add Android microphone permission, record a 60 second audio file, send it for Spanish transcription, and pass the returned text into this input.',
    );
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

  void _showIntegrationSheet({
    required String title,
    required IconData icon,
    required String body,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.cyan.withValues(alpha: 0.12),
                child: Icon(icon, color: AppColors.cyan),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 24 / 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TextInputPanel extends StatelessWidget {
  const _TextInputPanel({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 278,
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
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Type or paste your Spanish text here...',
          hintStyle: TextStyle(color: AppColors.textSecondary),
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
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.textDisabled)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or', style: TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(child: Divider(color: AppColors.textDisabled)),
      ],
    );
  }
}

class _MicControl extends StatelessWidget {
  const _MicControl({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.cyan.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.cyan.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.mic_none,
                color: AppColors.cyan,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Tap to record',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
