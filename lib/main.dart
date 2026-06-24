import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/handoff_screen.dart';
import 'screens/reveal_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/vote_screen.dart';
import 'screens/result_screen.dart';
import 'screens/end_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Dark status bar with light icons
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  // Load persisted config before first frame
  final gameState = GameState();
  await gameState.loadSavedConfig();
  runApp(
    ChangeNotifierProvider<GameState>.value(
      value: gameState,
      child: const ImpostorApp(),
    ),
  );
}

class ImpostorApp extends StatelessWidget {
  const ImpostorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chameleon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const GameRouter(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GameRouter — phase-driven screen switcher with crossfade transitions
// ─────────────────────────────────────────────────────────────────────────────
class GameRouter extends StatelessWidget {
  const GameRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final phase = context.select<GameState, GamePhase>((g) => g.phase);
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    return AnimatedSwitcher(
      duration: Duration(milliseconds: reducedMotion ? 200 : 350),
      transitionBuilder: (child, animation) {
        if (reducedMotion) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        }

        final offsetAnim = Tween<Offset>(
          begin: const Offset(0.0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        final scaleAnim = Tween<double>(
          begin: 0.95,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: SlideTransition(
            position: offsetAnim,
            child: ScaleTransition(
              scale: scaleAnim,
              child: child,
            ),
          ),
        );
      },
      child: _screenFor(phase),
    );
  }

  Widget _screenFor(GamePhase phase) {
    return switch (phase) {
      GamePhase.splash   => const SplashScreen(key: ValueKey('splash')),
      GamePhase.setup    => const SetupScreen(key: ValueKey('setup')),
      GamePhase.handoff  => const HandoffScreen(key: ValueKey('handoff')),
      GamePhase.reveal   => const RevealScreen(key: ValueKey('reveal')),
      GamePhase.timer    => const TimerScreen(key: ValueKey('timer')),
      GamePhase.vote     => const VoteScreen(key: ValueKey('vote')),
      GamePhase.result   => const ResultScreen(key: ValueKey('result')),
      GamePhase.end      => const EndScreen(key: ValueKey('end')),
    };
  }
}
