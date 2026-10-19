import 'package:echo_garden/session/model_isolate.dart';
import 'package:echo_garden/representation/world_view.dart';
import 'package:flutter_test/flutter_test.dart';

// counts what the world view hears
class CountingListener implements WorldViewListener {
  int added = 0;
  int removed = 0;
  int moved = 0;
  int changed = 0;

  @override
  void onAgentAdded(AgentView agent) => added++;

  @override
  void onAgentRemoved(AgentView agent) => removed++;

  @override
  void onAgentMoved(AgentView agent) => moved++;

  @override
  void onAgentChanged(AgentView agent) => changed++;
}

void main() {
  test('the model in its own isolate sends the world, then keeps it up to date', () async {
    ModelIsolate modelIsolate = await ModelIsolate.start(width: 40, height: 40);
    WorldView worldView = modelIsolate.worldView;
    expect(worldView.width, 40);
    expect(worldView.height, 40);

    CountingListener listener = CountingListener();
    worldView.addListener(listener);

    // the model runs in real time: within a few seconds rabbits hop and
    // energies change
    await Future.delayed(const Duration(seconds: 4));
    modelIsolate.stop();

    expect(listener.moved, greaterThan(0), reason: 'rabbits hopped');
    expect(listener.changed, greaterThan(0), reason: 'energies changed');
  });
}
