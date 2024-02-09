import 'dart:math';
import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/game.dart';
import 'package:flame/components.dart';

class TileSquare extends AgentVisualization with HasGameReference<GameVisualization> {
  static final Vector2 spriteSize = Vector2.all(kGameConfiguration.tileMap.tileSpriteSize);
  late final Sprite sprite;
  SpriteComponent? spriteComponent;

  final List<String> spriteFilenames; // List of sprite filenames

  static final Paint _paint = Paint()..isAntiAlias = false;

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
    spriteComponent = SpriteComponent(sprite: sprite, size: size, paint: _paint);
    //spriteComponent.setOpacity(0.1);
    // Create and add the SpriteComponent
    add(spriteComponent!);
  }
}
