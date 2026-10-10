import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/game_elements.dart';
import '../viewmodels/gameplay_viewmodel.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, GameplayViewModel vm) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
        vm.movePlayer(0, -1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) {
        vm.movePlayer(0, 1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
        vm.movePlayer(-1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
        vm.movePlayer(1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        vm.placeBomb();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GameplayViewModel>();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, vm),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('💣 Playing with Fire • Bomberman Arena'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppConstants.fireOrange),
              tooltip: 'Yeni Oyun',
              onPressed: () => vm.startNewGame(),
            )
          ],
        ),
        body: Column(
          children: [
            // GÖSTERGELER & ASSET STATÜLERİ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppConstants.bgCard,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Can Barı
                      Row(
                        children: [
                          const Text('❤️ ', style: TextStyle(fontSize: 16)),
                          SizedBox(
                            width: 100,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: vm.health / 100.0,
                                minHeight: 12,
                                backgroundColor: AppConstants.bgDark,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vm.health > 40 ? AppConstants.waterCyan : AppConstants.fireRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('${vm.health} HP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      // Skor
                      Text('🏆 Skor: ${vm.score}', style: const TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Asset İstatistikleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge('💣 Bomba', '${vm.activeBombsCount}/${vm.maxBombs}', AppConstants.fireRed),
                      _buildStatBadge('⚡ Şimşek', '${vm.bombRange} Menzil', Colors.amber),
                      _buildStatBadge('👟 Ayakkabı', '${vm.speed.toStringAsFixed(1)}x Hız', AppConstants.waterBlue),
                    ],
                  ),
                ],
              ),
            ),

            // BİLDİRİM BANNERI
            if (vm.lastNotification != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                color: const Color(0xFF1F2937),
                child: Text(
                  vm.lastNotification!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ),

            // OYUN IZGARASI (GRID ARENA)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: GameplayViewModel.cols / GameplayViewModel.rows,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A4031), // Klasik toprak zemin rengi
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF2E261B), width: 3),
                      ),
                      child: CustomPaint(
                        painter: BombermanPainter(vm: vm),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // DOKUNMATİK KONTROLLER (D-PAD & BOMBA)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppConstants.bgCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // D-Pad
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2A3749)),
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: () => vm.movePlayer(0, -1),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF2A3749)),
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => vm.movePlayer(-1, 0),
                          ),
                          const SizedBox(width: 44),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFF2A3749)),
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => vm.movePlayer(1, 0),
                          ),
                        ],
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF2A3749)),
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () => vm.movePlayer(0, 1),
                      ),
                    ],
                  ),

                  // BOMBA BIRAK BUTONU
                  GestureDetector(
                    onTap: () => vm.placeBomb(),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF3B30), Color(0xFFFF9500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('💣', style: TextStyle(fontSize: 32)),
                          Text('BOMBA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.bgDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppConstants.borderCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class BombermanPainter extends CustomPainter {
  final GameplayViewModel vm;

  BombermanPainter({required this.vm});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / GameplayViewModel.cols;
    final cellH = size.height / GameplayViewModel.rows;

    // 1. ZEMİN & DUVARLAR & VARİLLERİ ÇİZ
    for (int r = 0; r < GameplayViewModel.rows; r++) {
      for (int c = 0; c < GameplayViewModel.cols; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        final cell = vm.grid[r][c];

        if (cell == CellType.wall) {
          // Kırılmaz Taş Duvar
          final wallPaint = Paint()..color = const Color(0xFF6B5E4B);
          canvas.drawRect(rect, wallPaint);
          final borderPaint = Paint()
            ..color = const Color(0xFF3B3226)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawRect(rect, borderPaint);
        } else if (cell == CellType.barrel) {
          // Kırmızı Ahşap/Metal Varil (Resimdeki kırmızı variller)
          _drawBarrel(canvas, rect);
        } else {
          // Zemin ızgara çizgileri
          final gridBorder = Paint()
            ..color = const Color(0xFF3F3527)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawRect(rect, gridBorder);
        }
      }
    }

    // 2. POWER-UP'LARI (ASSET'LERİ) ÇİZ
    for (final p in vm.powerUps) {
      final rect = Rect.fromLTWH(p.x * cellW, p.y * cellH, cellW, cellH);
      _drawPowerUp(canvas, rect, p.type);
    }

    // 3. BOMBALARI ÇİZ
    for (final bomb in vm.bombs) {
      final center = Offset((bomb.x + 0.5) * cellW, (bomb.y + 0.5) * cellH);
      _drawBomb(canvas, center, cellW * 0.4);
    }

    // 4. ALEV / PATLAMA EFEKTLERİNİ ÇİZ (Playing with Fire 2 Tarzı Mavi/Elektrik Patlama)
    for (final exp in vm.explosions) {
      final rect = Rect.fromLTWH(exp.x * cellW, exp.y * cellH, cellW, cellH);
      _drawExplosion(canvas, rect);
    }

    // 5. BOTLARI ÇİZ (Mor, Yeşil, Turuncu İtfaiyeciler)
    for (final bot in vm.bots) {
      if (bot.health > 0) {
        final bCenter = Offset((bot.x + 0.5) * cellW, (bot.y + 0.5) * cellH);
        _drawPlayer(canvas, bCenter, cellW * 0.42, bodyColor: bot.color);
      }
    }

    // 6. OYUNCUYU ÇİZ (Mavi İtfaiyeci)
    if (vm.health > 0) {
      final pCenter = Offset((vm.playerX + 0.5) * cellW, (vm.playerY + 0.5) * cellH);
      _drawPlayer(canvas, pCenter, cellW * 0.42, bodyColor: const Color(0xFF0284C7));
    }
  }

  void _drawBarrel(Canvas canvas, Rect rect) {
    // Kırmızı varil gövdesi
    final barrelPaint = Paint()..color = const Color(0xFFB94A48);
    final rrect = RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(4));
    canvas.drawRRect(rrect, barrelPaint);

    // Varil çemberleri (şeritler)
    final stripePaint = Paint()
      ..color = const Color(0xFF5D2423)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(rect.left + 2, rect.top + rect.height * 0.33), Offset(rect.right - 2, rect.top + rect.height * 0.33), stripePaint);
    canvas.drawLine(Offset(rect.left + 2, rect.top + rect.height * 0.66), Offset(rect.right - 2, rect.top + rect.height * 0.66), stripePaint);
  }

  void _drawPowerUp(Canvas canvas, Rect rect, PowerUpType type) {
    Color boxColor;
    String emoji;

    switch (type) {
      case PowerUpType.lightning:
        boxColor = const Color(0xFF1E40AF);
        emoji = '⚡';
        break;
      case PowerUpType.shoe:
        boxColor = const Color(0xFF065F46);
        emoji = '👟';
        break;
      case PowerUpType.extraBomb:
        boxColor = const Color(0xFF7F1D1D);
        emoji = '💣';
        break;
      case PowerUpType.heal:
        boxColor = const Color(0xFF854D0E);
        emoji = '🔧';
        break;
    }

    final bgPaint = Paint()..color = boxColor;
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(4), const Radius.circular(6)), bgPaint);

    final textPainter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: rect.width * 0.55)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(rect.left + (rect.width - textPainter.width) / 2, rect.top + (rect.height - textPainter.height) / 2));
  }

  void _drawBomb(Canvas canvas, Offset center, double radius) {
    final bombPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(center, radius, bombPaint);

    final fusePaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3;
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx + 4, center.dy - radius - 6), fusePaint);

    canvas.drawCircle(Offset(center.dx + 4, center.dy - radius - 6), 3, Paint()..color = Colors.redAccent);
  }

  void _drawExplosion(Canvas canvas, Rect rect) {
    final outerPaint = Paint()..color = const Color(0xCC38BDF8);
    canvas.drawRect(rect, outerPaint);

    final innerPaint = Paint()..color = Colors.white;
    canvas.drawRect(rect.deflate(6), innerPaint);
  }

  void _drawPlayer(Canvas canvas, Offset center, double radius, {required Color bodyColor}) {
    // Gövde
    final bodyPaint = Paint()..color = bodyColor;
    canvas.drawCircle(center, radius, bodyPaint);

    // Şapka / Kask
    final hatPaint = Paint()..color = Colors.white70;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,
      3.14,
      true,
      hatPaint,
    );

    // Yüz
    final facePaint = Paint()..color = const Color(0xFFFFD1A4);
    canvas.drawCircle(Offset(center.dx, center.dy + 2), radius * 0.5, facePaint);

    // Gözler
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(center.dx - 3, center.dy + 2), 1.5, eyePaint);
    canvas.drawCircle(Offset(center.dx + 3, center.dy + 2), 1.5, eyePaint);
  }

  @override
  bool shouldRepaint(covariant BombermanPainter oldDelegate) => true;
}
