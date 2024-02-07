import 'package:echo_garden/model/agent.dart';

abstract class PlantModel extends AgentModel {
  static String staticTypeId = "PlantModel";

  double energy;

  PlantModel({required super.scheduler, this.energy = 0, super.x, super.y, super.cell});

  @override
  String get typeId => PlantModel.staticTypeId;

  @override
  void step() {}
}
