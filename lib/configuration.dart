const kGameConfiguration = (
  tileMap: (
    width: 50.0,
    height: 50.0,
    tileSpriteSize: 64.0,
  ),
  world: (
    tileSize: 64.0,
    visibleTileRadius: 35.0,
    tileSnap: 1.0,
    waterPercentage: 50.0,
  ),
  rabbit: (
    birthThreshold: 15.0,
    initEnergy: 5,
    energyPerStep: -0.4,
    maxEnergyPerEat: 0.6,
    maxEnergyCanEat: 25,
  ),
  plant: (
    weed: (
      initialEnergy: 0.5,
      growPercentage: 0.005,
    ),
    grass: (
      initialEnergy: 0.01,
      maxEnergy: 1.5,
      incEnergie: 0.05,
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
