import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/particle_burst.dart';

/// S7 — Result screen after vote — now with particle burst and drama
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _nameBounceCtrl;
  late final AnimationController _shakeCtrl;
  late final AnimationController _cutCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _nameScale;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _cutAnim;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _nameBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cutCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0, 0.7, curve: Curves.easeOut),
    ));
    _nameScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _nameBounceCtrl, curve: Curves.easeOut));

    // Natural physical decay screen shake: 0 -> 12 -> -12 -> 10 -> -8 -> 6 -> -3 -> 0
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -12.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 10.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -3.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -3.0, end: 0.0), weight: 15),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeOut));

    _cutAnim = CurvedAnimation(parent: _cutCtrl, curve: Curves.easeOut);

    // Sequence: entrance → name bounce & shake → sword cut → particles
    _entranceCtrl.forward().then((_) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward();
      _nameBounceCtrl.forward().then((_) {
        // Wait slightly, then trigger sword slash cut
        HapticFeedback.vibrate();
        _cutCtrl.forward().then((_) {
          final game = context.read<GameState>();
          if (game.eliminatedWasImpostor) {
            HapticFeedback.vibrate();
          }
          if (mounted) setState(() => _showParticles = true);
        });
      });
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _nameBounceCtrl.dispose();
    _shakeCtrl.dispose();
    _cutCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final wasImpostor = game.eliminatedWasImpostor;
    final eliminated = game.votedPlayerIndex != null
        ? game.players[game.votedPlayerIndex!]
        : '—';
    final impostorNames = game.impostorIndices
        .map((i) => game.players[i])
        .join(', ');
    // After fix, impostorIndices may have had the eliminated removed.
    // Show original by reconstructing from game state history isn't available,
    // but the word reveal and the eliminated player name is the key moment.
    final accentColor = wasImpostor ? AppColors.tertiary : AppColors.primary;
    final resultTitle = wasImpostor ? game.translate('result_title_won') : game.translate('result_title_lost');
    final resultSub = wasImpostor
        ? game.translate('result_sub_won')
        : (game.winner == 'impostor'
            ? game.translate('result_sub_impostor_won')
            : game.translate('result_sub_lost'));
    final remainingImpostors = game.impostorIndices
        .map((i) => game.players[i])
        .join(', ');
    final hasRemainingImpostors = game.impostorIndices.isNotEmpty && wasImpostor;
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Particles behind content
          if (_showParticles && game.winner != 'continua')
            ParticleBurst(citizensWon: wasImpostor),
          // Content
          SafeArea(
            child: AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                final offset = reducedMotion ? 0.0 : _shakeAnim.value;
                return Transform.translate(
                  offset: Offset(offset, 0.0),
                  child: child,
                );
              },
              child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      // Result icon
                      _ResultBadge(wasImpostor: wasImpostor, color: accentColor),
                      const SizedBox(height: 28),
                      // Eliminated player name — bouncing scale
                      AnimatedBuilder(
                        animation: _nameScale,
                        builder: (_, child) => Transform.scale(
                          scale: _nameScale.value,
                          child: child,
                        ),
                        child: _SwordCutName(
                          name: eliminated,
                          style: AppTextStyles.display(
                            color: wasImpostor
                                ? AppColors.primary
                                : AppColors.muted,
                            fontSize: 44.0,
                          ),
                          progress: _cutAnim,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Role badge for eliminated player
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: (wasImpostor ? AppColors.primary : AppColors.tertiary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: (wasImpostor ? AppColors.primary : AppColors.tertiary).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          wasImpostor ? game.translate('era_chameleon') : game.translate('era_citizen'),
                          style: AppTextStyles.label(
                            color: wasImpostor ? AppColors.primary : AppColors.tertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        resultTitle,
                        style: AppTextStyles.heading(color: accentColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resultSub,
                        style: AppTextStyles.body(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Info card
                      if (game.winner != 'continua')
                        _InfoCard(
                          word: game.roundWord,
                          wasImpostor: wasImpostor,
                          remainingImpostors: hasRemainingImpostors
                              ? remainingImpostors
                              : null,
                        ),
                      const Spacer(flex: 3),
                      // Actions
                      if (game.winner == 'continua') ...[
                        GameButton(
                          label: game.translate('next_round'),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            game.nextDiscussionRound();
                          },
                        ),
                      ] else ...[
                        GameButton(
                          label: game.translate('new_game'),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            game.playAgainSameConfig();
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      GameButton(
                        label: game.translate('finish_game'),
                        color: AppColors.surface,
                        textColor: AppColors.muted,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          game.finishGame();
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }
}

class _ResultBadge extends StatefulWidget {
  const _ResultBadge({required this.wasImpostor, required this.color});
  final bool wasImpostor;
  final Color color;

  @override
  State<_ResultBadge> createState() => _ResultBadgeState();
}

class _ResultBadgeState extends State<_ResultBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (!widget.wasImpostor) {
      // Impostor survived → pulsing danger
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final pulse = widget.wasImpostor ? 1.0 : 0.85 + _pulseCtrl.value * 0.15;
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(alpha: widget.wasImpostor ? 0.4 : 0.7),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: widget.wasImpostor ? 0.15 : 0.3),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              widget.wasImpostor
                  ? Icons.check_rounded
                  : Icons.warning_amber_rounded,
              color: widget.color,
              size: 44,
            ),
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.word,
    required this.wasImpostor,
    this.remainingImpostors,
  });

  final String word;
  final bool wasImpostor;
  final String? remainingImpostors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: context.watch<GameState>().translate('secret_word_was'),
            value: word.toUpperCase(),
          ),
          if (remainingImpostors != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: context.watch<GameState>().translate('remaining_chameleons'),
              value: remainingImpostors!,
              valueColor: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.small(color: AppColors.muted)),
        Flexible(
          child: Text(
            value,
            style:
                AppTextStyles.bodySemibold(color: valueColor ?? AppColors.ink),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sword Cut elimination widgets, clippers, and painters
// ─────────────────────────────────────────────────────────────────────────────

class _SwordCutName extends StatelessWidget {
  const _SwordCutName({
    required this.name,
    required this.style,
    required this.progress,
  });

  final String name;
  final TextStyle style;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final val = progress.value;

        // If reduced motion is requested, render the name undivided and static
        if (reducedMotion) {
          return Text(name, style: style, textAlign: TextAlign.center);
        }

        // Split slide apart starts after 0.2 of progress
        final slideVal = (val - 0.2).clamp(0.0, 0.8) / 0.8;
        final slideDist = slideVal * 12.0; // max 12 pixels displacement

        // Slash lines flashes between 0.0 and 0.4 of progress
        double slashOpacity = 0.0;
        double slashWidth = 0.0;
        if (val < 0.4) {
          slashOpacity = math.sin((val / 0.4) * math.pi);
          slashWidth = val / 0.4;
        }

        final textWidget = Text(
          name,
          style: style,
          textAlign: TextAlign.center,
        );

        return Stack(
          alignment: Alignment.center,
          children: [
            // Top half
            Transform.translate(
              offset: Offset(-slideDist, -slideDist * 0.4),
              child: ClipPath(
                clipper: TopHalfClipper(),
                child: textWidget,
              ),
            ),
            // Bottom half
            Transform.translate(
              offset: Offset(slideDist, slideDist * 0.4),
              child: ClipPath(
                clipper: BottomHalfClipper(),
                child: textWidget,
              ),
            ),
            // Slash effect overlay
            if (slashOpacity > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SlashPainter(
                      progress: slashWidth,
                      opacity: slashOpacity,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class TopHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width + 10, size.height * 0.6)
      ..lineTo(-10, size.height * 0.4)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BottomHalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(-10, size.height * 0.4)
      ..lineTo(size.width + 10, size.height * 0.6)
      ..lineTo(size.width, size.height + 10)
      ..lineTo(0, size.height + 10)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SlashPainter extends CustomPainter {
  const _SlashPainter({required this.progress, required this.opacity});
  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(-10, size.height * 0.38);
    final end = Offset(size.width + 10, size.height * 0.62);

    final currentEnd = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    final paintGlow = Paint()
      ..color = AppColors.primary.withValues(alpha: opacity * 0.7)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintCore = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, currentEnd, paintGlow);
    canvas.drawLine(start, currentEnd, paintCore);
  }

  @override
  bool shouldRepaint(covariant _SlashPainter old) =>
      old.progress != progress || old.opacity != opacity;
}
