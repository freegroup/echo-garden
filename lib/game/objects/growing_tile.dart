import 'dart:math';
import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/game/game.dart';
import 'package:flame/components.dart';

class GrowingTileSquare extends AgentVisualization with HasGameReference<GameVisualization> {
  static final Vector2 spriteSize = Vector2.all(kGameConfiguration.tileMap.tileSpriteSize);
  List<Sprite> sprites = [];
  SpriteComponent? spriteComponent;
  int currentSelectedSpriteIndex = 0;

  final List<String> spriteFilenames; // List of sprite filenames

  final Paint _paint = Paint()..isAntiAlias = false;
  final bool canFlipVertical;
  final bool canFlipHorizontal;
  GrowingTileSquare({
    required super.agentModel,
    required this.spriteFilenames, // Now expects a list of filenames
    super.anchor = Anchor.topLeft,
    required super.position,
    this.canFlipHorizontal = true,
    this.canFlipVertical = false,
  }) : super(
          size: Vector2.all(kGameConfiguration.world.tileSize),
        ) {
    assert(spriteFilenames.isNotEmpty, 'Sprite filenames list cannot be empty.');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Preload all sprites
    for (final filename in spriteFilenames) {
      final sprite = await Sprite.load(filename);
      sprites.add(sprite);
    }

    // Initially, you can display the first sprite or any specific one
    spriteComponent = SpriteComponent(sprite: sprites.first, size: size, paint: _paint);
    await add(spriteComponent!);
  }

  void setTileToShow(double currentValue, double minValue, double maxValue) {
    // Ensure currentValue falls within the provided range
    currentValue = currentValue.clamp(minValue, maxValue);

    // Normalize currentValue to a 0-1 range relative to minValue and maxValue
    double normalizedValue = (currentValue - minValue) / (maxValue - minValue);

    // Calculate the index of the sprite to display based on the normalized value
    int index = ((sprites.length - 1) * normalizedValue).round();
    if (sprites.isEmpty) return;
    index = index.clamp(0, sprites.length - 1);
    if (index == currentSelectedSpriteIndex) {
      return;
    }
    currentSelectedSpriteIndex = index;
    spriteComponent?.sprite = sprites[currentSelectedSpriteIndex];
    if (canFlipHorizontal && Random().nextBool()) spriteComponent?.flipHorizontallyAroundCenter();
    if (canFlipVertical && Random().nextBool()) spriteComponent?.flipVerticallyAroundCenter();
  }
}
