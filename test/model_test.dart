import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

GameModel newModel() => GameModel(
    size: Vector2(kGameConfiguration.tileMap.width, kGameConfiguration.tileMap.height));

List<RabbitAgent> rabbitsInGrid(GameModel model) => model
    .getLayer(ActorModel.staticLayerId)
    .getNonEmptyCellsAndAgents()
    .map((entry) => entry.value)
    .whereType<RabbitAgent>()
    .toList();

// Land cells without a rabbit on them.
List<Vector2> freeLandCells(GameModel model) => model
    .getLayer(SeedableModel.staticLayerId)
    .getNonEmptyCellsAndAgents()
    .map((entry) => entry.key)
    .where((cell) => model.getAgentAtCell(cell, ActorModel.staticLayerId) == null)
    .toList();

// A free land cell whose eight neighbors are free land as well.
Vector2 openLandCell(GameModel model) {
  final strategy = MovementStrategy(model: model);
  return freeLandCells(model).firstWhere((cell) =>
      strategy
              .getNeighborhood(
                  cell: cell, emptyCellsLookup: false, layerId: SeedableModel.staticLayerId)
              .length ==
          8 &&
      strategy.getNeighborhood(cell: cell, layerId: ActorModel.staticLayerId).length == 8);
}

void main() {
  test('a rabbit without food starves', () async {
    final model = newModel();
    // a fresh world has no plants yet, so there is nothing to eat
    final rabbit = RabbitAgent(gameModelRef: model, cell: openLandCell(model), energy: 0.5);
    await model.add(rabbit);

    // energy only ever drops without food; it must reach zero eventually
    final maxSteps =
        (0.5 / kGameConfiguration.rabbit.energyPerStep.abs()).ceil() + 1;
    for (var i = 0; i < maxSteps && rabbitsInGrid(model).contains(rabbit); i++) {
      await rabbit.step();
    }

    expect(rabbitsInGrid(model), isNot(contains(rabbit)));
  });

  test('a rabbit that gives birth keeps its place in the grid', () async {
    final model = newModel();
    final before = rabbitsInGrid(model).length;
    final parent = RabbitAgent(gameModelRef: model, cell: openLandCell(model), energy: 30);
    await model.add(parent);

    await parent.step();

    expect(model.getAgentAtCell(parent.cell, ActorModel.staticLayerId), parent);
    expect(rabbitsInGrid(model).length, before + 2);
  });

  test('crowded rabbits never push each other out of the grid', () async {
    final model = newModel();
    for (final cell in freeLandCells(model).take(2000)) {
      await model.add(RabbitAgent(gameModelRef: model, cell: cell, energy: 9));
    }

    for (var i = 0; i < 10; i++) {
      await model.step();
    }

    expect(rabbitsInGrid(model).length, model.rabbitCount);
  });
}
