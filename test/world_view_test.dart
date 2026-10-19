import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/messages.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/publisher.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flutter_test/flutter_test.dart';

// Every object, the ground and the wind of every cell must be the same in the
// model and in the view.
void expectSameWorld(GameModel model, WorldView view) {
  for (String layerId in model.layersMap.keys) {
    if (layerId == AirModel.staticLayerId) continue;
    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        AgentModel? inModel = model.getAgentAtCell(cell, layerId);
        AgentView? inView = view.agentAt(cell, layerId);
        if (inModel == null) {
          expect(inView, isNull, reason: '$layerId at $cell');
        } else {
          expect(inView, isNotNull, reason: '$layerId at $cell');
          expect(inView!.type, inModel.runtimeType, reason: '$layerId at $cell');
          expect(inView.cell, cell);
          expect(inView.energy, closeTo(inModel.energy, 0.000001), reason: '$layerId at $cell');
        }
      }
    }
  }

  for (int x = 0; x < model.width; x++) {
    for (int y = 0; y < model.height; y++) {
      Cell cell = Cell(x, y);
      expect(view.groundTypeAt(cell), model.groundTypeAt(cell), reason: 'ground at $cell');

      AirModel air = model.getAgentAtCell(cell, AirModel.staticLayerId) as AirModel;
      var wind = view.windAt(cell)!;
      expect(wind.direction, air.windDirection, reason: 'wind at $cell');
      // the wind travels as 32 bit floats
      expect(wind.strength, closeTo(air.windStrength, 0.0001), reason: 'wind at $cell');
    }
  }
}

void main() {
  test('the view built from the snapshot knows what the model knows', () {
    final model = GameModel(width: 40, height: 40, seed: 7);
    final view = WorldView(ModelPublisher(model).snapshot());

    expectSameWorld(model, view);
  });

  test('after many steps the view still knows what the model knows', () {
    final model = GameModel(width: 40, height: 40, seed: 7);
    final publisher = ModelPublisher(model);
    final view = WorldView(publisher.snapshot());

    // count the kinds of events, so the test does not pass without any change
    Map<Type, int> seen = {};
    for (int i = 0; i < 60; i++) {
      // 60 times 200 ms: every step of the air, several of the plants and rabbits
      model.advance(200);
      WorldUpdate update = publisher.takeUpdate();
      for (AgentEvent event in update.events) {
        seen[event.runtimeType] = (seen[event.runtimeType] ?? 0) + 1;
      }
      view.apply(update);
    }

    expect(seen[AgentMoved], greaterThan(0), reason: 'rabbits hopped');
    expect(seen[AgentAdded], greaterThan(0), reason: 'plants grew');
    expect(seen[AgentChanged], greaterThan(0), reason: 'energies changed');
    expectSameWorld(model, view);
  });

  test('the view answers the neighborhood questions as the model does', () {
    final model = GameModel(width: 40, height: 40, seed: 7);
    final publisher = ModelPublisher(model);
    final view = WorldView(publisher.snapshot());
    for (int i = 0; i < 20; i++) {
      model.advance(200);
      view.apply(publisher.takeUpdate());
    }
    MovementStrategy strategy = MovementStrategy(model: model);

    for (int x = 0; x < model.width; x++) {
      for (int y = 0; y < model.height; y++) {
        Cell cell = Cell(x, y);
        expect(
          view.nearestCellOf(cell: cell, radius: 3, type: BeachModel, layerId: PatchModel.staticLayerId),
          strategy.getNearestCellForAgentTypeOnLayer(
              cell: cell, radius: 3, type: BeachModel, layerId: PatchModel.staticLayerId),
          reason: 'nearest beach from $cell',
        );
        expect(
          view.energyAround(cell: cell, radius: 3, type: TreeModel, layerId: PlantModel.staticLayerId),
          closeTo(
              strategy.getAggregatedEnergyForAgentTypeOnLayer(
                  cell: cell, radius: 3, type: TreeModel, layerId: PlantModel.staticLayerId),
              0.000001),
          reason: 'trees around $cell',
        );
      }
    }
  });
}
