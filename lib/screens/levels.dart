import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

/// Mapa de los 15 niveles.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> with Later {
  @override
  void initState() {
    super.initState();
    later(400, _repeat);
  }

  void _repeat() => Voice.I.say('Elige un nivel. Para abrir el siguiente, juega tres juegos distintos.');

  void _pick(LevelDef lv) {
    final open = lv.n <= app.maxUnlocked;
    if (!open) {
      Voice.I.sfx('bad');
      Voice.I.say('Ese nivel todavía está cerrado. Juega tres juegos en el nivel ${app.maxUnlocked}.');
      return;
    }
    Voice.I.sfx('ok');
    app.setLevel(lv.n);
    final names = lv.letters.length <= 5 ? lv.letters.map((l) => kLetterNames[l]).join(', ') : lv.name;
    Voice.I.say('Nivel ${lv.n}: $names.');
    later(1200, () => Navigator.of(context).maybePop());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final maxOpen = app.maxUnlocked;
    return GameScaffold(
      title: 'Niveles',
      onRepeat: _repeat,
      child: Column(children: [
        WhiteCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            const StarIcon(size: 30),
            const SizedBox(width: 8),
            Expanded(child: Text('Abiertos: $maxOpen de ${kLevels.length}', style: nunito(17, color: Pal.ink, weight: FontWeight.w900))),
            Text('Nivel ${app.currentLevel}', style: baloo(20, color: const Color(0xFFF26A00))),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: kLevels.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.92),
            itemBuilder: (context, i) {
              final lv = kLevels[i];
              final open = lv.n <= maxOpen;
              final cur = lv.n == app.currentLevel;
              final st = app.levelStars(lv.n);
              final g = !open ? Pal.grey : (st >= 3 ? Pal.green : Pal.cycle[i % Pal.cycle.length]);
              return Pressable(
                label: 'Nivel ${lv.n}',
                onTap: () => _pick(lv),
                child: Container(
                  decoration: cur
                      ? BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0xFFFFD21F), spreadRadius: 5)])
                      : null,
                  child: Glossy(
                    g: g,
                    radius: 24,
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      open ? LabelText('${lv.n}', size: 34) : const Icon(Icons.lock_rounded, color: Color(0xFF9A8F7E), size: 30),
                      const SizedBox(height: 2),
                      FittedBox(
                        child: open
                            ? LabelText(lv.name, size: 15)
                            : Text(lv.name, style: nunito(14, color: const Color(0xFF8A8F9C), weight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (k) => StarIcon(size: 15, on: k < st))),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
