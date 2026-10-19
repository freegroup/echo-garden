import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/publisher.dart';
import 'package:echo_garden/session/player.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:echo_garden/model/movement_strategy.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

final int gridWidth = kGameConfiguration.grid.gridWidth;

// Removes everything from a cell, so a test can decide what lies there.
void clearCell(GameModel model, Cell cell) {
  for (String layerId in model.layersMap.keys) {
    AgentModel? agent = model.getAgentAtCell(cell, layerId);
    if (agent != null) {
      model.remove(agent);
    }
  }
}

void makeLand(GameModel model, Cell cell) {
  clearCell(model, cell);
  model.add(SoilModel(gameModelRef: model, cell: cell));
}

void makeWater(GameModel model, Cell cell) {
  clearCell(model, cell);
  model.add(WaterModel(gameModelRef: model, cell: cell));
}

// A small model where all of the first 10x10 cells are land.
GameModel landModel() {
  final model = GameModel(width: 10, height: 10);
  for (int x = 0; x < 10; x++) {
    for (int y = 0; y < 10; y++) {
      makeLand(model, Cell(x, y));
    }
  }
  return model;
}

// What the player knows about the model: built from its messages, after the
// test has decided what lies where.
WorldView viewOf(GameModel model) => WorldView(ModelPublisher(model).snapshot());

// Walks for the given time in small frames, like the game does.
void walk(Player player, double seconds) {
  const double frame = 1 / 60;
  for (double time = 0; time < seconds; time += frame) {
    player.update(frame);
  }
}

void main() {
  test('the player walks in the direction the input device set', () {
    final model = landModel();
    final player = Player(worldView: viewOf(model), position: const Cell(2, 2).center);
    final start = player.position;

    player.direction = Vector2(1, 0);
    player.update(1.0);

    expect(player.position, start + Pos(kGameConfiguration.player.speed, 0));
  });

  test('positions stay whole numbers, also for a joystick pushed halfway', () {
    final model = landModel();
    final player = Player(worldView: viewOf(model), position: const Cell(5, 5).center);
    final start = player.position;

    player.direction = Vector2(0.5, -0.25);
    player.update(1 / 60);

    // 3900 units per second * 1/60 s = 65 units at full speed
    expect(player.position, start + const Pos(33, -16));
  });

  test('a player without direction stands still', () {
    final model = landModel();
    final player = Player(worldView: viewOf(model), position: const Cell(5, 5).center);
    final start = player.position;

    player.update(1.0);

    expect(player.position, start);
  });

  test('the player cannot walk into the water', () {
    final model = landModel();
    makeWater(model, const Cell(6, 5));
    final player = Player(worldView: viewOf(model), position: const Cell(5, 5).center);

    player.direction = Vector2(1, 0);
    walk(player, 1.0);

    expect(player.position.cell, const Cell(5, 5));
  });

  test('the player cannot leave the map', () {
    final model = landModel();
    final player = Player(worldView: viewOf(model), position: const Cell(0, 0).center);

    player.direction = Vector2(-1, -1);
    walk(player, 1.0);

    expect(player.position.cell, const Cell(0, 0));
  });

  test('the player slides along the coast instead of getting stuck', () {
    final model = landModel();
    // a straight coast: water on the whole column 6
    for (int y = 0; y < 10; y++) {
      makeWater(model, Cell(6, y));
    }
    final player = Player(worldView: viewOf(model), position: const Cell(5, 2).center);

    // diagonal towards the water: right is blocked, down is free
    player.direction = Vector2(1, 1);
    walk(player, 0.5);

    expect(player.position.cell.x, 5, reason: 'stays on land');
    expect(player.position.cell.y, greaterThan(2), reason: 'slides down along the coast');
  });

  test('the player starts on walkable land near a beach', () {
    final model = GameModel(
        width: kGameConfiguration.grid.mapWidth, height: kGameConfiguration.grid.mapHeight);

    final player = Player.onLandNearBeach(viewOf(model));
    final cell = player.position.cell;

    expect(model.getAgentAtCell(cell, SeedableModel.staticLayerId), isNotNull,
        reason: 'the start cell must be land');
    expect(walking.canEnterCell(model, cell), isTrue, reason: 'the player must be able to walk');
    final beach = MovementStrategy(model: model).getNearestCellForAgentTypeOnLayer(
      cell: cell,
      radius: kGameConfiguration.player.startBeachDistance,
      type: BeachModel,
      layerId: PatchModel.staticLayerId,
    );
    expect(beach, isNotNull, reason: 'a beach must be close by');
  });
}
