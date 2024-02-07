import 'package:echo_garden/model/agent.dart';

class ActorModel extends AgentModel {
  static String staticTypeId = "ActorModel";

  ActorModel({super.cell, super.x, super.y, required super.scheduler});

  @override
  String get typeId => ActorModel.staticTypeId;
}
