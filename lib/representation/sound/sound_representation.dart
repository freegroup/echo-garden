import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/representation/representation.dart';
import 'package:echo_garden/representation/sound/sound_env.dart';
import 'package:echo_garden/representation/sound/engine/sound_backend_soloud.dart';
import 'package:echo_garden/representation/sound/engine/sound_listener.dart';
import 'package:echo_garden/representation/sound/engine/sound_manager.dart';
import 'package:echo_garden/representation/sound/engine/sound_source.dart';
import 'package:flame/components.dart';

/// Makes the model audible around the player.
///
/// The sounds are computed fresh every frame from the model, so this
/// representation needs no model events.
///
/// The steps already go through the SoundManager (sound in space: direction,
/// distance, dull from behind). Ocean, forest and wind still use the older
/// SoundEnvironment.
class SoundRepresentation extends Representation {
  // sounds are heard up to this distance, in cells
  static const int _maxRadiusCells = 7;

  // made when the representation wakes up for the first time, because the
  // audio engine has to be ready by then
  SoundManager? _sounds;
  SoundSource? _steps;

  // where the player was in the last frame, to hear whether it really moves
  late Pos _lastPlayerPosition;

  SoundRepresentation(super.worldView, super.player) {
    _lastPlayerPosition = player.position;
  }

  @override
  void wake() {
    super.wake();
    if (_sounds == null) {
      _sounds = SoundManager(
        backend: SoLoudSoundBackend(),
        listener: SoundListener(position: player.position),
      );
      _steps = SoundSource(asset: 'assets/audio/steps-grass.mp3', position: player.position);
      _sounds!.add(_steps!);
    }
  }

  @override
  void syncAll() {
    // nothing to do: update() computes everything from the current model
  }

  @override
  void sleep() {
    super.sleep();
    SoundEnvironment.stopAll();
    _steps?.volume = 0;
    _sounds?.update();
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

    _updateSteps(dt);
    _sounds?.update();
  }

  // The steps are heard while the player really moves (not when it walks
  // against the coast), a little ahead in the walking direction: so they come
  // from where the player goes, from the left when it goes left, dull from
  // behind when it goes south.
  void _updateSteps(double dt) {
    final sounds = _sounds;
    final steps = _steps;
    if (sounds == null || steps == null) return;

    Pos moved = player.position - _lastPlayerPosition;
    _lastPlayerPosition = player.position;

    sounds.listener.position = player.position;
    if (dt > 0) {
      sounds.listener.velocity = Vector2(moved.x / dt, moved.y / dt);
    }

    if (moved.x == 0 && moved.y == 0) {
      steps.volume = 0;
      return;
    }

    Vector2 direction = Vector2(moved.x.toDouble(), moved.y.toDouble()).normalized();
    double ahead = kGameConfiguration.sounds.steps.ahead * kGameConfiguration.grid.gridWidth;
    steps.position = player.position + Pos((direction.x * ahead).round(), (direction.y * ahead).round());
    // the steps go along with the player
    steps.velocity = sounds.listener.velocity.clone();
    steps.volume = kGameConfiguration.sounds.steps.volume;
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
        var wind = worldView.windAt(Cell(listenerCell.x + dx, listenerCell.y + dy));
        if (wind != null) {
          sum += wind.strength;
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
    Cell? nearestCell = worldView.nearestCellOf(
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
      aggregatedEnergy += worldView.energyAround(
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
