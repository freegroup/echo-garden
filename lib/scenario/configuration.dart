import 'package:flutter/material.dart';

var kConfiguration = (
  world: (
    width: 100,
    height: 100,
  ),
  rabbit: (
    birthThreshold: 40.0,
    initEnergy: 10,
    energyPerStep: -1.0,
    maxEnergyCanEat: 40,
  ),
  patch: (water: (color: Colors.blue,),),
  plant: (
    weed: (
      initialEnergy: 0.5,
      color: Colors.green,
    ),
    grass: (
      initialEnergy: 1.5,
      color: Colors.lightGreen,
    ),
    flower: (
      initialEnergy: 3.5,
      color: Colors.yellow,
    ),
    tree: (
      initialEnergy: 0.5,
      growEnergy: 0.005,
      maxEnergy: 100.0,
      color: Colors.deepPurpleAccent[700]!
    ),
  )
);
