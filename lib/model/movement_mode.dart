import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/cell.dart';
import 'package:echo_garden/model/game.dart';

/// A way of moving: walking, hopping, flying, ...
///
/// The movement mode alone decides where something can go. It only knows the
/// types of ground it gets along with (see the configuration).
class MovementMode {
  final String name;
  final List<Type> canEnter;

  const MovementMode({required this.name, required this.canEnter});

  bool canEnterCell(GameModel model, Cell cell) {
    Type? ground = model.groundTypeAt(cell);
    // outside of the map there is no ground
    if (ground == null) {
      return false;
    }
    return canEnter.contains(ground);
  }
}

// The movement modes of the game. Their lists are in the configuration.
final MovementMode walking =
    MovementMode(name: 'walking', canEnter: kGameConfiguration.movement.walking);
final MovementMode hopping =
    MovementMode(name: 'hopping', canEnter: kGameConfiguration.movement.hopping);
