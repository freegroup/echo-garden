import 'package:flame/components.dart';
import 'package:flame/rendering.dart';

class TileLayer extends PositionComponent {
  TileLayer({required super.priority, Decorator? decorator}) {
    if (decorator != null) {
      this.decorator.addLast(decorator);
    }
  }
}
