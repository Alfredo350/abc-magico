import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';
import 'find.dart';

/// Cuadrícula con las 27 letras.
class LettersScreen extends StatefulWidget {
  const LettersScreen({super.key});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

class _LettersScreenState extends State<LettersScreen> with Later {
  @override
  void initState() {
    super.initState();
    later(400, _repeat);
  }

  void _repeat() => Voice.I.say('Toca una letra para aprenderla. Las letras con candado se abren cuando juegas.');

  @override
  Widget build(BuildContext context) {
    final open = app.unlockedLetters;
    final learned = app.lettersLearned;
    return GameScaffold(
      title: 'Aprende las letras',
      onRepeat: _repeat,
      child: Column(
        children: [
          WhiteCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Glossy(g: Pal.orange, radius: 24, width: 48, height: 48, child: LabelText('${app.currentLevel}', size: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nivel ${app.currentLevel} · ${app.lvl.name}', style: nunito(17, color: Pal.ink, weight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: LinearProgressIndicator(
                      value: learned / 27,
                      minHeight: 14,
                      backgroundColor: const Color(0xFFE6EDF5),
                      color: const Color(0xFFFF8A00),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 10),
              Text('$learned/27', style: nunito(16, color: Pal.ink, weight: FontWeight.w900)),
            ]),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              itemCount: kLetters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 9, childAspectRatio: 0.78),
              itemBuilder: (context, i) {
                final l = kLetters[i];
                final unlocked = i < open;
                final st = app.letterStars[l] ?? 0;
                return Column(children: [
                  Pressable(
                    label: 'Letra $l',
                    onTap: () async {
                      if (!unlocked) {
                        Voice.I.sfx('bad');
                        Voice.I.say('Esta letra se abre cuando sigas jugando.');
                        return;
                      }
                      Voice.I.sfx('tap');
                      await go(context, LetterScreen(index: i));
                      if (mounted) setState(() {});
                    },
                    child: Glossy(
                      g: unlocked ? Pal.cycle[i % Pal.cycle.length] : Pal.grey,
                      radius: 18,
                      height: 58,
                      width: double.infinity,
                      child: unlocked
                          ? LabelText(l, size: 34)
                          : const Icon(Icons.lock_rounded, color: Color(0xFF9A8F7E), size: 22),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xD9FFFFFF), borderRadius: BorderRadius.circular(10)),
                    child: unlocked
                        ? Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (k) => StarIcon(size: 12, on: k < st)))
                        : Text(l, style: nunito(12, color: Pal.ink, weight: FontWeight.w900)),
                  ),
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Ficha de una letra: mayúscula, minúscula, palabra y dibujo.
class LetterScreen extends StatefulWidget {
  final int index;
  const LetterScreen({super.key, required this.index});

  @override
  State<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends State<LetterScreen> with Later {
  late int i;
  int mode = 0; // 0 ambas, 1 mayúscula, 2 minúscula

  @override
  void initState() {
    super.initState();
    i = widget.index;
    later(400, _sayAll);
  }

  LetterWord get w => kWords[i];
  String get l => w.letter;

  bool get _isMine => app.hasName && initialOf(app.name) == l;

  void _sayAll() {
    if (_isMine) {
      Voice.I.say('La primera letra de tu nombre, ${app.name}, es la ${kLetterNames[l]}. Como en ${w.word.toLowerCase()}.');
    } else {
      Voice.I.talk([Voice.lc(l), Voice.wc(w.word)]);
    }
  }

  void _sayLetter() {
    Voice.I.sfx('tap');
    app.rateLetter(l, 1);
    Voice.I.talk([Voice.lc(l)]);
  }

  void _sayWord() {
    Voice.I.sfx('tap');
    Voice.I.talk([Voice.wc(w.word)]);
  }

  void _go(int d) {
    final n = i + d;
    if (n < 0 || n >= kWords.length || n >= app.unlockedLetters) {
      Voice.I.sfx('bad');
      if (n >= app.unlockedLetters && n < kWords.length) Voice.I.say('Esa letra se abre cuando sigas jugando.');
      return;
    }
    Voice.I.sfx('flip');
    setState(() => i = n);
    later(150, _sayAll);
  }

  @override
  Widget build(BuildContext context) {
    final g = Pal.cycle[i % Pal.cycle.length];
    final word = w.word;
    final msg = _isMine
        ? '¡La $l es la primera letra de tu nombre, ${app.name}! Como en ${word.toLowerCase()}.'
        : 'La $l suena así, como en ${word.toLowerCase()}. ¡Tócala!';
    return GameScaffold(
      title: 'Letra $l',
      onRepeat: _sayAll,
      child: Column(
        children: [
          WhiteCard(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(children: [
              Pressable(
                label: 'Escuchar la letra',
                onTap: _sayLetter,
                child: SizedBox(
                  height: 160,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (mode != 2) GlossyLetter(l, g: g, size: 140),
                      if (mode == 0) const SizedBox(width: 8),
                      if (mode != 1) GlossyLetter(l.toLowerCase(), g: Pal.blue, size: 116),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Pressable(
                  label: 'Escuchar',
                  onTap: _sayLetter,
                  child: Glossy(
                    g: Pal.blue,
                    radius: 26,
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      LabelText('Escuchar', size: 20),
                    ]),
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  label: 'Cambiar mayúscula y minúscula',
                  onTap: () {
                    Voice.I.sfx('flip');
                    setState(() => mode = (mode + 1) % 3);
                    Voice.I.say(mode == 1 ? 'Mayúscula' : (mode == 2 ? 'Minúscula' : 'Mayúscula y minúscula'));
                  },
                  child: Container(
                    height: 52,
                    constraints: const BoxConstraints(minWidth: 100),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE3E9F3), width: 3),
                      boxShadow: const [BoxShadow(color: Color(0xFFD3DCEA), offset: Offset(0, 4))],
                    ),
                    child: Text(
                      mode == 0 ? '$l / ${l.toLowerCase()}' : (mode == 1 ? 'Mayúscula' : 'Minúscula'),
                      style: baloo(20, color: Pal.ink),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          WhiteCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Pressable(
                label: 'Escuchar la palabra',
                onTap: _sayWord,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE4F8DA), Color(0xFFC8EFB4)]),
                  ),
                  alignment: Alignment.center,
                  child: WordPic(pic: w.pic, letter: l, size: 88),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(TextSpan(style: baloo(40, color: Pal.ink), children: [
                      TextSpan(text: word.substring(0, 1), style: const TextStyle(color: Color(0xFFE53935))),
                      TextSpan(text: word.substring(1)),
                    ])),
                  ),
                  const SizedBox(height: 4),
                  Text('Letra ${i + 1} de ${kWords.length}', style: nunito(14, color: Pal.muted)),
                ]),
              ),
              RoundBtn(icon: Icons.volume_up_rounded, label: 'Escuchar la palabra', size: 48, onTap: _sayWord),
            ]),
          ),
          const Spacer(),
          LumiSays(text: msg, onTap: _sayAll, size: 72),
          Row(children: [
            RoundBtn(icon: Icons.arrow_back_ios_new_rounded, label: 'Letra anterior', size: 56, opacity: i == 0 ? 0.45 : 1, onTap: () => _go(-1)),
            const SizedBox(width: 10),
            Expanded(
              child: BigButton(
                text: '¡A jugar!',
                g: Pal.orange,
                onTap: () {
                  Voice.I.sfx('tap');
                  go(context, FindGame(firstTarget: l));
                },
              ),
            ),
            const SizedBox(width: 10),
            RoundBtn(icon: Icons.arrow_forward_ios_rounded, label: 'Letra siguiente', size: 56, opacity: i + 1 >= app.unlockedLetters ? 0.45 : 1, onTap: () => _go(1)),
          ]),
        ],
      ),
    );
  }
}
