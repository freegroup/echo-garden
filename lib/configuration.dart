import 'package:flutter/material.dart';

const kGameConfiguration = (
  tileMap: (
    width: 100.0,
    height: 100.0,
    tilemap: "world.png",
    tileSpriteSize: 63.0,
  ),
  world: (
    tileSize: 64.0,
    visibleTileRadius: 10.0,
  ),
  rabbit: (
    birthThreshold: 50.0,
    initEnergy: 10,
    energyPerStep: -1.05,
    maxEnergyCanEat: 25,
  ),
  patch: (water: (color: Colors.blue,),),
  plant: (
    weed: (
      initialEnergy: 0.5,
      growPercentage: 0.005,
    ),
    grass: (
      initialEnergy: 1.5,
      growPercentage: 0.035,
    ),
    flower: (
      initialEnergy: 3.5,
      growPercentage: 0.0005,
    ),
    tree: (
      initialEnergy: 0.5,
      growEnergy: 0.04,
      maxEnergy: 100.0,
      seedEnergy: 9.0,
      seedPercentage: 0.1,
      growPercentage: 0.0003,
    ),
  )
);
