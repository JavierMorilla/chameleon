import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../widgets/game_button.dart';
import '../widgets/player_counter.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    final canStart = game.players.length >= 3 &&
        game.impostorCount < game.players.length;
    final reducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    final children = [
      // Players counter
      PlayerCounter(
        label: 'Jugadores',
        value: game.players.length,
        min: 3,
        max: 12,
        accentColor: AppColors.primary,
        onDecrement: () =>
            game.setPlayerCount(game.players.length - 1),
        onIncrement: () =>
            game.setPlayerCount(game.players.length + 1),
      ),
      const SizedBox(height: 24),
      // Impostors counter
      PlayerCounter(
        label: 'Impostores',
        value: game.impostorCount,
        min: 1,
        max: (game.players.length - 1).clamp(1, 11),
        accentColor: AppColors.primary,
        onDecrement: () =>
            game.setImpostorCount(game.impostorCount - 1),
        onIncrement: () =>
            game.setImpostorCount(game.impostorCount + 1),
      ),
      const SizedBox(height: 32),
      // Player names
      Text('NOMBRES', style: AppTextStyles.label()),
      const SizedBox(height: 4),
      Text(
        'Escribe los nombres del grupo',
        style: AppTextStyles.small(color: AppColors.muted),
      ),
      const SizedBox(height: 12),
      _PlayerNamesSection(
        players: game.players,
        onNameChanged: game.setPlayerName,
      ),
      const SizedBox(height: 32),
      // Category selector
      Text('CATEGORÍA', style: AppTextStyles.label()),
      const SizedBox(height: 12),
      _CategoryGrid(
        categories: game.categories,
        selected: game.category,
        onSelect: game.setCategory,
      ),
      const SizedBox(height: 24),
      // Timer selector
      Text('TIEMPO DE RONDA', style: AppTextStyles.label()),
      const SizedBox(height: 12),
      _TimerSelector(
        current: game.timerSeconds,
        onSelect: game.setTimerSeconds,
      ),
      const SizedBox(height: 32),
      // Clues toggle
      _ClueToggle(
        enabled: game.showCluesEnabled,
        onChanged: game.setShowCluesEnabled,
      ),
      const SizedBox(height: 32),
      // Validation message
      if (!canStart) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Mínimo 3 jugadores y menos impostores que jugadores.',
            style: AppTextStyles.small(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 16),
      ],
      GameButton(
        label: '¡Empezar!',
        onTap: canStart
            ? () {
                HapticFeedback.heavyImpact();
                game.startGame();
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Mínimo 3 jugadores y menos impostores que jugadores.',
                      style: AppTextStyles.small(color: AppColors.ink),
                    ),
                    backgroundColor: AppColors.surface2,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
        disabled: !canStart,
      ),
      const SizedBox(height: 32),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      game.goToSplash();
                    },
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.muted, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text('Nueva partida', style: AppTextStyles.subheading()),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: reducedMotion
                      ? children
                      : children
                          .animate(interval: 40.ms)
                          .fadeIn(duration: 450.ms, curve: Curves.easeOutQuad)
                          .slideY(begin: 0.03, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
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
// Player names section — inline editable name per player
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerNamesSection extends StatefulWidget {
  const _PlayerNamesSection({
    required this.players,
    required this.onNameChanged,
  });

  final List<String> players;
  final void Function(int index, String name) onNameChanged;

  @override
  State<_PlayerNamesSection> createState() => _PlayerNamesSectionState();
}

class _PlayerNamesSectionState extends State<_PlayerNamesSection> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _focusNodes = [];
    _syncControllers();
  }

  void _syncControllers() {
    final currentLength = _controllers.length;
    final targetLength = widget.players.length;

    if (currentLength < targetLength) {
      // Grow
      for (int i = currentLength; i < targetLength; i++) {
        _controllers.add(TextEditingController(text: widget.players[i]));
        _focusNodes.add(FocusNode());
      }
    } else if (currentLength > targetLength) {
      // Shrink
      for (int i = targetLength; i < currentLength; i++) {
        _controllers[i].dispose();
        _focusNodes[i].dispose();
      }
      _controllers.removeRange(targetLength, currentLength);
      _focusNodes.removeRange(targetLength, currentLength);
    }

    // Sync text for existing ones if they don't have focus
    for (int i = 0; i < targetLength; i++) {
      if (_controllers[i].text != widget.players[i] &&
          !_focusNodes[i].hasFocus) {
        _controllers[i].text = widget.players[i];
      }
    }
  }

  @override
  void didUpdateWidget(covariant _PlayerNamesSection old) {
    super.didUpdateWidget(old);
    _syncControllers();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.players.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _NameField(
            key: ValueKey(i), // Use key to prevent state reuse bugs
            index: i,
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            onSubmit: (name) => widget.onNameChanged(i, name),
            nextFocus:
                i < widget.players.length - 1 ? _focusNodes[i + 1] : null,
          ),
        );
      }),
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({
    super.key,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    this.nextFocus,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onSubmit;
  final FocusNode? nextFocus;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  bool _focused = false;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    _listener = () {
      if (!mounted) return;
      setState(() => _focused = widget.focusNode.hasFocus);
      if (!widget.focusNode.hasFocus) {
        final text = widget.controller.text.trim();
        if (text.isNotEmpty) widget.onSubmit(text);
      }
    };
    widget.focusNode.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant _NameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_listener);
      widget.focusNode.addListener(_listener);
      _focused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        color: _focused ? AppColors.surface2 : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? AppColors.primary.withValues(alpha: 0.6) : AppColors.border,
          width: _focused ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Number badge
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.index + 1}',
              style: AppTextStyles.label(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: AppTextStyles.bodyMedium(),
              decoration: InputDecoration(
                hintText: 'Jugador ${widget.index + 1}',
                hintStyle: AppTextStyles.bodyMedium(color: AppColors.muted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textCapitalization: TextCapitalization.words,
              textInputAction: widget.nextFocus != null
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) {
                if (widget.nextFocus != null) {
                  widget.nextFocus!.requestFocus();
                } else {
                  widget.focusNode.unfocus();
                }
              },
              onChanged: (v) => widget.onSubmit(v),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String selected;
  final void Function(String) onSelect;

  static const _icons = <String, String>{
    'General':  '🎲',
    'Cine':     '🎬',
    'Comida':   '🍕',
    'Animales': '🐘',
    'Deportes': '⚽',
    'Lugares':  '🌍',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = cat == selected;
        final icon = _icons[cat] ?? '🎲';
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(cat);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  cat,
                  style: AppTextStyles.small(
                    color: isSelected ? AppColors.onPrimary : AppColors.ink,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TimerSelector extends StatelessWidget {
  const _TimerSelector({required this.current, required this.onSelect});

  final int current;
  final void Function(int) onSelect;

  static const options = [
    (60, '1 min'),
    (120, '2 min'),
    (180, '3 min'),
    (240, '4 min'),
    (300, '5 min'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map(((int, String) opt) {
        final isSelected = opt.$1 == current;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(opt.$1);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              opt.$2,
              style: AppTextStyles.small(
                color:
                    isSelected ? AppColors.onAccent : AppColors.ink,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ClueToggle extends StatelessWidget {
  const _ClueToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: enabled,
      label: 'Pistas para el impostor',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!enabled);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
              width: enabled ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pistas para el impostor',
                      style: AppTextStyles.bodySemibold(color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El impostor puede ver una pista sobre la palabra secreta.',
                      style: AppTextStyles.small(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Custom premium switch
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 26,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: enabled ? AppColors.primary : AppColors.border,
                ),
                alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
