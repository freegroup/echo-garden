import 'package:echo_garden/model/objects/patch.dart';

class SeedableModel extends PatchModel {
  static String staticLayerId = "$SeedableModel";

  SeedableModel({required super.gameModelRef, required super.cell, super.energy});

  @override
  String get layerId => SeedableModel.staticLayerId;

  @override
 Future<void> step() async {}
}
