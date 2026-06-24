import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ParticleBurst — celebración visual para S7/S8
// Emite partículas coloridas desde el centro, con gravedad y fade-out.
// ─────────────────────────────────────────────────────────────────────────────

class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    this.citizensWon = true,
    this.particleCount = 60,
  });

  final bool citizensWon;
  final int particleCount;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();
    _particles = List.generate(widget.particleCount, (_) => _buildParticle());
  }

  _Particle _buildParticle() {
    final colors = widget.citizensWon
        ? [AppColors.tertiary, AppColors.accent, AppColors.tertiary.withValues(alpha: 0.7)]
        : [AppColors.primary, AppColors.accent, AppColors.primaryDim];

    // Spawn across the horizontal span of the card/name (0.2 to 0.8)
    final px = 0.2 + _rng.nextDouble() * 0.6;
    // Spawn around the name line height (0.3 to 0.36)
    final py = 0.3 + _rng.nextDouble() * 0.06;

    // Upward-blowing velocities (negative vy) with a slight horizontal spread
    final vx = (_rng.nextDouble() - 0.5) * 0.005;
    final vy = -0.008 - _rng.nextDouble() * 0.012;

    return _Particle(
      x: px,
      y: py,
      vx: vx,
      vy: vy,
      size: 3 + _rng.nextDouble() * 7,
      color: colors[_rng.nextInt(colors.length)],
      rotationSpeed: (_rng.nextDouble() - 0.5) * 0.3,
      isRect: _rng.nextBool(),
      delay: _rng.nextDouble() * 0.3,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              progress: _ctrl.value,
              reducedMotion: reducedMotion,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy, size, rotationSpeed, delay;
  Color color;
  bool isRect;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.isRect,
    required this.delay,
  });
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.reducedMotion,
  });

  final List<_Particle> particles;
  final double progress;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (reducedMotion) return;

    for (final p in particles) {
      final localProgress = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (localProgress <= 0) continue;

      // Physics: Embers drift upwards and sway like smoke
      // Buoyancy / rising drift (upward acceleration)
      final py = p.y + p.vy * localProgress * 60 - 0.5 * 0.008 * localProgress * localProgress * 60;
      // Sinusoidal wind sway
      final sway = math.sin(localProgress * 2 * math.pi * 1.5) * 0.03;
      final px = p.x + p.vx * localProgress * 60 + sway;

      final opacity = (1.0 - localProgress * localProgress).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      // Shrink size as they burn/disintegrate
      final currentSize = p.size * (1.0 - localProgress * 0.6);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      final cx = px * size.width;
      final cy = py * size.height;
      final rotation = p.rotationSpeed * localProgress * 60;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(rotation);

      if (p.isRect) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: currentSize, height: currentSize * 0.5),
            const Radius.circular(1),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, currentSize * 0.5, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}
