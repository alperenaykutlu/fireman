import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/gameplay_viewmodel.dart';
/// Oyun Bitti Ekranı (Game Over Overlay)
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isGameOver = context.select<GameplayViewModel, bool>(
      (vm) => vm.isGameOver,
    );
    if (!isGameOver) return const SizedBox.shrink();

    final title =
        context.select<GameplayViewModel, String?>((vm) => vm.gameOverTitle) ??
        'OYUN BİTTİ';
    final message =
        context.select<GameplayViewModel, String?>(
          (vm) => vm.gameOverMessage,
        ) ??
        '';
    final score = context.select<GameplayViewModel, int>((vm) => vm.score);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF262626),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amberAccent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.amberAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'TOPLAM PUAN: $score',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                icon: const Icon(Icons.replay),
                label: const Text(
                  'TEKRAR OYNA',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () =>
                    context.read<GameplayViewModel>().startNewGame(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

