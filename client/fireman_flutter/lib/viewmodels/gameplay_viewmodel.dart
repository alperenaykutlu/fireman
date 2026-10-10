import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_elements.dart';

class GameplayViewModel extends ChangeNotifier {
  static const int cols = 11;
  static const int rows = 9;

  late List<List<CellType>> _grid;
  final List<Bomb> _bombs = [];
  final List<ExplosionTile> _explosions = [];
  final List<PowerUpItem> _powerUps = [];
  final List<BotPlayer> _bots = [];

  int _totalPlayerCount = 4; // 2, 3 veya 4

  // Oyuncu Durumu
  int _playerX = 1;
  int _playerY = 1;
  int _health = 100;
  final int _maxHealth = 100;
  int _maxBombs = 1;
  int _bombRange = 1;
  double _speed = 1.0;
  int _score = 0;
  String? _lastNotification;

  Timer? _gameLoopTimer;

  // Getters
  List<List<CellType>> get grid => _grid;
  List<Bomb> get bombs => List.unmodifiable(_bombs);
  List<ExplosionTile> get explosions => List.unmodifiable(_explosions);
  List<PowerUpItem> get powerUps => List.unmodifiable(_powerUps);
  List<BotPlayer> get bots => List.unmodifiable(_bots);

  int get totalPlayerCount => _totalPlayerCount;
  int get playerX => _playerX;
  int get playerY => _playerY;
  int get health => _health;
  int get maxHealth => _maxHealth;
  int get maxBombs => _maxBombs;
  int get bombRange => _bombRange;
  double get speed => _speed;
  int get score => _score;
  String? get lastNotification => _lastNotification;
  int get activeBombsCount => _bombs.length;

  GameplayViewModel() {
    startNewGame();
  }

  void setPlayerCount(int count) {
    _totalPlayerCount = count.clamp(2, 4);
    startNewGame();
  }

