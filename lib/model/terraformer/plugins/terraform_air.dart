import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// The air: one air object per cell. Its kind depends on the ground below,
/// which is final now: sea, beach, mountain, or flat land (at the foot of a
/// mountain or not). It does nothing before the model is filled.
class TerraformAir extends TerraformPlugin {
  @override
  void phase04Populate(GameModel model, TerrainMap map) {
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        model.add(_airFor(model, Cell(x, y)));
      }
    }
  }

  AirModel _airFor(GameModel model, Cell cell) {
    Type? ground = model.groundTypeAt(cell);

    if (ground == BeachModel) {
      return AirCoastModel(
        gameModelRef: model,
        cell: cell,
        landward: directionTowards(model, cell, _isLand),
      );
    }
    if (_isMountain(ground)) {
      return AirMountainModel(gameModelRef: model, cell: cell);
    }
    if (ground == SoilModel) {
      Direction? mountainward = directionTowards(model, cell, _makesUpdraft);
      // flat land right at the foot of a real mountain gets the updraft
      if (mountainward != null) {
        return AirFoothillModel(gameModelRef: model, cell: cell, mountainward: mountainward);
      }
      return AirLandModel(gameModelRef: model, cell: cell);
    }
    return AirSeaModel(gameModelRef: model, cell: cell);
  }

  bool _isMountain(Type? ground) {
    return ground == HeightAreaLowModel ||
        ground == HeightAreaMediumModel ||
        ground == HeightAreaHighModel;
  }

  // Only real mountains pull an updraft; low hills do not make wind.
  bool _makesUpdraft(Type? ground) {
    return ground == HeightAreaMediumModel || ground == HeightAreaHighModel;
  }

  bool _isLand(Type? ground) {
    return ground == SoilModel || _isMountain(ground);
  }

  /// The direction from [cell] towards the ground [isTarget] accepts: the
  /// directions of all such neighbors (as vectors of length 1) added up, then
  /// the direction closest to the sum. Null when no such ground is near.
  static Direction? directionTowards(
      GameModel model, Cell cell, bool Function(Type? ground) isTarget) {
    double sumX = 0;
    double sumY = 0;
    for (Direction direction in Direction.values) {
      if (isTarget(model.groundTypeAt(cell + direction.step))) {
        sumX += direction.unitX;
        sumY += direction.unitY;
      }
    }
    if (sumX == 0 && sumY == 0) {
      return null;
    }
    return Direction.closestTo(sumX, sumY);
  }
}
