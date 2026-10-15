import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/representation/representation.dart';
import 'package:echo_garden/representation/sound_env.dart';
import 'package:echo_garden/strategy/base.dart';
import 'package:flame/components.dart';

/// Makes the model audible around the player.
///
/// The sounds are computed fresh every frame from the model, so this
/// representation needs no model events.
class SoundRepresentation extends Representation {
  // sounds are heard up to this distance, in cells
  static const int _maxRadiusCells = 7;

  late final MovementStrategy _strategy;

  SoundRepresentation(super.model, super.player) {
    _strategy = MovementStrategy(model: model);
  }

  @override
  void syncAll() {
    // nothing to do: update() computes everything from the current model
  }

  @override
  void sleep() {
    super.sleep();
    SoundEnvironment.stopAll();
  }

  @override
  void update(double dt) {
    Vector2 listener = player.position;
    Vector2 listenerCell = listener.clone()..floor();

    _adjustNearestSound(listener, listenerCell, PatchModel.staticLayerId, BeachModel, Sound.ocean);

    double maxPossibleEnergy =
        kGameConfiguration.plant.tree.maxEnergy * (_maxRadiusCells * _maxRadiusCells - 1);
    _adjustAggregatedSound(
      listenerCell,
      PlantModel.staticLayerId,
      TreeModel,
      200,
      maxPossibleEnergy,
      Sound.blackForest,
    );
  }

  // The nearer the closest agent of the given type, the louder the sound.
  void _adjustNearestSound(
      Vector2 listener, Vector2 listenerCell, String layerId, Type agentType, Sound sound) {
    Vector2? nearestCell = _strategy.getNearestCellForAgentTypeOnLayer(
      cell: listenerCell,
      type: agentType,
      radius: _maxRadiusCells,
      layerId: layerId,
    );
    if (nearestCell == null) {
      SoundEnvironment.stop(sound);
      return;
    }

    Vector2 cellCenter = nearestCell + Vector2.all(0.5);
    double distance = cellCenter.distanceTo(listener).clamp(0, _maxRadiusCells.toDouble());
    double volume = 1 - (distance / _maxRadiusCells);
    SoundEnvironment.loop(sound, volume);
  }

  // The more energy the agents of the given type have around the listener,
  // the louder the sound.
  void _adjustAggregatedSound(Vector2 listenerCell, String layerId, Type agentType,
      double energyMinLevel, double energyMaxLevel, Sound sound) {
    double aggregatedEnergy = _strategy.getAggregatedEnergyForAgentTypeOnLayer(
      cell: listenerCell,
      type: agentType,
      radius: _maxRadiusCells,
      layerId: layerId,
    );
    if (aggregatedEnergy <= energyMinLevel) {
      SoundEnvironment.stop(sound);
      return;
    }

    aggregatedEnergy = aggregatedEnergy.clamp(energyMinLevel, energyMaxLevel);
    double volume = (aggregatedEnergy - energyMinLevel) / (energyMaxLevel - energyMinLevel);
    SoundEnvironment.loop(sound, volume);
  }
}
