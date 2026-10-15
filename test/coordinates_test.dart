import 'package:echo_garden/configuration.dart';
import 'package:echo_garden/model/index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final gridWidth = kGameConfiguration.grid.gridWidth;

  test('the grid width is even, so the middle of a cell is a whole number', () {
    expect(gridWidth % 2, 0);
  });

  test('the center of a cell lies in that cell', () {
    const cell = Cell(3, 7);

    expect(cell.center, Pos(3 * gridWidth + gridWidth ~/ 2, 7 * gridWidth + gridWidth ~/ 2));
    expect(cell.center.cell, cell);
  });

  test('every position of a cell belongs to that cell', () {
    expect(Pos(2 * gridWidth, 0).cell, const Cell(2, 0));
    expect(Pos(3 * gridWidth - 1, gridWidth - 1).cell, const Cell(2, 0));
  });

  test('positions left of or above the map get negative cells', () {
    expect(const Pos(-1, -1).cell, const Cell(-1, -1));
    expect(const Cell(-1, -1).isInsideMap, isFalse);
  });

  test('cells outside of the map are empty in every layer', () {
    final model = GameModel(width: 10, height: 10);

    expect(model.getAgentAtCell(const Cell(-1, 0), PatchModel.staticLayerId), isNull);
    expect(model.getAgentAtCell(const Cell(10, 3), SeedableModel.staticLayerId), isNull);
  });
}
