const kGameConfiguration = (
  tileMap: (
    width: 150.0,
    height: 150.0,
    tileSpriteSize: 64.0,
  ),
  world: (
    tileSize: 64.0,
    visibleTileRadius: 35.0,
    tileSnap: 1.0,
    waterPercentage: 50.0,
  ),
  rabbit: (
    birthThreshold: 10.0,
    initEnergy: 8,
    energyPerStep: -0.8,
    stepRadius: 1,
    maxEnergyPerEat: 2.0,
    maxEnergyCanEat: 25,
  ),
  plant: (
    weed: (
      initialEnergy: 0.5,
      growPercentage: 0.005,
    ),
    grass: (
      initialEnergy: 0.01,
      maxEnergy: 2.5,
      minEnergy: 0.01,
      incEnergie: 0.03,
      growPercentage: 0.055,
    ),
    flower: (
      initialEnergy: 0.5,
      maxEnergy: 3.5,
      incEnergie: 0.3,
      growPercentage: 0.001,
    ),
    tree: (
      initialEnergy: 0.5,
      growEnergy: 0.5,
      maxEnergy: 100.0,
      seedEnergy: 9.0,
      seedPercentage: 0.1,
      growPercentage: 0.0006,
    ),
  )
);
