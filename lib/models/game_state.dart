import 'dart:math';
import 'dart:ui';
// ignore_for_file: prefer_final_fields
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_bank.dart';
import '../utils/localization.dart';

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
const _kLanguage       = 'cfg_language';

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
  String language      = 'es';

  // ── Localization Helpers ─────────────────────────────────────────────────────
  String translate(String key, [Map<String, String>? args]) {
    return translateWith(language, key, args);
  }

  String translateCategory(String cat) {
    switch (cat) {
      case 'Cine': return translate('cat_cine');
      case 'Comida': return translate('cat_comida');
      case 'Animales': return translate('cat_animales');
      case 'Deportes': return translate('cat_deportes');
      case 'Lugares': return translate('cat_lugares');
      case 'General':
      default:
        return translate('cat_general');
    }
  }

  void setLanguage(String lang) {
    if (lang == 'es' || lang == 'en' || lang == 'de') {
      language = lang;
      _saveConfig();
      notifyListeners();
    }
  }

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
      
      final sysLang = PlatformDispatcher.instance.locale.languageCode;
      final defaultLang = (sysLang == 'de' || sysLang == 'en') ? sysLang : 'es';
      language = prefs.getString(_kLanguage) ?? defaultLang;

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
      await prefs.setString(_kLanguage, language);
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
        players.add('${translate('default_player_prefix')} ${i + 1}');
      }
    } else {
      players = players.sublist(0, clamped);
    }
    impostorCount = impostorCount.clamp(1, players.length - 1);
    _saveConfig();
    notifyListeners();
  }

  void setImpostorCount(int count) {
    impostorCount = count.clamp(1, players.length - 1);
    _saveConfig();
    notifyListeners();
  }

  void setPlayerName(int index, String name) {
    final trimmed = name.trim();
    if (index < players.length) {
      if (trimmed.isEmpty) {
        players[index] = '${translate('default_player_prefix')} ${index + 1}';
      } else {
        players[index] = trimmed;
      }
      _saveConfig();
      notifyListeners();
    }
  }

  void setCategory(String cat) {
    category = cat;
    _saveConfig();
    notifyListeners();
  }

  void setTimerSeconds(int secs) {
    timerSeconds = secs;
    _saveConfig();
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

    final wordsBank = getWordBank(language);
    final words = wordsBank[category] ?? wordsBank['General']!;
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
