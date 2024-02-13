import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/sound_env.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

extension RectExtension on Rect {
  bool containsVector2(Vector2 vector) {
    // Adjust the condition to include the right and bottom edges
    return vector.x >= left && vector.x <= right && vector.y >= top && vector.y <= bottom;
  }

  bool containsNotVector2(Vector2 vector) {
    // Adjust the condition to include the right and bottom edges
    return !(vector.x >= left && vector.x <= right && vector.y >= top && vector.y <= bottom);
  }
}

SoundProps? currentSound;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  //await Flame.device.fullScreen();

  await SoundEnvironment.init();

  GameModel model = GameModel(Vector2(
    kGameConfiguration.tileMap.width,
    kGameConfiguration.tileMap.height,
  ));
  final game = GameVisualization(gameModel: model);
  runApp(EchoGardenApp(game: game));
}

class EchoGardenApp extends StatelessWidget {
  const EchoGardenApp({super.key, required this.game});

  final GameVisualization game;

  @override
  Widget build(BuildContext context) {
    screenSize.x = MediaQuery.of(context).size.width;
    screenSize.y = MediaQuery.of(context).size.height;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: GameWidget(game: game),
    );
  }
}
