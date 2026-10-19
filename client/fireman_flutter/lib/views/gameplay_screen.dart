import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/character/animated_character_painter.dart';
import '../core/character/character_state.dart';
import '../core/responsive/responsive_layout.dart';
import '../models/game_elements.dart';
import '../viewmodels/gameplay_viewmodel.dart';
import 'widgets/touch_controls.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

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
      _pressedKeys.add(event.logicalKey);
      if (event.logicalKey == LogicalKeyboardKey.space) {
        vm.placeDynamite();
      }
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
    }

    // Çapraz hareketi engelle: Ya sadece yatay ya sadece dikey (Orthogonal)
    int dx = 0;
    int dy = 0;

    final isUp = _pressedKeys.contains(LogicalKeyboardKey.arrowUp) || _pressedKeys.contains(LogicalKeyboardKey.keyW);
    final isDown = _pressedKeys.contains(LogicalKeyboardKey.arrowDown) || _pressedKeys.contains(LogicalKeyboardKey.keyS);
    final isLeft = _pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || _pressedKeys.contains(LogicalKeyboardKey.keyA);
    final isRight = _pressedKeys.contains(LogicalKeyboardKey.arrowRight) || _pressedKeys.contains(LogicalKeyboardKey.keyD);

    if (isUp && !isDown) {
      dy = -1;
    } else if (isDown && !isUp) {
      dy = 1;
    } else if (isLeft && !isRight) {
      dx = -1;
    } else if (isRight && !isLeft) {
      dx = 1;
    }

    vm.setMovementDirection(dx, dy);
  }

  @override
  Widget build(BuildContext context) {
    // Sadece klavye tuş eventleri için context.read kullanılır; tüm ekranı izlemiyoruz (Optimizasyon 1.3)
    final vm = context.read<GameplayViewModel>();

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) => _handleKeyEvent(event, vm),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2C2C2C),
          elevation: 4,
          title: const Row(
            children: [
              Text(
                '🔥 PLAYING WITH FIRE 2 • ARENA',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 18,
                  color: Color(0xFFF59E0B),
                ),
              ),
              Spacer(),
              // İzole Süre Bileşeni (Yalnızca süre değişince rebuild olur)
              TimerBadge(),
              SizedBox(width: 14),
              // İzole Puan Bileşeni (Yalnızca skor değişince rebuild olur)
              ScoreBadge(),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.amberAccent),
              tooltip: 'Arenayı Yeniden Başlat',
              onPressed: () {
                _pressedKeys.clear();
                vm.startNewGame();
              },
            ),
          ],
        ),
        body: const Column(
          children: [
            // Bildirim Bandı
            NotificationBanner(),

            // Oyun Alanı & Sol Sidebar
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FightersSidebar(),
                  Expanded(child: ArenaViewport()),
                ],
              ),
            ),

            // Alt Kontroller
            BottomControlsPanel(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// İZOLE VE OPTİMİZE WİDGET PARÇALARI (PERFORMANS VE JANK ÖNLEME)
// ============================================================================

/// Süre Göstergesi (Yalnızca timer veya suddenDeath değiştiğinde rebuild olur)
class TimerBadge extends StatelessWidget {
  const TimerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final timerText = context.select<GameplayViewModel, String>((vm) => vm.formattedTimer);
    final isSuddenDeath = context.select<GameplayViewModel, bool>((vm) => vm.isSuddenDeath);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isSuddenDeath ? Colors.red.shade900 : Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isSuddenDeath ? Colors.redAccent : Colors.amber, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 16, color: isSuddenDeath ? Colors.redAccent : Colors.amber),
          const SizedBox(width: 4),
          Text(
            timerText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isSuddenDeath ? Colors.white : Colors.amberAccent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Skor Göstergesi (Yalnızca skor değiştiğinde rebuild olur)
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final score = context.select<GameplayViewModel, int>((vm) => vm.score);
    return Text(
      'PUAN: $score',
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent),
    );
  }
}

