import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/sound_env.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/screens/start_screen.dart';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
// requeried to load for extensions
// ignore: unused_import
import 'package:echo_garden/utils/extensions.dart';


SoundProps? currentSound;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  //await Flame.device.fullScreen();

  await SoundEnvironment.init();

  GameModel model =
      GameModel(size: Vector2(kGameConfiguration.tileMap.width, kGameConfiguration.tileMap.height));
  final game = GameVisualization(gameModel: model);
  runApp(EchoGardenApp(game: game));
}

class EchoGardenApp extends StatelessWidget {
  final GameVisualization game;

  const EchoGardenApp({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Garden',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StartScreen(game: game),
    );
  }
}
