import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

/// Encuentra la letra: tocar las 3 burbujas con la letra pedida.
class FindGame extends StatefulWidget {
  final String? firstTarget;
  const FindGame({super.key, this.firstTarget});

  @override
  State<FindGame> createState() => _FindGameState();
}

class _FindGameState extends State<FindGame> with Later {
  static const int rounds = 4;
  static const slots = [
    [16.0, 8.0, 100.0], [140.0, 0.0, 84.0], [250.0, 26.0, 92.0],
    [40.0, 132.0, 88.0], [160.0, 110.0, 96.0], [262.0, 158.0, 84.0],
    [10.0, 258.0, 86.0], [128.0, 240.0, 104.0], [254.0, 276.0, 84.0],
  ];
  static const slotCols = [Pal.orange, Pal.blue, Pal.green, Pal.purple, Pal.pink, Pal.teal, Pal.blue, Pal.yellow, Pal.orange];
  static const similar = {
    'B': ['D', 'P', 'R', 'E', 'F'],
    'M': ['N', 'W', 'H', 'V', 'A'],
    'S': ['Z', 'C', 'G', 'J', 'E'],
    'P': ['R', 'B', 'F', 'D', 'T'],
  };

  final math.Random _r = math.Random();
  int round = 0;
  bool done = false;
  String target = 'B';
  List<String> letters = [];
  final Set<int> found = {};
  int wrongIdx = -1;
  String msg = '';
  int earned = 0;
  int misses = 0;

  @override
  void initState() {
    super.initState();
    _makeRound(0);
    later(500, _repeat);
  }

  final LevelDef lv = app.lvl;

  void _makeRound(int r) {
    final ini = initialOf(app.name);
    final lvLetters = List<String>.from(lv.letters);
    String t;
    if (r == 0 && widget.firstTarget != null) {
      t = widget.firstTarget!;
    } else if (r == 0 && lvLetters.contains(ini)) {
      t = ini;
    } else {
      t = lvLetters[(r + _r.nextInt(lvLetters.length)) % lvLetters.length];
      if (t == target && lvLetters.length > 1) t = lvLetters[(lvLetters.indexOf(t) + 1) % lvLetters.length];
    }
    final sim = List<String>.from(similar[t] ?? (kLetters.where((x) => x != t).toList()..shuffle(_r)).take(5));
    final extra = kLetters.where((x) => x != t && !sim.contains(x)).toList()..shuffle(_r);
    final others = ([...sim, ...extra.take(2)]..shuffle(_r)).take(6).toList();
    target = t;
    letters = [t, t, t, ...others]..shuffle(_r);
    found.clear();
    wrongIdx = -1;
    misses = 0;
    final mine = r == 0 && app.hasName && t == ini && widget.firstTarget == null;
    final ts = showLetter(t, lv.lower);
    msg = mine ? '¡${app.name}, tu nombre empieza con $ts! Búscala 3 veces.' : '¡Busca y toca todas las $ts!';
  }

  void _repeat() => Voice.I.talk(['@I_toca', Voice.lc(target)]);

  void _tap(int k) {
    if (done || found.length >= 3 || found.contains(k)) return;
    final l = letters[k];
    if (l == target) {
      found.add(k);
      Voice.I.sfx('ok');
      if (found.length < 3) {
        Voice.I.talk([...Voice.I.praise(), Voice.lc(l)]);
        setState(() => msg = '¡Muy bien! Te faltan ${3 - found.length}.');
      } else {
        Voice.I.talk(['@P_excelente']);
        earned += misses == 0 ? 3 : 2;
        app.rateLetter(target, misses == 0 ? 3 : 2);
        setState(() => msg = '¡Excelente! Encontraste las 3.');
        later(1500, () {
          final r = round + 1;
          if (r >= rounds) {
            app.finishGame('encuentra', earned);
            Voice.I.sfx('win');
            setState(() {
              round = r;
              done = true;
            });
            later(900, () => Voice.I.talk(Voice.I.bravo()));
            return;
          }
          setState(() {
            round = r;
            _makeRound(r);
          });
          later(300, _repeat);
        });
      }
    } else {
      misses++;
      app.mistake(target);
      Voice.I.sfx('bad');
      Voice.I.talk(['@A_casi', '@I_toca', Voice.lc(target)]);
      setState(() {
        wrongIdx = k;
        msg = 'Esa es la ${showLetter(l, lv.lower)}. ¡Busca la ${showLetter(target, lv.lower)}!';
      });
      later(500, () => setState(() => wrongIdx = -1));
    }
  }

  void _restart() {
    setState(() {
      round = 0;
      earned = 0;
      done = false;
      _makeRound(0);
    });
    later(300, _repeat);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Encuentra · Nivel ${lv.n}',
      onRepeat: _repeat,
      overlay: done ? DoneOverlay(title: '¡Súper vista!', onRestart: _restart) : null,
      child: Column(
        children: [
          ProgressPill(done: round, total: rounds, g: Pal.pink),
          const SizedBox(height: 12),
          WhiteCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(children: [
              Expanded(child: Text('Toca todas las', style: baloo(24, color: Pal.ink))),
              GlossyLetter(showLetter(target, lv.lower), g: Pal.pink, size: 52),
              const SizedBox(width: 8),
              Text('${found.length}/3', style: baloo(24, color: const Color(0xFFA8185A))),
            ]),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 380,
            child: Stack(
              children: List.generate(letters.length, (k) {
                final s = slots[k];
                final f = found.contains(k);
                final w = wrongIdx == k;
                return Positioned(
                  left: s[0],
                  top: s[1],
                  child: Pressable(
                    label: 'Letra ${letters[k]}',
                    onTap: () => _tap(k),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: f ? 0.65 : 1,
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 120),
                        turns: w ? 0.02 : 0,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Balloon(letter: showLetter(letters[k], lv.lower), g: slotCols[k], size: s[2]),
                          if (f)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF22A02A),
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                        ]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          LumiSays(text: msg, onTap: _repeat),
        ],
      ),
    );
  }
}
