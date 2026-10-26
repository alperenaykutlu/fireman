import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/game_elements.dart';
import '../models/character.dart';
import '../services/game_audio_service.dart';

class GameplayViewModel extends ChangeNotifier {
  // Larger grid restores room to maneuver without taking space from the controls.
  static const int cols = 23;
  static const int rows = 13;

  late List<List<CellType>> _grid;
  final List<Dynamite> _dynamites = [];
  final List<ExplosionTile> _explosions = [];
  final List<PowerUpItem> _powerUps = [];
  final List<ArenaFighter> _fighters = [];

  int _totalPlayerCount = 4;
  int _score = 0;
  String _playerName = 'Oyuncu';
  CharacterModel? _localCharacter;
  String? _lastNotification;
  Timer? _gameLoopTimer;
  final Stopwatch _tickClock = Stopwatch();
  final Random _random = Random();

  // 2 Dakikalık Maç Süresi ve Ani Ölüm (Sudden Death)
  double _remainingSeconds = 120.0;
  bool _isSuddenDeath = false;
  int _suddenDeathStep = 0;
  double _suddenDeathCooldown = 0;
  final List<Point<int>> _spiralOrder = [];

  // Oyun Bitti (Game Over) Durumu
  bool _isGameOver = false;
  String? _gameOverTitle;
  String? _gameOverMessage;

  // Kesintisiz Basılı Tutma Hareketi (Continuous Movement)
  int _holdDx = 0;
  int _holdDy = 0;
  double _playerMoveCooldown = 0.0;
  int _mapRevision = 0;
  int _gameGeneration = 0;
  bool _disposed = false;
  bool _authoritativeOnline = false;
  double _shakeRemaining = 0;
  double _shakePhase = 0;
  double _humanHitFlashRemaining = 0;

  // Getters
  List<List<CellType>> get grid => _grid;
  // Render consumers iterate these frequently; avoid allocating immutable copies
  // on every frame. Mutations stay encapsulated in this view model.
  List<Dynamite> get dynamites => _dynamites;
  List<ExplosionTile> get explosions => _explosions;
  List<PowerUpItem> get powerUps => _powerUps;
  List<ArenaFighter> get fighters => _fighters;
  int get mapRevision => _mapRevision;

  ArenaFighter get humanPlayer => _fighters.firstWhere((f) => f.isHuman, orElse: () => _fighters.first);
  int get totalPlayerCount => _totalPlayerCount;
  bool get isAuthoritativeOnline => _authoritativeOnline;
  int get score => _score;
  void configureLocalPlayer({String? name, CharacterModel? character}) {
    if (name != null && name.trim().isNotEmpty) _playerName = name.trim();
    if (character != null) _localCharacter = character;
    for (final fighter in _fighters.where((item) => item.isHuman)) {
      fighter.name = _playerName;
      final model = _localCharacter;
      if (model == null) continue;
      fighter.bodyColor = Color(model.suitColorValue);
      fighter.skinColor = Color(model.skinColorValue);
      fighter.isFemale = model.gender == 'female';
      fighter.hatStyle = model.hatStyle;
      fighter.suitStyle = model.suitStyle;
      fighter.accessoryStyle = model.equippedAccessory.contains('telsizi') ? 1 : model.equippedAccessory.contains('tüp') ? 2 : 0;
      fighter.maskStyle = model.equippedMask.toLowerCase().contains('standart') ? -1 : 0;
    }
    notifyListeners();
  }
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
  bool get isHumanHitFlashing => _humanHitFlashRemaining > 0;
  Offset get cameraShakeOffset {
    if (_shakeRemaining <= 0) return Offset.zero;
    final intensity = (_shakeRemaining / .18).clamp(0.0, 1.0).toDouble();
    return Offset(
      sin(_shakePhase * 1.7) * 4.0 * intensity,
      cos(_shakePhase * 2.3) * 3.0 * intensity,
    );
  }

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

  void enableAuthoritativeOnlineMode() {
    if (_authoritativeOnline || _disposed) return;
    _authoritativeOnline = true;
    ++_gameGeneration;
    _gameLoopTimer?.cancel();
    _tickClock.stop();
    _fighters.clear();
    _dynamites.clear();
    _explosions.clear();
    _powerUps.clear();
    _grid = List.generate(9, (_) => List<CellType>.filled(11, CellType.empty));
    _mapRevision++;
    _remainingSeconds = 120;
    _isGameOver = false;
    notifyListeners();
  }

