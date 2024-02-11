import 'package:echo_garden/model/agent.dart';

// Patch is either rock,sand, mudd, water,...something like that
//
abstract class PatchModel extends AgentModel {
  static String staticLayerId = "$PatchModel";

  PatchModel({required super.gameModelRef, required super.cell, super.energy});
  @override
  String get layerId => PatchModel.staticLayerId;

  @override
  Future<void> step() async {}
}
