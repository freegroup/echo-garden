import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/representation/sound/engine/sound_backend.dart';
import 'package:echo_garden/representation/sound/engine/sound_manager.dart';
import 'package:echo_garden/representation/sound/engine/sound_source.dart';
import 'package:echo_garden/representation/sound/engine/sound_spatializer.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

final space = kGameConfiguration.sounds.space;

// a source at full volume, x and y in cells relative to the listener
SoundSource sourceAt(double x, double y, {DistanceModel model = DistanceModel.inverse}) {
  return SoundSource(
    asset: 'test.mp3',
    distanceModel: model,
    refDistance: 1,
    maxDistance: 10,
    rolloff: 1,
  )
    ..relativePosition = Vector2(x, y)
    ..volume = 1;
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
      SoundMix mix = spatialize(sourceAt(1, 0));
      expect(mix.pan, closeTo(1, 0.0001));
      expect(mix.cutoff, closeTo(space.frontCutoff, 0.01));
      expect(mix.speed, closeTo(1, 0.0001));
    });

    test('a source to the west is heard in the left ear', () {
      expect(spatialize(sourceAt(-1, 0)).pan, closeTo(-1, 0.0001));
    });

    test('a source to the north is in front: both ears, clear, normal pitch', () {
      SoundMix mix = spatialize(sourceAt(0, -1));
      expect(mix.pan, closeTo(0, 0.0001));
      expect(mix.cutoff, closeTo(space.frontCutoff, 0.01));
      expect(mix.speed, closeTo(1, 0.0001));
    });

    test('a source to the south is behind: both ears, dull and lower', () {
      SoundMix mix = spatialize(sourceAt(0, 1));
      expect(mix.pan, closeTo(0, 0.0001));
      expect(mix.cutoff, closeTo(space.rearCutoff, 0.01));
      expect(mix.speed, closeTo(1 - space.rearPitchDrop, 0.0001));
    });

    test('a source to the south-east is right of the middle and half dull', () {
      SoundMix mix = spatialize(sourceAt(1, 1));
      expect(mix.pan, closeTo(0.7071, 0.001));
      expect(mix.cutoff, lessThan(space.frontCutoff));
      expect(mix.cutoff, greaterThan(space.rearCutoff));
    });

    test('a source right at the listener is heard in front at its own volume', () {
      SoundMix mix = spatialize(sourceAt(0, 0)..volume = 0.4);
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
      double near = spatialize(sourceAt(1, 0)).volume;
      double far = spatialize(sourceAt(4, 0)).volume;
      expect(far, lessThan(near));
    });
  });

  group('Doppler', () {
    test('without motion the pitch stays', () {
      expect(dopplerShift(sourceAt(5, 0)), closeTo(1, 0.0001));
    });

    test('a source that comes closer sounds higher, one that goes away lower', () {
      SoundSource coming = sourceAt(5, 0)..relativeVelocity = Vector2(-20, 0);
      SoundSource going = sourceAt(5, 0)..relativeVelocity = Vector2(20, 0);
      expect(dopplerShift(coming), greaterThan(1));
      expect(dopplerShift(going), lessThan(1));
    });

    test('a source coming closer at v sounds c / (c - v)', () {
      double v = 20;
      SoundSource coming = sourceAt(5, 0)..relativeVelocity = Vector2(-v, 0);
      double c = space.speedOfSound;
      expect(dopplerShift(coming), closeTo(c / (c - space.dopplerFactor * v), 0.0001));
    });

    test('a source that moves across, not closer, keeps its pitch', () {
      SoundSource across = sourceAt(5, 0)..relativeVelocity = Vector2(0, 20);
      expect(dopplerShift(across), closeTo(1, 0.0001));
    });
  });

  group('SoundManager', () {
    test('starts a loop for an added source and mixes it on update', () async {
      FakeBackend backend = FakeBackend();
      SoundManager manager = SoundManager(backend: backend);

      await manager.add(sourceAt(1, 0));
      manager.update();

      expect(backend.started, ['test.mp3']);
      expect(backend.mixes[0]!.pan, closeTo(1, 0.0001));
    });

    test('follows the source when it moves', () async {
      FakeBackend backend = FakeBackend();
      SoundManager manager = SoundManager(backend: backend);
      SoundSource source = sourceAt(1, 0);
      await manager.add(source);

      source.relativePosition = Vector2(-1, 0);
      manager.update();

      expect(backend.mixes[0]!.pan, closeTo(-1, 0.0001));
    });

    test('stops the voice of a removed source', () async {
      FakeBackend backend = FakeBackend();
      SoundManager manager = SoundManager(backend: backend);
      SoundSource source = sourceAt(1, 0);
      await manager.add(source);

      manager.remove(source);
      manager.update();

      expect(backend.stopped, [0]);
    });
  });
}
