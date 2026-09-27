import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

/// Mi progreso: nivel, estrellas, letras aprendidas y medallas.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with Later {

  @override
  void initState() {
    super.initState();
    later(400, _repeat);
  }

  void _repeat() {
    final who = app.hasName ? '${app.name}, ya' : 'Ya';
    Voice.I.say('$who aprendiste ${app.lettersLearned} letras y tienes ${app.stars} estrellas. ¡Sigue así!');
  }

  Widget _stat(String value, String label, Widget icon) {
    return Expanded(
      child: WhiteCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(child: Text(value, style: baloo(26, color: Pal.ink, height: 1))),
              Text(label, style: nunito(13, color: Pal.muted), maxLines: 2),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = app.currentLevel;
    final maxOpen = app.maxUnlocked;
    return GameScaffold(
      title: 'Mi progreso',
      onRepeat: _repeat,
      child: SingleChildScrollView(
        child: Column(children: [
          WhiteCard(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('Nivel $level · ${levelDef(level).name}', style: baloo(21, color: Pal.ink))),
                Text('$maxOpen/${kLevels.length}', style: nunito(16, color: const Color(0xFFF26A00), weight: FontWeight.w900)),
              ]),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.25,
                children: List.generate(kLevels.length, (i) {
                  final n = i + 1;
                  final open = n <= maxOpen;
                  final st = app.levelStars(n);
                  final g = !open ? Pal.grey : (st >= 3 ? Pal.green : (n == level ? Pal.orange : Pal.blue));
                  return Glossy(
                    g: g,
                    radius: 14,
                    child: open
                        ? (st >= 3 ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : LabelText('$n', size: 18))
                        : const Icon(Icons.lock_rounded, color: Color(0xFF9A8F7E), size: 16),
                  );
                }),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            _stat('${app.lettersLearned}/27', 'Letras aprendidas', const GlossyLetter('A', g: Pal.green, size: 32)),
            const SizedBox(width: 10),
            _stat('${app.stars}', 'Estrellas', const StarIcon(size: 32)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _stat('${app.activities}', 'Juegos completados', const Icon(Icons.sports_esports_rounded, color: Color(0xFF2386F5), size: 32)),
            const SizedBox(width: 10),
            _stat('${app.streak} ${app.streak == 1 ? 'día' : 'días'}', 'Racha', const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF26A00), size: 32)),
          ]),
          const SizedBox(height: 10),
          WhiteCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mis letras', style: nunito(17, color: Pal.ink, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 9,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 1.05,
                children: List.generate(kLetters.length, (i) {
                  final l = kLetters[i];
                  final on = (app.letterStars[l] ?? 0) > 0;
                  return on
                      ? Glossy(g: Pal.cycle[i % Pal.cycle.length], radius: 9, child: LabelText(l, size: 15))
                      : Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: const Color(0xFFEEE8DE), borderRadius: BorderRadius.circular(9)),
                          child: Text(l, style: nunito(15, color: const Color(0xFF9AA0AC), weight: FontWeight.w900)),
                        );
                }),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          WhiteCard(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mis medallas', style: nunito(17, color: Pal.ink, weight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(kMedals.length, (i) {
                  final m = kMedals[i];
                  final got = app.medals.contains(m.id);
                  const gs = [Pal.yellow, Pal.blue, Pal.pink, Pal.purple, Pal.teal];
                  return SizedBox(
                    width: 60,
                    child: Column(children: [
                      Glossy(
                        g: got ? gs[i] : Pal.grey,
                        radius: 29,
                        width: 58,
                        height: 58,
                        child: got ? const StarIcon(size: 30) : const Icon(Icons.lock_rounded, color: Color(0xFF9A8F7E), size: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(m.title, textAlign: TextAlign.center, style: nunito(10.5, color: got ? Pal.ink : const Color(0xFF8A8F9C), weight: FontWeight.w900)),
                    ]),
                  );
                }),
              ),
            ]),
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }
}
