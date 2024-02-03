import 'package:flutter/material.dart';

var kConfiguration = (
  world: (
    width: 50,
    height: 100,
  ),
  rabbit: (
    birthThreshold: 50.0,
    initEnergy: 10,
    energyPerStep: -1.05,
    maxEnergyCanEat: 25,
    color: Colors.brown,
  ),
  patch: (water: (color: Colors.blue,),),
  plant: (
    weed: (
      initialEnergy: 0.5,
      color: Colors.green,
      growPercentage: 0.015,
    ),
    grass: (
      initialEnergy: 1.5,
      color: Colors.lightGreen,
      growPercentage: 0.035,
    ),
    flower: (
      initialEnergy: 3.5,
      color: Colors.yellow,
      growPercentage: 0.001,
    ),
    tree: (
      initialEnergy: 0.5,
      growEnergy: 0.04,
      maxEnergy: 100.0,
      seedEnergy: 9.0,
      seedPercentage: 0.1,
      growPercentage: 0.0005,
      color: Colors.deepPurpleAccent[700]!.withOpacity(0.01)
    ),
  )
);