  void startNewGame() {
    _gameLoopTimer?.cancel();
    _bombs.clear();
    _explosions.clear();
    _powerUps.clear();
    _bots.clear();

    _playerX = 1;
    _playerY = 1;
    _health = 100;
    _maxBombs = 1;
    _bombRange = 1;
    _speed = 1.0;
    _score = 0;
    _lastNotification = '$_totalPlayerCount Kişilik Arena Başladı! Varilleri patlat, güçlendiricileri topla!';

    // Botları ekle (Kullanıcı resmindeki Mor ve Yeşil İtfaiyeciler!)
    if (_totalPlayerCount >= 2) {
      _bots.add(BotPlayer(
        x: cols - 2,
        y: 1,
        name: 'Mor İtfaiyeci',
        color: const Color(0xFFA855F7), // Mor
      ));
    }
    if (_totalPlayerCount >= 3) {
      _bots.add(BotPlayer(
        x: 1,
        y: rows - 2,
        name: 'Yeşil İtfaiyeci',
        color: const Color(0xFF22C55E), // Yeşil
      ));
    }
    if (_totalPlayerCount >= 4) {
      _bots.add(BotPlayer(
        x: cols - 2,
        y: rows - 2,
        name: 'Turuncu İtfaiyeci',
        color: const Color(0xFFF97316), // Turuncu
      ));
    }

    // Haritayı oluştur
    _grid = List.generate(rows, (r) {
      return List.generate(cols, (c) {
        // Dış sınır duvarları
        if (r == 0 || r == rows - 1 || c == 0 || c == cols - 1) {
          return CellType.wall;
        }
        // Sabit labirent sütunları
        if (r % 2 == 0 && c % 2 == 0) {
          return CellType.wall;
        }
        // Oyuncu ve botların doğma köşeleri temiz kalmalı
        if ((r <= 2 && c <= 2) || // Sol Üst (Oyuncu)
            (r <= 2 && c >= cols - 3) || // Sağ Üst (Bot 1)
            (r >= rows - 3 && c <= 2) || // Sol Alt (Bot 2)
            (r >= rows - 3 && c >= cols - 3)) { // Sağ Alt (Bot 3)
          return CellType.empty;
        }
        // Kırmızı kırılabilir variller (%65 şansla)
        return Random().nextDouble() < 0.65 ? CellType.barrel : CellType.empty;
      });
    });

    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick(0.05));
    notifyListeners();
  }

  void movePlayer(int dx, int dy) {
    if (_health <= 0) return;

    final targetX = _playerX + dx;
    final targetY = _playerY + dy;

    if (targetX < 0 || targetX >= cols || targetY < 0 || targetY >= rows) return;
    if (_grid[targetY][targetX] != CellType.empty) return;

    final hasBombAtTarget = _bombs.any((b) => b.x == targetX && b.y == targetY);
    if (hasBombAtTarget) return;

    _playerX = targetX;
    _playerY = targetY;

    _checkPowerUpPickup();
    notifyListeners();
  }

  void placeBomb() {
    if (_health <= 0) return;
    if (_bombs.length >= _maxBombs) return;

    if (_bombs.any((b) => b.x == _playerX && b.y == _playerY)) return;

    _bombs.add(Bomb(
      x: _playerX,
      y: _playerY,
      range: _bombRange,
    ));

    notifyListeners();
  }

  void _checkPowerUpPickup() {
    final index = _powerUps.indexWhere((p) => p.x == _playerX && p.y == _playerY);
    if (index != -1) {
      final item = _powerUps.removeAt(index);
      _score += 150;

      switch (item.type) {
        case PowerUpType.lightning:
          _bombRange += 1;
          _lastNotification = '⚡ Şimşek Alındı! Patlama şiddeti: $_bombRange';
          break;
        case PowerUpType.shoe:
          _speed += 0.25;
          _lastNotification = '👟 Ayakkabı Alındı! Hız arttı: ${_speed.toStringAsFixed(2)}x';
          break;
        case PowerUpType.extraBomb:
          _maxBombs += 1;
          _lastNotification = '💣 Bomba Alındı! Maksimum bomba: $_maxBombs';
          break;
        case PowerUpType.heal:
          _health = (_health + 25).clamp(0, _maxHealth);
          _lastNotification = '🔧 Tamir Kiti! Can iyileşti: $_health HP';
          break;
      }
    }
  }

  void _tick(double dt) {
    bool stateChanged = false;

    // Patlama sürelerini güncelle
    for (int i = _explosions.length - 1; i >= 0; i--) {
      _explosions[i].duration -= dt;
      if (_explosions[i].duration <= 0) {
        _explosions.removeAt(i);
        stateChanged = true;
      }
    }

    // Bomba sayaçlarını güncelle
    for (int i = _bombs.length - 1; i >= 0; i--) {
      _bombs[i].timeLeft -= dt;
      if (_bombs[i].timeLeft <= 0) {
        final bomb = _bombs.removeAt(i);
        _detonateBomb(bomb);
        stateChanged = true;
      }
    }

    // Bot Yapay Zekasını Güncelle
    _updateBots(dt);

    if (stateChanged) {
      notifyListeners();
    }
  }

  void _updateBots(double dt) {
    final random = Random();

    for (final bot in _bots) {
      if (bot.health <= 0) continue;

      bot.moveCooldown -= dt;
      if (bot.moveCooldown <= 0) {
        bot.moveCooldown = 0.6 + random.nextDouble() * 0.4; // 0.6-1.0 sn arayla hamle

        const dirs = [
          [0, -1], [0, 1], [-1, 0], [1, 0]
        ];
        dirs.shuffle();

        for (final dir in dirs) {
          final nx = bot.x + dir[0];
          final ny = bot.y + dir[1];

          if (nx > 0 && nx < cols - 1 && ny > 0 && ny < rows - 1) {
            // Önünde varil varsa bomba bırakma şansı
            if (_grid[ny][nx] == CellType.barrel && random.nextDouble() < 0.35) {
              if (!_bombs.any((b) => b.x == bot.x && b.y == bot.y)) {
                _bombs.add(Bomb(x: bot.x, y: bot.y, range: 1));
                break;
              }
            }

            // Boş hücreye yürü
            if (_grid[ny][nx] == CellType.empty && !_bombs.any((b) => b.x == nx && b.y == ny)) {
              bot.x = nx;
              bot.y = ny;
              break;
            }
          }
        }
      }
    }
  }

  void _detonateBomb(Bomb bomb) {
    _addExplosion(bomb.x, bomb.y);

    const directions = [
      [0, -1], [0, 1], [-1, 0], [1, 0]
    ];

    for (final dir in directions) {
      for (int dist = 1; dist <= bomb.range; dist++) {
        final tx = bomb.x + (dir[0] * dist);
        final ty = bomb.y + (dir[1] * dist);

        if (tx < 0 || tx >= cols || ty < 0 || ty >= rows) break;
        if (_grid[ty][tx] == CellType.wall) break;

        if (_grid[ty][tx] == CellType.barrel) {
          _grid[ty][tx] = CellType.empty;
          _addExplosion(tx, ty);
          _score += 100;

          _maybeDropPowerUp(tx, ty);
          break;
        }

        final otherBomb = _bombs.cast<Bomb?>().firstWhere(
          (b) => b?.x == tx && b?.y == ty,
          orElse: () => null,
        );
        if (otherBomb != null) {
          otherBomb.timeLeft = 0.05;
        }

        _addExplosion(tx, ty);
      }
    }
  }

  void _addExplosion(int x, int y) {
    _explosions.add(ExplosionTile(x: x, y: y));

    // Oyuncu hasarı
    if (_playerX == x && _playerY == y) {
      _health = max(0, _health - 25);
      _lastNotification = '⚠️ Hasar aldın! Kalan Can: $_health HP';
      if (_health <= 0) {
        _lastNotification = '💀 Kaybettin! Yeniden başlatabilirsin.';
      }
    }

    // Bot hasarı
    for (final bot in _bots) {
      if (bot.x == x && bot.y == y && bot.health > 0) {
        bot.health -= 50;
        if (bot.health <= 0) {
          _score += 300;
          _lastNotification = '🎯 ${bot.name} elendi! +300 Puan!';
        }
      }
    }

    // Zafer kontrolü: Oyuncu hayatta ve tüm botlar elendiyse
    if (_health > 0 && _bots.isNotEmpty && _bots.every((b) => b.health <= 0)) {
      _lastNotification = '🏆 TEBRİKLER! Tüm rakipleri yendin, ARENA ŞAMPİYONUSUN!';
    }
  }

  void _maybeDropPowerUp(int x, int y) {
    if (Random().nextDouble() < 0.55) {
      final types = PowerUpType.values;
      final selected = types[Random().nextInt(types.length)];
      _powerUps.add(PowerUpItem(x: x, y: y, type: selected));
    }
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }
}