/// Bildirim Bandı
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final notification = context.select<GameplayViewModel, String?>((vm) => vm.lastNotification);
    if (notification == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      color: const Color(0xFF0F172A),
      child: Text(
        notification,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Sol Panel (Fighters Sidebar): Sabit boyutlu ve RepaintBoundary ile korumalı
class FightersSidebar extends StatelessWidget {
  const FightersSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final fighters = context.select<GameplayViewModel, List<ArenaFighter>>((vm) => vm.fighters);

    return RepaintBoundary(
      child: Container(
        width: 135,
        decoration: const BoxDecoration(
          color: Color(0xFF333333),
          border: Border(right: BorderSide(color: Color(0xFF555555), width: 2)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB45309), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
              ),
              child: const Center(
                child: Text(
                  'FIGHTERS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: fighters.length,
                itemExtent: 110, // Sabit eleman boyutu (Optimizasyon: 2.2 Sabit Boyutlar)
                itemBuilder: (context, index) => FighterCard(fighter: fighters[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FighterCard extends StatelessWidget {
  final ArenaFighter fighter;
  const FighterCard({super.key, required this.fighter});

  @override
  Widget build(BuildContext context) {
    final isAlive = fighter.status == PlayerStatus.alive;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF262626),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAlive ? fighter.hatColor : const Color(0xFF555555),
          width: isAlive ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 48,
                decoration: BoxDecoration(
                  color: isAlive ? const Color(0xFF1E293B) : const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF64748B), width: 1.5),
                ),
                child: CustomPaint(
                  painter: FighterPortraitPainter(
                    hatColor: fighter.hatColor,
                    bodyColor: fighter.bodyColor,
                    isAlive: isAlive,
                  ),
                ),
              ),
              if (!isAlive)
                Container(
                  width: 60,
                  height: 48,
                  color: Colors.black.withValues(alpha: 0.6),
                  alignment: Alignment.center,
                  child: const Text(
                    'K.O.',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            fighter.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isAlive ? Colors.white : Colors.white38,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fighter.health / 100.0,
              minHeight: 4,
              backgroundColor: Colors.black45,
              valueColor: AlwaysStoppedAnimation<Color>(
                fighter.health > 40 ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GAMES:', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text('${fighter.wins}', style: const TextStyle(fontSize: 9, color: Colors.amberAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Arena Ekranı (RepaintBoundary ile sarılarak UI thread ayrıştırılmıştır)
class ArenaViewport extends StatelessWidget {
  const ArenaViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: AspectRatio(
          aspectRatio: GameplayViewModel.cols / GameplayViewModel.rows,
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF8A7B58), width: 3),
                    ),
                    child: Consumer<GameplayViewModel>(
                      builder: (context, vm, child) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: PlayingWithFirePainter(vm: vm),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Oyun Bitti Katmanı
              const GameOverOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oyun Bitti Ekranı (Game Over Overlay)
class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final isGameOver = context.select<GameplayViewModel, bool>((vm) => vm.isGameOver);
    if (!isGameOver) return const SizedBox.shrink();

    final title = context.select<GameplayViewModel, String?>((vm) => vm.gameOverTitle) ?? 'OYUN BİTTİ';
    final message = context.select<GameplayViewModel, String?>((vm) => vm.gameOverMessage) ?? '';
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
              )
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
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'TOPLAM PUAN: $score',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                icon: const Icon(Icons.replay),
                label: const Text('TEKRAR OYNA', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.read<GameplayViewModel>().startNewGame(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alt Kontrol Paneli (Dokunmatik Sanal D-Pad / Joystick ve Dinamit Butonu)
class BottomControlsPanel extends StatelessWidget {
  const BottomControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<GameplayViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E232D),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol: Dokunmatik Sanal D-Pad / Joystick (Klavye Bağımlılığı Yok)
          VirtualTouchPad(
            size: 116,
            onDirectionChanged: (dx, dy) => vm.setMovementDirection(dx, dy),
          ),

          // Orta: Güçlendirici Rozetleri (Sadece ilgili oyuncu değişince rebuild)
          const PowerUpBadges(),

          // Sağ: Dokunsal, Parlayan Dinamit Aksiyon Butonu
          GlowingActionButton(
            label: 'DİNAMİT',
            iconEmoji: '🧨',
            size: 78,
            onPressed: () => vm.placeDynamite(),
          ),
        ],
      ),
    );
  }
}

class PowerUpBadges extends StatelessWidget {
  const PowerUpBadges({super.key});

  @override
  Widget build(BuildContext context) {
    final activeCount = context.select<GameplayViewModel, int>((vm) => vm.activeDynamiteCount);
    final maxDynamites = context.select<GameplayViewModel, int>((vm) => vm.humanPlayer.maxDynamites);
    final range = context.select<GameplayViewModel, int>((vm) => vm.humanPlayer.dynamiteRange);
    final speed = context.select<GameplayViewModel, double>((vm) => vm.humanPlayer.speed);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge('🧨 DİNAMİT', '$activeCount/$maxDynamites', Colors.redAccent),
        const SizedBox(height: 4),
        _buildBadge('⚡ MENZİL', '$range', Colors.amberAccent),
        const SizedBox(height: 4),
        _buildBadge('🛼 HIZ', '${speed.toStringAsFixed(2)}x', Colors.cyanAccent),
      ],
    );
  }

  Widget _buildBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          Text(value, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class HoldableDirectionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const HoldableDirectionButton({
    super.key,
    required this.icon,
    required this.onStart,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onStart(),
      onPointerUp: (_) => onEnd(),
      onPointerCancel: (_) => onEnd(),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF3F3F46),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF52525B)),
        ),
        child: Icon(icon, size: 28, color: Colors.white),
      ),
    );
  }
}

