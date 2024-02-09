import 'dart:math';
import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/game.dart';
import 'package:flame/components.dart';

class TileSquare extends AgentVisualization with HasGameReference<GameVisualization> {
  static final Vector2 spriteSize = Vector2.all(kGameConfiguration.tileMap.tileSpriteSize);
  late final Sprite sprite;
  final List<String> spriteFilenames; // List of sprite filenames

  TileSquare({
    required super.agentModel,
    required this.spriteFilenames, // Now expects a list of filenames
    super.anchor = Anchor.topLeft,
    required super.position,
  }) : super(
          size: Vector2.all(kGameConfiguration.world.tileSize),
        ) {
    assert(spriteFilenames.isNotEmpty, 'Sprite filenames list cannot be empty.');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Randomly select a filename from the list
    final randomIndex = Random().nextInt(spriteFilenames.length);
    final selectedFilename = spriteFilenames[randomIndex];

    // Load the sprite using the selected filename
    sprite = await Sprite.load(selectedFilename);

    // Create and add the SpriteComponent
    add(SpriteComponent(sprite: sprite, size: size));
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..isAntiAlias = false;
    sprite.render(canvas, size: size, overridePaint: paint);
  }
}
