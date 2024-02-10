import 'package:echo_garden/model/agent.dart';

class ActorModel extends AgentModel {
  static String staticLayerId = "ActorModel";

  ActorModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  String get layerId => ActorModel.staticLayerId;
}
