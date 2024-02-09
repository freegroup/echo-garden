import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/objects/tile.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';

class GrassTile extends TileSquare {
  GrassTile({required super.agentModel, required Vector2 position})
      : super(position: position, spriteFilenames: ["grass-01.png", "grass-02.png"]);

  @override
  void onModelChange() {
    var model = agentModel as GrassModel;

    var minEnergy = kGameConfiguration.plant.grass.initialEnergy;
    var maxEnergy = kGameConfiguration.plant.grass.maxEnergy;
    var currentEnergy = model.energy;

    // First, normalize currentEnergy to a value between 0 and 1
    double normalizedEnergy = (currentEnergy - minEnergy) / (maxEnergy - minEnergy);

    spriteComponent?.setOpacity(normalizedEnergy);
  }
}
