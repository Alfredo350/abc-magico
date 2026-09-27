import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

/// Une letra e imagen: tocar una letra y luego el dibujo que empieza con ella.
class MatchGame extends StatefulWidget {
  const MatchGame({super.key});

  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> with Later {
  static const int rounds = 3;
  final math.Random _r = math.Random();
  late List<LetterWord> order;
  int round = 0;
  bool done = false;
  List<LetterWord> pairs = [];
  List<int> lOrder = [0, 1, 2];
  List<int> tOrder = [0, 1, 2];
  int sel = -1;
  final Set<int> placed = {};
  int wrongT = -1;
  String msg = '';
  int earned = 0;
  int misses = 0;

  @override
  void initState() {
    super.initState();
    order = _makeOrder();
    _makeRound(0);
    later(500, _repeat);
  }

  final LevelDef lv = app.lvl;

  /// Primero las palabras de las letras del nivel, luego otras para completar.
  List<LetterWord> _makeOrder() {
    final mine = kWords.where((w) => lv.letters.contains(w.letter)).toList()..shuffle(_r);
    final rest = kWords.where((w) => !lv.letters.contains(w.letter)).toList()..shuffle(_r);
    return [...mine.take(9), ...rest].take(rounds * 3).toList()..shuffle(_r);
  }

  void _makeRound(int r) {
    final start = (r * 3) % order.length;
    pairs = List.generate(3, (k) => order[(start + k) % order.length]);
    lOrder = [0, 1, 2]..shuffle(_r);
    tOrder = [0, 1, 2]..shuffle(_r);
    sel = -1;
    placed.clear();
    wrongT = -1;
    misses = 0;
    msg = 'Toca una letra y después el dibujo que empieza con esa letra.';
  }

  void _repeat() => Voice.I.say('Toca una letra y después el dibujo que empieza con esa letra.');

  void _tapLetter(int i) {
    if (placed.contains(i) || done) return;
    Voice.I.sfx('tap');
    Voice.I.talk([Voice.lc(pairs[i].letter)]);
    setState(() {
      sel = i;
      msg = 'Ahora toca el dibujo que empieza con ${pairs[i].letter}.';
    });
  }

  void _tapTarget(int i) {
    if (placed.contains(i) || done) return;
    final p = pairs[i];
    if (sel < 0) {
      Voice.I.sfx('tap');
      Voice.I.talk([Voice.wc(p.word)]);
      setState(() => msg = 'Primero toca una letra.');
      return;
    }
    if (sel == i) {
      placed.add(i);
      Voice.I.sfx('ok');
      Voice.I.talk([...Voice.I.praise(), Voice.lc(p.letter), Voice.wc(p.word)]);
      app.rateLetter(p.letter, 1);
      setState(() {
        sel = -1;
        msg = '¡Eso es! ${p.letter} de ${p.word.toLowerCase()}.';
      });
      if (placed.length == 3) {
        earned += misses == 0 ? 3 : 2;
        later(1600, () {
          final r = round + 1;
          if (r >= rounds) {
            app.finishGame('une', earned);
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
        });
      }
    } else {
      misses++;
      app.mistake(pairs[sel].letter);
      Voice.I.sfx('bad');
      Voice.I.talk(['@A_casi', '@A_intenta']);
      setState(() {
        wrongT = i;
        msg = '${p.word} empieza con ${p.letter}. ¡Prueba otra vez!';
      });
      later(700, () => setState(() => wrongT = -1));
    }
  }

  void _restart() {
    order = _makeOrder();
    setState(() {
      round = 0;
      earned = 0;
      done = false;
      _makeRound(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    const lc = [Pal.pink, Pal.blue, Pal.orange];
    return GameScaffold(
      title: 'Une · Nivel ${lv.n}',
      onRepeat: _repeat,
      overlay: done ? DoneOverlay(title: '¡Todo unido!', onRestart: _restart) : null,
      child: Column(
        children: [
          ProgressPill(done: round, total: rounds, g: Pal.green),
          const SizedBox(height: 14),
          WoodSign.text('Toca una letra y luego su dibujo', size: 20),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (k) {
                final i = lOrder[k];
                final isSel = sel == i;
                final isPlaced = placed.contains(i);
                return Pressable(
                  label: 'Letra ${pairs[i].letter}',
                  onTap: () => _tapLetter(i),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isPlaced ? 0.25 : 1,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 150),
                      turns: isSel ? -0.02 : 0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 150),
                        scale: isSel ? 1.12 : 1,
                        child: Container(
                          decoration: isSel
                              ? BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0xFFFFD21F), spreadRadius: 6)])
                              : null,
                          child: Glossy(g: lc[k], radius: 24, width: 88, height: 88, child: LabelText(showLetter(pairs[i].letter, lv.lower), size: 54)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (k) {
              final i = tOrder[k];
              final p = pairs[i];
              final isPlaced = placed.contains(i);
              final border = isPlaced
                  ? const Color(0xFF3FC13A)
                  : (wrongT == i ? const Color(0xFFFF8A65) : (sel >= 0 ? const Color(0xFFFF4F93) : Colors.white));
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: k == 0 ? 0 : 5, right: k == 2 ? 0 : 5),
                  child: Pressable(
                    label: 'Dibujo ${p.word}',
                    onTap: () => _tapTarget(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: border, width: 4),
                        boxShadow: const [BoxShadow(color: Color(0x1F142850), offset: Offset(0, 6))],
                      ),
                      child: Column(children: [
                        WordPic(pic: p.pic, letter: p.letter, size: 80),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 46,
                          child: isPlaced
                              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Glossy(g: Pal.green, radius: 14, width: 46, height: 46, child: LabelText(showLetter(p.letter, lv.lower), size: 26)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF3FC13A), size: 28),
                                ])
                              : Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFBFC8D6), width: 3)),
                                ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(child: Text(p.word, style: baloo(17, color: Pal.ink))),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          LumiSays(text: msg, onTap: _repeat),
        ],
      ),
    );
  }
}
