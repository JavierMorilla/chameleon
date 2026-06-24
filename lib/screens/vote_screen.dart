import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/game_exit_button.dart';

/// S6 — Vote screen: select who you think is the impostor
class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final hasVote = game.votedPlayerIndex != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VOTACIÓN', style: AppTextStyles.label()),
                      const SizedBox(height: 8),
                      Text(
                        '¿Quién es el impostor?',
                        style: AppTextStyles.heading(),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '¿Quién está mintiendo?',
                        style: AppTextStyles.small(color: AppColors.muted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Align(
                    alignment: Alignment.topRight,
                    child: GameExitButton(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Builder(
                builder: (context) {
                  final activeIndices = <int>[];
                  for (int i = 0; i < game.players.length; i++) {
                    if (!game.eliminatedIndices.contains(i)) {
                      activeIndices.add(i);
                    }
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    itemCount: activeIndices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final i = activeIndices[idx];
                      final isSelected = game.votedPlayerIndex == i;
                      return _PlayerVoteRow(
                        name: game.players[i],
                        index: i,
                        isSelected: isSelected,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          game.setVote(i);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: GameButton(
                label: hasVote
                    ? 'Eliminar a ${game.players[game.votedPlayerIndex!]}'
                    : 'Selecciona un sospechoso',
                onTap: hasVote
                    ? () {
                        HapticFeedback.heavyImpact();
                        game.confirmVote();
                      }
                    : null,
                disabled: !hasVote,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerVoteRow extends StatefulWidget {
  const _PlayerVoteRow({
    required this.name,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final String name;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_PlayerVoteRow> createState() => _PlayerVoteRowState();
}

class _PlayerVoteRowState extends State<_PlayerVoteRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80), lowerBound: 0, upperBound: 1);
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isSelected ? AppColors.accent : AppColors.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.accent
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: widget.isSelected ? AppColors.accent : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.name.substring(0, 1).toUpperCase(),
                  style: AppTextStyles.bodySemibold(
                    color: widget.isSelected ? AppColors.onAccent : AppColors.muted,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.name,
                  style: AppTextStyles.bodyMedium(color: AppColors.ink),
                ),
              ),
              AnimatedOpacity(
                opacity: widget.isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.accent, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
