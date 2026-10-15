import 'package:echo_garden/model/agent.dart';

/// A mountain area on a cell. Optional: a cell without a height area is flat.
///
/// Height areas lie on land (above the soil) or rise as rocky islands out of
/// the water. The model knows no height as a number; other objects only ask
/// whether they get along with the type of the area.
abstract class HeightAreaModel extends AgentModel {
  static String staticLayerId = "$HeightAreaModel";

  HeightAreaModel({required super.gameModelRef, required super.cell});

  @override
  String get layerId => HeightAreaModel.staticLayerId;
}

class HeightAreaLowModel extends HeightAreaModel {
  HeightAreaLowModel({required super.gameModelRef, required super.cell});
}

class HeightAreaMediumModel extends HeightAreaModel {
  HeightAreaMediumModel({required super.gameModelRef, required super.cell});
}

class HeightAreaHighModel extends HeightAreaModel {
  HeightAreaHighModel({required super.gameModelRef, required super.cell});
}
