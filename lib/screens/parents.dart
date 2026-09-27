import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';
import 'welcome.dart';

const _bg = Color(0xFFF5F6F8);
const _border = Color(0xFFDDE1E8);
const _blue = Color(0xFF1463D8);

/// Puerta para adultos: una multiplicación sencilla.
class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  final math.Random _r = math.Random();
  late int a;
  late int b;
  String val = '';
  String note = '';
  bool bad = false;

  @override
  void initState() {
    super.initState();
    _newQ();
  }

  void _newQ() {
    a = 3 + _r.nextInt(7);
    b = 4 + _r.nextInt(6);
    val = '';
  }

  void _press(String d) {
    if (val.length >= 2) return;
    Voice.I.sfx('tap');
    setState(() {
      val += d;
      note = '';
    });
  }

  void _ok() {
    if (int.tryParse(val) == a * b) {
      Voice.I.sfx('ok');
      goReplace(context, const ParentsScreen());
    } else {
      Voice.I.sfx('bad');
      setState(() {
        _newQ();
        note = 'No es correcto. Prueba con esta otra.';
        bad = true;
      });
    }
  }

  Widget _key(Widget child, VoidCallback onTap, {Color bg = Colors.white, String? label}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Pressable(
          label: label,
          onTap: onTap,
          child: Container(
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _digit(String d) => _key(Text(d, style: nunito(28, color: Pal.ink)), () => _press(d), label: d);

  Widget _box(int i) => Container(
        width: 60,
        height: 68,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: val.length == i ? _blue : _border, width: 2),
        ),
        child: Text(val.length > i ? val[i] : '', style: nunito(36, color: Pal.ink, weight: FontWeight.w900)),
      );

  @override
  Widget build(BuildContext context) {
    return SceneScreen(
      scenery: false,
      background: _bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded, color: Pal.ink), tooltip: 'Volver'),
            Text('Zona para adultos', style: nunito(20, color: Pal.ink, weight: FontWeight.w900)),
          ]),
          const SizedBox(height: 18),
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: Color(0xFFE9F0FF), shape: BoxShape.circle),
            child: const Icon(Icons.lock_rounded, color: _blue, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            'Para entrar, resuelve esta operación. Así evitamos que los peques cambien la configuración.',
            textAlign: TextAlign.center,
            style: nunito(16, color: Pal.muted, weight: FontWeight.w700, height: 1.4),
          ),
          const SizedBox(height: 14),
          Text('$a × $b = ?', style: nunito(44, color: Pal.ink, weight: FontWeight.w900)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_box(0), const SizedBox(width: 10), _box(1)]),
          const SizedBox(height: 10),
          Text(note, style: nunito(15, color: bad ? const Color(0xFFB42318) : const Color(0xFF15834A))),
          const Spacer(),
          Row(children: [_digit('1'), _digit('2'), _digit('3')]),
          Row(children: [_digit('4'), _digit('5'), _digit('6')]),
          Row(children: [_digit('7'), _digit('8'), _digit('9')]),
          Row(children: [
            _key(const Icon(Icons.backspace_outlined, color: Pal.ink), () => setState(() => val = val.isEmpty ? '' : val.substring(0, val.length - 1)), bg: const Color(0xFFEEF0F4), label: 'Borrar'),
            _digit('0'),
            _key(const Icon(Icons.check_rounded, color: Colors.white, size: 30), _ok, bg: _blue, label: 'Aceptar'),
          ]),
        ]),
      ),
    );
  }
}

