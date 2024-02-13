import 'package:flame/components.dart';

final Vector2 screenSize = Vector2.all(100);

const kGameConfiguration = (
  tileMap: (
    width: 150.0,
    height: 150.0,
    tileSpriteSize: 64.0,
  ),
  world: (
    tileSize: 32.0,
    visibleTileRadius: 28.0,
    tileSnap: 1.0,
    waterPercentage: 50.0,
  ),
  rabbit: (
    birthThreshold: 10.0,
    initEnergy: 8,
    energyPerStep: -0.8,
    stepRadius: 1,
    maxEnergyPerEat: 2.0,
    maxEnergyCanEat: 25.0,
  ),
  patch: (
    soil: (
      maxEnergy: 100.0, // maximal water level
      initialEnergy: 90.0, // initial water level
      incEnergy: 0.01, // automatic ground water refill
    ),
  ),
  plant: (
    weed: (
      initialEnergy: 0.5,
      growPercentage: 0.005,
      requiresMinWaterLevel: 80.0, // can consume water from soil down to this soil energy level
    ),
    grass: (
      maxEnergy: 2.5,
      initialEnergy: 0.01,
      minEnergy: 0.01,
      growEnergy: 0.03, // water consumption and grow energy
      growPercentage: 0.055,
      requiresMinWaterLevel: 90.0, // can consume water from soil down to this soil energy level
    ),
    flower: (
      maxEnergy: 3.5,
      initialEnergy: 0.5,
      growEnergy: 0.3, // water consumption and grow energy
      growPercentage: 0.001,
      requiresMinWaterLevel: 95.0, // can consume water from soil down to this soil energy level
    ),
    tree: (
      maxEnergy: 100.0,
      initialEnergy: 0.5,
      growEnergy: 0.5, // water consumption and grow energy
      seedEnergy: 50.0,
      seedPercentage: 0.1,
      growPercentage: 0.0006,
      requiresMinWaterLevel: 35.0, // can consume water from soil down to this soil energy level
    ),
  )
);
