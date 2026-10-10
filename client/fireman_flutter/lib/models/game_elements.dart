import 'package:flutter/material.dart';

enum CellType {
  empty,
  wall,       // Kırılmaz sabit blok
  barrel,     // Kırmızı patlatılabilir varil
}

enum PowerUpType {
  lightning,  // Şimşek: Bomba menzili/şiddeti +1
  shoe,       // Ayakkabı: Hız artışı
  extraBomb,  // Bomba: +1 bomba hakkı
  heal,       // Tamir: Can iyileştirme
}

class Bomb {
  final int x;
  final int y;
  final int range;
  double timeLeft; // saniye cinsinden

  Bomb({
    required this.x,
    required this.y,
    required this.range,
    this.timeLeft = 2.4,
  });
}

class ExplosionTile {
  final int x;
  final int y;
  double duration;

  ExplosionTile({
    required this.x,
    required this.y,
    this.duration = 0.5,
  });
}

class PowerUpItem {
  final int x;
  final int y;
  final PowerUpType type;

  PowerUpItem({
    required this.x,
    required this.y,
    required this.type,
  });
}

class BotPlayer {
  int x;
  int y;
  int health;
  final String name;
  final Color color;
  double moveCooldown;

  BotPlayer({
    required this.x,
    required this.y,
    this.health = 100,
    required this.name,
    required this.color,
    this.moveCooldown = 0.0,
  });
}
