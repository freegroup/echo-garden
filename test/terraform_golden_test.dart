import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flutter_test/flutter_test.dart';

// A fingerprint of everything the terraformer makes: per cell the types on
// the ground layers and of the air, and the direction of the coast and
// foothill air. FNV-1a over the type names, so it is the same on every run.
int terrainFingerprint(GameModel model) {
  int hash = 0x811c9dc5;
  void add(String text) {
    for (int unit in text.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
  }

  for (int x = 0; x < model.width; x++) {
    for (int y = 0; y < model.height; y++) {
      Cell cell = Cell(x, y);
      for (String layerId in [
        PatchModel.staticLayerId,
        SeedableModel.staticLayerId,
        HeightAreaModel.staticLayerId,
        AirModel.staticLayerId,
      ]) {
        add('${model.getAgentAtCell(cell, layerId)?.runtimeType};');
      }
      AgentModel? air = model.getAgentAtCell(cell, AirModel.staticLayerId);
      if (air is AirCoastModel) add('${air.landward};');
      if (air is AirFoothillModel) add('${air.mountainward};');
    }
  }
  return hash;
}

// The fingerprints of the maps the terraformer made before it was split into
// plugins. Splitting it must not change any map.
const Map<int, int> goldenFingerprints = {
  0: 420104653,
  1: 2972355515,
  2: 3982952587,
  3: 1030959847,
  4: 1885629984,
};

void main() {
  test('the terraformer makes the same maps as before', () {
    for (int seed = 0; seed < 5; seed++) {
      final model = GameModel(
          width: kGameConfiguration.grid.mapWidth,
          height: kGameConfiguration.grid.mapHeight,
          seed: seed);
      expect(terrainFingerprint(model), goldenFingerprints[seed], reason: 'seed $seed');
    }
  });
}
