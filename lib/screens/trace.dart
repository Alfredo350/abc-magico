import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';

/// Traza la letra: funciona con cualquier letra (mayúscula o minúscula).
/// Se dibuja la letra grande y se reparten puntitos dentro de ella;
/// el niño la pinta con el dedo hasta cubrir casi todos los puntitos.
class TraceGame extends StatefulWidget {
  const TraceGame({super.key});

  @override
  State<TraceGame> createState() => _TraceGameState();
}

class _TraceGameState extends State<TraceGame> with Later {
  static const double boxW = 300;
  static const double boxH = 330;
  static const double designW = 310;
  static const double designH = 340;
  static const double needed = 0.8; // 80 % de los puntitos
  static const colors = [
    Color(0xFF9163F5), Color(0xFFFF8A00), Color(0xFF2386F5), Color(0xFF3FC13A), Color(0xFFFF4F93),
  ];

  final math.Random _r = math.Random();
  final LevelDef lv = app.lvl;
  late List<String> letters;
  late bool lower;
  int idx = 0;
  int color = 0;
  List<List<Offset>> ink = [];
  List<Offset> targets = [];
  final Set<int> hit = {};
  bool solved = false;
  bool done = false;
  bool drawing = false;
  int earned = 0;
  String msg = 'Pinta encima de la letra con el dedo hasta llenar los puntitos.';

  @override
  void initState() {
    super.initState();
    lower = lv.lower;
    letters = _pickLetters();
    _prepare();
    later(500, _repeat);
  }

  List<String> _pickLetters() {
    final l = List<String>.from(lv.letters)..shuffle(_r);
    final list = l.take(math.min(5, l.length)).toList();
    if (lv.letters.length <= 5) {
      // en los niveles de 3 letras se mantiene el orden del abecedario
      list.sort((a, b) => kLetters.indexOf(a).compareTo(kLetters.indexOf(b)));
    }
    return list;
  }

  String get cur => letters[idx % letters.length];
  String get glyph => showLetter(cur, lower);

  // ---------- la letra como dibujo ----------

