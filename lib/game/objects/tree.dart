import 'package:echo_garden/game/objects/growing_tile.dart';
import 'package:echo_garden/model/index.dart';

class TreeTile extends GrowingTileSquare {
  TreeTile({
    required super.agentModel,
    required super.position,
    super.spriteFilenames = const [
      "tree-01.png",
      "tree-02.png",
      "tree-03.png",
      "tree-04.png",
    ],
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await onModelChange();
  }

  @override
  Future<void> onModelChange() async {
    var model = agentModel as TreeModel;

    var minEnergy = model.settings.initialEnergy;
    var maxEnergy = model.settings.maxEnergy;
    var currentEnergy = model.energy;
    setTileToShow(currentEnergy, minEnergy, maxEnergy);
  }
}

class FirTile extends TreeTile {
  FirTile({required super.agentModel, required super.position})
      : super(spriteFilenames: [
          "fir-01.png",
          "fir-02.png",
          "fir-03.png",
          "fir-04.png",
        ]);
}

class PineTile extends TreeTile {
  PineTile({required super.agentModel, required super.position})
      : super(spriteFilenames: [
          "pine-01.png",
          "pine-02.png",
          "pine-03.png",
          "pine-04.png",
        ]);
}
