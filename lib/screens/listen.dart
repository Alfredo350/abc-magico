import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

/// Escucha y elige: suena una letra y el niño toca la correcta.
class ListenGame extends StatefulWidget {
  const ListenGame({super.key});

  @override
  State<ListenGame> createState() => _ListenGameState();
}

class _ListenGameState extends State<ListenGame> with Later {
  static const int rounds = 5;
  final math.Random _r = math.Random();
  int round = 0;
  bool done = false;
  String target = 'A';
  List<String> opts = [];
  List<String> wrong = [];
  bool solved = false;
  String msg = '';
  int earned = 0;

  @override
  void initState() {
    super.initState();
    _newRound();
    later(600, _play);
  }

  final LevelDef lv = app.lvl;
  late final List<String> _targets = _makeTargets();

  /// Las letras del nivel, repartidas en las 5 rondas.
  List<String> _makeTargets() {
    final out = <String>[];
    while (out.length < rounds) {
      out.addAll(List<String>.from(lv.letters)..shuffle(_r));
    }
    return out.take(rounds).toList();
  }

  void _newRound() {
    target = _targets[round.clamp(0, rounds - 1)];
    final others = kLetters.where((x) => x != target).toList()..shuffle(_r);
    opts = [target, ...others.take(3)]..shuffle(_r);
    wrong = [];
    solved = false;
    msg = 'Toca el botón azul y escucha. ¿Qué letra es?';
  }

  void _play() {
    Voice.I.sfx('tap');
    Voice.I.talk(['@I_escuchaste', Voice.lc(target)]);
  }

  void _pick(String l) {
    if (solved || done) return;
    if (l == target) {
      Voice.I.sfx('ok');
      Voice.I.talk([...Voice.I.praise(), Voice.lc(l)]);
      final firstTry = wrong.isEmpty;
      earned += firstTry ? 3 : 1;
      app.rateLetter(l, firstTry ? 2 : 1);
      setState(() {
        solved = true;
        msg = '¡Muy bien! Es la ${showLetter(l, lv.lower)}.';
      });
      later(1800, () {
        final r = round + 1;
        if (r >= rounds) {
          _finish(r);
          return;
        }
        setState(() {
          round = r;
          _newRound();
        });
        later(400, _play);
      });
    } else {
      Voice.I.sfx('bad');
      app.mistake(target);
      Voice.I.talk(['@A_casi', '@A_escucha', Voice.lc(target)]);
      setState(() {
        wrong.add(l);
        msg = 'Casi… esa es la ${showLetter(l, lv.lower)}. ¡Escucha otra vez!';
      });
    }
  }

  void _finish(int r) {
    app.finishGame('escucha', earned);
    Voice.I.sfx('win');
    setState(() {
      round = r;
      done = true;
    });
    later(900, () => Voice.I.talk(Voice.I.bravo()));
  }

  void _restart() {
    _targets
      ..clear()
      ..addAll(_makeTargets());
    setState(() {
      round = 0;
      earned = 0;
      done = false;
      _newRound();
    });
    later(400, _play);
  }

  @override
  Widget build(BuildContext context) {
    const cols = [Pal.blue, Pal.pink, Pal.green, Pal.purple];
    Widget option(int k) {
      final l = opts[k];
      final ok = solved && l == target;
      final bad = wrong.contains(l);
      return Expanded(
        child: Pressable(
          label: 'Letra $l',
          onTap: () => _pick(l),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: ok ? 1.05 : (bad ? 0.94 : 1),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: ok
                    ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8FBE0), Color(0xFFC8F2B4)])
                    : (bad ? null : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF0F5FF)])),
                color: bad ? const Color(0xFFF1ECE4) : null,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: ok ? const Color(0xFF3FC13A) : Colors.white, width: ok ? 5 : 4),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFB9C8E2), offset: Offset(0, 6)),
                  BoxShadow(color: Color(0x29142850), blurRadius: 18, offset: Offset(0, 12)),
                ],
              ),
              alignment: Alignment.center,
              child: GlossyLetter(showLetter(l, lv.lower), g: ok ? Pal.green : cols[k], size: 92),
            ),
          ),
        ),
      );
    }

    return GameScaffold(
      title: 'Escucha · Nivel ${lv.n}',
      onRepeat: _play,
      overlay: done ? DoneOverlay(title: '¡Buen oído!', onRestart: _restart) : null,
      child: Column(
        children: [
          ProgressPill(done: round, total: rounds, g: Pal.blue),
          const SizedBox(height: 16),
          Pressable(
            label: 'Escuchar la letra',
            onTap: _play,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 8),
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6EC3FF), Color(0xFF2386F5), Color(0xFF1463D8)]),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF0D4AA6), offset: Offset(0, 8)),
                  BoxShadow(color: Color(0x73FFFFFF), spreadRadius: 12),
                ],
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 76),
            ),
          ),
          const SizedBox(height: 18),
          WoodSign.text('¿Qué letra escuchaste?', size: 23),
          const SizedBox(height: 16),
          if (opts.length == 4) ...[
            Row(children: [option(0), const SizedBox(width: 14), option(1)]),
            const SizedBox(height: 14),
            Row(children: [option(2), const SizedBox(width: 14), option(3)]),
          ],
          const Spacer(),
          LumiSays(text: msg, onTap: _play),
        ],
      ),
    );
  }
}
