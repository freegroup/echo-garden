import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flame/components.dart';

/// The player: an observer of the world.
///
/// The player is not part of the model. It decides where the camera looks and
/// where the listener stands, but does not change the world (yet). Input
/// devices set the direction; the session moves the player every frame.
class Player {
  // position in cells, e.g. (12.4, 7.9)
  Vector2 position;

  // where the player wants to go; x and y are between -1 and 1
  Vector2 direction = Vector2.zero();

  Player({required this.position});

  /// Creates the player on land, close to a beach. Of all such cells the one
  /// nearest to the middle of the map is taken, so the camera is not stuck at
  /// the border. Without any beach the player starts in the middle of the map.
  factory Player.onLandNearBeach(GameModel model) {
    MovementStrategy strategy = MovementStrategy(model: model);
    Vector2 middle = Vector2(model.width / 2, model.height / 2);

    List<Vector2> cells = [];
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        cells.add(Vector2(x.toDouble(), y.toDouble()));
      }
    }
    cells.sort((a, b) => a.distanceToSquared(middle).compareTo(b.distanceToSquared(middle)));

    for (Vector2 cell in cells) {
      bool isLand = model.getAgentAtCell(cell, SeedableModel.staticLayerId) != null;
      if (!isLand) {
        continue;
      }
      Vector2? beach = strategy.getNearestCellForAgentTypeOnLayer(
        cell: cell,
        radius: kGameConfiguration.player.startBeachDistance,
        type: BeachModel,
        layerId: PatchModel.staticLayerId,
      );
      if (beach != null) {
        // stand in the middle of the cell
        return Player(position: cell + Vector2.all(0.5));
      }
    }
    return Player(position: middle);
  }

  bool get isMoving => !direction.isZero();

  // Moves by the frame time dt. The player is outside of the model, so it may
  // use dt; the model itself works with fixed steps.
  void update(double dt) {
    position += direction * (kGameConfiguration.player.speed * dt);
  }
}
