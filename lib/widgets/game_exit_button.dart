import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GameExitButton — botón ··· que aparece en pantallas de juego activo (S3-S7)
// Muestra un BottomSheet de confirmación para abandonar la partida.
// ─────────────────────────────────────────────────────────────────────────────
class GameExitButton extends StatelessWidget {
  const GameExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Opciones de partida',
      child: GestureDetector(
        onTap: () => _showExitSheet(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.more_horiz_rounded,
            color: AppColors.muted.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
      ),
    );
  }

  void _showExitSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ExitSheet(),
    );
  }
}

class _ExitSheet extends StatelessWidget {
  const _ExitSheet();

  @override
  Widget build(BuildContext context) {
    final game = context.read<GameState>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Opciones de partida', style: AppTextStyles.subheading()),
            const SizedBox(height: 6),
            Text(
              'La partida continúa hasta que salgas.',
              style: AppTextStyles.small(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            // Ver configuración
            _SheetButton(
              label: 'Ver configuración',
              icon: Icons.info_outline_rounded,
              color: AppColors.muted,
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => _ConfigSheet(game: game),
                );
              },
            ),
            const SizedBox(height: 10),
            _SheetButton(
              label: 'Abandonar la partida',
              icon: Icons.exit_to_app_rounded,
              color: AppColors.primary,
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop();
                game.newGame();
              },
            ),
            const SizedBox(height: 10),
            _SheetButton(
              label: 'Continuar jugando',
              icon: Icons.close_rounded,
              color: AppColors.ink,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodySemibold(color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Config sheet — read-only view of current game config
// ─────────────────────────────────────────────────────────────────────────────
class _ConfigSheet extends StatelessWidget {
  const _ConfigSheet({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Configuración', style: AppTextStyles.heading()),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ConfigRow(label: 'Jugadores', value: '${game.players.length}'),
                      const SizedBox(height: 12),
                      _ConfigRow(label: 'Impostores', value: '${game.impostorCount}'),
                      const SizedBox(height: 12),
                      _ConfigRow(label: 'Categoría', value: game.category),
                      const SizedBox(height: 12),
                      _ConfigRow(
                        label: 'Tiempo',
                        value: _formatTime(game.timerSeconds),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.border),
                      const SizedBox(height: 12),
                      Text('JUGADORES', style: AppTextStyles.label()),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: game.players.map((name) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              name,
                              style: AppTextStyles.small(color: AppColors.ink),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text('Cerrar', style: AppTextStyles.bodySemibold(color: AppColors.muted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return s == 0 ? '$m min' : '$m:${s.toString().padLeft(2, '0')} min';
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.small(color: AppColors.muted)),
        Text(value, style: AppTextStyles.bodySemibold()),
      ],
    );
  }
}
