import 'package:echo_garden/model/objects/patch.dart';

class SeedableModel extends PatchModel {
  static String staticLayerId = "SeedableModel";

  SeedableModel({required super.scheduler, super.x, super.y, super.cell});

  @override
  String get layerId => SeedableModel.staticLayerId;

  @override
  void step() {}
}