/// Panel para padres: progreso real, ajustes de sonido y reinicio.
class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  static const dayNames = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];

  BoxDecoration get _card => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE3E6EC)));

  Widget _mini(String v, String l) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _card,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FittedBox(child: Text(v, style: nunito(22, color: Pal.ink, weight: FontWeight.w900))),
            Text(l, style: nunito(12, color: Pal.muted, weight: FontWeight.w700)),
          ]),
        ),
      );

  Widget _toggle(IconData icon, String label, bool on, ValueChanged<bool> f) => Row(children: [
        Icon(icon, color: Pal.muted, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: nunito(16, color: Pal.ink, weight: FontWeight.w700))),
        Switch(value: on, onChanged: f, activeColor: Colors.white, activeTrackColor: _blue),
      ]);

  String _fmtMinutes(int m) => m >= 60 ? '${m ~/ 60} h ${m % 60}' : '$m min';

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('¿Borrar todo el progreso?'),
        content: const Text('Se borrarán estrellas, letras y medallas. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB42318)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sí, borrar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      app.resetProgress();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = app.last7;
    final total = week.fold<int>(0, (a, b) => a + b);
    final maxV = math.max(1, week.reduce(math.max));
    final now = DateTime.now();
    final weak = app.weakLetters;
    return SceneScreen(
      scenery: false,
      background: _bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(children: [
          Row(children: [
            IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded, color: Pal.ink), tooltip: 'Salir'),
            Expanded(child: Text('Panel para padres', style: nunito(20, color: Pal.ink, weight: FontWeight.w900))),
          ]),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: _card,
                child: Row(children: [
                  const Icon(Icons.child_care_rounded, color: _blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      app.hasName ? '${app.name} (${app.isGirl ? 'niña' : 'niño'})' : 'Sin nombre',
                      style: nunito(16, color: Pal.ink, weight: FontWeight.w800),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()), (_) => false),
                    child: const Text('Cambiar'),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _mini(_fmtMinutes(total), 'esta semana'),
                const SizedBox(width: 8),
                _mini('${app.lettersLearned}', 'letras practicadas'),
                const SizedBox(width: 8),
                _mini('${app.activities}', 'actividades'),
              ]),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: _card,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Minutos por día', style: nunito(15, color: Pal.ink, weight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 130,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final v = week[i];
                        final d = now.subtract(Duration(days: 6 - i));
                        return Expanded(
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text(v == 0 ? '–' : '$v', style: nunito(11, color: Pal.muted)),
                            const SizedBox(height: 4),
                            Container(
                              width: 26,
                              height: math.max(3.0, 90.0 * v / maxV),
                              decoration: BoxDecoration(
                                color: v == 0 ? const Color(0xFFDDE1E8) : const Color(0xFF2386F5),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(3)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(dayNames[d.weekday % 7], style: nunito(12, color: Pal.muted)),
                          ]),
                        );
                      }),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: _card,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Necesita más práctica', style: nunito(15, color: Pal.ink, weight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  if (weak.isEmpty)
                    Text('Aún no hay datos. Se llenará cuando juegue.', style: nunito(13, color: Pal.muted, weight: FontWeight.w700))
                  else
                    Wrap(
                      spacing: 8,
                      children: weak
                          .map((l) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFFFF1E6), borderRadius: BorderRadius.circular(14)),
                                child: Text(l, style: nunito(15, color: const Color(0xFF9A3D06))),
                              ))
                          .toList(),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
                decoration: _card,
                child: Column(children: [
                  _toggle(Icons.record_voice_over_rounded, 'Voz de Lumi', app.voiceOn, (v) => setState(() => app.setVoice(v))),
                  _toggle(Icons.notifications_active_rounded, 'Efectos de sonido', app.fxOn, (v) => setState(() => app.setFx(v))),
                  Row(children: [
                    const Icon(Icons.volume_up_rounded, color: Pal.muted, size: 22),
                    const SizedBox(width: 12),
                    Text('Volumen', style: nunito(16, color: Pal.ink, weight: FontWeight.w700)),
                    Expanded(
                      child: Slider(
                        value: app.volume,
                        onChanged: (v) => setState(() => app.setVolume(v)),
                        activeColor: _blue,
                      ),
                    ),
                  ]),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Voice.I.talk(['@P_genial', '@I_escuchaste', '@L_A']),
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const Text('Probar voz'),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: const Color(0xFFB42318),
                  side: const BorderSide(color: Color(0xFFE5B4B4), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _confirmReset,
                child: Text('Reiniciar progreso', style: nunito(16, color: const Color(0xFFB42318))),
              ),
              const SizedBox(height: 10),
            ]),
          ),
        ]),
      ),
    );
  }
}
