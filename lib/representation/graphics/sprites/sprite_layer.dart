import 'package:flame/components.dart';
import 'package:flame/rendering.dart';

class SpriteLayer extends PositionComponent {
  SpriteLayer({required super.priority, Decorator? decorator}) {
    if (decorator != null) {
      this.decorator.addLast(decorator);
    }
  }
}
