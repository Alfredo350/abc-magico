import 'package:flutter/material.dart';

import '../core/data.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/voice.dart';
import '../widgets/ui.dart';
import 'menu.dart';
import 'parents.dart';

/// Pantalla de bienvenida: pide el nombre y si es niño o niña.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with Later {
  final TextEditingController _ctrl = TextEditingController();
  String _gender = '';
  bool _editing = true;

  @override
  void initState() {
    super.initState();
    _ctrl.text = app.name;
    _gender = app.gender;
    _editing = !app.hasName;
    later(700, _greet);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _name => _ctrl.text.trim();

  void _greet() {
    final n = _name;
    if (n.isEmpty || _editing) {
      Voice.I.say('¡Hola! Soy Lumi, el búho mago. ¿Cómo te llamas? Escribe tu nombre.');
      return;
    }
    final c = initialOf(n);
    // Todo el saludo con una sola voz (la del teléfono), para que no se mezclen voces.
    var t = '¡Hola, $n! ¡Qué lindo nombre! Soy Lumi, el búho mago. ';
    if (kLetters.contains(c)) {
      t += 'Tu nombre empieza con la ${kLetterNames[c]}, como ${wordFor(c).word.toLowerCase()}. ';
    }
    t += '¿Estás ${_gender == 'f' ? 'lista' : 'listo'} para jugar con las letras?';
    Voice.I.say(t);
  }

  void _save() {
    final n = cleanName(_name).trim();
    if (n.isEmpty) {
      Voice.I.sfx('bad');
      Voice.I.say('Primero escribe tu nombre, por favor.');
      return;
    }
    FocusScope.of(context).unfocus();
    final g = _gender.isEmpty ? 'm' : _gender;
    app.setKid(n, g);
    setState(() {
      _ctrl.text = n;
      _gender = g;
      _editing = false;
    });
    Voice.I.sfx('win');
    later(350, _greet);
  }

  Widget _genderBtn(String label, String g, String kid) {
    final on = _gender == g;
    return Expanded(
      child: Pressable(
        label: label,
        onTap: () {
          Voice.I.sfx('tap');
          setState(() => _gender = g);
          Voice.I.say(label);
        },
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: on
                ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9F3FF), Color(0xFFCFE3FF)])
                : null,
            color: on ? null : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: on ? const Color(0xFF2386F5) : const Color(0xFFE3E9F3), width: on ? 4 : 3),
            boxShadow: const [BoxShadow(color: Color(0xFFC9D6EE), offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(padding: const EdgeInsets.only(top: 6), child: Kid(kid, size: 44, joy: true)),
              const SizedBox(width: 6),
              Text(label, style: baloo(21, color: Pal.ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _askCard() {
    return WhiteCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('¿Cómo te llamas?', textAlign: TextAlign.center, style: baloo(22, color: Pal.ink)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            maxLength: 18,
            style: nunito(24, color: Pal.ink),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Escribe tu nombre',
              hintStyle: nunito(22, color: const Color(0xFF9AA6BC)),
              filled: true,
              fillColor: const Color(0xFFF5F9FF),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFBFD4F5), width: 3)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF2386F5), width: 3)),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          Text('Soy…', textAlign: TextAlign.center, style: nunito(15, color: Pal.muted)),
          const SizedBox(height: 8),
          Row(children: [_genderBtn('niño', 'm', 'boy_cap'), const SizedBox(width: 10), _genderBtn('niña', 'f', 'girl_bow')]),
          const SizedBox(height: 12),
          Opacity(
            opacity: _name.isEmpty ? 0.55 : 1,
            child: BigButton(text: '¡Listo!', g: Pal.green, onTap: _save, height: 56, fontSize: 23),
          ),
        ],
      ),
    );
  }

  Widget _knownCard() {
    final c = initialOf(app.name);
    return WhiteCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(
            onTap: () {
              Voice.I.sfx('tap');
              _greet();
            },
            label: 'Escuchar saludo',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text('¡Hola, ${app.name}!', textAlign: TextAlign.center, style: baloo(30, color: Pal.ink))),
                const SizedBox(width: 6),
                const Icon(Icons.volume_up_rounded, color: Color(0xFF1E6FE0), size: 24),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tu nombre empieza con la $c. ¿Estás ${app.isGirl ? 'lista' : 'listo'}?',
            textAlign: TextAlign.center,
            style: nunito(17, color: Pal.muted),
          ),
          const SizedBox(height: 8),
          Pressable(
            label: 'Cambiar nombre',
            onTap: () {
              Voice.I.sfx('tap');
              setState(() => _editing = true);
              Voice.I.say('Escribe tu nombre.');
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD6E0F0), width: 2)),
              child: Text('Cambiar nombre', style: nunito(15, color: const Color(0xFF1463D8))),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SceneScreen(
      sun: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                GlossyLetter('A', g: Pal.red, size: 66),
                GlossyLetter('B', g: Pal.blue, size: 66),
                GlossyLetter('C', g: Pal.green, size: 66),
              ],
            ),
            const RainbowText('Mágico', size: 42),
            const SizedBox(height: 6),
            WoodSign.text('Aprende jugando', size: 19),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Kid('girl_tails', size: 70, joy: true),
                Pressable(
                  label: 'Escuchar a Lumi',
                  onTap: () {
                    Voice.I.sfx('tap');
                    _greet();
                  },
                  child: const Owl(size: 110),
                ),
                const Kid('boy', size: 70),
              ],
            ),
            const SizedBox(height: 8),
            _editing ? _askCard() : _knownCard(),
            const Spacer(),
            BigButton(
              text: '¡A jugar!',
              g: Pal.yellow,
              darkText: true,
              icon: Icons.play_arrow_rounded,
              onTap: () {
                if (_editing && _name.isNotEmpty) _save();
                go(context, const MenuScreen());
              },
            ),
            const SizedBox(height: 10),
            Pressable(
              label: 'Zona de padres',
              onTap: () => go(context, const ParentGateScreen()),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xEBFFFFFF), borderRadius: BorderRadius.circular(22)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 18, color: Pal.ink),
                    const SizedBox(width: 8),
                    Text('Zona de padres', style: nunito(16, color: Pal.ink, weight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
