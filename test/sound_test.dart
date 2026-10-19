import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/pos.dart';
import 'package:echo_garden/sound/sound_backend.dart';
import 'package:echo_garden/sound/sound_listener.dart';
import 'package:echo_garden/sound/sound_manager.dart';
import 'package:echo_garden/sound/sound_source.dart';
import 'package:echo_garden/sound/sound_spatializer.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

final int cell = kGameConfiguration.grid.gridWidth;
final space = kGameConfiguration.sounds.space;

SoundListener listenerAtOrigin() => SoundListener(position: const Pos(0, 0));

// a source at full volume, x and y in cells
SoundSource sourceAt(double x, double y, {DistanceModel model = DistanceModel.inverse}) {
  return SoundSource(
    asset: 'test.mp3',
    position: Pos((x * cell).round(), (y * cell).round()),
    distanceModel: model,
    refDistance: 1,
    maxDistance: 10,
    rolloff: 1,
  )..volume = 1;
}

// remembers what the manager asks for, instead of playing anything
class FakeBackend implements SoundBackend {
  final List<String> started = [];
  final Map<int, SoundMix> mixes = {};
  final List<int> stopped = [];

  @override
  Future<int> startLoop(String asset) async {
    started.add(asset);
    return started.length - 1;
  }

  @override
  void setMix(int voice, SoundMix mix) => mixes[voice] = mix;

  @override
  void stop(int voice) => stopped.add(voice);
}

void main() {
  group('direction', () {
    test('a source to the east is heard in the right ear, clear', () {
      SoundMix mix = spatialize(listenerAtOrigin(), sourceAt(1, 0));
      expect(mix.pan, closeTo(1, 0.0001));
      expect(mix.cutoff, closeTo(space.frontCutoff, 0.01));
      expect(mix.speed, closeTo(1, 0.0001));
    });

    test('a source to the west is heard in the left ear', () {
      SoundMix mix = spatialize(listenerAtOrigin(), sourceAt(-1, 0));
      expect(mix.pan, closeTo(-1, 0.0001));
    });

    test('a source to the north is in front: both ears, clear, normal pitch', () {
      SoundMix mix = spatialize(listenerAtOrigin(), sourceAt(0, -1));
      expect(mix.pan, closeTo(0, 0.0001));
      expect(mix.cutoff, closeTo(space.frontCutoff, 0.01));
      expect(mix.speed, closeTo(1, 0.0001));
    });

    test('a source to the south is behind: both ears, dull and lower', () {
      SoundMix mix = spatialize(listenerAtOrigin(), sourceAt(0, 1));
      expect(mix.pan, closeTo(0, 0.0001));
      expect(mix.cutoff, closeTo(space.rearCutoff, 0.01));
      expect(mix.speed, closeTo(1 - space.rearPitchDrop, 0.0001));
    });

    test('a source to the south-east is right of the middle and half dull', () {
      SoundMix mix = spatialize(listenerAtOrigin(), sourceAt(1, 1));
      expect(mix.pan, closeTo(0.7071, 0.001));
      expect(mix.cutoff, lessThan(space.frontCutoff));
      expect(mix.cutoff, greaterThan(space.rearCutoff));
    });

    test('a source right at the listener is heard in front at its own volume', () {
      SoundMix mix = spatialize(listenerAtOrigin(), sourceAt(0, 0)..volume = 0.4);
      expect(mix.pan, 0);
      expect(mix.cutoff, closeTo(space.frontCutoff, 0.01));
      expect(mix.volume, closeTo(0.4, 0.0001));
    });
  });

  group('distance', () {
    test('inverse: full volume up to refDistance, half at twice of it', () {
      expect(distanceGain(sourceAt(0, 0), 0.5), closeTo(1, 0.0001));
      expect(distanceGain(sourceAt(0, 0), 1), closeTo(1, 0.0001));
      expect(distanceGain(sourceAt(0, 0), 2), closeTo(0.5, 0.0001));
    });

    test('linear: half way to maxDistance half the volume, silent at maxDistance', () {
      SoundSource source = sourceAt(0, 0, model: DistanceModel.linear);
      expect(distanceGain(source, 5.5), closeTo(0.5, 0.0001));
      expect(distanceGain(source, 10), closeTo(0, 0.0001));
      expect(distanceGain(source, 30), closeTo(0, 0.0001));
    });

    test('exponential: half the volume at twice refDistance', () {
      SoundSource source = sourceAt(0, 0, model: DistanceModel.exponential);
      expect(distanceGain(source, 2), closeTo(0.5, 0.0001));
    });

    test('the volume of a source falls off with its distance', () {
      double near = spatialize(listenerAtOrigin(), sourceAt(1, 0)).volume;
      double far = spatialize(listenerAtOrigin(), sourceAt(4, 0)).volume;
      expect(far, lessThan(near));
    });
  });

  group('Doppler', () {
    test('without motion the pitch stays', () {
      expect(dopplerShift(listenerAtOrigin(), sourceAt(5, 0)), closeTo(1, 0.0001));
    });

    test('a source that comes closer sounds higher, one that goes away lower', () {
      SoundSource coming = sourceAt(5, 0)..velocity = Vector2(-20.0 * cell, 0);
      SoundSource going = sourceAt(5, 0)..velocity = Vector2(20.0 * cell, 0);
      expect(dopplerShift(listenerAtOrigin(), coming), greaterThan(1));
      expect(dopplerShift(listenerAtOrigin(), going), lessThan(1));
    });

    test('a listener moving towards a source hears (c + v) / c', () {
      double v = 20;
      SoundListener listener = listenerAtOrigin()..velocity = Vector2(v * cell, 0);
      double c = space.speedOfSound;
      double f = space.dopplerFactor;
      expect(dopplerShift(listener, sourceAt(5, 0)), closeTo((c + f * v) / c, 0.0001));
    });

    test('a source that goes along with the listener keeps its pitch', () {
      Vector2 velocity = Vector2(3.0 * cell, 0);
      SoundListener listener = listenerAtOrigin()..velocity = velocity;
      SoundSource steps = sourceAt(0.5, 0)..velocity = velocity.clone();
      expect(dopplerShift(listener, steps), closeTo(1, 0.0001));
    });
  });

  group('SoundManager', () {
    test('starts a loop for an added source and mixes it on update', () async {
      FakeBackend backend = FakeBackend();
      SoundManager manager = SoundManager(backend: backend, listener: listenerAtOrigin());
      SoundSource source = sourceAt(1, 0);

      await manager.add(source);
      manager.update();

      expect(backend.started, ['test.mp3']);
      expect(backend.mixes[0]!.pan, closeTo(1, 0.0001));
    });

    test('follows the source when it moves', () async {
      FakeBackend backend = FakeBackend();
      SoundManager manager = SoundManager(backend: backend, listener: listenerAtOrigin());
      SoundSource source = sourceAt(1, 0);
      await manager.add(source);

      source.position = Pos(-cell, 0);
      manager.update();

      expect(backend.mixes[0]!.pan, closeTo(-1, 0.0001));
    });

    test('stops the voice of a removed source', () async {
      FakeBackend backend = FakeBackend();
      SoundManager manager = SoundManager(backend: backend, listener: listenerAtOrigin());
      SoundSource source = sourceAt(1, 0);
      await manager.add(source);

      manager.remove(source);
      manager.update();

      expect(backend.stopped, [0]);
    });
  });
}
