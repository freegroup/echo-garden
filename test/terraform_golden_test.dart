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

// The fingerprints of the maps the terraformer makes, so no change of the maps
// goes unnoticed. When a change of the maps is wanted (e.g. smoother coasts),
// look at the new maps and then set these numbers anew.
const Map<int, int> goldenFingerprints = {
  0: 3920837536,
  1: 188489727,
  2: 940826424,
  3: 1358751492,
  4: 3696442347,
};

void main() {
  test('the terraformer makes the maps it is known to make', () {
    for (int seed = 0; seed < 5; seed++) {
      final model = GameModel(
          width: kGameConfiguration.grid.mapWidth,
          height: kGameConfiguration.grid.mapHeight,
          seed: seed);
      expect(terrainFingerprint(model), goldenFingerprints[seed], reason: 'seed $seed');
    }
  });
}
