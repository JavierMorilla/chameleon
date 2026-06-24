import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/game_exit_button.dart';

/// S4 — Role reveal with 3D card flip animation
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key});

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen>
    with TickerProviderStateMixin {
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;
  late final AnimationController _pulseCtrl;
  bool _showFront = true;
  Offset _tiltOffset = Offset.zero;
  Ticker? _tiltTicker;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
    _flipAnim.addListener(() {
      if (_flipAnim.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_flipAnim.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _flip(GameState game) {
    if (_flipCtrl.isCompleted) return;
    HapticFeedback.heavyImpact();
    _flipCtrl.forward();
    game.revealCard();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final rx = (_tiltOffset.dx + details.delta.dx / 150.0).clamp(-1.0, 1.0);
      final ry = (_tiltOffset.dy + details.delta.dy / 150.0).clamp(-1.0, 1.0);
      _tiltOffset = Offset(rx, ry);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _animateTiltBack();
  }

  void _animateTiltBack() {
    _tiltTicker?.stop();
    _tiltTicker = createTicker((elapsed) {
      if (!mounted) return;
      final t = elapsed.inMilliseconds / 200.0;
      if (t >= 1.0) {
        setState(() {
          _tiltOffset = Offset.zero;
        });
        _tiltTicker?.stop();
      } else {
        setState(() {
          final factor = math.pow(1.0 - t, 3).toDouble();
          _tiltOffset = _tiltOffset * factor;
          if (_tiltOffset.distance < 0.01) {
            _tiltOffset = Offset.zero;
            _tiltTicker?.stop();
          }
        });
      }
    });
    _tiltTicker?.start();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final isImpostor = game.isCurrentImpostor;
    final isLast = game.isLastPlayer;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient breathing glow behind the card
            if (game.cardRevealed)
              Positioned.fill(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) {
                      final opacity = 0.08 + _pulseCtrl.value * 0.06;
                      final glowColor = isImpostor ? AppColors.primary : AppColors.tertiary;
                      return Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glowColor.withValues(alpha: opacity),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: opacity),
                              blurRadius: 100,
                              spreadRadius: 30,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Screen content
            Column(
              children: [
                // Header with player name + exit button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      Text(
                        game.currentPlayerName,
                        style: AppTextStyles.label(),
                      ),
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
                        // Card with 3D flip & touch tilt
                        AnimatedBuilder(
                          animation: _flipAnim,
                          builder: (_, __) {
                            final angle = _flipAnim.value * math.pi;
                            final isBack = angle > math.pi / 2;
                            
                            // Combine flip rotation and interactive tilt rotation
                            final tiltX = _tiltOffset.dy * -0.22;
                            final tiltY = _tiltOffset.dx * 0.22;
                            
                            final transform = Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(tiltX)
                              ..rotateY(angle + tiltY);

                            return GestureDetector(
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              onPanCancel: () => _animateTiltBack(),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: transform,
                                child: Stack(
                                  children: [
                                    isBack
                                        ? Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.identity()..rotateY(math.pi),
                                            child: _RoleCard(
                                              isImpostor: isImpostor,
                                              word: game.roundWord,
                                              clue: game.roundClue,
                                              showCluesEnabled: game.showCluesEnabled,
                                            ),
                                          )
                                        : _CoverCard(
                                            playerName: game.currentPlayerName,
                                            onTap: () => _flip(game),
                                          ),
                                    Positioned.fill(
                                      child: _CardGlare(tiltOffset: _tiltOffset),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const Spacer(flex: 2),
                        // CTA — only visible after flip
                        AnimatedOpacity(
                          opacity: game.cardRevealed ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedSlide(
                            offset: game.cardRevealed
                                ? Offset.zero
                                : const Offset(0, 0.3),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: GameButton(
                              label: isLast ? game.translate('start_round') : game.translate('hide_and_pass'),
                              onTap: game.cardRevealed
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      _flipCtrl.reset();
                                      setState(() => _showFront = true);
                                      game.advanceReveal();
                                    }
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover card — brand pattern + 1.5s grace delay to prevent accidental reveals
// ─────────────────────────────────────────────────────────────────────────────
class _CoverCard extends StatefulWidget {
  const _CoverCard({required this.playerName, required this.onTap});

  final String playerName;
  final VoidCallback onTap;

  @override
  State<_CoverCard> createState() => _CoverCardState();
}

class _CoverCardState extends State<_CoverCard>
    with SingleTickerProviderStateMixin {
  bool _readyToReveal = false;
  late final AnimationController _hintCtrl;
  late final Animation<double> _hintFade;

  @override
  void initState() {
    super.initState();
    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hintFade = CurvedAnimation(parent: _hintCtrl, curve: Curves.easeOut);
    // Grace delay: 1.5s before accepting taps
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _readyToReveal = true);
        _hintCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _hintCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _readyToReveal ? widget.onTap : null,
      child: Container(
        width: double.infinity,
        height: 360,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            // Brand pattern background
            Positioned.fill(
              child: CustomPaint(painter: _BrandPatternPainter()),
            ),
            // Content overlay
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.playerName,
                        style: AppTextStyles.heading(),
                      ),
                      const SizedBox(height: 8),
                      // Fades in after grace delay
                      FadeTransition(
                        opacity: _hintFade,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              color: AppColors.muted,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.watch<GameState>().translate('tap_to_see_card'),
                              style: AppTextStyles.small(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      // Shown while locked
                      AnimatedOpacity(
                        opacity: _readyToReveal ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          context.watch<GameState>().translate('wait_grace'),
                          style: AppTextStyles.small(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const text = 'CHAMELEON';
    const fontSize = 14.0;
    const spacing = 52.0;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.border.withValues(alpha: 0.6),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 4);

    final cols = (size.width / spacing).ceil() + 4;
    final rows = (size.height / spacing).ceil() + 4;

    for (int row = -rows; row <= rows; row++) {
      for (int col = -cols; col <= cols; col++) {
        final x = col * spacing - tp.width / 2;
        final y = row * spacing - tp.height / 2;
        // Checker offset for even rows
        final offsetX = (row % 2 == 0) ? 0.0 : spacing / 2;
        tp.paint(canvas, Offset(x + offsetX, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card — shown after flip
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.isImpostor,
    required this.word,
    required this.clue,
    required this.showCluesEnabled,
  });

  final bool isImpostor;
  final String word;
  final String clue;
  final bool showCluesEnabled;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _showClue = false;

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final bgColor = widget.isImpostor
        ? const Color(0xFF1E1010) // very dark red tint for impostor
        : AppColors.surface;
    final labelColor = widget.isImpostor ? AppColors.primary : AppColors.tertiary;
    final wordText = widget.isImpostor ? game.translate('role_chameleon') : widget.word.toUpperCase();
    final wordColor = widget.isImpostor ? AppColors.primary : AppColors.ink;
    final hint = widget.isImpostor
        ? game.translate('chameleon_hint')
        : game.translate('citizen_hint');

    return Container(
      width: double.infinity,
      height: 360,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isImpostor
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: widget.isImpostor
            ? const [
                BoxShadow(
                  color: AppColors.glowPrimary,
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: labelColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              widget.isImpostor ? game.translate('role_chameleon') : game.translate('role_citizen'),
              style: AppTextStyles.label(color: labelColor),
            ),
          ),
          const SizedBox(height: 24),
          // Main word
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              wordText,
              style: AppTextStyles.hero(
                color: wordColor,
                fontSize: widget.isImpostor ? 32.0 : _wordFontSize(wordText),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 20),
          // Hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              hint,
              style: AppTextStyles.small(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ),
          if (widget.isImpostor && widget.showCluesEnabled) ...[
            const SizedBox(height: 24),
            _ClueRevealButton(
              clue: widget.clue,
              showClue: _showClue,
              onToggle: () {
                HapticFeedback.selectionClick();
                setState(() => _showClue = !_showClue);
              },
            ),
          ],
        ],
      ),
    );
  }

  double _wordFontSize(String text) {
    if (text.length <= 4) return 44;
    if (text.length <= 6) return 36;
    if (text.length <= 8) return 30;
    if (text.length <= 12) return 24;
    return 18;
  }
}

class _ClueRevealButton extends StatelessWidget {
  const _ClueRevealButton({
    required this.clue,
    required this.showClue,
    required this.onToggle,
  });

  final String clue;
  final bool showClue;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: showClue 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showClue 
                ? AppColors.primary.withValues(alpha: 0.4) 
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showClue ? Icons.lightbulb : Icons.lightbulb_outline,
              color: showClue ? AppColors.primary : AppColors.muted,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              showClue
                  ? context.watch<GameState>().translate('clue_label', {'clue': clue})
                  : context.watch<GameState>().translate('clue_reveal_btn'),
              style: AppTextStyles.small(
                color: showClue ? AppColors.primary : AppColors.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardGlare extends StatelessWidget {
  const _CardGlare({required this.tiltOffset});
  final Offset tiltOffset;

  @override
  Widget build(BuildContext context) {
    if (tiltOffset == Offset.zero) return const SizedBox.shrink();

    // Specular light source moves inversely to the tilt angle
    final alignX = -tiltOffset.dx;
    final alignY = -tiltOffset.dy;

    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment(alignX - 1.0, alignY - 1.0),
            end: Alignment(alignX + 1.0, alignY + 1.0),
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.06),
              Colors.white.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.06),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}
