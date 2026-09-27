import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/state.dart';
import 'core/voice.dart';
import 'screens/welcome.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await app.load();
  await Voice.I.init().timeout(const Duration(seconds: 5), onTimeout: () {});
  runApp(const AbcMagicoApp());
}

class AbcMagicoApp extends StatefulWidget {
  const AbcMagicoApp({super.key});

  @override
  State<AbcMagicoApp> createState() => _AbcMagicoAppState();
}

class _AbcMagicoAppState extends State<AbcMagicoApp> with WidgetsBindingObserver {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startClock();
  }

  /// Cuenta los minutos de uso (para el panel de padres).
  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => app.tickMinute());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startClock();
    } else {
      _clock?.cancel();
      Voice.I.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ABC Mágico',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2386F5),
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const WelcomeScreen(),
    );
  }
}
