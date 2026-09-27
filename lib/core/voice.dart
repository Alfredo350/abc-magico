import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'data.dart';
import 'state.dart';

/// Voz de Lumi.
/// - Partes que empiezan con '@' son audios grabados (assets/audio/<clave>.mp3).
/// - El resto se lee con la voz del teléfono (por ejemplo, el nombre del niño/niña).
class Voice {
  Voice._();
  static final Voice I = Voice._();

  final AudioPlayer _clip = AudioPlayer();
  final AudioPlayer _fx = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  final math.Random _rnd = math.Random();
  int _id = 0;
  Completer<void>? _ttsDone;

  void _ttsFinish() {
    final c = _ttsDone;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<void> init() async {
    try {
      await _clip.setReleaseMode(ReleaseMode.stop);
      await _fx.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
    try {
      await _tts.awaitSpeakCompletion(false);
      _tts.setCompletionHandler(_ttsFinish);
      _tts.setCancelHandler(_ttsFinish);
      _tts.setErrorHandler((_) => _ttsFinish());
      try {
        await _tts.setQueueMode(0); // cada frase reemplaza a la anterior, nunca se enciman
      } catch (_) {}
      await _tts.setLanguage('es-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.05);
      final voices = await _tts.getVoices;
      if (voices is List) {
        Map<String, String>? best;
        var bestScore = -999;
        for (final v in voices) {
          if (v is! Map) continue;
          final name = (v['name'] ?? '').toString();
          final locale = (v['locale'] ?? '').toString();
          final n = name.toLowerCase();
          final l = locale.toLowerCase();
          if (!l.startsWith('es')) continue;
          var sc = 0;
          if (RegExp(r'es[-_](us|mx|419|co|ar|bo|pe|cl|ve|ec)').hasMatch(l)) sc += 4;
          if (n.contains('local')) sc += 2; // funciona sin internet
          if (n.contains('female') || n.contains('mujer')) sc += 5;
          if (n.contains('male') && !n.contains('female')) sc -= 10;
          if (sc > bestScore) {
            bestScore = sc;
            best = {'name': name, 'locale': locale};
          }
        }
        if (best != null) await _tts.setVoice(best);
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    _id++;
    _ttsFinish();
    try {
      await _clip.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Dice una secuencia de partes (audios grabados y texto).
  Future<void> talk(List<String> parts) async {
    final id = ++_id;
    _ttsFinish();
    try {
      await _clip.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    for (final p in parts) {
      if (id != _id) return;
      if (p.isEmpty) continue;
      if (p.startsWith('@')) {
        await _playClip(p.substring(1));
      } else {
        await _speak(p);
      }
      if (id != _id) return;
      await Future<void>.delayed(const Duration(milliseconds: 90));
    }
  }

  Future<void> say(String text) => talk([text]);

  Future<void> _playClip(String key) async {
    if (!app.voiceOn) return;
    try {
      try {
        await _tts.stop();
      } catch (_) {}
      final done = _clip.onPlayerComplete.first;
      await _clip.setVolume(app.volume);
      await _clip.play(AssetSource('audio/$key.mp3'));
      await done.timeout(const Duration(seconds: 6), onTimeout: () {});
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    if (!app.voiceOn) return;
    try {
      try {
        await _clip.stop();
      } catch (_) {}
      final done = Completer<void>();
      _ttsDone = done;
      await _tts.setVolume(app.volume);
      await _tts.speak(text);
      await done.future.timeout(Duration(seconds: 3 + text.length ~/ 8), onTimeout: () {});
    } catch (_) {}
  }

  /// Efectos: ok, bad, tap, flip, win.
  Future<void> sfx(String kind) async {
    if (!app.fxOn) return;
    try {
      await _fx.stop();
      await _fx.play(AssetSource('sfx/$kind.wav'), volume: app.volume * 0.8);
    } catch (_) {}
  }

  // ---------- ayudas para armar frases ----------

  /// Audio grabado del nombre de una letra.
  static String lc(String l) => '@L_${l == 'Ñ' ? 'NY' : l.toUpperCase()}';

  /// Audio grabado de una palabra.
  static String wc(String w) {
    var s = stripAccents(w).toLowerCase().replaceAll('ñ', 'n').replaceAll('Ñ', 'n');
    s = s.replaceAll(' ', '');
    return '@W_$s';
  }

  T any<T>(List<T> a) => a[_rnd.nextInt(a.length)];

  /// Felicitación grabada (nunca se mezcla con la voz del teléfono).
  List<String> praise() => [any(['@P_muybien', '@P_genial', '@P_excelente', '@P_esoes'])];

  /// Ánimo suave cuando se equivoca.
  List<String> oops() => any([
        ['@A_casi', '@A_intenta'],
        ['@A_tupuedes'],
      ]);

  /// Al terminar un juego.
  List<String> bravo() => ['@P_lograste'];
}
