import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/terraformer/plugins/terraform_air.dart';
import 'package:flutter_test/flutter_test.dart';

AirModel airAt(GameModel model, Cell cell) =>
    model.getAgentAtCell(cell, AirModel.staticLayerId) as AirModel;

List<AirModel> allAir(GameModel model) => model
    .getLayer(AirModel.staticLayerId)
    .getNonEmptyCellsAndAgents()
    .map((entry) => entry.value as AirModel)
    .toList();

double totalDust(GameModel model) {
  double sum = 0;
  for (AirModel air in allAir(model)) {
    sum += air.dust;
  }
  return sum;
}

// A small map where all the air is land air that never slows the wind down,
// so a test sees only the basic behavior: no breezes, no slowing down.
GameModel modelWithPlainAir() {
  final model = GameModel(width: 10, height: 10, seed: 1);
  for (AirModel air in allAir(model)) {
    model.remove(air);
    // a long pass, so the land never slows the wind down in these tests
    model.add(AirLandModel(gameModelRef: model, cell: air.cell)..nopCount = 1000000);
  }
  return model;
}

// Removes the ground of a cell, so a test can decide what lies there.
void clearGround(GameModel model, Cell cell) {
  for (String layerId in [
    PatchModel.staticLayerId,
    SeedableModel.staticLayerId,
    HeightAreaModel.staticLayerId,
  ]) {
    AgentModel? agent = model.getAgentAtCell(cell, layerId);
    if (agent != null) {
      model.remove(agent);
    }
  }
}

void makeWater(GameModel model, Cell cell) {
  clearGround(model, cell);
  model.add(WaterModel(gameModelRef: model, cell: cell));
}

void makeLand(GameModel model, Cell cell) {
  clearGround(model, cell);
  model.add(SoilModel(gameModelRef: model, cell: cell));
}

void makeMountain(GameModel model, Cell cell) {
  makeLand(model, cell);
  model.add(HeightAreaMediumModel(gameModelRef: model, cell: cell));
}

// Runs only the air: every air cell steps once, in any order.
void stepAir(GameModel model, int steps) {
  for (int i = 0; i < steps; i++) {
    for (AirModel air in allAir(model)) {
      air.step();
    }
  }
}

