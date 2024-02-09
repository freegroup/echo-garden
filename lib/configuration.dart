const kGameConfiguration = (
  tileMap: (
    width: 100.0,
    height: 100.0,
    tileSpriteSize: 63.0,
  ),
  world: (
    tileSize: 32.0,
    visibleTileRadius: 40.0,
    tileSnap: 3.0,
  ),
  rabbit: (
    birthThreshold: 15.0,
    initEnergy: 5,
    energyPerStep: -0.1,
    maxEnergyPerEat: 0.2,
    maxEnergyCanEat: 25,
  ),
  plant: (
    weed: (
      initialEnergy: 0.5,
      growPercentage: 0.005,
    ),
    grass: (
      initialEnergy: 0.2,
      maxEnergy: 1.5,
      incEnergie: 0.3,
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
      growEnergy: 0.04,
      maxEnergy: 100.0,
      seedEnergy: 9.0,
      seedPercentage: 0.1,
      growPercentage: 0.0006,
    ),
  )
);
