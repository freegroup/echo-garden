import 'package:echo_garden/model/agent.dart';

abstract class PlantModel extends AgentModel {
  static String staticLayerId = "$PlantModel";

  PlantModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  String get layerId => PlantModel.staticLayerId;

  @override
  void step() {}
}
