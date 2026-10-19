import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/character/animated_character_painter.dart';
import '../core/character/character_state.dart';
import '../models/game_elements.dart';
import '../viewmodels/gameplay_viewmodel.dart';
import '../services/api_service.dart';
import 'connection_notice.dart';
import 'widgets/touch_controls.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Timer? _connectionTimer;
  String? _connectionMessage;
  bool _checkingConnection = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConnection());
    _connectionTimer = Timer.periodic(const Duration(seconds: 6), (_) => _checkConnection());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _connectionTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnection() async {
    if (_checkingConnection || !mounted) return;
    _checkingConnection = true;
    final api = context.read<ApiService>();
    final internet = await api.checkInternetConnection();
    final server = internet && await api.checkServerConnection();
    if (mounted) {
      final message = !internet
          ? 'İnternet bağlantısı kesildi • Çevrimdışı modda devam ediyorsun'
          : !server
              ? 'Oyun sunucusuyla bağlantı koptu • Bağlantı yeniden deneniyor'
              : null;
      if (_connectionMessage != message) setState(() => _connectionMessage = message);
    }
    _checkingConnection = false;
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

    final isUp =
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyW);
    final isDown =
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyS);
    final isLeft =
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyA);
    final isRight =
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight) ||
        _pressedKeys.contains(LogicalKeyboardKey.keyD);

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
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final controlSize = (constraints.maxHeight * 0.40).clamp(
                68.0,
                104.0,
              );
              return Column(
                children: [
                  const FightersStatusStrip(),
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Center(
                                child: VirtualTouchPad(
                                  size: controlSize,
                                  onDirectionChanged: (dx, dy) =>
                                      vm.setMovementDirection(dx, dy),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  const Positioned.fill(child: ArenaViewport()),
                                  if (_connectionMessage != null)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      top: 0,
                                      child: ConnectionAlert(
                                        message: _connectionMessage!,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Center(
                                child: GlowingActionButton(
                                  label: 'DİNAMİT',
                                  iconEmoji: '🧨',
                                  size: controlSize * 0.82,
                                  onPressed: vm.placeDynamite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 4,
                          left: controlSize + 14,
                          child: const Row(
                            children: [
                              TimerBadge(),
                              SizedBox(width: 8),
                              ScoreBadge(),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 2,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.refresh, color: Colors.amberAccent, size: 20),
                            tooltip: 'Arenayı yeniden başlat',
                            onPressed: () {
                              _pressedKeys.clear();
                              vm.startNewGame();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
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
    final timerText = context.select<GameplayViewModel, String>(
      (vm) => vm.formattedTimer,
    );
    final isSuddenDeath = context.select<GameplayViewModel, bool>(
      (vm) => vm.isSuddenDeath,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: isSuddenDeath ? Colors.red.shade900 : Colors.black87,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSuddenDeath ? Colors.redAccent : Colors.amber,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: isSuddenDeath ? Colors.redAccent : Colors.amber,
          ),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.amberAccent,
      ),
    );
  }
}

/// Bildirim Bandı
class NotificationBanner extends StatelessWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final notification = context.select<GameplayViewModel, String?>(
      (vm) => vm.lastNotification,
    );
    if (notification == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      color: const Color(0xFF0F172A),
      child: Text(
        notification,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.amber,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Sol Panel (Fighters Sidebar): Sabit boyutlu ve RepaintBoundary ile korumalı
class FightersSidebar extends StatelessWidget {
  const FightersSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final fighters = context.select<GameplayViewModel, List<ArenaFighter>>(
      (vm) => vm.fighters,
    );

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
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.5),
                ),
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
                itemExtent:
                    110, // Sabit eleman boyutu (Optimizasyon: 2.2 Sabit Boyutlar)
                itemBuilder: (context, index) =>
                    FighterCard(fighter: fighters[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact player state rail kept above the arena so the playfield stays wide.
class FightersStatusStrip extends StatelessWidget {
  const FightersStatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final fighters = context.select<GameplayViewModel, List<ArenaFighter>>(
      (vm) => vm.fighters,
    );
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        itemCount: fighters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final fighter = fighters[index];
          final alive = fighter.status == PlayerStatus.alive;
          return Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF202938),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: alive
                    ? fighter.hatColor.withValues(alpha: .8)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 42,
                  child: CustomPaint(
                    painter: FighterPortraitPainter(
                      hatColor: fighter.hatColor,
                      bodyColor: fighter.bodyColor,
                      isAlive: alive,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fighter.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            alive ? Icons.favorite : Icons.close,
                            size: 12,
                            color: alive
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ],
                      ),
                      if (!fighter.isDisconnected) const SizedBox(height: 5),
                      if (!fighter.isDisconnected) ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fighter.health.clamp(0, 100) / 100,
                          minHeight: 5,
                          backgroundColor: Colors.black45,
                          valueColor: AlwaysStoppedAnimation(
                            fighter.health > 40
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                      ),
                      if (!fighter.isDisconnected) const SizedBox(height: 2),
                      Text(
                        fighter.isDisconnected ? 'OYUNDAN DÜŞTÜ' : '${fighter.health}%  •  ${fighter.wins} galibiyet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
                  color: isAlive
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF64748B),
                    width: 1.5,
                  ),
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
                  child: Text(
                    fighter.isDisconnected ? 'DÜŞTÜ' : 'K.O.',
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
                const Text(
                  'GAMES:',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${fighter.wins}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardRatio = GameplayViewModel.cols / GameplayViewModel.rows;
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
                  child: RepaintBoundary(
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
        );
      },
    );
  }
}

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

class PowerUpBadges extends StatelessWidget {
  const PowerUpBadges({super.key});

  @override
  Widget build(BuildContext context) {
    final activeCount = context.select<GameplayViewModel, int>(
      (vm) => vm.activeDynamiteCount,
    );
    final maxDynamites = context.select<GameplayViewModel, int>(
      (vm) => vm.humanPlayer.maxDynamites,
    );
    final range = context.select<GameplayViewModel, int>(
      (vm) => vm.humanPlayer.dynamiteRange,
    );
    final speed = context.select<GameplayViewModel, double>(
      (vm) => vm.humanPlayer.speed,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBadge(
          '🧨 DİNAMİT',
          '$activeCount/$maxDynamites',
          Colors.redAccent,
        ),
        const SizedBox(height: 4),
        _buildBadge('⚡ MENZİL', '$range', Colors.amberAccent),
        const SizedBox(height: 4),
        _buildBadge(
          '🛼 HIZ',
          '${speed.toStringAsFixed(2)}x',
          Colors.cyanAccent,
        ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
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
  static final Paint _floorLightPaint = Paint()
    ..color = const Color(0xFF343A43);
  static final Paint _floorDarkPaint = Paint()..color = const Color(0xFF2D333C);
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
  static final Paint _dynSlideStickPaint = Paint()
    ..color = Colors.amber.shade800;
  static final Paint _dynStickLinePaint = Paint()
    ..color = const Color(0xFF991B1B)
    ..strokeWidth = 1.5;
  static final Paint _dynTapePaint = Paint()..color = const Color(0xFF18181B);
  static final Paint _dynFusePaint = Paint()
    ..color = Colors.white70
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke;

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
          canvas.drawRect(
            rect,
            (r + c).isEven ? _floorLightPaint : _floorDarkPaint,
          );
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
      _drawDynamite(
        canvas,
        rect,
        isSliding: dyn.slideDx != 0 || dyn.slideDy != 0,
        timeLeft: dyn.timeLeft,
      );
    }

    // 5. Patlama Alevleri
    for (final exp in vm.explosions) {
      final rect = Rect.fromLTWH(exp.x * cellW, exp.y * cellH, cellW, cellH);
      _drawExplosion(canvas, rect, exp);
    }

    // 6. Savaşçılar (Oyuncu ve Botlar)
    for (final fighter in vm.fighters) {
      if (fighter.status == PlayerStatus.alive) {
        final rect = Rect.fromLTWH(
          fighter.x * cellW,
          fighter.y * cellH,
          cellW,
          cellH,
        );
        _drawFighterSprite(canvas, rect, fighter);
      }
    }
  }

  void _drawStoneBlock(Canvas canvas, Rect rect) {
    final inset = rect.deflate(rect.shortestSide * .08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(rect.shortestSide * .12)),
      _stonePaint,
    );
    canvas.drawLine(
      inset.topLeft,
      inset.topRight,
      _stoneLightPaint..strokeWidth = rect.shortestSide * .08,
    );
    canvas.drawLine(
      inset.topLeft,
      inset.bottomLeft,
      _stoneLightPaint..strokeWidth = rect.shortestSide * .08,
    );
    canvas.drawLine(
      inset.bottomLeft,
      inset.bottomRight,
      _stoneDarkPaint..strokeWidth = rect.shortestSide * .08,
    );
    canvas.drawLine(
      inset.topRight,
      inset.bottomRight,
      _stoneDarkPaint..strokeWidth = rect.shortestSide * .08,
    );
    final face = inset.deflate(rect.shortestSide * .15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(rect.shortestSide * .08)),
      Paint()..color = const Color(0xFF998A63),
    );
    final mortar = Paint()
      ..color = const Color(0xFF6F6247)
      ..strokeWidth = rect.shortestSide * .035;
    canvas.drawLine(
      Offset(face.left, face.center.dy),
      Offset(face.right, face.center.dy),
      mortar,
    );
    canvas.drawLine(
      Offset(face.center.dx, face.top),
      Offset(face.center.dx, face.bottom),
      mortar,
    );
    canvas.drawCircle(
      Offset(face.left + face.width * .25, face.top + face.height * .25),
      rect.shortestSide * .035,
      Paint()..color = const Color(0xFFD6C69A),
    );
  }

  void _drawGreyStoneBlock(Canvas canvas, Rect rect) {
    final inset = rect.deflate(rect.shortestSide * .08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inset, Radius.circular(rect.shortestSide * .12)),
      _greyStonePaint,
    );
    final edge = rect.shortestSide * .075;
    canvas.drawLine(
      inset.topLeft,
      inset.topRight,
      _greyStoneLightPaint..strokeWidth = edge,
    );
    canvas.drawLine(
      inset.topLeft,
      inset.bottomLeft,
      _greyStoneLightPaint..strokeWidth = edge,
    );
    canvas.drawLine(
      inset.bottomLeft,
      inset.bottomRight,
      _greyStoneDarkPaint..strokeWidth = edge,
    );
    canvas.drawLine(
      inset.topRight,
      inset.bottomRight,
      _greyStoneDarkPaint..strokeWidth = edge,
    );
    final face = inset.deflate(rect.shortestSide * .15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(rect.shortestSide * .08)),
      _greyStoneInnerPaint,
    );
    final crack = Path()
      ..moveTo(face.left + face.width * .2, face.top + face.height * .12)
      ..lineTo(face.center.dx, face.center.dy)
      ..lineTo(face.right - face.width * .18, face.center.dy)
      ..lineTo(
        face.center.dx + face.width * .06,
        face.bottom - face.height * .08,
      );
    canvas.drawPath(
      crack,
      Paint()
        ..color = const Color(0xFFCBD5E1)
        ..strokeWidth = edge * .45
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawBarrel(Canvas canvas, Rect rect) {
    final barrelRect = rect.deflate(rect.shortestSide * .12);
    canvas.drawOval(
      Rect.fromLTWH(
        barrelRect.left + barrelRect.width * .12,
        barrelRect.bottom - barrelRect.height * .10,
        barrelRect.width * .85,
        barrelRect.height * .16,
      ),
      Paint()..color = Colors.black.withValues(alpha: .42),
    );
    final barrelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF991B1B), Color(0xFF7F1D1D), Color(0xFF450A0A)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(barrelRect);

    final rrect = RRect.fromRectAndRadius(barrelRect, const Radius.circular(3));
    canvas.drawRRect(rrect, barrelPaint);

    final y1 = barrelRect.top + barrelRect.height * 0.28;
    final y2 = barrelRect.top + barrelRect.height * 0.72;

    canvas.drawLine(
      Offset(barrelRect.left + 1, y1),
      Offset(barrelRect.right - 1, y1),
      _barrelBandPaint,
    );
    canvas.drawLine(
      Offset(barrelRect.left + 1, y2),
      Offset(barrelRect.right - 1, y2),
      _barrelBandPaint,
    );

    canvas.drawOval(
      Rect.fromLTWH(
        barrelRect.left + 2,
        barrelRect.top + 1,
        barrelRect.width - 4,
        barrelRect.height * 0.22,
      ),
      _barrelLidPaint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        barrelRect.left + barrelRect.width * .23,
        barrelRect.top + barrelRect.height * .04,
        barrelRect.width * .20,
        barrelRect.height * .08,
      ),
      Paint()..color = Colors.white.withValues(alpha: .35),
    );
    final hazard = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = rect.shortestSide * .07;
    canvas.drawLine(
      Offset(barrelRect.center.dx, barrelRect.top + barrelRect.height * .37),
      Offset(barrelRect.center.dx, barrelRect.top + barrelRect.height * .64),
      hazard,
    );
  }

  void _drawDynamite(
    Canvas canvas,
    Rect rect, {
    bool isSliding = false,
    required double timeLeft,
  }) {
    final center = rect.center;
    final w = rect.width * 0.70;
    final h = rect.height * 0.60;

    final stickRect = Rect.fromCenter(center: center, width: w, height: h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        stickRect,
        Radius.circular(rect.shortestSide * .16),
      ),
      isSliding ? _dynSlideStickPaint : _dynStickPaint,
    );

    canvas.drawLine(
      Offset(stickRect.left, stickRect.top + h * 0.33),
      Offset(stickRect.right, stickRect.top + h * 0.33),
      _dynStickLinePaint,
    );
    canvas.drawLine(
      Offset(stickRect.left, stickRect.top + h * 0.66),
      Offset(stickRect.right, stickRect.top + h * 0.66),
      _dynStickLinePaint,
    );

    final tapeRect = Rect.fromCenter(
      center: center,
      width: w * 0.35,
      height: h,
    );
    canvas.drawRect(tapeRect, _dynTapePaint);

    final shine = Paint()..color = Colors.white.withValues(alpha: .30);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          stickRect.left + w * .09,
          stickRect.top + h * .12,
          w * .12,
          h * .25,
        ),
        Radius.circular(rect.shortestSide * .06),
      ),
      shine,
    );

    final path = Path();
    path.moveTo(stickRect.right - 2, stickRect.top + 2);
    path.quadraticBezierTo(
      stickRect.right + 4,
      stickRect.top - 6,
      stickRect.right + 2,
      stickRect.top - 10,
    );
    canvas.drawPath(path, _dynFusePaint);

    final blink = (timeLeft * 8).floor().isEven;
    final sparkCenter = Offset(
      stickRect.right + rect.width * .06,
      stickRect.top - rect.height * .10,
    );
    if (blink) {
      final sparkPaint = Paint()..color = const Color(0xFFFFD54F);
      canvas.drawCircle(sparkCenter, rect.shortestSide * .13, sparkPaint);
      canvas.drawCircle(
        sparkCenter,
        rect.shortestSide * .065,
        _whiteFlashPaint,
      );
      canvas.drawLine(
        sparkCenter.translate(-rect.width * .12, 0),
        sparkCenter.translate(rect.width * .12, 0),
        Paint()
          ..color = Colors.orangeAccent
          ..strokeWidth = rect.shortestSide * .04,
      );
      canvas.drawLine(
        sparkCenter.translate(0, -rect.height * .12),
        sparkCenter.translate(0, rect.height * .12),
        Paint()
          ..color = Colors.orangeAccent
          ..strokeWidth = rect.shortestSide * .04,
      );
    }
  }

  void _drawExplosion(Canvas canvas, Rect rect, ExplosionTile explosion) {
    final life = (explosion.duration / .35).clamp(0.0, 1.0).toDouble();
    final bounds = rect.deflate(rect.shortestSide * .04);
    final center = bounds.center;
    final phase = (explosion.x * 13 + explosion.y * 7) * .13;
    final burst = Path();
    for (var point = 0; point < 16; point++) {
      final angle = phase + point * pi / 8;
      final radius =
          bounds.shortestSide * (point.isEven ? .49 : .31) * (.72 + life * .28);
      final position =
          center + Offset(cos(angle) * radius, sin(angle) * radius);
      if (point == 0) {
        burst.moveTo(position.dx, position.dy);
      } else {
        burst.lineTo(position.dx, position.dy);
      }
    }
    burst.close();
    final gradient = Paint()
      ..shader = RadialGradient(
        colors: explosion.isCenter
            ? [
                const Color(0xFFFFFFF2),
                const Color(0xFFFFE66D),
                const Color(0xFFFF5A1F).withValues(alpha: life),
              ]
            : [
                const Color(0xFFFFF3A3),
                const Color(0xFFFFA629).withValues(alpha: life),
                const Color(0xFFE83A18).withValues(alpha: life),
              ],
      ).createShader(bounds);
    canvas.drawPath(burst, gradient);
    final core = Paint()
      ..color = const Color(0xFFFFF8C5).withValues(alpha: life);
    canvas.drawCircle(
      center,
      bounds.shortestSide * (explosion.isCenter ? .23 : .15) * life,
      core,
    );
    for (var ember = 0; ember < 4; ember++) {
      final angle = phase + ember * pi / 2 + pi / 4;
      final point =
          center +
          Offset(
            cos(angle) * bounds.width * .34,
            sin(angle) * bounds.height * .34,
          );
      canvas.drawCircle(
        point,
        bounds.shortestSide * .045 * life,
        Paint()..color = const Color(0xFFFFD166).withValues(alpha: life),
      );
    }
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
    canvas.drawRRect(
      RRect.fromRectAndRadius(pRect, const Radius.circular(4)),
      Paint()..color = boxColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pRect, const Radius.circular(4)),
      Paint()
        ..color = Colors.white38
        ..style = PaintingStyle.stroke,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: rect.width * 0.55),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawFighterSprite(Canvas canvas, Rect rect, ArenaFighter fighter) {
    canvas.save();
    canvas.translate(rect.left, rect.top);

    final isMoving = fighter.isHuman
        ? vm.isHumanMoving
        : (fighter.moveCooldown > 0);
    final direction = fighter.isHuman
        ? (vm.holdDx < 0
              ? CharacterDirection.left
              : (vm.holdDx > 0
                    ? CharacterDirection.right
                    : (vm.holdDy < 0
                          ? CharacterDirection.up
                          : CharacterDirection.down)))
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
      suitColor: isAlive ? bodyColor : Colors.black,
      helmetColor: isAlive ? hatColor : Colors.black,
      skinColor: isAlive ? const Color(0xFFFFD1A4) : Colors.black,
      accessoryColor: isAlive ? const Color(0xFF38BDF8) : Colors.black,
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
