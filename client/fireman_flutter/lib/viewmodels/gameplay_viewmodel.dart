import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_elements.dart';

class GameplayViewModel extends ChangeNotifier {
  // Klasik Playing with Fire 2 / Bomberman Haritası (15 x 13)
  static const int cols = 15;
  static const int rows = 13;

  late List<List<CellType>> _grid;
  final List<Dynamite> _dynamites = [];
  final List<ExplosionTile> _explosions = [];
  final List<PowerUpItem> _powerUps = [];
  final List<ArenaFighter> _fighters = [];

  int _totalPlayerCount = 4;
  int _score = 0;
  String? _lastNotification;
  Timer? _gameLoopTimer;
  final Random _random = Random();

  // 2 Dakikalık Maç Süresi ve Ani Ölüm (Sudden Death)
  double _remainingSeconds = 120.0;
  bool _isSuddenDeath = false;
  int _suddenDeathStep = 0;
  final List<Point<int>> _spiralOrder = [];

  // Oyun Bitti (Game Over) Durumu
  bool _isGameOver = false;
  String? _gameOverTitle;
  String? _gameOverMessage;

  // Kesintisiz Basılı Tutma Hareketi (Continuous Movement)
  int _holdDx = 0;
  int _holdDy = 0;
  double _playerMoveCooldown = 0.0;

  // Getters
  List<List<CellType>> get grid => _grid;
  List<Dynamite> get dynamites => List.unmodifiable(_dynamites);
  List<ExplosionTile> get explosions => List.unmodifiable(_explosions);
  List<PowerUpItem> get powerUps => List.unmodifiable(_powerUps);
  List<ArenaFighter> get fighters => List.unmodifiable(_fighters);

  ArenaFighter get humanPlayer => _fighters.firstWhere((f) => f.isHuman, orElse: () => _fighters.first);
  int get totalPlayerCount => _totalPlayerCount;
  int get score => _score;
  String? get lastNotification => _lastNotification;
  int get activeDynamiteCount => _dynamites.where((d) => d.ownerId == humanPlayer.id).length;
  double get remainingSeconds => _remainingSeconds;
  bool get isSuddenDeath => _isSuddenDeath;
  bool get isGameOver => _isGameOver;
  String? get gameOverTitle => _gameOverTitle;
  String? get gameOverMessage => _gameOverMessage;
  int get holdDx => _holdDx;
  int get holdDy => _holdDy;
  bool get isHumanMoving => _holdDx != 0 || _holdDy != 0;

