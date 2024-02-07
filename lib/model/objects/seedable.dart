import 'package:echo_garden/model/objects/patch.dart';

class SeedableModel extends PatchModel {
  SeedableModel({required super.scheduler, super.x, super.y, super.cell}) {}

  @override
  void step() {}
}