  void applyAuthoritativeSnapshot(Map<String, dynamic> snapshot) {
    if (!_authoritativeOnline || _disposed) return;
    final columns = _readInt(snapshot, 'Columns', 11).clamp(1, 64);
    final rows = _readInt(snapshot, 'Rows', 9).clamp(1, 64);
    final rawTiles = snapshot['Tiles'] ?? snapshot['tiles'];
    if (rawTiles is List && rawTiles.length == columns * rows) {
      var changed = _grid.length != rows || (_grid.isNotEmpty && _grid.first.length != columns);
      final nextGrid = List.generate(rows, (y) => List.generate(columns, (x) {
        final raw = (rawTiles[y * columns + x] as num?)?.toInt() ?? 0;
        final value = CellType.values[raw.clamp(0, 2)];
        if (!changed && _grid[y][x] != value) changed = true;
        return value;
      }));
      if (changed) { _grid = nextGrid; _mapRevision++; }
    }

    final rawPlayers = snapshot['Players'] ?? snapshot['players'];
    if (rawPlayers is List) {
      final oldPlayers = {for (final fighter in _fighters) fighter.id: fighter};
      _fighters.clear();
      for (final raw in rawPlayers) {
        if (raw is! Map) continue;
        final player = Map<String, dynamic>.from(raw.map((key, value) => MapEntry(key.toString(), value)));
        final id = _readInt(player, 'PlayerId', _fighters.length + 1);
        final existing = oldPlayers[id];
        final userId = _readString(player, 'UserId');
        final rawX = _readInt(player, 'SubTileX', 128);
        final rawY = _readInt(player, 'SubTileY', 128);
        final x = (rawX / 256).floor().clamp(0, columns - 1);
        final y = (rawY / 256).floor().clamp(0, rows - 1);
        final alive = _readBool(player, 'IsAlive', true);
        final disconnected = existing?.isDisconnected ?? false;
        final fighter = ArenaFighter(
          id: id,
          name: _readString(player, 'Username').isEmpty ? 'Oyuncu $id' : _readString(player, 'Username'),
          userId: userId.isEmpty ? null : userId,
          hatColor: existing?.hatColor ?? _onlineHatColor(id),
          bodyColor: existing?.bodyColor ?? _onlineBodyColor(id),
          score: _readInt(player, 'Score', existing?.score ?? 0),
          isHuman: userId.isNotEmpty && userId == _apiUserId,
          x: x,
          y: y,
          health: disconnected ? 0 : _readInt(player, 'Health', alive ? 100 : 0).clamp(0, 100),
          maxDynamites: _readInt(player, 'BombCapacity', 1),
          dynamiteRange: _readInt(player, 'BombRange', 1),
          speed: _readInt(player, 'Speed', 8) / 8,
          status: alive && !disconnected ? PlayerStatus.alive : PlayerStatus.eliminated,
          isDisconnected: disconnected,
        );
        if (fighter.isHuman) {
          fighter.name = _playerName;
          final local = _localCharacter;
          if (local != null) {
            fighter.bodyColor = Color(local.suitColorValue);
            fighter.skinColor = Color(local.skinColorValue);
            fighter.isFemale = local.gender == 'female';
            fighter.hatStyle = local.hatStyle;
            fighter.suitStyle = local.suitStyle;
            fighter.accessoryStyle = local.equippedAccessory.contains('telsizi') ? 1 : local.equippedAccessory.contains('tüp') ? 2 : 0;
            fighter.maskStyle = local.equippedMask.toLowerCase().contains('standart') ? -1 : 0;
          }
        }
        _fighters.add(fighter);
      }
    }

    _dynamites
      ..clear()
      ..addAll(_readList(snapshot, 'Bombs').whereType<Map>().map((raw) {
        final bomb = Map<String, dynamic>.from(raw.map((key, value) => MapEntry(key.toString(), value)));
        return Dynamite(x: _readInt(bomb, 'TileX', 0), y: _readInt(bomb, 'TileY', 0), range: _readInt(bomb, 'Range', 1), ownerId: _readInt(bomb, 'OwnerPlayerId', -1), timeLeft: _readInt(bomb, 'RemainingTicks', 0) / 30);
      }));
    _explosions
      ..clear()
      ..addAll(_readList(snapshot, 'Flames').whereType<Map>().map((raw) {
        final flame = Map<String, dynamic>.from(raw.map((key, value) => MapEntry(key.toString(), value)));
        return ExplosionTile(x: _readInt(flame, 'TileX', 0), y: _readInt(flame, 'TileY', 0), duration: _readInt(flame, 'RemainingTicks', 1) / 30);
      }));
    _powerUps
      ..clear()
      ..addAll(_readList(snapshot, 'PowerUps').whereType<Map>().map((raw) {
        final powerUp = Map<String, dynamic>.from(raw.map((key, value) => MapEntry(key.toString(), value)));
        final type = switch (_readInt(powerUp, 'Type', 0)) { 1 => PowerUpType.dynamiteRange, 2 => PowerUpType.rollerSkate, 3 => PowerUpType.extraDynamite, 4 => PowerUpType.shield, _ => PowerUpType.shield };
        return PowerUpItem(x: _readInt(powerUp, 'TileX', 0), y: _readInt(powerUp, 'TileY', 0), type: type);
      }));

    final tick = _readInt(snapshot, 'Tick', 0);
    _remainingSeconds = max(0, 120 - tick / 30).toDouble();
    _isGameOver = _readBool(snapshot, 'IsMatchOver', false);
    ArenaFighter? localPlayer;
    for (final fighter in _fighters) {
      if (fighter.isHuman) { localPlayer = fighter; break; }
    }
    if (localPlayer != null) {
      _score = localPlayer.score;
      if (localPlayer.status == PlayerStatus.eliminated) {
        _score = -_score.abs();
        localPlayer.score = _score;
      }
    }
    if (_isGameOver) {
      if (localPlayer?.status == PlayerStatus.eliminated) _score = -_score.abs();
      _gameOverTitle = 'MAÇ TAMAMLANDI';
      _gameOverMessage = 'Sunucu otoriter sonucu eşitledi.';
      _gameLoopTimer?.cancel();
    }
    notifyListeners();
  }

