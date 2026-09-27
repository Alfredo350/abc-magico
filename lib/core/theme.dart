import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un color "brillante" con 4 tonos: claro (arriba), base, profundo (abajo) y sombra.
class Gl {
  final Color light;
  final Color base;
  final Color deep;
  final Color shadow;
  const Gl(this.light, this.base, this.deep, this.shadow);
}

/// Paleta de ABC Mágico.
class Pal {
  static const ink = Color(0xFF1F2A44);
  static const muted = Color(0xFF5B6478);
  static const brown = Color(0xFF6B3E1D);
  static const sky = Color(0xFF8ED8FF);

  static const orange = Gl(Color(0xFFFFC14D), Color(0xFFFF8A00), Color(0xFFF26A00), Color(0xFFC24E00));
  static const blue = Gl(Color(0xFF6EC3FF), Color(0xFF2386F5), Color(0xFF1463D8), Color(0xFF0D4AA6));
  static const green = Gl(Color(0xFF8FEA5C), Color(0xFF3FC13A), Color(0xFF22A02A), Color(0xFF17771E));
  static const pink = Gl(Color(0xFFFF9CC6), Color(0xFFFF4F93), Color(0xFFE22A77), Color(0xFFA8185A));
  static const purple = Gl(Color(0xFFC4A2FF), Color(0xFF9163F5), Color(0xFF7440E0), Color(0xFF5226AE));
  static const teal = Gl(Color(0xFF6FE6E6), Color(0xFF1CC0C8), Color(0xFF0B9DAA), Color(0xFF08727C));
  static const yellow = Gl(Color(0xFFFFF17A), Color(0xFFFFD21F), Color(0xFFFFB800), Color(0xFFC98A00));
  static const navy = Gl(Color(0xFF3E62B0), Color(0xFF23407F), Color(0xFF172D5E), Color(0xFF0C1A3A));
  static const red = Gl(Color(0xFFFF8A7A), Color(0xFFF44336), Color(0xFFD72C22), Color(0xFF9E1B14));
  static const grey = Gl(Color(0xFFF2EEE8), Color(0xFFDDD6CB), Color(0xFFC9C0B2), Color(0xFFA69C8C));

  static const List<Gl> cycle = [red, orange, green, blue, purple, pink, teal];
  static const List<Color> rainbow = [
    Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFF9A825), Color(0xFF43A047),
    Color(0xFF1E88E5), Color(0xFF8E24AA), Color(0xFFE91E63),
  ];
}

/// Tipografía redondeada para títulos y letras.
TextStyle baloo(double size, {Color? color, double height = 1.05}) =>
    GoogleFonts.baloo2(fontSize: size, fontWeight: FontWeight.w800, color: color, height: height);

/// Tipografía para textos.
TextStyle nunito(double size, {Color? color, FontWeight weight = FontWeight.w800, double? height}) =>
    GoogleFonts.nunito(fontSize: size, fontWeight: weight, color: color, height: height);
