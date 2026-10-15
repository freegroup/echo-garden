import 'dart:ui';

import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/game/agent.dart';
import 'package:echo_garden/model/actors/rabbit.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

// The images for one view. The side views look to the right; for the
// directions to the left the image is mirrored.
enum RabbitView {
  front('front', mirrored: false),
  frontRight('front-side', mirrored: false),
  right('side', mirrored: false),
  backRight('back-side', mirrored: false),
  back('back', mirrored: false),
  backLeft('back-side', mirrored: true),
  left('side', mirrored: true),
  frontLeft('front-side', mirrored: true);

  final String imageName;
  final bool mirrored;

  const RabbitView(this.imageName, {required this.mirrored});
}

const List<String> _furColors = ["brown", "grey"];

/// Shows a rabbit. It looks in the direction of its last hop.
class RabbitTile extends AgentVisualization {
  // Each rabbit keeps its fur color, even when its tile is created again
  // after it left the visible area.
  late final String _furColor;

  final Map<String, Sprite> _sprites = {};
  SpriteComponent? _spriteComponent;
  MoveEffect? _moveEffect;

  RabbitView _view = RabbitView.front;
  late Vector2 _lastCell;

  final Paint _paint = Paint()..isAntiAlias = false;

  RabbitTile({required super.agentModel, required super.position})
      : super(anchor: Anchor.topLeft, size: Vector2.all(kGameConfiguration.world.tileSize)) {
    _furColor = _furColors[agentModel.hashCode % _furColors.length];
    _lastCell = agentModel.cell.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (String imageName in ['front', 'front-side', 'side', 'back-side', 'back']) {
      _sprites[imageName] = await Sprite.load('rabbit-$_furColor-$imageName.png');
    }
    _spriteComponent = SpriteComponent(size: size, paint: _paint);
    await add(_spriteComponent!);
    _showView();
  }

  @override
  Future<void> onModelChange() async {
    final model = agentModel as RabbitAgent;

    Vector2 hop = model.cell - _lastCell;
    _lastCell = model.cell.clone();
    if (!hop.isZero()) {
      _view = _viewForHop(hop);
      _showView();
    }

    final targetPosition = model.cell * kGameConfiguration.world.tileSize;
    _moveEffect?.removeFromParent();
    _moveEffect = MoveEffect.to(
      targetPosition,
      EffectController(duration: 1.5, curve: Curves.easeInOut),
    );
    await add(_moveEffect!);
  }

  // y grows downwards: a hop with positive y comes towards the viewer.
  RabbitView _viewForHop(Vector2 hop) {
    bool toRight = hop.x > 0;
    bool toLeft = hop.x < 0;
    bool towardsViewer = hop.y > 0;
    bool awayFromViewer = hop.y < 0;

    if (towardsViewer && toRight) return RabbitView.frontRight;
    if (towardsViewer && toLeft) return RabbitView.frontLeft;
    if (towardsViewer) return RabbitView.front;
    if (awayFromViewer && toRight) return RabbitView.backRight;
    if (awayFromViewer && toLeft) return RabbitView.backLeft;
    if (awayFromViewer) return RabbitView.back;
    if (toRight) return RabbitView.right;
    return RabbitView.left;
  }

  void _showView() {
    SpriteComponent? spriteComponent = _spriteComponent;
    // the sprites are not loaded yet; onLoad shows the view afterwards
    if (spriteComponent == null) return;

    spriteComponent.sprite = _sprites[_view.imageName];
    if (spriteComponent.isFlippedHorizontally != _view.mirrored) {
      spriteComponent.flipHorizontallyAroundCenter();
    }
  }
}
