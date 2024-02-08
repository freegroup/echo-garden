import 'package:echo_garden/model/agent.dart';

abstract class PlantModel extends AgentModel {
  static String staticLayerId = "PlantModel";

  double energy;

  PlantModel({required super.scheduler, this.energy = 0, super.x, super.y, super.cell});

  @override
  String get layerId => PlantModel.staticLayerId;

  @override
  void step() {}
}
