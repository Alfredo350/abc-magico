import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme.dart';
import '../core/voice.dart';
import '../screens/celebration.dart';

// ======================================================================
// Navegación
// ======================================================================

Future<void> go(BuildContext context, Widget screen) async {
  Voice.I.stop();
  await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  Voice.I.stop();
}

void goReplace(BuildContext context, Widget screen) {
  Voice.I.stop();
  Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => screen));
}

// ======================================================================
// Temporizadores seguros para pantallas
// ======================================================================

mixin Later<T extends StatefulWidget> on State<T> {
  final List<Timer> _timers = [];

  void later(int ms, VoidCallback f) {
    _timers.add(Timer(Duration(milliseconds: ms), () {
      if (mounted) f();
    }));
  }

  void clearLater() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  void dispose() {
    clearLater();
    super.dispose();
  }
}

// ======================================================================
// Imágenes
// ======================================================================

class Img extends StatelessWidget {
  final String name;
  final double width;
  final double? height;
  const Img(this.name, {super.key, required this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/img/$name.svg', width: width, height: height ?? width, fit: BoxFit.contain);
  }
}

/// Niño o niña ilustrado (proporción 100 x 112).
class Kid extends StatelessWidget {
  final String kind; // boy, girl_bow, boy_cap, girl_tails
  final double size;
  final bool joy;
  const Kid(this.kind, {super.key, this.size = 80, this.joy = false});

  @override
  Widget build(BuildContext context) => Img('kid_$kind${joy ? '_joy' : ''}', width: size, height: size * 1.12);
}

class Owl extends StatelessWidget {
  final double size;
  final bool cheer;
  const Owl({super.key, this.size = 90, this.cheer = false});

  @override
  Widget build(BuildContext context) => Img(cheer ? 'owl_cheer' : 'owl', width: size, height: size * 134 / 120);
}

class StarIcon extends StatelessWidget {
  final double size;
  final bool on;
  const StarIcon({super.key, this.size = 22, this.on = true});

  @override
  Widget build(BuildContext context) => Img(on ? 'star' : 'star_dim', width: size);
}

// ======================================================================
// Botones y superficies brillantes
// ======================================================================

BoxDecoration glossDeco(Gl g, double r) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [g.light, g.base, g.deep],
        stops: const [0.0, 0.45, 1.0],
      ),
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: const Color(0xD9FFFFFF), width: 3),
      boxShadow: [
        BoxShadow(color: g.shadow, offset: const Offset(0, 6)),
        const BoxShadow(color: Color(0x33142850), blurRadius: 16, offset: Offset(0, 10)),
      ],
    );

