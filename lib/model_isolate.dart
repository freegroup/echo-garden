import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/messages.dart';
import 'package:echo_garden/model/publisher.dart';
import 'package:echo_garden/representation/world_view.dart';

/// Runs the model in an isolate of its own, so its computing never holds up
/// the user interface, and keeps the world view up to date from its messages.
///
/// The model lives only in that isolate. It sends a snapshot first, then an
/// update after every step of its loop (see messages.dart).
class ModelIsolate {
  final Isolate _isolate;
  final ReceivePort _fromModel;

  /// What the user interface knows about the world.
  final WorldView worldView;

  ModelIsolate._(this._isolate, this._fromModel, this.worldView);

  /// Starts the model and waits for its snapshot.
  static Future<ModelIsolate> start({required int width, required int height}) async {
    ReceivePort fromModel = ReceivePort();
    Isolate isolate = await Isolate.spawn(
      _runModel,
      (toUi: fromModel.sendPort, width: width, height: height),
    );

    // The messages arrive in the order they were sent: first the snapshot,
    // then the updates. Each is taken in right away, so none can get lost.
    Completer<WorldView> ready = Completer();
    WorldView? worldView;
    fromModel.listen((message) {
      if (message is WorldSnapshot) {
        worldView = WorldView(message);
        ready.complete(worldView);
      } else if (message is WorldUpdate) {
        worldView!.apply(message);
      }
    });

    return ModelIsolate._(isolate, fromModel, await ready.future);
  }

  void stop() {
    _isolate.kill();
    _fromModel.close();
  }
}

// how often the model takes the time that has passed
const Duration _tick = Duration(milliseconds: 16);

// A longer pause (e.g. while the app was in the background) is shortened, so
// the world does not jump. Catching up comes with step 6.
const int _maxTickMs = 100;

/// The loop of the model isolate: the model runs in real time and sends what
/// happened after every step.
void _runModel(({SendPort toUi, int width, int height}) args) {
  GameModel model = GameModel(width: args.width, height: args.height);
  ModelPublisher publisher = ModelPublisher(model);
  args.toUi.send(publisher.snapshot());

  Stopwatch realTime = Stopwatch()..start();
  int lastMs = 0;

  Timer.periodic(_tick, (_) {
    int nowMs = realTime.elapsedMilliseconds;
    int ms = min(nowMs - lastMs, _maxTickMs);
    lastMs = nowMs;
    if (ms <= 0) return;

    model.advance(ms);
    WorldUpdate update = publisher.takeUpdate();
    if (update.events.isNotEmpty || update.wind != null) {
      args.toUi.send(update);
    }
  });
}
