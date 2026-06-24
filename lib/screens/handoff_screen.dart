import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/game_exit_button.dart';

/// S3 — "Pasa el móvil a [Nombre]" — now with dramatic name display and brand pattern
import 'package:flutter_animate/flutter_animate.dart';

class HandoffScreen extends StatelessWidget {
  const HandoffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final total = game.players.length;
    final current = game.currentPlayerIndex + 1;
    final name = game.currentPlayerName;
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    Widget animate(Widget child, Duration delay) {
      if (reducedMotion) {
        return child.animate().fadeIn(duration: 200.ms);
      }
      return child.animate(delay: delay)
          .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
          .slideY(begin: 0.05, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
    }

    Widget nameWidget = Text(
      name,
      style: AppTextStyles.hero(fontSize: 44),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );


    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                children: [
                  Text('RONDA', style: AppTextStyles.label()),
                  const Spacer(),
                  const GameExitButton(),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Background brand pattern — subtle, same as card cover
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.035,
                      child: CustomPaint(painter: _HandoffPatternPainter()),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        // Dot progress
                        animate(
                          _TurnDots(total: total, current: game.currentPlayerIndex),
                          0.ms,
                        ),
                        const SizedBox(height: 48),
                        // "Pasa el móvil a"
                        animate(
                          Text(
                            'Pasa el móvil a',
                            style: AppTextStyles.body(color: AppColors.muted),
                          ),
                          80.ms,
                        ),
                        const SizedBox(height: 16),
                        // Big name — hero size with bounce-in and breathe pulse
                        animate(nameWidget, 160.ms),
                        const SizedBox(height: 16),
                        // Turn badge
                        animate(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              'Turno $current de $total',
                              style: AppTextStyles.label(),
                            ),
                          ),
                          240.ms,
                        ),
                        const SizedBox(height: 16),
                        animate(
                          Text(
                            'Que el resto mire para otro lado.',
                            style: AppTextStyles.small(color: AppColors.muted),
                          ),
                          320.ms,
                        ),
                        const Spacer(flex: 3),
                        animate(
                          GameButton(
                            label: 'Ver mi carta',
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              game.showReveal();
                            },
                          ),
                          400.ms,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtle diagonal text pattern for handoff background
// ─────────────────────────────────────────────────────────────────────────────
class _HandoffPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const text = '·';
    const fontSize = 32.0;
    const spacing = 48.0;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    for (double x = 0; x <= size.width + spacing; x += spacing) {
      for (double y = 0; y <= size.height + spacing; y += spacing) {
        final offsetX = (y ~/ spacing % 2 == 0) ? 0.0 : spacing / 2;
        tp.paint(canvas, Offset(x + offsetX - tp.width / 2, y - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Turn dots progress indicator
// ─────────────────────────────────────────────────────────────────────────────
class _TurnDots extends StatelessWidget {
  const _TurnDots({required this.total, required this.current});
  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: List.generate(total, (i) {
        final done = i < current;
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done
                ? AppColors.ink.withValues(alpha: 0.3)
                : active
                    ? AppColors.primary
                    : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