/// Se encoge un poquito al tocarlo.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  const Pressable({super.key, required this.child, this.onTap, this.label});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.93 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Caja brillante con reflejo.
class Glossy extends StatelessWidget {
  final Gl g;
  final double radius;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  const Glossy({
    super.key,
    required this.g,
    required this.child,
    this.radius = 26,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: glossDeco(g, radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(math.max(0.0, radius - 3)),
        child: Stack(
          children: [
            Positioned(
              left: 6,
              right: 6,
              top: 3,
              child: IgnorePointer(
                child: Container(
                  height: (height != null && height!.isFinite) ? height! * 0.42 : 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Align(
                alignment: alignment,
                widthFactor: width == null ? 1 : null,
                heightFactor: height == null ? 1 : null,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Texto con contorno (para letras brillantes y etiquetas).
class StrokeText extends StatelessWidget {
  final String text;
  final double size;
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final Color? shadow;
  final TextAlign align;
  final bool display;

  const StrokeText(
    this.text, {
    super.key,
    required this.size,
    this.fill = Colors.white,
    this.stroke = const Color(0x73000000),
    this.strokeWidth = 4,
    this.shadow,
    this.align = TextAlign.left,
    this.display = true,
  });

  @override
  Widget build(BuildContext context) {
    final st = display ? baloo(size) : nunito(size, weight: FontWeight.w900);
    final sh = shadow;
    return Stack(
      children: [
        Text(
          text,
          textAlign: align,
          style: st.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
            shadows: sh == null ? null : [Shadow(color: sh, offset: Offset(0, size * 0.05))],
          ),
        ),
        Text(text, textAlign: align, style: st.copyWith(color: fill)),
      ],
    );
  }
}

/// Letra grande brillante con borde blanco.
class GlossyLetter extends StatelessWidget {
  final String letter;
  final Gl g;
  final double size;
  const GlossyLetter(this.letter, {super.key, required this.g, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return StrokeText(letter, size: size, fill: g.base, stroke: Colors.white, strokeWidth: size * 0.11, shadow: g.shadow);
  }
}

/// Etiqueta blanca con contorno oscuro (texto sobre botones de color).
class LabelText extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;
  const LabelText(this.text, {super.key, this.size = 20, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) =>
      StrokeText(text, size: size, strokeWidth: size * 0.2, stroke: const Color(0x80000000), align: align);
}

/// Texto multicolor tipo arcoíris.
class RainbowText extends StatelessWidget {
  final String text;
  final double size;
  final TextAlign align;
  const RainbowText(this.text, {super.key, this.size = 30, this.align = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    final st = baloo(size);
    var i = 0;
    final spans = <TextSpan>[];
    for (final ch in text.split('')) {
      final c = ch.trim().isEmpty ? Colors.transparent : Pal.rainbow[i++ % Pal.rainbow.length];
      spans.add(TextSpan(text: ch, style: TextStyle(color: c)));
    }
    return Stack(
      children: [
        Text(
          text,
          textAlign: align,
          style: st.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = size * 0.16
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: const [Shadow(color: Color(0x33000000), offset: Offset(0, 3))],
          ),
        ),
        Text.rich(TextSpan(style: st, children: spans), textAlign: align),
      ],
    );
  }
}

/// Letrero de madera (con cuerdas opcionales).
class WoodSign extends StatelessWidget {
  final Widget child;
  final bool ropes;
  final EdgeInsetsGeometry padding;
  const WoodSign({super.key, required this.child, this.ropes = false, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6)});

  static Widget text(String t, {double size = 22, bool ropes = false}) => WoodSign(
        ropes: ropes,
        child: Text(t, textAlign: TextAlign.center, style: baloo(size, color: Pal.brown)),
      );

  @override
  Widget build(BuildContext context) {
    final board = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9E2B6), Color(0xFFEBC48A), Color(0xFFDDAE6C)],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: const Color(0xFFB9804A), width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0xFF8A5A2B), offset: Offset(0, 5)),
          BoxShadow(color: Color(0x40502800), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
    if (!ropes) return board;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        board,
        Positioned(top: -26, left: 24, child: _rope()),
        Positioned(top: -26, right: 24, child: _rope()),
      ],
    );
  }

  Widget _rope() => Container(
        width: 7,
        height: 30,
        decoration: BoxDecoration(color: const Color(0xFF8D5A34), borderRadius: BorderRadius.circular(4)),
      );
}

/// Botón redondo blanco con ícono.
class RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String label;
  final Color color;
  final double opacity;
  const RoundBtn({super.key, required this.icon, required this.onTap, required this.label, this.size = 54, this.color = const Color(0xFF1E6FE0), this.opacity = 1});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Pressable(
        onTap: onTap,
        label: label,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFE4EEFF)]),
            boxShadow: [
              BoxShadow(color: Color(0xFFA9BEDF), offset: Offset(0, 5)),
              BoxShadow(color: Color(0x33142850), blurRadius: 14, offset: Offset(0, 8)),
            ],
          ),
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      ),
    );
  }
}

/// Botón grande brillante.
class BigButton extends StatelessWidget {
  final String text;
  final Gl g;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool darkText;
  final double height;
  final double fontSize;
  const BigButton({super.key, required this.text, required this.g, required this.onTap, this.icon, this.darkText = false, this.height = 66, this.fontSize = 26});

  @override
  Widget build(BuildContext context) {
    final label = darkText
        ? Text(text, style: baloo(fontSize, color: Pal.ink))
        : LabelText(text, size: fontSize);
    return Pressable(
      onTap: onTap,
      label: text,
      child: Glossy(
        g: g,
        radius: height / 2,
        height: height,
        width: double.infinity,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: darkText ? Pal.ink : Colors.white, size: fontSize + 4),
            if (icon != null) const SizedBox(width: 8),
            label,
          ],
        ),
      ),
    );
  }
}

/// Tarjeta blanca.
class WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  const WhiteCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [
          BoxShadow(color: Color(0x1F142850), offset: Offset(0, 6)),
          BoxShadow(color: Color(0x26142850), blurRadius: 24, offset: Offset(0, 14)),
        ],
      ),
      child: child,
    );
  }
}

/// Píldora blanca pequeña (estrellas, racha).
class Pill extends StatelessWidget {
  final List<Widget> children;
  const Pill({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white, Color(0xFFF1F5FF)]),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0xFFB9C8E2), offset: Offset(0, 4))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Barra de progreso de un juego.
class ProgressPill extends StatelessWidget {
  final int done;
  final int total;
  final Gl g;
  const ProgressPill({super.key, required this.done, required this.total, required this.g});

  @override
  Widget build(BuildContext context) {
    final f = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x1F142850), offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 16,
                color: const Color(0xFFE6EDF5),
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 400),
                  widthFactor: f,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [g.light, g.base, g.deep]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const StarIcon(size: 18),
          const SizedBox(width: 3),
          Text('$done/$total', style: nunito(16, color: Pal.ink, weight: FontWeight.w900)),
        ],
      ),
    );
  }
}

/// Lumi hablando con un globo de texto.
class LumiSays extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double size;
  const LumiSays({super.key, required this.text, this.onTap, this.size = 66});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Pressable(onTap: onTap, label: 'Escuchar a Lumi', child: Owl(size: size)),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [BoxShadow(color: Color(0x24142850), offset: Offset(0, 5))],
            ),
            child: Text(text, style: nunito(17, color: Pal.ink, height: 1.3)),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