// ============================================================================
// PLAYING WITH FIRE 2 - ÖZEL VEKTÖR VE RENDER MOTORU (PAINTER)
// ============================================================================
class PlayingWithFirePainter extends CustomPainter {
  final GameplayViewModel vm;

  // Önbelleklenmiş Paint nesneleri (Her karede new Paint() tahsisatını önler)
  static final Paint _bgPaint = Paint()..color = const Color(0xFF222222);
  static final Paint _gridBorderPaint = Paint()
    ..color = const Color(0xFF2C2C2C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  static final Paint _stonePaint = Paint()..color = const Color(0xFFB5A67D);
  static final Paint _stoneLightPaint = Paint()
    ..color = const Color(0xFFDCD2AD)
    ..strokeWidth = 2;
  static final Paint _stoneDarkPaint = Paint()
    ..color = const Color(0xFF6B5D3D)
    ..strokeWidth = 2;
  static final Paint _stoneInnerPaint = Paint()
    ..color = const Color(0xFF8F805B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final Paint _greyStonePaint = Paint()..color = const Color(0xFF64748B);
  static final Paint _greyStoneLightPaint = Paint()
    ..color = const Color(0xFF94A3B8)
    ..strokeWidth = 2;
  static final Paint _greyStoneDarkPaint = Paint()
    ..color = const Color(0xFF334155)
    ..strokeWidth = 2;
  static final Paint _greyStoneInnerPaint = Paint()
    ..color = const Color(0xFF475569)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final Paint _barrelBandPaint = Paint()
    ..color = const Color(0xFF262626)
    ..strokeWidth = 2.5;
  static final Paint _barrelLidPaint = Paint()..color = const Color(0xFFB91C1C);

  static final Paint _dynStickPaint = Paint()..color = const Color(0xFFDC2626);
  static final Paint _dynSlideStickPaint = Paint()..color = Colors.amber.shade800;
  static final Paint _dynStickLinePaint = Paint()
    ..color = const Color(0xFF991B1B)
    ..strokeWidth = 1.5;
  static final Paint _dynTapePaint = Paint()..color = const Color(0xFF18181B);
  static final Paint _dynFusePaint = Paint()
    ..color = Colors.white70
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

  static final Paint _expCenterFirePaint = Paint()..color = const Color(0xFFFF5722);
  static final Paint _expOuterFirePaint = Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.9);
  static final Paint _expCorePaint = Paint()..color = Colors.yellowAccent;
  static final Paint _whiteFlashPaint = Paint()..color = Colors.white;

  PlayingWithFirePainter({required this.vm});

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / GameplayViewModel.cols;
    final cellH = size.height / GameplayViewModel.rows;

    // 1. Zemin Çizimi
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), _bgPaint);

    // 2. Duvarlar, Variller ve Ani Ölüm Taş Blokları
    for (int r = 0; r < GameplayViewModel.rows; r++) {
      for (int c = 0; c < GameplayViewModel.cols; c++) {
        final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW, cellH);
        final cell = vm.grid[r][c];

        if (cell == CellType.wall) {
          _drawStoneBlock(canvas, rect);
        } else if (cell == CellType.suddenDeath) {
          _drawGreyStoneBlock(canvas, rect);
        } else if (cell == CellType.barrel) {
          _drawBarrel(canvas, rect);
        } else {
          canvas.drawRect(rect, _gridBorderPaint);
        }
      }
    }

    // 3. Güçlendiriciler (Power-ups)
    for (final p in vm.powerUps) {
      final rect = Rect.fromLTWH(p.x * cellW, p.y * cellH, cellW, cellH);
      _drawPowerUp(canvas, rect, p.type);
    }

    // 4. Dinamitler
    for (final dyn in vm.dynamites) {
      final rect = Rect.fromLTWH(dyn.x * cellW, dyn.y * cellH, cellW, cellH);
      _drawDynamite(canvas, rect, isSliding: dyn.slideDx != 0 || dyn.slideDy != 0);
    }

    // 5. Patlama Alevleri
    for (final exp in vm.explosions) {
      final rect = Rect.fromLTWH(exp.x * cellW, exp.y * cellH, cellW, cellH);
      _drawExplosion(canvas, rect, exp.isCenter);
    }

    // 6. Savaşçılar (Oyuncu ve Botlar)
    for (final fighter in vm.fighters) {
      if (fighter.status == PlayerStatus.alive) {
        final rect = Rect.fromLTWH(fighter.x * cellW, fighter.y * cellH, cellW, cellH);
        _drawFighterSprite(canvas, rect, fighter);
      }
    }
  }

  void _drawStoneBlock(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _stonePaint);
    canvas.drawLine(rect.topLeft, rect.topRight, _stoneLightPaint);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, _stoneLightPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, _stoneDarkPaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, _stoneDarkPaint);
    canvas.drawRect(rect.deflate(rect.width * 0.18), _stoneInnerPaint);
  }

  void _drawGreyStoneBlock(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _greyStonePaint);
    canvas.drawLine(rect.topLeft, rect.topRight, _greyStoneLightPaint);
    canvas.drawLine(rect.topLeft, rect.bottomLeft, _greyStoneLightPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, _greyStoneDarkPaint);
    canvas.drawLine(rect.topRight, rect.bottomRight, _greyStoneDarkPaint);
    canvas.drawRect(rect.deflate(rect.width * 0.18), _greyStoneInnerPaint);
  }

  void _drawBarrel(Canvas canvas, Rect rect) {
    final barrelRect = rect.deflate(2);
    final barrelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF991B1B), Color(0xFF7F1D1D), Color(0xFF450A0A)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(barrelRect);

    final rrect = RRect.fromRectAndRadius(barrelRect, const Radius.circular(3));
    canvas.drawRRect(rrect, barrelPaint);

    final y1 = barrelRect.top + barrelRect.height * 0.28;
    final y2 = barrelRect.top + barrelRect.height * 0.72;

    canvas.drawLine(Offset(barrelRect.left + 1, y1), Offset(barrelRect.right - 1, y1), _barrelBandPaint);
    canvas.drawLine(Offset(barrelRect.left + 1, y2), Offset(barrelRect.right - 1, y2), _barrelBandPaint);

    canvas.drawOval(
      Rect.fromLTWH(barrelRect.left + 2, barrelRect.top + 1, barrelRect.width - 4, barrelRect.height * 0.22),
      _barrelLidPaint,
    );
  }

  void _drawDynamite(Canvas canvas, Rect rect, {bool isSliding = false}) {
    final center = rect.center;
    final w = rect.width * 0.65;
    final h = rect.height * 0.55;

    final stickRect = Rect.fromCenter(center: center, width: w, height: h);
    canvas.drawRRect(RRect.fromRectAndRadius(stickRect, const Radius.circular(3)), isSliding ? _dynSlideStickPaint : _dynStickPaint);

    canvas.drawLine(Offset(stickRect.left, stickRect.top + h * 0.33), Offset(stickRect.right, stickRect.top + h * 0.33), _dynStickLinePaint);
    canvas.drawLine(Offset(stickRect.left, stickRect.top + h * 0.66), Offset(stickRect.right, stickRect.top + h * 0.66), _dynStickLinePaint);

    final tapeRect = Rect.fromCenter(center: center, width: w * 0.35, height: h);
    canvas.drawRect(tapeRect, _dynTapePaint);

    final path = Path();
    path.moveTo(stickRect.right - 2, stickRect.top + 2);
    path.quadraticBezierTo(stickRect.right + 4, stickRect.top - 6, stickRect.right + 2, stickRect.top - 10);
    canvas.drawPath(path, _dynFusePaint);

    final sparkCenter = Offset(stickRect.right + 2, stickRect.top - 10);
    canvas.drawCircle(sparkCenter, 3.5, Paint()..color = Colors.amberAccent);
    canvas.drawCircle(sparkCenter, 1.5, _whiteFlashPaint);
  }

  void _drawExplosion(Canvas canvas, Rect rect, bool isCenter) {
    canvas.drawRect(rect, isCenter ? _expCenterFirePaint : _expOuterFirePaint);
    canvas.drawRect(rect.deflate(rect.width * 0.22), _expCorePaint);
    canvas.drawCircle(rect.center, rect.width * 0.18, _whiteFlashPaint);
  }

  void _drawPowerUp(Canvas canvas, Rect rect, PowerUpType type) {
    String emoji;
    Color boxColor;

    switch (type) {
      case PowerUpType.dynamiteRange:
        emoji = '⚡';
        boxColor = const Color(0xFF1E3A8A);
        break;
      case PowerUpType.rollerSkate:
        emoji = '🛼';
        boxColor = const Color(0xFF065F46);
        break;
      case PowerUpType.extraDynamite:
        emoji = '🧨';
        boxColor = const Color(0xFF7F1D1D);
        break;
      case PowerUpType.shield:
        emoji = '🛡️';
        boxColor = const Color(0xFF854D0E);
        break;
    }

    final pRect = rect.deflate(4);
    canvas.drawRRect(RRect.fromRectAndRadius(pRect, const Radius.circular(4)), Paint()..color = boxColor);
    canvas.drawRRect(RRect.fromRectAndRadius(pRect, const Radius.circular(4)), Paint()..color = Colors.white38..style = PaintingStyle.stroke);

    final textPainter = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: rect.width * 0.55)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(rect.left + (rect.width - textPainter.width) / 2, rect.top + (rect.height - textPainter.height) / 2));
  }

  void _drawFighterSprite(Canvas canvas, Rect rect, ArenaFighter fighter) {
    canvas.save();
    canvas.translate(rect.left, rect.top);

    final isMoving = fighter.isHuman ? vm.isHumanMoving : (fighter.moveCooldown > 0);
    final direction = fighter.isHuman
        ? (vm.holdDx < 0
            ? CharacterDirection.left
            : (vm.holdDx > 0
                ? CharacterDirection.right
                : (vm.holdDy < 0 ? CharacterDirection.up : CharacterDirection.down)))
        : CharacterDirection.down;

    final animTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final state = isMoving ? CharacterAnimState.walk : CharacterAnimState.idle;

    final painter = FirefighterCharacterPainter(
      animTime: animTime,
      state: state,
      direction: direction,
      suitColor: fighter.bodyColor,
      helmetColor: fighter.hatColor,
      showShadow: true,
      showHose: false,
    );

    painter.paint(canvas, rect.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PlayingWithFirePainter oldDelegate) => true;
}

class FighterPortraitPainter extends CustomPainter {
  final Color hatColor;
  final Color bodyColor;
  final bool isAlive;

  FighterPortraitPainter({
    required this.hatColor,
    required this.bodyColor,
    required this.isAlive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final painter = FirefighterCharacterPainter(
      animTime: 0,
      state: isAlive ? CharacterAnimState.idle : CharacterAnimState.hit,
      direction: CharacterDirection.down,
      suitColor: isAlive ? bodyColor : Colors.grey,
      helmetColor: isAlive ? hatColor : Colors.grey.shade600,
      showShadow: false,
      showHose: false,
    );
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant FighterPortraitPainter oldDelegate) =>
      oldDelegate.hatColor != hatColor ||
      oldDelegate.bodyColor != bodyColor ||
      oldDelegate.isAlive != isAlive;
}