  String _apiUserId = '';
  void setOnlineUserId(String userId) => _apiUserId = userId;

  void markUserDisconnected(String userId) {
    final index = _fighters.indexWhere((fighter) => fighter.userId == userId);
    if (index < 0) return;
    final fighter = _fighters[index];
    if (fighter.status == PlayerStatus.eliminated) return;
    _fighters[index] = ArenaFighter(id: fighter.id, name: fighter.name, userId: fighter.userId, hatColor: fighter.hatColor, bodyColor: fighter.bodyColor, isHuman: fighter.isHuman, x: fighter.x, y: fighter.y, health: 0, wins: fighter.wins, maxDynamites: fighter.maxDynamites, dynamiteRange: fighter.dynamiteRange, speed: fighter.speed, status: PlayerStatus.eliminated, isDisconnected: true, canMoveDynamite: fighter.canMoveDynamite);
    for (final offset in const [Point(0, 0), Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)]) {
      _explosions.add(ExplosionTile(x: fighter.x + offset.x, y: fighter.y + offset.y, duration: .65, isCenter: offset.x == 0 && offset.y == 0));
    }
    _lastNotification = '⚡ ${fighter.name} bağlantısı kesildi';
    notifyListeners();
  }

  static int _readInt(Map<String, dynamic> map, String key, int fallback) {
    final value = map[key] ?? map[key[0].toLowerCase() + key.substring(1)];
    return value is num ? value.toInt() : fallback;
  }
  static bool _readBool(Map<String, dynamic> map, String key, bool fallback) => (map[key] ?? map[key[0].toLowerCase() + key.substring(1)]) as bool? ?? fallback;
  static String _readString(Map<String, dynamic> map, String key) => (map[key] ?? map[key[0].toLowerCase() + key.substring(1)])?.toString() ?? '';
  static List<dynamic> _readList(Map<String, dynamic> map, String key) => (map[key] ?? map[key[0].toLowerCase() + key.substring(1)]) as List? ?? const [];
  static Color _onlineHatColor(int id) => [const Color(0xFFEF6B48), const Color(0xFF58A6FF), const Color(0xFFC084FC), const Color(0xFFFFC857)][(id - 1).abs() % 4];
  static Color _onlineBodyColor(int id) => [const Color(0xFFC84536), const Color(0xFF2463A8), const Color(0xFF7549A6), const Color(0xFF986C1D)][(id - 1).abs() % 4];

  /// Call this when the match transport reports that a remote participant left.
  void markPlayerDisconnected(int fighterId) {
    ArenaFighter? fighter;
    for (final candidate in _fighters) {
      if (candidate.id == fighterId && !candidate.isHuman) {
        fighter = candidate;
        break;
      }
    }
    if (fighter == null || fighter.status == PlayerStatus.eliminated) return;
    fighter.isDisconnected = true;
    fighter.status = PlayerStatus.eliminated;
    fighter.health = 0;
    for (final offset in const [Point(0, 0), Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)]) {
      _explosions.add(ExplosionTile(x: fighter.x + offset.x, y: fighter.y + offset.y, duration: .65, isCenter: offset.x == 0 && offset.y == 0));
    }
    _lastNotification = '⚡ ${fighter.name} bağlantısı koptu ve oyundan düştü';
    notifyListeners();
    _checkMatchEndCondition();
  }

  Future<void> startNewGame() async {
    if (_disposed) return;
    final generation = ++_gameGeneration;
    _gameLoopTimer?.cancel();
    _dynamites.clear();
    _explosions.clear();
    _powerUps.clear();
    _fighters.clear();

    _remainingSeconds = 120.0;
    _isSuddenDeath = false;
    _suddenDeathStep = 0;
    _suddenDeathCooldown = 0;
    _holdDx = 0;
    _holdDy = 0;
    _shakeRemaining = 0;
    _humanHitFlashRemaining = 0;
    _playerMoveCooldown = 0.0;
    _isGameOver = false;
    _gameOverTitle = null;
    _gameOverMessage = null;
    _grid = List.generate(rows, (r) => List.generate(cols, (c) =>
        r == 0 || r == rows - 1 || c == 0 || c == cols - 1 || (r.isEven && c.isEven)
            ? CellType.wall : CellType.empty));

    // 1. DÖRT KARAKTERİ OLUŞTUR (Başlangıç Hızı: 0.7)
    _score = 0;
    _fighters.add(ArenaFighter(
      id: 0,
      name: _playerName,
      hatColor: const Color(0xFF1D4ED8),
      bodyColor: const Color(0xFF2563EB),
      skinColor: Color(_localCharacter?.skinColorValue ?? 0xFFFFD1A4),
      isFemale: _localCharacter?.gender == 'female',
      hatStyle: _localCharacter?.hatStyle ?? 0,
      suitStyle: _localCharacter?.suitStyle ?? 0,
      accessoryStyle: _localCharacter?.equippedAccessory.contains('telsizi') == true ? 1 : 0,
      maskStyle: _localCharacter?.equippedMask.toLowerCase().contains('standart') == false ? 0 : -1,
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

    final generated = await compute(_generateArenaGrid, _random.nextInt(1 << 31));
    if (_disposed || generation != _gameGeneration) return;
    _grid = generated.map((row) => row.map((value) => CellType.values[value]).toList()).toList();
    _mapRevision++;
    _lastNotification = null;
    _tickClock
      ..reset()
      ..start();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      final dt = (_tickClock.elapsedMicroseconds / 1000000.0)
          .clamp(.001, .1)
          .toDouble();
      _tickClock.reset();
      _tick(dt);
    });
    notifyListeners();
  }

  // --- BASILI TUTMA & HAREKET KONTROLÜ (ÇAPRAZ GEÇİŞ YOK: SADECE DİK) ---
  void setMovementDirection(int dx, int dy) {
    // Çapraz hareketi engelle: ya sadece yatay ya sadece dikey
    if (dx != 0 && dy != 0) {
      dy = 0; // Yatay öncelikli dik hareket
    }

    final wasMoving = _holdDx != 0 || _holdDy != 0;
    final directionChanged = dx != _holdDx || dy != _holdDy;
    _holdDx = dx;
    _holdDy = dy;
    if (_authoritativeOnline) {
      notifyListeners();
      return;
    }
    if (wasMoving && dx == 0 && dy == 0) notifyListeners();
    if (dx != 0 || dy != 0) {
      final overlapsAnotherFighter = _fighters.any(
        (fighter) => !fighter.isHuman &&
            fighter.status == PlayerStatus.alive &&
            fighter.x == humanPlayer.x &&
            fighter.y == humanPlayer.y,
      );
      // A direction change or a shared tile must never leave a player feeling stuck.
      if (_playerMoveCooldown <= 0 || directionChanged || overlapsAnotherFighter) {
        final moved = _executePlayerMove(dx, dy);
        final player = humanPlayer;
        _playerMoveCooldown = 0.16 / player.speed;
        if (moved) notifyListeners();
      }
    }
  }

  bool _executePlayerMove(int dx, int dy) {
    final player = humanPlayer;
    if (player.status == PlayerStatus.eliminated || _isGameOver) return false;

    final targetX = player.x + dx;
    final targetY = player.y + dy;

    if (targetX < 0 || targetX >= cols || targetY < 0 || targetY >= rows) return false;

    // Duvara, varile veya kapanan gri taşa çarpma
    if (_grid[targetY][targetX] != CellType.empty) return false;

    // Hedef hücrede dinamit var mı?
    final dynIndex = _dynamites.indexWhere((d) => d.x == targetX && d.y == targetY);
    if (dynIndex != -1) {
      if (!player.canMoveDynamite) return false;
      final kickedDyn = _dynamites[dynIndex];
      final nextX = targetX + dx;
      final nextY = targetY + dy;
      if (nextX < 0 || nextX >= cols || nextY < 0 || nextY >= rows ||
          _grid[nextY][nextX] != CellType.empty ||
          _dynamites.any((d) => d.x == nextX && d.y == nextY)) {
        return false;
      }
      _kickDynamite(kickedDyn, dx, dy);
    }

    player.x = targetX;
    player.y = targetY;

    _checkPowerUpPickup(player);
    return true;
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
          fighter.health = (fighter.health + 10).clamp(0, 100).toInt();
          if (fighter.isHuman) _lastNotification = '❤️ Can yenilendi (+10 HP) • Kalan: ${fighter.health} HP';
          break;
        case PowerUpType.bombGlove:
          fighter.canMoveDynamite = true;
          if (fighter.isHuman) _lastNotification = '🧤 Dinamit eldiveni alındı • Artık bombaları itebilirsin';
          break;
      }
    }
  }

  // --- OYUN DÖNGÜSÜ ---
  void _tick(double dt) {
    bool stateChanged = false;
    _shakePhase += dt * 42;
    if (_shakeRemaining > 0) {
      _shakeRemaining = max(0.0, _shakeRemaining - dt).toDouble();
      stateChanged = true;
    }
    if (_humanHitFlashRemaining > 0) {
      _humanHitFlashRemaining = max(0.0, _humanHitFlashRemaining - dt).toDouble();
      stateChanged = true;
    }

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
      // Keep the arena closure speed stable even when the render tick rate changes.
      _suddenDeathCooldown -= dt;
      if (_suddenDeathCooldown <= 0 && _suddenDeathStep < _spiralOrder.length) {
        _suddenDeathCooldown = .05;
        final pt = _spiralOrder[_suddenDeathStep++];
        _grid[pt.y][pt.x] = CellType.suddenDeath;
        _mapRevision++;

        _powerUps.removeWhere((p) => p.x == pt.x && p.y == pt.y);
        _dynamites.removeWhere((d) => d.x == pt.x && d.y == pt.y);

        for (final f in _fighters) {
          if (f.status == PlayerStatus.alive && f.x == pt.x && f.y == pt.y) {
            f.health = 0;
            f.status = PlayerStatus.eliminated;
            if (f.isHuman) {
              _score = -_score.abs();
              _lastNotification = '💀 Duvar altında ezildin!';
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
        final moved = _executePlayerMove(_holdDx, _holdDy);
        final player = humanPlayer;
        _playerMoveCooldown = 0.14 / player.speed;
        stateChanged = stateChanged || moved;
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
    if (_explosions.isNotEmpty) {
      stateChanged = true;
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
    if (humanPlayer.status == PlayerStatus.eliminated) _score = -_score.abs();
    if (humanPlayer.status == PlayerStatus.eliminated) _score = -_score.abs();
    _gameLoopTimer?.cancel();
    _gameOverTitle = title;
    _gameOverMessage = message;

    // Tüm iç ızgarayı aynı anda gri duvara dönüştür
    for (int r = 1; r < rows - 1; r++) {
      for (int c = 1; c < cols - 1; c++) {
        _grid[r][c] = CellType.suddenDeath;
      }
    }
    _mapRevision++;

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
        final chosenMove = _chooseBotMove(bot, selectedMoves);
        _tryMoveFighter(bot, chosenMove[0], chosenMove[1]);
        _checkPowerUpPickup(bot);
      }
    }
  }

  /// Lightweight utility choice, evaluated only when a bot's decision cooldown expires.
  List<int> _chooseBotMove(ArenaFighter bot, List<List<int>> moves) {
    final human = humanPlayer;
    Point<int>? target;
    if (human.status == PlayerStatus.alive &&
        (human.x - bot.x).abs() + (human.y - bot.y).abs() <= 6) {
      target = Point(human.x, human.y);
    } else if (_powerUps.isNotEmpty) {
      var nearestDistance = 1 << 30;
      for (final item in _powerUps) {
        final distance = (item.x - bot.x).abs() + (item.y - bot.y).abs();
        if (distance < nearestDistance) {
          nearestDistance = distance;
          target = Point(item.x, item.y);
        }
      }
    } else {
      var nearestDistance = 1 << 30;
      for (var y = 1; y < rows - 1; y++) {
        for (var x = 1; x < cols - 1; x++) {
          if (_grid[y][x] != CellType.barrel) continue;
          final distance = (x - bot.x).abs() + (y - bot.y).abs();
          if (distance < nearestDistance) {
            nearestDistance = distance;
            target = Point(x, y);
          }
        }
      }
    }

    if (target == null) return moves[_random.nextInt(moves.length)];
    final currentDistance = (target.x - bot.x).abs() + (target.y - bot.y).abs();
    var bestScore = -double.infinity;
    final bestMoves = <List<int>>[];
    for (final move in moves) {
      final distance = (target.x - (bot.x + move[0])).abs() +
          (target.y - (bot.y + move[1])).abs();
      final score = currentDistance - distance + _random.nextDouble() * .15;
      if (score > bestScore) {
        bestScore = score;
        bestMoves
          ..clear()
          ..add(move);
      } else if (score == bestScore) {
        bestMoves.add(move);
      }
    }
    return bestMoves[_random.nextInt(bestMoves.length)];
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
    GameAudioService.instance.playExplosion();
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
          _mapRevision++;
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
    if (isCenter) {
      _shakeRemaining = .18;
    }

    // Hasar & Puanlama Mantığı
    for (final fighter in _fighters) {
      if (fighter.status == PlayerStatus.alive && fighter.x == x && fighter.y == y) {
        fighter.health = max(0, fighter.health - 25);
        if (fighter.isHuman) _humanHitFlashRemaining = .2;

        if (fighter.isHuman) {
          if (fighter.health <= 0) {
            fighter.status = PlayerStatus.eliminated;
            _score = -_score.abs();
            _lastNotification = '💀 Elendin!';
          } else {
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
    _disposed = true;
    _gameGeneration++;
    _gameLoopTimer?.cancel();
    _tickClock.stop();
    super.dispose();
  }
}

/// Builds the arena's static grid on a background isolate so map generation
/// cannot block input, animation, or painting on the UI isolate.
List<List<int>> _generateArenaGrid(int seed) {
  final random = Random(seed);
  return List.generate(GameplayViewModel.rows, (row) =>
      List.generate(GameplayViewModel.cols, (col) {
    if (row == 0 || row == GameplayViewModel.rows - 1 || col == 0 || col == GameplayViewModel.cols - 1 ||
        (row.isEven && col.isEven)) return CellType.wall.index;
    final corner = (row <= 2 && col <= 2) ||
        (row >= GameplayViewModel.rows - 3 && col >= GameplayViewModel.cols - 3) ||
        (row <= 2 && col >= GameplayViewModel.cols - 3) ||
        (row >= GameplayViewModel.rows - 3 && col <= 2);
    if (corner) return CellType.empty.index;
    return random.nextDouble() < .58 ? CellType.barrel.index : CellType.empty.index;
  }));
}
