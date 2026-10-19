import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/representation/graphics/tiles/growing_tile.dart';

class TreeTile extends GrowingTileSquare {
  // how this kind of tree grows (from the configuration); its energy decides
  // which of the images is shown
  final TreeSettings settings;

  TreeTile({
    required super.agent,
    required super.position,
    TreeSettings? settings,
    super.spriteFilenames = const [
      "tree-01.png",
      "tree-02.png",
      "tree-03.png",
      "tree-04.png",
    ],
  }) : settings = settings ?? kGameConfiguration.plant.tree;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await onModelChange();
  }

  @override
  Future<void> onModelChange() async {
    var minEnergy = settings.initialEnergy;
    var maxEnergy = settings.maxEnergy;
    var currentEnergy = agent.energy;
    setTileToShow(currentEnergy, minEnergy, maxEnergy);
  }
}

class FirTile extends TreeTile {
  FirTile({required super.agent, required super.position})
      : super(settings: kGameConfiguration.plant.fir, spriteFilenames: [
          "fir-01.png",
          "fir-02.png",
          "fir-03.png",
          "fir-04.png",
        ]);
}

class PineTile extends TreeTile {
  PineTile({required super.agent, required super.position})
      : super(settings: kGameConfiguration.plant.pine, spriteFilenames: [
          "pine-01.png",
          "pine-02.png",
          "pine-03.png",
          "pine-04.png",
        ]);
}
