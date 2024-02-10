import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/objects/growing_tile.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flame/components.dart';

class TreeTile extends GrowingTileSquare {
  TreeTile({required super.agentModel, required Vector2 position})
      : super(position: position, spriteFilenames: [
          "tree-01.png",
          "tree-02.png",
          "tree-03.png",
          "tree-04.png",
        ]);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await onModelChange();
  }

  @override
  Future<void> onModelChange() async {
    var model = agentModel as TreeModel;

    var minEnergy = kGameConfiguration.plant.tree.initialEnergy;
    var maxEnergy = kGameConfiguration.plant.tree.maxEnergy;
    var currentEnergy = model.energy;
    setTileToShow(currentEnergy, minEnergy, maxEnergy);
  }
}
