import 'package:flutter/material.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';
import 'complete.dart';
import 'detective.dart';
import 'find.dart';
import 'levels.dart';
import 'letters.dart';
import 'listen.dart';
import 'match.dart';
import 'memory.dart';
import 'order.dart';
import 'progress.dart';
import 'trace.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with Later {
  @override
  void initState() {
    super.initState();
    later(500, _hello);
  }

  void _hello() {
    final who = app.hasName ? ', ${app.name}' : '';
    Voice.I.say('¡Hola$who! Estás en el nivel ${app.currentLevel}. ¿Qué quieres jugar hoy?');
  }

  Future<void> _open(Widget screen) async {
    Voice.I.sfx('tap');
    await go(context, screen);
    if (mounted) setState(() {});
  }

  Widget _tile(String label, Gl g, Widget art, VoidCallback onTap, {bool locked = false, bool darkText = false}) {
    return Pressable(
      label: label,
      onTap: onTap,
      child: Glossy(
        g: g,
        radius: 28,
        height: 118,
        alignment: Alignment.bottomLeft,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 52, child: Align(alignment: Alignment.bottomLeft, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.bottomLeft, child: art))),
                const SizedBox(height: 3),
                darkText
                    ? Text(label, style: baloo(17, color: Pal.ink, height: 1.0))
                    : LabelText(label, size: 17),
              ],
            ),
            if (locked)
              Positioned(
                right: -4,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Pal.ink, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.lock_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 3),
                    Text('3 juegos', style: nunito(12, color: Colors.white, weight: FontWeight.w900)),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallPill(String t, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Pressable(
        label: t,
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFEEF3FF)]),
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Color(0xFFB9C8E2), offset: Offset(0, 5))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: const Color(0xFF1463D8), size: 24),
            const SizedBox(width: 8),
            Text(t, style: baloo(19, color: Pal.ink)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = app.hasName ? '${app.name}!' : '${app.explorer}!';
    final memLocked = !app.memoryUnlocked;
    return SceneScreen(
      child: Stack(
        children: [
          const Positioned(left: 2, bottom: 0, child: Img('blocks', width: 130, height: 104)),
          const Positioned(right: 2, bottom: 4, child: Img('books', width: 112, height: 86)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Owl(size: 76),
                    Expanded(
                      child: Center(
                        child: WoodSign(
                          ropes: true,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            const RainbowText('¡Hola,', size: 26),
                            FittedBox(child: RainbowText(name, size: name.length > 11 ? 22 : 26)),
                          ]),
                        ),
                      ),
                    ),
                    const Img('sun', width: 76),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Pill(children: [const StarIcon(size: 22), const SizedBox(width: 5), Text('${app.stars}', style: nunito(18, color: Pal.ink, weight: FontWeight.w900))]),
                        const SizedBox(width: 10),
                        Pressable(
                          label: 'Elegir nivel',
                          onTap: () => _open(const LevelsScreen()),
                          child: Pill(children: [
                            const Icon(Icons.map_rounded, color: Color(0xFFF26A00), size: 22),
                            const SizedBox(width: 4),
                            Text('Nivel ${app.currentLevel}', style: nunito(18, color: Pal.ink, weight: FontWeight.w900)),
                            const Icon(Icons.chevron_right_rounded, color: Pal.ink, size: 20),
                          ]),
                        ),
                      ]),
                    ),
                    RoundBtn(icon: Icons.volume_up_rounded, label: 'Escuchar saludo', size: 50, onTap: _hello),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 13,
                    crossAxisSpacing: 12,
                    childAspectRatio: 171 / 118,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      _tile('Aprende las letras', Pal.orange, const _ArtLetters(), () => _open(const LettersScreen())),
                      _tile('Escucha y repite', Pal.blue, const _ArtListen(), () => _open(const ListenGame())),
                      _tile('Une letra e imagen', Pal.green, const _ArtMatch(), () => _open(const MatchGame())),
                      _tile('Encuentra la letra', Pal.pink, const _ArtFind(), () => _open(const FindGame())),
                      _tile('Traza la letra', Pal.purple, const _ArtTrace(), () => _open(const TraceGame())),
                      _tile('Completa la palabra', Pal.teal, const _ArtComplete(), () => _open(const CompleteGame())),
                      _tile('Memoria ABC', Pal.yellow, const _ArtMemory(), () {
                        if (memLocked) {
                          Voice.I.sfx('bad');
                          Voice.I.say('Juega tres juegos para abrir la memoria.');
                          return;
                        }
                        _open(const MemoryGame());
                      }, locked: memLocked, darkText: true),
                      _tile('Mi progreso', Pal.navy, const _ArtProgress(), () => _open(const ProgressScreen())),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  _smallPill('Ordena', Icons.format_list_numbered_rounded, () => _open(const OrderGame())),
                  const SizedBox(width: 10),
                  _smallPill('Detective ABC', Icons.search_rounded, () => _open(const DetectiveGame())),
                ]),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- ilustraciones de las tarjetas ----------

class _ArtLetters extends StatelessWidget {
  const _ArtLetters();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        GlossyLetter('A', g: Pal.red, size: 50),
        GlossyLetter('a', g: Pal.blue, size: 50),
        Kid('boy', size: 54),
      ]);
}

class _ArtListen extends StatelessWidget {
  const _ArtListen();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Icon(Icons.volume_up_rounded, color: Colors.white, size: 56),
        Icon(Icons.music_note_rounded, color: Color(0xFFFFD21F), size: 26),
        Kid('girl_bow', size: 54, joy: true),
      ]);
}

class _ArtMatch extends StatelessWidget {
  const _ArtMatch();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        GlossyLetter('C', g: Pal.red, size: 54),
        SizedBox(width: 4),
        Img('pic_gato', width: 58),
      ]);
}

class _ArtFind extends StatelessWidget {
  const _ArtFind();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        StarIcon(size: 24),
        Icon(Icons.search_rounded, color: Color(0xFFFFD21F), size: 56),
        Kid('boy_cap', size: 54, joy: true),
      ]);
}

class _ArtTrace extends StatelessWidget {
  const _ArtTrace();
  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Icon(Icons.edit_rounded, color: Color(0xFFFFD21F), size: 54),
        SizedBox(width: 6),
        StrokeText('A', size: 52, fill: Color(0x00FFFFFF), stroke: Colors.white, strokeWidth: 3),
      ]);
}

class _ArtComplete extends StatelessWidget {
  const _ArtComplete();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        _blank(),
        const GlossyLetter('A', g: Pal.yellow, size: 50),
        _blank(),
        const SizedBox(width: 4),
        const Kid('girl_tails', size: 54, joy: true),
      ]);
  Widget _blank() => Container(width: 18, height: 6, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3)));
}

class _ArtMemory extends StatelessWidget {
  const _ArtMemory();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        _card('pic_manzana', -0.14),
        const SizedBox(width: 6),
        _card('pic_pelota', 0.1),
      ]);
  Widget _card(String p, double a) => Transform.rotate(
        angle: a,
        child: Container(
          width: 48,
          height: 54,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x2E000000), offset: Offset(0, 4))]),
          child: Center(child: Img(p, width: 38)),
        ),
      );
}

class _ArtProgress extends StatelessWidget {
  const _ArtProgress();
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        const StarIcon(size: 50),
        const SizedBox(width: 6),
        _bar(20, const Color(0xFFFF8A00)),
        _bar(30, const Color(0xFFFFD21F)),
        _bar(42, const Color(0xFF3FC13A)),
        _bar(54, const Color(0xFF2386F5)),
      ]);
  Widget _bar(double h, Color c) => Container(width: 11, height: h, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)));
}
