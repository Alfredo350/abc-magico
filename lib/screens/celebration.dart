import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';
import 'progress.dart';

/// Pantalla de premio al terminar un juego.
class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key});

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen> with Later, SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  bool _up = false;
  late final List<_Confetti> _confetti;

  @override
  void initState() {
    super.initState();
    final r = math.Random(7);
    const colors = [Color(0xFFFFD21F), Color(0xFFFF8A00), Color(0xFFFF4F93), Color(0xFF3FC13A), Color(0xFF2386F5), Color(0xFF9163F5), Colors.white];
    _confetti = List.generate(
      34,
      (_) => _Confetti(
        r.nextDouble() * 376,
        10 + r.nextDouble() * 500,
        [8.0, 10.0, 12.0][r.nextInt(3)],
        [6.0, 14.0, 18.0][r.nextInt(3)],
        colors[r.nextInt(colors.length)],
        r.nextDouble() * 1.5,
      ),
    );
    later(300, _celebrate);
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _celebrate() {
    Voice.I.sfx('win');
    Voice.I.talk(['@P_genial', '@P_lograste']);
    setState(() => _up = true);
    later(300, () => setState(() => _up = false));
  }

  String get _medalTitle {
    if (app.lastMedal.isNotEmpty) {
      return kMedals.firstWhere((m) => m.id == app.lastMedal, orElse: () => kMedals.first).title;
    }
    return app.isGirl ? 'Exploradora de letras' : 'Explorador de letras';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7440E0),
      body: Stack(children: [
        Positioned.fill(
          child: RotationTransition(
            turns: _spin,
            child: CustomPaint(painter: _RaysPainter()),
          ),
        ),
        SafeArea(
          child: DesignFrame(
            child: Stack(children: [
              for (final c in _confetti)
                Positioned(
                  left: c.x,
                  top: c.y,
                  child: Transform.rotate(
                    angle: c.a,
                    child: Container(width: c.w, height: c.h, decoration: BoxDecoration(color: c.c, borderRadius: BorderRadius.circular(3))),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Transform.rotate(angle: -0.25, child: const StarIcon(size: 64)),
                      const Padding(padding: EdgeInsets.only(bottom: 22), child: StarIcon(size: 88)),
                      Transform.rotate(angle: 0.25, child: const StarIcon(size: 64)),
                    ],
                  ),
                  const RainbowText('¡Genial!', size: 60),
                  WoodSign.text('¡Ganaste un premio!', size: 22),
                  const SizedBox(height: 10),
                  Pressable(
                    label: 'Celebrar otra vez',
                    onTap: _celebrate,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 250),
                      offset: _up ? const Offset(0, -0.08) : Offset.zero,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [Kid('girl_bow', size: 88, joy: true), Owl(size: 136, cheer: true), Kid('boy_cap', size: 88, joy: true)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  WhiteCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(children: [
                      const Glossy(g: Pal.yellow, radius: 38, width: 76, height: 76, child: StarIcon(size: 44)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(app.lastMedal.isNotEmpty ? '¡Medalla nueva!' : '¡Buen trabajo!', style: nunito(14, color: Pal.muted, weight: FontWeight.w900)),
                          Text(_medalTitle, style: baloo(22, color: Pal.ink, height: 1.1)),
                        ]),
                      ),
                      const StarIcon(size: 26),
                      Text('+${app.lastEarned}', style: nunito(20, color: Pal.ink, weight: FontWeight.w900)),
                    ]),
                  ),
                  const Spacer(),
                  BigButton(text: 'Seguir jugando', g: Pal.yellow, darkText: true, onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 10),
                  Pressable(
                    label: 'Ver mi progreso',
                    onTap: () => goReplace(context, const ProgressScreen()),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(color: const Color(0xEBFFFFFF), borderRadius: BorderRadius.circular(24)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const StarIcon(size: 22),
                        const SizedBox(width: 8),
                        Text('Ver mi progreso', style: nunito(18, color: Pal.ink, weight: FontWeight.w900)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _Confetti {
  final double x, y, w, h, a;
  final Color c;
  _Confetti(this.x, this.y, this.w, this.h, this.c, this.a);
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.3);
    final r = math.max(size.width, size.height) * 1.2;
    final paint = Paint()..color = const Color(0x2EFFFFFF);
    for (var i = 0; i < 20; i++) {
      final a0 = i * 2 * math.pi / 20;
      final a1 = a0 + math.pi / 20;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + r * math.cos(a0), center.dy + r * math.sin(a0))
        ..lineTo(center.dx + r * math.cos(a1), center.dy + r * math.sin(a1))
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
