import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

/// Estado global de la app (perfil del niño/niña, progreso y ajustes).
/// Se guarda en el teléfono con SharedPreferences.
final AppState app = AppState();

class Medal {
  final String id;
  final String title;
  const Medal(this.id, this.title);
}

const List<Medal> kMedals = [
  Medal('first', 'Primer juego'),
  Medal('letters5', '5 letras'),
  Medal('stars100', '100 estrellas'),
  Medal('allgames', 'Todos los juegos'),
  Medal('streak3', 'Racha de 3 días'),
];

const List<String> kGames = ['escucha', 'encuentra', 'une', 'traza', 'completa', 'memoria', 'ordena', 'detective'];

class AppState extends ChangeNotifier {
  SharedPreferences? _p;

  // Perfil
  String name = '';
  String gender = ''; // 'm' niño, 'f' niña

  // Progreso
  int stars = 0;
  int activities = 0;
  Map<String, int> letterStars = {};
  Set<String> gamesPlayed = {};
  Map<String, int> minutes = {}; // 'aaaa-mm-dd' -> minutos
  Set<String> days = {};
  Map<String, int> mistakes = {};
  List<String> medals = [];
  String lastMedal = '';
  int lastEarned = 0;

  // Niveles (1 a 15)
  int currentLevel = 1;
  Map<String, List<String>> levelGames = {};

  // Ajustes
  bool voiceOn = true;
  bool fxOn = true;
  double volume = 0.9;

  bool get isGirl => gender == 'f';
  bool get hasName => name.isNotEmpty;
  int get lettersLearned => letterStars.values.where((v) => v > 0).length;
  /// Nivel más alto abierto: se abre el siguiente al completar 3 juegos distintos en un nivel.
  int get maxUnlocked {
    var m = 1;
    while (m < kLevels.length && (levelGames['$m']?.length ?? 0) >= 3) {
      m++;
    }
    return m;
  }

  /// Estrellas de un nivel (una por juego distinto terminado, hasta 3).
  int levelStars(int n) => math.min(3, levelGames['$n']?.length ?? 0);
  LevelDef get lvl => levelDef(currentLevel);
  int get unlockedLetters => math.min(27, maxUnlocked * 3);
  bool get memoryUnlocked => true;
  String get explorer => isGirl ? 'exploradora' : 'explorador';

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get streak {
    var d = DateTime.now();
    if (!days.contains(dayKey(d))) d = d.subtract(const Duration(days: 1));
    var s = 0;
    while (days.contains(dayKey(d))) {
      s++;
      d = d.subtract(const Duration(days: 1));
    }
    return s;
  }

  /// Minutos de los últimos 7 días (del más antiguo a hoy).
  List<int> get last7 {
    final now = DateTime.now();
    return List.generate(7, (i) => minutes[dayKey(now.subtract(Duration(days: 6 - i)))] ?? 0);
  }

  List<String> get weakLetters {
    final e = mistakes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return e.take(3).map((x) => x.key).toList();
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _p = p;
      name = p.getString('name') ?? '';
      gender = p.getString('gender') ?? '';
      stars = p.getInt('stars') ?? 0;
      activities = p.getInt('activities') ?? 0;
      letterStars = _intMap(p.getString('letterStars'));
      minutes = _intMap(p.getString('minutes'));
      mistakes = _intMap(p.getString('mistakes'));
      gamesPlayed = (p.getStringList('gamesPlayed') ?? []).toSet();
      days = (p.getStringList('days') ?? []).toSet();
      medals = p.getStringList('medals') ?? [];
      voiceOn = p.getBool('voiceOn') ?? true;
      fxOn = p.getBool('fxOn') ?? true;
      volume = p.getDouble('volume') ?? 0.9;
      currentLevel = p.getInt('currentLevel') ?? 1;
      final lg = p.getString('levelGames');
      if (lg != null && lg.isNotEmpty) {
        final m = jsonDecode(lg) as Map<String, dynamic>;
        levelGames = m.map((k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()));
      }
    } catch (_) {}
  }

  Map<String, int> _intMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  void _save() {
    final p = _p;
    if (p == null) return;
    p.setString('name', name);
    p.setString('gender', gender);
    p.setInt('stars', stars);
    p.setInt('activities', activities);
    p.setString('letterStars', jsonEncode(letterStars));
    p.setString('minutes', jsonEncode(minutes));
    p.setString('mistakes', jsonEncode(mistakes));
    p.setStringList('gamesPlayed', gamesPlayed.toList());
    p.setStringList('days', days.toList());
    p.setStringList('medals', medals);
    p.setBool('voiceOn', voiceOn);
    p.setBool('fxOn', fxOn);
    p.setDouble('volume', volume);
    p.setInt('currentLevel', currentLevel);
    p.setString('levelGames', jsonEncode(levelGames));
  }

  void setKid(String n, String g) {
    name = n;
    gender = g;
    _save();
    notifyListeners();
  }

  /// Da estrellas a una letra (guarda el máximo, de 0 a 3).
  void rateLetter(String letter, int s) {
    final cur = letterStars[letter] ?? 0;
    if (s > cur) letterStars[letter] = math.min(3, s);
    days.add(dayKey(DateTime.now()));
    _checkMedals();
    _save();
    notifyListeners();
  }

  void mistake(String letter) {
    mistakes[letter] = (mistakes[letter] ?? 0) + 1;
    _save();
  }

  /// Al terminar un juego completo.
  void finishGame(String game, int earned) {
    stars += earned;
    lastEarned = earned;
    activities += 1;
    gamesPlayed.add(game);
    final lg = levelGames.putIfAbsent('$currentLevel', () => <String>[]);
    if (!lg.contains(game)) lg.add(game);
    days.add(dayKey(DateTime.now()));
    lastMedal = '';
    _checkMedals();
    _save();
    notifyListeners();
  }

  void tickMinute() {
    final k = dayKey(DateTime.now());
    minutes[k] = (minutes[k] ?? 0) + 1;
    days.add(k);
    _save();
  }

  void _checkMedals() {
    void give(String id, bool cond) {
      if (cond && !medals.contains(id)) {
        medals.add(id);
        lastMedal = id;
      }
    }

    give('first', activities >= 1);
    give('letters5', lettersLearned >= 5);
    give('stars100', stars >= 100);
    give('allgames', kGames.every(gamesPlayed.contains));
    give('streak3', streak >= 3);
  }

  void setLevel(int n) {
    currentLevel = n.clamp(1, maxUnlocked);
    _save();
    notifyListeners();
  }

  void setVoice(bool v) {
    voiceOn = v;
    _save();
    notifyListeners();
  }

  void setFx(bool v) {
    fxOn = v;
    _save();
    notifyListeners();
  }

  void setVolume(double v) {
    volume = v;
    _save();
    notifyListeners();
  }

  /// Reinicia el progreso (conserva nombre y ajustes).
  void resetProgress() {
    stars = 0;
    activities = 0;
    letterStars = {};
    gamesPlayed = {};
    minutes = {};
    days = {};
    mistakes = {};
    medals = [];
    currentLevel = 1;
    levelGames = {};
    lastMedal = '';
    lastEarned = 0;
    _save();
    notifyListeners();
  }
}
