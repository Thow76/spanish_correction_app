import 'package:flutter/material.dart';

import '../../../shared/design/app_colors.dart';
import '../../../shared/design/app_spacing.dart';

/// The frame every introduction step sits in: the English label centred at
/// the top, the question and its hint, the step's own content, and "Stop for
/// now" in small text centred at the bottom (on every step but the end
/// screen).
class IntroductionStepFrame extends StatelessWidget {
  const IntroductionStepFrame({
    required this.label,
    required this.child,
    this.questionText,
    this.centerQuestion = false,
    this.hint,
    this.onStopForNow,
    this.bottomAction,
    super.key,
  });

  final String label;
  final String? questionText;

  /// Whether the question is centred rather than left-aligned.
  final bool centerQuestion;
  final String? hint;

  /// Null on the end screen, which has no "Stop for now".
  final VoidCallback? onStopForNow;
  final Widget child;

  /// A button pinned to the bottom of the screen, above "Stop for now",
  /// so it stays in the same place whatever the step shows (for example
  /// the walk-through's Next).
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          label.toUpperCase(),
                          key: const ValueKey('introduction-step-label'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (questionText != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            questionText!,
                            textAlign: centerQuestion
                                ? TextAlign.center
                                : TextAlign.start,
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
                if (bottomAction != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: bottomAction,
                  ),
                if (onStopForNow != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Center(
                      child: TextButton(
                        onPressed: onStopForNow,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        child: const Text('Stop for now'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