  String get formattedTimer {
    final s = _remainingSeconds.ceil();
    if (s <= 0) return 'ANİ ÖLÜM!';
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  GameplayViewModel() {
    _initSpiralOrder();
    startNewGame();
  }

  void _initSpiralOrder() {
    _spiralOrder.clear();
    int top = 1;
    int bottom = rows - 2;
    int left = 1;
    int right = cols - 2;

    while (top <= bottom && left <= right) {
      for (int c = left; c <= right; c++) {
        _spiralOrder.add(Point(c, top));
      }
      top++;
      for (int r = top; r <= bottom; r++) {
        _spiralOrder.add(Point(right, r));
      }
      right--;
      if (top <= bottom) {
        for (int c = right; c >= left; c--) {
          _spiralOrder.add(Point(c, bottom));
        }
        bottom--;
      }
      if (left <= right) {
        for (int r = bottom; r >= top; r--) {
          _spiralOrder.add(Point(left, r));
        }
        left++;
      }
    }
  }

  void setPlayerCount(int count) {
    _totalPlayerCount = count.clamp(2, 4);
    startNewGame();
  }

  void startNewGame() {
    _gameLoopTimer?.cancel();
    _dynamites.clear();
    _explosions.clear();
    _powerUps.clear();
    _fighters.clear();

    _remainingSeconds = 120.0;
    _isSuddenDeath = false;
    _suddenDeathStep = 0;
    _holdDx = 0;
    _holdDy = 0;
    _playerMoveCooldown = 0.0;
    _isGameOver = false;
    _gameOverTitle = null;
    _gameOverMessage = null;

    // 1. DÖRT KARAKTERİ OLUŞTUR (Başlangıç Hızı: 0.7)
    _fighters.add(ArenaFighter(
      id: 0,
      name: 'Oyuncu 1',
      hatColor: const Color(0xFF1D4ED8),
      bodyColor: const Color(0xFF2563EB),
      isHuman: true,
      x: 1,
      y: 1,
      speed: 0.7,
    ));

    if (_totalPlayerCount >= 2) {
      _fighters.add(ArenaFighter(
        id: 1,
        name: 'Kırmızı',
        hatColor: const Color(0xFFB91C1C),
        bodyColor: const Color(0xFFDC2626),
        isHuman: false,
        x: cols - 2,
        y: rows - 2,
        speed: 0.7,
      ));
    }

    if (_totalPlayerCount >= 3) {
      _fighters.add(ArenaFighter(
        id: 2,
        name: 'Yeşil',
        hatColor: const Color(0xFF15803D),
        bodyColor: const Color(0xFF16A34A),
        isHuman: false,
        x: cols - 2,
        y: 1,
        speed: 0.7,
      ));
    }

    if (_totalPlayerCount >= 4) {
      _fighters.add(ArenaFighter(
        id: 3,
        name: 'Sarı',
        hatColor: const Color(0xFFA16207),
        bodyColor: const Color(0xFFCA8A04),
        isHuman: false,
        x: 1,
        y: rows - 2,
        speed: 0.7,
      ));
    }

    _generateMapWithDynamicBarrels();

    _lastNotification = 'Playing with Fire 2 Başladı! Süre: 2:00. Varilleri patlat!';
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 30), (_) => _tick(0.03));
    notifyListeners();
  }

  void _generateMapWithDynamicBarrels() {
    _grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        if (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) {
          return CellType.wall;
        }
        if (r % 2 == 0 && c % 2 == 0) {
          return CellType.wall;
        }

        final isCorner = (r <= 2 && c <= 2) ||
            (r >= rows - 3 && c >= cols - 3) ||
            (r <= 2 && c >= cols - 3) ||
            (r >= rows - 3 && c <= 2);

        if (isCorner) return CellType.empty;

        return _random.nextDouble() < 0.70 ? CellType.barrel : CellType.empty;
      });
    });
  }

  // --- BASILI TUTMA & HAREKET KONTROLÜ (ÇAPRAZ GEÇİŞ YOK: SADECE DİK) ---
  void setMovementDirection(int dx, int dy) {
    // Çapraz hareketi engelle: ya sadece yatay ya sadece dikey
    if (dx != 0 && dy != 0) {
      dy = 0; // Yatay öncelikli dik hareket
    }

    _holdDx = dx;
    _holdDy = dy;
    if (dx != 0 || dy != 0) {
      if (_playerMoveCooldown <= 0) {
        _executePlayerMove(dx, dy);
        final player = humanPlayer;
        _playerMoveCooldown = 0.16 / player.speed;
      }
    }
  }

  void _executePlayerMove(int dx, int dy) {
    final player = humanPlayer;
    if (player.status == PlayerStatus.eliminated || _isGameOver) return;

    final targetX = player.x + dx;
    final targetY = player.y + dy;

    if (targetX < 0 || targetX >= cols || targetY < 0 || targetY >= rows) return;

    // Duvara, varile veya kapanan gri taşa çarpma
    if (_grid[targetY][targetX] != CellType.empty) return;

    // Hedef hücrede dinamit var mı?
    final dynIndex = _dynamites.indexWhere((d) => d.x == targetX && d.y == targetY);
    if (dynIndex != -1) {
      final kickedDyn = _dynamites[dynIndex];
      _kickDynamite(kickedDyn, dx, dy);
    }

    player.x = targetX;
    player.y = targetY;

    _checkPowerUpPickup(player);
    notifyListeners();
  }

  void _kickDynamite(Dynamite dyn, int dx, int dy) {
    dyn.slideDx = dx;
    dyn.slideDy = dy;
    dyn.slideCooldown = 0.0;
  }

  void placeDynamite() {
    final player = humanPlayer;
    if (player.status == PlayerStatus.eliminated || _isGameOver) return;

    final activeCount = _dynamites.where((d) => d.ownerId == player.id).length;
    if (activeCount >= player.maxDynamites) return;

    if (_dynamites.any((d) => d.x == player.x && d.y == player.y)) return;

    _dynamites.add(Dynamite(
      x: player.x,
      y: player.y,
      range: player.dynamiteRange,
      ownerId: player.id,
    ));

    notifyListeners();
  }

  void _checkPowerUpPickup(ArenaFighter fighter) {
    final index = _powerUps.indexWhere((p) => p.x == fighter.x && p.y == fighter.y);
    if (index != -1) {
      final item = _powerUps.removeAt(index);
      if (fighter.isHuman) {
        _score += 500;
      }

      switch (item.type) {
        case PowerUpType.dynamiteRange:
          fighter.dynamiteRange += 1;
          if (fighter.isHuman) _lastNotification = '⚡ Şimşek Alındı (+500 Puan)! Dinamit alev menzili: ${fighter.dynamiteRange}';
          break;
        case PowerUpType.rollerSkate:
          fighter.speed += 0.20;
          if (fighter.isHuman) _lastNotification = '🛼 Paten Alındı (+500 Puan)! Hız arttı: ${fighter.speed.toStringAsFixed(2)}x';
          break;
        case PowerUpType.extraDynamite:
          fighter.maxDynamites += 1;
          if (fighter.isHuman) _lastNotification = '🧨 Dinamit Paketi Alındı (+500 Puan)! Azami dinamit: ${fighter.maxDynamites}';
          break;
        case PowerUpType.shield:
          fighter.health = (fighter.health + 35).clamp(0, 100);
          if (fighter.isHuman) _lastNotification = '🛡️ Zırh / Can Alındı (+500 Puan)! Kalan Can: ${fighter.health} HP';
          break;
      }
    }
  }

  // --- OYUN DÖNGÜSÜ ---
  void _tick(double dt) {
    bool stateChanged = false;

    // 1. Geri Sayım & Ani Ölüm (Sudden Death)
    if (_remainingSeconds > 0 && !_isGameOver) {
      _remainingSeconds -= dt;
      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        _isSuddenDeath = true;
        _lastNotification = '⚠️ SÜRE DOLDU! ALAN AŞIRI HIZLI KAPANMAYA BAŞLADI!';
        stateChanged = true;
      }
    } else if (_isSuddenDeath && !_isGameOver) {
      // Aşırı hızlı kapanma: her tick'te 1 kare kapanır (30 kare/saniye)!
      if (_suddenDeathStep < _spiralOrder.length) {
        final pt = _spiralOrder[_suddenDeathStep++];
        _grid[pt.y][pt.x] = CellType.suddenDeath;

        _powerUps.removeWhere((p) => p.x == pt.x && p.y == pt.y);
        _dynamites.removeWhere((d) => d.x == pt.x && d.y == pt.y);

        for (final f in _fighters) {
          if (f.status == PlayerStatus.alive && f.x == pt.x && f.y == pt.y) {
            f.health = 0;
            f.status = PlayerStatus.eliminated;
            if (f.isHuman) {
              _score = max(0, _score - 1000);
              _lastNotification = '💀 Duvar altında ezildin! (-1000 Puan)';
            }
          }
        }
        stateChanged = true;
        _checkMatchEndCondition();
      }
    }

    if (_isGameOver) {
      if (stateChanged) notifyListeners();
      return;
    }

    // 2. Basılı Tutulan Tuşla Oyuncu Hareketi
    if (_holdDx != 0 || _holdDy != 0) {
      _playerMoveCooldown -= dt;
      if (_playerMoveCooldown <= 0) {
        _executePlayerMove(_holdDx, _holdDy);
        final player = humanPlayer;
        _playerMoveCooldown = 0.14 / player.speed;
        stateChanged = true;
      }
    }

    // 3. Kayan Dinamitlerin Hareketi (KICK)
    for (final dyn in _dynamites) {
      if (dyn.slideDx != 0 || dyn.slideDy != 0) {
        dyn.slideCooldown -= dt;
        if (dyn.slideCooldown <= 0) {
          dyn.slideCooldown = 0.08;
          final nx = dyn.x + dyn.slideDx;
          final ny = dyn.y + dyn.slideDy;

          if (nx >= 0 && nx < cols && ny >= 0 && ny < rows && _grid[ny][nx] == CellType.empty) {
            final hasOtherDyn = _dynamites.any((d) => d != dyn && d.x == nx && d.y == ny);
            if (!hasOtherDyn) {
              dyn.x = nx;
              dyn.y = ny;
              stateChanged = true;
            } else {
              dyn.slideDx = 0;
              dyn.slideDy = 0;
            }
          } else {
            dyn.slideDx = 0;
            dyn.slideDy = 0;
          }
        }
      }
    }

    // 4. Patlama Alevlerini Güncelle
    for (int i = _explosions.length - 1; i >= 0; i--) {
      _explosions[i].duration -= dt;
      if (_explosions[i].duration <= 0) {
        _explosions.removeAt(i);
        stateChanged = true;
      }
    }

    // 5. Dinamit Sayaçlarını Güncelle
    for (int i = _dynamites.length - 1; i >= 0; i--) {
      _dynamites[i].timeLeft -= dt;
      if (_dynamites[i].timeLeft <= 0) {
        final d = _dynamites.removeAt(i);
        _detonateDynamite(d);
        stateChanged = true;
      }
    }

    // 6. Akıllı ve Optimize Bot AI
    _updateBotAI(dt);

    // Canlı oyuncu durum kontrolü
    _checkMatchEndCondition();

    if (stateChanged) {
      notifyListeners();
    }
  }

  void _checkMatchEndCondition() {
    if (_isGameOver) return;

    final aliveFighters = _fighters.where((f) => f.status == PlayerStatus.alive).toList();

    // Tüm oyuncular öldüyse veya sadece 1 kişi kaldıysa
    if (aliveFighters.isEmpty) {
      _triggerGameOverAllWallsClose(
        title: 'OYUN BİTTİ',
        message: 'Tüm savaşçılar elendi! Kazanan yok.',
      );
    } else if (aliveFighters.length == 1) {
      final winner = aliveFighters.first;
      winner.wins += 1;
      _triggerGameOverAllWallsClose(
        title: winner.isHuman ? '🏆 ZAFER!' : 'OYUN BİTTİ',
        message: winner.isHuman
            ? 'Tebrikler! Arenada hayatta kalan son kişi oldun!'
            : '${winner.name} son hayatta kalan şampiyon oldu!',
      );
    }
  }

  // Tüm oyuncular ölünce veya oyun bitince haritanın tamamını aynı anda gri duvarlarla kapatır
  void _triggerGameOverAllWallsClose({required String title, required String message}) {
    _isGameOver = true;
    _gameOverTitle = title;
    _gameOverMessage = message;

    // Tüm iç ızgarayı aynı anda gri duvara dönüştür
    for (int r = 1; r < rows - 1; r++) {
      for (int c = 1; c < cols - 1; c++) {
        _grid[r][c] = CellType.suddenDeath;
      }
    }

    _dynamites.clear();
    _explosions.clear();
    _powerUps.clear();
    _lastNotification = '🏁 $title - $message';
    notifyListeners();
  }

  // --- BOT YAPAY ZEKASI ---
  void _updateBotAI(double dt) {
    for (final bot in _fighters) {
      if (bot.isHuman || bot.status == PlayerStatus.eliminated) continue;

      bot.moveCooldown -= dt;
      if (bot.moveCooldown > 0) continue;

      bot.moveCooldown = (0.24 / bot.speed) + (_random.nextDouble() * 0.06);

      // 1. Tehlikeden Kaçış
      final inDanger = _isTileInDanger(bot.x, bot.y);
      if (inDanger) {
        final escapeDir = _findSafeNeighbor(bot.x, bot.y);
        if (escapeDir != null) {
          _tryMoveFighter(bot, escapeDir[0], escapeDir[1]);
          _checkPowerUpPickup(bot);
          continue;
        }
      }

      // 2. Dinamit Tuzağı Kurma (Diğer oyunculara ve varillere)
      final activeBotDyns = _dynamites.where((d) => d.ownerId == bot.id).length;
      final canPlace = activeBotDyns < bot.maxDynamites && !inDanger;

      final nearPlayer = _isAdjacentToHuman(bot.x, bot.y);
      final nearBarrel = _hasAdjacentBarrel(bot.x, bot.y);

      if (canPlace && (nearPlayer || (nearBarrel && _random.nextDouble() < 0.45))) {
        if (!_dynamites.any((d) => d.x == bot.x && d.y == bot.y)) {
          _dynamites.add(Dynamite(
            x: bot.x,
            y: bot.y,
            range: bot.dynamiteRange,
            ownerId: bot.id,
          ));
          bot.moveCooldown = 0.05;
          continue;
        }
      }

      // 3. Güvenli Yönlere Hareket
      final validMoves = _getValidMoves(bot.x, bot.y);
      if (validMoves.isNotEmpty) {
        final safeMoves = validMoves.where((m) => !_isTileInDanger(bot.x + m[0], bot.y + m[1])).toList();
        final selectedMoves = safeMoves.isNotEmpty ? safeMoves : validMoves;

        final chosenMove = selectedMoves[_random.nextInt(selectedMoves.length)];
        _tryMoveFighter(bot, chosenMove[0], chosenMove[1]);
        _checkPowerUpPickup(bot);
      }
    }
  }

  bool _isAdjacentToHuman(int x, int y) {
    final human = humanPlayer;
    if (human.status == PlayerStatus.eliminated) return false;
    return (human.x - x).abs() + (human.y - y).abs() <= 2;
  }

  bool _isTileInDanger(int x, int y) {
    if (_explosions.any((e) => e.x == x && e.y == y)) return true;

    for (final d in _dynamites) {
      if (d.x == x && (d.y - y).abs() <= d.range) {
        if (_hasClearPath(d.x, min(d.y, y), max(d.y, y), isVertical: true)) return true;
      }
      if (d.y == y && (d.x - x).abs() <= d.range) {
        if (_hasClearPath(d.y, min(d.x, x), max(d.x, x), isVertical: false)) return true;
      }
    }
    return false;
  }

  bool _hasClearPath(int fixed, int start, int end, {required bool isVertical}) {
    for (int p = start + 1; p < end; p++) {
      final cell = isVertical ? _grid[p][fixed] : _grid[fixed][p];
      if (cell != CellType.empty) return false;
    }
    return true;
  }

  List<int>? _findSafeNeighbor(int x, int y) {
    const dirs = [
      [0, -1], [0, 1], [-1, 0], [1, 0]
    ];
    for (final d in dirs) {
      final nx = x + d[0];
      final ny = y + d[1];
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows && _grid[ny][nx] == CellType.empty) {
        if (!_dynamites.any((dyn) => dyn.x == nx && dyn.y == ny) && !_isTileInDanger(nx, ny)) {
          return d;
        }
      }
    }
    return null;
  }

  bool _hasAdjacentBarrel(int x, int y) {
    const dirs = [
      [0, -1], [0, 1], [-1, 0], [1, 0]
    ];
    for (final d in dirs) {
      final nx = x + d[0];
      final ny = y + d[1];
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows && _grid[ny][nx] == CellType.barrel) {
        return true;
      }
    }
    return false;
  }

  List<List<int>> _getValidMoves(int x, int y) {
    const dirs = [
      [0, -1], [0, 1], [-1, 0], [1, 0]
    ];
    final moves = <List<int>>[];
    for (final d in dirs) {
      final nx = x + d[0];
      final ny = y + d[1];
      if (nx >= 0 && nx < cols && ny >= 0 && ny < rows && _grid[ny][nx] == CellType.empty) {
        if (!_dynamites.any((dyn) => dyn.x == nx && dyn.y == ny)) {
          moves.add(d);
        }
      }
    }
    return moves;
  }

  bool _tryMoveFighter(ArenaFighter fighter, int dx, int dy) {
    final tx = fighter.x + dx;
    final ty = fighter.y + dy;

    if (tx < 0 || tx >= cols || ty < 0 || ty >= rows) return false;
    if (_grid[ty][tx] != CellType.empty) return false;

    final hasDynamite = _dynamites.any((d) => d.x == tx && d.y == ty);
    if (hasDynamite) return false;

    fighter.x = tx;
    fighter.y = ty;
    return true;
  }

  // --- DİNAMİT PATLAMASI & PUANLAMA KURALLARI ---
  void _detonateDynamite(Dynamite d) {
    _addExplosion(d.x, d.y, isCenter: true);

    const directions = [
      [0, -1], [0, 1], [-1, 0], [1, 0]
    ];

    for (final dir in directions) {
      for (int dist = 1; dist <= d.range; dist++) {
        final tx = d.x + (dir[0] * dist);
        final ty = d.y + (dir[1] * dist);

        if (tx < 0 || tx >= cols || ty < 0 || ty >= rows) break;
        if (_grid[ty][tx] == CellType.wall || _grid[ty][tx] == CellType.suddenDeath) break;

        // Varil Patlatma (100 Puan)
        if (_grid[ty][tx] == CellType.barrel) {
          _grid[ty][tx] = CellType.empty;
          _addExplosion(tx, ty);

          if (d.ownerId == humanPlayer.id) {
            _score += 100;
          }

          _maybeDropPowerUp(tx, ty);
          break;
        }

        // Zincirleme Patlama
        final chained = _dynamites.cast<Dynamite?>().firstWhere(
              (dyn) => dyn?.x == tx && dyn?.y == ty,
              orElse: () => null,
            );
        if (chained != null) {
          chained.timeLeft = 0.04;
        }

        _addExplosion(tx, ty);
      }
    }
  }

  void _addExplosion(int x, int y, {bool isCenter = false}) {
    _explosions.add(ExplosionTile(x: x, y: y, isCenter: isCenter));

    // Hasar & Puanlama Mantığı
    for (final fighter in _fighters) {
      if (fighter.status == PlayerStatus.alive && fighter.x == x && fighter.y == y) {
        fighter.health = max(0, fighter.health - 50);

        if (fighter.isHuman) {
          if (fighter.health <= 0) {
            fighter.status = PlayerStatus.eliminated;
            _score = max(0, _score - 1000);
            _lastNotification = '💀 Elendin! (-1000 Puan)';
          } else {
            _score = max(0, _score - 200);
            _lastNotification = '⚠️ Alev hasarı aldın! Kalan: ${fighter.health} HP';
          }
        } else {
          _score += 1000;
          if (fighter.health <= 0) {
            fighter.status = PlayerStatus.eliminated;
            _lastNotification = '🎯 ${fighter.name} elendi! (+1000 Puan)';
          } else {
            _lastNotification = '💥 ${fighter.name} vuruldu! (+1000 Puan)';
          }
        }
      }
    }
  }

  // Kullanıcı İsteği: Malzeme çıkma olasılığı tam olarak %39 yapıldı
  void _maybeDropPowerUp(int x, int y) {
    if (_random.nextDouble() < 0.39) {
      const types = PowerUpType.values;
      final selected = types[_random.nextInt(types.length)];
      _powerUps.add(PowerUpItem(x: x, y: y, type: selected));
    }
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }
}
