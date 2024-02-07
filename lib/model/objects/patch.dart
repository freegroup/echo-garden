import 'package:echo_garden/model/agent.dart';

// Patch is either rock,sand, mudd, water,...something like that
//
abstract class PatchModel extends AgentModel {
  static String staticTypeId = "PatchModel";

  PatchModel({required super.scheduler, super.x, super.y, super.cell});
  @override
  String get typeId => PatchModel.staticTypeId;

  @override
  void step() {}
}