// Estructura de pantalla
// ======================================================================

/// Dibuja el diseño en un lienzo fijo de 390 x 800 y lo escala a cualquier pantalla.
class DesignFrame extends StatelessWidget {
  final Widget child;
  const DesignFrame({super.key, required this.child});

  static const double w = 390;
  static const double h = 800;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final s = math.min(box.maxWidth / w, box.maxHeight / h);
      return Center(
        child: SizedBox(
          width: w * s,
          height: h * s,
          child: FittedBox(fit: BoxFit.fill, child: SizedBox(width: w, height: h, child: child)),
        ),
      );
    });
  }
}

/// Fondo con paisaje + contenido escalado.
class SceneScreen extends StatelessWidget {
  final Widget child;
  final bool sun;
  final bool scenery;
  final Color background;
  const SceneScreen({super.key, required this.child, this.sun = false, this.scenery = true, this.background = Pal.sky});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          if (scenery)
            Positioned.fill(
              child: SvgPicture.asset(sun ? 'assets/img/scene_sun.svg' : 'assets/img/scene.svg', fit: BoxFit.cover),
            ),
          SafeArea(child: DesignFrame(child: child)),
        ],
      ),
    );
  }
}

/// Pantalla de juego: letrero con título, volver y repetir instrucción.
class GameScaffold extends StatelessWidget {
  final String title;
  final VoidCallback? onRepeat;
  final Widget child;
  final Widget? overlay;
  const GameScaffold({super.key, required this.title, required this.child, this.onRepeat, this.overlay});

  @override
  Widget build(BuildContext context) {
    return SceneScreen(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    RoundBtn(icon: Icons.arrow_back_ios_new_rounded, label: 'Volver', onTap: () => Navigator.of(context).maybePop()),
                    const SizedBox(width: 10),
                    Expanded(child: WoodSign.text(title, size: 22, ropes: true)),
                    const SizedBox(width: 10),
                    RoundBtn(icon: Icons.volume_up_rounded, label: 'Repetir instrucción', onTap: onRepeat),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(child: child),
              ],
            ),
          ),
          if (overlay != null) Positioned.fill(child: overlay!),
        ],
      ),
    );
  }
}

/// Aviso al terminar un juego.
class DoneOverlay extends StatelessWidget {
  final String title;
  final VoidCallback onRestart;
  const DoneOverlay({super.key, required this.title, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x8C142D5A),
      alignment: Alignment.center,
      child: Container(
        width: 330,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [BoxShadow(color: Color(0x33142850), offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.rotate(angle: -0.2, child: const StarIcon(size: 46)),
                const Padding(padding: EdgeInsets.only(bottom: 14), child: StarIcon(size: 62)),
                Transform.rotate(angle: 0.2, child: const StarIcon(size: 46)),
              ],
            ),
            RainbowText(title, size: 38),
            const SizedBox(height: 6),
            const Owl(size: 104, cheer: true),
            const SizedBox(height: 12),
            BigButton(
              text: 'Ver mi premio',
              g: Pal.yellow,
              darkText: true,
              onTap: () => goReplace(context, const CelebrationScreen()),
            ),
            const SizedBox(height: 12),
            Pressable(
              onTap: onRestart,
              label: 'Jugar otra vez',
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFE3E9F3), width: 3),
                  boxShadow: const [BoxShadow(color: Color(0xFFD3DCEA), offset: Offset(0, 4))],
                ),
                child: Text('Jugar otra vez', style: nunito(18, color: Pal.ink, weight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Burbuja con letra (para "Encuentra la letra").
class Balloon extends StatelessWidget {
  final String letter;
  final Gl g;
  final double size;
  const Balloon({super.key, required this.letter, required this.g, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), radius: 0.9, colors: [g.light, g.base, g.deep], stops: const [0.0, 0.45, 1.0]),
        boxShadow: [
          BoxShadow(color: g.shadow, offset: const Offset(0, 6)),
          const BoxShadow(color: Color(0x38142850), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: size * 0.2,
            top: size * 0.1,
            child: Container(
              width: size * 0.26,
              height: size * 0.16,
              decoration: BoxDecoration(color: const Color(0x99FFFFFF), borderRadius: BorderRadius.circular(size)),
            ),
          ),
          LabelText(letter, size: size * 0.52),
        ],
      ),
    );
  }
}

/// Dibujo de una palabra (o la letra en un círculo si no hay dibujo).
class WordPic extends StatelessWidget {
  final String pic;
  final String letter;
  final double size;
  const WordPic({super.key, required this.pic, required this.letter, this.size = 90});

  @override
  Widget build(BuildContext context) {
    if (pic.isNotEmpty) return Img('pic_$pic', width: size);
    return Glossy(
      g: Pal.orange,
      radius: size * 0.4,
      width: size * 0.8,
      height: size * 0.8,
      child: LabelText(letter, size: size * 0.48),
    );
  }
}

