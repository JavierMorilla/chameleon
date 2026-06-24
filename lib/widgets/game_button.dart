import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GameButton — full-width primary CTA
// ─────────────────────────────────────────────────────────────────────────────
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
    this.icon,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool disabled;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.disabled) _ctrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    if (!widget.disabled && widget.onTap != null) {
      HapticFeedback.lightImpact();
      widget.onTap!();
    }
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final bg = widget.disabled
        ? AppColors.primaryDim
        : (widget.color ?? AppColors.primary);
    final fg = widget.textColor ?? AppColors.onPrimary;

    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(
            scale: _scale.value,
            child: child,
          ),
          child: AnimatedOpacity(
            opacity: widget.disabled ? 0.5 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.buttonLabel(color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SecondaryButton — ghost style
// ─────────────────────────────────────────────────────────────────────────────
class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
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
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); HapticFeedback.selectionClick(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(widget.label, style: AppTextStyles.bodySemibold(color: AppColors.muted)),
          ),
        ),
      ),
    );
  }
}
