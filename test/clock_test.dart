import 'package:echo_garden/model/clock.dart';
import 'package:echo_garden/model/index.dart';
import 'package:echo_garden/model/scheduler/base.dart';
import 'package:flutter_test/flutter_test.dart';

// Counts how often its clock lets it run.
class CountingScheduler extends BaseScheduler {
  int steps = 0;

  CountingScheduler({required super.gameModelRef});

  @override
  void step() {
    steps++;
  }
}

void main() {
  final model = GameModel(width: 10, height: 10, seed: 1);

  test('a clock steps once per full interval', () {
    final scheduler = CountingScheduler(gameModelRef: model);
    final clock = Clock(kind: ClockKind.air, intervalMs: 200, scheduler: scheduler);

    clock.advance(199);
    expect(scheduler.steps, 0, reason: 'not yet a full interval');

    clock.advance(1);
    expect(scheduler.steps, 1);

    clock.advance(1000);
    expect(scheduler.steps, 6, reason: '1000 ms are five more intervals');
  });

  test('time left over counts for the next step', () {
    final scheduler = CountingScheduler(gameModelRef: model);
    final clock = Clock(kind: ClockKind.ecology, intervalMs: 1300, scheduler: scheduler);

    clock.advance(1000);
    clock.advance(1000);

    expect(scheduler.steps, 1, reason: '2000 ms: one step, 700 ms wait for the next');

    clock.advance(600);
    expect(scheduler.steps, 2);
  });

  test('after a step of the clock, its follow-up runs', () {
    int followUps = 0;
    final clock = Clock(
      kind: ClockKind.ecology,
      intervalMs: 100,
      scheduler: CountingScheduler(gameModelRef: model),
      afterStep: () => followUps++,
    );

    clock.advance(300);

    expect(followUps, 3);
  });

  test('the model counts the simulation time', () {
    final model = GameModel(width: 10, height: 10, seed: 1);

    model.advance(250);
    model.advance(750);

    expect(model.now, 1000);
  });

  test('every object knows its clock', () {
    final model = GameModel(width: 10, height: 10, seed: 1);
    final air = model.getAgentAtCell(const Cell(3, 3), AirModel.staticLayerId)!;

    expect(air.clock, ClockKind.air);
    expect(TreeModel(gameModelRef: model, cell: const Cell(1, 1)).clock, ClockKind.ecology);
  });
}
