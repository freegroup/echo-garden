import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/representation/graphics/game.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Debug view of the air: on every visible cell an arrow in the direction of
/// the wind. The stronger the wind, the less transparent the arrow; calm air
/// shows nothing.
///
/// This only reads the world view.
class AirDebugRenderer extends PositionComponent with HasGameReference<GameVisualization> {
  final WorldView worldView;

  // shown or not; switched with the D key (see GraphicsRepresentation)
  bool isShown = kGameConfiguration.debug.showWind;

  AirDebugRenderer({required this.worldView});

  static const double _tile = 64; // pixels per tile; must match world.tileSize

  // half the length of an arrow, and the size of its head, in pixels
  static const double _halfLength = _tile * 0.35;
  static const double _headSize = _tile * 0.15;

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;

  @override
  void render(Canvas canvas) {
    if (!isShown) return;

    Rect view = game.cameraComponent.visibleWorldRect;
    int x0 = (view.left / _tile).floor();
    int x1 = (view.right / _tile).ceil();
    int y0 = (view.top / _tile).floor();
    int y1 = (view.bottom / _tile).ceil();

    for (int y = y0; y <= y1; y++) {
      for (int x = x0; x <= x1; x++) {
        var wind = worldView.windAt(Cell(x, y));
        if (wind != null) {
          _drawArrow(canvas, x, y, wind.direction, wind.strength);
        }
      }
    }
  }

  void _drawArrow(Canvas canvas, int x, int y, Direction direction, double strength) {
    double fullStrength = kGameConfiguration.debug.windArrowFullStrength;
    double opacity = (strength / fullStrength).clamp(0.0, 1.0);
    if (opacity <= 0) {
      return;
    }
    _paint.color = Color.fromRGBO(20, 20, 50, opacity);

    // the arrow runs through the middle of the cell, in the wind direction
    Offset center = Offset((x + 0.5) * _tile, (y + 0.5) * _tile);
    Offset along = Offset(direction.unitX, direction.unitY);
    Offset across = Offset(-along.dy, along.dx);

    Offset tail = center - along * _halfLength;
    Offset tip = center + along * _halfLength;
    Offset headLeft = tip - along * _headSize + across * _headSize;
    Offset headRight = tip - along * _headSize - across * _headSize;

    canvas.drawLine(tail, tip, _paint);
    canvas.drawLine(tip, headLeft, _paint);
    canvas.drawLine(tip, headRight, _paint);
  }
}
