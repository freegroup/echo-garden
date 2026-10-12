import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:flame/components.dart';

class MaskedTileSquare extends AgentVisualization {
  late final Sprite sprite;
  late final Sprite baseLayerSprite; // Assume this is your base layer
  final String spriteFilename; // List of sprite filenames for the top layer
  final String baseLayerFilename; // List of sprite filenames for the base layer

  final Paint _paint = Paint()..isAntiAlias = false;

  // Flags for rounding corners
  bool roundTopLeft = false;
  bool roundTopRight = false;
  bool roundBottomLeft = false;
  bool roundBottomRight = false;
  final double borderRadius;

  MaskedTileSquare({
    required super.agentModel,
    required this.spriteFilename,
    required this.baseLayerFilename,
    this.borderRadius = 20.0, // Default radius for corners
    super.anchor = Anchor.topLeft,
    required super.position,
  }) : super(size: Vector2.all(kGameConfiguration.world.tileSize));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load(spriteFilename);
    baseLayerSprite = await Sprite.load(baseLayerFilename);
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    // Render the base layer sprite
    baseLayerSprite.render(canvas, size: size, overridePaint: _paint);

    // Prepare the path for clipping with selective rounded corners
    Path path = Path();

    // Define corner radii based on boolean flags
    Radius topLeftRadius = Radius.circular(roundTopLeft ? borderRadius : 0);
    Radius topRightRadius = Radius.circular(roundTopRight ? borderRadius : 0);
    Radius bottomLeftRadius = Radius.circular(roundBottomLeft ? borderRadius : 0);
    Radius bottomRightRadius = Radius.circular(roundBottomRight ? borderRadius : 0);

    // Create a rounded rectangle with individual corner radii
    RRect rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.x, size.y),
      topLeft: topLeftRadius,
      topRight: topRightRadius,
      bottomRight: bottomRightRadius,
      bottomLeft: bottomLeftRadius,
    );

    // Clip the canvas to the rounded rectangle
    path.addRRect(rrect);
    canvas.clipPath(path);

    // Render the top layer sprite within the clipped area
    sprite.render(canvas, size: size, overridePaint: _paint);

    canvas.restore();
  }

  // Method to update corner rounding flags
  void setCornerRounding({bool? topLeft, bool? topRight, bool? bottomLeft, bool? bottomRight}) {
    roundTopLeft = topLeft ?? roundTopLeft;
    roundTopRight = topRight ?? roundTopRight;
    roundBottomLeft = bottomLeft ?? roundBottomLeft;
    roundBottomRight = bottomRight ?? roundBottomRight;
  }
}
