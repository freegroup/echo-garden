import 'package:echo_garden/model/objects/beach.dart';
import 'package:echo_garden/model/objects/height_area.dart';
import 'package:echo_garden/model/objects/soil.dart';

// The values of a kind of tree. Trees and firs must have exactly these fields.
typedef TreeSettings = ({
  List<Type> growsOn,
  double maxEnergy,
  double initialEnergy,
  double growEnergy,
  double seedEnergy,
  double seedPercentage,
  double growPercentage,
  double requiresMinWaterLevel,
  // competition: a tree with larger neighbors within crowdingRadius whose
  // summed energy is above maxCrowdingEnergy does not grow but loses
  // crowdingPenalty energy per step. A high maxCrowdingEnergy means no limit
  // (dense forest allowed, e.g. the oak in the lowland).
  int crowdingRadius,
  double maxCrowdingEnergy,
  double crowdingPenalty,
});

const kGameConfiguration = (
  // the model: positions are whole numbers without a unit
  grid: (
    gridWidth: 1000, // width of one cell in units; must be even, so the middle of a cell is whole
    mapWidth: 150, // width of the map in cells
    mapHeight: 150, // height of the map in cells
  ),
  // the graphics
  tileMap: (
    tileSpriteSize: 64.0,
  ),
  world: (
    tileSize: 64.0,
    tileSnap: 1.0,
    waterPercentage: 40.0,
    minIslandSize: 20, // in cells: smaller pieces of land become water, bigger ones get a bridge
  ),
  mountain: (
    // share of the whole map, taken from the highest land
    highPercentage: 2.0,
    mediumPercentage: 4.0,
    lowPercentage: 8.0,
    // rocky islands in the water: high in the middle, then medium, then low
    islandCount: 3,
    islandHighRadius: 1.5, // in cells
    islandMediumRadius: 3.0,
    islandLowRadius: 4.5, // the rim gets up to 0.6 cells of random extra width
  ),
  // which types of ground each way of moving can enter
  movement: (
    walking: [SoilModel, BeachModel, HeightAreaLowModel, HeightAreaMediumModel],
    hopping: [SoilModel, HeightAreaLowModel],
  ),
  player: (
    speed: 3900, // units per second (formerly 250 pixels per second at 64 pixels per cell)
    startBeachDistance: 3, // the player starts on land, at most this many cells away from a beach
  ),
  rabbit: (
    birthThreshold: 10.0,
    initEnergy: 8,
    energyPerStep: -0.2,
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
      growsOn: [SoilModel, HeightAreaLowModel], // the ground this plant gets along with
      initialEnergy: 0.5,
      growPercentage: 0.005,
      requiresMinWaterLevel: 80.0, // can consume water from soil down to this soil energy level
    ),
    /* consumes water, but do not provide any kind of energy.
       This is because the sun can reduce now the water easy from the soil. 
    */
    parchedGrass: (
      maxEnergy: 0.0,
      initialEnergy: 0.0,
      minEnergy: 0.001,
      growEnergy: 0.03, // water consumption and grow energy
      requiresMinWaterLevel: 0.0,
    ),
    grass: (
      growsOn: [SoilModel, HeightAreaLowModel],
      maxEnergy: 2.5,
      initialEnergy: 0.01,
      minEnergy: 0.01,
      growEnergy: 0.03, // water consumption and grow energy
      growPercentage: 0.055,
      requiresMinWaterLevel: 90.0, // can consume water from soil down to this soil energy level
    ),
    flower: (
      growsOn: [SoilModel],
      maxEnergy: 3.5,
      initialEnergy: 0.5,
      growEnergy: 0.3, // water consumption and grow energy
      growPercentage: 0.001,
      requiresMinWaterLevel: 95.0, // can consume water from soil down to this soil energy level
    ),
    // the oak: the leafy lowland tree, dense forest allowed
    tree: (
      growsOn: [SoilModel],
      maxEnergy: 100.0,
      initialEnergy: 0.5,
      growEnergy: 0.5, // water consumption and grow energy
      seedEnergy: 50.0,
      seedPercentage: 0.1,
      growPercentage: 0.0006,
      requiresMinWaterLevel: 35.0, // can consume water from soil down to this soil energy level
      crowdingRadius: 1,
      maxCrowdingEnergy: 1000000.0, // no limit
      crowdingPenalty: 0.0,
    ),
    // the fir: sparse on the low mountains
    fir: (
      growsOn: [HeightAreaLowModel],
      maxEnergy: 100.0,
      initialEnergy: 0.5,
      growEnergy: 0.5,
      seedEnergy: 50.0,
      seedPercentage: 0.1,
      growPercentage: 0.0006,
      requiresMinWaterLevel: 35.0,
      crowdingRadius: 1,
      maxCrowdingEnergy: 20.0,
      crowdingPenalty: 5.0,
    ),
    // the pine: the dark conifer, sparse on the medium mountains
    pine: (
      growsOn: [HeightAreaMediumModel],
      maxEnergy: 100.0,
      initialEnergy: 0.5,
      growEnergy: 0.5,
      seedEnergy: 50.0,
      seedPercentage: 0.1,
      growPercentage: 0.0012,
      requiresMinWaterLevel: 0.0, // mountain rock holds little water
      crowdingRadius: 1,
      maxCrowdingEnergy: 20.0,
      crowdingPenalty: 5.0,
    ),
  )
);
