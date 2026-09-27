import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

class _Word {
  final String pic;
  final String word;
  final int hole;
  const _Word(this.pic, this.word, this.hole);
}

/// Completa la palabra: elegir la letra que falta.
class CompleteGame extends StatefulWidget {
  const CompleteGame({super.key});

  @override
  State<CompleteGame> createState() => _CompleteGameState();
}

class _CompleteGameState extends State<CompleteGame> with Later {
  static const int rounds = 5;
  static const pool = ['M', 'S', 'R', 'T', 'L', 'P', 'B', 'N', 'O', 'A', 'E', 'U', 'C', 'G', 'Z', 'D'];

  final math.Random _r = math.Random();
  final LevelDef lv = app.lvl;
  late List<_Word> order;

  /// Palabras de las letras del nivel (falta su letra) y otras para completar 5 rondas.
  List<_Word> _makeOrder() {
    final mine = kWords.where((w) => lv.letters.contains(w.letter)).toList()..shuffle(_r);
    final rest = kWords.where((w) => !lv.letters.contains(w.letter)).toList()..shuffle(_r);
    final out = <_Word>[for (final w in mine.take(rounds)) _Word(w.pic, w.word, holeFor(w))];
    for (final w in rest) {
      if (out.length >= rounds) break;
      out.add(_Word(w.pic, w.word, _r.nextInt(w.word.length)));
    }
    return out..shuffle(_r);
  }
  int round = 0;
  bool done = false;
  late _Word w;
  String miss = '';
  List<String> opts = [];
  final List<String> wrong = [];
  bool solved = false;
  String msg = '';
  int earned = 0;

  @override
  void initState() {
    super.initState();
    order = _makeOrder();
    _makeRound(0);
    later(500, _repeat);
  }

  void _makeRound(int r) {
    w = order[r];
    miss = stripAccents(w.word[w.hole]);
    final others = pool.where((x) => x != miss).toList()..shuffle(_r);
    opts = [miss, ...others.take(2)]..shuffle(_r);
    wrong.clear();
    solved = false;
    msg = 'Escucha la palabra. ¿Qué letra va en el hueco?';
  }

  void _repeat() => Voice.I.talk([Voice.wc(w.word), '@I_falta']);

  void _sayWord() {
    Voice.I.sfx('tap');
    Voice.I.talk([Voice.wc(w.word)]);
  }

  void _pick(String l) {
    if (solved || done) return;
    if (l == miss) {
      Voice.I.sfx('ok');
      Voice.I.talk([...Voice.I.praise(), Voice.wc(w.word)]);
      earned += wrong.isEmpty ? 3 : 1;
      app.rateLetter(miss, wrong.isEmpty ? 2 : 1);
      setState(() {
        solved = true;
        msg = '¡Genial! ${w.word.split('').join('-')}, ¡${w.word.toLowerCase()}!';
      });
      later(1900, () {
        final r = round + 1;
        if (r >= rounds) {
          app.finishGame('completa', earned);
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
    } else {
      Voice.I.sfx('bad');
      app.mistake(miss);
      Voice.I.talk(['@A_casi', '@A_escucha', Voice.wc(w.word)]);
      setState(() {
        wrong.add(l);
        msg = 'Casi… escucha otra vez: «${w.word.toLowerCase()}».';
      });
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
    later(300, _repeat);
  }

  @override
  Widget build(BuildContext context) {
    final chars = w.word.split('');
    final n = chars.length;
    final tileW = math.min(66.0, (300 - (n - 1) * 6) / n);
    final fs = n > 5 ? 32.0 : 50.0;
    const cols = [Pal.blue, Pal.pink, Pal.purple];
    return GameScaffold(
      title: 'Completa · Nivel ${lv.n}',
      onRepeat: _repeat,
      overlay: done ? DoneOverlay(title: '¡Palabras listas!', onRestart: _restart) : null,
      child: Column(
        children: [
          ProgressPill(done: round, total: rounds, g: Pal.teal),
          const SizedBox(height: 12),
          WhiteCard(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Pressable(label: 'Escuchar la palabra', onTap: _sayWord, child: Img('pic_${w.pic}', width: 96)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(n, (i) {
                  final hole = i == w.hole;
                  final show = !hole || solved;
                  return Container(
                    width: tileW,
                    height: 78,
                    margin: EdgeInsets.only(right: i == n - 1 ? 0 : 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: hole
                          ? (solved ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8FEA5C), Color(0xFF22A02A)]) : null)
                          : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE4FAFA), Color(0xFFC4F0F0)]),
                      color: hole && !solved ? const Color(0xB3FFFFFF) : null,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: hole && !solved ? const Color(0xFF0B9DAA) : Colors.white, width: hole && !solved ? 4 : 3),
                      boxShadow: hole && !solved ? null : const [BoxShadow(color: Color(0xFF9EDADF), offset: Offset(0, 4))],
                    ),
                    child: show
                        ? FittedBox(child: Text(chars[i], style: baloo(fs, color: hole ? Colors.white : const Color(0xFF0B6E78))))
                        : null,
                  );
                }),
              ),
              const SizedBox(height: 12),
              Pressable(
                label: 'Escuchar la palabra',
                onTap: _sayWord,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE4EEFF)]),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [BoxShadow(color: Color(0xFFA9BEDF), offset: Offset(0, 4))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.volume_up_rounded, color: Color(0xFF1463D8), size: 22),
                    const SizedBox(width: 8),
                    Text('Escuchar la palabra', style: nunito(16, color: const Color(0xFF1463D8), weight: FontWeight.w900)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          WoodSign.text('¿Qué letra falta?', size: 24),
          const SizedBox(height: 14),
          Row(
            children: List.generate(opts.length, (k) {
              final l = opts[k];
              final ok = solved && l == miss;
              final bad = wrong.contains(l);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: k == 0 ? 0 : 7, right: k == opts.length - 1 ? 0 : 7),
                  child: Pressable(
                    label: 'Letra $l',
                    onTap: () => _pick(l),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: ok ? 1.06 : (bad ? 0.94 : 1),
                      child: Glossy(
                        g: ok ? Pal.green : (bad ? Pal.grey : cols[k]),
                        radius: 28,
                        height: 94,
                        width: double.infinity,
                        child: bad ? Text(l, style: baloo(58, color: const Color(0xFF9A8F7E))) : LabelText(l, size: 58),
                      ),
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
