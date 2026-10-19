import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/flat_water.dart';
import 'package:echo_garden/model/terraformer/terraform_plugin.dart';
import 'package:echo_garden/model/terraformer/terrain_map.dart';

/// The coast: beaches on the land at the water, flat water in front of them.
///
/// Some of the passes count the neighbors while they change cells, so their
/// result depends on the order (x outside, y inside) — it is kept as it is.
class TerraformCoast extends TerraformPlugin {
  @override
  void phase03Areas(TerrainMap map) {
    // soil at the water becomes beach
    _change(map, from: SoilModel, to: BeachModel, when: (cell) => _hasNeighbor(map, cell, WaterModel));

    // water at the beach becomes flat water
    _change(map, from: WaterModel, to: FlatWaterModel, when: (cell) => _hasNeighbor(map, cell, BeachModel));

    // flat water mostly surrounded by beach becomes beach
    _change(map,
        from: FlatWaterModel,
        to: BeachModel,
        when: (cell) => countNeighborGround(map, cell, BeachModel) > 5);

    // beach mostly surrounded by flat water becomes flat water
    _change(map,
        from: BeachModel,
        to: FlatWaterModel,
        when: (cell) => countNeighborGround(map, cell, FlatWaterModel) > 5);

    // water mostly surrounded by flat water becomes flat water
    _change(map,
        from: WaterModel,
        to: FlatWaterModel,
        when: (cell) => countNeighborGround(map, cell, FlatWaterModel) > 6);
  }

  // One pass over the map: every cell with the ground [from] for which [when]
  // holds gets the ground [to], right away.
  void _change(TerrainMap map,
      {required Type from, required Type to, required bool Function(Cell) when}) {
    for (int x = 0; x < map.width; x++) {
      for (int y = 0; y < map.height; y++) {
        Cell cell = Cell(x, y);
        if (map.groundAt(cell) == from && when(cell)) {
          map.setGround(cell, to);
        }
      }
    }
  }

  bool _hasNeighbor(TerrainMap map, Cell cell, Type ground) {
    return countNeighborGround(map, cell, ground) > 0;
  }
}