  static TextPainter _painter(String t, Color c) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: 290, fontWeight: FontWeight.w900, color: c, height: 1.0)),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  static void paintGlyph(Canvas canvas, String t, Color c) {
    final tp = _painter(t, c);
    tp.paint(canvas, Offset((designW - tp.width) / 2, (designH - tp.height) / 2));
  }

  /// Busca los puntitos que caen dentro de la letra.
  Future<void> _prepare() async {
    final text = glyph;
    final pts = <Offset>[];
    try {
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      paintGlyph(canvas, text, Colors.black);
      final img = await rec.endRecording().toImage(designW.toInt(), designH.toInt());
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      img.dispose();
      if (data != null) {
        for (var y = 7; y < designH; y += 15) {
          for (var x = 7; x < designW; x += 15) {
            final i = (y * designW.toInt() + x) * 4 + 3;
            if (data.getUint8(i) > 140) pts.add(Offset(x.toDouble(), y.toDouble()));
          }
        }
      }
    } catch (_) {}
    if (!mounted || text != glyph) return;
    setState(() {
      targets = pts;
      hit.clear();
      ink = [];
    });
  }

  void _repeat() => Voice.I.talk(['@I_traza', Voice.lc(cur)]);

  Offset _toDesign(Offset p) => Offset(p.dx * designW / boxW, p.dy * designH / boxH);

  void _start(Offset p) {
    if (solved || done) return;
    drawing = true;
    setState(() => ink.add([_toDesign(p)]));
    _check(_toDesign(p));
  }

  void _move(Offset p) {
    if (!drawing || solved || done) return;
    final d = _toDesign(p);
    setState(() => ink.last.add(d));
    _check(d);
  }

  void _check(Offset d) {
    var changed = false;
    for (var i = 0; i < targets.length; i++) {
      if (!hit.contains(i) && (targets[i] - d).distance < 20) {
        hit.add(i);
        changed = true;
      }
    }
    if (targets.isEmpty) {
      // si no se pudo medir la letra, basta con pintar un buen rato
      final n = ink.fold<int>(0, (a, s) => a + s.length);
      if (n > 90) _win();
      return;
    }
    if (changed && hit.length >= (targets.length * needed).ceil()) _win();
  }

  double get _pct => targets.isEmpty ? 0 : hit.length / targets.length;

  void _win() {
    if (solved) return;
    drawing = false;
    earned += 3;
    app.rateLetter(cur, 3);
    Voice.I.sfx('win');
    Voice.I.talk([...Voice.I.praise(), Voice.lc(cur)]);
    setState(() {
      solved = true;
      msg = '¡Muy bien! Trazaste la $glyph.';
    });
    later(2000, () {
      final n = idx + 1;
      if (n >= letters.length) {
        app.finishGame('traza', earned);
        setState(() => done = true);
        later(900, () => Voice.I.talk(Voice.I.bravo()));
        return;
      }
      setState(() {
        idx = n;
        solved = false;
        targets = [];
        ink = [];
        hit.clear();
        msg = 'Ahora la $glyph. ¡Píntala toda!';
      });
      _prepare();
      later(300, _repeat);
    });
  }

  void _setMode(bool l) {
    if (l == lower) return;
    clearLater();
    Voice.I.sfx('flip');
    setState(() {
      lower = l;
      solved = false;
      targets = [];
      ink = [];
      hit.clear();
      msg = '${l ? 'Minúsculas' : 'Mayúsculas'}: pinta la $glyph.';
    });
    _prepare();
    later(200, _repeat);
  }

  void _clear() {
    Voice.I.sfx('tap');
    setState(() {
      ink = [];
      hit.clear();
      solved = false;
    });
  }

  void _restart() {
    setState(() {
      letters = _pickLetters();
      idx = 0;
      ink = [];
      hit.clear();
      targets = [];
      solved = false;
      done = false;
      earned = 0;
    });
    _prepare();
    later(300, _repeat);
  }

  Widget _segBtn(String t, bool on, VoidCallback onTap) {
    return Pressable(
      label: t,
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: on ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC4A2FF), Color(0xFF7440E0)]) : null,
          color: on ? null : const Color(0xEBFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: on ? const Color(0xFF5226AE) : const Color(0xFFB9C8E2), offset: const Offset(0, 5))],
        ),
        child: Text(t, style: nunito(17, color: on ? Colors.white : Pal.ink, weight: FontWeight.w900)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Traza · Nivel ${lv.n}',
      onRepeat: _repeat,
      overlay: done ? DoneOverlay(title: '¡Gran trazo!', onRestart: _restart) : null,
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _segBtn('Mayúsculas', !lower, () => _setMode(false)),
            const SizedBox(width: 10),
            _segBtn('Minúsculas', lower, () => _setMode(true)),
          ]),
          const SizedBox(height: 12),
          WhiteCard(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: SizedBox(
                width: boxW,
                height: boxH,
                child: Stack(children: [
                  GestureDetector(
                    onPanStart: (d) => _start(d.localPosition),
                    onPanUpdate: (d) => _move(d.localPosition),
                    onPanEnd: (_) => drawing = false,
                    onPanCancel: () => drawing = false,
                    child: CustomPaint(
                      size: const Size(boxW, boxH),
                      painter: _TracePainter(glyph: glyph, targets: targets, hit: hit, ink: ink, inkColor: colors[color]),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFF1ECFE), borderRadius: BorderRadius.circular(12)),
                      child: Text('${(_pct * 100).round()}%', style: nunito(15, color: const Color(0xFF7440E0), weight: FontWeight.w900)),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Text('${idx + 1}/${letters.length}', style: nunito(15, color: Pal.muted, weight: FontWeight.w900)),
                  ),
                  if (solved)
                    const Positioned(
                      right: 4,
                      bottom: 4,
                      child: Row(children: [StarIcon(size: 34), StarIcon(size: 34), StarIcon(size: 34)]),
                    ),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
            decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white, width: 3)),
            child: Row(children: [
              ...List.generate(colors.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Pressable(
                    label: 'Color',
                    onTap: () {
                      Voice.I.sfx('tap');
                      setState(() => color = i);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: i == color ? Pal.ink : Colors.white, width: i == color ? 4 : 3),
                        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [Colors.white, colors[i]], stops: const [0.0, 0.45]),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              RoundBtn(icon: Icons.cleaning_services_rounded, label: 'Borrar y empezar de nuevo', size: 48, onTap: _clear),
            ]),
          ),
          const Spacer(),
          LumiSays(text: msg, onTap: _repeat),
        ],
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final String glyph;
  final List<Offset> targets;
  final Set<int> hit;
  final List<List<Offset>> ink;
  final Color inkColor;

  _TracePainter({required this.glyph, required this.targets, required this.hit, required this.ink, required this.inkColor});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _TraceGameState.designW, size.height / _TraceGameState.designH);
    _TraceGameState.paintGlyph(canvas, glyph, const Color(0xFFEDE5FF));
    final inkPaint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in ink) {
      if (s.length == 1) {
        canvas.drawCircle(s.first, 15, Paint()..color = inkColor);
      } else {
        final p = Path()..moveTo(s.first.dx, s.first.dy);
        for (final o in s.skip(1)) {
          p.lineTo(o.dx, o.dy);
        }
        canvas.drawPath(p, inkPaint);
      }
    }
    for (var i = 0; i < targets.length; i++) {
      canvas.drawCircle(targets[i], 4.5, Paint()..color = hit.contains(i) ? const Color(0xFF3FC13A) : const Color(0xFFC9B8F5));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) => true;
}
