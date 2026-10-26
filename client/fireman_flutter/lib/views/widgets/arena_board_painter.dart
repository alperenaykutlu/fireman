import 'package:flutter/material.dart';
import '../../models/game_elements.dart';
import '../../viewmodels/gameplay_viewmodel.dart';
class ArenaBoardPainter extends CustomPainter {
  final GameplayViewModel vm;
  final int mapRevision;
  static final Paint _floorA = Paint()..color = const Color(0xFF343A43);
  static final Paint _floorB = Paint()..color = const Color(0xFF2D333C);
  static final Paint _wall = Paint()..color = const Color(0xFF8D805E);
  static final Paint _wallTop = Paint()..color = const Color(0xFFC7B98D);
  static final Paint _barrel = Paint()..color = const Color(0xFF8B2F25);
  static final Paint _barrelBand = Paint()..color = const Color(0xFF2A2020);
  static final Paint _danger = Paint()..color = const Color(0xFF64748B);

  ArenaBoardPainter({required this.vm}) : mapRevision = vm.mapRevision;

  @override
  void paint(Canvas canvas, Size size) {
    final rowCount = vm.grid.length;
    if (rowCount == 0) return;
    final columnCount = vm.grid.first.length;
    final cellW = size.width / columnCount;
    final cellH = size.height / rowCount;
    for (var row = 0; row < rowCount; row++) {
      for (var col = 0; col < columnCount; col++) {
        final rect = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
        canvas.drawRect(rect, (row + col).isEven ? _floorA : _floorB);
        switch (vm.grid[row][col]) {
          case CellType.wall:
            final block = rect.deflate(rect.shortestSide * .07);
            canvas.drawRRect(RRect.fromRectAndRadius(block, Radius.circular(rect.shortestSide * .1)), _wall);
            canvas.drawLine(block.topLeft, block.topRight, _wallTop..strokeWidth = rect.shortestSide * .08);
            break;
          case CellType.barrel:
            final drum = rect.deflate(rect.shortestSide * .15);
            canvas.drawRRect(RRect.fromRectAndRadius(drum, Radius.circular(rect.shortestSide * .2)), _barrel);
            canvas.drawLine(Offset(drum.left, drum.center.dy), Offset(drum.right, drum.center.dy), _barrelBand..strokeWidth = rect.shortestSide * .09);
            break;
          case CellType.suddenDeath:
            canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(rect.shortestSide * .08), Radius.circular(rect.shortestSide * .12)), _danger);
            break;
          case CellType.empty:
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ArenaBoardPainter oldDelegate) =>
      oldDelegate.mapRevision != mapRevision;
}

