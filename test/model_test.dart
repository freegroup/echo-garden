import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/movement_mode.dart';
import 'package:echo_garden/model/movement_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

GameModel newModel() =>
    GameModel(width: kGameConfiguration.grid.mapWidth, height: kGameConfiguration.grid.mapHeight);

List<RabbitAgent> rabbitsInGrid(GameModel model) => model
    .getLayer(ActorModel.staticLayerId)
    .getNonEmptyCellsAndAgents()
    .map((entry) => entry.value)
    .whereType<RabbitAgent>()
    .toList();

// Cells a rabbit can hop to, without a rabbit on them.
bool isFreeForRabbits(GameModel model, Cell cell) {
  return hopping.canEnterCell(model, cell) &&
      model.getAgentAtCell(cell, ActorModel.staticLayerId) == null;
}

List<Cell> freeLandCells(GameModel model) => model
    .getLayer(SeedableModel.staticLayerId)
    .getNonEmptyCellsAndAgents()
    .map((entry) => entry.key)
    .where((cell) => isFreeForRabbits(model, cell))
    .toList();

// A free cell whose eight neighbors are free for rabbits as well.
Cell openLandCell(GameModel model) {
  final strategy = MovementStrategy(model: model);
  return freeLandCells(model).firstWhere((cell) => strategy
      .getCellsAround(cell: cell)
      .every((neighbor) => isFreeForRabbits(model, neighbor)));
}

// Records the events the model sends, as a representation would receive them.
class RecordingListener implements ModelListener {
  final List<String> events = [];

  @override
  void onAgentAdded(AgentModel agent) => events.add('added');

  @override
  void onAgentRemoved(AgentModel agent) => events.add('removed');

  @override
  void onAgentMoved(AgentModel agent) => events.add('moved');

  @override
  void onAgentChanged(AgentModel agent) => events.add('changed');
}

void main() {
  test('listeners are told about added, moved and removed agents', () {
    final model = newModel();
    final listener = RecordingListener();
    model.addListener(listener);

    final rabbit = RabbitAgent(gameModelRef: model, cell: openLandCell(model), energy: 5);
    model.add(rabbit);
    model.move(rabbit, rabbit.cell);
    model.remove(rabbit);

    expect(listener.events, ['added', 'moved', 'removed']);
  });

  test('a removed listener gets no more events', () {
    final model = newModel();
    final listener = RecordingListener();
    model.addListener(listener);
    model.removeListener(listener);

    model.add(RabbitAgent(gameModelRef: model, cell: openLandCell(model), energy: 5));

    expect(listener.events, isEmpty);
  });

  test('a rabbit never hops onto ground its movement mode does not allow', () {
    final model = newModel();

    for (var i = 0; i < 30; i++) {
      model.step();
    }

    for (RabbitAgent rabbit in rabbitsInGrid(model)) {
      expect(hopping.canEnterCell(model, rabbit.cell), isTrue, reason: '${rabbit.cell}');
    }
  });

  test('a rabbit surrounded by high mountains stays where it is', () {
    final model = newModel();
    final start = openLandCell(model);
    for (Cell neighbor in MovementStrategy(model: model).getCellsAround(cell: start)) {
      // a neighbor may already be a low mountain, which rabbits can enter
      AgentModel? oldArea = model.getAgentAtCell(neighbor, HeightAreaModel.staticLayerId);
      if (oldArea != null) {
        model.remove(oldArea);
      }
      model.add(HeightAreaMediumModel(gameModelRef: model, cell: neighbor));
    }
    final rabbit = RabbitAgent(gameModelRef: model, cell: start, energy: 5);
    model.add(rabbit);

    for (var i = 0; i < 10; i++) {
      rabbit.step();
    }

    expect(rabbit.cell, start);
  });

  test('a rabbit without food starves', () {
    final model = newModel();
    // a fresh world has no plants yet, so there is nothing to eat
    final rabbit = RabbitAgent(gameModelRef: model, cell: openLandCell(model), energy: 0.5);
    model.add(rabbit);

    // energy only ever drops without food; it must reach zero eventually
    final maxSteps =
        (0.5 / kGameConfiguration.rabbit.energyPerStep.abs()).ceil() + 1;
    for (var i = 0; i < maxSteps && rabbitsInGrid(model).contains(rabbit); i++) {
      rabbit.step();
    }

    expect(rabbitsInGrid(model), isNot(contains(rabbit)));
  });

  test('a rabbit that gives birth keeps its place in the grid', () {
    final model = newModel();
    final before = rabbitsInGrid(model).length;
    final parent = RabbitAgent(gameModelRef: model, cell: openLandCell(model), energy: 30);
    model.add(parent);

    parent.step();

    expect(model.getAgentAtCell(parent.cell, ActorModel.staticLayerId), parent);
    expect(rabbitsInGrid(model).length, before + 2);
  });

  test('crowded rabbits never push each other out of the grid', () {
    final model = newModel();
    for (final cell in freeLandCells(model).take(2000)) {
      model.add(RabbitAgent(gameModelRef: model, cell: cell, energy: 9));
    }

    for (var i = 0; i < 10; i++) {
      model.step();
    }

    expect(rabbitsInGrid(model).length, model.rabbitCount);
  });
}
