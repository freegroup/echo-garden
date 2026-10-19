import 'package:echo_garden/session/game_session.dart';
import 'package:echo_garden/representation/sound/sound_env.dart';
import 'package:echo_garden/screens/start_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_soloud/flutter_soloud.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SoundEnvironment.init();
  // the audio engine of the SoundManager
  await SoLoud.instance.init();

  // the model starts in its own isolate; the world is known once this returns
  final session = await GameSession.create();
  runApp(EchoGardenApp(session: session));
}

class EchoGardenApp extends StatelessWidget {
  final GameSession session;

  const EchoGardenApp({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Garden',
      // The app speaks German. The locale also tells the screen reader which
      // voice to use for the texts; without it Flutter assumes English and
      // TalkBack reads German words with an English voice.
      locale: const Locale('de', 'DE'),
      supportedLocales: const [Locale('de', 'DE')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StartScreen(session: session),
    );
  }
}
