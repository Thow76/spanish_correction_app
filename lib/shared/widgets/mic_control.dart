import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';

class MicControl extends StatelessWidget {
  const MicControl({
    required this.onTap,
    required this.isRecording,
    required this.isTranscribing,
    required this.secondsRemaining,
    required this.idleLabel,
    required this.activeLabel,
    required this.transcribingLabel,
    super.key,
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
