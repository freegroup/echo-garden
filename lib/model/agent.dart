import 'dart:ui';

import 'package:echo_garden/model/intvector2.dart';
import 'package:echo_garden/model/simulator.dart';

import 'package:echo_garden/model/scheduler/base.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

abstract class Agent extends PositionComponent {
  final BaseScheduler scheduler;
  late final Paint paint;

  late IntVector2 _cell;

  Agent({required this.scheduler, x, y, cell}) {
    _cell = cell ?? IntVector2(x ?? 0, y ?? 0);
    paint = Paint();
    paint
      ..style = PaintingStyle.fill // Draw only the fill, no stroke
      ..isAntiAlias = false; // Optional: Set to false if you want to disable anti-aliasing

    scheduler.add(this);
  }

  Simulator get model => scheduler.model;

  // Public getter for _cell
  IntVector2 get cell => _cell;

  // Public setter for _cell that also updates the position
  set cell(IntVector2 value) {
    _cell = value;
    Vector2 newCellSize = Vector2(model.size.x / model.width, model.size.y / model.height);
    resize(model.size, newCellSize);
  }

  void preStep() {
    // called before the step is executed
  }

  void step();

  void postStep() {
    // after the step has executed
  }

  void die() {
    scheduler.remove(this);
  }

  void resize(Vector2 gameSize, Vector2 newCellSize) {
    size = newCellSize;
    position = Vector2(_cell.x * size.x, _cell.y * size.y);
    anchor = Anchor.topLeft;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), paint);
  }

  @override
  String toString() => 'Agent(cell: $_cell , model: $scheduler)';
}
