import 'dart:math';

import 'package:echo_garden/game/game.dart';
import 'package:echo_garden/game/pixels.dart';
import 'package:echo_garden/player.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/rendering.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// Shows the player of the model on the screen.
///
/// The sprite only follows the Player; it never moves the player itself.
class PlayerSprite extends SpriteAnimationComponent with HasGameReference<GameVisualization> {
  final Player _player;

  final double _animationSpeed = 0.01;
  double _postMovementEmissionDuration = 0.0;

  late final SpriteAnimation _runDownAnimation;
  late final SpriteAnimation _runLeftAnimation;
  late final SpriteAnimation _runUpAnimation;
  late final SpriteAnimation _runRightAnimation;

  final random = Random();
  final Tween<double> noise = Tween(begin: -2, end: 2);
  final ColorTween colorTween = ColorTween(
      begin: const Color.fromARGB(86, 76, 175, 79), end: const Color.fromARGB(152, 121, 85, 72));

  final Vector2 oldPosition = Vector2.all(0);

  PlayerSprite({required Player player})
      : _player = player,
        super(size: Vector2.all(96), anchor: Anchor.center) {
    priority = 500;
    position = _pixelPosition();
    //debugMode = true;
    decorator.addLast(Shadow3DDecorator(
      base: Vector2(100, size.y),
      angle: -1.4,
      xShift: 200,
      yScale: 2.5,
      opacity: 0.3,
      blur: 1.5,
    ));
  }

  Vector2 _pixelPosition() {
    return posToPixel(_player.position);
  }

  @override
  void onLoad() {
    final spriteSheet = SpriteSheet(
      image: game.images.fromCache('player.png'),
      srcSize: Vector2(96.0, 96.0),
    );

    _runDownAnimation = spriteSheet.createAnimation(row: 0, stepTime: _animationSpeed, to: 4);
    _runLeftAnimation = spriteSheet.createAnimation(row: 1, stepTime: _animationSpeed, to: 4);
    _runRightAnimation = spriteSheet.createAnimation(row: 2, stepTime: _animationSpeed, to: 4);
    _runUpAnimation = spriteSheet.createAnimation(row: 3, stepTime: _animationSpeed, to: 4);
    animation = _runLeftAnimation;
  }

  void schritteVibration() async {
    bool? canVibrate = await Vibration.hasVibrator();
    if (canVibrate != null && canVibrate) {
      // Erzeuge eine sanfte Vibration
      // Die Dauer der Vibration ist in Millisekunden.
      // Für sanfte Schritte könntest du kurze Vibrationen mit Pausen dazwischen verwenden.
      Vibration.vibrate(duration: 10, amplitude: 20);
    }
  }

  @override
  void update(double dt) {
    position = _pixelPosition();

    // Update the post-movement emission timer
    if (_player.isMoving) {
      _postMovementEmissionDuration = 0.2;
    } else if (_postMovementEmissionDuration > 0) {
      _postMovementEmissionDuration -= dt;
      _emitDust();
    }

    // standing still: no dust and no running animation
    if (!_player.isMoving) {
      return;
    }

    _selectAnimationByDirection();
    if (position.distanceTo(oldPosition) > 80) {
      schritteVibration();
      oldPosition.x = position.x;
      oldPosition.y = position.y;
    }

    _emitDust();
    super.update(dt);
  }

  void _emitDust() {
    game.world.add(ParticleSystemComponent(
      position: position.clone()..add(Vector2(0, 48)),
      priority: 300,
      particle: Particle.generate(
        count: 10,
        generator: (i) {
          return AcceleratedParticle(
            lifespan: 3.5,
            position: Vector2(
              noise.transform(random.nextDouble()) * 5,
              noise.transform(random.nextDouble()) * 2,
            ),
            speed: Vector2(
              noise.transform(random.nextDouble()) * 3,
              noise.transform(random.nextDouble()) * 3,
            ),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                // Apply ease-out effect to opacity
                double easeOutOpacity = pow(1 - particle.progress, 3).toDouble();
                final paint = Paint()
                  ..color = colorTween.transform(random.nextDouble())!.withOpacity(easeOutOpacity);
                canvas.drawCircle(Offset.zero, random.nextDouble() * 2, paint);
              },
            ),
          );
        },
      ),
    ));
  }

  void _selectAnimationByDirection() {
    Vector2 direction = _player.direction;
    double angleInDegrees = atan2(direction.y, direction.x) * (180 / pi);

    // Normalize the angle to [0, 360) range
    angleInDegrees = (angleInDegrees + 360) % 360;

    if ((angleInDegrees > 315 && angleInDegrees <= 360) || (angleInDegrees <= 45)) {
      // Right
      animation = _runRightAnimation;
    } else if (angleInDegrees > 135 && angleInDegrees <= 225) {
      // Left
      animation = _runLeftAnimation;
    } else if (angleInDegrees > 45 && angleInDegrees <= 135) {
      // Up
      animation = _runDownAnimation;
    } else if (angleInDegrees > 225 && angleInDegrees <= 315) {
      // Down
      animation = _runUpAnimation;
    }
  }
}
