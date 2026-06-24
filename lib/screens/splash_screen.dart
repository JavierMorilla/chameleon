import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';

import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    Widget animate(Widget child, Duration delay, {double slideBegin = 0.04, bool isLogo = false}) {
      if (reducedMotion) {
        return child.animate().fadeIn(duration: 200.ms);
      }
      var a = child.animate(delay: delay)
          .fadeIn(duration: 600.ms, curve: Curves.easeOutQuad)
          .slideY(begin: slideBegin, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
      if (isLogo) {
        a = a.shimmer(delay: 800.ms, duration: 1500.ms, color: AppColors.primary.withValues(alpha: 0.35));
      }
      return a;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Help button — top right
              Align(
                alignment: Alignment.topRight,
                child: animate(
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      showModalBottomSheet<void>(
                        context: context,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => const _RulesSheet(),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, right: 4),
                      child: Semantics(
                        button: true,
                        label: game.translate('rules_title'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '?',
                            style: AppTextStyles.bodySemibold(
                              color: AppColors.muted,
                            ).copyWith(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  300.ms,
                  slideBegin: -0.04,
                ),
              ),
              const Spacer(flex: 3),
              // Logo
              animate(
                Column(
                  children: [
                    // Eyemark — small coral dash
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      game.translate('app_title'),
                      textAlign: TextAlign.center,
                      softWrap: false,
                      style: AppTextStyles.hero(
                        fontSize: 40,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      game.translate('app_subtitle'),
                      style: AppTextStyles.body(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                0.ms,
                isLogo: true,
              ),
              const Spacer(flex: 4),
              // Language Selector & CTA
              animate(
                Column(
                  children: [
                    _LanguageSelector(
                      current: game.language,
                      onSelect: game.setLanguage,
                    ),
                    const SizedBox(height: 24),
                    GameButton(
                      label: game.translate('play'),
                      onTap: () => game.goTo(GamePhase.setup),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
                150.ms,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rules sheet — shown when tapping ?
// ─────────────────────────────────────────────────────────────────────────────
class _RulesSheet extends StatelessWidget {
  const _RulesSheet();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
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
            Text(game.translate('rules_title'), style: AppTextStyles.heading()),
            const SizedBox(height: 20),
            _RuleRow(
              number: '1',
              text: game.translate('rules_step_1'),
              color: AppColors.tertiary,
            ),
            _RuleRow(
              number: '2',
              text: game.translate('rules_step_2'),
              color: AppColors.accent,
            ),
            _RuleRow(
              number: '3',
              text: game.translate('rules_step_3'),
              color: AppColors.primary,
            ),
            _RuleRow(
              number: '4',
              text: game.translate('rules_step_4'),
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.number, required this.text, required this.color});
  final String number;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(number, style: AppTextStyles.label(color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.small(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language selector custom widget for Splash screen
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.current, required this.onSelect});

  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LangChip(
          label: 'ES 🇪🇸',
          active: current == 'es',
          onTap: () => onSelect('es'),
        ),
        const SizedBox(width: 8),
        _LangChip(
          label: 'EN 🇬🇧',
          active: current == 'en',
          onTap: () => onSelect('en'),
        ),
        const SizedBox(width: 8),
        _LangChip(
          label: 'DE 🇩🇪',
          active: current == 'de',
          onTap: () => onSelect('de'),
        ),
      ],
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySemibold(
            color: active ? AppColors.primary : AppColors.muted,
          ).copyWith(fontSize: 12),
        ),
      ),
    );
  }
}
