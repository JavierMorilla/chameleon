import 'dart:math';
// ignore_for_file: prefer_final_fields
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_bank.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GamePhase
// ─────────────────────────────────────────────────────────────────────────────
enum GamePhase { splash, setup, handoff, reveal, timer, vote, result, end }

// ─────────────────────────────────────────────────────────────────────────────
// SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────
const _kPlayers        = 'cfg_players';
const _kImpostorCount  = 'cfg_impostor_count';
const _kCategory       = 'cfg_category';
const _kTimerSeconds   = 'cfg_timer_seconds';
const _kShowClues      = 'cfg_show_clues';

// ─────────────────────────────────────────────────────────────────────────────
// GameState — single source of truth, ChangeNotifier
// ─────────────────────────────────────────────────────────────────────────────
class GameState extends ChangeNotifier {
  // ── Config ──────────────────────────────────────────────────────────────────
  List<String> players = List.generate(4, (i) => 'Jugador ${i + 1}');
  int impostorCount    = 1;
  String category      = 'General';
  int timerSeconds     = 180;
  bool showCluesEnabled = true;

  // ── Runtime ─────────────────────────────────────────────────────────────────
  GamePhase phase           = GamePhase.splash;
  List<int> impostorIndices = [];
  String roundWord          = '';
  String roundClue          = '';
  int currentPlayerIndex    = 0;
  bool cardRevealed         = false;

  // ── Voting ───────────────────────────────────────────────────────────────────
  int? votedPlayerIndex;
  List<int> eliminatedIndices = [];

  // ── Result ───────────────────────────────────────────────────────────────────
  bool eliminatedWasImpostor = false;
  int roundNumber            = 1;

  // ── End ──────────────────────────────────────────────────────────────────────
  String winner = '';
  List<String> impostorNames = [];

  // ── Categories ───────────────────────────────────────────────────────────────
  List<String> get categories => kWordBank.keys.toList();

  bool get isCurrentImpostor => impostorIndices.contains(currentPlayerIndex);
  String get currentPlayerName => players[currentPlayerIndex];
  bool get isLastPlayer => currentPlayerIndex == players.length - 1;

  // ─────────────────────────────────────────────────────────────────────────────
  // Persistence — load saved config on startup
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlayers = prefs.getStringList(_kPlayers);
      if (savedPlayers != null && savedPlayers.length >= 3) {
        players = List<String>.from(savedPlayers);
      }
      impostorCount = (prefs.getInt(_kImpostorCount) ?? 1)
          .clamp(1, players.length - 1);
      final savedCat = prefs.getString(_kCategory) ?? 'General';
      category = kWordBank.containsKey(savedCat) ? savedCat : 'General';
      timerSeconds = prefs.getInt(_kTimerSeconds) ?? 180;
      showCluesEnabled = prefs.getBool(_kShowClues) ?? true;
      notifyListeners();
    } catch (_) {
      // Fail silently — defaults are fine
    }
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kPlayers, players);
      await prefs.setInt(_kImpostorCount, impostorCount);
      await prefs.setString(_kCategory, category);
      await prefs.setInt(_kTimerSeconds, timerSeconds);
      await prefs.setBool(_kShowClues, showCluesEnabled);
    } catch (_) {
      // Fail silently — game still works without persistence
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Player management
  // ─────────────────────────────────────────────────────────────────────────────
  void setPlayerCount(int count) {
    final clamped = count.clamp(3, 12);
    if (clamped == players.length) return;
    if (clamped > players.length) {
      for (int i = players.length; i < clamped; i++) {
        players.add('Jugador ${i + 1}');
      }
    } else {
      players = players.sublist(0, clamped);
    }
    impostorCount = impostorCount.clamp(1, players.length - 1);
    notifyListeners();
  }

  void setImpostorCount(int count) {
    impostorCount = count.clamp(1, players.length - 1);
    notifyListeners();
  }

  void setPlayerName(int index, String name) {
    final trimmed = name.trim();
    if (index < players.length && trimmed.isNotEmpty) {
      players[index] = trimmed;
      notifyListeners();
    }
  }

  void setCategory(String cat) {
    category = cat;
    notifyListeners();
  }

  void setTimerSeconds(int secs) {
    timerSeconds = secs;
    notifyListeners();
  }

  void setShowCluesEnabled(bool value) {
    showCluesEnabled = value;
    _saveConfig();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Game flow
  // ─────────────────────────────────────────────────────────────────────────────
  void goTo(GamePhase p) {
    phase = p;
    notifyListeners();
  }

  /// Start a new round: assign roles, pick a word, go to handoff.
  void startGame() {
    final rng = Random();
    final indices = List.generate(players.length, (i) => i)..shuffle(rng);
    impostorIndices = indices.sublist(0, impostorCount);

    final words = kWordBank[category] ?? kWordBank['General']!;
    final selectedGameWord = words[rng.nextInt(words.length)];
    roundWord = selectedGameWord.word;
    roundClue = selectedGameWord.clue;

    currentPlayerIndex = 0;
    cardRevealed = false;
    votedPlayerIndex = null;
    eliminatedIndices = [];

    phase = GamePhase.handoff;
    _saveConfig(); // persist config when game actually starts
    notifyListeners();
  }

  void advanceReveal() {
    cardRevealed = false;
    if (currentPlayerIndex < players.length - 1) {
      currentPlayerIndex++;
      phase = GamePhase.handoff;
    } else {
      phase = GamePhase.timer;
    }
    notifyListeners();
  }

  void revealCard() {
    cardRevealed = true;
    notifyListeners();
  }

  void showReveal() {
    phase = GamePhase.reveal;
    notifyListeners();
  }

  void endTimer() {
    votedPlayerIndex = null;
    phase = GamePhase.vote;
    notifyListeners();
  }

  void setVote(int index) {
    votedPlayerIndex = index;
    notifyListeners();
  }

  void confirmVote() {
    if (votedPlayerIndex == null) return;
    eliminatedWasImpostor = impostorIndices.contains(votedPlayerIndex!);

    // Snapshot impostor names BEFORE removing from list
    impostorNames = impostorIndices
        .where((i) => i < players.length)
        .map((i) => players[i])
        .toList();

    // Add to eliminated list
    eliminatedIndices.add(votedPlayerIndex!);

    if (eliminatedWasImpostor) {
      impostorIndices.remove(votedPlayerIndex!);
    }

    final activeImpostors = impostorIndices.where((i) => !eliminatedIndices.contains(i)).length;
    final activePlayers = players.length - eliminatedIndices.length;

    if (activeImpostors == 0) {
      winner = 'ciudadanos';
    } else if (2 * activeImpostors >= activePlayers) {
      winner = 'impostor';
    } else {
      winner = 'continua';
    }

    phase = GamePhase.result;
    notifyListeners();
  }

  void nextDiscussionRound() {
    roundNumber++;
    votedPlayerIndex = null;
    phase = GamePhase.timer;
    notifyListeners();
  }

  void finishGame() {
    phase = GamePhase.end;
    notifyListeners();
  }

  void playAgainSameConfig() {
    roundNumber = 1;
    startGame();
  }

  void newGame() {
    roundNumber = 1;
    impostorIndices = [];
    impostorNames = [];
    roundWord = '';
    currentPlayerIndex = 0;
    cardRevealed = false;
    votedPlayerIndex = null;
    eliminatedIndices = [];
    winner = '';
    phase = GamePhase.setup;
    notifyListeners();
  }

  void goToSplash() {
    phase = GamePhase.splash;
    notifyListeners();
  }
}
