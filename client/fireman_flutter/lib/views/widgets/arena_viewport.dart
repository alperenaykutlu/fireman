import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/gameplay_viewmodel.dart';
import 'arena_board_painter.dart';
import 'game_over_overlay.dart';
import 'playing_with_fire_painter.dart';
class ArenaViewport extends StatelessWidget {
  const ArenaViewport({super.key});

  @override
  Widget build(BuildContext context) {
    final shakeOffset = context.select<GameplayViewModel, Offset>(
      (vm) => vm.cameraShakeOffset,
    );
    return Transform.translate(
      offset: shakeOffset,
      child: LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = context.select<GameplayViewModel, (int, int)>((vm) =>
            (vm.grid.isEmpty ? GameplayViewModel.cols : vm.grid.first.length,
             vm.grid.isEmpty ? GameplayViewModel.rows : vm.grid.length));
        final boardRatio = dimensions.$1 / dimensions.$2;
        final maxWidth = constraints.maxWidth - 8;
        final maxHeight = constraints.maxHeight - 8;
        final boardWidth = min(maxWidth, maxHeight * boardRatio);
        final boardHeight = boardWidth / boardRatio;
        return Center(
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF8A7B58),
                          width: 3,
                        ),
                      ),
                      child: Consumer<GameplayViewModel>(
                        builder: (context, vm, child) {
                          return Stack(fit: StackFit.expand, children: [
                            RepaintBoundary(child: CustomPaint(
                              painter: ArenaBoardPainter(vm: vm),
                            )),
                            RepaintBoundary(child: CustomPaint(
                              painter: PlayingWithFirePainter(vm: vm),
                            )),
                          ]);
                        },
                      ),
                    ),
                ),

                // Oyun Bitti Katmanı
                const GameOverOverlay(),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}

