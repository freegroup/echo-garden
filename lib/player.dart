import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flame/components.dart';

/// The player: an observer of the world.
///
/// The player is not part of the model. It decides where the camera looks and
/// where the listener stands, but does not change the world (yet). Input
/// devices set the direction; the session moves the player every frame.
class Player {
  // the player reads the model to know where it can walk
  final GameModel model;

  // position in units, like everything in the world
  Pos position;

  // decides where the player can go
  MovementMode movementMode = walking;

  // Where the player wants to go; x and y are between -1 and 1. This is not a
  // coordinate, so it may have a fraction (a joystick can be pushed halfway).
  Vector2 direction = Vector2.zero();

  Player({required this.model, required this.position});

  /// Creates the player on land where it can walk, close to a beach. Of all such cells the one
  /// nearest to the middle of the map is taken, so the camera is not stuck at
  /// the border. Without any beach the player starts in the middle of the map.
  factory Player.onLandNearBeach(GameModel model) {
    MovementStrategy strategy = MovementStrategy(model: model);
    Cell middle = Cell(model.width ~/ 2, model.height ~/ 2);

    List<Cell> cells = [];
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        cells.add(Cell(x, y));
      }
    }
    cells.sort((a, b) => a.distanceTo(middle).compareTo(b.distanceTo(middle)));

    for (Cell cell in cells) {
      bool isLand = model.getAgentAtCell(cell, SeedableModel.staticLayerId) != null;
      if (!isLand || !walking.canEnterCell(model, cell)) {
        continue;
      }
      Cell? beach = strategy.getNearestCellForAgentTypeOnLayer(
        cell: cell,
        radius: kGameConfiguration.player.startBeachDistance,
        type: BeachModel,
        layerId: PatchModel.staticLayerId,
      );
      if (beach != null) {
        return Player(model: model, position: cell.center);
      }
    }
    return Player(model: model, position: middle.center);
  }

  bool get isMoving => !direction.isZero();

  // Moves by the frame time dt. The player is outside of the model, so it may
  // use dt; the model itself works with fixed steps. The distance is rounded,
  // because positions are whole numbers.
  void update(double dt) {
    double distance = kGameConfiguration.player.speed * dt;
    int dx = (direction.x * distance).round();
    int dy = (direction.y * distance).round();

    Pos target = position + Pos(dx, dy);
    if (_canStandOn(target)) {
      position = target;
      return;
    }

    // Blocked: try each direction alone, so the player slides along a coast
    // instead of getting stuck.
    Pos onlyX = position + Pos(dx, 0);
    if (dx != 0 && _canStandOn(onlyX)) {
      position = onlyX;
      return;
    }
    Pos onlyY = position + Pos(0, dy);
    if (dy != 0 && _canStandOn(onlyY)) {
      position = onlyY;
    }
  }

  bool _canStandOn(Pos pos) {
    return movementMode.canEnterCell(model, pos.cell);
  }
}
