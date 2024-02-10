import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// Define an extension on Rect
/*
extension RectExtension on Rect {
  bool containsVector2(Vector2 vector) {
    return contains(Offset(vector.x, vector.y));
  }
}
*/
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();

  GameModel gameModel =
      GameModel(Vector2(kGameConfiguration.tileMap.width, kGameConfiguration.tileMap.height));
  final game = GameVisualization(gameModel: gameModel);
  runApp(EchoGardenApp(game: game));
}

class EchoGardenApp extends StatelessWidget {
  const EchoGardenApp({super.key, required this.game});

  final GameVisualization game;

  @override
  Widget build(BuildContext context) {
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
