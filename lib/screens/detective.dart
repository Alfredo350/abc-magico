import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

class _Hidden {
  final String letter;
  final double x;
  final double y;
  final double size;
  final Color color;
  final double angle;
  const _Hidden(this.letter, this.x, this.y, this.size, this.color, this.angle);
}

class _Round {
  final String target;
  final List<_Hidden> items;
  const _Round(this.target, this.items);
}

/// Detective ABC: buscar letras escondidas en el parque.
class DetectiveGame extends StatefulWidget {
  const DetectiveGame({super.key});

  @override
  State<DetectiveGame> createState() => _DetectiveGameState();
}

class _DetectiveGameState extends State<DetectiveGame> with Later {
  // Escondites en la escena de 350 x 420 (x, y, color que se camufla con el fondo).
  static const spots = [
    [90.0, 118.0, 0xFF1E7F28], [40.0, 180.0, 0xFF1E7F28], [70.0, 62.0, 0xFF9CCBEF], [178.0, 96.0, 0xFF7FB8F0],
    [268.0, 222.0, 0xFFC98A00], [222.0, 250.0, 0xFFC98A00], [300.0, 60.0, 0xFFE08E00], [250.0, 110.0, 0xFF9CCBEF],
    [138.0, 356.0, 0xFF2E8A2E], [36.0, 330.0, 0xFF2E8A2E], [300.0, 360.0, 0xFFEAF7E4], [200.0, 380.0, 0xFF2E8A2E],
    [64.0, 250.0, 0xFF6B3E1D], [160.0, 300.0, 0xFF3E8E30],
  ];
  static const int rounds = 3;
  final math.Random _r = math.Random();
  final LevelDef lv = app.lvl;
  late List<_Round> _rounds = _makeRounds();

  List<_Round> _makeRounds() {
    final letters = List<String>.from(lv.letters)..shuffle(_r);
    return List.generate(rounds, (i) {
      final t = letters[i % letters.length];
      final idx = List.generate(spots.length, (k) => k)..shuffle(_r);
      final decoys = kLetters.where((l) => l != t).toList()..shuffle(_r);
      final items = <_Hidden>[];
      for (var k = 0; k < 6; k++) {
        final sp = spots[idx[k]];
        final l = k < 3 ? t : decoys[k];
        items.add(_Hidden(showLetter(l, lv.lower), sp[0].toDouble(), sp[1].toDouble(), 22.0 + _r.nextInt(9), Color(sp[2].toInt()), (_r.nextDouble() - 0.5) * 0.5));
      }
      items.shuffle(_r);
      return _Round(showLetter(t, lv.lower), items);
    });
  }

  static const double sceneW = 336;
  static const double sceneH = 403;

  int round = 0;
  bool done = false;
  final Set<int> found = {};
  int wrong = -1;
  int hint = -1;
  String msg = '';
  int earned = 0;
  int misses = 0;

  String get target => _rounds[round.clamp(0, rounds - 1)].target;
  List<_Hidden> get items => _rounds[round.clamp(0, rounds - 1)].items;

  @override
  void initState() {
    super.initState();
    msg = 'Mira bien el parque y toca las $target escondidas.';
    later(500, _repeat);
  }

  void _repeat() => Voice.I.talk(['@I_escondidas', Voice.lc(target.toUpperCase())]);

