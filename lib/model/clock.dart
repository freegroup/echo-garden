import 'package:echo_garden/model/scheduler/base.dart';

/// The clocks of the model. Every object takes its steps on exactly one of
/// them (see `AgentModel.clock`).
enum ClockKind {
  ecology, // soil and plants, and new plants growing
  animal, // rabbits
  air, // the air: wind and fine dust
}

/// A clock with a fixed interval in simulation time. It collects the time
/// that passes and lets its objects take a step each time an interval is full.
class Clock {
  final ClockKind kind;
  final int intervalMs;

  /// Runs the objects of this clock (e.g. all of them, or a random share).
  final BaseScheduler scheduler;

  /// Runs after the objects of this clock have taken their step, e.g. new
  /// plants growing. Optional.
  final void Function()? afterStep;

  int _waitedMs = 0;

  Clock({
    required this.kind,
    required this.intervalMs,
    required this.scheduler,
    this.afterStep,
  });

  /// Lets [ms] of simulation time pass and takes as many steps as are due.
  void advance(int ms) {
    _waitedMs += ms;
    while (_waitedMs >= intervalMs) {
      _waitedMs -= intervalMs;
      step();
    }
  }

  /// One step of this clock, right now.
  void step() {
    scheduler.step();
    afterStep?.call();
  }
}
