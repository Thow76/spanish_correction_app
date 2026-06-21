import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../shared/design/app_colors.dart';
import '../../../../shared/design/app_spacing.dart';
import '../../../../shared/widgets/primary_action_button.dart';
import '../../../../shared/widgets/secondary_action_button.dart';
import '../../domain/walkthrough_result.dart';

/// The walkthrough results screen: a tier-coloured score ring with the rounded
/// percentage and a short, tier-dependent line of encouragement.
///
/// Self-contained, matching the game's `_SummaryPhase` pattern: a plain
/// [Column] with no [Scaffold]/background/nav bar, embedded by the host. Derives
/// the percentage and tier internally from the raw tally via [WalkthroughResult],
/// so one widget renders all three tiers from real numbers.
///
/// Phase 2 scope so far: the score ring + supporting text. The action buttons
/// are added in later steps.
class WalkthroughResultView extends StatelessWidget {
  const WalkthroughResultView({
    required this.correctCount,
    required this.totalCount,
    required this.onContinue,
    required this.onTryAgain,
    required this.onSeeAnswer,
    this.str = _defaultStr,
    super.key,
  });

  /// Default localisation: Spanish. A static tear-off so it can be a const
  /// constructor default. The game wiring passes the real `_str`.
  static String _defaultStr(String es, String pt) => es;

  final int correctCount;
  final int totalCount;

  /// The primary action, shown on every tier.
  final VoidCallback onContinue;

  /// Secondary action shown on the satisfactory and poor tiers: retry the full
  /// free-translation attempt.
  final VoidCallback onTryAgain;

  /// Secondary action shown on the poor tier only. The answer/explanation
  /// destination screen does not exist yet, so the host leaves this unwired for
  /// now (deferred dependency) — the button still surfaces the callback.
  final VoidCallback onSeeAnswer;

  /// Returns the Spanish or Portuguese string for the active language. Optional
  /// so callers/tests need no change; defaults to Spanish.
  final String Function(String es, String pt) str;

  @override
  Widget build(BuildContext context) {
    final result = WalkthroughResult(
      correctCount: correctCount,
      totalCount: totalCount,
    );
    final tierColor = _tierColor(result.tier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: SizedBox.square(
            dimension: 120,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                progress: result.percentage / 100,
                color: tierColor,
              ),
              child: Center(
                child: Text(
                  '${result.percentage}%',
                  style: TextStyle(
                    color: tierColor,
                    fontFamily: 'Sora',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 48 / 32,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              _supportingText(result.tier),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 24 / 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        PrimaryActionButton(
          label: str('Continuar', 'Continuar'),
          onPressed: onContinue,
        ),
        // Poor tier also offers a route to the answer (destination screen is a
        // later phase, so onSeeAnswer is wired up by the host then).
        if (result.tier == WalkthroughTier.poor) ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryActionButton(
            label: str('Ver respuesta', 'Ver resposta'),
            onPressed: onSeeAnswer,
          ),
        ],
        // Satisfactory and poor tiers offer retrying the full translation.
        if (result.tier != WalkthroughTier.success) ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryActionButton(
            label: str(
              'Intentar la traducción completa otra vez',
              'Tentar a tradução completa de novo',
            ),
            onPressed: onTryAgain,
          ),
        ],
      ],
    );
  }

  Color _tierColor(WalkthroughTier tier) => switch (tier) {
    WalkthroughTier.success => AppColors.success,
    WalkthroughTier.satisfactory => AppColors.cyan,
    WalkthroughTier.poor => AppColors.coral,
  };

  String _supportingText(WalkthroughTier tier) => switch (tier) {
    WalkthroughTier.success => str(
      'El patrón ya te sale — excelente trabajo.',
      'O padrão já está fluindo — ótimo trabalho.',
    ),
    WalkthroughTier.satisfactory => str(
      'Buen esfuerzo — mejorará con la práctica.',
      'Bom esforço — vai melhorar com a prática.',
    ),
    WalkthroughTier.poor => str(
      'Difícil — cada repaso lo refuerza.',
      'Difícil — cada revisão reforça.',
    ),
  };
}

/// Draws the score ring: a faint full track with a tier-coloured arc on top,
/// sweeping clockwise from the top in proportion to [progress] (0–1).
class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _strokeWidth = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - _strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.textPrimary.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, track);

    if (progress > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0, 1),
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