  void _tap(int k) {
    if (done || found.contains(k) || found.length >= 3) return;
    final it = items[k];
    if (it.letter == target) {
      found.add(k);
      Voice.I.sfx('ok');
      if (found.length < 3) {
        Voice.I.talk([...Voice.I.praise(), Voice.lc(it.letter.toUpperCase())]);
        setState(() {
          hint = -1;
          msg = '¡Bien! Te faltan ${3 - found.length}.';
        });
      } else {
        Voice.I.talk(['@P_excelente']);
        earned += misses == 0 ? 4 : 3;
        app.rateLetter(target.toUpperCase(), misses == 0 ? 3 : 2);
        setState(() {
          hint = -1;
          msg = '¡Caso resuelto!';
        });
        later(1500, () {
          final r = round + 1;
          if (r >= rounds) {
            app.finishGame('detective', earned);
            Voice.I.sfx('win');
            setState(() => done = true);
            later(900, () => Voice.I.talk(Voice.I.bravo()));
            return;
          }
          setState(() {
            round = r;
            found.clear();
            misses = 0;
            msg = 'Ahora busca las $target escondidas.';
          });
          later(300, _repeat);
        });
      }
    } else {
      misses++;
      app.mistake(target.toUpperCase());
      Voice.I.sfx('bad');
      Voice.I.talk(['@A_casi', '@I_escondidas', Voice.lc(target.toUpperCase())]);
      setState(() {
        wrong = k;
        msg = 'Esa es la ${it.letter}. ¡Busca la $target!';
      });
      later(600, () => setState(() => wrong = -1));
    }
  }

  void _hint() {
    final k = List.generate(items.length, (i) => i).firstWhere((i) => items[i].letter == target && !found.contains(i), orElse: () => -1);
    if (k < 0) return;
    Voice.I.sfx('tap');
    Voice.I.say('Mira donde brilla.');
    setState(() => hint = k);
    later(1800, () => setState(() => hint = -1));
  }

  void _restart() {
    _rounds = _makeRounds();
    setState(() {
      round = 0;
      found.clear();
      done = false;
      earned = 0;
      misses = 0;
      msg = 'Mira bien el parque y toca las $target escondidas.';
    });
    later(300, _repeat);
  }

  @override
  Widget build(BuildContext context) {
    final sx = sceneW / 350;
    final sy = sceneH / 420;
    return GameScaffold(
      title: 'Detective · Nivel ${lv.n}',
      onRepeat: _repeat,
      overlay: done ? DoneOverlay(title: '¡Gran detective!', onRestart: _restart) : null,
      child: Column(
        children: [
          ProgressPill(done: done ? rounds : round, total: rounds, g: Pal.green),
          const SizedBox(height: 10),
          WhiteCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(children: [
              Expanded(child: Text('Busca 3 letras', style: baloo(23, color: Pal.ink))),
              GlossyLetter(target, g: Pal.green, size: 48),
              const SizedBox(width: 8),
              Text('${found.length}/3', style: baloo(24, color: const Color(0xFF1E7F28))),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            width: sceneW + 8,
            height: sceneH + 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [BoxShadow(color: Color(0x1F142850), offset: Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(children: [
                const Positioned.fill(child: Img('detective_scene', width: sceneW, height: sceneH)),
                for (var k = 0; k < items.length; k++)
                  Positioned(
                    left: items[k].x * sx - 24,
                    top: items[k].y * sy - 24,
                    child: Pressable(
                      label: 'Letra escondida',
                      onTap: () => _tap(k),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: found.contains(k) ? const Color(0x99FFFFFF) : Colors.transparent,
                          border: Border.all(
                            color: found.contains(k) ? const Color(0xFF22A02A) : (wrong == k ? const Color(0xFFFF8A65) : Colors.transparent),
                            width: found.contains(k) ? 4 : 3,
                          ),
                          boxShadow: hint == k ? const [BoxShadow(color: Color(0xFFFFD21F), blurRadius: 24, spreadRadius: 8)] : null,
                        ),
                        child: Transform.rotate(
                          angle: items[k].angle,
                          child: Text(items[k].letter, style: baloo(items[k].size, color: items[k].color)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          BigButton(text: 'Pista', g: Pal.yellow, darkText: true, icon: Icons.lightbulb_rounded, height: 58, fontSize: 22, onTap: _hint),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text(msg, style: nunito(16, color: Pal.ink)),
          ),
        ],
      ),
    );
  }
}
