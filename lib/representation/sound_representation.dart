import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/representation/representation.dart';
import 'package:echo_garden/representation/sound_env.dart';
import 'package:echo_garden/strategy/base.dart';

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
    Pos listener = player.position;
    Cell listenerCell = listener.cell;

    _adjustNearestSound(listener, listenerCell, PatchModel.staticLayerId, BeachModel, Sound.ocean,
        kGameConfiguration.sounds.ocean.volume);

    double maxPossibleEnergy =
        kGameConfiguration.plant.tree.maxEnergy * (_maxRadiusCells * _maxRadiusCells - 1);
    _adjustAggregatedSound(
      listenerCell,
      PlantModel.staticLayerId,
      [TreeModel, FirModel, PineModel], // the forest: oaks, firs and pines
      200,
      maxPossibleEnergy,
      Sound.blackForest,
      kGameConfiguration.sounds.forest.volume,
    );

    _adjustWindSound(listenerCell);
  }

  // The stronger the wind around the listener, the louder the wind sound.
  // The wind of the listener's cell and its neighbors is averaged, so the
  // sound does not jump when the listener crosses into the next cell.
  void _adjustWindSound(Cell listenerCell) {
    int radius = kGameConfiguration.sounds.wind.radius;
    double sum = 0;
    int count = 0;
    for (int dx = -radius; dx <= radius; dx++) {
      for (int dy = -radius; dy <= radius; dy++) {
        AgentModel? air = model.getAgentAtCell(
            Cell(listenerCell.x + dx, listenerCell.y + dy), AirModel.staticLayerId);
        if (air is AirModel) {
          sum += air.windStrength;
          count++;
        }
      }
    }
    if (count == 0) {
      SoundEnvironment.stop(Sound.wind);
      return;
    }

    double averageWind = sum / count;
    double volume = (averageWind / kGameConfiguration.sounds.wind.fullStrength).clamp(0.0, 1.0) *
        kGameConfiguration.sounds.wind.volume;
    if (volume <= 0) {
      SoundEnvironment.stop(Sound.wind);
      return;
    }
    SoundEnvironment.loop(Sound.wind, volume);
  }

  // The nearer the closest agent of the given type, the louder the sound, up
  // to [maxVolume] right next to it.
  void _adjustNearestSound(Pos listener, Cell listenerCell, String layerId, Type agentType,
      Sound sound, double maxVolume) {
    Cell? nearestCell = _strategy.getNearestCellForAgentTypeOnLayer(
      cell: listenerCell,
      type: agentType,
      radius: _maxRadiusCells,
      layerId: layerId,
    );
    if (nearestCell == null) {
      SoundEnvironment.stop(sound);
      return;
    }

    double distanceInCells = nearestCell.center.distanceTo(listener) / kGameConfiguration.grid.gridWidth;
    double distance = distanceInCells.clamp(0, _maxRadiusCells.toDouble());
    double volume = (1 - (distance / _maxRadiusCells)) * maxVolume;
    SoundEnvironment.loop(sound, volume);
  }

  // The more energy the agents of the given types have around the listener,
  // the louder the sound, up to [maxVolume].
  void _adjustAggregatedSound(Cell listenerCell, String layerId, List<Type> agentTypes,
      double energyMinLevel, double energyMaxLevel, Sound sound, double maxVolume) {
    double aggregatedEnergy = 0;
    for (Type agentType in agentTypes) {
      aggregatedEnergy += _strategy.getAggregatedEnergyForAgentTypeOnLayer(
        cell: listenerCell,
        type: agentType,
        radius: _maxRadiusCells,
        layerId: layerId,
      );
    }
    if (aggregatedEnergy <= energyMinLevel) {
      SoundEnvironment.stop(sound);
      return;
    }

    aggregatedEnergy = aggregatedEnergy.clamp(energyMinLevel, energyMaxLevel);
    double volume =
        (aggregatedEnergy - energyMinLevel) / (energyMaxLevel - energyMinLevel) * maxVolume;
    SoundEnvironment.loop(sound, volume);
  }
}
