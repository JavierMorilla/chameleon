import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/game_exit_button.dart';

/// S5 — Countdown timer screen
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  late int _total;
  bool _paused = false;
  Timer? _ticker;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    final game = context.read<GameState>();
    _total = game.timerSeconds;
    _remaining = _total;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) {
        setState(() => _remaining--);
        if (_remaining <= 10 && _remaining > 0) {
          HapticFeedback.selectionClick();
        }
        if (_remaining <= 0) {
          _ticker?.cancel();
          HapticFeedback.vibrate();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) context.read<GameState>().endTimer();
          });
        }
      }
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    HapticFeedback.selectionClick();
  }

  String _formatTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final progress = _remaining / _total;
    final isUrgent = _remaining <= 10 && _remaining > 0;
    final timerColor = isUrgent ? AppColors.primary : AppColors.ink;
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with exit button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                children: [
                  Text(game.translate('timer_title'), style: AppTextStyles.label()),
                  const Spacer(),
                  const GameExitButton(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 1),
                    // Progress arc
                    SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient breathing glow behind the timer circle
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) {
                              final glowColor = isUrgent ? AppColors.primary : AppColors.tertiary;
                              final opacity = _paused 
                                  ? 0.03 
                                  : (isUrgent 
                                      ? 0.08 + _pulseCtrl.value * 0.06 
                                      : 0.04);
                              return Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: glowColor.withValues(alpha: opacity),
                                  boxShadow: [
                                    BoxShadow(
                                      color: glowColor.withValues(alpha: opacity),
                                      blurRadius: 80,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: 1.0,
                              strokeWidth: 4,
                              color: AppColors.border,
                            ),
                          ),
                          SizedBox.expand(
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 4,
                                  color: isUrgent
                                      ? AppColors.primary
                                      : AppColors.tertiary,
                                  strokeCap: StrokeCap.round,
                                );
                              },
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) {
                              final textChild = Text(
                                _remaining <= 0
                                    ? game.translate('time_up')
                                    : _formatTime(_remaining),
                                key: ValueKey(_remaining),
                                style: _remaining <= 0
                                    ? AppTextStyles.display(
                                        color: timerColor,
                                        fontSize: 32.0,
                                      )
                                    : AppTextStyles.timerDigits(
                                        color: timerColor,
                                        fontSize: 54.0,
                                      ),
                              );

                              final animatedChild = (reducedMotion || _paused)
                                  ? textChild
                                  : textChild.animate().scale(
                                      begin: const Offset(0.92, 0.92),
                                      end: const Offset(1.0, 1.0),
                                      duration: 150.ms,
                                      curve: Curves.easeOutBack,
                                    );

                              return Opacity(
                                opacity: (isUrgent && !_paused)
                                    ? 0.6 + _pulseCtrl.value * 0.4
                                    : 1.0,
                                child: animatedChild,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _paused ? game.translate('timer_paused') : game.translate('timer_running'),
                      style: AppTextStyles.label(),
                    ),
                    const Spacer(flex: 2),
                    // Controls
                    Row(
                      children: [
                        // Pause — now uses _PressableButton for consistent feel
                        _PressableButton(
                          onTap: _togglePause,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: AppColors.ink,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GameButton(
                            label: game.translate('vote_btn'),
                            onTap: () {
                              _ticker?.cancel();
                              HapticFeedback.mediumImpact();
                              game.endTimer();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PressableButton — spring scale wrapper consistent with GameButton behavior
// ─────────────────────────────────────────────────────────────────────────────
class _PressableButton extends StatefulWidget {
  const _PressableButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.watch<GameState>().translate('timer_paused'),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}