void main() {
  test('every cell has air', () {
    final model = GameModel(width: 10, height: 10, seed: 1);

    expect(allAir(model).length, 100);
  });

  test('every direction points to a direct neighbor', () {
    for (Direction direction in Direction.values) {
      expect(direction.step.x.abs() <= 1 && direction.step.y.abs() <= 1, isTrue);
      expect(direction.step == const Cell(0, 0), isFalse, reason: '$direction');
    }
    expect(Direction.values.length, 8);
  });

  test('the air starts calm', () {
    final model = modelWithPlainAir();

    expect(airAt(model, const Cell(3, 3)).windStrength, 0);
  });

  test('dust never goes below zero', () {
    final model = modelWithPlainAir();
    final air = airAt(model, const Cell(3, 3));

    air.addDust(2);
    air.addDust(-5);

    expect(air.dust, 0);
  });

  test('without wind the dust stays where it is', () {
    final model = modelWithPlainAir();
    airAt(model, const Cell(5, 5)).addDust(100);

    stepAir(model, 5);

    expect(airAt(model, const Cell(5, 5)).dust, 100);
    expect(airAt(model, const Cell(6, 5)).dust, 0);
  });

  test('the wind carries dust only in its direction', () {
    final model = modelWithPlainAir();
    for (AirModel air in allAir(model)) {
      air.windDirection = Direction.east;
      air.windStrength = 1;
    }
    airAt(model, const Cell(5, 5)).addDust(100);

    stepAir(model, 3);

    expect(airAt(model, const Cell(5, 5)).dust, lessThan(100));
    expect(airAt(model, const Cell(6, 5)).dust, greaterThan(0), reason: 'downwind');
    expect(airAt(model, const Cell(4, 5)).dust, 0, reason: 'upwind gets nothing');
    expect(airAt(model, const Cell(5, 4)).dust, 0, reason: 'sideways gets nothing');
  });

  test('the wind keeps the total amount of dust', () {
    final model = modelWithPlainAir();
    for (AirModel air in allAir(model)) {
      air.windDirection = Direction.southEast;
      air.windStrength = 1;
    }
    airAt(model, const Cell(2, 2)).addDust(50);
    airAt(model, const Cell(7, 3)).addDust(30);

    stepAir(model, 20);

    // dust that reaches the border stays there, nothing leaves the map
    expect(totalDust(model), closeTo(80, 0.0001));
  });

  test('every direction is closest to itself', () {
    for (Direction direction in Direction.values) {
      expect(Direction.closestTo(direction.unitX, direction.unitY), direction);
    }
  });

  test('calm air stays calm', () {
    final model = modelWithPlainAir();

    stepAir(model, 5);

    for (AirModel air in allAir(model)) {
      expect(air.windStrength, 0);
    }
  });

  test('an even wind over the whole map stays as it is', () {
    final model = modelWithPlainAir();
    for (AirModel air in allAir(model)) {
      air.windDirection = Direction.east;
      air.windStrength = 2;
    }

    stepAir(model, 10);

    final middle = airAt(model, const Cell(5, 5));
    expect(middle.windDirection, Direction.east);
    expect(middle.windStrength, closeTo(2, 0.0001));
  });

  test('a cell surrounded by wind takes on that wind', () {
    final model = modelWithPlainAir();
    const center = Cell(5, 5);
    for (Direction direction in Direction.values) {
      final neighbor = airAt(model, center + direction.step);
      neighbor.windDirection = Direction.south;
      neighbor.windStrength = 3;
    }
    final air = airAt(model, center);

    air.step();

    expect(air.windDirection, Direction.south);
    // a part of the way: 0 + (3 - 0) * windAdaptation
    expect(air.windStrength, closeTo(3 * 0.2, 0.0001));
  });

  test('a strong neighbor among calm ones only pulls a little', () {
    final model = modelWithPlainAir();
    const center = Cell(5, 5);
    final west = airAt(model, center + Direction.west.step);
    west.windDirection = Direction.east;
    west.windStrength = 8;
    final air = airAt(model, center);

    air.step();

    expect(air.windDirection, Direction.east);
    // the average around is 8 / 8 neighbors = 1, of which this cell takes 20 %
    expect(air.windStrength, closeTo(0.2, 0.0001));
  });

  test('a tree takes dust out of the air on its cell', () {
    final model = modelWithPlainAir();
    const cell = Cell(4, 4);
    // a tree needs no soil to clean the air, it only reads its own cell
    final tree = TreeModel(gameModelRef: model, cell: cell);
    airAt(model, cell).addDust(10);

    tree.step();

    expect(airAt(model, cell).dust, lessThan(10));
  });

  test('every cell gets the air that fits its ground', () {
    final model = GameModel(width: 40, height: 40, seed: 3);
    final kinds = <Type>{};
    for (AirModel air in allAir(model)) {
      Type? ground = model.groundTypeAt(air.cell);
      kinds.add(air.runtimeType);
      if (ground == BeachModel) {
        expect(air, isA<AirCoastModel>(), reason: '${air.cell}');
      } else if (ground == HeightAreaLowModel ||
          ground == HeightAreaMediumModel ||
          ground == HeightAreaHighModel) {
        expect(air, isA<AirMountainModel>(), reason: '${air.cell}');
      } else if (ground == SoilModel) {
        // at the foot of a real mountain (medium, high) the air makes an
        // updraft; next to low hills only it is plain land air
        bool nextToRealMountain = Direction.values.any((direction) {
          Type? neighbor = model.groundTypeAt(air.cell + direction.step);
          return neighbor == HeightAreaMediumModel || neighbor == HeightAreaHighModel;
        });
        if (nextToRealMountain) {
          expect(air, isA<AirFoothillModel>(), reason: '${air.cell}');
        } else {
          expect(air, isA<AirLandModel>(), reason: '${air.cell}');
        }
      } else {
        expect(air, isA<AirSeaModel>(), reason: '${air.cell}');
      }
    }
    expect(kinds, contains(AirSeaModel));
    expect(kinds, contains(AirLandModel));
  });

  test('the terraformer finds the direction towards the land', () {
    final model = GameModel(width: 10, height: 10, seed: 1);
    // water in the west, the beach in column 5, land in the east
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 10; x++) {
        if (x < 5) makeWater(model, Cell(x, y));
        if (x == 5) {
          clearGround(model, Cell(x, y));
          model.add(BeachModel(gameModelRef: model, cell: Cell(x, y)));
        }
        if (x > 5) makeLand(model, Cell(x, y));
      }
    }

    Direction? landward = TerraformAir.directionTowards(
        model, const Cell(5, 5), (ground) => ground == SoilModel);

    expect(landward, Direction.east);
  });

  test('without the searched ground there is no direction', () {
    final model = GameModel(width: 10, height: 10, seed: 1);
    for (int y = 0; y < 10; y++) {
      for (int x = 0; x < 10; x++) {
        makeWater(model, Cell(x, y));
      }
    }

    Direction? landward = TerraformAir.directionTowards(
        model, const Cell(5, 5), (ground) => ground == SoilModel);

    expect(landward, isNull);
  });

  test('the air over a beach blows towards the land, with the strength of its breeze', () {
    final model = modelWithPlainAir();
    final coast =
        AirCoastModel(gameModelRef: model, cell: const Cell(5, 5), landward: Direction.east);

    for (int i = 0; i < 50; i++) {
      coast.step();
      expect(coast.windDirection, Direction.east);
      expect(coast.windStrength, coast.breeze);
    }
  });

  test('the breeze changes smoothly: one small step at a time, within its limits', () {
    final model = modelWithPlainAir();
    final coast =
        AirCoastModel(gameModelRef: model, cell: const Cell(5, 5), landward: Direction.east);
    var config = kGameConfiguration.air.coast;
    double change = config.breezeChange * config.breezeMaxStrength;

    double before = coast.breeze;
    for (int i = 0; i < 500; i++) {
      coast.step();
      double difference = (coast.breeze - before).abs();
      // one step of change, or nothing at a limit
      expect(difference < 0.0001 || (difference - change).abs() < 0.0001, isTrue,
          reason: 'step $i: $before -> ${coast.breeze}');
      expect(coast.breeze, inInclusiveRange(0, config.breezeMaxStrength));
      before = coast.breeze;
    }
  });

  test('the breeze does not flicker: it keeps its direction for a run', () {
    final model = modelWithPlainAir();
    final coast =
        AirCoastModel(gameModelRef: model, cell: const Cell(5, 5), landward: Direction.east);
    var config = kGameConfiguration.air.coast;

    // count how often the breeze turns from rising to falling or back
    int turns = 0;
    int lastTrend = 0;
    double before = coast.breeze;
    const int steps = 1000;
    for (int i = 0; i < steps; i++) {
      coast.step();
      double difference = coast.breeze - before;
      before = coast.breeze;
      if (difference.abs() < 0.0001) continue; // at a limit
      int trend = difference > 0 ? 1 : -1;
      if (lastTrend != 0 && trend != lastTrend) turns++;
      lastTrend = trend;
    }

    // a turn can only happen when a run of at least breezeRunMin steps is over
    expect(turns, lessThanOrEqualTo(steps ~/ config.breezeRunMin));
  });

  test('a coast without land around is plain air and starts no breeze', () {
    final model = modelWithPlainAir();
    final coast = AirCoastModel(gameModelRef: model, cell: const Cell(5, 5), landward: null);

    for (int i = 0; i < 20; i++) {
      coast.step();
    }

    expect(coast.windStrength, 0);
  });

  test('the air at the foot of a mountain blows towards it, changing smoothly', () {
    final model = modelWithPlainAir();
    final foothill = AirFoothillModel(
        gameModelRef: model, cell: const Cell(5, 5), mountainward: Direction.south);
    var config = kGameConfiguration.air.foothill;
    double change = config.updraftChange * config.updraftMaxStrength;

    double before = foothill.updraft;
    for (int i = 0; i < 200; i++) {
      foothill.step();
      expect(foothill.windDirection, Direction.south);
      expect(foothill.windStrength, foothill.updraft);
      double difference = (foothill.updraft - before).abs();
      expect(difference < 0.0001 || (difference - change).abs() < 0.0001, isTrue);
      before = foothill.updraft;
    }
  });

  test('sea air loses half of its dust every step', () {
    final model = modelWithPlainAir();
    const seaCell = Cell(5, 5);
    model.remove(airAt(model, seaCell));
    final sea = AirSeaModel(gameModelRef: model, cell: seaCell);
    model.add(sea);
    sea.addDust(8);

    sea.step();

    expect(sea.dust, closeTo(4, 0.0001));
  });

  test('sea air first halves its dust, then takes dust from its neighbor', () {
    final model = modelWithPlainAir();
    const seaCell = Cell(5, 5);
    model.remove(airAt(model, seaCell));
    final sea = AirSeaModel(gameModelRef: model, cell: seaCell);
    model.add(sea);
    sea.addDust(4);
    // the western neighbor blows its dust onto the sea
    final land = airAt(model, const Cell(4, 5));
    land.setWind(Direction.east, 1);
    land.addDust(10);

    sea.step();

    double taken = 10 * kGameConfiguration.air.sea.windTransfer;
    expect(land.dust, closeTo(10 - taken, 0.0001));
    expect(sea.dust, closeTo(4 / 2 + taken, 0.0001));
  });

  test('a mountain slows the wind down', () {
    final model = modelWithPlainAir();
    const cell = Cell(5, 5);
    model.remove(airAt(model, cell));
    final mountainAir = AirMountainModel(gameModelRef: model, cell: cell);
    model.add(mountainAir);
    mountainAir.windDirection = Direction.east;
    mountainAir.windStrength = 2;

    mountainAir.step();

    // the calm neighbors pull it to 2 - 2 * windAdaptation, the mountain then
    // keeps only mountainWindDamping of it
    double expected = (2 - 2 * kGameConfiguration.air.mountain.windAdaptation) *
        kGameConfiguration.air.mountain.windDamping;
    expect(mountainAir.windStrength, closeTo(expected, 0.0001));
  });

  test('land air slows the wind down when it does not let it pass', () {
    final model = modelWithPlainAir();
    const cell = Cell(5, 5);
    model.remove(airAt(model, cell));
    final land = AirLandModel(gameModelRef: model, cell: cell);
    model.add(land);
    // all neighbors with the same wind, so adapting does not change it
    for (AirModel air in allAir(model)) {
      air.setWind(Direction.east, 2);
    }
    land.nopCount = 0;

    land.step();

    expect(land.windStrength, closeTo(2 * kGameConfiguration.air.land.windDamping, 0.0001));
  });

  test('land air lets the wind pass while its nopCount runs, and counts down', () {
    final model = modelWithPlainAir();
    const cell = Cell(5, 5);
    model.remove(airAt(model, cell));
    final land = AirLandModel(gameModelRef: model, cell: cell);
    model.add(land);
    for (AirModel air in allAir(model)) {
      air.setWind(Direction.east, 2);
    }
    land.nopCount = 3;

    land.step();

    expect(land.windStrength, closeTo(2, 0.0001), reason: 'not slowed down');
    expect(land.nopCount, 2);
  });

  test('the nopCount of land air stays between 0 and gustMaxSteps', () {
    final model = modelWithPlainAir();
    const cell = Cell(5, 5);
    model.remove(airAt(model, cell));
    final land = AirLandModel(gameModelRef: model, cell: cell);
    model.add(land);
    bool passedSometimes = false;

    for (int i = 0; i < 2000; i++) {
      land.step();
      expect(land.nopCount, inInclusiveRange(0, kGameConfiguration.air.land.gustMaxSteps));
      if (land.nopCount > 0) passedSometimes = true;
    }

    expect(passedSometimes, isTrue);
  });
}
