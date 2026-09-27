/// Contenido educativo: las 27 letras del abecedario español y sus palabras.
const List<String> kLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
  'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

class LetterWord {
  final String letter;
  final String word;
  /// Nombre del dibujo en assets/img/pic_<pic>.svg ('' si no hay dibujo).
  final String pic;
  const LetterWord(this.letter, this.word, this.pic);
}

const List<LetterWord> kWords = [
  LetterWord('A', 'ÁRBOL', 'arbol'),
  LetterWord('B', 'BARCO', 'barco'),
  LetterWord('C', 'CASA', 'casa'),
  LetterWord('D', 'DADO', 'dado'),
  LetterWord('E', 'ESTRELLA', 'estrella'),
  LetterWord('F', 'FOCA', 'foca'),
  LetterWord('G', 'GATO', 'gato'),
  LetterWord('H', 'HELADO', 'helado'),
  LetterWord('I', 'IGLÚ', 'iglu'),
  LetterWord('J', 'JIRAFA', 'jirafa'),
  LetterWord('K', 'KIWI', 'kiwi'),
  LetterWord('L', 'LUNA', 'luna'),
  LetterWord('M', 'MANZANA', 'manzana'),
  LetterWord('N', 'NUBE', 'nube'),
  LetterWord('Ñ', 'ÑANDÚ', 'nandu'),
  LetterWord('O', 'OSO', 'oso'),
  LetterWord('P', 'PEZ', 'pez'),
  LetterWord('Q', 'QUESO', 'queso'),
  LetterWord('R', 'RATÓN', 'raton'),
  LetterWord('S', 'SOL', 'sol'),
  LetterWord('T', 'TORTUGA', 'tortuga'),
  LetterWord('U', 'UVAS', 'uvas'),
  LetterWord('V', 'VACA', 'vaca'),
  LetterWord('W', 'WAFLE', 'wafle'),
  LetterWord('X', 'XILÓFONO', 'xilofono'),
  LetterWord('Y', 'YOYÓ', 'yoyo'),
  LetterWord('Z', 'ZAPATO', 'zapato'),
];

/// Palabras con dibujo, usadas en los juegos de imágenes.
List<LetterWord> get kPictureWords => kWords.where((w) => w.pic.isNotEmpty).toList();

LetterWord wordFor(String letter) => kWords.firstWhere((w) => w.letter == letter, orElse: () => kWords.first);

String stripAccents(String s) {
  const from = 'ÁÉÍÓÚÜáéíóúü';
  const to = 'AEIOUUaeiouu';
  var out = s;
  for (var i = 0; i < from.length; i++) {
    out = out.replaceAll(from[i], to[i]);
  }
  return out;
}

/// Primera letra del nombre (sin tilde; conserva la Ñ).
String initialOf(String name) {
  if (name.isEmpty) return '';
  final c = name[0].toUpperCase();
  if (c == 'Ñ') return 'Ñ';
  return stripAccents(c);
}

/// Deja el nombre limpio: solo letras, cada palabra con mayúscula inicial.
String cleanName(String v) {
  final only = v.replaceAll(RegExp(r"[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ' -]"), '').replaceAll(RegExp(r'\s+'), ' ');
  final trimmed = only.trimLeft();
  final cut = trimmed.length > 18 ? trimmed.substring(0, 18) : trimmed;
  return cut
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

/// Nombre de cada letra (para la voz del teléfono).
const Map<String, String> kLetterNames = {
  'A': 'a', 'B': 'be', 'C': 'ce', 'D': 'de', 'E': 'e', 'F': 'efe', 'G': 'ge', 'H': 'hache', 'I': 'i',
  'J': 'jota', 'K': 'ka', 'L': 'ele', 'M': 'eme', 'N': 'ene', 'Ñ': 'eñe', 'O': 'o', 'P': 'pe', 'Q': 'cu',
  'R': 'erre', 'S': 'ese', 'T': 'te', 'U': 'u', 'V': 've corta', 'W': 'doble ve', 'X': 'equis', 'Y': 'ye', 'Z': 'zeta',
};

/// Letra para mostrar (en minúscula en los niveles de minúsculas).
String showLetter(String l, bool lower) => lower ? l.toLowerCase() : l;

/// Un nivel de juego: qué letras se practican.
class LevelDef {
  final int n;
  final String name;
  final List<String> letters;
  final bool lower;
  const LevelDef(this.n, this.name, this.letters, {this.lower = false});
}

/// 15 niveles: 9 grupos de 3 letras, vocales, 3 repasos, minúsculas y todo el abecedario.
const List<LevelDef> kLevels = [
  LevelDef(1, 'A · B · C', ['A', 'B', 'C']),
  LevelDef(2, 'D · E · F', ['D', 'E', 'F']),
  LevelDef(3, 'G · H · I', ['G', 'H', 'I']),
  LevelDef(4, 'J · K · L', ['J', 'K', 'L']),
  LevelDef(5, 'M · N · Ñ', ['M', 'N', 'Ñ']),
  LevelDef(6, 'O · P · Q', ['O', 'P', 'Q']),
  LevelDef(7, 'R · S · T', ['R', 'S', 'T']),
  LevelDef(8, 'U · V · W', ['U', 'V', 'W']),
  LevelDef(9, 'X · Y · Z', ['X', 'Y', 'Z']),
  LevelDef(10, 'Vocales', ['A', 'E', 'I', 'O', 'U']),
  LevelDef(11, 'Repaso A–I', ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I']),
  LevelDef(12, 'Repaso J–Q', ['J', 'K', 'L', 'M', 'N', 'Ñ', 'O', 'P', 'Q']),
  LevelDef(13, 'Repaso R–Z', ['R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']),
  LevelDef(14, 'Minúsculas', kLetters, lower: true),
  LevelDef(15, 'Todo el ABC', kLetters),
];

LevelDef levelDef(int n) => kLevels[(n - 1).clamp(0, kLevels.length - 1)];

/// Posición de la letra dentro de la palabra (ignorando tildes).
int holeFor(LetterWord w) {
  final plain = stripAccents(w.word);
  final i = plain.indexOf(w.letter);
  return i < 0 ? 0 : i;
}
