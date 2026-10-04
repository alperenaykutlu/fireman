import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../viewmodels/gameplay_viewmodel.dart';
import '../viewmodels/character_viewmodel.dart';

class GameplayScreen extends StatelessWidget {
  const GameplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameplay = context.watch<GameplayViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🚒 Yangın Söndürme Sahası'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Puan: ${gameplay.score}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // CANLI CANVAS SAHASI
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.borderCard),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: FireGamePainter(
                    playerX: gameplay.playerPositionX,
                    waterLevel: gameplay.waterPercentage,
                    fireIntensity: gameplay.firePercentage,
                  ),
                  child: Container(),
                ),
              ),
            ),
          ),

          // HUD BARLARI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildMeter('💧 Su Tankı', gameplay.waterPercentage, AppConstants.waterBlue),
                const SizedBox(height: 10),
                _buildMeter('🔥 Yangın Şiddeti', gameplay.firePercentage, AppConstants.fireRed),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // KONTROLLER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Sol Hareket
                IconButton.filledTonal(
                  onPressed: () => gameplay.movePlayer(-15),
                  icon: const Icon(Icons.arrow_back),
                ),
                // SU PÜSKÜRTME
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.waterBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    gameplay.sprayWater();
                    if (gameplay.firePercentage <= 0) {
                      context.read<CharacterViewModel>().addRewards(100, 150);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Yangın söndürüldü! +100 Altın ve +150 XP kazanıldı!'),
                          backgroundColor: AppConstants.waterCyan,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.water_drop),
                  label: const Text('SU PÜSKÜRT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                // Sağ Hareket
                IconButton.filledTonal(
                  onPressed: () => gameplay.movePlayer(15),
                  icon: const Icon(Icons.arrow_forward),
                ),
                // Yenile
                IconButton(
                  onPressed: () {
                    gameplay.refillWater();
                    gameplay.restartFire();
                  },
                  tooltip: 'Yeniden Başlat',
                  icon: const Icon(Icons.refresh, color: AppConstants.fireOrange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeter(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text('${percent.toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 10,
            backgroundColor: AppConstants.bgDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class FireGamePainter extends CustomPainter {
  final double playerX;
  final double waterLevel;
  final double fireIntensity;

  FireGamePainter({
    required this.playerX,
    required this.waterLevel,
    required this.fireIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.75;

    // Zemin
    final groundPaint = Paint()..color = const Color(0xFF1E293B)..strokeWidth = 2;
    canvas.drawLine(Offset(0, groundY), Offset(size.width, groundY), groundPaint);

    // İtfaiyeci (Gövde & Kask)
    final bodyPaint = Paint()..color = AppConstants.waterBlue;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(playerX, groundY - 25), width: 26, height: 35),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Kask
    final helmetPaint = Paint()..color = AppConstants.fireRed;
    canvas.drawCircle(Offset(playerX, groundY - 48), 12, helmetPaint);

    // Hortum
    final hosePaint = Paint()..color = Colors.white70..strokeWidth = 4;
    canvas.drawLine(Offset(playerX + 10, groundY - 20), Offset(playerX + 30, groundY - 26), hosePaint);

    // Yangın Binası
    if (fireIntensity > 0) {
      final buildingPaint = Paint()..color = const Color(0xFF1F2937);
      canvas.drawRect(Rect.fromLTWH(size.width - 120, groundY - 120, 90, 120), buildingPaint);

      // Pencereler
      final winPaint = Paint()..color = AppConstants.gold;
      canvas.drawRect(Rect.fromLTWH(size.width - 105, groundY - 100, 20, 25), winPaint);
      canvas.drawRect(Rect.fromLTWH(size.width - 65, groundY - 100, 20, 25), winPaint);

      // Alevler
      final firePaint = Paint()..color = AppConstants.fireOrange;
      final flameRadius = (fireIntensity / 100.0) * 35;
      canvas.drawCircle(Offset(size.width - 75, groundY - 130), flameRadius, firePaint);
      canvas.drawCircle(Offset(size.width - 85, groundY - 110), flameRadius * 0.8, Paint()..color = AppConstants.fireRed);
    } else {
      final textPainter = TextPainter(
        text: const TextSpan(text: '✅ SÖNDÜRÜLDÜ!', style: TextStyle(color: AppConstants.waterCyan, fontSize: 16, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(size.width - 130, groundY - 60));
    }
  }

  @override
  bool shouldRepaint(covariant FireGamePainter oldDelegate) {
    return oldDelegate.playerX != playerX ||
           oldDelegate.waterLevel != waterLevel ||
           oldDelegate.fireIntensity != fireIntensity;
  }
}
