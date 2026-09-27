import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

/// Ordena: subir las letras al tren en orden alfabético.
class OrderGame extends StatefulWidget {
  const OrderGame({super.key});

  @override
  State<OrderGame> createState() => _OrderGameState();
}

class _OrderGameState extends State<OrderGame> with Later {
  static const int rounds = 3;
  static const wagonCols = [Pal.orange, Pal.blue, Pal.green, Pal.pink, Pal.purple];
  static const looseCols = [Pal.pink, Pal.green, Pal.purple, Pal.teal];

  final math.Random _r = math.Random();
  final LevelDef lv = app.lvl;
  late final List<List<String>> seqs = _makeSeqs();
  int round = 0;
  bool done = false;
  List<String> seq = [];
  int filled = 1;
  List<String> loose = [];
  String wrong = '';
  bool leaving = false;
  int earned = 0;
  int misses = 0;
  String msg = '';

  @override
  void initState() {
    super.initState();
    _makeRound(0);
    later(500, _repeat);
  }

  /// Trenes de 5 letras seguidas que incluyen letras del nivel.
  List<List<String>> _makeSeqs() {
    final idx = lv.letters.map((l) => kLetters.indexOf(l)).toList()..sort();
    final lo = math.max(0, idx.first - 2);
    final hi = math.min(kLetters.length - 5, idx.last - 2);
    final out = <List<String>>[];
    for (var i = 0; i < rounds; i++) {
      final span = math.max(0, hi - lo);
      final start = (lo + (span == 0 ? 0 : _r.nextInt(span + 1))).clamp(0, kLetters.length - 5);
      out.add(kLetters.sublist(start, start + 5));
    }
    return out;
  }

  void _makeRound(int r) {
    seq = List<String>.from(seqs[r]);
    filled = 1;
    loose = seq.sublist(1)..shuffle(_r);
    wrong = '';
    leaving = false;
    misses = 0;
    msg = 'La ${seq[0]} ya subió. ¿Qué letra sigue?';
  }

  void _repeat() => Voice.I.talk(['@I_orden', Voice.lc(seq[math.max(0, filled - 1)])]);

  void _tap(String l) {
    if (done || filled >= seq.length || seq.sublist(0, filled).contains(l)) return;
    if (l == seq[filled]) {
      Voice.I.sfx('ok');
      Voice.I.talk([Voice.lc(l)]);
      app.rateLetter(l, 1);
      setState(() {
        filled++;
        msg = filled < seq.length ? '¡Bien! ${seq.sublist(0, filled).join(', ')}… ¿y ahora?' : '¡El tren está listo! ¡Chu chu!';
      });
      if (filled == seq.length) {
        earned += misses == 0 ? 3 : 2;
        later(500, () {
          Voice.I.sfx('win');
          Voice.I.talk(seq.map(Voice.lc).toList());
          setState(() => leaving = true);
        });
        later(3200, () {
          final r = round + 1;
          if (r >= seqs.length) {
            app.finishGame('ordena', earned);
            setState(() {
              round = r;
              done = true;
            });
            later(600, () => Voice.I.talk(Voice.I.bravo()));
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
      app.mistake(seq[filled]);
      Voice.I.sfx('bad');
      Voice.I.talk(['@A_casi', '@A_intenta']);
      setState(() {
        wrong = l;
        msg = 'Después de la ${seq[filled - 1]} viene otra letra. ¡Prueba!';
      });
      later(500, () => setState(() => wrong = ''));
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

  Widget _wheels() => Row(mainAxisSize: MainAxisSize.min, children: [_wheel(), const SizedBox(width: 12), _wheel()]);
  Widget _wheel() => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF33415C), border: Border.all(color: Colors.white, width: 3)),
      );

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Ordena · Nivel ${lv.n}',
      onRepeat: _repeat,
      overlay: done ? DoneOverlay(title: '¡Tren completo!', onRestart: _restart) : null,
      child: Column(
        children: [
          ProgressPill(done: round, total: seqs.length, g: Pal.orange),
          const SizedBox(height: 14),
          WoodSign.text('Ayuda al tren: pon las letras en orden', size: 20),
          const SizedBox(height: 14),
          WhiteCard(
            padding: const EdgeInsets.fromLTRB(8, 22, 8, 16),
            child: ClipRect(
              child: Column(children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeIn,
                  offset: leaving ? const Offset(1.3, 0) : Offset.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(children: [
                        Glossy(
                          g: Pal.red,
                          radius: 14,
                          width: 52,
                          height: 84,
                          alignment: Alignment.topCenter,
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            width: 26,
                            height: 22,
                            decoration: BoxDecoration(color: const Color(0xFFBDE7FF), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white, width: 2)),
                          ),
                        ),
                        Transform.translate(offset: const Offset(0, -8), child: _wheels()),
                      ]),
                      const SizedBox(width: 3),
                      for (var i = 0; i < seq.length; i++) ...[
                        Column(children: [
                          i < filled
                              ? Glossy(g: wagonCols[i], radius: 12, width: 50, height: 60, child: LabelText(showLetter(seq[i], lv.lower), size: 34))
                              : Container(
                                  width: 50,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xB3FFFFFF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF8C96A8), width: 3),
                                  ),
                                ),
                          Transform.translate(offset: const Offset(0, -8), child: _wheels()),
                        ]),
                        if (i < seq.length - 1) const SizedBox(width: 3),
                      ],
                    ],
                  ),
                ),
                Container(
                  height: 8,
                  margin: const EdgeInsets.only(top: 0),
                  decoration: BoxDecoration(color: const Color(0xFF8D5A34), borderRadius: BorderRadius.circular(4)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 14,
            children: List.generate(loose.length, (k) {
              final l = loose[k];
              final used = seq.sublist(0, filled).contains(l);
              return Pressable(
                label: 'Letra $l',
                onTap: () => _tap(l),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: used ? 0.2 : 1,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 120),
                    turns: wrong == l ? 0.02 : 0,
                    child: Glossy(g: looseCols[k % looseCols.length], radius: 24, width: 76, height: 76, child: LabelText(showLetter(l, lv.lower), size: 46)),
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
