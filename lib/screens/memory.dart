import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

class _Card {
  final int key;
  final bool isLetter;
  final String letter;
  final String pic;
  final String word;
  const _Card(this.key, this.isLetter, this.letter, this.pic, this.word);
}

/// Memoria ABC: encontrar parejas de letra + dibujo.
class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> with Later {
  static const cols = [Pal.red, Pal.orange, Pal.green, Pal.blue, Pal.purple, Pal.pink];

  final math.Random _r = math.Random();
  final LevelDef lv = app.lvl;
  List<List<String>> pairs = [];
  List<_Card> deck = [];
  final List<int> open = [];
  final Set<int> matched = {};
  int tries = 0;
  bool lock = false;
  bool done = false;
  String msg = 'Da vuelta dos cartas: busca cada letra con su dibujo.';

  @override
  void initState() {
    super.initState();
    _fresh();
    later(500, _repeat);
  }

  void _fresh() {
    final mine = kWords.where((w) => lv.letters.contains(w.letter)).toList()..shuffle(_r);
    final rest = kWords.where((w) => !lv.letters.contains(w.letter)).toList()..shuffle(_r);
    pairs = [...mine.take(6), ...rest].take(6).map((w) => [w.letter, w.pic, w.word]).toList();
    final d = <_Card>[];
    for (var i = 0; i < pairs.length; i++) {
      final p = pairs[i];
      d.add(_Card(i, true, p[0], p[1], p[2]));
      d.add(_Card(i, false, p[0], p[1], p[2]));
    }
    d.shuffle(_r);
    deck = d;
    open.clear();
    matched.clear();
    tries = 0;
    lock = false;
    done = false;
  }

  void _repeat() => Voice.I.talk(['@I_parejas']);

  void _flip(int k) {
    final c = deck[k];
    if (lock || done || open.contains(k) || matched.contains(c.key)) return;
    Voice.I.sfx('flip');
    Voice.I.talk([c.isLetter ? Voice.lc(c.letter) : Voice.wc(c.word)]);
    setState(() => open.add(k));
    if (open.length < 2) return;
    final a = deck[open[0]];
    final b = deck[open[1]];
    tries++;
    lock = true;
    if (a.key == b.key) {
      setState(() => msg = '¡Pareja! ${a.letter} de ${a.word.toLowerCase()}.');
      later(600, () {
        Voice.I.sfx('ok');
        Voice.I.talk([...Voice.I.praise(), Voice.lc(a.letter), Voice.wc(a.word)]);
      });
      later(1200, () {
        app.rateLetter(a.letter, 1);
        setState(() {
          matched.add(a.key);
          open.clear();
          lock = false;
        });
        if (matched.length == pairs.length) {
          final earned = tries <= 9 ? 15 : 10;
          app.finishGame('memoria', earned);
          Voice.I.sfx('win');
          setState(() => done = true);
          later(900, () => Voice.I.talk(Voice.I.bravo()));
        }
      });
    } else {
      setState(() => msg = 'No son pareja. ¡Recuerda dónde están!');
      later(1300, () {
        Voice.I.sfx('bad');
        setState(() {
          open.clear();
          lock = false;
        });
      });
    }
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: WhiteCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: nunito(13, color: Pal.muted, weight: FontWeight.w900)),
          Text(value, style: baloo(30, color: Pal.ink, height: 1)),
        ]),
      ),
    );
  }

  Widget _cardView(int k) {
    final c = deck[k];
    final isMatched = matched.contains(c.key);
    final face = isMatched || open.contains(k);
    return Pressable(
      label: 'Carta',
      onTap: () => _flip(k),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: face
            ? Container(
                key: ValueKey('f$k'),
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isMatched ? const Color(0xFF3FC13A) : const Color(0xFFFFD21F), width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x26142850), offset: Offset(0, 5))],
                ),
                alignment: Alignment.center,
                child: c.isLetter ? GlossyLetter(showLetter(c.letter, lv.lower), g: cols[c.key], size: 58) : Img('pic_${c.pic}', width: 66),
              )
            : Glossy(
                key: ValueKey('b$k'),
                g: Pal.purple,
                radius: 18,
                height: 110,
                width: double.infinity,
                child: Container(
                  width: 56,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x99FFFFFF), width: 3),
                  ),
                  alignment: Alignment.center,
                  child: const StarIcon(size: 32),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Memoria · Nivel ${lv.n}',
      onRepeat: _repeat,
      overlay: done
          ? DoneOverlay(
              title: '¡Qué memoria!',
              onRestart: () {
                setState(_fresh);
                later(300, _repeat);
              },
            )
          : null,
      child: Column(
        children: [
          Row(children: [_stat('Parejas', '${matched.length} / ${pairs.length}'), const SizedBox(width: 10), _stat('Intentos', '$tries')]),
          const SizedBox(height: 14),
          for (var row = 0; row < 3; row++) ...[
            Row(children: [
              for (var col = 0; col < 4; col++) ...[
                Expanded(child: _cardView(row * 4 + col)),
                if (col < 3) const SizedBox(width: 10),
              ],
            ]),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          LumiSays(text: msg, onTap: _repeat),
        ],
      ),
    );
  }
}
