import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/particle_burst.dart';

/// S8 — End of game screen with drama and stats
class EndScreen extends StatefulWidget {
  const EndScreen({super.key});

  @override
  State<EndScreen> createState() => _EndScreenState();
}

class _EndScreenState extends State<EndScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _emojiCtrl;
  late final Animation<double> _fade;
  late final Animation<double> _emojiScale;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _emojiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0, 0.8, curve: Curves.easeOut),
    );
    _emojiScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(parent: _emojiCtrl, curve: Curves.easeOut));

    _entranceCtrl.forward().then((_) {
      HapticFeedback.heavyImpact();
      _emojiCtrl.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showParticles = true);
      });
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final citizensWon = game.winner == 'ciudadanos';
    final winnerLabel =
        citizensWon ? '¡Ganan los ciudadanos!' : '¡Gana el impostor!';
    final winnerColor = citizensWon ? AppColors.tertiary : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          if (_showParticles)
            ParticleBurst(
              citizensWon: citizensWon,
              particleCount: 80,
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        // Win icon — custom drawn, no emoji string
                        AnimatedBuilder(
                          animation: _emojiScale,
                          builder: (_, child) =>
                              Transform.scale(scale: _emojiScale.value, child: child),
                          child: _WinnerIcon(citizensWon: citizensWon),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          winnerLabel,
                          style: AppTextStyles.heading(color: winnerColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Stats card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _StatRow(
                                label: 'Rondas jugadas',
                                value: '${game.roundNumber}',
                              ),
                              Divider(color: AppColors.border, height: 32),
                              _StatRow(
                                label: 'Categoría',
                                value: game.category,
                              ),
                              Divider(color: AppColors.border, height: 32),
                              _StatRow(
                                label: game.impostorCount == 1
                                    ? 'El impostor era'
                                    : 'Los impostores eran',
                                value: _impostorNames(game),
                                valueColor: AppColors.primary,
                              ),
                              Divider(color: AppColors.border, height: 32),
                              _StatRow(
                                label: 'La palabra secreta',
                                value: game.roundWord.toUpperCase(),
                                valueColor: AppColors.tertiary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _fade,
                    child: Column(
                      children: [
                        GameButton(
                          label: 'Jugar de nuevo',
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            game.playAgainSameConfig();
                          },
                        ),
                        const SizedBox(height: 12),
                        GameButton(
                          label: 'Nueva partida',
                          color: AppColors.surface,
                          textColor: AppColors.muted,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            game.newGame();
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _impostorNames(GameState game) {
    // Use the snapshot captured at vote time (before indices were cleared)
    if (game.impostorNames.isNotEmpty) return game.impostorNames.join(', ');
    // Fallback: reconstruct from current indices if available
    if (game.impostorIndices.isNotEmpty) {
      return game.impostorIndices
          .where((i) => i < game.players.length)
          .map((i) => game.players[i])
          .join(', ');
    }
    return '—';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Winner icon — custom drawn, no emoji string dependency
// ─────────────────────────────────────────────────────────────────────────────
class _WinnerIcon extends StatelessWidget {
  const _WinnerIcon({required this.citizensWon});
  final bool citizensWon;

  @override
  Widget build(BuildContext context) {
    final color = citizensWon ? AppColors.tertiary : AppColors.primary;
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(
        citizensWon ? Icons.groups_rounded : Icons.theater_comedy_rounded,
        color: color,
        size: 52,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});
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
