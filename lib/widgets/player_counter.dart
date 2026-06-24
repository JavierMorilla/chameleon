import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PlayerCounter — ± stepper for numeric game config values
// ─────────────────────────────────────────────────────────────────────────────
class PlayerCounter extends StatelessWidget {
  const PlayerCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.min = 1,
    this.max = 12,
    this.accentColor = AppColors.primary,
  });

  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final int min;
  final int max;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.label()),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _CounterButton(
                icon: Icons.remove,
                onTap: value > min ? () { HapticFeedback.selectionClick(); onDecrement(); } : null,
              ),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                      ),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      '$value',
                      key: ValueKey(value),
                      style: AppTextStyles.heading(color: accentColor),
                    ),
                  ),
                ),
              ),
              _CounterButton(
                icon: Icons.add,
                onTap: value < max ? () { HapticFeedback.selectionClick(); onIncrement(); } : null,
                color: accentColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatefulWidget {
  const _CounterButton({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80), lowerBound: 0, upperBound: 1);
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null;
    return GestureDetector(
      onTapDown: active ? (_) => _ctrl.forward() : null,
      onTapUp: active ? (_) { _ctrl.reverse(); widget.onTap!(); } : null,
      onTapCancel: active ? () => _ctrl.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            color: active ? (widget.color ?? AppColors.ink) : AppColors.border,
            size: 24,
          ),
        ),
      ),
    );
  }
}
