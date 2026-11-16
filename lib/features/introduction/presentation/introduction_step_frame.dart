import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';

/// The frame every introduction step sits in: the small English label at the
/// top left, "Stop for now" at the top right (on every step but the end
/// screen), the question and its hint, then the step's own content.
class IntroductionStepFrame extends StatelessWidget {
  const IntroductionStepFrame({
    required this.label,
    required this.child,
    this.questionText,
    this.hint,
    this.onStopForNow,
    super.key,
  });

  final String label;
  final String? questionText;
  final String? hint;

  /// Null on the end screen, which has no "Stop for now".
  final VoidCallback? onStopForNow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label.toUpperCase(),
                            key: const ValueKey('introduction-step-label'),
                            style: const TextStyle(
                              color: AppColors.cyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        if (onStopForNow != null)
                          TextButton(
                            onPressed: onStopForNow,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                            child: const Text('Stop for now'),
                          ),
                      ],
                    ),
                  ),
                  if (questionText != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      questionText!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'Sora',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 32 / 24,
                      ),
                    ),
                  ],
                  if (hint != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      hint!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
