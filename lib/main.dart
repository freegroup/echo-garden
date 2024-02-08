import 'package:echo_garden/game/game.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// Define an extension on Rect
extension RectExtension on Rect {
  bool containsVector2(Vector2 vector) {
    return contains(Offset(vector.x, vector.y));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  await Flame.device.fullScreen();

  final game = EchoGardenGame();
  runApp(EchoGardenApp(game: game));
}

class EchoGardenApp extends StatelessWidget {
  const EchoGardenApp({super.key, required this.game});

  final EchoGardenGame game;

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
