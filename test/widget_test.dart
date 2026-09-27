import 'package:abc_magico/core/data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hay 27 letras con su palabra', () {
    expect(kLetters.length, 27);
    expect(kWords.length, 27);
    for (var i = 0; i < 27; i++) {
      expect(kWords[i].letter, kLetters[i]);
    }
  });

  test('El nombre se limpia y se obtiene la inicial', () {
    expect(cleanName('sofía 123'), 'Sofía ');
    expect(initialOf('Ámbar'), 'A');
    expect(initialOf('ñandú'), 'Ñ');
  });
}
